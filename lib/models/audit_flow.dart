import 'package:flutter/foundation.dart';

import 'analysis_result.dart';

/// State of the Soap audit in progress, shared by capture, review, analysis
/// and result screens so photos survive retries and navigation.
class AuditFlow {
  AuditFlow(this.shopName);

  final String shopName;
  final ValueNotifier<List<String>> photos = ValueNotifier(<String>[]);
  AnalysisResult? result;

  static AuditFlow? current;

  /// Starts a fresh flow, or resumes the current one for the same shop.
  static AuditFlow forShop(String name) {
    final existing = current;
    if (existing != null && existing.shopName == name) return existing;
    return current = AuditFlow(name);
  }

  static void reset() => current = null;

  void add(Iterable<String> paths) =>
      photos.value = [...photos.value, ...paths];

  void removeAt(int index) {
    final list = [...photos.value]..removeAt(index);
    photos.value = list;
  }

  void replaceAt(int index, String path) {
    final list = [...photos.value];
    list[index] = path;
    photos.value = list;
  }
}

/// Friendly reasons for an image-quality warning from the AI service.
String friendlyQualityReason(String raw) {
  final w = raw.toLowerCase();
  if (w.contains('overexpos') || w.contains('glare')) {
    return 'Strong glare on the shelf';
  }
  if (w.contains('blur')) return 'Product labels are difficult to read';
  if (w.contains('dark')) return 'Photo is too dark';
  if (w.contains('resolution')) return 'Photo resolution is too low';
  return raw;
}
