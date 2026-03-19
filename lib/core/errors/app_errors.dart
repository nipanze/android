/// Base exception for all OpenCapital errors.
abstract class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

/// Authentication / session errors.
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Network / connectivity errors.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Server errors (Supabase 5xx, Postgres errors).
class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

/// Client validation errors (caught before hitting the DB).
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// DB trigger fired — maps Postgres RAISE EXCEPTION to a typed error.
class DatabaseTriggerException extends AppException {
  const DatabaseTriggerException(super.message, {super.code});
}

/// Thrown by BidValidator / LoanRequestValidator.
class InsufficientFundsException extends AppException {
  const InsufficientFundsException({
    required this.available,
    required this.required,
  }) : super('Insufficient lendable balance. Available: $available UGX, Required: $required UGX.');

  final double available;
  final double required;
}

/// KYC not approved — maps to trg_fn_require_kyc_for_loan.
class KycRequiredException extends AppException {
  const KycRequiredException()
      : super('KYC approval required before creating a loan request.');
}

/// Account not active — maps to trg_fn_require_active_borrower.
class AccountNotActiveException extends AppException {
  const AccountNotActiveException()
      : super('Account must be in active status to create a loan request.');
}

/// Parses a Supabase / Postgres error string into a typed AppException.
AppException parseSupabaseError(Object error) {
  final msg = error.toString();

  if (msg.contains('KYC approval required')) return const KycRequiredException();
  if (msg.contains('active status')) return const AccountNotActiveException();
  if (msg.contains('Insufficient lendable balance')) {
    // Try to extract amounts from the message
    return DatabaseTriggerException(msg, code: 'insufficient_funds');
  }
  if (msg.contains('Invalid login credentials') ||
      msg.contains('Email not confirmed') ||
      msg.contains('User not found')) {
    return AuthException(msg, code: 'auth_error');
  }
  if (msg.contains('network') || msg.contains('SocketException')) {
    return const NetworkException('No internet connection. Please check your network.');
  }

  return ServerException(msg, code: 'server_error');
}
