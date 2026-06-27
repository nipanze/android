// lib/features/marketplace/presentation/pages/marketplace_page.dart
// ignore_for_file: directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
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
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, state) {
                      final unread = state is NotificationLoaded
                          ? state.unreadCount : 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () => context.push(AppRoutes.notifications),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 8, top: 8,
                              child: Container(
                                width: 8, height: 8,
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

            const SizedBox(height: 8),

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