// lib/features/activity/presentation/cubit/activity_state.dart
part of 'activity_cubit.dart';

abstract class ActivityState extends Equatable {
  const ActivityState();
  @override
  List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {
  const ActivityInitial();
}

class ActivityLoading extends ActivityState {
  const ActivityLoading();
}

class ActivityLoaded extends ActivityState {
  const ActivityLoaded({
    required this.offers,
    this.activity,
    this.deals = const [],
  });

  final List<LenderOffer> offers;
  final Map<String, dynamic>? activity;
  final List<dynamic> deals;

  ActivityLoaded copyWith({
    List<LenderOffer>? offers,
    Map<String, dynamic>? activity,
    List<dynamic>? deals,
  }) =>
      ActivityLoaded(
        offers: offers ?? this.offers,
        activity: activity ?? this.activity,
        deals: deals ?? this.deals,
      );

  @override
  List<Object?> get props => [offers, activity, deals];
}

class ActivityError extends ActivityState {
  const ActivityError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
