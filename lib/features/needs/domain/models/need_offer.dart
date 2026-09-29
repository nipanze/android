class NeedOffer {
  const NeedOffer({
    required this.id,
    required this.needId,
    this.publicOfferId,
    required this.price,
    required this.currency,
    required this.timelineText,
    required this.message,
    required this.status,
    required this.offeredAt,
    this.isOwnOffer = false,
    this.providerVerificationLevel = 'self_declared',
    this.providerRatingAvg,
    this.providerReviewCount = 0,
    this.providerCompletedDeals = 0,
    this.providerPhoneVerified = false,
  });

  factory NeedOffer.fromMap(Map<String, dynamic> map) {
    return NeedOffer(
      id: map['id'] as String? ?? '',
      needId: map['need_id'] as String? ?? '',
      publicOfferId: map['public_offer_id'] as String?,
      price: (map['price'] as num?)?.toInt() ?? 0,
      currency: map['currency'] as String? ?? 'UGX',
      timelineText: map['timeline_text'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      offeredAt: DateTime.tryParse(
            map['offered_at'] as String? ?? map['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      isOwnOffer: map['is_own_offer'] as bool? ?? false,
      providerVerificationLevel:
          map['provider_verification_level'] as String? ?? 'self_declared',
      providerRatingAvg: (map['provider_rating_avg'] as num?)?.toDouble(),
      providerReviewCount:
          (map['provider_review_count'] as num?)?.toInt() ?? 0,
      providerCompletedDeals:
          (map['provider_completed_deals'] as num?)?.toInt() ?? 0,
      providerPhoneVerified:
          map['provider_phone_verified'] as bool? ?? false,
    );
  }

  final String id;
  final String needId;
  final String? publicOfferId;
  final int price;
  final String currency;
  final String timelineText;
  final String message;
  final String status;
  final DateTime offeredAt;
  final bool isOwnOffer;
  final String providerVerificationLevel;
  final double? providerRatingAvg;
  final int providerReviewCount;
  final int providerCompletedDeals;
  final bool providerPhoneVerified;

  bool get isProviderVerified =>
      providerVerificationLevel == 'provider_verified';
}
