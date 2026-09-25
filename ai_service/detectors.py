from __future__ import annotations

from dataclasses import dataclass
import math
from pathlib import Path
from typing import Protocol

import cv2
import numpy as np


@dataclass(frozen=True, slots=True)
class RawDetection:
    x: int
    y: int
    width: int
    height: int
    confidence: float

    @property
    def xyxy(self) -> tuple[int, int, int, int]:
        return self.x, self.y, self.x + self.width, self.y + self.height


class ProductDetector(Protocol):
    name: str

    def detect(self, image: np.ndarray) -> list[RawDetection]: ...


class HeuristicFacingDetector:
    """Contour baseline used until a shelf-facing model is trained.

    It is intentionally isolated behind ProductDetector so a YOLO adapter can
    replace it without changing the API or calculation layer.
    """

    name = "opencv-contour-baseline"

    def __init__(self, confidence: float = 0.35) -> None:
        self.confidence = confidence

    def detect(self, image: np.ndarray) -> list[RawDetection]:
        shelf_grid = _shelf_grid_detections(image)
        if shelf_grid:
            return shelf_grid

        height, width = image.shape[:2]
        image_area = height * width
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray, (5, 5), 0)
        edges = cv2.Canny(gray, 45, 135)
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 7))
        closed = cv2.morphologyEx(edges, cv2.MORPH_CLOSE, kernel, iterations=2)
        contours, _ = cv2.findContours(closed, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        candidates: list[RawDetection] = []
        for contour in contours:
            x, y, box_width, box_height = cv2.boundingRect(contour)
            area_ratio = (box_width * box_height) / image_area
            aspect_ratio = box_width / max(box_height, 1)
            if not 0.0008 <= area_ratio <= 0.10:
                continue
            if not 0.25 <= aspect_ratio <= 2.8:
                continue
            if box_width < 18 or box_height < 24:
                continue
            rectangularity = cv2.contourArea(contour) / max(box_width * box_height, 1)
            confidence = min(0.85, 0.35 + rectangularity * 0.5)
            if confidence >= self.confidence:
                candidates.append(RawDetection(x, y, box_width, box_height, confidence))

        return _non_max_suppression(candidates, iou_threshold=0.35)


def _shelf_grid_detections(image: np.ndarray) -> list[RawDetection]:
    """Split a landscape shelf photo into product facings by rows and seams.

    Product packages often merge into one large contour, so contour detection
    alone under-counts them.  A shelf divider supplies the horizontal split and
    strong, well-spaced vertical seams supply the facing boundaries.
    """
    if image.size == 0:
        return []
    height, width = image.shape[:2]
    if width / max(height, 1) < 1.1 or min(width, height) < 320:
        return []

    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    horizontal = np.abs(cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)).mean(axis=1)
    horizontal = np.convolve(horizontal, np.ones(15) / 15, mode="same")
    search_start = int(height * 0.30)
    search_end = int(height * 0.70)
    middle = horizontal[search_start:search_end]
    if middle.size == 0:
        return []
    divider = search_start + int(np.argmax(middle))
    divider_strength = float(horizontal[divider])
    if divider_strength < max(12.0, float(np.median(middle)) * 1.35):
        return []

    row_gap = max(12, int(height * 0.085))
    bottom_margin = max(8, int(height * 0.055))
    rows = (
        (0, max(1, divider - 4)),
        (min(height - 1, divider + row_gap), max(divider + row_gap + 1, height - bottom_margin)),
    )
    detections: list[RawDetection] = []
    for top, bottom in rows:
        if bottom - top < height * 0.20:
            return []
        seams = _row_product_seams(gray[top:bottom], width)
        if len(seams) < 1:
            return []
        cuts = [0, *seams, width]
        row_boxes: list[RawDetection] = []
        for left, right in zip(cuts, cuts[1:]):
            box_width = right - left
            if not width * 0.10 <= box_width <= width * 0.42:
                return []
            row_boxes.append(
                RawDetection(left, top, box_width, bottom - top, 0.78)
            )
        if not 2 <= len(row_boxes) <= 7:
            return []
        detections.extend(row_boxes)
    return detections


def _row_product_seams(row: np.ndarray, image_width: int) -> list[int]:
    vertical = np.abs(cv2.Sobel(row, cv2.CV_32F, 1, 0, ksize=3)).mean(axis=0)
    smooth_width = max(9, int(image_width * 0.015))
    if smooth_width % 2 == 0:
        smooth_width += 1
    vertical = np.convolve(vertical, np.ones(smooth_width) / smooth_width, mode="same")
    radius = max(12, int(image_width * 0.018))
    start = int(image_width * 0.12)
    end = int(image_width * 0.88)
    peaks: list[tuple[float, int]] = []
    for x in range(start, end):
        local = vertical[max(0, x - radius) : min(image_width, x + radius + 1)]
        if local.size and vertical[x] == local.max():
            peaks.append((float(vertical[x]), x))

    minimum_spacing = int(image_width * 0.16)
    selected: list[int] = []
    for _, x in sorted(peaks, reverse=True):
        if all(abs(x - existing) >= minimum_spacing for existing in selected):
            selected.append(x)
    return sorted(selected)


class YoloFacingDetector:
    """Optional production adapter. Install ultralytics and provide trained weights."""

    name = "yolo-facing-detector"

    def __init__(self, weights: Path, confidence: float = 0.35) -> None:
        try:
            from ultralytics import YOLO
        except ImportError as exc:  # pragma: no cover - optional dependency
            raise RuntimeError(
                "Ultralytics is required when SHELFSIGHT_PRODUCT_MODEL is set."
            ) from exc
        self.model = YOLO(str(weights))
        self.confidence = confidence

    def detect(self, image: np.ndarray) -> list[RawDetection]:
        result = self.model.predict(image, conf=self.confidence, verbose=False)[0]
        detections: list[RawDetection] = []
        for box in result.boxes:
            x1, y1, x2, y2 = box.xyxy[0].tolist()
            detections.append(
                RawDetection(
                    x=int(x1),
                    y=int(y1),
                    width=max(1, int(x2 - x1)),
                    height=max(1, int(y2 - y1)),
                    confidence=float(box.conf[0]),
                )
            )
        return detections


def _non_max_suppression(
    detections: list[RawDetection], iou_threshold: float
) -> list[RawDetection]:
    selected: list[RawDetection] = []
    for candidate in sorted(detections, key=lambda item: item.confidence, reverse=True):
        if all(_iou(candidate, existing) < iou_threshold for existing in selected):
            selected.append(candidate)
    return selected


def _iou(first: RawDetection, second: RawDetection) -> float:
    ax1, ay1, ax2, ay2 = first.xyxy
    bx1, by1, bx2, by2 = second.xyxy
    intersection = max(0, min(ax2, bx2) - max(ax1, bx1)) * max(
        0, min(ay2, by2) - max(ay1, by1)
    )
    union = first.width * first.height + second.width * second.height - intersection
    return intersection / union if union else 0.0


@dataclass(frozen=True, slots=True)
class LogoMatch:
    confidence: float
    template_name: str | None


class TemplateLogoMatcher:
    """Multi-scale normalized template matcher applied inside product crops."""

    def __init__(self, template_directory: Path) -> None:
        self.name = "template-logo-matcher"
        self.templates: list[tuple[str, np.ndarray]] = []
        template_directory.mkdir(parents=True, exist_ok=True)
        for path in sorted(template_directory.glob("*")):
            if path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
                continue
            template = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
            if template is not None and min(template.shape[:2]) >= 8:
                self.templates.append((path.stem, template))

    def match(self, crop: np.ndarray) -> LogoMatch:
        if not self.templates or crop.size == 0:
            return LogoMatch(0.0, None)
        gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
        gray = cv2.equalizeHist(gray)
        best_score = 0.0
        best_template: str | None = None

        for name, template in self.templates:
            template = cv2.equalizeHist(template)
            for scale in (0.35, 0.5, 0.7, 0.9, 1.0, 1.15):
                target_width = max(8, int(template.shape[1] * scale))
                target_height = max(8, int(template.shape[0] * scale))
                if target_width >= gray.shape[1] or target_height >= gray.shape[0]:
                    continue
                resized = cv2.resize(template, (target_width, target_height))
                scores = cv2.matchTemplate(gray, resized, cv2.TM_CCOEFF_NORMED)
                score = float(scores.max())
                if score > best_score:
                    best_score = score
                    best_template = name
        return LogoMatch(max(0.0, min(best_score, 1.0)), best_template)


class FeatureLogoMatcher:
    """SIFT geometry matcher trained from official logo reference images."""

    name = "sift-square-logo-detector"

    def __init__(self, template_directory: Path) -> None:
        self.sift = cv2.SIFT_create(nfeatures=1200, contrastThreshold=0.01)
        self.matcher = cv2.BFMatcher(cv2.NORM_L2)
        self.templates: list[
            tuple[str, list[cv2.KeyPoint], np.ndarray, tuple[int, int]]
        ] = []
        for path in sorted(template_directory.glob("*")):
            if path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
                continue
            source = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
            if source is None:
                continue
            if source.shape[2] == 4:
                alpha = source[:, :, 3:4].astype(np.float32) / 255.0
                image = (source[:, :, :3] * alpha + 255 * (1 - alpha)).astype(np.uint8)
            else:
                image = source
            target_width = 640
            target_height = max(1, int(image.shape[0] * target_width / image.shape[1]))
            resized = cv2.resize(image, (target_width, target_height), interpolation=cv2.INTER_CUBIC)
            canvas_height = max(target_height * 3, target_width // 4)
            canvas = np.full((canvas_height, target_width, 3), 255, dtype=np.uint8)
            offset = (canvas_height - target_height) // 2
            canvas[offset : offset + target_height] = resized
            gray = cv2.cvtColor(canvas, cv2.COLOR_BGR2GRAY)
            keypoints, descriptors = self.sift.detectAndCompute(gray, None)
            if descriptors is not None and len(keypoints) >= 6:
                self.templates.append(
                    (path.stem, keypoints, descriptors, (canvas.shape[1], canvas.shape[0]))
                )

    def match(self, crop: np.ndarray) -> LogoMatch:
        return self.locate(crop)[0]

    def locate(self, crop: np.ndarray) -> tuple[LogoMatch, RawDetection | None]:
        if not self.templates or crop.size == 0:
            return LogoMatch(0.0, None), None
        original_height, original_width = crop.shape[:2]
        resize_scale = 1.0
        height, width = crop.shape[:2]
        if width < 420:
            resize_scale = 420 / max(width, 1)
            crop = cv2.resize(
                crop,
                (420, max(1, int(height * resize_scale))),
                interpolation=cv2.INTER_CUBIC,
            )
        gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
        target_keypoints, target_descriptors = self.sift.detectAndCompute(gray, None)
        if target_descriptors is None or len(target_keypoints) < 6:
            return LogoMatch(0.0, None), None

        best_score = 0.0
        best_template: str | None = None
        best_box: RawDetection | None = None
        for name, template_keypoints, template_descriptors, template_size in self.templates:
            pairs = self.matcher.knnMatch(template_descriptors, target_descriptors, k=2)
            good = []
            for pair in pairs:
                if len(pair) != 2:
                    continue
                first, second = pair
                if first.distance < 0.70 * second.distance:
                    good.append(first)
            if len(good) < 4:
                continue
            source_points = np.float32(
                [template_keypoints[item.queryIdx].pt for item in good]
            ).reshape(-1, 1, 2)
            target_points = np.float32(
                [target_keypoints[item.trainIdx].pt for item in good]
            ).reshape(-1, 1, 2)
            matrix, mask = cv2.findHomography(source_points, target_points, cv2.RANSAC, 4.0)
            inliers = int(mask.sum()) if mask is not None else 0
            inlier_ratio = inliers / max(len(good), 1)
            score = min(1.0, inliers / 7.0) * min(1.0, inlier_ratio / 0.65)
            if score > best_score:
                best_score = score
                best_template = name
                best_box = None
                if matrix is not None:
                    template_width, template_height = template_size
                    corners = np.float32(
                        [[0, 0], [template_width, 0], [template_width, template_height], [0, template_height]]
                    ).reshape(-1, 1, 2)
                    projected = cv2.perspectiveTransform(corners, matrix).reshape(-1, 2)
                    x1, y1 = projected.min(axis=0)
                    x2, y2 = projected.max(axis=0)
                    x1 = max(0, min(crop.shape[1] - 1, int(x1)))
                    y1 = max(0, min(crop.shape[0] - 1, int(y1)))
                    x2 = max(x1 + 1, min(crop.shape[1], int(x2)))
                    y2 = max(y1 + 1, min(crop.shape[0], int(y2)))
                    best_box = RawDetection(
                        x=max(0, int(x1 / resize_scale)),
                        y=max(0, int(y1 / resize_scale)),
                        width=max(1, min(original_width, int((x2 - x1) / resize_scale))),
                        height=max(1, min(original_height, int((y2 - y1) / resize_scale))),
                        confidence=best_score,
                    )
        match = LogoMatch(best_score, best_template if best_score >= 0.45 else None)
        return match, best_box if match.template_name else None


def logo_features(image: np.ndarray) -> np.ndarray:
    """Portable HOG + colour descriptor available in OpenCV headless."""
    resized = cv2.resize(image, (128, 32), interpolation=cv2.INTER_AREA)
    gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY).astype(np.float32) / 255.0
    sobel_x = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
    sobel_y = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)
    magnitude = cv2.magnitude(sobel_x, sobel_y)
    angles = (cv2.phase(sobel_x, sobel_y, angleInDegrees=True) % 180.0) / 20.0

    cell_size = 8
    bins = 9
    cells_y = gray.shape[0] // cell_size
    cells_x = gray.shape[1] // cell_size
    histogram = np.zeros((cells_y, cells_x, bins), dtype=np.float32)
    for cell_y in range(cells_y):
        for cell_x in range(cells_x):
            y1, y2 = cell_y * cell_size, (cell_y + 1) * cell_size
            x1, x2 = cell_x * cell_size, (cell_x + 1) * cell_size
            cell_magnitude = magnitude[y1:y2, x1:x2].reshape(-1)
            cell_angles = angles[y1:y2, x1:x2].reshape(-1)
            lower = np.floor(cell_angles).astype(np.int32) % bins
            fraction = cell_angles - np.floor(cell_angles)
            for index in range(cell_magnitude.size):
                histogram[cell_y, cell_x, lower[index]] += cell_magnitude[index] * (1.0 - fraction[index])
                histogram[cell_y, cell_x, (lower[index] + 1) % bins] += cell_magnitude[index] * fraction[index]

    blocks: list[np.ndarray] = []
    for cell_y in range(cells_y - 1):
        for cell_x in range(cells_x - 1):
            block = histogram[cell_y : cell_y + 2, cell_x : cell_x + 2].reshape(-1)
            block /= np.sqrt(float(block @ block) + 1e-6)
            blocks.append(np.minimum(block, 0.2))

    hsv = cv2.cvtColor(resized, cv2.COLOR_BGR2HSV)
    colour_features: list[np.ndarray] = []
    for channel, channel_bins, value_range in ((0, 18, (0, 180)), (1, 8, (0, 256))):
        values = cv2.calcHist([hsv], [channel], None, [channel_bins], list(value_range)).reshape(-1)
        values /= max(float(values.sum()), 1.0)
        colour_features.append(values)
    return np.concatenate((*blocks, *colour_features)).astype(np.float32)


class LinearLogoMatcher:
    """Locally trained linear matcher for the official Square wordmark."""

    name = "trained-square-logo-detector"

    def __init__(self, weights: Path) -> None:
        payload = np.load(weights)
        self.weights = payload["weights"].astype(np.float32)
        self.bias = float(payload["bias"])

    def _score(self, image: np.ndarray) -> float:
        features = logo_features(image).reshape(1, -1)
        margin = float((features @ self.weights).item() + self.bias)
        return 1.0 / (1.0 + math.exp(-max(-20.0, min(20.0, margin))))

    def match(self, crop: np.ndarray) -> LogoMatch:
        if crop.size == 0:
            return LogoMatch(0.0, None)
        height, width = crop.shape[:2]
        best = 0.0
        candidate_widths = sorted(
            {
                max(48, min(width, int(width * scale)))
                for scale in (0.22, 0.32, 0.45, 0.62, 0.82, 1.0)
            }
        )
        for window_width in candidate_widths:
            window_height = max(16, min(height, window_width // 4))
            if window_width > width or window_height > height:
                continue
            step_x = max(10, window_width // 4)
            step_y = max(8, window_height // 2)
            x_positions = list(range(0, width - window_width + 1, step_x))
            y_positions = list(range(0, height - window_height + 1, step_y))
            if not x_positions or x_positions[-1] != width - window_width:
                x_positions.append(width - window_width)
            if not y_positions or y_positions[-1] != height - window_height:
                y_positions.append(height - window_height)
            for y in y_positions:
                for x in x_positions:
                    score = self._score(crop[y : y + window_height, x : x + window_width])
                    best = max(best, score)
                    if best >= 0.995:
                        return LogoMatch(best, "square-logo-svm")
        return LogoMatch(best, "square-logo-svm" if best >= 0.5 else None)


class OfficialSquareLogoMatcher:
    """Verify a trained logo candidate against the official logo geometry."""

    name = "trained-official-square-logo-detector"

    def __init__(self, template_directory: Path, weights: Path) -> None:
        self.feature_matcher = FeatureLogoMatcher(template_directory)
        self.trained_matcher = LinearLogoMatcher(weights)
        self.templates = self.feature_matcher.templates

    def match(self, crop: np.ndarray) -> LogoMatch:
        return self.locate(crop)[0]

    def locate(self, crop: np.ndarray) -> tuple[LogoMatch, RawDetection | None]:
        trained = self.trained_matcher.match(crop)
        geometry, box = self.feature_matcher.locate(crop)
        geometry_confidence = min(1.0, geometry.confidence * 1.5)
        confidence = min(trained.confidence, geometry_confidence)
        template = geometry.template_name if confidence >= 0.45 else None
        return LogoMatch(confidence, template), box if template else None

    def locate_all(self, image: np.ndarray) -> list[tuple[LogoMatch, RawDetection]]:
        """Locate every visible official logo, not only the strongest SIFT match.

        SIFT is retained for perspective/blur tolerance.  A second pass finds the
        distinctive green grid followed by the red SQUARE wordmark, which lets us
        recover smaller repeated logos that a single homography necessarily drops.
        """
        matches: list[tuple[LogoMatch, RawDetection]] = []
        geometry, geometry_box = self.locate(image)
        if geometry_box is not None and geometry.template_name is not None:
            matches.append((geometry, geometry_box))

        for box in _official_grid_candidates(image):
            if any(_same_logo(box, existing_box) for _, existing_box in matches):
                continue
            crop = image[box.y : box.y + box.height, box.x : box.x + box.width]
            trained = self.trained_matcher.match(crop)
            confidence = max(0.90, trained.confidence)
            matches.append(
                (
                    LogoMatch(confidence, "square-official-grid"),
                    RawDetection(box.x, box.y, box.width, box.height, confidence),
                )
            )
        return matches


def _official_grid_candidates(image: np.ndarray) -> list[RawDetection]:
    """Find the official green 3x3 mark with supporting red wordmark pixels."""
    if image.size == 0:
        return []
    height, width = image.shape[:2]
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    green = cv2.inRange(hsv, np.array([35, 55, 45]), np.array([95, 255, 255]))
    red_low = cv2.inRange(hsv, np.array([0, 70, 55]), np.array([12, 255, 255]))
    red_high = cv2.inRange(hsv, np.array([168, 70, 55]), np.array([179, 255, 255]))
    red = cv2.bitwise_or(red_low, red_high)

    min_area = max(36, int(width * height * 0.00012))
    max_area = max(min_area + 1, int(width * height * 0.02))
    candidates: list[RawDetection] = []
    for kernel_size in (3, 5, 7, 9, 11):
        kernel = np.ones((kernel_size, kernel_size), dtype=np.uint8)
        connected = cv2.morphologyEx(green, cv2.MORPH_CLOSE, kernel)
        contours, _ = cv2.findContours(
            connected, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )
        for contour in contours:
            x, y, box_width, box_height = cv2.boundingRect(contour)
            area = box_width * box_height
            aspect = box_width / max(box_height, 1)
            if not min_area <= area <= max_area or not 0.65 <= aspect <= 1.45:
                continue
            green_density = cv2.countNonZero(
                green[y : y + box_height, x : x + box_width]
            ) / max(area, 1)
            if green_density < 0.42:
                continue

            # The official red SQUARE wordmark sits immediately below the grid.
            red_x1 = max(0, x - box_width // 3)
            red_x2 = min(width, x + box_width + box_width // 3)
            red_y1 = min(height, y + box_height)
            red_y2 = min(height, y + box_height * 2)
            red_area = cv2.countNonZero(red[red_y1:red_y2, red_x1:red_x2])
            if red_area < max(6, int(area * 0.018)):
                continue

            candidate = RawDetection(x, y, box_width, box_height, 0.95)
            if not any(_same_logo(candidate, existing) for existing in candidates):
                candidates.append(candidate)
    return candidates


def _same_logo(first: RawDetection, second: RawDetection) -> bool:
    first_center = (first.x + first.width / 2, first.y + first.height / 2)
    second_center = (second.x + second.width / 2, second.y + second.height / 2)
    tolerance = max(first.width, first.height, second.width, second.height) * 0.75
    return (
        abs(first_center[0] - second_center[0]) <= tolerance
        and abs(first_center[1] - second_center[1]) <= tolerance
    )


class YoloLogoMatcher:
    """Trained Square-logo detector applied to individual product crops."""

    name = "yolo-square-logo-detector"

    def __init__(self, weights: Path, confidence: float = 0.10) -> None:
        try:
            from ultralytics import YOLO
        except ImportError as exc:  # pragma: no cover - optional dependency
            raise RuntimeError(
                "Ultralytics is required when SHELFSIGHT_LOGO_MODEL is set."
            ) from exc
        self.model = YOLO(str(weights))
        self.confidence = confidence

    def match(self, crop: np.ndarray) -> LogoMatch:
        if crop.size == 0:
            return LogoMatch(0.0, None)
        result = self.model.predict(crop, conf=self.confidence, verbose=False)[0]
        if result.boxes is None or len(result.boxes) == 0:
            return LogoMatch(0.0, None)
        score = max(float(value) for value in result.boxes.conf.tolist())
        return LogoMatch(max(0.0, min(score, 1.0)), "yolo-square-logo")
