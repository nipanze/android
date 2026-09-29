class NeedCapability {
  const NeedCapability({
    required this.slug,
    required this.categorySlug,
    required this.name,
    this.isActive = true,
  });

  factory NeedCapability.fromMap(Map<String, dynamic> map) {
    return NeedCapability(
      slug: map['slug'] as String,
      categorySlug: map['category_slug'] as String,
      name: map['name'] as String,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  final String slug;
  final String categorySlug;
  final String name;
  final bool isActive;

  static const List<NeedCapability> defaults = [
    NeedCapability(
      slug: 'visa_assistance',
      categorySlug: 'travel_international',
      name: 'Visa Assistance',
    ),
    NeedCapability(
      slug: 'flight_tickets',
      categorySlug: 'travel_international',
      name: 'Flight Tickets & Bookings',
    ),
    NeedCapability(
      slug: 'hajj_umrah',
      categorySlug: 'travel_international',
      name: 'Hajj & Umrah Travel',
    ),
    NeedCapability(
      slug: 'excavator_hire',
      categorySlug: 'machinery_equipment',
      name: 'Excavator Hire',
    ),
    NeedCapability(
      slug: 'tractor_hire',
      categorySlug: 'machinery_equipment',
      name: 'Tractor & Farm Machinery',
    ),
    NeedCapability(
      slug: 'generator_hire',
      categorySlug: 'machinery_equipment',
      name: 'Industrial Generators',
    ),
    NeedCapability(
      slug: 'company_registration',
      categorySlug: 'professional_services',
      name: 'Company Registration & Legal',
    ),
    NeedCapability(
      slug: 'accounting_tax',
      categorySlug: 'professional_services',
      name: 'Accounting & Tax Advisory',
    ),
    NeedCapability(
      slug: 'engineering_consulting',
      categorySlug: 'professional_services',
      name: 'Engineering Consulting',
    ),
    NeedCapability(
      slug: 'heavy_haulage',
      categorySlug: 'transport_logistics',
      name: 'Heavy Freight & Bulk Haulage',
    ),
    NeedCapability(
      slug: 'courier_delivery',
      categorySlug: 'transport_logistics',
      name: 'Courier & Express Delivery',
    ),
    NeedCapability(
      slug: 'cold_chain_transport',
      categorySlug: 'transport_logistics',
      name: 'Cold Chain & Refrigerated',
    ),
    NeedCapability(
      slug: 'bulk_procurement',
      categorySlug: 'specialized_products',
      name: 'Bulk Industrial Procurement',
    ),
    NeedCapability(
      slug: 'medical_supplies',
      categorySlug: 'specialized_products',
      name: 'Medical & Lab Supplies',
    ),
    NeedCapability(
      slug: 'electronic_hardware',
      categorySlug: 'specialized_products',
      name: 'Specialized Electronics & Parts',
    ),
  ];
}
