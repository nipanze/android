// lib/features/account/data/profile_repository.dart
import 'dart:typed_data';

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

  /// Full profile from v_user_marketplace_activity joined with profiles.
  Future<UserProfile?> getProfile() async {
    try {
      // Run queries independently so a missing view or column (e.g. cloud DB
      // not yet patched) degrades gracefully instead of failing the whole load.
      final activityFuture = _client
          .from(ViewNames.userMarketplaceActivity)
          .select()
          .eq('user_id', _uid)
          .maybeSingle()
          .catchError((_) => null);

      // Use SELECT * so the query never fails on missing columns — new fields
      // added in later patches (e.g. preferred_employment_types from v4.5)
      // will be null-coalesced below when not present.
      final profileFuture = _client
          .from(TableNames.profiles)
          .select()
          .eq('id', _uid)
          .maybeSingle()
          .catchError((_) => null);

      final trustFuture = _client
          .from(ViewNames.trustProfilePublic)
          .select()
          .eq('user_id', _uid)
          .maybeSingle()
          .catchError((_) => null);

      final proTrustFuture = _client
          .from(ViewNames.trustProfilePro)
          .select()
          .eq('user_id', _uid)
          .maybeSingle()
          .catchError((_) => null);

      final results = await Future.wait([
        activityFuture,
        profileFuture,
        trustFuture,
        proTrustFuture,
      ]);

      final activity = results[0];
      final profile = results[1];
      final trust = results[2];
      final proTrust = results[3];

      if (activity == null && profile == null) return null;

      final email = _client.auth.currentUser?.email ?? '';

      return UserProfile(
        id: _uid,
        email: email,
        fullName: profile?['full_name'] as String?,
        avatarUrl: profile?['avatar_url'] as String?,
        phone: profile?['phone'] as String?,
        district: profile?['district'] as String?,
        employmentType: profile?['employment_type'] as String?,
        employerName: profile?['employer_name'] as String?,
        monthlyIncome: (profile?['monthly_income'] as num?)?.toInt(),
        incomeCurrency: profile?['income_currency'] as String? ?? 'UGX',
        preferredBank: profile?['preferred_bank'] as String?,
        institutionType: profile?['institution_type'] as String?,
        isBankAgent: profile?['is_bank_agent'] as bool? ?? false,
        showProfessionalTag: profile?['show_professional_tag'] as bool? ?? true,
        preferredEmploymentTypes: profile?['preferred_employment_types'] == null
            ? null
            : List<String>.from(profile!['preferred_employment_types'] as List),
        preferredIncomeBracket: profile?['preferred_income_bracket'] as String?,
        prefersSuggestedTerms:
            profile?['prefers_suggested_terms'] as bool? ?? false,
        prefersVerifiedOnly:
            profile?['prefers_verified_only'] as bool? ?? false,
        accountStatus: profile?['account_status'] as String? ?? 'active',
        memberSince: profile?['created_at'] != null
            ? DateTime.tryParse(profile!['created_at'] as String)
            : null,
        subscriptionPlan: activity?['subscription_plan'] as String?,
        subscriptionStatus: activity?['subscription_status'] as String?,
        subscriptionExpiresAt: activity?['subscription_expires_at'] != null
            ? DateTime.tryParse(activity!['subscription_expires_at'] as String)
            : null,
        kycStatus: activity?['kyc_status'] as String?,
        kycExpiresAt: activity?['kyc_expires_at'] != null
            ? DateTime.tryParse(activity!['kyc_expires_at'] as String)
            : null,
        trustRatingAvg: (trust?['rating_avg'] as num?)?.toDouble(),
        trustReviewCount: (trust?['review_count'] as num?)?.toInt() ?? 0,
        trustCompletedDealsCount:
            (trust?['completed_deals_count'] as num?)?.toInt() ?? 0,
        trustIsRepeatParticipant:
            trust?['is_repeat_participant'] as bool? ?? false,
        trustPhoneVerified: trust?['phone_verified'] as bool? ?? false,
        trustResponseTimeBucket: trust?['response_time_bucket'] as String?,
        trustIsVerified: trust?['is_verified'] as bool? ?? false,
        trustSuccessRate: (proTrust?['success_rate'] as num?)?.toDouble(),
        trustReliabilityScore:
            (proTrust?['reliability_score'] as num?)?.toInt(),
        activeListings: (activity?['active_listings'] as int?) ?? 0,
        activeOffers: (activity?['active_offers'] as int?) ?? 0,
        revealedContacts: (activity?['revealed_contacts'] as int?) ?? 0,
        freeUnlocksRemaining: (profile?['free_unlocks_remaining'] as int?) ?? 1,
        referralCode: profile?['referral_code'] as String?,
        referredBy: profile?['referred_by'] as String?,
        referralStatus: profile?['referral_status'] as String? ?? 'none',
        marketingEnabled: profile?['marketing_enabled'] as bool? ?? false,
        marketingCountry: profile?['marketing_country'] as String?,
        marketingJoinedAt: profile?['marketing_joined_at'] != null
            ? DateTime.tryParse(profile!['marketing_joined_at'] as String)
            : null,
      );
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Upload avatar image bytes to Supabase Storage bucket and return public URL.
  Future<String> uploadAvatarBytes(List<int> bytes, String fileExt) async {
    try {
      final cleanExt = fileExt.replaceAll('.', '').toLowerCase();
      final ext = cleanExt.isEmpty ? 'jpg' : cleanExt;
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final path =
          '$_uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      try {
        await _client.storage.from('avatars').uploadBinary(
              path,
              Uint8List.fromList(bytes),
              fileOptions: FileOptions(upsert: true, contentType: mimeType),
            );
        return _client.storage.from('avatars').getPublicUrl(path);
      } catch (_) {
        // Fallback to kyc-documents bucket if avatars bucket does not exist
        await _client.storage.from(StorageBuckets.kycDocuments).uploadBinary(
              path,
              Uint8List.fromList(bytes),
              fileOptions: FileOptions(upsert: true, contentType: mimeType),
            );
        return await _client.storage
            .from(StorageBuckets.kycDocuments)
            .createSignedUrl(path, 60 * 60 * 24 * 365);
      }
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Update editable profile fields.
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
    bool clearAvatar = false,
    String? phone,
    String? district,
    String? employmentType,
    String? employerName,
    int? monthlyIncome,
    String? incomeCurrency,
    List<String>? preferredEmploymentTypes,
    String? preferredIncomeBracket,
    bool? prefersSuggestedTerms,
    bool? prefersVerifiedOnly,
    String? preferredBank,
    String? institutionType,
    bool? isBankAgent,
    bool? showProfessionalTag,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (clearAvatar) {
        updates['avatar_url'] = null;
      } else if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl.isEmpty ? null : avatarUrl;
      }
      if (phone != null) updates['phone'] = phone;
      if (district != null) updates['district'] = district;
      if (employmentType != null) updates['employment_type'] = employmentType;
      if (employerName != null) updates['employer_name'] = employerName;
      if (monthlyIncome != null) {
        updates['monthly_income'] = monthlyIncome;
      }
      if (incomeCurrency != null) {
        updates['income_currency'] = incomeCurrency;
      }
      if (preferredBank != null) {
        updates['preferred_bank'] =
            preferredBank.trim().isEmpty ? null : preferredBank.trim();
      }
      if (institutionType != null) {
        updates['institution_type'] =
            (institutionType.isEmpty || institutionType == 'none')
                ? null
                : institutionType;
      }
      if (isBankAgent != null) updates['is_bank_agent'] = isBankAgent;
      if (showProfessionalTag != null) {
        updates['show_professional_tag'] = showProfessionalTag;
      }
      if (preferredEmploymentTypes != null) {
        updates['preferred_employment_types'] = preferredEmploymentTypes;
      }
      if (preferredIncomeBracket != null) {
        updates['preferred_income_bracket'] = preferredIncomeBracket;
      }
      if (prefersSuggestedTerms != null) {
        updates['prefers_suggested_terms'] = prefersSuggestedTerms;
      }
      if (prefersVerifiedOnly != null) {
        updates['prefers_verified_only'] = prefersVerifiedOnly;
      }

      if (updates.isEmpty) return;

      await _client.from(TableNames.profiles).update(updates).eq('id', _uid);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Consume one free unlock credit for a Free plan user.
  /// Returns the remaining count after decrement.
  /// Throws if the user has no credits remaining.
  Future<int> consumeFreeUnlock() async {
    try {
      final result = await _client.rpc('consume_free_unlock') as int?;
      return result ?? 0;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}
