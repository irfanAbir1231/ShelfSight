import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'app_shell.dart';

/// Sales Officer notifications (Territory Officers use the Alerts tab).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = [
    (
      Icons.headphones_rounded,
      'New coaching module assigned',
      'Improving Soap Shelf Visibility · from Nadia Islam',
      '25 min ago',
      true,
    ),
    (
      Icons.cloud_done_outlined,
      'Visit synced',
      'Gulshan Avenue Store audit uploaded',
      'Yesterday',
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      body: FixedHeaderScrollView(
        title: 'Notifications',
        subtitle: '1 unread',
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            for (final (icon, title, detail, time, unread) in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: unread ? AppColors.mint : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: AppColors.emeraldDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight:
                                    unread ? FontWeight.w800 : FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(detail, style: const TextStyle(fontSize: 13.5)),
                            const SizedBox(height: 4),
                            Text(time, style: const TextStyle(fontSize: 12.5)),
                          ],
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
                ),
              ),
          ]),
        ],
      ),
    );
  }
}
