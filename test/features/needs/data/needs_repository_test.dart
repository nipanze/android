import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/needs/data/needs_repository.dart';

void main() {
  group('deduplicateCatalogSearchResults', () {
    test('keeps one row when a work role is returned from both catalog sources',
        () {
      final results = deduplicateCatalogSearchResults([
        {
          'result_type': 'role',
          'slug': 'work_driver',
          'category_slug': 'transport_logistics',
          'label': 'Driver',
        },
        {
          'result_type': 'role',
          'slug': 'work_driver',
          'category_slug': 'transport_logistics',
          'label': 'Driver',
        },
        {
          'result_type': 'role',
          'slug': 'work_driver_guide',
          'category_slug': 'travel_international',
          'label': 'Driver-Guide',
        },
      ]);

      expect(results, hasLength(2));
      expect(results.map((result) => result['label']),
          containsAll(['Driver', 'Driver-Guide']));
    });

    test('keeps the canonical Driving School row for duplicate labels', () {
      final results = deduplicateCatalogSearchResults([
        {
          'result_type': 'service',
          'slug': 'driving_school_driver_training',
          'category_slug': 'professional_services',
          'label': 'Driving School / Driver Training',
        },
        {
          'result_type': 'service',
          'slug': 'driving_school',
          'category_slug': 'professional_services',
          'label': 'Driving School / Driver Training',
        },
      ]);

      expect(results, hasLength(1));
      expect(results.single['slug'], 'driving_school');
    });

    test('keeps same-named kinds belonging to different roles', () {
      final results = deduplicateCatalogSearchResults([
        {
          'result_type': 'kind',
          'slug': 'driver:general',
          'category_slug': 'transport_logistics',
          'label': 'General',
        },
        {
          'result_type': 'kind',
          'slug': 'technician:general',
          'category_slug': 'technology_digital',
          'label': 'General',
        },
      ]);

      expect(results, hasLength(2));
    });
  });
}
