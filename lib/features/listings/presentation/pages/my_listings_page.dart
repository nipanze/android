// lib/features/listings/presentation/pages/my_listings_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/forex_listing_model.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../marketplace/data/agreement_repository.dart';
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
      body: BlocConsumer<MyListingsCubit, MyListingsState>(
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
            final active = state.listings.where((l) => l.isActive).toList();
            final closed = state.listings
                .where((l) => l.isExpired || l.isCancelled)
                .toList();
            final contracted =
                state.listings.where((l) => l.isContracted).toList();
            final forexRequests = state.forexRequests;

            // Show empty state only when there are truly no requests at all
            if (active.isEmpty &&
                closed.isEmpty &&
                contracted.isEmpty &&
                forexRequests.isEmpty) {
              return _EmptyRequestState();
            }
            return _ListingsBody(
              listings: state.listings,
              forexRequests: forexRequests,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Listings body ────────────────────────────────────────────────────────────

class _ListingsBody extends StatelessWidget {
  const _ListingsBody({
    required this.listings,
    required this.forexRequests,
  });

  final List<MyListing> listings;
  final List<ForexListingModel> forexRequests;

  List<MyListing> get _active => listings.where((l) => l.isActive).toList();
  List<MyListing> get _closed =>
      listings.where((l) => l.isExpired || l.isCancelled).toList();
  List<MyListing> get _contracted =>
      listings.where((l) => l.isContracted).toList();

  List<ForexListingModel> get _activeForex =>
      forexRequests.where((f) => f.status == 'active').toList();
  List<ForexListingModel> get _closedForex => forexRequests
      .where((f) => f.status != 'active' && f.status != 'contracted')
      .toList();
  List<ForexListingModel> get _contractedForex =>
      forexRequests.where((f) => f.status == 'contracted').toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<MyListingsCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        children: [
          // ── Active Loan Requests ────────────────────────────────────
          if (_active.isNotEmpty) ...[
            SectionHeader(
                AppLocalizations.of(context)!.sectionActive(_active.length)),
            ..._active.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MyListingCard(
                    listing: l,
                    onTap: () => context.push('/marketplace/${l.id}'),
                    onCancel: () => _confirmCancel(context, l),
                  ),
                )),
          ],
          // ── Active Forex Requests ────────────────────────────────────
          if (_activeForex.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_exchange_rounded,
                            size: 13, color: AppColors.accent),
                        const SizedBox(width: 5),
                        Text(
                          'Active Forex · ${_activeForex.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ..._activeForex.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ForexRequestCard(
                    request: f,
                    onTap: () => context.push('/forex/${f.requestId}'),
                    onCancel: () => _confirmCancelForex(context, f),
                  ),
                )),
          ],
          // ── Contracted Loans ─────────────────────────────────────────
          if (_contracted.isNotEmpty) ...[
            SectionHeader(AppLocalizations.of(context)!
                .sectionContracted(_contracted.length)),
            ..._contracted.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MyListingCard(
                    listing: l,
                    onTap: () {},
                    onCancel: () {},
                    onViewAgreement: () => _openAgreement(context, l),
                  ),
                )),
          ],
          // ── Contracted Forex ─────────────────────────────────────────
          if (_contractedForex.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.handshake_rounded,
                            size: 13, color: Colors.green),
                        const SizedBox(width: 5),
                        Text(
                          'Forex Contracted · ${_contractedForex.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ..._contractedForex.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ForexRequestCard(
                    request: f,
                    onTap: () => context.push('/forex/${f.requestId}'),
                  ),
                )),
          ],
          // ── Closed Loans ─────────────────────────────────────────────
          if (_closed.isNotEmpty) ...[
            SectionHeader(
                AppLocalizations.of(context)!.sectionClosed(_closed.length)),
            ..._closed.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child:
                      MyListingCard(listing: l, onTap: () {}, onCancel: () {}),
                )),
          ],
          // ── Closed / Expired Forex ───────────────────────────────────
          if (_closedForex.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.currency_exchange_rounded,
                            size: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 5),
                        Text(
                          'Forex Closed · ${_closedForex.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ..._closedForex.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ForexRequestCard(
                    request: f,
                    onTap: () => context.push('/forex/${f.requestId}'),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  void _confirmCancelForex(
      BuildContext context, ForexListingModel request) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Take Down Forex Request'),
        content: Text(
          'Cancel your ${request.currencyHeld} → ${request.currencyNeeded} '
          'request? Any pending offers will be dismissed.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context, rootNavigator: true);
              if (navigator.canPop()) navigator.pop();
            },
            child: const Text('Keep It'),
          ),
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context, rootNavigator: true);
              if (navigator.canPop()) navigator.pop();
              context
                  .read<MyListingsCubit>()
                  .cancelForexRequest(request.requestId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Take Down'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAgreement(BuildContext context, MyListing listing) async {
    try {
      final repo = getIt<AgreementRepository>();
      final agreement = await repo.getAgreementByRequestId(listing.id);
      if (!context.mounted) return;
      if (agreement != null) {
        await context.push('/marketplace/agreement/${agreement.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.contractNotGenerated)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingErrorMessage(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _confirmCancel(BuildContext context, MyListing listing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelListing),
        content: Text(
          AppLocalizations.of(context)!.cancelListingConfirm(listing.title),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context, rootNavigator: true);
              if (navigator.canPop()) navigator.pop();
            },
            child: Text(AppLocalizations.of(context)!.keepIt),
          ),
          TextButton(
            onPressed: () {
              final navigator = Navigator.of(context, rootNavigator: true);
              if (navigator.canPop()) navigator.pop();
              context.read<MyListingsCubit>().cancelListing(listing.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(AppLocalizations.of(context)!.cancelListingBtn),
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
    return EmptyState(
      icon: Icons.request_page_outlined,
      title: AppLocalizations.of(context)!.noLoanRequests,
      subtitle: AppLocalizations.of(context)!.noLoanRequestsSubtitle,
      action: ElevatedButton(
        onPressed: () => context.go(AppRoutes.listingCreate),
        child: Text(AppLocalizations.of(context)!.createLoanRequest),
      ),
    );
  }
}

// ─── Forex request card ───────────────────────────────────────────────────────

class _ForexRequestCard extends StatelessWidget {
  const _ForexRequestCard({
    required this.request,
    required this.onTap,
    this.onCancel,
  });

  final ForexListingModel request;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  Color _statusColor(BuildContext context) {
    switch (request.status) {
      case 'active':
        return AppColors.accent;
      case 'contracted':
        return Colors.green;
      case 'cancelled':
      case 'expired':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  IconData _statusIcon() {
    switch (request.status) {
      case 'active':
        return Icons.radio_button_checked_rounded;
      case 'contracted':
        return Icons.handshake_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'expired':
        return Icons.timer_off_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  String _fmtAmount(int amount) =>
      NumberFormat('#,###').format(amount);

  String _fmtRate(double rate) {
    if (rate >= 1) return rate.toStringAsFixed(2);
    return rate.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context);
    final timeLeft = request.timeRemaining;
    final timeLabel = request.status == 'active' && !request.isExpired
        ? (timeLeft.inDays > 0
            ? '${timeLeft.inDays}d ${timeLeft.inHours % 24}h left'
            : timeLeft.inHours > 0
                ? '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m left'
                : '${timeLeft.inMinutes}m left')
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: request.status == 'active'
                ? AppColors.accent.withOpacity(0.3)
                : theme.dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: pair + status chip ──────────────────────────
            Row(
              children: [
                // Currency exchange icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.currency_exchange_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                // Pair label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.currencyHeld} → ${request.currencyNeeded}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (timeLabel != null)
                        Text(
                          timeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: request.isClosingSoon24h
                                ? AppColors.danger
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(), size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        request.status[0].toUpperCase() +
                            request.status.substring(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Amount ───────────────────────────────────────────────
            Text(
              '${request.currencyHeld} ${_fmtAmount(request.amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 6),
            // ── Rate + offers row ────────────────────────────────────
            Row(
              children: [
                if (request.preferredRate != null) ...[
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '@ ${_fmtRate(request.preferredRate!)} target rate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Icon(
                  Icons.local_offer_outlined,
                  size: 13,
                  color: request.numberOfOffers > 0
                      ? AppColors.accent
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  request.numberOfOffers == 0
                      ? 'No offers yet'
                      : '${request.numberOfOffers} offer${request.numberOfOffers == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: request.numberOfOffers > 0
                        ? AppColors.accent
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: request.numberOfOffers > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                // Settlement snippet
                Flexible(
                  child: Text(
                    request.settlementPreference,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
            // ── Cancel button (active only) ──────────────────────────
            if (request.status == 'active' && onCancel != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.unpublished_outlined, size: 15),
                  label: const Text('Take Down Request'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
        child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
