import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/app_constants.dart';
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

  Future<NipanzeUser> _fetchProfile(String id, String email) async {
    // ── 1. Profile + KYC ────────────────────────────────────────────────────
    Map<String, dynamic>? data;
    try {
      data = await _client
          .from('profiles')
          .select(
              'id, full_name, phone, district, credit_score, reputation_tier, lender_token, role, kyc_verifications(status)')
          .eq('id', id)
          .maybeSingle();
    } catch (_) {
      // If profile fetch fails entirely, return a bare user
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

    // ── 2. Subscription via SECURITY DEFINER RPC ─────────────────────────────
    // Prefer the RPC since it bypasses RLS, but fall back to the
    // `v_user_marketplace_activity` view if the RPC returns NULL.
    String subPlan = 'watchlist';
    try {
      final result = await _client.rpc('get_my_subscription_plan');
      if (result != null) {
        subPlan = result.toString();
      } else {
        // RPC returned NULL when executed from some environments —
        // fall back to querying the view (authenticated caller).
        try {
          // The view is `security_invoker=true` and RLS on `profiles`
          // already restricts results to the calling user. Call the
          // view without an explicit `user_id` filter so the DB-side
          // RLS can apply `auth.uid()` correctly for the authenticated
          // client session.
          final row = await _client
              .from(ViewNames.userMarketplaceActivity)
              .select('subscription_plan')
              .maybeSingle();
          debugPrint('DEBUG: fallback view row: $row');
          if (row != null && row['subscription_plan'] != null) {
            subPlan = row['subscription_plan'] as String;
          }
        } catch (e) {
          debugPrint('DEBUG: fallback view error: $e');
          // ignore fallback errors; keep default plan
        }
      }
      debugPrint('DEBUG: get_my_subscription_plan result: $result');
    } catch (e) {
      debugPrint('DEBUG: get_my_subscription_plan error: $e');
    }

    // ── 3. KYC status ────────────────────────────────────────────────────────
    final kycStatus =
        (data['kyc_verifications'] as List?)?.firstOrNull?['status'] ??
            'not_submitted';

    return NipanzeUser.fromMap({
      ...data,
      'email': email,
      'subscription_plan': subPlan,
      'kyc_status': kycStatus,
      'is_email_verified': _client.auth.currentUser?.emailConfirmedAt != null,
    });
  }
}
