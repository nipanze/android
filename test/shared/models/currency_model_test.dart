import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/shared/models/currency_model.dart';

void main() {
  group('CurrencyModel', () {
    test('fromMap parses all fields', () {
      final currency = CurrencyModel.fromMap({
        'code': 'UGX',
        'name': 'Ugandan Shilling',
        'is_market_currency': true,
        'market_country': 'UG',
        'forex_trading_enabled': true,
      });

      expect(currency.code, 'UGX');
      expect(currency.name, 'Ugandan Shilling');
      expect(currency.isMarketCurrency, isTrue);
      expect(currency.marketCountry, 'UG');
      expect(currency.forexTradingEnabled, isTrue);
    });

    test('fromMap defaults missing fields', () {
      final currency = CurrencyModel.fromMap({'code': 'USD'});

      expect(currency.code, 'USD');
      expect(currency.name, 'USD');
      expect(currency.isMarketCurrency, isFalse);
      expect(currency.marketCountry, isNull);
      expect(currency.forexTradingEnabled, isFalse);
    });

    test('equality across same data', () {
      final a = CurrencyModel.fromMap({'code': 'KES', 'name': 'Kenya'});
      final b = CurrencyModel.fromMap({'code': 'KES', 'name': 'Kenya'});
      expect(a, equals(b));
    });
  });
}
