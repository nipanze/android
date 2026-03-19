// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';

/// Reusable widget for displaying one of the three wallet pools.
/// Used on WalletPage and DashboardPage.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.label,
    required this.sublabel,
    required this.amount,
    required this.color,
    required this.icon,
    required this.tooltipText,
  });

  final String label;
  final String sublabel;
  final double amount;
  final Color color;
  final IconData icon;
  final String tooltipText;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'en_UG');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'UGX ${fmt.format(amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Tooltip(
                  message: tooltipText,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reputation tier badge chip.
class ReputationTierBadge extends StatelessWidget {
  const ReputationTierBadge({super.key, required this.tier, this.score});
  final String tier;
  final int? score;

  Color get _color => switch (tier.toLowerCase()) {
        'platinum' => AppColors.tierPlatinum,
        'gold' => AppColors.tierGold,
        'silver' => AppColors.tierSilver,
        'bronze' => AppColors.tierBronze,
        _ => AppColors.tierRestricted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 13, color: _color),
          const SizedBox(width: 4),
          Text(
            tier[0].toUpperCase() + tier.substring(1).toLowerCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _color,
              fontFamily: 'Inter',
            ),
          ),
          if (score != null) ...[
            const SizedBox(width: 4),
            Text(
              '($score)',
              style: TextStyle(
                fontSize: 10,
                color: _color.withOpacity(0.7),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// KYC status chip.
class KycStatusChip extends StatelessWidget {
  const KycStatusChip({super.key, required this.status});
  final String? status;

  Color get _color => switch (status) {
        'approved' => AppColors.success,
        'pending' => AppColors.warning,
        'rejected' => AppColors.error,
        'expired' => AppColors.error,
        _ => Colors.grey,
      };

  String get _label => switch (status) {
        'approved' => 'KYC Verified',
        'pending' => 'KYC Pending',
        'rejected' => 'KYC Rejected',
        'expired' => 'KYC Expired',
        'not_started' => 'KYC Required',
        _ => 'KYC Unknown',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
