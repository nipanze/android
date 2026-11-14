import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Shares the active request editor's save action with shell navigation and
/// system-back handlers.
class NeedDraftExitGuard {
  static Object? _owner;
  static bool Function()? _hasChanges;
  static Future<bool> Function()? _saveDraft;

  static void register(
    Object owner, {
    required bool Function() hasChanges,
    required Future<bool> Function() saveDraft,
  }) {
    _owner = owner;
    _hasChanges = hasChanges;
    _saveDraft = saveDraft;
  }

  static void unregister(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _hasChanges = null;
    _saveDraft = null;
  }

  static Future<bool> confirmExit(BuildContext context) async {
    if (_hasChanges?.call() != true) return true;
    final l10n = AppLocalizations.of(context)!;
    final choice = await showPrompt(
      context: context,
      title: l10n.unsavedRequestTitle,
      message: l10n.unsavedRequestMessage,
    );
    if (choice == 'discard') return true;
    if (choice == 'save') return await _saveDraft?.call() ?? false;
    return false;
  }

  static Future<String?> showPrompt({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colors = theme.colorScheme;
        final l10n = AppLocalizations.of(dialogContext)!;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, 'save'),
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: Text(l10n.unsavedRequestSaveDraft),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, 'stay'),
                          child: Text(l10n.unsavedRequestStay),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, 'discard'),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.error,
                          ),
                          child: Text(l10n.unsavedRequestDiscard),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
