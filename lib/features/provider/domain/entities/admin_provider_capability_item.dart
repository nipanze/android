// lib/features/provider/domain/entities/admin_provider_capability_item.dart

import 'provider_capability.dart';

class AdminProviderCapabilityItem {
  const AdminProviderCapabilityItem({
    required this.id,
    required this.userId,
    required this.capabilitySlug,
    required this.verificationLevel,
    this.evidenceUrl,
    this.userEmail,
    this.userPhone,
    this.kycStatus,
    required this.createdAt,
  });

  factory AdminProviderCapabilityItem.fromMap(Map<String, dynamic> map) {
    return AdminProviderCapabilityItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      capabilitySlug: map['capability_slug'] as String,
      verificationLevel: ProviderVerificationLevel.fromString(
          map['verification_level'] as String?),
      evidenceUrl: map['evidence_url'] as String?,
      userEmail: map['user_email'] as String?,
      userPhone: map['user_phone'] as String?,
      kycStatus: map['kyc_status'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String capabilitySlug;
  final ProviderVerificationLevel verificationLevel;
  final String? evidenceUrl;
  final String? userEmail;
  final String? userPhone;
  final String? kycStatus;
  final DateTime createdAt;

  bool get isPending =>
      verificationLevel == ProviderVerificationLevel.selfDeclared;
}
