// lib/features/account/presentation/pages/account_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nipanze/core/constants/app_constants.dart';
import 'package:nipanze/features/auth/domain/models/nipanze_user.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import '../../domain/models/user_profile.dart';
import '../cubit/profile_cubit.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..load(),
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ProfileCubit, ProfileCubitState>(
          listener: (context, state) {
            if (state is ProfileCubitLoaded && state.justSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated.')));
            }
            if (state is ProfileCubitError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ));
            }
          },
          builder: (context, state) {
            if (state is ProfileCubitLoading || state is ProfileCubitInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            // profile is UserProfile? — may be null if state is ProfileCubitError
            final profile =
                state is ProfileCubitLoaded ? state.profile : null;

            return RefreshIndicator(
              onRefresh: () => context.read<ProfileCubit>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const SizedBox(height: 8),

                  // Avatar
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Center(child: Text(
                      profile?.initials ?? 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    )),
                  ),
                  const SizedBox(height: 10),
                  Text(profile?.displayName ?? 'User',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(profile?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  if (profile != null)
                    RepTierBadge(_tierFromString(profile.reputationTier)),
                  const SizedBox(height: 20),

                  // Quick stats
                  if (profile != null) ...[
                    Row(children: [
                      _StatChip(
                        label: 'Active listings',
                        value: '${profile.activeListings}',
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Active bids',
                        value: '${profile.activeBids}',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Contracts',
                        value: '${profile.contractedAsBorrower + profile.contractedAsLender}',
                        color: AppColors.purple,
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // Notifications shortcut
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, notifState) {
                      final unread = notifState is NotificationLoaded
                          ? notifState.unreadCount
                          : 0;
                      return _ActionRow(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        trailing: unread > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$unread',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              )
                            : null,
                        onTap: () => context.push(AppRoutes.notifications),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit profile',
                    onTap: () => context.push(AppRoutes.profile),
                  ),
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Identity verification (KYC)',
                    trailing: _kycBadge(profile?.kycStatus),
                    onTap: () => context.push(AppRoutes.kyc),
                  ),
                  const SizedBox(height: 20),

                  // Subscription card
                  const SectionHeader('Subscription'),
                  _SubscriptionCard(profile: profile),
                  const SizedBox(height: 20),

                  // Identity panel
                  const SectionHeader('Identity'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(children: [
                        // lenderToken and district are String? on UserProfile.
                        // _InfoRow accepts String? and renders '—' when null.
                        _InfoRow(
                          'Lender token',
                          profile?.lenderToken,
                          mono: true,
                        ),
                        const Divider(height: 16),
                        _InfoRow('Reputation score',
                            '${profile?.creditScore ?? 50}/100'),
                        const Divider(height: 16),
                        _InfoRow('Account status',
                            profile?.accountStatus),
                        if (profile?.district != null) ...[
                          const Divider(height: 16),
                          // Fix: _InfoRow takes String? — no ! needed
                          _InfoRow('District', profile?.district),
                        ],
                        if (profile?.employmentType != null) ...[
                          const Divider(height: 16),
                          // Fix: use ?. and fallback instead of !
                          _InfoRow('Employment',
                              _fmtEmployment(profile?.employmentType ?? '')),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign out
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<AuthBloc>()
                          .add(const AuthSignOutRequested());
                      context.go(AppRoutes.login);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Sign out'),
                  ),
                  const SizedBox(height: 20),

                  // Disclaimer
                  Text(
                    AppStrings.nonCustodialDisclaimer ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.7),
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget? _kycBadge(String? status) {
    if (status == null) return null;
    final (label, color) = switch (status) {
      'approved' => ('Verified', AppColors.success),
      'pending'  => ('Pending',  AppColors.warning),
      'rejected' => ('Rejected', AppColors.danger),
      'expired'  => ('Expired',  AppColors.warning),
      _          => ('Not submitted', AppColors.text2Dark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _fmtEmployment(String s) {
    switch (s) {
      case 'employed':       return 'Employed';
      case 'self_employed':  return 'Self-employed';
      case 'business_owner': return 'Business owner';
      case 'student':        return 'Student';
      default:               return 'Other';
    }
  }
}

// ─── Subscription Card ────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.profile});
  final UserProfile? profile;

  static const _plans = [
    ('watchlist', 'Free',    'Watch listings',     AppColors.text2Dark),
    ('borrower',  '20K/mo',  'Post & accept bids', AppColors.success),
    ('lender',    '35K/mo',  'Bid on listings',    AppColors.accent),
    ('pro',       '150K/mo', 'All features + API', AppColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    final plan   = profile?.subscriptionPlan ?? 'watchlist';
    final status = profile?.subscriptionStatus ?? 'active';
    final expiry = profile?.subscriptionExpiresAt;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Current plan card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _planColor(plan).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _planColor(plan).withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${_planLabel(plan)} plan',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _planColor(plan)),
            ),
            if (expiry != null)
              Text(
                'Renews ${expiry.day}/${expiry.month}/${expiry.year}',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Text('Free forever',
                  style: Theme.of(context).textTheme.bodySmall),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status == 'active' ? 'Active' : status,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),

      // Plan selector row
      Row(children: _plans.map((p) {
        final isSelected = plan == p.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (!isSelected) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Upgrade handled off-platform. Contact support@nipanze.ug'),
                ));
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? p.$4.withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? p.$4.withValues(alpha: 0.4)
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(children: [
                Text(p.$2,
                    style: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? p.$4 : null)),
                const SizedBox(height: 2),
                Text(_planLabel(p.$1),
                    style: const TextStyle(fontSize: 9)),
              ]),
            ),
          ),
        );
      }).toList()),
    ]);
  }

  Color _planColor(String plan) {
    switch (plan) {
      case 'borrower': return AppColors.success;
      case 'lender':   return AppColors.accent;
      case 'pro':      return AppColors.purple;
      default:         return AppColors.text2Dark;
    }
  }

  String _planLabel(String plan) {
    switch (plan) {
      case 'borrower': return 'Borrower';
      case 'lender':   return 'Lender';
      case 'pro':      return 'Pro';
      default:         return 'Watchlist';
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.color});
  final String label;
  final String? value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Text(value ?? '—',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'DM Mono')),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.trailing});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(children: [
            Icon(icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 13))),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            Icon(Icons.chevron_right_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ]),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.mono = false});
  final String label;
  final String? value;  // nullable — renders '—' when null
  final bool mono;

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value ?? '—',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'DM Mono' : null)),
      ]);
}

RepTier _tierFromString(String s) {
  switch (s) {
    case 'platinum':   return RepTier.platinum;
    case 'gold':       return RepTier.gold;
    case 'silver':     return RepTier.silver;
    case 'restricted': return RepTier.restricted;
    default:           return RepTier.bronze;
  }
}
