import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:nipanze/core/services/localization_fallback.dart';

void main() {
  test('uses English intl formatting for Kinyarwanda', () {
    final localeName = intlLocaleName(const Locale('rw'));

    expect(localeName, 'en');
    expect(NumberFormat.decimalPattern(localeName).format(123456), '123,456');
  });

  test('preserves locales supported by intl', () {
    expect(intlLocaleName(const Locale('fr')), 'fr');
  });
}
