// lib/features/contracts/presentation/cubit/contract_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../marketplace/domain/models/loan_listing.dart';
import '../../data/contract_repository.dart';
import '../../domain/models/negotiator_info.dart';

part 'contract_state.dart';

@injectable
class ContractCubit extends Cubit<ContractState> {
  ContractCubit(this._repository) : super(const ContractLoading());

  final ContractRepository _repository;

  Future<void> load(String contractId) async {
    emit(const ContractLoading());
    try {
      final results = await Future.wait([
        _repository.getContract(contractId),
        _repository.getSchedule(contractId),
        _repository.getNegotiator(contractId),
        _repository.getMyReveal(contractId),
      ]);

      emit(ContractLoaded(
        contract:    results[0] as ContractSummary,
        schedule:    results[1] as List<RepaymentLine>,
        negotiator:  results[2] as NegotiatorInfo?,
        myReveal:    results[3] as ContactReveal?,
        isRevealing: false,
      ));
    } catch (e) {
      emit(ContractError(e.toString()));
    }
  }

  Future<void> confirmReveal(String contractId) async {
    if (state is! ContractLoaded) return;
    final current = state as ContractLoaded;
    emit(current.copyWith(isRevealing: true));
    try {
      final reveal = await _repository.confirmReveal(contractId);
      emit(current.copyWith(myReveal: reveal, isRevealing: false));
    } catch (e) {
      emit(current.copyWith(isRevealing: false));
      emit(ContractError(e.toString()));
    }
  }

  Future<void> reportRepayment(
      String contractId, String scheduleId, String status) async {
    try {
      await _repository.reportRepayment(scheduleId, status);
      await load(contractId); // refresh
    } catch (e) {
      emit(ContractError(e.toString()));
    }
  }

  Future<void> refresh(String contractId) => load(contractId);
}