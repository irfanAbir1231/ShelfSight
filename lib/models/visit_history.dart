import 'package:flutter/foundation.dart';

class VisitRecord {
  const VisitRecord({
    required this.shopName,
    required this.date,
    required this.squareShare,
    required this.photos,
    this.category = 'Soap',
    this.status = 'Completed',
    this.duration = '14 min',
  });
  final String shopName;
  final DateTime date;
  final String category;
  final int squareShare;
  final int photos;
  final String status;
  final String duration;
}

/// Sales Officer visit history (newest first). Seeded with demo visits.
final ValueNotifier<List<VisitRecord>> visitHistory = ValueNotifier([
  VisitRecord(
    shopName: 'Gulshan Avenue Store',
    date: DateTime(2026, 10, 4, 11, 20),
    squareShare: 44,
    photos: 3,
    duration: '18 min',
  ),
  VisitRecord(
    shopName: 'Niketan Retail Point',
    date: DateTime(2026, 10, 5, 10, 5),
    squareShare: 38,
    photos: 2,
  ),
  VisitRecord(
    shopName: 'Police Plaza General Store',
    date: DateTime(2026, 10, 1, 15, 40),
    squareShare: 29,
    photos: 2,
    status: 'Needs review',
  ),
  VisitRecord(
    shopName: 'Samson Center Demo Outlet',
    date: DateTime(2026, 10, 3, 12, 10),
    squareShare: 32,
    photos: 3,
    duration: '16 min',
  ),
]);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
