import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../models/territory_data.dart';
import '../theme/app_theme.dart';
import '../widgets/annotated_image.dart';
import '../widgets/app_widgets.dart';
import '../widgets/share_ring.dart';
import '../widgets/shell_widgets.dart';
import 'app_shell.dart';
import 'team_screens.dart';

const _amberText = Color(0xFF92580A);

/// Territory screen 2: full competitive audit summary.
class AuditSummaryScreen extends StatelessWidget {
  const AuditSummaryScreen({super.key, required this.alert});
  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context) {
    final share = DemoAudit.squareShare;
    return RoleNavScaffold(
      activeTab: 1,
      body: FixedHeaderScrollView(
        title: 'Audit summary',
        subtitle: DemoAudit.shop,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DemoAudit.shop,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DemoAudit.officer} · Today ${DemoAudit.timeLabel} · '
                    '${DemoAudit.category}',
                  ),
                  const SizedBox(height: 10),
                  const StatusPill(
                    label: 'Visit location verified',
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              child: Column(
                children: [
                  ShareRing(
                    value: share,
                    label: 'Square share',
                    size: 190,
                    stroke: 16,
                    color: CompanyColors.square,
                    target: DemoAudit.targetShare,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: _Mini('Total facings', '20')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Mini(
                          'Target',
                          '${DemoAudit.targetShare.round()}%',
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: _Mini('Gap', '10 pts', warning: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const StatusPill(
                    label: 'Below target',
                    icon: Icons.trending_down_rounded,
                    color: _amberText,
                    background: AppColors.amberSoft,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Company breakdown'),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                children: [
                  _StackedBar(companies: DemoAudit.companies),
                  const SizedBox(height: 14),
                  for (final c in DemoAudit.companies)
                    _CompanyRow(
                      c: c,
                      isSquare: c.company == 'Square Toiletries',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Full brand breakdown',
              icon: Icons.list_alt_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BrandBreakdownScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _Outlined(
              label: 'View annotated image',
              icon: Icons.image_search_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnnotatedAuditScreen(alert: alert),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _Outlined(
              label: 'Recommended follow-up',
              icon: Icons.assignment_turned_in_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TerritoryActionScreen(alert: alert),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Outlined extends StatelessWidget {
  const _Outlined({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.navy, width: 1.5),
        shape: const StadiumBorder(),
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value, {this.warning = false});
  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: warning ? AppColors.amberSoft : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
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

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.companies});
  final List<CompanyFinding> companies;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Company share bar',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            for (final c in companies)
              Expanded(
                flex: c.facings,
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  color: CompanyColors.of(c.company),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _CompanyRow extends StatelessWidget {
  const _CompanyRow({required this.c, required this.isSquare});
  final CompanyFinding c;
  final bool isSquare;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: CompanyColors.of(c.company),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            c.company,
            style: TextStyle(
              fontWeight: isSquare ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(
          '${c.facings} facings',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 44,
          child: Text(
            '${c.sharePercent(DemoAudit.total).round()}%',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Territory screen 3: company accordion with brands and confidence.
class BrandBreakdownScreen extends StatelessWidget {
  const BrandBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      activeTab: 1,
      body: FixedHeaderScrollView(
        title: 'Brand breakdown',
        subtitle: '${DemoAudit.shop} · ${DemoAudit.total} facings',
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            for (final c in DemoAudit.companies)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompanyTile(c: c),
              ),
            const SizedBox(height: 4),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: AppColors.inkMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Brands come from logo matching on detected facings. Not '
                    'every physical product or variant is recognized, so '
                    'treat counts as estimates.',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.c});
  final CompanyFinding c;

  @override
  Widget build(BuildContext context) {
    final avg =
        c.brands.fold<double>(0, (s, b) => s + b.confidence * b.facings) /
        c.facings;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          initiallyExpanded: c.company == 'Square Toiletries',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: CompanyColors.of(c.company),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          title: Text(
            c.company,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            '${c.facings} facings · ${c.sharePercent(DemoAudit.total).round()}% · '
            '${(avg * 100).round()}% avg confidence',
            style: const TextStyle(fontSize: 13),
          ),
          children: [
            for (final b in c.brands)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.brand,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text('${b.facings} facing${b.facings == 1 ? '' : 's'}'),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(b.confidence * 100).round()}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: b.confidence < .6
                              ? _amberText
                              : AppColors.ink,
                        ),
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
}

class _DemoBox {
  const _DemoBox(this.id, this.company, this.brand, this.confidence, this.box);
  final String id;
  final String company;
  final String brand;
  final double confidence;
  final NormalizedBox box;
}

String _tagFor(String company) => switch (company) {
  'Square Toiletries' => 'SQ',
  'Unilever' => 'UN',
  'Reckitt' => 'RK',
  'Keya Cosmetics' => 'KY',
  _ => '?',
};

/// 20 demo detections over a 4-shelf layout, in company order.
List<_DemoBox> _demoBoxes() {
  final order = <(String, String, double)>[
    for (final c in DemoAudit.companies)
      for (final b in c.brands)
        for (var i = 0; i < b.facings; i++) (c.company, b.brand, b.confidence),
  ];
  // Interleave so companies are mixed across shelves.
  final mixed = <(String, String, double)>[];
  for (var i = 0; i < order.length; i++) {
    mixed.add(order[(i * 7) % order.length]);
  }
  return [
    for (var i = 0; i < mixed.length; i++)
      _DemoBox(
        'd$i',
        mixed[i].$1,
        mixed[i].$2,
        mixed[i].$3,
        NormalizedBox(
          x: .04 + (i % 5) * .19,
          y: .06 + (i ~/ 5) * .235,
          width: .16,
          height: .19,
        ),
      ),
  ];
}

/// Territory screen 4: annotated image with zoom, legend and corrections.
class AnnotatedAuditScreen extends StatefulWidget {
  const AnnotatedAuditScreen({super.key, required this.alert});
  final TerritoryAlert alert;

  @override
  State<AnnotatedAuditScreen> createState() => _AnnotatedAuditScreenState();
}

class _AnnotatedAuditScreenState extends State<AnnotatedAuditScreen> {
  final _boxes = _demoBoxes();
  final _verdicts = <String, String>{};
  int _photo = 0;
  String? _selectedId;
  bool _flagging = false;

  List<_DemoBox> get _inPhoto =>
      _photo == 0 ? _boxes.sublist(0, 12) : _boxes.sublist(12);

  _DemoBox? get _selected {
    for (final b in _boxes) {
      if (b.id == _selectedId) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    return RoleNavScaffold(
      activeTab: 1,
      body: FixedHeaderScrollView(
        title: 'Annotated image',
        subtitle: DemoAudit.shop,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < 2; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Photo ${i + 1}'),
                        selected: _photo == i,
                        onSelected: (_) => setState(() {
                          _photo = i;
                          _selectedId = null;
                          _flagging = false;
                        }),
                        showCheckmark: false,
                        selectedColor: AppColors.navy,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _photo == i ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: AnnotatedImage(
                  fallback: const ShelfArtwork(radius: 0),
                  fallbackAspect: 4 / 3,
                  boxes: [
                    for (final b in _inPhoto)
                      BoxOverlay(
                        id: b.id,
                        box: b.box,
                        color: CompanyColors.of(b.company),
                        tag: _tagFor(b.company),
                        selected: b.id == _selectedId,
                      ),
                  ],
                  onBoxTap: (id) => setState(() {
                    _selectedId = id;
                    _flagging = false;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.pinch_outlined, size: 18, color: AppColors.inkMuted),
                SizedBox(width: 6),
                Text(
                  'Pinch to zoom, drag to pan, tap a box',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final c in DemoAudit.companies)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        color: CompanyColors.of(c.company),
                        child: Text(
                          _tagFor(c.company),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: c.company == 'Other / Unknown'
                                ? AppColors.ink
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.company,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              child: sel == null
                  ? const Row(
                      children: [
                        Icon(Icons.touch_app_outlined, color: AppColors.inkMuted),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Select a box to see the detected company'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: CompanyColors.of(sel.company),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${sel.company} · ${sel.brand}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence ${(sel.confidence * 100).round()}%'
                          '${_verdicts[sel.id] == null ? '' : ' · Marked: ${_verdicts[sel.id]}'}',
                        ),
                        const SizedBox(height: 8),
                        if (!_flagging)
                          TextButton.icon(
                            onPressed: () => setState(() => _flagging = true),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 44),
                              foregroundColor: AppColors.navy,
                            ),
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text(
                              'Flag incorrect detection',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final v in const [
                                'Correct',
                                'Wrong company',
                                'Not a product',
                                'Unknown brand',
                              ])
                                ChoiceChip(
                                  label: Text(v),
                                  selected: _verdicts[sel.id] == v,
                                  onSelected: (_) => setState(() {
                                    _verdicts[sel.id] = v;
                                    _flagging = false;
                                  }),
                                  showCheckmark: false,
                                  selectedColor: AppColors.mint,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                            ],
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

/// Territory screen 5: recommended follow-up and mark reviewed.
class TerritoryActionScreen extends StatefulWidget {
  const TerritoryActionScreen({super.key, required this.alert});
  final TerritoryAlert alert;

  @override
  State<TerritoryActionScreen> createState() => _TerritoryActionScreenState();
}

class _TerritoryActionScreenState extends State<TerritoryActionScreen> {
  final _note = TextEditingController();
  final _noteFocus = FocusNode();
  final _done = <String>{};
  DateTime? _nextVisit;

  @override
  void dispose() {
    _note.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _coaching() async {
    final assigned = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssignCoachingScreen(officer: officers.first),
      ),
    );
    if (assigned == true) setState(() => _done.add('coaching'));
  }

  Future<void> _schedule() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (d != null) {
      setState(() {
        _nextVisit = d;
        _done.add('visit');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final comp = DemoAudit.largestCompetitor;
    return RoleNavScaffold(
      activeTab: 1,
      body: FixedHeaderScrollView(
        title: 'Recommended follow-up',
        subtitle: DemoAudit.shop,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SurfaceCard(
              color: AppColors.amberSoft,
              borderColor: AppColors.amber,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.trending_down_rounded, color: _amberText),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Square share is 10 percentage points below the '
                      'territory target.',
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
            const SizedBox(height: 10),
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: CompanyColors.unilever,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${comp.company} has '
                      '${comp.sharePercent(DemoAudit.total).round()}% of '
                      'detected Soap facings.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Actions'),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.headphones_rounded,
              title: 'Send coaching module to Sales Officer',
              done: _done.contains('coaching'),
              onTap: _coaching,
            ),
            _ActionRow(
              icon: Icons.edit_note_rounded,
              title: 'Add follow-up note',
              done: _note.text.trim().isNotEmpty,
              onTap: () => _noteFocus.requestFocus(),
            ),
            _ActionRow(
              icon: Icons.event_outlined,
              title: _nextVisit == null
                  ? 'Schedule next visit'
                  : 'Next visit: ${_fmt(_nextVisit!)}',
              done: _done.contains('visit'),
              onTap: _schedule,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              focusNode: _noteFocus,
              minLines: 3,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Follow-up note',
                hintText: 'Write a note for Arif Rahman',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Mark alert reviewed',
              icon: Icons.done_all_rounded,
              onPressed: () {
                markAlertRead(widget.alert.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Alert marked as reviewed.')),
                  );
                shellTab.value = 1;
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ]),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.done,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SurfaceCard(
      onTap: onTap,
      borderColor: done ? AppColors.emeraldDark : AppColors.border,
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
          ),
          Icon(
            done ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            color: done ? AppColors.emeraldDark : AppColors.inkMuted,
          ),
        ],
      ),
    ),
  );
}
