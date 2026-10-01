// lib/features/provider/domain/entities/provider_capability.dart

enum ProviderVerificationLevel {
  selfDeclared,
  providerVerified;

  static ProviderVerificationLevel fromString(String? s) {
    switch (s) {
      case 'provider_verified':
        return ProviderVerificationLevel.providerVerified;
      default:
        return ProviderVerificationLevel.selfDeclared;
    }
  }

  String get dbValue {
    switch (this) {
      case ProviderVerificationLevel.providerVerified:
        return 'provider_verified';
      case ProviderVerificationLevel.selfDeclared:
        return 'self_declared';
    }
  }
}

class ProviderCapability {
  const ProviderCapability({
    required this.id,
    required this.userId,
    required this.capabilitySlug,
    required this.verificationLevel,
    this.evidenceUrl,
    this.metadata = const {},
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    // Joined from need_capabilities
    this.capabilityName,
    this.categorySlug,
    this.categoryName,
    this.categoryIcon,
  });

  factory ProviderCapability.fromMap(Map<String, dynamic> map) {
    return ProviderCapability(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      capabilitySlug: map['capability_slug'] as String,
      verificationLevel: ProviderVerificationLevel.fromString(
          map['verification_level'] as String?),
      evidenceUrl: map['evidence_url'] as String?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
      verifiedBy: map['verified_by'] as String?,
      verifiedAt: map['verified_at'] != null
          ? DateTime.tryParse(map['verified_at'] as String)
          : null,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      capabilityName: map['capability_name'] as String?,
      categorySlug: map['category_slug'] as String?,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
    );
  }

  final String id;
  final String userId;
  final String capabilitySlug;
  final ProviderVerificationLevel verificationLevel;
  final String? evidenceUrl;
  final Map<String, dynamic> metadata;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  // Joined fields
  final String? capabilityName;
  final String? categorySlug;
  final String? categoryName;
  final String? categoryIcon;

  bool get isVerified =>
      verificationLevel == ProviderVerificationLevel.providerVerified;
}
