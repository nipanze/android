// test/features/auth/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/core/errors/app_exception.dart';
import 'package:nipanze/features/auth/data/auth_repository.dart';
import 'package:nipanze/features/auth/domain/models/nipanze_user.dart';
import 'package:nipanze/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, AuthState;

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  const testUser = NipanzeUser(
    id: 'test-uuid-123',
    email: 'test@nipanze.ug',
    fullName: 'Test User',
    isEmailVerified: true,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.authStateChanges)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockRepo.currentUser).thenReturn(null);
    when(() => mockRepo.isEmailVerified).thenReturn(false);
  });

  group('AuthBloc', () {
    test('initial state is AuthLoading', () {
      final bloc = AuthBloc(mockRepo);
      expect(bloc.state, isA<AuthLoading>());
      bloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'AuthStarted emits AuthUnauthenticated when no session',
      build: () {
        when(() => mockRepo.currentUser).thenReturn(null);
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthStarted emits AuthAuthenticated when session exists',
      build: () {
        when(() => mockRepo.currentUser).thenReturn(testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignInRequested emits Loading then Authenticated on success',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.signIn(
            email: 'test@nipanze.ug',
            password: 'Test1234!')).thenAnswer((_) async => testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
      },
      act: (bloc) => bloc.add(const AuthSignInRequested(
        email: 'test@nipanze.ug',
        password: 'Test1234!',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignInRequested emits Loading then AuthError on failure',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.signIn(
                email: any(named: 'email'), password: any(named: 'password')))
            .thenThrow(const AuthException('Invalid email or password.'));
      },
      act: (bloc) => bloc.add(const AuthSignInRequested(
        email: 'bad@nipanze.ug',
        password: 'wrongpassword',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignUpRequested emits Loading then AuthUnauthenticated with pendingVerification',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AuthSignUpRequested(
        email: 'new@nipanze.ug',
        password: 'Test1234!',
        fullName: 'New User',
      )),
      expect: () => [
        isA<AuthLoading>(),
        predicate<AuthState>(
            (s) => s is AuthUnauthenticated && s.pendingVerification),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignOutRequested emits AuthUnauthenticated',
      build: () {
        when(() => mockRepo.signOut()).thenAnswer((_) async {});
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthPasswordResetRequested emits AuthPasswordResetSent on success',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.resetPassword(any())).thenAnswer((_) async {});
      },
      act: (bloc) =>
          bloc.add(const AuthPasswordResetRequested('test@nipanze.ug')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthPasswordResetSent>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthUserChanged with user emits AuthAuthenticated',
      build: () => AuthBloc(mockRepo),
      act: (bloc) => bloc.add(const AuthUserChanged(testUser)),
      expect: () => [isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthUserChanged with null emits AuthUnauthenticated',
      build: () => AuthBloc(mockRepo),
      act: (bloc) => bloc.add(const AuthUserChanged(null)),
      expect: () => [isA<AuthUnauthenticated>()],
    );
  });

  group('parseSupabaseError', () {
    test('unknown error returns generic DatabaseException', () {
      final e = parseSupabaseError(Exception('unexpected error'));
      expect(e, isA<DatabaseException>());
    });

    test('duplicate postgres code returns duplicate DatabaseException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      ));

      expect(e, isA<DatabaseException>());
      expect(e.message, 'A duplicate entry already exists.');
    });

    test('request not found postgres code returns ListingNotFoundException',
        () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'JSON object requested, multiple or no rows returned',
        code: 'PGRST116',
      ));

      expect(e, isA<ListingNotFoundException>());
      expect(e.message, 'This request could not be found.');
    });

    test('lender subscription trigger maps to offer subscription message', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_LENDER_SUBSCRIPTION_REQUIRED',
      ));

      expect(e, isA<SubscriptionRequiredException>());
      expect(e.message, 'A Lender subscription is required for this action.');
    });

    test('self offer trigger maps to user-friendly validation message', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_SELF_BID',
      ));

      expect(e, isA<ValidationException>());
      expect(e.message, 'You cannot make an offer on your own request.');
    });

    test('contact reveal trigger maps to permission message', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_CONTACT_NOT_ALLOWED',
      ));

      expect(e, isA<PermissionException>());
      expect(
        e.message,
        'Contact details are only available after an offer is accepted.',
      );
    });
  });
}
