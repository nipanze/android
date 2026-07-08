// lib/features/watchlist/presentation/cubit/watchlist_state.dart
part of 'watchlist_cubit.dart';

abstract class WatchlistState extends Equatable {
  const WatchlistState();

  @override
  List<Object?> get props => [];
}

class WatchlistInitial extends WatchlistState {
  const WatchlistInitial();
}

class WatchlistLoading extends WatchlistState {
  const WatchlistLoading();
}

class WatchlistLoaded extends WatchlistState {
  const WatchlistLoaded({required this.listings});

  final List<LoanListing> listings;

  @override
  List<Object?> get props => [listings];
}

class WatchlistError extends WatchlistState {
  const WatchlistError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
