import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/kyc/domain/models/verification_requirement.dart';
import 'package:nipanze/l10n/app_localizations.dart';
import 'package:nipanze/shared/widgets/verification_gate_modal.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('VerificationGateModal', () {
    testWidgets('renders identity verification modal properly', (tester) async {
      const result = VerificationCheckResult(
        allowed: false,
        reason: 'identity_verification_required',
        missingRequirements: ['identity_verification_required'],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const VerificationGateModal(checkResult: result),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Identity verification required'), findsOneWidget);
      expect(
        find.text('Verify your identity before you can post or offer on Nipanze.'),
        findsOneWidget,
      );
      expect(find.text('Verify Identity'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    });

    testWidgets('renders provider verification modal properly', (tester) async {
      const result = VerificationCheckResult(
        allowed: false,
        reason: 'provider_verification_required',
        missingRequirements: ['provider_verification_required'],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const VerificationGateModal(checkResult: result),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Additional verification required'), findsOneWidget);
      expect(
        find.text(
            'This category requires provider verification before you can offer this service.'),
        findsOneWidget,
      );
      expect(find.text('Start Provider Verification'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('respects custom title and description', (tester) async {
      const result = VerificationCheckResult(
        allowed: false,
        reason: 'identity_verification_required',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const VerificationGateModal(
            checkResult: result,
            customTitle: 'Custom Title',
            customMessage: 'Custom description text',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom description text'), findsOneWidget);
    });
  });
}
