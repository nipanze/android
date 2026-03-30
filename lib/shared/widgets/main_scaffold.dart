import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(label: 'Markets', icon: Icons.show_chart_rounded, route: AppRoutes.marketplace),
    _TabItem(label: 'Watchlist', icon: Icons.star_outline_rounded, route: AppRoutes.watchlist),
    _TabItem(label: 'Positions', icon: Icons.account_balance_wallet_outlined, route: AppRoutes.positions),
    _TabItem(label: 'Account', icon: Icons.person_outline_rounded, route: AppRoutes.account),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Offline banner placeholder — wired up in Stage 3
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => context.go(_tabs[index].route),
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.label, required this.icon, required this.route});
  final String label;
  final IconData icon;
  final String route;
}
