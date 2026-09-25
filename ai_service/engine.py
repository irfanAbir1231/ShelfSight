from __future__ import annotations

import uuid
from pathlib import Path

import cv2
import numpy as np

from .config import Settings
from .detectors import (
    HeuristicFacingDetector,
    FeatureLogoMatcher,
    LinearLogoMatcher,
    OfficialSquareLogoMatcher,
    ProductDetector,
    RawDetection,
    TemplateLogoMatcher,
    YoloFacingDetector,
    YoloLogoMatcher,
)
from .schemas import (
    AnalysisResponse,
    AnalysisSummary,
    BoundingBox,
    DetectionEvidence,
    DetectionLabel,
    ImageQuality,
    PhotoAnalysis,
    PixelBox,
    ProductDetection,
)


class ShelfAnalysisEngine:
    def __init__(
        self,
        settings: Settings,
        product_detector: ProductDetector | None = None,
        logo_matcher: TemplateLogoMatcher | FeatureLogoMatcher | YoloLogoMatcher | LinearLogoMatcher | OfficialSquareLogoMatcher | None = None,
    ) -> None:
        self.settings = settings
        self.settings.output_directory.mkdir(parents=True, exist_ok=True)
        if product_detector is not None:
            self.product_detector = product_detector
        elif settings.product_model_path:
            self.product_detector = YoloFacingDetector(
                settings.product_model_path, settings.product_confidence
            )
        else:
            self.product_detector = HeuristicFacingDetector(settings.product_confidence)
        if logo_matcher is not None:
            self.logo_matcher = logo_matcher
        elif settings.logo_model_path:
            self.logo_matcher = YoloLogoMatcher(
                settings.logo_model_path,
                min(settings.uncertain_logo_confidence, 0.25),
            )
        elif settings.logo_linear_path:
            self.logo_matcher = OfficialSquareLogoMatcher(
                settings.logo_directory,
                settings.logo_linear_path,
            )
        else:
            self.logo_matcher = FeatureLogoMatcher(settings.logo_directory)

    def analyze(
        self, images: list[tuple[str, bytes]], audit_id: str | None = None
    ) -> AnalysisResponse:
        audit_id = audit_id or f"audit_{uuid.uuid4().hex[:12]}"
        photos: list[PhotoAnalysis] = []
        warnings: list[str] = []

        if isinstance(
            self.logo_matcher,
            (TemplateLogoMatcher, FeatureLogoMatcher, OfficialSquareLogoMatcher),
        ) and not self.logo_matcher.templates:
            warnings.append(
                "No Square logo templates are loaded; detections will be classified as other."
            )
        if isinstance(self.product_detector, HeuristicFacingDetector):
            warnings.append(
                "Using contour baseline; train and configure a shelf-facing model for field accuracy."
            )

        for index, (filename, payload) in enumerate(images, start=1):
            image = cv2.imdecode(np.frombuffer(payload, dtype=np.uint8), cv2.IMREAD_COLOR)
            if image is None:
                raise ValueError(f"Unable to decode image: {filename}")
            photos.append(self._analyze_photo(audit_id, index, filename, image))

        detections = [item for photo in photos for item in photo.detections]
        square = sum(item.label == DetectionLabel.SQUARE for item in detections)
        uncertain = sum(item.label == DetectionLabel.UNCERTAIN for item in detections)
        other = sum(item.label == DetectionLabel.OTHER for item in detections)
        total = len(detections)
        share = round((square / total * 100) if total else 0.0, 2)

        return AnalysisResponse(
            audit_id=audit_id,
            summary=AnalysisSummary(
                total_facings=total,
                square_facings=square,
                other_facings=other,
                uncertain_facings=uncertain,
                square_share=share,
            ),
            photos=photos,
            warnings=warnings,
            engine=self.product_detector.name,
        )

    def _analyze_photo(
        self, audit_id: str, index: int, filename: str, image: np.ndarray
    ) -> PhotoAnalysis:
        height, width = image.shape[:2]
        quality = _quality(image)
        raw_detections = self.product_detector.detect(image)
        if isinstance(self.logo_matcher, OfficialSquareLogoMatcher):
            for full_logo, logo_box in self.logo_matcher.locate_all(image):
                if (
                    full_logo.confidence >= self.settings.logo_confidence
                    and not any(_contains(item, logo_box) for item in raw_detections)
                ):
                    raw_detections.append(_fit_product_box(image, logo_box))
        detections: list[ProductDetection] = []

        for item_index, raw in enumerate(raw_detections, start=1):
            crop = image[raw.y : raw.y + raw.height, raw.x : raw.x + raw.width]
            logo = self.logo_matcher.match(crop)
            if logo.confidence >= self.settings.logo_confidence:
                label = DetectionLabel.SQUARE
            elif logo.confidence >= self.settings.uncertain_logo_confidence:
                label = DetectionLabel.UNCERTAIN
            else:
                label = DetectionLabel.OTHER
            classification_confidence = (
                logo.confidence if label != DetectionLabel.OTHER else raw.confidence
            )
            detections.append(
                ProductDetection(
                    id=f"{audit_id}_p{index}_{item_index}",
                    label=label,
                    confidence=round(classification_confidence, 4),
                    box=_normalize(raw, width, height),
                    pixel_box=PixelBox(
                        x=raw.x, y=raw.y, width=raw.width, height=raw.height
                    ),
                    evidence=DetectionEvidence(
                        logo_detected=label != DetectionLabel.OTHER,
                        logo_confidence=round(logo.confidence, 4),
                        logo_template=logo.template_name,
                        detector=self.logo_matcher.name,
                    ),
                )
            )

        annotated = _annotate(image.copy(), detections)
        output_name = f"{audit_id}_photo_{index}.jpg"
        output_path = self.settings.output_directory / output_name
        cv2.imwrite(str(output_path), annotated)
        return PhotoAnalysis(
            photo_id=f"{audit_id}_photo_{index}",
            filename=filename,
            quality=quality,
            detections=detections,
            annotated_image=f"/artifacts/{output_name}",
        )


def _quality(image: np.ndarray) -> ImageQuality:
    height, width = image.shape[:2]
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blur_score = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    brightness = float(gray.mean())
    warnings: list[str] = []
    if min(width, height) < 720:
        warnings.append("Image resolution is below the recommended 720px minimum.")
    if blur_score < 65:
        warnings.append("Image may be blurry.")
    if brightness < 45:
        warnings.append("Image is too dark.")
    elif brightness > 220:
        warnings.append("Image may be overexposed.")
    return ImageQuality(
        width=width,
        height=height,
        blur_score=round(blur_score, 2),
        brightness=round(brightness, 2),
        acceptable=not warnings,
        warnings=warnings,
    )


def _normalize(raw: RawDetection, width: int, height: int) -> BoundingBox:
    return BoundingBox(
        x=round(raw.x / width, 6),
        y=round(raw.y / height, 6),
        width=round(raw.width / width, 6),
        height=round(raw.height / height, 6),
    )


def _contains(product: RawDetection, logo: RawDetection) -> bool:
    center_x = logo.x + logo.width / 2
    center_y = logo.y + logo.height / 2
    return (
        product.width >= max(32, logo.width * 2)
        and product.height >= max(32, logo.height * 2)
        and
        product.x <= center_x <= product.x + product.width
        and product.y <= center_y <= product.y + product.height
    )


def _fit_product_box(image: np.ndarray, logo: RawDetection) -> RawDetection:
    """Snap a logo match to the smallest plausible package contour around it."""
    image_height, image_width = image.shape[:2]
    center_x = logo.x + logo.width / 2
    center_y = logo.y + logo.height / 2
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(cv2.GaussianBlur(gray, (5, 5), 0), 35, 110)
    contours, _ = cv2.findContours(edges, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    candidates: list[RawDetection] = []
    for contour in contours:
        x, y, width, height = cv2.boundingRect(contour)
        if not (x <= center_x <= x + width and y <= center_y <= y + height):
            continue
        if width < image_width * 0.08 or height < image_height * 0.12:
            continue
        area_ratio = width * height / max(image_width * image_height, 1)
        aspect_ratio = width / max(height, 1)
        if not 0.008 <= area_ratio <= 0.35 or not 0.30 <= aspect_ratio <= 2.4:
            continue
        candidates.append(RawDetection(x, y, width, height, logo.confidence))
    if candidates:
        return min(candidates, key=lambda item: item.width * item.height)

    target_width = min(
        image_width,
        max(logo.width, logo.height * 3, image_width // 6),
    )
    target_height = min(image_height, max(logo.height * 4, int(target_width * 1.15)))
    center_x = logo.x + logo.width // 2
    center_y = logo.y + logo.height // 2
    x = max(0, min(image_width - target_width, center_x - target_width // 2))
    y = max(0, min(image_height - target_height, center_y - target_height // 2))
    return RawDetection(
        x=int(x),
        y=int(y),
        width=int(target_width),
        height=int(target_height),
        confidence=logo.confidence,
    )


def _annotate(image: np.ndarray, detections: list[ProductDetection]) -> np.ndarray:
    colors = {
        DetectionLabel.SQUARE: (80, 185, 40),
        DetectionLabel.OTHER: (180, 180, 180),
        DetectionLabel.UNCERTAIN: (11, 158, 245),
    }
    for detection in detections:
        box = detection.pixel_box
        color = colors[detection.label]
        cv2.rectangle(image, (box.x, box.y), (box.x + box.width, box.y + box.height), color, 2)
        text = f"{detection.label.value} {detection.confidence:.2f}"
        cv2.rectangle(image, (box.x, max(0, box.y - 20)), (box.x + 120, box.y), color, -1)
        cv2.putText(image, text, (box.x + 3, max(13, box.y - 5)), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (20, 20, 20), 1, cv2.LINE_AA)
    return image
