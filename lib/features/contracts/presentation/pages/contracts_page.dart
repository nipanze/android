import 'package:flutter/material.dart';

/// Contracts — List of loan_contracts for current user. Stage 2.10.
class ContractsPage extends StatelessWidget {
  const ContractsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contracts')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('List of loan_contracts for current user. Stage 2.10.', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
