// lib/features/provider/presentation/cubit/capabilities_state.dart

import '../../domain/entities/provider_capability.dart';
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
  });

  final List<ProviderCapability> capabilities;
  final List<ProviderOpportunity> opportunities;
  final bool capabilityProfilesEnabled;
  final bool workProfilesEnabled;
}

class CapabilitiesError extends CapabilitiesState {
  const CapabilitiesError(this.message);
  final String message;
}
