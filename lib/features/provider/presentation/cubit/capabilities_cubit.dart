// lib/features/provider/presentation/cubit/capabilities_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/provider_repository_interface.dart';
import 'capabilities_state.dart';

@injectable
class CapabilitiesCubit extends Cubit<CapabilitiesState> {
  CapabilitiesCubit(this._repo) : super(const CapabilitiesInitial());

  final IProviderRepository _repo;

  Future<void> load() async {
    emit(const CapabilitiesLoading());
    try {
      final caps = await _repo.getProviderCapabilities();
      emit(CapabilitiesLoaded(capabilities: caps));
    } catch (e) {
      emit(CapabilitiesError(e.toString()));
    }
  }

  Future<void> loadWithOpportunities() async {
    emit(const CapabilitiesLoading());
    try {
      final caps = await _repo.getProviderCapabilities();
      final opps = await _repo.getProviderOpportunities();
      emit(CapabilitiesLoaded(capabilities: caps, opportunities: opps));
    } catch (e) {
      emit(CapabilitiesError(e.toString()));
    }
  }

  Future<void> addCapabilities(List<String> slugs) async {
    try {
      await _repo.addCapabilities(slugs);
      await load();
    } catch (e) {
      emit(CapabilitiesError(e.toString()));
    }
  }

  Future<void> removeCapability(String capabilitySlug) async {
    try {
      await _repo.removeCapability(capabilitySlug);
      await load();
    } catch (e) {
      emit(CapabilitiesError(e.toString()));
    }
  }
}
