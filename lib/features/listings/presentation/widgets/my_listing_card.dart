import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/models/my_listing.dart';

class MyListingCard extends StatelessWidget {
  const MyListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.onCancel,
  });

  final MyListing listing;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor(context)),
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
                            fontSize: 13, fontWeight: FontWeight.w600),
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
                _StatusBadge(listing.status),
              ],
            ),

            const SizedBox(height: 8),

            // Amount
            UgxAmount(listing.requestedAmount, fontSize: 19),

            const SizedBox(height: 8),

            // Offer count row
            Row(
              children: [
                if (listing.numberOfOffers > 0) ...[
                  const Icon(Icons.how_to_vote_outlined,
                      size: 12, color: AppColors.success),
                  const SizedBox(width: 3),
                  Text(
                    '${listing.numberOfOffers} offer${listing.numberOfOffers != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success),
                  ),
                ] else
                  Text('No offers yet',
                      style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  '${listing.durationMonths} months',
                  style: const TextStyle(fontFamily: AppFonts.body, fontSize: 10),
                ),
              ],
            ),

            // Time remaining (active only)
            if (listing.isActive && listing.timeRemainingLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 11,
                  color: listing.isClosingSoon
                      ? AppColors.danger
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  listing.timeRemainingLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: listing.isClosingSoon
                        ? AppColors.danger
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ]),
            ],

            // Actions (active only — contracted listings not shown here)
            if (listing.isActive) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                    child: const Text('View offers'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Cancel'),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Color _borderColor(BuildContext context) {
    if (listing.isActive && listing.numberOfOffers > 0) {
      return AppColors.accent.withValues(alpha: 0.5);
    }
    return Theme.of(context).dividerColor;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ListingStatus.active     => ('Active',      AppColors.success),
      ListingStatus.contracted => ('Contracted',  AppColors.accent),
      ListingStatus.expired    => ('Expired',     AppColors.text2Dark),
      ListingStatus.cancelled  => ('Cancelled',   AppColors.danger),
      ListingStatus.pendingKyc => ('Pending KYC', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}