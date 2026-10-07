import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/session.dart';
import '../screens/app_shell.dart' show shellTab;
import '../screens/notifications_screen.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

/// Fixed glass header: logo, title (+ optional subtitle), bell. Never scrolls.
class ShelfSightHeader extends StatelessWidget {
  const ShelfSightHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.alertCount = 0,
    this.unreadDot = false,
    this.onBack,
  });

  static const double height = 68;

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final int alertCount;
  final bool unreadDot;
  final VoidCallback? onBack;

  /// Total height including the status bar, for scroll-content top padding.
  static double totalHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top + height;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return GlassSurface(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      color: Colors.white.withValues(alpha: .72),
      borderColor: Colors.white.withValues(alpha: .8),
      blur: 22,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top + 8, 12, 8),
        child: SizedBox(
          height: height - 16,
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 48),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.ink,
                  ),
                ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/branding/shelfsight-logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.1,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  if (currentSession.value?.role == UserRole.territoryOfficer) {
                    shellTab.value = 1;
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  }
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: AppColors.surfaceAlt,
                ),
                icon: Badge(
                  isLabelVisible: alertCount > 0 || unreadDot,
                  label: alertCount > 0 ? Text('$alertCount') : null,
                  backgroundColor: AppColors.red,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem {
  const NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating glass bottom navigation with side margins and rounded edges.
class FloatingGlassNav extends StatelessWidget {
  const FloatingGlassNav({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  static const double height = 68;
  static double totalHeight(BuildContext context) =>
      height + math.max(MediaQuery.paddingOf(context).bottom, 8.0) + 8;

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 8.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330B1426),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(26),
          color: AppColors.navy.withValues(alpha: .84),
          blur: 20,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: items[i],
                      selected: i == index,
                      onTap: () => onChanged(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? AppColors.emerald : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 24,
                  color: selected ? AppColors.navy : Colors.white,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.navy : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scroll page under the fixed glass header. Content blurs behind the header
/// and the shell-provided floating nav.
class FixedHeaderScrollView extends StatelessWidget {
  const FixedHeaderScrollView({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.alertCount = 0,
    this.onBack,
    this.showNavInset = true,
    required this.slivers,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final int alertCount;
  final VoidCallback? onBack;
  final bool showNavInset;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: ShelfSightHeader.totalHeight(context) + 12,
              ),
            ),
            ...slivers,
            SliverToBoxAdapter(
              child: SizedBox(
                height: showNavInset
                    ? FloatingGlassNav.totalHeight(context) + 12
                    : 24 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ShelfSightHeader(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            alertCount: alertCount,
            onBack: onBack,
          ),
        ),
      ],
    );
  }
}

/// Standard horizontal page padding sliver.
SliverPadding pagePadding(List<Widget> children) => SliverPadding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  sliver: SliverList.list(children: children),
);

/// White rounded surface used for every content block.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = Colors.white,
    this.borderColor = AppColors.border,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0B1426),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
