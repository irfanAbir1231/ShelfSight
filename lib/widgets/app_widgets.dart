import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.color = const Color(0xC9111827),
    this.borderColor = const Color(0x29FFFFFF),
    this.blur = 18,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color color;
  final Color borderColor;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

class FixedGlassHeader extends StatelessWidget {
  const FixedGlassHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.zero,
      color: AppColors.headerSurface.withValues(alpha: .78),
      borderColor: Colors.white.withValues(alpha: .7),
      blur: 22,
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
    );
  }
}

class FixedHeaderScrollView extends StatelessWidget {
  const FixedHeaderScrollView({
    super.key,
    required this.header,
    required this.slivers,
  });

  final Widget header;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: slivers,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FixedGlassHeader(child: header),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.backgroundColor = AppColors.navy,
    this.foregroundColor = Colors.white,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: AppColors.border,
        shape: const StadiumBorder(),
      ),
      iconAlignment: IconAlignment.end,
      icon: Icon(icon, size: 21),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.emeraldDark,
    this.background = AppColors.mint,
  });
  final String label;
  final IconData? icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class ShelfArtwork extends StatelessWidget {
  const ShelfArtwork({super.key, this.radius = 20, this.overlay});
  final double radius;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _ShelfPainter()),
        if (overlay != null) overlay!,
      ],
    ),
  );
}

class _ShelfPainter extends CustomPainter {
  const _ShelfPainter();
  static const palette = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF38BDF8),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFFFACC15),
    Color(0xFFFB7185),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF243040),
    );
    final rng = math.Random(7);
    const rows = 5;
    final rowHeight = size.height / rows;
    for (var row = 0; row < rows; row++) {
      final y = row * rowHeight;
      var x = 6.0;
      while (x < size.width - 6) {
        final width = 12 + rng.nextDouble() * 18;
        final top = y + 8 + rng.nextDouble() * 5;
        final safeWidth = math.min(width, size.width - x - 5).toDouble();
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, safeWidth, rowHeight - 15),
          const Radius.circular(2),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = palette[rng.nextInt(palette.length)],
        );
        canvas.drawRect(
          Rect.fromLTWH(
            x + 2,
            top + 3,
            math.max(2, safeWidth - 5).toDouble(),
            2,
          ),
          Paint()..color = Colors.white.withValues(alpha: .65),
        );
        x += width + 3;
      }
      canvas.drawRect(
        Rect.fromLTWH(0, y + rowHeight - 7, size.width, 7),
        Paint()..color = const Color(0xFF0F172A),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, y + rowHeight - 7, size.width, 1),
        Paint()..color = Colors.white.withValues(alpha: .35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}
