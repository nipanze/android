import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/domain/models/nipanze_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../l10n/app_localizations.dart';

class KycGateScreen extends StatefulWidget {
  const KycGateScreen({
    super.key,
    required this.kycStatus,
    required this.pageTitle,
    this.reason,
  });

  final KycStatus kycStatus;
  final String pageTitle;

  /// Override message — used when KYC is approved but the account is otherwise
  /// ineligible (e.g. canBorrow == false).
  final String? reason;

  @override
  State<KycGateScreen> createState() => _KycGateScreenState();
}

class _KycGateScreenState extends State<KycGateScreen> {
  Timer? _pollTimer;

  Future<void> _openKyc(BuildContext context) async {
    await context.push(AppRoutes.kyc);
    if (context.mounted) {
      context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
    }
  }

  void _startPolling() {
    // Only poll while pending; dispatch a profile refresh every 5 seconds.
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthProfileRefreshRequested());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.kycStatus == KycStatus.pending) {
      _startPolling();
    }
  }

  @override
  void didUpdateWidget(covariant KycGateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kycStatus != widget.kycStatus) {
      if (widget.kycStatus == KycStatus.pending) {
        _startPolling();
      } else {
        _stopPolling();
      }
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final kycStatus = widget.kycStatus;

    final (IconData icon, Color iconColor, String title, String body) =
        switch (kycStatus) {
      KycStatus.pending => (
          Icons.hourglass_top_rounded,
          AppColors.warning,
          l10n?.kycGatePendingTitle ?? 'Verification in review',
          l10n?.kycGatePendingBody ??
              'Your identity documents are being reviewed. You\'ll be notified as soon as your account is approved.',
        ),
      KycStatus.rejected => (
          Icons.cancel_outlined,
          AppColors.danger,
          l10n?.kycGateRejectedTitle ?? 'Verification rejected',
          l10n?.kycGateRejectedBody ??
              'Your KYC submission was not approved. Please re-submit with valid documents.',
        ),
      KycStatus.expired => (
          Icons.lock_clock_outlined,
          AppColors.warning,
          l10n?.kycGateExpiredTitle ?? 'Verification expired',
          l10n?.kycGateExpiredBody ??
              'Your KYC verification has expired. Please re-submit to continue posting requests.',
        ),
      _ => (
          Icons.lock_person_outlined,
          AppColors.accent,
          l10n?.kycGateTitle ?? 'Verify your identity first',
          l10n?.kycGateBody ??
              'To post loan or forex requests and connect with lenders, you need to complete identity verification. It only takes a few minutes.',
        ),
    };

    final isNotSubmitted = kycStatus == KycStatus.notSubmitted;
    final isPending = kycStatus == KycStatus.pending;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button & title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.marketplace),
                  ),
                  Expanded(
                    child: Text(
                      widget.pageTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // Icon badge
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, size: 44, color: iconColor),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 14),

                    Text(
                      widget.reason ?? body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    // Steps for notSubmitted
                    if (isNotSubmitted) ...[
                      _GateStep(
                        number: '1',
                        label: l10n?.kycStep1 ??
                            'Submit your national ID or passport',
                      ),
                      const SizedBox(height: 12),
                      _GateStep(
                        number: '2',
                        label: l10n?.kycStep2 ??
                            'Wait for review (usually within 24 hours)',
                      ),
                      const SizedBox(height: 12),
                      _GateStep(
                        number: '3',
                        label: l10n?.kycStep3 ??
                            'Post requests once approved',
                      ),
                      const SizedBox(height: 36),
                    ],

                    // Under Review info card for pending status
                    if (isPending) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded,
                                color: AppColors.warning, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n?.kycPendingNotice ??
                                    'Documents submitted — admin review in progress. This usually takes 1–2 business days.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: Text(l10n?.kycStatusPending ?? 'View verification details'),
                          onPressed: () => _openKyc(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go(AppRoutes.marketplace),
                          child: Text(l10n?.browseMarketplace ?? 'Browse marketplace'),
                        ),
                      ),
                    ],

                    // Buttons for notSubmitted, rejected, or expired
                    if (!isPending) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.verified_user_outlined, size: 18),
                          label: Text(
                            isNotSubmitted
                                ? (l10n?.kycGateCta ?? 'Start verification')
                                : (l10n?.kycGateResubmitCta ??
                                    'Re-submit verification'),
                          ),
                          onPressed: () => _openKyc(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.marketplace),
                        child: Text(l10n?.btnBack ?? 'Back'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GateStep extends StatelessWidget {
  const _GateStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
