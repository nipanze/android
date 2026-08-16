import 'package:equatable/equatable.dart';

class ForexListingModel extends Equatable {
  const ForexListingModel({
    required this.requestId,
    this.requesterId,
    required this.currencyHeld,
    required this.currencyNeeded,
    required this.amount,
    required this.country,
    required this.settlementPreference,
    this.preferredRate,
    this.termsLockedAt,
    required this.status,
    required this.numberOfOffers,
    this.rateCoverageTier,
    required this.listedAt,
    required this.expiresAt,
    this.kycStatus,
    this.trustRatingAvg,
    this.trustReviewCount = 0,
    this.trustCompletedDealsCount = 0,
    this.trustIsRepeatParticipant = false,
    this.trustPhoneVerified = false,
    this.trustResponseTimeBucket,
    this.trustIsVerified = false,
  });

  final String requestId;
  final String? requesterId;
  final String currencyHeld;
  final String currencyNeeded;
  final int amount;
  final String country;
  final String settlementPreference;
  final double? preferredRate;
  final DateTime? termsLockedAt;
  final String status;
  final int numberOfOffers;
  final String? rateCoverageTier;
  final DateTime listedAt;
  final DateTime expiresAt;
  final String? kycStatus;
  final double? trustRatingAvg;
  final int trustReviewCount;
  final int trustCompletedDealsCount;
  final bool trustIsRepeatParticipant;
  final bool trustPhoneVerified;
  final String? trustResponseTimeBucket;
  final bool trustIsVerified;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  bool get isClosingSoon24h =>
      timeRemaining.inHours < 24 && !timeRemaining.isNegative;
  bool get isClosingSoon6h =>
      timeRemaining.inHours < 6 && !timeRemaining.isNegative;
  bool get isExpired => timeRemaining.isNegative;

  int get receiveEstimate =>
      preferredRate == null ? 0 : (amount * preferredRate!).round();

  factory ForexListingModel.fromMap(Map<String, dynamic> map) {
    return ForexListingModel(
      requestId: map['request_id'] as String,
      requesterId: map['requester_id'] as String?,
      currencyHeld: map['currency_held'] as String? ?? 'UGX',
      currencyNeeded: map['currency_needed'] as String? ?? 'USD',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      country: map['country'] as String? ?? 'UG',
      settlementPreference: map['settlement_preference'] as String? ?? '',
      preferredRate: (map['preferred_rate'] as num?)?.toDouble(),
      termsLockedAt: map['terms_locked_at'] != null
          ? DateTime.tryParse(map['terms_locked_at'] as String)
          : null,
      status: map['status'] as String? ?? 'active',
      numberOfOffers: (map['number_of_offers'] as num?)?.toInt() ?? 0,
      rateCoverageTier: map['rate_coverage_tier'] as String?,
      listedAt: DateTime.tryParse(map['listed_at'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(map['expires_at'] as String? ?? '') ??
          DateTime.now(),
      kycStatus: map['kyc_status'] as String?,
      trustRatingAvg: (map['trust_rating_avg'] as num?)?.toDouble(),
      trustReviewCount: (map['trust_review_count'] as num?)?.toInt() ?? 0,
      trustCompletedDealsCount:
          (map['trust_completed_deals_count'] as num?)?.toInt() ?? 0,
      trustIsRepeatParticipant:
          map['trust_is_repeat_participant'] as bool? ?? false,
      trustPhoneVerified: map['trust_phone_verified'] as bool? ?? false,
      trustResponseTimeBucket: map['trust_response_time_bucket'] as String?,
      trustIsVerified: map['trust_is_verified'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [requestId, requesterId, status, numberOfOffers];
}
