import 'package:flutter/material.dart';

import '../models/audit_flow.dart';
import '../models/session.dart';
import '../models/visit_history.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'app_shell.dart';
import 'visit_screens.dart';

/// Visit completed: records the visit once, then offers home or a summary.
class VisitCompletedScreen extends StatefulWidget {
  const VisitCompletedScreen({
    super.key,
    required this.storeName,
    required this.share,
  });
  final String storeName;
  final double share;

  @override
  State<VisitCompletedScreen> createState() => _VisitCompletedScreenState();
}

class _VisitCompletedScreenState extends State<VisitCompletedScreen> {
  late final DateTime _completedAt = DateTime.now();
  late final int _photos = AuditFlow.current?.photos.value.length ?? 0;
  late final String _duration = _formatDuration();

  String _formatDuration() {
    final start = ActiveVisit.current?.startedAt;
    if (start == null) return '—';
    final m = _completedAt.difference(start).inMinutes;
    return m < 1 ? 'under 1 min' : '$m min';
  }

  @override
  void initState() {
    super.initState();
    // Update shared notifiers after this frame so listeners can rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  void _record() {
    final shop = DemoData.shops.firstWhere(
      (s) => s.name == widget.storeName,
      orElse: () => DemoData.samson,
    );
    visitedToday.value = {...visitedToday.value, shop.id};
    visitHistory.value = [
      VisitRecord(
        shopName: widget.storeName,
        date: _completedAt,
        squareShare: widget.share.round(),
        photos: _photos,
        duration: _duration,
      ),
      ...visitHistory.value,
    ];
    ActiveVisit.current?.step.value = 4;
  }

  void _home() {
    ActiveVisit.current = null;
    AuditFlow.reset();
    shellTab.value = 0;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: FixedHeaderScrollView(
          title: 'Visit completed',
          subtitle: widget.storeName,
          showNavInset: false,
          slivers: [
            pagePadding([
              const SizedBox(height: 8),
              Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, v, child) => Transform.scale(
                    scale: v.clamp(0, 1.2),
                    child: child,
                  ),
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Visit completed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.storeName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15.5),
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                child: Column(
                  children: [
                    _Row('Completed at', formatClock(_completedAt)),
                    _Row('Categories audited', 'Soap'),
                    _Row('Photos submitted', '$_photos'),
                    _Row('Square share recorded', '${widget.share.round()}%'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: StatusPill(
                  label: 'Territory Officer notified',
                  icon: Icons.notifications_active_outlined,
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Return to home',
                icon: Icons.home_rounded,
                onPressed: _home,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VisitSummaryScreen(
                        record: visitHistory.value.first,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy, width: 1.5),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'View visit summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );
}

/// Read-only summary of one visit. Square data only (Sales Officer view).
class VisitSummaryScreen extends StatelessWidget {
  const VisitSummaryScreen({super.key, required this.record});
  final VisitRecord record;

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      activeTab: 1,
      body: FixedHeaderScrollView(
        title: 'Visit summary',
        subtitle: record.shopName,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SurfaceCard(
              child: Column(
                children: [
                  _Row('Date', formatDate(record.date)),
                  _Row('Time', formatClock(record.date)),
                  _Row('Category', record.category),
                  _Row('Photos', '${record.photos}'),
                  _Row('Visit length', record.duration),
                  _Row('Square share', '${record.squareShare}%'),
                  _Row('Status', record.status),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
