// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/models/loan_listing.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final LoanListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasOffers = listing.numberOfOffers > 0;
    final borderColor = hasOffers
        ? AppColors.accent.withOpacity(0.6)
        : Theme.of(context).dividerColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${listing.district} · ${listing.durationMonths} months',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (listing.kycStatus != null)
                   Badge(
                    label: Text(listing.kycStatus!.toUpperCase()),
                    backgroundColor: listing.kycStatus == 'verified' ? AppColors.success : AppColors.warning,
                   ),
              ],
            ),

            const SizedBox(height: 8),

            // Amount
            UgxAmount(listing.requestedAmount, fontSize: 20),

            const SizedBox(height: 8),

            // Offer row
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.purpose,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasOffers)
                  Text(
                    '${listing.numberOfOffers} offer${listing.numberOfOffers != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  )
                else
                  Text(
                    'No offers yet',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Activity bar
            _OfferActivityBar(offerCount: listing.numberOfOffers),

            const SizedBox(height: 5),

            // Footer row
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.incomeSource,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  listing.timeRemainingLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: listing.isClosingSoon6h
                        ? AppColors.danger
                        : listing.isClosingSoon24h
                            ? AppColors.warning
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferActivityBar extends StatelessWidget {
  const _OfferActivityBar({required this.offerCount});

  final int offerCount;

  static const _maxOffersForFullBar = 5;

  @override
  Widget build(BuildContext context) {
    final fraction = (offerCount / _maxOffersForFullBar).clamp(0.0, 1.0);
    final color = offerCount >= 4
        ? AppColors.success
        : offerCount >= 2
            ? AppColors.warning
            : AppColors.text2Dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 3,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
