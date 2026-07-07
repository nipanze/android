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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marketplace',
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
                            return Row(
                              children: [
                                const LiveDot(),
                                const SizedBox(width: 5),
                                Text(
                                  '$count listings · live',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
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
                      if (state.listings.isEmpty) {
                        return const EmptyState(
                          icon: Icons.show_chart_rounded,
                          title: 'No listings found',
                          subtitle:
                              'Check back soon — new listings appear in real time.',
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<MarketplaceCubit>().refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(13, 1, 13, 14),
                          itemCount: state.listings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
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
            ),
          ],
        ),
      ),
    );
  }
}
