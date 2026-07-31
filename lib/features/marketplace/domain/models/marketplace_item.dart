import '../../../../shared/models/forex_listing_model.dart';
import 'loan_listing.dart';

enum MarketplaceModule { loan, forex }

class MarketplaceItem {
  const MarketplaceItem.loan(this.loan)
      : forex = null,
        module = MarketplaceModule.loan;

  const MarketplaceItem.forex(this.forex)
      : loan = null,
        module = MarketplaceModule.forex;

  final MarketplaceModule module;
  final LoanListing? loan;
  final ForexListingModel? forex;

  String get requestId => loan?.requestId ?? forex!.requestId;
  DateTime get listedAt => loan?.listedAt ?? forex!.listedAt;
}
