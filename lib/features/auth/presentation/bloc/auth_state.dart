part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, this.needsEmailVerification = false});
  final NipanzeUser user;
  final bool needsEmailVerification;
  @override
  List<Object?> get props => [user, needsEmailVerification];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.pendingVerification = false});
  final bool pendingVerification;
  @override
  List<Object?> get props => [pendingVerification];
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}
