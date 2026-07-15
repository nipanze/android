// lib/features/marketplace/presentation/widgets/listing_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../marketplace/domain/models/loan_listing.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.isSaved,
    required this.onWatchlistToggle,
  });

  final LoanListing listing;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback onWatchlistToggle;

  @override
  Widget build(BuildContext context) {
    final hasOffers = listing.numberOfOffers > 0;
    final fundedFraction = _fundedFraction(listing);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progressColor = hasOffers
        ? AppColors.accent
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final fundedLabel = hasOffers
        ? '${listing.numberOfOffers} offer${listing.numberOfOffers == 1 ? '' : 's'}'
        : 'No bids yet';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A2A28)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE1E1DD),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
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
                IconButton(
                  tooltip:
                      isSaved ? 'Remove from watchlist' : 'Save to watchlist',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isSaved ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isSaved
                        ? AppColors.accent
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onWatchlistToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'UGX ${_fmtAmount(listing.requestedAmount)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
