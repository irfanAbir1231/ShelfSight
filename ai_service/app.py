from __future__ import annotations

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse

from .config import settings
from .engine import ShelfAnalysisEngine
from .schemas import AnalysisResponse


app = FastAPI(
    title="ShelfSight AI",
    version="0.1.0",
    description="Local product-facing and Square-logo analysis service.",
)
engine = ShelfAnalysisEngine(settings)


@app.get("/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "engine": engine.product_detector.name,
        "product_model": settings.product_model_path is not None,
        "logo_model": settings.logo_model_path is not None,
        "logo_linear_model": settings.logo_linear_path is not None,
        "logo_detector": engine.logo_matcher.name,
        "logo_templates": len(getattr(engine.logo_matcher, "templates", [])),
    }


@app.post("/v1/analyze", response_model=AnalysisResponse)
async def analyze(
    images: list[UploadFile] = File(...),
    audit_id: str | None = Form(default=None),
) -> AnalysisResponse:
    if not images:
        raise HTTPException(status_code=400, detail="At least one image is required.")
    payloads: list[tuple[str, bytes]] = []
    for image in images:
        filename = image.filename or "shelf.jpg"
        suffix = filename.lower().rsplit(".", maxsplit=1)[-1]
        supported_type = image.content_type in {"image/jpeg", "image/png", "image/webp"}
        supported_suffix = suffix in {"jpg", "jpeg", "png", "webp"}
        if not supported_type and not supported_suffix:
            raise HTTPException(status_code=415, detail=f"Unsupported file: {image.filename}")
        payloads.append((filename, await image.read()))
    try:
        return engine.analyze(payloads, audit_id=audit_id)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc


@app.get("/artifacts/{filename}")
def artifact(filename: str) -> FileResponse:
    safe_name = filename.replace("/", "").replace("\\", "")
    path = settings.output_directory / safe_name
    if not path.is_file():
        raise HTTPException(status_code=404, detail="Artifact not found.")
    return FileResponse(path, media_type="image/jpeg")
