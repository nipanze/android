// lib/features/positions/presentation/cubit/positions_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/positions_repository.dart';
import '../../domain/models/lender_bid.dart';

part 'positions_state.dart';

@injectable
class PositionsCubit extends Cubit<PositionsState> {
  PositionsCubit(this._repository) : super(const PositionsInitial());

  final PositionsRepository _repository;
  StreamSubscription<List<LenderBid>>? _bidsSub;

  Future<void> load() async {
    emit(const PositionsLoading());
    try {
      final results = await Future.wait([
        _repository.getMyBids(),
        _repository.getMyContracts(),
        _repository.getPortfolioSummary(),
      ]);

      emit(PositionsLoaded(
        bids:      results[0] as List<LenderBid>,
        contracts: results[1] as List<Map<String, dynamic>>,
        portfolio: results[2] as Map<String, dynamic>?,
      ));

      _subscribeBidsRealtime();
    } catch (e) {
      emit(PositionsError(e.toString()));
    }
  }

  void _subscribeBidsRealtime() {
    _bidsSub?.cancel();
    _bidsSub = _repository.watchMyBids().listen(
      (bids) {
        if (!isClosed && state is PositionsLoaded) {
          final current = state as PositionsLoaded;
          emit(current.copyWith(bids: bids));
        }
      },
      onError: (_) {},
    );
  }

  Future<void> withdrawBid(String bidId) async {
    if (state is! PositionsLoaded) return;
    final current = state as PositionsLoaded;

    // Optimistic update
    final updated = current.bids
        .map((b) => b.bidId == bidId
            ? LenderBid(
                bidId: b.bidId, requestId: b.requestId,
                listingTitle: b.listingTitle, district: b.district,
                durationMonths: b.durationMonths, riskCategory: b.riskCategory,
                bidAmount: b.bidAmount, bidRate: b.bidRate,
                bidStatus: BidStatus.withdrawn, placedAt: b.placedAt)
            : b)
        .toList();
    emit(current.copyWith(bids: updated));

    try {
      await _repository.withdrawBid(bidId);
    } catch (e) {
      emit(current); // rollback
      emit(PositionsError(e.toString()));
    }
  }

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _bidsSub?.cancel();
    return super.close();
  }
}