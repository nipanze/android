import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(
        label: 'Marketplace',
        icon: Icons.show_chart_rounded,
        route: AppRoutes.marketplace),
    _TabItem(
        label: 'Watchlist',
        icon: Icons.star_outline_rounded,
        route: AppRoutes.watchlist),
    _TabItem(
        label: 'Request',
        icon: Icons.add_circle_rounded,
        route: AppRoutes.listingCreate),
    _TabItem(
        label: 'Positions',
        icon: Icons.receipt_long_outlined,
        route: AppRoutes.positions),
    _TabItem(
        label: 'Account',
        icon: Icons.person_outline_rounded,
        route: AppRoutes.account),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    // listingCreate before myListings — more specific prefix wins
    if (location.startsWith(AppRoutes.listingCreate)) return 2;
    if (location.startsWith(AppRoutes.myListings)) {
      return 2; // "My requests" accessed via + in AppBar still highlights Request
    }
    if (location.startsWith(AppRoutes.marketplace)) return 0;
    if (location.startsWith(AppRoutes.watchlist)) return 1;
    if (location.startsWith(AppRoutes.positions)) return 3;
    if (location.startsWith(AppRoutes.account)) return 4;

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: Stack(
        children: [
          child,
          // Offline banner — Stage 3
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => context.go(_tabs[index].route),
          items: _tabs.map((t) {
            final isRequest = t.label == 'Request';
            return BottomNavigationBarItem(
              icon: Icon(t.icon, size: isRequest ? 28 : 22),
              label: t.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(
      {required this.label, required this.icon, required this.route});
  final String label;
  final IconData icon;
  final String route;
}
