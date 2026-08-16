import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/listing_repository.dart';
import '../../domain/models/my_listing.dart';

part 'my_listings_state.dart';

@injectable
class MyListingsCubit extends Cubit<MyListingsState> {
  MyListingsCubit(this._repository) : super(const MyListingsInitial());

  final ListingRepository _repository;
  StreamSubscription<List<MyListing>>? _realtimeSub;

  Future<void> load() async {
    emit(const MyListingsLoading());
    try {
      final listings = await _repository.getMyListings();
      emit(MyListingsLoaded(listings));
      _subscribeRealtime();
    } catch (e) {
      emit(MyListingsError(userFacingErrorMessage(e)));
    }
  }

  void _subscribeRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = _repository.watchMyListings().listen(
      (listings) {
        if (!isClosed) emit(MyListingsLoaded(listings));
      },
      onError: (_) {}, // stale data still shown on stream error
    );
  }

  Future<void> cancelListing(String requestId) async {
    try {
      await _repository.cancelListing(requestId);
      final refreshed = await _repository.getMyListings();
      if (!isClosed) emit(MyListingsLoaded(refreshed));
      _subscribeRealtime();
    } catch (e) {
      // Bubble error to UI via a transient error state while keeping existing list
      final current = state;
      emit(MyListingsError(userFacingErrorMessage(e)));
      if (current is MyListingsLoaded) emit(current);
    }
  }

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
