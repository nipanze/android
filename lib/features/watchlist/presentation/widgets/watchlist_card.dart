// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../marketplace/domain/models/loan_listing.dart';

class WatchlistCard extends StatelessWidget {
  const WatchlistCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.onRemove,
  });

  final LoanListing listing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasOffers = listing.numberOfOffers > 0;
    final isDanger = listing.isClosingSoon6h;
    final isWarning = listing.isClosingSoon24h;
    final urgencyColor = isDanger
        ? AppColors.danger
        : isWarning
            ? AppColors.warning
            : null;

    // Urgency border: thick red for 6h, amber for 24h, normal otherwise
    final borderWidth = isDanger
        ? 2.0
        : isWarning
            ? 1.5
            : 1.0;
    final borderColor = urgencyColor ??
        (hasOffers
            ? AppColors.accent.withOpacity(0.6)
            : Theme.of(context).dividerColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: borderWidth),
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
                    backgroundColor: listing.kycStatus == 'verified'
                        ? AppColors.success
                        : AppColors.warning,
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
                if (listing.kycStatus != null)
                  Text(
                    'User verification status: ${listing.kycStatus!.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  )
                else if (hasOffers)
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

            const SizedBox(height: 10),

            // Footer row with time remaining and remove button
            Row(
              children: [
                Text(
                  listing.timeRemainingLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDanger
                        ? AppColors.danger
                        : isWarning
                            ? AppColors.warning
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isWarning || isDanger ? FontWeight.w600 : null,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
