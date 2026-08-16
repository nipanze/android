import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('userFacingErrorMessage', () {
    test('returns message directly for AppException', () {
      const exception = KycRequiredException();
      expect(userFacingErrorMessage(exception),
          'Verification is required before continuing.');
    });

    test('never leaks raw text for unknown errors', () {
      final message = userFacingErrorMessage(Exception('internal_sql_detail'));
      expect(message.toLowerCase(), isNot(contains('internal_sql_detail')));
    });
  });

  group('parseSupabaseError', () {
    test('maps network failures to NetworkException', () {
      final result = parseSupabaseError(const SocketException('no route'));
      expect(result, isA<NetworkException>());

      final timeout = parseSupabaseError(TimeoutException('slow'));
      expect(timeout, isA<NetworkException>());
    });

    test('maps NIPANZE_KYC_REQUIRED to KycRequiredException', () {
      final result = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_KYC_REQUIRED',
        code: 'P0001',
      ));
      expect(result, isA<KycRequiredException>());
    });

    test('maps NIPANZE_SUBSCRIPTION_REQUIRED to SubscriptionRequiredException',
        () {
      final result = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_LENDER_SUBSCRIPTION_REQUIRED',
        code: 'P0001',
      ));
      expect(result, isA<SubscriptionRequiredException>());
    });

    test('maps NIPANZE_PRO_REQUIRED to Pro subscription error', () {
      final result = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_PRO_REQUIRED',
        code: 'P0104',
      ));
      expect(result, isA<SubscriptionRequiredException>());
      expect(result.message, contains('Pro'));
    });

    test('maps NIPANZE_SELF_OFFER to ValidationException', () {
      final result = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_SELF_OFFER',
        code: 'P0112',
      ));
      expect(result, isA<ValidationException>());
    });

    test('maps NIPANZE_MAX_REQUESTS to DatabaseException', () {
      final result = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_MAX_REQUESTS',
        code: 'P0001',
      ));
      expect(result, isA<DatabaseException>());
      expect(result.message, contains('maximum number of active listings'));
    });

    test('maps generic 23505 to duplicate entry error', () {
      final result = parseSupabaseError(const PostgrestException(
        message: 'duplicate key value',
        code: '23505',
      ));
      expect(result, isA<DatabaseException>());
    });

    test('maps PGRST116 to ListingNotFoundException', () {
      final result = parseSupabaseError(const PostgrestException(
        message: 'no rows',
        code: 'PGRST116',
      ));
      expect(result, isA<ListingNotFoundException>());
    });

    test('maps forex not enabled code to PermissionException', () {
      final result = parseSupabaseError(const PostgrestException(
        message: 'forex disabled',
        code: 'P0102',
      ));
      expect(result, isA<PermissionException>());
      expect(result.message, contains('Forex is not yet enabled'));
    });

    test('maps storage policy violations to PermissionException', () {
      final result = parseSupabaseError(const StorageException(
        'new row violates row-level security policy',
        statusCode: '403',
      ));
      expect(result, isA<PermissionException>());
    });

    test('falls back to generic DatabaseException', () {
      final result = parseSupabaseError(const PostgrestException(
        message: 'some unknown db problem',
        code: 'XX000',
      ));
      expect(result, isA<DatabaseException>());
      expect(result.message, 'Something went wrong. Please try again.');
    });
  });
}
