import 'package:flutter/material.dart';

/// KYC Verification — Document upload to Supabase Storage. Stage 3.2.
class KycPage extends StatelessWidget {
  const KycPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Document upload to Supabase Storage. Stage 3.2.', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
