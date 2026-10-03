// lib/shared/widgets/main_scaffold.dart

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

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home) ||
        location.startsWith(AppRoutes.dashboard)) {
      return 0;
    }
    if (location.startsWith(AppRoutes.watchlist)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.listingCreate) ||
        location.startsWith(AppRoutes.forexCreate) ||
        location.startsWith(AppRoutes.needsCreate)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.positions) ||
        location.startsWith(AppRoutes.activity) ||
        location.startsWith(AppRoutes.myListings)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.account)) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => getIt<NotificationCubit>()..load(),
      child: Scaffold(
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  // 1. Home
                  _buildNavTab(
                    context,
                    icon: Icons.home_rounded,
                    label: AppLocalizations.of(context)!.navHome,
                    isSelected: currentIndex == 0,
                    onTap: () => context.go(AppRoutes.home),
                  ),
                  // 2. Watchlist
                  _buildNavTab(
                    context,
                    icon: Icons.star_outline_rounded,
                    label: AppLocalizations.of(context)!.navWatchlist,
                    isSelected: currentIndex == 1,
                    onTap: () => context.go(AppRoutes.watchlist),
                  ),
                  // 3. Center + Button (TikTok-style prominent button, NO text)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showRequestChoice(context),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: 46,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: theme.colorScheme.onPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 4. Activity
                  _buildNavTab(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: AppLocalizations.of(context)!.navActivity,
                    isSelected: currentIndex == 3,
                    onTap: () => context.go(AppRoutes.positions),
                  ),
                  // 5. Account (with incomplete steps red dot)
                  _buildNavTabAccount(
                    context,
                    isSelected: currentIndex == 4,
                    onTap: () => context.go(AppRoutes.account),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final baseColor = Theme.of(context).colorScheme.onSurface;
    final color = isSelected ? baseColor : baseColor.withValues(alpha: 0.5);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabAccount(
    BuildContext context, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final baseColor = Theme.of(context).colorScheme.onSurface;
    final color = isSelected ? baseColor : baseColor.withValues(alpha: 0.5);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final user =
                    authState is AuthAuthenticated ? authState.user : null;
                final hasIncomplete =
                    user?.hasIncompleteAccountSteps ?? false;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 22,
                      color: color,
                    ),
                    if (hasIncomplete)
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
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.navAccount,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestChoice(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final optionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n?.postChoiceTitle ?? 'What do you want to post?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
                ),
                title: Text(
                  l10n?.postLoanAction ?? 'Loan Request',
                  style: optionTitleStyle,
                ),
                subtitle: const Text(
                  'Borrow or finance capital for business or personal needs',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.listingCreate);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.currency_exchange_rounded,
                  color: AppColors.success,
                ),
                title: Text(
                  l10n?.postForexAction ?? 'Forex Request',
                  style: optionTitleStyle,
                ),
                subtitle: const Text(
                  'Exchange foreign currency at negotiated peer rates',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.forexCreate);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFF59E0B),
                ),
                title: Text(
                  l10n?.postNeedAction ?? 'Need Request',
                  style: optionTitleStyle,
                ),
                subtitle: const Text(
                  'Post what equipment, service, or procurement you need',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.needsCreate);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.business_center_outlined,
                  color: Color(0xFF3B82F6),
                ),
                title: Text(
                  l10n?.postServiceAction ?? 'Offer a Service',
                  style: optionTitleStyle,
                ),
                subtitle: Text(
                  l10n?.postServiceSubtitle ??
                      'List your services and get matched with client requests',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.accountServices);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
