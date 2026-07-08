part of 'my_listings_cubit.dart';

abstract class MyListingsState extends Equatable {
  const MyListingsState();
  @override
  List<Object?> get props => [];
}

class MyListingsInitial extends MyListingsState {
  const MyListingsInitial();
}

class MyListingsLoading extends MyListingsState {
  const MyListingsLoading();
}

class MyListingsLoaded extends MyListingsState {
  const MyListingsLoaded(this.listings);
  final List<MyListing> listings;
  @override
  List<Object?> get props => [listings];
}

class MyListingsError extends MyListingsState {
  const MyListingsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
