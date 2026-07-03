// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../cubit/watchlist_cubit.dart';
import '../widgets/watchlist_card.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  @override
  void initState() {
    super.initState();
    context.read<WatchlistCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Watchlist',
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text("Listings you're tracking",
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const Spacer(),
                  BlocBuilder<WatchlistCubit, WatchlistState>(
                    builder: (context, state) {
                      final count = state is WatchlistLoaded
                          ? state.listings.length
                          : 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Theme.of(context).dividerColor),
                        ),
                        child: Text('$count saved',
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: const Text(
                'Free for all users. Get notified when bids change, rates improve, or a listing is closing. Subscribe to bid.',
                style: TextStyle(fontSize: 11),
              ),
            ),
            Expanded(
              child:
                  BlocBuilder<WatchlistCubit, WatchlistState>(
                builder: (context, state) {
                  if (state is WatchlistLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: const SkeletonBox(
                              height: 180,
                              width: double.infinity,
                              radius: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is WatchlistError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error loading watchlist',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<WatchlistCubit>().load(),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is WatchlistLoaded) {
                    if (state.listings.isEmpty) {
                      return EmptyState(
                        icon: Icons.star_outline_rounded,
                        title: 'No saved listings',
                        subtitle:
                            'Browse the marketplace and tap "Save to watchlist" on any listing.',
                        action: ElevatedButton(
                          onPressed: () => context.go('/marketplace'),
                          child: const Text('Browse marketplace'),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.listings.length,
                      itemBuilder: (context, index) {
                        final listing = state.listings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: WatchlistCard(
                            listing: listing,
                            onTap: () {
                              context.push(
                                '/listing/${listing.requestId}',
                              );
                            },
                            onRemove: () {
                              context
                                  .read<WatchlistCubit>()
                                  .remove(listing.requestId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Removed from watchlist'),
                                  duration:
                                      const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      // Re-add would require calling add() on repository
                                      // For now, user can re-add from marketplace
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }

                  return EmptyState(
                    icon: Icons.star_outline_rounded,
                    title: 'No saved listings',
                    subtitle:
                        'Browse the marketplace and tap "Save to watchlist" on any listing.',
                    action: ElevatedButton(
                      onPressed: () => context.go('/marketplace'),
                      child: const Text('Browse marketplace'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

