import 'package:equatable/equatable.dart';

class ForexListingModel extends Equatable {
  const ForexListingModel({
    required this.requestId,
    this.requesterId,
    required this.currencyHeld,
    required this.currencyNeeded,
    required this.amount,
    required this.country,
    required this.district,
    required this.settlementPreference,
    this.settlementMethod,
    this.settlementDetails,
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
  final String district;
  final String settlementPreference;
  final String? settlementMethod;
  final String? settlementDetails;
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
    final rawPreference =
        (map['settlement_preference'] as String?)?.trim() ?? '';
    final method = (map['settlement_method'] as String?)?.trim();
    final details = (map['settlement_details'] as String?)?.trim();

    String effectivePreference = rawPreference;
    if (effectivePreference.isEmpty && method != null && method.isNotEmpty) {
      switch (method) {
        case 'bank':
          effectivePreference = details != null && details.isNotEmpty
              ? 'Bank transfer — $details'
              : 'Bank transfer';
          break;
        case 'mobile_money':
          effectivePreference = details != null && details.isNotEmpty
              ? 'Mobile money — $details'
              : 'Mobile money';
          break;
        case 'in_person':
          effectivePreference = details != null && details.isNotEmpty
              ? 'In person — $details'
              : 'In person';
          break;
        default:
          effectivePreference = details != null && details.isNotEmpty
              ? 'Other — $details'
              : 'Other';
      }
    }

    return ForexListingModel(
      requestId: map['request_id'] as String,
      requesterId: map['requester_id'] as String?,
      currencyHeld: map['currency_held'] as String? ?? 'UGX',
      currencyNeeded: map['currency_needed'] as String? ?? 'USD',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      country: map['country'] as String? ?? 'UG',
      district:
          map['district'] as String? ?? map['location'] as String? ?? 'Other',
      settlementPreference: effectivePreference,
      settlementMethod: method,
      settlementDetails: details,
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

  static String settlementLabelFromPreference(String? settlementPreference) {
    final raw = (settlementPreference ?? '').trim();
    if (raw.isEmpty) return 'Flexible';

    final cleaned = _stripLocationFromSettlement(raw);
    final provider = _extractSettlementProvider(cleaned);
    if (provider.isNotEmpty) return provider;

    final value = cleaned.toLowerCase();
    if (value.contains('equity')) return 'Equity Bank';
    if (value.contains('mpesa') || value.contains('m-pesa') || value.contains('m pesa')) {
      return 'M-Pesa';
    }
    if (value.contains('airtel')) return 'Airtel Money';
    if (value.contains('bank')) return 'Bank';
    if (value.contains('mobile')) return 'Mobile Money';
    if (value.contains('person') || value.contains('cash') || value.contains('pickup')) {
      return 'In person';
    }
    return _cleanSettlementText(cleaned);
  }

  static String locationFromSettlement(
    String? settlementPreference,
    String? district,
  ) {
    final explicitDistrict = (district ?? '').trim();
    if (explicitDistrict.isNotEmpty && explicitDistrict.toLowerCase() != 'other') {
      return explicitDistrict;
    }

    final raw = (settlementPreference ?? '').trim();
    if (raw.isEmpty) return 'Nearby';

    final city = _extractSettlementLocation(raw);
    return city.isNotEmpty ? city : 'Nearby';
  }

  static String _stripLocationFromSettlement(String raw) {
    final normalized = raw.trim();
    final commaIndex = normalized.lastIndexOf(',');
    if (commaIndex > -1 && commaIndex < normalized.length - 1) {
      return normalized.substring(0, commaIndex).trim();
    }
    return normalized;
  }

  static String _extractSettlementProvider(String raw) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(raw);
    if (match == null) return '';

    final provider = match.group(1)?.trim() ?? '';
    if (provider.isEmpty) return '';
    return provider;
  }

  static String _extractSettlementLocation(String raw) {
    final normalized = raw.trim();
    final commaIndex = normalized.lastIndexOf(',');
    if (commaIndex > -1 && commaIndex < normalized.length - 1) {
      return normalized.substring(commaIndex + 1).trim();
    }

    final match = RegExp(r'\)\s*([A-Za-z][A-Za-z0-9 .-]+)$').firstMatch(normalized);
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }

    return '';
  }

  static String _cleanSettlementText(String raw) {
    var text = raw.trim();
    text = text
        .replaceAll(RegExp(r'\s*[:|/]\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.startsWith('via ')) {
      text = text.substring(4).trim();
    }
    if (text.startsWith('to ')) {
      text = text.substring(3).trim();
    }
    return text;
  }

  @override
  List<Object?> get props => [requestId, requesterId, status, numberOfOffers];
}
