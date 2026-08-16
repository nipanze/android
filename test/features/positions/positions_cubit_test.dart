import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/features/positions/data/positions_repository.dart';
import 'package:nipanze/features/positions/domain/models/lender_offer.dart';
import 'package:nipanze/features/positions/presentation/cubit/positions_cubit.dart';

class MockPositionsRepository extends Mock implements PositionsRepository {}

LenderOffer _offer(String id, {OfferStatus status = OfferStatus.pending}) {
  return LenderOffer(
    offerId: id,
    requestId: 'req-1',
    listingTitle: 'Medical Expense',
    listingPurpose: 'Medical',
    district: 'Kampala',
    durationMonths: 12,
    requestedAmount: 1000000,
    offerAmount: 900000,
    interestRatePct: 15.0,
    lateFeePct: 3.0,
    repaymentFrequency: 'monthly',
    installmentAmount: 86250,
    status: status,
    offeredAt: DateTime.now(),
  );
}

void main() {
  late MockPositionsRepository mockRepo;

  setUp(() {
    mockRepo = MockPositionsRepository();
    when(() => mockRepo.watchMyOffers())
        .thenAnswer((_) => const Stream.empty());
  });

  group('PositionsCubit', () {
    blocTest<PositionsCubit, PositionsState>(
      'load emits Loading then Loaded with offers and activity',
      build: () {
        when(() => mockRepo.getMyOffers())
            .thenAnswer((_) async => [_offer('o-1')]);
        when(() => mockRepo.getMarketplaceActivity())
            .thenAnswer((_) async => {'active_requests': 2});
        return PositionsCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<PositionsLoading>(),
        isA<PositionsLoaded>()
            .having((s) => s.offers.length, 'offers count', 1)
            .having((s) => s.activity, 'activity', {'active_requests': 2}),
      ],
    );

    blocTest<PositionsCubit, PositionsState>(
      'load emits Error when repository throws',
      build: () {
        when(() => mockRepo.getMyOffers()).thenThrow(Exception('down'));
        when(() => mockRepo.getMarketplaceActivity())
            .thenAnswer((_) async => null);
        return PositionsCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<PositionsLoading>(),
        isA<PositionsError>(),
      ],
    );

    blocTest<PositionsCubit, PositionsState>(
      'withdrawOffer marks the offer withdrawn optimistically',
      build: () {
        when(() => mockRepo.getMyOffers())
            .thenAnswer((_) async => [_offer('o-1'), _offer('o-2')]);
        when(() => mockRepo.getMarketplaceActivity())
            .thenAnswer((_) async => null);
        when(() => mockRepo.withdrawOffer('o-1')).thenAnswer((_) async {});
        return PositionsCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.withdrawOffer('o-1');
      },
      skip: 2,
      expect: () => [
        isA<PositionsLoaded>()
            .having((s) => s.offers.first.status,
                'withdrawn status', OfferStatus.withdrawn)
            .having((s) => s.offers.last.status, 'other untouched',
                OfferStatus.pending),
      ],
    );

    blocTest<PositionsCubit, PositionsState>(
      'withdrawOffer rolls back and emits Error on failure',
      build: () {
        when(() => mockRepo.getMyOffers())
            .thenAnswer((_) async => [_offer('o-1')]);
        when(() => mockRepo.getMarketplaceActivity())
            .thenAnswer((_) async => null);
        when(() => mockRepo.withdrawOffer('o-1'))
            .thenThrow(Exception('failed'));
        return PositionsCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.withdrawOffer('o-1');
      },
      skip: 2,
      expect: () => [
        isA<PositionsLoaded>()
            .having((s) => s.offers.first.status, 'optimistic withdrawn',
                OfferStatus.withdrawn),
        isA<PositionsLoaded>()
            .having((s) => s.offers.first.status, 'rolled back',
                OfferStatus.pending),
        isA<PositionsError>(),
      ],
    );

    test('withdrawOffer is a no-op before load', () async {
      final cubit = PositionsCubit(mockRepo);
      await cubit.withdrawOffer('o-1');
      expect(cubit.state, isA<PositionsInitial>());
      await cubit.close();
    });
  });
}
