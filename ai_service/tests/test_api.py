import cv2
import numpy as np
from fastapi.testclient import TestClient

from ai_service.app import app


client = TestClient(app)


def test_health_reports_engine() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert "engine" in payload


def test_analyze_accepts_camera_jpg_with_generic_content_type() -> None:
    image = np.full((480, 640, 3), 220, dtype=np.uint8)
    encoded, payload = cv2.imencode(".jpg", image)
    assert encoded

    response = client.post(
        "/v1/analyze",
        files={"images": ("scaled_37963.jpg", payload.tobytes(), "application/octet-stream")},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "completed"
