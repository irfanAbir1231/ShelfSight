import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Percentage ring. The value text sits inside the inner circle with room to
/// spare and scales down instead of touching the stroke.
class ShareRing extends StatelessWidget {
  const ShareRing({
    super.key,
    required this.value,
    required this.label,
    this.size = 220,
    this.stroke = 18,
    this.color = AppColors.emerald,
    this.trackColor = AppColors.border,
    this.textColor = AppColors.ink,
    this.target,
  });

  /// 0..100.
  final double value;
  final String label;
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;
  final Color textColor;

  /// Optional target tick (0..100).
  final double? target;

  @override
  Widget build(BuildContext context) {
    final inner = size - stroke * 2 - 24; // padding from the stroke
    return Semantics(
      label: '$label ${value.round()} percent',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                value: value.clamp(0, 100) / 100,
                stroke: stroke,
                color: color,
                track: trackColor,
                target: target == null ? null : target! / 100,
              ),
            ),
            SizedBox(
              width: inner,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${value.round()}%',
                      style: TextStyle(
                        fontSize: size * .25,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.track,
    this.target,
  });
  final double value;
  final double stroke;
  final Color color;
  final Color track;
  final double? target;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        base..color = color,
      );
    }
    if (target != null) {
      final a = -math.pi / 2 + math.pi * 2 * target!;
      final r = rect.width / 2;
      final c = rect.center;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r - stroke / 2 - 3),
        c + Offset(math.cos(a), math.sin(a)) * (r + stroke / 2 + 3),
        Paint()
          ..color = AppColors.navy
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.target != target || old.color != color;
}
