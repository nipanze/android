import '../../features/provider/presentation/pages/provider_services_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/pages/blocked_users_page.dart';
import '../../features/account/presentation/pages/profile_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/positions/presentation/pages/positions_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/forex/presentation/pages/forex_create_page.dart';
import '../../features/forex/presentation/pages/forex_detail_page.dart';
import '../../features/forex/presentation/pages/my_forex_requests_page.dart';
import '../../features/kyc/presentation/pages/kyc_page.dart';
import '../../features/listings/presentation/pages/listing_create_page.dart';
import '../../features/listings/presentation/pages/my_listings_page.dart';
import '../../features/marketplace/presentation/pages/agreement_review_page.dart';
import '../../features/marketplace/presentation/pages/contact_details_page.dart';
import '../../features/marketplace/presentation/pages/loan_detail_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/marketplace/presentation/pages/needs_detail_page.dart';
import '../../features/marketplace/presentation/pages/proposed_deal_page.dart';
import '../../features/needs/presentation/pages/needs_create_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/pricing/presentation/pages/pricing_page.dart';
import '../../features/referrals/presentation/pages/referrals_page.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';
import '../../shared/widgets/main_scaffold.dart';

// Deleted: import '../../features/contracts/presentation/pages/contract_detail_page.dart';

class AppRoutes {
  static const String welcome = '/auth/welcome';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resetPassword = '/auth/reset-password';

  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String marketplace = '/marketplace';
  static const String marketplaceDetail = '/marketplace/:requestId';
  static const String agreement = '/marketplace/agreement/:agreementId';
  static const String proposedDeal = '/marketplace/proposed-deal/:agreementId';
  static const String contactDetails =
      '/marketplace/contact-details/:agreementId';
  static const String dealUnlock = '/marketplace/deal-unlock/:agreementId';
  static const String watchlist = '/watchlist';
  static const String activity = '/activity';
  static const String positions = '/positions';
  static const String myListings = '/listings/my-listings';
  static const String listingCreate =
      '/listings/create'; // ← top-level, not nested
  static const String forexCreate = '/forex/create';
  static const String needsCreate = '/needs/create';
  static const String forexDetail = '/forex/:requestId';
  static const String myForexRequests = '/forex/my-forex';
  static const String notifications = '/notifications';
  static const String kyc = '/kyc';
  static const String profile = '/profile';
  static const String account = '/account';
  static const String accountServices = '/account/services';
  static const String blockedUsers = '/account/blocked-users';
  static const String admin = '/admin';
  static const String pricing = '/pricing';
  static const String referrals = '/referrals';
}

class AppRouter {
  AppRouter({required this.authBloc});

  final AuthBloc authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    redirect: _redirect,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => AppRoutes.home,
      ),
      // ── Auth routes (no shell) ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (_, state) => _fade(state, const WelcomePage()),
      ),
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
        path: '/r/:referralCode',
        name: 'referralRegister',
        pageBuilder: (_, state) => _fade(
          state,
          RegisterPage(referralCode: state.pathParameters['referralCode']),
        ),
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
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (_, state) => _fade(state, const HomePage()),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            redirect: (_, __) => AppRoutes.home,
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
              GoRoute(
                path: 'needs/:requestId',
                name: 'needsDetail',
                pageBuilder: (_, state) => _slide(
                  state,
                  NeedsDetailPage(
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
          // ── Request creation routes (bottom nav visible) ──────────
          GoRoute(
            path: AppRoutes.listingCreate,
            name: 'listingCreate',
            pageBuilder: (_, state) => _fade(state, const ListingCreatePage()),
          ),
          GoRoute(
            path: AppRoutes.forexCreate,
            name: 'forexCreate',
            pageBuilder: (_, state) => _fade(state, const ForexCreatePage()),
          ),
          GoRoute(
            path: AppRoutes.needsCreate,
            name: 'needsCreate',
            pageBuilder: (_, state) => _fade(state, const NeedsCreatePage()),
          ),
          GoRoute(
            path: AppRoutes.forexDetail,
            name: 'forexDetail',
            pageBuilder: (_, state) => _slide(
              state,
              ForexDetailPage(requestId: state.pathParameters['requestId']!),
            ),
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
            path: AppRoutes.activity,
            name: 'activity',
            redirect: (_, __) => AppRoutes.positions,
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
        path: AppRoutes.myForexRequests,
        name: 'myForexRequests',
        pageBuilder: (_, state) => _slide(state, const MyForexRequestsPage()),
      ),
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
        path: AppRoutes.proposedDeal,
        name: 'proposedDeal',
        pageBuilder: (_, state) => _slide(
          state,
          ProposedDealPage(
            agreementId: state.pathParameters['agreementId']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.contactDetails,
        name: 'contactDetails',
        pageBuilder: (_, state) => _slide(
          state,
          ContactDetailsPage(
            agreementId: state.pathParameters['agreementId']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.dealUnlock,
        name: 'dealUnlock',
        redirect: (context, state) =>
            '/marketplace/contact-details/${state.pathParameters['agreementId']}',
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
        path: AppRoutes.accountServices,
        name: 'accountServices',
        pageBuilder: (_, state) => _slide(state, const ProviderServicesPage()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (_, state) =>
            _slide(state, ProfilePage()), // ignore: prefer_const_constructors
      ),
      GoRoute(
        path: AppRoutes.blockedUsers,
        name: 'blockedUsers',
        pageBuilder: (_, state) => _slide(state, const BlockedUsersPage()),
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
      GoRoute(
        path: AppRoutes.referrals,
        name: 'referrals',
        pageBuilder: (_, state) => _slide(state, const ReferralsPage()),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;
    final onAuth = state.matchedLocation.startsWith('/auth');
    final onReferralSignup = state.matchedLocation.startsWith('/r/');

    if (authState is AuthLoading) return null;

    if (authState is AuthUnauthenticated) {
      return onAuth || onReferralSignup ? null : AppRoutes.welcome;
    }

    if (authState is AuthAuthenticated) {
      if (onAuth || onReferralSignup) return AppRoutes.home;
      if (authState.needsEmailVerification) return AppRoutes.verifyEmail;
      if (state.matchedLocation == AppRoutes.admin && !authState.user.isAdmin) {
        return AppRoutes.marketplace;
      }
    }

    return null;
  }

  static CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: ValueKey('fade-${state.uri}'),
      child: child,
      transitionsBuilder: (_, animation, __, widget) =>
          FadeTransition(opacity: animation, child: widget),
    );
  }

  static CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: ValueKey('slide-${state.uri}'),
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
