// lib/features/listings/presentation/widgets/listing_create_widgets.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Formats an integer amount with comma thousands separators.
String fmtAmount(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
  return buf.toString();
}

// ─── Header with step progress ───────────────────────────────────────────────
class ListingStepHeader extends StatelessWidget {
  const ListingStepHeader({super.key, 
    required this.title,
    required this.subtitle,
    required this.progress,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                // Screen title uses Sora (heading font) per app_theme.dart —
                // headlineSmall already carries AppFonts.heading, no override needed.
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info banner ──────────────────────────────────────────────────────────────
// Theme fix: previously hardcoded Color(0xFF062B57)/Color(0xFF7DB7FF), which
// only look correct in dark mode and never adapt. Now derived from
// AppColors.accent so it reads correctly in both light and dark themes.


class ListingInfoBanner extends StatelessWidget {
  const ListingInfoBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 10.5,
          color: AppColors.accentDark,
        ),
      ),
    );
  }
}

// ─── Grouped form panel ───────────────────────────────────────────────────────
// Groups related fields under one labeled panel instead of one long flat list,
// so the form reads as a handful of short sections rather than a wall of inputs.


class ListingFormPanel extends StatelessWidget {
  const ListingFormPanel({super.key, 
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.48),
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

// ─── Review row ───────────────────────────────────────────────────────────────
// Theme fix: previously used raw 'DM Mono'/'DM Sans' font-family strings that
// don't exist in this theme (AppTheme registers Sora/Inter via AppFonts).
// Hero numeric values now correctly use AppFonts.heading (Sora), matching the
// "hero numbers" rule in app_theme.dart's doc comment.


class ListingReviewRow extends StatelessWidget {
  const ListingReviewRow({super.key, 
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon,
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: highlight ? 18 : 13,
                fontWeight: FontWeight.w600,
                fontFamily: highlight ? AppFonts.heading : AppFonts.body,
                color: highlight ? AppColors.accent : null,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Live Repayment Math Panel ────────────────────────────────────────────────


class LiveRepaymentMathPanel extends StatelessWidget {
  const LiveRepaymentMathPanel({super.key, 
    required this.currency,
    required this.principal,
    required this.durationMonths,
    required this.repaymentPlan,
    required this.installmentAmount,
  });

  final String currency;
  final int principal;
  final int durationMonths;
  final String? repaymentPlan;
  final int installmentAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (principal <= 0 || durationMonths <= 0 || repaymentPlan == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          l10n?.liveCalcNoData ??
              'Fill in the fields above to see your repayment breakdown.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }

    final int periods = switch (repaymentPlan) {
      'weekly' => durationMonths * 4,
      'one_time' => 1,
      _ => durationMonths,
    };

    final int totalPayback = installmentAmount > 0
        ? installmentAmount * periods
        : 0;

    final int borrowingCost = totalPayback > principal
        ? totalPayback - principal
        : 0;

    final planNote = switch (repaymentPlan) {
      'weekly' => l10n?.liveCalcWeeklyNote(durationMonths, periods) ??
          'Weekly plan: $durationMonths months × 4 = $periods payments',
      'one_time' => l10n?.liveCalcOneTimeNote ?? '1 lump-sum payment',
      _ => l10n?.liveCalcMonthlyNote(periods) ?? '$periods monthly payments',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                (l10n?.liveCalcTitle ?? 'Repayment breakdown').toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.repaymentCalcFormula ??
                'installment × number of payments = total payback',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 10),
          MathRow(
            label: l10n?.liveCalcLoanAmount ?? 'Loan amount',
            value: '$currency ${fmtAmount(principal)}',
          ),
          MathRow(
            label: l10n?.liveCalcDuration ?? 'Duration',
            value: '$durationMonths ${l10n?.months ?? "months"}',
          ),
          MathRow(
            label: l10n?.liveCalcTotalPayments ?? 'Total payments',
            value: planNote,
          ),
          if (installmentAmount > 0) ...[
            const Divider(height: 12),
            MathRow(
              label: l10n?.liveCalcInstallment ?? 'Per period installment',
              value: '$currency ${fmtAmount(installmentAmount)}',
            ),
            MathRow(
              label: l10n?.liveCalcTotalPayback ?? 'Total payback',
              value: '$currency ${fmtAmount(totalPayback)}',
              isBold: true,
            ),
            if (borrowingCost > 0)
              MathRow(
                label: l10n?.liveCalcBorrowingCost ?? 'Borrowing cost',
                value: '$currency ${fmtAmount(borrowingCost)}',
                valueColor: AppColors.success,
                isBold: true,
              ),
          ],
        ],
      ),
    );
  }
}

class MathRow extends StatelessWidget {

  const MathRow({super.key, 
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

