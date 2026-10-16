// lib/features/provider/presentation/cubit/capabilities_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/offline_service.dart';
import '../../domain/repositories/provider_repository_interface.dart';
import 'capabilities_state.dart';

@injectable
class CapabilitiesCubit extends Cubit<CapabilitiesState> {
  CapabilitiesCubit(this._repo) : super(const CapabilitiesInitial()) {
    _connectionSubscription = OfflineService().onReconnected.listen((_) {
      if (!isClosed) unawaited(loadWithOpportunities());
    });
  }

  final IProviderRepository _repo;
  late final StreamSubscription<void> _connectionSubscription;

  Future<void> load() async {
    if (state is! CapabilitiesLoaded) emit(const CapabilitiesLoading());
    try {
      final caps = await _repo.getProviderCapabilities();
      final enabled = await _repo.capabilityProfilesEnabled();
      final workEnabled = await _repo.workProfilesEnabled();
      emit(CapabilitiesLoaded(
        capabilities: caps,
        capabilityProfilesEnabled: enabled,
        workProfilesEnabled: workEnabled,
      ));
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      if (state is! CapabilitiesLoaded) {
        emit(CapabilitiesError(userFacingErrorMessage(e)));
      }
    }
  }

  Future<void> loadWithOpportunities() async {
    if (state is! CapabilitiesLoaded) emit(const CapabilitiesLoading());
    try {
      final caps = await _repo.getProviderCapabilities();
      final opps = await _repo.getProviderOpportunities();
      final enabled = await _repo.capabilityProfilesEnabled();
      final workEnabled = await _repo.workProfilesEnabled();
      emit(CapabilitiesLoaded(
        capabilities: caps,
        opportunities: opps,
        capabilityProfilesEnabled: enabled,
        workProfilesEnabled: workEnabled,
      ));
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      if (state is! CapabilitiesLoaded) {
        emit(CapabilitiesError(userFacingErrorMessage(e)));
      }
    }
  }

  Future<void> addCapabilities(
    List<String> slugs, {
    Map<String, Map<String, dynamic>> metadataBySlug = const {},
  }) async {
    try {
      await _repo.addCapabilities(slugs, metadataBySlug: metadataBySlug);
      await loadWithOpportunities();
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      if (state is! CapabilitiesLoaded ||
          parseSupabaseError(e) is! NetworkException) {
        emit(CapabilitiesError(userFacingErrorMessage(e)));
      }
    }
  }

  Future<void> saveCapabilitiesBulk({
    required List<Map<String, dynamic>> items,
    String? categorySlug,
    List<String> removeSlugs = const [],
  }) async {
    try {
      await _repo.saveProviderCapabilitiesBulk(
        items: items,
        categorySlug: categorySlug,
        removeSlugs: removeSlugs,
      );
      await loadWithOpportunities();
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      if (state is! CapabilitiesLoaded ||
          parseSupabaseError(e) is! NetworkException) {
        emit(CapabilitiesError(userFacingErrorMessage(e)));
      }
      rethrow;
    }
  }

  Future<void> setCapabilityPaused({
    required String capabilitySlug,
    required bool paused,
  }) async {
    try {
      await _repo.setCapabilityPaused(
        capabilitySlug: capabilitySlug,
        paused: paused,
      );
      await loadWithOpportunities();
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      if (state is! CapabilitiesLoaded ||
          parseSupabaseError(e) is! NetworkException) {
        emit(CapabilitiesError(userFacingErrorMessage(e)));
      }
    }
  }

  Future<void> removeCapability(String capabilitySlug) async {
    try {
      await _repo.removeCapability(capabilitySlug);
      await loadWithOpportunities();
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      if (state is! CapabilitiesLoaded ||
          parseSupabaseError(e) is! NetworkException) {
        emit(CapabilitiesError(userFacingErrorMessage(e)));
      }
    }
  }

  @override
  Future<void> close() {
    _connectionSubscription.cancel();
    return super.close();
  }
}
