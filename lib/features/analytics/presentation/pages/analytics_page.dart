import 'package:flutter/material.dart';

/// Analytics — Portfolio charts from v_user_portfolio. Stage 3.6.
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Portfolio charts from v_user_portfolio. Stage 3.6.', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
