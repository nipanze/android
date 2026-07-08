// lib/features/positions/presentation/widgets/contract_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class ContractCard extends StatelessWidget {
  const ContractCard({
    super.key,
    required this.contract,
    required this.currentUserId,
  });

  final Map<String, dynamic> contract;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final id = contract['id'] as String;
    final status = contract['status'] as String? ?? 'draft';
    final amount = (contract['amount'] as num?)?.toInt() ?? 0;
    final rate = (contract['interest_rate'] as num?)?.toDouble() ?? 0;
    final months = contract['duration_months'] as int? ?? 0;
    final district = contract['district'] as String? ?? '';
    final title =
        (contract['loan_requests'] as Map?)?['title'] as String? ?? 'Untitled';
    final monthly =
        (contract['indicative_monthly_payment_ugx'] as num?)?.toInt();
    final borrowerId = contract['borrower_id'] as String? ?? '';
    final isBorrower = borrowerId == currentUserId;
    final role = isBorrower ? 'Borrower' : 'Lender';

    return GestureDetector(
      onTap: () => context.push('/contracts/$id'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor(status, context)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('$district · $months months · as $role',
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
            ),
            const SizedBox(width: 8),
            _ContractStatusBadge(status),
          ]),

          const SizedBox(height: 10),

          // Financials
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Amount', style: Theme.of(context).textTheme.bodySmall),
              UgxAmount(amount, fontSize: 15),
            ]),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Rate', style: Theme.of(context).textTheme.bodySmall),
              Text('${rate.toStringAsFixed(1)}% p.a.',
                  style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ]),
            if (monthly != null) ...[
              const SizedBox(width: 24),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('~Monthly', style: Theme.of(context).textTheme.bodySmall),
                Text(_fmt(monthly),
                    style: const TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ]),
            ],
          ]),

          const SizedBox(height: 10),

          // Non-custodial note + view link
          Row(children: [
            Expanded(
              child: Text(
                'Settlement off-platform · indicative figures only',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 9),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16),
          ]),
        ]),
      ),
    );
  }

  Color _borderColor(String status, BuildContext context) {
    switch (status) {
      case 'in_execution':
        return AppColors.success.withValues(alpha: 0.5);
      case 'completed':
        return AppColors.accent.withValues(alpha: 0.4);
      case 'defaulted':
        return AppColors.danger.withValues(alpha: 0.5);
      case 'disputed':
        return AppColors.warning.withValues(alpha: 0.5);
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
    return 'UGX $buf';
  }
}

class _ContractStatusBadge extends StatelessWidget {
  const _ContractStatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'in_execution' => ('Active', AppColors.success),
      'completed' => ('Completed', AppColors.accent),
      'defaulted' => ('Defaulted', AppColors.danger),
      'disputed' => ('Disputed', AppColors.warning),
      _ => ('Draft', AppColors.purple),
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
