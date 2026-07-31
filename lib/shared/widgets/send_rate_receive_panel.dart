import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../models/forex_listing_model.dart';

class SendRateReceivePanel extends StatelessWidget {
  const SendRateReceivePanel({super.key, required this.listing});

  final ForexListingModel listing;

  @override
  Widget build(BuildContext context) {
    final rate = listing.preferredRate;
    return Row(
      children: [
        Expanded(
          child: _PanelPart(
            label: 'You send',
            value: '${listing.currencyHeld} ${_fmt(listing.amount)}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PanelPart(
            label: 'Rate',
            value: rate == null
                ? listing.rateCoverageTier ?? 'Open'
                : rate.toStringAsFixed(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PanelPart(
            label: 'You receive',
            value: rate == null
                ? listing.currencyNeeded
                : '${listing.currencyNeeded} ${_fmt(listing.receiveEstimate)}',
          ),
        ),
      ],
    );
  }

  String _fmt(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _PanelPart extends StatelessWidget {
  const _PanelPart({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
