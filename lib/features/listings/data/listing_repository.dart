import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/my_listing.dart';

@lazySingleton
class ListingRepository {
  ListingRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// Fetch all loan requests belonging to the current borrower.
  Future<List<MyListing>> getMyListings() async {
    try {
      final data = await _client
          .from(TableNames.loanRequests)
          .select(
            'id, title, purpose, district, country, countries(currency_code), duration_months, requested_amount, '
            'income_source, preferred_repayment_plan, repayment_amount_per_period, '
            'repayment_timeline, suggested_interest_rate_pct, suggested_late_fee_pct, '
            'suggested_repayment_frequency, suggested_installment_amount, terms_locked_at, '
            'has_collateral, collateral_details, collateral_estimated_value, collateral_location, '
            'status, number_of_offers, '
            'listed_at, expires_at, contracted_at, cancelled_at',
          )
          .eq('borrower_id', _uid)
          .order('listed_at', ascending: false);

      return (data as List).map((e) => MyListing.fromMap(e)).toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Create a new loan request. All DB-level guards (KYC, subscription,
  /// max_concurrent_loans, expiry) are enforced by triggers server-side.
  Future<String> createListing({
    required String title,
    required String purpose,
    required int requestedAmount,
    required int durationMonths,
    required String district,
    required String incomeSource,
    required String preferredRepaymentPlan,
    required int repaymentAmountPerPeriod,
    required String repaymentTimeline,
    double? suggestedInterestRatePct,
    double? suggestedLateFeePct,
    String? suggestedRepaymentFrequency,
    int? suggestedInstallmentAmount,
    bool hasCollateral = false,
    String? collateralDetails,
    int? collateralEstimatedValue,
    String? collateralLocation,
    String country = 'UG',
  }) async {
    try {
      final cleanCollateralDetails = collateralDetails?.trim();
      final cleanCollateralLocation = collateralLocation?.trim();
      final data = await _client
          .from(TableNames.loanRequests)
          .insert({
            'borrower_id': _uid,
            'title': title,
            'purpose': purpose,
            'requested_amount': requestedAmount,
            'duration_months': durationMonths,
            'district': district,
            'income_source': incomeSource,
            'preferred_repayment_plan': preferredRepaymentPlan,
            'repayment_amount_per_period': repaymentAmountPerPeriod,
            'repayment_timeline': repaymentTimeline,
            'country': country,
            'has_collateral': hasCollateral,
            'collateral_details': hasCollateral &&
                    cleanCollateralDetails != null &&
                    cleanCollateralDetails.isNotEmpty
                ? cleanCollateralDetails
                : null,
            'collateral_estimated_value':
                hasCollateral ? collateralEstimatedValue : null,
            'collateral_location': hasCollateral &&
                    cleanCollateralLocation != null &&
                    cleanCollateralLocation.isNotEmpty
                ? cleanCollateralLocation
                : null,
            if (suggestedInterestRatePct != null)
              'suggested_interest_rate_pct': suggestedInterestRatePct,
            if (suggestedLateFeePct != null)
              'suggested_late_fee_pct': suggestedLateFeePct,
            if (suggestedRepaymentFrequency != null)
              'suggested_repayment_frequency': suggestedRepaymentFrequency,
            if (suggestedInstallmentAmount != null)
              'suggested_installment_amount': suggestedInstallmentAmount,
          })
          .select('id')
          .single();

      return data['id'] as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Cancel an active listing.
  Future<void> cancelListing(String requestId) async {
    try {
      await _client
          .from(TableNames.loanRequests)
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('borrower_id', _uid);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Realtime stream — refreshes whenever any of the current user's
  /// loan_requests rows change.
  Stream<List<MyListing>> watchMyListings() {
    return _client
        .from(TableNames.loanRequests)
        .stream(primaryKey: ['id'])
        .eq('borrower_id', _uid)
        .asyncMap((_) => getMyListings());
  }
}
