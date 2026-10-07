import 'package:flutter/material.dart';

import '../models/visit_history.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'visit_completed_screen.dart';

enum _Range { all, today, week }

/// Sales Officer visit history. Square share only; no competitor figures.
class AuditsScreen extends StatefulWidget {
  const AuditsScreen({super.key});

  @override
  State<AuditsScreen> createState() => _AuditsScreenState();
}

class _AuditsScreenState extends State<AuditsScreen> {
  _Range _range = _Range.all;
  String _query = '';

  List<VisitRecord> _visible(List<VisitRecord> all) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return [
      for (final v in all)
        if (v.shopName.toLowerCase().contains(_query.toLowerCase()) &&
            switch (_range) {
              _Range.all => true,
              _Range.today => !v.date.isBefore(startOfToday),
              _Range.week => !v.date.isBefore(
                startOfToday.subtract(const Duration(days: 7)),
              ),
            })
          v,
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<VisitRecord>>(
      valueListenable: visitHistory,
      builder: (context, all, _) {
        final visits = _visible(all);
        return FixedHeaderScrollView(
          title: 'Visit history',
          subtitle: '${all.length} visits recorded',
          slivers: [
            pagePadding([
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search shops',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (r, label) in const [
                      (_Range.all, 'All dates'),
                      (_Range.today, 'Today'),
                      (_Range.week, 'Last 7 days'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _range == r,
                          onSelected: (_) => setState(() => _range = r),
                          avatar: Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: _range == r ? Colors.white : AppColors.ink,
                          ),
                          showCheckmark: false,
                          selectedColor: AppColors.navy,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _range == r ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (visits.isEmpty)
                _Empty(
                  onClear: () => setState(() {
                    _query = '';
                    _range = _Range.all;
                  }),
                ),
              for (final v in visits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VisitCard(
                    visit: v,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VisitSummaryScreen(record: v),
                      ),
                    ),
                  ),
                ),
            ]),
          ],
        );
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.onTap});
  final VisitRecord visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final review = visit.status != 'Completed';
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.shopName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${formatDate(visit.date)} · ${visit.category}',
            style: const TextStyle(fontSize: 13.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusPill(
                label: 'Square ${visit.squareShare}%',
                icon: Icons.pie_chart_outline_rounded,
                color: AppColors.ink,
                background: AppColors.surfaceAlt,
              ),
              StatusPill(
                label: visit.status,
                icon: review
                    ? Icons.visibility_outlined
                    : Icons.check_circle_rounded,
                color: review ? const Color(0xFF92580A) : AppColors.emeraldDark,
                background: review ? AppColors.amberSoft : AppColors.mint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            color: AppColors.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'No visits found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Try a different shop name or date range.',
          textAlign: TextAlign.center,
        ),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: const Text(
            'Clear filters',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
