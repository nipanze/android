import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/marketplace_item.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loan = listing.loan;
    final forex = listing.forex;
    final needs = listing.needs;
    final isForex = forex != null;
    final isNeeds = needs != null;
    final accent = isNeeds
        ? const Color(0xFFF59E0B)
        : isForex
            ? const Color(0xFF06B6D4)
        : AppColors.accent;
    final surfaceColor = isDark
      ? AppColors.bg2Dark
      : theme.colorScheme.surfaceContainerHighest;
    final borderColor = isDark
        ? accent.withValues(alpha: 0.95)
        : AppColors.accent.withValues(alpha: 0.22);
    final mutedColor =
        isDark ? AppColors.text2Dark : theme.colorScheme.onSurfaceVariant;
    final title = needs?.title ??
        loan?.title ??
        '${forex!.currencyHeld} to ${forex.currencyNeeded}';
    final amount = needs != null
        ? (needs.budget > 0
            ? '${needs.currency} ${_fmtAmount(context, needs.budget)}'
            : l10n.marketplaceNeeded)
        : loan != null
            ? '${loan.currency} ${_fmtAmount(context, loan.requestedAmount)}'
            : '${forex!.currencyHeld} ${_fmtAmount(context, forex.amount)}';
    final description = needs?.specification ??
        loan?.purpose ??
        _forexDescription(forex, context);
    final location = needs?.location ??
        loan?.district ??
        _settlementCity(forex!.settlementPreference);
    final isVerified = needs?.trustIsVerified ??
        loan?.trustIsVerified ??
        forex?.trustIsVerified ??
        false;
    final authState = context.watch<AuthBloc>().state;
    final canSeeCollateral = authState is AuthAuthenticated &&
        authState.user.subscriptionPlan == SubscriptionPlan.pro;
    final showCollateral =
        canSeeCollateral && loan != null && loan.hasCollateral;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final main = _MainListingArea(
                accent: accent,
                moduleLabel: isNeeds
                    ? l10n.marketplaceNeeds
                    : isForex
                        ? l10n.marketplaceForex
                        : l10n.marketplaceLoan,
                moduleIcon: isNeeds
                    ? Icons.inventory_2_rounded
                    : isForex
                        ? Icons.currency_exchange_rounded
                        : Icons.widgets_rounded,
                posted: _postedAgo(context, listing.listedAt),
                title: title,
                amount: amount,
                isLoan: loan != null,
                location: location,
                verified: isVerified,
                mutedColor: mutedColor,
                description: description,
                isSaved: isSaved,
                onWatchlistToggle: onWatchlistToggle,
                attributes: [
                  if (needs != null) needs.category,
                  if (needs != null) needs.urgency,
                  if (loan != null) '${loan.durationMonths} ${l10n.months}',
                  if (forex != null && forex.preferredRate != null)
                    forex.preferredRate!.toStringAsFixed(2),
                  if (showCollateral && loan.collateralPreview != null)
                    loan.collateralPreview!,
                ],
              );

              return Column(
                children: [
                  Align(alignment: Alignment.centerLeft, child: main),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _forexDescription(dynamic forex, BuildContext context) {
    return '${forex.settlementPreference}. ${forex.currencyNeeded} ${AppLocalizations.of(context)!.marketplaceNeeded.toLowerCase()}';
  }

  String _settlementCity(String value) {
    final pieces = value.split(',');
    final city = pieces.isEmpty ? value.trim() : pieces.last.trim();
    return city.isEmpty ? value : city;
  }

  String _postedAgo(BuildContext context, DateTime listedAt) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(listedAt);
    if (diff.inDays <= 0) return l10n.today;
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    final weeks = (diff.inDays / 7).floor();
    return weeks <= 1 ? l10n.weekAgo : l10n.weeksAgo(weeks);
  }

  String _fmtAmount(BuildContext context, int amount) {
    return NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(amount);
  }
}

class _MoreActionsButton extends StatelessWidget {
  const _MoreActionsButton({
    required this.isSaved,
    required this.onWatchlistToggle,
  });

  final bool isSaved;
  final VoidCallback onWatchlistToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 19,
        color: AppColors.accent,
      ),
      onSelected: (_) => onWatchlistToggle(),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'toggle',
          child: Text(
            isSaved ? l10n.removeFromWatchlist : l10n.saveToWatchlist,
          ),
        ),
      ],
    );
  }
}

class _MainListingArea extends StatelessWidget {
  const _MainListingArea({
    required this.accent,
    required this.moduleLabel,
    required this.moduleIcon,
    required this.posted,
    required this.title,
    required this.amount,
    required this.isLoan,
    required this.location,
    required this.verified,
    required this.mutedColor,
    required this.description,
    required this.isSaved,
    required this.onWatchlistToggle,
    required this.attributes,
  });

  final Color accent;
  final String moduleLabel;
  final IconData moduleIcon;
  final String posted;
  final String title;
  final String amount;
  final bool isLoan;
  final String location;
  final bool verified;
  final Color mutedColor;
  final String description;
  final bool isSaved;
  final VoidCallback onWatchlistToggle;
  final List<String> attributes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: 9,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ModuleBadge(
                    label: moduleLabel,
                    icon: moduleIcon,
                    color: accent,
                  ),
                  _MetaIcon(
                    icon: Icons.schedule_rounded,
                    label: posted,
                    color: mutedColor,
                  ),
                ],
              ),
            ),
            _MoreActionsButton(
              isSaved: isSaved,
              onWatchlistToggle: onWatchlistToggle,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: accent,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MetaIcon(
              icon: Icons.location_on_rounded,
              label: location,
              color: mutedColor,
            ),
            if (verified && isLoan)
              const _MetaIcon(
                icon: Icons.shield_rounded,
                label: 'Secured',
                color: AppColors.success,
              ),
            for (final attribute in attributes)
              _MetaIcon(
                icon: Icons.calendar_month_rounded,
                label: attribute,
                color: mutedColor,
              ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: mutedColor,
            fontSize: 13,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _ModuleBadge extends StatelessWidget {
  const _ModuleBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.95)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
