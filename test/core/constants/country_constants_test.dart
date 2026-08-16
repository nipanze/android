import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/core/constants/country_constants.dart';

void main() {
  group('EastAfricaCountries', () {
    test('supports exactly the 7 planned markets', () {
      expect(
        EastAfricaCountries.all.map((c) => c.code),
        ['UG', 'KE', 'TZ', 'RW', 'NG', 'ZA', 'EG'],
      );
    });

    test('every country has complete configuration', () {
      for (final country in EastAfricaCountries.all) {
        expect(country.code, isNotEmpty);
        expect(country.name, isNotEmpty);
        expect(country.flag, isNotEmpty);
        expect(country.dialCode, startsWith('+'));
        expect(country.currency, hasLength(3));
        expect(country.regions, isNotEmpty);
        expect(country.lenderPriceFormatted, isNotEmpty);
        expect(country.proPriceFormatted, isNotEmpty);
      }
    });

    test('findByCode returns matching country or default', () {
      expect(EastAfricaCountries.findByCode('KE').name, 'Kenya');
      expect(EastAfricaCountries.findByCode('TZ').currency, 'TZS');
      expect(EastAfricaCountries.findByCode('XX').code, 'UG');
      expect(EastAfricaCountries.findByCode(null).code, 'UG');
      expect(EastAfricaCountries.findByCode('').code, 'UG');
    });

    test('findByCode resolves legacy countries', () {
      expect(EastAfricaCountries.findByCode('BI').name, 'Burundi');
      expect(EastAfricaCountries.findByCode('SS').currency, 'SSP');
    });

    test('findByLocale matches country code case-insensitively', () {
      expect(
        EastAfricaCountries.findByLocale(const Locale('en', 'ng')).name,
        'Nigeria',
      );
      expect(EastAfricaCountries.findByLocale(const Locale('en')).code, 'UG');
      expect(EastAfricaCountries.findByLocale(null).code, 'UG');
    });

    test('findByPhone matches dial codes', () {
      expect(EastAfricaCountries.findByPhone('+254712345678').name, 'Kenya');
      expect(EastAfricaCountries.findByPhone('+256700000000').code, 'UG');
      expect(EastAfricaCountries.findByPhone('+123456').code, 'UG');
      expect(EastAfricaCountries.findByPhone(null).code, 'UG');
      expect(EastAfricaCountries.findByPhone('').code, 'UG');
    });

    test('country currencies map to market codes', () {
      final byCode = {
        for (final c in EastAfricaCountries.all) c.code: c.currency,
      };
      expect(byCode, {
        'UG': 'UGX',
        'KE': 'KES',
        'TZ': 'TZS',
        'RW': 'RWF',
        'NG': 'NGN',
        'ZA': 'ZAR',
        'EG': 'EGP',
      });
    });
  });
}
