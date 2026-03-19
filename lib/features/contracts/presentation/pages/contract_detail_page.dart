import 'package:flutter/material.dart';

/// Contract detail — signing flow, trg_fn_check_all_lenders_signed, PDF. Stage 2.10.
class ContractDetailPage extends StatelessWidget {
  const ContractDetailPage({super.key, required this.contractId});
  final String contractId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contract Detail')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Contract: $contractId\n\nSigning flow — Stage 2.10.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
