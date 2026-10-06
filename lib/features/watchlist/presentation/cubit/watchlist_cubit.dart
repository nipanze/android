// lib/features/watchlist/presentation/cubit/watchlist_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../marketplace/domain/models/marketplace_item.dart';
import '../../data/watchlist_repository.dart';

part 'watchlist_state.dart';

enum WatchlistActionResult { success, offline, failure }

@injectable
class WatchlistCubit extends Cubit<WatchlistState> {
  WatchlistCubit(this._repository) : super(const WatchlistInitial());

  final WatchlistRepository _repository;
  StreamSubscription<void>? _realtimeSubscription;
  int _watchlistRevision = 0;

  Future<void> load() async {
    if (isClosed) return;
    final revision = _watchlistRevision;
    emit(const WatchlistLoading());
    try {
      final listings = await _repository.getWatchedListings();
      if (isClosed || revision != _watchlistRevision) return;
      emit(WatchlistLoaded(listings: listings));
      _subscribeToRealtime();
    } catch (e) {
      if (isClosed) return;
      emit(WatchlistError(userFacingErrorMessage(e)));
    }
  }

  void _subscribeToRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _repository.watchWatchlistChanges().listen(
      (_) => unawaited(_refreshFromRealtime()),
      onError: (e) {
        if (!isClosed) {
          emit(WatchlistError(userFacingErrorMessage(e)));
        }
      },
    );
  }

  Future<void> _refreshFromRealtime() async {
    final revision = _watchlistRevision;
    try {
      final listings = await _repository.getWatchedListings();
      if (isClosed || revision != _watchlistRevision) return;
      emit(WatchlistLoaded(listings: listings));
    } catch (e) {
      if (!isClosed && revision == _watchlistRevision) {
        emit(WatchlistError(userFacingErrorMessage(e)));
      }
    }
  }

  Future<WatchlistActionResult> remove(MarketplaceItem listing) async {
    _watchlistRevision++;
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
      if (isClosed) return WatchlistActionResult.failure;
      final current = state;
      if (current is WatchlistLoaded &&
          current.listings.any((item) => _isSameListing(item, listing))) {
        emit(WatchlistLoaded(
          listings: current.listings
              .where((item) => !_isSameListing(item, listing))
              .toList(),
        ));
      }
      _watchlistRevision++;
      return WatchlistActionResult.success;
    } catch (e) {
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
      _watchlistRevision++;
      return _failureResult(e);
    }
  }

  Future<WatchlistActionResult> add(MarketplaceItem listing) async {
    _watchlistRevision++;
    try {
      await _repository.add(
        listing.requestId,
        module: listing.module,
      );
      if (isClosed) return WatchlistActionResult.failure;
      final current = state;
      if (current is WatchlistLoaded) {
        if (!current.listings.any((item) => _isSameListing(item, listing))) {
          emit(WatchlistLoaded(listings: [...current.listings, listing]));
        }
      } else {
        await load();
      }
      _watchlistRevision++;
      return WatchlistActionResult.success;
    } catch (e) {
      if (!isClosed) emit(WatchlistError(userFacingErrorMessage(e)));
      _watchlistRevision++;
      return _failureResult(e);
    }
  }

  Future<WatchlistActionResult> undoRemove(
    MarketplaceItem listing, {
    required int index,
  }) async {
    _watchlistRevision++;
    final previous = state;
    if (previous is WatchlistLoaded &&
        !previous.listings.any((item) => _isSameListing(item, listing))) {
      final restored = [...previous.listings];
      restored.insert(index.clamp(0, restored.length).toInt(), listing);
      emit(WatchlistLoaded(listings: restored));
    }

    try {
      await _repository.add(listing.requestId, module: listing.module);
      if (isClosed) return WatchlistActionResult.failure;
      final current = state;
      if (current is WatchlistLoaded) {
        if (!current.listings.any((item) => _isSameListing(item, listing))) {
          final restored = [...current.listings];
          restored.insert(index.clamp(0, restored.length).toInt(), listing);
          emit(WatchlistLoaded(listings: restored));
        }
      } else {
        await load();
      }
      _watchlistRevision++;
      return WatchlistActionResult.success;
    } catch (e) {
      if (!isClosed && previous is WatchlistLoaded) {
        emit(WatchlistLoaded(listings: previous.listings));
      }
      _watchlistRevision++;
      return _failureResult(e);
    }
  }

  WatchlistActionResult _failureResult(Object error) =>
      parseSupabaseError(error) is NetworkException
          ? WatchlistActionResult.offline
          : WatchlistActionResult.failure;

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
