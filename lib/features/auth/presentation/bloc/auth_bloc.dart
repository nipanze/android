// ignore_for_file: unused_import, directives_ordering

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:opencapital/core/errors/app_errors.dart';
import 'package:opencapital/features/auth/data/auth_repository.dart';


// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.role,
  });
  final String email;
  final String password;
  final String role;

  @override
  List<Object?> get props => [email, role];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});
  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthResendVerificationRequested extends AuthEvent {
  const AuthResendVerificationRequested({required this.email});
  final String email;

  @override
  List<Object?> get props => [email];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess();
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthVerificationResent extends AuthState {
  const AuthVerificationResent();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthResendVerificationRequested>(_onResendVerification);
  }

  final AuthRepository authRepository;

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.register(
        email: event.email,
        password: event.password,
        role: event.role,
      );
      emit(const AuthSuccess());
    } on AppException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(const AuthSuccess());
    } on AppException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await authRepository.signOut();
    emit(const AuthInitial());
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.sendPasswordReset(email: event.email);
      emit(const AuthPasswordResetSent());
    } on AppException catch (e) {
      emit(AuthError(e.message));
    }
  }

  Future<void> _onResendVerification(
    AuthResendVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.resendVerification(email: event.email);
      emit(const AuthVerificationResent());
    } on AppException catch (e) {
      emit(AuthError(e.message));
    }
  }
}
