// lib/shared/widgets/post_duration_info_card.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Informational card displaying how long a request post will remain active
/// before it automatically expires, matching Nipanze's primary brand style.
class PostDurationInfoCard extends StatelessWidget {
  const PostDurationInfoCard({
    super.key,
    required this.durationDays,
    this.compact = false,
  });

  /// Duration in days the post stays active.
  final int durationDays;

  /// If true, renders a more condensed version for dialogs or tight sheets.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = isDark
        ? AppColors.bg2Dark
        : theme.colorScheme.surface;
    final borderColor = isDark
        ? AppColors.borderDark
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_rounded,
              size: 16,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.postDurationFullNotice(durationDays) ??
                      'Your request will be active for $durationDays days.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n?.postDurationNotice ??
                        'Your request will automatically expire after this period.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

