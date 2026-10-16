// lib/features/provider/presentation/widgets/capability_badge.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../needs/domain/models/need_capability.dart';
import '../../../needs/domain/models/need_category.dart';
import '../../domain/entities/provider_capability.dart';
import 'provider_verification_chip.dart';

class CapabilityBadge extends StatelessWidget {
  const CapabilityBadge({
    super.key,
    required this.capability,
    this.showProfileDetails = false,
    this.opportunityCount,
    this.onTap,
    this.onEdit,
    this.onTogglePause,
    this.onRemove,
  });

  final ProviderCapability capability;
  final bool showProfileDetails;
  final int? opportunityCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onTogglePause;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;
    final localeCode = Localizations.localeOf(context).languageCode;

    final isJob = capability.isWork;
    final icon = capability.categoryIcon ?? (isJob ? '💼' : '🔧');
    final capabilityFallback = NeedCapability(
      slug: capability.capabilitySlug,
      categorySlug: capability.categorySlug ?? '',
      name: capability.capabilityName ?? capability.capabilitySlug,
    ).localizedName(localeCode);
    final name = _capabilityDisplayName(
      capability.capabilitySlug,
      capabilityFallback,
      l10n,
    );
    final category = capability.categorySlug == null
        ? capability.categoryName ?? ''
        : NeedCategory(
            slug: capability.categorySlug!,
            name: capability.categoryName ?? capability.categorySlug!,
            icon: icon,
          ).localizedName(localeCode);

    // Compute one-line status note
    String statusNote;
    if (capability.status == ProviderCapabilityStatus.providerVerified) {
      statusNote = 'Verified by Nipanze';
    } else if (capability.status == ProviderCapabilityStatus.pendingReview) {
      statusNote = 'Documents submitted · Under review';
    } else if (capability.status == ProviderCapabilityStatus.rejected) {
      statusNote = capability.latestRejectReason ?? 'Evidence rejected · Tap to resubmit';
    } else if (capability.status == ProviderCapabilityStatus.expired) {
      statusNote = 'Verification expired · Resubmit proof';
    } else if (isJob && capability.qualificationIds.isNotEmpty) {
      statusNote = '${capability.qualificationIds.length} qualifications declared';
    } else {
      statusNote = 'Self-declared · Add proof to verify';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isJob ? Colors.purple : AppColors.accent)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag & Category
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
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(fontSize: 12, color: text2),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (isJob && capability.kindIds.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: capability.kindIds.take(3).map((k) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: border.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatSlug(k),
                                style: TextStyle(
                                    fontSize: 11, color: text2),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ProviderVerificationChip(
                            level: capability.verificationLevel,
                            status: capability.status,
                          ),
                          if (opportunityCount != null && opportunityCount! > 0)
                            _OpportunityPill(
                                count: opportunityCount!, l10n: l10n),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusNote,
                        style: TextStyle(
                          fontSize: 11,
                          color: text2,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (capability.capabilitySlug == 'i_have_an_audience') ...[
                        const SizedBox(height: 8),
                        _DeclaredAudience(capability: capability, l10n: l10n),
                      ],
                      if (capability.metadata['institution'] != null ||
                          capability.metadata['role'] != null) ...[
                        const SizedBox(height: 6),
                        _DeclaredOrganisation(capability: capability),
                      ],
                      if (showProfileDetails) ...[
                        const SizedBox(height: 8),
                        _CapabilityProfileSummary(capability: capability),
                      ],
                    ],
                  ),
                ),
                // Three-dot menu or remove button
                if (onEdit != null || onTogglePause != null || onRemove != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: text2, size: 20),
                    padding: EdgeInsets.zero,
                    onSelected: (val) {
                      if (val == 'edit' && onEdit != null) onEdit!();
                      if (val == 'pause' && onTogglePause != null) {
                        onTogglePause!(!capability.isPaused);
                      }
                      if (val == 'remove' && onRemove != null) onRemove!();
                    },
                    itemBuilder: (ctx) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onTogglePause != null)
                        PopupMenuItem(
                          value: 'pause',
                          child: Row(
                            children: [
                              Icon(
                                capability.isPaused
                                    ? Icons.play_arrow_outlined
                                    : Icons.pause_circle_outline,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(capability.isPaused
                                  ? 'Resume'
                                  : (isJob ? 'Pause jobs' : 'Pause')),
                            ],
                          ),
                        ),
                      if (onRemove != null)
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Text(
                                l10n.removeService,
                                style:
                                    const TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                else if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: text2,
                    tooltip: l10n.removeService,
                    onPressed: onRemove,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CapabilityProfileSummary extends StatelessWidget {
  const _CapabilityProfileSummary({required this.capability});

  final ProviderCapability capability;

  @override
  Widget build(BuildContext context) {
    final metadata = capability.metadata;
    final engagements = capability.engagements;
    final roles = capability.roles;
    final details = <String>[
      if (engagements.contains('service')) 'Provides service',
      if (engagements.contains('work')) 'Available for jobs',
      if (metadata['years_experience'] != null)
        '${metadata['years_experience']} experience',
      if (metadata['availability'] != null) metadata['availability'].toString(),
      if (metadata['willing_to_travel'] == true) 'Willing to travel',
    ];

    final roleLabels = roles
        .map((role) {
          final roleId = role['role_id']?.toString();
          final kinds = (role['kind_ids'] as List? ?? const [])
              .map((kind) => kind.toString())
              .join(', ');
          if (roleId == null || roleId.isEmpty) return null;
          return kinds.isEmpty
              ? _formatSlug(roleId)
              : '${_formatSlug(roleId)}: $kinds';
        })
        .whereType<String>()
        .toList();

    final qualificationLabels = capability.roleQualificationClaims.map((claim) {
      final name = claim['qualification_name']?.toString() ??
          _formatSlug(claim['qualification_slug']?.toString() ?? '');
      final status = switch (claim['status']) {
        'pending_review' => 'Nipanze review pending',
        'verified' => 'Nipanze verified',
        'rejected' => 'Evidence rejected',
        'expired' => 'Verification expired',
        _ => 'Self-declared',
      };
      return '$name · $status';
    }).toList();

    final evidenceParts = <String>[
      if (capability.pendingEvidenceCount > 0)
        '${capability.pendingEvidenceCount} pending',
      if (capability.approvedEvidenceCount > 0)
        '${capability.approvedEvidenceCount} approved',
      if (capability.rejectedEvidenceCount > 0)
        '${capability.rejectedEvidenceCount} rejected',
      if (capability.expiredEvidenceCount > 0)
        '${capability.expiredEvidenceCount} expired',
    ];

    if (details.isEmpty &&
        roleLabels.isEmpty &&
        qualificationLabels.isEmpty &&
        evidenceParts.isEmpty &&
        capability.latestRejectReason == null) {
      return const SizedBox.shrink();
    }

    final text2 =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.isNotEmpty)
          Text(
            details.join(' · '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: text2,
                ),
          ),
        if (roleLabels.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            roleLabels.join(' · '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: text2,
                ),
          ),
        ],
        if (qualificationLabels.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            'Qualifications: ${qualificationLabels.join(' · ')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: text2,
                ),
          ),
        ],
        if (evidenceParts.isNotEmpty) ...[
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final part in evidenceParts) _MiniPill(label: part),
            ],
          ),
        ],
        if (capability.latestRejectReason != null &&
            capability.latestRejectReason!.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            capability.latestRejectReason!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                ),
          ),
        ],
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _DeclaredAudience extends StatelessWidget {
  const _DeclaredAudience({required this.capability, required this.l10n});

  final ProviderCapability capability;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final metadata = capability.metadata;
    final platforms = (metadata['audience_platforms'] as List? ?? const [])
        .map((platform) => _platformLabel(platform.toString(), l10n))
        .join(', ');
    final count = metadata['audience_followers_count']?.toString();
    final location = metadata['audience_main_location']?.toString();
    final interest = metadata['audience_main_interest']?.toString();
    final details = <String>[
      if (platforms.isNotEmpty) platforms,
      if (count != null && count.isNotEmpty)
        '${l10n.audienceFollowersMembersCount}: $count',
      if (location != null && location.isNotEmpty)
        '${l10n.audienceMainLocation}: $location',
      if (interest != null && interest.isNotEmpty)
        '${l10n.audienceMainInterest}: $interest',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.declaredAudience,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            details.join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _DeclaredOrganisation extends StatelessWidget {
  const _DeclaredOrganisation({required this.capability});

  final ProviderCapability capability;

  @override
  Widget build(BuildContext context) {
    final metadata = capability.metadata;
    final institution = metadata['institution']?.toString();
    final role = metadata['role']?.toString();
    final parts = <String>[
      if (institution != null && institution.isNotEmpty) institution,
      if (role != null && role.isNotEmpty) role,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.business_outlined, size: 13, color: AppColors.accent),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _platformLabel(String slug, AppLocalizations l10n) => switch (slug) {
      'tiktok' => l10n.audiencePlatformTikTok,
      'instagram' => l10n.audiencePlatformInstagram,
      'youtube' => l10n.audiencePlatformYouTube,
      'facebook' => l10n.audiencePlatformFacebook,
      'whatsapp' => l10n.audiencePlatformWhatsApp,
      _ => l10n.audiencePlatformOther,
    };

String _formatSlug(String slug) => slug
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _capabilityDisplayName(
  String slug,
  String fallback,
  AppLocalizations l10n,
) =>
    switch (slug) {
      // Marketing
      'marketing_services' => l10n.marketingAndPromotion,
      'social_media_marketing' => l10n.socialMediaMarketing,
      'influencer_marketing' => l10n.influencerMarketing,
      'content_creation' => l10n.contentCreation,
      'product_reviews' => l10n.productReviews,
      'event_promotion' => l10n.eventPromotion,
      'affiliate_marketing' => l10n.affiliateMarketing,
      'advertising_campaigns' => l10n.advertisingCampaigns,
      'brand_promotion' => l10n.brandPromotion,
      'other_marketing_services' => l10n.otherMarketingServices,
      'i_have_an_audience' => l10n.iHaveAnAudience,
      // Financial Services
      'bank_loan_agent' => l10n.bankLoanAgentCapability,
      'money_lender_private_lender' => l10n.moneyLenderPrivateLenderCapability,
      'financial_advisory' => l10n.financialAdvisoryCapability,
      'forex_currency_exchange' => l10n.forexCurrencyExchangeCapability,
      'loan_services' => l10n.loanServicesCapability,
      'sacco_microfinance' => l10n.saccoMicrofinanceCapability,
      'other_financial_services' => l10n.otherFinancialServicesCapability,
      _ => fallback,
    };

class _OpportunityPill extends StatelessWidget {
  const _OpportunityPill({required this.count, required this.l10n});
  final int count;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        l10n.opportunitiesCount(count),
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
