from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

import cv2
import numpy as np

from ai_service.detectors import logo_features


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATASET = ROOT / "datasets" / "square_logos"
DEFAULT_OUTPUT = ROOT / "models" / "square_logo_linear.npz"


def _boxes(label_path: Path, width: int, height: int) -> list[tuple[int, int, int, int]]:
    boxes: list[tuple[int, int, int, int]] = []
    for line in label_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        _, center_x, center_y, box_width, box_height = map(float, line.split())
        pixel_width = max(1, int(box_width * width))
        pixel_height = max(1, int(box_height * height))
        x = int(center_x * width - pixel_width / 2)
        y = int(center_y * height - pixel_height / 2)
        boxes.append((x, y, pixel_width, pixel_height))
    return boxes


def _aspect_crop(image: np.ndarray, box: tuple[int, int, int, int]) -> np.ndarray:
    x, y, width, height = box
    image_height, image_width = image.shape[:2]
    crop_width = min(image_width, max(width, height * 4))
    crop_height = min(image_height, max(height, crop_width // 4))
    center_x = x + width // 2
    center_y = y + height // 2
    x1 = max(0, min(image_width - crop_width, center_x - crop_width // 2))
    y1 = max(0, min(image_height - crop_height, center_y - crop_height // 2))
    return image[y1 : y1 + crop_height, x1 : x1 + crop_width]


def _iou(first: tuple[int, int, int, int], second: tuple[int, int, int, int]) -> float:
    ax, ay, aw, ah = first
    bx, by, bw, bh = second
    intersection = max(0, min(ax + aw, bx + bw) - max(ax, bx)) * max(
        0, min(ay + ah, by + bh) - max(ay, by)
    )
    union = aw * ah + bw * bh - intersection
    return intersection / union if union else 0.0


def _negative_crops(
    image: np.ndarray,
    positives: list[tuple[int, int, int, int]],
    rng: random.Random,
    count: int = 12,
) -> list[np.ndarray]:
    height, width = image.shape[:2]
    crops: list[np.ndarray] = []
    attempts = 0
    while len(crops) < count and attempts < 60:
        attempts += 1
        window_width = rng.randint(max(48, width // 6), max(49, width * 3 // 4))
        window_height = max(16, window_width // 4)
        if window_width > width or window_height > height:
            continue
        x = rng.randint(0, width - window_width)
        y = rng.randint(0, height - window_height)
        candidate = (x, y, window_width, window_height)
        if any(_iou(candidate, positive) > 0.02 for positive in positives):
            continue
        crops.append(image[y : y + window_height, x : x + window_width])
    return crops


def _features(dataset: Path, split: str, seed: int) -> tuple[np.ndarray, np.ndarray]:
    rng = random.Random(seed)
    features: list[np.ndarray] = []
    labels: list[int] = []
    image_dir = dataset / "images" / split
    label_dir = dataset / "labels" / split
    for image_path in sorted(image_dir.glob("*.jpg")):
        image = cv2.imread(str(image_path), cv2.IMREAD_COLOR)
        if image is None:
            continue
        height, width = image.shape[:2]
        boxes = _boxes(label_dir / f"{image_path.stem}.txt", width, height)
        for box in boxes:
            crop = _aspect_crop(image, box)
            features.append(logo_features(crop))
            labels.append(1)
        for crop in _negative_crops(image, boxes, rng):
            features.append(logo_features(crop))
            labels.append(-1)
    return np.asarray(features, dtype=np.float32), np.asarray(labels, dtype=np.int32)


def train(dataset: Path, output: Path, seed: int = 42) -> dict[str, float | int]:
    train_x, train_y = _features(dataset, "train", seed)
    val_x, val_y = _features(dataset, "val", seed + 1)
    if not len(train_x) or 1 not in train_y or -1 not in train_y:
        raise ValueError("Training data needs both positive and negative samples.")

    targets = (train_y == 1).astype(np.float32)
    weights = np.zeros(train_x.shape[1], dtype=np.float32)
    bias = 0.0
    generator = np.random.default_rng(seed)
    positive_weight = float((train_y == -1).sum() / max(1, (train_y == 1).sum()))
    batch_size = 64
    for epoch in range(120):
        learning_rate = 0.08 / (1.0 + epoch * 0.025)
        permutation = generator.permutation(len(train_y))
        for start in range(0, len(train_y), batch_size):
            indices = permutation[start : start + batch_size]
            batch_x = train_x[indices]
            batch_y = targets[indices]
            logits = np.clip(batch_x @ weights + bias, -20, 20)
            probabilities = 1.0 / (1.0 + np.exp(-logits))
            sample_weights = np.where(batch_y == 1, positive_weight, 1.0)
            errors = (probabilities - batch_y) * sample_weights
            normalizer = max(1.0, float(sample_weights.sum()))
            gradient = batch_x.T @ errors / normalizer + 1e-4 * weights
            weights -= learning_rate * gradient.astype(np.float32)
            bias -= learning_rate * float(errors.sum() / normalizer)

    val_logits = np.clip(val_x @ weights + bias, -20, 20)
    val_probabilities = 1.0 / (1.0 + np.exp(-val_logits))
    predicted = np.where(val_probabilities >= 0.5, 1, -1).astype(np.int32)
    true_positive = int(((predicted == 1) & (val_y == 1)).sum())
    false_positive = int(((predicted == 1) & (val_y == -1)).sum())
    false_negative = int(((predicted == -1) & (val_y == 1)).sum())
    precision = true_positive / max(1, true_positive + false_positive)
    recall = true_positive / max(1, true_positive + false_negative)
    accuracy = float((predicted == val_y).mean())

    output.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(output, weights=weights, bias=np.float32(bias))
    metrics: dict[str, float | int] = {
        "train_samples": int(len(train_y)),
        "validation_samples": int(len(val_y)),
        "validation_accuracy": round(accuracy, 4),
        "validation_precision": round(precision, 4),
        "validation_recall": round(recall, 4),
        "positive_probability_mean": round(float(val_probabilities[val_y == 1].mean()), 4),
        "negative_probability_mean": round(float(val_probabilities[val_y == -1].mean()), 4),
    }
    output.with_suffix(".json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    return metrics


def main() -> None:
    parser = argparse.ArgumentParser(description="Train the official Square logo SVM.")
    parser.add_argument("--dataset", type=Path, default=DEFAULT_DATASET)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    metrics = train(args.dataset.resolve(), args.output.resolve(), args.seed)
    print(json.dumps(metrics, indent=2))
    print(f"Saved trained logo model to {args.output.resolve()}")


if __name__ == "__main__":
    main()
