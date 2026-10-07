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

  String get firstName => name.split(' ').first;

  String get roleLabel =>
      role == UserRole.salesOfficer ? 'Sales Officer' : 'Territory Officer';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }
}

/// Demo credential directory. Replace with the real auth API.
/// SO-1001 / TO-2001, password "shelf123".
abstract final class DemoAuth {
  static const password = 'shelf123';
  static const _users = {
    'SO-1001': UserSession(
      employeeId: 'SO-1001',
      name: 'Arif Rahman',
      role: UserRole.salesOfficer,
      territory: 'Gulshan',
    ),
    'TO-2001': UserSession(
      employeeId: 'TO-2001',
      name: 'Nadia Islam',
      role: UserRole.territoryOfficer,
      territory: 'Gulshan',
    ),
  };

  static UserSession? signIn(String id, String pass) {
    final user = _users[id.trim().toUpperCase()];
    return (user != null && pass == password) ? user : null;
  }
}

/// Holds the signed-in user for the app lifetime.
final ValueNotifier<UserSession?> currentSession = ValueNotifier(null);

/// Shop ids with a completed visit today.
final ValueNotifier<Set<String>> visitedToday = ValueNotifier(<String>{});

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.lastVisit,
    this.squareShare,
  });

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String lastVisit;

  /// Last recorded Square soap share (%), if any.
  final int? squareShare;
}

enum DemoLocation { insideShop, outsideShop }

abstract final class DemoData {
  static const geofenceMeters = 120.0;

  static const samson = Shop(
    id: 'S-001',
    name: 'Samson Center Demo Outlet',
    address: 'Plot CES(G) 5A, 43 Road 126, Dhaka 1212',
    lat: 23.78075,
    lng: 90.41792,
    lastVisit: 'No visit recorded today',
    squareShare: 32,
  );

  static const shops = [
    samson,
    Shop(
      id: 'S-002',
      name: 'Gulshan Avenue Store',
      address: 'Gulshan Avenue, Gulshan 1, Dhaka 1212',
      lat: 23.7925,
      lng: 90.4160,
      lastVisit: '3 days ago',
      squareShare: 44,
    ),
    Shop(
      id: 'S-003',
      name: 'Niketan Retail Point',
      address: 'Road 3, Niketan, Dhaka 1212',
      lat: 23.7735,
      lng: 90.4150,
      lastVisit: '2 days ago',
      squareShare: 38,
    ),
    Shop(
      id: 'S-004',
      name: 'Police Plaza General Store',
      address: 'Police Plaza Concord, Gulshan 1, Dhaka 1212',
      lat: 23.7862,
      lng: 90.4172,
      lastVisit: '6 days ago',
      squareShare: 29,
    ),
    Shop(
      id: 'S-005',
      name: 'Mohakhali Market Outlet',
      address: 'Mohakhali Bazar, Dhaka 1212',
      lat: 23.7780,
      lng: 90.4000,
      lastVisit: 'Never',
    ),
  ];

  /// Simulated GPS fixes (about 24 m and 436 m from Samson Center).
  static (double, double) locationFor(DemoLocation loc) => switch (loc) {
    DemoLocation.insideShop => (23.780534, 90.41792),
    DemoLocation.outsideShop => (23.784672, 90.41792),
  };

  static Shop? byId(String id) {
    for (final s in shops) {
      if (s.id == id) return s;
    }
    return null;
  }

  static double distanceTo(Shop s, double lat, double lng) =>
      distanceMeters(lat, lng, s.lat, s.lng);

  static bool insideGeofence(Shop s, double lat, double lng) =>
      distanceTo(s, lat, lng) <= geofenceMeters;
}

/// "24 m" / "1.2 km".
String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
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
