import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

void showPostChoiceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                l10n?.postChoiceTitle ?? 'What do you want to post?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            // ── 1. Loan ──────────────────────────────────────────────────────
            _PostOptionTile(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF1E88E5),
              title: l10n?.postLoanAction ?? 'Loan',
              subtitle: l10n?.postLoanSubtitle ?? 'Create a loan request',
              onTap: () {
                Navigator.pop(sheetContext);
                context.go(AppRoutes.listingCreate);
              },
            ),
            // ── 2. Forex ─────────────────────────────────────────────────────
            _PostOptionTile(
              icon: Icons.currency_exchange_rounded,
              iconColor: const Color(0xFF10B981),
              title: l10n?.postForexAction ?? 'Forex',
              subtitle: l10n?.postForexSubtitle ??
                  'Create a currency exchange request',
              onTap: () {
                Navigator.pop(sheetContext);
                context.go(AppRoutes.forexCreate);
              },
            ),
            // ── 3. Need ──────────────────────────────────────────────────────
            _PostOptionTile(
              icon: Icons.search_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: l10n?.postNeedAction ?? 'Need',
              subtitle: l10n?.postNeedSubtitle ?? 'Create a Need',
              onTap: () {
                Navigator.pop(sheetContext);
                context.go(AppRoutes.needsCreate);
              },
            ),
            // ── 4. Offer a Service (Highlighted card) ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Material(
                color: isDark ? AppColors.bg3Dark : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(AppRoutes.accountServices);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.business_center_outlined,
                          color: Color(0xFF1E88E5),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.postServiceAction ?? 'Offer a Service',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.5,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n?.postServiceSubtitle ??
                                    'List your services and get matched with client requests',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.text2Dark
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PostOptionTile extends StatelessWidget {
  const _PostOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.text2Dark
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
