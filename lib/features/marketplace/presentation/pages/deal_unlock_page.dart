// lib/features/marketplace/presentation/pages/deal_unlock_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../account/data/profile_repository.dart';
import '../../../account/domain/models/user_profile.dart';
import '../../../auth/domain/models/nipanze_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/agreement_repository.dart';
import '../../domain/models/agreement.dart';

class DealUnlockPage extends StatefulWidget {
  const DealUnlockPage({super.key, required this.agreementId});

  final String agreementId;

  @override
  State<DealUnlockPage> createState() => _DealUnlockPageState();
}

class _DealUnlockPageState extends State<DealUnlockPage> {
  late final AgreementRepository _agreementRepo;
  late final ProfileRepository _profileRepo;
  Agreement? _agreement;
  UserProfile? _profile;
  bool _loading = true;
  String? _error;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _agreementRepo = getIt<AgreementRepository>();
    _profileRepo = getIt<ProfileRepository>();
    _loadAgreement();
  }

  Future<void> _loadAgreement() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _agreementRepo.getAgreement(widget.agreementId),
        _profileRepo.getProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _agreement = results[0] as Agreement?;
        _profile = results[1] as UserProfile?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Returns true if this user unlocks for free (lender/pro subscription).
  bool _isPaidUser(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.lender || plan == SubscriptionPlan.pro;

  Future<void> _unlockContact(
      SubscriptionPlan plan, UserProfile? profile) async {
    final isPaid = _isPaidUser(plan);
    final freeLeft = profile?.freeUnlocksRemaining ?? 0;
    final hasWelcomeCredit = freeLeft > 0;

    // Decide the dialog content based on tier
    String title;
    String body;
    String confirmLabel;

    if (isPaid) {
      title = 'Unlock contact details?';
      body =
          'As a ${plan == SubscriptionPlan.pro ? 'Pro' : 'Lender'} subscriber, this unlock is included in your plan at no extra cost.\n\nContact details will be shared with both parties immediately.';
      confirmLabel = 'Unlock for Free';
    } else if (hasWelcomeCredit) {
      title = '🎁 Use your welcome unlock';
      body =
          'You have $freeLeft free unlock${freeLeft == 1 ? '' : 's'} remaining as a welcome gift.\n\nContact details will be shared with both parties. Subsequent unlocks cost UGX 5,000 each.\n\nThis action is irreversible.';
      confirmLabel = 'Use Free Unlock';
    } else {
      // No credits — show payment gate instead
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
      // Consume a free credit if applicable.
      // If the SQL patch hasn't been applied yet, this call may fail;
      // we swallow that error so the contact reveal still proceeds.
      if (!isPaid && hasWelcomeCredit) {
        try {
          final newRemaining = await _profileRepo.consumeFreeUnlock();
          if (mounted && _profile != null) {
            setState(() {
              _profile = _profile!.copyWith(freeUnlocksRemaining: newRemaining);
            });
          }
        } catch (creditError) {
          // RPC not yet deployed — log and continue.
          debugPrint('[DealUnlock] consumeFreeUnlock failed: $creditError');
        }
      }

      final contactData =
          await _agreementRepo.unlockContact(widget.agreementId);
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => _ContactRevealDialog(
          borrowerName: contactData.borrowerName,
          borrowerPhone: contactData.borrowerPhone,
          borrowerEmail: contactData.borrowerEmail,
          lenderName: contactData.lenderName,
          lenderPhone: contactData.lenderPhone,
          lenderEmail: contactData.lenderEmail,
          onClose: () {
            Navigator.pop(ctx);
            context.go('/positions');
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unlocking contact: $e'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 6),
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
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Unlock contact details',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            // Fee info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_open_rounded,
                        color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('One-time unlock fee',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        SizedBox(height: 2),
                        Text(
                          'UGX 5,000',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent),
                        ),
                        Text(
                          'Reveals contact info for this deal only.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // What you get
            const _FeatureRow(
              icon: Icons.person_outline_rounded,
              text: 'Full legal name of both parties',
            ),
            const _FeatureRow(
              icon: Icons.phone_outlined,
              text: 'Direct phone numbers for both parties',
            ),
            const _FeatureRow(
              icon: Icons.email_outlined,
              text: 'Email addresses for both parties',
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // Upgrade nudge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_outline_rounded,
                      color: AppColors.purple, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upgrade to Lender (UGX 35,000/mo) or Pro (UGX 150,000/mo) to unlock all contacts at no per-deal fee.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.purple.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.pricing);
                    },
                    child: const Text('Upgrade Plan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _proceedWithPayment();
                    },
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text('Pay UGX 5,000'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder for actual payment integration.
  /// For now shows a coming-soon snack bar.
  void _proceedWithPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Payment integration coming soon. You\'ll be charged UGX 5,000 to unlock contact details.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unlock deal')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _agreement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unlock deal')),
        body: ErrorState(
          message: _error ?? 'Agreement not found',
          onRetry: _loadAgreement,
        ),
      );
    }

    final agreement = _agreement!;

    if (!agreement.isFullyLocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unlock deal')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline,
                    size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Deal not yet ready',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Both borrower and lender must confirm the agreement before you can unlock contact details.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Read auth state for subscription plan
    final authState = context.watch<AuthBloc>().state;
    final plan = authState is AuthAuthenticated
        ? authState.user.subscriptionPlan
        : SubscriptionPlan.free;

    final profile = _profile;

    final isPaid = _isPaidUser(plan);
    final freeLeft = profile?.freeUnlocksRemaining ?? 0;
    final hasFreeCredit = !isPaid && freeLeft > 0;
    final needsPayment = !isPaid && !hasFreeCredit;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/positions');
            }
          },
        ),
        title: const Text('Unlock deal & contact'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Locked badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.success),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock,
                          size: 20, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'Deal agreement locked',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Both borrower and lender have confirmed the deal. '
                    'You can now unlock contact details to connect directly.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Unlock cost banner ────────────────────────────────────────
            if (isPaid)
              _UnlockCostBanner(
                icon: Icons.workspace_premium_rounded,
                color: AppColors.purple,
                title: 'Included in your ${plan == SubscriptionPlan.pro ? 'Pro' : 'Lender'} plan',
                subtitle: 'Unlimited contact unlocks at no extra fee.',
              )
            else if (hasFreeCredit)
              _UnlockCostBanner(
                icon: Icons.card_giftcard_rounded,
                color: AppColors.success,
                title: '🎁 Welcome gift — $freeLeft free unlock${freeLeft == 1 ? '' : 's'} remaining',
                subtitle: 'This deal uses one of your free unlocks. Additional unlocks cost UGX 5,000.',
              )
            else
              const _UnlockCostBanner(
                icon: Icons.payment_rounded,
                color: AppColors.warning,
                title: 'UGX 5,000 unlock fee applies',
                subtitle: 'Your welcome unlock has been used. Upgrade to Lender or Pro for unlimited free unlocks.',
              ),

            const SizedBox(height: 20),

            // What happens next
            Text(
              'What happens next',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const _InfoStep(
              number: 1,
              title: 'Contact details revealed',
              description:
                  'Legal name, phone, and email of both parties will be shared.',
            ),
            const SizedBox(height: 8),
            const _InfoStep(
              number: 2,
              title: 'Direct connection',
              description:
                  'You can now contact your partner outside the Nipanze platform.',
            ),
            const SizedBox(height: 8),
            const _InfoStep(
              number: 3,
              title: 'Complete transaction',
              description:
                  'Finalize the loan agreement and exchange funds directly.',
            ),
            const SizedBox(height: 24),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nipanze does not hold or move any funds. You and your '
                      'partner are solely responsible for all financial '
                      'transactions and dispute resolution.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Unlock button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _unlocking
                    ? null
                    : () => _unlockContact(plan, profile),
                style: FilledButton.styleFrom(
                  backgroundColor: needsPayment
                      ? AppColors.warning
                      : AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _unlocking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        needsPayment
                            ? Icons.payment_rounded
                            : Icons.lock_open_rounded,
                        size: 18,
                      ),
                label: Text(
                  needsPayment
                      ? 'Pay UGX 5,000 to Unlock'
                      : (hasFreeCredit
                          ? 'Unlock with Free Credit'
                          : 'Unlock contact details'),
                ),
              ),
            ),

            // Upgrade nudge for free users who've used credits
            if (needsPayment) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.pricing),
                  child: const Text(
                    'Upgrade for unlimited unlocks',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Support widgets ────────────────────────────────────────────────────────────

class _UnlockCostBanner extends StatelessWidget {
  const _UnlockCostBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
                child:
                    Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactRevealDialog extends StatelessWidget {
  const _ContactRevealDialog({
    required this.borrowerName,
    required this.borrowerPhone,
    required this.borrowerEmail,
    required this.lenderName,
    required this.lenderPhone,
    required this.lenderEmail,
    required this.onClose,
  });

  final String borrowerName;
  final String borrowerPhone;
  final String borrowerEmail;
  final String lenderName;
  final String lenderPhone;
  final String lenderEmail;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact details revealed'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connection successful. Here are the contact details:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _ContactCard(
              label: 'Borrower',
              name: borrowerName,
              phone: borrowerPhone,
              email: borrowerEmail,
            ),
            const SizedBox(height: 12),
            _ContactCard(
              label: 'Lender',
              name: lenderName,
              phone: lenderPhone,
              email: lenderEmail,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You can now contact your partner directly to complete the transaction outside of the Nipanze platform.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.label,
    required this.name,
    required this.phone,
    required this.email,
  });

  final String label;
  final String name;
  final String phone;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _ContactDetail(icon: Icons.person, value: name),
          const SizedBox(height: 4),
          _ContactDetail(icon: Icons.phone, value: phone),
          const SizedBox(height: 4),
          _ContactDetail(icon: Icons.email, value: email),
        ],
      ),
    );
  }
}

class _ContactDetail extends StatelessWidget {
  const _ContactDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
