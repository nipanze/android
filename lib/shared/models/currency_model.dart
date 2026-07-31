import 'package:equatable/equatable.dart';

class CurrencyModel extends Equatable {
  const CurrencyModel({
    required this.code,
    required this.name,
    this.isMarketCurrency = false,
    this.marketCountry,
    this.forexTradingEnabled = false,
  });

  final String code;
  final String name;
  final bool isMarketCurrency;
  final String? marketCountry;
  final bool forexTradingEnabled;

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      code: map['code'] as String,
      name: map['name'] as String? ?? map['code'] as String,
      isMarketCurrency: map['is_market_currency'] as bool? ?? false,
      marketCountry: map['market_country'] as String?,
      forexTradingEnabled: map['forex_trading_enabled'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        code,
        name,
        isMarketCurrency,
        marketCountry,
        forexTradingEnabled,
      ];
}
