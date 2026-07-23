// lib/features/positions/presentation/widgets/lender_offer_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
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
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Offered Amount',
                style: Theme.of(context).textTheme.bodySmall),
            CurrencyAmount(offer.offerAmount, currency: offer.currency, fontSize: 16),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Status', style: Theme.of(context).textTheme.bodySmall),
            Text(offer.status.name.toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.accent)),
          ]),
        ]),

        // Structured terms (Stage 4)
        const SizedBox(height: 10),
        _TermRow(
          icon: Icons.percent,
          label: 'Interest',
          value: '${offer.interestRatePct.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 4),
        _TermRow(
          icon: Icons.gavel_outlined,
          label: 'Late fee',
          value: '${offer.lateFeePct.toStringAsFixed(1)}% per missed installment',
        ),
        const SizedBox(height: 4),
        _TermRow(
          icon: Icons.calendar_today,
          label: 'Repayment',
          value:
              '${offer.currency} ${_fmt(offer.installmentAmount)} ${offer.repaymentFrequencyLabel.toLowerCase()}',
        ),
        const SizedBox(height: 4),
        _TermRow(
          icon: Icons.account_balance_wallet,
          label: 'Total payable',
          value: '${offer.currency} ${_fmt(offer.totalRepayment)}',
        ),

        if (offer.proposedExpectations != null &&
            offer.proposedExpectations!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              offer.proposedExpectations!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Placed at
        Text(
          'Sent ${_fmtDate(offer.placedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),

        // Actions
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push('/marketplace/${offer.requestId}'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 11)),
              child: const Text('View Listing'),
            ),
          ),
          if (offer.isAccepted) ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _viewContract(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('View Contract'),
              ),
            ),
          ],
          if (offer.canWithdraw) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onWithdraw,
              style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  textStyle: const TextStyle(fontSize: 11),
                  minimumSize: Size.zero),
              child: const Text('Withdraw'),
            ),
          ],
        ]),
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
          const SnackBar(
            content: Text('Contract not yet generated.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading contract: $e'),
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

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.accent),
        const SizedBox(width: 6),
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _OfferStatusBadge extends StatelessWidget {
  const _OfferStatusBadge(this.status);
  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OfferStatus.pending => AppColors.accent,
      OfferStatus.accepted => AppColors.success,
      OfferStatus.rejected => AppColors.danger,
      _ => AppColors.text2Dark,
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
