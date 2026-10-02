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

  test('offline capability catalog includes creative and celebration services',
      () {
    final slugs = NeedCapability.defaults.map((capability) => capability.slug);

    expect(
      slugs,
      containsAll([
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
