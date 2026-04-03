// lib/features/watchlist/presentation/cubit/watchlist_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/watchlist_repository.dart';

part 'watchlist_state.dart';

@injectable
class WatchlistCubit extends Cubit<WatchlistState> {
  WatchlistCubit(this._repository) : super(const WatchlistInitial());

  final WatchlistRepository _repository;

  Future<void> load() async {
    emit(const WatchlistLoading());
    try {
      final ids = await _repository.getWatchlist();
      emit(WatchlistLoaded(requestIds: ids));
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  Future<void> add(String requestId) async {
    await _repository.add(requestId);
    final current = state;
    if (current is WatchlistLoaded) {
      emit(WatchlistLoaded(requestIds: [...current.requestIds, requestId]));
    }
  }

  Future<void> remove(String requestId) async {
    await _repository.remove(requestId);
    final current = state;
    if (current is WatchlistLoaded) {
      emit(WatchlistLoaded(
        requestIds: current.requestIds.where((id) => id != requestId).toList(),
      ));
    }
  }

  bool isWatched(String requestId) {
    final current = state;
    if (current is WatchlistLoaded) {
      return current.requestIds.contains(requestId);
    }
    return false;
  }
}