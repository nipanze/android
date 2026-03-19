// test/features/wallet/wallet_cubit_test.dart

// ignore_for_file: prefer_const_literals_to_create_immutables, directives_ordering

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:opencapital/features/wallet/data/wallet_repository.dart';
import 'package:opencapital/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:opencapital/shared/models/wallet_model.dart';
import 'package:opencapital/core/errors/app_errors.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

final _mockWallet = WalletModel(
  walletId: 'w1',
  userId: 'u1',
  lendableBalance: 3000000,
  lockedRepayment: 1000000,
  nonLendableBorrowed: 500000,
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  late MockWalletRepository mockRepo;

  setUp(() {
    mockRepo = MockWalletRepository();
  });

  group('WalletCubit — watchWallet', () {
    blocTest<WalletCubit, WalletState>(
      'emits [WalletLoading, WalletLoaded] on stream emit',
      build: () {
        when(() => mockRepo.watchWallet(any()))
            .thenAnswer((_) => Stream.value(_mockWallet));
        return WalletCubit(walletRepository: mockRepo);
      },
      act: (c) => c.watchWallet('u1'),
      expect: () => [
        const WalletLoading(),
        WalletLoaded(_mockWallet),
      ],
    );

    blocTest<WalletCubit, WalletState>(
      'emits [WalletLoading, WalletError] on stream error',
      build: () {
        when(() => mockRepo.watchWallet(any()))
            .thenAnswer((_) => Stream.error(
                  const ServerException('Wallet not found'),
                ));
        return WalletCubit(walletRepository: mockRepo);
      },
      act: (c) => c.watchWallet('u1'),
      expect: () => [
        const WalletLoading(),
        isA<WalletError>(),
      ],
    );
  });

  group('WalletCubit — topUp', () {
    blocTest<WalletCubit, WalletState>(
      'emits WalletTopUpSuccess on successful top-up',
      build: () {
        when(() => mockRepo.mockTopUp(userId: any(named: 'userId'), amount: any(named: 'amount')))
            .thenAnswer((_) async {});
        return WalletCubit(walletRepository: mockRepo);
      },
      act: (c) => c.topUp(userId: 'u1', amount: 500000),
      expect: () => [const WalletTopUpSuccess()],
    );

    blocTest<WalletCubit, WalletState>(
      'emits WalletError on failed top-up',
      build: () {
        when(() => mockRepo.mockTopUp(userId: any(named: 'userId'), amount: any(named: 'amount')))
            .thenThrow(const ValidationException('Amount must be greater than zero.'));
        return WalletCubit(walletRepository: mockRepo);
      },
      act: (c) => c.topUp(userId: 'u1', amount: 0),
      expect: () => [
        isA<WalletError>()
            .having((e) => e.message, 'message', contains('greater than zero')),
      ],
    );
  });

  group('WalletModel — three pool contract', () {
    test('lendableBalance is independent of locked and borrowed', () {
      expect(_mockWallet.lendableBalance, 3000000);
      expect(_mockWallet.lockedRepayment, 1000000);
      expect(_mockWallet.nonLendableBorrowed, 500000);
      expect(_mockWallet.totalBalance, 4500000);
    });

    test('fromJson maps all three columns correctly', () {
      final wallet = WalletModel.fromJson({
        'wallet_id': 'w1',
        'user_id': 'u1',
        'lendable_balance': 1000000,
        'locked_repayment': 200000,
        'non_lendable_borrowed': 50000,
        'updated_at': '2026-01-01T00:00:00.000Z',
      });
      expect(wallet.lendableBalance, 1000000);
      expect(wallet.lockedRepayment, 200000);
      expect(wallet.nonLendableBorrowed, 50000);
    });
  });
}
