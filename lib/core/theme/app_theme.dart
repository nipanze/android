import 'package:flutter/material.dart';

/// Nipanze brand colours and typography.
/// Brand: DM Sans (body) · DM Mono (numeric/code values)
class AppColors {
  AppColors._();

  // Brand
  static const Color accent = Color(0xFF3B82F6);       // blue
  static const Color accentDark = Color(0xFF2563EB);
  static const Color success = Color(0xFF10B981);      // green
  static const Color warning = Color(0xFFF59E0B);      // amber
  static const Color danger = Color(0xFFEF4444);       // red
  static const Color purple = Color(0xFF8B5CF6);

  // Dark theme surfaces
  static const Color bgDark = Color(0xFF0A0C10);
  static const Color bg2Dark = Color(0xFF111318);
  static const Color bg3Dark = Color(0xFF181B22);
  static const Color borderDark = Color(0xFF1E222C);
  static const Color textDark = Color(0xFFE8EAF0);
  static const Color text2Dark = Color(0xFF8892A4);
  static const Color text3Dark = Color(0xFF4A5265);

  // Light theme surfaces
  static const Color bgLight = Color(0xFFF8F9FC);
  static const Color bg2Light = Color(0xFFFFFFFF);
  static const Color bg3Light = Color(0xFFF0F2F7);
  static const Color borderLight = Color(0xFFE2E6EF);
  static const Color textLight = Color(0xFF0F1623);
  static const Color text2Light = Color(0xFF5A657A);
  static const Color text3Light = Color(0xFF9BA6B8);
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
      fontFamily: 'DM Sans',
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: isDark ? AppColors.text3Dark : AppColors.text3Light,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.bg3Dark : AppColors.bg3Light,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.text2Dark : AppColors.text2Light,
          fontFamily: 'DM Sans',
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.text3Dark : AppColors.text3Light,
          fontFamily: 'DM Sans',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
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
        displayLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        titleMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          color: isDark ? AppColors.text2Dark : AppColors.text2Light,
        ),
        bodySmall: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          color: isDark ? AppColors.text3Dark : AppColors.text3Light,
        ),
        labelSmall: TextStyle(
          fontFamily: 'DM Mono',
          fontSize: 11,
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
      ),
    );
  }
}
