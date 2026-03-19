import 'package:flutter/material.dart';

/// Repayment schedule — installments from loan_repayments. Stage 2.12.
class RepaymentSchedulePage extends StatelessWidget {
  const RepaymentSchedulePage({super.key, required this.contractId});
  final String contractId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repayment Schedule')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Contract: $contractId\n\nSchedule from loan_repayments — Stage 2.12.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
