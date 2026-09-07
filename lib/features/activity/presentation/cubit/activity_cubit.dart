// lib/features/activity/presentation/cubit/activity_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/activity_repository.dart';
import '../../domain/models/lender_offer.dart';

part 'activity_state.dart';

@injectable
class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit(this._repository) : super(const ActivityInitial());

  final ActivityRepository _repository;
  StreamSubscription<List<LenderOffer>>? _offersSub;
  final Set<String> _hiddenOfferIds = {};

  Future<void> load() async {
    emit(const ActivityLoading());
    try {
      final results = await Future.wait([
        _repository.getMyOffers(),
        _repository.getMarketplaceActivity(),
        _repository.getMyDeals(),
      ]);

      emit(ActivityLoaded(
        offers: _visibleOffers(results[0] as List<LenderOffer>),
        activity: results[1] as Map<String, dynamic>?,
        deals: results[2] as List<dynamic>,
      ));

      _subscribeOffersRealtime();
    } catch (e) {
      emit(ActivityError(userFacingErrorMessage(e)));
    }
  }

  void _subscribeOffersRealtime() {
    _offersSub?.cancel();
    _offersSub = _repository.watchMyOffers().listen(
      (offers) {
        if (!isClosed && state is ActivityLoaded) {
          final current = state as ActivityLoaded;
          emit(current.copyWith(offers: _visibleOffers(offers)));
        }
      },
      onError: (_) {},
    );
  }

  Future<void> withdrawOffer(String offerId) async {
    if (state is! ActivityLoaded) return;
    final current = state as ActivityLoaded;

    _hiddenOfferIds.add(offerId);
    final updated = _visibleOffers(current.offers);
    emit(current.copyWith(offers: updated));

    try {
      await _repository.withdrawOffer(offerId);
    } catch (e) {
      _hiddenOfferIds.remove(offerId);
      emit(ActivityError(userFacingErrorMessage(e)));
      emit(current); // rollback
    }
  }

  List<LenderOffer> _visibleOffers(List<LenderOffer> offers) => offers
      .where((offer) => !_hiddenOfferIds.contains(offer.offerId))
      .toList();

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _offersSub?.cancel();
    return super.close();
  }
}
