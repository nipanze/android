// lib/features/positions/presentation/widgets/lender_offer_card.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../marketplace/data/agreement_repository.dart';
import '../../domain/models/lender_offer.dart';

class LenderOfferCard extends StatelessWidget {
  const LenderOfferCard({
    super.key,
    required this.offer,
    required this.onWithdraw,
  });

  final LenderOffer offer;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(offer.listingTitle,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${offer.district} · ${offer.durationMonths} months',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          const SizedBox(width: 8),
          _OfferStatusBadge(offer.status),
        ]),

        const SizedBox(height: 12),

        // Offer amount
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n?.offeredAmountLabel ?? 'Offered amount',
              style: Theme.of(context).textTheme.bodySmall),
          CurrencyAmount(offer.offerAmount,
              currency: offer.currency, fontSize: 16),
        ]),

        const SizedBox(height: 10),
        _OfferTermsGrid(
          leftTerms: [
            _OfferTerm(
              icon: Icons.percent,
              label: l10n?.interestLabel ?? 'Interest',
              value: '${offer.interestRatePct.toStringAsFixed(1)}%',
            ),
            _OfferTerm(
              icon: Icons.event_available_outlined,
              label: l10n?.lateFeeLabel ?? 'Late fee',
              value: l10n?.lateFeePerMissedInstallment(
                    '${offer.lateFeePct.toStringAsFixed(1)}%',
                  ) ??
                  '${offer.lateFeePct.toStringAsFixed(1)}% per missed installment',
            ),
          ],
          rightTerms: [
            _OfferTerm(
              icon: Icons.rotate_left_rounded,
              label: l10n?.repaymentLabel ?? 'Repayment',
              value:
                  '${offer.currency} ${_fmt(offer.installmentAmount)} ${offer.repaymentFrequencyLabel.toLowerCase()}',
            ),
            _OfferTerm(
              icon: Icons.account_balance_wallet_outlined,
              label: l10n?.totalPayableLabel ?? 'Total payable',
              value: '${offer.currency} ${_fmt(offer.totalRepayment)}',
            ),
          ],
        ),

        if (offer.proposedExpectations != null &&
            offer.proposedExpectations!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.accentLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    offer.proposedExpectations!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.72),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),
        _OfferFooter(
          sentLabel: l10n?.sentDateLabel(_fmtDate(offer.placedAt)) ??
              'Sent ${_fmtDate(offer.placedAt)}',
          countdown: offer.expiresAt != null && offer.isPending
              ? _OfferCountdownChip(expiresAt: offer.expiresAt!)
              : null,
          onViewListing: () => context.push('/marketplace/${offer.requestId}'),
          onViewContract:
              offer.isAccepted ? () => _viewContract(context) : null,
          onWithdraw: offer.canWithdraw ? onWithdraw : null,
          viewListingLabel: l10n?.viewListing ?? 'View listing',
          viewContractLabel: l10n?.viewContract ?? 'View Deal',
          withdrawLabel: l10n?.withdraw ?? 'Withdraw',
        ),
      ]),
    );
  }

  Future<void> _viewContract(BuildContext context) async {
    try {
      final repo = getIt<AgreementRepository>();
      final agreement = await repo.getAgreementByOfferId(offer.offerId);
      if (!context.mounted) return;
      if (agreement != null) {
        await context.push('/marketplace/agreement/${agreement.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.contractNotGenerated ??
                  'Contract not yet generated.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final message = userFacingErrorMessage(e);
      if (isNetworkErrorMessage(message)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Color _borderColor(BuildContext context) {
    switch (offer.status) {
      case OfferStatus.accepted:
        return AppColors.success.withValues(alpha: 0.5);
      case OfferStatus.pending:
        return AppColors.accent.withValues(alpha: 0.4);
      default:
        return Theme.of(context).dividerColor;
    }
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _OfferCountdownChip extends StatefulWidget {
  const _OfferCountdownChip({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_OfferCountdownChip> createState() => _OfferCountdownChipState();
}

class _OfferCountdownChipState extends State<_OfferCountdownChip> {
  late final Timer _timer;

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

class _OfferTerm {
  const _OfferTerm({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _OfferTermsGrid extends StatelessWidget {
  const _OfferTermsGrid({
    required this.leftTerms,
    required this.rightTerms,
  });

  final List<_OfferTerm> leftTerms;
  final List<_OfferTerm> rightTerms;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(
            children: [
              ...leftTerms.map(_TermLine.new),
              ...rightTerms.map(_TermLine.new),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _TermColumn(terms: leftTerms)),
            Container(
              width: 1,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.accent.withValues(alpha: 0.24),
            ),
            Expanded(child: _TermColumn(terms: rightTerms)),
          ],
        );
      },
    );
  }
}

class _TermColumn extends StatelessWidget {
  const _TermColumn({required this.terms});

  final List<_OfferTerm> terms;

  @override
  Widget build(BuildContext context) {
    return Column(children: terms.map(_TermLine.new).toList());
  }
}

class _TermLine extends StatelessWidget {
  const _TermLine(this.term);

  final _OfferTerm term;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(term.icon, size: 13, color: AppColors.accent),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: textStyle,
              children: [
                TextSpan(text: '${term.label}: '),
                TextSpan(
                  text: term.value,
                  style: textStyle?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferFooter extends StatelessWidget {
  const _OfferFooter({
    required this.sentLabel,
    required this.countdown,
    required this.onViewListing,
    required this.onViewContract,
    required this.onWithdraw,
    required this.viewListingLabel,
    required this.viewContractLabel,
    required this.withdrawLabel,
  });

  final String sentLabel;
  final Widget? countdown;
  final VoidCallback onViewListing;
  final VoidCallback? onViewContract;
  final VoidCallback? onWithdraw;
  final String viewListingLabel;
  final String viewContractLabel;
  final String withdrawLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 13, color: AppColors.accentLight),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  sentLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (countdown != null) ...[
                const SizedBox(width: 6),
                Flexible(child: countdown!),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        _ActionPill(
          onPressed: onViewListing,
          icon: Icons.visibility_rounded,
          label: viewListingLabel,
        ),
        if (onViewContract != null) ...[
          const SizedBox(width: 8),
          _ActionPill(
            onPressed: onViewContract!,
            icon: Icons.description_outlined,
            label: viewContractLabel,
            foregroundColor: AppColors.success,
          ),
        ],
        if (onWithdraw != null) ...[
          const SizedBox(width: 8),
          _ActionPill(
            onPressed: onWithdraw!,
            icon: Icons.cancel_outlined,
            label: withdrawLabel,
            foregroundColor: AppColors.danger,
            compact: true,
          ),
        ],
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.foregroundColor = AppColors.accent,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 13),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        side: BorderSide(color: foregroundColor),
        minimumSize: Size(compact ? 0 : 120, 34),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: 8,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OfferStatusBadge extends StatelessWidget {
  const _OfferStatusBadge(this.status);
  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (status) {
      OfferStatus.pending => AppColors.accent,
      OfferStatus.accepted => AppColors.success,
      OfferStatus.rejected => AppColors.danger,
      _ => isDark ? AppColors.text2Dark : AppColors.text2Light,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.name.toUpperCase(),
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
