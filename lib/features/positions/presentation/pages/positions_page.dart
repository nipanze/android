// lib/features/positions/presentation/pages/positions_page.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../listings/presentation/pages/my_listings_page.dart';
import '../../../marketplace/domain/models/agreement.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // ── Screen Title Header (Matching WatchlistPage) ───────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.navActivity,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    BlocBuilder<PositionsCubit, PositionsState>(
                      builder: (context, state) {
                        final loaded = state is PositionsLoaded ? state : null;
                        final requests =
                            (loaded?.activity?['active_listings'] as num?)?.toInt() ??
                                0;
                        final offers = loaded?.offers
                                .where((offer) =>
                                    offer.status == OfferStatus.pending)
                                .length ??
                            0;
                        final deals = loaded?.deals.length ?? 0;

                        return Text(
                            '$requests Requests - $offers Offers - $deals Deals',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),
                BlocBuilder<PositionsCubit, PositionsState>(
                  builder: (context, state) {
                    final activeCount = state is PositionsLoaded
                        ? (state.activity?['active_listings'] ?? 0) +
                            state.offers
                                .where((o) => o.status == OfferStatus.pending)
                                .length
                        : 0;
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
                        '$activeCount active',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Tab bar ─────────────────────────────────────────────────
          TabBar(
            controller: _tc,
            indicatorColor: AppColors.accent,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor:
              Theme.of(context).brightness == Brightness.dark
                ? AppColors.text3Dark
                : AppColors.text3Light,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: [
              Tab(text: AppLocalizations.of(context)!.tabMyRequests),
              Tab(text: AppLocalizations.of(context)!.tabMyOffers),
              Tab(text: AppLocalizations.of(context)!.tabDeals),
            ],
          ),

          // ── Tab views ───────────────────────────────────────────────
          Expanded(
            child: BlocConsumer<PositionsCubit, PositionsState>(
              listener: (context, state) {
                if (state is PositionsError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.danger));
                }
              },
              builder: (context, state) {
                return TabBarView(
                  controller: _tc,
                  children: [
                    const MyListingsPage(),
                    _LenderTab(state: state),
                    _DealsTab(state: state),
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
      return ErrorState(
          message: (state as PositionsError).message,
          onRetry: () => context.read<PositionsCubit>().refresh());
    }
    if (state is! PositionsLoaded) return const SizedBox.shrink();

    final offers = (state as PositionsLoaded).offers;
    if (offers.isEmpty) {
      return EmptyState(
        icon: Icons.payments_outlined,
        title: AppLocalizations.of(context)!.noOffersYet,
        subtitle: AppLocalizations.of(context)!.noOffersSubtitle,
        action: ElevatedButton(
            onPressed: () => context.go('/marketplace'),
            child: Text(AppLocalizations.of(context)!.browseMarketplaceBtn)),
      );
    }

    final pending =
        offers.where((o) => o.status == OfferStatus.pending).toList();
    final history = offers
        .where((o) =>
            o.status != OfferStatus.pending &&
            o.status != OfferStatus.withdrawn)
        .toList();

    return RefreshIndicator(
      onRefresh: () => context.read<PositionsCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (pending.isNotEmpty) ...[
            ...pending.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LenderOfferCard(
                      offer: o, onWithdraw: () => _confirmWithdraw(context, o)),
                )),
          ],
          if (history.isNotEmpty) ...[
            SectionHeader(AppLocalizations.of(context)!.history),
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
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.withdrawOffer),
        content: Text(
            AppLocalizations.of(context)!.withdrawConfirm(offer.offerAmount)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppLocalizations.of(context)!.keepOffer)),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<PositionsCubit>().withdrawOffer(offer.offerId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(AppLocalizations.of(context)!.withdraw),
          ),
        ],
      ),
    );
  }
}

class _DealsTab extends StatelessWidget {
  const _DealsTab({required this.state});
  final PositionsState state;

  @override
  Widget build(BuildContext context) {
    if (state is PositionsLoading || state is PositionsInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is PositionsError) {
      return ErrorState(
          message: (state as PositionsError).message,
          onRetry: () => context.read<PositionsCubit>().refresh());
    }
    if (state is! PositionsLoaded) return const SizedBox.shrink();

    final loadedState = state as PositionsLoaded;
    final acceptedOffers = loadedState.offers
        .where((o) => o.status == OfferStatus.accepted)
        .toList();
    final deals = loadedState.deals;

    if (acceptedOffers.isEmpty && deals.isEmpty) {
      return EmptyState(
        icon: Icons.handshake_outlined,
        title: AppLocalizations.of(context)!.noDealsYet,
        subtitle: AppLocalizations.of(context)!.noDealsSubtitle,
        action: ElevatedButton(
            onPressed: () => context.go('/marketplace'),
            child: Text(AppLocalizations.of(context)!.browseMarketplaceBtn)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PositionsCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (deals.isNotEmpty) ...[
            ...deals.map((deal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DealCard(deal: deal),
                )),
          ],
          if (acceptedOffers.isNotEmpty) ...[
            if (deals.isEmpty) SectionHeader(AppLocalizations.of(context)!.matchedAccepted),
            ...acceptedOffers.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LenderOfferCard(offer: o, onWithdraw: () {}),
                )),
          ],
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal});
  final dynamic deal;

  @override
  Widget build(BuildContext context) {
    final map = deal is Map<String, dynamic>
        ? deal as Map<String, dynamic>
        : (deal as Agreement).toMap();
    final agreement = deal is Agreement ? deal : Agreement.fromMap(map);

    final isLocked = agreement.isFullyLocked;
    final statusText = isLocked
        ? AppLocalizations.of(context)!.verified
        : agreement.status.displayName;
    final statusColor = isLocked ? AppColors.success : AppColors.warning;
    final theme = Theme.of(context);

    // Derive position (Borrowing / Lending / Forex Offering)
    final currentUid = Supabase.instance.client.auth.currentUser?.id;
    final snapshot = map['agreement_snapshot'] as Map<String, dynamic>? ?? agreement.agreementSnapshot;

    final borrowerId = snapshot?['borrower_id'] as String? ?? map['borrower_id'] as String? ?? agreement.borrowerId;
    final lenderId = snapshot?['lender_id'] as String? ?? map['lender_id'] as String? ?? agreement.lenderId;
    final dealType = (snapshot?['deal_type'] as String? ?? map['deal_type'] as String? ?? '').toLowerCase();
    final isForex = dealType == 'forex' || (snapshot?['is_forex'] == true) || (map['is_forex'] == true);

    final isBorrower = currentUid != null && borrowerId == currentUid;
    final isLender = currentUid != null && lenderId == currentUid;

    final String positionLabel;
    final IconData positionIcon;
    final Color positionColor;
    final Color positionBgColor;

    if (isForex) {
      positionLabel = 'FOREX EXCHANGE';
      positionIcon = Icons.currency_exchange_rounded;
      positionColor = const Color(0xFFC084FC); // Purple Accent
      positionBgColor = Colors.purple.withValues(alpha: 0.15);
    } else if (isBorrower) {
      positionLabel = 'BORROWING';
      positionIcon = Icons.south_west_rounded;
      positionColor = const Color(0xFF60A5FA); // Blue Accent
      positionBgColor = const Color(0xFF1E3A8A).withValues(alpha: 0.35);
    } else if (isLender) {
      positionLabel = 'LENDING';
      positionIcon = Icons.north_east_rounded;
      positionColor = AppColors.success; // Emerald Green
      positionBgColor = AppColors.success.withValues(alpha: 0.15);
    } else {
      positionLabel = 'LOAN DEAL';
      positionIcon = Icons.handshake_outlined;
      positionColor = theme.colorScheme.onSurface.withValues(alpha: 0.8);
      positionBgColor = theme.colorScheme.surfaceContainerHighest;
    }

    final dealTitle = snapshot?['title'] as String? ??
        snapshot?['request_title'] as String? ??
        snapshot?['purpose'] as String? ??
        map['title'] as String? ??
        map['request_title'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked
              ? AppColors.success.withValues(alpha: 0.4)
              : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Position Pill & Status Pill ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: positionBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(positionIcon, size: 12, color: positionColor),
                    const SizedBox(width: 4),
                    Text(
                      positionLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: positionColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Title (if available) ───────────────────────────────────────
          if (dealTitle != null && dealTitle.isNotEmpty) ...[
            Text(
              dealTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // ── Loan Amount ───────────────────────────────────────────────
          CurrencyAmount(
            agreement.loanAmount > 0
                ? agreement.loanAmount
                : agreement.totalRepaymentAmount,
            currency: agreement.currency,
            fontSize: 16,
          ),
          const SizedBox(height: 8),

          // ── Term Row ──────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                '${agreement.repaymentPeriod} ${agreement.repaymentFrequency.displayName} payments',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              if (agreement.interestRate > 0)
                Text(
                  '${agreement.interestRate}% interest',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Action Buttons ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/marketplace/agreement/${agreement.id}');
                  },
                  icon: const Icon(Icons.description_outlined, size: 14),
                  label: Text(
                    AppLocalizations.of(context)!.viewContract,
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/marketplace/contact-details/${agreement.id}');
                  },
                  icon: const Icon(Icons.phone_outlined, size: 14),
                  label: Text(
                    AppLocalizations.of(context)!.unlockDealAndContact,
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
