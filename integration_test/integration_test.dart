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
//
// Test users seeded by seed.sql:
//   borrower@nipanze.test  / Test1234!
//   lender@nipanze.test    / Test1234!

// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nipanze/main.dart' as app;

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Sign in via the login form. Call only from login screen.
Future<void> _signIn(WidgetTester tester, String email, String password) async {
  expect(find.byType(TextFormField), findsWidgets);
  await tester.enterText(find.byType(TextFormField).first, email);
  await tester.enterText(find.byType(TextFormField).last, password);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
  await tester.pumpAndSettle(const Duration(seconds: 6));
}

/// Sign out from Account tab. Call only when authenticated.
Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.person_outline_rounded));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  final signOutBtn = find.widgetWithText(OutlinedButton, 'Sign out');
  if (signOutBtn.evaluate().isNotEmpty) {
    await tester.tap(signOutBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

// ─── Test Suite ───────────────────────────────────────────────────────────────
//
// All tests run in a SINGLE app instance — integration tests cannot restart
// the Flutter engine mid-run. Tests are ordered: unauthenticated → sign in →
// authenticated flows → sign out.

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01. app launches and shows login screen', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Register'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Forgot password?'), findsOneWidget);
  });

  testWidgets('02. empty email fails form validation', (tester) async {
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('03. invalid email format fails validation', (tester) async {
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'notanemail');
    await tester.enterText(fields.last, 'Test1234!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('04. empty password fails form validation', (tester) async {
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'test@nipanze.test');
    await tester.enterText(fields.last, '');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('05. wrong credentials shows error banner', (tester) async {
    await tester.pumpAndSettle();
    await _signIn(tester, 'nobody@nowhere.com', 'wrongpassword');
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('06. Register link opens create-account page', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('07. register: mismatched passwords shows validation error', (tester) async {
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test User');
    await tester.enterText(fields.at(1), 'new@nipanze.test');
    await tester.enterText(fields.at(2), 'Test1234!');
    await tester.enterText(fields.at(3), 'DifferentPassword!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('08. back from register returns to login', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('09. forgot password page loads and validates empty email', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('10. back from reset-password returns to login', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  // ── Sign in and authenticated tests ────────────────────────────────────────

  testWidgets('11. successful login lands on Marketplace', (tester) async {
    await tester.pumpAndSettle();
    await _signIn(tester, 'lender@nipanze.test', 'Test1234!');
    expect(find.text('Marketplace'), findsWidgets);
  });

  testWidgets('12. marketplace shows live dot and listing count', (tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.textContaining('live'), findsWidgets);
  });

  testWidgets('13. filter chips — All, Low risk, High yield, Closing soon all present', (tester) async {
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Low risk'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'High yield'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Closing soon'), findsOneWidget);
  });

  testWidgets('14. Low risk filter chip is tappable without crash', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Low risk'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Marketplace'), findsWidgets);
  });

  testWidgets('15. notifications icon opens notifications page', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('16. bottom nav: Watchlist tab', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Watchlist'), findsWidgets);
  });

  testWidgets('17. bottom nav: Positions tab', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(find.text('My positions'), findsOneWidget);
  });

  testWidgets('18. Positions: As borrower tab shows no-listings empty state', (tester) async {
    await tester.pumpAndSettle();
    expect(find.text('No active listings'), findsWidgets);
  });

  testWidgets('19. Positions: As lender tab shows no-bids empty state', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text('As lender'));
    await tester.pumpAndSettle();
    expect(find.text('No active bids'), findsWidgets);
  });

  testWidgets('20. Positions: Contracts tab shows empty state', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contracts'));
    await tester.pumpAndSettle();
    expect(find.text('No contracts'), findsWidgets);
  });

  testWidgets('21. bottom nav: Account tab', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Subscription'), findsOneWidget);
  });

  testWidgets('22. account page has upgrade plan section', (tester) async {
    await tester.pumpAndSettle();
    expect(find.text('Upgrade plan'), findsWidgets);
  });

  testWidgets('23. sign-out returns to login screen', (tester) async {
    await tester.pumpAndSettle();
    await _signOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('24. borrower can sign in', (tester) async {
    await tester.pumpAndSettle();
    await _signIn(tester, 'borrower@nipanze.test', 'Test1234!');
    expect(find.text('Marketplace'), findsWidgets);
  });

  testWidgets('25. watchlist shows browse-marketplace action', (tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Browse marketplace'), findsOneWidget);
  });

  testWidgets('26. final sign-out', (tester) async {
    await tester.pumpAndSettle();
    await _signOut(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
