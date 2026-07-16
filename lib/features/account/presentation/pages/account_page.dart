// lib/features/account/presentation/pages/account_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/trust_badges.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
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
                  backgroundColor: AppColors.danger));
            }
          },
          builder: (context, state) {
            if (state is ProfileCubitLoading || state is ProfileCubitInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = state is ProfileCubitLoaded ? state.profile : null;

            return RefreshIndicator(
              onRefresh: () => context.read<ProfileCubit>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const SizedBox(height: 8),

                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Center(
                        child: Text(
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
                  const SizedBox(height: 20),

                  // Quick stats
                  if (profile != null) ...[
                    Row(children: [
                      _StatChip(
                        label: 'Listings',
                        value: '${profile.activeListings}',
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Offers',
                        value: '${profile.activeOffers}',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Matches',
                        value: '${profile.revealedContacts}',
                        color: AppColors.purple,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    const SectionHeader('Trust & reputation'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Public trust signals',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Based only on activity completed through Nipanze.',
                              style: TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            TrustBadgeRow(
                              ratingAvg: profile.trustRatingAvg,
                              reviewCount: profile.trustReviewCount,
                              completedDealsCount:
                                  profile.trustCompletedDealsCount,
                              isRepeatParticipant:
                                  profile.trustIsRepeatParticipant,
                              phoneVerified: profile.trustPhoneVerified,
                              responseTimeBucket:
                                  profile.trustResponseTimeBucket,
                              isVerified: profile.trustIsVerified,
                              showProVerification: profile.hasActiveProPlan,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (profile.hasActiveProPlan) ...[
                      const SizedBox(height: 10),
                      AdvancedTrustPanel(
                        successRate: profile.trustSuccessRate,
                        reliabilityScore: profile.trustReliabilityScore,
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],

                  // Shortcuts
                  _ActionRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    onTap: () => context.push(AppRoutes.profile),
                  ),
                  const Divider(height: 1),
                  _ThemeToggleRow(),
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.verified_user_outlined,
                    label: 'KYC Verification',
                    trailing: _kycBadge(profile?.kycStatus),
                    onTap: () => context.push(AppRoutes.kyc),
                  ),
                  const SizedBox(height: 20),

                  // Subscription card
                  const SectionHeader('Subscription'),
                  _SubscriptionCard(profile: profile),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.pricing),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('View plans & upgrade'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Identity panel
                  const SectionHeader('Account Properties'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(children: [
                        _InfoRow('Account Status',
                            profile?.accountStatus.toUpperCase()),
                        const Divider(height: 16),
                        _InfoRow('District', profile?.district),
                        if (profile?.employmentType != null) ...[
                          const Divider(height: 16),
                          _InfoRow('Employment', profile?.employmentType),
                        ],
                      ]),
                    ),
                  ),
                  if (context.read<AuthBloc>().state is AuthAuthenticated &&
                      (context.read<AuthBloc>().state as AuthAuthenticated)
                          .user
                          .isAdmin) ...[
                    const SizedBox(height: 20),
                    _ActionRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin dashboard',
                      onTap: () => context.push(AppRoutes.admin),
                    ),
                  ],
                  const SizedBox(height: 24),

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
                        side: const BorderSide(color: AppColors.danger)),
                    child: const Text('Sign Out'),
                  ),
                  const SizedBox(height: 32),

                  // Disclaimer
                  const Text(
                    'Nipanze is a non-custodial matchmaking platform. We do not hold, move, or settle funds. All transactions occur direct between participants.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10, color: AppColors.text3Dark, height: 1.5),
                  ),
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
      'pending' => ('Pending', AppColors.warning),
      _ => ('Incomplete', AppColors.text2Dark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final plan = profile?.subscriptionPlan ?? 'free';
    final status = profile?.subscriptionStatus ?? 'active';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _planColor(plan).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _planColor(plan).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_planLabel(plan)} plan',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _planColor(plan))),
          const Text('Non-custodial access', style: TextStyle(fontSize: 11)),
        ]),
        const Spacer(),
        Text(status.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _planColor(plan))),
      ]),
    );
  }

  Color _planColor(String plan) {
    switch (plan) {
      case 'lender':
        return AppColors.accent;
      case 'pro':
        return AppColors.purple;
      default:
        return AppColors.success;
    }
  }

  String _planLabel(String plan) {
    switch (plan) {
      case 'lender':
        return 'Lender';
      case 'pro':
        return 'Pro';
      default:
        return 'Free';
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 9)),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.text2Dark),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            if (trailing != null) trailing!,
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.text3Dark),
          ]),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.text2Dark)),
        const Spacer(),
        Text(value ?? '—',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ]);
}

class _ThemeToggleRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.notifier,
      builder: (context, mode, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            const Icon(Icons.brightness_6_outlined,
                size: 20, color: AppColors.text2Dark),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('Appearance', style: TextStyle(fontSize: 13))),
            SegmentedButton<ThemeMode>(
              style: SegmentedButton.styleFrom(
                textStyle:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Auto'),
                    icon: Icon(Icons.brightness_auto_outlined, size: 14)),
                ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined, size: 14)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined, size: 14)),
              ],
              selected: {mode},
              onSelectionChanged: (s) => ThemeService.instance.setMode(s.first),
            ),
          ]),
        );
      },
    );
  }
}
