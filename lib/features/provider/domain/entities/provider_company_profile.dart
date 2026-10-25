class ProviderCompanyProfile {
  const ProviderCompanyProfile({
    required this.categorySlug,
    this.companyName,
    this.logoPath,
    this.registrationNumber,
    this.teamSize,
    this.yearsInBusiness,
    this.serviceAreas = const [],
  });

  factory ProviderCompanyProfile.fromMap(Map<String, dynamic> map) =>
      ProviderCompanyProfile(
        categorySlug: map['category_slug']?.toString() ?? '',
        companyName: map['company_name']?.toString(),
        logoPath: map['logo_path']?.toString(),
        registrationNumber: map['registration_number']?.toString(),
        teamSize: map['team_size']?.toString(),
        yearsInBusiness: map['years_in_business']?.toString(),
        serviceAreas: (map['service_areas'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(),
      );

  final String categorySlug;
  final String? companyName;
  final String? logoPath;
  final String? registrationNumber;
  final String? teamSize;
  final String? yearsInBusiness;
  final List<String> serviceAreas;

  Map<String, dynamic> toJson() => {
        'company_name': _emptyToNull(companyName),
        'logo_path': _emptyToNull(logoPath),
        'registration_number': _emptyToNull(registrationNumber),
        'team_size': teamSize,
        'years_in_business': yearsInBusiness,
        'service_areas': serviceAreas,
      };

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
