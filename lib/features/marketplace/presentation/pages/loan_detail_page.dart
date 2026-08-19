// lib/features/marketplace/presentation/pages/loan_detail_page.dart
// ignore_for_file: unused_import, unused_element, unused_element_parameter

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../account/data/privacy_repository.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../settings/data/system_settings_repository.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/loan_listing.dart';
import '../../domain/models/marketplace_item.dart';
import '../widgets/lender_required_sheet.dart';
import '../widgets/loan_detail/make_offer_sheet.dart';
import '../widgets/loan_detail/offer_card.dart';
import '../widgets/pro_required_sheet.dart';

class LoanDetailPage extends StatefulWidget {
  const LoanDetailPage({super.key, required this.requestId});
  final String requestId;

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  LoanListing? _listing;
  List<LoanOffer> _offers = [];
  bool _loading = true;
  String? _error;
  bool _showOfferSheet = false;
  bool _newOfferFlash = false;
  bool _isOwnerValue = false;
  bool _isParticipant = false;
  String? _ownerId;

  final _repo = getIt<MarketplaceRepository>();
  final _settingsRepo = getIt<SystemSettingsRepository>();
  double _marketBaselinePct = 10.0;
  StreamSubscription<List<LoanOffer>>? _offersSub;
  StreamSubscription<List<MarketplaceItem>>? _listingSub;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadOnce();
  }

  Future<void> _loadSettings() async {
    final limits = await _settingsRepo.getLimits();
    if (!mounted) return;
    setState(() => _marketBaselinePct = limits.marketRateBaselinePct);
  }

  @override
  void dispose() {
    _offersSub?.cancel();
    _listingSub?.cancel();
    super.dispose();
  }

  Future<void> _loadOnce() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Force-refresh subscription plan in case it changed since login
    context.read<AuthBloc>().add(const AuthProfileRefreshRequested());

    try {
      final listing = await _repo.getListingDetail(widget.requestId);
      if (!mounted) return;

      bool isOwner = false;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _ownerId = await _repo.getListingOwnerId(widget.requestId);
        isOwner = await _repo.isListingOwner(
          requestId: widget.requestId,
          userId: authState.user.id,
        );
      }

      final offers = await _repo.getOffers(
        widget.requestId,
        includePrivate: isOwner,
      );

      if (!mounted) return;
      setState(() {
        _listing = listing;
        _offers = offers;
        _isOwnerValue = isOwner;
        // The RPC only returns rows after it has confirmed participation. Its
        // lender labels are deliberately anonymised, so never compare them to
        // the authenticated user's ID in the client.
        _isParticipant = !isOwner && offers.isNotEmpty;
        _loading = false;
      });
      _subscribeRealtime();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFacingErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _subscribeRealtime() {
    _offersSub = _repo
        .watchOffers(
      widget.requestId,
      includePrivate: _isOwnerValue,
    )
        .listen(
      (offers) {
        if (!mounted) return;
        final hadOffers = _offers.length;
        setState(() => _offers = offers);
        if (offers.length > hadOffers) _flashOrderBook();
      },
      onError: (_) {},
    );

    _listingSub = _repo.watchListings(module: MarketplaceModule.loan).listen(
      (listings) {
        if (!mounted) return;
        final updated = listings.where((l) => l.requestId == widget.requestId);
        if (updated.isNotEmpty) setState(() => _listing = updated.first.loan);
      },
      onError: (_) {},
    );
  }

  void _flashOrderBook() async {
    setState(() => _newOfferFlash = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _newOfferFlash = false);
  }

  Future<void> _acceptOffer(LoanOffer offer) async {
    try {
      final agreementId = await _repo.acceptOffer(
        requestId: widget.requestId,
        offerId: offer.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Offer accepted — contract generated.')));
      // Navigate to agreement review page
      context.go('/marketplace/agreement/$agreementId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(userFacingErrorMessage(e)),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  Future<void> _blockOwner() async {
    final ownerId = _ownerId;
    if (ownerId == null) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.blockUserConfirmTitle),
        content: Text(l10n.blockUserConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.block),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await getIt<PrivacyRepository>().blockUser(ownerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userBlocked)),
      );
      context.go(AppRoutes.marketplace);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingErrorMessage(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(
            message: _error ?? 'Listing not found', onRetry: _loadOnce),
      );
    }

    final listing = _listing!;
    final authState = context.watch<AuthBloc>().state;
    final l10n = AppLocalizations.of(context);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isOwner = _isOwnerValue;
    final hasMadeOffer = _isParticipant;
    final canMakeOffer = !isOwner && !hasMadeOffer;
    // Pro borrowers see term-comparison arrows on each offer card
    final isProBorrower = isOwner &&
        authState is AuthAuthenticated &&
        authState.user.canSuggestBorrowerTerms;
    final canViewCollateral = isOwner ||
        (authState is AuthAuthenticated &&
            authState.user.subscriptionPlan == SubscriptionPlan.pro);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.marketplace),
        ),
        title: Text(AppLocalizations.of(context)?.listingDetailTitle ??
            'Listing detail'),
        actions: [
          if (user != null && !isOwner && _ownerId != null)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (value) {
                if (value == 'block') _blockOwner();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(
                    AppLocalizations.of(context)?.blockUser ?? 'Block User',
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOnce,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Main listing card ────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + time badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (listing.isSponsored) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.purple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.purple
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  l10n?.sponsoredLabel ?? 'Sponsored',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                listing.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (listing.isClosingSoon24h
                                  ? AppColors.danger
                                  : AppColors.warning)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: listing.isClosingSoon24h
                                  ? AppColors.danger
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              listing.timeRemainingLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: listing.isClosingSoon24h
                                    ? AppColors.danger
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Amount — hero number, rendered in Sora via CurrencyAmount
                  CurrencyAmount(
                    listing.requestedAmount,
                    currency: listing.currency,
                    fontSize: 27,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(height: 6),
                  // Purpose description
                  Text(
                    listing.purpose,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.76),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // ── Funded progress bar ──────────────────────────────────
                  _FundedProgressBar(
                    offers: _offers,
                    requestedAmount: listing.requestedAmount,
                    kycStatus: listing.kycStatus,
                    isOwner: isOwner,
                  ),

                  const SizedBox(height: 12),

                  // ── Preferred terms badges row ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _TermBadge(
                          '${listing.durationMonths} ${l10n?.months ?? 'months'}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _TermBadge(
                          '${listing.currency} ${fmtAmount(listing.repaymentAmountPerPeriod)}${l10n?.perMonth ?? ' / month'}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TermBadge(
                          listing.suggestedInterestRatePct == null
                              ? (l10n?.borrowerTermsMissing ?? '—')
                              : (l10n?.interestPercent(
                                    listing.suggestedInterestRatePct!
                                        .toStringAsFixed(0),
                                  ) ??
                                  '${listing.suggestedInterestRatePct!.toStringAsFixed(0)}% interest'),
                        ),
                      ),
                    ],
                  ),

                  if (canViewCollateral && listing.hasCollateral) ...[
                    const SizedBox(height: 16),
                    _CollateralDetailsSection(
                      listing: listing,
                      currency: (authState is AuthAuthenticated &&
                              authState.user.incomeCurrency.isNotEmpty)
                          ? authState.user.incomeCurrency
                          : listing.currency,
                      embedded: true,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Offers header ────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        l10n?.offersLabel ?? 'OFFERS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                            ),
                      ),
                      const SizedBox(width: 6),
                      const LiveDot(),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // If the current user is a participant (made an offer) but
                  // isn't the listing owner, show a short note explaining
                  // that only their own offer is visible.
                  if (_isParticipant && !_isOwnerValue)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n?.onlyYourOfferVisible ??
                                  'Only your offer is visible here. The full bid book is visible to the borrower.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Offer tiles ──────────────────────────────────────────
                  if (_offers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          l10n?.noOffersYet ?? 'No offers yet',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                  else
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _newOfferFlash
                            ? [
                                BoxShadow(
                                    color: AppColors.success
                                        .withValues(alpha: 0.2),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                      child: OfferList(
                        offers: _offers,
                        requestedAmount: listing.requestedAmount,
                        isOwner: isOwner,
                        isParticipant: _isParticipant,
                        onAccept: _acceptOffer,
                        durationMonths: listing.durationMonths,
                        isProBorrower: isProBorrower,
                        marketBaselinePct: _marketBaselinePct,
                        suggestedInterestRatePct:
                            listing.suggestedInterestRatePct,
                        suggestedLateFeePct: listing.suggestedLateFeePct,
                        suggestedRepaymentFrequency:
                            listing.suggestedRepaymentFrequency,
                        suggestedInstallmentAmount:
                            listing.suggestedInstallmentAmount,
                        onUpgrade: () => showProRequiredSheet(context),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (listing.suggestedInterestRatePct != null ||
                listing.suggestedLateFeePct != null) ...[
              _ProposedRepaymentPlan(listing: listing),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),

            if (canMakeOffer)
              ElevatedButton(
                onPressed: () {
                  if (user == null) {
                    context.go('/auth/login');
                    return;
                  }
                  if (!user.canLend) {
                    showLenderRequiredSheet(context);
                    return;
                  }
                  setState(() => _showOfferSheet = true);
                },
                child: Text(l10n?.makeAnOffer ?? 'Make an offer'),
              )
            else if (hasMadeOffer)
              _OfferPlacedNotice(),
          ]),
        ),
      ),
      bottomSheet: _showOfferSheet
          ? MakeOfferSheet(
              listing: listing,
              onClose: () => setState(() => _showOfferSheet = false),
              onOfferPlaced: () {
                setState(() => _showOfferSheet = false);
                _loadOnce();
              },
            )
          : null,
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}

class _ProposedRepaymentPlan extends StatefulWidget {
  const _ProposedRepaymentPlan({required this.listing});
  final LoanListing listing;

  @override
  State<_ProposedRepaymentPlan> createState() =>
      _ProposedRepaymentPlanState();
}

class _ProposedRepaymentPlanState extends State<_ProposedRepaymentPlan> {
  bool _expanded = false;

  String fmtAmount(int? n) {
    if (n == null) return '—';
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      )),
            ),
            const SizedBox(width: 8),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listing = widget.listing;
    final currency = listing.currency;
    final installment = listing.suggestedInstallmentAmount;
    final freq = listing.suggestedRepaymentFrequency ?? listing.preferredRepaymentPlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (l10n?.proposedRepaymentPlanLabel ?? 'Proposed repayment plan')
              .toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accent, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${listing.preferredRepaymentPlan} · ${listing.repaymentTimeline}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                      const SizedBox(height: 6),
                      if (installment != null)
                        Text(
                            '$currency ${fmtAmount(installment)} / $freq',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(l10n?.preferredRepaymentPlanLabel ?? 'Preferred repayment plan', listing.preferredRepaymentPlan),
                _row(l10n?.repaymentTimelineLabel ?? 'Repayment timeline & schedule', listing.repaymentTimeline),
                if (installment != null)
                  _row(l10n?.suggestedInstallmentAmountLabel(currency) ?? 'Suggested installment amount ($currency)', '$currency ${fmtAmount(installment)}'),
                if (listing.suggestedInterestRatePct != null)
                  _row('Interest rate', '${listing.suggestedInterestRatePct!.toStringAsFixed(1)}%'),
                if (listing.suggestedLateFeePct != null)
                  _row('Late fee', '${listing.suggestedLateFeePct!.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ]
      ],
    );
  }
}

class _CollateralDetailsSection extends StatelessWidget {
  const _CollateralDetailsSection({
    required this.listing,
    required this.currency,
    this.embedded = false,
  });

  final LoanListing listing;
  final String currency;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = listing.collateralDetails?.trim();
    final location = listing.collateralLocation?.trim();
    final value = listing.collateralEstimatedValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 17,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (l10n?.collateralLabel ?? 'Collateral').toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 11, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      l10n?.securedCollateralLabel ?? 'Secured',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (details?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              details!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (value != null)
                _CollateralFact(
                  icon: Icons.payments_outlined,
                  label: l10n?.estimatedValueLabel ?? 'Estimated value',
                  value: '$currency ${fmtAmount(value)}',
                ),
              if (location?.isNotEmpty == true)
                _CollateralFact(
                  icon: Icons.location_on_outlined,
                  label: l10n?.locationLabel ?? 'Location',
                  value: location!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String fmtAmount(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _CollateralFact extends StatelessWidget {
  const _CollateralFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 135),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.success),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferPlacedNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.offerSubmittedReviewNotice ??
                  'Offer submitted. You can review your offer above.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Funded Progress Bar ─────────────────────────────────────────────────────


class _FundedProgressBar extends StatelessWidget {
  const _FundedProgressBar({
    required this.offers,
    required this.requestedAmount,
    this.kycStatus,
    this.isOwner = false,
  });

  final List<LoanOffer> offers;
  final int requestedAmount;
  final String? kycStatus;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalFunded = offers.fold<int>(0, (s, o) => s + o.offerAmount);
    final pct = requestedAmount > 0
        ? (totalFunded / requestedAmount).clamp(0.0, 1.0)
        : 0.0;
    final pctInt = (pct * 100).round();
    // Offer count is only ever shown to the listing owner.
    // Lenders and participants see a generic "Active listing" label so they
    // cannot discover how many competing bids are in the book.
    final bidsLabel = kycStatus != null
        ? (l10n?.userVerificationStatus(kycStatus!.toUpperCase()) ??
            'User verification status: ${kycStatus!.toUpperCase()}')
        : (isOwner
            ? (offers.isEmpty
                ? (l10n?.noOffersYet ?? 'No offers yet')
                : (l10n?.listingOfferCount(offers.length) ??
                    '${offers.length} offer${offers.length > 1 ? 's' : ''}'))
            : (l10n?.activeListingLabel ?? 'Active listing'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n?.fundedLabel ?? 'Funded',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$pctInt%  · $bidsLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 7,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (offers.isEmpty) {
                  return Container(
                    color: Theme.of(context).dividerColor,
                  );
                }

                // ── Non-owners (lenders / bidders): flat single-colour bar ──
                // A segmented bar reveals exactly how many competing bids
                // exist (one segment = one offer). Lenders must not see
                // that count, so we render a plain filled bar instead.
                if (!isOwner) {
                  return Row(
                    children: [
                      Flexible(
                        flex: (pct * 1000).round().clamp(1, 1000),
                        child: Container(color: AppColors.accent),
                      ),
                      if (pct < 1.0)
                        Flexible(
                          flex: ((1 - pct) * 1000).round().clamp(1, 1000),
                          child:
                              Container(color: Theme.of(context).dividerColor),
                        ),
                    ],
                  );
                }

                // ── Owner: full segmented bar (one colour per offer) ────────
                final total = offers.fold<int>(0, (s, o) => s + o.offerAmount);
                return Row(
                  children: [
                    for (int i = 0; i < offers.length; i++) ...[
                      Flexible(
                        flex: requestedAmount > 0
                            ? (offers[i].offerAmount / requestedAmount * 1000)
                                .round()
                            : 1,
                        child: Container(
                          color: kBidColors[i % kBidColors.length],
                        ),
                      ),
                      if (i < offers.length - 1) const SizedBox(width: 2),
                    ],
                    if (total < requestedAmount)
                      Flexible(
                        flex: ((1 - total / requestedAmount) * 1000).round(),
                        child: Container(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Term Badge ───────────────────────────────────────────────────────────────
// Theme fix: previously branched on Theme.of(context).colorScheme.brightness
// to pick between two hardcoded hex values that happened to (almost)
// duplicate bg3Dark/bg3Light from AppColors. Using surfaceContainerHighest
// directly removes the duplicated logic and stays correct if the theme's
// surface tokens ever change.

class _TermBadge extends StatelessWidget {
  const _TermBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
