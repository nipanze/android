// lib/features/provider/presentation/widgets/provider_verification_chip.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/provider_capability.dart';

class ProviderVerificationChip extends StatelessWidget {
  const ProviderVerificationChip({
    super.key,
    required this.level,
    this.phoneVerified = false,
    this.identityVerified = false,
  });

  final ProviderVerificationLevel level;
  final bool phoneVerified;
  final bool identityVerified;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isProviderVerified =
      level == ProviderVerificationLevel.providerVerified;
    final color = isProviderVerified || identityVerified
      ? AppColors.accent
      : phoneVerified
        ? AppColors.success
        : AppColors.warning;
    final label = isProviderVerified
      ? l10n.providerVerified
      : identityVerified
        ? l10n.kycIdentityVerified
        : phoneVerified
          ? l10n.phoneVerified
          : l10n.selfDeclared;
    final icon = isProviderVerified || identityVerified
      ? Icons.verified_rounded
      : phoneVerified
        ? Icons.phone_iphone_rounded
        : Icons.info_outline_rounded;

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
