// lib/features/provider/domain/entities/provider_opportunity.dart

class ProviderOpportunity {
  const ProviderOpportunity({
    required this.capabilitySlug,
    required this.opportunityCount,
    this.capabilityName,
    this.categorySlug,
    this.categoryName,
    this.categoryIcon,
  });

  factory ProviderOpportunity.fromMap(Map<String, dynamic> map) {
    return ProviderOpportunity(
      capabilitySlug: map['capability_slug'] as String? ?? '',
      opportunityCount: (map['opportunity_count'] as num?)?.toInt() ??
          (map['open_needs_count'] as num?)?.toInt() ??
          0,
      capabilityName: map['capability_name'] as String?,
      categorySlug: map['category_slug'] as String?,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
    );
  }

  final String capabilitySlug;
  final int opportunityCount;
  final String? capabilityName;
  final String? categorySlug;
  final String? categoryName;
  final String? categoryIcon;
}
