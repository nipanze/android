import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/core/di/injection.dart';
import 'package:nipanze/features/auth/data/auth_repository.dart';
import 'package:nipanze/features/auth/domain/models/nipanze_user.dart';
import 'package:nipanze/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nipanze/features/marketplace/data/marketplace_repository.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';
import 'package:nipanze/features/marketplace/domain/models/marketplace_item.dart';
import 'package:nipanze/features/marketplace/presentation/cubit/marketplace_cubit.dart';
import 'package:nipanze/features/marketplace/presentation/pages/marketplace_page.dart';
import 'package:nipanze/features/notifications/data/notification_repository.dart';
import 'package:nipanze/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:nipanze/features/provider/domain/repositories/provider_repository_interface.dart';
import 'package:nipanze/features/watchlist/data/watchlist_repository.dart';
import 'package:nipanze/features/watchlist/presentation/cubit/watchlist_cubit.dart';
import 'package:nipanze/l10n/app_localizations.dart';
import 'package:nipanze/shared/widgets/main_scaffold.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockProviderRepository extends Mock implements IProviderRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockMarketplaceRepository marketplaceRepository;
  late MockWatchlistRepository watchlistRepository;
  late MockNotificationRepository notificationRepository;
  late MockProviderRepository providerRepository;
  late AuthBloc authBloc;
  late NotificationCubit notificationCubit;

  final listing = MarketplaceItem.loan(
    LoanListing(
      requestId: 'request-1',
      title: 'Business loan',
      purpose: 'Stock',
      district: 'Kampala',
      country: 'UG',
      durationMonths: 12,
      requestedAmount: 1000000,
      incomeSource: 'Business',
      preferredRepaymentPlan: 'Monthly',
      repaymentAmountPerPeriod: 100000,
      repaymentTimeline: '12 months',
      status: 'active',
      listedAt: DateTime(2026),
      expiresAt: DateTime(2026, 12),
      numberOfOffers: 0,
    ),
  );

  setUp(() async {
    await getIt.reset();
    MarketplaceCubit.clearSessionCache();
    authRepository = MockAuthRepository();
    marketplaceRepository = MockMarketplaceRepository();
    watchlistRepository = MockWatchlistRepository();
    notificationRepository = MockNotificationRepository();
    providerRepository = MockProviderRepository();
    when(() => authRepository.authStateChanges)
        .thenAnswer((_) => const Stream.empty());
    when(() => authRepository.currentUser).thenReturn(null);
    when(() => authRepository.isEmailVerified).thenReturn(false);
    authBloc = AuthBloc(authRepository)
      ..emit(const AuthAuthenticated(
        user: NipanzeUser(id: 'user-1', email: 'test@example.com'),
      ));
    notificationCubit = NotificationCubit(notificationRepository);

    when(() => marketplaceRepository.currentViewerId).thenReturn('user-1');
    when(() => marketplaceRepository.getListings(
          district: any(named: 'district'),
          module: any(named: 'module'),
          country: any(named: 'country'),
        )).thenAnswer((_) async => []);
    when(() => marketplaceRepository.watchListings(
          module: any(named: 'module'),
          country: any(named: 'country'),
        )).thenAnswer((_) => const Stream.empty());
    when(() => marketplaceRepository.watchForexListings(
          module: any(named: 'module'),
          country: any(named: 'country'),
        )).thenAnswer((_) => const Stream.empty());
    when(() => watchlistRepository.getWatchedListings())
        .thenAnswer((_) async => []);
    when(() => watchlistRepository.watchWatchlistChanges())
        .thenAnswer((_) => const Stream.empty());
    when(() => notificationRepository.getNotifications())
        .thenAnswer((_) async => []);
    when(() => notificationRepository.watchNotifications())
        .thenAnswer((_) => const Stream.empty());
    when(() => providerRepository.getProviderCapabilities())
        .thenAnswer((_) async => []);

    getIt.registerFactory<MarketplaceCubit>(
      () => MarketplaceCubit(marketplaceRepository),
    );
    getIt.registerFactory<WatchlistCubit>(
      () => WatchlistCubit(watchlistRepository),
    );
    getIt.registerFactory<NotificationCubit>(() => notificationCubit);
    getIt.registerFactory<IProviderRepository>(() => providerRepository);
  });

  tearDown(() async {
    await authBloc.close();
    if (!notificationCubit.isClosed) await notificationCubit.close();
    await getIt.reset();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: BlocProvider<NotificationCubit>.value(
          value: notificationCubit,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MarketplacePage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('marketplace shell and empty feed render without layout errors',
      (tester) async {
    await pumpPage(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nipanze'), findsOneWidget);
    expect(find.text('For You'), findsOneWidget);
    expect(find.text('Loans'), findsOneWidget);
    expect(find.text('Forex'), findsOneWidget);
    expect(find.text('Needs'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.text('0 active listings'), findsOneWidget);
    expect(find.text('No listings found'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('0 active listings')).style?.fontWeight,
      FontWeight.w800,
    );

    final cubit = tester.element(find.text('Loans')).read<MarketplaceCubit>();
    for (final (label, module) in [
      ('Loans', MarketplaceModule.loan),
      ('Forex', MarketplaceModule.forex),
      ('Needs', MarketplaceModule.needs),
      ('For You', null),
    ]) {
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 200));
      expect((cubit.state as MarketplaceLoaded).moduleFilter, module);
      expect(find.text('0 active listings'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('marketplace listing cards render without layout errors',
      (tester) async {
    when(() => marketplaceRepository.getListings(
          district: any(named: 'district'),
          module: any(named: 'module'),
          country: any(named: 'country'),
        )).thenAnswer((_) async => [listing]);

    await pumpPage(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Business loan'), findsOneWidget);
    expect(find.text('1 active listing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marketplace renders in its production navigation shell',
      (tester) async {
    when(() => marketplaceRepository.getListings(
          district: any(named: 'district'),
          module: any(named: 'module'),
          country: any(named: 'country'),
        )).thenAnswer((_) async => [listing]);

    final router = GoRouter(
      initialLocation: '/marketplace',
      routes: [
        ShellRoute(
          builder: (_, __, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: '/marketplace',
              builder: (_, __) => const MarketplacePage(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ListView)).height, greaterThan(0));
    expect(find.text('Business loan'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
}
