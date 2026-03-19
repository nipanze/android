// ignore_for_file: unused_import, directives_ordering

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:opencapital/core/errors/app_errors.dart';
import 'package:opencapital/features/wallet/data/wallet_repository.dart';
import 'package:opencapital/shared/models/wallet_model.dart';

import '../../../core/errors/app_errors.dart';

// States
abstract class WalletState extends Equatable {
  const WalletState();
  @override List<Object?> get props => [];
}
class WalletInitial extends WalletState { const WalletInitial(); }
class WalletLoading extends WalletState { const WalletLoading(); }
class WalletLoaded extends WalletState {
  const WalletLoaded(this.wallet, {this.transactions = const []});
  final WalletModel wallet;
  final List<Map<String, dynamic>> transactions;
  @override List<Object?> get props => [wallet, transactions];
}
class WalletTopUpSuccess extends WalletState { const WalletTopUpSuccess(); }
class WalletError extends WalletState {
  const WalletError(this.message);
  final String message;
  @override List<Object?> get props => [message];
}

// Cubit
class WalletCubit extends Cubit<WalletState> {
  WalletCubit({required this.walletRepository}) : super(const WalletInitial());

  final WalletRepository walletRepository;
  StreamSubscription<WalletModel>? _sub;

  void watchWallet(String userId) {
    emit(const WalletLoading());
    _sub?.cancel();
    _sub = walletRepository.watchWallet(userId).listen(
      (wallet) => emit(WalletLoaded(wallet)),
      onError: (e) => emit(WalletError(parseSupabaseError(e).message)),
    );
  }

  Future<void> loadTransactions(String userId) async {
    final current = state;
    if (current is! WalletLoaded) return;
    try {
      final txns = await walletRepository.getTransactionHistory(userId);
      emit(WalletLoaded(current.wallet, transactions: txns));
    } catch (e) {
      // Non-fatal — wallet still shows, transactions just empty
    }
  }

  Future<void> topUp({required String userId, required double amount}) async {
    try {
      await walletRepository.mockTopUp(userId: userId, amount: amount);
      emit(const WalletTopUpSuccess());
    } on AppException catch (e) {
      emit(WalletError(e.message));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
