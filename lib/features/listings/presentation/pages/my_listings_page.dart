// lib/features/listings/presentation/pages/my_listings_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/models/my_listing.dart';
import '../cubit/my_listings_cubit.dart';
import '../widgets/my_listing_card.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MyListingsCubit>()..load(),
      child: const _MyListingsView(),
    );
  }
}

class _MyListingsView extends StatelessWidget {
  const _MyListingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My requests',
                    style: Theme.of(context).textTheme.headlineMedium),
                Text('Your loan listings',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              const Spacer(),
              BlocBuilder<MyListingsCubit, MyListingsState>(
                builder: (context, state) {
                  if (state is! MyListingsLoaded) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'New request',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context.push(AppRoutes.listingCreate),
                  );
                },
              ),
            ]),
          ),

          Expanded(
            child: BlocConsumer<MyListingsCubit, MyListingsState>(
              listener: (context, state) {
                if (state is MyListingsError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.danger,
                  ));
                }
              },
              builder: (context, state) {
                if (state is MyListingsInitial || state is MyListingsLoading) {
                  return _LoadingSkeleton();
                }
                if (state is MyListingsError) {
                  return ErrorState(
                    message: state.message,
                    onRetry: () => context.read<MyListingsCubit>().refresh(),
                  );
                }
                if (state is MyListingsLoaded) {
                  if (state.listings.isEmpty) return _EmptyRequestState();
                  return _ListingsBody(listings: state.listings);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Listings body ────────────────────────────────────────────────────────────

class _ListingsBody extends StatelessWidget {
  const _ListingsBody({required this.listings});
  final List<MyListing> listings;

  List<MyListing> get _active => listings.where((l) => l.isActive).toList();
  // contracted count — shown as banner pointing to Positions tab
  int get _contracted => listings.where((l) => l.isContracted).toList().length;
  List<MyListing> get _closed =>
      listings.where((l) => l.isExpired || l.isCancelled).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<MyListingsCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        children: [
          if (_active.isNotEmpty) ...[
            SectionHeader('Active · ${_active.length}'),
            ..._active.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MyListingCard(
                    listing: l,
                    onTap: () => context.push('/marketplace/${l.id}'),
                    onCancel: () => _confirmCancel(context, l),
                  ),
                )),
          ],
          // Banner pointing contracted listings to Positions tab
          if (_contracted > 0) ...[
            GestureDetector(
              onTap: () => context.go(AppRoutes.positions),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.handshake_outlined, size: 16, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    '$_contracted contracted listing${_contracted > 1 ? 's' : ''} — view in Positions',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.success),
                  )),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.success),
                ]),
              ),
            ),
          ],
          if (_active.isEmpty) ...[
            const SizedBox(height: 12),
            _NewRequestCard(),
          ],
          if (_closed.isNotEmpty) ...[
            SectionHeader('Closed · ${_closed.length}'),
            ..._closed.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MyListingCard(listing: l, onTap: () {}, onCancel: () {}),
                )),
          ],
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, MyListing listing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel listing?'),
        content: Text(
          'This will remove "${listing.title}" from the marketplace. '
          'Any pending bids will be rejected. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MyListingsCubit>().cancelListing(listing.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cancel listing'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyRequestState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 32),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: const Icon(Icons.request_page_outlined,
              color: AppColors.accent, size: 32),
        ),
        const SizedBox(height: 20),
        Text('No loan requests yet',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Post a request and lenders will compete to offer you the best rate.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () => context.push(AppRoutes.listingCreate),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create your first request'),
        ),
        const SizedBox(height: 28),
        _HowItWorksCard(),
      ]),
    );
  }
}

// ─── New request prompt (inline when no active listings) ──────────────────────

class _NewRequestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.listingCreate),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.add_circle_outline_rounded,
              color: AppColors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('New loan request',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
            Text('Post another request to the marketplace',
                style: Theme.of(context).textTheme.bodySmall),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.accent, size: 18),
        ]),
      ),
    );
  }
}

// ─── How it works ─────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  static const _steps = [
    (Icons.edit_note_rounded, AppColors.accent,
        'Post your request',
        'Set the amount, duration, and your maximum acceptable interest rate.'),
    (Icons.how_to_vote_outlined, AppColors.success,
        'Lenders bid',
        'Verified lenders compete by offering lower rates. You see every bid.'),
    (Icons.handshake_outlined, AppColors.purple,
        'You choose',
        'Accept the best offer. A negotiator is assigned to facilitate the deal.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How it works', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        ..._steps.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: s.$2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s.$1, color: s.$2, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.$3, style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(s.$4, style: Theme.of(context).textTheme.bodySmall),
                ])),
              ]),
            )),
      ]),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SkeletonBox(width: 130, height: 13),
            Spacer(),
            SkeletonBox(width: 55, height: 20, radius: 10),
          ]),
          SizedBox(height: 8),
          SkeletonBox(width: 80, height: 10),
          SizedBox(height: 10),
          SkeletonBox(width: 150, height: 20),
          SizedBox(height: 10),
          Row(children: [
            SkeletonBox(width: 60, height: 20, radius: 10),
            SizedBox(width: 8),
            SkeletonBox(width: 80, height: 10),
          ]),
        ]),
      ),
    );
  }
}