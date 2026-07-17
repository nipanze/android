// lib/features/marketplace/domain/models/agreement.dart
import 'package:equatable/equatable.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum AgreementStatus {
  pending,
  borrowerAgreed,
  lenderAgreed,
  locked;

  String get displayName {
    switch (this) {
      case AgreementStatus.pending:
        return 'Pending';
      case AgreementStatus.borrowerAgreed:
        return 'Borrower Agreed';
      case AgreementStatus.lenderAgreed:
        return 'Lender Agreed';
      case AgreementStatus.locked:
        return 'Locked';
    }
  }

  bool get isLocked => this == AgreementStatus.locked;
  bool get bothAgreed =>
      this == AgreementStatus.borrowerAgreed ||
      this == AgreementStatus.lenderAgreed ||
      this == AgreementStatus.locked;

  static AgreementStatus fromString(String value) {
    switch (value) {
      case 'borrower_agreed':
        return AgreementStatus.borrowerAgreed;
      case 'lender_agreed':
        return AgreementStatus.lenderAgreed;
      case 'locked':
        return AgreementStatus.locked;
      default:
        return AgreementStatus.pending;
    }
  }
}

enum RepaymentFrequency {
  weekly,
  monthly,
  oneTime;

  String get displayName {
    switch (this) {
      case RepaymentFrequency.weekly:
        return 'Weekly';
      case RepaymentFrequency.monthly:
        return 'Monthly';
      case RepaymentFrequency.oneTime:
        return 'One-time';
    }
  }

  static RepaymentFrequency fromString(String value) {
    switch (value) {
      case 'weekly':
        return RepaymentFrequency.weekly;
      case 'one_time':
        return RepaymentFrequency.oneTime;
      default:
        return RepaymentFrequency.monthly;
    }
  }
}

// ─── Agreement ─────────────────────────────────────────────────────────────────

class Agreement extends Equatable {
  const Agreement({
    required this.id,
    required this.offerId,
    required this.requestId,
    required this.repaymentFrequency,
    required this.repaymentAmount,
    required this.repaymentPeriod,
    required this.totalRepaymentAmount,
    required this.loanAmount,
    required this.interestRate,
    required this.latePenaltyPercentage,
    required this.agreementText,
    this.agreementSnapshot,
    required this.status,
    this.borrowerAgreedAt,
    this.lenderAgreedAt,
    this.lockedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String offerId;
  final String requestId;
  final RepaymentFrequency repaymentFrequency;
  final int repaymentAmount;
  final int repaymentPeriod;
  final int totalRepaymentAmount;
  final int loanAmount;
  final double interestRate;
  final double latePenaltyPercentage;
  final String agreementText;
  final Map<String, dynamic>? agreementSnapshot;
  final AgreementStatus status;
  final DateTime? borrowerAgreedAt;
  final DateTime? lenderAgreedAt;
  final DateTime? lockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDraft => status == AgreementStatus.pending;
  bool get isFullyLocked => status == AgreementStatus.locked;
  bool get canBeEdited => status == AgreementStatus.pending;

  factory Agreement.fromMap(Map<String, dynamic> map) {
    final snapshot = map['agreement_snapshot'] as Map<String, dynamic>?;
    return Agreement(
      id: map['id'] as String,
      offerId: map['offer_id'] as String,
      requestId: map['request_id'] as String,
      repaymentFrequency: RepaymentFrequency.fromString(
        map['repayment_frequency'] as String? ?? 'monthly',
      ),
      repaymentAmount: (map['repayment_amount'] as num?)?.toInt() ?? 0,
      repaymentPeriod: (map['repayment_period'] as num?)?.toInt() ?? 0,
      totalRepaymentAmount: (map['total_repayment_amount'] as num?)?.toInt() ?? 0,
      loanAmount: (snapshot?['loan_amount'] as num?)?.toInt() ?? 0,
      interestRate: (snapshot?['interest_rate_pct'] as num?)?.toDouble() ?? 0.0,
      latePenaltyPercentage:
          (map['late_payment_penalty_pct'] as num?)?.toDouble() ?? 0.0,
      agreementText: map['agreement_text'] as String? ?? '',
      agreementSnapshot: snapshot,
      status: AgreementStatus.fromString(
        map['status'] as String? ?? 'pending',
      ),
      borrowerAgreedAt: map['borrower_agreed_at'] != null
          ? DateTime.tryParse(map['borrower_agreed_at'] as String)
          : null,
      lenderAgreedAt: map['lender_agreed_at'] != null
          ? DateTime.tryParse(map['lender_agreed_at'] as String)
          : null,
      lockedAt: map['locked_at'] != null
          ? DateTime.tryParse(map['locked_at'] as String)
          : null,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'offer_id': offerId,
      'request_id': requestId,
      'repayment_frequency': repaymentFrequency == RepaymentFrequency.oneTime
          ? 'one_time'
          : repaymentFrequency.name,
      'repayment_amount': repaymentAmount,
      'repayment_period': repaymentPeriod,
      'total_repayment_amount': totalRepaymentAmount,
      'late_payment_penalty_pct': latePenaltyPercentage,
      'agreement_text': agreementText,
      'agreement_snapshot': agreementSnapshot,
      'status': status.name.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)!.toLowerCase()}',
      ),
      'borrower_agreed_at': borrowerAgreedAt?.toIso8601String(),
      'lender_agreed_at': lenderAgreedAt?.toIso8601String(),
      'locked_at': lockedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Agreement copyWith({
    String? id,
    String? offerId,
    String? requestId,
    RepaymentFrequency? repaymentFrequency,
    int? repaymentAmount,
    int? repaymentPeriod,
    int? totalRepaymentAmount,
    int? loanAmount,
    double? interestRate,
    double? latePenaltyPercentage,
    String? agreementText,
    Map<String, dynamic>? agreementSnapshot,
    AgreementStatus? status,
    DateTime? borrowerAgreedAt,
    DateTime? lenderAgreedAt,
    DateTime? lockedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Agreement(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      requestId: requestId ?? this.requestId,
      repaymentFrequency: repaymentFrequency ?? this.repaymentFrequency,
      repaymentAmount: repaymentAmount ?? this.repaymentAmount,
      repaymentPeriod: repaymentPeriod ?? this.repaymentPeriod,
      totalRepaymentAmount: totalRepaymentAmount ?? this.totalRepaymentAmount,
      loanAmount: loanAmount ?? this.loanAmount,
      interestRate: interestRate ?? this.interestRate,
      latePenaltyPercentage:
          latePenaltyPercentage ?? this.latePenaltyPercentage,
      agreementText: agreementText ?? this.agreementText,
      agreementSnapshot: agreementSnapshot ?? this.agreementSnapshot,
      status: status ?? this.status,
      borrowerAgreedAt: borrowerAgreedAt ?? this.borrowerAgreedAt,
      lenderAgreedAt: lenderAgreedAt ?? this.lenderAgreedAt,
      lockedAt: lockedAt ?? this.lockedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        offerId,
        repaymentFrequency,
        repaymentAmount,
        repaymentPeriod,
        totalRepaymentAmount,
        loanAmount,
        interestRate,
        status,
        borrowerAgreedAt,
        lenderAgreedAt,
        lockedAt,
      ];
}

// ─── ContactRevealData ─────────────────────────────────────────────────────────

class ContactRevealData extends Equatable {
  const ContactRevealData({
    required this.agreementId,
    required this.borrowerName,
    required this.borrowerPhone,
    required this.borrowerEmail,
    required this.lenderName,
    required this.lenderPhone,
    required this.lenderEmail,
    required this.revealedAt,
  });

  final String agreementId;
  final String borrowerName;
  final String borrowerPhone;
  final String borrowerEmail;
  final String lenderName;
  final String lenderPhone;
  final String lenderEmail;
  final DateTime revealedAt;

  factory ContactRevealData.fromJson(Map<String, dynamic> json) {
    return ContactRevealData(
      agreementId: json['agreement_id'] as String? ?? '',
      borrowerName: (json['borrower'] as Map?)?['full_name'] as String? ?? '',
      borrowerPhone: (json['borrower'] as Map?)?['phone'] as String? ?? '',
      borrowerEmail: (json['borrower'] as Map?)?['email'] as String? ?? '',
      lenderName: (json['lender'] as Map?)?['full_name'] as String? ?? '',
      lenderPhone: (json['lender'] as Map?)?['phone'] as String? ?? '',
      lenderEmail: (json['lender'] as Map?)?['email'] as String? ?? '',
      revealedAt: json['revealed_at'] != null
          ? DateTime.tryParse(json['revealed_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        agreementId,
        borrowerEmail,
        lenderEmail,
        revealedAt,
      ];
}
