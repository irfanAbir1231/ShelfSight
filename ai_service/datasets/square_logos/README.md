# Square-logo dataset

Use cropped product images where possible. Put images and YOLO label files in
the same train/validation structure as the product-facing dataset.

Draw a tight class `0` box around each official Square logo. Include difficult
examples: small logos, glare, rotation, partial occlusion, old packaging, and
different Square product families. Include non-Square product crops with empty
label files so the model learns hard negatives.
