part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
  });
  final String email;
  final String password;
  final String fullName;
  @override
  List<Object?> get props => [email, fullName];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);
  final NipanzeUser? user;
  @override
  List<Object?> get props => [user];
}
