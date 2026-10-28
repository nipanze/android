import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/core/constants/country_constants.dart';
import 'package:nipanze/features/needs/domain/models/need_capability.dart';
import 'package:nipanze/features/needs/domain/models/need_category.dart';
import 'package:nipanze/features/needs/domain/models/need_form_schema.dart';

void main() {
  test('categories follow the Uganda demand order for display', () {
    final categories = NeedCategory.sortForDisplay(
      NeedCategory.defaultCategories.reversed,
    );

    expect(
      categories.map((category) => category.slug).toList(),
      [
        'machinery_equipment',
        'transport_logistics',
        'specialized_products',
        'construction_building',
        'professional_services',
        'travel_international',
        'agriculture_agribusiness',
        'energy_utilities',
        'technology_digital',
        'marketing_promotion',
        'education_training',
        'events_celebrations',
        'photo_video_talent',
        'beauty_fashion_styling',
      ],
    );
  });

  test('location and nationality suggestions follow country settings', () {
    expect(
      CountryLocations.localitiesFor(EastAfricaCountries.uganda),
      containsAll(['Kampala', 'Entebbe', 'Mukono', 'Jinja']),
    );
    expect(
      CountryLocations.localitiesFor(EastAfricaCountries.kenya),
      containsAll(['Nairobi', 'Mombasa', 'Kisumu']),
    );
    expect(
      CountryLocations.localitiesFor(EastAfricaCountries.kenya),
      isNot(contains('Kampala')),
    );

    final ugandanNationalities =
        CountryLocations.nationalitiesFor(EastAfricaCountries.uganda);
    expect(ugandanNationalities.first, 'Ugandan');
    expect(
      ugandanNationalities,
      containsAll(['Congolese (DRC)', 'South African', 'Nigerian']),
    );
    expect(CountryLocations.flagForNationality('Ugandan'), '🇺🇬');
    expect(CountryLocations.flagForNationality('Congolese (DRC)'), '🇨🇩');
    expect(CountryLocations.flagForNationality('Unknown'), isNull);

    final southAfricanNationalities =
        CountryLocations.nationalitiesFor(EastAfricaCountries.southAfrica);
    expect(southAfricanNationalities.first, 'South African');
    expect(southAfricanNationalities, contains('Nigerian'));
  });

  test('category labels use the country override and shared fallback', () {
    final category = NeedCategory.fromMap(
      {
        'slug': 'weddings_celebrations',
        'name': 'Weddings & Celebrations',
        'country_labels': {
          'KE': {'name': 'Celebrations & Events'},
        },
      },
      countryCode: 'ke',
    );

    expect(category.name, 'Celebrations & Events');
    expect(category.nameForCountry('ke'), 'Celebrations & Events');
    expect(category.nameForCountry('UG'), 'Weddings & Celebrations');
  });

  test('capability labels use the country override and shared fallback', () {
    final capability = NeedCapability.fromMap(
      {
        'slug': 'celebration_mc_dj',
        'category_slug': 'weddings_celebrations',
        'name': 'DJs / MCs',
        'country_labels': {
          'UG': {'name': 'DJs and MCs'},
        },
      },
      countryCode: 'UG',
    );

    expect(capability.name, 'DJs and MCs');
    expect(capability.nameForCountry('UG'), 'DJs and MCs');
    expect(capability.nameForCountry('KE'), 'DJs / MCs');
  });

  test('service labels follow the app locale when no country override exists',
      () {
    final category = NeedCategory.defaultCategories
        .firstWhere((category) => category.slug == 'professional_services');
    final capability = NeedCapability.defaults
        .firstWhere((capability) => capability.slug == 'company_registration');

    expect(category.localizedName('rw'), 'Serivisi z\'Ubucuruzi');
    expect(category.localizedName('fr'), 'Services professionnels');
    expect(capability.localizedName('rw'), 'Iyandikisha ry\'ikorporasiyo');
    expect(capability.localizedName('en'), 'Company Registration & Legal');
  });

  test('all service categories respond to every supported app language', () {
    const categories = [
      NeedCategory(
        slug: 'machinery_equipment',
        name: 'Machinery & Equipment',
        icon: '🚜',
      ),
      NeedCategory(
        slug: 'professional_services',
        name: 'Professional & Business Services',
        icon: '🧑‍💼',
      ),
      NeedCategory(
        slug: 'transport_logistics',
        name: 'Transport & Logistics',
        icon: '🚚',
      ),
      NeedCategory(
        slug: 'specialized_products',
        name: 'Specialized Products & Procurement',
        icon: '🔎',
      ),
      NeedCategory(
        slug: 'construction_building',
        name: 'Construction & Building',
        icon: '🏗️',
      ),
      NeedCategory(
        slug: 'agriculture_agribusiness',
        name: 'Agriculture & Agribusiness',
        icon: '🌾',
      ),
      NeedCategory(
        slug: 'technology_digital',
        name: 'Technology & Digital',
        icon: '💻',
      ),
      NeedCategory(
        slug: 'events_production',
        name: 'Events & Production',
        icon: '🎉',
      ),
      NeedCategory(
        slug: 'energy_utilities',
        name: 'Energy & Utilities',
        icon: '⚡',
      ),
      NeedCategory(
        slug: 'education_training',
        name: 'Education & Training',
        icon: '🎓',
      ),
      NeedCategory(
        slug: 'travel_international',
        name: 'Travel & International',
        icon: '✈️',
      ),
      NeedCategory(
        slug: 'music_video',
        name: 'Music & Video',
        icon: '🎬',
      ),
      NeedCategory(
        slug: 'weddings_celebrations',
        name: 'Weddings & Celebrations',
        icon: '🎉',
      ),
    ];

    for (final category in categories) {
      for (final locale in ['rw', 'fr', 'sw', 'ar']) {
        expect(
          category.localizedName(locale),
          isNot(category.name),
          reason: '${category.slug} should be translated for $locale',
        );
      }
    }
  });

  test('category descriptions respond to every supported app language', () {
    for (final category in NeedCategory.defaultCategories) {
      if (category.description == null) continue;

      for (final locale in ['rw', 'fr', 'sw', 'ar']) {
        expect(
          category.localizedDescription(locale),
          isNot(category.description),
          reason:
              '${category.slug} description should be translated for $locale',
        );
      }
    }
  });

  test('all fallback service capabilities respond to every supported language',
      () {
    for (final capability in NeedCapability.defaults) {
      for (final locale in ['rw', 'fr', 'sw', 'ar']) {
        expect(
          capability.localizedName(locale),
          isNot(capability.name),
          reason: '${capability.slug} should be translated for $locale',
        );
      }
    }
  });

  test('Events & Production subcategories respond to every app language', () {
    const eventCapabilities = {
      'catering_services': 'Catering',
      'event_equipment': 'Event Equipment',
      'event_planning': 'Event Planning',
      'lighting_hire': 'Lighting',
      'mc_services': 'MCs',
      'other_events': 'Other Events',
      'photography_services': 'Photography',
      'sound_systems': 'Sound Systems',
      'tent_hire': 'Tents',
      'videography_services': 'Videography',
    };

    for (final entry in eventCapabilities.entries) {
      final capability = NeedCapability(
        slug: entry.key,
        categorySlug: 'events_production',
        name: entry.value,
      );
      for (final locale in ['rw', 'fr', 'sw', 'ar']) {
        expect(
          capability.localizedName(locale),
          isNot(entry.value),
          reason: '${entry.key} should be translated for $locale',
        );
      }
    }
  });

  test('creative and celebration categories have structured request fields',
      () {
    expect(
      NeedFormSchema.fieldsForCategory('music_video').map((field) => field.key),
      containsAll(['production_type', 'shoot_date', 'location']),
    );
    expect(
      NeedFormSchema.fieldsForCategory('weddings_celebrations')
          .map((field) => field.key),
      containsAll(['celebration_type', 'event_date', 'venue_location']),
    );
  });

  test('all structured need categories have beginner-friendly form guidance',
      () {
    for (final categorySlug in NeedFormSchema.categoryFields.keys) {
      final guidance = NeedFormSchema.categoryGuidance[categorySlug];

      expect(guidance, isNotNull, reason: categorySlug);
      expect(guidance!.titleHint, isNotEmpty, reason: categorySlug);
      expect(guidance.specificationHint, isNotEmpty, reason: categorySlug);
      expect(guidance.specificationHelper, isNotEmpty, reason: categorySlug);
    }
  });

  test('all need categories have usable guidance and field explanations', () {
    const catalogCategorySlugs = [
      'machinery_equipment',
      'professional_services',
      'transport_logistics',
      'specialized_products',
      'construction_building',
      'agriculture_agribusiness',
      'technology_digital',
      'events_production',
      'energy_utilities',
      'education_training',
      'travel_international',
      'music_video',
      'weddings_celebrations',
    ];

    for (final categorySlug in catalogCategorySlugs) {
      final guidance = NeedFormSchema.categoryGuidance[categorySlug];

      expect(guidance, isNotNull, reason: categorySlug);
      expect(guidance!.titleHint, isNotEmpty, reason: categorySlug);
      expect(guidance.specificationHint, isNotEmpty, reason: categorySlug);
      expect(guidance.specificationHelper, isNotEmpty, reason: categorySlug);
      final presets = NeedFormSchema.presetsForCategory(categorySlug);
      expect(presets, isNotEmpty, reason: '$categorySlug needs quick helpers');
      expect(
        presets.map((preset) => preset.label),
        isNot(contains('Standard request')),
        reason: '$categorySlug should have category-specific quick helpers',
      );
      for (final preset in presets) {
        expect(preset.title, isNotEmpty,
            reason: '$categorySlug/${preset.label}');
        expect(preset.specification, isNotEmpty,
            reason: '$categorySlug/${preset.label}');
      }
      for (final field in NeedFormSchema.fieldsForCategory(categorySlug)) {
        expect(field.guidance, isNotEmpty,
            reason: '$categorySlug/${field.key}');
      }
    }

    expect(
      NeedFormSchema.categoryFields.keys,
      containsAll(catalogCategorySlugs),
    );
    expect(
      NeedFormSchema.guidanceForCategory('another_need_category')
          .specificationHelper,
      isNotEmpty,
    );
  });

  test('travel fields include actionable helpers and privacy guidance', () {
    final fields = NeedFormSchema.fieldsForCategory('travel_international');
    final byKey = {for (final field in fields) field.key: field};

    expect(
      byKey.values.every(
        (field) => field.helperText != null && field.helperText!.isNotEmpty,
      ),
      isTrue,
    );
    expect(byKey['nationality']!.helperText, contains('passport numbers'));
    expect(
      byKey['additional_requirements']!.helperText,
      contains('private document details'),
    );
  });

  test('education requests include structured training and location fields',
      () {
    final fields = NeedFormSchema.fieldsForCategory('education_training');
    final byKey = {for (final field in fields) field.key: field};

    expect(
      byKey.keys,
      containsAll([
        'training_type',
        'training_level',
        'preferred_format',
        'preferred_location',
        'max_travel_distance',
        'start_date',
        'duration',
        'schedule',
        'required_qualifications',
        'specific_skills_topics',
        'additional_requirements',
      ]),
    );
    expect(
      byKey['preferred_format']!.options,
      ['Online', 'In-person', 'Either'],
    );
    expect(
      byKey['max_travel_distance']!.options,
      ['2 km', '5 km', '10 km', '20 km', 'Anywhere'],
    );
  });

  test('education and travel categories are active in the fallback catalog',
      () {
    final education = NeedCategory.defaultCategories
        .firstWhere((category) => category.slug == 'education_training');
    final travel = NeedCategory.defaultCategories
        .firstWhere((category) => category.slug == 'travel_international');

    expect(education.isActive, isTrue);
    expect(travel.isActive, isTrue);
    expect(travel.requiresProviderVerification, isTrue);
    expect(travel.sortOrder, greaterThan(5));
  });

  test('financial services is not an active Needs category or capability', () {
    expect(
      NeedCategory.defaultCategories.map((category) => category.slug),
      isNot(contains('financial_services')),
    );
    expect(
      NeedCategory.defaultCategories
          .map((category) => category.name.toLowerCase()),
      isNot(contains('financial services')),
    );
    expect(
      NeedCapability.defaults.where(
          (capability) => capability.categorySlug == 'financial_services'),
      isEmpty,
    );
  });

  test('offline capability catalog includes creative and celebration services',
      () {
    final slugs = NeedCapability.defaults.map((capability) => capability.slug);

    expect(
      slugs,
      containsAll([
        'visa_assistance',
        'travel_documentation',
        'international_relocation',
        'music_video_models',
        'music_producers',
        'graduation_photography',
        'wedding_photography',
        'hair_styling',
        'celebration_catering',
        'wedding_event_planning',
        'baby_shower_planning',
      ]),
    );
  });

  group('Driving School & Driver Training taxonomy & matching', () {
    test(
        'Driving School appears under Professional Services and NOT Transport & Logistics',
        () {
      final professionalServicesCapabilities = NeedCapability.defaults
          .where((c) => c.categorySlug == 'professional_services')
          .toList();
      final transportLogisticsCapabilities = NeedCapability.defaults
          .where((c) => c.categorySlug == 'transport_logistics')
          .toList();

      expect(
        professionalServicesCapabilities.map((c) => c.slug),
        contains('driving_school'),
        reason: 'Driving School must be listed under Professional Services',
      );
      expect(
        transportLogisticsCapabilities.map((c) => c.slug),
        isNot(contains('driving_school')),
        reason: 'Driving School must NOT be listed under Transport & Logistics',
      );

      final drivingSchoolCap = professionalServicesCapabilities
          .firstWhere((c) => c.slug == 'driving_school');
      expect(drivingSchoolCap.categorySlug, 'professional_services');
      expect(drivingSchoolCap.nameForCountry('UG'),
          'Driving School / Driver Training');
      expect(drivingSchoolCap.nameForCountry('KE'),
          'Driving School & Driver Training');
    });

    test(
        'Professional Services form presets and quick values include Driving School',
        () {
      final presets =
          NeedFormSchema.presetsForCategory('professional_services');
      expect(
        presets.map((p) => p.label),
        contains('Driving school'),
      );

      final drivingPreset =
          presets.firstWhere((p) => p.label == 'Driving school');
      expect(drivingPreset.details['service_type'],
          'Driving School & Driver Training');
    });

    test(
        'existing providers with driving_school capability retain it under Professional Services',
        () {
      final map = {
        'id': 'cap-driving-1',
        'user_id': 'u-provider-1',
        'capability_slug': 'driving_school',
        'verification_level': 'provider_verified',
        'created_at': '2026-10-01T12:00:00Z',
        'capability_name': 'Driving School / Driver Training',
        'category_slug': 'professional_services',
        'category_name': 'Professional Services',
        'category_icon': '🧑‍💼',
      };
      final cap = NeedCapability.fromMap({
        'slug': 'driving_school',
        'category_slug': 'professional_services',
        'name': 'Driving School / Driver Training',
      });

      expect(cap.slug, 'driving_school');
      expect(cap.categorySlug, 'professional_services');
      expect(map['capability_slug'], 'driving_school');
      expect(map['category_slug'], 'professional_services');
      expect(map['category_name'], 'Professional Services');
    });
  });
}
