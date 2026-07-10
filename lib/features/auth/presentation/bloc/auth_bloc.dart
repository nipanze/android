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
    on<AuthProfileRefreshRequested>(_onProfileRefresh); // ← add this

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

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
