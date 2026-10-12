// lib/features/provider/domain/repositories/provider_repository_interface.dart

import '../entities/provider_capability.dart';
import '../entities/provider_opportunity.dart';
import '../entities/provider_service_role.dart';

abstract class IProviderRepository {
  Future<bool> capabilityProfilesEnabled();
  Future<List<ProviderCapability>> getProviderCapabilities();
  Future<void> addCapabilities(
    List<String> slugs, {
    Map<String, Map<String, dynamic>> metadataBySlug = const {},
  });
  Future<void> removeCapability(String capabilitySlug);
  Future<bool> hasCapability(String capabilitySlug);
  Future<String> submitCapabilityEvidence({
    required String providerCapabilityId,
    required String requirementKey,
    required String fileUrl,
  });
  Future<List<ProviderOpportunity>> getProviderOpportunities();
  Future<List<ProviderServiceRole>> getServiceRoles({
    String? categorySlug,
    String? capabilitySlug,
  });
}
