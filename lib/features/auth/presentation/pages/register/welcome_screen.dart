// lib/features/auth/presentation/pages/register/welcome_screen.dart

import 'package:flutter/material.dart';


import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../widgets/live_dot.dart';
import '../../widgets/starfield_background.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, 
    required this.onContinueWithPhone,
    required this.onContinueWithEmail,
    required this.onCreateAccount,
  });

  final VoidCallback onContinueWithPhone;
  final VoidCallback onContinueWithEmail;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    final bgColor = isDark ? const Color(0xFF06080E) : const Color(0xFFFFFFFF);

    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
    final footerTextColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF475569);
    final footerLinkColor = isDark ? AppColors.accentLight : AppColors.accent;

    return Container(
      width: double.infinity,
      height: size.height,
      decoration: BoxDecoration(
        color: bgColor,
      ),
      // Stack lets the starfield/continent silhouette sit behind everything
      // without disturbing the existing Column layout below.
      child: Stack(
        children: [
          StarfieldBackground(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                // ── Top: Logo ─────────────────────────────────────────────
                const SizedBox(height: 32),
                const NipanzeLogo(),

                // ── Hero copy ─────────────────────────────────────────────
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        l10n.welcomeTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const LiveDot(size: 8),
                          const SizedBox(width: 6),
                          Text(
                            l10n.welcomeTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                              height: 1.4,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.welcomeSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: subtitleColor.withValues(alpha: 0.8),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Hero illustration ─────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.25, 0.75, 1.0],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        isDark
                            ? 'assets/images/hero_illustration_dark.png'
                            : 'assets/images/hero_illustration_light.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // ── CTA + footer ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 50),
                  child: Column(
                    children: [
                      // Primary CTA
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: onContinueWithPhone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 20),
                          label: const Text(
                            'Continue with Phone',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Terms footer
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 8),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: footerTextColor,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(
                                      text:
                                          'By continuing, you agree to our\n'),
                                  TextSpan(
                                    text: 'Terms of Use',
                                    style: TextStyle(
                                      color: footerLinkColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: footerLinkColor,
                                      fontWeight: FontWeight.w600,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nipanze logo image ────────────────────────────────────────────────────────
class NipanzeLogo extends StatelessWidget {
  const NipanzeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/nipanze_logo.png',
      height: 110,
      fit: BoxFit.contain,
    );
  }
}

// ── 1. Phone Entry ────────────────────────────────────────────────────────────
