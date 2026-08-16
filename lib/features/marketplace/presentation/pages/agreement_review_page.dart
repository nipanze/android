// lib/features/marketplace/presentation/pages/agreement_review_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/agreement_repository.dart';
import '../../domain/models/agreement.dart';

class AgreementReviewPage extends StatefulWidget {
  const AgreementReviewPage({super.key, required this.agreementId});

  final String agreementId;

  @override
  State<AgreementReviewPage> createState() => _AgreementReviewPageState();
}

class _AgreementReviewPageState extends State<AgreementReviewPage> {
  late final AgreementRepository _repo;
  Agreement? _agreement;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = getIt<AgreementRepository>();
    _loadAgreement();
  }

  Future<void> _loadAgreement() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final agreement = await _repo.getAgreement(widget.agreementId);
      if (!mounted) return;
      setState(() {
        _agreement = agreement;
        _loading = false;
      });
      _repo.watchAgreement(widget.agreementId).listen((updated) {
        if (mounted && updated != null) setState(() => _agreement = updated);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFacingErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deal Agreement')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _agreement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deal Agreement')),
        body: ErrorState(
          message: _error ?? 'Agreement not found',
          onRetry: _loadAgreement,
        ),
      );
    }

    final a = _agreement!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/positions');
            }
          },
        ),
        title: const Text('Deal Agreement'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAgreement,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status banner ──────────────────────────────────────────
              _StatusBanner(agreement: a),
              const SizedBox(height: 20),

              // ── Locked terms card ──────────────────────────────────────
              _SectionCard(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.accent,
                title: 'Locked Repayment Terms',
                child: Column(
                  children: [
                    _TermRow(
                      label: 'Principal',
                      value: 'UGX ${_fmt(a.loanAmount)}',
                      valueColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    _TermRow(
                      label: 'Interest rate',
                      value: '${a.interestRate.toStringAsFixed(1)}% per annum',
                    ),
                    _TermRow(
                      label: 'Repayment amount',
                      value: 'UGX ${_fmt(a.repaymentAmount)}',
                      valueColor: Theme.of(context).colorScheme.onSurface,
                      bold: true,
                    ),
                    _TermRow(
                      label: 'Repayment period',
                      value: '${a.repaymentPeriod} months',
                    ),
                    _TermRow(
                      label: 'Total repayment',
                      value: 'UGX ${_fmt(a.totalRepaymentAmount)}',
                    ),
                    _TermRow(
                      label: 'Frequency',
                      value: a.repaymentFrequency.displayName,
                    ),
                    _TermRow(
                      label: 'Late payment penalty',
                      value:
                          '${a.latePenaltyPercentage.toStringAsFixed(1)}% of missed installment',
                      valueColor: a.latePenaltyPercentage > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Agreement timeline ─────────────────────────────────────
              _SectionCard(
                icon: Icons.timeline_rounded,
                iconColor: AppColors.purple,
                title: 'Agreement Timeline',
                child: Column(
                  children: [
                    _TimelineRow(
                      label: 'Agreement created',
                      date: a.createdAt,
                      done: true,
                    ),
                    if (a.borrowerAgreedAt != null)
                      _TimelineRow(
                        label: 'Borrower confirmed',
                        date: a.borrowerAgreedAt,
                        done: true,
                      )
                    else
                      const _TimelineRow(
                        label: 'Borrower confirmation',
                        pending: true,
                      ),
                    if (a.lenderAgreedAt != null)
                      _TimelineRow(
                        label: 'Lender confirmed',
                        date: a.lenderAgreedAt,
                        done: true,
                      )
                    else
                      const _TimelineRow(
                        label: 'Lender confirmation',
                        pending: true,
                      ),
                    if (a.lockedAt != null)
                      _TimelineRow(
                        label: 'Contract locked',
                        date: a.lockedAt,
                        done: true,
                        isLast: true,
                      )
                    else
                      const _TimelineRow(
                        label: 'Contract locked',
                        pending: true,
                        isLast: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Agreement text ─────────────────────────────────────────
              _SectionCard(
                icon: Icons.description_outlined,
                iconColor: AppColors.text2Light,
                title: 'Full Agreement Text',
                child: Text(
                  a.agreementText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.55),
                ),
              ),
              const SizedBox(height: 24),

              // ── CTA ────────────────────────────────────────────────────
              if (a.isFullyLocked) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/marketplace/deal-unlock/${a.id}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: const Text('Unlock Deal & Contact'),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Contact details are only revealed after unlock.\n'
                    'Final terms are solely between borrower and lender.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                // Not yet locked — show waiting state
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Awaiting confirmation from both parties before the contract is locked.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.agreement});
  final Agreement agreement;

  @override
  Widget build(BuildContext context) {
    final isLocked = agreement.isFullyLocked;
    final statusColor = isLocked ? AppColors.success : AppColors.warning;
    final icon =
        isLocked ? Icons.verified_rounded : Icons.pending_actions_rounded;
    final label = isLocked ? 'Contract locked' : agreement.status.displayName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agreement Status',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      letterSpacing: 0.4,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 7),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                      color: iconColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Term Row ───────────────────────────────────────────────────────────────────

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline Row ───────────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    this.date,
    this.done = false,
    this.pending = false,
    this.isLast = false,
  });

  final String label;
  final DateTime? date;
  final bool done;
  final bool pending;
  final bool isLast;

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.success
        : pending
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
            : AppColors.accent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: done ? color : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 7, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight:
                              done ? FontWeight.w600 : FontWeight.normal,
                          color: done
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                        ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      _fmt(date!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.45),
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

// ─── Helpers ───────────────────────────────────────────────────────────────────

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
