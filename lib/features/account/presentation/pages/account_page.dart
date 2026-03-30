import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    return Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      const SizedBox(height: 8),
      // Avatar
      Container(width: 56, height: 56, decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28)),
        child: Center(child: Text(
          user?.fullName?.isNotEmpty == true ? user!.fullName![0].toUpperCase() : 'U',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 10),
      Text(user?.fullName ?? 'User', style: Theme.of(context).textTheme.titleMedium),
      Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      if (user != null) RepTierBadge(user.repTier),
      const SizedBox(height: 20),
      const SectionHeader('Subscription'),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(user?.subscriptionPlan.name.toUpperCase() ?? 'WATCHLIST',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            // ignore: deprecated_member_use
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text('Active', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.success))),
        ]),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        Text(_planDescription(user?.subscriptionPlan), style: Theme.of(context).textTheme.bodySmall),
      ]))),
      const SectionHeader('Upgrade plan'),
      Row(children: SubscriptionPlan.values.map((plan) {
        final isSelected = user?.subscriptionPlan == plan;
        return Expanded(child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: isSelected ? AppColors.accent.withOpacity(0.08) : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.accent : Theme.of(context).dividerColor)),
            child: Column(children: [
              Text(_planPrice(plan), style: TextStyle(fontFamily: 'DM Mono', fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? AppColors.accent : null)),
              Text(plan.name[0].toUpperCase() + plan.name.substring(1), style: const TextStyle(fontSize: 10)),
            ]),
          ),
        ));
      }).toList()),
      const SectionHeader('Identity'),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        _InfoRow('KYC status', user?.kycStatus.name ?? '—', onTap: () => context.push(AppRoutes.kyc)),
        const Divider(height: 16),
        _InfoRow('Reputation score', '${user?.creditScore ?? 50}/100'),
        const Divider(height: 16),
        _InfoRow('Lender token', user?.lenderToken ?? '—'),
      ]))),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () { context.read<AuthBloc>().add(const AuthSignOutRequested()); context.go(AppRoutes.login); },
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
        child: const Text('Sign out')),
      const SizedBox(height: 16),
      Text('Nipanze is a technology marketplace. We do not hold, pool, or move your funds. All deals are arranged directly between matched participants.',
        textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.7)),
    ]))));
  }
  String _planPrice(SubscriptionPlan plan) { switch(plan) { case SubscriptionPlan.watchlist: return 'Free'; case SubscriptionPlan.borrower: return '20K'; case SubscriptionPlan.lender: return '35K'; case SubscriptionPlan.pro: return '150K'; } }
  String _planDescription(SubscriptionPlan? plan) { switch(plan) { case SubscriptionPlan.borrower: return 'List up to 2 requests · Accept bids · Contact reveals'; case SubscriptionPlan.lender: return 'Bid on listings · Track investments · Realtime alerts'; case SubscriptionPlan.pro: return 'All features + Analytics API access'; default: return 'Browse and watch listings — free forever.'; } }
}
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.onTap});
  final String label; final String value; final VoidCallback? onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, child: Row(children: [
    Text(label, style: Theme.of(context).textTheme.bodyMedium), const Spacer(),
    Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    if (onTap != null) const Icon(Icons.chevron_right, size: 16),
  ]));
}
