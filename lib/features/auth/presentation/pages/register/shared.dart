// lib/features/auth/presentation/pages/register/shared.dart

import 'package:flutter/material.dart';


import '../../../../../core/services/language_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../widgets/language_selector_sheet.dart';

class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class StepProgressHeader extends StatelessWidget {
  const StepProgressHeader({super.key, 
    required this.onBack,
    required this.currentStep,
  });

  final VoidCallback onBack;
  final int currentStep;
  static const int totalSteps = 3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final stepNumber = index + 1;
              final isActive = stepNumber == currentStep;
              return Container(
                width: 32,
                height: 4,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accent
                      : (isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
        ValueListenableBuilder<Locale?>(
          valueListenable: LanguageService.instance.notifier,
          builder: (context, _, __) {
            final currentLang = LanguageService.instance.currentLanguage;
            final cardBgColor =
                isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
            final cardBorderColor =
                isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
            final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final subtitleColor =
                isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
            return GestureDetector(
              onTap: () => showLanguageSelectorSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currentLang.flag,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 3),
                    Text(
                      currentLang.code.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: subtitleColor,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class ButtonLoader extends StatelessWidget {
  const ButtonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}

