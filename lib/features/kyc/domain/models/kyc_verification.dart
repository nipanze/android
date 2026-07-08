// lib/features/kyc/domain/models/kyc_verification.dart
import 'package:equatable/equatable.dart';

enum KycDocType { nationalIdFront, nationalIdBack, selfie }

class KycVerification extends Equatable {
  const KycVerification({
    required this.id,
    required this.userId,
    required this.status,
    this.nationalIdFrontUrl,
    this.nationalIdBackUrl,
    this.selfieUrl,
    this.rejectionReason,
    this.submittedAt,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String
      status; // not_submitted | pending | approved | rejected | expired
  final String? nationalIdFrontUrl;
  final String? nationalIdBackUrl;
  final String? selfieUrl;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? expiresAt;

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';
  bool get notSubmitted => status == 'not_submitted';

  bool get hasFront => nationalIdFrontUrl != null;
  bool get hasBack => nationalIdBackUrl != null;
  bool get hasSelfie => selfieUrl != null;
  bool get allDocsUploaded => hasFront && hasBack && hasSelfie;

  factory KycVerification.fromMap(Map<String, dynamic> map) {
    return KycVerification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      status: map['status'] as String? ?? 'not_submitted',
      nationalIdFrontUrl: map['national_id_front_url'] as String?,
      nationalIdBackUrl: map['national_id_back_url'] as String?,
      selfieUrl: map['selfie_url'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'] as String)
          : null,
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, status, hasFront, hasBack, hasSelfie];
}
