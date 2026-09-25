import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'audits_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'store_visit_screen.dart';
import 'support_screens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            const _HomeTab(),
            const AuditsScreen(),
            const ReportsScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: GlassSurface(
        borderRadius: BorderRadius.zero,
        color: AppColors.canvas.withValues(alpha: .18),
        borderColor: Colors.transparent,
        blur: 16,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D0F172A),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: GlassSurface(
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedIndex: _tab,
                onDestinationSelected: (value) => setState(() => _tab = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assignment_outlined),
                    label: 'Audits',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_rounded),
                    label: 'Reports',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 116),
              sliver: SliverList.list(
                children: [
                  Text(
                    'GOOD MORNING',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.inkMuted,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rahim Ahmed',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const StatusPill(
                        label: 'Dhaka North',
                        icon: Icons.circle,
                        background: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _VisitHero(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StoreVisitScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'AUDITS',
                          value: '12',
                          footnote: '+3 this week',
                          icon: Icons.task_alt_rounded,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          label: 'AVG. SHARE',
                          value: '44.8%',
                          footnote: 'Facing share',
                          icon: Icons.donut_large_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search audits or outlets',
                      suffixIcon: Icon(Icons.tune_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle(
                    title: 'Recent audits',
                    action: 'View all',
                  ),
                  const SizedBox(height: 12),
                  const _AuditCard(
                    store: 'Shwapno Super Shop',
                    location: 'Gulshan 2 • Today, 10:15 AM',
                    share: '42%',
                    status: 'Analyzed',
                    good: true,
                  ),
                  const SizedBox(height: 12),
                  const _AuditCard(
                    store: 'Meena Bazar',
                    location: 'Dhanmondi 27 • Yesterday',
                    share: '38%',
                    status: 'Review needed',
                    good: false,
                  ),
                  const SizedBox(height: 12),
                  const _AuditCard(
                    store: 'Agora Superstore',
                    location: 'Banani • Sep 22, 11:10 AM',
                    share: '51%',
                    status: 'Analyzed',
                    good: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FixedGlassHeader(child: _BrandHeader()),
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(16),
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
      const Expanded(
        child: SizedBox(
          height: 46,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ShelfSight',
                style: TextStyle(
                  fontSize: 21,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Retail shelf intelligence',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
      IconButton.filledTonal(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        icon: const Icon(Icons.notifications_none_rounded),
      ),
    ],
  );
}

class _VisitHero extends StatelessWidget {
  const _VisitHero({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22111827),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusPill(
          label: 'SHELF AUDIT',
          icon: Icons.auto_awesome_rounded,
          color: Color(0xFF6EE7B7),
          background: Color(0xFF293445),
        ),
        const SizedBox(height: 20),
        const Text(
          'Start a new store visit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Capture shelf photos and measure Square product-facing share.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .72),
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Start visit',
          icon: Icons.camera_alt_outlined,
          onPressed: onTap,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.navy,
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.footnote,
    required this.icon,
  });
  final String label;
  final String value;
  final String footnote;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
              Icon(icon, size: 19, color: AppColors.emerald),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footnote,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    ),
  );
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({
    required this.store,
    required this.location,
    required this.share,
    required this.status,
    required this.good,
  });
  final String store;
  final String location;
  final String share;
  final String status;
  final bool good;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const SizedBox(
            width: 68,
            height: 68,
            child: ShelfArtwork(radius: 16),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: status,
                      color: good ? AppColors.emeraldDark : Color(0xFFB45309),
                      background: good ? AppColors.mint : Color(0xFFFEF3C7),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Square share  $share',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: good
                        ? AppColors.emeraldDark
                        : const Color(0xFFB45309),
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
