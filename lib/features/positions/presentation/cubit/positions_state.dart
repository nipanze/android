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
    this.deals = const [],
  });

  final List<LenderOffer> offers;
  final Map<String, dynamic>? activity;
  final List<dynamic> deals;

  PositionsLoaded copyWith({
    List<LenderOffer>? offers,
    Map<String, dynamic>? activity,
    List<dynamic>? deals,
  }) =>
      PositionsLoaded(
        offers: offers ?? this.offers,
        activity: activity ?? this.activity,
        deals: deals ?? this.deals,
      );

  @override
  List<Object?> get props => [offers, activity, deals];
}

class PositionsError extends PositionsState {
  const PositionsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
