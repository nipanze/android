// lib/features/marketplace/presentation/widgets/listing_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/send_rate_receive_panel.dart';
import '../../../../shared/widgets/trust_badges.dart';
import '../../../marketplace/domain/models/marketplace_item.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.isSaved,
    required this.onWatchlistToggle,
  });

  final MarketplaceItem listing;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback onWatchlistToggle;

  @override
  Widget build(BuildContext context) {
    final fundedFraction = _fundedFraction(listing);
    final loan = listing.loan;
    final forex = listing.forex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progressColor =
        (loan?.numberOfOffers ?? forex?.numberOfOffers ?? 0) > 0
            ? AppColors.accent
            : Theme.of(context).colorScheme.onSurfaceVariant;

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
                        loan?.title ??
                            '${forex!.currencyHeld} to ${forex.currencyNeeded}',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        loan != null
                            ? '${loan.district} · ${loan.durationMonths} ${AppLocalizations.of(context)!.months}'
                            : '${forex!.country} · ${forex.settlementPreference}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isSaved
                      ? AppLocalizations.of(context)!.removeFromWatchlist
                      : AppLocalizations.of(context)!.saveToWatchlist,
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
            if (loan != null) ...[
              Row(
                children: [
                  const _ModuleBadge(label: 'Loan', color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${loan.currency} ${_fmtAmount(loan.requestedAmount)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                loan.purpose,
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
            ] else ...[
              Row(
                children: [
                  const _ModuleBadge(label: 'Forex', color: AppColors.accent),
                  if (forex!.isUrgent || forex.isClosingSoon24h) ...[
                    const SizedBox(width: 6),
                    const _UrgentTag(),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SendRateReceivePanel(listing: forex),
            ],
            const SizedBox(height: 4),
            Text(
              _shortTimeLabel(listing, AppLocalizations.of(context)!),
              style: TextStyle(
                fontSize: 10,
                color: (loan?.isClosingSoon6h ?? forex!.isClosingSoon6h)
                    ? AppColors.danger
                    : (loan?.isClosingSoon24h ?? forex!.isClosingSoon24h)
                        ? AppColors.warning
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            TrustBadgeRow(
              ratingAvg: loan?.trustRatingAvg ?? forex!.trustRatingAvg,
              reviewCount: loan?.trustReviewCount ?? forex!.trustReviewCount,
              completedDealsCount: loan?.trustCompletedDealsCount ??
                  forex!.trustCompletedDealsCount,
              isRepeatParticipant: loan?.trustIsRepeatParticipant ??
                  forex!.trustIsRepeatParticipant,
              phoneVerified:
                  loan?.trustPhoneVerified ?? forex!.trustPhoneVerified,
              responseTimeBucket: loan?.trustResponseTimeBucket ??
                  forex!.trustResponseTimeBucket,
            ),
          ],
        ),
      ),
    );
  }

  double _fundedFraction(MarketplaceItem item) {
    final listing = item.loan;
    if (listing == null) return 0;
    if (listing.numberOfOffers >= 3) return 1;
    if (listing.numberOfOffers <= 0) return 0;
    return (listing.numberOfOffers / 6).clamp(0.0, 0.9);
  }

  String _shortTimeLabel(MarketplaceItem listing, AppLocalizations l10n) {
    final duration =
        listing.loan?.timeRemaining ?? listing.forex!.timeRemaining;
    final expired = listing.loan?.isExpired ?? listing.forex!.isExpired;
    if (expired) return l10n.expired;
    final days = duration.inDays;
    if (days > 0) return l10n.daysLeft(days);
    final hours = duration.inHours;
    if (hours > 0) return l10n.hoursLeft(hours);
    return l10n.minutesLeft(duration.inMinutes);
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

class _ModuleBadge extends StatelessWidget {
  const _ModuleBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _UrgentTag extends StatelessWidget {
  const _UrgentTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '⚡ Urgent',
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
