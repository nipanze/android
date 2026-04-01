// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        title: const Text('Admin dashboard'),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12),
            child: Row(children: [
              const LiveDot(),
              const SizedBox(width: 4),
              Text('live', style: Theme.of(context).textTheme.bodySmall),
            ])),
        ],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.6,
          children: const [
            _KpiBox(label: 'Active listings', value: '41', trend: '↑ 6 this week', trendUp: true),
            _KpiBox(label: 'Bid volume', value: '312M', trend: '↑ UGX this month', trendUp: true),
            _KpiBox(label: 'Subscribers', value: '284', trend: '↑ 18 this week', trendUp: true),
            _KpiBox(label: 'Reveals / month', value: '47', trend: 'UGX 1,175,000 rev.', trendUp: true),
            _KpiBox(label: 'Avg rate', value: '11.4%', trend: '↓ 0.3% vs last mo.', trendUp: false),
            _KpiBox(label: 'Match rate', value: '68%', trend: 'Listings with bids', trendUp: true),
          ]),
        const SectionHeader('Quick actions'),
        const Card(child: Padding(padding: EdgeInsets.all(14), child: Column(children: [
          _AdminAction(icon: Icons.verified_user_outlined, label: 'Review KYC submissions', color: AppColors.accent),
          Divider(height: 16),
          _AdminAction(icon: Icons.people_outline, label: 'Manage users', color: AppColors.purple),
          Divider(height: 16),
          _AdminAction(icon: Icons.people_alt_outlined, label: 'Manage negotiators', color: AppColors.success),
          Divider(height: 16),
          _AdminAction(icon: Icons.history_outlined, label: 'View audit logs', color: AppColors.warning),
          Divider(height: 16),
          _AdminAction(icon: Icons.settings_outlined, label: 'System settings', color: AppColors.text2Dark),
        ]))),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withOpacity(0.3))),
          child: const Text('Admin dashboard — Stage 5 feature. Full KPI data, KYC review, and user management coming in Stage 5.', style: TextStyle(fontSize: 11))),
      ])),
    );
  }
}
class _KpiBox extends StatelessWidget {
  const _KpiBox({required this.label, required this.value, required this.trend, required this.trendUp});
  final String label, value, trend; final bool trendUp;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Theme.of(context).dividerColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9, letterSpacing: 0.5)),
      const Spacer(),
      Text(value, style: const TextStyle(fontFamily: AppFonts.body, fontSize: 18, fontWeight: FontWeight.w600)),
      Text(trend, style: TextStyle(fontSize: 10, color: trendUp ? AppColors.success : AppColors.danger)),
    ]));
}
class _AdminAction extends StatelessWidget {
  const _AdminAction({required this.icon, required this.label, required this.color});
  final IconData icon; final String label; final Color color;
  @override Widget build(BuildContext context) => InkWell(onTap: () {},
    child: Row(children: [
      Icon(icon, size: 18, color: color), const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontSize: 13)), const Spacer(),
      Icon(Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
    ]));
}
