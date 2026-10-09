part of 'discovery_cubit.dart';

abstract class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => [];
}

class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial();
}

class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading();
}

class DiscoveryCardLoaded extends DiscoveryState {
  const DiscoveryCardLoaded(this.template);

  final DiscoveryQuestionTemplate? template;

  @override
  List<Object?> get props => [template];
}

class DiscoveryPlansLoaded extends DiscoveryState {
  const DiscoveryPlansLoaded(this.plans);

  final List<UserDiscoveryPlan> plans;

  @override
  List<Object?> get props => [plans];
}

class DiscoveryError extends DiscoveryState {
  const DiscoveryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
