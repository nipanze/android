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

enum ProviderCapabilityStatus {
  selfDeclared,
  pendingReview,
  providerVerified,
  rejected,
  expired;

  static ProviderCapabilityStatus fromString(String? value) => switch (value) {
        'pending_review' => ProviderCapabilityStatus.pendingReview,
        'provider_verified' => ProviderCapabilityStatus.providerVerified,
        'rejected' => ProviderCapabilityStatus.rejected,
        'expired' => ProviderCapabilityStatus.expired,
        _ => ProviderCapabilityStatus.selfDeclared,
      };
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
    ProviderCapabilityStatus? status,
    this.pendingEvidenceCount = 0,
    this.approvedEvidenceCount = 0,
    this.rejectedEvidenceCount = 0,
    this.expiredEvidenceCount = 0,
    this.latestRejectReason,
    this.roleQualificationClaims = const [],
  }) : status = status ??
            (verificationLevel == ProviderVerificationLevel.providerVerified
                ? ProviderCapabilityStatus.providerVerified
                : ProviderCapabilityStatus.selfDeclared);

  factory ProviderCapability.fromMap(Map<String, dynamic> map) {
    final verificationLevel = ProviderVerificationLevel.fromString(
      map['verification_level'] as String?,
    );
    return ProviderCapability(
      id: (map['id'] ?? map['provider_capability_id']) as String,
      userId: map['user_id'] as String,
      capabilitySlug: map['capability_slug'] as String,
      verificationLevel: verificationLevel,
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
      status: ProviderCapabilityStatus.fromString(
        map['capability_status'] as String? ?? verificationLevel.dbValue,
      ),
      pendingEvidenceCount:
          (map['pending_evidence_count'] as num?)?.toInt() ?? 0,
      approvedEvidenceCount:
          (map['approved_evidence_count'] as num?)?.toInt() ?? 0,
      rejectedEvidenceCount:
          (map['rejected_evidence_count'] as num?)?.toInt() ?? 0,
      expiredEvidenceCount:
          (map['expired_evidence_count'] as num?)?.toInt() ?? 0,
      latestRejectReason: map['latest_reject_reason'] as String?,
      roleQualificationClaims:
          ((map['role_qualification_claims'] as List?) ?? const [])
              .whereType<Map>()
              .map((claim) => claim.cast<String, dynamic>())
              .toList(),
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
  final ProviderCapabilityStatus status;
  final int pendingEvidenceCount;
  final int approvedEvidenceCount;
  final int rejectedEvidenceCount;
  final int expiredEvidenceCount;
  final String? latestRejectReason;
  final List<Map<String, dynamic>> roleQualificationClaims;

  bool get isVerified =>
      verificationLevel == ProviderVerificationLevel.providerVerified ||
      status == ProviderCapabilityStatus.providerVerified;

  List<String> get engagements => (metadata['engagements'] as List? ?? const [])
      .map((value) => value.toString())
      .toList();

  List<Map<String, dynamic>> get roles =>
      (metadata['roles'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => value.cast<String, dynamic>())
          .toList();
}
