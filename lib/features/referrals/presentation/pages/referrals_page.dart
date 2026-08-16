import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/models/referral_dashboard.dart';
import '../cubit/referral_cubit.dart';

class ReferralsPage extends StatelessWidget {
  const ReferralsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReferralCubit>()..load(),
      child: const _ReferralsView(),
    );
  }
}

class _ReferralsView extends StatelessWidget {
  const _ReferralsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: BlocConsumer<ReferralCubit, ReferralState>(
        listener: (context, state) {
          if (state is! ReferralLoaded) return;
          final message = switch (state.lastAction) {
            ReferralAction.codeCopied => 'Referral code copied',
            ReferralAction.codeApplied => 'Referral code applied successfully!',
            ReferralAction.none => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          if (state is ReferralLoading || state is ReferralInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReferralError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<ReferralCubit>().load(),
            );
          }
          final dashboard = (state as ReferralLoaded).dashboard;
          return RefreshIndicator(
            onRefresh: () => context.read<ReferralCubit>().refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _ReferralCodePanel(dashboard: dashboard),
                const SizedBox(height: 16),
                _OverviewGrid(summary: dashboard.summary),
                const SizedBox(height: 20),
                Text(
                  'Referral history',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (dashboard.history.isEmpty)
                  const EmptyState(
                    icon: Icons.group_add_outlined,
                    title: 'No referrals yet',
                    subtitle: 'Shared referrals will appear here after signup.',
                  )
                else
                  ...dashboard.history.map(_ReferralHistoryTile.new),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReferralCodePanel extends StatelessWidget {
  const _ReferralCodePanel({required this.dashboard});

  final ReferralDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final marketer = dashboard.marketer;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Your referral code',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showApplyCodeSheet(
                  context,
                  context.read<ReferralCubit>(),
                ),
                icon: const Icon(Icons.card_giftcard_rounded, size: 16),
                label: const Text(
                  'Enter Code',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            marketer.referralCode.isNotEmpty
                ? marketer.referralCode
                : 'Generating...',
            style: const TextStyle(
              fontFamily: AppFonts.heading,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (marketer.referralLink.isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(
              marketer.referralLink,
              style: const TextStyle(color: AppColors.text2Dark, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.read<ReferralCubit>().shareReferral(),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share Link'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.read<ReferralCubit>().copyCode(),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Code'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApplyCodeSheet(BuildContext context, ReferralCubit cubit) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter referral code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'If a friend invited you to Nipanze, enter their referral code below.',
              style: TextStyle(fontSize: 13, color: AppColors.text2Dark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. NIPANZE-JOHN1234',
                labelText: 'Referral code',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final code = controller.text.trim();
                  if (code.isEmpty) return;
                  Navigator.pop(sheetContext);
                  await cubit.attributeReferral(code);
                },
                child: const Text('Apply Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.summary});

  final ReferralSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _MetricTile('Total referrals', '${summary.totalReferrals}',
            Icons.groups_outlined),
        _MetricTile('Registered', '${summary.registered}',
            Icons.person_add_alt_1_outlined),
        _MetricTile(
            'Verified', '${summary.verified}', Icons.verified_user_outlined),
        _MetricTile(
            'Qualified', '${summary.qualified}', Icons.task_alt_rounded),
        _MetricTile('Pending rewards', _money(summary.pendingRewards),
            Icons.schedule_rounded),
        _MetricTile('Available', _money(summary.availableRewards),
            Icons.account_balance_wallet_outlined),
        _MetricTile('Total earned', _money(summary.totalEarned),
            Icons.trending_up_rounded),
        _MetricTile(
            'Total paid', _money(summary.totalPaid), Icons.payments_outlined),
      ],
    );
  }

  String _money(int amount) =>
      '${NumberFormat.decimalPattern().format(amount)} ${summary.currency}';
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.text2Dark),
          ),
        ],
      ),
    );
  }
}

class _ReferralHistoryTile extends StatelessWidget {
  const _ReferralHistoryTile(this.item);

  final ReferralHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final reward = item.rewardAmount > 0
        ? '${NumberFormat.decimalPattern().format(item.rewardAmount)} ${item.rewardCurrency}'
        : 'No reward yet';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(item.status).withValues(alpha: 0.12),
          child: Icon(Icons.person_outline_rounded,
              color: _statusColor(item.status), size: 20),
        ),
        title: Text(
          item.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${DateFormat('MMM d, yyyy').format(item.registeredAt)} • '
          '${_label(item.status)} • ${_label(item.rewardStatus)}',
        ),
        trailing: Text(
          reward,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'qualified' || 'paid' || 'reward_earned' => AppColors.success,
      'verified' || 'registered' || 'reward_pending' => AppColors.accent,
      'rejected' || 'fraud_flagged' || 'fraud_hold' => AppColors.danger,
      _ => AppColors.text2Dark,
    };
  }

  String _label(String value) {
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
