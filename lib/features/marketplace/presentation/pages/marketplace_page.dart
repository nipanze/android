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
      ],
      child: _MarketplaceView(country: userCountry),
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
            _ForYouPreferencesRow(key: _ForYouPreferencesRow.editKey),
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
                              if (state.moduleFilter == null &&
                                  context
                                      .read<MarketplaceCubit>()
                                      .forYouInterests
                                      .isEmpty)
                                Card(
                                  child: ListTile(
                                    leading:
                                        const Icon(Icons.interests_outlined),
                                    title: const Text('Pick interests'),
                                    subtitle: const Text(
                                        'Choose topics to personalize For You.'),
                                    trailing: TextButton(
                                      onPressed: () => _ForYouPreferencesRow
                                          .editKey.currentState
                                          ?._edit(),
                                      child: const Text('Choose'),
                                    ),
                                  ),
                                ),
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
                                final reason = context
                                    .read<MarketplaceCubit>()
                                    .forYouReason(listing);
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ListingCard(
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
                                          unawaited(() async {
                                            final removed =
                                                await watchlist.remove(listing);
                                            if (removed ==
                                                    WatchlistActionResult
                                                        .failure &&
                                                context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                ..clearSnackBars()
                                                ..showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppLocalizations.of(
                                                              context)!
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
                                                    WatchlistActionResult
                                                        .failure &&
                                                context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                ..clearSnackBars()
                                                ..showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .watchlistError,
                                                    ),
                                                  ),
                                                );
                                            }
                                          }());
                                        }
                                      },
                                    ),
                                    if (isForYou && reason != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 4, left: 10),
                                        child: Text(reason,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.w600)),
                                      )
                                  ],
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
    iLend: true,
  );
}

class _ForYouPreferencesRow extends StatefulWidget {
  const _ForYouPreferencesRow({super.key});

  static final editKey = GlobalKey<_ForYouPreferencesRowState>();

  @override
  State<_ForYouPreferencesRow> createState() => _ForYouPreferencesRowState();
}

class _ForYouPreferencesRowState extends State<_ForYouPreferencesRow> {
  static const _choices = <String, String>{
    'machinery_equipment': 'Equipment',
    'transport_logistics': 'Logistics',
    'professional_services': 'Services',
    'specialized_products': 'Procurement',
    'energy_utilities': 'Solar',
    'agriculture_agribusiness': 'Farming',
    'education_training': 'Education',
    'forex': 'Forex',
  };
  Set<String> _interests = {};
  Set<String> _offers = {};
  bool _lends = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final discovery = getIt<DiscoveryRepository>();
      final values = await Future.wait([
        discovery.getSavedInterestCategories(),
        getIt<IProviderRepository>().getProviderCapabilities(),
        SharedPreferences.getInstance(),
      ]);
      final prefs = values[2] as SharedPreferences;
      if (!mounted) return;
      setState(() {
        _interests =
            (values[0] as Set<String>).intersection(_choices.keys.toSet());
        _offers = (values[1] as List<ProviderCapability>)
            .where((capability) => capability.isActive)
            .map((capability) =>
                capability.categorySlug ?? capability.capabilitySlug)
            .toSet();
        _lends = prefs.getBool('marketplace_i_lend') ?? true;
      });
      _syncCubit();
    } catch (_) {
      // Keep the feed usable if preferences are unavailable offline.
    }
  }

  void _syncCubit() => context.read<MarketplaceCubit>().setForYouPreferences(
        interestSlugs: _interests,
        providerSlugs: _offers,
        iLend: _lends,
      );

  Future<void> _edit() async {
    final selected = Set<String>.from(_interests);
    var lends = _lends;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          StatefulBuilder(builder: (context, setSheetState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personalize For You',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 18),
                  const Text('I’m interested in',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _choices.entries
                          .map((entry) => FilterChip(
                                label: Text(entry.value),
                                selected: selected.contains(entry.key),
                                onSelected: (value) => setSheetState(() => value
                                    ? selected.add(entry.key)
                                    : selected.remove(entry.key)),
                              ))
                          .toList()),
                  const SizedBox(height: 18),
                  const Text('I can offer',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                      'From Provider Services. Services are set per category.'),
                  const SizedBox(height: 7),
                  Wrap(
                      spacing: 6,
                      children: _offers
                          .map((slug) => Chip(
                              label: Text(
                                  _choices[slug] ?? slug.replaceAll('_', ' '))))
                          .toList()),
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('I lend'),
                      value: lends,
                      onChanged: (value) => setSheetState(() => lends = value)),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          child: const Text('Save'))),
                ]),
          ),
        );
      }),
    );
    if (result != true || !mounted) return;
    try {
      final repository = getIt<DiscoveryRepository>();
      final previous = (await repository.getSavedInterestCategories())
          .intersection(_choices.keys.toSet());
      await repository.removeInterestCategories(previous.difference(selected));
      await repository.saveInterestCategories(selected.difference(previous));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('marketplace_i_lend', lends);
      if (!mounted) return;
      setState(() {
        _interests = selected;
        _lends = lends;
      });
      _syncCubit();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save preferences: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MarketplaceCubit, MarketplaceState>(
        builder: (context, state) {
          if (state is MarketplaceLoaded && state.moduleFilter != null) {
            return const SizedBox.shrink();
          }
          final labels = [
            ..._offers.map((slug) =>
                'Offer: ${_choices[slug] ?? slug.replaceAll('_', ' ')}'),
            ..._interests
                .map((slug) => _choices[slug] ?? slug.replaceAll('_', ' ')),
            if (_lends) 'I lend',
          ];
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 14, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('For you:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 6),
                Expanded(
                    child: labels.isEmpty
                        ? const Text('General feed',
                            style: TextStyle(fontSize: 12, color: Colors.grey))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                                children: labels
                                    .map((label) => Padding(
                                          padding:
                                              const EdgeInsets.only(right: 5),
                                          child: Chip(
                                              label: Text(label,
                                                  style: const TextStyle(
                                                      fontSize: 10)),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              padding: EdgeInsets.zero),
                                        ))
                                    .toList()))),
                TextButton(onPressed: _edit, child: const Text('Edit')),
              ]),
              if (state is MarketplaceLoaded && state.moduleFilter == null)
                const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                        'Personalization ranks matching posts. Who can see a post is decided separately; audience access is enforced on the server. Build notes: saved account interests, Provider Services categories, and I lend preference power this feed.',
                        style: TextStyle(fontSize: 10, color: Colors.grey))),
            ]),
          );
        },
      );
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
                        label: AppLocalizations.of(context)!.marketplaceForYou,
                        icon: Icons.auto_awesome_rounded,
                        selected: selected == null,
                        accentColor: AppColors.accent,
                        onTap: () => context
                            .read<MarketplaceCubit>()
                            .setModuleFilter(null),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label: AppLocalizations.of(context)!.marketplaceLoans,
                        icon: Icons.account_balance_wallet_outlined,
                        selected: selected == MarketplaceModule.loan,
                        accentColor: AppColors.accent,
                        onTap: () => context
                            .read<MarketplaceCubit>()
                            .setModuleFilter(MarketplaceModule.loan),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label: AppLocalizations.of(context)!.marketplaceForex,
                        icon: Icons.currency_exchange_rounded,
                        selected: selected == MarketplaceModule.forex,
                        accentColor: const Color(0xFF06B6D4),
                        onTap: () => context
                            .read<MarketplaceCubit>()
                            .setModuleFilter(MarketplaceModule.forex),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label: AppLocalizations.of(context)!.marketplaceNeeds,
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
