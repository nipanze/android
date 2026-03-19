// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Dashboard — Stage 2.1. Shows v_user_portfolio aggregates.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(Routes.notifications),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Portfolio Summary',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Text('Full dashboard coming in Stage 2.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push(Routes.loanCreate),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Request a Loan'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go(Routes.marketplace),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Browse Marketplace'),
          ),
        ],
      ),
    );
  }
}
