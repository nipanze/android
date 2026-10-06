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
import 'offline_connection_listener.dart';
import 'post_choice_sheet.dart';

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
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: child),
            const OfflineConnectionListener(),
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
                      onTap: () => showPostChoiceSheet(context),
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
                final hasIncomplete = user?.hasIncompleteAccountSteps ?? false;
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
}
