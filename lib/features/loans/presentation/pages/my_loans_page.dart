import 'package:flutter/material.dart';

/// My Loans — Borrower + lender tabs. Full implementation Stage 2.8.
class MyLoansPage extends StatelessWidget {
  const MyLoansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Loans')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Borrower + lender tabs. Full implementation Stage 2.8.', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
