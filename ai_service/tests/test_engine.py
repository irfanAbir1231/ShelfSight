from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np

from ai_service.config import Settings
from ai_service.detectors import (
    RawDetection,
    TemplateLogoMatcher,
    _official_grid_candidates,
    _shelf_grid_detections,
)
from ai_service.engine import ShelfAnalysisEngine


class FixedDetector:
    name = "test-fixed-detector"

    def detect(self, image: np.ndarray) -> list[RawDetection]:
        return [
            RawDetection(20, 20, 120, 180, 0.95),
            RawDetection(170, 20, 120, 180, 0.94),
        ]


def _encode(image: np.ndarray) -> bytes:
    success, payload = cv2.imencode(".png", image)
    assert success
    return payload.tobytes()


def test_engine_counts_logo_matched_product(tmp_path: Path) -> None:
    logos = tmp_path / "logos"
    output = tmp_path / "output"
    logos.mkdir()

    rng = np.random.default_rng(42)
    logo = rng.integers(0, 255, size=(28, 38), dtype=np.uint8)
    cv2.imwrite(str(logos / "square_primary.png"), logo)

    image = np.full((240, 320, 3), 235, dtype=np.uint8)
    image[20:200, 20:140] = (70, 120, 190)
    image[20:200, 170:290] = (130, 180, 80)
    image[60:88, 55:93] = cv2.cvtColor(logo, cv2.COLOR_GRAY2BGR)

    config = Settings(
        logo_directory=logos,
        output_directory=output,
        logo_confidence=0.75,
        uncertain_logo_confidence=0.55,
    )
    engine = ShelfAnalysisEngine(
        config,
        product_detector=FixedDetector(),
        logo_matcher=TemplateLogoMatcher(logos),
    )
    result = engine.analyze([("shelf.png", _encode(image))], audit_id="test-audit")

    assert result.summary.total_facings == 2
    assert result.summary.square_facings == 1
    assert result.summary.other_facings == 1
    assert result.summary.square_share == 50.0
    assert (output / "test-audit_photo_1.jpg").is_file()


def test_official_grid_finds_multiple_logos() -> None:
    image = np.full((360, 640, 3), 245, dtype=np.uint8)

    def draw_logo(left: int, top: int, tile: int) -> None:
        gap = max(2, tile // 4)
        for row in range(3):
            for column in range(3):
                x = left + column * (tile + gap)
                y = top + row * (tile + gap)
                cv2.rectangle(image, (x, y), (x + tile, y + tile), (70, 185, 75), -1)
        grid_size = tile * 3 + gap * 2
        cv2.rectangle(
            image,
            (left, top + grid_size + 3),
            (left + grid_size, top + grid_size + max(5, tile // 2)),
            (30, 30, 235),
            -1,
        )

    draw_logo(80, 70, 14)
    draw_logo(430, 230, 9)

    detections = _official_grid_candidates(image)

    assert len(detections) == 2
    centers = sorted((item.x + item.width // 2, item.y + item.height // 2) for item in detections)
    assert centers[0][0] < 150
    assert centers[1][0] > 400


def test_shelf_grid_counts_each_facing_in_two_rows() -> None:
    image = np.full((600, 800, 3), 35, dtype=np.uint8)
    colours = ((225, 225, 225), (35, 180, 235), (170, 80, 45), (55, 190, 80))
    for row_top, row_bottom in ((0, 280), (335, 570)):
        for column, colour in enumerate(colours):
            left = column * 200
            cv2.rectangle(image, (left, row_top), (left + 198, row_bottom), colour, -1)
            cv2.rectangle(
                image,
                (left + 35, row_top + 60),
                (left + 160, row_bottom - 55),
                tuple(max(0, value - 30) for value in colour),
                3,
            )
    cv2.rectangle(image, (0, 280), (799, 334), (90, 105, 125), -1)

    detections = _shelf_grid_detections(image)

    assert len(detections) == 8
    assert len([item for item in detections if item.y == 0]) == 4
