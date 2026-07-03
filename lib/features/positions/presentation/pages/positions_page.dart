// lib/features/positions/presentation/pages/positions_page.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../listings/presentation/pages/my_listings_page.dart';
import '../../domain/models/lender_offer.dart';
import '../cubit/positions_cubit.dart';
import '../widgets/lender_offer_card.dart';

class PositionsPage extends StatelessWidget {
  const PositionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PositionsCubit>()..load(),
      child: const _PositionsView(),
    );
  }
}

class _PositionsView extends StatefulWidget {
  const _PositionsView();

  @override
  State<_PositionsView> createState() => _PositionsViewState();
}

class _PositionsViewState extends State<_PositionsView> with SingleTickerProviderStateMixin {
  late final TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My Activity', style: Theme.of(context).textTheme.headlineMedium),
                BlocBuilder<PositionsCubit, PositionsState>(
                  builder: (context, state) {
                    if (state is! PositionsLoaded) {
                      return Text('Manage your listings and offers', style: Theme.of(context).textTheme.bodySmall);
                    }
                    final activity = state.activity;
                    final activeOffers = state.offers.where((o) => o.status == OfferStatus.pending).length;
                    return Text(
                      '${activity?['active_listings'] ?? 0} Listings · $activeOffers Active Offers',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ]),
            ]),
          ),

          // ── Tab bar ─────────────────────────────────────────────────
          TabBar(
            controller: _tc,
            indicatorColor: AppColors.accent,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'My Requests'),
              Tab(text: 'My Offers'),
            ],
          ),

          // ── Tab views ───────────────────────────────────────────────
          Expanded(
            child: BlocConsumer<PositionsCubit, PositionsState>(
              listener: (context, state) {
                if (state is PositionsError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.danger));
                }
              },
              builder: (context, state) {
                return TabBarView(
                  controller: _tc,
                  children: [
                    const MyListingsPage(),
                    _LenderTab(state: state),
                  ],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _LenderTab extends StatelessWidget {
  const _LenderTab({required this.state});
  final PositionsState state;

  @override
  Widget build(BuildContext context) {
    if (state is PositionsLoading || state is PositionsInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is PositionsError) {
      return ErrorState(message: (state as PositionsError).message, onRetry: () => context.read<PositionsCubit>().refresh());
    }
    if (state is! PositionsLoaded) return const SizedBox.shrink();

    final offers = (state as PositionsLoaded).offers;
    if (offers.isEmpty) {
      return EmptyState(
        icon: Icons.payments_outlined,
        title: 'No offers yet',
        subtitle: 'Bids you place on marketplace listings will appear here.',
        action: ElevatedButton(onPressed: () => context.go('/marketplace'), child: const Text('Browse Marketplace')),
      );
    }

    final pending = offers.where((o) => o.status == OfferStatus.pending).toList();
    final accepted = offers.where((o) => o.status == OfferStatus.accepted).toList();
    final history = offers.where((o) => o.status != OfferStatus.pending && o.status != OfferStatus.accepted).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<PositionsCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            const SectionHeader('Active Offers'),
            ...pending.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LenderOfferCard(offer: o, onWithdraw: () => _confirmWithdraw(context, o)),
            )),
          ],
          if (accepted.isNotEmpty) ...[
             const SectionHeader('Matched / Accepted'),
            ...accepted.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LenderOfferCard(offer: o, onWithdraw: () {}),
            )),
          ],
           if (history.isNotEmpty) ...[
             const SectionHeader('History'),
            ...history.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LenderOfferCard(offer: o, onWithdraw: () {}),
            )),
          ],
        ],
      ),
    );
  }

  void _confirmWithdraw(BuildContext context, LenderOffer offer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw Offer?'),
        content: Text('Are you sure you want to withdraw your offer for UGX ${offer.offerAmount}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Offer')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PositionsCubit>().withdrawOffer(offer.offerId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}