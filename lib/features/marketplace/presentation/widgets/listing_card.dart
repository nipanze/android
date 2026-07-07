import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/loan_listing.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final LoanListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasOffers = listing.numberOfOffers > 0;
    final fundedFraction = _fundedFraction(listing);
    final fundedLabel = fundedFraction >= 1
        ? 'Fully funded'
        : '${(fundedFraction * 100).round()}% funded';
    final progressColor =
        fundedFraction >= 1 ? AppColors.success : AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${listing.district} · ${listing.durationMonths} months',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _OfferChip(offerCount: listing.numberOfOffers),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'UGX ${_fmtAmount(listing.requestedAmount)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: AppFonts.body,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              listing.purpose,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.76),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 7),
            _FundedBar(
              fraction: fundedFraction,
              color: progressColor,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  hasOffers ? fundedLabel : 'No bids yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: progressColor,
                      ),
                ),
                const Spacer(),
                Text(
                  _shortTimeLabel(listing),
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

  double _fundedFraction(LoanListing listing) {
    if (listing.numberOfOffers >= 3) return 1;
    if (listing.numberOfOffers <= 0) return 0;
    return (listing.numberOfOffers / 6).clamp(0.0, 0.9);
  }

  String _shortTimeLabel(LoanListing listing) {
    if (listing.isExpired) return 'Expired';
    final days = listing.timeRemaining.inDays;
    if (days > 0) return '${days}d left';
    final hours = listing.timeRemaining.inHours;
    if (hours > 0) return '${hours}h left';
    return '${listing.timeRemaining.inMinutes}m left';
  }

  String _fmtAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _OfferChip extends StatelessWidget {
  const _OfferChip({required this.offerCount});

  final int offerCount;

  @override
  Widget build(BuildContext context) {
    final hasOffers = offerCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasOffers
            ? const Color(0xFF053A08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        hasOffers
            ? '$offerCount offer${offerCount == 1 ? '' : 's'}'
            : '0 offers',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: hasOffers
              ? AppColors.success
              : Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

class _FundedBar extends StatelessWidget {
  const _FundedBar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 3,
        backgroundColor: Theme.of(context).colorScheme.surface,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
