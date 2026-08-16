// lib/features/marketplace/presentation/widgets/loan_detail/offer_card.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../core/di/injection.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ticker_card.dart';
import '../../../../../shared/widgets/trust_badges.dart';
import '../../../data/marketplace_repository.dart';
import '../../../domain/models/loan_listing.dart';
import 'pro_panels.dart';

/// Formats an integer amount with comma thousands separators.
String fmtAmount(int v) {
  if (v == 0) return '0';
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

const List<Color> kBidColors = [
  Color(0xFF3B82F6), // blue
  Color(0xFF60A5FA), // light blue
  Color(0xFF10B981), // green
  Color(0xFFF59E0B), // amber
  Color(0xFF8B5CF6), // purple
];

class OfferList extends StatelessWidget {
  const OfferList({super.key, 
    required this.offers,
    required this.requestedAmount,
    required this.isOwner,
    required this.isParticipant,
    required this.onAccept,
    required this.durationMonths,
    required this.onUpgrade,
    required this.marketBaselinePct,
    this.suggestedInterestRatePct,
    this.suggestedLateFeePct,
    this.suggestedRepaymentFrequency,
    this.suggestedInstallmentAmount,
    this.isProBorrower = false,
  });

  final List<LoanOffer> offers;
  final double marketBaselinePct;
  final int requestedAmount;
  final bool isOwner;
  final bool isParticipant;
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
      itemBuilder: (context, index) => OfferCard(
        offer: offers[index],
        index: index,
        requestedAmount: requestedAmount,
        isOwner: isOwner,
        isParticipant: isParticipant,
        onAccept: onAccept,
        durationMonths: durationMonths,
        marketBaselinePct: marketBaselinePct,
        suggestedInterestRatePct: suggestedInterestRatePct,
        suggestedLateFeePct: suggestedLateFeePct,
        suggestedInstallmentAmount: suggestedInstallmentAmount,
        suggestedRepaymentFrequency: suggestedRepaymentFrequency,
        isProBorrower: isProBorrower,
        onUpgrade: onUpgrade,
        dotColor: kBidColors[index % kBidColors.length],
      ),
    );
  }
}

class OfferCard extends StatefulWidget {
  const OfferCard({super.key, 
    required this.offer,
    required this.index,
    required this.requestedAmount,
    required this.isOwner,
    required this.isParticipant,
    required this.onAccept,
    required this.durationMonths,
    required this.onUpgrade,
    required this.dotColor,
    required this.marketBaselinePct,
    this.suggestedInterestRatePct,
    this.suggestedLateFeePct,
    this.suggestedInstallmentAmount,
    this.suggestedRepaymentFrequency,
    this.isProBorrower = false,
  });

  final LoanOffer offer;
  final double marketBaselinePct;
  final int index;
  final int requestedAmount;
  final bool isOwner;
  final bool isParticipant;
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
  State<OfferCard> createState() => OfferCardState();
}

class OfferCardState extends State<OfferCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _anim;
  late final Animation<double> _expandAnim;
  List<double>? _rateHistory;
  bool _loadingHistory = false;

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
    if (_expanded &&
        widget.isOwner &&
        widget.isProBorrower &&
        _rateHistory == null &&
        !_loadingHistory) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final history = await getIt<MarketplaceRepository>()
        .getLenderInterestHistory(widget.offer.lenderId);
    if (!mounted) return;
    setState(() {
      _rateHistory = history;
      _loadingHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offer = widget.offer;
    final lenderLabel = offer.lenderId == 'your-offer'
        ? (l10n?.yourOfferLabel ?? 'Your offer')
        : offer.hasMaskedLender
            ? (l10n?.lenderNumberLabel(widget.index + 1) ??
                'Lender #${widget.index + 1}')
            : (l10n?.lenderTextLabel(offer.lenderId.substring(0, 5)) ??
                'Lender #${offer.lenderId.substring(0, 5)}');
    final coverage = widget.requestedAmount <= 0
        ? 0
        : ((offer.offerAmount / widget.requestedAmount) * 100).round();
    final isFull = offer.offerAmount >= widget.requestedAmount;
    final offerType = isFull
        ? (l10n?.fullOfferLabel ?? 'Full offer')
        : (l10n?.partialOfferLabel(coverage) ?? 'Partial · $coverage%');
    final professionalTag = widget.isOwner ? offer.professionalTag : null;
    final dotColor = widget.dotColor;
    final isActiveParticipant = widget.isOwner || widget.isParticipant;

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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                  // Lender label + offer meta on the left
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
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
                        if (professionalTag != null) ...[
                          ProfessionalTag(professionalTag),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (offer.expiresAt != null) ...[
                          const SizedBox(width: 6),
                          OfferCountdownChip(expiresAt: offer.expiresAt!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Amount + chevron on the right
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SizedBox(
                          height: 20,
                          child: Center(
                            child: Text(
                              isActiveParticipant
                                  ? fmtAmount(offer.offerAmount)
                                  : '≈$coverage%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                color: isFull ? AppColors.success : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 12, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TrustBadgeRow(
                ratingAvg: offer.trustRatingAvg,
                reviewCount: offer.trustReviewCount,
                completedDealsCount: offer.trustCompletedDealsCount,
                isRepeatParticipant: offer.trustIsRepeatParticipant,
                phoneVerified: offer.trustPhoneVerified,
                responseTimeBucket: offer.trustResponseTimeBucket,
                isVerified: offer.trustIsVerified,
                showReviews: true,
                showCompletedDeals: true,
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
                  if (isActiveParticipant) ...[
                    // Full details for owner / bidder
                    // Enhanced term rows with sparkline tickers
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: TickerCard(
                                label: l10n?.interestLabel ?? 'Interest',
                                value:
                                    '${offer.interestRatePct.toStringAsFixed(1)}%',
                                deltaLabel: widget.suggestedInterestRatePct !=
                                        null
                                    ? (l10n?.vsAskLabel(
                                          '${(offer.interestRatePct - widget.suggestedInterestRatePct!) >= 0 ? '+' : ''}${(offer.interestRatePct - widget.suggestedInterestRatePct!).toStringAsFixed(1)}',
                                        ) ??
                                        '${(offer.interestRatePct - widget.suggestedInterestRatePct!) >= 0 ? '+' : ''}${(offer.interestRatePct - widget.suggestedInterestRatePct!).toStringAsFixed(1)} vs ask')
                                    : '—',
                                isPositive:
                                    widget.suggestedInterestRatePct == null ||
                                        offer.interestRatePct <=
                                            widget.suggestedInterestRatePct!,
                                sparklineValues: [offer.interestRatePct],
                                baselineValue: widget.marketBaselinePct,
                                baselineColor: AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                              width: 1,
                              height: 40,
                              color: Theme.of(context).dividerColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Center(
                              child: TickerCard(
                                label: l10n?.lateFeeLabel ?? 'Late fee',
                                value:
                                    '${offer.lateFeePct.toStringAsFixed(1)}%',
                                deltaLabel: widget.suggestedLateFeePct != null
                                    ? (l10n?.vsAskLabel(
                                          '${(offer.lateFeePct - widget.suggestedLateFeePct!) >= 0 ? '+' : ''}${(offer.lateFeePct - widget.suggestedLateFeePct!).toStringAsFixed(1)}',
                                        ) ??
                                        '${(offer.lateFeePct - widget.suggestedLateFeePct!) >= 0 ? '+' : ''}${(offer.lateFeePct - widget.suggestedLateFeePct!).toStringAsFixed(1)} vs ask')
                                    : '—',
                                isPositive:
                                    widget.suggestedLateFeePct == null ||
                                        offer.lateFeePct <=
                                            widget.suggestedLateFeePct!,
                                sparklineValues: [offer.lateFeePct],
                                baselineValue: widget.marketBaselinePct,
                                baselineColor: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Total payable summary row ──
                    TotalPayableRow(
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
                          child: ProAnalysisPanel(
                            interestDiff:
                                widget.suggestedInterestRatePct != null
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
                            currency: offer.currency,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ] else ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ProUpgradePanel(onUpgrade: widget.onUpgrade),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],

                    if (offer.proposedExpectations != null &&
                        offer.proposedExpectations!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Text(
                          l10n?.lenderNotesLabel ?? 'Lender notes',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
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
                            child:
                                Text(l10n?.acceptOfferLabel ?? 'Accept offer'),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 12),
                  ] else ...[
                    // ── Non-participant: summary + CTA ──
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isFull
                                    ? Icons.check_circle_outline
                                    : Icons.pie_chart_outline,
                                size: 18,
                                color: isFull
                                    ? AppColors.success
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isFull
                                    ? (l10n?.fullCoverageOfferLabel ??
                                        'Full coverage offer')
                                    : (l10n?.partialCoverageLabel(coverage) ??
                                        'Partial coverage · $coverage%'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isFull ? AppColors.success : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.45),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)
                                            ?.makeAnOfferToUnlock ??
                                        'Make an offer to unlock full details',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OfferCountdownChip extends StatefulWidget {
  const OfferCountdownChip({super.key, required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<OfferCountdownChip> createState() => OfferCountdownChipState();
}

class OfferCountdownChipState extends State<OfferCountdownChip> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remaining = widget.expiresAt.difference(DateTime.now());
    final expired = remaining.isNegative;
    final label = expired
        ? (l10n?.expiredLabel ?? 'Expired')
        : (l10n?.offerCountdownLabel(_formatRemaining(remaining)) ??
            '${_formatRemaining(remaining)} left');
    final color = expired || remaining.inHours < 6
        ? AppColors.danger
        : remaining.inHours < 24
            ? AppColors.warning
            : AppColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes.clamp(0, 59)}m';
  }
}

class ProfessionalTag extends StatelessWidget {
  const ProfessionalTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class TotalPayableRow extends StatelessWidget {
  const TotalPayableRow({super.key, 
    required this.offer,
    required this.durationMonths,
    required this.isFull,
  });

  final LoanOffer offer;
  final int durationMonths;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  l10n?.totalPayablePaymentsLabel(periods) ??
                      'Total payable ($periods payments)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isFull ? AppColors.success : AppColors.accent,
                      ),
                ),
                const Spacer(),
                Text(
                  '${offer.currency} ${fmtAmount(totalPayable)}',
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
                    l10n?.borrowingCostLabel(
                          '${offer.currency} ${fmtAmount(totalCost)}',
                        ) ??
                        'Borrowing cost: ${offer.currency} ${fmtAmount(totalCost)}',
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
