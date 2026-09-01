// lib/shared/widgets/safety_toolkit_sheet.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

Future<void> showSafetyToolkitSheet(
  BuildContext context, {
  String? kycStatus,
  bool phoneVerified = false,
  double? ratingAvg,
  int reviewCount = 0,
  int completedDealsCount = 0,
  bool hasCollateral = false,
  String? dealStatus,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => _SafetyToolkitSheet(
      kycStatus: kycStatus,
      phoneVerified: phoneVerified,
      ratingAvg: ratingAvg,
      reviewCount: reviewCount,
      completedDealsCount: completedDealsCount,
      hasCollateral: hasCollateral,
      dealStatus: dealStatus,
    ),
  );
}

class _SafetyToolkitSheet extends StatelessWidget {
  const _SafetyToolkitSheet({
    this.kycStatus,
    this.phoneVerified = false,
    this.ratingAvg,
    this.reviewCount = 0,
    this.completedDealsCount = 0,
    this.hasCollateral = false,
    this.dealStatus,
  });

  final String? kycStatus;
  final bool phoneVerified;
  final double? ratingAvg;
  final int reviewCount;
  final int completedDealsCount;
  final bool hasCollateral;
  final String? dealStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marketplace Safety & Trust',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Trust signals, deal guidance, and protection tips',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Trust signals matrix card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Counterparty Trust Signals',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // KYC Identity Badge
                      _SignalChip(
                        icon: kycStatus == 'approved'
                            ? Icons.verified_user_rounded
                            : Icons.gavel_rounded,
                        label: kycStatus == 'approved'
                            ? 'Identity Verified (KYC)'
                            : 'KYC Unverified',
                        isPositive: kycStatus == 'approved',
                      ),
                      // Phone verification badge
                      _SignalChip(
                        icon: phoneVerified
                            ? Icons.phone_android_rounded
                            : Icons.phone_locked_outlined,
                        label: phoneVerified
                            ? 'Phone Verified'
                            : 'Phone Unverified',
                        isPositive: phoneVerified,
                      ),
                      // Rating & reviews
                      if (ratingAvg != null && ratingAvg! > 0)
                        _SignalChip(
                          icon: Icons.star_rounded,
                          label:
                              '${ratingAvg!.toStringAsFixed(1)} ★ ($reviewCount reviews)',
                          isPositive: true,
                        ),
                      // Completed deals
                      _SignalChip(
                        icon: Icons.handshake_outlined,
                        label: '$completedDealsCount Deals Completed',
                        isPositive: completedDealsCount > 0,
                      ),
                      // Collateral status
                      if (hasCollateral)
                        const _SignalChip(
                          icon: Icons.lock_outline_rounded,
                          label: 'Secured Collateral Listing',
                          isPositive: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Deal Safety Guidance Checklist
            Text(
              'Safe Dealing Guidance',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const _GuidelineItem(
              icon: Icons.money_off_rounded,
              iconColor: AppColors.danger,
              title: 'Never pay upfront fees',
              description:
                  'Do not pay processing fees, inspection charges, or advance deposits prior to deal execution.',
            ),
            const _GuidelineItem(
              icon: Icons.description_outlined,
              iconColor: AppColors.accent,
              title: 'Use written deal agreements',
              description:
                  'Ensure loan or forex terms are reviewed and agreed upon via Nipanze Deal Agreement.',
            ),
            const _GuidelineItem(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.success,
              title: 'Keep messages on Nipanze',
              description:
                  'Maintain communication records within Nipanze for clarity and official records.',
            ),
            const SizedBox(height: 16),

            // Non-custodial legal disclaimer card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nipanze is a non-custodial peer-to-peer technology platform. Nipanze does not hold user funds, process repayments, or guarantee transaction outcomes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.35,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Support & Reporting buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDialog(
                      context,
                      'Report Listing or User',
                      'To report fraud, suspicious activity, or misconduct, please email safety@nipanze.com with details and screenshots.',
                    ),
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('Report User'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDialog(
                      context,
                      'Nipanze Safety Support',
                      'Need assistance? Contact support@nipanze.com or visit support.nipanze.com for marketplace resolution guides.',
                    ),
                    icon: const Icon(Icons.help_outline_rounded, size: 16),
                    label: const Text('Help & Support'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _showDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({
    required this.icon,
    required this.label,
    required this.isPositive,
  });

  final IconData icon;
  final String label;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
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

class _GuidelineItem extends StatelessWidget {
  const _GuidelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
