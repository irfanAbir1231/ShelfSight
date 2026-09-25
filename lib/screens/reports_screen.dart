import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'support_screens.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FixedHeaderScrollView(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 3),
              const Text(
                'Shelf presence performance',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportFiltersScreen()),
            ),
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: const Text('30 days'),
          ),
        ],
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 116),
          sliver: SliverList.list(
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AVERAGE SQUARE SHARE',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF163D36),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '↑ 4.2%',
                            style: TextStyle(
                              color: Color(0xFF6EE7B7),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '44.8%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const Text(
                      'Across 38 analyzed stores',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    const SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(painter: _TrendPainter()),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Aug 26',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        Text(
                          'Sep 02',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        Text(
                          'Sep 09',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        Text(
                          'Sep 24',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: _ReportMetric(
                      label: 'AUDITS',
                      value: '142',
                      note: '+12% vs last month',
                      icon: Icons.assignment_turned_in_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _ReportMetric(
                      label: 'COVERAGE',
                      value: '86%',
                      note: '43 of 50 outlets',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Share by category', action: 'Details'),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _ProgressRow(
                        label: 'Food & Beverage',
                        value: 52,
                        color: AppColors.emerald,
                      ),
                      SizedBox(height: 18),
                      _ProgressRow(
                        label: 'Personal Care',
                        value: 46,
                        color: Color(0xFF38BDF8),
                      ),
                      SizedBox(height: 18),
                      _ProgressRow(
                        label: 'Household Care',
                        value: 39,
                        color: Color(0xFF8B5CF6),
                      ),
                      SizedBox(height: 18),
                      _ProgressRow(
                        label: 'Pharmacy',
                        value: 31,
                        color: AppColors.amber,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Area performance'),
              const SizedBox(height: 12),
              const _AreaCard(
                rank: 1,
                area: 'Gulshan & Banani',
                stores: '12 stores',
                share: '51.2%',
                change: '+5.8%',
              ),
              const SizedBox(height: 10),
              const _AreaCard(
                rank: 2,
                area: 'Dhanmondi',
                stores: '9 stores',
                share: '45.6%',
                change: '+2.1%',
              ),
              const SizedBox(height: 10),
              const _AreaCard(
                rank: 3,
                area: 'Mirpur',
                stores: '11 stores',
                share: '37.9%',
                change: '-1.4%',
                negative: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .08)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        grid,
      );
    }
    final points = <Offset>[
      Offset(0, size.height * .78),
      Offset(size.width * .15, size.height * .65),
      Offset(size.width * .30, size.height * .72),
      Offset(size.width * .45, size.height * .48),
      Offset(size.width * .60, size.height * .55),
      Offset(size.width * .75, size.height * .30),
      Offset(size.width, size.height * .18),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.emerald
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xFF6EE7B7));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
  });
  final String label;
  final String value;
  final String note;
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
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkMuted,
                  letterSpacing: .7,
                ),
              ),
              Icon(icon, size: 19, color: AppColors.emeraldDark),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
        ],
      ),
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Text(
            '$value%',
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: value / 100,
          minHeight: 8,
          color: color,
          backgroundColor: AppColors.surfaceAlt,
        ),
      ),
    ],
  );
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.rank,
    required this.area,
    required this.stores,
    required this.share,
    required this.change,
    this.negative = false,
  });
  final int rank;
  final String area;
  final String stores;
  final String share;
  final String change;
  final bool negative;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.mint : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: rank == 1 ? AppColors.emeraldDark : AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(area, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  stores,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(share, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                change,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: negative ? AppColors.red : AppColors.emeraldDark,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
