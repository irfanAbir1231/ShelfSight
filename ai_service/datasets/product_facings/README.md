# Product-facing dataset

Put shelf images in `images/train` and `images/val`. Put matching YOLO label
files in `labels/train` and `labels/val`.

Each visible front-facing package gets one class `0` box:

```text
0 x_center y_center width height
```

Coordinates are normalized from 0 to 1. Include partial products when at least
half of the front face is visible. Do not label price tags, shelf strips, or
reflections as products.
