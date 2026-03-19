import 'package:flutter/material.dart';

/// My Bids — Lender bid history across all loans. Stage 2.8.
class MyBidsPage extends StatelessWidget {
  const MyBidsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bids')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Lender bid history across all loans. Stage 2.8.', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
