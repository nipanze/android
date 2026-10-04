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
    if (isClosed) return;
    emit(const WatchlistLoading());
    try {
      final listings = await _repository.getWatchedListings();
      if (isClosed) return;
      emit(WatchlistLoaded(listings: listings));
      _subscribeToRealtime();
    } catch (e) {
      if (isClosed) return;
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

  Future<bool> remove(MarketplaceItem listing) async {
    final previous = state;
    final previousListings =
        previous is WatchlistLoaded ? previous.listings : null;
    final removedIndex =
        previousListings?.indexWhere((item) => _isSameListing(item, listing)) ??
            -1;
    if (previousListings != null && removedIndex >= 0) {
      emit(WatchlistLoaded(
        listings: previousListings
            .where((item) => !_isSameListing(item, listing))
            .toList(),
      ));
    }

    try {
      await _repository.remove(listing.requestId, module: listing.module);
      if (isClosed) return false;
      return true;
    } catch (_) {
      if (!isClosed && previousListings != null && removedIndex >= 0) {
        final current = state;
        if (current is WatchlistLoaded &&
            !current.listings.any((item) => _isSameListing(item, listing))) {
          final restored = [...current.listings];
          restored.insert(
            removedIndex.clamp(0, restored.length).toInt(),
            listing,
          );
          emit(WatchlistLoaded(listings: restored));
        } else if (current is! WatchlistLoaded) {
          emit(WatchlistLoaded(listings: previousListings));
        }
      }
      return false;
    }
  }

  Future<bool> add(MarketplaceItem listing) async {
    try {
      await _repository.add(
        listing.requestId,
        module: listing.module,
      );
      if (isClosed) return false;
      final current = state;
      if (current is WatchlistLoaded) {
        if (!current.listings.any((item) => _isSameListing(item, listing))) {
          emit(WatchlistLoaded(listings: [...current.listings, listing]));
        }
      } else {
        await load();
      }
      return true;
    } catch (e) {
      if (!isClosed) emit(WatchlistError(userFacingErrorMessage(e)));
      return false;
    }
  }

  Future<bool> undoRemove(MarketplaceItem listing, {required int index}) async {
    final previous = state;
    if (previous is WatchlistLoaded &&
        !previous.listings.any((item) => _isSameListing(item, listing))) {
      final restored = [...previous.listings];
      restored.insert(index.clamp(0, restored.length).toInt(), listing);
      emit(WatchlistLoaded(listings: restored));
    }

    try {
      await _repository.add(listing.requestId, module: listing.module);
      if (isClosed) return false;
      if (state is! WatchlistLoaded) {
        await load();
      }
      return true;
    } catch (_) {
      if (!isClosed && previous is WatchlistLoaded) {
        emit(WatchlistLoaded(listings: previous.listings));
      }
      return false;
    }
  }

  bool isWatched(
    String requestId, {
    MarketplaceModule module = MarketplaceModule.loan,
  }) {
    final current = state;
    if (current is WatchlistLoaded) {
      return current.listings.any(
        (listing) => listing.requestId == requestId && listing.module == module,
      );
    }
    return false;
  }

  bool _isSameListing(MarketplaceItem first, MarketplaceItem second) =>
      first.requestId == second.requestId && first.module == second.module;

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    return super.close();
  }
}
