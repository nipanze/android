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
                const _ReferralProcess(),
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
    final hasCode = marketer.referralCode.isNotEmpty;
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
          const Text(
            'Your referral code',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (hasCode)
            SelectableText(
              marketer.referralCode.toUpperCase(),
              style: const TextStyle(
                fontFamily: AppFonts.heading,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            )
          else ...
            [
              Text(
                'Your code is being generated…',
                style: TextStyle(
                  fontSize: 16,
                  color: _mutedTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.read<ReferralCubit>().load(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try again'),
              ),
            ],
          if (hasCode && marketer.referralLink.isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(
              marketer.referralLink,
              style: TextStyle(
                color: _mutedTextColor(context),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Invite people to Nipanze and earn rewards when they complete the required qualifying actions.',
            style: TextStyle(
              color: _mutedTextColor(context),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasCode
                      ? () => context.read<ReferralCubit>().shareReferral()
                      : null,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share Link'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasCode
                      ? () => context.read<ReferralCubit>().copyCode()
                      : null,
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
}

class _ReferralProcess extends StatelessWidget {
  const _ReferralProcess();

  static const _steps = [
    ('Share', Icons.ios_share_rounded),
    ('Sign Up', Icons.person_add_alt_1_outlined),
    ('Verify', Icons.verified_user_outlined),
    ('Qualify', Icons.task_alt_rounded),
    ('Earn', Icons.payments_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            Expanded(
              child: _ProcessStep(
                label: _steps[i].$1,
                icon: _steps[i].$2,
              ),
            ),
            if (i != _steps.length - 1)
              Icon(
                Icons.chevron_right_rounded,
                color: _subtleTextColor(context),
                size: 18,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  const _ProcessStep({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _mutedTextColor(context),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.summary});

  final ReferralSummary summary;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Responsive columns and aspect ratio to make tiles smaller on wide screens
    int crossAxisCount;
    double childAspectRatio;
    if (screenWidth >= 1000) {
      crossAxisCount = 4;
      childAspectRatio = 3.2;
    } else if (screenWidth >= 700) {
      crossAxisCount = 3;
      childAspectRatio = 2.8;
    } else if (screenWidth >= 430) {
      crossAxisCount = 2;
      childAspectRatio = 2.6;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 2.4;
    }

    return GridView.count(
    crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _MetricTile(
          label: 'Total referrals',
          value: '${summary.totalReferrals}',
          icon: Icons.groups_outlined,
        ),
        _MetricTile(
          label: 'Registered referrals',
          value: '${summary.registered}',
          icon: Icons.person_add_alt_1_outlined,
        ),
        _MetricTile(
          label: 'Verified referrals',
          value: '${summary.verified}',
          icon: Icons.verified_user_outlined,
        ),
        _MetricTile(
          label: 'Qualified referrals',
          value: '${summary.qualified}',
          icon: Icons.task_alt_rounded,
          tooltip:
              'A qualified referral is someone you invited who completed the actions required for a referral reward.',
        ),
        _MetricTile(
          label: 'Pending rewards',
          value: _money(summary.pendingRewards),
          icon: Icons.schedule_rounded,
          description: 'Not yet available',
        ),
        _MetricTile(
          label: 'Available rewards',
          value: _money(summary.availableRewards),
          icon: Icons.account_balance_wallet_outlined,
          description: 'Ready to claim',
        ),
        _MetricTile(
          label: 'Total earned',
          value: _money(summary.totalEarned),
          icon: Icons.trending_up_rounded,
          description: 'Lifetime rewards',
        ),
        _MetricTile(
          label: 'Total paid',
          value: _money(summary.totalPaid),
          icon: Icons.payments_outlined,
          description: 'Already paid',
        ),
      ],
    );
  }

  String _money(int amount) =>
      '${NumberFormat.decimalPattern().format(amount)} ${summary.currency}';
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.description,
    this.tooltip,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? description;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tooltip = this.tooltip;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              if (tooltip != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: tooltip,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: _subtleTextColor(context),
                    size: 17,
                  ),
                ),
              ],
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: _mutedTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(
              description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: _subtleTextColor(context),
              ),
            ),
          ],
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
    if (value == 'approved') return 'Available';
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

Color _mutedTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.text2Dark
      : AppColors.text2Light;
}

Color _subtleTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.text3Dark
      : AppColors.text3Light;
}
