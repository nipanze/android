// lib/features/auth/presentation/widgets/language_selector_sheet.dart
import 'package:flutter/material.dart';
import '../../../../core/services/language_service.dart';

/// Shows a bottom sheet allowing the user to switch the app language dynamically.
void showLanguageSelectorSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final sheetBg = isDark ? const Color(0xFF0F101C) : Colors.white;
  final cardBg = isDark ? const Color(0xFF181928) : const Color(0xFFF1F5F9);
  final cardBorder = isDark ? const Color(0xFF28293D) : const Color(0xFFE2E8F0);
  final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
  final subtitleColor = isDark ? const Color(0xFF9E9EB8) : const Color(0xFF64748B);
  const purpleColor = Color(0xFF7C3AED);

  final currentCode = LanguageService.instance.locale?.languageCode ??
      Localizations.localeOf(context).languageCode;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: cardBorder, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D42) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header Text
            Text(
              'Select Language',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose your preferred language',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 20),

            // List of languages
            ...LanguageService.supportedLanguages.map((lang) {
              final isSelected = lang.code == currentCode;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    LanguageService.instance.setLanguage(lang.code);
                    Navigator.of(sheetContext).pop();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? purpleColor.withValues(alpha: 0.12)
                          : cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? purpleColor
                            : cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          lang.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.nativeName,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                              Text(
                                lang.name,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: purpleColor,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}
