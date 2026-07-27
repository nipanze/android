// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

/// Nipanze brand colours and typography.
/// Typography: Sora (headings/hero numbers) · Inter (body/forms/data)
class AppColors {
  AppColors._();

  // Brand – Nipanze primary: Violet/Purple
  static const Color accent     = Color(0xFF7C3AED); // primary purple
  static const Color accentDark = Color(0xFF6D28D9); // pressed / dark variant
  static const Color accentLight = Color(0xFFA78BFA); // light variant (dark-mode text on purple)
  static const Color success = Color(0xFF10B981); // green
  static const Color warning = Color(0xFFF59E0B); // amber
  static const Color danger = Color(0xFFEF4444); // red
  static const Color purple = Color(0xFF7C3AED); // alias kept for backward compat

  // Dark theme surfaces
  static const Color bgDark = Color(0xFF191917);
  static const Color bg2Dark = Color(0xFF242422);
  static const Color bg3Dark = Color(0xFF2C2C2A);
  static const Color borderDark = Color(0xFF474744);
  static const Color textDark = Color(0xFFF5F5F1);
  static const Color text2Dark = Color(0xFFB7B5AE);
  static const Color text3Dark = Color(0xFF8A8881);

  // Light theme surfaces
  static const Color bgLight = Color(0xFFF8F9FC);
  static const Color bg2Light = Color(0xFFFFFFFF);
  static const Color bg3Light = Color(0xFFF0F2F7);
  static const Color borderLight = Color(0xFFE2E6EF);
  static const Color textLight = Color(0xFF0F1623);
  static const Color text2Light = Color(0xFF5A657A);
  static const Color text3Light = Color(0xFF9BA6B8);
}

/// Font family constants — use these instead of raw strings everywhere.
class AppFonts {
  AppFonts._();

  /// Inter — body text, labels, form fields, buttons, data tables.
  /// Excellent for small sizes and numeric data (loan amounts, rates, offers).
  static const String body = 'Inter';

  /// Sora — screen titles, section headings, hero numbers (e.g. "UGX 5,000,000").
  /// Gives Nipanze a distinctive, modern fintech identity.
  static const String heading = 'Sora';
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.success,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
      onSurface: isDark ? AppColors.textDark : AppColors.textLight,
      surfaceContainerHighest: isDark ? AppColors.bg3Dark : AppColors.bg3Light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,

      // Inter as the default for all body/UI text
      fontFamily: AppFonts.body,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bg2Light,
        foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.heading, // Sora for screen titles
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        selectedItemColor: AppColors.accent,
        unselectedItemColor:
            isDark ? AppColors.text3Dark : AppColors.text3Light,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.bg3Dark : AppColors.bg3Light,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: TextStyle(
          fontFamily: AppFonts.body,
          color: isDark ? AppColors.text2Dark : AppColors.text2Light,
        ),
        hintStyle: TextStyle(
          fontFamily: AppFonts.body,
          color: isDark ? AppColors.text3Dark : AppColors.text3Light,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),

      textTheme: TextTheme(
        // Sora — large display headings (e.g. onboarding hero text)
        displayLarge: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        displayMedium: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        displaySmall: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),

        // Sora — screen/section headings
        headlineLarge: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.heading,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),

        // Inter — card titles, list item titles
        titleLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        titleSmall: TextStyle(
          fontFamily: AppFonts.body,
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),

        // Inter — body text, descriptions, paragraphs
        bodyLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.text2Dark : AppColors.text2Light,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.text3Dark : AppColors.text3Light,
        ),

        // Inter — labels, tags, badges, captions
        labelLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        labelMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.text2Dark : AppColors.text2Light,
        ),
        // labelSmall — numeric values: loan amounts, rates, offers (Inter tabular)
        labelSmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
      ),
    );
  }
}
