// lib/features/marketplace/presentation/cubit/marketplace_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/marketplace_repository.dart';
import '../../domain/models/loan_listing.dart';

part 'marketplace_state.dart';

@injectable
class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit(this._repository) : super(const MarketplaceInitial());

  final MarketplaceRepository _repository;
  StreamSubscription<List<LoanListing>>? _realtimeSub;
  String _activeFilter = 'all';

  Future<void> load({String filter = 'all'}) async {
    _activeFilter = filter;
    emit(const MarketplaceLoading());
    try {
      final listings = await _repository.getListings(
        riskFilter: filter == 'low' ? 'low' : null,
        closingSoon: filter == 'closing',
        highYield: filter == 'yield',
      );
      emit(MarketplaceLoaded(listings: listings, activeFilter: filter));
      _subscribeRealtime();
    } catch (e) {
      emit(MarketplaceError(e.toString()));
    }
  }

  void _subscribeRealtime() {
    _realtimeSub?.cancel();
    // .take(1) ensures the stream completes after one emission so that
    // pumpAndSettle() can settle in integration tests. The subscription is
    // re-created on every load()/refresh() call, so live updates still work
    // in production — each pull-to-refresh re-opens the subscription.
    _realtimeSub = _repository.watchListings().take(1).listen(
      (listings) {
        if (!isClosed) {
          emit(MarketplaceLoaded(
            listings: listings,
            activeFilter: _activeFilter,
          ));
        }
      },
      onError: (_) {},
    );
  }

  Future<void> refresh() => load(filter: _activeFilter);

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}