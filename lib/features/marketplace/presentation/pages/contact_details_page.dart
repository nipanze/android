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

      final contactData = await _agreementRepo.unlockContact(widget.agreementId);
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
          content: Text('Error unlocking contact: $e'),
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

    final bgColor = isDark ? const Color(0xFF040A12) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final mutedColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text(l10n.contactDetailsTitle, style: TextStyle(fontFamily: 'Sora', color: textColor)),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      );
    }

    if (_error != null || _agreement == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text(l10n.contactDetailsTitle, style: TextStyle(fontFamily: 'Sora', color: textColor)),
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
    final name = contactData == null
        ? (isBorrower ? l10n.lender : l10n.borrower)
        : (isBorrower ? contactData.lenderName : contactData.borrowerName);

    final phone = contactData == null
        ? ''
        : (isBorrower ? contactData.lenderPhone : contactData.borrowerPhone);

    final email = contactData == null
        ? ''
        : (isBorrower ? contactData.lenderEmail : contactData.borrowerEmail);

    final location = contactData == null
        ? 'Uganda'
        : (isBorrower ? contactData.lenderDistrict : contactData.borrowerDistrict);

    final rating = contactData == null
        ? 4.9
        : (isBorrower ? contactData.lenderRating : contactData.borrowerRating);

    final reviewCount = contactData == null
        ? 27
        : (isBorrower ? contactData.lenderReviewCount : contactData.borrowerReviewCount);

    final completedDeals = contactData == null
        ? 12
        : (isBorrower ? contactData.lenderCompletedDeals : contactData.borrowerCompletedDeals);

    final isVerified = contactData == null
        ? true
        : (isBorrower ? contactData.lenderIsVerified : contactData.borrowerIsVerified);

    final initials = _getInitials(name);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/positions');
            }
          },
        ),
        title: Text(
          l10n.contactDetailsTitle,
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF00E676),
              size: 22,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner 1: Deal Agreement Created ───────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF062015) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF00E676).withValues(alpha: 0.35)
                      : const Color(0xFF81C784),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF00E676).withValues(alpha: 0.15)
                          : const Color(0xFFC8E6C9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dealAgreementCreated,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.dealAgreementCreatedSubtitle,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.8)
                                : const Color(0xFF1B5E20),
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section Title ──────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.person_rounded, color: subtitleColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.contactTheOtherParty,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              l10n.detailsOnlyVisibleToYou,
              style: TextStyle(fontSize: 12, color: mutedColor),
            ),
            const SizedBox(height: 16),

            // ── Card 2: Opposite Party Contact Details Card ─────────────
            if (contactData == null) ...[
              // Unlock prompt container if not yet revealed
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A131F) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF00E676).withValues(alpha: 0.3)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded, size: 40, color: Color(0xFF00E676)),
                    const SizedBox(height: 12),
                    Text(
                      l10n.contactInfoLocked,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.contactInfoLockedSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: subtitleColor),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _unlocking ? null : _unlockContactFlow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A131F) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF00E676).withValues(alpha: 0.4)
                            : const Color(0xFF81C784),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black54 : Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Profile Info
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF063021) : const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF00E676).withValues(alpha: 0.6)
                                      : const Color(0xFF4CAF50),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isVerified) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.verified_rounded,
                                          color: Color(0xFF2196F3),
                                          size: 18,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: mutedColor,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        location,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        Icon(Icons.star_rounded,
                                            color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                                            size: 14),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$rating (${l10n.reviewsCount(reviewCount)})',
                                          style: TextStyle(
                                              fontSize: 11.5, color: subtitleColor),
                                        ),
                                        Text(
                                          '  |  ',
                                          style: TextStyle(
                                              color: mutedColor, fontSize: 12),
                                        ),
                                        Icon(
                                          Icons.verified_user_outlined,
                                          color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                                          size: 13,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          l10n.successfulDealsCount(completedDeals),
                                          style: TextStyle(
                                              fontSize: 11.5, color: subtitleColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                        const SizedBox(height: 14),

                        // Action 1: Phone
                        _ContactActionRow(
                          icon: Icons.phone_rounded,
                          label: l10n.phoneNumberLabel,
                          value: phone.isEmpty ? l10n.notProvided : phone,
                          actionLabel: l10n.callAction,
                          actionIcon: Icons.phone_forwarded_rounded,
                          onTap: () => _launchCall(phone, l10n),
                        ),
                        const SizedBox(height: 12),

                        // Action 2: Email
                        _ContactActionRow(
                          icon: Icons.email_rounded,
                          label: l10n.emailAddressLabel,
                          value: email.isEmpty ? l10n.notProvided : email,
                          actionLabel: l10n.emailAction,
                          actionIcon: Icons.mail_outline_rounded,
                          onTap: () => _launchEmail(email, l10n),
                        ),
                        const SizedBox(height: 12),

                        // Action 3: WhatsApp
                        _ContactActionRow(
                          icon: Icons.chat_rounded,
                          label: l10n.whatsappLabel,
                          value: phone.isEmpty ? l10n.notProvided : phone,
                          actionLabel: l10n.chatAction,
                          actionIcon: Icons.chat_bubble_outline_rounded,
                          onTap: () => _launchWhatsApp(phone, l10n),
                        ),
                      ],
                    ),
                  ),

                  // Floating Top Pill Badge
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF081C13) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF00E676) : const Color(0xFF4CAF50),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.oppositePartyContact,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ── Card 3: Safety First ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C1D36) : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBAE6FD),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.safetyFirstTitle,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.safetyFirstDesc,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0369A1),
                            fontSize: 12,
                            height: 1.38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Bottom Buttons ─────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF0052D4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
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
                onPressed: () => context.go('/positions'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.goToMyDeals,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/positions');
                  }
                },
                child: Text(
                  l10n.backToActivity,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactActionRow extends StatelessWidget {
  const _ContactActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.actionIcon,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF06141F) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF00E676).withValues(alpha: 0.12)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF00E676).withValues(alpha: 0.15)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF00E676).withValues(alpha: 0.4)
                      : const Color(0xFF81C784),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    actionIcon,
                    color: isDark ? const Color(0xFF00E676) : const Color(0xFF2E7D32),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
