import 'analysis_result.dart';

/// Marks a photo path as the bundled demo shelf (no camera or server needed).
const demoPhotoPath = 'asset:assets/demo/demo-shelf.jpg';

bool isDemoPhoto(String path) => path.startsWith('asset:');

// Per row: top, height, then [x, width] for each of the four columns.
const _rows = [
  (
    .05,
    .26,
    [
      [.02, .25],
      [.27, .24],
      [.51, .24],
      [.76, .23],
    ],
  ),
  (
    .36,
    .29,
    [
      [.04, .18],
      [.23, .26],
      [.50, .25],
      [.77, .22],
    ],
  ),
  (
    .70,
    .25,
    [
      [.02, .23],
      [.27, .23],
      [.50, .23],
      [.75, .24],
    ],
  ),
];

// 5 Square, 1 uncertain, 6 other.
const _labels = [
  ['square', 'other', 'square', 'other'],
  ['uncertain', 'other', 'square', 'other'],
  ['square', 'other', 'square', 'other'],
];

/// Hand-placed detections for the bundled demo shelf image (4 x 3 grid).
/// Boxes are normalized to the image so they align at any display size.
AnalysisResult buildDemoResult(List<String> paths) {
  final detections = <ProductDetection>[];
  for (var r = 0; r < _rows.length; r++) {
    for (var c = 0; c < 4; c++) {
      final xw = _rows[r].$3[c];
      detections.add(
        ProductDetection(
          id: 'demo_$r$c',
          label: _labels[r][c],
          confidence: _labels[r][c] == 'uncertain' ? .61 : .9,
          box: NormalizedBox(
            x: xw[0],
            y: _rows[r].$1,
            width: xw[1],
            height: _rows[r].$2,
          ),
        ),
      );
    }
  }
  const quality = ImageQuality(acceptable: true, warnings: []);
  final square = detections.where((d) => d.label == 'square').length;
  final uncertain = detections.where((d) => d.label == 'uncertain').length;
  return AnalysisResult(
    auditId: 'demo-audit',
    summary: AnalysisSummary(
      totalFacings: detections.length,
      squareFacings: square,
      otherFacings: detections.length - square - uncertain,
      uncertainFacings: uncertain,
      squareShare: square / detections.length * 100,
    ),
    photos: [
      for (final p in paths)
        PhotoAnalysis(
          filename: 'demo-shelf.jpg',
          annotatedImage: '',
          quality: quality,
          detections: detections,
          localPath: p,
        ),
    ],
    warnings: const [],
    engine: 'demo',
  );
}
