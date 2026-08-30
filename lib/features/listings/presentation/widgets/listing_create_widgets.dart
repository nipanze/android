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

// ─── Affordability Warning Banner ─────────────────────────────────────────────
// Shown inline when the borrower's total repayment (installment × periods) is
// less than the loan principal they are requesting, meaning no lender would
// accept the deal at a loss.

class AffordabilityWarningBanner extends StatelessWidget {
  const AffordabilityWarningBanner({
    super.key,
    required this.currency,
    required this.principal,
    required this.totalRepayment,
    required this.installmentAmount,
  });

  final String currency;
  final int principal;
  final int totalRepayment;
  final int installmentAmount;

  @override
  Widget build(BuildContext context) {
    if (principal <= 0 || installmentAmount <= 0) return const SizedBox.shrink();
    if (totalRepayment >= principal) return const SizedBox.shrink();

    final shortfall = principal - totalRepayment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repayment may be too low',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your total repayment of $currency ${fmtAmount(totalRepayment)} is $currency ${fmtAmount(shortfall)} below the amount you are requesting. '
                  'Lenders need to earn a return — consider increasing your installment amount.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Repayment Schedule Timeline ──────────────────────────────────────────────
// Horizontal scroll of instalment date cards, built from the borrower's own
// due day / time / frequency settings — no listing object needed.

class RepaymentScheduleTimeline extends StatelessWidget {
  const RepaymentScheduleTimeline({
    super.key,
    required this.durationMonths,
    required this.repaymentPlan,
    required this.installmentAmount,
    required this.currency,
    required this.selectedDueDay,
    required this.selectedDueTime,
    this.anchorDate,
  });

  final int durationMonths;
  final String repaymentPlan;
  final int installmentAmount;
  final String currency;
  final String? selectedDueDay;
  final String? selectedDueTime;
  final DateTime? anchorDate;

  int get _numberOfInstallments {
    switch (repaymentPlan.toLowerCase()) {
      case 'weekly':
        return durationMonths * 4;
      case 'one_time':
      case 'lump_sum':
        return 1;
      case 'monthly':
      default:
        return durationMonths;
    }
  }

  int? get _dueDayOfMonth {
    final d = selectedDueDay?.toLowerCase();
    if (d == null) return null;
    if (d.contains('1st')) return 1;
    if (d.contains('5th')) return 5;
    if (d.contains('10th')) return 10;
    if (d.contains('15th')) return 15;
    if (d.contains('20th')) return 20;
    if (d.contains('25th')) return 25;
    if (d.contains('last day')) return -1;
    return null;
  }

  int? get _dueWeekday {
    final d = selectedDueDay?.toLowerCase();
    if (d == null) return null;
    if (d.contains('monday')) return DateTime.monday;
    if (d.contains('wednesday')) return DateTime.wednesday;
    if (d.contains('friday')) return DateTime.friday;
    if (d.contains('sunday')) return DateTime.sunday;
    return null;
  }

  String? get _dueTimeLabel {
    if (selectedDueTime == null) return null;
    return selectedDueTime!.split(' (').first;
  }

  DateTime _instalmentDate(int index) {
    final anchor = anchorDate ?? DateTime.now();
    switch (repaymentPlan.toLowerCase()) {
      case 'weekly':
        final targetWd = _dueWeekday;
        DateTime base = anchor.add(Duration(days: 7 * (index + 1)));
        if (targetWd != null) {
          final diff = (targetWd - base.weekday) % 7;
          base = base.add(Duration(days: diff));
        }
        return DateTime(base.year, base.month, base.day);

      case 'one_time':
      case 'lump_sum':
        final months = durationMonths > 0 ? durationMonths : 1;
        final targetDay = _dueDayOfMonth;
        final mo = anchor.month + months;
        int day;
        if (targetDay == null) {
          day = anchor.day;
        } else if (targetDay == -1) {
          day = DateTime(anchor.year, mo + 1, 0).day;
        } else {
          final daysInM = DateTime(anchor.year, mo + 1, 0).day;
          day = targetDay.clamp(1, daysInM);
        }
        return DateTime(anchor.year, mo, day);

      case 'monthly':
      default:
        final targetDay = _dueDayOfMonth;
        final mo = anchor.month + (index + 1);
        int day;
        if (targetDay == null) {
          day = anchor.day;
        } else if (targetDay == -1) {
          day = DateTime(anchor.year, mo + 1, 0).day;
        } else {
          final daysInM = DateTime(anchor.year, mo + 1, 0).day;
          day = targetDay.clamp(1, daysInM);
        }
        return DateTime(anchor.year, mo, day);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final prefix =
        repaymentPlan.toLowerCase() == 'weekly' ? '${weekdays[dt.weekday]} ' : '';
    return '$prefix${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (durationMonths <= 0 || installmentAmount <= 0) {
      return const SizedBox.shrink();
    }

    final count = _numberOfInstallments;
    final displayCount = count.clamp(1, 6);
    final extraCount = count > 6 ? count - 6 : 0;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 14, color: primary),
              const SizedBox(width: 6),
              Text(
                'PAYMENT SCHEDULE ($count ${count == 1 ? "instalment" : "instalments"})',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...List.generate(displayCount, (index) {
                  final date = _instalmentDate(index);
                  final isLast = index == displayCount - 1 && extraCount == 0;
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: primary.withValues(alpha: 0.28)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}',
                              style: const TextStyle(
                                  fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_dueTimeLabel != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                _dueTimeLabel!,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              '$currency ${fmtAmount(installmentAmount)}',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.35),
                          ),
                        ),
                    ],
                  );
                }),
                if (extraCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '+$extraCount more',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Term Guide Chips (Pro borrowers only) ────────────────────────────────────
// Quick-fill preset chips so Pro borrowers can set competitive suggested terms
// without having to know what numbers to enter.

class TermGuideChips extends StatelessWidget {
  const TermGuideChips({super.key, required this.onPresetSelected});

  /// Called with (interestPct, lateFeePct) when a chip is tapped.
  final void Function(double interestPct, double lateFeePct) onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK TERM GUIDE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(context, '💡 Low Interest', 8.0, 0.0,
                    'Attract lenders fast with a competitive low rate.'),
                _chip(context, '🤝 Fair Terms', 10.0, 2.0,
                    'A balanced offer that lenders commonly accept.'),
                _chip(context, '📊 Negotiable', 12.0, 3.0,
                    'Slightly higher yield — gives lenders room to negotiate down.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, double interest,
      double lateFee, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: ActionChip(
          label: Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
          onPressed: () => onPresetSelected(interest, lateFee),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

