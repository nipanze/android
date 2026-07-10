// lib/core/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen ThemeMode across app restarts.
///
/// Usage:
///   ThemeService.instance.mode      — current mode
///   ThemeService.instance.notifier  — ValueNotifier to drive MaterialApp.router
///   ThemeService.instance.setMode(ThemeMode.dark)
class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _key = 'theme_mode';

  late final ValueNotifier<ThemeMode> notifier;

  /// Must be called once during app initialisation (before runApp).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    final initial = _fromString(saved);
    notifier = ValueNotifier(initial);
  }

  ThemeMode get mode => notifier.value;

  Future<void> setMode(ThemeMode mode) async {
    notifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _toString(mode));
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static ThemeMode _fromString(String? s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _toString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
}
