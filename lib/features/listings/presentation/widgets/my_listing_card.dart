// lib/features/listings/presentation/widgets/my_listing_card.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/models/my_listing.dart';

class MyListingCard extends StatelessWidget {
  const MyListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.onCancel,
    this.onViewAgreement,
  });

  final MyListing listing;
  final VoidCallback onTap;
  final VoidCallback onCancel;
  final VoidCallback? onViewAgreement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final borderRadius = BorderRadius.circular(8);
    final effectiveOnTap = listing.isContracted ? onViewAgreement : onTap;
    final hasMoreActions =
        listing.isActive || (listing.isContracted && onViewAgreement != null);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: _borderColor(context)),
      ),
      child: InkWell(
        onTap: effectiveOnTap,
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 30, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.business_center_outlined,
                          size: 19,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (listing.isSponsored) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.purple
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: AppColors.purple
                                              .withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      l10n?.sponsoredLabel ?? 'Sponsored',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.purple,
                                      ),
                                    ),
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    listing.title,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
                      if (hasMoreActions)
                        PopupMenuButton<_ListingAction>(
                          tooltip: 'More actions',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                              width: 28, height: 28),
                          icon: const Icon(Icons.more_vert, size: 19),
                          onSelected: (action) {
                            switch (action) {
                              case _ListingAction.cancel:
                                onCancel();
                              case _ListingAction.viewAgreement:
                                onViewAgreement?.call();
                            }
                          },
                          itemBuilder: (_) => [
                            if (listing.isActive)
                              const PopupMenuItem(
                                value: _ListingAction.cancel,
                                child: Text('Cancel request'),
                              ),
                            if (listing.isContracted && onViewAgreement != null)
                              const PopupMenuItem(
                                value: _ListingAction.viewAgreement,
                                child: Text('View deal'),
                              ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Amount
                  CurrencyAmount(listing.requestedAmount,
                      currency: listing.currency, fontSize: 19),

                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 9),

                  // Request metrics
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RequestMetric(
                          icon: Icons.people_outline_rounded,
                          value:
                              '${listing.numberOfOffers} ${listing.numberOfOffers == 1 ? 'Offer' : 'Offers'}',
                          color: listing.numberOfOffers > 0
                              ? AppColors.success
                              : null,
                        ),
                      ),
                      Expanded(
                        child: _RequestMetric(
                          icon: listing.hasCollateral
                              ? Icons.verified_user_outlined
                              : Icons.shield_outlined,
                          value: listing.hasCollateral
                              ? 'Secured'
                              : 'No collateral',
                        ),
                      ),
                      Expanded(
                        child: _RequestMetric(
                          icon: Icons.schedule_outlined,
                          value: listing.isActive
                              ? listing.timeRemainingLabel
                              : listing.status.name,
                          color:
                              listing.isClosingSoon ? AppColors.danger : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _borderColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }
}

enum _ListingAction { cancel, viewAgreement }

class _RequestMetric extends StatelessWidget {
  const _RequestMetric({
    required this.value,
    required this.icon,
    this.color,
  });

  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final foreground = color ?? muted;
    return Row(
      children: [
        Icon(icon, size: 17, color: foreground),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ListingStatus.active => ('Active', AppColors.success),
      ListingStatus.contracted => ('Contracted', AppColors.accent),
      ListingStatus.expired => ('Expired', AppColors.text2Dark),
      ListingStatus.cancelled => ('Cancelled', AppColors.danger),
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
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
