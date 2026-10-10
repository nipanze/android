import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/localization_fallback.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/forex_listing_model.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../domain/models/marketplace_item.dart';
import 'listing_expiry_indicator.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.isSaved,
    required this.onWatchlistToggle,
    this.showMoreActions = true,
    this.moreActionLabel,
    this.onMoreAction,
    this.showDeleteAction = false,
  });

  final MarketplaceItem listing;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback onWatchlistToggle;
  final bool showMoreActions;
  final String? moreActionLabel;
  final VoidCallback? onMoreAction;
  final bool showDeleteAction;

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
    const accent = AppColors.accent;
    final surfaceColor = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final mutedColor =
        isDark ? AppColors.text2Dark : theme.colorScheme.onSurfaceVariant;
    final title = needs?.title ??
        loan?.title ??
        '${forex!.currencyHeld} to ${forex.currencyNeeded}';
    final amount = needs != null
        ? (needs.budget > 0
            ? '${needs.currency} ${_fmtAmount(context, needs.budget)}'
            : l10n.openToOffers)
        : loan != null
            ? '${loan.currency} ${_fmtAmount(context, loan.requestedAmount)}'
            : '${forex!.currencyHeld} ${_fmtAmount(context, forex.amount)}';
    final amountWidget = isForex
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.forexHoldLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${forex.currencyHeld} ${_fmtAmount(context, forex.amount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppFonts.heading,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.forexNeedLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${forex.currencyNeeded} ${_fmtAmount(context, forex.preferredRate != null && forex.preferredRate! > 0 ? (forex.amount * forex.preferredRate!).round() : forex.amount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppFonts.heading,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: needs != null && needs.budget > 0
                  ? theme.colorScheme.onSurface
                  : AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: AppFonts.heading,
              height: 1.05,
            ),
          );
    final description = needs?.specification ??
        loan?.purpose ??
        _forexDescription(forex, context);
    final location =
        needs?.location ?? loan?.district ?? _forexLocation(forex, context);
    final authState = context.watch<AuthBloc>().state;
    final canSeeCollateral = authState is AuthAuthenticated &&
        authState.user.subscriptionPlan == SubscriptionPlan.pro;
    final showCollateral =
        canSeeCollateral && loan != null && loan.hasCollateral;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 9),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final main = _MainListingArea(
                accent: accent,
                moduleLabel: isNeeds
                    ? NeedCategory(
                        slug: needs.categorySlug,
                        name: needs.category,
                        icon: needs.categoryIcon,
                      ).localizedName(
                        Localizations.localeOf(context).languageCode,
                      )
                    : isForex
                        ? l10n.marketplaceForex
                        : l10n.marketplaceLoan,
                moduleIcon: isNeeds
                    ? Icons.search_rounded
                    : isForex
                        ? Icons.currency_exchange_rounded
                        : Icons.account_balance_wallet_outlined,
                expiryIndicator: ListingExpiryIndicator(
                  listedAt: listing.listedAt,
                  expiresAt:
                      loan?.expiresAt ?? forex?.expiresAt ?? needs?.expiresAt,
                ),
                title: title,
                amountWidget: amountWidget,
                isLoan: loan != null,
                location: location,
                verified: loan?.hasCollateral == true,
                mutedColor: mutedColor,
                description: description,
                isSaved: isSaved,
                onWatchlistToggle: onWatchlistToggle,
                showMoreActions: showMoreActions,
                moreActionLabel: moreActionLabel,
                onMoreAction: onMoreAction,
                showDeleteAction: showDeleteAction,
                attributes: [
                  l10n.offersCount(
                    loan?.numberOfOffers ??
                        forex?.numberOfOffers ??
                        needs!.numberOfOffers,
                  ),
                  if (needs != null && needs.urgency.trim().isNotEmpty)
                    needs.urgency,
                  if (forex != null) _forexSettlementLabel(forex, context),
                  if (forex != null &&
                      forex.preferredRate != null &&
                      forex.preferredRate! > 0)
                    'Rate: 1 ${forex.currencyHeld} = ${forex.preferredRate!.toStringAsFixed(2)} ${forex.currencyNeeded}',
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
    return '';
  }

  String _forexSettlementLabel(dynamic forex, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = ForexListingModel.settlementLabelFromPreference(
      forex.settlementPreference,
    );
    return switch (label) {
      'Bank' => l10n.bankLabel,
      'Mobile Money' => l10n.forexSettlementMobileMoney,
      'In person' => l10n.forexSettlementInPerson,
      'Flexible' => l10n.flexibleLabel,
      _ => label,
    };
  }

  String _forexLocation(dynamic forex, BuildContext context) {
    final location = ForexListingModel.locationFromSettlement(
      forex.settlementPreference,
      forex.district,
    );
    return location == 'Nearby'
        ? AppLocalizations.of(context)!.nearbyLabel
        : location;
  }

  String _fmtAmount(BuildContext context, int amount) {
    return NumberFormat.decimalPattern(
      intlLocaleName(Localizations.localeOf(context)),
    ).format(amount);
  }
}

class _MoreActionsButton extends StatelessWidget {
  const _MoreActionsButton({
    required this.isSaved,
    required this.onWatchlistToggle,
    this.moreActionLabel,
    this.onMoreAction,
    required this.showDeleteAction,
  });

  final bool isSaved;
  final VoidCallback onWatchlistToggle;
  final String? moreActionLabel;
  final VoidCallback? onMoreAction;
  final bool showDeleteAction;

  @override
  Widget build(BuildContext context) {
    final action = onMoreAction ?? onWatchlistToggle;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: showDeleteAction
          ? (moreActionLabel ?? '')
          : isSaved
              ? AppLocalizations.of(context)!.removeFromWatchlist
              : AppLocalizations.of(context)!.saveToWatchlist,
      onPressed: action,
      icon: Icon(
        showDeleteAction
            ? Icons.delete_outline_rounded
            : (isSaved ? Icons.star_rounded : Icons.star_border_rounded),
        size: 19,
        color: showDeleteAction
            ? AppColors.danger
            : (isSaved
                ? AppColors.warning
                : (isDark ? AppColors.text3Dark : AppColors.text3Light)),
      ),
    );
  }
}

class _MainListingArea extends StatelessWidget {
  const _MainListingArea({
    required this.accent,
    required this.moduleLabel,
    required this.moduleIcon,
    required this.expiryIndicator,
    required this.title,
    required this.amountWidget,
    required this.isLoan,
    required this.location,
    required this.verified,
    required this.mutedColor,
    required this.description,
    required this.isSaved,
    required this.onWatchlistToggle,
    required this.showMoreActions,
    required this.moreActionLabel,
    required this.onMoreAction,
    required this.showDeleteAction,
    required this.attributes,
  });

  final Color accent;
  final String moduleLabel;
  final IconData moduleIcon;
  final Widget expiryIndicator;
  final String title;
  final Widget amountWidget;
  final bool isLoan;
  final String location;
  final bool verified;
  final Color mutedColor;
  final String description;
  final bool isSaved;
  final VoidCallback onWatchlistToggle;
  final bool showMoreActions;
  final String? moreActionLabel;
  final VoidCallback? onMoreAction;
  final bool showDeleteAction;
  final List<String> attributes;

  IconData _attributeIcon(String attribute) {
    final value = attribute.toLowerCase();
    if (value.contains('equity') || value.contains('bank')) {
      return Icons.account_balance_rounded;
    }
    if (value.contains('mpesa') ||
        value.contains('m-pesa') ||
        value.contains('airtel') ||
        value.contains('mobile')) {
      return Icons.phone_iphone_rounded;
    }
    if (value.contains('person') || value.contains('cash')) {
      return Icons.people_alt_rounded;
    }
    if (value.contains('rate') || value.contains('.')) {
      return Icons.swap_horiz_rounded;
    }
    if (value.contains('offer')) return Icons.chat_bubble_outline_rounded;
    if (value.contains('urgent') || value.contains('flexible')) {
      return Icons.hourglass_bottom_rounded;
    }
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ModuleBadge(
                label: moduleLabel,
                icon: moduleIcon,
                color: accent,
              ),
            ),
            expiryIndicator,
            if (showMoreActions)
              _MoreActionsButton(
                isSaved: isSaved,
                onWatchlistToggle: onWatchlistToggle,
                moreActionLabel: moreActionLabel,
                onMoreAction: onMoreAction,
                showDeleteAction: showDeleteAction,
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            height: 1.12,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.bg3Dark.withValues(alpha: 0.6)
                : AppColors.bg3Light.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.5)
                  : AppColors.borderLight,
            ),
          ),
          child: amountWidget,
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (location.trim().isNotEmpty)
              _MetaIcon(
                icon: Icons.location_on_rounded,
                label: location,
                color: mutedColor,
              ),
            if (verified && isLoan)
              _MetaIcon(
                icon: Icons.shield_rounded,
                label: AppLocalizations.of(context)!.securedCollateralLabel,
                color: AppColors.success,
              ),
            for (final attribute in attributes)
              _MetaIcon(
                icon: _attributeIcon(attribute),
                label: attribute,
                color: mutedColor,
              ),
          ],
        ),
        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.22)),
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
              fontWeight: FontWeight.w600,
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
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
