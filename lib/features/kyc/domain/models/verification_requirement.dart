// lib/features/kyc/domain/models/verification_requirement.dart
import 'package:equatable/equatable.dart';

class VerificationRequirement extends Equatable {
  const VerificationRequirement({
    required this.id,
    required this.scopeType,
    required this.scopeId,
    this.identityRequired = true,
    this.phoneRequired = false,
    this.providerVerificationRequired = false,
    this.evidenceRequirements = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String scopeType; // 'global' | 'activity' | 'category' | 'capability'
  final String scopeId;
  final bool identityRequired;
  final bool phoneRequired;
  final bool providerVerificationRequired;
  final List<String> evidenceRequirements;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VerificationRequirement.fromMap(Map<String, dynamic> map) {
    List<String> evidence = [];
    if (map['evidence_requirements'] is List) {
      evidence = (map['evidence_requirements'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return VerificationRequirement(
      id: map['id'] as String? ?? '',
      scopeType: map['scope_type'] as String? ?? 'global',
      scopeId: map['scope_id'] as String? ?? 'global',
      identityRequired: map['identity_required'] as bool? ?? true,
      phoneRequired: map['phone_required'] as bool? ?? false,
      providerVerificationRequired:
          map['provider_verification_required'] as bool? ?? false,
      evidenceRequirements: evidence,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scope_type': scopeType,
      'scope_id': scopeId,
      'identity_required': identityRequired,
      'phone_required': phoneRequired,
      'provider_verification_required': providerVerificationRequired,
      'evidence_requirements': evidenceRequirements,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        scopeType,
        scopeId,
        identityRequired,
        phoneRequired,
        providerVerificationRequired,
        evidenceRequirements,
        isActive,
      ];
}

class VerificationCheckResult extends Equatable {
  const VerificationCheckResult({
    required this.allowed,
    this.reason,
    this.missingRequirements = const [],
    this.requirement,
  });

  final bool allowed;
  final String? reason; // 'identity_verification_required', 'provider_verification_required', 'phone_verification_required'
  final List<String> missingRequirements;
  final VerificationRequirement? requirement;

  bool get requiresIdentity =>
      missingRequirements.contains('identity_verification_required') ||
      reason == 'identity_verification_required';

  bool get requiresProviderVerification =>
      missingRequirements.contains('provider_verification_required') ||
      reason == 'provider_verification_required';

  bool get requiresPhone =>
      missingRequirements.contains('phone_verification_required') ||
      reason == 'phone_verification_required';

  factory VerificationCheckResult.fromMap(Map<String, dynamic> map) {
    List<String> missing = [];
    if (map['missing_requirements'] is List) {
      missing = (map['missing_requirements'] as List)
          .map((e) => e.toString())
          .toList();
    }

    VerificationRequirement? req;
    if (map['scope_type'] != null) {
      req = VerificationRequirement.fromMap(map);
    }

    return VerificationCheckResult(
      allowed: map['allowed'] as bool? ?? false,
      reason: map['reason'] as String?,
      missingRequirements: missing,
      requirement: req,
    );
  }

  static const VerificationCheckResult allowedResult =
      VerificationCheckResult(allowed: true);

  @override
  List<Object?> get props => [allowed, reason, missingRequirements, requirement];
}
