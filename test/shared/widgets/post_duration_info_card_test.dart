// test/shared/widgets/post_duration_info_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/l10n/app_localizations.dart';
import 'package:nipanze/shared/widgets/post_duration_info_card.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required int durationDays,
    bool compact = false,
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: PostDurationInfoCard(
              durationDays: durationDays,
              compact: compact,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PostDurationInfoCard', () {
    group('English — standard durations', () {
      testWidgets('shows 30 days for Loans', (tester) async {
        await pumpCard(tester, durationDays: 30);
        expect(find.textContaining('30'), findsWidgets);
        expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      });

      testWidgets('shows 7 days for Forex', (tester) async {
        await pumpCard(tester, durationDays: 7);
        expect(find.textContaining('7'), findsWidgets);
        expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      });

      testWidgets('shows 14 days for Needs categories', (tester) async {
        await pumpCard(tester, durationDays: 14);
        expect(find.textContaining('14'), findsWidgets);
      });

      testWidgets('shows expiry subtitle in non-compact mode', (tester) async {
        await pumpCard(tester, durationDays: 30);
        // subtitle text should appear
        expect(
          find.textContaining('expire'),
          findsWidgets,
        );
      });

      testWidgets('hides expiry subtitle in compact mode', (tester) async {
        await pumpCard(tester, durationDays: 30, compact: true);
        expect(
          find.textContaining('expire'),
          findsNothing,
        );
      });
    });

    group('Dark mode', () {
      testWidgets('renders without overflow in dark mode', (tester) async {
        await pumpCard(
          tester,
          durationDays: 30,
          themeMode: ThemeMode.dark,
        );
        expect(find.byType(PostDurationInfoCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Locales', () {
      testWidgets('renders in Swahili (sw)', (tester) async {
        await pumpCard(
          tester,
          durationDays: 30,
          locale: const Locale('sw'),
        );
        expect(find.byType(PostDurationInfoCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders in French (fr)', (tester) async {
        await pumpCard(
          tester,
          durationDays: 7,
          locale: const Locale('fr'),
        );
        expect(find.byType(PostDurationInfoCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders in Kinyarwanda (rw)', (tester) async {
        await pumpCard(
          tester,
          durationDays: 14,
          locale: const Locale('rw'),
        );
        expect(find.byType(PostDurationInfoCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders in Arabic (ar) without overflow', (tester) async {
        await pumpCard(
          tester,
          durationDays: 30,
          locale: const Locale('ar'),
        );
        expect(find.byType(PostDurationInfoCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Edge cases', () {
      testWidgets('handles 1 day duration', (tester) async {
        await pumpCard(tester, durationDays: 1);
        expect(find.textContaining('1'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles large duration (365 days)', (tester) async {
        await pumpCard(tester, durationDays: 365);
        expect(find.textContaining('365'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

