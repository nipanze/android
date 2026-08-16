// lib/features/marketplace/presentation/widgets/pro_required_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Show the Pro plan required bottom sheet matching the Nipanze paywall design.
Future<void> showProRequiredSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ProRequiredSheet(),
  );
}

class _ProRequiredSheet extends StatelessWidget {
  const _ProRequiredSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    String? countryCode;
    try {
      final authState = context.watch<AuthBloc?>()?.state;
      if (authState is AuthAuthenticated) countryCode = authState.user.country;
    } catch (_) {}
    final country = EastAfricaCountries.findByCode(countryCode);

    final bg = isDark ? const Color(0xFF1C1F26) : AppColors.bg2Light;
    final cardBg = isDark ? const Color(0xFF14171E) : AppColors.bg3Light;
    final cardBorder = isDark ? const Color(0xFF5B21B6) : const Color(0xFFDDD6FE);
    final badgeBg = isDark ? const Color(0xFF2E1065) : const Color(0xFFEDE9FE);
    final badgeText = isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9);
    final textPrimary = isDark ? AppColors.textDark : AppColors.textLight;
    final textSecondary = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final textMuted = isDark ? AppColors.text3Dark : AppColors.text3Light;
    final checkColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final handleColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    const buttonBg = Color(0xFF6B5AED);

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
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 22,
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n?.proRequired ?? 'Pro tier required',
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
                l10n?.proRequiredSubtitle ??
                    'Advanced features like custom term proposals and advanced filters are reserved for Pro subscribers.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // ── Pro Plan Card ───────────────────────────────────────────
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
                    // Badge: Pro tier
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n?.proTier ?? 'Pro tier',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Star / Pro Icon + Title
                    Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: 22,
                          color: badgeText,
                        ),
                        const SizedBox(width: 8),
                         Text(
                           'Pro',
                           style: TextStyle(
                             fontFamily: AppFonts.heading,
                             fontSize: 17,
                             fontWeight: FontWeight.w700,
                             color: textPrimary,
                           ),
                         ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Pricing: [Country Currency Price] / month
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                           country.proPriceFormatted,
                           style: TextStyle(
                             fontFamily: AppFonts.heading,
                             fontSize: 22,
                             fontWeight: FontWeight.w800,
                             color: textPrimary,
                             letterSpacing: -0.5,
                           ),
                        ),
                        Text(
                          l10n?.perMonth ?? ' / month',
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
                      l10n?.proTierDesc ??
                          'Full marketplace access, advanced filters and strong request positioning.',
                     style: TextStyle(
                       fontSize: 12.5,
                       height: 1.4,
                       color: textSecondary,
                     ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF2D323E) : AppColors.borderLight, height: 1),
                    const SizedBox(height: 16),

                    // Feature Checkmark List
                    _buildFeatureItem(checkColor, textPrimary, l10n?.everythingInLender ?? 'Everything in Lender'),
                    const SizedBox(height: 10),
                    _buildFeatureItem(checkColor, textPrimary, l10n?.proFeature1 ?? 'Suggest rates, late fees and repayment terms'),
                    const SizedBox(height: 10),
                    _buildFeatureItem(checkColor, textPrimary, l10n?.proFeature2 ?? 'Advanced filters (income, employment, verified)'),
                    const SizedBox(height: 10),
                    _buildFeatureItem(checkColor, textPrimary, l10n?.proFeature3 ?? 'Verified badge, reliability score and priority visibility'),

                    const SizedBox(height: 22),

                    // "Choose Pro" Button
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
                        child: Text(
                          l10n?.choosePro ?? 'Choose Pro',
                          style: const TextStyle(
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
                  child: Text(
                    l10n?.notNow ?? 'Not now',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Legal / Security Caption ────────────────────────────────
              Text(
                l10n?.paymentSecurityDisclaimer ??
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
              fontSize: 12.5,
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
