import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nipanze/l10n/app_localizations.dart';
import 'package:nipanze/shared/widgets/post_choice_sheet.dart';

void main() {
  late GoRouter router;

  Future<void> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    router = GoRouter(
      initialLocation: '/activity',
      routes: [
        GoRoute(
          path: '/activity',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showPostChoiceSheet(context),
                  child: const Text('Open chooser'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/listings/create',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Loan creation')),
          ),
        ),
        GoRoute(
          path: '/forex/create',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Forex creation')),
          ),
        ),
        GoRoute(
          path: '/needs/create',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Need creation')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    router.dispose();
  });

  testWidgets('chooser routes the full module option tiles', (tester) async {
    await pumpApp(tester);

    for (final (option, destination) in [
      ('Create a loan request', 'Loan creation'),
      ('Create a currency exchange request', 'Forex creation'),
      ('Create a Need', 'Need creation'),
    ]) {
      router.go('/activity');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open chooser'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option));
      await tester.pumpAndSettle();

      expect(find.text(destination), findsOneWidget);
    }
  });

  testWidgets('back dismisses chooser without navigating', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Open chooser'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/activity');
    expect(find.text('Open chooser'), findsOneWidget);
  });

  testWidgets('chooser labels follow the selected locale', (tester) async {
    await pumpApp(tester, locale: const Locale('fr'));
    await tester.tap(find.text('Open chooser'));
    await tester.pumpAndSettle();

    expect(find.text('Que souhaitez-vous publier ?'), findsOneWidget);
    expect(find.text('Prêt'), findsOneWidget);
    expect(find.text('Créer une demande de prêt'), findsOneWidget);
  });
}
