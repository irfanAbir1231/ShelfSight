import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/onboarding_widgets.dart';
import '../widgets/shell_widgets.dart';
import '../widgets/state_widgets.dart';
import 'app_shell.dart';
import 'login_screen.dart';
import 'visit_screens.dart';

const _amberText = Color(0xFF92580A);

/// Offline: map tiles unavailable, cached shops visible, captures queue.
/// Does not promise offline maps.
class OfflineStateScreen extends StatefulWidget {
  const OfflineStateScreen({super.key});

  @override
  State<OfflineStateScreen> createState() => _OfflineStateScreenState();
}

class _OfflineStateScreenState extends State<OfflineStateScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _retrying = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Still offline. We will keep trying.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      body: FixedHeaderScrollView(
        title: 'You are offline',
        subtitle: 'Showing saved shops',
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            const SurfaceCard(
              color: AppColors.amberSoft,
              borderColor: AppColors.amber,
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: _amberText),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Map tiles unavailable. Your assigned shops are still '
                      'listed below.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: Color(0xFF6B3F06),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.surfaceAlt),
                    const ShelfPattern(
                      color: AppColors.inkMuted,
                      opacity: .1,
                      rows: 3,
                    ),
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 36,
                            color: AppColors.inkMuted,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Map unavailable offline',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              child: Column(
                children: [
                  for (final s in DemoData.shops)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: AppColors.navy),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SurfaceCard(
              child: Row(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppColors.emeraldDark),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can still capture photos. Audits will upload when '
                      'the connection returns.',
                      style: TextStyle(height: 1.4, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: _retrying ? 'Checking…' : 'Retry connection',
              icon: _retrying ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
              onPressed: _retrying ? null : _retry,
            ),
          ]),
        ],
      ),
    );
  }
}

/// Location denied: explains why, offers settings, shops without GPS.
class LocationDeniedScreen extends StatefulWidget {
  const LocationDeniedScreen({super.key});

  @override
  State<LocationDeniedScreen> createState() => _LocationDeniedScreenState();
}

class _LocationDeniedScreenState extends State<LocationDeniedScreen> {
  bool _showShops = false;
  bool _override = false;

  void _openSettings() => showModalBottomSheet<void>(
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
              'Turn on location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 10),
            Text(
              'Open your phone Settings, choose Apps, then ShelfSight, then '
              'Permissions, and allow Location while using the app.',
              style: TextStyle(height: 1.45),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      activeTab: 0,
      body: FixedHeaderScrollView(
        title: 'Location is off',
        subtitle: _showShops ? 'Assigned shops' : 'Needed to find your shop',
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            if (!_showShops) ...[
              const LocationIllustration(),
              const SizedBox(height: 20),
              const Text(
                'We need your location to find your shop',
                style: TextStyle(
                  fontSize: 22,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ShelfSight uses your location only while the app is open, to '
                'match you to the shop you are visiting. Without it, visits '
                'cannot be started.',
                style: TextStyle(fontSize: 15.5, height: 1.45),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Open app settings',
                icon: Icons.settings_rounded,
                onPressed: _openSettings,
              ),
              TextButton(
                onPressed: () => setState(() => _showShops = true),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.navy,
                ),
                child: const Text(
                  'View shops without location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.inkMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Start visit is off until location is available.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final s in DemoData.shops)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(s.address, style: const TextStyle(fontSize: 13.5)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _override
                                ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          VisitOverviewScreen(shop: s),
                                    ),
                                  )
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              disabledBackgroundColor: AppColors.border,
                              shape: const StadiumBorder(),
                            ),
                            icon: Icon(
                              _override
                                  ? Icons.play_arrow_rounded
                                  : Icons.lock_outline_rounded,
                            ),
                            label: Text(
                              _override ? 'Start visit' : 'Location needed',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  value: _override,
                  onChanged: (v) => setState(() => _override = v),
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.emeraldDark,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Demo override · testing only',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

/// Session expired: sign in again; unsent captures stay on the phone.
class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: FixedHeaderScrollView(
        title: 'Signed out',
        subtitle: 'Please sign in again',
        showNavInset: false,
        slivers: [
          pagePadding([
            const SizedBox(height: 24),
            StateMessage(
              icon: Icons.lock_clock_outlined,
              tone: StateTone.warning,
              title: 'Your session has expired',
              message:
                  'For your security, ShelfSight signs you out after a while. '
                  'Sign in again to continue.',
              primaryLabel: 'Sign in again',
              primaryIcon: Icons.login_rounded,
              onPrimary: () {
                currentSession.value = null;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
            const SizedBox(height: 18),
            const Center(
              child: StatusPill(
                label: 'Unsent photos are kept on this phone',
                icon: Icons.save_outlined,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Demo shortcuts to the shared system states (testing only).
class SystemStatesDemo extends StatelessWidget {
  const SystemStatesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String label, Widget page) => ListTile(
      minVerticalPadding: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: AppColors.inkMuted),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Demo system states · testing only',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          row(Icons.wifi_off_rounded, 'Offline', const OfflineStateScreen()),
          row(
            Icons.location_off_outlined,
            'Location denied',
            const LocationDeniedScreen(),
          ),
          row(
            Icons.lock_clock_outlined,
            'Session expired',
            const SessionExpiredScreen(),
          ),
        ],
      ),
    );
  }
}
