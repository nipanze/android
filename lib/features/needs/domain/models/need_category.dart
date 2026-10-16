import 'need_catalog_localizations.dart';

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

  bool get requiresProviderVerification => providerVerificationRequired;

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

  String localizedName(String? localeCode) {
    final code = localeCode?.toLowerCase();
    final map = switch (code) {
      'rw' => {
          'professional_services': 'Serivisi z\'Ubucuruzi',
          'machinery_equipment': 'Imashini n\'Ibikoresho',
          'transport_logistics': 'Ibikorwa by\'ubuhahirane',
          'specialized_products': 'Ibicuruzwa byihariye',
          'education_training': 'Amashuri n\'Amasomo',
          'travel_international': 'Ingendo n\'Ububanyi',
          'music_video': 'Umuziki na Videwo',
          'weddings_celebrations': 'Ubukwe n\'Amatariki',
        },
      'fr' => {
          'professional_services': 'Services professionnels',
          'machinery_equipment': 'Machinerie et équipements',
          'transport_logistics': 'Transport et logistique',
          'specialized_products': 'Produits spécialisés',
          'education_training': 'Éducation et formation',
          'travel_international': 'Voyages et international',
          'music_video': 'Musique et vidéo',
          'weddings_celebrations': 'Mariages et célébrations',
        },
      'sw' => {
          'professional_services': 'Huduma za kitaalamu',
          'machinery_equipment': 'Mashine na vifaa',
          'transport_logistics': 'Usafirishaji na vifaa',
          'specialized_products': 'Bidhaa maalum',
          'education_training': 'Elimu na mafunzo',
          'travel_international': 'Usafiri na kimataifa',
          'music_video': 'Muziki na video',
          'weddings_celebrations': 'Harusi na sherehe',
        },
      'ar' => {
          'professional_services': 'الخدمات المهنية',
          'machinery_equipment': 'الآلات والمعدات',
          'transport_logistics': 'النقل والخدمات اللوجستية',
          'specialized_products': 'المنتجات المتخصصة',
          'education_training': 'التعليم والتدريب',
          'travel_international': 'السفر والدولي',
          'music_video': 'الموسيقى والفيديو',
          'weddings_celebrations': 'الزفاف والاحتفالات',
        },
      _ => const <String, String>{},
    };

    return map[slug] ??
        NeedCatalogLocalizations.categoryName(localeCode, slug) ??
        baseName ??
        name;
  }

  String? localizedDescription(String? localeCode) {
    return NeedCatalogLocalizations.categoryDescription(localeCode, slug) ??
        baseDescription ??
        description;
  }

  static const List<NeedCategory> defaultCategories = [
    NeedCategory(
      slug: 'machinery_equipment',
      name: 'Machinery & Equipment',
      icon: '🚜',
      description:
          'Heavy machinery and equipment hire, with or without an operator.',
      sortOrder: 1,
      isActive: true,
    ),
    NeedCategory(
      slug: 'technology_digital',
      name: 'Technology & Digital',
      icon: '💻',
      description: 'Software, websites, IT support and security.',
      sortOrder: 2,
      isActive: true,
    ),
    NeedCategory(
      slug: 'marketing_promotion',
      name: 'Marketing & Promotion',
      icon: '📢',
      description: 'Advertising, content and influencer work.',
      sortOrder: 3,
      isActive: true,
    ),
    NeedCategory(
      slug: 'professional_services',
      name: 'Business & Professional Services',
      icon: '🧑‍💼',
      description: 'Legal, accounting, HR, engineering and consulting.',
      sortOrder: 4,
      isActive: true,
    ),
    NeedCategory(
      slug: 'education_training',
      name: 'Education & Training',
      icon: '🎓',
      description:
          'Education, internships, professional training and admissions.',
      sortOrder: 5,
      isActive: true,
    ),
    NeedCategory(
      slug: 'events_celebrations',
      name: 'Events & Celebrations',
      icon: '🎉',
      description: 'Weddings, parties, equipment, catering and crews.',
      sortOrder: 6,
      isActive: true,
    ),
    NeedCategory(
      slug: 'photo_video_talent',
      name: 'Photo, Video, Music & Talent',
      icon: '🎬',
      description: 'Creative production, talent and performers.',
      sortOrder: 7,
      isActive: true,
    ),
    NeedCategory(
      slug: 'beauty_fashion_styling',
      name: 'Beauty, Fashion & Styling',
      icon: '💄',
      description: 'Makeup, hair, styling and clothing.',
      sortOrder: 8,
      isActive: true,
    ),
    NeedCategory(
      slug: 'construction_building',
      name: 'Construction & Building',
      icon: '🏗️',
      description: 'Contractors, trades and surveying.',
      sortOrder: 9,
      isActive: true,
    ),
    NeedCategory(
      slug: 'energy_utilities',
      name: 'Energy & Water',
      icon: '⚡',
      description: 'Solar, power backup, boreholes and water systems.',
      sortOrder: 10,
      isActive: true,
    ),
    NeedCategory(
      slug: 'transport_logistics',
      name: 'Transport & Logistics',
      icon: '🚚',
      description: 'Moving, hauling, delivery and fleet services.',
      sortOrder: 11,
      isActive: true,
    ),
    NeedCategory(
      slug: 'agriculture_agribusiness',
      name: 'Agriculture & Agribusiness',
      icon: '🌾',
      description: 'Farm services, inputs and produce.',
      sortOrder: 12,
      isActive: true,
    ),
    NeedCategory(
      slug: 'specialized_products',
      name: 'Specialized Products & Procurement',
      icon: '🔎',
      description: 'Buying, importing and finding hard-to-get products.',
      sortOrder: 13,
      isActive: true,
    ),
    NeedCategory(
      slug: 'travel_international',
      name: 'Travel & International',
      icon: '✈️',
      description:
          'Travel, visa assistance, flights, accommodation, and relocation.',
      sortOrder: 14,
      isActive: true,
      providerVerificationRequired: true,
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
