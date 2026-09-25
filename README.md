# ShelfSight

ShelfSight is a Flutter retail-audit app with a FastAPI/OpenCV backend. A user
captures a shelf photo, the backend identifies visible product facings, detects
products carrying the official Square logo, and returns Square's share of
facings with annotated bounding boxes.

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/irfanAbir1231/ShelfSight)

## Current MVP

- Flutter camera and gallery capture flow
- Multi-image multipart analysis API
- Shelf-row-aware product-facing detection
- Local official Square-logo detection using OpenCV, SIFT geometry, and a
  lightweight trained classifier
- Count-based share: `Square facings / all detected facings * 100`
- Detection review and annotated result screens
- No authentication in the current MVP

## Repository layout

```text
lib/                    Flutter application
ai_service/             FastAPI analysis service
ai_service/models/      Lightweight inference weights
ai_service/assets/      Official logo reference
ai_service/tests/       Backend tests
render.yaml             Render Blueprint
```

## Deploy the backend to Render

The button above creates a Render Blueprint from `render.yaml`. Alternatively,
open Render, create a new Blueprint, and select this repository. The Blueprint
already configures:

- Python 3.12 via `.python-version`
- Singapore region
- Runtime-only Python dependencies
- Uvicorn bound to Render's `$PORT`
- `/health` deployment health check
- Temporary annotated-image storage under `/tmp`

After deployment, verify:

```text
https://YOUR-SERVICE.onrender.com/health
https://YOUR-SERVICE.onrender.com/docs
```

The Blueprint keeps automatic deploys off because it is designed for one-click
deployment. Enable auto-deploy in the Render dashboard if this is your own
service and you want every push to redeploy it.

Render's free web service can sleep after inactivity, so the first analysis
after an idle period can take longer. Generated annotated images are ephemeral;
this is intentional for the MVP because the app fetches them immediately after
analysis.

## Point the Flutter app at Render

The API URL is a compile-time Dart define. Build or run the app using the URL
Render assigns to the service:

```powershell
flutter run --dart-define=SHELFSIGHT_API_URL=https://YOUR-SERVICE.onrender.com
```

For a release APK:

```powershell
flutter build apk --release --dart-define=SHELFSIGHT_API_URL=https://YOUR-SERVICE.onrender.com
```

For USB-based local development, start the backend and reverse port 8000:

```powershell
adb reverse tcp:8000 tcp:8000
flutter run
```

## Run the backend locally

```powershell
py -3.12 -m venv .venv-ai
.\.venv-ai\Scripts\python.exe -m pip install -r ai_service\requirements-dev.txt
.\.venv-ai\Scripts\python.exe -m uvicorn ai_service.app:app --host 0.0.0.0 --port 8000 --reload
```

API documentation is available at `http://127.0.0.1:8000/docs`.

Run backend tests:

```powershell
.\.venv-ai\Scripts\python.exe -m pytest ai_service\tests -q
```

## Run Flutter locally

```powershell
flutter pub get
flutter run
```

## Production accuracy note

The included OpenCV pipeline is an MVP baseline. For diverse real-world stores,
train and configure dedicated product-facing and Square-logo object-detection
models as described in [ai_service/README.md](ai_service/README.md).
