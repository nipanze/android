// lib/features/marketplace/presentation/pages/marketplace_page.dart
// ignore_for_file: directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import '../../../watchlist/presentation/cubit/watchlist_cubit.dart';
import '../../domain/models/marketplace_item.dart';
import '../cubit/marketplace_cubit.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_card_skeleton.dart';
import '../widgets/pro_filters_sheet.dart';
import '../widgets/pro_required_sheet.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Resolve user's country code for filtering — defaults to 'UG'.
    final authState = context.read<AuthBloc>().state;
    final userCountry = authState is AuthAuthenticated
        ? authState.user.country
        : EastAfricaCountries.defaultCountry.code;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<MarketplaceCubit>()..load(country: userCountry),
        ),
        BlocProvider(create: (_) => getIt<WatchlistCubit>()..load()),
      ],
      child: const _MarketplaceView(),
    );
  }
}

class _MarketplaceView extends StatelessWidget {
  const _MarketplaceView();

  // ── Pro filter button tap handler ───────────────────────────────────────

  void _onProFilterTap(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isPro = authState is AuthAuthenticated &&
        authState.user.subscriptionPlan == SubscriptionPlan.pro;

    if (!isPro) {
      showProRequiredSheet(context);
      return;
    }

    showProFiltersSheet(
      context,
      cubit: context.read<MarketplaceCubit>(),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 8),
              child: Row(
                children: [
                  // Title + live count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.marketplaceTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        BlocBuilder<MarketplaceCubit, MarketplaceState>(
                          builder: (context, state) {
                            final count = state is MarketplaceLoaded
                                ? state.listings.length
                                : 0;
                            final proActive = state is MarketplaceLoaded &&
                                state.proFilterCriteria.isActive;
                            return Row(
                              children: [
                                const LiveDot(),
                                const SizedBox(width: 5),
                                Text(
                                  AppLocalizations.of(context)!
                                      .listingsLive(count),
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (proActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.accent.withValues(alpha: 0.30),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.filtered,
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // ── Notification bell ─────────────────────────────────
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, state) {
                      final unread =
                          state is NotificationLoaded ? state.unreadCount : 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                size: 22,
                              ),
                              onPressed: () =>
                                  context.push(AppRoutes.notifications),
                            ),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  // ── Compact + Add Service button ──────────────────────
                  InkWell(
                    onTap: () => context.push(AppRoutes.accountServices),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.accent,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            AppLocalizations.of(context)!.addService,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Filter / Tabs Row with filter button on far right ────────
            _ModuleFilterRow(
              onProFilterTap: () => _onProFilterTap(context),
            ),
            // ── Listing feed ─────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: BlocBuilder<MarketplaceCubit, MarketplaceState>(
                  builder: (context, state) {
                    if (state is MarketplaceLoading ||
                        state is MarketplaceInitial) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(13, 1, 13, 14),
                        itemCount: 4,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, __) => const ListingCardSkeleton(),
                      );
                    }

                    if (state is MarketplaceError) {
                      return ErrorState(
                        message: state.message,
                        onRetry: () =>
                            context.read<MarketplaceCubit>().refresh(),
                      );
                    }

                    if (state is MarketplaceLoaded) {
                      // Subtle loading overlay while Pro filter RPC is in flight.
                      if (state.proFilterActive) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.applyingFilters,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.accent),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state.listings.isEmpty) {
                        if (state.proFilterCriteria.isActive) {
                          return const _EmptyProFilter();
                        }
                        return EmptyState(
                          icon: Icons.show_chart_rounded,
                          title:
                              AppLocalizations.of(context)!.noListingsFound,
                          subtitle: AppLocalizations.of(context)!
                              .noListingsSubtitle,
                        );
                      }

                      // Discovery card is index 0; listings start at index 1.
                      final totalCount = state.listings.length + 1;

                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<MarketplaceCubit>().refresh(),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(13, 6, 13, 14),
                          itemCount: totalCount,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _DiscoveryPromptCard(
                                onTap: () => context
                                    .push(AppRoutes.accountServices),
                              );
                            }

                            final listing = state.listings[index - 1];
                            return BlocBuilder<WatchlistCubit, WatchlistState>(
                              builder: (context, _) {
                                final watchlist =
                                    context.read<WatchlistCubit>();
                                final isSaved =
                                    watchlist.isWatched(listing.requestId);
                                return ListingCard(
                                  listing: listing,
                                  onTap: () => context.push(
                                    listing.forex == null
                                        ? listing.needs == null
                                            ? '/marketplace/${listing.requestId}'
                                            : '/marketplace/needs/${listing.requestId}'
                                        : '/forex/${listing.requestId}',
                                  ),
                                  isSaved: isSaved,
                                  onWatchlistToggle: () {
                                    if (isSaved) {
                                      watchlist.remove(
                                        listing.requestId,
                                        forex: listing.forex != null,
                                      );
                                    } else {
                                      watchlist.add(listing);
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Discovery prompt card ─────────────────────────────────────────────────────

class _DiscoveryPromptCard extends StatelessWidget {
  const _DiscoveryPromptCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Left: capability icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handshake_outlined,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Middle: text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.whatCanYouHelpWith,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppLocalizations.of(context)!.whatCanYouHelpWithSubtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Right: neutral arrow icon
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isDark ? AppColors.bg3Dark : AppColors.bg3Light,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleFilterRow extends StatelessWidget {
  const _ModuleFilterRow({required this.onProFilterTap});
  final VoidCallback onProFilterTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        final selected = state is MarketplaceLoaded ? state.moduleFilter : null;
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 14, 6),
          child: Row(
            children: [
              // Scrollable filter pills
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 18),
                  child: Row(
                    children: [
                      _FilterPill(
                        label:
                            AppLocalizations.of(context)!.marketplaceForYou,
                        icon: Icons.auto_awesome_rounded,
                        selected: selected == null,
                        accentColor: AppColors.accent,
                        onTap: () => context
                            .read<MarketplaceCubit>()
                            .setModuleFilter(null),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label:
                            AppLocalizations.of(context)!.marketplaceLoans,
                        icon: Icons.account_balance_wallet_outlined,
                        selected: selected == MarketplaceModule.loan,
                        accentColor: AppColors.accent,
                        onTap: () => context
                            .read<MarketplaceCubit>()
                            .setModuleFilter(MarketplaceModule.loan),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label:
                            AppLocalizations.of(context)!.marketplaceForex,
                        icon: Icons.currency_exchange_rounded,
                        selected: selected == MarketplaceModule.forex,
                        accentColor: const Color(0xFF06B6D4),
                        onTap: () => context
                            .read<MarketplaceCubit>()
                            .setModuleFilter(MarketplaceModule.forex),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label:
                            AppLocalizations.of(context)!.marketplaceNeeds,
                        icon: Icons.search_rounded,
                        selected: selected == MarketplaceModule.needs,
                        accentColor: AppColors.warning,
                        onTap: () => context
                            .read<MarketplaceCubit>()
                            .setModuleFilter(MarketplaceModule.needs),
                      ),
                    ],
                  ),
                ),
              ),
              // Filter button pinned to far right of the row
              const SizedBox(width: 8),
              _ProFilterButton(onTap: onProFilterTap),
            ],
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Unselected: neutral bg + neutral text. Selected: solid accent.
    final shellColor = selected
        ? accentColor
        : (isDark ? AppColors.bg2Dark : AppColors.bg2Light);
    final textColor = selected
        ? Colors.white
        : (isDark ? AppColors.text2Dark : AppColors.text2Light);
    final borderColor = selected
        ? accentColor
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 28, minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: shellColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: textColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pro filter icon button ────────────────────────────────────────────────────

class _ProFilterButton extends StatelessWidget {
  const _ProFilterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        final hasActiveFilters =
            state is MarketplaceLoaded && state.proFilterCriteria.isActive;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SizedBox(
          width: 32,
          height: 32,
          child: Tooltip(
            message: AppLocalizations.of(context)!.proAdvancedFilters,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? AppColors.accent.withValues(alpha: 0.14)
                          : (isDark ? AppColors.bg3Dark : AppColors.bg3Light),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasActiveFilters
                            ? AppColors.accent.withValues(alpha: 0.60)
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                        width: hasActiveFilters ? 1.3 : 1,
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: hasActiveFilters
                          ? AppColors.accent
                          : (isDark ? AppColors.text2Dark : AppColors.text2Light),
                    ),
                  ),
                  // Active-filter dot indicator
                  if (hasActiveFilters)
                    Positioned(
                      right: 3,
                      top: 3,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state when Pro filter has no results ────────────────────────────────

class _EmptyProFilter extends StatelessWidget {
  const _EmptyProFilter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bg3Dark : AppColors.bg3Light,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off_rounded,
                color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context)!.noMatches,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.noMatchesSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              icon: const Icon(Icons.tune_rounded, size: 14),
              label: Text(AppLocalizations.of(context)!.adjustFilters),
              onPressed: () => showProFiltersSheet(
                context,
                cubit: context.read<MarketplaceCubit>(),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
