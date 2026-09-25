from __future__ import annotations

from enum import StrEnum

from pydantic import BaseModel, Field


class DetectionLabel(StrEnum):
    SQUARE = "square"
    OTHER = "other"
    UNCERTAIN = "uncertain"


class BoundingBox(BaseModel):
    x: float = Field(ge=0, le=1)
    y: float = Field(ge=0, le=1)
    width: float = Field(gt=0, le=1)
    height: float = Field(gt=0, le=1)


class PixelBox(BaseModel):
    x: int
    y: int
    width: int
    height: int


class DetectionEvidence(BaseModel):
    logo_detected: bool
    logo_confidence: float = Field(ge=0, le=1)
    logo_template: str | None = None
    detector: str


class ProductDetection(BaseModel):
    id: str
    label: DetectionLabel
    confidence: float = Field(ge=0, le=1)
    box: BoundingBox
    pixel_box: PixelBox
    evidence: DetectionEvidence


class ImageQuality(BaseModel):
    width: int
    height: int
    blur_score: float
    brightness: float
    acceptable: bool
    warnings: list[str] = []


class PhotoAnalysis(BaseModel):
    photo_id: str
    filename: str
    quality: ImageQuality
    detections: list[ProductDetection]
    annotated_image: str


class AnalysisSummary(BaseModel):
    total_facings: int
    square_facings: int
    other_facings: int
    uncertain_facings: int
    square_share: float


class AnalysisResponse(BaseModel):
    audit_id: str
    status: str = "completed"
    summary: AnalysisSummary
    photos: list[PhotoAnalysis]
    warnings: list[str] = []
    engine: str
