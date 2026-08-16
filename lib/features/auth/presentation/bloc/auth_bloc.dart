// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/nipanze_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthLoading()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthProfileRefreshRequested>(_onProfileRefresh);
    on<AuthPhoneSignInRequested>(_onPhoneSignIn);
    on<AuthPhoneSignUpRequested>(_onPhoneSignUp);
    on<AuthBypassEmailVerificationRequested>(_onBypassEmailVerification);

    _subscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  final AuthRepository _authRepository;
  late final StreamSubscription<NipanzeUser?> _subscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(
        user: user,
        needsEmailVerification: !_authRepository.isEmailVerified,
      ));
      // Asynchronously fetch complete profile to update subscription plan
      try {
        final fullUser = await _authRepository.fetchCurrentProfile();
        emit(AuthAuthenticated(
          user: fullUser,
          needsEmailVerification: !_authRepository.isEmailVerified,
        ));
      } catch (e) {
        // Log error and keep current user details
        debugPrint('Error fetching user profile at start: $e');
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignIn(
      AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(
        user: user,
        needsEmailVerification: !_authRepository.isEmailVerified,
      ));
    } on AppException catch (e) {
      emit(AuthError(e.message));
    }
  }

  Future<void> _onSignUp(
      AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final existingEmail =
          await _authRepository.checkPhoneRegistered(event.email);
      if (existingEmail != null) {
        emit(const AuthError(
            'This email is already registered. Please log in instead.'));
        return;
      }
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      emit(const AuthUnauthenticated(pendingVerification: true));
    } on AppException catch (e) {
      emit(AuthError(e.message));
    }
  }

  Future<void> _onSignOut(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.resetPassword(event.email);
      emit(const AuthPasswordResetSent());
    } on AppException catch (e) {
      emit(AuthError(e.message));
    }
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user != null) {
      emit(AuthAuthenticated(
        user: user,
        needsEmailVerification: !_authRepository.isEmailVerified,
      ));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onProfileRefresh(
    AuthProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    try {
      final fullUser = await _authRepository.fetchCurrentProfile();
      emit(AuthAuthenticated(
        user: fullUser,
        needsEmailVerification: current.needsEmailVerification,
      ));
    } catch (e) {
      debugPrint('Error refreshing user profile: $e');
    }
  }

  /// Phone sign-in: resolve phone → email via RPC, then sign in.
  Future<void> _onPhoneSignIn(
    AuthPhoneSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final clean = _authRepository.cleanPhone(event.phone);
      var resolvedEmail = await _authRepository.checkPhoneRegistered(clean);
      if (resolvedEmail == null) {
        // Fallback: derive mock email format from digits if phone lookup didn't return an email
        final digits = clean.replaceAll('+', '');
        resolvedEmail = '$digits@nipanze.test';
      }
      final user = await _authRepository.signIn(
        email: resolvedEmail,
        password: event.password,
      );
      // Ensure profile has phone updated
      await _authRepository.updateProfile(
        targetUserId: user.id,
        phone: clean,
      );
      emit(AuthAuthenticated(
        user: user,
        needsEmailVerification: !_authRepository.isEmailVerified,
      ));
    } on AppException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError(
          'Sign-in failed. Check your credentials and try again.'));
    }
  }

  /// Phone sign-up: create account with mock email, then save profile data.
  Future<void> _onPhoneSignUp(
    AuthPhoneSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final clean = _authRepository.cleanPhone(event.phone);
      final existingPhone = await _authRepository.checkPhoneRegistered(clean);
      if (existingPhone != null) {
        emit(const AuthError(
            'This phone number is already registered. Please log in instead.'));
        return;
      }

      if (event.email != null && event.email!.trim().isNotEmpty) {
        final existingEmail =
            await _authRepository.checkPhoneRegistered(event.email!.trim());
        if (existingEmail != null) {
          emit(const AuthError(
              'This email is already registered. Please use another email or log in.'));
          return;
        }
      }

      // Derive a deterministic mock email from the E.164 phone number.
      final digits = clean.replaceAll('+', '');
      final mockEmail = '$digits@nipanze.test';

      final createdUser = await _authRepository.signUp(
        email: mockEmail,
        password: event.password,
        fullName: event.fullName,
        phone: clean,
        countryCode: event.countryCode,
        referralCode: event.referralCode,
      );

      NipanzeUser? user;
      try {
        user = await _authRepository.signIn(
          email: mockEmail,
          password: event.password,
        );
      } catch (signInErr) {
        debugPrint('signIn after signUp notice: $signInErr');
        if (createdUser != null) {
          user = NipanzeUser(
            id: createdUser.id,
            email: createdUser.email ?? mockEmail,
            fullName: event.fullName,
            phone: clean,
            country: event.countryCode,
          );
        }
      }

      // Persist the collected profile data using explicit user ID if available.
      final targetId = user?.id ?? createdUser?.id;
      if (targetId != null) {
        await _authRepository.updateProfile(
          targetUserId: targetId,
          fullName: event.fullName,
          phone: clean,
          country: event.countryCode,
        );
      }

      if (event.referralCode?.trim().isNotEmpty == true && user != null) {
        try {
          await _authRepository.attributeReferral(
            referralCode: event.referralCode!.trim(),
            source: 'registration',
          );
        } catch (e) {
          debugPrint('Referral attribution failed: $e');
        }
      }

      if (user != null) {
        emit(AuthAuthenticated(
          user: user,
          needsEmailVerification: false,
        ));
      } else {
        emit(const AuthError('Registration failed. Please try again.'));
      }
    } on AppException catch (e) {
      debugPrint('AppException in phone sign-up: ${e.message}');
      emit(AuthError(e.message));
    } catch (e, stack) {
      debugPrint('Phone sign-up error: $e\n$stack');
      emit(const AuthError('Registration failed. Please try again.'));
    }
  }

  void _onBypassEmailVerification(
    AuthBypassEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) {
    final current = state;
    if (current is AuthAuthenticated) {
      emit(AuthAuthenticated(
        user: current.user,
        needsEmailVerification: false,
      ));
    } else {
      final user = _authRepository.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(
          user: user,
          needsEmailVerification: false,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
