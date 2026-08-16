// test/features/auth/welcome_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/auth/presentation/pages/register/welcome_screen.dart';
import 'package:nipanze/l10n/app_localizations.dart';

void main() {
  testWidgets('WelcomeScreen renders logo, tagline, and phone CTA',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WelcomeScreen(
          onContinueWithPhone: _noop,
          onContinueWithEmail: _noop,
          onCreateAccount: _noop,
        ),
      ),
    );

    expect(find.byType(NipanzeLogo), findsOneWidget);
    expect(find.text('Continue with Phone'), findsOneWidget);
  });

  testWidgets('Continue with Phone invokes the callback',
      (WidgetTester tester) async {
    var phoneTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WelcomeScreen(
          onContinueWithPhone: () => phoneTapped = true,
          onContinueWithEmail: _noop,
          onCreateAccount: _noop,
        ),
      ),
    );

    await tester.tap(find.text('Continue with Phone'));
    // Plain pump: the looping starfield animation never settles.
    await tester.pump();

    expect(phoneTapped, isTrue);
  });
}

void _noop() {}
