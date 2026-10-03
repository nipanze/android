enum NeedFieldType { text, number, date, boolean }

class NeedFormField {
  const NeedFormField({
    required this.key,
    required this.label,
    required this.hint,
    this.type = NeedFieldType.text,
    this.isRequired = true,
  });

  const NeedFormField.text(
    this.key, {
    required this.label,
    required this.hint,
    this.isRequired = true,
  }) : type = NeedFieldType.text;

  const NeedFormField.number(
    this.key, {
    required this.label,
    required this.hint,
    this.isRequired = true,
  }) : type = NeedFieldType.number;

  const NeedFormField.date(
    this.key, {
    required this.label,
    required this.hint,
    this.isRequired = true,
  }) : type = NeedFieldType.date;

  const NeedFormField.boolean(
    this.key, {
    required this.label,
    this.hint = '',
    this.isRequired = false,
  }) : type = NeedFieldType.boolean;

  final String key;
  final String label;
  final String hint;
  final NeedFieldType type;
  final bool isRequired;
}

class NeedFormSchema {
  static const Map<String, List<NeedFormField>> categoryFields = {
    'education_training': [
      NeedFormField.text(
        'course_field',
        label: 'Course / Field of Study',
        hint: 'e.g. Computer Science, Nursing, Accounting',
      ),
      NeedFormField.text(
        'preferred_role',
        label: 'Preferred Internship Role',
        hint: 'e.g. Software Development Intern, Marketing Intern',
      ),
      NeedFormField.text(
        'preferred_location',
        label: 'Preferred Location',
        hint: 'e.g. Kampala, Kansanga, Mukono',
      ),
      NeedFormField.text(
        'location_preference',
        label: 'Location Preference',
        hint: 'Near Campus, Near Home, Specific Area, Anywhere',
      ),
      NeedFormField.text(
        'max_travel_distance',
        label: 'Maximum Travel Distance',
        hint: 'e.g. 5 km, 10 km, Anywhere',
      ),
      NeedFormField.text(
        'start_date',
        label: 'Start Date',
        hint: 'e.g. June 2026',
      ),
      NeedFormField.text(
        'duration',
        label: 'Duration',
        hint: 'e.g. 8 weeks, 3 months',
      ),
      NeedFormField.text(
        'schedule',
        label: 'Schedule',
        hint: 'e.g. Full-time, Weekends, Flexible',
      ),
      NeedFormField.text(
        'max_budget',
        label: 'Maximum Budget',
        hint: 'e.g. Free / No placement fee, Up to UGX 300,000, Open to offers',
      ),
      NeedFormField.text(
        'university_requirements',
        label: 'University Requirements',
        hint: 'e.g. Course credit, 8-week requirement, report submission',
      ),
      NeedFormField.text(
        'skills_interests',
        label: 'Skills / Interests',
        hint: 'e.g. Web development, data analysis, design',
      ),
      NeedFormField.text(
        'additional_requirements',
        label: 'Additional Requirements',
        hint: 'e.g. Remote-friendly, evening schedule, transport support',
      ),
    ],
    'travel_international': [
      NeedFormField.text(
        'destination_country',
        label: 'Destination country',
        hint: 'e.g. UAE, Sweden, Saudi Arabia',
      ),
      NeedFormField.text(
        'destination_city',
        label: 'Destination city',
        hint: 'e.g. Dubai, Stockholm, Jeddah',
      ),
      NeedFormField.text(
        'travel_date',
        label: 'Intended travel date or month',
        hint: 'e.g. December 2026',
      ),
      NeedFormField.date(
        'return_date',
        label: 'Return date (if applicable)',
        hint: 'e.g. 15 January 2027',
      ),
      NeedFormField.number(
        'travellers',
        label: 'Number of travellers',
        hint: 'e.g. 1',
      ),
      NeedFormField.text(
        'purpose',
        label: 'Purpose of travel',
        hint: 'e.g. Tourism, business, study, family visit',
      ),
      NeedFormField.text(
        'service_needed',
        label: 'Service needed',
        hint: 'e.g. Visa assistance, flight ticket, Hajj / Umrah support',
      ),
      NeedFormField.text(
        'visa_type',
        label: 'Visa type',
        hint: 'e.g. Tourist visa, business visa, transit visa',
      ),
      NeedFormField.text(
        'nationality',
        label: 'Traveller nationality',
        hint: 'e.g. Ugandan, Kenyan',
      ),
      NeedFormField.text(
        'departure_city',
        label: 'Departure city',
        hint: 'e.g. Kampala, Nairobi',
      ),
      NeedFormField.boolean(
        'flexible_dates',
        label: 'Flexible dates are acceptable',
      ),
      NeedFormField.text(
        'additional_requirements',
        label: 'Additional requirements',
        hint: 'e.g. Hotel booking, passport renewal help, visa checklist',
      ),
    ],
    'machinery_equipment': [
      NeedFormField.text(
        'equipment_type',
        label: 'Equipment model or type',
        hint: 'e.g. CAT 320 Excavator, 50kVA Generator',
      ),
      NeedFormField.number(
        'duration_days',
        label: 'Duration (days or months)',
        hint: 'e.g. 30',
      ),
      NeedFormField.boolean(
        'operator_needed',
        label: 'Machine operator required',
      ),
    ],
    'professional_services': [
      NeedFormField.text(
        'service_type',
        label: 'Specialist service required',
        hint: 'e.g. Company tax audit, Patent filing',
      ),
      NeedFormField.text(
        'deadline',
        label: 'Target deadline or timeline',
        hint: 'e.g. End of next month',
      ),
      NeedFormField.text(
        'deliverable',
        label: 'Expected output / deliverable',
        hint: 'e.g. Signed URA audit report',
      ),
    ],
    'transport_logistics': [
      NeedFormField.text(
        'from_location',
        label: 'Pickup location',
        hint: 'e.g. Kampala Industrial Area',
      ),
      NeedFormField.text(
        'to_location',
        label: 'Dropoff destination',
        hint: 'e.g. Gulu Town',
      ),
      NeedFormField.text(
        'load_description',
        label: 'Cargo / weight description',
        hint: 'e.g. 20 tonnes of bagged cement',
      ),
    ],
    'specialized_products': [
      NeedFormField.text(
        'product_name',
        label: 'Exact product / part name',
        hint: 'e.g. 50 Epson L3150 printers',
      ),
      NeedFormField.text(
        'quantity',
        label: 'Quantity or volume',
        hint: 'e.g. 50 units',
      ),
      NeedFormField.text(
        'delivery_location',
        label: 'Delivery destination',
        hint: 'e.g. Mbarara warehouse',
      ),
    ],
    'construction_building': [
      NeedFormField.text(
        'project_type',
        label: 'Construction or work type',
        hint: 'e.g. Residential roofing, Commercial plumbing',
      ),
      NeedFormField.text(
        'site_location',
        label: 'Site / property location',
        hint: 'e.g. Mukono plot 45',
      ),
      NeedFormField.text(
        'project_scope',
        label: 'Scope & materials needed',
        hint: 'e.g. 200 sqm roof replacement, contractor to provide timber',
      ),
    ],
    'agriculture_agribusiness': [
      NeedFormField.text(
        'agri_item',
        label: 'Commodity, machinery or inputs',
        hint: 'e.g. Hybrid maize seeds, Combine harvester hire',
      ),
      NeedFormField.text(
        'farm_location',
        label: 'Farm / district location',
        hint: 'e.g. Nakasongola farm block',
      ),
      NeedFormField.text(
        'volume_or_acres',
        label: 'Quantity, acreage or duration',
        hint: 'e.g. 50 bags / 20 acres',
      ),
    ],
    'technology_digital': [
      NeedFormField.text(
        'tech_requirement',
        label: 'Project or tech requirement',
        hint: 'e.g. E-commerce Flutter app, Office CCTV networking',
      ),
      NeedFormField.text(
        'deliverables',
        label: 'Key features / deliverables',
        hint: 'e.g. Mobile app on Play Store, Admin portal',
      ),
      NeedFormField.text(
        'timeline',
        label: 'Desired completion timeline',
        hint: 'e.g. 6 weeks',
      ),
    ],
    'events_production': [
      NeedFormField.text(
        'event_type',
        label: 'Event type & guest count',
        hint: 'e.g. Corporate gala dinner (200 guests)',
      ),
      NeedFormField.date(
        'event_date',
        label: 'Event date',
        hint: 'e.g. 15 November 2026',
      ),
      NeedFormField.text(
        'venue_location',
        label: 'Venue or town',
        hint: 'e.g. Serena Hotel gardens, Kampala',
      ),
    ],
    'music_video': [
      NeedFormField.text(
        'production_type',
        label: 'Music or video project',
        hint: 'e.g. Music video, live session, short film',
      ),
      NeedFormField.date(
        'shoot_date',
        label: 'Shoot or performance date',
        hint: 'e.g. 15 November 2026',
      ),
      NeedFormField.text(
        'location',
        label: 'Studio, venue, or town',
        hint: 'e.g. Kampala',
      ),
    ],
    'weddings_celebrations': [
      NeedFormField.text(
        'celebration_type',
        label: 'Celebration type and guest count',
        hint: 'e.g. Wedding reception, 150 guests',
      ),
      NeedFormField.date(
        'event_date',
        label: 'Event date',
        hint: 'e.g. 15 November 2026',
      ),
      NeedFormField.text(
        'venue_location',
        label: 'Venue or town',
        hint: 'e.g. Entebbe',
      ),
    ],
    'energy_utilities': [
      NeedFormField.text(
        'system_type',
        label: 'Power or utility system',
        hint: 'e.g. 10kW Commercial Solar System, Borehole pump',
      ),
      NeedFormField.text(
        'installation_site',
        label: 'Installation location / facility',
        hint: 'e.g. Poultry farm, Masaka',
      ),
      NeedFormField.boolean(
        'installation_labor_needed',
        label: 'Installation & commissioning labor required',
      ),
    ],
  };

  static List<NeedFormField> fieldsForCategory(String slug) {
    return categoryFields[slug] ??
        const [
          NeedFormField.text(
            'details_note',
            label: 'Additional specifics',
            hint: 'Describe any specific requirements',
            isRequired: false,
          ),
        ];
  }
}
