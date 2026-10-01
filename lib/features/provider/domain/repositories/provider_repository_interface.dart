// lib/features/provider/domain/repositories/provider_repository_interface.dart

import '../entities/provider_capability.dart';
import '../entities/provider_opportunity.dart';

abstract class IProviderRepository {
  Future<List<ProviderCapability>> getProviderCapabilities();
  Future<void> addCapabilities(List<String> slugs);
  Future<void> removeCapability(String capabilitySlug);
  Future<bool> hasCapability(String capabilitySlug);
  Future<List<ProviderOpportunity>> getProviderOpportunities();
}
