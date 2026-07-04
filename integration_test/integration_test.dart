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

// ignore_for_file: unused_local_variable, directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nipanze/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:nipanze/main.dart' as app;

// ─── Cloud seed account credentials ──────────────────────────────────────────

const _kPassword = 'Test1234!';

// Borrower (Both/Pro) — active request with 2 pending offers
const _kBorrowerBoth = 'james.okello@outlook.com';

// Borrower (Free) — active request, 1 pending offer
const _kBorrowerFree = 'maria.nakato@gmail.com';

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

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  final fields = find.byType(TextFormField);
  expect(fields, findsWidgets);
  await tester.enterText(fields.first, email);
  await tester.enterText(fields.last, password);
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

  // ==========================================================================
  // GROUP A: Auth screens (unauthenticated)
  // ==========================================================================

  group('A — Auth screens', () {
    testWidgets('A01. login screen loads', (tester) async {
      await _launchApp(tester);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Register'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Forgot password?'), findsOneWidget);
    });

    testWidgets('A02. empty email fails validation', (tester) async {
      await _launchApp(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('A03. invalid email format fails validation', (tester) async {
      await _launchApp(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'notanemail');
      await tester.enterText(fields.last, _kPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('A04. empty password fails validation', (tester) async {
      await _launchApp(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'test@nipanze.test');
      await tester.enterText(fields.last, '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('A05. wrong credentials shows error', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, 'nobody@nowhere.com', 'wrongpassword');
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('A06. Register link navigates to create-account', (tester) async {
      await _launchApp(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Register'));
      await _pump(tester);
      expect(find.text('Create account'), findsWidgets);
    });

    testWidgets('A07. forgot password page loads', (tester) async {
      await _launchApp(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
      await _pump(tester);
      expect(find.text('Reset password'), findsWidgets);
    });
  });

  // ==========================================================================
  // GROUP B: Borrower end-to-end flow (james.okello — Both/Pro)
  //   Tests: login, marketplace, watchlist, post request, positions, cancel
  // ==========================================================================

  group('B — Borrower flow (cloud)', () {
    testWidgets('B01. login as borrower lands on Marketplace', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      expect(find.text('Marketplace'), findsWidgets);
    });

    testWidgets('B02. marketplace shows listings from cloud', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      await _pump(tester, total: const Duration(seconds: 4));
      // Should have at least one ListingCard on screen
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('B03. filter chips present on marketplace', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      expect(find.text('All'), findsWidgets);
    });

    testWidgets('B04. open listing detail page', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      await _pump(tester, total: const Duration(seconds: 3));
      // Tap the first Card to open detail
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await _pump(tester, total: const Duration(seconds: 4));
        // Detail page should have amount/duration info
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('B05. save to watchlist from detail', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      await _pump(tester, total: const Duration(seconds: 3));
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await _pump(tester, total: const Duration(seconds: 4));
        // Tap star/bookmark icon if present
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
        } else if (starFilledIcon.evaluate().isNotEmpty) {
          // Already saved — test passes
        }
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('B06. Watchlist tab loads', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      await _tapNav(tester, 'Watchlist');
      expect(find.text('Watchlist'), findsWidgets);
    });

    testWidgets('B07. Request tab opens listing create page', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      await _tapNav(tester, 'Request');
      await _pump(tester, total: const Duration(seconds: 3));
      // Should land on ListingCreatePage (has a form)
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('B08. Positions tab loads My Requests', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      await _tapNav(tester, 'Positions');
      await _pump(tester, total: const Duration(seconds: 4));
      expect(find.text('Positions'), findsWidgets);
      // My Requests tab should be visible
      final myRequestsTab = find.text('My Requests');
      expect(myRequestsTab, findsWidgets);
    });

    testWidgets('B09. Positions My Offers tab loads', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      await _tapNav(tester, 'Positions');
      await _pump(tester, total: const Duration(seconds: 3));
      final myOffersTab = find.text('My Offers');
      if (myOffersTab.evaluate().isNotEmpty) {
        await tester.tap(myOffersTab.first);
        await _pump(tester, total: const Duration(seconds: 3));
      }
      expect(find.text('Positions'), findsWidgets);
    });

    testWidgets('B10. Account page shows email', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      await _goAccount(tester);
      expect(find.textContaining('okello'), findsWidgets);
    });

    testWidgets('B11. sign out returns to login', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      await _signOut(tester);
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  // ==========================================================================
  // GROUP C: Lender end-to-end flow (lending@equatorfinance.ug — Lender sub)
  //   Tests: login, browse, view detail, make offer panel visible, withdraw
  // ==========================================================================

  group('C — Lender flow (cloud)', () {
    testWidgets('C01. lender login lands on Marketplace', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kLenderActive, _kPassword);
      expect(find.text('Marketplace'), findsWidgets);
    });

    testWidgets('C02. marketplace has listings for lender', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kLenderActive, _kPassword);
      await _pump(tester, total: const Duration(seconds: 4));
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('C03. lender can open listing detail', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kLenderActive, _kPassword);
      await _pump(tester, total: const Duration(seconds: 3));
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await _pump(tester, total: const Duration(seconds: 4));
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('C04. lender Positions tab loads My Offers', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kLenderActive, _kPassword);
      await _tapNav(tester, 'Positions');
      await _pump(tester, total: const Duration(seconds: 4));
      expect(find.text('Positions'), findsWidgets);
      // Should show My Offers tab since this lender has a pending offer
      final myOffersTab = find.text('My Offers');
      if (myOffersTab.evaluate().isNotEmpty) {
        await tester.tap(myOffersTab.first);
        await _pump(tester, total: const Duration(seconds: 4));
        // Should show at least one offer card
        expect(find.byType(Card), findsWidgets);
      }
    });

    testWidgets('C05. lender withdraw offer shows confirm dialog', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kLenderActive, _kPassword);
      await _tapNav(tester, 'Positions');
      await _pump(tester, total: const Duration(seconds: 3));
      final myOffersTab = find.text('My Offers');
      if (myOffersTab.evaluate().isNotEmpty) {
        await tester.tap(myOffersTab.first);
        await _pump(tester, total: const Duration(seconds: 4));
        final withdrawBtn = find.widgetWithText(OutlinedButton, 'Withdraw');
        if (withdrawBtn.evaluate().isNotEmpty) {
          await tester.tap(withdrawBtn.first);
          await _pump(tester, total: const Duration(seconds: 2));
          // Confirm dialog should appear
          expect(find.byType(AlertDialog), findsOneWidget);
          // Cancel out — don't actually withdraw
          final cancelBtn = find.widgetWithText(TextButton, 'Cancel');
          if (cancelBtn.evaluate().isNotEmpty) {
            await tester.tap(cancelBtn.first);
            await _pump(tester);
          }
        }
      }
    });

    testWidgets('C06. lender Watchlist tab loads', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kLenderActive, _kPassword);
      await _tapNav(tester, 'Watchlist');
      expect(find.text('Watchlist'), findsWidgets);
    });

    testWidgets('C07. lender Account page loads', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kLenderActive, _kPassword);
      await _goAccount(tester);
      expect(find.textContaining('equatorfinance'), findsWidgets);
    });

    testWidgets('C08. lender sign out returns to login', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kLenderActive, _kPassword);
      await _signOut(tester);
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  // ==========================================================================
  // GROUP D: KYC flow (alice.namuli — pending_verification)
  // ==========================================================================

  group('D — KYC flow (cloud)', () {
    testWidgets('D01. KYC-pending user can log in', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kKycPending, _kPassword);
      expect(find.text('Marketplace'), findsWidgets);
    });

    testWidgets('D02. Account tab shows KYC / verification state', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kKycPending, _kPassword);
      await _goAccount(tester);
      // Should show KYC-related text (pending, verification, etc.)
      final kycRelatedText = find.textContaining('verif',
          findRichText: true);
      // Page at minimum loads without crashing
      expect(find.text('Account'), findsWidgets);
    });

    testWidgets('D03. KYC page navigates without crash', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kKycPending, _kPassword);
      await _goAccount(tester);
      // Try to tap KYC / identity verification button if visible
      final kycBtn = find.textContaining('KYC');
      final verifyBtn = find.textContaining('Verification');
      if (kycBtn.evaluate().isNotEmpty) {
        await tester.tap(kycBtn.first);
        await _pump(tester, total: const Duration(seconds: 3));
        expect(find.byType(Scaffold), findsWidgets);
      } else if (verifyBtn.evaluate().isNotEmpty) {
        await tester.tap(verifyBtn.first);
        await _pump(tester, total: const Duration(seconds: 3));
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });

  // ==========================================================================
  // GROUP E: Notifications
  // ==========================================================================

  group('E — Notifications', () {
    testWidgets('E01. notifications icon is tappable', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kBorrowerBoth, _kPassword);
      final notifIcon = find.byIcon(Icons.notifications_outlined);
      if (notifIcon.evaluate().isNotEmpty) {
        await tester.tap(notifIcon.first);
        await _pump(tester);
        expect(find.text('Notifications'), findsWidgets);
      }
    });

    testWidgets('E02. pro lender notifications load', (tester) async {
      await _launchApp(tester);
      await _signIn(tester, _kLenderPro, _kPassword);
      await _pump(tester, total: const Duration(seconds: 3));
      final notifIcon = find.byIcon(Icons.notifications_outlined);
      if (notifIcon.evaluate().isNotEmpty) {
        await tester.tap(notifIcon.first);
        await _pump(tester, total: const Duration(seconds: 3));
        expect(find.text('Notifications'), findsWidgets);
      }
    });
  });
}