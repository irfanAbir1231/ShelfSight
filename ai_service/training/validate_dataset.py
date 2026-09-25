from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path


IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}


@dataclass(frozen=True, slots=True)
class SplitReport:
    split: str
    images: int
    labels: int
    boxes: int
    errors: list[str]


def validate_dataset(root: Path, class_count: int = 1) -> list[SplitReport]:
    return [_validate_split(root, split, class_count) for split in ("train", "val")]


def _validate_split(root: Path, split: str, class_count: int) -> SplitReport:
    image_dir = root / "images" / split
    label_dir = root / "labels" / split
    images = {
        path.stem: path
        for path in image_dir.glob("*")
        if path.suffix.lower() in IMAGE_SUFFIXES
    }
    labels = {path.stem: path for path in label_dir.glob("*.txt")}
    errors: list[str] = []
    boxes = 0

    for stem, image in images.items():
        label = labels.get(stem)
        if label is None:
            errors.append(f"{image.name}: missing label file (use an empty file for negatives)")
            continue
        for line_number, line in enumerate(label.read_text(encoding="utf-8").splitlines(), 1):
            if not line.strip():
                continue
            parts = line.split()
            if len(parts) != 5:
                errors.append(f"{label.name}:{line_number}: expected 5 values")
                continue
            try:
                class_id = int(parts[0])
                values = [float(value) for value in parts[1:]]
            except ValueError:
                errors.append(f"{label.name}:{line_number}: values must be numeric")
                continue
            if not 0 <= class_id < class_count:
                errors.append(f"{label.name}:{line_number}: invalid class {class_id}")
            if any(value < 0 or value > 1 for value in values):
                errors.append(f"{label.name}:{line_number}: box values must be within 0..1")
            if values[2] <= 0 or values[3] <= 0:
                errors.append(f"{label.name}:{line_number}: width and height must be positive")
            boxes += 1

    for stem, label in labels.items():
        if stem not in images:
            errors.append(f"{label.name}: no matching image")

    return SplitReport(split, len(images), len(labels), boxes, errors)


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate a ShelfSight YOLO dataset.")
    parser.add_argument("dataset", type=Path)
    parser.add_argument("--classes", type=int, default=1)
    args = parser.parse_args()

    reports = validate_dataset(args.dataset.resolve(), args.classes)
    errors = [error for report in reports for error in report.errors]
    for report in reports:
        print(
            f"{report.split}: {report.images} images, "
            f"{report.labels} labels, {report.boxes} boxes"
        )
        for error in report.errors:
            print(f"  ERROR: {error}")
    if any(report.images == 0 for report in reports):
        errors.append("Both train and val splits need at least one image.")
    if errors:
        raise SystemExit(1)
    print("Dataset is ready for training.")


if __name__ == "__main__":
    main()
