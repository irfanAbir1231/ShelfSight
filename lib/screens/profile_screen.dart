import 'package:flutter/material.dart';

import '../models/coaching.dart';
import '../models/session.dart';
import '../models/visit_history.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'login_screen.dart';
import 'system_states.dart';

/// Identity block shared by both roles.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({super.key, required this.session});
  final UserSession session;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      children: [
        Container(
          width: 68,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.emerald, width: 3),
          ),
          child: Text(
            session.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                  color: AppColors.ink,
                ),
              ),
              Text(
                session.roleLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusPill(
                    label: session.employeeId,
                    icon: Icons.badge_outlined,
                    color: AppColors.ink,
                    background: AppColors.surfaceAlt,
                  ),
                  StatusPill(
                    label: session.territory,
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, indent: 16, endIndent: 16),
          children[i],
        ],
      ],
    ),
  );
}

class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: value,
    onChanged: onChanged,
    activeThumbColor: Colors.white,
    activeTrackColor: AppColors.emeraldDark,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    secondary: Icon(icon, color: AppColors.navy),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    subtitle: subtitle == null ? null : Text(subtitle!),
  );
}

class SettingLink extends StatelessWidget {
  const SettingLink({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    minVerticalPadding: 14,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    leading: Icon(icon, color: AppColors.navy),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
  );
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: OutlinedButton.icon(
      onPressed: () {
        currentSession.value = null;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.red,
        side: const BorderSide(color: AppColors.red, width: 1.5),
        shape: const StadiumBorder(),
      ),
      icon: const Icon(Icons.logout_rounded),
      label: const Text(
        'Log out',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

void showHelpSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  backgroundColor: Colors.white,
  builder: (_) => const SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(22, 0, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Help and support',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'For app or account problems, contact your Territory Officer or '
            'the IT help desk. Include your employee ID.',
            style: TextStyle(height: 1.45),
          ),
        ],
      ),
    ),
  ),
);

/// Sales Officer profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _location = true;
  bool _notifications = true;
  bool _mobileData = false;

  @override
  Widget build(BuildContext context) {
    final session = currentSession.value;
    if (session == null) return const SizedBox.shrink();
    final today = DateTime.now();
    final auditsToday = visitHistory.value
        .where(
          (v) =>
              v.date.year == today.year &&
              v.date.month == today.month &&
              v.date.day == today.day,
        )
        .length;
    final done = coachingProgress.value.values.where((v) => v >= 1).length;
    return FixedHeaderScrollView(
      title: 'Profile',
      subtitle: session.roleLabel,
      slivers: [
        pagePadding([
          ProfileIdentityCard(session: session),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Today’s progress'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  '${visitedToday.value.length}/${DemoData.shops.length}',
                  'Shops visited',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _Metric('$auditsToday', 'Audits completed')),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  '$done/${coachingModules.length}',
                  'Learning',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Settings'),
          const SizedBox(height: 8),
          SettingsGroup(
            children: [
              SettingSwitch(
                icon: Icons.my_location_rounded,
                title: 'Location access',
                subtitle: 'Only while the app is open',
                value: _location,
                onChanged: (v) => setState(() => _location = v),
              ),
              SettingSwitch(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              SettingSwitch(
                icon: Icons.signal_cellular_alt_rounded,
                title: 'Upload on mobile data',
                subtitle: 'Off: photos wait for Wi-Fi',
                value: _mobileData,
                onChanged: (v) => setState(() => _mobileData = v),
              ),
              SettingLink(
                icon: Icons.help_outline_rounded,
                title: 'Help and support',
                onTap: () => showHelpSheet(context),
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

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
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
              letterSpacing: -.5,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12.5, height: 1.25)),
      ],
    ),
  );
}
