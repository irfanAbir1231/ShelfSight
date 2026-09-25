import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF111827);
  static const navySoft = Color(0xFF1F2937);
  static const emerald = Color(0xFF10B981);
  static const emeraldDark = Color(0xFF047857);
  static const mint = Color(0xFFD1FAE5);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const canvas = Color(0xFFF7F9FC);
  static const headerSurface = Color(0xFFEAF0F7);
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const inkMuted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
      primary: AppColors.navy,
      secondary: AppColors.emerald,
      surface: Colors.white,
      error: AppColors.red,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
          color: AppColors.navy,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
          color: AppColors.navy,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w800,
          letterSpacing: -.35,
          color: AppColors.navy,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: AppColors.navy),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppColors.inkMuted,
        ),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerSurface,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 10,
        backgroundColor: AppColors.navy,
        indicatorColor: AppColors.emerald,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.navy
                : Colors.white70,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white60,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
        ),
      ),
    );
  }
}
