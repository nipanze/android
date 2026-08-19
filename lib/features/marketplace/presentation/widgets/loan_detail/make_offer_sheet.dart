// lib/features/marketplace/presentation/widgets/loan_detail/make_offer_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/di/injection.dart';
import '../../../../../../core/errors/app_exception.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/marketplace_repository.dart';
import '../../../domain/models/loan_listing.dart';

const _monthlyDueDayOptions = [
  '1st of every month',
  '5th of every month',
  '10th of every month',
  '15th of every month',
  '20th of every month',
  '25th of every month',
  'Last day of every month',
  'Custom day',
];

const _weeklyDueDayOptions = [
  'Every Monday',
  'Every Wednesday',
  'Every Friday',
  'Every Sunday',
  'Custom day',
];

const _oneTimeDueDayOptions = [
  'Maturity date / End of term',
  '1st of target month',
  '15th of target month',
  'Custom day',
];

const _dueTimeOptions = [
  '5:00 PM (End of business day)',
  '12:00 PM (Noon)',
  '8:00 PM (Evening)',
  '11:59 PM (End of day)',
  'Custom time',
];

class MakeOfferSheet extends StatefulWidget {
  const MakeOfferSheet(
      {super.key,
      required this.listing,
      required this.onClose,
      required this.onOfferPlaced});
  final LoanListing listing;
  final VoidCallback onClose;
  final VoidCallback onOfferPlaced;
  @override
  State<MakeOfferSheet> createState() => MakeOfferSheetState();
}

class MakeOfferSheetState extends State<MakeOfferSheet> {
  final _amountController = TextEditingController();
  final _expController = TextEditingController();
  final _interestController = TextEditingController();
  final _lateFeeController = TextEditingController();
  final _installmentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _repaymentFrequency = 'monthly';
  bool _loading = false;
  String? _selectedDueDay;
  String? _selectedDueTime;

  @override
  void initState() {
    super.initState();
    // Auto-fill amount with the requested amount
    _amountController.text = widget.listing.requestedAmount.toString();

    // Auto-fill suggested interest rate, late fee, and repayment frequency if available
    final suggestedInterest = widget.listing.suggestedInterestRatePct ?? 10.0;
    _interestController.text = suggestedInterest.toStringAsFixed(0);

    final suggestedLateFee = widget.listing.suggestedLateFeePct ?? 0.0;
    _lateFeeController.text = suggestedLateFee.toStringAsFixed(0);

    if (widget.listing.suggestedRepaymentFrequency != null) {
      _repaymentFrequency = widget.listing.suggestedRepaymentFrequency!;
    } else if (widget.listing.preferredRepaymentPlan.isNotEmpty) {
      final p = widget.listing.preferredRepaymentPlan.toLowerCase();
      if (p.contains('week')) {
        _repaymentFrequency = 'weekly';
      } else if (p.contains('one') || p.contains('lump')) {
        _repaymentFrequency = 'one_time';
      } else {
        _repaymentFrequency = 'monthly';
      }
    }

    if (widget.listing.suggestedInstallmentAmount != null &&
        widget.listing.suggestedInstallmentAmount! > 0) {
      _installmentController.text =
          widget.listing.suggestedInstallmentAmount.toString();
    } else {
      _installmentController.text = _suggestedInstallmentAmount.toString();
    }

    // Initialize due day and time from repaymentTimeline
    final timeline = widget.listing.repaymentTimeline.toLowerCase();

    if (_repaymentFrequency == 'weekly') {
      if (timeline.contains('monday')) {
        _selectedDueDay = 'Every Monday';
      } else if (timeline.contains('wednesday')) {
        _selectedDueDay = 'Every Wednesday';
      } else if (timeline.contains('friday')) {
        _selectedDueDay = 'Every Friday';
      } else if (timeline.contains('sunday')) {
        _selectedDueDay = 'Every Sunday';
      } else {
        _selectedDueDay = 'Every Monday';
      }
    } else if (_repaymentFrequency == 'one_time') {
      if (timeline.contains('maturity') || timeline.contains('end of term')) {
        _selectedDueDay = 'Maturity date / End of term';
      } else if (timeline.contains('1st')) {
        _selectedDueDay = '1st of target month';
      } else if (timeline.contains('15th')) {
        _selectedDueDay = '15th of target month';
      } else {
        _selectedDueDay = 'Maturity date / End of term';
      }
    } else {
      if (timeline.contains('1st')) {
        _selectedDueDay = '1st of every month';
      } else if (timeline.contains('5th')) {
        _selectedDueDay = '5th of every month';
      } else if (timeline.contains('10th')) {
        _selectedDueDay = '10th of every month';
      } else if (timeline.contains('15th')) {
        _selectedDueDay = '15th of every month';
      } else if (timeline.contains('20th')) {
        _selectedDueDay = '20th of every month';
      } else if (timeline.contains('25th')) {
        _selectedDueDay = '25th of every month';
      } else if (timeline.contains('last day')) {
        _selectedDueDay = 'Last day of every month';
      } else {
        _selectedDueDay = '5th of every month';
      }
    }

    if (timeline.contains('5:00 pm')) {
      _selectedDueTime = '5:00 PM (End of business day)';
    } else if (timeline.contains('12:00 pm')) {
      _selectedDueTime = '12:00 PM (Noon)';
    } else if (timeline.contains('8:00 pm')) {
      _selectedDueTime = '8:00 PM (Evening)';
    } else if (timeline.contains('11:59 pm')) {
      _selectedDueTime = '11:59 PM (End of day)';
    } else {
      _selectedDueTime = '5:00 PM (End of business day)';
    }

    for (final controller in [
      _amountController,
      _interestController,
      _lateFeeController,
      _installmentController,
    ]) {
      controller.addListener(_refreshButtonState);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _amountController,
      _interestController,
      _lateFeeController,
      _installmentController,
    ]) {
      controller.removeListener(_refreshButtonState);
    }
    _amountController.dispose();
    _expController.dispose();
    _interestController.dispose();
    _lateFeeController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  void _refreshButtonState() {
    if (mounted) setState(() {});
  }

  int get _parsedAmount =>
      int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  double get _parsedInterest =>
      double.tryParse(_interestController.text) ?? 0.0;

  int get _parsedInstallment =>
      int.tryParse(_installmentController.text.replaceAll(',', '')) ?? 0;

  int get _numberOfInstallments {
    final months = widget.listing.durationMonths;
    final duration = months > 0 ? months : 1;
    switch (_repaymentFrequency.toLowerCase()) {
      case 'weekly':
        return duration * 4;
      case 'one_time':
      case 'lump_sum':
        return 1;
      case 'monthly':
      default:
        return duration;
    }
  }

  int get _totalRepayment => _numberOfInstallments * _parsedInstallment;

  int get _targetMinimumRepayment {
    final principal = _parsedAmount;
    final interestPct = _parsedInterest;
    return (principal + (principal * (interestPct / 100))).ceil();
  }

  int get _suggestedInstallmentAmount {
    final target = _targetMinimumRepayment;
    final count = _numberOfInstallments;
    if (count <= 0) return target;
    return (target / count).ceil();
  }

  bool get _isPrincipalLoss =>
      _parsedAmount > 0 && _totalRepayment < _parsedAmount;

  bool get _isTargetDeficit =>
      _parsedAmount > 0 && _totalRepayment < _targetMinimumRepayment;

  int get _netProfit => _totalRepayment - _parsedAmount;

  String _fmtAmount(int? n) {
    if (n == null) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  bool get _isOfferReady {
    final amount = int.tryParse(_amountController.text.replaceAll(',', ''));
    final interest = double.tryParse(_interestController.text);
    final lateFee = double.tryParse(_lateFeeController.text);
    final installment =
        int.tryParse(_installmentController.text.replaceAll(',', ''));
    return amount != null &&
        amount > 0 &&
        interest != null &&
        interest >= 0 &&
        interest <= 100 &&
        lateFee != null &&
        lateFee >= 0 &&
        lateFee <= 100 &&
        installment != null &&
        installment > 0;
  }

  Future<bool?> _showLossWarningDialog() {
    final l10n = AppLocalizations.of(context);
    final currency = widget.listing.currency;
    final principal = _parsedAmount;
    final total = _totalRepayment;
    final target = _targetMinimumRepayment;
    final count = _numberOfInstallments;
    final installment = _parsedInstallment;

    final isLoss = _isPrincipalLoss;
    final deficit = target - total;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.danger,
          size: 36,
        ),
        title: Text(
          isLoss
              ? (l10n?.principalLossWarningTitle ?? 'Principal Loss Warning')
              : (l10n?.belowTargetReturnTitle ?? 'Below Target Return Warning'),
        ),
        content: Text(
          isLoss
              ? 'Your offer of $currency ${_fmtAmount(principal)} with $count instalments of $currency ${_fmtAmount(installment)} yields a total repayment of $currency ${_fmtAmount(total)}.\n\nThis results in a loss of $currency ${_fmtAmount(principal - total)} below your offered principal.\n\nAre you sure you want to send this offer?'
              : 'Your offer of $currency ${_fmtAmount(principal)} with $count instalments of $currency ${_fmtAmount(installment)} yields a total repayment of $currency ${_fmtAmount(total)}.\n\nThis is $currency ${_fmtAmount(deficit)} below your target return (Principal + ${_parsedInterest.toStringAsFixed(0)}% Interest).\n\nAre you sure you want to send this offer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Adjust Offer'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.sendAnyway ?? 'Send Offer Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPrincipalLoss || _isTargetDeficit) {
      final confirm = await _showLossWarningDialog();
      if (confirm != true) return;
    }

    setState(() => _loading = true);
    try {
      final scheduleText = _proposedRepaymentTimeline;
      final notes = _expController.text.trim();
      final finalExpectations = notes.isNotEmpty
          ? '$notes\n\nProposed schedule: $scheduleText'
          : 'Proposed schedule: $scheduleText';

      await getIt<MarketplaceRepository>().makeOffer(
        requestId: widget.listing.requestId,
        amount: int.parse(_amountController.text.replaceAll(',', '')),
        interestRatePct: double.parse(_interestController.text),
        lateFeePct: double.parse(_lateFeeController.text),
        repaymentFrequency: _repaymentFrequency,
        installmentAmount:
            int.parse(_installmentController.text.replaceAll(',', '')),
        expectations: finalExpectations,
      );
      widget.onOfferPlaced();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.offerSentSuccessfully ??
                  'Offer sent successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userFacingErrorMessage(e)),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _adjustAmount(int delta) {
    final current = _parsedAmount;
    const step = 50000;
    final next =
        (current + (delta * step)).clamp(10000, widget.listing.requestedAmount * 2);
    setState(() {
      _amountController.text = next.toString();
      _installmentController.text = _suggestedInstallmentAmount.toString();
    });
  }

  void _adjustInterest(double delta) {
    final current = _parsedInterest;
    final next = (current + delta).clamp(0.0, 100.0);
    setState(() {
      _interestController.text = next.toStringAsFixed(0);
      _installmentController.text = _suggestedInstallmentAmount.toString();
    });
  }

  void _adjustLateFee(double delta) {
    final current = double.tryParse(_lateFeeController.text) ?? 0.0;
    final next = (current + delta).clamp(0.0, 100.0);
    setState(() {
      _lateFeeController.text = next.toStringAsFixed(0);
    });
  }

  void _adjustInstallment(int delta) {
    final current = _parsedInstallment;
    const step = 10000;
    final next = (current + (delta * step)).clamp(1000, 1000000000);
    setState(() {
      _installmentController.text = next.toString();
    });
  }

  double get _parsedLateFee =>
      double.tryParse(_lateFeeController.text) ?? 0.0;

  int get _lateFeeCurrencyValue =>
      (_parsedInstallment * (_parsedLateFee / 100)).ceil();

  Widget _buildStepperSuffix({
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
          color: Theme.of(context).colorScheme.primary,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onDecrement,
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          color: Theme.of(context).colorScheme.primary,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onIncrement,
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  Widget _buildAdjustableRateLine({
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        children: [
          Text(
            '${min.toInt()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.18),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: (max - min).toInt() > 0 ? (max - min).toInt() : 1,
                onChanged: onChanged,
              ),
            ),
          ),
          Text(
            '${max.toInt()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips({required List<Widget> chips}) {
    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  Widget _microPill(String label, VoidCallback onTap, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.4),
              width: selected ? 1.0 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  // ── Beginner UX Helpers ──────────────────────────────────────────

  void _showFieldInfo(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.info_outline_rounded, color: AppColors.accent),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text(body, style: const TextStyle(fontSize: 13, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTooltip(String title, String body) {
    return GestureDetector(
      onTap: () => _showFieldInfo(title, body),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(Icons.info_outline_rounded,
            size: 15,
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.55)),
      ),
    );
  }

  Widget _buildStepsIndicator({required int currentStep}) {
    // currentStep: 0 = Enter Terms, 1 = Preview, 2 = Sent
    const steps = ['Enter Terms', 'Preview', 'Sent'];
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIdx < currentStep ? primary : muted,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isDone = stepIdx < currentStep;
          final isActive = stepIdx == currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 22 : 16,
                height: isActive ? 22 : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? primary
                      : isActive
                          ? primary
                          : muted,
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 12, color: Colors.white)
                    : isActive
                        ? Center(
                            child: Text(
                              '${stepIdx + 1}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          )
                        : null,
              ),
              const SizedBox(height: 3),
              Text(
                steps[stepIdx],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.w400,
                  color: isActive
                      ? primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBorrowerTrustBadge() {
    final listing = widget.listing;
    final hasRating =
        listing.trustRatingAvg != null && listing.trustRatingAvg! > 0;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Avatar circle with initials
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withValues(alpha: 0.18),
            child: Text(
              listing.title.isNotEmpty
                  ? listing.title[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        listing.title,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (listing.trustIsVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 13, color: AppColors.accent),
                    ],
                    if (listing.trustPhoneVerified) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.phone_iphone_rounded,
                          size: 12, color: AppColors.success),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (hasRating) ...[
                      Icon(Icons.star_rounded,
                          size: 12,
                          color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text(
                        listing.trustRatingAvg!.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (listing.trustCompletedDealsCount > 0) ...[
                      const Icon(Icons.handshake_outlined,
                          size: 12, color: AppColors.success),
                      const SizedBox(width: 2),
                      Text(
                        '${listing.trustCompletedDealsCount} deal${listing.trustCompletedDealsCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.success),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (listing.trustIsRepeatParticipant)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Repeat',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Loan purpose & duration
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${listing.durationMonths}mo',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primary),
              ),
              const SizedBox(height: 2),
              Text(
                listing.purpose.isNotEmpty
                    ? listing.purpose
                    : listing.preferredRepaymentPlan,
                style: TextStyle(
                    fontSize: 9.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFillSuggestedButton() {
    final hasSuggestions = widget.listing.suggestedInterestRatePct != null ||
        widget.listing.suggestedLateFeePct != null ||
        widget.listing.suggestedInstallmentAmount != null;
    if (!hasSuggestions) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            if (widget.listing.suggestedInterestRatePct != null) {
              _interestController.text =
                  widget.listing.suggestedInterestRatePct!.toStringAsFixed(0);
            }
            if (widget.listing.suggestedLateFeePct != null) {
              _lateFeeController.text =
                  widget.listing.suggestedLateFeePct!.toStringAsFixed(0);
            }
            if (widget.listing.suggestedRepaymentFrequency != null) {
              _repaymentFrequency =
                  widget.listing.suggestedRepaymentFrequency!;
            }
            _installmentController.text =
                _suggestedInstallmentAmount.toString();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.12),
                Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 15, color: AppColors.accent),
              SizedBox(width: 6),
              Text(
                'Fill Borrower-Suggested Terms',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Repayment date computation from borrower's exact schedule ─────────────
  //
  // The borrower filled these in listing_create_page.dart:
  //   _selectedDueDay  → e.g. "5th of every month" / "Every Friday"
  //   _selectedDueTime → e.g. "5:00 PM (End of business day)"
  // These are joined into listing.repaymentTimeline, e.g.:
  //   "Paid by the 5th of every month by 5:00 PM for 6 months"
  // We parse that string to extract the exact day & time so the offer
  // preview shows the borrower's own chosen due date, not an estimate.

  /// Returns the day-of-month [1..31] that the borrower picked, or null.
  int? get _borrowerDueDayOfMonth {
    if (_selectedDueDay == null) return null;
    final dayStr = _selectedDueDay!.toLowerCase();
    if (dayStr.contains('1st')) return 1;
    if (dayStr.contains('5th')) return 5;
    if (dayStr.contains('10th')) return 10;
    if (dayStr.contains('15th')) return 15;
    if (dayStr.contains('20th')) return 20;
    if (dayStr.contains('25th')) return 25;
    if (dayStr.contains('last day')) return -1;
    return null;
  }

  /// Returns the weekday [1=Mon..7=Sun] the borrower picked, or null.
  int? get _borrowerDueWeekday {
    if (_selectedDueDay == null) return null;
    final dayStr = _selectedDueDay!.toLowerCase();
    if (dayStr.contains('monday')) return DateTime.monday;
    if (dayStr.contains('wednesday')) return DateTime.wednesday;
    if (dayStr.contains('friday')) return DateTime.friday;
    if (dayStr.contains('sunday')) return DateTime.sunday;
    return null;
  }

  /// Returns a short display string like "5:00 PM" from the timeline, or null.
  String? get _borrowerDueTime {
    if (_selectedDueTime == null) return null;
    return _selectedDueTime!.split(' (').first;
  }

  String get _proposedRepaymentTimeline {
    final parts = <String>[];

    if (_selectedDueDay != null && _selectedDueDay != 'Custom day') {
      if (_repaymentFrequency == 'weekly') {
        parts.add('Paid $_selectedDueDay');
      } else if (_repaymentFrequency == 'one_time') {
        parts.add('Paid on $_selectedDueDay');
      } else {
        parts.add('Paid by the $_selectedDueDay');
      }
    }

    if (_selectedDueTime != null && _selectedDueTime != 'Custom time') {
      final cleanTime = _selectedDueTime!.split(' (').first;
      parts.add('by $cleanTime');
    }

    final durationMonths = widget.listing.durationMonths;
    if (durationMonths > 0) {
      parts.add('for $durationMonths months');
    }

    return parts.join(' ');
  }

  DateTime _getInstalmentDate(int index) {
    // Anchor: use the listing's listedAt date as the loan start.
    // If the loan isn't active yet fall back to today.
    final anchor = widget.listing.listedAt;
    final freq = _repaymentFrequency.toLowerCase();

    switch (freq) {
      case 'weekly':
        // Anchor to the borrower's chosen weekday if available.
        final targetWeekday = _borrowerDueWeekday;
        DateTime base = anchor.add(Duration(days: 7 * (index + 1)));
        if (targetWeekday != null) {
          // Walk forward from base to find the next occurrence of that weekday.
          final diff = (targetWeekday - base.weekday) % 7;
          base = base.add(Duration(days: diff));
        }
        return DateTime(base.year, base.month, base.day);

      case 'one_time':
      case 'lump_sum':
        final months =
            widget.listing.durationMonths > 0 ? widget.listing.durationMonths : 1;
        final targetDay = _borrowerDueDayOfMonth;
        int day;
        if (targetDay == null) {
          day = anchor.day;
        } else if (targetDay == -1) {
          // Last day of that month
          final m = DateTime(anchor.year, anchor.month + months + 1, 0);
          day = m.day;
        } else {
          day = targetDay;
        }
        final yr = anchor.year;
        final mo = anchor.month + months;
        // clamp day to valid range for that month
        final daysInMonth = DateTime(yr, mo + 1, 0).day;
        return DateTime(yr, mo, day.clamp(1, daysInMonth));

      case 'monthly':
      default:
        final targetDay = _borrowerDueDayOfMonth;
        final mo = anchor.month + (index + 1);
        int day;
        if (targetDay == null) {
          day = anchor.day;
        } else if (targetDay == -1) {
          day = DateTime(anchor.year, mo + 1, 0).day; // last day
        } else {
          final daysInMonth = DateTime(anchor.year, mo + 1, 0).day;
          day = targetDay.clamp(1, daysInMonth);
        }
        return DateTime(anchor.year, mo, day);
    }
  }

  String _formatDateShort(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    // Weekday abbreviations for weekly schedules
    const weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = _repaymentFrequency == 'weekly'
        ? '${weekdays[dt.weekday]} '
        : '';
    return '$dayName${months[dt.month - 1]} ${dt.day}';
  }

  Widget _buildStrategyMoodPresets() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK OFFER STRATEGY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _moodChip('⚡ Fast Accept', () {
                  setState(() {
                    _interestController.text = '8';
                    _lateFeeController.text = '0';
                    _installmentController.text =
                        _suggestedInstallmentAmount.toString();
                  });
                }),
                _moodChip('🤝 Standard', () {
                  setState(() {
                    _interestController.text = '10';
                    _lateFeeController.text = '2';
                    _installmentController.text =
                        _suggestedInstallmentAmount.toString();
                  });
                }),
                _moodChip('📈 High Yield', () {
                  setState(() {
                    _interestController.text = '15';
                    _lateFeeController.text = '5';
                    _installmentController.text =
                        _suggestedInstallmentAmount.toString();
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: null,
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildScheduleTimeline() {

    final count = _numberOfInstallments;
    final displayCount = count.clamp(1, 6);
    final extraCount = count > 6 ? count - 6 : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined,
                  size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'REPAYMENT TIMELINE ($count ${count == 1 ? "instalment" : "instalments"})',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...List.generate(displayCount, (index) {
                  final date = _getInstalmentDate(index);
                  final isLast = index == displayCount - 1 && extraCount == 0;
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instalment ${index + 1}',
                              style: const TextStyle(
                                  fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateShort(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_borrowerDueTime != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                _borrowerDueTime!,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              '${widget.listing.currency} ${_fmtAmount(_parsedInstallment)}',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
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
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.4),
                        ),
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
          // Show the borrower's own schedule text as a source caption
          if (widget.listing.repaymentTimeline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Borrower\'s schedule: ${widget.listing.repaymentTimeline}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildPlainEnglishReturnCard() {
    final currency = widget.listing.currency;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('You Lend (Principal):', style: TextStyle(fontSize: 11.5)),
              Text('$currency ${_fmtAmount(_parsedAmount)}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('+ You Earn (Interest):',
                  style: TextStyle(fontSize: 11.5, color: AppColors.success)),
              Text(
                _isPrincipalLoss
                    ? '-$currency ${_fmtAmount(_parsedAmount - _totalRepayment)}'
                    : '+$currency ${_fmtAmount(_netProfit)}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _isPrincipalLoss ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('= Total You Receive:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(
                '$currency ${_fmtAmount(_totalRepayment)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _previewOffer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPrincipalLoss || _isTargetDeficit) {
      final confirm = await _showLossWarningDialog();
      if (confirm != true) return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review_outlined, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'OFFER SUMMARY PREVIEW',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _previewRow('Listing Title', widget.listing.title),
                  const Divider(height: 16),
                  _previewRow(
                    'Offered Amount',
                    '${widget.listing.currency} ${_fmtAmount(_parsedAmount)}',
                  ),
                  const SizedBox(height: 6),
                  _previewRow(
                    'Interest Rate',
                    '${_parsedInterest.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 6),
                  _previewRow(
                    'Repayment Schedule',
                    '$_repaymentFrequency ($_numberOfInstallments instalments)',
                  ),
                  const SizedBox(height: 6),
                  _previewRow(
                    'Instalment Amount',
                    '${widget.listing.currency} ${_fmtAmount(_parsedInstallment)} / $_repaymentFrequency',
                  ),
                  const SizedBox(height: 6),
                  _previewRow(
                    'Late Payment Fee',
                    '${_parsedLateFee.toStringAsFixed(0)}% (${widget.listing.currency} ${_fmtAmount(_lateFeeCurrencyValue)} per overdue instalment)',
                  ),
                  const Divider(height: 16),
                  _previewRow(
                    'Total Repayment',
                    '${widget.listing.currency} ${_fmtAmount(_totalRepayment)}',
                    isBold: true,
                  ),
                  const SizedBox(height: 6),
                  _previewRow(
                    'Estimated Return',
                    _isPrincipalLoss
                        ? 'LOSS: -${widget.listing.currency} ${_fmtAmount(_parsedAmount - _totalRepayment)}'
                        : 'PROFIT: +${widget.listing.currency} ${_fmtAmount(_netProfit)}',
                    color: _isPrincipalLoss
                        ? AppColors.danger
                        : AppColors.success,
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  _buildScheduleTimeline(),
                  if (_expController.text.trim().isNotEmpty) ...[
                    const Divider(height: 16),
                    _previewRow('Notes for Borrower', _expController.text.trim()),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Edit Offer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _submit();
                    },
                    child: const Text('Confirm & Send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
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
                    Text(l10n?.makeAnOffer ?? 'Make an offer',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose)
                  ]),
                  const SizedBox(height: 10),
                  _buildStepsIndicator(currentStep: 0),
                  _buildBorrowerTrustBadge(),
                  _buildFillSuggestedButton(),
                  _buildStrategyMoodPresets(),
                  const SizedBox(height: 4),

                  // ── Amount Field with Steppers & Micro Preset Pills ──────
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n?.amountLabelWithCurrency(
                              widget.listing.currency) ??
                          'Amount (${widget.listing.currency})',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      suffixIcon: _buildStepperSuffix(
                        onDecrement: () => _adjustAmount(-1),
                        onIncrement: () => _adjustAmount(1),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? (l10n?.validationAmountRequired ?? 'Enter an amount')
                        : null,
                  ),
                  _buildQuickChips(chips: [
                    _microPill('50%', () {
                      final val = (widget.listing.requestedAmount * 0.5).round();
                      setState(() {
                        _amountController.text = val.toString();
                        _installmentController.text =
                            _suggestedInstallmentAmount.toString();
                      });
                    },
                        selected: _parsedAmount ==
                            (widget.listing.requestedAmount * 0.5).round()),
                    _microPill('75%', () {
                      final val = (widget.listing.requestedAmount * 0.75).round();
                      setState(() {
                        _amountController.text = val.toString();
                        _installmentController.text =
                            _suggestedInstallmentAmount.toString();
                      });
                    },
                        selected: _parsedAmount ==
                            (widget.listing.requestedAmount * 0.75).round()),
                    _microPill('100% (Full)', () {
                      setState(() {
                        _amountController.text =
                            widget.listing.requestedAmount.toString();
                        _installmentController.text =
                            _suggestedInstallmentAmount.toString();
                      });
                    }, selected: _parsedAmount == widget.listing.requestedAmount),
                  ]),

                  const SizedBox(height: 8),

                  // ── Interest Rate Field with Sleek Adjustable Slider Line ─
                  TextFormField(
                    controller: _interestController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n?.interestRateLabel ?? 'Interest rate (%)'),
                          _buildInfoTooltip(
                            'What is Interest Rate?',
                            'This is the extra % you earn on top of your principal. '  
                            'E.g. if you lend UGX 100,000 at 10% interest, '
                            'you get back UGX 110,000 in total.\n\n'
                            'Higher rate = more profit, but borrower may not accept.',
                          ),
                        ],
                      ),
                      prefixIcon: const Icon(Icons.percent_rounded),
                      suffixIcon: _buildStepperSuffix(
                        onDecrement: () => _adjustInterest(-1.0),
                        onIncrement: () => _adjustInterest(1.0),
                      ),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0 || n > 100) {
                        return l10n?.validationPercentRange ?? 'Use 0 to 100';
                      }
                      return null;
                    },
                  ),
                  _buildAdjustableRateLine(
                    value: _parsedInterest,
                    min: 0.0,
                    max: 50.0,
                    color: AppColors.accent,
                    onChanged: (v) {
                      setState(() {
                        _interestController.text = v.toStringAsFixed(0);
                        _installmentController.text =
                            _suggestedInstallmentAmount.toString();
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── Late Payment Fee Field with Sleek Adjustable Line & Currency Value ──
                  TextFormField(
                    controller: _lateFeeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n?.latePaymentFeeLabel ??
                              'Late payment fee (%)'),
                          _buildInfoTooltip(
                            'What is Late Payment Fee?',
                            'This fee is charged only if the borrower pays an '
                            'instalment after its due date.\n\n'
                            'It is calculated as a % of the overdue instalment amount.\n\n'
                            'E.g. a 5% late fee on a UGX 50,000 instalment = '
                            'UGX 2,500 extra charge. This protects you against delays.',
                          ),
                        ],
                      ),
                      prefixIcon: const Icon(Icons.warning_amber_rounded),
                      suffixIcon: _buildStepperSuffix(
                        onDecrement: () => _adjustLateFee(-1.0),
                        onIncrement: () => _adjustLateFee(1.0),
                      ),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0 || n > 100) {
                        return l10n?.validationPercentRange ?? 'Use 0 to 100';
                      }
                      return null;
                    },
                  ),
                  _buildAdjustableRateLine(
                    value: _parsedLateFee,
                    min: 0.0,
                    max: 30.0,
                    color: AppColors.warning,
                    onChanged: (v) {
                      setState(() {
                        _lateFeeController.text = v.toStringAsFixed(0);
                      });
                    },
                  ),
                  if (_parsedInstallment > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 13, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_parsedLateFee.toStringAsFixed(0)}% late fee = ${widget.listing.currency} ${_fmtAmount(_lateFeeCurrencyValue)} per overdue instalment (applied to late paid amount)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: _repaymentFrequency,
                    decoration: InputDecoration(
                      labelText:
                          l10n?.repaymentScheduleLabel ?? 'Repayment schedule',
                      prefixIcon: const Icon(Icons.event_repeat_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'monthly',
                          child: Text(l10n?.monthly ?? 'Monthly')),
                      DropdownMenuItem(
                          value: 'weekly',
                          child: Text(l10n?.weekly ?? 'Weekly')),
                      DropdownMenuItem(
                          value: 'one_time',
                          child:
                              Text(l10n?.oneTimePayment ?? 'One-time payment')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _repaymentFrequency = v;
                          // Reset due day selection to first valid option for new frequency
                          if (v == 'weekly') {
                            _selectedDueDay = 'Every Monday';
                          } else if (v == 'one_time') {
                            _selectedDueDay = 'Maturity date / End of term';
                          } else {
                            _selectedDueDay = '5th of every month';
                          }
                          _installmentController.text =
                              _suggestedInstallmentAmount.toString();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedDueDay,
                    decoration: InputDecoration(
                      labelText: l10n?.dueDayLabel ?? 'Due day / frequency',
                      prefixIcon: const Icon(Icons.today_outlined, size: 20),
                    ),
                    hint: Text(l10n?.dueDayHint ?? 'Select due day (e.g. 5th of every month)'),
                    items: (_repaymentFrequency == 'weekly'
                            ? _weeklyDueDayOptions
                            : _repaymentFrequency == 'one_time'
                                ? _oneTimeDueDayOptions
                                : _monthlyDueDayOptions)
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text(day),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedDueDay = v;
                    }),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedDueTime,
                    decoration: InputDecoration(
                      labelText: l10n?.dueCutoffTimeLabel ??
                          'Due cutoff time (for late fee timing)',
                      prefixIcon: const Icon(Icons.access_time_rounded, size: 20),
                    ),
                    hint: Text(l10n?.dueCutoffTimeHint ?? 'Select due time (e.g. 5:00 PM)'),
                    items: _dueTimeOptions
                        .map((time) => DropdownMenuItem(
                              value: time,
                              child: Text(time),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedDueTime = v;
                    }),
                  ),
                  const SizedBox(height: 16),

                  // ── Installment Amount Field with Steppers & Micro Preset Pills ─
                  TextFormField(
                    controller: _installmentController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n?.installmentAmountLabel(
                              widget.listing.currency) ??
                          'Installment amount (${widget.listing.currency})',
                      prefixIcon: const Icon(Icons.price_check_outlined),
                      suffixIcon: _buildStepperSuffix(
                        onDecrement: () => _adjustInstallment(-1),
                        onIncrement: () => _adjustInstallment(1),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? (l10n?.validationAmountRequired ?? 'Enter an amount')
                        : null,
                  ),
                  _buildQuickChips(chips: [
                    _microPill('Fair Target (${_fmtAmount(_suggestedInstallmentAmount)})', () {
                      setState(() {
                        _installmentController.text =
                            _suggestedInstallmentAmount.toString();
                      });
                    }, selected: _parsedInstallment == _suggestedInstallmentAmount),
                    _microPill('+10k', () => _adjustInstallment(1)),
                    _microPill('+50k', () => _adjustInstallment(5)),
                  ]),
                  const SizedBox(height: 16),

                  // ── Live Math & Return Estimates Panel ───────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isPrincipalLoss
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : (_isTargetDeficit
                              ? AppColors.warning.withValues(alpha: 0.12)
                              : AppColors.success.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isPrincipalLoss
                            ? AppColors.danger.withValues(alpha: 0.35)
                            : (_isTargetDeficit
                                ? AppColors.warning.withValues(alpha: 0.35)
                                : AppColors.success.withValues(alpha: 0.35)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isPrincipalLoss
                                  ? Icons.warning_amber_rounded
                                  : (_isTargetDeficit
                                      ? Icons.info_outline
                                      : Icons.trending_up_rounded),
                              size: 18,
                              color: _isPrincipalLoss
                                  ? AppColors.danger
                                  : (_isTargetDeficit
                                      ? AppColors.warning
                                      : AppColors.success),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LIVE RETURN ESTIMATE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: _isPrincipalLoss
                                    ? AppColors.danger
                                    : (_isTargetDeficit
                                        ? AppColors.warning
                                        : AppColors.success),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (_isPrincipalLoss
                                        ? AppColors.danger
                                        : (_isTargetDeficit
                                            ? AppColors.warning
                                            : AppColors.success))
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _isPrincipalLoss
                                    ? 'LOSS: -${widget.listing.currency} ${_fmtAmount(_parsedAmount - _totalRepayment)}'
                                    : (_isTargetDeficit
                                        ? 'BELOW TARGET'
                                        : 'PROFIT: +${widget.listing.currency} ${_fmtAmount(_netProfit)}'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _isPrincipalLoss
                                      ? AppColors.danger
                                      : (_isTargetDeficit
                                          ? AppColors.warning
                                          : AppColors.success),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Repayment ($_numberOfInstallments x ${_fmtAmount(_parsedInstallment)})',
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
                            Text(
                              '${widget.listing.currency} ${_fmtAmount(_totalRepayment)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _isPrincipalLoss
                                        ? AppColors.danger
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target Return (Principal + ${_parsedInterest.toStringAsFixed(0)}% interest)',
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
                            Text(
                              '${widget.listing.currency} ${_fmtAmount(_targetMinimumRepayment)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        _buildPlainEnglishReturnCard(),
                        if (_parsedInstallment != _suggestedInstallmentAmount) ...[
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _installmentController.text =
                                    _suggestedInstallmentAmount.toString();
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_fix_high_rounded,
                                      size: 14, color: AppColors.accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Auto-calculate fair installment (${widget.listing.currency} ${_fmtAmount(_suggestedInstallmentAmount)})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent,
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

                  const SizedBox(height: 12),
                  _buildScheduleTimeline(),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _expController,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: l10n?.additionalExpectationsLabel ??
                            'Additional expectations',
                        hintText: l10n?.optionalBorrowerNotesHint ??
                            'Optional notes for the borrower',
                        alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _loading || !_isOfferReady ? null : _previewOffer,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Preview Offer')),
                ])),
      ),
    );
  }
}


