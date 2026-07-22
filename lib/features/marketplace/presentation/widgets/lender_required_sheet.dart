// lib/features/marketplace/presentation/widgets/lender_required_sheet.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Show the Lender plan required bottom sheet matching the Nipanze paywall design.
Future<void> showLenderRequiredSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _LenderRequiredSheet(),
  );
}

class _LenderRequiredSheet extends StatelessWidget {
  const _LenderRequiredSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF1C1F26) : AppColors.bg2Light;
    final cardBg = isDark ? const Color(0xFF14171E) : AppColors.bg3Light;
    final cardBorder = isDark ? const Color(0xFF1F4885) : const Color(0xFFBFDBFE);
    final badgeBg = isDark ? const Color(0xFF0F2C54) : const Color(0xFFDBEAFE);
    final badgeText = isDark ? const Color(0xFF388DF8) : const Color(0xFF1D4ED8);
    final textPrimary = isDark ? AppColors.textDark : AppColors.textLight;
    final textSecondary = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final textMuted = isDark ? AppColors.text3Dark : AppColors.text3Light;
    final checkColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final handleColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    const buttonBg = AppColors.accent;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle bar ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Title & Lock Icon Header ────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 22,
                    color: textPrimary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Lender required',
                    style: TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Subtitle ────────────────────────────────────────────────
              Text(
                'Making offers is part of the Lender plan (also included in Pro). Upgrade to unlock offer placement on any listing.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // ── Lender Plan Card ───────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder, width: 1.5),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: Lender tier
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Lender tier',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Handshake / Offer Icon + Title
                    Row(
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: 22,
                          color: badgeText,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lender',
                          style: TextStyle(
                            fontFamily: AppFonts.heading,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Pricing: UGX 19,900 / month
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'UGX 19,900',
                          style: TextStyle(
                            fontFamily: AppFonts.heading,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          ' / month',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Short Card Description
                    Text(
                      'For anyone ready to make structured offers and earn returns on Nipanze.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF2D323E) : AppColors.borderLight, height: 1),
                    const SizedBox(height: 16),

                    // Feature Checkmark List
                    _buildFeatureItem(checkColor, textPrimary, 'Everything in Free'),
                    const SizedBox(height: 10),
                    _buildFeatureItem(checkColor, textPrimary, 'Make offers with full terms (rate, fee, schedule)'),
                    const SizedBox(height: 10),
                    _buildFeatureItem(checkColor, textPrimary, 'See offer detail where you participate'),

                    const SizedBox(height: 22),

                    // "Choose Lender" Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBg,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.pricing);
                        },
                        child: const Text(
                          'Choose Lender',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Not now Text Button ────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                  ),
                  child: const Text(
                    'Not now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Legal / Security Caption ────────────────────────────────
              Text(
                'Nipanze does not hold or move funds. Subscription changes are confirmed through a secure payment flow.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(Color checkColor, Color textColor, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Icon(
           Icons.check_circle_outline,
           size: 16,
           color: checkColor,
         ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
