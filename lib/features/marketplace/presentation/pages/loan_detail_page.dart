// lib/features/marketplace/presentation/pages/loan_detail_page.dart
// ignore_for_file: unused_import, unused_element, unused_element_parameter

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

    // Force-refresh subscription plan in case it changed since login
    context.read<AuthBloc>().add(const AuthProfileRefreshRequested());

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
        title: const Text('Listing detail'),
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
                border: Border.all(color: Theme.of(context).dividerColor),
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
                        child: Text(
                          listing.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Theme fix: was a hardcoded Color(0xFF6E1717) box that
                      // never adapted to light mode. Now built from
                      // AppColors.danger so both themes read as an urgency tag,
                      // consistent with the success/warning tint pattern used
                      // elsewhere on this screen.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 11, color: AppColors.danger),
                            const SizedBox(width: 4),
                            Text(
                              listing.timeRemainingLabel,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Amount — hero number, rendered in Sora via UgxAmount
                  UgxAmount(
                    listing.requestedAmount,
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
                  ),

                  const SizedBox(height: 12),

                  // ── Preferred terms badges row ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                          child:
                              _TermBadge('${listing.durationMonths} months')),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _TermBadge(
                            'UGX ${_fmt(listing.repaymentAmountPerPeriod)} / month'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TermBadge(
                            '${listing.suggestedInterestRatePct?.toStringAsFixed(0) ?? '0'}% interest'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Bids header ──────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'BIDS',
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

                  // ── Bid tiles ──────────────────────────────────────────
                  if (_offers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No bids yet.',
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
                      child: _OfferList(
                        offers: _offers,
                        requestedAmount: listing.requestedAmount,
                        isOwner: isOwner,
                        onAccept: _acceptOffer,
                        durationMonths: listing.durationMonths,
                        isProBorrower: isProBorrower,
                        suggestedInterestRatePct:
                            listing.suggestedInterestRatePct,
                        suggestedLateFeePct: listing.suggestedLateFeePct,
                        suggestedRepaymentFrequency:
                            listing.suggestedRepaymentFrequency,
                        suggestedInstallmentAmount:
                            listing.suggestedInstallmentAmount,
                        onUpgrade: () => _showSubscriptionGate(
                          requiredPlan: 'Pro',
                          reason:
                              'Unlock relative comparison arrows and cost deltas with a PRO borrower subscription.',
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Additional details card ──────────────────────────────────────
            if (listing.suggestedInterestRatePct != null ||
                listing.suggestedLateFeePct != null) ...[
              _DescriptionSection(
                  title: 'Proposed repayment plan',
                  body:
                      '${listing.preferredRepaymentPlan}  ·  ${listing.repaymentTimeline}'),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),

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
                child: const Text('Make a bid'),
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

// ─── Funded Progress Bar ─────────────────────────────────────────────────────

const List<Color> _kBidColors = [
  Color(0xFF3B82F6), // blue
  Color(0xFF60A5FA), // light blue
  Color(0xFF10B981), // green
  Color(0xFFF59E0B), // amber
  Color(0xFF8B5CF6), // purple
];

class _FundedProgressBar extends StatelessWidget {
  const _FundedProgressBar({
    required this.offers,
    required this.requestedAmount,
    this.kycStatus,
  });

  final List<LoanOffer> offers;
  final int requestedAmount;
  final String? kycStatus;

  @override
  Widget build(BuildContext context) {
    final totalFunded = offers.fold<int>(0, (s, o) => s + o.offerAmount);
    final pct = requestedAmount > 0
        ? (totalFunded / requestedAmount).clamp(0.0, 1.0)
        : 0.0;
    final pctInt = (pct * 100).round();
    final bidsLabel = kycStatus != null
        ? 'User verification status: ${kycStatus!.toUpperCase()}'
        : (offers.isEmpty
            ? 'No bids'
            : '${offers.length} bid${offers.length > 1 ? 's' : ''}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Funded',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const Spacer(),
            Text(
              '$pctInt%  · $bidsLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
                          color: _kBidColors[i % _kBidColors.length],
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
  final double? suggestedInterestRatePct;
  final double? suggestedLateFeePct;
  final String? suggestedRepaymentFrequency;
  final int? suggestedInstallmentAmount;
  final bool isProBorrower;

  @override
  Widget build(BuildContext context) {
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
        dotColor: _kBidColors[index % _kBidColors.length],
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
    required this.dotColor,
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
  final Color dotColor;
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
    final offerType = isFull ? 'Full bid' : 'Partial · $coverage%';
    final dotColor = widget.dotColor;

    // Theme fix: previously Color(0xFF07340A)/Color(0xFF082F0B), two
    // hand-picked dark greens that only worked against a near-black
    // background and broke in light mode. A translucent tint of
    // AppColors.success reads correctly against both surface colors.
    final rowBg = isFull
        ? AppColors.success.withValues(alpha: 0.08)
        : Theme.of(context).colorScheme.surface;
    final expandedBg =
        isFull ? AppColors.success.withValues(alpha: 0.05) : rowBg;
    final borderColor = isFull
        ? AppColors.success.withValues(alpha: 0.35)
        : Theme.of(context).dividerColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Colored dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Lender label
                  Flexible(
                    child: Text(
                      lenderLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isFull ? AppColors.success : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Bid type badge
                  Text(
                    offerType,
                    style: TextStyle(
                      fontSize: 11,
                      color: isFull
                          ? AppColors.success.withValues(alpha: 0.75)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  // Amount + chevron.
                  // Fix: these two used to sit directly in the row as a bare
                  // Text and a bare Icon. Text's layout box follows the
                  // font's line-height metrics while Icon's follows its
                  // literal `size`, so even with the Row's default
                  // crossAxisAlignment.center the two visually sat a couple
                  // pixels off from each other. Giving both a matching
                  // fixed-height SizedBox + Center pins them to the same
                  // box, so centering is exact regardless of font metrics.
                  SizedBox(
                    height: 20,
                    child: Center(
                      child: Text(
                        _fmt(offer.offerAmount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: isFull ? AppColors.success : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 20,
                    width: 18,
                    child: Center(
                      child: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isFull
                              ? AppColors.success.withValues(alpha: 0.7)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded details ───────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: expandedBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                    color: borderColor,
                  ),
                  // Enhanced term rows with trend arrows
                  _BidTermRow(
                    label: 'Interest rate',
                    value: '${offer.interestRatePct.toStringAsFixed(2)}%',
                    diff: widget.suggestedInterestRatePct != null
                        ? offer.interestRatePct -
                            widget.suggestedInterestRatePct!
                        : null,
                    diffLabel: widget.suggestedInterestRatePct != null
                        ? '${offer.interestRatePct.toStringAsFixed(1)} vs ${widget.suggestedInterestRatePct!.toStringAsFixed(1)}%'
                        : null,
                    lowerIsBetter: true,
                    baseColor: isFull ? AppColors.success : null,
                  ),
                  _BidTermRow(
                    label: 'Monthly fine',
                    value: '${offer.lateFeePct.toStringAsFixed(2)}%',
                    diff: widget.suggestedLateFeePct != null
                        ? offer.lateFeePct - widget.suggestedLateFeePct!
                        : null,
                    diffLabel: widget.suggestedLateFeePct != null
                        ? 'penalty on late payment'
                        : null,
                    lowerIsBetter: true,
                    baseColor: isFull ? AppColors.success : null,
                  ),
                  _BidTermRow(
                    label: 'Monthly installment',
                    value:
                        'UGX ${_fmt(offer.installmentAmount)} ${_freqLabel(offer.repaymentFrequency).toLowerCase()}',
                    diff: widget.suggestedInstallmentAmount != null
                        ? (offer.installmentAmount -
                                widget.suggestedInstallmentAmount!)
                            .toDouble()
                        : null,
                    diffLabel: widget.suggestedInstallmentAmount != null
                        ? 'UGX ${_fmt((offer.installmentAmount - widget.suggestedInstallmentAmount!).abs())} difference'
                        : null,
                    lowerIsBetter: true,
                    baseColor: isFull ? AppColors.success : null,
                  ),
                  // ── Total payable summary row ──────────────────────────────
                  _TotalPayableRow(
                    offer: offer,
                    durationMonths: widget.durationMonths,
                    isFull: isFull,
                  ),

                  // Pro comparison analytics (owner only)
                  if (widget.isOwner) ...[
                    if (widget.isProBorrower) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ProAnalysisPanel(
                          interestDiff: widget.suggestedInterestRatePct != null
                              ? offer.interestRatePct -
                                  widget.suggestedInterestRatePct!
                              : null,
                          lateFeeDiff: widget.suggestedLateFeePct != null
                              ? offer.lateFeePct - widget.suggestedLateFeePct!
                              : null,
                          installmentDiff:
                              widget.suggestedInstallmentAmount != null
                                  ? offer.installmentAmount -
                                      widget.suggestedInstallmentAmount!
                                  : null,
                          suggestedInterest: widget.suggestedInterestRatePct,
                          suggestedLateFee: widget.suggestedLateFeePct,
                          suggestedInstallment:
                              widget.suggestedInstallmentAmount,
                          offeredInterest: offer.interestRatePct,
                          offeredLateFee: offer.lateFeePct,
                          offeredInstallment: offer.installmentAmount,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ] else ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ProUpgradePanel(onUpgrade: widget.onUpgrade),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],

                  if (offer.proposedExpectations != null &&
                      offer.proposedExpectations!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text(
                        'Lender notes',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                      child: Text(offer.proposedExpectations!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],

                  // Accept button (owner only)
                  if (widget.isOwner) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => widget.onAccept(offer),
                          child: const Text('Accept bid'),
                        ),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
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

class _BidDetailRow extends StatelessWidget {
  const _BidDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ??
                        Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.72),
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ??
                      Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Enhanced bid term row with trend arrow ───────────────────────────────────

class _BidTermRow extends StatelessWidget {
  const _BidTermRow({
    required this.label,
    required this.value,
    this.diff,
    this.diffLabel,
    this.lowerIsBetter = true,
    this.baseColor,
  });

  final String label;
  final String value;
  final double? diff; // positive = higher than suggested
  final String? diffLabel;
  final bool lowerIsBetter;
  final Color? baseColor;

  @override
  Widget build(BuildContext context) {
    final hasDiff = diff != null;
    final bool? isGood = hasDiff
        ? (diff!.abs() < 0.01
            ? null
            : (lowerIsBetter ? diff! < 0 : diff! > 0))
        : null;

    final Color arrowColor;
    final IconData arrowIcon;
    if (!hasDiff || diff!.abs() < 0.01) {
      arrowColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);
      arrowIcon = Icons.remove_rounded;
    } else if (isGood == true) {
      arrowColor = AppColors.success;
      arrowIcon = Icons.arrow_drop_down_rounded;
    } else {
      arrowColor = AppColors.danger;
      arrowIcon = Icons.arrow_drop_up_rounded;
    }

    final labelColor = baseColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72);
    final valueColor = baseColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: labelColor, fontSize: 13),
                ),
                if (hasDiff && diffLabel != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    diffLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: arrowColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ),
          // Trend arrow (like a stock ticker)
          Icon(arrowIcon, size: 20, color: arrowColor),
          const SizedBox(width: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Total payable summary row ────────────────────────────────────────────────

class _TotalPayableRow extends StatelessWidget {
  const _TotalPayableRow({
    required this.offer,
    required this.durationMonths,
    required this.isFull,
  });

  final LoanOffer offer;
  final int durationMonths;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final periods = offer.repaymentFrequency == 'monthly'
        ? durationMonths
        : (offer.repaymentFrequency == 'weekly' ? durationMonths * 4 : 1);
    final totalPayable = offer.installmentAmount * periods;
    final totalCost = totalPayable - offer.offerAmount;
    final isZeroCost = totalCost <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (isFull ? AppColors.success : AppColors.accent)
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isFull ? AppColors.success : AppColors.accent)
                .withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total payable headline
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 13,
                  color: isFull ? AppColors.success : AppColors.accent,
                ),
                const SizedBox(width: 5),
                Text(
                  'Total payable ($periods payments)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isFull ? AppColors.success : AppColors.accent,
                      ),
                ),
                const Spacer(),
                Text(
                  'UGX ${_fmt(totalPayable)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: isFull ? AppColors.success : AppColors.accent,
                      ),
                ),
              ],
            ),
            if (!isZeroCost) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Borrowing cost: UGX ${_fmt(totalCost)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
                'Installment cost breakdown',
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
            'Formula: installment × repayments count = total payback',
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
            label: 'Offered installment',
            value: 'UGX ${_fmt(offer.installmentAmount)}',
          ),
          _CalculatorRow(
            label: 'Repayments plan',
            value: '× $periods $frequencyText payments',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 3.0),
            child: Divider(height: 1),
          ),
          _CalculatorRow(
            label: 'Total payback amount',
            value: 'UGX ${_fmt(totalRepayable)}',
            isBold: true,
          ),
          _CalculatorRow(
            label: 'Principal borrowed',
            value: 'UGX ${_fmt(offer.offerAmount)}',
            subtle: true,
          ),
          _CalculatorRow(
            label: 'Borrowing cost (total interest)',
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
            '• Interest is lower by ${interestDiff!.abs().toStringAsFixed(2)}% (reduces cost).\n');
      } else {
        notes.write(
            '• Interest is higher by ${interestDiff!.abs().toStringAsFixed(2)}% (increases cost).\n');
      }
    }

    if (lateFeeDiff != null && suggestedLateFee != null) {
      parsedAny = true;
      if (lateFeeDiff!.abs() < 0.005) {
        notes.write('• Late payment penalty matches your suggested rate.\n');
      } else if (lateFeeDiff! < 0) {
        notes.write(
            '• Penalty charge fine: lower by ${lateFeeDiff!.abs().toStringAsFixed(2)}% (safer payment guard).\n');
      } else {
        notes.write(
            '• Penalty fine is higher by ${lateFeeDiff!.abs().toStringAsFixed(2)}% (higher penalty risk).\n');
      }
    }

    if (installmentDiff != null && suggestedInstallment != null) {
      parsedAny = true;
      if (installmentDiff == 0) {
        notes.write('• Period installment matches your expectations.\n');
      } else if (installmentDiff! < 0) {
        notes.write(
            '• Installment payment is lower by UGX ${_fmt(installmentDiff!.abs())}.\n');
      } else {
        notes.write(
            '• Installment cost is higher by UGX ${_fmt(installmentDiff!.abs())}.\n');
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
                'Pro comparison analysis',
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
                'Unlock deal comparison',
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
            'Upgrade to a Pro borrower subscription to see how interest rates, payment fines, and installments stack up against your goals with comparative sparklines and instant delta calculations.',
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
                'Upgrade to Pro',
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
          Text('Upgrade required',
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
                      Text('Make a bid',
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
                            : const Text('Send bid')),
                  ])),
        ),
      );
}
