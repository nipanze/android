import 'package:equatable/equatable.dart';

class ForexOfferModel extends Equatable {
  const ForexOfferModel({
    required this.id,
    required this.requestId,
    required this.offerMakerId,
    required this.rateOffered,
    required this.amountAvailable,
    this.terms,
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
    this.preferredBank,
    this.institutionType,
    this.isBankAgent = false,
    this.showProfessionalTag = false,
  });

  final String id;
  final String requestId;
  final String offerMakerId;
  final double rateOffered;
  final int amountAvailable;
  final String? terms;
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
  final String? preferredBank;
  final String? institutionType;
  final bool isBankAgent;
  final bool showProfessionalTag;

  bool get hasMaskedOfferMaker => offerMakerId.startsWith('public-offer-');
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

  factory ForexOfferModel.fromMap(Map<String, dynamic> map) {
    return ForexOfferModel(
      id: map['id'] as String? ?? map['offer_id'] as String,
      requestId: map['request_id'] as String,
      offerMakerId:
          map['offer_maker_id'] as String? ?? map['lender_id'] as String? ?? '',
      rateOffered: (map['rate_offered'] as num?)?.toDouble() ?? 0,
      amountAvailable: (map['amount_available'] as num?)?.toInt() ?? 0,
      terms: map['terms'] as String?,
      termsLockedAt: map['terms_locked_at'] != null
          ? DateTime.tryParse(map['terms_locked_at'] as String)
          : null,
      status: map['status'] as String? ??
          map['offer_status'] as String? ??
          'pending',
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
      preferredBank: map['preferred_bank'] as String?,
      institutionType: map['institution_type'] as String?,
      isBankAgent: map['is_bank_agent'] as bool? ?? false,
      showProfessionalTag: map['show_professional_tag'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, status, rateOffered, amountAvailable];
}
