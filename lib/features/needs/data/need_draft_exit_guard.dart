import 'package:flutter/material.dart';

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
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save this request as a draft?'),
        content: const Text(
          'Your request is not finished. Save it so you can resume later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'stay'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: const Text('Discard and exit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('Save draft and exit'),
          ),
        ],
      ),
    );
    if (choice == 'discard') return true;
    if (choice == 'save') return await _saveDraft?.call() ?? false;
    return false;
  }
}
