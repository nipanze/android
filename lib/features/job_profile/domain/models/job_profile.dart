class JobProfile {
  const JobProfile({
    required this.id,
    required this.userId,
    required this.categorySlug,
    required this.categoryName,
    this.categoryIcon,
    required this.isActive,
    this.availability,
    this.preferredLocation,
    this.remotePreference = 'flexible',
    this.preferredCurrency = 'UGX',
    this.expectedPayAmount,
    this.expectedPayPeriod,
    this.languages = const [],
    this.summary,
    this.roles = const [],
  });

  factory JobProfile.fromMap(Map<String, dynamic> map) {
    return JobProfile(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      categorySlug: map['category_slug'] as String? ?? '',
      categoryName: map['category_name'] as String? ?? '',
      categoryIcon: map['category_icon'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      availability: map['availability'] as String?,
      preferredLocation: map['preferred_location'] as String?,
      remotePreference: map['remote_preference'] as String? ?? 'flexible',
      preferredCurrency: map['preferred_currency'] as String? ?? 'UGX',
      expectedPayAmount: (map['expected_pay_amount'] as num?)?.toInt(),
      expectedPayPeriod: map['expected_pay_period'] as String?,
      languages: (map['languages'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
      summary: map['summary'] as String?,
      roles: (map['roles'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => JobProfileRole.fromMap(value.cast()))
          .toList(),
    );
  }

  final String id;
  final String userId;
  final String categorySlug;
  final String categoryName;
  final String? categoryIcon;
  final bool isActive;
  final String? availability;
  final String? preferredLocation;
  final String remotePreference;
  final String preferredCurrency;
  final int? expectedPayAmount;
  final String? expectedPayPeriod;
  final List<String> languages;
  final String? summary;
  final List<JobProfileRole> roles;

  int get qualificationCount => roles
      .where((role) => role.isActive)
      .fold(0, (sum, role) => sum + role.qualifications.length);
}

class JobProfileRole {
  const JobProfileRole({
    required this.id,
    required this.roleSlug,
    required this.roleName,
    this.isActive = true,
    this.yearsExperience,
    this.workTypes = const [],
    this.qualifications = const [],
  });

  factory JobProfileRole.fromMap(Map<String, dynamic> map) {
    return JobProfileRole(
      id: map['id'] as String? ?? '',
      roleSlug: map['role_slug'] as String? ?? '',
      roleName: map['role_name'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      yearsExperience: map['years_experience'] as String?,
      workTypes: (map['work_types'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => JobProfileOption.fromMap(value.cast()))
          .toList(),
      qualifications: (map['qualifications'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => JobProfileOption.fromMap(value.cast()))
          .toList(),
    );
  }

  final String id;
  final String roleSlug;
  final String roleName;
  final bool isActive;
  final String? yearsExperience;
  final List<JobProfileOption> workTypes;
  final List<JobProfileOption> qualifications;
}

class JobProfileOption {
  const JobProfileOption({
    required this.slug,
    required this.name,
  });

  factory JobProfileOption.fromMap(Map<String, dynamic> map) {
    return JobProfileOption(
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }

  final String slug;
  final String name;
}

class JobProfileDraft {
  JobProfileDraft({
    required this.categorySlug,
    required this.preferredCurrency,
    this.availability,
    this.preferredLocation,
    this.remotePreference = 'flexible',
    this.expectedPayAmount,
    this.expectedPayPeriod,
    this.languages = const ['en'],
    this.summary,
    this.roles = const [],
  });

  final String categorySlug;
  final String preferredCurrency;
  String? availability;
  String? preferredLocation;
  String remotePreference;
  int? expectedPayAmount;
  String? expectedPayPeriod;
  List<String> languages;
  String? summary;
  List<JobProfileRoleDraft> roles;
}

class JobProfileRoleDraft {
  const JobProfileRoleDraft({
    required this.roleSlug,
    this.yearsExperience,
    this.workTypeSlugs = const [],
    this.qualificationSlugs = const [],
  });

  final String roleSlug;
  final String? yearsExperience;
  final List<String> workTypeSlugs;
  final List<String> qualificationSlugs;
}
