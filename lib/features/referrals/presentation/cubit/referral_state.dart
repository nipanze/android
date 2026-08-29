part of 'referral_cubit.dart';

enum ReferralAction { none, codeCopied, codeApplied }

enum ReferralValidationStatus { initial, validating, valid, invalid, error }

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

class ReferralCodeValidationState extends Equatable {
  const ReferralCodeValidationState({
    this.status = ReferralValidationStatus.initial,
    this.message,
    this.reason,
    this.referrerName,
  });

  final ReferralValidationStatus status;
  final String? message;
  final String? reason;
  final String? referrerName;

  bool get isValid => status == ReferralValidationStatus.valid;
  bool get isBlocking =>
      status == ReferralValidationStatus.validating ||
      status == ReferralValidationStatus.invalid ||
      status == ReferralValidationStatus.error;

  @override
  List<Object?> get props => [status, message, reason, referrerName];
}
