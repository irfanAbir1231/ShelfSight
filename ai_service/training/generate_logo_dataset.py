from __future__ import annotations

import argparse
import random
import shutil
from pathlib import Path

import cv2
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LOGO = ROOT / "assets" / "logos" / "square-official-grid.png"
DEFAULT_OUTPUT = ROOT / "datasets" / "square_logos"
DEFAULT_BACKGROUNDS = ROOT.parent / "test_assets"


def _load_logo(path: Path) -> tuple[np.ndarray, np.ndarray]:
    source = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    if source is None:
        raise ValueError(f"Could not load logo: {path}")
    if source.shape[2] == 4:
        image, alpha = source[:, :, :3], source[:, :, 3]
    else:
        image = source
        gray = cv2.cvtColor(source, cv2.COLOR_BGR2GRAY)
        alpha = np.where(gray < 248, 255, 0).astype(np.uint8)
    rows, columns = np.where(alpha > 18)
    if not len(rows):
        raise ValueError(f"Logo {path} has no visible pixels.")
    y1, y2 = int(rows.min()), int(rows.max()) + 1
    x1, x2 = int(columns.min()), int(columns.max()) + 1
    return image[y1:y2, x1:x2], alpha[y1:y2, x1:x2]


def _backgrounds(directory: Path) -> list[np.ndarray]:
    images: list[np.ndarray] = []
    if directory.is_dir():
        for path in directory.iterdir():
            if path.suffix.lower() not in {".jpg", ".jpeg", ".png", ".webp"}:
                continue
            image = cv2.imread(str(path), cv2.IMREAD_COLOR)
            if image is not None:
                images.append(image)
    return images


def _make_background(size: int, sources: list[np.ndarray], rng: random.Random) -> np.ndarray:
    if sources and rng.random() < 0.72:
        source = rng.choice(sources)
        height, width = source.shape[:2]
        scale = max(size / width, size / height) * rng.uniform(1.0, 1.8)
        resized = cv2.resize(source, (max(size, int(width * scale)), max(size, int(height * scale))))
        y = rng.randint(0, resized.shape[0] - size)
        x = rng.randint(0, resized.shape[1] - size)
        canvas = resized[y : y + size, x : x + size].copy()
    else:
        base = np.zeros((size, size, 3), dtype=np.uint8)
        base[:] = np.array([rng.randint(35, 220) for _ in range(3)], dtype=np.uint8)
        for _ in range(rng.randint(6, 18)):
            x1, y1 = rng.randint(0, size - 1), rng.randint(0, size - 1)
            x2 = min(size, x1 + rng.randint(25, size // 2))
            y2 = min(size, y1 + rng.randint(20, size // 2))
            color = tuple(rng.randint(20, 240) for _ in range(3))
            cv2.rectangle(base, (x1, y1), (x2, y2), color, -1)
        canvas = cv2.GaussianBlur(base, (5, 5), 0)
    brightness = rng.uniform(0.70, 1.25)
    return np.clip(canvas.astype(np.float32) * brightness, 0, 255).astype(np.uint8)


def _transform_logo(
    logo: np.ndarray,
    alpha: np.ndarray,
    target_width: int,
    rng: random.Random,
) -> tuple[np.ndarray, np.ndarray]:
    target_height = max(10, int(target_width * logo.shape[0] / logo.shape[1]))
    resized_logo = cv2.resize(logo, (target_width, target_height), interpolation=cv2.INTER_AREA)
    resized_alpha = cv2.resize(alpha, (target_width, target_height), interpolation=cv2.INTER_AREA)

    border = max(6, min(target_width, target_height) // 8)
    padded_logo = cv2.copyMakeBorder(resized_logo, border, border, border, border, cv2.BORDER_CONSTANT)
    padded_alpha = cv2.copyMakeBorder(resized_alpha, border, border, border, border, cv2.BORDER_CONSTANT)
    center = (padded_logo.shape[1] / 2, padded_logo.shape[0] / 2)
    matrix = cv2.getRotationMatrix2D(center, rng.uniform(-14, 14), rng.uniform(0.92, 1.08))
    output_size = (padded_logo.shape[1], padded_logo.shape[0])
    warped_logo = cv2.warpAffine(padded_logo, matrix, output_size, flags=cv2.INTER_LINEAR)
    warped_alpha = cv2.warpAffine(padded_alpha, matrix, output_size, flags=cv2.INTER_LINEAR)

    if rng.random() < 0.30:
        warped_logo = cv2.GaussianBlur(warped_logo, (3, 3), rng.uniform(0.2, 1.0))
    warped_logo = np.clip(
        warped_logo.astype(np.float32) * rng.uniform(0.72, 1.28) + rng.uniform(-15, 15),
        0,
        255,
    ).astype(np.uint8)
    return warped_logo, warped_alpha


def _overlay(
    canvas: np.ndarray,
    logo: np.ndarray,
    alpha: np.ndarray,
    x: int,
    y: int,
) -> tuple[int, int, int, int]:
    mask = alpha > 18
    rows, columns = np.where(mask)
    if not len(rows):
        raise ValueError("Logo alpha mask is empty.")
    height, width = logo.shape[:2]
    region = canvas[y : y + height, x : x + width]
    blend = (alpha.astype(np.float32) / 255.0)[:, :, None]
    region[:] = (logo * blend + region * (1 - blend)).astype(np.uint8)
    return x + int(columns.min()), y + int(rows.min()), int(columns.max() - columns.min() + 1), int(rows.max() - rows.min() + 1)


def generate(
    logo_path: Path,
    output: Path,
    backgrounds: Path,
    train_count: int,
    val_count: int,
    size: int,
    seed: int,
) -> None:
    rng = random.Random(seed)
    logo, alpha = _load_logo(logo_path)
    sources = _backgrounds(backgrounds)
    max_logo_width = min(
        int(size * 0.72),
        int(size * 0.72 / max(1.25, logo.shape[0] / logo.shape[1] + 0.25)),
    )

    for split, count in (("train", train_count), ("val", val_count)):
        image_dir = output / "images" / split
        label_dir = output / "labels" / split
        if image_dir.exists():
            shutil.rmtree(image_dir)
        if label_dir.exists():
            shutil.rmtree(label_dir)
        image_dir.mkdir(parents=True)
        label_dir.mkdir(parents=True)

        for index in range(count):
            canvas = _make_background(size, sources, rng)
            boxes: list[tuple[int, int, int, int]] = []
            is_negative = rng.random() < 0.20
            if not is_negative:
                for _ in range(1 if rng.random() < 0.88 else 2):
                    target_width = rng.randint(int(size * 0.18), max(64, max_logo_width))
                    transformed, transformed_alpha = _transform_logo(logo, alpha, target_width, rng)
                    height, width = transformed.shape[:2]
                    x = rng.randint(0, max(0, size - width))
                    y = rng.randint(0, max(0, size - height))
                    boxes.append(_overlay(canvas, transformed, transformed_alpha, x, y))

            if rng.random() < 0.35:
                quality = rng.randint(45, 88)
                success, encoded = cv2.imencode(".jpg", canvas, [cv2.IMWRITE_JPEG_QUALITY, quality])
                if success:
                    canvas = cv2.imdecode(encoded, cv2.IMREAD_COLOR)

            name = f"square_{split}_{index:05d}"
            cv2.imwrite(str(image_dir / f"{name}.jpg"), canvas)
            lines = []
            for x, y, width, height in boxes:
                lines.append(
                    "0 "
                    f"{(x + width / 2) / size:.6f} "
                    f"{(y + height / 2) / size:.6f} "
                    f"{width / size:.6f} {height / size:.6f}"
                )
            (label_dir / f"{name}.txt").write_text("\n".join(lines), encoding="utf-8")

    print(
        f"Generated {train_count} train and {val_count} validation images in {output} "
        f"from official template {logo_path.name}."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate augmented Square-logo training data.")
    parser.add_argument("--logo", type=Path, default=DEFAULT_LOGO)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--backgrounds", type=Path, default=DEFAULT_BACKGROUNDS)
    parser.add_argument("--train", type=int, default=400)
    parser.add_argument("--val", type=int, default=80)
    parser.add_argument("--size", type=int, default=512)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    generate(args.logo, args.output, args.backgrounds, args.train, args.val, args.size, args.seed)


if __name__ == "__main__":
    main()
