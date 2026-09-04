// lib/features/listings/presentation/pages/my_listings_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/forex_listing_model.dart';
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
                .where((l) => l.isExpired && !l.isCancelled)
                .toList();
            final forexRequests = state.forexRequests;
            final activeForex =
                forexRequests.where((f) => f.status == 'active').toList();
            final closedForex = forexRequests
                .where((f) =>
                    f.status != 'active' &&
                    f.status != 'contracted' &&
                    f.status != 'cancelled')
                .toList();

            // Show empty state when there are no active or closed requests on this tab
            if (active.isEmpty &&
                closed.isEmpty &&
                activeForex.isEmpty &&
                closedForex.isEmpty) {
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
      listings.where((l) => l.isExpired && !l.isCancelled).toList();

  List<ForexListingModel> get _activeForex =>
      forexRequests.where((f) => f.status == 'active').toList();
  List<ForexListingModel> get _closedForex => forexRequests
      .where((f) =>
          f.status != 'active' &&
          f.status != 'contracted' &&
          f.status != 'cancelled')
      .toList();

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

          // ── Closed Loans ─────────────────────────────────────────────
          if (_closed.isNotEmpty) ...[
            SectionHeader(
                AppLocalizations.of(context)!.sectionClosed(_closed.length)),
            ..._closed.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MyListingCard(
                    listing: l,
                    onTap: () => context.push('/marketplace/${l.id}'),
                    onCancel: () {},
                  ),
                )),
          ],
          // ── Closed / Expired Forex ───────────────────────────────────
          if (_closedForex.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.currency_exchange_rounded,
                            size: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5)),
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

  void _confirmCancelForex(BuildContext context, ForexListingModel request) {
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
        return AppColors.purple;
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

  String _fmtAmount(int amount) => NumberFormat('#,###').format(amount);

  String _timeLabel() {
    if (request.status != 'active' || request.isExpired) return request.status;

    final timeLeft = request.timeRemaining;
    if (timeLeft.inDays > 0) {
      return '${timeLeft.inDays}d ${timeLeft.inHours % 24}h left';
    }
    if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m left';
    }
    return '${timeLeft.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context);
    final metadata = [
      if (request.settlementPreference.trim().isNotEmpty)
        request.settlementPreference.trim(),
      if (request.country.trim().isNotEmpty) request.country.trim(),
    ].join(' · ');

    final borderRadius = BorderRadius.circular(8);
    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: request.status == 'active'
              ? AppColors.purple.withOpacity(
                  request.numberOfOffers > 0 ? 0.5 : 0.3,
                )
              : theme.dividerColor,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 30, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.currency_exchange_rounded,
                          size: 18,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 10),
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
                            if (metadata.isNotEmpty)
                              Text(
                                metadata,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.55),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                      if (request.status == 'active' && onCancel != null)
                        PopupMenuButton<_ForexRequestAction>(
                          tooltip: 'More actions',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                              width: 28, height: 28),
                          icon: const Icon(Icons.more_vert, size: 19),
                          onSelected: (_) => onCancel!(),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: _ForexRequestAction.cancel,
                              child: Text('Cancel request'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    '${request.currencyHeld} ${_fmtAmount(request.amount)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.35),
                  ),
                  const SizedBox(height: 9),

                  // Request metrics
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ForexRequestMetric(
                          icon: Icons.people_outline_rounded,
                          value:
                              '${request.numberOfOffers} ${request.numberOfOffers == 1 ? 'Offer' : 'Offers'}',
                          color: request.numberOfOffers > 0
                              ? AppColors.purple
                              : null,
                        ),
                      ),
                      Expanded(
                        child: _ForexRequestMetric(
                          icon: Icons.swap_horiz_rounded,
                          value: request.settlementPreference.isEmpty
                              ? 'Forex request'
                              : request.settlementPreference,
                        ),
                      ),
                      Expanded(
                        child: _ForexRequestMetric(
                          icon: Icons.schedule_outlined,
                          value: _timeLabel(),
                          color: request.isClosingSoon24h
                              ? AppColors.danger
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.72),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ForexRequestAction { cancel }

class _ForexRequestMetric extends StatelessWidget {
  const _ForexRequestMetric({
    required this.icon,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final foreground = color ?? muted;
    return Row(
      children: [
        Icon(icon, size: 17, color: foreground),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ],
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
