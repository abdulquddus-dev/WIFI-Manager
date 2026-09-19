// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ── الألوان الأساسية ──────────────────────────────────
  static const Color primary       = Color(0xFF0A1628);
  static const Color accent        = Color(0xFF00D4FF);
  static const Color green         = Color(0xFF00E096);
  static const Color red           = Color(0xFFFF4757);
  static const Color gold          = Color(0xFFFFD700);
  static const Color surface       = Color(0xFF0F1F3D);
  static const Color surfaceLight  = Color(0xFF1A2F50);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8FA5C0);
  static const Color border        = Color(0xFF1E3A5F);

  // ── ألوان التدرج والبطاقات ───────────────────────────
  static const Color primaryDark  = Color(0xFF0F2447);
  static const Color profitDark   = Color(0xFF003D2A);
  static const Color profitDeep   = Color(0xFF00261A);
  static const Color lossDark     = Color(0xFF3D0010);
  static const Color lossDeep     = Color(0xFF260009);
  static const Color dividerBlue  = Color(0xFF2A4A6A);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: green,
        surface: surface,
        error: red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ── مساعد التاريخ ────────────────────────────────────
String getCurrentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

String formatMonthKey(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length != 2) return monthKey;
  const months = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  final month = int.tryParse(parts[1]) ?? 0;
  return '${months[month]} ${parts[0]}';
}

String formatAmount(double amount) {
  if (amount == amount.truncate()) {
    return amount.toInt().toString();
  }
  return amount.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}
