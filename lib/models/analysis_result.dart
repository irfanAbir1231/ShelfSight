class AnalysisResult {
  const AnalysisResult({
    required this.auditId,
    required this.summary,
    required this.photos,
    required this.warnings,
    required this.engine,
  });

  final String auditId;
  final AnalysisSummary summary;
  final List<PhotoAnalysis> photos;
  final List<String> warnings;
  final String engine;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
    auditId: json['audit_id'] as String? ?? '',
    summary: AnalysisSummary.fromJson(json['summary'] as Map<String, dynamic>),
    photos: (json['photos'] as List<dynamic>? ?? const [])
        .map((item) => PhotoAnalysis.fromJson(item as Map<String, dynamic>))
        .toList(),
    warnings: (json['warnings'] as List<dynamic>? ?? const []).cast<String>(),
    engine: json['engine'] as String? ?? 'unknown',
  );
}

class AnalysisSummary {
  const AnalysisSummary({
    required this.totalFacings,
    required this.squareFacings,
    required this.otherFacings,
    required this.uncertainFacings,
    required this.squareShare,
  });

  final int totalFacings;
  final int squareFacings;
  final int otherFacings;
  final int uncertainFacings;
  final double squareShare;

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) =>
      AnalysisSummary(
        totalFacings: json['total_facings'] as int? ?? 0,
        squareFacings: json['square_facings'] as int? ?? 0,
        otherFacings: json['other_facings'] as int? ?? 0,
        uncertainFacings: json['uncertain_facings'] as int? ?? 0,
        squareShare: (json['square_share'] as num? ?? 0).toDouble(),
      );
}

class PhotoAnalysis {
  const PhotoAnalysis({
    required this.filename,
    required this.annotatedImage,
    required this.quality,
    required this.detections,
  });

  final String filename;
  final String annotatedImage;
  final ImageQuality quality;
  final List<ProductDetection> detections;

  factory PhotoAnalysis.fromJson(Map<String, dynamic> json) => PhotoAnalysis(
    filename: json['filename'] as String? ?? '',
    annotatedImage: json['annotated_image'] as String? ?? '',
    quality: ImageQuality.fromJson(json['quality'] as Map<String, dynamic>),
    detections: (json['detections'] as List<dynamic>? ?? const [])
        .map((item) => ProductDetection.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

class ImageQuality {
  const ImageQuality({required this.acceptable, required this.warnings});
  final bool acceptable;
  final List<String> warnings;

  factory ImageQuality.fromJson(Map<String, dynamic> json) => ImageQuality(
    acceptable: json['acceptable'] as bool? ?? false,
    warnings: (json['warnings'] as List<dynamic>? ?? const []).cast<String>(),
  );
}

class ProductDetection {
  const ProductDetection({
    required this.id,
    required this.label,
    required this.confidence,
    required this.box,
  });
  final String id;
  final String label;
  final double confidence;
  final NormalizedBox box;

  factory ProductDetection.fromJson(Map<String, dynamic> json) =>
      ProductDetection(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? 'uncertain',
        confidence: (json['confidence'] as num? ?? 0).toDouble(),
        box: NormalizedBox.fromJson(json['box'] as Map<String, dynamic>),
      );
}

class NormalizedBox {
  const NormalizedBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  final double x;
  final double y;
  final double width;
  final double height;

  factory NormalizedBox.fromJson(Map<String, dynamic> json) => NormalizedBox(
    x: (json['x'] as num? ?? 0).toDouble(),
    y: (json['y'] as num? ?? 0).toDouble(),
    width: (json['width'] as num? ?? 0).toDouble(),
    height: (json['height'] as num? ?? 0).toDouble(),
  );
}
