// lib/features/marketplace/presentation/pages/proposed_deal_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/agreement_repository.dart';
import '../../domain/models/agreement.dart';

class ProposedDealPage extends StatefulWidget {
  const ProposedDealPage({super.key, required this.agreementId});

  final String agreementId;

  @override
  State<ProposedDealPage> createState() => _ProposedDealPageState();
}

class _ProposedDealPageState extends State<ProposedDealPage> {
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
      Agreement? agreement;
      try {
        agreement = await _repo.getAgreement(widget.agreementId);
      } catch (_) {
        agreement = await _repo.getAgreementByOfferId(widget.agreementId);
        agreement ??=
            await _repo.getAgreementByRequestId(widget.agreementId);
      }

      if (agreement == null) {
        throw const FormatException('Agreement details not found');
      }

      if (!mounted) return;
      setState(() {
        _agreement = agreement;
        _loading = false;
      });
      _repo.watchAgreement(agreement.id).listen((updated) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subtitleColor = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final cardBgColor = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final borderColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : AppColors.borderLight;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Proposed Deal'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.success)),
      );
    }

    if (_error != null || _agreement == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Proposed Deal'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
        body: ErrorState(
          message: _error ?? 'Proposed deal not found',
          onRetry: _loadAgreement,
        ),
      );
    }

    final a = _agreement!;
    final isLocked = a.isFullyLocked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposed Deal'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Header Banner Card ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isLocked ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isLocked ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLocked ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                              size: 13,
                              color: isLocked ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isLocked ? 'Contract Locked' : 'Proposed Terms',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isLocked ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'ID: ${a.id.length > 8 ? a.id.substring(0, 8).toUpperCase() : a.id}',
                        style: TextStyle(fontSize: 11.5, color: subtitleColor, fontFamily: AppFonts.body),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Principal Amount',
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${a.currency} ${_fmt(a.loanAmount)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      fontFamily: AppFonts.heading,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 2. Financial Breakdown Card ────────────────────────────────
            _DealSectionCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.accent,
              title: 'Financial Breakdown',
              child: Column(
                children: [
                  _DealTermRow(label: 'Principal Amount', value: '${a.currency} ${_fmt(a.loanAmount)}', bold: true),
                  _DealTermRow(label: 'Interest Rate', value: '${a.interestRate.toStringAsFixed(1)}% per annum'),
                  _DealTermRow(label: 'Repayment Amount', value: '${a.currency} ${_fmt(a.repaymentAmount)}'),
                  _DealTermRow(label: 'Repayment Period', value: '${a.repaymentPeriod} months'),
                  _DealTermRow(
                    label: 'Total Repayment',
                    value: '${a.currency} ${_fmt(a.totalRepaymentAmount)}',
                    valueColor: AppColors.accent,
                    bold: true,
                  ),
                  _DealTermRow(label: 'Repayment Frequency', value: a.repaymentFrequency.displayName),
                  _DealTermRow(
                    label: 'Late Payment Penalty',
                    value: '${a.latePenaltyPercentage.toStringAsFixed(1)}% of installment',
                    valueColor: a.latePenaltyPercentage > 0 ? AppColors.warning : AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 3. Legal Agreement Text Document Card ──────────────────────
            _DealSectionCard(
              icon: Icons.gavel_outlined,
              iconColor: AppColors.purple,
              title: 'Legal Contract & Terms',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgDark : AppColors.bg3Light,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      a.agreementText,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.6,
                        color: textColor,
                        fontFamily: AppFonts.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 4. Legal Disclaimer ───────────────────────────────────────
            Center(
              child: Text(
                'This proposed deal agreement forms a binding framework upon mutual consent.\n'
                'Nipanze provides the platform for agreement resolution.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: subtitleColor, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DealSectionCard extends StatelessWidget {
  const _DealSectionCard({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final borderColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : AppColors.borderLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DealTermRow extends StatelessWidget {
  const _DealTermRow({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final defaultValColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: labelColor),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? defaultValColor,
            ),
          ),
        ],
      ),
    );
  }
}

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
