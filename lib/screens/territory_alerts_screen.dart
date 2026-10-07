import 'package:flutter/material.dart';

import '../models/territory_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import '../widgets/state_widgets.dart';
import 'audit_screens.dart';

/// Opens the audit linked to an alert and marks it read.
void openAlert(BuildContext context, TerritoryAlert a) {
  markAlertRead(a.id);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => a.kind == AlertKind.quality
          ? AnnotatedAuditScreen(alert: a)
          : AuditSummaryScreen(alert: a),
    ),
  );
}

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.unread,
    required this.onTap,
    this.onMarkRead,
  });
  final TerritoryAlert alert;
  final bool unread;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final important = alert.kind.important;
    return SurfaceCard(
      onTap: onTap,
      borderColor: unread && important ? AppColors.red : AppColors.border,
      color: unread ? Colors.white : const Color(0xFFFAFBFD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: important
                  ? AppColors.redSoft
                  : alert.kind == AlertKind.completed
                  ? AppColors.mint
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              alert.kind.icon,
              color: important
                  ? AppColors.red
                  : alert.kind == AlertKind.completed
                  ? AppColors.emeraldDark
                  : AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (unread)
                      const StatusPill(
                        label: 'New',
                        color: Colors.white,
                        background: AppColors.navy,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  alert.shop,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${alert.officer} · ${alert.time}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  alert.detail,
                  style: const TextStyle(fontSize: 13.5, height: 1.35),
                ),
                if (unread && onMarkRead != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onMarkRead,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 44),
                        foregroundColor: AppColors.emeraldDark,
                      ),
                      icon: const Icon(Icons.done_rounded, size: 18),
                      label: const Text(
                        'Mark as read',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Filter { all, competitive, below, quality }

class TerritoryAlertsScreen extends StatefulWidget {
  const TerritoryAlertsScreen({super.key});

  @override
  State<TerritoryAlertsScreen> createState() => _TerritoryAlertsScreenState();
}

class _TerritoryAlertsScreenState extends State<TerritoryAlertsScreen> {
  _Filter _filter = _Filter.all;

  bool _matches(TerritoryAlert a) => switch (_filter) {
    _Filter.all => true,
    _Filter.competitive => a.kind == AlertKind.competitive,
    _Filter.below => a.kind == AlertKind.belowTarget,
    _Filter.quality =>
      a.kind == AlertKind.quality || a.kind == AlertKind.unknownCount,
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: readAlerts,
      builder: (context, read, _) {
        final unread = unreadAlertCount;
        final shown = territoryAlerts.where(_matches).toList();
        return FixedHeaderScrollView(
          title: 'Alerts',
          subtitle: unread == 0 ? 'All caught up' : '$unread unread',
          alertCount: unread,
          slivers: [
            pagePadding([
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (f, label) in const [
                      (_Filter.all, 'All'),
                      (_Filter.competitive, 'Competitive'),
                      (_Filter.below, 'Below target'),
                      (_Filter.quality, 'Quality issues'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          showCheckmark: false,
                          selectedColor: AppColors.navy,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _filter == f ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (unread > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => readAlerts.value = {
                      for (final a in territoryAlerts) a.id,
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      foregroundColor: AppColors.emeraldDark,
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 20),
                    label: const Text(
                      'Mark all as read',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: StateMessage(
                    icon: Icons.notifications_off_outlined,
                    title: 'No alerts here',
                    message: 'Nothing in this category right now.',
                    tone: StateTone.positive,
                  ),
                ),
              for (final group in const ['Today', 'Yesterday'])
                if (shown.any((a) => a.group == group)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Text(
                      group,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                  for (final a in shown.where((a) => a.group == group))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _swipeable(context, a, read),
                    ),
                ],
            ]),
          ],
        );
      },
    );
  }

  /// Swipe either way to mark read. Never deletes.
  Widget _swipeable(BuildContext context, TerritoryAlert a, Set<String> read) {
    final isUnread = !read.contains(a.id);
    final card = AlertCard(
      alert: a,
      unread: isUnread,
      onTap: () => openAlert(context, a),
      onMarkRead: () => markAlertRead(a.id),
    );
    if (!isUnread) return card;
    return Dismissible(
      key: ValueKey('${a.id}-${read.contains(a.id)}'),
      confirmDismiss: (_) async {
        markAlertRead(a.id);
        return false;
      },
      background: _swipeBg(Alignment.centerLeft),
      secondaryBackground: _swipeBg(Alignment.centerRight),
      child: card,
    );
  }

  Widget _swipeBg(Alignment align) => Container(
    alignment: align,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: BoxDecoration(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done_rounded, color: AppColors.emeraldDark),
        SizedBox(width: 6),
        Text(
          'Mark read',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.emeraldDark,
          ),
        ),
      ],
    ),
  );
}
