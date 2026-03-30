// ignore_for_file: unused_import

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nipanze/features/marketplace/data/marketplace_repository.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';

import '../../../data/marketplace_repository.dart';
import '../../../domain/models/loan_listing.dart';

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
    _realtimeSub = _repository.watchListings().listen(
      (listings) {
        if (!isClosed) {
          emit(MarketplaceLoaded(listings: listings, activeFilter: _activeFilter));
        }
      },
      onError: (_) {}, // silently ignore realtime errors — stale data still shown
    );
  }

  Future<void> refresh() => load(filter: _activeFilter);

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
