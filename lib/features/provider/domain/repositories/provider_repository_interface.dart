// lib/features/provider/domain/repositories/provider_repository_interface.dart

import 'dart:typed_data';

import '../entities/provider_capability.dart';
import '../entities/provider_category_type.dart';
import '../entities/provider_company_profile.dart';
import '../entities/provider_opportunity.dart';
import '../entities/provider_service_role.dart';

abstract class IProviderRepository {
  Future<bool> capabilityProfilesEnabled();
  Future<Map<String, ProviderCategoryType>> getMyCategoryTypes();
  Future<Map<String, DateTime>> getMyCategoryIdentityUpdatedAt();
  Future<void> setCategoryType(String categorySlug, ProviderCategoryType type);
  Future<Map<String, dynamic>> getMyProviderIdentity(String categorySlug);
  Future<void> saveProviderIdentityPresentation({
    required String categorySlug,
    required ProviderCategoryType type,
    required Map<String, dynamic> presentation,
  });
  Future<Map<String, dynamic>> switchProviderIdentity({
    required String categorySlug,
    required ProviderCategoryType type,
    required Map<String, dynamic> presentation,
  });
  Future<ProviderCompanyProfile?> getCompanyProfile(String categorySlug);
  Future<List<Map<String, dynamic>>> getCompanyVerificationSubmissions(
      String categorySlug);
  Future<String> uploadCompanyVerificationDocument({
    required String categorySlug,
    required String documentType,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  });
  Future<void> submitCompanyVerificationDocument({
    required String categorySlug,
    required String documentType,
    required String filePath,
  });
  Future<List<Map<String, dynamic>>> getCompanyVerificationRequirements({
    required String categorySlug,
    required List<String> serviceSlugs,
  });
  Future<List<Map<String, dynamic>>> getCompanyEvidence({
    required String categorySlug,
    required List<String> serviceSlugs,
  });
  Future<void> saveCompanyCategory({
    required String categorySlug,
    required List<String> serviceSlugs,
    required List<String> roleCapabilitySlugs,
    required Map<String, dynamic> profile,
    required List<Map<String, String>> evidence,
  });
  Future<String> uploadCompanyEvidence({
    required String categorySlug,
    required String requirementKey,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  });
  Future<String> uploadRoleQualificationEvidence({
    required String capabilitySlug,
    required String roleSlug,
    required String qualificationSlug,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  });
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
