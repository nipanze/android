// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome back',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(user?.fullName ?? user?.email ?? 'User',
                    style: Theme.of(context).textTheme.headlineMedium),
              ]),
              const Spacer(),
            ]),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                _QuickAction(
                    icon: Icons.show_chart_rounded,
                    label: 'Browse market',
                    color: AppColors.accent,
                    onTap: () => context.go(AppRoutes.marketplace)),
                _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'List a request',
                    color: AppColors.success,
                    onTap: () => context.push(AppRoutes.listingCreate)),
                _QuickAction(
                    icon: Icons.star_outline_rounded,
                    label: 'Watchlist',
                    color: AppColors.warning,
                    onTap: () => context.go(AppRoutes.watchlist)),
                _QuickAction(
                    icon: Icons.verified_user_outlined,
                    label: 'KYC status',
                    color: AppColors.purple,
                    onTap: () => context.push(AppRoutes.kyc)),
              ],
            ),
            const SizedBox(height: 20),
            SectionHeader('Quick info'),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _InfoRow('Subscription', user?.subscriptionPlan.name ?? '—'),
                const Divider(height: 16),
                _InfoRow('KYC status', user?.kycStatus.name ?? '—'),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]);
}
