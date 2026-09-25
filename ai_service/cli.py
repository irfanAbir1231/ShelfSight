from __future__ import annotations

import argparse
import json
from pathlib import Path

from .config import settings
from .engine import ShelfAnalysisEngine


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze shelf photos locally.")
    parser.add_argument("images", nargs="+", type=Path)
    parser.add_argument("--audit-id", default=None)
    args = parser.parse_args()

    payloads = [(path.name, path.read_bytes()) for path in args.images]
    result = ShelfAnalysisEngine(settings).analyze(payloads, audit_id=args.audit_id)
    print(json.dumps(result.model_dump(mode="json"), indent=2))


if __name__ == "__main__":
    main()
