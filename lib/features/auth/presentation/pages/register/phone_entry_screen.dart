// lib/features/auth/presentation/pages/register/phone_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../../../../core/constants/country_constants.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import 'shared.dart';

class PhoneEntryScreen extends StatelessWidget {
  const PhoneEntryScreen({super.key, 
    required this.formKey,
    required this.selectedCountry,
    required this.controller,
    required this.isLoading,
    required this.onCountryTap,
    required this.onBack,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final CountryInfo selectedCountry;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onCountryTap;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
    final cardBgColor =
        isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
    final cardBorderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Header: Back button + 3-step progress bar ────────────────
                    StepProgressHeader(onBack: onBack, currentStep: 1),
                    const SizedBox(height: 36),

                    // ── Titles ─────────────────────────────────────────────────
                    Text(
                      l10n.enterPhoneTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.enterPhoneSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Phone Input Field Card ─────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorderColor),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          // Country selector chip
                          GestureDetector(
                            onTap: onCountryTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedCountry.flag,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedCountry.dialCode,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: subtitleColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Vertical divider line
                          Container(
                            height: 28,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            color: cardBorderColor,
                          ),
                          // Phone input
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: titleColor,
                              ),
                              onFieldSubmitted: (_) => onNext(),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                hintText: '7XXXXXXXX',
                                hintStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  color: isDark
                                      ? const Color(0xFF4B5563)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 7) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Security Callout Card ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: AppColors.accentLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.phoneSafeTitle,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.phoneSafeSubtitle,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 24),

                    // ── Primary Action Button ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.accent.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const ButtonLoader()
                            : Text(
                                l10n.sendCode,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── 2. OTP ────────────────────────────────────────────────────────────────────
