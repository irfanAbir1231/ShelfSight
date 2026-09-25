from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent


def _configured_model(env_name: str, default_name: str) -> Path | None:
    configured = os.getenv(env_name)
    candidate = Path(configured) if configured else ROOT / "models" / default_name
    return candidate if candidate.is_file() else None


@dataclass(frozen=True, slots=True)
class Settings:
    logo_directory: Path = Path(os.getenv("SHELFSIGHT_LOGO_DIR", ROOT / "assets" / "logos"))
    output_directory: Path = Path(os.getenv("SHELFSIGHT_OUTPUT_DIR", ROOT / "output"))
    product_model_path: Path | None = _configured_model(
        "SHELFSIGHT_PRODUCT_MODEL", "product_facings.pt"
    )
    logo_model_path: Path | None = _configured_model(
        "SHELFSIGHT_LOGO_MODEL", "square_logo.pt"
    )
    logo_linear_path: Path | None = _configured_model(
        "SHELFSIGHT_LOGO_LINEAR", "square_logo_linear.npz"
    )
    product_confidence: float = float(os.getenv("SHELFSIGHT_PRODUCT_CONFIDENCE", "0.35"))
    logo_confidence: float = float(os.getenv("SHELFSIGHT_LOGO_CONFIDENCE", "0.78"))
    uncertain_logo_confidence: float = float(
        os.getenv("SHELFSIGHT_UNCERTAIN_LOGO_CONFIDENCE", "0.60")
    )


settings = Settings()
