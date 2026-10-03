class NeedCapability {
  const NeedCapability({
    required this.slug,
    required this.categorySlug,
    required this.name,
    this.countryLabels = const {},
    this.baseName,
    this.isActive = true,
  });

  factory NeedCapability.fromMap(
    Map<String, dynamic> map, {
    String? countryCode,
  }) {
    final countryLabels =
        (map['country_labels'] as Map<String, dynamic>?) ?? const {};
    final countryLabel = countryLabels[countryCode?.toUpperCase()];
    final countryName =
        countryLabel is Map ? countryLabel['name'] as String? : null;
    return NeedCapability(
      slug: map['slug'] as String,
      categorySlug: map['category_slug'] as String,
      name: countryName ?? map['name'] as String,
      countryLabels: countryLabels,
      baseName: map['name'] as String,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  final String slug;
  final String categorySlug;
  final String name;
  final Map<String, dynamic> countryLabels;
  final String? baseName;
  final bool isActive;

  String nameForCountry(String? countryCode) {
    final labels = countryLabels[countryCode?.toUpperCase()];
    if (labels is Map) return labels['name'] as String? ?? baseName ?? name;
    return baseName ?? name;
  }

  static const List<NeedCapability> defaults = [
    NeedCapability(
      slug: 'visa_assistance',
      categorySlug: 'travel_international',
      name: 'Visa Assistance',
    ),
    NeedCapability(
      slug: 'flight_tickets',
      categorySlug: 'travel_international',
      name: 'Flight Tickets & Bookings',
    ),
    NeedCapability(
      slug: 'hajj_umrah',
      categorySlug: 'travel_international',
      name: 'Hajj & Umrah Travel',
    ),
    NeedCapability(
      slug: 'travel_consultation',
      categorySlug: 'travel_international',
      name: 'Travel Consultation',
    ),
    NeedCapability(
      slug: 'travel_documentation',
      categorySlug: 'travel_international',
      name: 'Travel Documentation',
    ),
    NeedCapability(
      slug: 'international_relocation',
      categorySlug: 'travel_international',
      name: 'International Relocation',
    ),
    NeedCapability(
      slug: 'excavator_hire',
      categorySlug: 'machinery_equipment',
      name: 'Excavator Hire',
    ),
    NeedCapability(
      slug: 'tractor_hire',
      categorySlug: 'machinery_equipment',
      name: 'Tractor & Farm Machinery',
    ),
    NeedCapability(
      slug: 'generator_hire',
      categorySlug: 'machinery_equipment',
      name: 'Industrial Generators',
    ),
    NeedCapability(
      slug: 'company_registration',
      categorySlug: 'professional_services',
      name: 'Company Registration & Legal',
    ),
    NeedCapability(
      slug: 'accounting_tax',
      categorySlug: 'professional_services',
      name: 'Accounting & Tax Advisory',
    ),
    NeedCapability(
      slug: 'engineering_consulting',
      categorySlug: 'professional_services',
      name: 'Engineering Consulting',
    ),
    NeedCapability(
      slug: 'heavy_haulage',
      categorySlug: 'transport_logistics',
      name: 'Heavy Freight & Bulk Haulage',
    ),
    NeedCapability(
      slug: 'courier_delivery',
      categorySlug: 'transport_logistics',
      name: 'Courier & Express Delivery',
    ),
    NeedCapability(
      slug: 'cold_chain_transport',
      categorySlug: 'transport_logistics',
      name: 'Cold Chain & Refrigerated',
    ),
    NeedCapability(
      slug: 'bulk_procurement',
      categorySlug: 'specialized_products',
      name: 'Bulk Industrial Procurement',
    ),
    NeedCapability(
      slug: 'medical_supplies',
      categorySlug: 'specialized_products',
      name: 'Medical & Lab Supplies',
    ),
    NeedCapability(
      slug: 'electronic_hardware',
      categorySlug: 'specialized_products',
      name: 'Specialized Electronics & Parts',
    ),
    NeedCapability(
      slug: 'music_video_models',
      categorySlug: 'music_video',
      name: 'Music Video Models / Video Vixens',
    ),
    NeedCapability(
      slug: 'dancers',
      categorySlug: 'music_video',
      name: 'Dancers',
    ),
    NeedCapability(
      slug: 'actors_actresses',
      categorySlug: 'music_video',
      name: 'Actors / Actresses',
    ),
    NeedCapability(
      slug: 'background_extras',
      categorySlug: 'music_video',
      name: 'Background Extras',
    ),
    NeedCapability(
      slug: 'singers_vocalists',
      categorySlug: 'music_video',
      name: 'Singers / Vocalists',
    ),
    NeedCapability(
      slug: 'songwriters',
      categorySlug: 'music_video',
      name: 'Songwriters',
    ),
    NeedCapability(
      slug: 'music_producers',
      categorySlug: 'music_video',
      name: 'Music Producers',
    ),
    NeedCapability(
      slug: 'recording_studios',
      categorySlug: 'music_video',
      name: 'Recording Studios',
    ),
    NeedCapability(
      slug: 'mixing_mastering',
      categorySlug: 'music_video',
      name: 'Mixing & Mastering',
    ),
    NeedCapability(
      slug: 'videographers',
      categorySlug: 'music_video',
      name: 'Videographers',
    ),
    NeedCapability(
      slug: 'video_editors',
      categorySlug: 'music_video',
      name: 'Video Editors',
    ),
    NeedCapability(
      slug: 'photographers',
      categorySlug: 'music_video',
      name: 'Photographers',
    ),
    NeedCapability(
      slug: 'music_video_makeup',
      categorySlug: 'music_video',
      name: 'Makeup Artists',
    ),
    NeedCapability(
      slug: 'music_video_stylists',
      categorySlug: 'music_video',
      name: 'Stylists',
    ),
    NeedCapability(
      slug: 'graduation_photography',
      categorySlug: 'weddings_celebrations',
      name: 'Graduation Photography',
    ),
    NeedCapability(
      slug: 'graduation_videography',
      categorySlug: 'weddings_celebrations',
      name: 'Graduation Videography',
    ),
    NeedCapability(
      slug: 'wedding_photography',
      categorySlug: 'weddings_celebrations',
      name: 'Wedding Photography',
    ),
    NeedCapability(
      slug: 'wedding_videography',
      categorySlug: 'weddings_celebrations',
      name: 'Wedding Videography',
    ),
    NeedCapability(
      slug: 'celebration_makeup',
      categorySlug: 'weddings_celebrations',
      name: 'Makeup Artists',
    ),
    NeedCapability(
      slug: 'hair_styling',
      categorySlug: 'weddings_celebrations',
      name: 'Hair Stylists',
    ),
    NeedCapability(
      slug: 'bridal_styling',
      categorySlug: 'weddings_celebrations',
      name: 'Bridal Styling',
    ),
    NeedCapability(
      slug: 'dresses_bridesmaid_outfits',
      categorySlug: 'weddings_celebrations',
      name: 'Wedding Dresses / Bridesmaid Outfits',
    ),
    NeedCapability(
      slug: 'event_decoration',
      categorySlug: 'weddings_celebrations',
      name: 'Decoration',
    ),
    NeedCapability(
      slug: 'celebration_catering',
      categorySlug: 'weddings_celebrations',
      name: 'Catering',
    ),
    NeedCapability(
      slug: 'celebration_cakes',
      categorySlug: 'weddings_celebrations',
      name: 'Cakes',
    ),
    NeedCapability(
      slug: 'celebration_mc_dj',
      categorySlug: 'weddings_celebrations',
      name: 'DJs / MCs',
    ),
    NeedCapability(
      slug: 'celebration_singers_dancers',
      categorySlug: 'weddings_celebrations',
      name: 'Singers / Dancers',
    ),
    NeedCapability(
      slug: 'wedding_event_planning',
      categorySlug: 'weddings_celebrations',
      name: 'Event Planning',
    ),
    NeedCapability(
      slug: 'event_transport',
      categorySlug: 'weddings_celebrations',
      name: 'Event Transport',
    ),
    NeedCapability(
      slug: 'engagement_planning',
      categorySlug: 'weddings_celebrations',
      name: 'Engagements',
    ),
    NeedCapability(
      slug: 'bridal_shower_planning',
      categorySlug: 'weddings_celebrations',
      name: 'Bridal Showers',
    ),
    NeedCapability(
      slug: 'baby_shower_planning',
      categorySlug: 'weddings_celebrations',
      name: 'Baby Showers',
    ),
    NeedCapability(
      slug: 'birthday_celebrations',
      categorySlug: 'weddings_celebrations',
      name: 'Birthdays',
    ),
    NeedCapability(
      slug: 'anniversary_celebrations',
      categorySlug: 'weddings_celebrations',
      name: 'Anniversaries',
    ),
    NeedCapability(
      slug: 'other_social_celebrations',
      categorySlug: 'weddings_celebrations',
      name: 'Other Social Celebrations',
    ),
  ];
}
