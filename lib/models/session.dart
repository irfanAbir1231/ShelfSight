import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum UserRole { salesOfficer, territoryOfficer }

class UserSession {
  const UserSession({
    required this.employeeId,
    required this.name,
    required this.role,
    required this.territory,
  });

  final String employeeId;
  final String name;
  final UserRole role;
  final String territory;

  String get roleLabel => role == UserRole.salesOfficer
      ? 'Sales Officer'
      : 'Territory Officer';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }
}

/// Demo credential directory. Replace with the real auth API.
/// SO-1042 / TO-2001, password "shelf123".
abstract final class DemoAuth {
  static const password = 'shelf123';
  static const _users = {
    'SO-1042': UserSession(
      employeeId: 'SO-1042',
      name: 'Rahim Ahmed',
      role: UserRole.salesOfficer,
      territory: 'Dhaka North',
    ),
    'TO-2001': UserSession(
      employeeId: 'TO-2001',
      name: 'Nusrat Jahan',
      role: UserRole.territoryOfficer,
      territory: 'Dhaka North',
    ),
  };

  static UserSession? signIn(String id, String pass) {
    final user = _users[id.trim().toUpperCase()];
    return (user != null && pass == password) ? user : null;
  }
}

/// Holds the signed-in user for the app lifetime.
final ValueNotifier<UserSession?> currentSession = ValueNotifier(null);

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.area,
    required this.lat,
    required this.lng,
    required this.lastVisit,
    this.visitedToday = false,
  });

  final String id;
  final String name;
  final String area;
  final double lat;
  final double lng;
  final String lastVisit;
  final bool visitedToday;
}

abstract final class DemoData {
  /// Simulated GPS fix. Swap for a real location stream (e.g. geolocator).
  static const userLat = 23.79372;
  static const userLng = 90.40660;

  static const shops = [
    Shop(
      id: 'S-101',
      name: 'Shwapno Banani',
      area: 'Road 11, Banani',
      lat: 23.79385,
      lng: 90.40672,
      lastVisit: '6 days ago',
    ),
    Shop(
      id: 'S-102',
      name: 'Meena Bazar Banani',
      area: 'Kemal Ataturk Ave',
      lat: 23.79610,
      lng: 90.40190,
      lastVisit: 'Today, 10:15',
      visitedToday: true,
    ),
    Shop(
      id: 'S-103',
      name: 'Agora Superstore',
      area: 'Block C, Banani',
      lat: 23.79100,
      lng: 90.41060,
      lastVisit: '2 days ago',
    ),
    Shop(
      id: 'S-104',
      name: 'Prince Bazar',
      area: 'Road 27, Gulshan 1',
      lat: 23.78820,
      lng: 90.40430,
      lastVisit: '9 days ago',
    ),
    Shop(
      id: 'S-105',
      name: 'Nandan Departmental',
      area: 'Road 4, Banani',
      lat: 23.79720,
      lng: 90.41000,
      lastVisit: 'Never',
    ),
  ];

  static const detectRadiusMeters = 60.0;

  /// Nearest assigned shop within [detectRadiusMeters], else null.
  static ({Shop shop, double meters})? detect(double lat, double lng) {
    Shop? best;
    var bestDist = double.infinity;
    for (final s in shops) {
      final d = distanceMeters(lat, lng, s.lat, s.lng);
      if (d < bestDist) {
        best = s;
        bestDist = d;
      }
    }
    if (best == null || bestDist > detectRadiusMeters) return null;
    return (shop: best, meters: bestDist);
  }
}

double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

class ProductCategory {
  const ProductCategory(this.name, this.active);
  final String name;
  final bool active;
}

const productCategories = [
  ProductCategory('Soap', true),
  ProductCategory('Shampoo', false),
  ProductCategory('Toothpaste', false),
  ProductCategory('Detergent', false),
  ProductCategory('Dishwashing Liquid', false),
  ProductCategory('Toilet Cleaner', false),
];

class CompanyGroup {
  const CompanyGroup(this.name, this.brands);
  final String name;
  final List<String> brands;
}

const soapCompanyGroups = [
  CompanyGroup('Square Toiletries', ['Meril', 'Sepnil']),
  CompanyGroup('Unilever', ['Lux', 'Lifebuoy', 'Dove']),
  CompanyGroup('Reckitt', ['Dettol']),
  CompanyGroup('Keya Cosmetics', ['Keya']),
  CompanyGroup('Other / Unknown', []),
];
