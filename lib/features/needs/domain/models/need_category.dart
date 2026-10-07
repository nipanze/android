class NeedCategory {
  const NeedCategory({
    required this.slug,
    required this.name,
    required this.icon,
    this.description,
    this.countryLabels = const {},
    this.baseName,
    this.baseDescription,
    this.sortOrder = 0,
    this.isActive = true,
    this.providerVerificationRequired = false,
  });

  factory NeedCategory.fromMap(
    Map<String, dynamic> map, {
    String? countryCode,
  }) {
    final countryLabels =
        (map['country_labels'] as Map<String, dynamic>?) ?? const {};
    final countryLabel = countryLabels[countryCode?.toUpperCase()];
    final countryName =
        countryLabel is Map ? countryLabel['name'] as String? : null;
    final countryDescription =
        countryLabel is Map ? countryLabel['description'] as String? : null;
    final slug = map['slug'] as String? ?? '';
    return NeedCategory(
      slug: slug,
      name: countryName ?? map['name'] as String? ?? slug,
      icon: map['icon'] as String? ?? '🔎',
      description: countryDescription ?? map['description'] as String?,
      countryLabels: countryLabels,
      baseName: map['name'] as String?,
      baseDescription: map['description'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      providerVerificationRequired:
          map['provider_verification_required'] as bool? ?? true,
    );
  }

  final String slug;
  final String name;
  final String icon;
  final String? description;
  final Map<String, dynamic> countryLabels;
  final String? baseName;
  final String? baseDescription;
  final int sortOrder;
  final bool isActive;
  final bool providerVerificationRequired;

  bool get requiresProviderVerification =>
      providerVerificationRequired;

  String nameForCountry(String? countryCode) {
    final labels = countryLabels[countryCode?.toUpperCase()];
    if (labels is Map) return labels['name'] as String? ?? baseName ?? name;
    return baseName ?? name;
  }

  String? descriptionForCountry(String? countryCode) {
    final labels = countryLabels[countryCode?.toUpperCase()];
    if (labels is Map) {
      return labels['description'] as String? ?? baseDescription ?? description;
    }
    return baseDescription ?? description;
  }

  static const List<NeedCategory> defaultCategories = [
    NeedCategory(
      slug: 'financial_services',
      name: 'Financial Services',
      icon: '💰',
      description: 'Loan services, forex exchange, bank agents, SACCO, microfinance, and financial advisory.',
      sortOrder: 1,
      isActive: true,
    ),
    NeedCategory(
      slug: 'machinery_equipment',
      name: 'Machinery & Equipment',
      icon: '🚜',
      sortOrder: 2,
      isActive: true,
    ),
    NeedCategory(
      slug: 'professional_services',
      name: 'Professional Services',
      icon: '🧑‍💼',
      sortOrder: 3,
      isActive: true,
    ),
    NeedCategory(
      slug: 'transport_logistics',
      name: 'Transport & Logistics',
      icon: '🚚',
      sortOrder: 4,
      isActive: true,
    ),
    NeedCategory(
      slug: 'specialized_products',
      name: 'Specialized Products & Procurement',
      icon: '🔎',
      sortOrder: 5,
      isActive: true,
    ),
    NeedCategory(
      slug: 'education_training',
      name: 'Education & Training',
      icon: '🎓',
      description:
          'Education, internships, professional training, admissions, academic support, and skills development.',
      sortOrder: 6,
      isActive: true,
    ),
    NeedCategory(
      slug: 'travel_international',
      name: 'Travel & International',
      icon: '✈️',
      description:
          'Travel, visa assistance, flights, accommodation, Hajj & Umrah, study abroad, and international relocation services.',
      sortOrder: 10,
      isActive: true,
      providerVerificationRequired: true,
    ),
    NeedCategory(
      slug: 'music_video',
      name: 'Music & Video',
      icon: '🎬',
      sortOrder: 11,
      isActive: true,
    ),
    NeedCategory(
      slug: 'weddings_celebrations',
      name: 'Weddings & Celebrations',
      icon: '🎉',
      sortOrder: 12,
      isActive: true,
    ),
  ];

  static NeedCategory findBySlug(String slug) {
    return defaultCategories.firstWhere(
      (c) => c.slug == slug,
      orElse: () => NeedCategory(
        slug: slug,
        name: slug,
        icon: '🔎',
      ),
    );
  }
}
