// lib/features/marketplace/presentation/pages/marketplace_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../cubit/marketplace_cubit.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_card_skeleton.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MarketplaceCubit>()..load(),
      child: const _MarketplaceView(),
    );
  }
}

class _MarketplaceView extends StatelessWidget {
  const _MarketplaceView();

  static const _filters = [
    ('all', 'All'),
    ('low', 'Low risk'),
    ('yield', 'High yield'),
    ('closing', 'Closing soon'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marketplace',
                          style: Theme.of(context).textTheme.headlineMedium),
                      BlocBuilder<MarketplaceCubit, MarketplaceState>(
                        builder: (context, state) {
                          final count = state is MarketplaceLoaded
                              ? state.listings.length
                              : 0;
                          return Row(
                            children: [
                              const LiveDot(),
                              const SizedBox(width: 4),
                              Text(
                                '$count listings · live',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push(AppRoutes.notifications),
                  ),
                ],
              ),
            ),

            // Filter pills
            BlocBuilder<MarketplaceCubit, MarketplaceState>(
              buildWhen: (prev, curr) => curr is MarketplaceLoaded,
              builder: (context, state) {
                final active = state is MarketplaceLoaded ? state.activeFilter : 'all';
                return SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _filters.map((f) {
                      final isOn = f.$1 == active;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f.$2),
                          selected: isOn,
                          onSelected: (_) =>
                              context.read<MarketplaceCubit>().load(filter: f.$1),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isOn ? Colors.white : null,
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          selectedColor: AppColors.accent,
                          side: BorderSide(
                            color: isOn
                                ? AppColors.accent
                                : Theme.of(context).dividerColor,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Feed
            Expanded(
              child: BlocBuilder<MarketplaceCubit, MarketplaceState>(
                builder: (context, state) {
                  if (state is MarketplaceLoading || state is MarketplaceInitial) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, __) => const ListingCardSkeleton(),
                    );
                  }

                  if (state is MarketplaceError) {
                    return ErrorState(
                      message: state.message,
                      onRetry: () => context.read<MarketplaceCubit>().refresh(),
                    );
                  }

                  if (state is MarketplaceLoaded) {
                    if (state.listings.isEmpty) {
                      return const EmptyState(
                        icon: Icons.show_chart_rounded,
                        title: 'No listings found',
                        subtitle: 'Check back soon — new listings appear in real time.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => context.read<MarketplaceCubit>().refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        itemCount: state.listings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return ListingCard(
                            listing: state.listings[index],
                            onTap: () => context.push(
                              '/marketplace/${state.listings[index].requestId}',
                            ),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
