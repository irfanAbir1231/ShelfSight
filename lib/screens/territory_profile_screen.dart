import 'package:flutter/material.dart';

import '../models/session.dart';
import '../models/territory_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'app_shell.dart';
import 'profile_screen.dart';
import 'system_states.dart';

/// Notification toggles shared by the settings screen.
final ValueNotifier<Map<String, bool>> notificationPrefs = ValueNotifier({
  'Competitive shelf updates': true,
  'Square share below target': true,
  'Image-quality warnings': true,
  'Visit completion': false,
  'Coaching completion': false,
  'Quiet hours': false,
});

class TerritoryProfileScreen extends StatelessWidget {
  const TerritoryProfileScreen({super.key});

  void _sheet(BuildContext context, String title, Widget body) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                body,
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final session = currentSession.value;
    if (session == null) return const SizedBox.shrink();
    return FixedHeaderScrollView(
      title: 'Profile',
      subtitle: session.roleLabel,
      slivers: [
        pagePadding([
          ProfileIdentityCard(session: session),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Territory statistics'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Stat('${DemoData.shops.length}', 'Shops')),
              const SizedBox(width: 10),
              Expanded(child: _Stat('${officers.length}', 'Officers')),
              const SizedBox(width: 10),
              const Expanded(child: _Stat('42%', 'Avg Square')),
            ],
          ),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Settings'),
          const SizedBox(height: 8),
          SettingsGroup(
            children: [
              SettingLink(
                icon: Icons.notifications_none_rounded,
                title: 'Notification settings',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
              ),
              SettingLink(
                icon: Icons.tune_rounded,
                title: 'Alert preferences',
                subtitle: 'Target 50% · alert below 45%',
                onTap: () => _sheet(
                  context,
                  'Alert preferences',
                  const Text(
                    'Square share target: 50%\n'
                    'Alert when a shop is below: 45%\n'
                    'Competitor alert when one company exceeds: 35%',
                    style: TextStyle(height: 1.7),
                  ),
                ),
              ),
              SettingLink(
                icon: Icons.sync_rounded,
                title: 'Data sync settings',
                subtitle: 'Last synced just now',
                onTap: () => _sheet(
                  context,
                  'Data sync',
                  const Text(
                    'Territory data refreshes automatically while the app is '
                    'open on Wi-Fi or mobile data.',
                    style: TextStyle(height: 1.45),
                  ),
                ),
              ),
              SettingLink(
                icon: Icons.help_outline_rounded,
                title: 'Help and support',
                onTap: () => showHelpSheet(context),
              ),
              SettingLink(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy and permissions',
                onTap: () => _sheet(
                  context,
                  'Privacy and permissions',
                  const Text(
                    'Location: only while the app is open, to verify visits.\n'
                    'Camera: to capture shelf photos.\n'
                    'Notifications: for alerts you choose.\n\n'
                    'Competitor details are visible to Territory Officers '
                    'only.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SystemStatesDemo(),
          const SizedBox(height: 18),
          const SignOutButton(),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'ShelfSight 1.0.0',
              style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
            ),
          ),
        ]),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    ),
  );
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  static const _icons = {
    'Competitive shelf updates': Icons.swap_horiz_rounded,
    'Square share below target': Icons.trending_down_rounded,
    'Image-quality warnings': Icons.image_search_rounded,
    'Visit completion': Icons.task_alt_rounded,
    'Coaching completion': Icons.headphones_rounded,
    'Quiet hours': Icons.bedtime_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      activeTab: 3,
      body: FixedHeaderScrollView(
        title: 'Notifications',
        subtitle: 'Choose what you are alerted about',
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            ValueListenableBuilder<Map<String, bool>>(
              valueListenable: notificationPrefs,
              builder: (context, prefs, _) => SettingsGroup(
                children: [
                  for (final e in prefs.entries)
                    SettingSwitch(
                      icon: _icons[e.key]!,
                      title: e.key,
                      subtitle: e.key == 'Quiet hours'
                          ? '10:00 PM to 6:00 AM'
                          : null,
                      value: e.value,
                      onChanged: (v) =>
                          notificationPrefs.value = {...prefs, e.key: v},
                    ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
