import 'need_catalog_localizations.dart';

class NeedCapability {
  const NeedCapability({
    required this.slug,
    required this.categorySlug,
    required this.name,
    this.countryLabels = const {},
    this.baseName,
    this.isActive = true,
    this.uiGroupSlug,
    this.serviceGroupSlug,
    this.serviceGroupName,
    this.serviceSortOrder = 1000,
    this.verificationPolicy = 'open',
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
      uiGroupSlug: map['ui_group_slug'] as String?,
      serviceGroupSlug: map['service_group_slug'] as String?,
      serviceGroupName: map['service_group_name'] as String?,
      serviceSortOrder: (map['service_sort_order'] as num?)?.toInt() ?? 1000,
      verificationPolicy: map['verification_policy'] as String? ?? 'open',
    );
  }

  final String slug;
  final String categorySlug;
  final String name;
  final Map<String, dynamic> countryLabels;
  final String? baseName;
  final bool isActive;
  final String? uiGroupSlug;
  final String? serviceGroupSlug;
  final String? serviceGroupName;
  final int serviceSortOrder;
  final String verificationPolicy;

  String nameForCountry(String? countryCode) {
    final labels = countryLabels[countryCode?.toUpperCase()];
    if (labels is Map) return labels['name'] as String? ?? baseName ?? name;
    return baseName ?? name;
  }

  String localizedName(String? localeCode) {
    final code = localeCode?.toLowerCase();
    final map = switch (code) {
      'rw' => {
          'company_registration': 'Iyandikisha ry\'ikorporasiyo',
          'legal_services': 'Serivisi z\'amategeko',
          'accounting_tax': 'Ibaruramari n\'Imisoro',
          'business_consulting': 'Inama z\'ubucuruzi',
          'hr_services': 'Serivisi z\'abakoresha',
          'engineering_consulting': 'Ubuhanga / Injeniyeri',
          'architecture_services': 'Ubwubatsi',
          'other_professional': 'Ibindi serivisi z\'umwuga',
          'marketing_services': 'Kwamamaza no kumenyekanisha',
          'social_media_marketing': 'Kumenyekanisha ku mbuga nkoranyabizikora',
          'tiktok_promotion': 'Kwamamaza kuri TikTok',
          'instagram_promotion': 'Kwamamaza kuri Instagram',
          'youtube_promotion': 'Kwamamaza kuri YouTube',
          'facebook_promotion': 'Kwamamaza kuri Facebook',
          'influencer_marketing': 'Marketing ya Influencer',
          'content_creation': 'Kurema ibitungo by\'ubutumwa',
          'product_reviews': 'Isuzuma ry\'ibicuruzwa',
          'event_promotion': 'Kumenyekanisha ibitaramo',
          'whatsapp_community_promotion': 'WhatsApp / Kumenyekanisha umuryango',
          'affiliate_marketing': 'Marketing wa affiliate',
          'advertising_campaigns': 'Amashyirahamwe y\'itangazamakuru',
          'brand_promotion': 'Kumenyekanisha ikirango',
          'other_marketing_services': 'Ibindi serivisi z\'umukono',
          'driving_school': 'Ishuri ry\'ubujyanama / Gutwara ibinyabiziga',
          'i_have_an_audience': 'Nifite isoko',
          'bank_loan_agent': 'Umukozi wa banki / bank loan agent',
          'money_lender_private_lender': 'Umwenda w\'umwenda wibanga',
          'financial_advisory': 'Inama z\'imari',
          'forex_currency_exchange': 'Forex / Guhindura amafaranga',
          'loan_services': 'Serivisi z\'imari',
          'sacco_microfinance': 'SACCO / Microfinance',
          'other_financial_services': 'Ibindi serivisi z\'imari',
        },
      'fr' => {
          'company_registration': 'Immatriculation de société',
          'legal_services': 'Services juridiques',
          'accounting_tax': 'Comptabilité et fiscalité',
          'business_consulting': 'Conseil aux entreprises',
          'hr_services': 'Services RH',
          'engineering_consulting': 'Ingénierie',
          'architecture_services': 'Services d’architecture',
          'other_professional': 'Autres services professionnels',
          'marketing_services': 'Marketing et promotion',
          'social_media_marketing': 'Marketing des réseaux sociaux',
          'influencer_marketing': 'Marketing d’influence',
          'content_creation': 'Création de contenu',
          'product_reviews': 'Avis produits',
          'event_promotion': 'Promotion d’événements',
          'affiliate_marketing': 'Marketing d’affiliation',
          'advertising_campaigns': 'Campagnes publicitaires',
          'brand_promotion': 'Promotion de marque',
          'other_marketing_services': 'Autres services marketing',
          'driving_school': 'Auto-école / Formation des conducteurs',
          'i_have_an_audience': 'J’ai une audience',
          'bank_loan_agent': 'Agent de prêt bancaire',
          'money_lender_private_lender': 'Prêteur privé',
          'financial_advisory': 'Conseil financier',
          'forex_currency_exchange': 'Forex / Échange de devises',
          'loan_services': 'Services de prêt',
          'sacco_microfinance': 'SACCO / Microfinance',
          'other_financial_services': 'Autres services financiers',
        },
      'sw' => {
          'company_registration': 'Usajili wa kampuni',
          'legal_services': 'Huduma za kisheria',
          'accounting_tax': 'Uhasibu na kodi',
          'business_consulting': 'Ushauri wa biashara',
          'hr_services': 'Huduma za HR',
          'engineering_consulting': 'Uhandisi',
          'architecture_services': 'Usanifu',
          'other_professional': 'Huduma zingine za kitaalamu',
          'marketing_services': 'Uuzaji na kukuza',
          'social_media_marketing': 'Uuzaji wa mitandao ya kijamii',
          'influencer_marketing': 'Uuzaji wa Influencer',
          'content_creation': 'Uundaji wa maudhui',
          'product_reviews': 'Ukaguzi wa bidhaa',
          'event_promotion': 'Kukuza matukio',
          'affiliate_marketing': 'Uuzaji wa affiliate',
          'advertising_campaigns': 'Kampeni za matangazo',
          'brand_promotion': 'Kukuza chapa',
          'other_marketing_services': 'Huduma zingine za marketing',
          'driving_school': 'Shule ya udereva / Mafunzo ya udereva',
          'i_have_an_audience': 'Nina hadhira',
          'bank_loan_agent': 'Wakala wa mkopo wa benki',
          'money_lender_private_lender': 'Mkopeshaji binafsi',
          'financial_advisory': 'Ushauri wa kifedha',
          'forex_currency_exchange': 'Forex / Kubadilishana sarafu',
          'loan_services': 'Huduma za mkopo',
          'sacco_microfinance': 'SACCO / Microfinance',
          'other_financial_services': 'Huduma zingine za kifedha',
        },
      'ar' => {
          'company_registration': 'تسجيل الشركة',
          'legal_services': 'الخدمات القانونية',
          'accounting_tax': 'المحاسبة والضرائب',
          'business_consulting': 'استشارات الأعمال',
          'hr_services': 'خدمات الموارد البشرية',
          'engineering_consulting': 'الهندسة',
          'architecture_services': 'الهندسة المعمارية',
          'other_professional': 'خدمات مهنية أخرى',
          'marketing_services': 'التسويق والترويج',
          'social_media_marketing': 'تسويق وسائل التواصل الاجتماعي',
          'tiktok_promotion': 'ترويج تيك توك',
          'instagram_promotion': 'ترويج إنستغرام',
          'youtube_promotion': 'ترويج يوتيوب',
          'facebook_promotion': 'ترويج فيسبوك',
          'influencer_marketing': 'تسويق المؤثرين',
          'content_creation': 'إنتاج المحتوى',
          'product_reviews': 'مراجعات المنتجات',
          'event_promotion': 'ترويج الأحداث',
          'whatsapp_community_promotion': 'واتساب / ترويج المجتمع',
          'affiliate_marketing': 'تسويق الشراكات',
          'advertising_campaigns': 'حملات إعلانية',
          'brand_promotion': 'ترويج العلامة التجارية',
          'other_marketing_services': 'خدمات تسويق أخرى',
          'driving_school': 'مدرسة القيادة / تدريب السائقين',
          'i_have_an_audience': 'لدي جمهور',
          'bank_loan_agent': 'وكيل القروض البنكية',
          'money_lender_private_lender': 'مقرض خاص',
          'financial_advisory': 'استشارات مالية',
          'forex_currency_exchange': 'الفوركس / تبادل العملات',
          'loan_services': 'خدمات القروض',
          'sacco_microfinance': 'SACCO / التمويل الصغير',
          'other_financial_services': 'خدمات مالية أخرى',
        },
      _ => const <String, String>{},
    };

    return map[slug] ??
        NeedCatalogLocalizations.capabilityName(localeCode, slug) ??
        baseName ??
        name;
  }

  static const List<NeedCapability> defaults = [
    NeedCapability(
      slug: 'internship_placement',
      categorySlug: 'education_training',
      name: 'Internship Placement',
    ),
    NeedCapability(
      slug: 'private_tutoring',
      categorySlug: 'education_training',
      name: 'Private Tutoring',
    ),
    NeedCapability(
      slug: 'online_classes',
      categorySlug: 'education_training',
      name: 'Online Classes',
    ),
    NeedCapability(
      slug: 'professional_training',
      categorySlug: 'education_training',
      name: 'Professional Training',
    ),
    NeedCapability(
      slug: 'vocational_training',
      categorySlug: 'education_training',
      name: 'Vocational Training',
    ),
    NeedCapability(
      slug: 'university_admissions',
      categorySlug: 'education_training',
      name: 'University Admissions',
    ),
    NeedCapability(
      slug: 'study_abroad_guidance',
      categorySlug: 'education_training',
      name: 'Study Abroad Guidance',
    ),
    NeedCapability(
      slug: 'academic_consulting',
      categorySlug: 'education_training',
      name: 'Academic Consulting',
    ),
    NeedCapability(
      slug: 'exam_preparation',
      categorySlug: 'education_training',
      name: 'Exam Preparation',
    ),
    NeedCapability(
      slug: 'language_training',
      categorySlug: 'education_training',
      name: 'Language Training',
    ),
    NeedCapability(
      slug: 'computer_training',
      categorySlug: 'education_training',
      name: 'Computer Training',
    ),
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
      slug: 'travel_agency_services',
      categorySlug: 'travel_international',
      name: 'Travel Agency Services',
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
      slug: 'hajj_umrah',
      categorySlug: 'travel_international',
      name: 'Hajj & Umrah Travel',
    ),
    NeedCapability(
      slug: 'hotel_accommodation',
      categorySlug: 'travel_international',
      name: 'Hotel & Accommodation',
    ),
    NeedCapability(
      slug: 'airport_transfers',
      categorySlug: 'travel_international',
      name: 'Airport Transfers',
    ),
    NeedCapability(
      slug: 'travel_insurance',
      categorySlug: 'travel_international',
      name: 'Travel Insurance',
    ),
    NeedCapability(
      slug: 'tour_packages',
      categorySlug: 'travel_international',
      name: 'Tour Packages',
    ),
    NeedCapability(
      slug: 'study_abroad',
      categorySlug: 'travel_international',
      name: 'Study Abroad',
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
      serviceGroupSlug: 'earthmoving',
      serviceGroupName: 'Earthmoving',
    ),
    NeedCapability(
      slug: 'loader_hire',
      categorySlug: 'machinery_equipment',
      name: 'Loader Hire',
      serviceGroupSlug: 'earthmoving',
      serviceGroupName: 'Earthmoving',
    ),
    NeedCapability(
      slug: 'grader_hire',
      categorySlug: 'machinery_equipment',
      name: 'Grader Hire',
      serviceGroupSlug: 'earthmoving',
      serviceGroupName: 'Earthmoving',
    ),
    NeedCapability(
      slug: 'crane_hire',
      categorySlug: 'machinery_equipment',
      name: 'Crane Hire',
      serviceGroupSlug: 'lifting_power',
      serviceGroupName: 'Lifting & Power',
    ),
    NeedCapability(
      slug: 'generator_hire',
      categorySlug: 'machinery_equipment',
      name: 'Generator Hire',
      serviceGroupSlug: 'lifting_power',
      serviceGroupName: 'Lifting & Power',
    ),
    NeedCapability(
      slug: 'tractor_hire',
      categorySlug: 'machinery_equipment',
      name: 'Tractor Hire',
      serviceGroupSlug: 'farm_industrial',
      serviceGroupName: 'Farm & Industrial',
    ),
    NeedCapability(
      slug: 'industrial_equipment',
      categorySlug: 'machinery_equipment',
      name: 'Industrial Equipment',
      serviceGroupSlug: 'farm_industrial',
      serviceGroupName: 'Farm & Industrial',
    ),
    NeedCapability(
      slug: 'other_machinery',
      categorySlug: 'machinery_equipment',
      name: 'Other Machinery',
      serviceGroupSlug: 'other',
      serviceGroupName: 'Other',
    ),
    NeedCapability(
      slug: 'company_registration',
      categorySlug: 'professional_services',
      name: 'Company Registration & Legal',
    ),
    NeedCapability(
      slug: 'legal_services',
      categorySlug: 'professional_services',
      name: 'Legal Services',
    ),
    NeedCapability(
      slug: 'accounting_tax',
      categorySlug: 'professional_services',
      name: 'Accounting & Tax Advisory',
    ),
    NeedCapability(
      slug: 'business_consulting',
      categorySlug: 'professional_services',
      name: 'Business Consulting',
    ),
    NeedCapability(
      slug: 'hr_services',
      categorySlug: 'professional_services',
      name: 'HR Services',
    ),
    NeedCapability(
      slug: 'marketing_services',
      categorySlug: 'professional_services',
      name: 'Marketing & Promotion',
    ),
    NeedCapability(
      slug: 'engineering_consulting',
      categorySlug: 'professional_services',
      name: 'Engineering Consulting',
    ),
    NeedCapability(
      slug: 'architecture_services',
      categorySlug: 'professional_services',
      name: 'Architecture',
    ),
    NeedCapability(
      slug: 'other_professional',
      categorySlug: 'professional_services',
      name: 'Other Professional Services',
    ),
    NeedCapability(
      slug: 'social_media_marketing',
      categorySlug: 'professional_services',
      name: 'Social Media Marketing',
    ),
    NeedCapability(
      slug: 'influencer_marketing',
      categorySlug: 'professional_services',
      name: 'Influencer Marketing',
    ),
    NeedCapability(
      slug: 'content_creation',
      categorySlug: 'professional_services',
      name: 'Content Creation',
    ),
    NeedCapability(
      slug: 'product_reviews',
      categorySlug: 'professional_services',
      name: 'Product Reviews',
    ),
    NeedCapability(
      slug: 'event_promotion',
      categorySlug: 'professional_services',
      name: 'Event Promotion',
    ),
    NeedCapability(
      slug: 'affiliate_marketing',
      categorySlug: 'professional_services',
      name: 'Affiliate Marketing',
    ),
    NeedCapability(
      slug: 'advertising_campaigns',
      categorySlug: 'professional_services',
      name: 'Advertising Campaigns',
    ),
    NeedCapability(
      slug: 'brand_promotion',
      categorySlug: 'professional_services',
      name: 'Brand Promotion',
    ),
    NeedCapability(
      slug: 'other_marketing_services',
      categorySlug: 'professional_services',
      name: 'Other Marketing Services',
    ),
    NeedCapability(
      slug: 'i_have_an_audience',
      categorySlug: 'professional_services',
      name: 'I Have an Audience',
    ),
    NeedCapability(
      slug: 'driving_school',
      categorySlug: 'professional_services',
      name: 'Driving School / Driver Training',
      countryLabels: {
        'UG': {'name': 'Driving School / Driver Training'},
        'KE': {'name': 'Driving School & Driver Training'},
        'TZ': {'name': 'Mafunzo ya Udereva / Chuo cha Udereva'},
        'RW': {'name': 'Amashuri yo Gutwara Ibinyabiziga'},
        'SS': {'name': 'Driving School / Driver Training'},
        'BI': {'name': 'Auto-École / Formation des Conducteurs'},
      },
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
      slug: 'it_internships',
      categorySlug: 'education_training',
      name: 'IT Internships',
    ),
    NeedCapability(
      slug: 'software_development_internships',
      categorySlug: 'education_training',
      name: 'Software Development Internships',
    ),
    NeedCapability(
      slug: 'it_support_internships',
      categorySlug: 'education_training',
      name: 'IT Support Internships',
    ),
    NeedCapability(
      slug: 'accounting_internships',
      categorySlug: 'education_training',
      name: 'Accounting Internships',
    ),
    NeedCapability(
      slug: 'engineering_internships',
      categorySlug: 'education_training',
      name: 'Engineering Internships',
    ),
    NeedCapability(
      slug: 'marketing_internships',
      categorySlug: 'education_training',
      name: 'Marketing Internships',
    ),
    NeedCapability(
      slug: 'business_internships',
      categorySlug: 'education_training',
      name: 'Business Internships',
    ),
    NeedCapability(
      slug: 'health_nursing_placements',
      categorySlug: 'education_training',
      name: 'Health/Nursing Placements',
    ),
    NeedCapability(
      slug: 'hospitality_internships',
      categorySlug: 'education_training',
      name: 'Hospitality Internships',
    ),
    NeedCapability(
      slug: 'administrative_internships',
      categorySlug: 'education_training',
      name: 'Administrative Internships',
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
