// lib/features/provider/presentation/pages/capability_detail_sheet.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/provider_capability.dart';
import '../widgets/provider_verification_chip.dart';

class CapabilityDetailSheet extends StatelessWidget {
  const CapabilityDetailSheet({
    super.key,
    required this.capability,
    this.opportunityCount = 0,
    required this.onEdit,
    required this.onTogglePause,
    required this.onRemove,
  });

  final ProviderCapability capability;
  final int opportunityCount;
  final VoidCallback onEdit;
  final ValueChanged<bool> onTogglePause;
  final VoidCallback onRemove;

  static Future<void> show(
    BuildContext context, {
    required ProviderCapability capability,
    int opportunityCount = 0,
    required VoidCallback onEdit,
    required ValueChanged<bool> onTogglePause,
    required VoidCallback onRemove,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CapabilityDetailSheet(
        capability: capability,
        opportunityCount: opportunityCount,
        onEdit: onEdit,
        onTogglePause: onTogglePause,
        onRemove: onRemove,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    final isJob = capability.isWork;
    final title = capability.capabilityName ?? capability.capabilitySlug;
    final category = capability.categoryName ?? '';
    final icon = capability.categoryIcon ?? (isJob ? '💼' : '🔧');

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (isJob ? Colors.purple : AppColors.accent)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isJob
                                  ? Colors.purple.withValues(alpha: 0.15)
                                  : AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isJob ? 'Job' : 'Service',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    isJob ? Colors.purple : AppColors.accent,
                              ),
                            ),
                          ),
                          if (category.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              category,
                              style: TextStyle(fontSize: 12, color: text2),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ProviderVerificationChip(
                        level: capability.verificationLevel,
                        status: capability.status,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: text2,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Open jobs / opportunities match banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isJob ? Colors.purple : AppColors.accent)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isJob ? Colors.purple : AppColors.accent)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.work_outline_rounded,
                    size: 18,
                    color: isJob ? Colors.purple : AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opportunityCount > 0
                        ? '$opportunityCount open ${isJob ? 'jobs' : 'needs'} match this profile'
                        : 'No open ${isJob ? 'jobs' : 'needs'} matching right now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isJob ? Colors.purple : AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isJob && capability.kindIds.isNotEmpty) ...[
                  Text(
                    'Kinds & Equipment',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: text2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: capability.kindIds.map((k) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: border.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatSlug(k),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Verification checklist section
                Text(
                  'What is needed for the verified badge',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _VerificationChecklist(capability: capability),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          capability.isPaused
                              ? Icons.play_arrow_outlined
                              : Icons.pause_circle_outline,
                          size: 18,
                        ),
                        label: Text(
                          capability.isPaused
                              ? 'Resume'
                              : (isJob ? 'Pause jobs' : 'Pause'),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onTogglePause(!capability.isPaused);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.redAccent),
                  label: Text(
                    l10n.removeService,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onRemove();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatSlug(String slug) {
    return slug
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}

class _VerificationChecklist extends StatelessWidget {
  const _VerificationChecklist({required this.capability});

  final ProviderCapability capability;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    final isVerified = capability.isVerified;
    final claims = capability.roleQualificationClaims;
    final pendingCount = capability.pendingEvidenceCount;

    final items = <_ChecklistItem>[
      const _ChecklistItem(
        title: 'ID & Account KYC',
        state: _ChecklistState.approved,
        subtitle: 'Verified through national ID / KYC review',
      ),
      if (claims.isNotEmpty)
        ...claims.map((c) {
          final qName = c['qualification_name']?.toString() ?? 'Qualification';
          final st = c['status']?.toString();
          final state = switch (st) {
            'verified' => _ChecklistState.approved,
            'pending_review' => _ChecklistState.underReview,
            'rejected' => _ChecklistState.rejected,
            _ => _ChecklistState.selfDeclared,
          };
          return _ChecklistItem(
            title: qName,
            state: state,
            subtitle: c['reject_reason']?.toString(),
          );
        })
      else
        _ChecklistItem(
          title: 'Professional Evidence & Certificates',
          state: isVerified
              ? _ChecklistState.approved
              : pendingCount > 0
                  ? _ChecklistState.underReview
                  : _ChecklistState.notAdded,
          subtitle: isVerified
              ? 'Documents reviewed and approved by Nipanze'
              : pendingCount > 0
                  ? 'Document submitted, pending admin review'
                  : 'Add licences, logbooks, or trade qualifications',
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        children: items.map((item) {
          return ListTile(
            dense: true,
            leading: Icon(
              item.state.icon,
              size: 20,
              color: item.state.color,
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: item.subtitle != null
                ? Text(item.subtitle!,
                    style: TextStyle(fontSize: 11, color: text2))
                : null,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.state.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.state.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: item.state.color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum _ChecklistState {
  underReview(Icons.hourglass_empty_rounded, Colors.orange, 'Under review'),
  approved(Icons.check_circle_rounded, Colors.green, 'Approved'),
  selfDeclared(Icons.person_outline_rounded, Colors.blueGrey, 'Self-declared'),
  rejected(Icons.error_outline_rounded, Colors.redAccent, 'Rejected'),
  notAdded(Icons.add_circle_outline_rounded, Colors.grey, 'Not added');

  const _ChecklistState(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}

class _ChecklistItem {
  const _ChecklistItem({
    required this.title,
    required this.state,
    this.subtitle,
  });

  final String title;
  final _ChecklistState state;
  final String? subtitle;
}

