// lib/features/positions/presentation/widgets/lender_bid_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/models/lender_bid.dart';

class LenderBidCard extends StatelessWidget {
  const LenderBidCard({
    super.key,
    required this.bid,
    required this.onWithdraw,
  });

  final LenderBid bid;
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bid.listingTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${bid.district} · ${bid.durationMonths} months',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          const SizedBox(width: 8),
          _BidStatusBadge(bid.bidStatus),
        ]),

        const SizedBox(height: 8),

        // Bid details
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your bid', style: Theme.of(context).textTheme.bodySmall),
            UgxAmount(bid.bidAmount, fontSize: 16),
          ]),
          const SizedBox(width: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Rate', style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${bid.bidRate.toStringAsFixed(1)}% p.a.',
              style: const TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent),
            ),
          ]),
          const Spacer(),
          RiskBadge.fromString(bid.riskCategory),
        ]),

        const SizedBox(height: 8),

        // Placed at
        Text(
          'Placed ${_fmtDate(bid.placedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),

        // Contract info if accepted
        if (bid.isAccepted && bid.contractId != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.handshake_outlined,
                  size: 14, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bid accepted${bid.repaymentStartDate != null ? ' · Repayments from ${_fmtDate(bid.repaymentStartDate!)}' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.success),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/contracts/${bid.contractId}'),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('View contract',
                    style: TextStyle(fontSize: 11)),
              ),
            ]),
          ),
        ],

        // Withdraw button (pending only)
        if (bid.isPending) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/marketplace/${bid.requestId}'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 11)),
                child: const Text('View listing'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onWithdraw,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  textStyle: const TextStyle(fontSize: 11),
                  minimumSize: Size.zero),
              child: const Text('Withdraw'),
            ),
          ]),
        ],
      ]),
    );
  }

  Color _borderColor(BuildContext context) {
    switch (bid.bidStatus) {
      case BidStatus.accepted:  return AppColors.success.withValues(alpha: 0.5);
      case BidStatus.pending:   return AppColors.accent.withValues(alpha: 0.4);
      case BidStatus.withdrawn:
      case BidStatus.rejected:
      case BidStatus.expired:   return Theme.of(context).dividerColor;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _BidStatusBadge extends StatelessWidget {
  const _BidStatusBadge(this.status);
  final BidStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BidStatus.pending   => ('Pending',   AppColors.accent),
      BidStatus.accepted  => ('Accepted',  AppColors.success),
      BidStatus.rejected  => ('Rejected',  AppColors.danger),
      BidStatus.withdrawn => ('Withdrawn', AppColors.text2Dark),
      BidStatus.expired   => ('Expired',   AppColors.text2Dark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}