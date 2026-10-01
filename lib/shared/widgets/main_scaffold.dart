// lib/shared/widgets/main_scaffold.dart
// ignore_for_file: unused_local_variable, prefer_final_locals

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/notifications/presentation/cubit/notification_cubit.dart';
import '../../../l10n/app_localizations.dart';
import 'offline_banner.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(
        label: 'Home',
        icon: Icons.home_rounded,
        route: AppRoutes.home),
    _TabItem(
        label: 'Watchlist',
        icon: Icons.star_outline_rounded,
        route: AppRoutes.watchlist),
    _TabItem(
        label: 'Post',
        icon: Icons.add_circle_rounded,
        route: AppRoutes.listingCreate),
    _TabItem(
        label: 'Activity',
        icon: Icons.receipt_long_outlined,
        route: AppRoutes.positions),
    _TabItem(
        label: 'Account',
        icon: Icons.person_outline_rounded,
        route: AppRoutes.account),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home) || location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.watchlist)) return 1;
    if (location.startsWith(AppRoutes.listingCreate) ||
        location.startsWith(AppRoutes.forexCreate) ||
        location.startsWith(AppRoutes.needsCreate)) return 2;
    if (location.startsWith(AppRoutes.positions) ||
        location.startsWith(AppRoutes.activity) ||
        location.startsWith(AppRoutes.myListings)) return 3;
    if (location.startsWith(AppRoutes.account)) return 4;
    return 0;
  }

  String _getTabLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;
    switch (key) {
      case 'Home':
        return l10n.navHome;
      case 'Watchlist':
        return l10n.navWatchlist;
      case 'Post':
        return l10n.navPost;
      case 'Activity':
        return l10n.navActivity;
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
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: (index) {
              if (_tabs[index].label == 'Post') {
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
    final isPost = tab.label == 'Post';

    Widget icon = Icon(
      tab.icon,
      size: isPost ? 28 : 22,
    );

    // Red dot indicator over Account ONLY when the user has incomplete account steps
    if (tab.label == 'Account') {
      return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;
          final hasIncomplete = user?.hasIncompleteAccountSteps ?? false;
          if (!hasIncomplete) return icon;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              icon,
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
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
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n?.postChoiceTitle ?? 'What do you want to post?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accent),
                title: Text(l10n?.postLoanAction ?? '💰 Loan Request'),
                subtitle: const Text('Borrow or finance capital for business or personal needs'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.listingCreate);
                },
              ),
              ListTile(
                leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.success),
                title: Text(l10n?.postForexAction ?? '💱 Forex Request'),
                subtitle: const Text('Exchange foreign currency at negotiated peer rates'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.forexCreate);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search_rounded, color: Color(0xFFF59E0B)),
                title: Text(l10n?.postNeedAction ?? '🔎 Need Request'),
                subtitle: const Text('Post what equipment, service, or procurement you need'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.needsCreate);
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
