// lib/features/marketplace/presentation/pages/marketplace_page.dart
// ignore_for_file: directives_ordering

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../discovery/data/discovery_repository.dart';
import '../../../discovery/presentation/cubit/discovery_cubit.dart';
import '../../../discovery/presentation/widgets/discovery_card.dart';
import '../../../needs/data/needs_repository.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import '../../../provider/domain/repositories/provider_repository_interface.dart';
import '../../../provider/domain/entities/provider_capability.dart';
import '../../../provider/domain/entities/provider_category_type.dart';
import '../../../provider/presentation/cubit/capabilities_cubit.dart';
import '../../../provider/presentation/cubit/capabilities_state.dart';
import '../../../watchlist/presentation/cubit/watchlist_cubit.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/marketplace_item.dart';
import '../cubit/marketplace_cubit.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_card_skeleton.dart';
import '../widgets/pro_filters_sheet.dart';
import '../widgets/pro_required_sheet.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({
    super.key,
    this.initialModule,
    this.interestCategorySlugs = const {},
  });

  final MarketplaceModule? initialModule;
  final Set<String> interestCategorySlugs;

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
          create: (_) => DiscoveryCubit(getIt<DiscoveryRepository>())
            ..loadCard(
              country: userCountry,
            ),
        ),
        BlocProvider(
          create: (_) {
            final cubit = getIt<MarketplaceCubit>();
            unawaited(cubit.load(
              country: userCountry,
              module: initialModule,
              interestCategorySlugs: interestCategorySlugs,
            ));
            if (initialModule == null && interestCategorySlugs.isEmpty) {
              unawaited(() async {
                try {
                  final preferences = await getIt<DiscoveryRepository>()
                      .getSavedInterestCategories();
                  if (!cubit.isClosed) {
                    cubit.setPersonalizationCategories(preferences);
                  }
                } catch (error) {
                  OfflineService().reportRequestFailure(error);
                }
              }());
            }
            return cubit;
          },
        ),
        BlocProvider(create: (_) => getIt<WatchlistCubit>()..load()),
        BlocProvider(create: (_) => getIt<CapabilitiesCubit>()..load()),
      ],
      child: BlocListener<NotificationCubit, NotificationState>(
        listenWhen: (previous, current) {
          if (previous is! NotificationLoaded ||
              current is! NotificationLoaded ||
              current.notifications.isEmpty) {
            return false;
          }
          final latest = current.notifications.first;
          final prevIds = previous.notifications.map((n) => n.id).toSet();
          final kind = latest.data?['kind']?.toString();
          return !prevIds.contains(latest.id) &&
              (kind == 'provider_capability_approved' ||
                  kind == 'provider_capability_rejected' ||
                  kind == 'provider_company_document_approved' ||
                  kind == 'provider_company_document_rejected' ||
                  kind == 'provider_role_qualification_approved' ||
                  kind == 'provider_role_qualification_rejected');
        },
        listener: (context, _) {
          unawaited(context.read<CapabilitiesCubit>().load());
        },
        child: _MarketplaceView(country: userCountry),
      ),
    );
  }
}

class _MarketplaceView extends StatelessWidget {
  const _MarketplaceView({required this.country});

  final String country;

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
                                        color: AppColors.accent
                                            .withValues(alpha: 0.30),
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
                ],
              ),
            ),
            // ── Filter / Tabs Row with filter button on far right ────────
            _ModuleFilterRow(
              onProFilterTap: () => _onProFilterTap(context),
            ),
            const _ForYouPreferencesSync(),
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
                      final discoveryCubit = context.read<DiscoveryCubit>();
                      final hasActiveDiscoveryCard =
                          discoveryCubit.state is DiscoveryCardLoaded &&
                              (discoveryCubit.state as DiscoveryCardLoaded)
                                      .template !=
                                  null;
                      final shouldShowMarketDiscoveryPrompt =
                          discoveryCubit.state is! DiscoveryLoading &&
                              !hasActiveDiscoveryCard;

                      if (state.moduleFilter == MarketplaceModule.loan &&
                          !context.read<MarketplaceCubit>().isLendingEnabled) {
                        return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Card(
                                  child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                                Icons.lock_outline_rounded,
                                                color: AppColors.accent),
                                            const SizedBox(height: 10),
                                            const Text(
                                                'Loan requests are for lenders',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            const SizedBox(height: 6),
                                            const Text(
                                                'Turn on I lend to see loan requests in your feed.'),
                                            const SizedBox(height: 12),
                                            FilledButton(
                                                onPressed: () =>
                                                    _enableLending(context),
                                                child: const Text(
                                                    'Turn on I lend')),
                                          ]))),
                            ]);
                      }

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
                                    fontSize: 12.5, color: AppColors.accent),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state.listings.isEmpty) {
                        if (state.proFilterCriteria.isActive) {
                          return const _EmptyProFilter();
                        }
                        return RefreshIndicator(
                          onRefresh: () =>
                              context.read<MarketplaceCubit>().refresh(),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(13, 6, 13, 14),
                            children: [
                              if (state.moduleFilter == null) ...[
                                DiscoveryCard(
                                  country: country,
                                  spacingAfter: true,
                                  cubit: discoveryCubit,
                                ),
                                if (shouldShowMarketDiscoveryPrompt)
                                  _MarketplaceDiscoveryCard(
                                    country: country,
                                    hideOpportunities: state.moduleFilter ==
                                        MarketplaceModule.needs,
                                  ),
                              ],
                              EmptyState(
                                icon: Icons.show_chart_rounded,
                                title: AppLocalizations.of(context)!
                                    .noListingsFound,
                                subtitle: state.moduleFilter ==
                                            MarketplaceModule.needs &&
                                        state.interestCategorySlugs.isNotEmpty
                                    ? 'Your interests are saved for future recommendations.'
                                    : AppLocalizations.of(context)!
                                        .noListingsSubtitle,
                              ),
                              if (state.moduleFilter ==
                                      MarketplaceModule.needs &&
                                  state.interestCategorySlugs.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Center(
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        context.push(AppRoutes.needsCreate),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Create a Need'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      final isForYou = state.moduleFilter == null;
                      final placementHint = state.listings.fold<int>(
                        0,
                        (value, listing) =>
                            value +
                            listing.requestId.codeUnits.fold<int>(
                              0,
                              (sum, unit) => sum + unit,
                            ),
                      );
                      final desiredDiscoveryIndex = 2 + placementHint % 2;
                      final discoveryIndex = isForYou
                          ? (desiredDiscoveryIndex < state.listings.length
                              ? desiredDiscoveryIndex
                              : state.listings.length)
                          : null;
                      final totalCount = isForYou
                          ? state.listings.length + 1
                          : state.listings.length;

                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<MarketplaceCubit>().refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(13, 6, 13, 14),
                          itemCount: totalCount,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (isForYou && index == discoveryIndex) {
                              return Column(
                                key: const ValueKey('marketplace-discovery'),
                                children: [
                                  DiscoveryCard(
                                    country: country,
                                    spacingAfter: true,
                                    cubit: context.read<DiscoveryCubit>(),
                                  ),
                                  if (shouldShowMarketDiscoveryPrompt)
                                    _MarketplaceDiscoveryCard(
                                      country: country,
                                      hideOpportunities: state.moduleFilter ==
                                          MarketplaceModule.needs,
                                    ),
                                ],
                              );
                            }

                            final listingIndex = isForYou &&
                                    discoveryIndex != null
                                ? (index < discoveryIndex ? index : index - 1)
                                : index;
                            final listing = state.listings[listingIndex];
                            return BlocBuilder<WatchlistCubit, WatchlistState>(
                              builder: (context, _) {
                                final watchlist =
                                    context.read<WatchlistCubit>();
                                final isSaved = watchlist.isWatched(
                                  listing.requestId,
                                  module: listing.module,
                                );
                                final marketplaceCubit =
                                    context.read<MarketplaceCubit>();
                                final reason =
                                    marketplaceCubit.forYouReason(listing);
                                final providerIdentityType = marketplaceCubit
                                    .forYouProviderIdentityType(listing);
                                final categoryBadgeColor =
                                    switch (providerIdentityType) {
                                  'individual' => AppColors.proPurple,
                                  'company' => AppColors.accent,
                                  _ => isForYou
                                      ? (reason == null
                                          ? AppColors.accent
                                          : AppColors.warning)
                                      : null,
                                };
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
                                  matchReason: isForYou ? reason : null,
                                  categoryBadgeColor: categoryBadgeColor,
                                  onWatchlistToggle: () {
                                    if (isSaved) {
                                      unawaited(() async {
                                        final removed =
                                            await watchlist.remove(listing);
                                        if (removed ==
                                                WatchlistActionResult.failure &&
                                            context.mounted) {
                                          ScaffoldMessenger.of(context)
                                            ..clearSnackBars()
                                            ..showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  AppLocalizations.of(context)!
                                                      .watchlistError,
                                                ),
                                              ),
                                            );
                                        }
                                      }());
                                    } else {
                                      unawaited(() async {
                                        final added =
                                            await watchlist.add(listing);
                                        if (added ==
                                                WatchlistActionResult.failure &&
                                            context.mounted) {
                                          ScaffoldMessenger.of(context)
                                            ..clearSnackBars()
                                            ..showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  AppLocalizations.of(context)!
                                                      .watchlistError,
                                                ),
                                              ),
                                            );
                                        }
                                      }());
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

Future<void> _enableLending(BuildContext context) async {
  final cubit = context.read<MarketplaceCubit>();
  await (await SharedPreferences.getInstance())
      .setBool('marketplace_i_lend', true);
  cubit.setForYouPreferences(
    interestSlugs: cubit.forYouInterests,
    providerSlugs: cubit.providerCategories,
    providerIdentityTypes: cubit.providerCategoryIdentityTypes,
    iLend: true,
  );
}

class _ForYouPreferencesSync extends StatefulWidget {
  const _ForYouPreferencesSync();

  @override
  State<_ForYouPreferencesSync> createState() => _ForYouPreferencesSyncState();
}

class _ForYouPreferencesSyncState extends State<_ForYouPreferencesSync> {
  @override
  void initState() {
    super.initState();
    unawaited(_sync());
  }

  Future<void> _sync() async {
    try {
      final values = await Future.wait([
        getIt<DiscoveryRepository>().getSavedInterestCategories(),
        getIt<IProviderRepository>().getProviderCapabilities(),
        SharedPreferences.getInstance(),
      ]);
      if (!mounted) return;
      final interests = values[0] as Set<String>;
      final capabilities = values[1] as List<ProviderCapability>;
      final activeCapabilities = capabilities.where((capability) =>
          capability.isActive &&
          !capability.isPaused &&
          (!capability.isWork ||
              capability.metadata['is_role_active'] != false));
      final providerIdentityTypes = <String, String>{};
      for (final capability in activeCapabilities) {
        final categorySlug =
            capability.categorySlug ?? capability.capabilitySlug;
        final identityType = capability.identityType ??
            (capability.isWork ? 'individual' : 'company');
        if (identityType == 'company' ||
            !providerIdentityTypes.containsKey(categorySlug)) {
          providerIdentityTypes[categorySlug] = identityType;
        }
      }
      final providerSlugs = providerIdentityTypes.keys.toSet();
      final prefs = values[2] as SharedPreferences;
      if (!mounted) return;
      context.read<MarketplaceCubit>().setForYouPreferences(
            interestSlugs: interests,
            providerSlugs: providerSlugs,
            providerIdentityTypes: providerIdentityTypes,
            iLend: prefs.getBool('marketplace_i_lend') ?? false,
          );
    } catch (_) {
      // Keep the feed usable if preferences are unavailable offline.
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

enum _DiscoveryPromptKind { addServices, newCategories, opportunities }

class _DiscoveryPrompt {
  const _DiscoveryPrompt({
    required this.kind,
    this.categories = const [],
    this.matchingRequestCount = 0,
  });

  final _DiscoveryPromptKind kind;
  final List<NeedCategory> categories;
  final int matchingRequestCount;
}

class _MarketplaceDiscoveryCard extends StatefulWidget {
  const _MarketplaceDiscoveryCard({
    required this.country,
    required this.hideOpportunities,
  });

  final String country;
  final bool hideOpportunities;

  @override
  State<_MarketplaceDiscoveryCard> createState() =>
      _MarketplaceDiscoveryCardState();
}

class _MarketplaceDiscoveryCardState extends State<_MarketplaceDiscoveryCard> {
  late Future<_DiscoveryPrompt?> _prompt;

  @override
  void initState() {
    super.initState();
    _loadPrompt();
  }

  @override
  void didUpdateWidget(covariant _MarketplaceDiscoveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.country != widget.country ||
        oldWidget.hideOpportunities != widget.hideOpportunities) {
      _loadPrompt();
    }
  }

  void _loadPrompt() {
    _prompt = _fetchPrompt().catchError((Object error, StackTrace stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'marketplace discovery card',
      ));
      return null;
    });
  }

  Future<_DiscoveryPrompt?> _fetchPrompt() async {
    final capabilities =
        await getIt<IProviderRepository>().getProviderCapabilities();
    if (capabilities.isEmpty) {
      return const _DiscoveryPrompt(kind: _DiscoveryPromptKind.addServices);
    }

    final newCategories =
        await getIt<NeedsRepository>().getNewCategoriesForCurrentUser();
    if (newCategories.isNotEmpty) {
      return _DiscoveryPrompt(
        kind: _DiscoveryPromptKind.newCategories,
        categories: newCategories,
      );
    }
    if (widget.hideOpportunities) return null;

    final capabilitySlugs =
        capabilities.map((capability) => capability.capabilitySlug).toSet();
    final categorySlugs = capabilities
        .map((capability) => capability.categorySlug)
        .whereType<String>()
        .toSet();
    final listings = await getIt<MarketplaceRepository>().getListings(
      module: MarketplaceModule.needs,
      country: widget.country,
    );
    final matchingNeeds = listings
        .where((item) => item.needs != null)
        .where((item) {
          final need = item.needs!;
          return need.capabilitySlug != null
              ? capabilitySlugs.contains(need.capabilitySlug)
              : categorySlugs.contains(need.categorySlug);
        })
        .map((item) => item.needs!)
        .toList();
    final uniqueNeeds = {
      for (final need in matchingNeeds) need.requestId: need,
    }.values.toList();
    if (uniqueNeeds.isEmpty) return null;

    final matchingCategories = <String, NeedCategory>{};
    for (final need in uniqueNeeds) {
      matchingCategories.putIfAbsent(
        need.categorySlug,
        () => NeedCategory(
          slug: need.categorySlug,
          name: need.category,
          icon: need.categoryIcon,
        ),
      );
    }

    return _DiscoveryPrompt(
      kind: _DiscoveryPromptKind.opportunities,
      matchingRequestCount: uniqueNeeds.length,
      categories: matchingCategories.values.toList(),
    );
  }

  Future<void> _onTap(_DiscoveryPrompt prompt) async {
    switch (prompt.kind) {
      case _DiscoveryPromptKind.addServices:
        await context.push<void>(AppRoutes.accountServices);
        if (mounted) setState(_loadPrompt);
      case _DiscoveryPromptKind.newCategories:
        try {
          await Future.wait(
            prompt.categories.map(
              (category) => getIt<NeedsRepository>()
                  .recordInterestEvent(category.slug, 'view'),
            ),
          );
        } catch (error, stackTrace) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'marketplace category discovery',
          ));
        }
        if (mounted) {
          await context.push<void>(AppRoutes.accountServices);
          if (mounted) setState(_loadPrompt);
        }
      case _DiscoveryPromptKind.opportunities:
        await context
            .read<MarketplaceCubit>()
            .setModuleFilter(MarketplaceModule.needs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DiscoveryPrompt?>(
      future: _prompt,
      builder: (context, snapshot) {
        final prompt = snapshot.data;
        if (prompt == null ||
            (widget.hideOpportunities &&
                prompt.kind == _DiscoveryPromptKind.opportunities)) {
          return const SizedBox.shrink();
        }

        final l10n = AppLocalizations.of(context)!;
        final localeCode = Localizations.localeOf(context).languageCode;
        final localizedPromptCategories = prompt.categories
            .take(3)
            .map((category) => category.localizedName(localeCode))
            .toList();
        final newCategorySummary = '${localizedPromptCategories.join(', ')}'
            '${prompt.categories.length > 3 ? '…' : ''}';
        final title = switch (prompt.kind) {
          _DiscoveryPromptKind.addServices => l10n.whatCanYouHelpWith,
          _DiscoveryPromptKind.newCategories => l10n.newCategoriesAvailable,
          _DiscoveryPromptKind.opportunities => l10n.peopleLookingForServices,
        };
        final subtitle = switch (prompt.kind) {
          _DiscoveryPromptKind.addServices => l10n.whatCanYouHelpWithSubtitle,
          _DiscoveryPromptKind.newCategories =>
            l10n.newCategoriesAvailableSubtitle(newCategorySummary),
          _DiscoveryPromptKind.opportunities =>
            l10n.matchingNeedsSubtitle(prompt.matchingRequestCount),
        };
        final cta = switch (prompt.kind) {
          _DiscoveryPromptKind.addServices => l10n.addYourServicesCta,
          _DiscoveryPromptKind.newCategories => l10n.exploreNewCategoriesCta,
          _DiscoveryPromptKind.opportunities => l10n.seeOpportunitiesCta,
        };
        final categoryNames = prompt.kind == _DiscoveryPromptKind.opportunities
            ? localizedPromptCategories.take(3).join(' · ')
            : '';
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            );
        final detailStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.58),
            );

        return GestureDetector(
          onTap: () => _onTap(prompt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    prompt.kind == _DiscoveryPromptKind.opportunities
                        ? Icons.campaign_outlined
                        : Icons.handshake_outlined,
                    color: AppColors.accent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      const SizedBox(height: 3),
                      Text(subtitle, style: detailStyle),
                      if (categoryNames.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          categoryNames,
                          style: detailStyle?.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cta,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.accent,
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModuleFilterRow extends StatefulWidget {
  const _ModuleFilterRow({required this.onProFilterTap});
  final VoidCallback onProFilterTap;

  @override
  State<_ModuleFilterRow> createState() => _ModuleFilterRowState();
}

class _ModuleFilterRowState extends State<_ModuleFilterRow> {
  String? _selectedProviderCapabilityId;

  void _selectForYou(BuildContext context) {
    setState(() => _selectedProviderCapabilityId = null);
    context.read<MarketplaceCubit>().setModuleFilter(null);
  }

  Widget _providerServicePill(
    BuildContext context,
    ProviderCapability service, {
    required String identityType,
    required bool selected,
  }) {
    final isIndividual = identityType == 'individual';
    final l10n = AppLocalizations.of(context)!;
    final identityLabel =
        isIndividual ? l10n.providerTypeIndividual : l10n.companyLabel;
    final categoryLabel = service.categoryName?.trim().isNotEmpty == true
        ? service.categoryName!.trim()
        : service.capabilityName?.trim().isNotEmpty == true
            ? service.capabilityName!.trim()
            : service.capabilitySlug;
    return _FilterPill(
      label: _providerServiceLabel(
        service,
        context: context,
        showFullCategoryName: selected,
      ),
      selected: selected,
      accentColor: isIndividual ? AppColors.proPurple : AppColors.accent,
      colorWhenUnselected: true,
      icon:
          isIndividual ? Icons.person_outline_rounded : Icons.business_outlined,
      semanticsLabel: '$categoryLabel, $identityLabel provider service',
      onTap: () {
        setState(() => _selectedProviderCapabilityId = service.id);
        context.read<MarketplaceCubit>().setProviderCategoryFilter(
              categorySlug: service.categorySlug ?? service.capabilitySlug,
              identityType: identityType,
              module: _moduleForProviderService(service),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        final selected = state is MarketplaceLoaded ? state.moduleFilter : null;
        return BlocBuilder<CapabilitiesCubit, CapabilitiesState>(
          builder: (context, capabilitiesState) {
            final services = capabilitiesState is CapabilitiesLoaded
                ? capabilitiesState.capabilities
                    .where((capability) =>
                        capability.isActive &&
                        !capability.isPaused &&
                        (!capability.isWork ||
                            capability.metadata['is_role_active'] != false))
                    .toList()
                : const <ProviderCapability>[];
            final categoryTypes = capabilitiesState is CapabilitiesLoaded
                ? capabilitiesState.categoryTypes
                : const <String, dynamic>{};
            String identityFor(ProviderCapability capability) {
              final categoryType = categoryTypes[capability.categorySlug];
              final resolvedType = switch (categoryType) {
                ProviderCategoryType.individual => 'individual',
                ProviderCategoryType.company => 'company',
                _ => null,
              };
              return capability.identityType ??
                  resolvedType ??
                  (capability.isWork ? 'individual' : 'company');
            }

            final uniqueServices = <ProviderCapability>[];
            final seenProviderCategories = <String>{};
            for (final service in services) {
              final key =
                  '${service.categorySlug ?? service.capabilitySlug}|${identityFor(service)}';
              if (seenProviderCategories.add(key)) {
                uniqueServices.add(service);
              }
            }
            final isLoading = capabilitiesState is CapabilitiesInitial ||
                capabilitiesState is CapabilitiesLoading;
            final loadFailed = capabilitiesState is CapabilitiesError;
            ProviderCapability? selectedProviderService;
            if (selected != null) {
              for (final service in services) {
                if (_moduleForProviderService(service) == selected &&
                    service.id == _selectedProviderCapabilityId) {
                  selectedProviderService = service;
                  break;
                }
              }
              if (selectedProviderService == null) {
                for (final service in services) {
                  if (_moduleForProviderService(service) == selected) {
                    selectedProviderService = service;
                    break;
                  }
                }
              }
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 14, 6),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 18),
                      child: Row(
                        children: isLoading
                            ? [
                                _FilterPill(
                                  label: AppLocalizations.of(context)!
                                      .marketplaceForYou,
                                  icon: Icons.auto_awesome_rounded,
                                  selected: selected == null,
                                  accentColor: AppColors.accent,
                                  onTap: () => _selectForYou(context),
                                ),
                                const SizedBox(width: 6),
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ]
                            : loadFailed
                                ? [
                                    _FilterPill(
                                      label: AppLocalizations.of(context)!
                                          .marketplaceForYou,
                                      icon: Icons.auto_awesome_rounded,
                                      selected: selected == null,
                                      accentColor: AppColors.accent,
                                      onTap: () => _selectForYou(context),
                                    ),
                                    const SizedBox(width: 6),
                                    ActionChip(
                                      label: const Text('Retry services'),
                                      avatar: const Icon(
                                        Icons.refresh_rounded,
                                        size: 16,
                                      ),
                                      onPressed: () => context
                                          .read<CapabilitiesCubit>()
                                          .load(),
                                    ),
                                  ]
                                : services.isEmpty
                                    ? [
                                        _FilterPill(
                                          label: AppLocalizations.of(context)!
                                              .marketplaceForYou,
                                          icon: Icons.auto_awesome_rounded,
                                          selected: selected == null,
                                          accentColor: AppColors.accent,
                                          onTap: () => _selectForYou(context),
                                        ),
                                        const SizedBox(width: 6),
                                        _DottedAddServiceChip(
                                          onTap: () => context
                                              .push(AppRoutes.accountServices),
                                        ),
                                      ]
                                    : [
                                        _FilterPill(
                                          label: AppLocalizations.of(context)!
                                              .marketplaceForYou,
                                          icon: Icons.auto_awesome_rounded,
                                          selected: selected == null,
                                          accentColor: AppColors.accent,
                                          onTap: () => _selectForYou(context),
                                        ),
                                        const SizedBox(width: 6),
                                        for (var i = 0;
                                            i < uniqueServices.length;
                                            i++) ...[
                                          if (i > 0) const SizedBox(width: 6),
                                          _providerServicePill(
                                            context,
                                            uniqueServices[i],
                                            identityType:
                                                identityFor(uniqueServices[i]),
                                            selected: selected ==
                                                    _moduleForProviderService(
                                                        uniqueServices[i]) &&
                                                selectedProviderService?.id ==
                                                    uniqueServices[i].id,
                                          ),
                                        ],
                                      ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ProFilterButton(onTap: widget.onProFilterTap),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DottedAddServiceChip extends StatelessWidget {
  const _DottedAddServiceChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    const addServicePurple = Color(0xFF6D4AFF);

    return Semantics(
      button: true,
      label: l10n.addService,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              height: 28,
              child: Center(
                child: CustomPaint(
                  foregroundPainter: const _DottedRoundedBorderPainter(
                    color: addServicePurple,
                  ),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 17, color: addServicePurple),
                        const SizedBox(width: 5),
                        Text(
                          l10n.addService,
                          maxLines: 1,
                          style: const TextStyle(
                            color: addServicePurple,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DottedRoundedBorderPainter extends CustomPainter {
  const _DottedRoundedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(12),
        ).deflate(0.75),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final metric in border.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 7) {
        final end = (start + 3.5).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DottedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

String _providerServiceLabel(
  ProviderCapability service, {
  BuildContext? context,
  bool showFullCategoryName = false,
}) {
  if (showFullCategoryName && context != null && service.categorySlug != null) {
    return NeedCategory.findBySlug(service.categorySlug!)
        .localizedName(Localizations.localeOf(context).languageCode);
  }
  final category = service.categoryName?.trim();
  if (category != null && category.isNotEmpty) return category;
  if (service.isWork) {
    final roleId = service.metadata['role_id']?.toString().trim();
    if (roleId != null && roleId.isNotEmpty) {
      return roleId
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
    }
  }
  final name = service.capabilityName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return service.capabilitySlug
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

MarketplaceModule _moduleForProviderService(ProviderCapability service) {
  final slugs =
      '${service.capabilitySlug} ${service.categorySlug ?? ''}'.toLowerCase();
  if (slugs.contains('forex') || slugs.contains('currency_exchange')) {
    return MarketplaceModule.forex;
  }
  if (slugs.contains('loan') ||
      slugs.contains('financial') ||
      slugs.contains('microfinance') ||
      slugs.contains('sacco')) {
    return MarketplaceModule.loan;
  }
  return MarketplaceModule.needs;
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    this.icon,
    this.colorWhenUnselected = false,
    this.semanticsLabel,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  final IconData? icon;
  final bool colorWhenUnselected;
  final String? semanticsLabel;

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
        : colorWhenUnselected
            ? accentColor
            : (isDark ? AppColors.text2Dark : AppColors.text2Light);
    final borderColor = selected
        ? accentColor
        : colorWhenUnselected
            ? accentColor.withValues(alpha: 0.38)
            : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: selected,
      child: GestureDetector(
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
                          : (isDark
                              ? AppColors.text2Dark
                              : AppColors.text2Light),
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
