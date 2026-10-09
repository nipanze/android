class UserDiscoveryPlan {
  const UserDiscoveryPlan({
    required this.id,
    required this.userId,
    required this.category,
    required this.planType,
    required this.title,
    required this.answers,
    required this.createdAt,
    required this.updatedAt,
    this.templateId,
    this.needCategorySlug,
    this.destination,
    this.preferredLocation,
    this.expectedDate,
    this.timeframe,
    this.reminderPreference = 'none',
    this.expiresAt,
    this.reviewAt,
  });

  factory UserDiscoveryPlan.fromMap(Map<String, dynamic> map) {
    return UserDiscoveryPlan(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      templateId: map['template_id'] as String?,
      category: map['category'] as String? ?? 'general',
      needCategorySlug: map['need_category_slug'] as String?,
      planType: map['plan_type'] as String? ?? 'general',
      title: map['title'] as String? ?? 'Saved plan',
      answers: Map<String, dynamic>.from((map['answers'] as Map?) ?? const {}),
      destination: map['destination'] as String?,
      preferredLocation: map['preferred_location'] as String?,
      expectedDate: map['expected_date'] == null
          ? null
          : DateTime.tryParse(map['expected_date'] as String),
      timeframe: map['timeframe'] as String?,
      reminderPreference: map['reminder_preference'] as String? ?? 'none',
      expiresAt: map['expires_at'] == null
          ? null
          : DateTime.tryParse(map['expires_at'] as String),
      reviewAt: map['review_at'] == null
          ? null
          : DateTime.tryParse(map['review_at'] as String),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String userId;
  final String? templateId;
  final String category;
  final String? needCategorySlug;
  final String planType;
  final String title;
  final Map<String, dynamic> answers;
  final String? destination;
  final String? preferredLocation;
  final DateTime? expectedDate;
  final String? timeframe;
  final String reminderPreference;
  final DateTime? expiresAt;
  final DateTime? reviewAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get summary {
    final parts = [
      destination,
      preferredLocation,
      timeframe,
      if (expectedDate != null)
        '${expectedDate!.year.toString().padLeft(4, '0')}-${expectedDate!.month.toString().padLeft(2, '0')}-${expectedDate!.day.toString().padLeft(2, '0')}',
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();
    return parts.isEmpty ? 'No details added yet' : parts.join(' · ');
  }
}

class DiscoveryPlanDraft {
  const DiscoveryPlanDraft({
    required this.category,
    required this.planType,
    required this.title,
    this.templateId,
    this.needCategorySlug,
    this.answers = const {},
    this.destination,
    this.preferredLocation,
    this.expectedDate,
    this.timeframe,
    this.reminderPreference = 'none',
  });

  final String? templateId;
  final String category;
  final String? needCategorySlug;
  final String planType;
  final String title;
  final Map<String, dynamic> answers;
  final String? destination;
  final String? preferredLocation;
  final DateTime? expectedDate;
  final String? timeframe;
  final String reminderPreference;

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'template_id': templateId,
        'category': category,
        'need_category_slug': needCategorySlug,
        'plan_type': planType,
        'title': title,
        'answers': answers,
        'destination': _blankToNull(destination),
        'preferred_location': _blankToNull(preferredLocation),
        'expected_date': expectedDate?.toIso8601String().split('T').first,
        'timeframe': _blankToNull(timeframe),
        'reminder_preference': reminderPreference,
        'review_at':
            expectedDate?.subtract(const Duration(days: 7)).toIso8601String(),
      };

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
