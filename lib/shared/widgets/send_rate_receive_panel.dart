import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/forex_listing_model.dart';

class SendRateReceivePanel extends StatelessWidget {
  const SendRateReceivePanel({
    super.key,
    required this.listing,
    this.showBorder = true,
    this.prominent = false,
  });

  final ForexListingModel listing;
  final bool showBorder;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rate = listing.preferredRate;
    final rateText = _formatRateText(context, listing);
    final receiveText = rate == null
        ? listing.currencyNeeded
        : '${_currencySymbol(listing.currencyNeeded)} ${_fmt(listing.receiveEstimate)}';
    final sendText =
        '${_currencySymbol(listing.currencyHeld)} ${_fmt(listing.amount)}';

    final cardBg = isDark
        ? Colors.black.withValues(alpha: 0.20)
        : Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4);
    final mutedLabelColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final primaryTextColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: prominent
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: showBorder ? Border.all(color: borderColor, width: 1) : null,
      ),
      child: Row(
        children: prominent
            ? [
                Expanded(
                  child: _ProminentForexMetric(
                    icon: Icons.arrow_downward_rounded,
                    label: l10n?.iHold ?? 'I hold',
                    value: sendText,
                    iconColor: mutedLabelColor,
                    labelColor: mutedLabelColor,
                    valueColor: primaryTextColor,
                  ),
                ),
                _MetricDivider(isDark: isDark, prominent: true),
                Expanded(
                  child: _ProminentForexMetric(
                    icon: Icons.swap_horiz_rounded,
                    label: l10n?.rate ?? 'Rate',
                    value: rateText,
                    iconColor: mutedLabelColor,
                    labelColor: mutedLabelColor,
                    valueColor: primaryTextColor,
                    valueFontSize: 14,
                  ),
                ),
                _MetricDivider(isDark: isDark, prominent: true),
                Expanded(
                  child: _ProminentForexMetric(
                    icon: Icons.arrow_upward_rounded,
                    label: l10n?.iNeed ?? 'I need',
                    value: receiveText,
                    iconColor: mutedLabelColor,
                    labelColor: mutedLabelColor,
                    valueColor: primaryTextColor,
                  ),
                ),
              ]
            : [
                Expanded(
                  flex: 3,
                  child: _CompactForexMetric(
                    icon: Icons.arrow_downward_rounded,
                    label: l10n?.iHold ?? 'I hold',
                    value: sendText,
                    iconColor: mutedLabelColor,
                    labelColor: mutedLabelColor,
                    valueColor: primaryTextColor,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _CompactForexMetric(
                    icon: Icons.swap_horiz_rounded,
                    label: l10n?.rate ?? 'Rate',
                    value: rateText,
                    iconColor: mutedLabelColor,
                    labelColor: mutedLabelColor,
                    valueColor: primaryTextColor,
                    valueFontSize: 11,
                  ),
                ),
                _MetricDivider(isDark: isDark),
                Expanded(
                  flex: 4,
                  child: _CompactForexMetric(
                    icon: Icons.arrow_upward_rounded,
                    label: l10n?.iNeed ?? 'I need',
                    value: receiveText,
                    iconColor: mutedLabelColor,
                    labelColor: mutedLabelColor,
                    valueColor: primaryTextColor,
                  ),
                ),
              ],
      ),
    );
  }

  String _formatRateText(BuildContext context, ForexListingModel listing) {
    final l10n = AppLocalizations.of(context);
    final rate = listing.preferredRate;
    if (rate == null) {
      return listing.rateCoverageTier ?? l10n?.marketRate ?? 'Market rate';
    }
    // E.g. USD -> UGX rate = 0.000269 -> 1 USD = 3,717 UGX
    // Or UGX -> KES rate = 0.0285 -> 1 KES = 35 UGX
    if (listing.currencyHeld == 'USD' && rate > 1) {
      return '1 USD = ${_fmtDouble(rate)} ${listing.currencyNeeded}';
    } else if (listing.currencyNeeded == 'USD' && rate < 1) {
      final inv = 1 / rate;
      return '1 USD = ${_fmtDouble(inv)} ${listing.currencyHeld}';
    } else if (rate < 1) {
      final inv = 1 / rate;
      if (inv >= 2) {
        return '1 ${listing.currencyNeeded} = ${_fmtDouble(inv)} ${listing.currencyHeld}';
      }
      return '1 ${listing.currencyHeld} = ${rate.toStringAsFixed(4)} ${listing.currencyNeeded}';
    } else {
      return '1 ${listing.currencyHeld} = ${_fmtDouble(rate)} ${listing.currencyNeeded}';
    }
  }

  String _currencySymbol(String code) {
    return switch (code) {
      'USD' => '\$',
      'EUR' => '€',
      'GBP' => '£',
      _ => code,
    };
  }

  String _fmtDouble(double val) {
    if (val >= 100) {
      return _fmt(val.round());
    }
    return val.toStringAsFixed(2);
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

class _CompactForexMetric extends StatelessWidget {
  const _CompactForexMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.labelColor,
    required this.valueColor,
    this.valueFontSize = 12,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color labelColor;
  final Color valueColor;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIcon(icon: icon, color: iconColor),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProminentForexMetric extends StatelessWidget {
  const _ProminentForexMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.labelColor,
    required this.valueColor,
    this.valueFontSize = 16,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color labelColor;
  final Color valueColor;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({required this.isDark, this.prominent = false});

  final bool isDark;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: prominent ? 50 : 20,
      margin: EdgeInsets.symmetric(horizontal: prominent ? 10 : 3),
      color: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.08),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, size: 11, color: color),
    );
  }
}
