// lib/features/marketplace/presentation/pages/loan_detail_page.dart
// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/models/loan_listing.dart';

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

  final _repo = getIt<MarketplaceRepository>();
  StreamSubscription<List<LoanOffer>>? _offersSub;
  StreamSubscription<List<LoanListing>>? _listingSub;

  @override
  void initState() {
    super.initState();
    _loadOnce();
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
    try {
      final listing = await _repo.getListingDetail(widget.requestId);
      if (!mounted) return;

      bool isOwner = false;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
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
        _loading = false;
      });
      _subscribeRealtime();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
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

    _listingSub = _repo.watchListings().listen(
      (listings) {
        if (!mounted) return;
        final updated = listings.where((l) => l.requestId == widget.requestId);
        if (updated.isNotEmpty) setState(() => _listing = updated.first);
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid accepted — contract generated.')));
      // Navigate to agreement review page
      context.go('/marketplace/agreement/$agreementId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: AppColors.danger));
    }
  }

  void _showSubscriptionGate(
      {required String requiredPlan, required String reason}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SubscriptionGateSheet(
        requiredPlan: requiredPlan,
        reason: reason,
        onUpgrade: () {
          Navigator.pop(context);
          context.go('/account');
        },
      ),
    );
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
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isOwner = _isOwnerValue;
    // Pro borrowers see term-comparison arrows on each bid card
    final isProBorrower = isOwner &&
        authState is AuthAuthenticated &&
        authState.user.canSuggestBorrowerTerms;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Listing Detail'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOnce,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(listing.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            UgxAmount(listing.requestedAmount, fontSize: 26),
            const SizedBox(height: 16),

            _DescriptionSection(
                title: 'Proposed Repayment Plan',
                body:
                    '${listing.preferredRepaymentPlan}\n${listing.repaymentTimeline}'),
            if (listing.suggestedInterestRatePct != null ||
                listing.suggestedLateFeePct != null ||
                listing.suggestedRepaymentFrequency != null ||
                listing.suggestedInstallmentAmount != null) ...[
              const SizedBox(height: 12),
              _DescriptionSection(
                title: 'Borrower Suggested Terms',
                body: [
                  if (listing.suggestedInterestRatePct != null)
                    '${listing.suggestedInterestRatePct!.toStringAsFixed(2)}% interest',
                  if (listing.suggestedLateFeePct != null)
                    '${listing.suggestedLateFeePct!.toStringAsFixed(2)}% late fee on missed installment',
                  if (listing.suggestedRepaymentFrequency != null)
                    listing.suggestedRepaymentFrequency!,
                  if (listing.suggestedInstallmentAmount != null)
                    'UGX ${listing.suggestedInstallmentAmount} installment',
                ].join('\n'),
              ),
            ],
            const SizedBox(height: 12),
            _DescriptionSection(
                title: 'Purpose of Loan', body: listing.purpose),

            const SizedBox(height: 24),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                _StatBox(label: 'Bids', value: '${listing.numberOfOffers}'),
                _StatBox(
                    label: 'Repayment',
                    value:
                        'UGX ${listing.repaymentAmountPerPeriod.toString()}'),
                _StatBox(
                    label: 'Duration',
                    value: '${listing.durationMonths} Months'),
                _StatBox(
                  label: 'Time left',
                  value: listing.timeRemainingLabel,
                  valueColor: listing.isClosingSoon6h ? AppColors.danger : null,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Live order book (Bids)
            const Row(children: [
              SectionHeader('Current Bids'),
              SizedBox(width: 8),
              LiveDot(),
            ]),
            const SizedBox(height: 8),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: _newOfferFlash
                    ? [
                        BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.2),
                            blurRadius: 8)
                      ]
                    : [],
              ),
              child: _OfferList(
                offers: _offers,
                requestedAmount: listing.requestedAmount,
                isOwner: isOwner,
                onAccept: _acceptOffer,
                durationMonths: listing.durationMonths,
                isProBorrower: isProBorrower,
                suggestedInterestRatePct: listing.suggestedInterestRatePct,
                suggestedLateFeePct: listing.suggestedLateFeePct,
                suggestedRepaymentFrequency:
                    listing.suggestedRepaymentFrequency,
                suggestedInstallmentAmount: listing.suggestedInstallmentAmount,
                onUpgrade: () => _showSubscriptionGate(
                  requiredPlan: 'Pro',
                  reason:
                      'Unlock relative comparison arrows and cost deltas with a PRO borrower subscription.',
                ),
              ),
            ),

            const SizedBox(height: 32),

            if (!isOwner)
              ElevatedButton(
                onPressed: () {
                  if (user == null) {
                    context.go('/auth/login');
                    return;
                  }
                  if (!user.canLend) {
                    _showSubscriptionGate(
                      requiredPlan: 'Lender',
                      reason: 'A subscription is required to make bids.',
                    );
                    return;
                  }
                  setState(() => _showOfferSheet = true);
                },
                child: const Text('Make a Bid'),
              ),
          ]),
        ),
      ),
      bottomSheet: _showOfferSheet
          ? _MakeOfferSheet(
              listing: listing,
              onClose: () => setState(() => _showOfferSheet = false),
              onOfferPlaced: () => setState(() => _showOfferSheet = false),
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

// ─── Offer list ─────────────────────────────────────────────────────────────

class _OfferList extends StatelessWidget {
  const _OfferList({
    required this.offers,
    required this.requestedAmount,
    required this.isOwner,
    required this.onAccept,
    required this.durationMonths,
    required this.onUpgrade,
    this.suggestedInterestRatePct,
    this.suggestedLateFeePct,
    this.suggestedRepaymentFrequency,
    this.suggestedInstallmentAmount,
    this.isProBorrower = false,
  });

  final List<LoanOffer> offers;
  final int requestedAmount;
  final bool isOwner;
  final Function(LoanOffer) onAccept;
  final int durationMonths;
  final VoidCallback onUpgrade;
  // Borrower's suggested terms (Pro only comparison)
  final double? suggestedInterestRatePct;
  final double? suggestedLateFeePct;
  final String? suggestedRepaymentFrequency;
  final int? suggestedInstallmentAmount;
  final bool isProBorrower;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12)),
        child: const Text('No bids yet.', textAlign: TextAlign.center),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _OfferCard(
        offer: offers[index],
        index: index,
        requestedAmount: requestedAmount,
        isOwner: isOwner,
        onAccept: onAccept,
        durationMonths: durationMonths,
        suggestedInterestRatePct: suggestedInterestRatePct,
        suggestedLateFeePct: suggestedLateFeePct,
        suggestedInstallmentAmount: suggestedInstallmentAmount,
        suggestedRepaymentFrequency: suggestedRepaymentFrequency,
        isProBorrower: isProBorrower,
        onUpgrade: onUpgrade,
      ),
    );
  }
}

// ─── Single expandable offer card ────────────────────────────────────────────

class _OfferCard extends StatefulWidget {
  const _OfferCard({
    required this.offer,
    required this.index,
    required this.requestedAmount,
    required this.isOwner,
    required this.onAccept,
    required this.durationMonths,
    required this.onUpgrade,
    this.suggestedInterestRatePct,
    this.suggestedLateFeePct,
    this.suggestedInstallmentAmount,
    this.suggestedRepaymentFrequency,
    this.isProBorrower = false,
  });

  final LoanOffer offer;
  final int index;
  final int requestedAmount;
  final bool isOwner;
  final Function(LoanOffer) onAccept;
  final int durationMonths;
  final VoidCallback onUpgrade;
  final double? suggestedInterestRatePct;
  final double? suggestedLateFeePct;
  final int? suggestedInstallmentAmount;
  final String? suggestedRepaymentFrequency;
  final bool isProBorrower;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _anim;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _expandAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _anim.forward() : _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final lenderLabel = offer.hasMaskedLender
        ? 'Lender #${widget.index + 1}'
        : 'Lender #${offer.lenderId.substring(0, 5)}';
    final coverage = widget.requestedAmount <= 0
        ? 0
        : ((offer.offerAmount / widget.requestedAmount) * 100).round();
    final isFull = offer.offerAmount >= widget.requestedAmount;
    final offerType = isFull ? 'Full bid' : 'Partial bid · $coverage%';

    final isComparing = widget.isOwner &&
        (widget.suggestedInterestRatePct != null ||
            widget.suggestedLateFeePct != null ||
            widget.suggestedInstallmentAmount != null);

    // ── Comparison calculations ──
    double? interestDiff;
    double? interestDiffPct;
    bool? isInterestFavorable;
    if (widget.suggestedInterestRatePct != null) {
      interestDiff = offer.interestRatePct - widget.suggestedInterestRatePct!;
      if (widget.suggestedInterestRatePct! > 0) {
        interestDiffPct =
            (interestDiff / widget.suggestedInterestRatePct!) * 100;
      } else {
        interestDiffPct = 0.0;
      }
      if (interestDiff.abs() < 0.005) {
        isInterestFavorable = null; // flat
      } else if (interestDiff < 0) {
        isInterestFavorable = true; // lower is better
      } else {
        isInterestFavorable = false; // higher is worse
      }
    }

    double? lateFeeDiff;
    double? lateFeeDiffPct;
    bool? isLateFeeFavorable;
    if (widget.suggestedLateFeePct != null) {
      lateFeeDiff = offer.lateFeePct - widget.suggestedLateFeePct!;
      if (widget.suggestedLateFeePct! > 0) {
        lateFeeDiffPct = (lateFeeDiff / widget.suggestedLateFeePct!) * 100;
      } else {
        lateFeeDiffPct = 0.0;
      }
      if (lateFeeDiff.abs() < 0.005) {
        isLateFeeFavorable = null; // flat
      } else if (lateFeeDiff < 0) {
        isLateFeeFavorable = true; // lower is better
      } else {
        isLateFeeFavorable = false; // higher is worse
      }
    }

    int? installmentDiff;
    double? installmentDiffPct;
    bool? isInstallmentFavorable;
    if (widget.suggestedInstallmentAmount != null) {
      installmentDiff =
          offer.installmentAmount - widget.suggestedInstallmentAmount!;
      if (widget.suggestedInstallmentAmount! > 0) {
        installmentDiffPct =
            (installmentDiff / widget.suggestedInstallmentAmount!) * 100;
      } else {
        installmentDiffPct = 0.0;
      }
      if (installmentDiff == 0) {
        isInstallmentFavorable = null; // flat
      } else if (installmentDiff < 0) {
        isInstallmentFavorable = true; // lower is better
      } else {
        isInstallmentFavorable = false; // higher is worse
      }
    }

    final String interestDiffValText =
        interestDiff != null ? '${interestDiff.abs().toStringAsFixed(2)}%' : '';
    final String interestDiffPctText = interestDiffPct != null
        ? '${interestDiffPct.abs().toStringAsFixed(1)}%'
        : '';

    final String lateFeeDiffValText =
        lateFeeDiff != null ? '${lateFeeDiff.abs().toStringAsFixed(2)}%' : '';
    final String lateFeeDiffPctText = lateFeeDiffPct != null
        ? '${lateFeeDiffPct.abs().toStringAsFixed(1)}%'
        : '';

    final String installmentDiffValText =
        installmentDiff != null ? 'UGX ${_fmt(installmentDiff.abs())}' : '';
    final String installmentDiffPctText = installmentDiffPct != null
        ? '${installmentDiffPct.abs().toStringAsFixed(1)}%'
        : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.accent.withValues(alpha: 0.4)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  size: 14, color: AppColors.accent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lenderLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      offerType,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                isFull ? AppColors.success : AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ]),
            ),
            const SizedBox(width: 8),
            UgxAmount(offer.offerAmount, fontSize: 15),
          ]),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Divider(height: 1),
        ),

        // ── Stock Ticker Comparison Rows ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Column(
            children: [
              _StockTermRow(
                label: 'Interest Rate',
                value: '${offer.interestRatePct.toStringAsFixed(2)}%',
                diffValueText: interestDiffValText,
                diffPercentText: interestDiffPctText,
                isPositiveTrend: isInterestFavorable,
                isComparing: widget.suggestedInterestRatePct != null,
                isPro: widget.isProBorrower,
                suggestedText: widget.suggestedInterestRatePct != null
                    ? '${widget.suggestedInterestRatePct!.toStringAsFixed(2)}%'
                    : null,
                onUpgrade: widget.onUpgrade,
              ),
              const Divider(height: 1, indent: 4, endIndent: 4),
              _StockTermRow(
                label: 'Late Payment Fine',
                value: '${offer.lateFeePct.toStringAsFixed(2)}%',
                diffValueText: lateFeeDiffValText,
                diffPercentText: lateFeeDiffPctText,
                isPositiveTrend: isLateFeeFavorable,
                isComparing: widget.suggestedLateFeePct != null,
                isPro: widget.isProBorrower,
                suggestedText: widget.suggestedLateFeePct != null
                    ? '${widget.suggestedLateFeePct!.toStringAsFixed(2)}%'
                    : null,
                onUpgrade: widget.onUpgrade,
              ),
              const Divider(height: 1, indent: 4, endIndent: 4),
              _StockTermRow(
                label: 'Installment Amount',
                value: 'UGX ${_fmt(offer.installmentAmount)}',
                diffValueText: installmentDiffValText,
                diffPercentText: installmentDiffPctText,
                isPositiveTrend: isInstallmentFavorable,
                isComparing: widget.suggestedInstallmentAmount != null,
                isPro: widget.isProBorrower,
                suggestedText: widget.suggestedInstallmentAmount != null
                    ? 'UGX ${_fmt(widget.suggestedInstallmentAmount!)}'
                    : null,
                onUpgrade: widget.onUpgrade,
              ),
              const Divider(height: 1, indent: 4, endIndent: 4),
              _StockTermRow(
                label: 'Repayment Schedule',
                value: _freqLabel(offer.repaymentFrequency),
                isComparing: widget.suggestedRepaymentFrequency != null,
                isPro: widget.isProBorrower,
                isPositiveTrend: null,
                suggestedText: widget.suggestedRepaymentFrequency != null
                    ? _freqLabel(widget.suggestedRepaymentFrequency!)
                    : null,
                onUpgrade: widget.onUpgrade,
              ),
            ],
          ),
        ),

        // ── Pro comparison legend ────────────────────────────────────────────
        if (isComparing && widget.isProBorrower) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 11, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                'Indicators compare bid terms side-by-side with your original suggestions',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.accent, fontSize: 10),
              ),
            ]),
          ),
        ],

        // ── More / Less toggle ───────────────────────────────────────────────
        GestureDetector(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Row(children: [
              Text(
                _expanded ? 'Less details' : 'More details',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more_rounded,
                    size: 14, color: AppColors.accent),
              ),
            ]),
          ),
        ),

        // ── Expanded details ─────────────────────────────────────────────────
        SizeTransition(
          sizeFactor: _expandAnim,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Divider(height: 1, color: Theme.of(context).dividerColor),
              const SizedBox(height: 12),

              // Installment Math breakdown ("How this number came about")
              _CalculatorRowDetailPanel(
                offer: offer,
                durationMonths: widget.durationMonths,
              ),

              // Deal Comparison Analytics or Upgrade Lock Banner
              if (widget.isOwner) ...[
                if (widget.isProBorrower)
                  _ProAnalysisPanel(
                    interestDiff: interestDiff,
                    lateFeeDiff: lateFeeDiff,
                    installmentDiff: installmentDiff,
                    suggestedInterest: widget.suggestedInterestRatePct,
                    suggestedLateFee: widget.suggestedLateFeePct,
                    suggestedInstallment: widget.suggestedInstallmentAmount,
                    offeredInterest: offer.interestRatePct,
                    offeredLateFee: offer.lateFeePct,
                    offeredInstallment: offer.installmentAmount,
                  )
                else
                  _ProUpgradePanel(onUpgrade: widget.onUpgrade),
              ],

              const SizedBox(height: 12),
              if (offer.termsLockedAt != null)
                _DetailRow(
                    label: 'Terms locked',
                    value: _dateLabel(offer.termsLockedAt!)),
              if (offer.proposedExpectations != null &&
                  offer.proposedExpectations!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Lender notes',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.accent)),
                const SizedBox(height: 4),
                Text(offer.proposedExpectations!,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
              ],
            ]),
          ),
        ),

        // ── Accept button (owner only) ───────────────────────────────────────
        if (widget.isOwner) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => widget.onAccept(offer),
                child: const Text('Accept Bid'),
              ),
            ),
          ),
        ] else
          const SizedBox(height: 12),
      ]),
    );
  }
}

// ─── Sparkline payoff curve painter ──────────────────────────────────────────

class _SparklineWidget extends StatelessWidget {
  const _SparklineWidget({
    required this.isPositive,
  });

  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive == null
        ? (Theme.of(context).colorScheme.brightness == Brightness.dark
            ? AppColors.text3Dark
            : AppColors.text3Light)
        : (isPositive! ? AppColors.success : AppColors.danger);

    return CustomPaint(
      size: const Size(55, 18),
      painter: _SparklinePainter(isPositive: isPositive, color: color),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.isPositive, required this.color});

  final bool? isPositive;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.16),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final points = <Offset>[];
    final step = size.width / 5;

    if (isPositive == null) {
      points.add(Offset(0, size.height * 0.5));
      points.add(Offset(step, size.height * 0.46));
      points.add(Offset(step * 2, size.height * 0.54));
      points.add(Offset(step * 3, size.height * 0.48));
      points.add(Offset(step * 4, size.height * 0.52));
      points.add(Offset(size.width, size.height * 0.5));
    } else if (isPositive!) {
      points.add(Offset(0, size.height * 0.22));
      points.add(Offset(step, size.height * 0.32));
      points.add(Offset(step * 2, size.height * 0.26));
      points.add(Offset(step * 3, size.height * 0.58));
      points.add(Offset(step * 4, size.height * 0.48));
      points.add(Offset(size.width, size.height * 0.8));
    } else {
      points.add(Offset(0, size.height * 0.78));
      points.add(Offset(step, size.height * 0.68));
      points.add(Offset(step * 2, size.height * 0.74));
      points.add(Offset(step * 3, size.height * 0.42));
      points.add(Offset(step * 4, size.height * 0.52));
      points.add(Offset(size.width, size.height * 0.2));
    }

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(points.last, 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Stock Term Row Widget ───────────────────────────────────────────────────

class _StockTermRow extends StatelessWidget {
  const _StockTermRow({
    required this.label,
    required this.value,
    this.diffValueText,
    this.diffPercentText,
    required this.isPositiveTrend,
    required this.isPro,
    required this.isComparing,
    this.suggestedText,
    required this.onUpgrade,
  });

  final String label;
  final String value;
  final String? diffValueText;
  final String? diffPercentText;
  final bool? isPositiveTrend;
  final bool isPro;
  final bool isComparing;
  final String? suggestedText;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final Color trendColor;
    final IconData trendIcon;
    final String sign;
    if (isPositiveTrend == null) {
      trendColor = Theme.of(context).colorScheme.brightness == Brightness.dark
          ? AppColors.text2Dark
          : AppColors.text2Light;
      trendIcon = Icons.trending_flat_rounded;
      sign = '';
    } else if (isPositiveTrend!) {
      trendColor = AppColors.success;
      trendIcon = Icons.trending_down_rounded;
      sign = '-';
    } else {
      trendColor = AppColors.danger;
      trendIcon = Icons.trending_up_rounded;
      sign = '+';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                if (isComparing && suggestedText != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    'Suggested: $suggestedText',
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: isComparing
                ? Center(
                    child: isPro
                        ? _SparklineWidget(isPositive: isPositiveTrend)
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.16,
                                child: _SparklineWidget(
                                    isPositive: isPositiveTrend),
                              ),
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.35),
                              ),
                            ],
                          ),
                  )
                : const SizedBox(),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppFonts.body,
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (isComparing) ...[
                  const SizedBox(height: 1),
                  isPro
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(trendIcon, size: 10, color: trendColor),
                            const SizedBox(width: 2),
                            Text(
                              '$sign$diffValueText ($diffPercentText)',
                              style: textTheme.bodySmall?.copyWith(
                                color: trendColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: onUpgrade,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_rounded,
                                    size: 8, color: AppColors.purple),
                                const SizedBox(width: 2),
                                Text(
                                  'PRO DELTA',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.purple,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calculator widgets ──────────────────────────────────────────────────────

class _CalculatorRowDetailPanel extends StatelessWidget {
  const _CalculatorRowDetailPanel({
    required this.offer,
    required this.durationMonths,
  });

  final LoanOffer offer;
  final int durationMonths;

  @override
  Widget build(BuildContext context) {
    final frequencyText = _freqLabel(offer.repaymentFrequency);
    final periods = offer.repaymentFrequency == 'monthly'
        ? durationMonths
        : (offer.repaymentFrequency == 'weekly' ? durationMonths * 4 : 1);
    final totalRepayable = offer.installmentAmount * periods;
    final totalInterest = totalRepayable - offer.offerAmount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined,
                  size: 15, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                'Installment Cost Breakdown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Formula: Installment × RepaymentsCount = Total Payback',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 10,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 8),
          _CalculatorRow(
            label: 'Offered Installment',
            value: 'UGX ${_fmt(offer.installmentAmount)}',
          ),
          _CalculatorRow(
            label: 'Repayments Plan',
            value: '× $periods $frequencyText payments',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 3.0),
            child: Divider(height: 1),
          ),
          _CalculatorRow(
            label: 'Total Payback Amount',
            value: 'UGX ${_fmt(totalRepayable)}',
            isBold: true,
          ),
          _CalculatorRow(
            label: 'Principal Borrowed',
            value: 'UGX ${_fmt(offer.offerAmount)}',
            subtle: true,
          ),
          _CalculatorRow(
            label: 'Borrowing Cost (Total Interest)',
            value: 'UGX ${_fmt(totalInterest.clamp(0, totalInterest))}',
            valueColor: AppColors.success,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _CalculatorRow extends StatelessWidget {
  const _CalculatorRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.subtle = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final bool subtle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11.5,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: subtle
          ? Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)
          : Theme.of(context).colorScheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: style.copyWith(
              color: valueColor ?? style.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pro Analysis & Upgrade CTAs ──────────────────────────────────────────────

class _ProAnalysisPanel extends StatelessWidget {
  const _ProAnalysisPanel({
    this.interestDiff,
    this.lateFeeDiff,
    this.installmentDiff,
    this.suggestedInterest,
    this.suggestedLateFee,
    this.suggestedInstallment,
    required this.offeredInterest,
    required this.offeredLateFee,
    required this.offeredInstallment,
  });

  final double? interestDiff;
  final double? lateFeeDiff;
  final int? installmentDiff;
  final double? suggestedInterest;
  final double? suggestedLateFee;
  final int? suggestedInstallment;
  final double offeredInterest;
  final double offeredLateFee;
  final int offeredInstallment;

  @override
  Widget build(BuildContext context) {
    final notes = StringBuffer();
    bool parsedAny = false;

    if (interestDiff != null && suggestedInterest != null) {
      parsedAny = true;
      if (interestDiff!.abs() < 0.005) {
        notes.write('• Interest rate matches your requested rate.\n');
      } else if (interestDiff! < 0) {
        notes.write(
            '• Interest is LOWER by ${interestDiff!.abs().toStringAsFixed(2)}% (reduces cost).\n');
      } else {
        notes.write(
            '• Interest is HIGHER by ${interestDiff!.abs().toStringAsFixed(2)}% (increases cost).\n');
      }
    }

    if (lateFeeDiff != null && suggestedLateFee != null) {
      parsedAny = true;
      if (lateFeeDiff!.abs() < 0.005) {
        notes.write('• Late payment penalty matches your suggested rate.\n');
      } else if (lateFeeDiff! < 0) {
        notes.write(
            '• Penalty charge fine: LOWER by ${lateFeeDiff!.abs().toStringAsFixed(2)}% (safer payment guard).\n');
      } else {
        notes.write(
            '• Penalty fine is HIGHER by ${lateFeeDiff!.abs().toStringAsFixed(2)}% (higher penalty risk).\n');
      }
    }

    if (installmentDiff != null && suggestedInstallment != null) {
      parsedAny = true;
      if (installmentDiff == 0) {
        notes.write('• Period installment matches your expectations.\n');
      } else if (installmentDiff! < 0) {
        notes.write(
            '• Installment payment is LOWER by UGX ${_fmt(installmentDiff!.abs())}.\n');
      } else {
        notes.write(
            '• Installment cost is HIGHER by UGX ${_fmt(installmentDiff!.abs())}.\n');
      }
    }

    final analysisText = parsedAny
        ? notes.toString().trim()
        : 'Bid matches your proposed expectations.';

    final Color trendColor;
    if ((interestDiff ?? 0) < 0 ||
        (lateFeeDiff ?? 0) < 0 ||
        (installmentDiff ?? 0) < 0) {
      trendColor = AppColors.success;
    } else if ((interestDiff ?? 0) > 0 ||
        (lateFeeDiff ?? 0) > 0 ||
        (installmentDiff ?? 0) > 0) {
      trendColor = AppColors.danger;
    } else {
      trendColor = AppColors.accent;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: trendColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.query_stats_rounded, size: 15, color: trendColor),
              const SizedBox(width: 6),
              Text(
                'PRO Comparison Analysis',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: trendColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            analysisText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.35,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProUpgradePanel extends StatelessWidget {
  const _ProUpgradePanel({required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_person_outlined,
                  size: 15, color: AppColors.purple),
              const SizedBox(width: 6),
              Text(
                'Unlock Deal Comparison',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.purple,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Upgrade to a PRO borrower subscription to see how interest rates, payment fines, and installments stack up against your goals with comparative sparklines and instant delta calculations.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                  height: 1.35,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: onUpgrade,
              child: const Text(
                'Upgrade to PRO',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expanded detail row ──────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.6))),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(int v) {
  if (v == 0) return '0';
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _freqLabel(String f) {
  switch (f) {
    case 'weekly':
      return 'Weekly';
    case 'one_time':
      return 'One-time';
    default:
      return 'Monthly';
  }
}

String _dateLabel(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
        ]),
      );
}

class _SubscriptionGateSheet extends StatelessWidget {
  const _SubscriptionGateSheet(
      {required this.requiredPlan,
      required this.reason,
      required this.onUpgrade});
  final String requiredPlan;
  final String reason;
  final VoidCallback onUpgrade;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_person_outlined,
              size: 48, color: AppColors.accent),
          const SizedBox(height: 16),
          Text('Upgrade Required',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(reason, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: onUpgrade, child: Text('Upgrade to $requiredPlan')),
        ]),
      );
}

class _MakeOfferSheet extends StatefulWidget {
  const _MakeOfferSheet(
      {required this.listing,
      required this.onClose,
      required this.onOfferPlaced});
  final LoanListing listing;
  final VoidCallback onClose;
  final VoidCallback onOfferPlaced;
  @override
  State<_MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<_MakeOfferSheet> {
  final _amountController = TextEditingController();
  final _expController = TextEditingController();
  final _interestController = TextEditingController();
  final _lateFeeController = TextEditingController();
  final _installmentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _repaymentFrequency = 'monthly';
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _expController.dispose();
    _interestController.dispose();
    _lateFeeController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<MarketplaceRepository>().makeOffer(
        requestId: widget.listing.requestId,
        amount: int.parse(_amountController.text.replaceAll(',', '')),
        interestRatePct: double.parse(_interestController.text),
        lateFeePct: double.parse(_lateFeeController.text),
        repaymentFrequency: _repaymentFrequency,
        installmentAmount:
            int.parse(_installmentController.text.replaceAll(',', '')),
        expectations: _expController.text,
      );
      widget.onOfferPlaced();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bid sent successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Make a Bid',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose)
                    ]),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Amount (UGX)',
                          prefixIcon: Icon(Icons.payments_outlined)),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter amount' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _interestController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Interest rate (%)',
                          prefixIcon: Icon(Icons.percent_rounded)),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 100) {
                          return 'Use 0 to 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lateFeeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Late payment fee (%)',
                          prefixIcon: Icon(Icons.warning_amber_rounded)),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 100) {
                          return 'Use 0 to 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _repaymentFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Repayment schedule',
                        prefixIcon: Icon(Icons.event_repeat_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(
                            value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(
                            value: 'one_time', child: Text('One-time payment')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _repaymentFrequency = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _installmentController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Installment amount (UGX)',
                          prefixIcon: Icon(Icons.price_check_outlined)),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter amount' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _expController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Additional expectations',
                          hintText: 'Optional notes for the borrower',
                          alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Send Bid')),
                  ])),
        ),
      );
}
