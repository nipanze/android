import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';
import 'package:nipanze/features/marketplace/domain/models/marketplace_item.dart';
import 'package:nipanze/features/watchlist/data/watchlist_repository.dart';
import 'package:nipanze/features/watchlist/presentation/cubit/watchlist_cubit.dart';

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

MarketplaceItem _loanItem(String id) {
  return MarketplaceItem.loan(LoanListing(
    requestId: id,
    title: 'Listing $id',
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
    listedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(days: 5)),
    numberOfOffers: 0,
  ));
}

MarketplaceItem _needsItem(String id) {
  return MarketplaceItem.needs(NeedsListing(
    requestId: id,
    title: 'Need $id',
    specification: 'Specification',
    category: 'Specialized Products',
    budget: 100000,
    currency: 'UGX',
    location: 'Kampala',
    urgency: 'Flexible',
    listedAt: DateTime.now(),
  ));
}

void main() {
  late MockWatchlistRepository mockRepo;

  setUp(() {
    mockRepo = MockWatchlistRepository();
    when(() => mockRepo.watchWatchedListings())
        .thenAnswer((_) => const Stream.empty());
  });

  group('WatchlistCubit', () {
    blocTest<WatchlistCubit, WatchlistState>(
      'initial state is WatchlistInitial',
      build: () => WatchlistCubit(mockRepo),
      verify: (cubit) => expect(cubit.state, isA<WatchlistInitial>()),
    );

    blocTest<WatchlistCubit, WatchlistState>(
      'load emits Loading then Loaded with listings',
      build: () {
        when(() => mockRepo.getWatchedListings())
            .thenAnswer((_) async => [_loanItem('req-1')]);
        return WatchlistCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<WatchlistLoading>(),
        isA<WatchlistLoaded>()
            .having((s) => s.listings.length, 'listings count', 1),
      ],
    );

    blocTest<WatchlistCubit, WatchlistState>(
      'load emits Error when repository throws',
      build: () {
        when(() => mockRepo.getWatchedListings()).thenThrow(Exception('boom'));
        return WatchlistCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<WatchlistLoading>(),
        isA<WatchlistError>(),
      ],
    );

    blocTest<WatchlistCubit, WatchlistState>(
      'remove drops the listing from loaded state',
      build: () {
        when(() => mockRepo.getWatchedListings()).thenAnswer((_) async => [
              _loanItem('req-1'),
              _loanItem('req-2'),
            ]);
        when(() => mockRepo.remove(
              'req-1',
              module: MarketplaceModule.loan,
            )).thenAnswer((_) async {});
        return WatchlistCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.remove(_loanItem('req-1'));
      },
      skip: 2,
      expect: () => [
        isA<WatchlistLoaded>()
            .having((s) => s.listings.length, 'listings count', 1)
            .having((s) => s.listings.first.requestId, 'remaining', 'req-2'),
      ],
    );

    blocTest<WatchlistCubit, WatchlistState>(
      'add appends the listing to loaded state',
      build: () {
        when(() => mockRepo.getWatchedListings())
            .thenAnswer((_) async => [_loanItem('req-1')]);
        when(() => mockRepo.add(
              'req-2',
              module: MarketplaceModule.loan,
            )).thenAnswer((_) async {});
        return WatchlistCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.add(_loanItem('req-2'));
      },
      skip: 2,
      expect: () => [
        isA<WatchlistLoaded>()
            .having((s) => s.listings.length, 'listings count', 2),
      ],
    );

    blocTest<WatchlistCubit, WatchlistState>(
      'undo restores a removed listing at its original position',
      build: () {
        when(() => mockRepo.getWatchedListings()).thenAnswer((_) async => [
              _loanItem('req-1'),
              _loanItem('req-2'),
              _loanItem('req-3'),
            ]);
        when(() => mockRepo.remove(
              'req-2',
              module: MarketplaceModule.loan,
            )).thenAnswer((_) async {});
        when(() => mockRepo.add(
              'req-2',
              module: MarketplaceModule.loan,
            )).thenAnswer((_) async {});
        return WatchlistCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        final listing = _loanItem('req-2');
        await cubit.remove(listing);
        await cubit.undoRemove(listing, index: 1);
      },
      skip: 2,
      expect: () => [
        isA<WatchlistLoaded>().having(
          (state) =>
              state.listings.map((listing) => listing.requestId).toList(),
          'listings after removal',
          ['req-1', 'req-3'],
        ),
        isA<WatchlistLoaded>().having(
          (state) =>
              state.listings.map((listing) => listing.requestId).toList(),
          'listings after undo',
          ['req-1', 'req-2', 'req-3'],
        ),
      ],
    );

    blocTest<WatchlistCubit, WatchlistState>(
      'removing a Needs listing does not remove another module with the same id',
      build: () {
        when(() => mockRepo.getWatchedListings()).thenAnswer((_) async => [
              _loanItem('shared-id'),
              _needsItem('shared-id'),
            ]);
        when(() => mockRepo.remove(
              'shared-id',
              module: MarketplaceModule.needs,
            )).thenAnswer((_) async {});
        return WatchlistCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.remove(_needsItem('shared-id'));
      },
      skip: 2,
      expect: () => [
        isA<WatchlistLoaded>()
            .having((state) => state.listings.length, 'remaining count', 1)
            .having(
              (state) => state.listings.single.module,
              'remaining module',
              MarketplaceModule.loan,
            ),
      ],
    );

    test('isWatched checks loaded state', () async {
      when(() => mockRepo.getWatchedListings())
          .thenAnswer((_) async => [_loanItem('req-1')]);
      final cubit = WatchlistCubit(mockRepo);

      await cubit.load();
      expect(cubit.isWatched('req-1'), isTrue);
      expect(cubit.isWatched('req-2'), isFalse);

      await cubit.close();
    });
  });
}
