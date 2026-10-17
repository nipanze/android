enum ProviderCategoryType {
  individual,
  company;

  static ProviderCategoryType? fromValue(Object? value) => switch (value) {
        'individual' => ProviderCategoryType.individual,
        'company' => ProviderCategoryType.company,
        _ => null,
      };
}
