// lib/features/provider/presentation/pages/capability_detail_sheet.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
    this.hiddenForCompanyOnly = false,
  });

  final ProviderCapability capability;
  final int opportunityCount;
  final VoidCallback onEdit;
  final ValueChanged<bool> onTogglePause;
  final VoidCallback onRemove;
  final bool hiddenForCompanyOnly;

  static Future<void> show(
    BuildContext context, {
    required ProviderCapability capability,
    int opportunityCount = 0,
    required VoidCallback onEdit,
    required ValueChanged<bool> onTogglePause,
    required VoidCallback onRemove,
    bool hiddenForCompanyOnly = false,
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
        hiddenForCompanyOnly: hiddenForCompanyOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Hidden: offered as Company only',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.text2Light)),
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
                      onAddProof: onEdit,
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
  });

  final ProviderCapability capability;
  final VoidCallback? onAddProof;

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
      if (claims.isNotEmpty) {
        for (final c in claims) {
          final qName = c['qualification_name']?.toString() ?? 'Qualification';
          final st = c['status']?.toString();
          if (st == 'verified') {
            items.add(_ChecklistItem(
              title: qName,
              icon: Icons.check_circle_rounded,
              iconColor: AppColors.success,
              subtitle: 'Approved',
            ));
          } else if (st == 'pending_review') {
            items.add(_ChecklistItem(
              title: qName,
              icon: Icons.schedule_rounded,
              iconColor: Colors.amber.shade800,
              subtitle: 'Under review, usually within 2 days',
            ));
          } else {
            items.add(_ChecklistItem(
              title: qName,
              icon: Icons.add_circle_outline_rounded,
              iconColor: Colors.grey,
              subtitle: 'Self-declared',
              trailingAction: 'Add proof',
            ));
          }
        }
      } else {
        // Canonical defaults matching Screen G
        items.addAll([
          _ChecklistItem(
            title: 'Operator licence',
            icon: Icons.schedule_rounded,
            iconColor: Colors.amber.shade800,
            subtitle: 'Under review, usually within 2 days',
          ),
          const _ChecklistItem(
            title: 'Safety / OSHA certificate',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            subtitle: 'Approved',
          ),
          const _ChecklistItem(
            title: '3+ years experience',
            icon: Icons.add_circle_outline_rounded,
            iconColor: Colors.grey,
            subtitle: 'Self-declared',
            trailingAction: 'Add proof',
          ),
          const _ChecklistItem(
            title: 'Medical fitness',
            icon: Icons.add_circle_outline_rounded,
            iconColor: Colors.grey,
            subtitle: 'Not added yet',
            trailingAction: 'Add',
          ),
          const _ChecklistItem(
            title: 'Can work away from home',
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            subtitle: 'Self-declared, no proof needed',
          ),
        ]);
      }
    } else {
      items.add(
        _ChecklistItem(
          title: 'Professional Evidence & Certificates',
          icon: isVerified
              ? Icons.check_circle_rounded
              : Icons.add_circle_outline_rounded,
          iconColor: isVerified ? AppColors.success : Colors.grey,
          subtitle: isVerified
              ? 'Documents reviewed and approved by Nipanze'
              : 'Add licences, logbooks, or trade qualifications',
          trailingAction: isVerified ? null : 'Add proof',
        ),
      );
    }

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
              item.icon,
              size: 20,
              color: item.iconColor,
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              item.subtitle,
              style: TextStyle(fontSize: 11, color: text2),
            ),
            trailing: item.trailingAction != null
                ? InkWell(
                    onTap: onAddProof,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Text(
                        item.trailingAction!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.proPurple,
                        ),
                      ),
                    ),
                  )
                : null,
          );
        }).toList(),
      ),
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
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  final String? trailingAction;
}
