// lib/features/marketplace/presentation/widgets/listing_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/send_rate_receive_panel.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

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
    final theme = Theme.of(context);
    final isForex = forex != null;
    final moduleColor = isForex ? AppColors.purple : AppColors.success;
    final surfaceColor = isDark ? AppColors.bg2Dark : theme.colorScheme.surface;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.borderLight;
    final mutedColor =
        isDark ? const Color(0xFFA6ABB7) : theme.colorScheme.onSurfaceVariant;
    final progressColor =
        (loan?.numberOfOffers ?? forex?.numberOfOffers ?? 0) > 0
            ? AppColors.accent
            : Theme.of(context).colorScheme.onSurfaceVariant;
    final authState = context.watch<AuthBloc>().state;
    final canSeeCollateral = authState is AuthAuthenticated &&
        authState.user.subscriptionPlan == SubscriptionPlan.pro;
    final showCollateralBadge =
        canSeeCollateral && loan != null && loan.hasCollateral;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
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
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ModuleBadge(
                        label: isForex ? 'Forex' : 'Loan',
                        color: moduleColor,
                      ),
                      if (loan != null)
                        Text(
                          '${loan.district} · ${loan.durationMonths} ${AppLocalizations.of(context)!.months}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: mutedColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        _ForexHeaderLabel(
                          settlementPreference: forex!.settlementPreference,
                          color: mutedColor,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isSaved
                      ? AppLocalizations.of(context)!.removeFromWatchlist
                      : AppLocalizations.of(context)!.saveToWatchlist,
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isSaved ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 22,
                    color: isSaved
                        ? AppColors.warning
                        : isDark
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onWatchlistToggle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              loan?.title ??
                  '${forex!.currencyHeld} to ${forex.currencyNeeded}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.12,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            if (loan != null) ...[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${loan.currency} ${_fmtAmount(loan.requestedAmount)}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                loan.purpose,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: mutedColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              _FundedBar(
                fraction: fundedFraction,
                color: progressColor,
              ),
            ] else ...[
              Text(
                'Exchange ${_currencySymbol(forex!.currencyHeld)}${_fmtAmount(forex.amount)} to ${forex.currencyNeeded}${forex.preferredRate != null ? ' at preferred rate' : ''}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: mutedColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 9),
              SendRateReceivePanel(listing: forex),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (loan?.isSponsored == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.sponsoredLabel ?? 'Sponsored',
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
                    _shortTimeLabel(listing, AppLocalizations.of(context)!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: (loan?.isClosingSoon24h ?? forex!.isClosingSoon24h)
                        ? AppColors.danger
                        : mutedColor,
                    ),
                  ),
                ),
                if (showCollateralBadge) ...[
                  const SizedBox(width: 8),
                  _SecuredBadge(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _currencySymbol(String code) {
    return switch (code) {
      'USD' => '\$',
      'EUR' => '€',
      'GBP' => '£',
      _ => '$code ',
    };
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

class _SecuredBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const color = AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            'Secured',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleBadge extends StatelessWidget {
  const _ModuleBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForexHeaderLabel extends StatelessWidget {
  const _ForexHeaderLabel({
    required this.settlementPreference,
    required this.color,
  });

  final String settlementPreference;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final parts = _splitSettlement(settlementPreference);

    return Text.rich(
      TextSpan(
        children: [
          if (parts.city != null) ...[
            TextSpan(
              text: parts.city,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            TextSpan(
              text: ' · ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.76),
              ),
            ),
          ],
          TextSpan(
            text: parts.method,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  _SettlementParts _splitSettlement(String value) {
    final pieces = value.split(',');
    if (pieces.length < 2) {
      return _SettlementParts(method: value.trim());
    }

    final city = pieces.last.trim();
    final method = pieces.sublist(0, pieces.length - 1).join(',').trim();
    return _SettlementParts(
      city: city.isEmpty ? null : city,
      method: method.isEmpty ? value.trim() : method,
    );
  }
}

class _SettlementParts {
  const _SettlementParts({required this.method, this.city});

  final String method;
  final String? city;
}

class _FundedBar extends StatelessWidget {
  const _FundedBar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 5,
        backgroundColor:
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.09),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
