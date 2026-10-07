import 'dart:io';

import 'package:flutter/widgets.dart';

/// Image provider for a captured photo path. Paths starting with `asset:`
/// are bundled demo photos.
ImageProvider photoProvider(String path, {int? cacheWidth}) {
  final ImageProvider base = path.startsWith('asset:')
      ? AssetImage(path.substring(6))
      : FileImage(File(path));
  return cacheWidth == null ? base : ResizeImage(base, width: cacheWidth);
}
