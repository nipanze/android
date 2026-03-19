// ignore_for_file: duplicate_import, unused_import, avoid_relative_lib_imports, directives_ordering

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/onboarding_page.dart' show OnboardingPage;
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../main.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/marketplace/presentation/pages/loan_detail_page.dart';
import '../../features/loans/presentation/pages/loan_create_page.dart';
import '../../features/loans/presentation/pages/my_loans_page.dart';
import '../../features/loans/presentation/pages/repayment_schedule_page.dart';
import '../../features/bids/presentation/pages/my_bids_page.dart';
import '../../features/contracts/presentation/pages/contracts_page.dart';
import '../../features/contracts/presentation/pages/contract_detail_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/kyc/presentation/pages/kyc_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';

/// All route path constants. Import this instead of using raw strings.
abstract class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const verifyEmail = '/auth/verify-email';
  static const forgotPassword = '/auth/forgot-password';

  // Main tabs (shell route children)
  static const dashboard = '/dashboard';
  static const marketplace = '/marketplace';
  static const myLoans = '/loans/my-loans';
  static const wallet = '/wallet';
  static const profile = '/profile';

  // Sub-pages
  static const loanDetail = '/marketplace/:requestId';
  static const loanCreate = '/loans/create';
  static const repaymentSchedule = '/loans/repayments/:contractId';
  static const myBids = '/bids';
  static const contracts = '/contracts';
  static const contractDetail = '/contracts/:contractId';
  static const notifications = '/notifications';
  static const kyc = '/kyc';
  static const analytics = '/analytics';
  static const admin = '/admin';

  /// Build /marketplace/:requestId with a real id.
  static String loanDetailPath(String requestId) => '/marketplace/$requestId';
  static String repaymentSchedulePath(String contractId) => '/loans/repayments/$contractId';
  static String contractDetailPath(String contractId) => '/contracts/$contractId';
}

abstract class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: Routes.splash,
        debugLogDiagnostics: true,

        // ---------------------------------------------------------------------------
        // Auth guard: runs on every navigation event.
        // ---------------------------------------------------------------------------
        redirect: (context, state) {
          final session = supabase.auth.currentSession;
          final loc = state.matchedLocation;

          // Allow public routes regardless of auth state.
          const publicRoutes = [
            Routes.splash,
            Routes.onboarding,
            Routes.login,
            Routes.register,
            Routes.forgotPassword,
          ];
          if (publicRoutes.contains(loc)) return null;

          // Not signed in → login
          if (session == null) return Routes.login;

          // Signed in but email not confirmed → verify
          if (session.user.emailConfirmedAt == null && loc != Routes.verifyEmail) {
            return Routes.verifyEmail;
          }

          return null; // proceed
        },

        routes: [
          // Splash
          GoRoute(
            path: Routes.splash,
            builder: (_, __) => const SplashPage(),
          ),

          // Onboarding
          GoRoute(
            path: Routes.onboarding,
            builder: (_, __) => const OnboardingPage(),
          ),

          // Auth routes (no shell)
          GoRoute(path: Routes.login, builder: (_, __) => const LoginPage()),
          GoRoute(path: Routes.register, builder: (_, __) => const RegisterPage()),
          GoRoute(
            path: Routes.verifyEmail,
            builder: (_, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              return VerifyEmailPage(email: email);
            },
          ),
          GoRoute(path: Routes.forgotPassword, builder: (_, __) => const ForgotPasswordPage()),

          // Shell route — main scaffold with bottom nav
          ShellRoute(
            navigatorKey: _shellNavigatorKey,
            builder: (_, __, child) => MainScaffold(child: child),
            routes: [
              GoRoute(path: Routes.dashboard, builder: (_, __) => const DashboardPage()),
              GoRoute(path: Routes.marketplace, builder: (_, __) => const MarketplacePage()),
              GoRoute(path: Routes.myLoans, builder: (_, __) => const MyLoansPage()),
              GoRoute(path: Routes.wallet, builder: (_, __) => const WalletPage()),
              GoRoute(path: Routes.profile, builder: (_, __) => const ProfilePage()),
            ],
          ),

          // Sub-pages (push over shell)
          GoRoute(
            path: Routes.loanDetail,
            builder: (_, state) => LoanDetailPage(requestId: state.pathParameters['requestId']!),
          ),
          GoRoute(path: Routes.loanCreate, builder: (_, __) => const LoanCreatePage()),
          GoRoute(
            path: Routes.repaymentSchedule,
            builder: (_, state) =>
                RepaymentSchedulePage(contractId: state.pathParameters['contractId']!),
          ),
          GoRoute(path: Routes.myBids, builder: (_, __) => const MyBidsPage()),
          GoRoute(path: Routes.contracts, builder: (_, __) => const ContractsPage()),
          GoRoute(
            path: Routes.contractDetail,
            builder: (_, state) =>
                ContractDetailPage(contractId: state.pathParameters['contractId']!),
          ),
          GoRoute(path: Routes.notifications, builder: (_, __) => const NotificationsPage()),
          GoRoute(path: Routes.kyc, builder: (_, __) => const KycPage()),
          GoRoute(path: Routes.analytics, builder: (_, __) => const AnalyticsPage()),
          GoRoute(path: Routes.admin, builder: (_, __) => const AdminDashboardPage()),
        ],
      );
}
