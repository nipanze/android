// lib/features/contracts/presentation/cubit/contract_state.dart
part of 'contract_cubit.dart';

abstract class ContractState extends Equatable {
  const ContractState();
  @override
  List<Object?> get props => [];
}

class ContractLoading extends ContractState {
  const ContractLoading();
}

class ContractLoaded extends ContractState {
  const ContractLoaded({
    required this.contract,
    required this.schedule,
    this.negotiator,
    this.myReveal,
    this.isRevealing = false,
  });

  final ContractSummary      contract;
  final List<RepaymentLine>  schedule;
  final NegotiatorInfo?      negotiator;
  final ContactReveal?       myReveal;
  final bool                 isRevealing;

  bool get hasRevealed => myReveal?.isRevealed == true;

  ContractLoaded copyWith({
    ContractSummary?      contract,
    List<RepaymentLine>?  schedule,
    NegotiatorInfo?       negotiator,
    ContactReveal?        myReveal,
    bool?                 isRevealing,
  }) => ContractLoaded(
    contract:    contract    ?? this.contract,
    schedule:    schedule    ?? this.schedule,
    negotiator:  negotiator  ?? this.negotiator,
    myReveal:    myReveal    ?? this.myReveal,
    isRevealing: isRevealing ?? this.isRevealing,
  );

  @override
  List<Object?> get props =>
      [contract, schedule, negotiator, myReveal, isRevealing];
}

class ContractError extends ContractState {
  const ContractError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}