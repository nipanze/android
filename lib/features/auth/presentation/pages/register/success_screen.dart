// lib/features/auth/presentation/pages/register/success_screen.dart

import 'package:flutter/material.dart';


import '../../../../../core/theme/app_theme.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.onGoToMarketplace});
  final VoidCallback onGoToMarketplace;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
    final cardBgColor =
        isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
    final cardBorderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // ── Big green checkmark ───────────────────────────────────────
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF22C55E),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF22C55E),
                size: 60,
              ),
            ),
            const SizedBox(height: 32),

            // ── Title ─────────────────────────────────────────────────────
            Text(
              "You're in! 🎉",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: titleColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your account has been created\nsuccessfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // ── Feature cards ─────────────────────────────────────────────
            SuccessFeatureCard(
              icon: Icons.people_alt_rounded,
              iconBgColor: AppColors.accent.withValues(alpha: 0.15),
              iconColor: AppColors.accentLight,
              title: 'Explore loan requests',
              subtitle: 'Find borrowers and lenders\nin your country.',
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 12),
            SuccessFeatureCard(
              icon: Icons.verified_user_rounded,
              iconBgColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
              iconColor: const Color(0xFF22C55E),
              title: 'Safe & secure',
              subtitle: 'We protect your data and\ntransactions.',
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),

            const Spacer(),
            const SizedBox(height: 8),

            // ── CTA button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onGoToMarketplace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Go to Marketplace',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class SuccessFeatureCard extends StatelessWidget {
  const SuccessFeatureCard({super.key, 
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.cardBgColor,
    required this.cardBorderColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color cardBgColor;
  final Color cardBorderColor;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: subtitleColor,
                    height: 1.4,
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

// ── 5. Email Login ────────────────────────────────────────────────────────────
