// lib/shared/widgets/verification_gate_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/domain/models/nipanze_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/kyc/data/verification_service.dart';
import '../../features/kyc/domain/models/verification_requirement.dart';
import '../../l10n/app_localizations.dart';

class VerificationGateModal extends StatelessWidget {
  const VerificationGateModal({
    super.key,
    required this.checkResult,
    this.customTitle,
    this.customMessage,
    this.onVerified,
  });

  final VerificationCheckResult checkResult;
  final String? customTitle;
  final String? customMessage;
  final VoidCallback? onVerified;

  /// Central verification gate helper.
  /// Checks whether the user satisfies the verification requirements for [action].
  /// If not, displays the verification prompt bottom sheet.
  /// Returns `true` if allowed (or verified after prompt), `false` if dismissed.
  static Future<bool> checkAndGate(
    BuildContext context, {
    required String action, // 'loan_request' | 'forex_request' | 'need_request' | 'loan_offer' | 'forex_offer' | 'need_offer' | 'service_offer'
    String? categorySlug,
    String? capabilitySlug,
    String? customTitle,
    String? customMessage,
    VoidCallback? onVerified,
  }) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      context.go(AppRoutes.login);
      return false;
    }

    final user = authState.user;

    // Fast local identity check if applicable
    final verificationService = getIt<VerificationService>();
    final result = await verificationService.canPerform(
      action: action,
      categorySlug: categorySlug,
      capabilitySlug: capabilitySlug,
      user: user,
    );

    if (result.allowed) {
      onVerified?.call();
      return true;
    }

    if (!context.mounted) return false;

    // Show prompt sheet
    final didVerify = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => VerificationGateModal(
        checkResult: result,
        customTitle: customTitle,
        customMessage: customMessage,
        onVerified: onVerified,
      ),
    );

    return didVerify ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isProviderReq = checkResult.requiresProviderVerification;

    final title = customTitle ??
        (isProviderReq
            ? (l10n?.providerVerificationRequiredTitle ??
                'Additional verification required')
            : (l10n?.identityVerificationRequiredTitle ??
                'Identity verification required'));

    final message = customMessage ??
        (isProviderReq
            ? (l10n?.providerVerificationRequiredDesc ??
                'This category requires provider verification before you can offer this service.')
            : (l10n?.identityVerificationRequiredDesc ??
                'Verify your identity before you can post or offer on Nipanze.'));

    final primaryButtonLabel = isProviderReq
        ? (l10n?.startProviderVerificationBtn ?? 'Start Provider Verification')
        : (l10n?.verifyIdentityBtn ?? 'Verify Identity');

    final icon = isProviderReq
        ? Icons.verified_rounded
        : Icons.badge_outlined;

    final iconColor = isProviderReq ? AppColors.accent : AppColors.success;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Primary action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                  isProviderReq ? Icons.arrow_forward_rounded : Icons.verified_user_outlined,
                  size: 18,
                ),
                label: Text(primaryButtonLabel),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.accent,
                ),
                onPressed: () async {
                  Navigator.pop(context, false);
                  if (isProviderReq) {
                    await context.push(AppRoutes.accountServices);
                  } else {
                    await context.push(AppRoutes.kyc);
                  }

                  if (!context.mounted) return;
                  context.read<AuthBloc>().add(const AuthProfileRefreshRequested());

                  final refreshedState = context.read<AuthBloc>().state;
                  if (refreshedState is AuthAuthenticated &&
                      refreshedState.user.kycApproved) {
                    onVerified?.call();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Secondary button (Maybe Later)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n?.maybeLaterBtn ?? 'Maybe Later',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
