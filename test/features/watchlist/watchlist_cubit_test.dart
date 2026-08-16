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
        when(() => mockRepo.getWatchedListings())
            .thenThrow(Exception('boom'));
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
        when(() => mockRepo.remove('req-1', forex: any(named: 'forex')))
            .thenAnswer((_) async {});
        return WatchlistCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.remove('req-1');
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
        when(() => mockRepo.add('req-2', forex: any(named: 'forex')))
            .thenAnswer((_) async {});
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
