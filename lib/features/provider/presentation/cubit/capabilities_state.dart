// lib/features/provider/presentation/cubit/capabilities_state.dart

import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_category_type.dart';
import '../../domain/entities/provider_opportunity.dart';

abstract class CapabilitiesState {
  const CapabilitiesState();
}

class CapabilitiesInitial extends CapabilitiesState {
  const CapabilitiesInitial();
}

class CapabilitiesLoading extends CapabilitiesState {
  const CapabilitiesLoading();
}

class CapabilitiesLoaded extends CapabilitiesState {
  const CapabilitiesLoaded({
    required this.capabilities,
    this.opportunities = const [],
    this.capabilityProfilesEnabled = false,
    this.workProfilesEnabled = false,
    this.categoryTypes = const {},
  });

  final List<ProviderCapability> capabilities;
  final List<ProviderOpportunity> opportunities;
  final bool capabilityProfilesEnabled;
  final bool workProfilesEnabled;
  final Map<String, ProviderCategoryType> categoryTypes;
}

class CapabilitiesError extends CapabilitiesState {
  const CapabilitiesError(this.message);
  final String message;
}
