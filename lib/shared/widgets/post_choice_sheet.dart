import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

void showPostChoiceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final optionTitleStyle = theme.textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w600,
  );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
          bottom: Radius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  l10n?.postChoiceTitle ?? 'What do you want to post?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                title: Text(
                  l10n?.postLoanAction ?? 'Loan',
                  style: optionTitleStyle,
                ),
                subtitle: Text(
                  l10n?.postLoanSubtitle ?? 'Create a loan request',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.listingCreate);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.currency_exchange_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                title: Text(
                  l10n?.postForexAction ?? 'Forex',
                  style: optionTitleStyle,
                ),
                subtitle: Text(
                  l10n?.postForexSubtitle ??
                      'Create a currency exchange request',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.forexCreate);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                ),
                title: Text(
                  l10n?.postNeedAction ?? 'Need',
                  style: optionTitleStyle,
                ),
                subtitle: Text(
                  l10n?.postNeedSubtitle ?? 'Create a Need',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.needsCreate);
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Material(
                  color: Color.alphaBlend(
                    theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    theme.colorScheme.surface,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.business_center_outlined,
                        color: Color(0xFF3B82F6),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      l10n?.postServiceAction ?? 'Offer a Service',
                      style: optionTitleStyle,
                    ),
                    subtitle: Text(
                      l10n?.postServiceSubtitle ??
                          'List your services and get matched with client requests',
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push(AppRoutes.accountServices);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
