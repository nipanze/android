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
  active,
  inactive,
  selfDeclared,
  pendingReview,
  providerVerified,
  rejected,
  expired;

  static ProviderCapabilityStatus fromString(String? value) => switch (value) {
        'active' => ProviderCapabilityStatus.active,
        'inactive' => ProviderCapabilityStatus.inactive,
        'pending_review' => ProviderCapabilityStatus.pendingReview,
        'provider_verified' => ProviderCapabilityStatus.providerVerified,
        'rejected' => ProviderCapabilityStatus.rejected,
        'expired' => ProviderCapabilityStatus.expired,
        _ => ProviderCapabilityStatus.selfDeclared,
      };
}

enum ProviderVerificationPolicy {
  open,
  optionalProof,
  requiredProof;

  static ProviderVerificationPolicy fromString(String? value) =>
      switch (value) {
        'optional_proof' => ProviderVerificationPolicy.optionalProof,
        'required_proof' => ProviderVerificationPolicy.requiredProof,
        _ => ProviderVerificationPolicy.open,
      };

  String get dbValue => switch (this) {
        ProviderVerificationPolicy.open => 'open',
        ProviderVerificationPolicy.optionalProof => 'optional_proof',
        ProviderVerificationPolicy.requiredProof => 'required_proof',
      };
}

class ProviderCapability {
  const ProviderCapability({
    required this.id,
    required this.userId,
    required this.capabilitySlug,
    required this.verificationLevel,
    this.capabilityType = 'service',
    this.evidenceUrl,
    this.metadata = const {},
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    this.updatedAt,
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
    this.verificationPolicy = ProviderVerificationPolicy.open,
    this.isActive = true,
  }) : status = status ??
            (verificationLevel == ProviderVerificationLevel.providerVerified
                ? ProviderCapabilityStatus.providerVerified
                : ProviderCapabilityStatus.active);

  factory ProviderCapability.fromMap(Map<String, dynamic> map) {
    final verificationLevel = ProviderVerificationLevel.fromString(
      map['verification_level'] as String?,
    );
    final rawSlug = map['capability_slug'] as String? ?? '';
    final rawType = map['capability_type'] as String?;
    final determinedType =
        rawType ?? (rawSlug.startsWith('work_') ? 'work' : 'service');
    return ProviderCapability(
      id: (map['id'] ?? map['provider_capability_id']) as String,
      userId: map['user_id'] as String,
      capabilitySlug: rawSlug,
      capabilityType: determinedType,
      verificationLevel: verificationLevel,
      evidenceUrl: map['evidence_url'] as String?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
      verifiedBy: map['verified_by'] as String?,
      verifiedAt: map['verified_at'] != null
          ? DateTime.tryParse(map['verified_at'] as String)
          : null,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      capabilityName: map['capability_name'] as String?,
      categorySlug: map['category_slug'] as String?,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      status: ProviderCapabilityStatus.fromString(
        _resolvedStatus(map, verificationLevel),
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
      verificationPolicy: ProviderVerificationPolicy.fromString(
        map['verification_policy'] as String?,
      ),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  static String _resolvedStatus(
    Map<String, dynamic> map,
    ProviderVerificationLevel verificationLevel,
  ) {
    final status = map['capability_status'] as String?;
    if (status != null && status != 'self_declared') return status;
    final active = map['is_active'] as bool? ?? true;
    final policy = ProviderVerificationPolicy.fromString(
      map['verification_policy'] as String?,
    );
    if (!active && policy == ProviderVerificationPolicy.requiredProof) {
      return 'inactive';
    }
    if (verificationLevel == ProviderVerificationLevel.providerVerified) {
      return 'provider_verified';
    }
    return 'active';
  }

  final String id;
  final String userId;
  final String capabilitySlug;
  final String capabilityType;
  final ProviderVerificationLevel verificationLevel;
  final String? evidenceUrl;
  final Map<String, dynamic> metadata;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
  final ProviderVerificationPolicy verificationPolicy;
  final bool isActive;

  bool get isVerified =>
      verificationLevel == ProviderVerificationLevel.providerVerified ||
      status == ProviderCapabilityStatus.providerVerified;

  bool get isWork =>
      capabilityType == 'work' ||
      capabilitySlug.startsWith('work_') ||
      engagements.contains('work') ||
      roles.isNotEmpty ||
      metadata.containsKey('kind_ids');

  bool get isService => !isWork;

  bool get isPaused => metadata['is_paused'] as bool? ?? false;

  List<String> get kindIds => (metadata['kind_ids'] as List? ?? const [])
      .map((e) => e.toString())
      .toList();

  List<String> get qualificationIds =>
      (metadata['qualification_ids'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();

  String? get yearsExperience => metadata['years_experience'] as String?;
  String? get availability => metadata['availability'] as String?;
  List<String> get languages => (metadata['languages'] as List? ?? const [])
      .map((e) => e.toString())
      .toList();
  bool get willingToTravel => metadata['willing_to_travel'] as bool? ?? false;
  num? get expectedPayAmount {
    final pay = metadata['expected_pay'];
    if (pay is Map) return pay['amount'] as num?;
    return metadata['expected_pay_amount'] as num?;
  }

  String? get expectedPayPeriod {
    final pay = metadata['expected_pay'];
    if (pay is Map) return pay['period'] as String?;
    return metadata['expected_pay_period'] as String?;
  }

  String? get expectedPayCurrency {
    final pay = metadata['expected_pay'];
    if (pay is Map) return pay['currency'] as String?;
    return metadata['expected_pay_currency'] as String? ?? 'UGX';
  }

  List<String> get engagements => (metadata['engagements'] as List? ?? const [])
      .map((value) => value.toString())
      .toList();

  List<Map<String, dynamic>> get roles =>
      (metadata['roles'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => value.cast<String, dynamic>())
          .toList();
}
