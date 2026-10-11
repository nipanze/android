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
        listedAt: now.subtract(const Duration(hours: 12)),
        expiresAt: now.add(const Duration(hours: 12)),
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
    final expiresAt = now.add(const Duration(hours: 13, minutes: 4));
    await tester.pumpWidget(
      buildIndicator(
        listedAt: now.subtract(const Duration(days: 1)),
        expiresAt: expiresAt,
      ),
    );

    await tester.tap(find.byTooltip('Show time remaining'));
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ListingExpiryIndicator)),
    )!;
    final remaining = expiresAt.difference(DateTime.now());
    final expected = remaining.inDays > 0
        ? l10n.listingRemainingDaysHours(
            remaining.inDays,
            remaining.inHours % 24,
          )
        : remaining.inHours > 0
            ? l10n.listingRemainingHoursMinutes(
                remaining.inHours,
                remaining.inMinutes % 60,
              )
            : remaining.inMinutes > 0
                ? l10n.listingRemainingMinutes(remaining.inMinutes)
                : l10n.listingRemainingSeconds(
                    remaining.inSeconds.clamp(1, 59),
                  );

    expect(find.text(expected), findsOneWidget);
    expect(tester.takeException(), isNull);

    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pump();
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
    await tester.pump();
    expect(find.text('Expired'), findsOneWidget);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .color,
      AppColors.danger,
    );

    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pump();
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

  testWidgets('future expiry outside the warning window stays hidden',
      (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      buildIndicator(
        listedAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 9)),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byTooltip('Show time remaining'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
