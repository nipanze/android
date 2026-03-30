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
    final hasActiveBids = listing.numberOfBids > 0;
    final borderColor = hasActiveBids
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
                RiskBadge.fromString(listing.riskCategory),
              ],
            ),

            const SizedBox(height: 8),

            // Amount
            UgxAmount(listing.requestedAmount, fontSize: 20),

            const SizedBox(height: 8),

            // Bid row
            Row(
              children: [
                Text(
                  'Max ${listing.maxInterestRate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 6),
                Text('·', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 6),
                if (hasActiveBids)
                  Text(
                    '${listing.numberOfBids} bid${listing.numberOfBids != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  )
                else
                  Text(
                    'No bids yet',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const Spacer(),
                if (listing.bestBidRate != null)
                  Text(
                    'Best: ${listing.bestBidRate!.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 11,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Bid activity bar (bid-count based — no money totals)
            _BidActivityBar(bidCount: listing.numberOfBids),

            const SizedBox(height: 5),

            // Footer row
            Row(
              children: [
                Text(
                  hasActiveBids
                      ? '${listing.numberOfBids} bid${listing.numberOfBids != 1 ? 's' : ''} placed'
                      : 'No bids yet',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
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

// ─── Bid Activity Bar ─────────────────────────────────────────────────────────
// Shows lender competition level by bid count — never by money amounts.
// 0 bids = empty, 5+ bids = full. Platform is non-custodial; no totals held.

class _BidActivityBar extends StatelessWidget {
  const _BidActivityBar({required this.bidCount});

  final int bidCount;

  static const _maxBidsForFullBar = 5;

  @override
  Widget build(BuildContext context) {
    final fraction = (bidCount / _maxBidsForFullBar).clamp(0.0, 1.0);
    final color = bidCount >= 4
        ? AppColors.success
        : bidCount >= 2
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
