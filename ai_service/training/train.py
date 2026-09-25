from __future__ import annotations

import argparse
import shutil
import tempfile
from pathlib import Path

from .validate_dataset import validate_dataset


ROOT = Path(__file__).resolve().parents[1]
TASKS = {
    "products": (ROOT / "datasets" / "product_facings", "product_facings.pt", "product"),
    "logos": (ROOT / "datasets" / "square_logos", "square_logo.pt", "square_logo"),
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Train a ShelfSight YOLO26 model.")
    parser.add_argument("task", choices=TASKS)
    parser.add_argument("--model", default="yolo26n.pt")
    parser.add_argument("--epochs", type=int, default=100)
    parser.add_argument("--image-size", type=int, default=960)
    parser.add_argument("--batch", type=int, default=-1)
    parser.add_argument("--device", default=None)
    args = parser.parse_args()

    dataset, output_name, class_name = TASKS[args.task]
    reports = validate_dataset(dataset)
    errors = [error for report in reports for error in report.errors]
    if any(report.images == 0 for report in reports):
        errors.append("Both train and val splits need at least one image.")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        raise SystemExit("Dataset validation failed. Fix labels before training.")

    try:
        from ultralytics import YOLO
    except ImportError as exc:
        raise SystemExit(
            "Install training dependencies first: "
            ".venv-ai\\Scripts\\python.exe -m pip install "
            "-r ai_service\\requirements-training.txt"
        ) from exc

    yaml_text = (
        f'path: "{dataset.as_posix()}"\n'
        'train: images/train\n'
        'val: images/val\n'
        'names:\n'
        f'  0: {class_name}\n'
    )
    with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False) as handle:
        handle.write(yaml_text)
        resolved_yaml = Path(handle.name)

    try:
        model = YOLO(args.model)
        result = model.train(
            data=str(resolved_yaml),
            epochs=args.epochs,
            imgsz=args.image_size,
            batch=args.batch,
            device=args.device,
            project=str(ROOT / "models" / "runs"),
            name=args.task,
        )
        best = Path(result.save_dir) / "weights" / "best.pt"
        destination = ROOT / "models" / output_name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(best, destination)
        print(f"Saved deployable weights to {destination}")
    finally:
        resolved_yaml.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
