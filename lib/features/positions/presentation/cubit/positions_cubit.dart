// lib/features/positions/presentation/cubit/positions_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/positions_repository.dart';
import '../../domain/models/lender_offer.dart';

part 'positions_state.dart';

@injectable
class PositionsCubit extends Cubit<PositionsState> {
  PositionsCubit(this._repository) : super(const PositionsInitial());

  final PositionsRepository _repository;
  StreamSubscription<List<LenderOffer>>? _offersSub;

  Future<void> load() async {
    emit(const PositionsLoading());
    try {
      final results = await Future.wait([
        _repository.getMyOffers(),
        _repository.getMarketplaceActivity(),
      ]);

      emit(PositionsLoaded(
        offers: results[0] as List<LenderOffer>,
        activity: results[1] as Map<String, dynamic>?,
      ));

      _subscribeOffersRealtime();
    } catch (e) {
      emit(PositionsError(e.toString()));
    }
  }

  void _subscribeOffersRealtime() {
    _offersSub?.cancel();
    _offersSub = _repository.watchMyOffers().listen(
      (offers) {
        if (!isClosed && state is PositionsLoaded) {
          final current = state as PositionsLoaded;
          emit(current.copyWith(offers: offers));
        }
      },
      onError: (_) {},
    );
  }

  Future<void> withdrawOffer(String offerId) async {
    if (state is! PositionsLoaded) return;
    final current = state as PositionsLoaded;

    // Optimistic local update
    final updated = current.offers
        .map((o) => o.offerId == offerId
            ? o.copyWith(status: OfferStatus.withdrawn)
            : o)
        .toList();
    emit(current.copyWith(offers: updated));

    try {
      await _repository.withdrawOffer(offerId);
    } catch (e) {
      emit(current); // rollback
      emit(PositionsError(e.toString()));
    }
  }

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _offersSub?.cancel();
    return super.close();
  }
}
