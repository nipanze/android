// lib/features/marketplace/presentation/pages/contact_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../account/data/profile_repository.dart';
import '../../../account/domain/models/user_profile.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/agreement_repository.dart';
import '../../domain/models/agreement.dart';

class ContactDetailsPage extends StatefulWidget {
  const ContactDetailsPage({super.key, required this.agreementId});

  final String agreementId;

  @override
  State<ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  late final AgreementRepository _agreementRepo;
  late final ProfileRepository _profileRepo;

  Agreement? _agreement;
  ContactRevealData? _contactData;
  UserProfile? _profile;
  bool _loading = true;
  String? _error;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _agreementRepo = getIt<AgreementRepository>();
    _profileRepo = getIt<ProfileRepository>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Agreement? agreement;
      try {
        agreement = await _agreementRepo.getAgreement(widget.agreementId);
      } catch (_) {
        agreement =
            await _agreementRepo.getAgreementByOfferId(widget.agreementId);
        agreement ??=
            await _agreementRepo.getAgreementByRequestId(widget.agreementId);
      }

      if (agreement == null) {
        throw const FormatException('Agreement not found');
      }

      UserProfile? profile;
      try {
        profile = await _profileRepo.getProfile();
      } catch (_) {}

      ContactRevealData? contactData;
      if (agreement.isFullyLocked) {
        try {
          contactData = await _agreementRepo.unlockContact(agreement.id);
        } catch (_) {
          // Contact not unlocked yet
        }
      }

      if (!mounted) return;
      setState(() {
        _agreement = agreement;
        _profile = profile;
        _contactData = contactData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFacingErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _unlockContactFlow() async {
    final authState = context.read<AuthBloc>().state;
    final plan = authState is AuthAuthenticated
        ? authState.user.subscriptionPlan
        : SubscriptionPlan.free;
    final isPaid = plan == SubscriptionPlan.lender || plan == SubscriptionPlan.pro;
    final freeLeft = _profile?.freeUnlocksRemaining ?? 0;
    final hasWelcomeCredit = freeLeft > 0;

    String title;
    String body;
    String confirmLabel;

    if (isPaid) {
      title = 'Unlock Contact Details';
      body =
          'As a ${plan == SubscriptionPlan.pro ? 'Pro' : 'Lender'} subscriber, this unlock is included in your plan at no extra cost.\n\nOpposite party contact details will be revealed immediately.';
      confirmLabel = 'Unlock Now';
    } else if (hasWelcomeCredit) {
      title = '$freeLeft Free Unlock${freeLeft == 1 ? '' : 's'} Remaining';
      body =
          'You have $freeLeft free unlock${freeLeft == 1 ? '' : 's'} remaining as a welcome gift.\n\nContact details for the opposite party will be revealed. Subsequent unlocks cost UGX 5,000 each.';
      confirmLabel = 'Use Free Unlock';
    } else {
      await _showPaymentGate();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _unlocking = true);
    try {
      if (!isPaid && hasWelcomeCredit) {
        try {
          final newRemaining = await _profileRepo.consumeFreeUnlock();
          if (mounted && _profile != null) {
            setState(() {
              _profile = _profile!.copyWith(freeUnlocksRemaining: newRemaining);
            });
          }
        } catch (e) {
          debugPrint('[ContactDetails] consumeFreeUnlock error: $e');
        }
      }

      final targetAgreementId = _agreement?.id ?? widget.agreementId;
      final contactData =
          await _agreementRepo.unlockContact(targetAgreementId);
      if (!mounted) return;

      setState(() {
        _contactData = contactData;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact details successfully unlocked!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unlocking contact: ${userFacingErrorMessage(e)}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<void> _showPaymentGate() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlock Contact Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF00E676),
                    child: Icon(Icons.lock_open_rounded, color: Colors.black),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('One-time unlock fee',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('UGX 5,000',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00E676))),
                        Text('Reveals contact info for this deal only.',
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchCall(String phone, AppLocalizations l10n) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _copyToClipboard(phone, l10n.phoneCopiedToClipboard);
      }
    } catch (_) {
      _copyToClipboard(phone, l10n.phoneCopiedToClipboard);
    }
  }

  Future<void> _launchEmail(String email, AppLocalizations l10n) async {
    if (email.isEmpty) return;
    final uri = Uri.parse('mailto:$email');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _copyToClipboard(email, l10n.emailCopiedToClipboard);
      }
    } catch (_) {
      _copyToClipboard(email, l10n.emailCopiedToClipboard);
    }
  }

  Future<void> _launchWhatsApp(String phone, AppLocalizations l10n) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _copyToClipboard(phone, l10n.whatsappCopiedToClipboard);
      }
    } catch (_) {
      _copyToClipboard(phone, l10n.whatsappCopiedToClipboard);
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'OP';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF040A12) : const Color(0xFF0B1726);
    const textColor = Colors.white;
    const subtitleColor = Color(0xFF94A3B8);
    const cardBgColor = Color(0xFF081421);
    const accentGreen = Color(0xFF00E676);

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/positions');
              }
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: accentGreen)),
      );
    }

    if (_error != null || _agreement == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/positions');
              }
            },
          ),
        ),
        body: ErrorState(
          message: _error ?? 'Agreement details not found',
          onRetry: _loadData,
        ),
      );
    }

    final agreement = _agreement!;
    final authState = context.watch<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : '';

    // Determine whether current user is borrower or lender
    final isBorrower = currentUserId.isNotEmpty &&
        currentUserId == agreement.borrowerId;

    // Filter to ONLY show opposite party's info
    final contactData = _contactData;

    // If current logged in user is borrower, opposite party is Lender.
    // If current logged in user is lender, opposite party is Borrower.
    final isOppositePartyLender = isBorrower;
    final oppositeRoleTitle = isOppositePartyLender ? 'Lender' : 'Borrower';

    final name = contactData == null
        ? oppositeRoleTitle
        : (isOppositePartyLender ? contactData.lenderName : contactData.borrowerName);

    final phone = contactData == null
        ? ''
        : (isOppositePartyLender ? contactData.lenderPhone : contactData.borrowerPhone);

    final email = contactData == null
        ? ''
        : (isOppositePartyLender ? contactData.lenderEmail : contactData.borrowerEmail);

    final location = contactData == null
        ? 'Kampala, Uganda'
        : (isOppositePartyLender ? contactData.lenderDistrict : contactData.borrowerDistrict);

    final rating = contactData == null
        ? 4.9
        : (isOppositePartyLender ? contactData.lenderRating : contactData.borrowerRating);

    final completedDeals = contactData == null
        ? 12
        : (isOppositePartyLender ? contactData.lenderCompletedDeals : contactData.borrowerCompletedDeals);

    final initials = _getInitials(name);

    // Tag under name e.g. (Bank Agent) or (Lender) / (Borrower)
    final roleTag = (oppositeRoleTitle == 'Lender' && name.contains('Kasujja'))
        ? '(Bank Agent)'
        : '($oppositeRoleTitle)';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/positions');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 1. Top Badge: Lender or Borrower ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF031E13),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentGreen,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person,
                    color: accentGreen,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    oppositeRoleTitle,
                    style: const TextStyle(
                      color: accentGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. Large Avatar Circle ──────────────────────────────────────
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF021B10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentGreen,
                  width: 2.0,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: accentGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── 3. Name & Subtitle & Location ──────────────────────────────
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              roleTag,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  color: subtitleColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 4. Stats Row Bar (Verified | 4.9 | 12 Matches) ────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  // Col 1: Verified
                  const Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: accentGreen,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 22, color: Colors.white.withValues(alpha: 0.12)),
                  // Col 2: Rating
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_outline_rounded,
                          color: accentGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$rating',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 22, color: Colors.white.withValues(alpha: 0.12)),
                  // Col 3: Matches (e.g. 12 Matches)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.work_outline_rounded,
                          color: accentGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$completedDeals Matches',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 5. Reach out subtitle & Contact Cards ─────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isOppositePartyLender
                    ? 'Reach out to the lender directly'
                    : 'Reach out to the borrower directly',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (contactData == null) ...[
              // Locked Prompt Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded, size: 40, color: accentGreen),
                    const SizedBox(height: 12),
                    Text(
                      l10n.contactInfoLocked,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.contactInfoLockedSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, color: subtitleColor),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _unlocking ? null : _unlockContactFlow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _unlocking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.lock_open_rounded, size: 18),
                        label: Text(
                          _unlocking ? 'Unlocking...' : l10n.unlockContactDetails,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── Action 1: Phone Card ─────────────────────────────────
              _ContactActionCard(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: phone.isEmpty ? l10n.notProvided : phone,
                actionIcon: Icons.phone,
                onTap: () => _launchCall(phone, l10n),
              ),
              const SizedBox(height: 10),

              // ── Action 2: Email Card ─────────────────────────────────
              _ContactActionCard(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: email.isEmpty ? l10n.notProvided : email,
                actionIcon: Icons.mail_rounded,
                onTap: () => _launchEmail(email, l10n),
              ),
              const SizedBox(height: 10),

              // ── Action 3: Whatsapp Card ──────────────────────────────
              _ContactActionCard(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Whatsapp',
                value: phone.isEmpty ? l10n.notProvided : phone,
                actionIcon: Icons.chat_rounded,
                onTap: () => _launchWhatsApp(phone, l10n),
              ),
            ],
            const SizedBox(height: 14),

            // ── 6. Disclaimer Card ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF041822),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentGreen.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: accentGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nipanze doesn’t hold funds or mediate the deal.\nConfirm details before you send anything.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 7. Bottom Buttons ──────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: accentGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accentGreen.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (_agreement != null) {
                    context.push('/marketplace/agreement/${_agreement!.id}');
                  } else {
                    context.go('/positions');
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Preview Deal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/positions');
                }
              },
              child: const Text(
                'Back to activity',
                style: TextStyle(
                  color: accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactActionCard extends StatelessWidget {
  const _ContactActionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionIcon,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final IconData actionIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF00E676);
    const textColor = Colors.white;
    const subtitleColor = Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF081421),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Left Icon Box
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF042015),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Middle Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Right Circular Action Button
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF042015),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentGreen,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Icon(
                  actionIcon,
                  color: accentGreen,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
