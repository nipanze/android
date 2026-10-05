import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/core/di/injection.dart';
import 'package:nipanze/features/auth/domain/models/nipanze_user.dart';
import 'package:nipanze/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';
import 'package:nipanze/features/marketplace/domain/models/marketplace_item.dart';
import 'package:nipanze/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:nipanze/features/watchlist/data/watchlist_repository.dart';
import 'package:nipanze/features/watchlist/presentation/cubit/watchlist_cubit.dart';
import 'package:nipanze/features/watchlist/presentation/pages/watchlist_page.dart';
import 'package:nipanze/l10n/app_localizations.dart';
import 'package:nipanze/shared/widgets/main_scaffold.dart';

class MockWatchlistRepository extends Mock implements WatchlistRepository {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockNotificationCubit extends Mock implements NotificationCubit {}

void main() {
  late MockWatchlistRepository mockWatchlistRepo;
  late MockAuthBloc mockAuthBloc;
  late MockNotificationCubit mockNotificationCubit;

  setUpAll(() {
    registerFallbackValue(const AuthStarted());
  });

  setUp(() {
    mockWatchlistRepo = MockWatchlistRepository();
    mockAuthBloc = MockAuthBloc();
    mockNotificationCubit = MockNotificationCubit();

    when(() => mockWatchlistRepo.watchWatchlistChanges())
        .thenAnswer((_) => const Stream.empty());
    when(() => mockWatchlistRepo.getWatchedListings())
        .thenAnswer((_) async => []);

    when(() => mockAuthBloc.state).thenReturn(
      const AuthAuthenticated(
        user: NipanzeUser(
          id: 'user-1',
          email: 'test@nipanze.test',
          phone: '+256700000000',
          subscriptionPlan: SubscriptionPlan.lender,
          kycStatus: KycStatus.approved,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockNotificationCubit.state).thenReturn(const NotificationInitial());
    when(() => mockNotificationCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockNotificationCubit.load()).thenAnswer((_) async {});

    if (getIt.isRegistered<WatchlistCubit>()) {
      getIt.unregister<WatchlistCubit>();
    }
    if (getIt.isRegistered<WatchlistRepository>()) {
      getIt.unregister<WatchlistRepository>();
    }
    if (getIt.isRegistered<NotificationCubit>()) {
      getIt.unregister<NotificationCubit>();
    }

    getIt.registerLazySingleton<WatchlistRepository>(() => mockWatchlistRepo);
    getIt.registerFactory<WatchlistCubit>(() => WatchlistCubit(mockWatchlistRepo));
    getIt.registerLazySingleton<NotificationCubit>(() => mockNotificationCubit);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('WatchlistPage inside MainScaffold renders correctly without layout or ParentData errors', (tester) async {
    when(() => mockWatchlistRepo.getWatchedListings()).thenAnswer((_) async => [
      MarketplaceItem.loan(LoanListing(
        requestId: 'req-1',
        title: 'Business Expansion Loan',
        purpose: 'Inventory',
        district: 'Kampala',
        country: 'UG',
        durationMonths: 6,
        requestedAmount: 5000000,
        incomeSource: 'Retail',
        preferredRepaymentPlan: 'Monthly',
        repaymentAmountPerPeriod: 900000,
        repaymentTimeline: '6 months',
        status: 'active',
        listedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        numberOfOffers: 2,
      )),
    ]);

    await tester.pumpWidget(
      buildTestableWidget(
        const MainScaffold(
          child: WatchlistPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Watchlist'), findsWidgets);
    expect(find.text('Business Expansion Loan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
