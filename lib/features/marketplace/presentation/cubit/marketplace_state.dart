// lib/features/marketplace/presentation/cubit/marketplace_state.dart
part of 'marketplace_cubit.dart';

abstract class MarketplaceState extends Equatable {
  const MarketplaceState();

  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {
  const MarketplaceInitial();
}

class MarketplaceLoading extends MarketplaceState {
  const MarketplaceLoading();
}

class MarketplaceLoaded extends MarketplaceState {
  const MarketplaceLoaded({
    required this.listings,
    required this.activeFilter,
  });

  final List<LoanListing> listings;
  final String activeFilter;

  @override
  List<Object?> get props => [listings, activeFilter];
}

class MarketplaceError extends MarketplaceState {
  const MarketplaceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}