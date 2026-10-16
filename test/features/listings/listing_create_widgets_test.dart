// test/features/listings/listing_create_widgets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/core/theme/app_theme.dart';
import 'package:nipanze/features/listings/presentation/widgets/listing_create_widgets.dart';
import 'package:nipanze/shared/widgets/form_suggestion_strip.dart';

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

  testWidgets('ListingFormPanel uses a layered, muted dark surface',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: ListingFormPanel(title: 'The basics', children: [Text('Field')]),
      ),
    ));

    final panel = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ListingFormPanel),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = panel.decoration! as BoxDecoration;

    expect(decoration.color, AppColors.bg2Dark);
    expect(decoration.border!.top.color, AppColors.borderDark);
  });

  testWidgets('FormSuggestionStrip applies a selected suggestion',
      (WidgetTester tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FormSuggestionStrip(
          label: 'Recent',
          suggestions: const ['Shop stock', 'Shop stock'],
          onSelected: (value) => selected = value,
        ),
      ),
    ));

    expect(find.text('Shop stock'), findsOneWidget);
    await tester.tap(find.text('Shop stock'));

    expect(selected, 'Shop stock');
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
