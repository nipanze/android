// lib/features/auth/presentation/pages/register/otp_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../../../../core/theme/app_theme.dart';
import 'shared.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key, 
    required this.phone,
    required this.isReturningUser,
    required this.controllers,
    required this.focusNodes,
    required this.isLoading,
    required this.resendSeconds,
    required this.errorMsg,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
  });

  final String phone;
  final bool isReturningUser;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isLoading;
  final int resendSeconds;
  final String? errorMsg;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Header: Back button + Step 2 indicator ─────────────────
                  StepProgressHeader(onBack: onBack, currentStep: 2),
                  const SizedBox(height: 36),

                  // ── Titles ─────────────────────────────────────────────────
                  Text(
                    isReturningUser ? 'Welcome back 👋' : 'Verify your number',
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
                    'Enter the 6-digit code sent to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone.isNotEmpty ? phone : '+256 7XX XXX XXX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Demo hint ─────────────────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text(
                          'Demo mode: default OTP is 123456 (pre-filled).',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── 6-Digit OTP Box Row ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (i) => OtpBox(
                        controller: controllers[i],
                        focusNode: focusNodes[i],
                        nextFocus: i < 5 ? focusNodes[i + 1] : null,
                        prevFocus: i > 0 ? focusNodes[i - 1] : null,
                        onComplete: i == 5 ? onVerify : null,
                      ),
                    ),
                  ),

                  if (errorMsg != null) ...[
                    const SizedBox(height: 16),
                    ErrorBanner(message: errorMsg!),
                  ],

                  const SizedBox(height: 32),

                  // ── Resend Code Countdown Line ─────────────────────────────
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                      children: [
                        const TextSpan(text: "Didn't receive code? "),
                        if (resendSeconds > 0) ...[
                          const TextSpan(
                            text: 'Resend',
                            style: TextStyle(
                              color: AppColors.accentLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' in 00:${resendSeconds.toString().padLeft(2, '0')}',
                            style: TextStyle(color: subtitleColor),
                          ),
                        ] else ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: onResend,
                              child: const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: AppColors.accentLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                      onPressed: isLoading ? null : onVerify,
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
                          : const Text(
                              'Verify & Continue',
                              style: TextStyle(
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
        );
      },
    );
  }
}

// OTP single box with dynamic focus & border highlights
class OtpBox extends StatelessWidget {
  const OtpBox({super.key, 
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    this.prevFocus,
    this.onComplete,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final FocusNode? prevFocus;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBgColor =
        isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
    final cardBorderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        final hasValue = controller.text.isNotEmpty;
        final isActive = isFocused || hasValue;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 58,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? AppColors.accent : cardBorderColor,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              cursorColor: AppColors.accent,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
              onChanged: (v) {
                if (v.length == 1) {
                  if (nextFocus != null) {
                    nextFocus!.requestFocus();
                  } else {
                    onComplete?.call();
                  }
                } else if (v.isEmpty && prevFocus != null) {
                  prevFocus!.requestFocus();
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ── 3. Profile Setup ──────────────────────────────────────────────────────────
