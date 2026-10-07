import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/shell_widgets.dart';
import 'audits_screen.dart';
import 'learn_screen.dart';
import 'profile_screen.dart';
import 'sales_home_screen.dart';
import 'team_screens.dart';
import 'territory_profile_screen.dart';
import 'territory_alerts_screen.dart';
import 'territory_dashboard_screen.dart';

const salesNav = [
  NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
  NavItem(Icons.assignment_outlined, Icons.assignment_rounded, 'Visits'),
  NavItem(Icons.headphones_outlined, Icons.headphones_rounded, 'Learn'),
  NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
];

const territoryNav = [
  NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
  NavItem(
    Icons.notifications_none_rounded,
    Icons.notifications_rounded,
    'Alerts',
  ),
  NavItem(Icons.groups_outlined, Icons.groups_rounded, 'Team'),
  NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
];

/// Active tab of the role shell. Pushed pages switch tabs through this.
final ValueNotifier<int> shellTab = ValueNotifier(0);

/// Wraps a pushed page with the role's floating glass navigation so the
/// bar stays visible through multi-step flows. Selecting a tab returns to
/// the shell on that tab.
class RoleNavScaffold extends StatelessWidget {
  const RoleNavScaffold({super.key, required this.body, this.activeTab = -1});
  final Widget body;
  final int activeTab;

  @override
  Widget build(BuildContext context) {
    final isSales = currentSession.value?.role != UserRole.territoryOfficer;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingGlassNav(
              items: isSales ? salesNav : territoryNav,
              index: activeTab,
              onChanged: (i) {
                shellTab.value = i;
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Role-based shell: same glass chrome, different destinations.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.session});
  final UserSession session;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool get _isSales => widget.session.role == UserRole.salesOfficer;

  @override
  void initState() {
    super.initState();
    shellTab.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _isSales
        ? <Widget>[
            SalesHomeScreen(session: widget.session),
            const AuditsScreen(),
            const LearnScreen(),
            const ProfileScreen(),
          ]
        : <Widget>[
            TerritoryDashboardScreen(session: widget.session),
            const TerritoryAlertsScreen(),
            const TerritoryTeamScreen(),
            const TerritoryProfileScreen(),
          ];
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, tab, _) => Scaffold(
        backgroundColor: AppColors.canvas,
        body: Stack(
          children: [
            Positioned.fill(child: IndexedStack(index: tab, children: pages)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingGlassNav(
                items: _isSales ? salesNav : territoryNav,
                index: tab,
                onChanged: (i) => shellTab.value = i,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
