// lib/features/auth/data/auth_repository.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/errors/app_exception.dart';
import '../../referrals/data/referral_repository.dart';
import '../domain/models/nipanze_user.dart';

@lazySingleton
class AuthRepository {
  AuthRepository(this._client, this._referralRepository);

  final SupabaseClient _client;
  final ReferralRepository _referralRepository;

  Stream<NipanzeUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) return null;
      return _fetchProfile(session.user.id, session.user.email ?? '');
    });
  }

  NipanzeUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return NipanzeUser(id: user.id, email: user.email ?? '');
  }

  bool get isEmailVerified =>
      _client.auth.currentUser?.emailConfirmedAt != null;

  Future<NipanzeUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth
          .signInWithPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      final user = response.user;
      if (user == null) {
        throw const AuthException('Sign in failed. Please try again.');
      }
      return await _fetchProfile(user.id, user.email ?? email);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? countryCode,
    String? referralCode,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (phone != null) 'phone': phone,
          if (countryCode != null) 'country_code': countryCode,
          if (referralCode != null && referralCode.trim().isNotEmpty)
            'referral_code': referralCode.trim(),
        },
      ).timeout(const Duration(seconds: 15));
      return res.user;
    } catch (e) {
      debugPrint('signUp error: $e');
      throw parseSupabaseError(e);
    }
  }

  Future<void> attributeReferral({
    required String referralCode,
    String source = 'registration',
  }) {
    return _referralRepository.attributeReferral(
      referralCode: referralCode,
      source: source,
    );
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> resendVerificationEmail() async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return;
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> updateAuthEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;
    try {
      await _client.auth.updateUser(UserAttributes(email: cleanEmail));
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<NipanzeUser> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No current user authenticated.');
    }
    return _fetchProfile(user.id, user.email ?? '');
  }

  String cleanPhone(String phone) {
    var clean = phone.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (clean.startsWith('0') && clean.length == 10) {
      clean = '+256${clean.substring(1)}';
    } else if (!clean.startsWith('+')) {
      clean = '+$clean';
    }
    return clean;
  }

  Future<String?> checkPhoneRegistered(String phone) async {
    try {
      final clean = cleanPhone(phone);
      final response = await _client.rpc('check_phone_registered',
          params: {'p_phone': clean}).timeout(const Duration(seconds: 10));
      return response as String?;
    } catch (e) {
      debugPrint('Error in checkPhoneRegistered RPC: $e');
      return null;
    }
  }

  Future<String?> checkLoginRegistered(String login) async {
    try {
      final clean = login.trim();
      final lookup = clean.contains('@') ? clean : cleanPhone(clean);
      final response = await _client.rpc('check_phone_registered',
          params: {'p_phone': lookup}).timeout(const Duration(seconds: 10));
      return response as String?;
    } catch (e) {
      debugPrint('Error in checkLoginRegistered RPC: $e');
      return null;
    }
  }

  Future<NipanzeUser> _fetchProfile(String id, String email) async {
    // ── 1. Profile ──────────────────────────────────────────────────────────
    Map<String, dynamic>? data;
    try {
      data = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('DEBUG: profiles fetch error: $e');
      return NipanzeUser(
        id: id,
        email: email,
        isEmailVerified: _client.auth.currentUser?.emailConfirmedAt != null,
      );
    }

    if (data == null) {
      return NipanzeUser(
        id: id,
        email: email,
        isEmailVerified: _client.auth.currentUser?.emailConfirmedAt != null,
      );
    }

    // ── 2. KYC Status (isolated query) ───────────────────────────────────────
    String kycStatus = 'not_submitted';
    try {
      final kycData = await _client
          .from('kyc_verifications')
          .select('status')
          .eq('user_id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      if (kycData != null) {
        kycStatus = (kycData['status'] as String?) ?? 'not_submitted';
      }
    } catch (e) {
      debugPrint('DEBUG: KYC fetch error: $e');
    }

    // ── 3. Subscription via SECURITY DEFINER RPC ─────────────────────────────
    String subPlan = 'free';
    try {
      final result = await _client
          .rpc('get_my_subscription_plan')
          .timeout(const Duration(seconds: 8));
      if (result != null) {
        subPlan = result.toString();
      } else {
        // Fallback: query subscriptions table directly
        final subData = await _client
            .from('subscriptions')
            .select('plan')
            .eq('user_id', id)
            .eq('status', 'active')
            .maybeSingle()
            .timeout(const Duration(seconds: 8));
        if (subData != null) {
          subPlan = (subData['plan'] as String?) ?? 'free';
        }
      }
      debugPrint('DEBUG: get_my_subscription_plan result: $result');
    } catch (e) {
      debugPrint('DEBUG: get_my_subscription_plan error: $e');
      // Fallback: query subscriptions table directly
      try {
        final subData = await _client
            .from('subscriptions')
            .select('plan')
            .eq('user_id', id)
            .eq('status', 'active')
            .maybeSingle()
            .timeout(const Duration(seconds: 8));
        if (subData != null) {
          subPlan = (subData['plan'] as String?) ?? 'free';
        }
      } catch (fallbackErr) {
        debugPrint('DEBUG: subscriptions fallback query error: $fallbackErr');
      }
    }

    return NipanzeUser.fromMap({
      ...data,
      'email': email,
      'subscription_plan': subPlan,
      'kyc_status': kycStatus,
      'is_email_verified': _client.auth.currentUser?.emailConfirmedAt != null,
    });
  }

  /// Upload avatar image bytes for a user to Supabase Storage bucket and return public URL.
  Future<String> uploadAvatarBytes(
      String userId, List<int> bytes, String fileExt) async {
    try {
      final cleanExt = fileExt.replaceAll('.', '').toLowerCase();
      final ext = cleanExt.isEmpty ? 'jpg' : cleanExt;
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final path =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      try {
        await _client.storage.from('avatars').uploadBinary(
              path,
              Uint8List.fromList(bytes),
              fileOptions: FileOptions(upsert: true, contentType: mimeType),
            );
        return _client.storage.from('avatars').getPublicUrl(path);
      } catch (_) {
        await _client.storage.from('kyc-documents').uploadBinary(
              path,
              Uint8List.fromList(bytes),
              fileOptions: FileOptions(upsert: true, contentType: mimeType),
            );
        return await _client.storage
            .from('kyc-documents')
            .createSignedUrl(path, 60 * 60 * 24 * 365);
      }
    } catch (e) {
      debugPrint('Error uploading avatar bytes: $e');
      rethrow;
    }
  }

  /// Update profile fields for a user. Accepts an optional explicit [targetUserId].
  Future<void> updateProfile({
    String? targetUserId,
    String? fullName,
    String? avatarUrl,
    bool clearAvatar = false,
    String? phone,
    String? country,
    String? district,
    String? streetAddress,
    String? employmentType,
    String? employerName,
    int? monthlyIncome,
    String? incomeCurrency,
    String? preferredBank,
    String? institutionType,
    bool? isBankAgent,
    bool? showProfessionalTag,
  }) async {
    final userId = targetUserId ?? _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('updateProfile called but userId is null');
      return;
    }
    final updates = <String, dynamic>{
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (clearAvatar) {
      updates['avatar_url'] = null;
    } else if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl.isEmpty ? null : avatarUrl;
    }
    if (phone != null) updates['phone'] = phone;
    if (country != null) updates['country'] = country;
    if (district != null) updates['district'] = district;
    if (streetAddress != null) updates['street_address'] = streetAddress;
    if (employmentType != null) updates['employment_type'] = employmentType;
    if (employerName != null) updates['employer_name'] = employerName;
    if (monthlyIncome != null) updates['monthly_income'] = monthlyIncome;
    if (incomeCurrency != null) updates['income_currency'] = incomeCurrency;
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

    try {
      await _client.from('profiles').upsert(updates);
    } catch (e) {
      debugPrint('Error upserting profile: $e');
      try {
        await _client.from('profiles').update(updates).eq('id', userId);
      } catch (err2) {
        debugPrint('Fallback profile update error: $err2');
      }
    }
  }
}
