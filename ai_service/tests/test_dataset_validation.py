from pathlib import Path

from ai_service.training.validate_dataset import validate_dataset


def test_dataset_validator_accepts_normalized_yolo_boxes(tmp_path: Path) -> None:
    for split in ("train", "val"):
        image_dir = tmp_path / "images" / split
        label_dir = tmp_path / "labels" / split
        image_dir.mkdir(parents=True)
        label_dir.mkdir(parents=True)
        (image_dir / f"{split}.jpg").write_bytes(b"image fixture")
        (label_dir / f"{split}.txt").write_text(
            "0 0.5 0.5 0.4 0.6\n", encoding="utf-8"
        )

    reports = validate_dataset(tmp_path)

    assert sum(report.boxes for report in reports) == 2
    assert not [error for report in reports for error in report.errors]


def test_dataset_validator_rejects_out_of_range_box(tmp_path: Path) -> None:
    image_dir = tmp_path / "images" / "train"
    label_dir = tmp_path / "labels" / "train"
    image_dir.mkdir(parents=True)
    label_dir.mkdir(parents=True)
    (image_dir / "bad.jpg").write_bytes(b"image fixture")
    (label_dir / "bad.txt").write_text("0 1.2 0.5 0.4 0.6\n", encoding="utf-8")

    errors = [error for report in validate_dataset(tmp_path) for error in report.errors]

    assert any("within 0..1" in error for error in errors)
