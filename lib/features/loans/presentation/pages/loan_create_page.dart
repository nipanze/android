import 'package:flutter/material.dart';

/// Create Loan Request — Full form coming in Stage 2.4 of the build plan.
class LoanCreatePage extends StatelessWidget {
  const LoanCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Loan Request')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Full form coming in Stage 2.4 of the build plan.', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
