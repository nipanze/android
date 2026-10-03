import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/needs/domain/models/need_capability.dart';
import 'package:nipanze/features/needs/domain/models/need_category.dart';
import 'package:nipanze/features/needs/domain/models/need_form_schema.dart';

void main() {
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
}
