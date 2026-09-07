import '../../../../shared/models/forex_listing_model.dart';
import 'loan_listing.dart';

enum MarketplaceModule { loan, forex, needs }

class NeedsListing {
  const NeedsListing({
    required this.requestId,
    required this.title,
    required this.specification,
    required this.category,
    required this.budget,
    required this.currency,
    required this.location,
    required this.urgency,
    required this.listedAt,
    this.trustIsVerified = false,
  });

  factory NeedsListing.fromMap(Map<String, dynamic> map) {
    return NeedsListing(
      requestId: map['request_id'] as String? ?? map['id'] as String,
      title: map['title'] as String? ?? map['item_name'] as String? ?? 'Need',
      specification: map['specification'] as String? ??
          map['description'] as String? ??
          '',
      category:
          map['category'] as String? ?? map['need_type'] as String? ?? 'Other',
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
      trustIsVerified: map['trust_is_verified'] as bool? ??
          map['is_verified'] as bool? ??
          false,
    );
  }

  final String requestId;
  final String title;
  final String specification;
  final String category;
  final int budget;
  final String currency;
  final String location;
  final String urgency;
  final DateTime listedAt;
  final bool trustIsVerified;
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
