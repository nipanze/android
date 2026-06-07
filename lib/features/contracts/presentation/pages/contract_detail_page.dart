// lib/features/contracts/presentation/pages/contract_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../marketplace/domain/models/loan_listing.dart';
import '../../domain/models/negotiator_info.dart';
import '../cubit/contract_cubit.dart';

class ContractDetailPage extends StatelessWidget {
  const ContractDetailPage({super.key, required this.contractId});
  final String contractId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContractCubit>()..load(contractId),
      child: _ContractDetailView(contractId: contractId),
    );
  }
}

class _ContractDetailView extends StatelessWidget {
  const _ContractDetailView({required this.contractId});
  final String contractId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Contract'),
        actions: [
          BlocBuilder<ContractCubit, ContractState>(
            builder: (context, state) {
              if (state is! ContractLoaded) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _StatusBadge(state.contract.status),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ContractCubit, ContractState>(
        listener: (context, state) {
          if (state is ContractError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ));
          }
          if (state is ContractLoaded && state.hasRevealed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contacts revealed — negotiator will be in touch.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ContractLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ContractError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<ContractCubit>().refresh(contractId),
            );
          }
          if (state is ContractLoaded) {
            return _ContractBody(
              contractId: contractId,
              state: state,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ContractBody extends StatelessWidget {
  const _ContractBody({required this.contractId, required this.state});
  final String contractId;
  final ContractLoaded state;

  @override
  Widget build(BuildContext context) {
    final c = state.contract;

    return RefreshIndicator(
      onRefresh: () =>
          context.read<ContractCubit>().refresh(contractId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Amount
          UgxAmount(c.amount, fontSize: 26),
          const SizedBox(height: 4),
          Text(
            '${c.district} · ${c.durationMonths} months · ${c.interestRate.toStringAsFixed(1)}% p.a.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Non-custodial notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.verified_outlined, size: 14, color: AppColors.success),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Informational record only. Nipanze does not hold funds '
                'or process payments. All settlement is off-platform.',
                style: TextStyle(fontSize: 10, color: AppColors.success),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          // Contract terms
          const SectionHeader('Terms'),
          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _Row('Purpose', c.purpose),
              _divider(),
              _Row('Amount', 'UGX ${_fmt(c.amount)}'),
              _divider(),
              _Row('Interest rate', '${c.interestRate.toStringAsFixed(1)}% per annum'),
              _divider(),
              _Row('Duration', '${c.durationMonths} months'),
              if (c.indicativeMonthlyPayment != null) ...[
                _divider(),
                _Row('Indicative monthly',
                    'UGX ${_fmt(c.indicativeMonthlyPayment!)}',
                    sub: 'reference only'),
              ],
              if (c.indicativeTotalRepayment != null) ...[
                _divider(),
                _Row('Indicative total',
                    'UGX ${_fmt(c.indicativeTotalRepayment!)}',
                    sub: 'reference only'),
              ],
              _divider(),
              const _Row('Governing law', 'Laws of Uganda'),
            ]),
          )),

          // Negotiator section
          const SectionHeader('Negotiator'),
          _NegotiatorSection(
            negotiator: state.negotiator,
            hasRevealed: state.hasRevealed,
          ),

          // Contact reveal section
          if (!state.hasRevealed) ...[
            const SizedBox(height: 8),
            _RevealSection(
              contractId: contractId,
              isRevealing: state.isRevealing,
            ),
          ] else ...[
            const SizedBox(height: 8),
            _RevealedContactsSection(
              negotiator: state.negotiator,
            ),
          ],

          // Repayment schedule
          if (state.schedule.isNotEmpty) ...[
            const SectionHeader('Indicative repayment schedule'),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Participant-reported status only. '
                'Nipanze does not verify or track payments.',
                style: TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(height: 8),
            ...state.schedule.map((line) => _ScheduleLine(
                  line: line,
                  onReport: (status) => context
                      .read<ContractCubit>()
                      .reportRepayment(contractId, line.id, status),
                )),
          ],

          const SizedBox(height: 20),

          // Download PDF placeholder
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('PDF export — available in Stage 5'))),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Download contract PDF'),
          ),
        ]),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1);
  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── Negotiator section ───────────────────────────────────────────────────────

class _NegotiatorSection extends StatelessWidget {
  const _NegotiatorSection({
    required this.negotiator,
    required this.hasRevealed,
  });
  final NegotiatorInfo? negotiator;
  final bool hasRevealed;

  @override
  Widget build(BuildContext context) {
    if (negotiator == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(children: [
          const Icon(Icons.hourglass_top_rounded,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 12),
          Text('Negotiator being assigned...',
              style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: Text('N',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.purple,
                  fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assigned negotiator',
                style: TextStyle(
                    fontSize: 10, color: AppColors.purple,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(negotiator!.fullName,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            if (negotiator!.credentials != null)
              Text(negotiator!.credentials!,
                  style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            // Contact details blurred until reveal
            if (!hasRevealed)
              const _BlurredText('Contact details visible after reveal'),
            if (hasRevealed) ...[
              Text(negotiator!.phone,
                  style: const TextStyle(
                      fontFamily: 'DM Mono', fontSize: 11)),
              Text(negotiator!.email,
                  style: const TextStyle(fontSize: 11)),
            ],
          ],
        )),
      ]),
    );
  }
}

// ─── Reveal section ───────────────────────────────────────────────────────────

class _RevealSection extends StatelessWidget {
  const _RevealSection({
    required this.contractId,
    required this.isRevealing,
  });
  final String contractId;
  final bool   isRevealing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.lock_outline_rounded,
              size: 16, color: AppColors.purple),
          SizedBox(width: 8),
          Text('Contact details locked',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple)),
        ]),
        const SizedBox(height: 6),
        Text(
          'Borrower, lender, and negotiator contact details are '
          'hidden until you confirm the reveal. '
          'This action is irreversible.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),

        // Blurred preview rows
        const _BlurredRow(label: 'Borrower',   value: 'Sarah Nakato · +256 77X XXX XXX'),
        const SizedBox(height: 6),
        const _BlurredRow(label: 'Lender',     value: 'Pearl Capital Ltd · +256 7XX XXX XXX'),
        const SizedBox(height: 6),
        const _BlurredRow(label: 'Negotiator', value: 'James Ochieng · +256 70X XXX XXX'),
        const SizedBox(height: 14),

        ElevatedButton(
          onPressed: isRevealing
              ? null
              : () => _confirmReveal(context),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple),
          child: isRevealing
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Reveal contact details'),
        ),
      ]),
    );
  }

  void _confirmReveal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reveal contact details?'),
        content: const Text(
          'This will permanently unlock the borrower, lender, and '
          'negotiator contact details for this contract. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ContractCubit>()
                  .confirmReveal(contractId);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple),
            child: const Text('Confirm reveal'),
          ),
        ],
      ),
    );
  }
}

// ─── Revealed contacts ────────────────────────────────────────────────────────

class _RevealedContactsSection extends StatelessWidget {
  const _RevealedContactsSection({required this.negotiator});
  final NegotiatorInfo? negotiator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.visibility_rounded,
              size: 16, color: AppColors.success),
          SizedBox(width: 8),
          Text('Contacts revealed',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success)),
        ]),
        const SizedBox(height: 10),
        Text(
          'The negotiator will contact both parties to facilitate the deal. '
          'All financial settlement happens directly off-platform.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (negotiator != null) ...[
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 8),
          Text('Negotiator: ${negotiator!.fullName}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
          Text(negotiator!.phone,
              style: const TextStyle(
                  fontFamily: 'DM Mono', fontSize: 11)),
          Text(negotiator!.email,
              style: const TextStyle(fontSize: 11)),
        ],
      ]),
    );
  }
}

// ─── Schedule line ────────────────────────────────────────────────────────────

class _ScheduleLine extends StatelessWidget {
  const _ScheduleLine({required this.line, required this.onReport});
  final RepaymentLine line;
  final void Function(String status) onReport;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (line.reportedStatus) {
      'reported_paid' => AppColors.success,
      'reported_late' => AppColors.warning,
      'disputed'      => AppColors.danger,
      _               => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final statusLabel = switch (line.reportedStatus) {
      'reported_paid' => 'Paid',
      'reported_late' => 'Late',
      'disputed'      => 'Disputed',
      _               => 'Pending',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(children: [
        Text('#${line.instalmentNumber}',
            style: const TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 10),
        Text(_fmtDate(line.dueDate),
            style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text('UGX ${_fmt(line.totalUgx)}',
            style: const TextStyle(
                fontFamily: 'DM Mono', fontSize: 11)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showReportMenu(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColor)),
          ),
        ),
      ]),
    );
  }

  void _showReportMenu(BuildContext context) {
    if (line.reportedStatus == 'reported_paid') return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Text('Report instalment #${line.instalmentNumber}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.check_circle_outline,
                color: AppColors.success),
            title: const Text('Mark as paid'),
            onTap: () {
              Navigator.pop(context);
              onReport('reported_paid');
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning),
            title: const Text('Report late'),
            onTap: () {
              Navigator.pop(context);
              onReport('reported_late');
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded,
                color: AppColors.danger),
            title: const Text('Raise dispute'),
            onTap: () {
              Navigator.pop(context);
              onReport('disputed');
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
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

// ─── Blurred text ─────────────────────────────────────────────────────────────

class _BlurredText extends StatelessWidget {
  const _BlurredText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: const ColorFilter.mode(
          Colors.transparent, BlendMode.clear),
      child: Stack(children: [
        Text(text, style: const TextStyle(fontSize: 11)),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ]),
    );
  }
}

class _BlurredRow extends StatelessWidget {
  const _BlurredRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 80,
        child: Text(label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: Stack(children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: 'DM Mono', fontSize: 11)),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.9),
                child: Center(
                  child: Text(
                    '● ● ● ● ● ● ●',
                    style: TextStyle(
                        fontSize: 8,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                        letterSpacing: 4),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.sub});
  final String label; final String value; final String? sub;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const Spacer(),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500)),
        if (sub != null)
          Text(sub!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 9)),
      ]),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'in_execution' => ('Active',    AppColors.success),
      'completed'    => ('Completed', AppColors.accent),
      'defaulted'    => ('Defaulted', AppColors.danger),
      'disputed'     => ('Disputed',  AppColors.warning),
      _              => ('Draft',     AppColors.purple),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}