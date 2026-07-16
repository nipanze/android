import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The public, platform-scoped reputation signals shown consistently wherever
/// a participant is represented. These never describe off-platform repayment.
class TrustBadgeRow extends StatelessWidget {
  const TrustBadgeRow({
    super.key,
    this.ratingAvg,
    required this.reviewCount,
    required this.completedDealsCount,
    required this.isRepeatParticipant,
    required this.phoneVerified,
    this.responseTimeBucket,
    this.isVerified = false,
    this.showProVerification = false,
  });

  final double? ratingAvg;
  final int reviewCount;
  final int completedDealsCount;
  final bool isRepeatParticipant;
  final bool phoneVerified;
  final String? responseTimeBucket;
  final bool isVerified;
  final bool showProVerification;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      _TrustBadge(
        icon: Icons.star_rounded,
        label: ratingAvg == null
            ? 'No reviews yet'
            : '${ratingAvg!.toStringAsFixed(1)} ($reviewCount)',
        color: AppColors.warning,
      ),
      _TrustBadge(
        icon: Icons.handshake_outlined,
        label: '$completedDealsCount completed',
        color: AppColors.accent,
      ),
      if (isRepeatParticipant)
        const _TrustBadge(
          icon: Icons.repeat_rounded,
          label: 'Repeat participant',
          color: AppColors.success,
        ),
      if (phoneVerified)
        const _TrustBadge(
          icon: Icons.phone_iphone_rounded,
          label: 'Phone verified',
          color: AppColors.success,
        ),
      if (responseTimeBucket != null)
        _TrustBadge(
          icon: Icons.schedule_rounded,
          label: _responseLabel(responseTimeBucket!),
          color: AppColors.purple,
        ),
      if (showProVerification && isVerified)
        const _TrustBadge(
          icon: Icons.verified_rounded,
          label: 'Verified',
          color: AppColors.purple,
        ),
    ];

    return Wrap(spacing: 6, runSpacing: 6, children: badges);
  }

  String _responseLabel(String bucket) => switch (bucket) {
        'responds_quickly' => 'Responds quickly',
        'responds_within_a_day' => 'Responds within a day',
        'responds_slowly' => 'Responds slowly',
        _ => 'Response time unknown',
      };
}

class AdvancedTrustPanel extends StatelessWidget {
  const AdvancedTrustPanel({
    super.key,
    this.successRate,
    this.reliabilityScore,
  });

  final double? successRate;
  final int? reliabilityScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.07),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.insights_outlined, color: AppColors.purple),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pro trust insights',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              'Success rate ${successRate == null ? '—' : '${successRate!.toStringAsFixed(0)}%'} · Reliability ${reliabilityScore == null ? '—' : '$reliabilityScore/100'}',
              style: const TextStyle(fontSize: 11),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}
