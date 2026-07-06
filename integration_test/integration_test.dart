// integration_test/integration_test.dart
// Integration tests for Nipanze — runs against Supabase Cloud.
//
// Run:
//   source .env.local && flutter test integration_test/integration_test.dart \
//     -d chrome \
//     --dart-define=SUPABASE_URL="$SUPABASE_URL" \
//     --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
//
// Test accounts (password: Test1234!) — from seed v2.0 on cloud:
//   Borrower (Both/Pro): james.okello@outlook.com
//   Borrower (Free):     maria.nakato@gmail.com
//   Lender (Pro):        invest@pearlcapital.ug
//   Lender (Lender):     lending@equatorfinance.ug
//   KYC pending:         alice.namuli@gmail.com

// ignore_for_file: unused_local_variable, directives_ordering, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nipanze/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:nipanze/main.dart' as app;
import 'package:nipanze/features/marketplace/presentation/widgets/listing_card.dart';
import 'package:nipanze/features/positions/presentation/widgets/lender_offer_card.dart';

// ─── Cloud seed account credentials ──────────────────────────────────────────

const _kPassword = 'Test1234!';

// Borrower (Both/Pro) — active request with 2 pending offers
const _kBorrowerBoth = 'james.okello@outlook.com';

// Lender (Pro) — offer accepted, contact revealed (contracted)
const _kLenderPro = 'invest@pearlcapital.ug';

// Lender — pending offer on James's request
const _kLenderActive = 'lending@equatorfinance.ug';

// KYC pending
const _kKycPending = 'alice.namuli@gmail.com';

// ─── Suite-level setup ────────────────────────────────────────────────────────

Future<void> _suiteSetUp() async {
  await Hive.initFlutter();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: false,
  );
}

// ─── Pump helpers ─────────────────────────────────────────────────────────────
//
// pumpAndSettle hangs forever when GoRouterRefreshStream / Realtime channels
// are open. Use _pump() everywhere — it advances time in fixed steps.

Future<void> _pump(
  WidgetTester tester, {
  Duration total = const Duration(seconds: 4),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final steps = total.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

// ─── App launch ───────────────────────────────────────────────────────────────

Future<void> _launchApp(WidgetTester tester) async {
  try {
    await Supabase.instance.client.auth.signOut();
  } catch (_) {}
  await Future<void>.delayed(const Duration(milliseconds: 300));
  app.main();
  await _pump(tester, total: const Duration(seconds: 5));
}

// ─── Common helpers ───────────────────────────────────────────────────────────

Future<void> _enterText(WidgetTester tester, Finder fieldFinder, String text) async {
  expect(fieldFinder, findsOneWidget);
  final topLeft = tester.getTopLeft(fieldFinder);
  await tester.tapAt(topLeft + const Offset(30, 20));
  await tester.pump();
  tester.testTextInput.enterText(text);
  await tester.pump();
}

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  final emailFinder = find.byKey(const Key('email_field'));
  final pwdFinder = find.byKey(const Key('password_field'));
  expect(emailFinder, findsOneWidget);
  expect(pwdFinder, findsOneWidget);
  await _enterText(tester, emailFinder, email);
  await _enterText(tester, pwdFinder, password);
  await tester.pump();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
  // Network round-trip + auth redirect + data load
  await _pump(tester, total: const Duration(seconds: 10));
}

Future<void> _tapNav(WidgetTester tester, String label) async {
  final navBar = find.byType(BottomNavigationBar);
  expect(navBar, findsOneWidget);
  final labelFinder = find.descendant(
    of: navBar,
    matching: find.text(label),
  );
  expect(labelFinder, findsOneWidget);
  await tester.tapAt(tester.getCenter(labelFinder));
  await _pump(tester, total: const Duration(seconds: 3));
}

Future<void> _goAccount(WidgetTester tester) async {
  await _tapNav(tester, 'Account');
  await _pump(tester, total: const Duration(seconds: 4));
}

Future<void> _signOut(WidgetTester tester) async {
  await _goAccount(tester);
  for (var i = 0; i < 10; i++) {
    final signOutBtn = find.widgetWithText(OutlinedButton, 'Sign out');
    if (signOutBtn.evaluate().isNotEmpty) {
      try {
        await tester.ensureVisible(signOutBtn);
        await _pump(tester, total: const Duration(milliseconds: 300));
        await tester.tap(signOutBtn);
        await _pump(tester, total: const Duration(seconds: 5));
        return;
      } catch (_) {}
    }
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await _pump(tester, total: const Duration(milliseconds: 200));
  }
}

// ─── Test Suite ───────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_suiteSetUp);

  testWidgets('Nipanze End-to-End E2E Integration Suite', (tester) async {
    // 1. Initial Launch
    print('[START] Restructured Nipanze E2E Integration Suite running sequentially');
    await _launchApp(tester);

    // ==========================================================================
    // GROUP A: Auth screens (unauthenticated)
    // ==========================================================================
    print('[TEST] A01. login screen loads');
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Register'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Forgot password?'), findsOneWidget);

    print('[TEST] A02. empty email fails validation');
    final emailField = find.byKey(const Key('email_field'));
    expect(emailField, findsOneWidget);
    await _enterText(tester, emailField, '');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);

    print('[TEST] A03. invalid email format fails validation');
    final pwdField = find.byKey(const Key('password_field'));
    expect(pwdField, findsOneWidget);
    await _enterText(tester, emailField, 'notanemail');
    await _enterText(tester, pwdField, _kPassword);
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);

    print('[TEST] A04. empty password fails validation');
    await _enterText(tester, emailField, 'test@nipanze.test');
    await _enterText(tester, pwdField, '');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your password'), findsOneWidget);

    print('[TEST] A05. wrong credentials shows error');
    await _enterText(tester, emailField, 'nobody@nowhere.com');
    await _enterText(tester, pwdField, 'wrongpassword');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await _pump(tester, total: const Duration(seconds: 10)); // wait for network roundtrip + error render
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    print('[TEST] A06. Register link navigates to create-account');
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await _pump(tester);
    expect(find.text('Create account'), findsWidgets);
    // Tap back button
    final backBtn1 = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn1, findsOneWidget);
    await tester.tap(backBtn1);
    await _pump(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    print('[TEST] A07. forgot password page loads');
    await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
    await _pump(tester);
    expect(find.text('Reset password'), findsWidgets);
    // Tap back button
    final backBtn2 = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn2, findsOneWidget);
    await tester.tap(backBtn2);
    await _pump(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    // ==========================================================================
    // GROUP B: Borrower flow (cloud)
    // ==========================================================================
    print('[TEST] B01-B03. Sign in as borrower and inspect feed');
    await _signIn(tester, _kBorrowerBoth, _kPassword);
    expect(find.text('Marketplace'), findsWidgets);
    expect(find.byType(ListingCard), findsWidgets);

    print('[TEST] B04-B05. Toggle listing watchlist from detail page');
    final cards = find.byType(ListingCard);
    if (cards.evaluate().isNotEmpty) {
      await tester.tap(cards.first);
      await _pump(tester, total: const Duration(seconds: 4));
      expect(find.byType(Scaffold), findsWidgets);

      final starIcon = find.byIcon(Icons.star_outline);
      final starFilledIcon = find.byIcon(Icons.star);
      final bookmarkIcon = find.byIcon(Icons.bookmark_border);
      if (starIcon.evaluate().isNotEmpty) {
        await tester.tap(starIcon.first);
        await _pump(tester, total: const Duration(seconds: 3));
        expect(find.byIcon(Icons.star), findsWidgets);
      } else if (bookmarkIcon.evaluate().isNotEmpty) {
        await tester.tap(bookmarkIcon.first);
        await _pump(tester, total: const Duration(seconds: 3));
      }
      
      // Tap back button to exit detail page
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await _pump(tester, total: const Duration(seconds: 3));
      }
    }

    print('[TEST] B06. Watchlist tab loads');
    await _tapNav(tester, 'Watchlist');
    expect(find.text('Watchlist'), findsWidgets);

    print('[TEST] B07. Request tab opens');
    await _tapNav(tester, 'Request');
    await _pump(tester, total: const Duration(seconds: 3));
    expect(find.byType(TextFormField), findsWidgets);

    print('[TEST] B08. Positions my requests check');
    await _tapNav(tester, 'Positions');
    await _pump(tester, total: const Duration(seconds: 4));
    expect(find.text('My Requests'), findsWidgets);

    print('[TEST] B09. Positions my offers check');
    final myOffersTab = find.text('My Offers');
    if (myOffersTab.evaluate().isNotEmpty) {
      await tester.tap(myOffersTab.first);
      await _pump(tester, total: const Duration(seconds: 3));
    }

    print('[TEST] B10. Account page email check');
    await _goAccount(tester);
    expect(find.textContaining('okello'), findsWidgets);

    print('[TEST] B11. Sign out borrower');
    await _signOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    // ==========================================================================
    // GROUP C: Lender flow (cloud)
    // ==========================================================================
    print('[TEST] C01-C02. Sign in lender and inspect feed');
    await _signIn(tester, _kLenderActive, _kPassword);
    expect(find.text('Marketplace'), findsWidgets);
    expect(find.byType(ListingCard), findsWidgets);

    print('[TEST] C03. Lender detail page check');
    final lenderCards = find.byType(ListingCard);
    if (lenderCards.evaluate().isNotEmpty) {
      await tester.tap(lenderCards.first);
      await _pump(tester, total: const Duration(seconds: 4));
      expect(find.byType(Scaffold), findsWidgets);
      
      // Navigate back
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await _pump(tester, total: const Duration(seconds: 3));
      }
    }

    print('[TEST] C04-C05. Lender Positions check and withdraw offer cancel choice');
    await _tapNav(tester, 'Positions');
    await _pump(tester, total: const Duration(seconds: 4));
    
    final lenderOffersTab = find.text('My Offers');
    if (lenderOffersTab.evaluate().isNotEmpty) {
      await tester.tap(lenderOffersTab.first);
      await _pump(tester, total: const Duration(seconds: 4));
      expect(find.byType(LenderOfferCard), findsWidgets);
      
      final withdrawBtn = find.widgetWithText(OutlinedButton, 'Withdraw');
      if (withdrawBtn.evaluate().isNotEmpty) {
        await tester.tap(withdrawBtn.first);
        await _pump(tester, total: const Duration(seconds: 2));
        
        expect(find.byType(AlertDialog), findsOneWidget);
        final cancelBtn = find.widgetWithText(TextButton, 'Keep Offer');
        if (cancelBtn.evaluate().isNotEmpty) {
          await tester.tap(cancelBtn.first);
          await _pump(tester);
        }
      }
    }

    print('[TEST] C06. Lender Watchlist tab');
    await _tapNav(tester, 'Watchlist');
    expect(find.text('Watchlist'), findsWidgets);

    print('[TEST] C07. Lender Account page email check');
    await _goAccount(tester);
    expect(find.textContaining('equatorfinance'), findsWidgets);

    print('[TEST] C08. Sign out lender');
    await _signOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    // ==========================================================================
    // GROUP D: KYC flow (cloud)
    // ==========================================================================
    print('[TEST] D01. KYC-pending user logs in');
    await _signIn(tester, _kKycPending, _kPassword);
    expect(find.text('Marketplace'), findsWidgets);

    print('[TEST] D02-D03. KYC-pending user account check and page navigation');
    await _goAccount(tester);
    expect(find.text('Account'), findsWidgets);
    
    final kycBtn = find.textContaining('KYC');
    final verifyBtn = find.textContaining('Verification');
    if (kycBtn.evaluate().isNotEmpty) {
      await tester.tap(kycBtn.first);
      await _pump(tester, total: const Duration(seconds: 3));
      expect(find.byType(Scaffold), findsWidgets);
      // Navigate back
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await _pump(tester, total: const Duration(seconds: 3));
      }
    } else if (verifyBtn.evaluate().isNotEmpty) {
      await tester.tap(verifyBtn.first);
      await _pump(tester, total: const Duration(seconds: 3));
      expect(find.byType(Scaffold), findsWidgets);
      // Navigate back
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await _pump(tester, total: const Duration(seconds: 3));
      }
    }

    print('[TEST] Sign out KYC-pending user');
    await _signOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    // ==========================================================================
    // GROUP E: Notifications and lender notification audit
    // ==========================================================================
    print('[TEST] E01. James Okello notification layout check');
    await _signIn(tester, _kBorrowerBoth, _kPassword);
    final notifIcon = find.byIcon(Icons.notifications_outlined);
    if (notifIcon.evaluate().isNotEmpty) {
      await tester.tap(notifIcon.first);
      await _pump(tester);
      expect(find.text('Notifications'), findsWidgets);
      
      // Tap back button from notifications
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await _pump(tester, total: const Duration(seconds: 3));
      }
    }
    
    // Sign out James
    await _signOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);

    print('[TEST] E02. Pearl Capital notification layout check');
    await _signIn(tester, _kLenderPro, _kPassword);
    final proNotifIcon = find.byIcon(Icons.notifications_outlined);
    if (proNotifIcon.evaluate().isNotEmpty) {
      await tester.tap(proNotifIcon.first);
      await _pump(tester, total: const Duration(seconds: 3));
      expect(find.text('Notifications'), findsWidgets);
      
      // Tap back button from notifications
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await _pump(tester, total: const Duration(seconds: 3));
      }
    }
    
    // Sign out Pearl capital
    await _signOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    
    print('[SUCCESS] All Nipanze integration tests passed successfully!');
  });
}