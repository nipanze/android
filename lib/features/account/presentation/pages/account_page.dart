// lib/features/account/presentation/pages/account_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/language_selector_sheet.dart';
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
        child: MultiBlocListener(
          listeners: [
            BlocListener<ProfileCubit, ProfileCubitState>(
              listener: (context, state) {
                if (state is ProfileCubitLoaded && state.justSaved) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.profileUpdated)));
                }
                if (state is ProfileCubitError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.danger));
                }
              },
            ),
            BlocListener<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (authState is AuthAuthenticated) {
                  context.read<ProfileCubit>().refresh();
                }
              },
            ),
          ],
          child: BlocBuilder<ProfileCubit, ProfileCubitState>(
            builder: (context, state) {
              if (state is ProfileCubitLoading ||
                  state is ProfileCubitInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              final profile =
                  state is ProfileCubitLoaded ? state.profile : null;
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
                        Text(AppLocalizations.of(context)!.accountTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontFamily: AppFonts.heading,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20)),
                        const Spacer(),
                        IconButton(
                          tooltip: AppLocalizations.of(context)!.settingsTitle,
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
                            label: AppLocalizations.of(context)!.statListings,
                            subtitle: AppLocalizations.of(context)!
                                .statListingsSubtitle,
                            value: '${profile?.activeListings ?? 0}',
                            color: AppColors.accent,
                            icon: Icons.article_outlined,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: AppLocalizations.of(context)!.statOffers,
                            subtitle: AppLocalizations.of(context)!
                                .statOffersSubtitle,
                            value: '${profile?.activeOffers ?? 0}',
                            color: AppColors.success,
                            icon: Icons.handshake_outlined,
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: AppLocalizations.of(context)!.statMatches,
                            subtitle: AppLocalizations.of(context)!
                                .statMatchesSubtitle,
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
                          AppLocalizations.of(context)!.trustReputation,
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
                      SectionHeader(
                          AppLocalizations.of(context)?.subscription ??
                              'Subscription'),
                      _SubscriptionCard(profile: profile),
                      const SizedBox(height: 8),
                      if (authState is AuthAuthenticated &&
                          authState.user.subscriptionPlan !=
                              SubscriptionPlan.pro)
                        _UpgradeButton(
                          onTap: () => context.push(AppRoutes.pricing),
                          label: authState.user.subscriptionPlan ==
                                  SubscriptionPlan.lender
                              ? (AppLocalizations.of(context)?.upgradeToPro ??
                                  'Upgrade to Pro')
                              : (AppLocalizations.of(context)
                                      ?.viewPlansUpgrade ??
                                  'View plans'),
                        ),

                      const SectionHeader('Refer & Earn'),
                      Card(
                        child: _ActionRow(
                          icon: Icons.campaign_outlined,
                          label: 'Invite people and track rewards',
                          onTap: () => context.push(AppRoutes.referrals),
                        ),
                      ),

                      SectionHeader(AppLocalizations.of(context)?.privacyAndVisibility ??
                          'Privacy & Visibility'),
                      Card(
                        child: _ActionRow(
                          icon: Icons.visibility_off_outlined,
                          label: AppLocalizations.of(context)?.blockedUsers ??
                              'Blocked Users',
                          onTap: () => context.push(AppRoutes.blockedUsers),
                        ),
                      ),

                      if (context.read<AuthBloc>().state is AuthAuthenticated &&
                          (context.read<AuthBloc>().state as AuthAuthenticated)
                              .user
                              .isAdmin) ...[
                        const SectionHeader('Admin'),
                        Card(
                            child: _ActionRow(
                          icon: Icons.admin_panel_settings_outlined,
                          label: AppLocalizations.of(context)?.adminDashboard ??
                              'Admin Dashboard',
                          onTap: () => context.push(AppRoutes.admin),
                        )),
                      ],
                      const SizedBox(height: 20),

                      Text(
                        AppLocalizations.of(context)?.nipanzeDisclaimer ??
                            'Nipanze connects borrowers and lenders. Loans are private agreements between users.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
      ),
    );
  }

  void _showTrustExplainer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.howTrustWorks,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(l10n.trustExplanation),
            ]),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userPhone = authState is AuthAuthenticated ? authState.user.phone : null;
    final userCountryCode = authState is AuthAuthenticated ? authState.user.country : null;
    final userCountry = userPhone != null && userPhone.isNotEmpty
        ? EastAfricaCountries.findByPhone(userPhone)
        : EastAfricaCountries.findByCode(userCountryCode);

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  AppLocalizations.of(sheetCtx)!.settingsTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              _ThemeToggleRow(),
              const Divider(height: 1),
              // Language row – switch app language dynamically
              ValueListenableBuilder<Locale?>(
                valueListenable: LanguageService.instance.notifier,
                builder: (ctx, _, __) {
                  final lang = LanguageService.instance.currentLanguage;
                  return _ActionRow(
                    icon: Icons.language_rounded,
                    label: AppLocalizations.of(sheetCtx)!.selectLanguage,
                    trailing: _SettingsBadge('${lang.flag} ${lang.nativeName}'),
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      showLanguageSelectorSheet(context);
                    },
                  );
                },
              ),
              const Divider(height: 1),
              // Subscription Currency row – locked to registered phone country code
              _ActionRow(
                icon: Icons.monetization_on_outlined,
                label: 'Subscription Currency',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SettingsBadge('${userCountry.flag} ${userCountry.currency}'),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AppColors.text3Dark,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showCurrencyLockedInfoDialog(context, userCountry);
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: AppLocalizations.of(sheetCtx)!.contactUs,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showContactDialog(context);
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.groups_outlined,
                label: AppLocalizations.of(sheetCtx)!.community,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showCommunityDialog(context);
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.gavel_outlined,
                label: AppLocalizations.of(sheetCtx)!.legal,
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
                  label: Text(AppLocalizations.of(sheetCtx)!.signOut),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyLockedInfoDialog(BuildContext context, CountryInfo country) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text('Subscription Currency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your subscription currency is set to ${country.currency} (${country.name}) based on your registered phone number region (${country.dialCode}).',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Subscription currency is locked to your phone number region for payment compatibility and cannot be changed manually.',
              style: TextStyle(fontSize: 12, color: AppColors.text2Dark, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.accent),
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
            Text(
                'Join the conversation, ask questions, and share feedback with other users:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.accent),
                SizedBox(width: 8),
                Text('Telegram Community',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.forum_outlined, color: AppColors.purple),
                SizedBox(width: 8),
                Text('Discord Server',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  AppLocalizations.of(sheetCtx)!.accountTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.person_outline_rounded,
                label: AppLocalizations.of(sheetCtx)!.editProfile,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  final currentLocation =
                      GoRouterState.of(context).matchedLocation;
                  if (currentLocation != AppRoutes.profile) {
                    router.push(AppRoutes.profile);
                  }
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.verified_user_outlined,
                label: AppLocalizations.of(sheetCtx)!.identityVerification,
                trailing: _kycBadge(profile?.kycStatus),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  router.push(AppRoutes.kyc);
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.lock_outline_rounded,
                label: AppLocalizations.of(sheetCtx)!.security,
                onTap: () => Navigator.of(sheetCtx).pop(),
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.notifications_none_rounded,
                label: AppLocalizations.of(sheetCtx)!.notifications,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  router.push(AppRoutes.notifications);
                },
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.settings_outlined,
                label: AppLocalizations.of(sheetCtx)!.settingsTitle,
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
        title: Text(AppLocalizations.of(context)!.signOut),
        content: Text(AppLocalizations.of(context)!.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
              context.go(AppRoutes.login);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(AppLocalizations.of(context)!.signOut),
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
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      image: profile?.avatarUrl?.isNotEmpty == true
                          ? DecorationImage(
                              image: NetworkImage(profile!.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: profile?.avatarUrl?.isNotEmpty == true
                        ? null
                        : Center(
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
                              fontSize: 16, fontWeight: FontWeight.w700),
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
                          profile?.district ??
                              AppLocalizations.of(context)!.districtNotSet,
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
                          AppLocalizations.of(context)!.memberSince(
                              DateFormat('MMM yyyy')
                                  .format(profile!.memberSince!)),
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
        child: Text(AppLocalizations.of(context)!.verified,
            style: const TextStyle(
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
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
    final l10n = AppLocalizations.of(context)!;
    final hasScore = profile.trustReliabilityScore != null;
    final scorePct =
        hasScore ? (profile.trustReliabilityScore!.clamp(0, 100)) / 100 : 0.0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                    Text(l10n.trustScore,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.text2Dark),
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
                    Text(
                      l10n.completeDealsToBuild,
                      style: const TextStyle(
                          fontSize: 8, color: AppColors.text3Dark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
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
                        ? l10n.noReviewsYet
                        : '${profile.trustRatingAvg!.toStringAsFixed(1)} (${profile.trustReviewCount})',
                  ),
                  _TrustBadgeItem(
                    icon: Icons.handshake_outlined,
                    color: AppColors.success,
                    label:
                        l10n.successfulDeals(profile.trustCompletedDealsCount),
                  ),
                  _TrustBadgeItem(
                    icon: Icons.repeat_rounded,
                    color: AppColors.accent,
                    label: profile.trustIsRepeatParticipant
                        ? l10n.repeatParticipant
                        : l10n.notRepeatYet,
                  ),
                  _TrustBadgeItem(
                    icon: Icons.phone_iphone_rounded,
                    color: AppColors.success,
                    label: profile.trustPhoneVerified
                        ? l10n.phoneVerified
                        : l10n.phoneNotVerified,
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.accent.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.shield_outlined,
                size: 18, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
                child: Text(l10n.publicTrustSignals,
                    style: const TextStyle(fontSize: 10, height: 1.3))),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.text3Dark),
          ]),
        ),
      ),
    );
  }
}

// ── Subscription Card ─────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final authPlan = authState is AuthAuthenticated
        ? authState.user.subscriptionPlan.name.toLowerCase()
        : null;
    final plan = authPlan ?? profile?.subscriptionPlan ?? 'free';
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                l10n?.planTitle(_planLabel(plan)) ?? '${_planLabel(plan)} Plan',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(l10n?.nonCustodialAccess ?? 'Non-custodial access',
                style: const TextStyle(fontSize: 11)),
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
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
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

/// Small pill badge used to show the active language / currency in the
/// Settings sheet Language row.
class _SettingsBadge extends StatelessWidget {
  const _SettingsBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.accent.withValues(alpha: 0.15)
            : AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.accent : AppColors.accent,
        ),
      ),
    );
  }
}
