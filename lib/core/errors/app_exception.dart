import 'package:supabase_flutter/supabase_flutter.dart';

/// Typed exception hierarchy for Nipanze.
/// All exceptions carry a user-friendly [message] — internal codes are never shown to users.
abstract class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Check your internet connection.']);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'You do not have permission to perform this action.']);
}

class KycRequiredException extends AppException {
  const KycRequiredException()
      : super('KYC verification is required before posting a listing.');
}

class SubscriptionRequiredException extends AppException {
  const SubscriptionRequiredException(String plan)
      : super('A $plan subscription is required for this action.');
}

class ListingNotFoundException extends AppException {
  const ListingNotFoundException() : super('This listing could not be found.');
}

/// Parses Supabase exceptions into user-friendly [AppException]s.
/// Raw Supabase error codes and messages are NEVER returned to the UI.
AppException parseSupabaseError(Object error) {
  if (error is AuthException) {
    return _parseAuthError(error.message);
  }
  if (error is PostgrestException) {
    return _parsePostgrestError(error.code ?? '', error.message);
  }
  if (error is StorageException) {
    return const DatabaseException('File upload failed. Please try again.');
  }
  return const DatabaseException('Something went wrong. Please try again.');
}

AppException _parseAuthError(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('invalid login')) {
    return const AuthException('Invalid email or password.');
  }
  if (lower.contains('email not confirmed')) {
    return const AuthException('Please verify your email address before signing in.');
  }
  if (lower.contains('user already registered')) {
    return const AuthException('An account with this email already exists.');
  }
  if (lower.contains('rate limit')) {
    return const AuthException('Too many attempts. Please wait a moment and try again.');
  }
  return const AuthException('Authentication failed. Please try again.');
}

AppException _parsePostgrestError(String code, String message) {
  // Nipanze-specific trigger codes
  if (message.contains('NIPANZE_KYC_REQUIRED')) return const KycRequiredException();
  if (message.contains('NIPANZE_KYC_EXPIRED')) {
    return const DatabaseException('Your KYC has expired. Please re-verify to continue.');
  }
  if (message.contains('NIPANZE_ACCOUNT_INACTIVE')) {
    return const PermissionException('Your account is not active.');
  }
  if (message.contains('NIPANZE_SUBSCRIPTION_REQUIRED')) {
    return const SubscriptionRequiredException('Borrower or Pro');
  }
  if (message.contains('NIPANZE_LENDER_SUBSCRIPTION_REQUIRED')) {
    return const SubscriptionRequiredException('Lender or Pro');
  }
  if (message.contains('NIPANZE_MAX_LISTINGS')) {
    return const DatabaseException('You have reached the maximum number of active listings.');
  }
  if (message.contains('NIPANZE_SELF_BID')) {
    return const ValidationException('You cannot bid on your own listing.');
  }
  if (message.contains('NIPANZE_RATE_CEILING')) {
    return const ValidationException('Your bid rate exceeds the listing ceiling rate.');
  }
  if (message.contains('NIPANZE_BID_LOCKED')) {
    return const DatabaseException('This bid has already been accepted and cannot be changed.');
  }
  if (message.contains('NIPANZE_NO_NEGOTIATOR')) {
    return const DatabaseException('No negotiators are available. Please try again shortly.');
  }

  // Generic Postgres codes
  if (code == '23505') return const DatabaseException('A duplicate entry already exists.');
  if (code == '42501') return const PermissionException();
  if (code == 'PGRST116') return const ListingNotFoundException();

  return const DatabaseException('Something went wrong. Please try again.');
}
