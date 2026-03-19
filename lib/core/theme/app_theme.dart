import 'package:flutter/material.dart';

/// OpenCapital design tokens.
///
/// Brand colour: #1A56DB (primary blue)
/// Typography:   Sora (headings) + Inter (body)
abstract class AppColors {
  // Brand
  static const primary = Color(0xFF1A56DB);
  static const primaryDark = Color(0xFF1141A8);
  static const primaryLight = Color(0xFF4B7EE8);
  static const accent = Color(0xFF00C9A7);

  // Status
  static const success = Color(0xFF0E9F6E);
  static const warning = Color(0xFFE3A008);
  static const error = Color(0xFFF05252);
  static const info = Color(0xFF3F83F8);

  // Wallet pools
  static const lendable = Color(0xFF0E9F6E); // green — own money
  static const locked = Color(0xFFE3A008); // amber — reserved
  static const borrowed = Color(0xFFF05252); // red — non-lendable

  // Reputation tiers
  static const tierPlatinum = Color(0xFF6366F1);
  static const tierGold = Color(0xFFD97706);
  static const tierSilver = Color(0xFF6B7280);
  static const tierBronze = Color(0xFF92400E);
  static const tierRestricted = Color(0xFFEF4444);

  // Neutrals — light
  static const surfaceLight = Color(0xFFF9FAFB);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE5E7EB);
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6B7280);

  // Neutrals — dark
  static const surfaceDark = Color(0xFF111827);
  static const cardDark = Color(0xFF1F2937);
  static const borderDark = Color(0xFF374151);
  static const textPrimaryDark = Color(0xFFF9FAFB);
  static const textSecondaryDark = Color(0xFF9CA3AF);
}

abstract class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,

      // Typography — Sora headings, Inter body
      fontFamily: 'Inter',
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 32),
        displayMedium: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 28),
        displaySmall: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 24),
        headlineLarge: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 22),
        headlineMedium: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 20),
        headlineSmall: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 18),
        titleLarge: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 16),
        titleMedium: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14),
        titleSmall: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        bodySmall: TextStyle(fontFamily: 'Inter', fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        labelLarge: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 10),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        titleTextStyle: TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11),
      ),

      // Chip
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        thickness: 1,
      ),
    );
  }
}
