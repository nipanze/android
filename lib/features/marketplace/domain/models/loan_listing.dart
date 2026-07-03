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
    required this.status,
    required this.listedAt,
    required this.expiresAt,
    required this.numberOfOffers,
    this.kycStatus,
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
  final String status;
  final DateTime listedAt;
  final DateTime expiresAt;
  final int numberOfOffers;
  final String? kycStatus;

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
      status: map['status'] as String? ?? 'active',
      listedAt: DateTime.tryParse(map['listed_at'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(map['expires_at'] as String? ?? '') ??
          DateTime.now(),
      numberOfOffers: map['number_of_offers'] as int? ?? 0,
      kycStatus: map['kyc_status'] as String?,
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
    this.proposedExpectations,
    required this.status,
    required this.offeredAt,
    this.acceptedAt,
  });

  final String id;
  final String requestId;
  final String lenderId;
  final int offerAmount;
  final String? proposedExpectations;
  final String status;
  final DateTime offeredAt;
  final DateTime? acceptedAt;

  bool get hasMaskedLender => lenderId.startsWith('public-offer-');

  factory LoanOffer.fromMap(Map<String, dynamic> map) {
    return LoanOffer(
      id: map['id'] as String,
      requestId: map['request_id'] as String,
      lenderId: map['lender_id'] as String,
      offerAmount: (map['offer_amount'] as num?)?.toInt() ?? 0,
      proposedExpectations: map['proposed_expectations'] as String?,
      status: map['status'] as String? ?? 'pending',
      offeredAt: DateTime.tryParse(map['offered_at'] as String? ?? '') ??
          DateTime.now(),
      acceptedAt: map['accepted_at'] != null
          ? DateTime.tryParse(map['accepted_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, status, offerAmount];
}
