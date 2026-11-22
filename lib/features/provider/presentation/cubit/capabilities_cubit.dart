// lib/features/provider/presentation/cubit/capabilities_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/offline_service.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_category_type.dart';
import '../../domain/entities/provider_opportunity.dart';
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

  Future<Map<String, ProviderCategoryType>> _loadCategoryTypes() async {
    try {
      return await _repo.getMyCategoryTypes();
    } catch (_) {
      // Type preferences are additive and must not block the existing service list.
      return const {};
    }
  }

  Future<void> load() async {
    if (state is! CapabilitiesLoaded) emit(const CapabilitiesLoading());
    try {
      final results = await Future.wait<Object>([
        _repo.getProviderCapabilities(),
        _repo.capabilityProfilesEnabled(),
        _repo.workProfilesEnabled(),
        _loadCategoryTypes(),
      ]);
      final caps = results[0] as List<ProviderCapability>;
      final enabled = results[1] as bool;
      final workEnabled = results[2] as bool;
      final categoryTypes =
          results[3] as Map<String, ProviderCategoryType>;
      emit(CapabilitiesLoaded(
        capabilities: caps,
        capabilityProfilesEnabled: enabled,
        workProfilesEnabled: workEnabled,
        categoryTypes: categoryTypes,
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
      final results = await Future.wait<Object>([
        _repo.getProviderCapabilities(),
        _repo.getProviderOpportunities(),
        _repo.capabilityProfilesEnabled(),
        _repo.workProfilesEnabled(),
        _loadCategoryTypes(),
      ]);
      final caps = results[0] as List<ProviderCapability>;
      final opps = results[1] as List<ProviderOpportunity>;
      final enabled = results[2] as bool;
      final workEnabled = results[3] as bool;
      final categoryTypes =
          results[4] as Map<String, ProviderCategoryType>;
      emit(CapabilitiesLoaded(
        capabilities: caps,
        opportunities: opps,
        capabilityProfilesEnabled: enabled,
        workProfilesEnabled: workEnabled,
        categoryTypes: categoryTypes,
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
    String? categorySlug,
    Map<String, Map<String, dynamic>> metadataBySlug = const {},
  }) async {
    await addCapabilitiesAndReport(
      slugs,
      categorySlug: categorySlug,
      metadataBySlug: metadataBySlug,
    );
  }

  Future<bool> addCapabilitiesAndReport(
    List<String> slugs, {
    String? categorySlug,
    Map<String, Map<String, dynamic>> metadataBySlug = const {},
  }) async {
    try {
      await _repo.addCapabilities(
        slugs,
        categorySlug: categorySlug,
        metadataBySlug: metadataBySlug,
      );
      return true;
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      emit(CapabilitiesError(userFacingErrorMessage(e)));
      return false;
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
    required String providerCapabilityId,
    required bool paused,
  }) async {
    try {
      await _repo.setCapabilityPaused(
        providerCapabilityId: providerCapabilityId,
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

  Future<void> removeCapability(String providerCapabilityId) async {
    try {
      await _repo.removeCapability(providerCapabilityId);
      await loadWithOpportunities();
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      if (state is! CapabilitiesLoaded) {
        emit(CapabilitiesError(userFacingErrorMessage(e)));
      }
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _connectionSubscription.cancel();
    return super.close();
  }
}
