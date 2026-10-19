// lib/features/provider/presentation/widgets/provider_verification_chip.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/provider_capability.dart';

class ProviderVerificationChip extends StatelessWidget {
  const ProviderVerificationChip({
    super.key,
    required this.level,
    this.status,
  });

  final ProviderVerificationLevel level;
  final ProviderCapabilityStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final capabilityStatus = status ??
        (level == ProviderVerificationLevel.providerVerified
            ? ProviderCapabilityStatus.providerVerified
            : ProviderCapabilityStatus.active);
    final color = switch (capabilityStatus) {
      ProviderCapabilityStatus.active => AppColors.accent,
      ProviderCapabilityStatus.inactive => AppColors.danger,
      ProviderCapabilityStatus.providerVerified => AppColors.accent,
      ProviderCapabilityStatus.pendingReview => AppColors.warning,
      ProviderCapabilityStatus.rejected => AppColors.danger,
      ProviderCapabilityStatus.expired => AppColors.danger,
      ProviderCapabilityStatus.selfDeclared => AppColors.warning,
    };
    final label = switch (capabilityStatus) {
      ProviderCapabilityStatus.active => l10n.providerCapabilityActive,
      ProviderCapabilityStatus.inactive => l10n.providerCapabilityInactive,
      ProviderCapabilityStatus.providerVerified => l10n.providerVerified,
      ProviderCapabilityStatus.pendingReview =>
        l10n.providerCapabilityPendingReview,
      ProviderCapabilityStatus.rejected => l10n.providerCapabilityRejected,
      ProviderCapabilityStatus.expired => l10n.expired,
      ProviderCapabilityStatus.selfDeclared => l10n.providerCapabilityActive,
    };
    final icon = switch (capabilityStatus) {
      ProviderCapabilityStatus.active => Icons.check_circle_outline_rounded,
      ProviderCapabilityStatus.inactive => Icons.block_rounded,
      ProviderCapabilityStatus.providerVerified => Icons.verified_rounded,
      ProviderCapabilityStatus.pendingReview => Icons.hourglass_top_rounded,
      ProviderCapabilityStatus.rejected => Icons.error_outline_rounded,
      ProviderCapabilityStatus.expired => Icons.event_busy_rounded,
      ProviderCapabilityStatus.selfDeclared =>
        Icons.check_circle_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
