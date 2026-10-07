import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';

/// Demo territory-wide soap shares. Only Territory Officers ever see these.
const _groupShares = [
  ('Square Toiletries', 38.0, AppColors.emeraldDark),
  ('Unilever', 34.0, AppColors.navy),
  ('Reckitt', 12.0, Color(0xFF475569)),
  ('Keya Cosmetics', 9.0, Color(0xFF7C8DA6)),
  ('Other / Unknown', 7.0, Color(0xFFB8C4D4)),
];

class TerritoryDashboardScreen extends StatelessWidget {
  const TerritoryDashboardScreen({super.key, required this.session});
  final UserSession session;

  @override
  Widget build(BuildContext context) {
    return FixedHeaderScrollView(
      title: 'Dashboard',
      subtitle: '${session.territory} · Soap',
      alertCount: 3,
      slivers: [
        pagePadding([
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SQUARE SHELF SHARE',
                  style: TextStyle(
                    color: Color(0xFFB6C2D4),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '38%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                    ),
                    SizedBox(width: 10),
                    Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: StatusPill(
                        label: '+2.4 pts this week',
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '42 shops audited · 1,284 facings counted',
                  style: TextStyle(color: Color(0xFFB6C2D4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Company share'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              children: [
                for (final g in _groupShares) _ShareRow(g.$1, g.$2, g.$3),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Needs attention'),
          const SizedBox(height: 8),
          const _AttentionRow(
            shop: 'Prince Bazar',
            detail: 'Square share 18% · below 25% target',
          ),
          const SizedBox(height: 10),
          const _AttentionRow(
            shop: 'Nandan Departmental',
            detail: 'Not visited yet this cycle',
            warning: true,
          ),
        ]),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow(this.name, this.value, this.color);
  final String name;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.shop,
    required this.detail,
    this.warning = false,
  });
  final String shop;
  final String detail;
  final bool warning;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      children: [
        Icon(
          warning ? Icons.schedule_rounded : Icons.trending_down_rounded,
          color: warning ? AppColors.amber : AppColors.red,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TerritoryAlertsScreen extends StatelessWidget {
  const TerritoryAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FixedHeaderScrollView(
      title: 'Alerts',
      subtitle: 'Competitive intelligence',
      alertCount: 3,
      slivers: [
        pagePadding([
          const _CompetitorAlert(
            important: true,
            title: 'Unilever gained shelf space',
            shop: 'Shwapno Banani · reported by Rahim Ahmed',
            detail: 'Unilever 41% in this shop, up from 33% last visit.',
            time: '25 min ago',
          ),
          const SizedBox(height: 10),
          const _CompetitorAlert(
            important: true,
            title: 'Dettol promotion banner',
            shop: 'Agora Superstore · reported by Rahim Ahmed',
            detail: 'Reckitt in-store display at eye level.',
            time: '2 h ago',
          ),
          const SizedBox(height: 10),
          const _CompetitorAlert(
            important: false,
            title: 'Unknown soap brand detected',
            shop: 'Prince Bazar · reported by Karim Hossain',
            detail: '6 facings classed Other / Unknown. Review photos.',
            time: 'Yesterday',
          ),
        ]),
      ],
    );
  }
}

class _CompetitorAlert extends StatelessWidget {
  const _CompetitorAlert({
    required this.important,
    required this.title,
    required this.shop,
    required this.detail,
    required this.time,
  });
  final bool important;
  final String title;
  final String shop;
  final String detail;
  final String time;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    borderColor: important ? AppColors.red : AppColors.border,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusPill(
              label: important ? 'Competitor alert' : 'Review',
              icon: important
                  ? Icons.warning_amber_rounded
                  : Icons.visibility_outlined,
              color: important
                  ? const Color(0xFF9B1C1C)
                  : const Color(0xFF92580A),
              background: important ? AppColors.redSoft : AppColors.amberSoft,
            ),
            const Spacer(),
            Text(
              time,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12.5),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          shop,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(detail, style: const TextStyle(color: AppColors.ink, height: 1.4)),
      ],
    ),
  );
}

class TerritoryTeamScreen extends StatelessWidget {
  const TerritoryTeamScreen({super.key});

  static const _team = [
    ('Rahim Ahmed', 'SO-1042', 9, 41),
    ('Karim Hossain', 'SO-1057', 7, 33),
    ('Sadia Islam', 'SO-1063', 11, 44),
    ('Tanvir Alam', 'SO-1071', 4, 29),
  ];

  @override
  Widget build(BuildContext context) {
    return FixedHeaderScrollView(
      title: 'Team',
      subtitle: '${_team.length} Sales Officers',
      slivers: [
        pagePadding([
          for (final m in _team)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        m.$1.split(' ').map((p) => p[0]).take(2).join(),
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
                            m.$1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '${m.$2} · ${m.$3} visits this week',
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: 'Square ${m.$4}%',
                      icon: Icons.pie_chart_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
        ]),
      ],
    );
  }
}
