// lib/features/positions/presentation/pages/positions_page.dart
// ignore_for_file: unused_import, directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../listings/presentation/pages/my_listings_page.dart';
import '../cubit/positions_cubit.dart';
import '../widgets/lender_bid_card.dart';
import '../widgets/contract_card.dart';
import '../../domain/models/lender_bid.dart';

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

class _PositionsViewState extends State<_PositionsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Positions',
                    style: Theme.of(context).textTheme.headlineMedium),
                BlocBuilder<PositionsCubit, PositionsState>(
                  builder: (context, state) {
                    if (state is! PositionsLoaded) {
                      return Text('Your listings, bids & contracts',
                          style: Theme.of(context).textTheme.bodySmall);
                    }
                    final activeBids = state.bids
                        .where((b) => b.isPending).length;
                    final activeContracts = state.contracts
                        .where((c) => c['status'] == 'in_execution').length;
                    return Text(
                      [
                        if (activeBids > 0) '$activeBids active bid${activeBids != 1 ? 's' : ''}',
                        if (activeContracts > 0) '$activeContracts contract${activeContracts != 1 ? 's' : ''}',
                      ].join(' · ').ifEmpty('Your listings, bids & contracts'),
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ]),
              const Spacer(),
              if (user != null) RepTierBadge(user.repTier),
            ]),
          ),

          // Tab bar
          TabBar(
            controller: _tc,
            indicatorColor: AppColors.accent,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: 'Borrower'),
              Tab(text: 'Lender'),
              Tab(text: 'Contracts'),
            ],
          ),

          // Tab views
          Expanded(
            child: BlocConsumer<PositionsCubit, PositionsState>(
              listener: (context, state) {
                if (state is PositionsError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.danger,
                  ));
                }
              },
              builder: (context, state) {
                return TabBarView(
                  controller: _tc,
                  children: [
                    // ── Borrower tab — MyListingsPage embedded ──────────
                    const MyListingsPage(),

                    // ── Lender tab ──────────────────────────────────────
                    _LenderTab(state: state),

                    // ── Contracts tab ───────────────────────────────────
                    _ContractsTab(
                      state: state,
                      currentUserId: (context.read<AuthBloc>().state
                              is AuthAuthenticated)
                          ? (context.read<AuthBloc>().state
                                  as AuthAuthenticated)
                              .user
                              .id
                          : '',
                    ),
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

// ─── Lender Tab ───────────────────────────────────────────────────────────────

class _LenderTab extends StatelessWidget {
  const _LenderTab({required this.state});
  final PositionsState state;

  @override
  Widget build(BuildContext context) {
    if (state is PositionsLoading || state is PositionsInitial) {
      return _skeleton(context);
    }
    if (state is PositionsError) {
      return ErrorState(
        message: (state as PositionsError).message,
        onRetry: () => context.read<PositionsCubit>().refresh(),
      );
    }
    if (state is! PositionsLoaded) return const SizedBox.shrink();

    final bids = (state as PositionsLoaded).bids;
    final pending    = bids.where((b) => b.isPending).toList();
    final accepted   = bids.where((b) => b.isAccepted).toList();
    final historical = bids
        .where((b) => b.isWithdrawn || b.bidStatus == BidStatus.rejected ||
            b.bidStatus == BidStatus.expired)
        .toList();

    if (bids.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No bids yet',
        subtitle: 'Browse the marketplace and place bids on listings.',
        action: ElevatedButton(
          onPressed: () => context.go('/marketplace'),
          child: const Text('Browse marketplace'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PositionsCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        children: [
          if (pending.isNotEmpty) ...[
            SectionHeader('Pending · ${pending.length}'),
            ...pending.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LenderBidCard(
                    bid: b,
                    onWithdraw: () => _confirmWithdraw(context, b),
                  ),
                )),
          ],
          if (accepted.isNotEmpty) ...[
            SectionHeader('Accepted · ${accepted.length}'),
            ...accepted.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LenderBidCard(bid: b, onWithdraw: () {}),
                )),
          ],
          if (historical.isNotEmpty) ...[
            SectionHeader('History · ${historical.length}'),
            ...historical.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LenderBidCard(bid: b, onWithdraw: () {}),
                )),
          ],
        ],
      ),
    );
  }

  void _confirmWithdraw(BuildContext context, LenderBid bid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw bid?'),
        content: Text(
          'Your bid of UGX ${_fmt(bid.bidAmount)} at ${bid.bidRate.toStringAsFixed(1)}% '
          'on "${bid.listingTitle}" will be withdrawn. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep bid'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PositionsCubit>().withdrawBid(bid.bidId);
            },
            style: TextButton.styleFrom(
                foregroundColor: AppColors.danger),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  Widget _skeleton(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 110,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
        ),
      );

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── Contracts Tab ────────────────────────────────────────────────────────────

class _ContractsTab extends StatelessWidget {
  const _ContractsTab({
    required this.state,
    required this.currentUserId,
  });
  final PositionsState state;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (state is PositionsLoading || state is PositionsInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is PositionsError) {
      return ErrorState(
        message: (state as PositionsError).message,
        onRetry: () => context.read<PositionsCubit>().refresh(),
      );
    }
    if (state is! PositionsLoaded) return const SizedBox.shrink();

    final contracts = (state as PositionsLoaded).contracts;
    final active = contracts
        .where((c) => c['status'] == 'in_execution').toList();
    final other = contracts
        .where((c) => c['status'] != 'in_execution').toList();

    if (contracts.isEmpty) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        title: 'No contracts yet',
        subtitle:
            'Contracts appear here after a bid is accepted by a borrower.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PositionsCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        children: [
          if (active.isNotEmpty) ...[
            SectionHeader('Active · ${active.length}'),
            ...active.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ContractCard(
                      contract: c, currentUserId: currentUserId),
                )),
          ],
          if (other.isNotEmpty) ...[
            SectionHeader('Other · ${other.length}'),
            ...other.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ContractCard(
                      contract: c, currentUserId: currentUserId),
                )),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Nipanze does not hold or move funds. All financial '
              'settlement is directly between matched participants '
              'off-platform. Indicative figures only.',
              style: TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Extension ────────────────────────────────────────────────────────────────

extension _StringX on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}