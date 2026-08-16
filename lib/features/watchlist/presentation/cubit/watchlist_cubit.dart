// lib/features/watchlist/presentation/cubit/watchlist_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../marketplace/domain/models/marketplace_item.dart';
import '../../data/watchlist_repository.dart';

part 'watchlist_state.dart';

@injectable
class WatchlistCubit extends Cubit<WatchlistState> {
  WatchlistCubit(this._repository) : super(const WatchlistInitial());

  final WatchlistRepository _repository;
  StreamSubscription<List<MarketplaceItem>>? _realtimeSubscription;

  Future<void> load() async {
    emit(const WatchlistLoading());
    try {
      final listings = await _repository.getWatchedListings();
      emit(WatchlistLoaded(listings: listings));
      _subscribeToRealtime();
    } catch (e) {
      emit(WatchlistError(userFacingErrorMessage(e)));
    }
  }

  void _subscribeToRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _repository.watchWatchedListings().listen(
      (listings) {
        if (isClosed) return;
        emit(WatchlistLoaded(listings: listings));
      },
      onError: (e) {
        if (!isClosed) {
          emit(WatchlistError(userFacingErrorMessage(e)));
        }
      },
    );
  }

  Future<void> remove(String requestId, {bool forex = false}) async {
    try {
      await _repository.remove(requestId, forex: forex);
      final current = state;
      if (current is WatchlistLoaded) {
        final updated = current.listings
            .where((listing) => listing.requestId != requestId)
            .toList();
        emit(WatchlistLoaded(listings: updated));
      }
    } catch (e) {
      emit(WatchlistError(userFacingErrorMessage(e)));
    }
  }

  Future<void> add(MarketplaceItem listing) async {
    try {
      await _repository.add(
        listing.requestId,
        forex: listing.module == MarketplaceModule.forex,
      );
      final current = state;
      if (current is WatchlistLoaded &&
          !current.listings
              .any((item) => item.requestId == listing.requestId)) {
        emit(WatchlistLoaded(listings: [...current.listings, listing]));
      }
    } catch (e) {
      emit(WatchlistError(userFacingErrorMessage(e)));
    }
  }

  bool isWatched(String requestId) {
    final current = state;
    if (current is WatchlistLoaded) {
      return current.listings.any((l) => l.requestId == requestId);
    }
    return false;
  }

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    return super.close();
  }
}
