// test/features/marketplace/lender_required_sheet_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/marketplace/presentation/widgets/lender_required_sheet.dart';

void main() {
  testWidgets('LenderRequiredSheet renders title, pricing, and action button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showLenderRequiredSheet(context),
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      ),
    );

    // Open the sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify Lender Required Sheet content
    expect(find.text('Lender required'), findsOneWidget);
    expect(find.text('UGX 19,900'), findsOneWidget);
    expect(find.text('Choose Lender'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(
      find.text('Everything in Free'),
      findsOneWidget,
    );
    expect(
      find.text('Make offers with full terms (rate, fee, schedule)'),
      findsOneWidget,
    );
  });
}
