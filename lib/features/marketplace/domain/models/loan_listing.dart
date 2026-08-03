// lib/features/marketplace/domain/models/loan_listing.dart
import 'package:equatable/equatable.dart';

// ─── LoanListing ──────────────────────────────────────────────────────────────

class LoanListing extends Equatable {
  const LoanListing({
    required this.requestId,
    required this.title,
    required this.purpose,
    required this.district,
    required this.durationMonths,
    required this.requestedAmount,
    required this.incomeSource,
    required this.preferredRepaymentPlan,
    required this.repaymentAmountPerPeriod,
    required this.repaymentTimeline,
    this.suggestedInterestRatePct,
    this.suggestedLateFeePct,
    this.suggestedRepaymentFrequency,
    this.suggestedInstallmentAmount,
    this.termsLockedAt,
    required this.status,
    required this.listedAt,
    required this.expiresAt,
    required this.numberOfOffers,
    this.kycStatus,
    this.offerCoverageTier,
    this.trustRatingAvg,
    this.trustReviewCount = 0,
    this.trustCompletedDealsCount = 0,
    this.trustIsRepeatParticipant = false,
    this.trustPhoneVerified = false,
    this.trustResponseTimeBucket,
    this.trustIsVerified = false,
    this.currency = 'UGX',
    this.preferredBank,
    this.institutionType,
    this.isBankAgent = false,
    this.showProfessionalTag = false,
  });

  final String requestId;
  final String title;
  final String purpose;
  final String district;
  final int durationMonths;
  final int requestedAmount;
  final String incomeSource;
  final String preferredRepaymentPlan;
  final int repaymentAmountPerPeriod;
  final String repaymentTimeline;
  final double? suggestedInterestRatePct;
  final double? suggestedLateFeePct;
  final String? suggestedRepaymentFrequency;
  final int? suggestedInstallmentAmount;
  final DateTime? termsLockedAt;
  final String status;
  final DateTime listedAt;
  final DateTime expiresAt;
  final int numberOfOffers;
  final String? kycStatus;
  final String? offerCoverageTier;
  final double? trustRatingAvg;
  final int trustReviewCount;
  final int trustCompletedDealsCount;
  final bool trustIsRepeatParticipant;
  final bool trustPhoneVerified;
  final String? trustResponseTimeBucket;
  final bool trustIsVerified;
  final String currency;
  final String? preferredBank;
  final String? institutionType;
  final bool isBankAgent;
  final bool showProfessionalTag;

  String? get professionalTag {
    if (!showProfessionalTag) return null;
    if (isBankAgent) {
      if (preferredBank?.isNotEmpty == true) {
        return '${preferredBank!} agent';
      }
      return 'Bank loan agent';
    }
    return switch (institutionType) {
      'bank' => 'Bank',
      'forex_exchange' => 'Forex exchange',
      'sacco' => 'SACCO',
      'company' => 'Company',
      _ => null,
    };
  }

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  bool get isClosingSoon24h =>
      timeRemaining.inHours < 24 && !timeRemaining.isNegative;
  bool get isClosingSoon6h =>
      timeRemaining.inHours < 6 && !timeRemaining.isNegative;
  bool get isExpired => timeRemaining.isNegative;

  String get timeRemainingLabel {
    if (isExpired) return 'Expired';
    final d = timeRemaining;
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m left';
    return '${d.inMinutes}m left';
  }

  factory LoanListing.fromMap(Map<String, dynamic> map) {
    return LoanListing(
      requestId: map['request_id'] as String,
      title: map['title'] as String? ?? 'Untitled',
      purpose: map['purpose'] as String? ?? '',
      district: map['district'] as String? ?? '',
      durationMonths: map['duration_months'] as int? ?? 0,
      requestedAmount: (map['requested_amount'] as num?)?.toInt() ?? 0,
      incomeSource: map['income_source'] as String? ?? '',
      preferredRepaymentPlan: map['preferred_repayment_plan'] as String? ?? '',
      repaymentAmountPerPeriod:
          (map['repayment_amount_per_period'] as num?)?.toInt() ?? 0,
      repaymentTimeline: map['repayment_timeline'] as String? ?? '',
      suggestedInterestRatePct:
          (map['suggested_interest_rate_pct'] as num?)?.toDouble(),
      suggestedLateFeePct: (map['suggested_late_fee_pct'] as num?)?.toDouble(),
      suggestedRepaymentFrequency:
          map['suggested_repayment_frequency'] as String?,
      suggestedInstallmentAmount:
          (map['suggested_installment_amount'] as num?)?.toInt(),
      termsLockedAt: map['terms_locked_at'] != null
          ? DateTime.tryParse(map['terms_locked_at'] as String)
          : null,
      status: map['status'] as String? ?? 'active',
      listedAt: DateTime.tryParse(map['listed_at'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(map['expires_at'] as String? ?? '') ??
          DateTime.now(),
      numberOfOffers: map['number_of_offers'] as int? ?? 0,
      kycStatus: map['kyc_status'] as String?,
      offerCoverageTier: map['offer_coverage_tier'] as String?,
      trustRatingAvg: (map['trust_rating_avg'] as num?)?.toDouble(),
      trustReviewCount: (map['trust_review_count'] as num?)?.toInt() ?? 0,
      trustCompletedDealsCount:
          (map['trust_completed_deals_count'] as num?)?.toInt() ?? 0,
      trustIsRepeatParticipant:
          map['trust_is_repeat_participant'] as bool? ?? false,
      trustPhoneVerified: map['trust_phone_verified'] as bool? ?? false,
      trustResponseTimeBucket: map['trust_response_time_bucket'] as String?,
      trustIsVerified: map['trust_is_verified'] as bool? ?? false,
      currency: map['currency'] as String? ?? 'UGX',
      preferredBank: map['preferred_bank'] as String?,
      institutionType: map['institution_type'] as String?,
      isBankAgent: map['is_bank_agent'] as bool? ?? false,
      showProfessionalTag: map['show_professional_tag'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [requestId, status, numberOfOffers];
}

// ─── LoanOffer ────────────────────────────────────────────────────────────────

class LoanOffer extends Equatable {
  const LoanOffer({
    required this.id,
    required this.requestId,
    required this.lenderId,
    required this.offerAmount,
    required this.interestRatePct,
    required this.lateFeePct,
    required this.repaymentFrequency,
    required this.installmentAmount,
    this.proposedExpectations,
    this.termsLockedAt,
    required this.status,
    required this.offeredAt,
    this.acceptedAt,
    this.trustRatingAvg,
    this.trustReviewCount = 0,
    this.trustCompletedDealsCount = 0,
    this.trustIsRepeatParticipant = false,
    this.trustPhoneVerified = false,
    this.trustResponseTimeBucket,
    this.trustIsVerified = false,
    this.currency = 'UGX',
    this.preferredBank,
    this.institutionType,
    this.isBankAgent = false,
    this.showProfessionalTag = false,
  });

  final String id;
  final String requestId;
  final String lenderId;
  final int offerAmount;
  final double interestRatePct;
  final double lateFeePct;
  final String repaymentFrequency;
  final int installmentAmount;
  final String? proposedExpectations;
  final DateTime? termsLockedAt;
  final String status;
  final DateTime offeredAt;
  final DateTime? acceptedAt;
  final double? trustRatingAvg;
  final int trustReviewCount;
  final int trustCompletedDealsCount;
  final bool trustIsRepeatParticipant;
  final bool trustPhoneVerified;
  final String? trustResponseTimeBucket;
  final bool trustIsVerified;
  final String currency;
  final String? preferredBank;
  final String? institutionType;
  final bool isBankAgent;
  final bool showProfessionalTag;

  bool get hasMaskedLender => lenderId.startsWith('public-offer-');
  String? get professionalTag {
    if (!showProfessionalTag) return null;
    if (isBankAgent) {
      if (preferredBank?.isNotEmpty == true) {
        return '${preferredBank!} agent';
      }
      return 'Bank loan agent';
    }
    return switch (institutionType) {
      'bank' => 'Bank',
      'forex_exchange' => 'Forex exchange',
      'sacco' => 'SACCO',
      'company' => 'Company',
      _ => null,
    };
  }

  factory LoanOffer.fromMap(Map<String, dynamic> map) {
    return LoanOffer(
      id: map['id'] as String,
      requestId: map['request_id'] as String,
      lenderId: map['lender_id'] as String,
      offerAmount: (map['offer_amount'] as num?)?.toInt() ?? 0,
      interestRatePct: (map['interest_rate_pct'] as num?)?.toDouble() ?? 0,
      lateFeePct: (map['late_fee_pct'] as num?)?.toDouble() ?? 0,
      repaymentFrequency: map['repayment_frequency'] as String? ?? 'monthly',
      installmentAmount: (map['installment_amount'] as num?)?.toInt() ?? 0,
      proposedExpectations: map['proposed_expectations'] as String?,
      termsLockedAt: map['terms_locked_at'] != null
          ? DateTime.tryParse(map['terms_locked_at'] as String)
          : null,
      status: map['status'] as String? ?? 'pending',
      offeredAt: DateTime.tryParse(map['offered_at'] as String? ?? '') ??
          DateTime.now(),
      acceptedAt: map['accepted_at'] != null
          ? DateTime.tryParse(map['accepted_at'] as String)
          : null,
      trustRatingAvg: (map['trust_rating_avg'] as num?)?.toDouble(),
      trustReviewCount: (map['trust_review_count'] as num?)?.toInt() ?? 0,
      trustCompletedDealsCount:
          (map['trust_completed_deals_count'] as num?)?.toInt() ?? 0,
      trustIsRepeatParticipant:
          map['trust_is_repeat_participant'] as bool? ?? false,
      trustPhoneVerified: map['trust_phone_verified'] as bool? ?? false,
      trustResponseTimeBucket: map['trust_response_time_bucket'] as String?,
      trustIsVerified: map['trust_is_verified'] as bool? ?? false,
      currency: map['currency'] as String? ?? 'UGX',
      preferredBank: map['preferred_bank'] as String?,
      institutionType: map['institution_type'] as String?,
      isBankAgent: map['is_bank_agent'] as bool? ?? false,
      showProfessionalTag: map['show_professional_tag'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, status, offerAmount];
}
