// test/features/auth/auth_bloc_test.dart
// ignore_for_file: directives_ordering

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:opencapital/features/auth/data/auth_repository.dart';
import 'package:opencapital/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:opencapital/core/errors/app_errors.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockAuthRepository extends Mock implements AuthRepository {}

// AuthResponse has no public constructor — use a fake via mocktail
class FakeAuthResponse extends Fake implements sb.AuthResponse {}

void main() {
  late MockAuthRepository mockRepo;

  setUpAll(() {
    // Register fallback values for named-parameter matchers
    registerFallbackValue(FakeAuthResponse());
  });

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('AuthBloc — Register', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] on successful register',
      build: () {
        when(() => mockRepo.register(
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
            )).thenAnswer((_) async => FakeAuthResponse());
        return AuthBloc(authRepository: mockRepo);
      },
      act: (b) => b.add(const AuthRegisterRequested(
        email: 'test@example.com',
        password: 'Test1234!',
        role: 'borrower',
      )),
      expect: () => [const AuthLoading(), const AuthSuccess()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on AuthException',
      build: () {
        when(() => mockRepo.register(
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
            )).thenThrow(const AuthException('Email already registered'));
        return AuthBloc(authRepository: mockRepo);
      },
      act: (b) => b.add(const AuthRegisterRequested(
        email: 'existing@example.com',
        password: 'Test1234!',
        role: 'borrower',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Email already registered'),
        ),
      ],
    );
  });

  group('AuthBloc — Login', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] on valid credentials',
      build: () {
        when(() => mockRepo.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => FakeAuthResponse());
        return AuthBloc(authRepository: mockRepo);
      },
      act: (b) => b.add(const AuthLoginRequested(
        email: 'test@example.com',
        password: 'Test1234!',
      )),
      expect: () => [const AuthLoading(), const AuthSuccess()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on wrong password',
      build: () {
        when(() => mockRepo.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const AuthException('Invalid login credentials'));
        return AuthBloc(authRepository: mockRepo);
      },
      act: (b) => b.add(const AuthLoginRequested(
        email: 'test@example.com',
        password: 'wrongpassword',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Invalid login credentials'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on network error',
      build: () {
        when(() => mockRepo.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
          const NetworkException(
              'No internet connection. Please check your network.'),
        );
        return AuthBloc(authRepository: mockRepo);
      },
      act: (b) => b.add(const AuthLoginRequested(
        email: 'test@example.com',
        password: 'Test1234!',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('internet'),
        ),
      ],
    );
  });

  group('AuthBloc — Password Reset', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthPasswordResetSent] on success',
      build: () {
        when(() => mockRepo.sendPasswordReset(email: any(named: 'email')))
            .thenAnswer((_) async {});
        return AuthBloc(authRepository: mockRepo);
      },
      act: (b) => b.add(
          const AuthPasswordResetRequested(email: 'test@example.com')),
      expect: () => [const AuthLoading(), const AuthPasswordResetSent()],
    );
  });

  group('AuthBloc — Sign Out', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthInitial] on sign out',
      build: () {
        when(() => mockRepo.signOut()).thenAnswer((_) async {});
        return AuthBloc(authRepository: mockRepo);
      },
      act: (b) => b.add(const AuthSignOutRequested()),
      expect: () => [const AuthLoading(), const AuthInitial()],
    );
  });
}