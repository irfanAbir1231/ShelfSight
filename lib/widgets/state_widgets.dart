import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_widgets.dart';
import 'shell_widgets.dart';

/// Pulsing placeholder block used by every loading state.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 12});
  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Color.lerp(
          AppColors.surfaceAlt,
          const Color(0xFFDCE5EF),
          _c.value,
        ),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

/// Centered illustration + message + optional actions. One look for every
/// empty, offline, denied and expired state.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = StateTone.neutral,
    this.primaryLabel,
    this.primaryIcon = Icons.refresh_rounded,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });
  final IconData icon;
  final String title;
  final String message;
  final StateTone tone;
  final String? primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      StateTone.neutral => (AppColors.surfaceAlt, AppColors.inkMuted),
      StateTone.positive => (AppColors.mint, AppColors.emeraldDark),
      StateTone.warning => (AppColors.amberSoft, AppColors.amberText),
    };
    return Column(
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 48, color: fg),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            height: 1.25,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, height: 1.45),
        ),
        if (primaryLabel != null) ...[
          const SizedBox(height: 22),
          PrimaryButton(
            label: primaryLabel!,
            icon: primaryIcon,
            onPressed: onPrimary,
          ),
        ],
        if (secondaryLabel != null) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: onSecondary,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: AppColors.navy,
            ),
            child: Text(
              secondaryLabel!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

enum StateTone { neutral, positive, warning }

/// Inline version for sections inside a page.
class InlineEmpty extends StatelessWidget {
  const InlineEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.emeraldDark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(message, style: const TextStyle(fontSize: 14, height: 1.35)),
            ],
          ),
        ),
      ],
    ),
  );
}
