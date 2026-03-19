// lib/features/auth/data/auth_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  // ── Sign in ──────────────────────────────────────────────────────────────

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  // ── Sign up / register ───────────────────────────────────────────────────

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? role,
    Map<String, dynamic>? data,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: {...?data, if (role != null) 'role': role},
      );

  // ── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() => _client.auth.signOut();

  // ── Password reset ───────────────────────────────────────────────────────

  Future<void> sendPasswordReset({required String email}) =>
      _client.auth.resetPasswordForEmail(email);

  /// Alias kept for compatibility with older call sites.
  Future<void> resetPassword(String email) =>
      sendPasswordReset(email: email);

  // ── Email verification ───────────────────────────────────────────────────

  /// Resends the email verification / OTP to the given address.
  Future<void> resendVerification({required String email}) =>
      _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );

  /// Marks the user's email as verified by updating their profile metadata.
  /// Called from VerifyEmailPage after the OTP/magic-link is confirmed.
  Future<void> markEmailVerified(String userId) async {
    await _client.auth.updateUser(
      UserAttributes(data: {'email_verified': true}),
    );
  }

  // ── Session / user accessors ─────────────────────────────────────────────

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}