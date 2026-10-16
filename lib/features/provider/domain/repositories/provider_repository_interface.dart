// lib/features/provider/domain/repositories/provider_repository_interface.dart

import '../entities/provider_capability.dart';
import '../entities/provider_opportunity.dart';
import '../entities/provider_service_role.dart';

abstract class IProviderRepository {
  Future<bool> capabilityProfilesEnabled();
  Future<bool> workProfilesEnabled();
  Future<bool> isCategoryWorkProfileEnabled(String categorySlug);
  Future<List<ProviderCapability>> getProviderCapabilities();
  Future<void> addCapabilities(
    List<String> slugs, {
    Map<String, Map<String, dynamic>> metadataBySlug = const {},
  });
  Future<void> saveProviderCapabilitiesBulk({
    required List<Map<String, dynamic>> items,
    String? categorySlug,
    List<String> removeSlugs = const [],
  });
  Future<void> removeCapability(String capabilitySlug);
  Future<bool> hasCapability(String capabilitySlug);
  Future<void> setCapabilityPaused({
    required String capabilitySlug,
    required bool paused,
  });
  Future<String> submitCapabilityEvidence({
    required String providerCapabilityId,
    required String requirementKey,
    required String fileUrl,
  });
  Future<String> submitRoleQualificationEvidence({
    required String providerCapabilityId,
    required String roleSlug,
    required String qualificationSlug,
    required String evidenceObjectPath,
  });
  Future<List<ProviderOpportunity>> getProviderOpportunities();
  Future<List<ProviderServiceRole>> getServiceRoles({
    String? categorySlug,
    String? capabilitySlug,
  });
}
