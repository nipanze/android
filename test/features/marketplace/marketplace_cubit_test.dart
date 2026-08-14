// test/features/marketplace/marketplace_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/features/marketplace/data/marketplace_repository.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';
import 'package:nipanze/features/marketplace/domain/models/marketplace_item.dart';
import 'package:nipanze/features/marketplace/presentation/cubit/marketplace_cubit.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

void main() {
  late MockMarketplaceRepository mockRepo;

  final testListings = [
    MarketplaceItem.loan(LoanListing(
      requestId: 'req-1',
      title: 'Medical Expense',
      purpose: 'Medical',
      district: 'Kampala',
      country: 'UG',
      durationMonths: 12,
      requestedAmount: 1000000,
      incomeSource: 'Salaried',
      preferredRepaymentPlan: 'Monthly',
      repaymentAmountPerPeriod: 100000,
      repaymentTimeline: '12 months',
      status: 'active',
      listedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      numberOfOffers: 0,
    )),
    MarketplaceItem.loan(LoanListing(
      requestId: 'req-2',
      title: 'Business Growth',
      purpose: 'Business',
      district: 'Wakiso',
      country: 'UG',
      durationMonths: 6,
      requestedAmount: 500000,
      incomeSource: 'Business',
      preferredRepaymentPlan: 'Weekly',
      repaymentAmountPerPeriod: 100000,
      repaymentTimeline: '6 months',
      status: 'active',
      listedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 5)),
      numberOfOffers: 2,
    )),
  ];

  setUp(() {
    mockRepo = MockMarketplaceRepository();
    when(() => mockRepo.currentViewerId).thenReturn('viewer-default');
    when(() => mockRepo.watchListings(module: any(named: 'module')))
        .thenAnswer((_) => const Stream.empty());
    when(() => mockRepo.watchForexListings(module: any(named: 'module')))
        .thenAnswer((_) => const Stream.empty());
  });

  group('MarketplaceCubit', () {
    blocTest<MarketplaceCubit, MarketplaceState>(
      'initial state is MarketplaceInitial',
      build: () => MarketplaceCubit(mockRepo),
      verify: (cubit) {
        expect(cubit.state, isA<MarketplaceInitial>());
      },
    );

    blocTest<MarketplaceCubit, MarketplaceState>(
      'load emits Loading then Loaded with cached listings',
      build: () {
        when(() => mockRepo.getListings(
              district: any(named: 'district'),
              module: any(named: 'module'),
            )).thenAnswer((_) async => testListings);
        return MarketplaceCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<MarketplaceLoading>(),
        isA<MarketplaceLoaded>()
            .having((s) => s.listings.length, 'listings count', 2),
      ],
    );

    blocTest<MarketplaceCubit, MarketplaceState>(
      'applyProFilters emits proFilterActive then Loaded with intersected listings matching RPC results',
      build: () {
        when(() => mockRepo.getListings(
              district: any(named: 'district'),
              module: any(named: 'module'),
            )).thenAnswer((_) async => testListings);
        when(() => mockRepo.getProFilteredRequestIds(
              employmentTypes: any(named: 'employmentTypes'),
              incomeBrackets: any(named: 'incomeBrackets'),
              suggestedTermsOnly: any(named: 'suggestedTermsOnly'),
              verifiedOnly: any(named: 'verifiedOnly'),
            )).thenAnswer((_) async => {'req-2'});
        return MarketplaceCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.applyProFilters(const ProFilterCriteria(
          employmentTypes: ['self_employed'],
        ));
      },
      skip: 2, // skip initial load states
      expect: () => [
        isA<MarketplaceLoaded>()
            .having((s) => s.proFilterActive, 'filtering active', true)
            .having((s) => s.proFilterCriteria.employmentTypes,
                'filter criteria', ['self_employed']),
        isA<MarketplaceLoaded>()
            .having((s) => s.proFilterActive, 'filtering done', false)
            .having((s) => s.listings.length, 'listings count', 1)
            .having(
                (s) => s.listings.first.requestId, 'matching request', 'req-2'),
      ],
    );

    blocTest<MarketplaceCubit, MarketplaceState>(
      'clearProFilters restores all cached listings',
      build: () {
        when(() => mockRepo.getListings(
              district: any(named: 'district'),
              module: any(named: 'module'),
            )).thenAnswer((_) async => testListings);
        when(() => mockRepo.getProFilteredRequestIds(
              employmentTypes: any(named: 'employmentTypes'),
              incomeBrackets: any(named: 'incomeBrackets'),
              suggestedTermsOnly: any(named: 'suggestedTermsOnly'),
              verifiedOnly: any(named: 'verifiedOnly'),
            )).thenAnswer((_) async => {'req-2'});
        return MarketplaceCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.applyProFilters(const ProFilterCriteria(
          employmentTypes: ['self_employed'],
        ));
        cubit.clearProFilters();
      },
      skip: 4, // skip load & apply filter states
      expect: () => [
        isA<MarketplaceLoaded>()
            .having((s) => s.listings.length, 'restored full count', 2)
            .having(
                (s) => s.proFilterCriteria.isActive, 'filters active', false),
      ],
    );

    test('personalizes listing order for different viewers', () async {
      final now = DateTime.utc(2026, 1, 1, 12);
      final sameSignalListings = ['req-a', 'req-b', 'req-c', 'req-d', 'req-e']
          .map((id) => MarketplaceItem.loan(LoanListing(
                requestId: id,
                title: 'Working Capital',
                purpose: 'Business',
                district: 'Kampala',
                country: 'UG',
                durationMonths: 6,
                requestedAmount: 500000,
                incomeSource: 'Business',
                preferredRepaymentPlan: 'Monthly',
                repaymentAmountPerPeriod: 90000,
                repaymentTimeline: '6 months',
                status: 'active',
                listedAt: now,
                expiresAt: now.add(const Duration(days: 5)),
                numberOfOffers: 1,
              )))
          .toList();

      Future<List<String>> loadOrderFor(String viewerId) async {
        final repo = MockMarketplaceRepository();
        when(() => repo.currentViewerId).thenReturn(viewerId);
        when(() => repo.getListings(
              district: any(named: 'district'),
              module: any(named: 'module'),
            )).thenAnswer((_) async => sameSignalListings);
        when(() => repo.watchListings(module: any(named: 'module')))
            .thenAnswer((_) => const Stream.empty());
        when(() => repo.watchForexListings(module: any(named: 'module')))
            .thenAnswer((_) => const Stream.empty());

        final cubit = MarketplaceCubit(repo);
        await cubit.load(module: MarketplaceModule.loan);
        final loaded = cubit.state as MarketplaceLoaded;
        await cubit.close();
        return loaded.listings.map((listing) => listing.requestId).toList();
      }

      final firstViewerOrder = await loadOrderFor('viewer-one');
      final secondViewerOrder = await loadOrderFor('viewer-two');

      expect(firstViewerOrder, isNot(secondViewerOrder));
      expect(firstViewerOrder.toSet(),
          sameSignalListings.map((l) => l.requestId).toSet());
      expect(secondViewerOrder.toSet(),
          sameSignalListings.map((l) => l.requestId).toSet());
    });
  });
}
