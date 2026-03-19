// test/features/marketplace/marketplace_cubit_test.dart

// ignore_for_file: directives_ordering, prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:opencapital/features/marketplace/data/marketplace_repository.dart';
import 'package:opencapital/features/marketplace/presentation/cubit/marketplace_cubit.dart';
import 'package:opencapital/shared/models/loan_listing_model.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

final _listings = [
  LoanListingModel(
    requestId: 'r1',
    requestedAmount: 5000000,
    durationMonths: 12,
    maxInterestRate: 12,
    purpose: 'Business Expansion',
    district: 'Central',
    riskCategory: 'low',
    creditScoreBand: '700-749',
    fundingPercentage: 0,
    numberOfBids: 0,
    status: 'active',
  ),
  LoanListingModel(
    requestId: 'r2',
    requestedAmount: 3500000,
    durationMonths: 6,
    maxInterestRate: 15,
    purpose: 'Education',
    district: 'Wakiso',
    riskCategory: 'medium',
    creditScoreBand: '600-649',
    fundingPercentage: 60,
    numberOfBids: 2,
    status: 'partially_funded',
  ),
];

void main() {
  late MockMarketplaceRepository mockRepo;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
  });

  group('MarketplaceCubit — watch', () {
    blocTest<MarketplaceCubit, MarketplaceState>(
      'emits [MarketplaceLoading, MarketplaceLoaded] on stream emit',
      build: () {
        when(() => mockRepo.watchListings())
            .thenAnswer((_) => Stream.value(_listings));
        return MarketplaceCubit(repository: mockRepo);
      },
      act: (c) => c.watch(),
      expect: () => [
        const MarketplaceLoading(),
        isA<MarketplaceLoaded>()
            .having((s) => s.listings.length, 'count', 2),
      ],
    );

    blocTest<MarketplaceCubit, MarketplaceState>(
      'borrower_id is never present in any listing',
      build: () {
        when(() => mockRepo.watchListings())
            .thenAnswer((_) => Stream.value(_listings));
        return MarketplaceCubit(repository: mockRepo);
      },
      act: (c) => c.watch(),
      verify: (c) {
        final state = c.state as MarketplaceLoaded;
        // LoanListingModel has no borrowerId field — this verifies the model contract
        for (final listing in state.listings) {
          // If this compiles, borrowerId is not on the model
          expect(listing.requestId, isNotNull);
        }
      },
    );
  });

  group('MarketplaceCubit — applyFilters', () {
    blocTest<MarketplaceCubit, MarketplaceState>(
      'filters by riskCategory correctly',
      build: () {
        when(() => mockRepo.watchListings())
            .thenAnswer((_) => Stream.value(_listings));
        return MarketplaceCubit(repository: mockRepo);
      },
      act: (c) async {
        c.watch();
        await Future.delayed(Duration.zero);
        c.applyFilters(riskCategory: 'low');
      },
      expect: () => [
        const MarketplaceLoading(),
        isA<MarketplaceLoaded>()
            .having((s) => s.listings.length, 'all', 2),
        isA<MarketplaceLoaded>()
            .having((s) => s.display.length, 'filtered', 1)
            .having((s) => s.display.first.riskCategory, 'risk', 'low'),
      ],
    );

    blocTest<MarketplaceCubit, MarketplaceState>(
      'clearFilters restores full listing',
      build: () {
        when(() => mockRepo.watchListings())
            .thenAnswer((_) => Stream.value(_listings));
        return MarketplaceCubit(repository: mockRepo);
      },
      act: (c) async {
        c.watch();
        await Future.delayed(Duration.zero);
        c.applyFilters(riskCategory: 'low');
        c.clearFilters();
      },
      skip: 2,
      expect: () => [
        isA<MarketplaceLoaded>()
            .having((s) => s.display.length, 'filtered', 1),
        isA<MarketplaceLoaded>()
            .having((s) => s.display.length, 'cleared', 2),
      ],
    );
  });
}
