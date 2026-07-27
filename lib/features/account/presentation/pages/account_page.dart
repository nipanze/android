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
import '../../../auth/domain/models/nipanze_user.dart';
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
             final authState = context.read<AuthBloc>().state;

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
                      Text('Account',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontFamily: AppFonts.heading,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () => _showSettingsSheet(context),
                        icon: const Icon(Icons.settings_outlined, size: 22),
                      ),
                    ]),
                    const SizedBox(height: 8),

                    // ── Profile card ──────────────────────────────────────
                    _ProfileHeaderCard(
                      profile: profile,
                      onTap: () => _showAccountSheet(context, profile),
                    ),
                    const SizedBox(height: 12),

                    // ── Stats row ─────────────────────────────────────────
                    // Fix: `CrossAxisAlignment.stretch` was here to make the
                    // three chips equal height, but this Row lives inside a
                    // Column inside a SingleChildScrollView — an unbounded
                    // height context. `stretch` demands children fill the
                    // Row's own height, which becomes "stretch to infinity"
                    // in an unbounded parent and crashes layout. Removed:
                    // Row already sizes to its tallest child by default,
                    // which is sufficient since all three _StatChips share
                    // identical internal structure.
                    Row(
                      children: [
                        _StatChip(
                          label: 'Listings',
                          subtitle: 'Posted requests',
                          value: '${profile?.activeListings ?? 0}',
                          color: AppColors.accent,
                          icon: Icons.article_outlined,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Offers',
                          subtitle: 'Offers made',
                          value: '${profile?.activeOffers ?? 0}',
                          color: AppColors.success,
                          icon: Icons.handshake_outlined,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Matches',
                          subtitle: 'Successful matches',
                          value: '${profile?.revealedContacts ?? 0}',
                          color: AppColors.purple,
                          icon: Icons.track_changes_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ── Trust & Reputation ────────────────────────────────
                    // Fix: SectionHeader renders uppercase/10px, styled
                    // deliberately that way for Subscription/Account below.
                    // The mockup wants this specific header larger and in
                    // mixed case (more like a subheading than a label), so
                    // it's built as a one-off Row here instead of reusing
                    // SectionHeader, keeping the other sections untouched.
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        'Trust & Reputation',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (profile != null) _TrustPanel(profile: profile),
                    const SizedBox(height: 8),
                    _PublicTrustInfoCard(
                        onTap: () => _showTrustExplainer(context)),
                    const SizedBox(height: 4),

                    // ── Subscription ──────────────────────────────────────
                    const SectionHeader('Subscription'),
                    _SubscriptionCard(profile: profile),
                    const SizedBox(height: 8),
                    if (authState is AuthAuthenticated &&
                        authState.user.subscriptionPlan != SubscriptionPlan.pro)
                      _UpgradeButton(
                        onTap: () => context.push(AppRoutes.pricing),
                        label: authState.user.subscriptionPlan ==
                                SubscriptionPlan.lender
                            ? 'Upgrade to Pro'
                            : 'View plans & upgrade',
                      ),

                    if (context.read<AuthBloc>().state is AuthAuthenticated &&
                        (context.read<AuthBloc>().state as AuthAuthenticated)
                            .user
                            .isAdmin) ...[
                      const SectionHeader('Admin'),
                      Card(
                          child: _ActionRow(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Admin dashboard',
                        onTap: () => context.push(AppRoutes.admin),
                      )),
                    ],
                    const SizedBox(height: 20),

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

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Settings',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              _ThemeToggleRow(),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Contact Us',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showContactDialog(context);
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.groups_outlined,
                label: 'Community',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showCommunityDialog(context);
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.gavel_outlined,
                label: 'Legal',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showLegalDialog(context);
                },
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    _showSignOutConfirmation(context);
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger)),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Us'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Have questions or need support? Reach out to us via email:'),
            SizedBox(height: 12),
            Text(
              'support@nipanze.com',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
            SizedBox(height: 8),
            Text('We typically respond within 24 hours.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCommunityDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Community'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join the conversation, ask questions, and share feedback with other users:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accent),
                SizedBox(width: 8),
                Text('Telegram Community', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.forum_outlined, color: AppColors.purple),
                SizedBox(width: 8),
                Text('Discord Server', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Legal'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'By using Nipanze, you agree that Nipanze is a non-custodial matchmaking platform. We do not hold, move, or settle funds. All transactions occur directly between participants at their own risk.',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 12),
              Text(
                'Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'We respect your privacy and data ownership. We encrypt all private user identifiers and will never sell your personal data without your consent.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAccountSheet(BuildContext context, UserProfile? profile) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        // Capture router before the sheet opens so we can navigate after pop.
        final router = GoRouter.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Account',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  final currentLocation = GoRouterState.of(context).matchedLocation;
                  if (currentLocation != AppRoutes.profile) {
                    router.push(AppRoutes.profile);
                  }
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.verified_user_outlined,
                label: 'Identity Verification',
                trailing: _kycBadge(profile?.kycStatus),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  router.push(AppRoutes.kyc);
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.lock_outline_rounded,
                label: 'Security',
                onTap: () => Navigator.of(sheetCtx).pop(),
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  router.push(AppRoutes.notifications);
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showSettingsSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
              context.go(AppRoutes.login);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
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

// ── Profile Header Card ────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile, required this.onTap});
  final UserProfile? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVerified = profile?.isKycApproved == true;
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
              // Fix: wrapped in a Stack with a small checkmark badge
              // overlaid on the bottom-right corner, matching the "Verified"
              // pill next to the name — a redundant-but-familiar pattern
              // (avatar badge + text pill) seen across account/profile UIs.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
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
                  if (isVerified)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? AppColors.bg2Dark : AppColors.bg2Light,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
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
                      if (isVerified) ...[
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
// Fix: previously centered icon → value → label vertically stacked, with no
// subtitle. Rewritten to left-align an icon+value row up top, then a bold
// label, then a muted subtitle line below — matching the target mockup's
// "Listings / Posted requests" layout.

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String subtitle;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.5)
                : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 1),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.text2Dark)),
          ],
        ),
      ),
    );
  }
}

// ── Trust Panel ───────────────────────────────────────────────────────────────

class _TrustPanel extends StatelessWidget {
  const _TrustPanel({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasScore = profile.trustReliabilityScore != null;
    // Fix: reliability score is 0-100 already (per ProfileRepository mapping
    // from proTrust['reliability_score']), so no extra scaling is needed.
    final scorePct =
        hasScore ? (profile.trustReliabilityScore!.clamp(0, 100)) / 100 : 0.0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        // Fix: badge rows were bunched at the top with fixed 6px gaps,
        // leaving dead space below since the Column only took its natural
        // (min) height while the left score box was taller. IntrinsicHeight
        // gives this Row a shared finite height (safe here, unlike the
        // earlier stats-Row crash, because Card sizes to its child rather
        // than passing down an unbounded height) — CrossAxisAlignment.stretch
        // then makes the badge Column match the score box's height, and
        // mainAxisAlignment.spaceBetween distributes the four rows evenly
        // across it instead of clumping them at the top.
        child: IntrinsicHeight(
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Left — score block
            // Fix: was a fixed `width: 100`, which read as a narrow sliver
            // next to the badge list. Switched to Expanded(flex: 5) against
            // the badge column's Expanded(flex: 6) below so the two columns
            // split the available width almost evenly (with the badges
            // getting a slight edge, matching the mockup's proportions)
            // instead of the score block being squeezed down to a minimum.
            Expanded(
              flex: 5,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                        style:
                            TextStyle(fontSize: 9, color: AppColors.text2Dark),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(
                      hasScore ? '${profile.trustReliabilityScore}' : 'New',
                      style: TextStyle(
                          fontSize: hasScore ? 22 : 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFonts.heading),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Complete deals to build your score',
                      style:
                          TextStyle(fontSize: 8, color: AppColors.text3Dark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Progress bar toward a scored state, with % readout.
                    // Fix: previously used Theme.of(context).dividerColor as
                    // the track background, which renders far too bright
                    // against this dark card and reads as a solid white bar
                    // instead of a subtle track. Switched to the theme's own
                    // muted surface token (bg3Dark/bg3Light) to match. Also
                    // moved the "0%" label onto the same row as the bar (was
                    // a separate stacked line below), and added a small
                    // leading dot to mark the current progress position,
                    // matching the target design's slider-style indicator.
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: scorePct,
                                    backgroundColor: isDark
                                        ? AppColors.bg3Dark
                                        : AppColors.bg3Light,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.accent),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment(
                                    -1 + 2 * scorePct.clamp(0.0, 1.0), 0),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(scorePct * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text2Dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Right — badge list
            // Fix: badges were being greyed out (icon + text muted) whenever
            // the underlying status was "not yet achieved" (0 deals, not a
            // repeat participant), which doesn't match the target design —
            // there, every badge keeps full-brightness text and a fully
            // saturated icon color regardless of whether the state is
            // positive or still-pending; only the label copy communicates
            // the state. Dropped `muted` entirely so all four rows render
            // consistently. Also swapped the "repeat participant" icon color
            // from success (green, same as the deals-count badge right above
            // it) to accent (blue), matching the mockup's distinct color per
            // badge instead of reusing green twice in a row.
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TrustBadgeItem(
                    icon: Icons.star_rounded,
                    color: AppColors.warning,
                    label: profile.trustRatingAvg == null
                        ? 'No reviews yet'
                        : '${profile.trustRatingAvg!.toStringAsFixed(1)} (${profile.trustReviewCount})',
                  ),
                  _TrustBadgeItem(
                    icon: Icons.handshake_outlined,
                    color: AppColors.success,
                    label:
                        '${profile.trustCompletedDealsCount} successful deals',
                  ),
                  _TrustBadgeItem(
                    icon: Icons.repeat_rounded,
                    color: AppColors.accent,
                    label: profile.trustIsRepeatParticipant
                        ? 'Repeat participant'
                        : 'Not a repeat yet',
                  ),
                  _TrustBadgeItem(
                    icon: Icons.phone_iphone_rounded,
                    color: AppColors.success,
                    label: profile.trustPhoneVerified
                        ? 'Phone verified'
                        : 'Phone not verified',
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TrustBadgeItem extends StatelessWidget {
  const _TrustBadgeItem({
    required this.icon,
    required this.color,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
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
  const _UpgradeButton({
    required this.onTap,
    required this.label,
  });
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.workspace_premium_outlined, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
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