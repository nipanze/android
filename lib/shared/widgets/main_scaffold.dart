// lib/shared/widgets/main_scaffold.dart
// ignore_for_file: unused_local_variable, prefer_final_locals

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/notifications/presentation/cubit/notification_cubit.dart';
import '../../../l10n/app_localizations.dart';
import 'offline_banner.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(
        label: 'Markets',
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
    if (location.startsWith(AppRoutes.forexCreate)) return 2;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  String _getTabLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;
    switch (key) {
      case 'Markets':
        return l10n.navMarkets;
      case 'Watchlist':
        return l10n.navWatchlist;
      case 'Request':
        return l10n.navRequest;
      case 'Positions':
        return l10n.navPositions;
      case 'Account':
        return l10n.navAccount;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return BlocProvider(
      create: (_) => getIt<NotificationCubit>()..load(),
      child: Scaffold(
        body: Column(children: [
          const OfflineBanner(),
          Expanded(child: child),
        ]),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              if (_tabs[index].label == 'Request') {
                _showRequestChoice(context);
                return;
              }
              context.go(_tabs[index].route);
            },
            items: _tabs.map((t) {
              return BottomNavigationBarItem(
                icon: _buildIcon(context, t, currentIndex),
                label: _getTabLabel(context, t.label),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, _TabItem tab, int currentIndex) {
    final isRequest = tab.label == 'Request';

    Widget icon = Icon(
      tab.icon,
      size: isRequest ? 28 : 22,
    );

    // Bell icon with unread badge on Account (notifications accessed from there)
    // Actually we show the bell on the marketplace top bar —
    // the unread badge here goes on the nav as a dot over Account
    // Simplified: just show dot over Account tab when unread > 0
    if (tab.label == 'Account') {
      return BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          final unread = state is NotificationLoaded ? state.unreadCount : 0;
          if (unread == 0) return icon;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              icon,
              Positioned(
                right: -4,
                top: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return icon;
  }

  void _showRequestChoice(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(l10n?.loanRequestTitle ?? 'Loan request'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.listingCreate);
                },
              ),
              ListTile(
                leading: const Icon(Icons.currency_exchange_rounded),
                title: Text(l10n?.forexRequestTitle ?? 'Forex request'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.forexCreate);
                },
              ),
            ],
          ),
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
