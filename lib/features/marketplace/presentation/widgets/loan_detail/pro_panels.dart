// lib/features/marketplace/presentation/widgets/loan_detail/pro_panels.dart
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_theme.dart';
import 'offer_card.dart';

class ProAnalysisPanel extends StatelessWidget {
  const ProAnalysisPanel({super.key, 
    this.interestDiff,
    this.lateFeeDiff,
    this.installmentDiff,
    this.suggestedInterest,
    this.suggestedLateFee,
    this.suggestedInstallment,
    required this.offeredInterest,
    required this.offeredLateFee,
    required this.offeredInstallment,
    this.currency = 'UGX',
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
  final String currency;

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
            '• Installment payment is lower by $currency ${fmtAmount(installmentDiff!.abs())}.\n');
      } else {
        notes.write(
            '• Installment cost is higher by $currency ${fmtAmount(installmentDiff!.abs())}.\n');
      }
    }

    final analysisText = parsedAny
        ? notes.toString().trim()
        : 'Offer matches your proposed expectations.';

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

class ProUpgradePanel extends StatelessWidget {
  const ProUpgradePanel({super.key, required this.onUpgrade});
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
