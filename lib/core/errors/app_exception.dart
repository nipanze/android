import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as sb show AuthException;

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
  const PermissionException(
      [super.message = 'You do not have permission to perform this action.']);
}

class KycRequiredException extends AppException {
  const KycRequiredException()
      : super('Verification is required before continuing.');
}

class SubscriptionRequiredException extends AppException {
  const SubscriptionRequiredException(String plan)
      : super('A $plan subscription is required for this action.');
}

class ListingNotFoundException extends AppException {
  const ListingNotFoundException() : super('This request could not be found.');
}

String userFacingErrorMessage(Object error) {
  if (error is AppException) return error.message;
  return parseSupabaseError(error).message;
}

/// Parses Supabase exceptions into user-friendly [AppException]s.
/// Raw Supabase error codes and messages are NEVER returned to the UI.
AppException parseSupabaseError(Object error) {
  // Treat low-level network/socket failures as NetworkException so UI shows a
  // clear, actionable message when the app cannot reach the service.
  try {
    if (error is SocketException) {
      return const NetworkException(
        'We could not connect. Check your internet and try again.',
      );
    }
    if (error is TimeoutException) {
      return const NetworkException(
        'The connection is taking too long. Try again on a stronger network.',
      );
    }
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('connection refused') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('connection timed out') ||
        errStr.contains('connection closed') ||
        errStr.contains('clientexception') ||
        errStr.contains('xmlhttprequest error') ||
        errStr.contains('socketexception')) {
      return const NetworkException(
        'We could not connect. Check your internet and try again.',
      );
    }
  } catch (_) {
    // ignore and fall through to other handlers
  }
  if (error is sb.AuthException) {
    return _parseAuthError(error.message);
  }
  if (error is PostgrestException) {
    return _parsePostgrestError(error.code ?? '', error.message);
  }
  if (error is StorageException) {
    // Storage policy violations (403) surface as StorageException
    final msg = error.message.toLowerCase();
    if (msg.contains('policy') ||
        msg.contains('unauthorized') ||
        msg.contains('403') ||
        msg.contains('violates')) {
      return const PermissionException(
          'Upload permission denied. Please contact support.');
    }
    return const DatabaseException('File upload failed. Please try again.');
  }
  // Supabase web client sometimes wraps StorageException or PostgrestException inside a generic
  // Exception — check the string representation as a fallback.
  final errStr = error.toString().toLowerCase();
  if (errStr.contains('storageerror') ||
      (errStr.contains('storage') && errStr.contains('policy')) ||
      (errStr.contains('storage') && errStr.contains('upload')) ||
      errStr.contains('bucket not found') ||
      errStr.contains('404') ||
      errStr.contains('403')) {
    return const DatabaseException('File upload failed. Please try again.');
  }
  if (errStr.contains('permission denied') || errStr.contains('42501')) {
    return const PermissionException();
  }
  return const DatabaseException('Something went wrong. Please try again.');
}

AppException _parseAuthError(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('invalid login')) {
    return const AuthException('Invalid email or password.');
  }
  if (lower.contains('email not confirmed')) {
    return const AuthException(
        'Please verify your email address before signing in.');
  }
  if (lower.contains('user already registered')) {
    return const AuthException('An account with this email already exists.');
  }
  if (lower.contains('rate limit')) {
    return const AuthException(
        'Too many attempts. Please wait a moment and try again.');
  }
  return const AuthException('Authentication failed. Please try again.');
}

AppException _parsePostgrestError(String code, String message) {
  final forex = _parseForexError(code, message);
  if (forex != null) return forex;

  // Nipanze-specific trigger codes (aligned to v4.0)
  if (message.contains('NIPANZE_KYC_REQUIRED')) {
    return const KycRequiredException();
  }
  if (message.contains('NIPANZE_ACCOUNT_INACTIVE')) {
    return const PermissionException('Your account is not active.');
  }
  if (message.contains('NIPANZE_SUBSCRIPTION_REQUIRED') ||
      message.contains('NIPANZE_LENDER_SUBSCRIPTION_REQUIRED')) {
    return const SubscriptionRequiredException('Lender');
  }
  if (message.contains('NIPANZE_PRO_REQUIRED')) {
    return const SubscriptionRequiredException('Pro');
  }
  if (message.contains('NIPANZE_MAX_REQUESTS')) {
    return const DatabaseException(
        'You have reached the maximum number of active listings.');
  }
  if (message.contains('NIPANZE_SELF_OFFER') ||
      message.contains('NIPANZE_SELF_BID')) {
    return const ValidationException(
        'You cannot make an offer on your own request.');
  }
  if (message.contains('NIPANZE_MIN_OFFER')) {
    return const ValidationException(
        'Offer amount is below the platform minimum.');
  }
  if (message.contains('NIPANZE_OFFER_LOCKED')) {
    return const DatabaseException(
        'This offer has already been accepted and cannot be modified.');
  }
  if (message.contains('NIPANZE_ALREADY_REVEALED')) {
    return const DatabaseException(
        'Contact details have already been revealed.');
  }
  if (message.contains('NIPANZE_LISTING_NOT_ACTIVE') ||
      message.contains('NIPANZE_LISTING_EXPIRED')) {
    return const DatabaseException(
        'This listing is no longer accepting offers.');
  }
  if (message.contains('NIPANZE_CONTACT_NOT_ALLOWED')) {
    return const PermissionException(
        'Contact details are only available after an offer is accepted.');
  }

  // Generic Postgres codes
  if (code == '23505') {
    return const DatabaseException('A duplicate entry already exists.');
  }
  if (code == '42501') return const PermissionException();
  if (code == 'PGRST116') return const ListingNotFoundException();

  return const DatabaseException('Something went wrong. Please try again.');
}

AppException? _parseForexError(String code, String message) {
  if (code == 'P0101' || message.contains('NIPANZE_ACCOUNT_INACTIVE')) {
    return const PermissionException('Your account is not active.');
  }
  if (code == 'P0102' || message.contains('NIPANZE_FOREX_NOT_ENABLED')) {
    return const PermissionException(
      'Forex is not yet enabled in this market.',
    );
  }
  if (code == 'P0103' || message.contains('NIPANZE_CURRENCY_NOT_TRADEABLE')) {
    return const ValidationException(
      'One or both currencies are not cleared for forex trading yet.',
    );
  }
  if (code == 'P0104' || message.contains('NIPANZE_PRO_REQUIRED')) {
    return const SubscriptionRequiredException('Pro');
  }
  if (code == 'P0105' ||
      message.contains('NIPANZE_FOREX_REQUEST_TERMS_LOCKED')) {
    return const DatabaseException(
      'This forex request is locked and cannot be edited.',
    );
  }
  if (code == 'P0106' ||
      message.contains('NIPANZE_FOREX_REQUEST_COUNTRY_LOCKED')) {
    return const DatabaseException(
      'This forex request country is locked after publishing.',
    );
  }
  if (code == 'P0110' ||
      code == 'P0122' ||
      message.contains('NIPANZE_FOREX_LISTING_NOT_ACTIVE')) {
    return const DatabaseException(
      'This forex request is no longer accepting offers.',
    );
  }
  if (code == 'P0111' || message.contains('NIPANZE_FOREX_LISTING_EXPIRED')) {
    return const DatabaseException('This forex request has expired.');
  }
  if (code == 'P0112' || message.contains('NIPANZE_SELF_OFFER')) {
    return const ValidationException(
      'You cannot make an offer on your own forex request.',
    );
  }
  if (code == 'P0113' || message.contains('NIPANZE_SUBSCRIPTION_REQUIRED')) {
    return const SubscriptionRequiredException('Lender');
  }
  if (code == 'P0114' ||
      message.contains('NIPANZE_FOREX_OFFER_TERMS_REQUIRED')) {
    return const ValidationException(
      'Enter both a rate and available amount for your forex offer.',
    );
  }
  if (code == 'P0115' || message.contains('NIPANZE_FOREX_OFFER_TERMS_LOCKED')) {
    return const DatabaseException(
      'Forex offer terms are locked after submission.',
    );
  }
  if (code == 'P0116' || message.contains('NIPANZE_FOREX_OFFER_LOCKED')) {
    return const DatabaseException(
      'This accepted forex offer cannot be modified.',
    );
  }
  if (code == 'P0120' ||
      code == 'P0123' ||
      message.contains('NIPANZE_FOREX_LISTING_NOT_FOUND') ||
      message.contains('NIPANZE_FOREX_OFFER_NOT_FOUND')) {
    return const ListingNotFoundException();
  }
  if (code == 'P0121' ||
      code == 'P0124' ||
      code == 'P0146' ||
      message.contains('NIPANZE_UNAUTHORIZED')) {
    return const PermissionException();
  }
  if (code == 'P0141' ||
      message.contains('NIPANZE_FOREX_AGREEMENT_NOT_FOUND')) {
    return const DatabaseException('This forex agreement could not be found.');
  }
  if (code == 'P0145' ||
      message.contains('NIPANZE_FOREX_AGREEMENT_NOT_LOCKED')) {
    return const DatabaseException(
      'This forex agreement must be locked before contact can be unlocked.',
    );
  }
  if (code.startsWith('P01')) {
    return const DatabaseException(
      'This forex action could not be completed. Please review the request and try again.',
    );
  }
  return null;
}
