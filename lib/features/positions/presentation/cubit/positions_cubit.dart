// lib/features/positions/presentation/cubit/positions_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/offline_service.dart';
import '../../data/positions_repository.dart';
import '../../domain/models/lender_offer.dart';

part 'positions_state.dart';

@injectable
class PositionsCubit extends Cubit<PositionsState> {
  PositionsCubit(this._repository) : super(const PositionsInitial()) {
    _connectionSubscription = OfflineService().onReconnected.listen((_) {
      if (!isClosed) unawaited(refresh());
    });
  }

  final PositionsRepository _repository;
  late final StreamSubscription<void> _connectionSubscription;
  StreamSubscription<List<LenderOffer>>? _offersSub;

  Future<void> load() async {
    if (state is! PositionsLoaded) emit(const PositionsLoading());
    try {
      final results = await Future.wait([
        _repository.getMyOffers(),
        _repository.getMarketplaceActivity(),
        _repository.getMyDeals(),
      ]);

      emit(PositionsLoaded(
        offers: results[0] as List<LenderOffer>,
        activity: results[1] as Map<String, dynamic>?,
        deals: results[2] as List<dynamic>,
      ));

      _subscribeOffersRealtime();
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      if (state is! PositionsLoaded) {
        emit(PositionsError(userFacingErrorMessage(e)));
      }
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

    final optimisticOffers = current.offers
        .map((offer) => offer.offerId == offerId
            ? offer.copyWith(status: OfferStatus.withdrawn)
            : offer)
        .toList();

    emit(current.copyWith(offers: optimisticOffers));

    try {
      await _repository.withdrawOffer(offerId);
    } catch (e) {
      emit(current.copyWith(offers: current.offers));
      OfflineService().reportRequestFailure(e);
      if (parseSupabaseError(e) is NetworkException) return;
      emit(PositionsError(userFacingErrorMessage(e)));
    }
  }

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _offersSub?.cancel();
    _connectionSubscription.cancel();
    return super.close();
  }
}
