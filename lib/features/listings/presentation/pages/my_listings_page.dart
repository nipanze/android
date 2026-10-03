// lib/features/listings/presentation/pages/my_listings_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/marketplace/domain/models/loan_listing.dart';
import '../../../../features/marketplace/domain/models/marketplace_item.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/forex_listing_model.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../marketplace/presentation/widgets/listing_card.dart';
import '../../domain/models/my_listing.dart';
import '../cubit/my_listings_cubit.dart';

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

  List<MyListing> get _active {
    final list = listings.where((l) => l.isActive).toList();
    list.sort((a, b) {
      final offersComp = b.numberOfOffers.compareTo(a.numberOfOffers);
      if (offersComp != 0) return offersComp;
      return b.listedAt.compareTo(a.listedAt);
    });
    return list;
  }

  List<MyListing> get _closed =>
      listings.where((l) => l.isExpired && !l.isCancelled).toList();

  List<ForexListingModel> get _activeForex {
    final list = forexRequests.where((f) => f.status == 'active').toList();
    list.sort((a, b) {
      final offersComp = b.numberOfOffers.compareTo(a.numberOfOffers);
      if (offersComp != 0) return offersComp;
      return b.listedAt.compareTo(a.listedAt);
    });
    return list;
  }

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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        children: [
          // ── Active Forex Requests ────────────────────────────────────
          if (_activeForex.isNotEmpty) ...[
            ..._activeForex.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ForexRequestCard(
                    request: f,
                    onTap: () => context.push('/forex/${f.requestId}'),
                    onDelete: () => _confirmCancelForex(context, f),
                  ),
                )),
          ],
          // ── Active Loan Requests ────────────────────────────────────
          if (_active.isNotEmpty) ...[
            ..._active.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListingCard(
                    listing: MarketplaceItem.loan(_myListingToLoanListing(l)),
                    onTap: () => context.push('/marketplace/${l.id}'),
                    isSaved: false,
                    onWatchlistToggle: () => _confirmCancel(context, l),
                    showMoreActions: true,
                    showDeleteAction: true,
                    moreActionLabel: 'Cancel request',
                    onMoreAction: () => _confirmCancel(context, l),
                  ),
                )),
          ],

          // ── Closed Loans ─────────────────────────────────────────────
          if (_closed.isNotEmpty) ...[
            SectionHeader(
                AppLocalizations.of(context)!.sectionClosed(_closed.length)),
            ..._closed.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListingCard(
                    listing: MarketplaceItem.loan(_myListingToLoanListing(l)),
                    onTap: () => context.push('/marketplace/${l.id}'),
                    isSaved: false,
                    onWatchlistToggle: () {},
                    showMoreActions: false,
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
                    onDelete: () {},
                  ),
                )),
          ],
        ],
      ),
    );
  }

  LoanListing _myListingToLoanListing(MyListing listing) {
    return LoanListing(
      requestId: listing.id,
      title: listing.title,
      purpose: listing.purpose,
      district: listing.district,
      country: 'UG',
      durationMonths: listing.durationMonths,
      requestedAmount: listing.requestedAmount,
      incomeSource: listing.incomeSource,
      preferredRepaymentPlan: listing.preferredRepaymentPlan,
      repaymentAmountPerPeriod: listing.repaymentAmountPerPeriod,
      repaymentTimeline: listing.repaymentTimeline,
      suggestedInterestRatePct: listing.suggestedInterestRatePct,
      suggestedLateFeePct: listing.suggestedLateFeePct,
      suggestedRepaymentFrequency: listing.suggestedRepaymentFrequency,
      suggestedInstallmentAmount: listing.suggestedInstallmentAmount,
      hasCollateral: listing.hasCollateral,
      collateralDetails: listing.collateralDetails,
      collateralEstimatedValue: listing.collateralEstimatedValue,
      collateralLocation: listing.collateralLocation,
      status: switch (listing.status) {
        ListingStatus.pendingKyc => 'pending_kyc',
        ListingStatus.active => 'active',
        ListingStatus.contracted => 'contracted',
        ListingStatus.expired => 'expired',
        ListingStatus.cancelled => 'cancelled',
      },
      listedAt: listing.listedAt,
      expiresAt: listing.expiresAt,
      numberOfOffers: listing.numberOfOffers,
      trustIsVerified: false,
      currency: listing.currency,
      isSponsored: listing.isSponsored,
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
    required this.onDelete,
  });

  final ForexListingModel request;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
    if (request.status != 'active' || request.isExpired) return '';

    final timeLeft = request.timeRemaining;
    if (timeLeft.isNegative) return '';
    if (timeLeft.inDays > 0) {
      return '${timeLeft.inDays}d ${timeLeft.inHours % 24}h left';
    }
    if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m left';
    }
    if (timeLeft.inMinutes > 0) {
      return '${timeLeft.inMinutes}m left';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.purple;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.bg2Dark : theme.colorScheme.surface;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.borderLight;
    final mutedColor =
        isDark ? AppColors.text2Dark : theme.colorScheme.onSurfaceVariant;
    final heldAmount = '${request.currencyHeld} ${_fmtAmount(request.amount)}';
    final projectedAmount =
        '${request.currencyNeeded} ${_fmtAmount(request.receiveEstimate)}';
    final offersLabel = '${request.numberOfOffers} Offers';

    return Material(
      color: surfaceColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: accent.withValues(alpha: 0.95)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.currency_exchange_rounded, size: 12, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          'Forex',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: mutedColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _timeLabel().isNotEmpty ? _timeLabel() : '3 weeks ago',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    tooltip: 'Delete request',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.bg3Dark.withValues(alpha: 0.55)
                      : AppColors.bg3Light,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : AppColors.borderLight,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final available = constraints.maxWidth;
                    final leftWidth = available * 0.48;
                    final rightWidth = available - leftWidth - 52;

                    return Row(
                      children: [
                        SizedBox(
                          width: leftWidth,
                          child: Flexible(
                            child: Text(
                              heldAmount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: rightWidth.clamp(70.0, double.infinity),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Projected Money',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                projectedAmount,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ForexRequestMetric(
                    icon: Icons.people_outline_rounded,
                    value: offersLabel,
                    color: mutedColor,
                  ),
                ],
              ),
            ],
          ),
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
        Expanded(
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
