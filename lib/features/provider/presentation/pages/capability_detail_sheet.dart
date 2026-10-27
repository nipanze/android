// lib/features/provider/presentation/pages/capability_detail_sheet.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_category_type.dart';
import '../widgets/provider_verification_chip.dart';

class CapabilityDetailSheet extends StatelessWidget {
  const CapabilityDetailSheet({
    super.key,
    required this.capability,
    this.opportunityCount = 0,
    required this.onEdit,
    required this.onTogglePause,
    required this.onRemove,
    this.onAddProof,
    this.onAddRoleProof,
    this.onRemoveRoleProof,
    this.hiddenForCompanyOnly = false,
    this.providerType,
  });

  final ProviderCapability capability;
  final int opportunityCount;
  final VoidCallback onEdit;
  final ValueChanged<bool> onTogglePause;
  final VoidCallback onRemove;
  final VoidCallback? onAddProof;
  final void Function(String? roleSlug, String? qualificationSlug)?
      onAddRoleProof;
  final void Function(String? roleSlug, String? qualificationSlug)?
      onRemoveRoleProof;
  final bool hiddenForCompanyOnly;
  final ProviderCategoryType? providerType;

  static Future<void> show(
    BuildContext context, {
    required ProviderCapability capability,
    int opportunityCount = 0,
    required VoidCallback onEdit,
    required ValueChanged<bool> onTogglePause,
    required VoidCallback onRemove,
    VoidCallback? onAddProof,
    void Function(String? roleSlug, String? qualificationSlug)? onAddRoleProof,
    void Function(String? roleSlug, String? qualificationSlug)?
        onRemoveRoleProof,
    bool hiddenForCompanyOnly = false,
    ProviderCategoryType? providerType,
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
        onAddProof: onAddProof,
        onAddRoleProof: onAddRoleProof,
        onRemoveRoleProof: onRemoveRoleProof,
        hiddenForCompanyOnly: hiddenForCompanyOnly,
        providerType: providerType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    final isJob = capability.isWork;
    final hasApprovedRoleProof = capability.roleQualificationClaims.any(
      (claim) => claim['status'] == 'verified' && claim['has_evidence'] == true,
    );
    final title = capability.capabilityName ?? capability.capabilitySlug;
    final category = capability.categoryName ?? '';
    final icon = capability.categoryIcon ?? (isJob ? '💼' : '🔧');

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              if (hiddenForCompanyOnly)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(l10n.providerTypeHiddenCompanyOnly,
                      style: TextStyle(fontSize: 12, color: text2)),
                ),

              // Header (matches Image G)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isJob
                            ? const Color(0xFFFEF3C7)
                            : AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isJob ? '👷' : icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Builder(builder: (ctx) {
                            final kindsFormatted = capability.kindIds
                                .map(_formatSlug)
                                .where((s) => s.isNotEmpty)
                                .join(', ');
                            final subtitleParts = [
                              if (category.isNotEmpty) category,
                              if (kindsFormatted.isNotEmpty) kindsFormatted,
                            ];
                            final subtitleText = subtitleParts.isNotEmpty
                                ? subtitleParts.join(' · ')
                                : (isJob ? 'Work Profile' : 'Service Profile');
                            return Text(
                              subtitleText,
                              style: TextStyle(fontSize: 12, color: text2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ProviderVerificationChip(
                      level: capability.verificationLevel,
                      status: capability.status,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (providerType != null || isJob)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.bg3Dark.withValues(alpha: 0.7)
                          : const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.providerTypeOfferingAs} ${isJob ? l10n.companyPersonalProfile : providerType == ProviderCategoryType.company ? l10n.providerTypeCompany : l10n.providerTypeIndividual}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: onEdit,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.providerTypeChange,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Open jobs / opportunities match banner (matches Image G)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: (isJob ? AppColors.proPurple : AppColors.accent)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isJob ? AppColors.proPurple : AppColors.accent)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        opportunityCount > 0
                            ? '$opportunityCount open ${isJob ? 'jobs' : 'needs'} match this profile'
                            : '3 open ${isJob ? 'jobs' : 'needs'} match this profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isJob ? AppColors.proPurple : AppColors.accent,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isJob ? AppColors.proPurple : AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Details summary: Verification checklist section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHAT IS NEEDED FOR THE VERIFIED BADGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: text2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _VerificationChecklist(
                      capability: capability,
                      onAddProof: onAddProof,
                      onAddRoleProof: isJob && !capability.isVerified
                          ? onAddRoleProof
                          : null,
                      onRemoveRoleProof: isJob && !capability.isVerified
                          ? onRemoveRoleProof
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons matching Image 2 Screen G
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isJob ? AppColors.proPurple : AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit();
                      },
                      child: Text(
                        isJob ? 'Edit work profile' : 'Edit',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (hasApprovedRoleProof && !capability.isPaused)
                          const Expanded(
                            child: Text(
                              'Approved proof · this role stays active',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onTogglePause(!capability.isPaused);
                            },
                            child: Text(
                              capability.isPaused
                                  ? 'Resume'
                                  : (isJob
                                      ? 'Pause jobs for this role'
                                      : 'Pause service'),
                              style: TextStyle(color: text2, fontSize: 13),
                            ),
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onRemove();
                          },
                          child: const Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
  const _VerificationChecklist({
    required this.capability,
    this.onAddProof,
    this.onAddRoleProof,
    this.onRemoveRoleProof,
  });

  final ProviderCapability capability;
  final VoidCallback? onAddProof;
  final void Function(String? roleSlug, String? qualificationSlug)?
      onAddRoleProof;
  final void Function(String? roleSlug, String? qualificationSlug)?
      onRemoveRoleProof;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderLight;
    final text2 = Theme.of(context).brightness == Brightness.dark
        ? AppColors.text2Dark
        : AppColors.text2Light;

    final isVerified = capability.isVerified;
    final claims = capability.roleQualificationClaims;
    final isJob = capability.isWork;

    final items = <_ChecklistItem>[];
    if (isJob) {
      final evidenceClaims =
          claims.where((claim) => claim['is_evidence'] == true).toList();
      if (evidenceClaims.isNotEmpty) {
        for (final c in evidenceClaims) {
          final qName = c['qualification_name']?.toString() ?? 'Qualification';
          final roleSlug = c['role_slug']?.toString() ?? '';
          final qualificationSlug = c['qualification_slug']?.toString() ?? '';
          final st = c['status']?.toString();
          final hasEvidence = c['has_evidence'] == true;
          final statusLabel = switch (st) {
            'verified' => AppLocalizations.of(context)!.companyEvidenceApproved,
            'pending_review' =>
              AppLocalizations.of(context)!.companyVerificationPending,
            'rejected' => AppLocalizations.of(context)!.companyEvidenceRejected,
            'expired' => AppLocalizations.of(context)!.companyEvidenceExpired,
            _ => hasEvidence
                ? AppLocalizations.of(context)!.companyEvidenceUploaded
                : AppLocalizations.of(context)!.companyEvidenceNotAdded,
          };
          final rejectReason = c['reject_reason']?.toString();
          final actionLabel = hasEvidence
              ? AppLocalizations.of(context)!.companyEvidenceReplace
              : AppLocalizations.of(context)!.companyEvidenceAdd;
          if (st == 'verified') {
            items.add(_ChecklistItem(
              title: qName,
              icon: Icons.check_circle_rounded,
              iconColor: AppColors.success,
              subtitle: statusLabel,
            ));
          } else if (st == 'pending_review') {
            items.add(_ChecklistItem(
              title: qName,
              icon: Icons.schedule_rounded,
              iconColor: Colors.amber.shade800,
              subtitle: statusLabel,
              trailingAction: actionLabel,
              onAction: onAddRoleProof == null
                  ? null
                  : () => onAddRoleProof!(roleSlug, qualificationSlug),
              onRemove: hasEvidence && onRemoveRoleProof != null
                  ? () => onRemoveRoleProof!(roleSlug, qualificationSlug)
                  : null,
            ));
          } else {
            items.add(_ChecklistItem(
              title: qName,
              icon: st == 'rejected'
                  ? Icons.error_outline_rounded
                  : Icons.add_circle_outline_rounded,
              iconColor: st == 'rejected'
                  ? Theme.of(context).colorScheme.error
                  : Colors.grey,
              subtitle: rejectReason == null
                  ? statusLabel
                  : '$statusLabel · $rejectReason',
              trailingAction: onAddRoleProof == null ? null : actionLabel,
              onAction: onAddRoleProof == null
                  ? null
                  : () => onAddRoleProof!(roleSlug, qualificationSlug),
              onRemove: hasEvidence && onRemoveRoleProof != null
                  ? () => onRemoveRoleProof!(roleSlug, qualificationSlug)
                  : null,
            ));
          }
        }
      } else {
        items.add(_ChecklistItem(
          title: 'Role details',
          icon: capability.pendingEvidenceCount > 0
              ? Icons.schedule_rounded
              : Icons.info_outline_rounded,
          iconColor: capability.pendingEvidenceCount > 0
              ? Colors.amber.shade800
              : text2,
          subtitle: capability.pendingEvidenceCount > 0
              ? '${capability.pendingEvidenceCount} evidence item(s) pending review'
              : AppLocalizations.of(context)!.providerCapabilityActive,
          trailingAction: isVerified
              ? null
              : AppLocalizations.of(context)!.companyEvidenceAdd,
          onAction: onAddRoleProof == null
              ? null
              : () => onAddRoleProof!(
                    null,
                    null,
                  ),
        ));
      }
    } else {
      items.add(
        _ChecklistItem(
          title: capability.capabilityName ?? capability.capabilitySlug,
          icon: isVerified
              ? Icons.check_circle_rounded
              : Icons.add_circle_outline_rounded,
          iconColor: isVerified ? AppColors.success : Colors.grey,
          subtitle: isVerified
              ? AppLocalizations.of(context)!.providerVerified
              : capability.pendingEvidenceCount > 0
                  ? AppLocalizations.of(context)!
                      .providerCapabilityPendingReview
                  : capability.rejectedEvidenceCount > 0
                      ? AppLocalizations.of(context)!.providerCapabilityRejected
                      : capability.verificationPolicy ==
                              ProviderVerificationPolicy.requiredProof
                          ? AppLocalizations.of(context)!
                              .providerPolicyProofRequired
                          : capability.verificationPolicy ==
                                  ProviderVerificationPolicy.optionalProof
                              ? AppLocalizations.of(context)!
                                  .providerPolicyProofLater
                              : AppLocalizations.of(context)!
                                  .providerPolicyProofLater,
          trailingAction: isVerified || onAddProof == null
              ? null
              : AppLocalizations.of(context)!.companyEvidenceAdd,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Column(
            children: items.map((item) {
              return ListTile(
                dense: true,
                leading: Icon(
                  item.icon,
                  size: 20,
                  color: item.iconColor,
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 11, color: text2),
                ),
                trailing: item.trailingAction != null || item.onRemove != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.trailingAction != null)
                            TextButton(
                              onPressed:
                                  item.onAction ?? (isJob ? null : onAddProof),
                              child: Text(item.trailingAction!),
                            ),
                          if (item.onRemove != null)
                            IconButton(
                              tooltip: AppLocalizations.of(context)!
                                  .companyDocumentRemove,
                              visualDensity: VisualDensity.compact,
                              onPressed: item.onRemove,
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      )
                    : null,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
    this.trailingAction,
    this.onAction,
    this.onRemove,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  final String? trailingAction;
  final VoidCallback? onAction;
  final VoidCallback? onRemove;
}
