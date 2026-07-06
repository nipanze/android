import 'package:equatable/equatable.dart';

enum ListingStatus { pendingKyc, active, contracted, expired, cancelled }

class MyListing extends Equatable {
  const MyListing({
    required this.id,
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
    required this.numberOfOffers,
    required this.listedAt,
    required this.expiresAt,
    this.contractedAt,
    this.cancelledAt,
  });

  final String id;
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
  final ListingStatus status;
  final int numberOfOffers;
  final DateTime listedAt;
  final DateTime expiresAt;
  final DateTime? contractedAt;
  final DateTime? cancelledAt;

  bool get isActive => status == ListingStatus.active;
  bool get isContracted => status == ListingStatus.contracted;
  bool get isExpired => status == ListingStatus.expired;
  bool get isCancelled => status == ListingStatus.cancelled;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  bool get isClosingSoon =>
      timeRemaining.inHours < 24 && !timeRemaining.isNegative;
  bool get hasExpired => timeRemaining.isNegative;

  String get timeRemainingLabel {
    if (hasExpired || !isActive) return '';
    final d = timeRemaining;
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m left';
    return '${d.inMinutes}m left';
  }

  factory MyListing.fromMap(Map<String, dynamic> map) {
    return MyListing(
      id: map['id'] as String,
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
      status: _statusFromString(map['status'] as String? ?? 'active'),
      numberOfOffers: map['number_of_offers'] as int? ?? 0,
      listedAt: DateTime.tryParse(map['listed_at'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(map['expires_at'] as String? ?? '') ??
          DateTime.now(),
      contractedAt: map['contracted_at'] != null
          ? DateTime.tryParse(map['contracted_at'] as String)
          : null,
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.tryParse(map['cancelled_at'] as String)
          : null,
    );
  }

  static ListingStatus _statusFromString(String s) {
    switch (s) {
      case 'pending_kyc':
        return ListingStatus.pendingKyc;
      case 'contracted':
        return ListingStatus.contracted;
      case 'expired':
        return ListingStatus.expired;
      case 'cancelled':
        return ListingStatus.cancelled;
      default:
        return ListingStatus.active;
    }
  }

  @override
  List<Object?> get props => [id, status, numberOfOffers];
}
