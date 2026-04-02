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
    required this.bids,
    required this.contracts,
    this.portfolio,
  });

  final List<LenderBid>            bids;
  final List<Map<String, dynamic>> contracts;
  final Map<String, dynamic>?      portfolio;

  PositionsLoaded copyWith({
    List<LenderBid>?            bids,
    List<Map<String, dynamic>>? contracts,
    Map<String, dynamic>?       portfolio,
  }) => PositionsLoaded(
    bids:      bids      ?? this.bids,
    contracts: contracts ?? this.contracts,
    portfolio: portfolio ?? this.portfolio,
  );

  @override
  List<Object?> get props => [bids, contracts, portfolio];
}

class PositionsError extends PositionsState {
  const PositionsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}