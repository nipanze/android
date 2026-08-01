// lib/features/marketplace/presentation/pages/marketplace_page.dart
// ignore_for_file: directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import '../../../watchlist/presentation/cubit/watchlist_cubit.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../cubit/marketplace_cubit.dart';
import '../../domain/models/marketplace_item.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_card_skeleton.dart';
import '../widgets/pro_filters_sheet.dart';
import '../widgets/pro_required_sheet.dart';
import '../../../../l10n/app_localizations.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<MarketplaceCubit>()..load()),
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
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
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
                              ?.copyWith(fontSize: 22),
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
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (proActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.purple
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.filtered,
                                      style: const TextStyle(
                                        color: AppColors.purple,
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
                  // ── Pro filter icon button (Option B) ─────────────────
                  _ProFilterButton(onTap: () => _onProFilterTap(context)),
                  const SizedBox(width: 6),
                  // ── Notification bell ─────────────────────────────────
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, state) {
                      final unread =
                          state is NotificationLoaded ? state.unreadCount : 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                size: 18,
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
                ],
              ),
            ),
            const _ModuleFilterRow(),
            // ── Listing feed ─────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.72),
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
                                  color: AppColors.purple,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.applyingFilters,
                                style: const TextStyle(
                                    fontSize: 12.5, color: AppColors.purple),
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
                          title: AppLocalizations.of(context)!.noListingsFound,
                          subtitle:
                              AppLocalizations.of(context)!.noListingsSubtitle,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<MarketplaceCubit>().refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(13, 1, 13, 14),
                          itemCount: state.listings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final listing = state.listings[index];
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
                                        ? '/marketplace/${listing.requestId}'
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

class _ModuleFilterRow extends StatelessWidget {
  const _ModuleFilterRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        final selected = state is MarketplaceLoaded ? state.moduleFilter : null;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
          child: Row(
            children: [
              _FilterPill(
                label: 'All',
                selected: selected == null,
                accentColor: AppColors.accent,
                onTap: () =>
                    context.read<MarketplaceCubit>().setModuleFilter(null),
              ),
              const SizedBox(width: 6),
              _FilterPill(
                label: 'Loans',
                icon: Icons.payments_rounded,
                selected: selected == MarketplaceModule.loan,
                accentColor: AppColors.success,
                onTap: () => context
                    .read<MarketplaceCubit>()
                    .setModuleFilter(MarketplaceModule.loan),
              ),
              const SizedBox(width: 6),
              _FilterPill(
                label: 'Forex',
                icon: Icons.currency_exchange_rounded,
                selected: selected == MarketplaceModule.forex,
                accentColor: AppColors.purple,
                onTap: () => context
                    .read<MarketplaceCubit>()
                    .setModuleFilter(MarketplaceModule.forex),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellColor =
        selected ? accentColor.withValues(alpha: 0.10) : Colors.transparent;
    final textColor = accentColor.withValues(alpha: selected ? 1 : 0.95);
    final borderColor = selected
        ? accentColor.withValues(alpha: 0.9)
        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.16);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: shellColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color:
                        accentColor.withValues(alpha: selected ? 0.16 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: textColor,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 12,
                color: accentColor.withValues(alpha: selected ? 1 : 0.95),
              ),
            ],
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

        return SizedBox(
          width: 34,
          height: 34,
          child: Tooltip(
            message: 'Pro Advanced Filters',
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? AppColors.purple.withValues(alpha: 0.18)
                          : AppColors.purple.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasActiveFilters
                            ? AppColors.purple
                            : AppColors.purple.withValues(alpha: 0.35),
                        width: hasActiveFilters ? 1.3 : 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: AppColors.purple,
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
                          color: AppColors.purple,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list_off_rounded,
                color: AppColors.purple,
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
                foregroundColor: AppColors.purple,
                side: const BorderSide(color: AppColors.purple),
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
