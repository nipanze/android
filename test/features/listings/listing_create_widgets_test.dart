// test/features/listings/listing_create_widgets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/listings/presentation/widgets/listing_create_widgets.dart';

void main() {
  testWidgets('ListingFormPanel renders title, subtitle, and children',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ListingFormPanel(
          title: 'The basics',
          subtitle: 'Tell lenders what this is for',
          children: [
            Text('Title field'),
            Text('Amount field'),
          ],
        ),
      ),
    ));

    // Panel titles are uppercased by design.
    expect(find.text('THE BASICS'), findsOneWidget);
    expect(find.text('Tell lenders what this is for'), findsOneWidget);
    expect(find.text('Title field'), findsOneWidget);
    expect(find.text('Amount field'), findsOneWidget);
  });

  testWidgets('MathRow renders label and formatted value with bold styling',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MathRow(
          label: 'Total payback',
          value: 'UGX 1,200,000',
          isBold: true,
        ),
      ),
    ));

    expect(find.text('Total payback'), findsOneWidget);
    expect(find.text('UGX 1,200,000'), findsOneWidget);
  });

  test('fmtAmount inserts comma thousands separators', () {
    expect(fmtAmount(0), '0');
    expect(fmtAmount(500), '500');
    expect(fmtAmount(50000), '50,000');
    expect(fmtAmount(1200000), '1,200,000');
  });
}
