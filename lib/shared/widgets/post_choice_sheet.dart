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
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n?.postChoiceTitle ?? 'What do you want to post?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
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
                leading: const Icon(
                  Icons.currency_exchange_rounded,
                  color: AppColors.success,
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
                leading: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFF59E0B),
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Material(
                  color: Color.alphaBlend(
                    theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    theme.colorScheme.surface,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(
                      Icons.business_center_outlined,
                      color: Color(0xFF3B82F6),
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
