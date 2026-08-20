import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/forex_listing_model.dart';
import '../../../forex/data/forex_repository.dart';
import '../../data/listing_repository.dart';
import '../../domain/models/my_listing.dart';

part 'my_listings_state.dart';

@injectable
class MyListingsCubit extends Cubit<MyListingsState> {
  MyListingsCubit(this._repository, this._forexRepository)
      : super(const MyListingsInitial());

  final ListingRepository _repository;
  final ForexRepository _forexRepository;
  StreamSubscription<List<MyListing>>? _realtimeSub;
  StreamSubscription<List<ForexListingModel>>? _forexRealtimeSub;

  Future<void> load() async {
    emit(const MyListingsLoading());
    try {
      final listings = await _repository.getMyListings();
      final forexRequests = await _forexRepository.getMyForexRequests();
      emit(MyListingsLoaded(listings, forexRequests: forexRequests));
      _subscribeRealtime();
    } catch (e) {
      emit(MyListingsError(userFacingErrorMessage(e)));
    }
  }

  void _subscribeRealtime() {
    _realtimeSub?.cancel();
    _forexRealtimeSub?.cancel();

    _realtimeSub = _repository.watchMyListings().listen(
      (listings) {
        if (!isClosed) {
          final currentForex = state is MyListingsLoaded
              ? (state as MyListingsLoaded).forexRequests
              : <ForexListingModel>[];
          emit(MyListingsLoaded(listings, forexRequests: currentForex));
        }
      },
      onError: (_) {},
    );

    _forexRealtimeSub = _forexRepository.watchForexRequests().listen(
      (forex) {
        if (!isClosed) {
          final currentListings = state is MyListingsLoaded
              ? (state as MyListingsLoaded).listings
              : <MyListing>[];
          emit(MyListingsLoaded(currentListings, forexRequests: forex));
        }
      },
      onError: (_) {},
    );
  }

  Future<void> cancelListing(String requestId) async {
    try {
      await _repository.cancelListing(requestId);
      final refreshed = await _repository.getMyListings();
      final currentForex = state is MyListingsLoaded
          ? (state as MyListingsLoaded).forexRequests
          : <ForexListingModel>[];
      if (!isClosed) emit(MyListingsLoaded(refreshed, forexRequests: currentForex));
      _subscribeRealtime();
    } catch (e) {
      final current = state;
      emit(MyListingsError(userFacingErrorMessage(e)));
      if (current is MyListingsLoaded) emit(current);
    }
  }

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    _forexRealtimeSub?.cancel();
    return super.close();
  }
}
