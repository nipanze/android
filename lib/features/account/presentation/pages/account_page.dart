// lib/features/account/presentation/pages/account_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(children: [
                      Text('Profile',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontFamily: AppFonts.heading,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Appearance',
                        onPressed: () => _showAppearanceSheet(context),
                        icon: const Icon(Icons.settings_outlined, size: 22),
                      ),
                    ]),
                    const SizedBox(height: 8),

                    // ── Profile card ──────────────────────────────────────
                    _ProfileHeaderCard(
                      profile: profile,
                      onTap: () => context.push(AppRoutes.profile),
                    ),
                    const SizedBox(height: 12),

                    // ── Stats row ─────────────────────────────────────────
                    Row(children: [
                      _StatChip(
                        label: 'Listings',
                        value: '${profile?.activeListings ?? 0}',
                        color: AppColors.accent,
                        icon: Icons.article_outlined,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Offers',
                        value: '${profile?.activeOffers ?? 0}',
                        color: AppColors.success,
                        icon: Icons.handshake_outlined,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Matches',
                        value: '${profile?.revealedContacts ?? 0}',
                        color: AppColors.purple,
                        icon: Icons.track_changes_outlined,
                      ),
                    ]),
                    const SizedBox(height: 6),

                    // ── Trust & Reputation ────────────────────────────────
                    SectionHeader('Trust & Reputation',
                        trailing: TextButton.icon(
                            onPressed: () => _showTrustExplainer(context),
                            icon: const Icon(Icons.info_outline, size: 14),
                            label: const Text('How it works'))),
                    if (profile != null) _TrustPanel(profile: profile),
                    const SizedBox(height: 8),
                    _PublicTrustInfoCard(
                        onTap: () => _showTrustExplainer(context)),
                    const SizedBox(height: 4),

                    // ── Subscription ──────────────────────────────────────
                    const SectionHeader('Subscription'),
                    _SubscriptionCard(profile: profile),
                    const SizedBox(height: 8),
                    _UpgradeButton(
                        onTap: () => context.push(AppRoutes.pricing)),

                    // ── Account ───────────────────────────────────────────
                    const SectionHeader('Account'),
                    Card(
                        child: Column(children: [
                      _ActionRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Edit Profile',
                          onTap: () => context.push(AppRoutes.profile)),
                      const Divider(height: 1),
                      _ActionRow(
                          icon: Icons.verified_user_outlined,
                          label: 'Identity Verification',
                          trailing: _kycBadge(profile?.kycStatus),
                          onTap: () => context.push(AppRoutes.kyc)),
                      const Divider(height: 1),
                      _ActionRow(
                          icon: Icons.lock_outline_rounded,
                          label: 'Security',
                          onTap: () {}),
                      const Divider(height: 1),
                      _ActionRow(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notifications',
                          onTap: () =>
                              context.push(AppRoutes.notifications)),
                    ])),
                    if (context.read<AuthBloc>().state is AuthAuthenticated &&
                        (context.read<AuthBloc>().state as AuthAuthenticated)
                            .user
                            .isAdmin) ...[
                      const SizedBox(height: 8),
                      _ActionRow(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Admin dashboard',
                        onTap: () => context.push(AppRoutes.admin),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Sign out ──────────────────────────────────────────
                    SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context
                                .read<AuthBloc>()
                                .add(const AuthSignOutRequested());
                            context.go(AppRoutes.login);
                          },
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side:
                                  const BorderSide(color: AppColors.danger)),
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text('Sign Out'),
                        )),
                    const SizedBox(height: 22),
                    const Text(
                      'Nipanze is a non-custodial matchmaking platform. We do not hold, move, or settle funds. All transactions occur direct between participants.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.text3Dark,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showTrustExplainer(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How trust works',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 10),
                Text(
                    'Trust signals reflect only activity completed through Nipanze. They do not assess or imply off-platform repayment behaviour.'),
              ]),
        ),
      );

  void _showAppearanceSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: _ThemeToggleRow(),
        ),
      );

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

// ── Profile Header Card ────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile, required this.onTap});
  final UserProfile? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.5)
                  : AppColors.borderLight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4757D8), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    profile?.initials ?? 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified pill
                    Row(children: [
                      Flexible(
                        child: Text(
                          profile?.displayName ?? 'User',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile?.isKycApproved == true) ...[
                        const SizedBox(width: 7),
                        _VerifiedBadge(),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    // Email
                    Text(
                      profile?.email ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.text2Dark),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Location
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.text3Dark),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          profile?.district ?? 'District not set',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.text2Dark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    // Member since
                    if (profile?.memberSince != null) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 11, color: AppColors.text3Dark),
                        const SizedBox(width: 4),
                        Text(
                          'Member since ${DateFormat('MMM yyyy').format(profile!.memberSince!)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.text2Dark),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.text3Dark),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Verified',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.success)),
      );
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.text2Dark)),
          ]),
        ),
      );
}

// ── Trust Panel ───────────────────────────────────────────────────────────────

class _TrustPanel extends StatelessWidget {
  const _TrustPanel({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final hasScore = profile.trustReliabilityScore != null;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Left — score block
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 22, color: AppColors.accent),
                const SizedBox(height: 4),
                const Text('Trust score',
                    style: TextStyle(fontSize: 9, color: AppColors.text2Dark),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  hasScore
                      ? '${profile.trustReliabilityScore}'
                      : 'New',
                  style: TextStyle(
                      fontSize: hasScore ? 22 : 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppFonts.heading),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete deals to build your score',
                  style: TextStyle(fontSize: 8, color: AppColors.text3Dark),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Right — badge list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrustBadgeItem(
                  icon: Icons.star_rounded,
                  color: AppColors.warning,
                  label: profile.trustRatingAvg == null
                      ? 'No reviews yet'
                      : '${profile.trustRatingAvg!.toStringAsFixed(1)} (${profile.trustReviewCount})',
                ),
                const SizedBox(height: 6),
                _TrustBadgeItem(
                  icon: Icons.handshake_outlined,
                  color: AppColors.success,
                  label:
                      '${profile.trustCompletedDealsCount} successful deals',
                ),
                const SizedBox(height: 6),
                _TrustBadgeItem(
                  icon: Icons.repeat_rounded,
                  color: AppColors.success,
                  label: profile.trustIsRepeatParticipant
                      ? 'Repeat participant'
                      : 'Not a repeat yet',
                  muted: !profile.trustIsRepeatParticipant,
                ),
                const SizedBox(height: 6),
                _TrustBadgeItem(
                  icon: Icons.phone_iphone_rounded,
                  color: AppColors.success,
                  label: profile.trustPhoneVerified
                      ? 'Phone verified'
                      : 'Phone not verified',
                  muted: !profile.trustPhoneVerified,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _TrustBadgeItem extends StatelessWidget {
  const _TrustBadgeItem({
    required this.icon,
    required this.color,
    required this.label,
    this.muted = false,
  });
  final IconData icon;
  final Color color;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: muted ? AppColors.text3Dark : color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: muted ? AppColors.text3Dark : null),
            ),
          ),
        ],
      );
}

// ── Public Trust Info Card ────────────────────────────────────────────────────

class _PublicTrustInfoCard extends StatelessWidget {
  const _PublicTrustInfoCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.accent),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Public trust signals are based only on activity completed through Nipanze.',
                      style: TextStyle(fontSize: 10, height: 1.3))),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.text3Dark),
            ]),
          ),
        ),
      );
}

// ── Subscription Card ─────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final plan = profile?.subscriptionPlan ?? 'free';
    final status = profile?.subscriptionStatus ?? 'active';
    final color = _planColor(plan);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24), width: 1.2),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.workspace_premium_outlined, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_planLabel(plan)} plan',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 2),
                const Text('Non-custodial access',
                    style: TextStyle(fontSize: 11)),
              ]),
        ),
        _StatusPill(label: status.toUpperCase(), color: color),
      ]),
    );
  }

  Color _planColor(String plan) => switch (plan) {
        'lender' => AppColors.accent,
        'pro' => AppColors.purple,
        _ => AppColors.success,
      };

  String _planLabel(String plan) => switch (plan) {
        'lender' => 'Lender',
        'pro' => 'Pro',
        _ => 'Free',
      };
}

// ── Upgrade Button ────────────────────────────────────────────────────────────

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.workspace_premium_outlined, size: 16),
          label: const Text('View plans & upgrade'),
          style:
              OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
        ),
      );
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.text2Dark),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13))),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.text3Dark),
          ]),
        ),
      );
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
                textStyle: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w500),
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
              onSelectionChanged: (s) =>
                  ThemeService.instance.setMode(s.first),
            ),
          ]),
        );
      },
    );
  }
}
