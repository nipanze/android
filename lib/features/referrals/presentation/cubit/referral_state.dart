part of 'referral_cubit.dart';

enum ReferralAction { none, codeCopied }

abstract class ReferralState extends Equatable {
  const ReferralState();

  @override
  List<Object?> get props => [];
}

class ReferralInitial extends ReferralState {
  const ReferralInitial();
}

class ReferralLoading extends ReferralState {
  const ReferralLoading();
}

class ReferralLoaded extends ReferralState {
  const ReferralLoaded({
    required this.dashboard,
    this.lastAction = ReferralAction.none,
  });

  final ReferralDashboard dashboard;
  final ReferralAction lastAction;

  ReferralLoaded copyWith({
    ReferralDashboard? dashboard,
    ReferralAction? lastAction,
  }) {
    return ReferralLoaded(
      dashboard: dashboard ?? this.dashboard,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [dashboard, lastAction];
}

class ReferralError extends ReferralState {
  const ReferralError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
