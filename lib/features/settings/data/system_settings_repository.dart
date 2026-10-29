// lib/features/settings/data/system_settings_repository.dart
// ignore_for_file: unused_import

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/domain/models/nipanze_user.dart';

/// Public platform limits read from system_settings at runtime.
/// These are the only fields exposed to the client (is_public = TRUE).
class PlatformLimits {
  const PlatformLimits({
    this.minLoanAmount = 100000,
    this.maxLoanAmount = 50000000,
    this.minInterestRate = 5,
    this.maxInterestRate = 30,
    this.minLenderInvestment = 100000,
    this.maxActiveRequestsFree = 3,
    this.maxActiveRequestsLender = 8,
    this.maxActiveRequestsPro = 20,
    this.maxActiveResponsesLender = 10,
    this.listingDurationDays = 30,
    this.forexListingDurationDays = 7,
    this.needsDurationByCategory = const {
      'machinery_equipment': 14,
      'professional_services': 14,
      'transport_logistics': 7,
      'specialized_products': 14,
      'travel_international': 14,
    },
    this.marketRateBaselinePct = 10.0,
  });

  final int minLoanAmount;
  final int maxLoanAmount;
  final double minInterestRate;
  final double maxInterestRate;
  final int minLenderInvestment;
  final int maxActiveRequestsFree;
  final int maxActiveRequestsLender;
  final int maxActiveRequestsPro;
  final int maxActiveResponsesLender;
  final int listingDurationDays;
  final int forexListingDurationDays;
  final Map<String, int> needsDurationByCategory;
  final double marketRateBaselinePct;

  int maxActiveRequestsFor(SubscriptionPlan plan) => switch (plan) {
        SubscriptionPlan.free => maxActiveRequestsFree,
        SubscriptionPlan.lender => maxActiveRequestsLender,
        SubscriptionPlan.pro => maxActiveRequestsPro,
      };

  int durationForNeedsCategory(String slug) =>
      needsDurationByCategory[slug] ??
      switch (slug) {
        'machinery_equipment' => 14,
        'professional_services' => 14,
        'transport_logistics' => 7,
        'specialized_products' => 14,
        'travel_international' => 14,
        _ => 14,
      };

  /// Fallback defaults match the schema seed values.
  static const PlatformLimits defaults = PlatformLimits();
}

@lazySingleton
class SystemSettingsRepository {
  SystemSettingsRepository(this._client);

  final SupabaseClient _client;

  PlatformLimits? _cached;

  /// Returns cached limits or fetches from DB.
  /// Falls back to [PlatformLimits.defaults] on any error so the
  /// app always has usable values.
  Future<PlatformLimits> getLimits({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached!;

    try {
      final data = await _client
          .from(TableNames.systemSettings)
          .select('setting_key, setting_value')
          .eq('is_public', true);

      final map = <String, String>{};
      for (final row in (data as List)) {
        map[row['setting_key'] as String] = row['setting_value'] as String;
      }

      _cached = PlatformLimits(
        minLoanAmount: int.tryParse(map['min_loan_amount'] ?? '') ?? 100000,
        maxLoanAmount: int.tryParse(map['max_loan_amount'] ?? '') ?? 50000000,
        minInterestRate: double.tryParse(map['min_interest_rate'] ?? '') ?? 5,
        maxInterestRate: double.tryParse(map['max_interest_rate'] ?? '') ?? 30,
        minLenderInvestment:
            int.tryParse(map['min_lender_investment'] ?? '') ?? 100000,
        maxActiveRequestsFree:
            int.tryParse(map['max_active_requests_free'] ?? '') ??
                int.tryParse(map['max_concurrent_requests'] ?? '') ??
                3,
        maxActiveRequestsLender:
            int.tryParse(map['max_active_requests_lender'] ?? '') ?? 8,
        maxActiveRequestsPro:
            int.tryParse(map['max_active_requests_pro'] ?? '') ?? 20,
        maxActiveResponsesLender:
            int.tryParse(map['max_active_responses_lender'] ?? '') ?? 10,
        listingDurationDays:
            int.tryParse(map['listing_duration_days'] ?? '') ?? 30,
        forexListingDurationDays:
            int.tryParse(map['forex_listing_duration_days'] ?? '') ?? 7,
        needsDurationByCategory: {
          'machinery_equipment': int.tryParse(
                  map['needs_default_duration_machinery_equipment_days'] ??
                      '') ??
              14,
          'professional_services': int.tryParse(
                  map['needs_default_duration_professional_services_days'] ??
                      '') ??
              14,
          'transport_logistics': int.tryParse(
                  map['needs_default_duration_transport_logistics_days'] ??
                      '') ??
              7,
          'specialized_products': int.tryParse(
                  map['needs_default_duration_specialized_products_days'] ??
                      '') ??
              14,
          'travel_international': int.tryParse(
                  map['needs_default_duration_travel_international_days'] ??
                      '') ??
              14,
        },
        marketRateBaselinePct: double.tryParse(
                map['market_interest_rate_baseline_pct'] ??
                    map['market_rate_baseline_pct'] ??
                    '') ??
            10.0,
      );
      return _cached!;
    } catch (_) {
      return PlatformLimits.defaults;
    }
  }
}
