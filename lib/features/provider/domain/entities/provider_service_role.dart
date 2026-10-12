class ProviderServiceRole {
  const ProviderServiceRole({
    required this.slug,
    required this.name,
    this.kindQuestion,
    this.categorySlug,
    this.capabilitySlug,
    this.kinds = const [],
    this.qualifications = const [],
  });

  factory ProviderServiceRole.fromMap(Map<String, dynamic> map) {
    return ProviderServiceRole(
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      kindQuestion: map['kind_question'] as String?,
      categorySlug: map['category_slug'] as String?,
      capabilitySlug: map['capability_slug'] as String?,
      kinds: ((map['role_kinds'] as List?) ?? const [])
          .map(ProviderRoleOption.fromMap)
          .toList(),
      qualifications: ((map['role_qualifications'] as List?) ?? const [])
          .map(ProviderRoleQualification.fromMap)
          .toList(),
    );
  }

  final String slug;
  final String name;
  final String? kindQuestion;
  final String? categorySlug;
  final String? capabilitySlug;
  final List<ProviderRoleOption> kinds;
  final List<ProviderRoleQualification> qualifications;
}

class ProviderRoleOption {
  const ProviderRoleOption({
    required this.slug,
    required this.name,
  });

  factory ProviderRoleOption.fromMap(dynamic value) {
    final map = value as Map<String, dynamic>;
    return ProviderRoleOption(
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }

  final String slug;
  final String name;
}

class ProviderRoleQualification {
  const ProviderRoleQualification({
    required this.slug,
    required this.name,
    this.isEvidence = false,
  });

  factory ProviderRoleQualification.fromMap(dynamic value) {
    final map = value as Map<String, dynamic>;
    return ProviderRoleQualification(
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      isEvidence: map['is_evidence'] as bool? ?? false,
    );
  }

  final String slug;
  final String name;
  final bool isEvidence;
}
