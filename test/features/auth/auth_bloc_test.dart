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

  const fullUser = NipanzeUser(
    id: 'test-uuid-123',
    email: 'test@nipanze.ug',
    fullName: 'Test User',
    phone: '+256712345678',
    district: 'Kampala',
    country: 'UG',
    subscriptionPlan: SubscriptionPlan.pro,
    kycStatus: KycStatus.approved,
    isEmailVerified: true,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.authStateChanges)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockRepo.currentUser).thenReturn(null);
    when(() => mockRepo.isEmailVerified).thenReturn(false);
    when(() => mockRepo.checkPhoneRegistered(any()))
        .thenAnswer((_) async => null);
    when(() => mockRepo.checkLoginRegistered(any()))
        .thenAnswer((_) async => null);
    when(() => mockRepo.updateAuthEmail(any())).thenAnswer((_) async {});
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
      'AuthStarted fetches full profile after initial auth',
      build: () {
        when(() => mockRepo.currentUser).thenReturn(testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
        when(() => mockRepo.fetchCurrentProfile())
            .thenAnswer((_) async => fullUser);
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        isA<AuthAuthenticated>(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.subscriptionPlan,
          'subscriptionPlan',
          SubscriptionPlan.pro,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthStarted keeps initial user when fetchCurrentProfile throws',
      build: () {
        when(() => mockRepo.currentUser).thenReturn(testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
        when(() => mockRepo.fetchCurrentProfile())
            .thenThrow(Exception('network error'));
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthStarted emits needsEmailVerification when email not verified',
      build: () {
        when(() => mockRepo.currentUser).thenReturn(testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(false);
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        isA<AuthAuthenticated>().having(
          (s) => s.needsEmailVerification,
          'needsEmailVerification',
          isTrue,
        ),
      ],
    );

    // ── Sign In ───────────────────────────────────────────────────────────

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
      'AuthSignInRequested sets needsEmailVerification when email unverified',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.signIn(
                email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async => testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(false);
      },
      act: (bloc) => bloc.add(const AuthSignInRequested(
        email: 'test@nipanze.ug',
        password: 'Test1234!',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (s) => s.needsEmailVerification,
          'needsEmailVerification',
          isTrue,
        ),
      ],
    );

    // ── Sign Up ───────────────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'AuthSignUpRequested emits Loading then AuthUnauthenticated with pendingVerification',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => null);
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
      'AuthSignUpRequested emits AuthError when email already exists',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.checkLoginRegistered('existing@nipanze.ug'))
            .thenAnswer((_) async => 'existing@nipanze.ug');
      },
      act: (bloc) => bloc.add(const AuthSignUpRequested(
        email: 'existing@nipanze.ug',
        password: 'Test1234!',
        fullName: 'Existing User',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignUpRequested emits AuthError when signUp throws AppException',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.signUp(
                  email: any(named: 'email'),
                  password: any(named: 'password'),
                  fullName: any(named: 'fullName'),
                ))
            .thenThrow(const AuthException(
                'An account with this email already exists.'));
      },
      act: (bloc) => bloc.add(const AuthSignUpRequested(
        email: 'dup@nipanze.ug',
        password: 'Test1234!',
        fullName: 'Dup User',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    // ── Phone Sign In ─────────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignInRequested emits Authenticated on success',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256712345678'))
            .thenReturn('+256712345678');
        when(() => mockRepo.checkPhoneRegistered('+256712345678'))
            .thenAnswer((_) async => 'resolved@nipanze.ug');
        when(() => mockRepo.signIn(
            email: 'resolved@nipanze.ug',
            password: 'Test1234!')).thenAnswer((_) async => testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
        when(() => mockRepo.updateProfile(
            targetUserId: any(named: 'targetUserId'),
            phone: any(named: 'phone'))).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AuthPhoneSignInRequested(
        phone: '+256712345678',
        password: 'Test1234!',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(() => mockRepo.updateProfile(
              targetUserId: 'test-uuid-123',
              phone: '+256712345678',
            )).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignInRequested uses fallback email when phone not registered',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256799999999'))
            .thenReturn('+256799999999');
        when(() => mockRepo.checkPhoneRegistered('+256799999999'))
            .thenAnswer((_) async => null);
        when(() => mockRepo.signIn(
            email: '256799999999@nipanze.test',
            password: 'Test1234!')).thenAnswer((_) async => testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
        when(() => mockRepo.updateProfile(
            targetUserId: any(named: 'targetUserId'),
            phone: any(named: 'phone'))).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AuthPhoneSignInRequested(
        phone: '+256799999999',
        password: 'Test1234!',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(() => mockRepo.signIn(
              email: '256799999999@nipanze.test',
              password: 'Test1234!',
            )).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignInRequested emits AuthError on AppException',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256712345678'))
            .thenReturn('+256712345678');
        when(() => mockRepo.checkPhoneRegistered('+256712345678'))
            .thenAnswer((_) async => 'user@test.ug');
        when(() => mockRepo.signIn(
                email: any(named: 'email'), password: any(named: 'password')))
            .thenThrow(const AuthException('Invalid credentials.'));
      },
      act: (bloc) => bloc.add(const AuthPhoneSignInRequested(
        phone: '+256712345678',
        password: 'wrong',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignInRequested emits generic AuthError on unexpected exception',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256712345678'))
            .thenReturn('+256712345678');
        when(() => mockRepo.checkPhoneRegistered('+256712345678'))
            .thenAnswer((_) async => 'user@test.ug');
        when(() => mockRepo.signIn(
                email: any(named: 'email'), password: any(named: 'password')))
            .thenThrow(Exception('server crashed'));
      },
      act: (bloc) => bloc.add(const AuthPhoneSignInRequested(
        phone: '+256712345678',
        password: 'Test1234!',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          contains('Sign-in failed'),
        ),
      ],
    );

    // ── Phone Sign Up ─────────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignUpRequested emits Authenticated on full success',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256712345678'))
            .thenReturn('+256712345678');
        when(() => mockRepo.checkPhoneRegistered('+256712345678'))
            .thenAnswer((_) async => null);
        when(() => mockRepo.signUp(
              email: '256712345678@nipanze.test',
              password: 'Test1234!',
              fullName: 'New User',
              phone: '+256712345678',
              countryCode: 'UG',
              referralCode: null,
            )).thenAnswer((_) async => null);
        when(() => mockRepo.signIn(
            email: '256712345678@nipanze.test',
            password: 'Test1234!')).thenAnswer((_) async => testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
        when(() => mockRepo.updateProfile(
            targetUserId: any(named: 'targetUserId'),
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            country: any(named: 'country'))).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AuthPhoneSignUpRequested(
        phone: '+256712345678',
        password: 'Test1234!',
        fullName: 'New User',
        countryCode: 'UG',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignUpRequested emits AuthError when optional email already registered',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256712345678'))
            .thenReturn('+256712345678');
        when(() => mockRepo.checkPhoneRegistered('+256712345678'))
            .thenAnswer((_) async => null);
        when(() => mockRepo.checkLoginRegistered('taken@test.com'))
            .thenAnswer((_) async => 'existing@user.com');
      },
      act: (bloc) => bloc.add(const AuthPhoneSignUpRequested(
        phone: '+256712345678',
        password: 'Test1234!',
        fullName: 'New User',
        countryCode: 'UG',
        email: 'taken@test.com',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          contains('email is already registered'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignUpRequested with referral code calls attributeReferral',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256712345678'))
            .thenReturn('+256712345678');
        when(() => mockRepo.checkPhoneRegistered('+256712345678'))
            .thenAnswer((_) async => null);
        when(() => mockRepo.signUp(
              email: '256712345678@nipanze.test',
              password: 'Test1234!',
              fullName: 'New User',
              phone: '+256712345678',
              countryCode: 'UG',
              referralCode: 'GAVA123',
            )).thenAnswer((_) async => null);
        when(() => mockRepo.signIn(
            email: '256712345678@nipanze.test',
            password: 'Test1234!')).thenAnswer((_) async => testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
        when(() => mockRepo.updateProfile(
            targetUserId: any(named: 'targetUserId'),
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            country: any(named: 'country'))).thenAnswer((_) async {});
        when(() => mockRepo.attributeReferral(
            referralCode: 'GAVA123',
            source: 'registration')).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AuthPhoneSignUpRequested(
        phone: '+256712345678',
        password: 'Test1234!',
        fullName: 'New User',
        countryCode: 'UG',
        referralCode: 'GAVA123',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(() => mockRepo.attributeReferral(
              referralCode: 'GAVA123',
              source: 'registration',
            )).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignUpRequested emits AuthError when signUp throws AppException',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256712345678'))
            .thenReturn('+256712345678');
        when(() => mockRepo.checkPhoneRegistered('+256712345678'))
            .thenAnswer((_) async => null);
        when(() => mockRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
              countryCode: any(named: 'countryCode'),
            )).thenThrow(const AuthException('Registration failed.'));
      },
      act: (bloc) => bloc.add(const AuthPhoneSignUpRequested(
        phone: '+256712345678',
        password: 'Test1234!',
        fullName: 'New User',
        countryCode: 'UG',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignUpRequested emits generic AuthError on unexpected exception',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256712345678'))
            .thenReturn('+256712345678');
        when(() => mockRepo.checkPhoneRegistered('+256712345678'))
            .thenAnswer((_) async => null);
        when(() => mockRepo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
              countryCode: any(named: 'countryCode'),
            )).thenThrow(Exception('server error'));
      },
      act: (bloc) => bloc.add(const AuthPhoneSignUpRequested(
        phone: '+256712345678',
        password: 'Test1234!',
        fullName: 'New User',
        countryCode: 'UG',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          contains('Registration failed'),
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthPhoneSignUpRequested emits error when signIn after signUp fails and no user',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.cleanPhone('+256712345678'))
            .thenReturn('+256712345678');
        when(() => mockRepo.checkPhoneRegistered('+256712345678'))
            .thenAnswer((_) async => null);
        when(() => mockRepo.signUp(
              email: '256712345678@nipanze.test',
              password: 'Test1234!',
              fullName: 'New User',
              phone: '+256712345678',
              countryCode: 'UG',
              referralCode: null,
            )).thenAnswer((_) async => null);
        when(() => mockRepo.signIn(
            email: '256712345678@nipanze.test',
            password: 'Test1234!')).thenThrow(Exception('session init failed'));
        when(() => mockRepo.updateProfile(
            targetUserId: any(named: 'targetUserId'),
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            country: any(named: 'country'))).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AuthPhoneSignUpRequested(
        phone: '+256712345678',
        password: 'Test1234!',
        fullName: 'New User',
        countryCode: 'UG',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          contains('Registration failed'),
        ),
      ],
    );

    // ── Sign Out ──────────────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'AuthSignOutRequested emits AuthUnauthenticated',
      build: () {
        when(() => mockRepo.signOut()).thenAnswer((_) async {});
        return AuthBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    // ── Password Reset ────────────────────────────────────────────────────

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
      'AuthPasswordResetRequested emits AuthError on failure',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.resetPassword(any()))
            .thenThrow(const AuthException('Unable to send reset email.'));
      },
      act: (bloc) =>
          bloc.add(const AuthPasswordResetRequested('test@nipanze.ug')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    // ── Profile Refresh ───────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'AuthProfileRefreshRequested refreshes profile when authenticated',
      build: () => AuthBloc(mockRepo),
      seed: () => const AuthAuthenticated(user: testUser),
      setUp: () {
        when(() => mockRepo.fetchCurrentProfile())
            .thenAnswer((_) async => fullUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
      },
      act: (bloc) => bloc.add(const AuthProfileRefreshRequested()),
      expect: () => [
        isA<AuthAuthenticated>().having(
          (s) => s.user.subscriptionPlan,
          'subscriptionPlan',
          SubscriptionPlan.pro,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthProfileRefreshRequested does nothing when not authenticated',
      build: () => AuthBloc(mockRepo),
      seed: () => const AuthUnauthenticated(),
      act: (bloc) => bloc.add(const AuthProfileRefreshRequested()),
      expect: () => [],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthProfileRefreshRequested does not change state on fetch failure',
      build: () => AuthBloc(mockRepo),
      seed: () => const AuthAuthenticated(user: testUser),
      setUp: () {
        when(() => mockRepo.fetchCurrentProfile())
            .thenThrow(Exception('network'));
      },
      act: (bloc) => bloc.add(const AuthProfileRefreshRequested()),
      expect: () => [],
    );

    // ── User Changed ──────────────────────────────────────────────────────

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

    blocTest<AuthBloc, AuthState>(
      'AuthUserChanged sets needsEmailVerification when email unverified',
      build: () => AuthBloc(mockRepo),
      setUp: () {
        when(() => mockRepo.isEmailVerified).thenReturn(false);
      },
      act: (bloc) => bloc.add(const AuthUserChanged(testUser)),
      expect: () => [
        isA<AuthAuthenticated>().having(
          (s) => s.needsEmailVerification,
          'needsEmailVerification',
          isTrue,
        ),
      ],
    );

    // ── Bypass Email Verification ─────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'AuthBypassEmailVerificationRequested clears needsEmailVerification when authenticated',
      build: () => AuthBloc(mockRepo),
      seed: () => const AuthAuthenticated(
        user: testUser,
        needsEmailVerification: true,
      ),
      act: (bloc) => bloc.add(const AuthBypassEmailVerificationRequested()),
      expect: () => [
        isA<AuthAuthenticated>().having(
          (s) => s.needsEmailVerification,
          'needsEmailVerification',
          isFalse,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthBypassEmailVerificationRequested uses currentUser when not authenticated',
      build: () {
        when(() => mockRepo.currentUser).thenReturn(testUser);
        when(() => mockRepo.isEmailVerified).thenReturn(true);
        return AuthBloc(mockRepo);
      },
      seed: () => const AuthUnauthenticated(),
      act: (bloc) => bloc.add(const AuthBypassEmailVerificationRequested()),
      expect: () => [
        isA<AuthAuthenticated>().having(
          (s) => s.needsEmailVerification,
          'needsEmailVerification',
          isFalse,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthBypassEmailVerificationRequested does nothing when not authenticated and no currentUser',
      build: () {
        when(() => mockRepo.currentUser).thenReturn(null);
        return AuthBloc(mockRepo);
      },
      seed: () => const AuthUnauthenticated(),
      act: (bloc) => bloc.add(const AuthBypassEmailVerificationRequested()),
      expect: () => [],
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

    test('permission denied postgres code maps to PermissionException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'permission denied',
        code: '42501',
      ));
      expect(e, isA<PermissionException>());
    });

    test('NIPANZE_OFFER_LOCKED maps to DatabaseException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_OFFER_LOCKED',
      ));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('already been accepted'));
    });

    test('NIPANZE_ALREADY_REVEALED maps to DatabaseException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_ALREADY_REVEALED',
      ));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('already been revealed'));
    });

    test('NIPANZE_LISTING_EXPIRED maps to DatabaseException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_LISTING_EXPIRED',
      ));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('no longer accepting offers'));
    });

    test('NIPANZE_MIN_OFFER maps to ValidationException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_MIN_OFFER',
      ));
      expect(e, isA<ValidationException>());
      expect(e.message, contains('below the platform minimum'));
    });

    test('NIPANZE_KYC_REQUIRED maps to KycRequiredException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_KYC_REQUIRED',
      ));
      expect(e, isA<KycRequiredException>());
    });

    test('NIPANZE_ACCOUNT_INACTIVE maps to PermissionException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_ACCOUNT_INACTIVE',
      ));
      expect(e, isA<PermissionException>());
      expect(e.message, contains('not active'));
    });

    test('NIPANZE_PRO_REQUIRED maps to Pro SubscriptionRequiredException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_PRO_REQUIRED',
      ));
      expect(e, isA<SubscriptionRequiredException>());
      expect(e.message, contains('Pro'));
    });

    test('NIPANZE_MAX_REQUESTS maps to max listings DatabaseException', () {
      final e = parseSupabaseError(const PostgrestException(
        message: 'NIPANZE_MAX_REQUESTS',
      ));
      expect(e, isA<DatabaseException>());
      expect(e.message, contains('maximum number'));
    });
  });
}
