import 'package:flutter/material.dart';

import '../../../marketplace/domain/models/marketplace_item.dart';
import '../../../marketplace/presentation/widgets/listing_card.dart';

class WatchlistCard extends StatelessWidget {
  const WatchlistCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.onRemove,
  });

  final MarketplaceItem listing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListingCard(
      listing: listing,
      onTap: onTap,
      isSaved: true,
      onWatchlistToggle: onRemove,
    );
  }
}
