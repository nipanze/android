import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
// Deleted: import '../../features/contracts/presentation/pages/contract_detail_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/kyc/presentation/pages/kyc_page.dart';
import '../../features/listings/presentation/pages/listing_create_page.dart';
import '../../features/listings/presentation/pages/my_listings_page.dart';
import '../../features/marketplace/presentation/pages/agreement_review_page.dart';
import '../../features/marketplace/presentation/pages/deal_unlock_page.dart';
import '../../features/marketplace/presentation/pages/loan_detail_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/positions/presentation/pages/positions_page.dart';
import '../../features/pricing/presentation/pages/pricing_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';
import '../../shared/widgets/main_scaffold.dart';

class AppRoutes {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resetPassword = '/auth/reset-password';

  static const String dashboard = '/dashboard';
  static const String marketplace = '/marketplace';
  static const String marketplaceDetail = '/marketplace/:requestId';
  static const String agreement = '/marketplace/agreement/:agreementId';
  static const String dealUnlock = '/marketplace/deal-unlock/:agreementId';
  static const String watchlist = '/watchlist';
  static const String positions = '/positions';
  static const String myListings = '/listings/my-listings';
  static const String listingCreate =
      '/listings/create'; // ← top-level, not nested
  static const String revealContact = '/marketplace/reveal/:revealId';
  static const String notifications = '/notifications';
  static const String kyc = '/kyc';
  static const String profile = '/profile';
  static const String account = '/account';
  static const String admin = '/admin';
  static const String pricing = '/pricing';
}

class AppRouter {
  AppRouter({required this.authBloc});

  final AuthBloc authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.marketplace,
    debugLogDiagnostics: false,
    redirect: _redirect,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      // ── Auth routes (no shell) ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (_, state) => _fade(state, const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (_, state) => _fade(state, const RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verifyEmail',
        pageBuilder: (_, state) => _fade(state, const VerifyEmailPage()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        pageBuilder: (_, state) => _fade(state, const ResetPasswordPage()),
      ),

      // ── Shell routes (bottom nav) ───────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (_, state) => _fade(state, const DashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.marketplace,
            name: 'marketplace',
            pageBuilder: (_, state) => _fade(state, const MarketplacePage()),
            routes: [
              GoRoute(
                path: ':requestId',
                name: 'marketplaceDetail',
                pageBuilder: (_, state) => _slide(
                  state,
                  LoanDetailPage(
                    requestId: state.pathParameters['requestId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.watchlist,
            name: 'watchlist',
            pageBuilder: (_, state) => _fade(state, const WatchlistPage()),
          ),
          // ── Request tab — goes directly to the create form ──────────
          GoRoute(
            path: AppRoutes.listingCreate,
            name: 'listingCreate',
            pageBuilder: (_, state) => _fade(state, const ListingCreatePage()),
          ),
          // ── My listings — accessible via profile/account, not the tab ──
          GoRoute(
            path: AppRoutes.myListings,
            name: 'myListings',
            pageBuilder: (_, state) => _fade(state, const MyListingsPage()),
          ),
          GoRoute(
            path: AppRoutes.positions,
            name: 'positions',
            pageBuilder: (_, state) => _fade(state, const PositionsPage()),
          ),
          GoRoute(
            path: AppRoutes.account,
            name: 'account',
            pageBuilder: (_, state) => _fade(state, const AccountPage()),
          ),
        ],
      ),

      // ── Non-shell authenticated routes ─────────────────────────────
      GoRoute(
        path: AppRoutes.agreement,
        name: 'agreement',
        pageBuilder: (_, state) => _slide(
          state,
          AgreementReviewPage(
            agreementId: state.pathParameters['agreementId']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.dealUnlock,
        name: 'dealUnlock',
        pageBuilder: (_, state) => _slide(
          state,
          DealUnlockPage(
            agreementId: state.pathParameters['agreementId']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.revealContact,
        name: 'revealContact',
        pageBuilder: (_, state) => _slide(
          state,
          // Placeholder for RevealContactPage — to be implemented in Stage 2.4
          Scaffold(
              appBar: AppBar(title: const Text('Contact Details')),
              body: const Center(child: Text('Revealed Contact Details'))),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (_, state) => _slide(state, const NotificationsPage()),
      ),
      GoRoute(
        path: AppRoutes.kyc,
        name: 'kyc',
        pageBuilder: (_, state) => _slide(state, const KycPage()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (_, state) => _slide(state, const ProfilePage()),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        pageBuilder: (_, state) => _slide(state, const AdminDashboardPage()),
      ),
      GoRoute(
        path: AppRoutes.pricing,
        name: 'pricing',
        pageBuilder: (_, state) => _slide(state, const PricingPage()),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;
    final onAuth = state.matchedLocation.startsWith('/auth');

    if (authState is AuthLoading) return null;

    if (authState is AuthUnauthenticated) {
      return onAuth ? null : AppRoutes.login;
    }

    if (authState is AuthAuthenticated) {
      if (onAuth) return AppRoutes.marketplace;
      if (authState.needsEmailVerification) return AppRoutes.verifyEmail;
      if (state.matchedLocation == AppRoutes.admin && !authState.user.isAdmin) {
        return AppRoutes.marketplace;
      }
    }

    return null;
  }

  static CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, widget) =>
          FadeTransition(opacity: animation, child: widget),
    );
  }

  static CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, widget) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: widget,
      ),
    );
  }
}

// Makes GoRouter listen to BLoC stream for redirects
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
