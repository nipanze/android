import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/core/theme/app_theme.dart';
import 'package:nipanze/features/marketplace/presentation/widgets/listing_expiry_indicator.dart';
import 'package:nipanze/l10n/app_localizations.dart';

void main() {
  Widget buildIndicator({
    required DateTime listedAt,
    required DateTime? expiresAt,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListingExpiryIndicator(
          listedAt: listedAt,
          expiresAt: expiresAt,
        ),
      ),
    );
  }

  testWidgets('ring represents the remaining listing lifetime and updates',
      (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      buildIndicator(
        listedAt: now.subtract(const Duration(days: 10)),
        expiresAt: now.add(const Duration(days: 10)),
      ),
    );

    final ringFinder = find.byType(CircularProgressIndicator);
    final initialValue =
        tester.widget<CircularProgressIndicator>(ringFinder).value!;
    expect(initialValue, closeTo(0.5, 0.001));

    await tester.pump(const Duration(seconds: 3));
    final updatedValue =
        tester.widget<CircularProgressIndicator>(ringFinder).value!;
    expect(updatedValue, lessThan(initialValue));
  });

  testWidgets('tapping the clock shows an accurate live countdown',
      (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      buildIndicator(
        listedAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 13, hours: 4)),
      ),
    );

    await tester.tap(find.byTooltip('Show time remaining'));
    await tester.pumpAndSettle();

    expect(find.text('13 days, 4 hours remaining'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expired listings show Expired in the countdown sheet',
      (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      buildIndicator(
        listedAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.subtract(const Duration(seconds: 1)),
      ),
    );

    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      0,
    );
    await tester.tap(find.byTooltip('Show time remaining'));
    await tester.pumpAndSettle();
    expect(find.text('Expired'), findsOneWidget);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .color,
      AppColors.danger,
    );
  });

  testWidgets('missing expiry renders no misleading countdown', (tester) async {
    await tester.pumpWidget(
      buildIndicator(
        listedAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: null,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byTooltip('Show time remaining'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
