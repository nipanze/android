// lib/core/services/localization_fallback.dart
//
// Custom localizations delegates that gracefully fall back to English
// for locales not supported by GlobalMaterialLocalizations /
// GlobalCupertinoLocalizations (e.g. Kinyarwanda 'rw').

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Falls back to English material localizations for unsupported locales.
class SafeMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const SafeMaterialLocalizationsDelegate();

  static const _fallback = Locale('en');

  @override
  bool isSupported(Locale locale) => true; // Accept every locale

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final target = GlobalMaterialLocalizations.delegate.isSupported(locale)
        ? locale
        : _fallback;
    return GlobalMaterialLocalizations.delegate.load(target);
  }

  @override
  bool shouldReload(SafeMaterialLocalizationsDelegate old) => false;
}

/// Falls back to English cupertino localizations for unsupported locales.
class SafeCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const SafeCupertinoLocalizationsDelegate();

  static const _fallback = Locale('en');

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final target = GlobalCupertinoLocalizations.delegate.isSupported(locale)
        ? locale
        : _fallback;
    return GlobalCupertinoLocalizations.delegate.load(target);
  }

  @override
  bool shouldReload(SafeCupertinoLocalizationsDelegate old) => false;
}
