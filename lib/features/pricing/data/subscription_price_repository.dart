// lib/features/pricing/data/subscription_price_repository.dart

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/country_constants.dart';

/// Holds live prices for a single country fetched from `subscription_prices`.
class SubscriptionPriceData {
  const SubscriptionPriceData({
    required this.countryCode,
    required this.currencyCode,
    required this.lenderAmount,
    required this.proAmount,
    required this.lenderMinorUnits,
    required this.proMinorUnits,
  });

  final String countryCode;
  final String currencyCode;
  final double lenderAmount;
  final double proAmount;
  final int lenderMinorUnits;
  final int proMinorUnits;

  /// Formatted display strings, e.g. "UGX 19,900"
  String get lenderAmountFormatted =>
      '${_fmt(lenderAmount)} $currencyCode';

  String get proAmountFormatted =>
      '${_fmt(proAmount)} $currencyCode';

  static String _fmt(double v) {
    // Integer-safe: show comma-separated whole number
    final asInt = v.round();
    return asInt.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
  }

  /// Build fallback from hardcoded [CountryInfo] constants so the app
  /// always has usable values even when offline or before the DB row exists.
  factory SubscriptionPriceData.fromCountryInfo(CountryInfo info) {
    // Parse amounts from the formatted strings stored in constants,
    // e.g. "UGX 19,900"  →  19900
    double parsePriceStr(String formatted) {
      final stripped = formatted
          .replaceAll(RegExp(r'[A-Z]+'), '')
          .replaceAll(',', '')
          .trim();
      return double.tryParse(stripped) ?? 0;
    }

    final lender = parsePriceStr(info.lenderPriceFormatted);
    final pro = parsePriceStr(info.proPriceFormatted);
    return SubscriptionPriceData(
      countryCode: info.code,
      currencyCode: info.currency,
      lenderAmount: lender,
      proAmount: pro,
      lenderMinorUnits: lender.round(),
      proMinorUnits: pro.round(),
    );
  }
}

/// Fetches subscription prices from the `subscription_prices` table.
/// Results are cached in memory for [_ttl] to avoid repeated round-trips
/// while navigating the pricing page.
@lazySingleton
class SubscriptionPriceRepository {
  SubscriptionPriceRepository(this._client);

  final SupabaseClient _client;

  static const _ttl = Duration(minutes: 5);
  final Map<String, _CacheEntry> _cache = {};

  /// Returns DB prices for [countryCode], or falls back to hardcoded
  /// [CountryInfo] values on any error so the UI is never blocked.
  Future<SubscriptionPriceData> getPricesForCountry(
    String countryCode, {
    bool forceRefresh = false,
  }) async {
    final upper = countryCode.toUpperCase();
    final entry = _cache[upper];
    if (!forceRefresh &&
        entry != null &&
        DateTime.now().isBefore(entry.expiresAt)) {
      return entry.data;
    }

    try {
      final rows = await _client
          .from(TableNames.subscriptionPrices)
          .select('plan, price_amount, price_minor_units, currency_code')
          .eq('country_code', upper);

      String currency = '';
      double lender = 0;
      double pro = 0;
      int lenderMinor = 0;
      int proMinor = 0;

      for (final row in (rows as List<dynamic>)) {
        final plan = row['plan'] as String;
        final amount = (row['price_amount'] as num).toDouble();
        final minor = (row['price_minor_units'] as num).toInt();
        currency = row['currency_code'] as String;
        if (plan == 'lender') {
          lender = amount;
          lenderMinor = minor;
        } else if (plan == 'pro') {
          pro = amount;
          proMinor = minor;
        }
      }

      // If nothing came back, fall through to fallback
      if (currency.isEmpty) throw Exception('no rows');

      final data = SubscriptionPriceData(
        countryCode: upper,
        currencyCode: currency,
        lenderAmount: lender,
        proAmount: pro,
        lenderMinorUnits: lenderMinor,
        proMinorUnits: proMinor,
      );

      _cache[upper] = _CacheEntry(
        data: data,
        expiresAt: DateTime.now().add(_ttl),
      );
      return data;
    } catch (_) {
      // Graceful fallback — never throw to the UI
      final info = EastAfricaCountries.findByCode(upper);
      return SubscriptionPriceData.fromCountryInfo(info);
    }
  }

  /// Clears cached entry for a country (e.g. after admin save propagates).
  void invalidate(String countryCode) =>
      _cache.remove(countryCode.toUpperCase());

  /// Clears the entire in-memory cache.
  void invalidateAll() => _cache.clear();
}

class _CacheEntry {
  const _CacheEntry({required this.data, required this.expiresAt});
  final SubscriptionPriceData data;
  final DateTime expiresAt;
}
