import '../../../../shared/models/forex_listing_model.dart';
import 'loan_listing.dart';

enum MarketplaceModule { loan, forex, needs }

class NeedsListing {
  const NeedsListing({
    required this.requestId,
    required this.title,
    required this.specification,
    required this.category,
    this.categorySlug = 'specialized_products',
    this.categoryIcon = '🔎',
    this.capabilitySlug,
    this.details = const {},
    required this.budget,
    required this.currency,
    required this.location,
    required this.urgency,
    required this.listedAt,
    this.numberOfOffers = 0,
    this.offerCoverageTier = 'no_offers',
    this.expiresAt,
    this.timeRemaining,
    this.trustIsVerified = false,
    this.trustPhoneVerified = false,
    this.trustRatingAvg,
    this.trustReviewCount = 0,
    this.trustCompletedDealsCount = 0,
    this.trustIsRepeatParticipant = false,
  });

  factory NeedsListing.fromMap(Map<String, dynamic> map) {
    final rawDetails = map['details'];
    final Map<String, dynamic> detailsMap;
    if (rawDetails is Map<String, dynamic>) {
      detailsMap = rawDetails;
    } else if (rawDetails is Map) {
      detailsMap = Map<String, dynamic>.from(rawDetails);
    } else {
      detailsMap = const {};
    }

    return NeedsListing(
      requestId: map['request_id'] as String? ?? map['id'] as String,
      title: map['title'] as String? ?? map['item_name'] as String? ?? 'Need',
      specification: map['specification'] as String? ??
          map['description'] as String? ??
          '',
      category:
          map['category'] as String? ?? map['need_type'] as String? ?? 'Specialized Products & Procurement',
      categorySlug: map['category_slug'] as String? ?? 'specialized_products',
      categoryIcon: map['category_icon'] as String? ?? '🔎',
      capabilitySlug: map['capability_slug'] as String?,
      details: detailsMap,
      budget: (map['budget'] as num?)?.toInt() ??
          (map['amount'] as num?)?.toInt() ??
          0,
      currency: map['currency'] as String? ?? 'UGX',
      location: map['location'] as String? ?? map['district'] as String? ?? '',
      urgency: map['urgency'] as String? ?? 'Flexible',
      listedAt: DateTime.tryParse(
            map['listed_at'] as String? ?? map['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      numberOfOffers: (map['number_of_offers'] as num?)?.toInt() ?? 0,
      offerCoverageTier: map['offer_coverage_tier'] as String? ?? 'no_offers',
      expiresAt: DateTime.tryParse(map['expires_at'] as String? ?? ''),
      timeRemaining: map['time_remaining'] as String?,
      trustIsVerified: map['trust_is_verified'] as bool? ??
          map['is_verified'] as bool? ??
          false,
      trustPhoneVerified: map['trust_phone_verified'] as bool? ?? false,
      trustRatingAvg: (map['trust_rating_avg'] as num?)?.toDouble(),
      trustReviewCount: (map['trust_review_count'] as num?)?.toInt() ?? 0,
      trustCompletedDealsCount:
          (map['trust_completed_deals_count'] as num?)?.toInt() ?? 0,
      trustIsRepeatParticipant:
          map['trust_is_repeat_participant'] as bool? ?? false,
    );
  }

  final String requestId;
  final String title;
  final String specification;
  final String category;
  final String categorySlug;
  final String categoryIcon;
  final String? capabilitySlug;
  final Map<String, dynamic> details;
  final int budget;
  final String currency;
  final String location;
  final String urgency;
  final DateTime listedAt;
  final int numberOfOffers;
  final String offerCoverageTier;
  final DateTime? expiresAt;
  final String? timeRemaining;
  final bool trustIsVerified;
  final bool trustPhoneVerified;
  final double? trustRatingAvg;
  final int trustReviewCount;
  final int trustCompletedDealsCount;
  final bool trustIsRepeatParticipant;
}

class MarketplaceItem {
  const MarketplaceItem.loan(this.loan)
      : forex = null,
        needs = null,
        module = MarketplaceModule.loan;

  const MarketplaceItem.forex(this.forex)
      : loan = null,
        needs = null,
        module = MarketplaceModule.forex;

  const MarketplaceItem.needs(this.needs)
      : loan = null,
        forex = null,
        module = MarketplaceModule.needs;

  final MarketplaceModule module;
  final LoanListing? loan;
  final ForexListingModel? forex;
  final NeedsListing? needs;

  String get requestId =>
      loan?.requestId ?? forex?.requestId ?? needs!.requestId;
  DateTime get listedAt => loan?.listedAt ?? forex?.listedAt ?? needs!.listedAt;
}
