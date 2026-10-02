// lib/features/provider/presentation/widgets/capability_badge.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/provider_capability.dart';
import 'provider_verification_chip.dart';

class CapabilityBadge extends StatelessWidget {
  const CapabilityBadge({
    super.key,
    required this.capability,
    this.phoneVerified = false,
    this.identityVerified = false,
    this.opportunityCount,
    this.onRemove,
  });

  final ProviderCapability capability;
  final bool phoneVerified;
  final bool identityVerified;
  final int? opportunityCount;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text2 = isDark ? AppColors.text2Dark : AppColors.text2Light;

    final icon = capability.categoryIcon ?? '🔧';
    final name = _capabilityDisplayName(
      capability.capabilitySlug,
      capability.capabilityName ?? capability.capabilitySlug,
      l10n,
    );
    final category = capability.categoryName ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
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
                Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(fontSize: 12, color: text2),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ProviderVerificationChip(
                      level: capability.verificationLevel,
                      phoneVerified: phoneVerified,
                      identityVerified: identityVerified,
                    ),
                    if (opportunityCount != null && opportunityCount! > 0)
                      _OpportunityPill(count: opportunityCount!, l10n: l10n),
                  ],
                ),
                if (capability.capabilitySlug == 'i_have_an_audience') ...[
                  const SizedBox(height: 8),
                  _DeclaredAudience(capability: capability, l10n: l10n),
                ],
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: text2,
              tooltip: l10n.removeService,
              onPressed: onRemove,
            ),
        ],
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

String _platformLabel(String slug, AppLocalizations l10n) => switch (slug) {
      'tiktok' => l10n.audiencePlatformTikTok,
      'instagram' => l10n.audiencePlatformInstagram,
      'youtube' => l10n.audiencePlatformYouTube,
      'facebook' => l10n.audiencePlatformFacebook,
      'whatsapp' => l10n.audiencePlatformWhatsApp,
      _ => l10n.audiencePlatformOther,
    };

String _capabilityDisplayName(
  String slug,
  String fallback,
  AppLocalizations l10n,
) => switch (slug) {
      'marketing_services' => l10n.marketingAndPromotion,
      'social_media_marketing' => l10n.socialMediaMarketing,
      'tiktok_promotion' => l10n.tiktokPromotion,
      'instagram_promotion' => l10n.instagramPromotion,
      'youtube_promotion' => l10n.youtubePromotion,
      'facebook_promotion' => l10n.facebookPromotion,
      'influencer_marketing' => l10n.influencerMarketing,
      'content_creation' => l10n.contentCreation,
      'product_reviews' => l10n.productReviews,
      'event_promotion' => l10n.eventPromotion,
      'whatsapp_community_promotion' => l10n.whatsAppCommunityPromotion,
      'affiliate_marketing' => l10n.affiliateMarketing,
      'advertising_campaigns' => l10n.advertisingCampaigns,
      'brand_promotion' => l10n.brandPromotion,
      'other_marketing_services' => l10n.otherMarketingServices,
      'i_have_an_audience' => l10n.iHaveAnAudience,
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
