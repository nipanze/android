import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as sb show AuthException;

void main() {
  group('parseSupabaseError - AuthException variants', () {
    test('invalid login maps to user-friendly message', () {
      final e = parseSupabaseError(
          const sb.AuthException('Invalid login credentials'));
      expect(e, isA<AuthException>());
      expect(e.message, 'Invalid email or password.');
    });

    test('email not confirmed maps to verification message', () {
      final e = parseSupabaseError(
          const sb.AuthException('Email not confirmed'));
      expect(e, isA<AuthException>());
      expect(e.message, contains('verify your email'));
    });

    test('user already registered maps to duplicate account message', () {
      final e = parseSupabaseError(
          const sb.AuthException('User already registered'));
      expect(e, isA<AuthException>());
      expect(e.message, contains('already exists'));
    });

    test('rate limit maps to rate limit message', () {
      final e = parseSupabaseError(
          const sb.AuthException('Rate limit exceeded'));
      expect(e, isA<AuthException>());
      expect(e.message, contains('Too many attempts'));
    });

    test('generic auth error returns fallback message', () {
      final e = parseSupabaseError(
          const sb.AuthException('Some unknown auth error'));
      expect(e, isA<AuthException>());
      expect(e.message, 'Authentication failed. Please try again.');
    });

    test('auth error is case-insensitive', () {
      final e = parseSupabaseError(
          const sb.AuthException('INVALID LOGIN CREDENTIALS'));
      expect(e, isA<AuthException>());
      expect(e.message, 'Invalid email or password.');
    });
  });

  group('parseSupabaseError - Network errors', () {
    test('SocketException maps to NetworkException', () {
      final e = parseSupabaseError(const SocketException('Connection refused'));
      expect(e, isA<NetworkException>());
      expect(e.message, contains('internet'));
    });

    test('TimeoutException maps to NetworkException', () {
      final e = parseSupabaseError(TimeoutException('took too long'));
      expect(e, isA<NetworkException>());
      expect(e.message, contains('taking too long'));
    });

    test('connection refused string maps to NetworkException', () {
      final e = parseSupabaseError(Exception('Connection refused'));
      expect(e, isA<NetworkException>());
    });

    test('failed host lookup maps to NetworkException', () {
      final e = parseSupabaseError(Exception('failed host lookup'));
      expect(e, isA<NetworkException>());
    });

    test('connection timed out maps to NetworkException', () {
      final e = parseSupabaseError(Exception('connection timed out'));
      expect(e, isA<NetworkException>());
    });

    test('ClientException maps to NetworkException', () {
      final e = parseSupabaseError(Exception('ClientException'));
      expect(e, isA<NetworkException>());
    });
  });

  group('parseSupabaseError - Storage errors', () {
    test('StorageException with policy violation maps to PermissionException', () {
      final e = parseSupabaseError(const StorageException(
        'new row violates row-level security policy',
        statusCode: '403',
      ));
      expect(e, isA<PermissionException>());
      expect(e.message, contains('Upload permission denied'));
    });

    test('StorageException without policy maps to DatabaseException', () {
      final e = parseSupabaseError(const StorageException(
        'Bucket not found',
        statusCode: '404',
      ));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('File upload failed'));
    });

    test('StorageException with upload error maps to DatabaseException', () {
      final e = parseSupabaseError(const StorageException(
        'Upload failed due to network',
      ));
      expect(e, isA<DatabaseException>());
    });

    test('string with storageerror maps to DatabaseException', () {
      final e = parseSupabaseError(Exception('StorageError occurred'));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('File upload failed'));
    });

    test('string with bucket not found maps to DatabaseException', () {
      final e = parseSupabaseError(Exception('bucket not found'));
      expect(e, isA<DatabaseException>());
    });
  });

  group('parseSupabaseError - Postgrest NIPANZE trigger codes', () {
    test('NIPANZE_SELF_OFFER maps to ValidationException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_SELF_OFFER',
      ));
      expect(e, isA<ValidationException>());
      expect(e.message, contains('own forex request'));
    });

    test('NIPANZE_LISTING_NOT_ACTIVE maps to DatabaseException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_LISTING_NOT_ACTIVE',
      ));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('no longer accepting'));
    });

    test('42501 code maps to PermissionException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'forbidden',
        code: '42501',
      ));
      expect(e, isA<PermissionException>());
    });
  });

  group('parseSupabaseError - Forex-specific codes', () {
    test('P0102 maps to forex not enabled', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'forex not available',
        code: 'P0102',
      ));
      expect(e, isA<PermissionException>());
      expect(e.message, contains('Forex is not yet enabled'));
    });

    test('P0103 maps to currency not tradeable', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'currency issue',
        code: 'P0103',
      ));
      expect(e, isA<ValidationException>());
      expect(e.message, contains('not cleared for forex'));
    });

    test('P0110 maps to forex listing not active', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'forex inactive',
        code: 'P0110',
      ));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('no longer accepting'));
    });

    test('P0111 maps to forex listing expired', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'forex expired',
        code: 'P0111',
      ));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('expired'));
    });

    test('P0120 maps to ListingNotFoundException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'not found',
        code: 'P0120',
      ));
      expect(e, isA<ListingNotFoundException>());
    });

    test('P0146 maps to PermissionException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'unauthorized',
        code: 'P0146',
      ));
      expect(e, isA<PermissionException>());
    });

    test('unknown P01xx code maps to generic forex DatabaseException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'unknown forex error',
        code: 'P0199',
      ));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('forex action'));
    });
  });

  group('userFacingErrorMessage', () {
    test('returns message directly for AppException subclasses', () {
      const auth = AuthException('Test auth error');
      expect(userFacingErrorMessage(auth), 'Test auth error');

      const db = DatabaseException('Test db error');
      expect(userFacingErrorMessage(db), 'Test db error');

      const perm = PermissionException('Test permission error');
      expect(userFacingErrorMessage(perm), 'Test permission error');
    });

    test('wraps unknown errors via parseSupabaseError', () {
      final msg = userFacingErrorMessage(Exception('something'));
      expect(msg, isA<String>());
      expect(msg, isNotEmpty);
    });
  });
}
