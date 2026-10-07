import 'package:flutter/material.dart';

import '../models/coaching.dart';
import '../models/session.dart';
import '../models/territory_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import '../widgets/state_widgets.dart';
import 'app_shell.dart';
import 'coaching_player_screens.dart';

class _OfficerStats {
  const _OfficerStats(this.visits, this.audits, this.square);
  final int visits, audits, square;
}

_OfficerStats _statsFor(Officer o, bool week) => week
    ? _OfficerStats(o.visitsWeek, o.auditsWeek, o.squareWeek)
    : _OfficerStats(o.visitsToday, o.auditsToday, o.squareToday);

/// Team screen 1: officer overview.
class TerritoryTeamScreen extends StatefulWidget {
  const TerritoryTeamScreen({super.key});

  @override
  State<TerritoryTeamScreen> createState() => _TerritoryTeamScreenState();
}

class _TerritoryTeamScreenState extends State<TerritoryTeamScreen> {
  bool _week = false;
  String _query = '';
  String _status = 'All';

  @override
  Widget build(BuildContext context) {
    final list = [
      for (final o in officers)
        if (o.name.toLowerCase().contains(_query.toLowerCase()) &&
            (_status == 'All' ||
                (_status == 'Active') == o.active))
          o,
    ];
    return FixedHeaderScrollView(
      title: 'Team',
      subtitle: 'Gulshan · ${officers.length} Sales Officers',
      slivers: [
        pagePadding([
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    selectedBackgroundColor: AppColors.navy,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
                  ),
                  segments: const [
                    ButtonSegment(value: false, label: Text('Today')),
                    ButtonSegment(value: true, label: Text('This week')),
                  ],
                  selected: {_week},
                  onSelectionChanged: (s) => setState(() => _week = s.first),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Leaderboard',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LeaderboardScreen(week: _week),
                  ),
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: AppColors.navy,
                ),
                icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search officers',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in const ['All', 'Active', 'Offline'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                      showCheckmark: false,
                      selectedColor: AppColors.navy,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _status == s ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: StateMessage(
                icon: Icons.person_search_outlined,
                title: 'No officers found',
                message: 'Try another name or status.',
              ),
            ),
          for (final o in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OfficerCard(
                officer: o,
                stats: _statsFor(o, _week),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OfficerDetailScreen(officer: o),
                  ),
                ),
              ),
            ),
        ]),
      ],
    );
  }
}

class _OfficerCard extends StatelessWidget {
  const _OfficerCard({
    required this.officer,
    required this.stats,
    required this.onTap,
  });
  final Officer officer;
  final _OfficerStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = officer;
    return SurfaceCard(
      onTap: onTap,
      borderColor: o.top ? AppColors.emeraldDark : AppColors.border,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  o.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.name,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(o.id, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              StatusPill(
                label: o.active ? 'Active' : 'Offline',
                icon: o.active ? Icons.circle : Icons.circle_outlined,
                color: o.active ? AppColors.emeraldDark : AppColors.inkMuted,
                background: o.active ? AppColors.mint : AppColors.surfaceAlt,
              ),
            ],
          ),
          if (o.top) ...[
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                label: 'Top performer',
                icon: Icons.workspace_premium_rounded,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Metric('${stats.visits}', 'Shops visited')),
              Expanded(child: _Metric('${stats.audits}', 'Audits')),
              Expanded(child: _Metric('${stats.square}%', 'Avg Square')),
              Expanded(child: _Metric('${o.coachingDone}%', 'Coaching')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(fontSize: 11.5, height: 1.2),
      ),
    ],
  );
}

/// Team screen 2: one officer. Territory Officers may see company shares.
class OfficerDetailScreen extends StatelessWidget {
  const OfficerDetailScreen({super.key, required this.officer});
  final Officer officer;

  static const _route = [
    ('Samson Center Demo Outlet', '10:42 AM', true),
    ('Gulshan Avenue Store', '12:30 PM', false),
    ('Niketan Retail Point', '2:15 PM', false),
  ];

  @override
  Widget build(BuildContext context) {
    final o = officer;
    final shops = DemoData.shops;
    final visited = o.visitsToday;
    return RoleNavScaffold(
      activeTab: 2,
      body: FixedHeaderScrollView(
        title: o.name,
        subtitle: '${o.id} · Gulshan',
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      o.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sales Officer',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        StatusPill(
                          label: o.active ? 'Active now' : 'Offline',
                          icon: o.active ? Icons.circle : Icons.circle_outlined,
                          color: o.active
                              ? AppColors.emeraldDark
                              : AppColors.inkMuted,
                          background: o.active
                              ? AppColors.mint
                              : AppColors.surfaceAlt,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Tile('$visited/${shops.length}', 'Visit completion'),
                ),
                const SizedBox(width: 10),
                Expanded(child: _Tile('${o.squareWeek}%', 'Avg Square share')),
                const SizedBox(width: 10),
                Expanded(child: _Tile('${o.coachingDone}%', 'Coaching')),
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Company share (this week)'),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                children: [
                  for (final (name, v) in [
                    ('Square Toiletries', o.squareWeek.toDouble()),
                    ('Unilever', 33.0),
                    ('Reckitt', 14.0),
                    ('Keya Cosmetics', 6.0),
                    ('Other / Unknown', 100 - o.squareWeek - 53.0),
                  ])
                    _ShareLine(name, v),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Today’s route'),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                children: [
                  for (var i = 0; i < _route.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Icon(
                            _route[i].$3
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: _route[i].$3
                                ? AppColors.emeraldDark
                                : AppColors.inkMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _route[i].$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Text(_route[i].$2),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Assigned shops'),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                children: [
                  for (final s in shops)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(color: AppColors.ink),
                            ),
                          ),
                          Icon(
                            statusForShare(territoryShopShares[s.id] ?? 0).icon,
                            size: 18,
                            color: statusForShare(
                              territoryShopShares[s.id] ?? 0,
                            ).textColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${territoryShopShares[s.id]}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Coaching progress'),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: o.coachingDone / 100,
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceAlt,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${o.coachingDone}% of assigned modules completed'),
                  ValueListenableBuilder<Map<String, List<String>>>(
                    valueListenable: assignedCoaching,
                    builder: (context, map, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final t in map[o.id] ?? const <String>[])
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule_send_rounded,
                                  size: 18,
                                  color: AppColors.emeraldDark,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Assigned: $t')),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Assign coaching',
              icon: Icons.headphones_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AssignCoachingScreen(officer: o),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _showVisits(context, o),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.5),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text(
                  'View visits',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _showVisits(BuildContext context, Officer o) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent audits · ${o.name}',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final (shop, time, share) in const [
              ('Samson Center Demo Outlet', 'Today, 11:42 AM', 40),
              ('Gulshan Avenue Store', 'Yesterday', 52),
              ('Niketan Retail Point', '5 Oct', 47),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(shop),
                subtitle: Text(time),
                trailing: Text(
                  'Square $share%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12.5, height: 1.25)),
      ],
    ),
  );
}

class _ShareLine extends StatelessWidget {
  const _ShareLine(this.name, this.value);
  final String name;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: CompanyColors.of(name),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
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
              '${value.round()}%',
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
            value: value / 100,
            minHeight: 8,
            backgroundColor: AppColors.surfaceAlt,
            color: CompanyColors.of(name),
          ),
        ),
      ],
    ),
  );
}

enum _Metric3 { visits, square, coaching }

/// Team screen 3: ranking by one metric for a stated period.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.week});
  final bool week;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _Metric3 _metric = _Metric3.square;

  double _value(Officer o) => switch (_metric) {
    _Metric3.visits => (widget.week ? o.visitsWeek : o.visitsToday) /
        (widget.week ? 12 : DemoData.shops.length) *
        100,
    _Metric3.square => (widget.week ? o.squareWeek : o.squareToday).toDouble(),
    _Metric3.coaching => o.coachingDone.toDouble(),
  };

  @override
  Widget build(BuildContext context) {
    final ranked = [...officers]..sort((a, b) => _value(b).compareTo(_value(a)));
    final top = ranked.first;
    final period = widget.week ? 'This week · 5–11 Oct 2026' : 'Today · 7 Oct 2026';
    return RoleNavScaffold(
      activeTab: 2,
      body: FixedHeaderScrollView(
        title: 'Leaderboard',
        subtitle: period,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (m, label) in const [
                    (_Metric3.square, 'Average Square share'),
                    (_Metric3.visits, 'Visit completion'),
                    (_Metric3.coaching, 'Coaching completion'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _metric == m,
                        onSelected: (_) => setState(() => _metric = m),
                        showCheckmark: false,
                        selectedColor: AppColors.navy,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _metric == m ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.navy,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top performer',
                          style: TextStyle(color: Color(0xFFB6C2D4)),
                        ),
                        Text(
                          top.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_value(top).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < ranked.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == 0 ? AppColors.emerald : AppColors.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ranked[i].name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_value(ranked[i]) / 100).clamp(0, 1),
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceAlt,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_value(ranked[i]).round()}%',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: AppColors.inkMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data based on completed audits. Rankings show results '
                    'side by side and do not mean coaching caused a change in '
                    'sales.',
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

/// Team screen 4: assign a coaching module, with success confirmation.
class AssignCoachingScreen extends StatefulWidget {
  const AssignCoachingScreen({super.key, required this.officer});
  final Officer officer;

  @override
  State<AssignCoachingScreen> createState() => _AssignCoachingScreenState();
}

class _AssignCoachingScreenState extends State<AssignCoachingScreen> {
  CoachingModule _module = coachingModules.first;
  DateTime _due = DateTime.now().add(const Duration(days: 3));
  final _note = TextEditingController();
  bool _assigned = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _due = d);
  }

  void _assign() {
    final id = widget.officer.id;
    assignedCoaching.value = {
      ...assignedCoaching.value,
      id: [...(assignedCoaching.value[id] ?? const []), _module.title],
    };
    setState(() => _assigned = true);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.officer;
    return RoleNavScaffold(
      activeTab: 2,
      body: FixedHeaderScrollView(
        title: _assigned ? 'Coaching assigned' : 'Assign coaching',
        subtitle: o.name,
        onBack: () => Navigator.of(context).pop(_assigned),
        slivers: [
          pagePadding([
            if (_assigned) ...[
              const SizedBox(height: 12),
              StateMessage(
                icon: Icons.check_rounded,
                tone: StateTone.positive,
                title: 'Module assigned',
                message:
                    '${_module.title} is assigned to ${o.name}, due '
                    '${_due.day}/${_due.month}/${_due.year}.',
                primaryLabel: 'Done',
                primaryIcon: Icons.check_rounded,
                onPrimary: () => Navigator.of(context).pop(true),
              ),
            ] else ...[
              SurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        o.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${o.name} · ${o.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle(title: 'Coaching module'),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _module.id,
                onChanged: (v) => setState(
                  () => _module = coachingModules.firstWhere((m) => m.id == v),
                ),
                child: Column(
                  children: [
                    for (final m in coachingModules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          borderColor: _module.id == m.id
                              ? AppColors.emeraldDark
                              : AppColors.border,
                          child: RadioListTile<String>(
                            value: m.id,
                            activeColor: AppColors.emeraldDark,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              m.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            subtitle: Text('${m.durationLabel} · Bengali audio'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SurfaceCard(
                onTap: _pickDate,
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: AppColors.navy),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Due date',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      '${_due.day}/${_due.month}/${_due.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AudioPlayerScreen(module: _module),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy, width: 1.5),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text(
                    'Preview audio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Assign module',
                icon: Icons.send_rounded,
                onPressed: _assign,
              ),
            ],
          ]),
        ],
      ),
    );
  }
}
