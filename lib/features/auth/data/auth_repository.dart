// lib/features/auth/data/auth_repository.dart
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/errors/app_exception.dart';
import '../domain/models/nipanze_user.dart';

@lazySingleton
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

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
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
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

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } catch (e) {
      throw parseSupabaseError(e);
    }
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

  Future<NipanzeUser> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No current user authenticated.');
    }
    return _fetchProfile(user.id, user.email ?? '');
  }

  Future<NipanzeUser> _fetchProfile(String id, String email) async {
    // ── 1. Profile ──────────────────────────────────────────────────────────
    Map<String, dynamic>? data;
    try {
      data = await _client
          .from('profiles')
          .select('id, full_name, phone, district, employment_type, employer_name, monthly_income_ugx, is_admin')
          .eq('id', id)
          .maybeSingle();
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
          .maybeSingle();
      if (kycData != null) {
        kycStatus = (kycData['status'] as String?) ?? 'not_submitted';
      }
    } catch (e) {
      debugPrint('DEBUG: KYC fetch error: $e');
    }

    // ── 3. Subscription via SECURITY DEFINER RPC ─────────────────────────────
    String subPlan = 'free';
    try {
      final result = await _client.rpc('get_my_subscription_plan');
      if (result != null) {
        subPlan = result.toString();
      } else {
        // Fallback: query subscriptions table directly
        final subData = await _client
            .from('subscriptions')
            .select('plan')
            .eq('user_id', id)
            .eq('status', 'active')
            .maybeSingle();
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
            .maybeSingle();
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

  /// Update the current user's profile fields.
  Future<void> updateProfile({
    String? fullName,
    String? district,
    String? employmentType,
    String? employerName,
    int? monthlyIncomeUgx,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (district != null) updates['district'] = district;
    if (employmentType != null) updates['employment_type'] = employmentType;
    if (employerName != null) updates['employer_name'] = employerName;
    if (monthlyIncomeUgx != null) updates['monthly_income_ugx'] = monthlyIncomeUgx;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', userId);
  }
}
