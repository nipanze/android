// integration_test/integration_test.dart
// Integration tests for Nipanze — requires local Supabase stack.
//
// Prerequisites:
//   supabase start
//   psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -f sql/schema.sql
//   psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -f sql/seed.sql
//
// Run:
//   flutter test integration_test/integration_test.dart -d linux \
//     --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
//     --dart-define=SUPABASE_ANON_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH

// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nipanze/core/config/supabase_config.dart';
import 'package:nipanze/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

// ─── Suite-level setup ────────────────────────────────────────────────────────

Future<void> _suiteSetUp() async {
  await Hive.initFlutter();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: false,
  );
}

// ─── Pump helper ─────────────────────────────────────────────────────────────
//
// pumpAndSettle hangs forever in integration tests on Linux when there is any
// open async source — GoRouterRefreshStream (listens to authBloc.stream) and
// Supabase realtime channels both count. We must never call pumpAndSettle
// after the app is launched; use _pump() everywhere instead.
//
// _pump() drives the clock forward in small steps so animations and async
// futures complete, without waiting for "zero pending work" (which never
// happens while a stream is open).

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
  // Pump long enough for the app to build and auth state to resolve.
  await _pump(tester, total: const Duration(seconds: 5));
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  final fields = find.byType(TextFormField);
  expect(fields, findsWidgets);
  await tester.enterText(fields.first, email);
  await tester.enterText(fields.last, password);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
  // Pump long enough for: network round-trip + AuthAuthenticated + GoRouter
  // redirect + MarketplaceCubit.load() + first frame of MarketplacePage.
  await _pump(tester, total: const Duration(seconds: 8));
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

Future<void> _signOut(WidgetTester tester) async {
  await _tapNav(tester, 'Account');
  final signOutBtn = find.widgetWithText(OutlinedButton, 'Sign out');
  if (signOutBtn.evaluate().isNotEmpty) {
    await tester.tap(signOutBtn);
    await _pump(tester, total: const Duration(seconds: 4));
  }
}

/// Scrolls the first [SingleChildScrollView] on screen downward by [pixels].
/// Uses drag() rather than scrollUntilVisible() because the target widget may
/// not yet be laid out in the tree when we start scrolling.
Future<void> _scrollDown(WidgetTester tester, double pixels) async {
  final scrollable = find.byType(SingleChildScrollView).first;
  await tester.drag(scrollable, Offset(0, -pixels));
  await _pump(tester, total: const Duration(milliseconds: 500));
}

// ─── Test Suite ───────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_suiteSetUp);

  // ── Unauthenticated flow ───────────────────────────────────────────────────

  testWidgets('01. app launches and shows login screen', (tester) async {
    await _launchApp(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Register'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Forgot password?'), findsOneWidget);
  });

  testWidgets('02. empty email fails form validation', (tester) async {
    await _launchApp(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('03. invalid email format fails validation', (tester) async {
    await _launchApp(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'notanemail');
    await tester.enterText(fields.last, 'Test1234!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('04. empty password fails form validation', (tester) async {
    await _launchApp(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'test@nipanze.test');
    await tester.enterText(fields.last, '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('05. wrong credentials shows error banner', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'nobody@nowhere.com', 'wrongpassword');
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('06. Register link opens create-account page', (tester) async {
    await _launchApp(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await _pump(tester);
    expect(find.text('Create account'), findsWidgets);
  });

  testWidgets('07. register: mismatched passwords shows validation error',
      (tester) async {
    await _launchApp(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await _pump(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test User');
    await tester.enterText(fields.at(1), 'new@nipanze.test');
    await tester.enterText(fields.at(2), 'Test1234!');
    await tester.enterText(fields.at(3), 'DifferentPassword!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('08. back from register returns to login', (tester) async {
    await _launchApp(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await _pump(tester);
    final NavigatorState navigator = tester.state(find.byType(Navigator).last);
    navigator.pop();
    await _pump(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('09. forgot password page loads and validates empty email',
      (tester) async {
    await _launchApp(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
    await _pump(tester);
    expect(find.text('Reset password'), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset link'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('10. back from reset-password returns to login', (tester) async {
    await _launchApp(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
    await _pump(tester);
    final NavigatorState navigator = tester.state(find.byType(Navigator).last);
    navigator.pop();
    await _pump(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  // ── Authenticated flow (lender) ────────────────────────────────────────────

  testWidgets('11. successful login lands on Marketplace', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    expect(find.text('Marketplace'), findsWidgets);
  });

  testWidgets('12. marketplace shows live dot and listing count',
      (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await _pump(tester, total: const Duration(seconds: 3));
    expect(find.textContaining('live'), findsWidgets);
  });

  testWidgets(
      '13. filter chips — All, Low risk, High yield, Closing soon all present',
      (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    expect(find.text('All'), findsWidgets);
    expect(find.text('Low risk'), findsWidgets);
    expect(find.text('High yield'), findsWidgets);
    expect(find.text('Closing soon'), findsWidgets);
  });

  testWidgets('14. Low risk filter chip is tappable without crash',
      (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    // Tap the FilterChip widget directly — find.text('Low risk') is ambiguous
    // because listing cards also show a "Low risk" RiskBadge label.
    await tester.tap(find.widgetWithText(FilterChip, 'Low risk'));
    await _pump(tester, total: const Duration(seconds: 3));
    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await _pump(tester, total: const Duration(seconds: 2));
    expect(find.text('Marketplace'), findsWidgets);
  });

  testWidgets('15. notifications icon opens notifications page', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await _pump(tester);
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('16. bottom nav: Watchlist tab', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await _tapNav(tester, 'Watchlist');
    expect(find.text('Watchlist'), findsWidgets);
  });

  testWidgets('17. bottom nav: Positions tab', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await _tapNav(tester, 'Positions');
    expect(find.text('My positions'), findsOneWidget);
  });

  testWidgets('18. Positions: As borrower tab shows no-listings empty state',
      (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await _tapNav(tester, 'Positions');
    await _pump(tester, total: const Duration(seconds: 2));
    expect(find.text('No active listings'), findsOneWidget);
  });

  testWidgets('19. Positions: As lender tab shows no-bids empty state',
      (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await _tapNav(tester, 'Positions');
    await tester.tap(find.text('As lender'));
    await _pump(tester);
    expect(find.text('No active bids'), findsOneWidget);
  });

  testWidgets('20. Positions: Contracts tab shows empty state', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await _tapNav(tester, 'Positions');
    await tester.tap(find.text('Contracts'));
    await _pump(tester);
    expect(find.text('No contracts'), findsOneWidget);
  });

  testWidgets('21. bottom nav: Account tab', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await _tapNav(tester, 'Account');
    // Account page loads async data — give it extra time to render.
    await _pump(tester, total: const Duration(seconds: 3));
    // SectionHeader calls title.toUpperCase() before rendering, so the actual
    // Text widget in the tree contains 'SUBSCRIPTION', not 'Subscription'.
    await _scrollDown(tester, 300);
    expect(find.text('SUBSCRIPTION'), findsOneWidget);
  });

  testWidgets('22. account page has upgrade plan section', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await _tapNav(tester, 'Account');
    await _pump(tester, total: const Duration(seconds: 3));
    // Same reason — SectionHeader uppercases its title.
    await _scrollDown(tester, 500);
    expect(find.text('UPGRADE PLAN'), findsOneWidget);
  });

  testWidgets('23. sign-out returns to login screen', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    await _signOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  // ── Borrower flow ──────────────────────────────────────────────────────────

  testWidgets('24. borrower can sign in', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'borrower@nipanze.test', 'Test1234!');
    expect(find.text('Marketplace'), findsWidgets);
  });

  testWidgets('25. watchlist shows browse-marketplace action', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'borrower@nipanze.test', 'Test1234!');
    await _tapNav(tester, 'Watchlist');
    expect(
      find.widgetWithText(ElevatedButton, 'Browse marketplace'),
      findsOneWidget,
    );
  });

  testWidgets('26. final sign-out', (tester) async {
    await _launchApp(tester);
    await _signIn(tester, 'borrower@nipanze.test', 'Test1234!');
    await _signOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}