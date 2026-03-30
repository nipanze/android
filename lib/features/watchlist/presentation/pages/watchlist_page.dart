// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Watchlist', style: Theme.of(context).textTheme.headlineMedium),
            Text("Listings you're tracking", style: Theme.of(context).textTheme.bodySmall),
          ]),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
            child: const Text('0 saved', style: TextStyle(fontSize: 10))),
        ])),
        Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withOpacity(0.2))),
          child: const Text('Free for all users. Get notified when bids change, rates improve, or a listing is closing. Subscribe to bid.', style: TextStyle(fontSize: 11))),
        Expanded(child: EmptyState(icon: Icons.star_outline_rounded, title: 'No saved listings',
          subtitle: 'Browse the marketplace and tap "Save to watchlist" on any listing.',
          action: ElevatedButton(onPressed: () => context.go('/marketplace'), child: const Text('Browse marketplace')))),
      ])),
    );
  }
}
