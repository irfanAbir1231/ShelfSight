import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../theme/app_theme.dart';

/// One bounding box drawn over an image.
class BoxOverlay {
  const BoxOverlay({
    required this.id,
    required this.box,
    required this.color,
    required this.tag,
    this.selected = false,
    this.dimmed = false,
  });
  final String id;
  final NormalizedBox box;
  final Color color;

  /// Short non-color marker (e.g. "S", "?") so status is not color-only.
  final String tag;
  final bool selected;
  final bool dimmed;
}

/// Image with normalized boxes. The stack is sized to the image's own aspect
/// ratio, so boxes stay aligned to image coordinates at any display size.
class AnnotatedImage extends StatefulWidget {
  const AnnotatedImage({
    super.key,
    this.image,
    this.fallbackAspect = 4 / 3,
    this.fallback,
    this.boxes = const [],
    this.onBoxTap,
    this.radius = 0,
  });

  final ImageProvider? image;

  /// Used when [image] is null (demo artwork) or has not resolved yet.
  final double fallbackAspect;
  final Widget? fallback;
  final List<BoxOverlay> boxes;
  final ValueChanged<String>? onBoxTap;
  final double radius;

  @override
  State<AnnotatedImage> createState() => _AnnotatedImageState();
}

class _AnnotatedImageState extends State<AnnotatedImage> {
  double? _aspect;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    final a = info.image.width / info.image.height;
    if (mounted && a != _aspect) setState(() => _aspect = a);
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant AnnotatedImage old) {
    super.didUpdateWidget(old);
    if (old.image != widget.image) _resolve();
  }

  void _resolve() {
    _stream?.removeListener(_listener);
    final img = widget.image;
    if (img == null) return;
    _stream = img.resolve(createLocalImageConfiguration(context))
      ..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect ?? widget.fallbackAspect;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AspectRatio(
        aspectRatio: aspect,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (widget.image != null)
                  Image(image: widget.image!, fit: BoxFit.fill)
                else
                  widget.fallback ?? const ColoredBox(color: AppColors.navy),
                for (final b in widget.boxes)
                  Positioned(
                    left: b.box.x * w,
                    top: b.box.y * h,
                    width: b.box.width * w,
                    height: b.box.height * h,
                    child: _BoxView(
                      overlay: b,
                      onTap: widget.onBoxTap == null
                          ? null
                          : () => widget.onBoxTap!(b.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BoxView extends StatelessWidget {
  const _BoxView({required this.overlay, this.onTap});
  final BoxOverlay overlay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final o = overlay;
    final opacity = o.dimmed ? .25 : 1.0;
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: o.color, width: o.selected ? 4 : 2.5),
            color: o.color.withValues(alpha: o.selected ? .22 : .08),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: LayoutBuilder(
              builder: (context, c) {
                // Skip the tag when the box is too small to hold it.
                if (math.min(c.maxWidth, c.maxHeight) < 16) {
                  return const SizedBox.shrink();
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: o.color,
                  child: Text(
                    o.tag,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
