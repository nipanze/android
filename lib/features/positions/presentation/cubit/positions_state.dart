// lib/features/positions/presentation/cubit/positions_state.dart
part of 'positions_cubit.dart';

abstract class PositionsState extends Equatable {
  const PositionsState();
  @override
  List<Object?> get props => [];
}

class PositionsInitial extends PositionsState {
  const PositionsInitial();
}

class PositionsLoading extends PositionsState {
  const PositionsLoading();
}

class PositionsLoaded extends PositionsState {
  const PositionsLoaded({
    required this.offers,
    this.activity,
  });

  // Renamed from bids to offers to match v4.0.
  // Contracts removed - non-custodial matching only.
  final List<LenderOffer>          offers;
  final Map<String, dynamic>?      activity;

  PositionsLoaded copyWith({
    List<LenderOffer>?          offers,
    Map<String, dynamic>?       activity,
  }) => PositionsLoaded(
    offers:      offers      ?? this.offers,
    activity:    activity    ?? this.activity,
  );

  @override
  List<Object?> get props => [offers, activity];
}

class PositionsError extends PositionsState {
  const PositionsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}