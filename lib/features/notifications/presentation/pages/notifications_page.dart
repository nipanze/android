import 'package:flutter/material.dart';

/// Notifications — Real-time notifications feed. Stage 3.1.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Real-time notifications feed. Stage 3.1.', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
