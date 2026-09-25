# ShelfSight AI prototype

This service implements the first runnable analysis pipeline:

1. image quality checks;
2. product-facing candidate detection;
3. locally trained HOG/colour matching verified against official-logo SIFT geometry;
4. `square`, `other`, and `uncertain` classification;
5. facing-share calculation;
6. annotated output images and Flutter-friendly normalized boxes.

The included OpenCV contour detector is a development baseline, not a field-
accuracy model. Set `SHELFSIGHT_PRODUCT_MODEL` to trained YOLO weights after the
dataset is annotated. The API and response contract stay unchanged.

## Current official-logo bootstrap

The repository includes a local bootstrap path that needs neither cloud inference
nor PyTorch. It generates augmented examples only from the official Square
green-grid/red-wordmark logo, trains a lightweight HOG/colour classifier, and verifies
every positive with SIFT geometry. Full-image localization is used as a fallback
when the contour product detector cuts the logo out of its candidate boxes.

```powershell
.\.venv-ai\Scripts\python.exe -m ai_service.training.generate_logo_dataset --backgrounds ai_service\assets\clean_backgrounds --train 600 --val 120
.\.venv-ai\Scripts\python.exe -m ai_service.training.validate_dataset ai_service\datasets\square_logos
.\.venv-ai\Scripts\python.exe -m ai_service.training.train_logo_svm
```

The resulting `ai_service/models/square_logo_linear.npz` is loaded automatically.
`/health` reports `trained-official-square-logo-detector` when both the weights
and official template are active.

## Train the production detectors

ShelfSight uses two models in production:

1. `product_facings.pt` finds every visible front-facing package.
2. `square_logo.pt` finds the official Square logo inside each product crop.

Collect and label real shop photos using the YOLO detection format documented in
`datasets/product_facings/README.md` and `datasets/square_logos/README.md`.
Ultralytics labels use one normalized row per box: `class x_center y_center
width height`.

Install the optional training stack, validate labels, and train:

```powershell
.\.venv-ai\Scripts\python.exe -m pip install -r ai_service\requirements-training.txt
.\.venv-ai\Scripts\python.exe -m ai_service.training.validate_dataset ai_service\datasets\product_facings
.\.venv-ai\Scripts\python.exe -m ai_service.training.validate_dataset ai_service\datasets\square_logos
.\.venv-ai\Scripts\python.exe -m ai_service.training.train products
.\.venv-ai\Scripts\python.exe -m ai_service.training.train logos
```

The scripts validate every label before training and copy the best weights into
`ai_service/models`. Restart the API; `/health` will then report
`product_model: true` and `logo_model: true`.

For an MVP dataset, target at least 100-300 varied shelf photos with a separate
validation split. Include hard negatives, glare, old packaging, small logos,
partial occlusion, different camera distances, and non-Square products.

## Setup

```powershell
C:\Python312\python.exe -m venv .venv-ai
.\.venv-ai\Scripts\python.exe -m pip install -r ai_service\requirements.txt
```

Add Square logo templates to `ai_service/assets/logos`, then run:

```powershell
.\.venv-ai\Scripts\python.exe -m uvicorn ai_service.app:app --host 0.0.0.0 --port 8000 --reload
```

API documentation is available at `http://127.0.0.1:8000/docs`.

Analyze from the command line:

```powershell
.\.venv-ai\Scripts\python.exe -m ai_service.cli path\to\shelf.jpg
```

Run tests:

```powershell
.\.venv-ai\Scripts\python.exe -m pytest ai_service\tests
```
