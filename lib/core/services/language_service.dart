// lib/core/services/language_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.countryCode,
  });

  final String code;        // e.g. 'en', 'sw', 'fr', 'rw', 'ar'
  final String name;        // e.g. 'English', 'Swahili'
  final String nativeName;  // e.g. 'Kiswahili', 'Ikinyarwanda'
  final String flag;        // e.g. '🇬🇧', '🇰🇪', '🇫🇷', '🇷🇼', '🇪🇬'
  final String countryCode; // e.g. 'UG', 'KE', 'RW', 'EG' – drives currency

  Locale get locale => Locale(code);
}

/// Persists the user's chosen locale code across app restarts.
/// Defaults to device/system locale when null.
class LanguageService {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const _key = 'user_locale_code';

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧', countryCode: 'UG'),
    AppLanguage(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili', flag: '🇰🇪', countryCode: 'KE'),
    AppLanguage(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷', countryCode: 'RW'),
    AppLanguage(code: 'rw', name: 'Kinyarwanda', nativeName: 'Ikinyarwanda', flag: '🇷🇼', countryCode: 'RW'),
    AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇪🇬', countryCode: 'EG'),
  ];

  final ValueNotifier<Locale?> notifier = ValueNotifier<Locale?>(null);

  /// Must be called once during app initialisation (before runApp).
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_key);
      final initial = (savedCode != null && savedCode.isNotEmpty) ? Locale(savedCode) : null;
      notifier.value = initial;
    } catch (_) {}
  }

  Locale? get locale => notifier.value;

  AppLanguage get currentLanguage {
    final code = notifier.value?.languageCode;
    return supportedLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => supportedLanguages.first,
    );
  }

  Future<void> setLanguage(String languageCode) async {
    notifier.value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }

  Future<void> setLocale(Locale? locale) async {
    notifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}
