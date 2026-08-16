// lib/features/watchlist/presentation/pages/watchlist_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/watchlist_cubit.dart';
import '../widgets/watchlist_card.dart';

/// Outer shell — provides [WatchlistCubit] so descendants can read it safely.
class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WatchlistCubit>()..load(),
      child: const _WatchlistView(),
    );
  }
}

/// Inner view — consumes [WatchlistCubit]; safe to call context.read in build.
class _WatchlistView extends StatelessWidget {
  const _WatchlistView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isSubscribed =
        user != null && user.subscriptionPlan != SubscriptionPlan.free;

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
                      Text(AppLocalizations.of(context)!.watchlistTitle,
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text(AppLocalizations.of(context)!.watchlistSubtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const Spacer(),
                  BlocBuilder<WatchlistCubit, WatchlistState>(
                    builder: (context, state) {
                      final count =
                          state is WatchlistLoaded ? state.listings.length : 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(
                            AppLocalizations.of(context)!.watchlistSaved(count),
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
              child: Text(
                isSubscribed
                    ? AppLocalizations.of(context)!.watchlistInfoSubscribed
                    : AppLocalizations.of(context)!.watchlistInfoFree,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Expanded(
              child: BlocBuilder<WatchlistCubit, WatchlistState>(
                builder: (context, state) {
                  if (state is WatchlistLoading) {
                    return SingleChildScrollView(
                      child: Column(
                        children: List.generate(
                          3,
                          (i) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: SkeletonBox(
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.watchlistError,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<WatchlistCubit>().load(),
                            child: Text(AppLocalizations.of(context)!.tryAgain),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is WatchlistLoaded) {
                    if (state.listings.isEmpty) {
                      return EmptyState(
                        icon: Icons.star_outline_rounded,
                        title: AppLocalizations.of(context)!.watchlistEmpty,
                        subtitle: AppLocalizations.of(context)!
                            .watchlistEmptySubtitle,
                        action: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            context.go('/marketplace');
                          },
                          child: Text(
                              AppLocalizations.of(context)!.browseMarketplace),
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
                              ScaffoldMessenger.of(context).clearSnackBars();
                              context.push(listing.forex == null
                                  ? '/marketplace/${listing.requestId}'
                                  : '/forex/${listing.requestId}');
                            },
                            onRemove: () {
                              context.read<WatchlistCubit>().remove(
                                    listing.requestId,
                                    forex: listing.forex != null,
                                  );

                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                              scaffoldMessenger.clearSnackBars();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!
                                      .removedFromWatchlist),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: AppLocalizations.of(context)!.undo,
                                    textColor: AppColors.accent,
                                    onPressed: () {
                                      context
                                          .read<WatchlistCubit>()
                                          .add(listing);
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
                    title: AppLocalizations.of(context)!.watchlistEmpty,
                    subtitle:
                        AppLocalizations.of(context)!.watchlistEmptySubtitle,
                    action: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        context.go('/marketplace');
                      },
                      child:
                          Text(AppLocalizations.of(context)!.browseMarketplace),
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
