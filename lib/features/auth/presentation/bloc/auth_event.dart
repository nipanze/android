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

/// Forces a re-fetch of the current user's profile (including
/// subscription_plan) from the DB, without signing out/in.
/// Fire this whenever a screen depends on up-to-date plan/KYC state.
class AuthProfileRefreshRequested extends AuthEvent {
  const AuthProfileRefreshRequested();
}

/// Phone-based login: resolve phone → email via RPC, then sign in with
/// the stored email + provided password (or Test1234! bypass in dev).
class AuthPhoneSignInRequested extends AuthEvent {
  const AuthPhoneSignInRequested({
    required this.phone,
    required this.password,
  });
  final String phone;
  final String password;
  @override
  List<Object?> get props => [phone];
}

/// Phone-based registration: create auth account using a mock email derived
/// from the phone number, then update the profile with all gathered data.
class AuthPhoneSignUpRequested extends AuthEvent {
  const AuthPhoneSignUpRequested({
    required this.phone,
    required this.password,
    required this.fullName,
    required this.countryCode,
    this.email,
    this.referralCode,
    this.avatarBytes,
  });
  final String phone;
  final String password;
  final String fullName;
  final String countryCode;
  final String? email; // optional real email from Step 3
  final String? referralCode;
  final Uint8List? avatarBytes;
  @override
  List<Object?> get props => [phone, fullName, referralCode, avatarBytes];
}

/// Development mode helper: bypasses email verification requirement.
class AuthBypassEmailVerificationRequested extends AuthEvent {
  const AuthBypassEmailVerificationRequested();
}
