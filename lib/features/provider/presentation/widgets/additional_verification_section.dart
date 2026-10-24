import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/repositories/provider_repository_interface.dart';

// ─── Additional Verification Section ──────────────────────────────────────────

class AdditionalVerificationSection extends StatefulWidget {
  const AdditionalVerificationSection({super.key});

  @override
  State<AdditionalVerificationSection> createState() =>
      _AdditionalVerificationSectionState();
}

class _AdditionalVerificationSectionState
    extends State<AdditionalVerificationSection> {
  List<ProviderCapability> _capabilities = [];
  bool _loading = true;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final repo = getIt<IProviderRepository>();
      final enabled = await repo.capabilityProfilesEnabled();
      final caps = enabled ? await repo.getProviderCapabilities() : const [];
      final byCategory = <String, ProviderCapability>{};
      for (final cap in caps) {
        if (cap.isWork ||
            cap.verificationPolicy !=
                ProviderVerificationPolicy.requiredProof) {
          continue;
        }
        final slug = cap.categorySlug;
        if (slug != null) byCategory.putIfAbsent(slug, () => cap);
      }
      if (mounted) {
        setState(() {
          _enabled = enabled;
          _capabilities = byCategory.values.toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    if (!_enabled && !_loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : AppColors.bg2Light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.additionalVerificationTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.additionalVerificationSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_capabilities.isNotEmpty) ...[
            ..._capabilities.map((cap) {
              final isVerified = cap.isVerified;
              final status = isVerified
                  ? l10n.providerVerified
                  : cap.pendingEvidenceCount > 0
                      ? l10n.providerCapabilityPendingReview
                      : cap.rejectedEvidenceCount > 0
                          ? l10n.providerCapabilityRejected
                          : l10n.providerPolicyProofRequired;
              final statusIcon = isVerified
                  ? Icons.check_circle_outline_rounded
                  : cap.pendingEvidenceCount > 0
                      ? Icons.schedule_rounded
                      : cap.rejectedEvidenceCount > 0
                          ? Icons.error_outline_rounded
                          : Icons.upload_file_outlined;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.push(
                    AppRoutes.accountServices,
                    extra: cap.capabilitySlug,
                  ),
                  child: Row(
                    children: [
                      Text(cap.categoryIcon ?? '💼',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cap.categoryName ??
                              cap.capabilityName ??
                              cap.capabilitySlug,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon,
                                size: 16,
                                color: isVerified
                                    ? AppColors.success
                                    : theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                status,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.additionalVerificationEmpty,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.business_center_outlined, size: 16),
              label: Text(l10n.manageProviderCapabilities),
              onPressed: () => context.push(AppRoutes.accountServices),
            ),
          ),
        ],
      ),
    );
  }
}
