class DiscoveryQuestionTemplate {
  const DiscoveryQuestionTemplate({
    required this.id,
    required this.slug,
    required this.title,
    required this.question,
    required this.category,
    required this.planType,
    required this.answerType,
    required this.options,
    required this.priority,
    this.needCategorySlug,
    this.followUpRules = const {},
    this.countryCodes = const [],
    this.ctaLabel,
    this.deepLink,
  });

  factory DiscoveryQuestionTemplate.fromMap(Map<String, dynamic> map) {
    return DiscoveryQuestionTemplate(
      id: map['id'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      title: map['title'] as String? ?? 'A quick question',
      question: map['question'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      needCategorySlug: map['need_category_slug'] as String?,
      planType: map['plan_type'] as String? ?? 'general',
      answerType: map['answer_type'] as String? ?? 'single_select',
      options: ((map['options'] as List?) ?? const [])
          .whereType<Map>()
          .map((option) =>
              DiscoveryAnswerOption.fromMap(Map<String, dynamic>.from(option)))
          .toList(),
      followUpRules: Map<String, dynamic>.from(
          (map['follow_up_rules'] as Map?) ?? const {}),
      countryCodes: ((map['country_codes'] as List?) ?? const [])
          .whereType<String>()
          .map((code) => code.toUpperCase())
          .toList(),
      priority: (map['priority'] as num?)?.toInt() ?? 100,
      ctaLabel: map['cta_label'] as String?,
      deepLink: map['deep_link'] as String?,
    );
  }

  final String id;
  final String slug;
  final String title;
  final String question;
  final String category;
  final String? needCategorySlug;
  final String planType;
  final String answerType;
  final List<DiscoveryAnswerOption> options;
  final Map<String, dynamic> followUpRules;
  final List<String> countryCodes;
  final int priority;
  final String? ctaLabel;
  final String? deepLink;

  bool isEligibleForCountry(String countryCode) {
    if (countryCodes.isEmpty) return true;
    return countryCodes.contains(countryCode.toUpperCase());
  }

  List<String> followUpKeysFor(String value) {
    final keys = followUpRules[value];
    if (keys is List) return keys.whereType<String>().toList();
    return const [];
  }
}

class DiscoveryAnswerOption {
  const DiscoveryAnswerOption({
    required this.value,
    required this.label,
    this.savePlan = false,
  });

  factory DiscoveryAnswerOption.fromMap(Map<String, dynamic> map) {
    return DiscoveryAnswerOption(
      value: map['value'] as String? ?? '',
      label: map['label'] as String? ?? '',
      savePlan: map['save_plan'] as bool? ?? false,
    );
  }

  final String value;
  final String label;
  final bool savePlan;
}
