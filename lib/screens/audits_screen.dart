import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'support_screens.dart';

class AuditsScreen extends StatefulWidget {
  const AuditsScreen({super.key});

  @override
  State<AuditsScreen> createState() => _AuditsScreenState();
}

class _AuditsScreenState extends State<AuditsScreen> {
  String _filter = 'All';
  final _filters = const ['All', 'Submitted', 'Review', 'Draft'];

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
              Text('Audits', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 3),
              const Text(
                'Track every shelf visit',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 116),
          sliver: SliverList.list(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: _AuditStat(
                      label: 'THIS MONTH',
                      value: '12',
                      icon: Icons.assignment_turned_in_outlined,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _AuditStat(
                      label: 'TO REVIEW',
                      value: '3',
                      icon: Icons.rate_review_outlined,
                      warning: true,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _AuditStat(
                      label: 'DRAFTS',
                      value: '2',
                      icon: Icons.edit_note_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search store, area, or audit ID',
                  suffixIcon: Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final selected = filter == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: AppColors.navy,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'September 2026',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text(
                    '12 audits',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._visibleAudits.map(
                (audit) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AuditListCard(
                    audit: audit,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AuditDetailScreen(audit: audit),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<AuditPreview> get _visibleAudits {
    if (_filter == 'All') return audits;
    return audits.where((audit) => audit.status == _filter).toList();
  }
}

class AuditPreview {
  const AuditPreview({
    required this.store,
    required this.location,
    required this.date,
    required this.share,
    required this.facings,
    required this.status,
    required this.id,
  });
  final String store;
  final String location;
  final String date;
  final double share;
  final int facings;
  final String status;
  final String id;
}

const audits = [
  AuditPreview(
    store: 'Shwapno Super Shop',
    location: 'Gulshan 2, Dhaka',
    date: 'Today • 10:15 AM',
    share: 42.8,
    facings: 126,
    status: 'Submitted',
    id: 'AUD-24091',
  ),
  AuditPreview(
    store: 'Meena Bazar',
    location: 'Dhanmondi 27, Dhaka',
    date: 'Yesterday • 4:40 PM',
    share: 38.1,
    facings: 94,
    status: 'Review',
    id: 'AUD-24088',
  ),
  AuditPreview(
    store: 'Agora Superstore',
    location: 'Banani, Dhaka',
    date: 'Sep 22 • 11:10 AM',
    share: 51.4,
    facings: 142,
    status: 'Submitted',
    id: 'AUD-24076',
  ),
  AuditPreview(
    store: 'Prince Bazar',
    location: 'Mirpur 1, Dhaka',
    date: 'Sep 21 • 3:05 PM',
    share: 0,
    facings: 0,
    status: 'Draft',
    id: 'AUD-24070',
  ),
];

class _AuditStat extends StatelessWidget {
  const _AuditStat({
    required this.label,
    required this.value,
    required this.icon,
    this.warning = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool warning;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: warning ? AppColors.amber : AppColors.emeraldDark,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.inkMuted,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AuditListCard extends StatelessWidget {
  const _AuditListCard({required this.audit, required this.onTap});
  final AuditPreview audit;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isReview = audit.status == 'Review';
    final isDraft = audit.status == 'Draft';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const SizedBox(
                width: 76,
                height: 82,
                child: ShelfArtwork(radius: 17),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            audit.store,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: audit.status,
                          color: isReview
                              ? const Color(0xFFB45309)
                              : isDraft
                              ? AppColors.inkMuted
                              : AppColors.emeraldDark,
                          background: isReview
                              ? const Color(0xFFFEF3C7)
                              : isDraft
                              ? AppColors.surfaceAlt
                              : AppColors.mint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      audit.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      audit.date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 9),
                    if (isDraft)
                      const Text(
                        'Continue audit',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else
                      Row(
                        children: [
                          Text(
                            '${audit.share}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                          const Text(
                            ' Square share',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${audit.facings} facings',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuditDetailScreen extends StatelessWidget {
  const AuditDetailScreen({super.key, required this.audit});
  final AuditPreview audit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit details'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(audit.store, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          Text(
            '${audit.location}  •  ${audit.id}',
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShelfViewerScreen()),
              ),
              borderRadius: BorderRadius.circular(20),
              child: ShelfArtwork(
                overlay: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: StatusPill(
                      label: audit.status,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SQUARE FACING SHARE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkMuted,
                            letterSpacing: .8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${audit.share}%',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: CircularProgressIndicator(
                      value: audit.share / 100,
                      strokeWidth: 10,
                      backgroundColor: AppColors.surfaceAlt,
                      color: AppColors.emerald,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _DetailMetric(label: 'Square', value: '54'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _DetailMetric(label: 'Other', value: '65'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _DetailMetric(label: 'Corrected', value: '7'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Visit information'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Captured',
                    value: audit.date,
                  ),
                  const Divider(height: 26),
                  const _InfoRow(
                    icon: Icons.photo_library_outlined,
                    label: 'Photos',
                    value: '3 shelf sections',
                  ),
                  const Divider(height: 26),
                  const _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'GPS',
                    value: 'Verified • ±8 m',
                  ),
                  const Divider(height: 26),
                  const _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: 'Food & Beverage',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.inkMuted),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: AppColors.inkMuted)),
      const Spacer(),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
