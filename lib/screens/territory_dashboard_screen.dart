import 'dart:async';

import 'package:flutter/material.dart';

import '../models/session.dart';
import '../models/territory_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import '../widgets/state_widgets.dart';
import 'app_shell.dart';
import 'territory_alerts_screen.dart';
import 'territory_map_screen.dart';

enum DashState { loading, ready, noAlerts, noVisits, apiError }

const _amberText = Color(0xFF92580A);

class TerritoryDashboardScreen extends StatefulWidget {
  const TerritoryDashboardScreen({super.key, required this.session});
  final UserSession session;

  @override
  State<TerritoryDashboardScreen> createState() =>
      _TerritoryDashboardScreenState();
}

class _TerritoryDashboardScreenState extends State<TerritoryDashboardScreen> {
  DashState _state = DashState.loading;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _load([DashState next = DashState.ready]) {
    _timer?.cancel();
    setState(() => _state = DashState.loading);
    _timer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _state = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: readAlerts,
      builder: (context, read, _) => FixedHeaderScrollView(
        title: 'Good morning, ${widget.session.firstName}',
        subtitle: '${widget.session.territory} Territory',
        alertCount: unreadAlertCount,
        trailing: PopupMenuButton<DashState>(
          tooltip: 'Demo state (testing only)',
          icon: const Icon(Icons.science_outlined, color: AppColors.inkMuted),
          onSelected: (s) => s == DashState.loading ? _load() : setState(() => _state = s),
          itemBuilder: (_) => const [
            PopupMenuItem(enabled: false, child: Text('Demo state · testing only')),
            PopupMenuItem(value: DashState.ready, child: Text('Normal')),
            PopupMenuItem(value: DashState.loading, child: Text('Loading')),
            PopupMenuItem(value: DashState.noAlerts, child: Text('No alerts')),
            PopupMenuItem(value: DashState.noVisits, child: Text('No visits today')),
            PopupMenuItem(value: DashState.apiError, child: Text('API unavailable')),
          ],
        ),
        slivers: [
          pagePadding(switch (_state) {
            DashState.loading => _skeleton(),
            DashState.apiError => [
              const SizedBox(height: 30),
              StateMessage(
                icon: Icons.cloud_off_rounded,
                tone: StateTone.warning,
                title: 'Dashboard unavailable',
                message:
                    'We could not load territory data. Your saved audits are '
                    'safe. Check your connection and try again.',
                primaryLabel: 'Retry',
                onPrimary: _load,
              ),
            ],
            _ => _content(context, read),
          }),
        ],
      ),
    );
  }

  List<Widget> _skeleton() => [
    const Row(
      children: [
        Expanded(child: SkeletonBox(height: 78, radius: 20)),
        SizedBox(width: 10),
        Expanded(child: SkeletonBox(height: 78, radius: 20)),
      ],
    ),
    const SizedBox(height: 10),
    const Row(
      children: [
        Expanded(child: SkeletonBox(height: 78, radius: 20)),
        SizedBox(width: 10),
        Expanded(child: SkeletonBox(height: 78, radius: 20)),
      ],
    ),
    const SizedBox(height: 14),
    const SkeletonBox(height: 170, radius: 22),
    const SizedBox(height: 22),
    const SkeletonBox(height: 20, width: 140),
    const SizedBox(height: 10),
    const SkeletonBox(height: 96, radius: 20),
    const SizedBox(height: 10),
    const SkeletonBox(height: 96, radius: 20),
  ];

  List<Widget> _content(BuildContext context, Set<String> read) {
    final noVisits = _state == DashState.noVisits;
    final noAlerts = _state == DashState.noAlerts;
    final priority = noAlerts
        ? <TerritoryAlert>[]
        : territoryAlerts.where((a) => !read.contains(a.id)).take(2).toList();
    return [
      Row(
        children: [
          Expanded(
            child: _Summary(Icons.storefront_outlined, '5', 'Assigned shops'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Summary(Icons.groups_outlined, '4', 'Active officers'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _Summary(
              Icons.task_alt_rounded,
              noVisits ? '0' : '7',
              'Visits today',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Summary(
              Icons.swap_horiz_rounded,
              noAlerts ? '0' : '3',
              'Competitive alerts',
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AVERAGE SQUARE SOAP SHARE',
              style: TextStyle(
                color: Color(0xFFB6C2D4),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '42%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Target 50%',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFFB6C2D4)),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 90,
                  height: 44,
                  child: CustomPaint(painter: _SparkPainter()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const StatusPill(
              label: '8 points below target',
              icon: Icons.trending_down_rounded,
              color: _amberText,
              background: AppColors.amberSoft,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      SectionTitle(
        title: 'Priority alerts',
        action: noAlerts ? null : 'View all',
        onAction: () => shellTab.value = 1,
      ),
      const SizedBox(height: 8),
      if (priority.isEmpty)
        const InlineEmpty(
          icon: Icons.notifications_none_rounded,
          title: 'No alerts',
          message: 'You are all caught up. New alerts appear here.',
        ),
      for (final a in priority)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AlertCard(
            alert: a,
            unread: true,
            onTap: () => openAlert(context, a),
          ),
        ),
      const SizedBox(height: 12),
      SurfaceCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TerritoryMapScreen()),
        ),
        child: const Row(
          children: [
            Icon(Icons.map_outlined, color: AppColors.navy),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Territory map',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const SectionTitle(title: 'Today’s activity'),
      const SizedBox(height: 8),
      if (noVisits)
        const InlineEmpty(
          icon: Icons.directions_walk_rounded,
          title: 'No visits yet today',
          message: 'Completed visits will appear here as officers report in.',
        )
      else
        const SurfaceCard(
          child: Column(
            children: [
              _Activity('11:42 AM', 'Arif Rahman completed Samson Center', true),
              _Activity('11:05 AM', 'Sadia Islam started Gulshan Avenue Store', false),
              _Activity('10:15 AM', 'Sadia Islam completed Police Plaza', true),
            ],
          ),
        ),
      const SizedBox(height: 22),
      const SectionTitle(title: 'Shop performance'),
      const SizedBox(height: 8),
      SurfaceCard(
        child: Column(
          children: [
            for (final s in DemoData.shops)
              _ShopShare(
                name: s.name,
                share: territoryShopShares[s.id] ?? 0,
              ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const SectionTitle(title: 'Top Sales Officer'),
      const SizedBox(height: 8),
      SurfaceCard(
        borderColor: AppColors.emeraldDark,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'SI',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sadia Islam',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  Text('3 visits today · Square 48%'),
                ],
              ),
            ),
            const StatusPill(
              label: 'Top',
              icon: Icons.workspace_premium_rounded,
            ),
          ],
        ),
      ),
    ];
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: Row(
      children: [
        Icon(icon, color: AppColors.emeraldDark),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                style: const TextStyle(fontSize: 12.5, height: 1.2),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Activity extends StatelessWidget {
  const _Activity(this.time, this.text, this.done);
  final String time;
  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
          size: 20,
          color: done ? AppColors.emeraldDark : AppColors.inkMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(time, style: const TextStyle(fontSize: 12.5)),
      ],
    ),
  );
}

class _ShopShare extends StatelessWidget {
  const _ShopShare({required this.name, required this.share});
  final String name;
  final int share;

  @override
  Widget build(BuildContext context) {
    final st = statusForShare(share);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        children: [
          Row(
            children: [
              Icon(st.icon, size: 18, color: st.textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '$share%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share / 100,
              minHeight: 7,
              backgroundColor: AppColors.surfaceAlt,
              color: st.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter();
  static const _pts = [38.0, 39.0, 41.0, 40.0, 42.0, 41.0, 42.0];

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < _pts.length; i++) {
      final x = i / (_pts.length - 1) * size.width;
      final y = size.height - (_pts[i] - 36) / 8 * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.emerald,
    );
    canvas.drawCircle(
      Offset(size.width, size.height - (_pts.last - 36) / 8 * size.height),
      4.5,
      Paint()..color = AppColors.emerald,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
