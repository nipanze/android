import 'package:flutter_test/flutter_test.dart';
import 'package:nipanze/features/needs/domain/models/need_catalog_localizations.dart';
import 'package:nipanze/features/needs/domain/models/need_category.dart';
import 'package:nipanze/features/needs/domain/models/need_form_schema.dart';
import 'package:nipanze/features/provider/domain/entities/provider_service_role.dart';

void main() {
  test('Pets & Animal Services exposes multiple animal-specific work roles',
      () {
    final roles =
        ProviderServiceRole.defaultsForCategory('pets_animal_services');
    expect(roles, hasLength(11));
    expect(
        roles.map((role) => role.slug),
        containsAll([
          'veterinarian',
          'veterinary_assistant',
          'pet_trainer_behaviour_specialist',
          'pet_groomer',
          'pet_sitter',
          'pet_boarding_provider',
          'dog_walker',
          'animal_transport_provider',
          'animal_breeder',
          'animal_nutritionist',
          'veterinary_livestock_officer',
        ]));

    final veterinarian =
        roles.singleWhere((role) => role.slug == 'veterinarian');
    expect(
        veterinarian.kinds.map((kind) => kind.slug),
        containsAll([
          'dogs',
          'cats',
          'cattle',
          'poultry',
          'goats',
          'sheep',
          'rabbits',
          'horses',
          'other_animals',
        ]));
    expect(veterinarian.requiredProofQualificationSlug, 'veterinary_licence');
    expect(
      ProviderServiceRole.defaultsForCategory('agriculture_agribusiness')
          .map((role) => role.slug),
      isNot(contains('veterinary_livestock_officer')),
    );
  });

  test('animal request form collects animal type and relevant service details',
      () {
    final fields = NeedFormSchema.fieldsForCategory('pets_animal_services');
    final animalType =
        fields.singleWhere((field) => field.key == 'animal_type');
    expect(animalType.options,
        containsAll(['Dogs', 'Cats', 'Cattle', 'Other animals']));
    expect(fields.map((field) => field.key), contains('animal_service'));
    expect(
      NeedCategory.defaultCategories
          .singleWhere((category) => category.slug == 'pets_animal_services')
          .icon,
      '🐾',
    );
  });

  test('pet role names, animals, and proof labels respect app language', () {
    expect(NeedCatalogLocalizations.providerRoleName('sw', 'dog_trainer'),
        'Mkufunzi wa mbwa');
    expect(NeedCatalogLocalizations.providerAnimalName('fr', 'dogs', 'Dogs'),
        'Chiens');
    expect(
      NeedCatalogLocalizations.providerQualificationName(
        'rw',
        'veterinary_licence',
        'Veterinary licence',
      ),
      contains('Kwiyandikisha'),
    );
  });
}
