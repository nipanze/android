import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/forex_listing_model.dart';

class SendRateReceivePanel extends StatelessWidget {
  const SendRateReceivePanel({
    super.key,
    required this.listing,
    this.showBorder = true,
  });

  final ForexListingModel listing;
  final bool showBorder;

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: showBorder ? Border.all(color: borderColor, width: 1) : null,
      ),
      child: Row(
        children: [
          // ── 1. I HOLD ───────────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _CircleIcon(
                  icon: Icons.arrow_downward_rounded,
                  color: mutedLabelColor,
                  bgOpacity: 0.10,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n?.iHold ?? 'I hold',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: mutedLabelColor,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          sendText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 2. RATE (with swap icon) ──────────────────────────────────────
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 12,
                    color: mutedLabelColor,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n?.rate ?? 'Rate',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: mutedLabelColor,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          rateText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider line ─────────────────────────────────────────────────
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08),
          ),

          // ── 3. I NEED ──────────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _CircleIcon(
                  icon: Icons.arrow_upward_rounded,
                  color: mutedLabelColor,
                  bgOpacity: 0.10,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n?.iNeed ?? 'I need',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: mutedLabelColor,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          receiveText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.color,
    required this.bgOpacity,
  });

  final IconData icon;
  final Color color;
  final double bgOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgOpacity),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, size: 11, color: color),
    );
  }
}
