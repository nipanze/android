// lib/features/account/data/profile_repository.dart
import 'package:injectable/injectable.dart';
import 'package:nipanze/features/account/domain/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';

@lazySingleton
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// Full profile from v_user_portfolio joined with profiles.
  Future<UserProfile?> getProfile() async {
    try {
      // Fetch portfolio view (subscription, kyc, counts)
      final portfolio = await _client
          .from(ViewNames.userPortfolio)
          .select()
          .eq('user_id', _uid)
          .maybeSingle();

      // Fetch raw profile fields not in view
      final profile = await _client
          .from(TableNames.profiles)
          .select('full_name, phone, district, employment_type, employer_name, monthly_income_ugx, lender_token, account_status')
          .eq('id', _uid)
          .maybeSingle();

      if (portfolio == null && profile == null) return null;

      final email = _client.auth.currentUser?.email ?? '';

      return UserProfile(
        id:             _uid,
        email:          email,
        fullName:       profile?['full_name']       as String?,
        phone:          profile?['phone']           as String?,
        district:       profile?['district']        as String?,
        employmentType: profile?['employment_type'] as String?,
        employerName:   profile?['employer_name']   as String?,
        monthlyIncomeUgx: (profile?['monthly_income_ugx'] as num?)?.toInt(),
        creditScore:    portfolio?['credit_score']  as int?    ?? 50,
        reputationTier: portfolio?['reputation_tier'] as String? ?? 'bronze',
        lenderToken:    profile?['lender_token']    as String?  ?? '',
        accountStatus:  profile?['account_status']  as String?  ?? 'active',
        subscriptionPlan:    portfolio?['subscription_plan']       as String?,
        subscriptionStatus:  portfolio?['subscription_status']     as String?,
        subscriptionExpiresAt: portfolio?['subscription_expires_at'] != null
            ? DateTime.tryParse(portfolio!['subscription_expires_at'] as String)
            : null,
        kycStatus:    portfolio?['kyc_status']    as String?,
        kycExpiresAt: portfolio?['kyc_expires_at'] != null
            ? DateTime.tryParse(portfolio!['kyc_expires_at'] as String)
            : null,
        activeListings:       (portfolio?['active_listings']        as int?) ?? 0,
        contractedAsBorrower: (portfolio?['contracted_as_borrower'] as int?) ?? 0,
        activeBids:           (portfolio?['active_bids']            as int?) ?? 0,
        contractedAsLender:   (portfolio?['contracted_as_lender']   as int?) ?? 0,
      );
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Update editable profile fields.
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? district,
    String? employmentType,
    String? employerName,
    int?    monthlyIncomeUgx,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName        != null) updates['full_name']         = fullName;
      if (phone           != null) updates['phone']             = phone;
      if (district        != null) updates['district']          = district;
      if (employmentType  != null) updates['employment_type']   = employmentType;
      if (employerName    != null) updates['employer_name']     = employerName;
      if (monthlyIncomeUgx != null) updates['monthly_income_ugx'] = monthlyIncomeUgx;

      if (updates.isEmpty) return;

      await _client
          .from(TableNames.profiles)
          .update(updates)
          .eq('id', _uid);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}