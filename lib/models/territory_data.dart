import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'session.dart';

/// Company colors used on every Territory chart. Square is always emerald.
abstract final class CompanyColors {
  static const square = AppColors.emeraldDark;
  static const unilever = AppColors.navy;
  static const reckitt = Color(0xFF475569);
  static const keya = Color(0xFF94A3B8);
  static const other = Color(0xFFCBD5E1);

  static Color of(String company) => switch (company) {
    'Square Toiletries' => square,
    'Unilever' => unilever,
    'Reckitt' => reckitt,
    'Keya Cosmetics' => keya,
    _ => other,
  };
}

class BrandFinding {
  const BrandFinding(this.brand, this.facings, this.confidence);
  final String brand;
  final int facings;

  /// Average detector confidence 0..1.
  final double confidence;
}

class CompanyFinding {
  const CompanyFinding(this.company, this.facings, this.brands);
  final String company;
  final int facings;
  final List<BrandFinding> brands;

  double sharePercent(int total) => facings / total * 100;
}

/// The demo competitive audit (Samson Center, Soap). Territory Officers only.
abstract final class DemoAudit {
  static const shop = 'Samson Center Demo Outlet';
  static const officer = 'Arif Rahman';
  static const category = 'Soap';
  static const total = 20;
  static const targetShare = 50.0;
  static const timeLabel = '11:42 AM';

  static const companies = [
    CompanyFinding('Square Toiletries', 8, [
      BrandFinding('Meril', 5, .91),
      BrandFinding('Sepnil', 3, .88),
    ]),
    CompanyFinding('Unilever', 7, [
      BrandFinding('Lux', 3, .86),
      BrandFinding('Lifebuoy', 2, .84),
      BrandFinding('Dove', 2, .82),
    ]),
    CompanyFinding('Reckitt', 3, [BrandFinding('Dettol', 3, .85)]),
    CompanyFinding('Keya Cosmetics', 1, [BrandFinding('Keya', 1, .79)]),
    CompanyFinding('Other / Unknown', 1, [BrandFinding('Unknown brand', 1, .52)]),
  ];

  static double get squareShare => companies.first.sharePercent(total);

  static CompanyFinding get largestCompetitor =>
      companies.skip(1).reduce((a, b) => a.facings >= b.facings ? a : b);
}

enum ShareStatus { onTarget, near, below }

ShareStatus statusForShare(int share) => share >= 50
    ? ShareStatus.onTarget
    : share >= 45
    ? ShareStatus.near
    : ShareStatus.below;

extension ShareStatusInfo on ShareStatus {
  String get label => switch (this) {
    ShareStatus.onTarget => 'On target',
    ShareStatus.near => 'Near target',
    ShareStatus.below => 'Below target',
  };
  IconData get icon => switch (this) {
    ShareStatus.onTarget => Icons.check_circle_rounded,
    ShareStatus.near => Icons.remove_circle_outline_rounded,
    ShareStatus.below => Icons.trending_down_rounded,
  };
  Color get color => switch (this) {
    ShareStatus.onTarget => AppColors.emerald,
    ShareStatus.near => AppColors.amber,
    ShareStatus.below => AppColors.red,
  };
  Color get textColor => switch (this) {
    ShareStatus.onTarget => AppColors.emeraldDark,
    ShareStatus.near => const Color(0xFF92580A),
    ShareStatus.below => const Color(0xFF9B1C1C),
  };
  Color get softColor => switch (this) {
    ShareStatus.onTarget => AppColors.mint,
    ShareStatus.near => AppColors.amberSoft,
    ShareStatus.below => AppColors.redSoft,
  };
}

/// Current Square share by shop id. Averages 42%.
const territoryShopShares = {
  'S-001': 40,
  'S-002': 52,
  'S-003': 47,
  'S-004': 36,
  'S-005': 35,
};

class ActiveOfficerVisit {
  const ActiveOfficerVisit(this.officer, this.shopId, this.since);
  final String officer;
  final String shopId;
  final String since;
}

const activeOfficerVisits = [
  ActiveOfficerVisit('Arif Rahman', 'S-001', '10:42 AM'),
  ActiveOfficerVisit('Sadia Islam', 'S-002', '11:05 AM'),
];

enum AlertKind { competitive, belowTarget, unknownCount, quality, completed }

class TerritoryAlert {
  const TerritoryAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.shop,
    required this.officer,
    required this.time,
    required this.group,
    required this.detail,
  });
  final String id;
  final AlertKind kind;
  final String title;
  final String shop;
  final String officer;
  final String time;
  final String group; // Today / Yesterday
  final String detail;
}

extension AlertKindInfo on AlertKind {
  IconData get icon => switch (this) {
    AlertKind.competitive => Icons.swap_horiz_rounded,
    AlertKind.belowTarget => Icons.trending_down_rounded,
    AlertKind.unknownCount => Icons.help_outline_rounded,
    AlertKind.quality => Icons.image_search_rounded,
    AlertKind.completed => Icons.task_alt_rounded,
  };

  /// Red only for important competitor alerts.
  bool get important => this == AlertKind.competitive;

  String get label => switch (this) {
    AlertKind.competitive => 'Competitive',
    AlertKind.belowTarget => 'Below target',
    AlertKind.unknownCount => 'Unknown products',
    AlertKind.quality => 'Image quality',
    AlertKind.completed => 'Visit completed',
  };
}

const territoryAlerts = [
  TerritoryAlert(
    id: 'a1',
    kind: AlertKind.competitive,
    title: 'Competitive shelf update',
    shop: 'Samson Center Demo Outlet',
    officer: 'Arif Rahman',
    time: '11:42 AM',
    group: 'Today',
    detail: 'Square 40% · Largest competitor: Unilever 35%',
  ),
  TerritoryAlert(
    id: 'a2',
    kind: AlertKind.belowTarget,
    title: 'Square share below target',
    shop: 'Police Plaza General Store',
    officer: 'Sadia Islam',
    time: '10:15 AM',
    group: 'Today',
    detail: 'Square 36% · 14 points below target',
  ),
  TerritoryAlert(
    id: 'a3',
    kind: AlertKind.quality,
    title: 'Image requires review',
    shop: 'Mohakhali Market Outlet',
    officer: 'Karim Hossain',
    time: '9:30 AM',
    group: 'Today',
    detail: 'Strong glare on one photo. Detections may be incomplete.',
  ),
  TerritoryAlert(
    id: 'a4',
    kind: AlertKind.unknownCount,
    title: 'High Unknown product count',
    shop: 'Niketan Retail Point',
    officer: 'Arif Rahman',
    time: '4:20 PM',
    group: 'Yesterday',
    detail: '6 of 18 facings could not be matched to a known brand.',
  ),
  TerritoryAlert(
    id: 'a5',
    kind: AlertKind.completed,
    title: 'Visit completed',
    shop: 'Gulshan Avenue Store',
    officer: 'Sadia Islam',
    time: '2:05 PM',
    group: 'Yesterday',
    detail: 'Soap audited · Square 52%',
  ),
];

/// Alert ids already read.
final ValueNotifier<Set<String>> readAlerts = ValueNotifier({'a4', 'a5'});

void markAlertRead(String id) => readAlerts.value = {...readAlerts.value, id};

int get unreadAlertCount =>
    territoryAlerts.where((a) => !readAlerts.value.contains(a.id)).length;

class Officer {
  const Officer({
    required this.name,
    required this.id,
    required this.active,
    required this.visitsToday,
    required this.visitsWeek,
    required this.auditsToday,
    required this.auditsWeek,
    required this.squareToday,
    required this.squareWeek,
    required this.coachingDone,
    this.top = false,
  });
  final String name;
  final String id;
  final bool active;
  final int visitsToday, visitsWeek;
  final int auditsToday, auditsWeek;
  final int squareToday, squareWeek;

  /// Coaching completion %, 0..100.
  final int coachingDone;
  final bool top;

  String get initials => name.split(' ').map((p) => p[0]).take(2).join();
}

const officers = [
  Officer(
    name: 'Arif Rahman',
    id: 'SO-1001',
    active: true,
    visitsToday: 2,
    visitsWeek: 9,
    auditsToday: 2,
    auditsWeek: 9,
    squareToday: 40,
    squareWeek: 42,
    coachingDone: 60,
  ),
  Officer(
    name: 'Sadia Islam',
    id: 'SO-1063',
    active: true,
    visitsToday: 3,
    visitsWeek: 11,
    auditsToday: 3,
    auditsWeek: 11,
    squareToday: 48,
    squareWeek: 46,
    coachingDone: 100,
    top: true,
  ),
  Officer(
    name: 'Karim Hossain',
    id: 'SO-1057',
    active: false,
    visitsToday: 1,
    visitsWeek: 7,
    auditsToday: 1,
    auditsWeek: 7,
    squareToday: 35,
    squareWeek: 38,
    coachingDone: 40,
  ),
  Officer(
    name: 'Tanvir Alam',
    id: 'SO-1071',
    active: false,
    visitsToday: 1,
    visitsWeek: 4,
    auditsToday: 1,
    auditsWeek: 4,
    squareToday: 36,
    squareWeek: 36,
    coachingDone: 20,
  ),
];

/// Coaching assignments made this session: officer id -> module titles.
final ValueNotifier<Map<String, List<String>>> assignedCoaching =
    ValueNotifier({});

String shopNameById(String id) => DemoData.byId(id)?.name ?? id;
