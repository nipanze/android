import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/core/di/injection.dart';
import 'package:nipanze/features/account/presentation/pages/profile_page.dart';
import 'package:nipanze/features/provider/domain/entities/provider_capability.dart';
import 'package:nipanze/features/provider/domain/repositories/provider_repository_interface.dart';
import 'package:nipanze/features/provider/presentation/widgets/additional_verification_section.dart';
import 'package:nipanze/l10n/app_localizations.dart';

class _ProviderRepositoryMock extends Mock implements IProviderRepository {}

Widget _localizedApp(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

ProviderCapability _capability({
  required String slug,
  required String category,
  required String categoryName,
  required ProviderVerificationPolicy policy,
}) =>
    ProviderCapability(
      id: 'id-$slug',
      userId: 'user-1',
      capabilitySlug: slug,
      verificationLevel: ProviderVerificationLevel.selfDeclared,
      createdAt: DateTime(2026, 1, 1),
      categorySlug: category,
      categoryName: categoryName,
      verificationPolicy: policy,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('access chips use current gates and wrap at narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_localizedApp(
      const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: MarketplaceAccessSummary(
            isKycApproved: true,
            canBorrow: true,
            canLend: false,
            canOfferService: true,
          ),
        ),
      ),
    ));

    expect(find.text('3 of 5'), findsOneWidget);
    expect(find.textContaining('Loan Requests'), findsOneWidget);
    expect(find.textContaining('Forex Requests'), findsOneWidget);
    expect(find.textContaining('Need Requests'), findsOneWidget);
    expect(find.textContaining('Make Offers · Locked'), findsOneWidget);
    expect(find.textContaining('Offer a Service · Unlocked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Additional Verification lists required categories and opens it',
      (tester) async {
    final repository = _ProviderRepositoryMock();
    when(repository.capabilityProfilesEnabled)
        .thenAnswer((_) async => true);
    when(repository.getProviderCapabilities).thenAnswer((_) async => [
          _capability(
            slug: 'business_consulting',
            category: 'consulting',
            categoryName: 'Business Consulting',
            policy: ProviderVerificationPolicy.requiredProof,
          ),
          _capability(
            slug: 'consulting_audit',
            category: 'consulting',
            categoryName: 'Business Consulting',
            policy: ProviderVerificationPolicy.requiredProof,
          ),
          _capability(
            slug: 'open_service',
            category: 'open',
            categoryName: 'Open Service',
            policy: ProviderVerificationPolicy.open,
          ),
        ]);
    await getIt.reset();
    getIt.registerSingleton<IProviderRepository>(repository);
    addTearDown(getIt.reset);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(
              child: AdditionalVerificationSection(),
            ),
          ),
        ),
        GoRoute(
          path: '/account/services',
          builder: (_, state) => Scaffold(
            body: Center(child: Text('Opened ${state.extra}')),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Business Consulting'), findsOneWidget);
    expect(find.text('Open Service'), findsNothing);
    await tester.tap(find.text('Business Consulting'));
    await tester.pumpAndSettle();
    expect(find.text('Opened business_consulting'), findsOneWidget);
  });
}
