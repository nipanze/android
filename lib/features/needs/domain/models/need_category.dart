class NeedCategory {
  const NeedCategory({
    required this.slug,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory NeedCategory.fromMap(Map<String, dynamic> map) {
    return NeedCategory(
      slug: map['slug'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '🔎',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  final String slug;
  final String name;
  final String icon;
  final int sortOrder;
  final bool isActive;

  static const List<NeedCategory> defaultCategories = [
    NeedCategory(
      slug: 'travel_international',
      name: 'Travel & International',
      icon: '✈️',
      sortOrder: 1,
      isActive: true,
    ),
    NeedCategory(
      slug: 'machinery_equipment',
      name: 'Machinery & Equipment',
      icon: '🚜',
      sortOrder: 2,
      isActive: true,
    ),
    NeedCategory(
      slug: 'professional_services',
      name: 'Professional Services',
      icon: '🧑‍💼',
      sortOrder: 3,
      isActive: true,
    ),
    NeedCategory(
      slug: 'transport_logistics',
      name: 'Transport & Logistics',
      icon: '🚚',
      sortOrder: 4,
      isActive: true,
    ),
    NeedCategory(
      slug: 'specialized_products',
      name: 'Specialized Products & Procurement',
      icon: '🔎',
      sortOrder: 5,
      isActive: true,
    ),
  ];

  static NeedCategory findBySlug(String slug) {
    return defaultCategories.firstWhere(
      (c) => c.slug == slug,
      orElse: () => NeedCategory(
        slug: slug,
        name: slug,
        icon: '🔎',
      ),
    );
  }
}
