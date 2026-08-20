// test/features/auth/auth_register_screens_test.dart
//
// Widget tests for the registration wizard sub-screens.
// Each screen is a stateless widget that receives all state via constructor
// parameters, so we can test rendering and callbacks in isolation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/core/constants/country_constants.dart';
import 'package:nipanze/features/auth/presentation/pages/register/email_login_screen.dart';
import 'package:nipanze/features/auth/presentation/pages/register/otp_screen.dart';
import 'package:nipanze/features/auth/presentation/pages/register/phone_entry_screen.dart';
import 'package:nipanze/features/auth/presentation/pages/register/profile_setup_screen.dart';
import 'package:nipanze/features/auth/presentation/pages/register/success_screen.dart';
import 'package:nipanze/l10n/app_localizations.dart';

// ─── Shared test helpers ─────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 1200)),
        child: Scaffold(body: child),
      ),
    );

// ─── EmailLoginScreen ────────────────────────────────────────────────────────

void main() {
  group('EmailLoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        EmailLoginScreen(
          formKey: formKey,
          emailController: emailCtrl,
          passwordController: passwordCtrl,
          obscurePassword: true,
          isLoading: false,
          errorMsg: null,
          onTogglePassword: () {},
          onBack: () {},
          onSubmit: () {},
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
    });

    testWidgets('shows error banner when errorMsg is provided',
        (tester) async {
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        EmailLoginScreen(
          formKey: formKey,
          emailController: emailCtrl,
          passwordController: passwordCtrl,
          obscurePassword: true,
          isLoading: false,
          errorMsg: 'Invalid credentials',
          onTogglePassword: () {},
          onBack: () {},
          onSubmit: () {},
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('disables submit button when loading', (tester) async {
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        EmailLoginScreen(
          formKey: formKey,
          emailController: emailCtrl,
          passwordController: passwordCtrl,
          obscurePassword: true,
          isLoading: true,
          errorMsg: null,
          onTogglePassword: () {},
          onBack: () {},
          onSubmit: () {},
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      ));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('onSubmit callback is invoked', (tester) async {
      var submitted = false;
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        EmailLoginScreen(
          formKey: formKey,
          emailController: emailCtrl,
          passwordController: passwordCtrl,
          obscurePassword: true,
          isLoading: false,
          errorMsg: null,
          onTogglePassword: () {},
          onBack: () {},
          onSubmit: () => submitted = true,
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(submitted, isTrue);
    });

    testWidgets('onBack callback is invoked', (tester) async {
      var backed = false;
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        EmailLoginScreen(
          formKey: formKey,
          emailController: emailCtrl,
          passwordController: passwordCtrl,
          obscurePassword: true,
          isLoading: false,
          errorMsg: null,
          onTogglePassword: () {},
          onBack: () => backed = true,
          onSubmit: () {},
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();
      expect(backed, isTrue);
    });

    testWidgets('onForgotPassword callback is invoked', (tester) async {
      var forgotTapped = false;
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        EmailLoginScreen(
          formKey: formKey,
          emailController: emailCtrl,
          passwordController: passwordCtrl,
          obscurePassword: true,
          isLoading: false,
          errorMsg: null,
          onTogglePassword: () {},
          onBack: () {},
          onSubmit: () {},
          onForgotPassword: () => forgotTapped = true,
          onCreateAccount: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      expect(forgotTapped, isTrue);
    });

    testWidgets('onCreateAccount callback is invoked', (tester) async {
      var createTapped = false;
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        EmailLoginScreen(
          formKey: formKey,
          emailController: emailCtrl,
          passwordController: passwordCtrl,
          obscurePassword: true,
          isLoading: false,
          errorMsg: null,
          onTogglePassword: () {},
          onBack: () {},
          onSubmit: () {},
          onForgotPassword: () {},
          onCreateAccount: () => createTapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create an account'));
      await tester.pump();
      expect(createTapped, isTrue);
    });

    testWidgets('password visibility toggle works', (tester) async {
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();
      var toggled = false;

      await tester.pumpWidget(_wrap(
        EmailLoginScreen(
          formKey: formKey,
          emailController: emailCtrl,
          passwordController: passwordCtrl,
          obscurePassword: true,
          isLoading: false,
          errorMsg: null,
          onTogglePassword: () => toggled = true,
          onBack: () {},
          onSubmit: () {},
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(toggled, isTrue);
    });
  });

  // ─── OtpScreen ───────────────────────────────────────────────────────────

  group('OtpScreen', () {
    List<TextEditingController> makeCtrls() =>
        List.generate(6, (_) => TextEditingController());
    List<FocusNode> makeFocus() =>
        List.generate(6, (_) => FocusNode());

    testWidgets('renders 6 OTP input boxes and verify button',
        (tester) async {
      final ctrls = makeCtrls();
      final focus = makeFocus();

      await tester.pumpWidget(_wrap(
        OtpScreen(
          phone: '+256712345678',
          isReturningUser: false,
          controllers: ctrls,
          focusNodes: focus,
          isLoading: false,
          resendSeconds: 0,
          errorMsg: null,
          onBack: () {},
          onVerify: () {},
          onResend: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(find.textContaining('+256712345678'), findsOneWidget);
    });

    testWidgets('shows phone number', (tester) async {
      final ctrls = makeCtrls();
      final focus = makeFocus();

      await tester.pumpWidget(_wrap(
        OtpScreen(
          phone: '+256700000000',
          isReturningUser: false,
          controllers: ctrls,
          focusNodes: focus,
          isLoading: false,
          resendSeconds: 0,
          errorMsg: null,
          onBack: () {},
          onVerify: () {},
          onResend: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('+256700000000'), findsOneWidget);
    });

    testWidgets('shows error banner when errorMsg is provided',
        (tester) async {
      final ctrls = makeCtrls();
      final focus = makeFocus();

      await tester.pumpWidget(_wrap(
        OtpScreen(
          phone: '+256712345678',
          isReturningUser: false,
          controllers: ctrls,
          focusNodes: focus,
          isLoading: false,
          resendSeconds: 0,
          errorMsg: 'OTP verification failed',
          onBack: () {},
          onVerify: () {},
          onResend: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('OTP verification failed'), findsOneWidget);
    });

    testWidgets('shows countdown when resendSeconds > 0', (tester) async {
      final ctrls = makeCtrls();
      final focus = makeFocus();

      await tester.pumpWidget(_wrap(
        OtpScreen(
          phone: '+256712345678',
          isReturningUser: false,
          controllers: ctrls,
          focusNodes: focus,
          isLoading: false,
          resendSeconds: 25,
          errorMsg: null,
          onBack: () {},
          onVerify: () {},
          onResend: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('00:25', findRichText: true), findsOneWidget);
    });

    testWidgets('shows Resend Code when countdown is 0', (tester) async {
      final ctrls = makeCtrls();
      final focus = makeFocus();

      await tester.pumpWidget(_wrap(
        OtpScreen(
          phone: '+256712345678',
          isReturningUser: false,
          controllers: ctrls,
          focusNodes: focus,
          isLoading: false,
          resendSeconds: 0,
          errorMsg: null,
          onBack: () {},
          onVerify: () {},
          onResend: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Resend Code'), findsOneWidget);
    });

    testWidgets('onResend callback is invoked', (tester) async {
      var resendTapped = false;
      final ctrls = makeCtrls();
      final focus = makeFocus();

      await tester.pumpWidget(_wrap(
        OtpScreen(
          phone: '+256712345678',
          isReturningUser: false,
          controllers: ctrls,
          focusNodes: focus,
          isLoading: false,
          resendSeconds: 0,
          errorMsg: null,
          onBack: () {},
          onVerify: () {},
          onResend: () => resendTapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resend Code'));
      await tester.pump();
      expect(resendTapped, isTrue);
    });

    testWidgets('disables verify button when loading', (tester) async {
      final ctrls = makeCtrls();
      final focus = makeFocus();

      await tester.pumpWidget(_wrap(
        OtpScreen(
          phone: '+256712345678',
          isReturningUser: false,
          controllers: ctrls,
          focusNodes: focus,
          isLoading: true,
          resendSeconds: 0,
          errorMsg: null,
          onBack: () {},
          onVerify: () {},
          onResend: () {},
        ),
      ));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(btn.onPressed, isNull);
    });
  });

  // ─── PhoneEntryScreen ────────────────────────────────────────────────────

  group('PhoneEntryScreen', () {
    testWidgets('renders phone input and Send Code button', (tester) async {
      final ctrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        PhoneEntryScreen(
          formKey: formKey,
          selectedCountry: EastAfricaCountries.defaultCountry,
          controller: ctrl,
          isLoading: false,
          onCountryTap: () {},
          onBack: () {},
          onNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
    });

    testWidgets('shows default country dial code', (tester) async {
      final ctrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        PhoneEntryScreen(
          formKey: formKey,
          selectedCountry: EastAfricaCountries.defaultCountry,
          controller: ctrl,
          isLoading: false,
          onCountryTap: () {},
          onBack: () {},
          onNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(EastAfricaCountries.defaultCountry.dialCode),
        findsOneWidget,
      );
    });

    testWidgets('onNext callback is invoked', (tester) async {
      var nextTapped = false;
      final ctrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        PhoneEntryScreen(
          formKey: formKey,
          selectedCountry: EastAfricaCountries.defaultCountry,
          controller: ctrl,
          isLoading: false,
          onCountryTap: () {},
          onBack: () {},
          onNext: () => nextTapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();
      expect(nextTapped, isTrue);
    });

    testWidgets('disables Send Code when loading', (tester) async {
      final ctrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(_wrap(
        PhoneEntryScreen(
          formKey: formKey,
          selectedCountry: EastAfricaCountries.defaultCountry,
          controller: ctrl,
          isLoading: true,
          onCountryTap: () {},
          onBack: () {},
          onNext: () {},
        ),
      ));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(btn.onPressed, isNull);
    });
  });

  // ─── ProfileSetupScreen ──────────────────────────────────────────────────

  group('ProfileSetupScreen', () {
    Widget buildProfile(
      WidgetTester tester, {
      bool isReturningUser = false,
      bool isLoading = false,
      String? errorMsg,
    }) {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final nameCtrl = TextEditingController();
      final emailCtrl = TextEditingController();
      final passwordCtrl = TextEditingController();
      final confirmCtrl = TextEditingController();
      final referralCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      return _wrap(
        ProfileSetupScreen(
          isReturningUser: isReturningUser,
          nameController: nameCtrl,
          emailController: emailCtrl,
          passwordController: passwordCtrl,
          confirmController: confirmCtrl,
          referralCodeController: referralCtrl,
          obscurePassword: true,
          obscureConfirm: true,
          formKey: formKey,
          isLoading: isLoading,
          errorMsg: errorMsg,
          onTogglePassword: () {},
          onToggleConfirm: () {},
          onBack: () {},
          onSubmit: () {},
        ),
      );
    }

    testWidgets('renders profile fields for new user', (tester) async {
      await tester.pumpWidget(buildProfile(tester));
      await tester.pumpAndSettle();

      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Email (optional)'), findsOneWidget);
      expect(find.text('Create password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Referral code (optional)'), findsOneWidget);
    });

    testWidgets('renders only password field for returning user',
        (tester) async {
      await tester.pumpWidget(buildProfile(tester, isReturningUser: true));
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Full name'), findsNothing);
      expect(find.text('Confirm password'), findsNothing);
    });

    testWidgets('shows error banner when errorMsg is provided',
        (tester) async {
      await tester
          .pumpWidget(buildProfile(tester, errorMsg: 'Registration failed'));
      await tester.pumpAndSettle();

      expect(find.text('Registration failed'), findsOneWidget);
    });

    testWidgets('disables submit button when loading', (tester) async {
      await tester.pumpWidget(buildProfile(tester, isLoading: true));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('avatar picker circle is visible for new user',
        (tester) async {
      await tester.pumpWidget(buildProfile(tester));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('avatar picker is hidden for returning user', (tester) async {
      await tester
          .pumpWidget(buildProfile(tester, isReturningUser: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt_rounded), findsNothing);
    });
  });

  // ─── SuccessScreen ───────────────────────────────────────────────────────

  group('SuccessScreen', () {
    testWidgets('renders success title and marketplace button',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SuccessScreen(onGoToMarketplace: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining("You're in!"), findsOneWidget);
      expect(find.text('Go to Marketplace'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('shows feature cards', (tester) async {
      await tester.pumpWidget(_wrap(
        SuccessScreen(onGoToMarketplace: () {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Explore loan requests'), findsOneWidget);
      expect(find.text('Safe & secure'), findsOneWidget);
    });

    testWidgets('onGoToMarketplace callback is invoked', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        SuccessScreen(onGoToMarketplace: () => tapped = true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Marketplace'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
