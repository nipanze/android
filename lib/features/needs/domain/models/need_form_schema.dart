enum NeedFieldType { text, number, date, boolean }

class NeedFormField {
  const NeedFormField({
    required this.key,
    required this.label,
    required this.hint,
    this.helperText,
    this.type = NeedFieldType.text,
    this.isRequired = true,
    this.options,
  });

  const NeedFormField.text(
    this.key, {
    required this.label,
    required this.hint,
    this.helperText,
    this.isRequired = true,
    this.options,
  }) : type = NeedFieldType.text;

  const NeedFormField.number(
    this.key, {
    required this.label,
    required this.hint,
    this.helperText,
    this.isRequired = true,
    this.options,
  }) : type = NeedFieldType.number;

  const NeedFormField.date(
    this.key, {
    required this.label,
    required this.hint,
    this.helperText,
    this.isRequired = true,
    this.options,
  }) : type = NeedFieldType.date;

  const NeedFormField.boolean(
    this.key, {
    required this.label,
    this.hint = '',
    this.helperText,
    this.isRequired = false,
    this.options,
  }) : type = NeedFieldType.boolean;

  final String key;
  final String label;
  final String hint;
  final String? helperText;
  final NeedFieldType type;
  final bool isRequired;
  final List<String>? options;
}

class NeedFormGuidance {
  const NeedFormGuidance({
    required this.titleHint,
    required this.specificationHint,
    required this.specificationHelper,
  });

  final String titleHint;
  final String specificationHint;
  final String specificationHelper;
}

class NeedFormSchema {
  static const Map<String, NeedFormGuidance> categoryGuidance = {
    'machinery_equipment': NeedFormGuidance(
      titleHint: 'e.g. Rent a 20-tonne excavator for 2 weeks',
      specificationHint: 'Describe the machine, work site, and rental period',
      specificationHelper:
          'Include the model or capacity, location, dates, and whether you need an operator.',
    ),
    'professional_services': NeedFormGuidance(
      titleHint: 'e.g. Find an accountant for my small business',
      specificationHint: 'Describe the task and the result you need',
      specificationHelper:
          'Explain the work, expected deliverable, deadline, and any qualifications or experience required.',
    ),
    'transport_logistics': NeedFormGuidance(
      titleHint: 'e.g. Move 20 tonnes of maize from Gulu to Kampala',
      specificationHint: 'Describe the cargo and the journey',
      specificationHelper:
          'Include pickup and drop-off points, cargo size or weight, preferred dates, and loading needs.',
    ),
    'specialized_products': NeedFormGuidance(
      titleHint: 'e.g. Source 50 Epson printers for my office',
      specificationHint: 'Name the product, quantity, and delivery location',
      specificationHelper:
          'Share the exact model or specifications, quantity, quality expectations, and latest delivery date.',
    ),
    'education_training': NeedFormGuidance(
      titleHint: 'e.g. Find a weekend math tutor for Senior 4',
      specificationHint:
          'Describe the subject, level, and kind of support you need',
      specificationHelper:
          'Include your current level, preferred format or schedule, start date, and any goals.',
    ),
    'travel_international': NeedFormGuidance(
      titleHint: 'e.g. Help plan a December trip to Sweden',
      specificationHint:
          'Describe your destination and the travel service you need',
      specificationHelper:
          'Include destination, travel dates, number of travellers, and services needed. Do not post passport numbers or private document details.',
    ),
    'construction_building': NeedFormGuidance(
      titleHint: 'e.g. Find a contractor to replace my house roof',
      specificationHint: 'Describe the work, property, and materials involved',
      specificationHelper:
          'Include the site location, approximate measurements, materials, and when the work should start.',
    ),
    'agriculture_agribusiness': NeedFormGuidance(
      titleHint: 'e.g. Find a maize harvester for my farm',
      specificationHint: 'Describe the farm need, quantity, and location',
      specificationHelper:
          'Include the crop or input, quantity or acreage, farm location, and when you need it.',
    ),
    'technology_digital': NeedFormGuidance(
      titleHint: 'e.g. Build an online shop for my business',
      specificationHint: 'Describe what you want built or fixed',
      specificationHelper:
          'List the main features, users or devices, expected deliverables, and preferred timeline.',
    ),
    'events_production': NeedFormGuidance(
      titleHint: 'e.g. Find a caterer for a 200-guest gala',
      specificationHint: 'Describe the event and the service you need',
      specificationHelper:
          'Include the event date, guest count, venue or town, and the services or equipment required.',
    ),
    'music_video': NeedFormGuidance(
      titleHint: 'e.g. Find a videographer for a music video',
      specificationHint:
          'Describe the production and the people or services needed',
      specificationHelper:
          'Include the project type, shoot or performance date, location, and any style or deliverable requirements.',
    ),
    'weddings_celebrations': NeedFormGuidance(
      titleHint: 'e.g. Book a photographer for a wedding in Entebbe',
      specificationHint: 'Describe the celebration and the service you need',
      specificationHelper:
          'Include the occasion, date, venue or town, guest count, and any style or package preferences.',
    ),
    'energy_utilities': NeedFormGuidance(
      titleHint: 'e.g. Install solar power at my poultry farm',
      specificationHint: 'Describe the system and where it will be installed',
      specificationHelper:
          'Include the power or water needs, site location, system size if known, and whether installation is required.',
    ),
  };

  static const Map<String, List<NeedFormField>> categoryFields = {
    'education_training': [
      NeedFormField.text(
        'training_type',
        label: 'Training Type',
        hint: 'e.g. Internship, tutoring, professional or vocational training',
      ),
      NeedFormField.text(
        'training_level',
        label: 'Training Level',
        hint: 'e.g. Beginner, intermediate, advanced, university',
      ),
      NeedFormField.text(
        'preferred_format',
        label: 'Preferred Format',
        hint: 'Choose online, in-person, or either',
        options: ['Online', 'In-person', 'Either'],
      ),
      NeedFormField.text(
        'preferred_location',
        label: 'Preferred Location',
        hint: 'e.g. Near campus, home, or a specific area',
      ),
      NeedFormField.text(
        'max_travel_distance',
        label: 'Maximum Travel Distance',
        hint: 'Choose a maximum distance',
        options: ['2 km', '5 km', '10 km', '20 km', 'Anywhere'],
      ),
      NeedFormField.text(
        'start_date',
        label: 'Start Date',
        hint: 'e.g. June 2026 or as soon as possible',
      ),
      NeedFormField.text(
        'duration',
        label: 'Duration',
        hint: 'e.g. 8 weeks, 3 months, or flexible',
      ),
      NeedFormField.text(
        'schedule',
        label: 'Schedule',
        hint: 'e.g. Full-time, part-time, weekends, flexible',
      ),
      NeedFormField.text(
        'required_qualifications',
        label: 'Required Qualifications / Experience',
        hint: 'e.g. Current university student, prior experience',
        isRequired: false,
      ),
      NeedFormField.text(
        'specific_skills_topics',
        label: 'Specific Skills / Topics',
        hint: 'e.g. Software development, accounting, academic writing',
      ),
      NeedFormField.text(
        'additional_requirements',
        label: 'Additional Requirements',
        hint: 'Anything else providers should know',
        isRequired: false,
      ),
    ],
    'travel_international': [
      NeedFormField.text(
        'destination_country',
        label: 'Destination country',
        hint: 'e.g. UAE, Sweden, Saudi Arabia',
        helperText: 'Enter each country if your trip has multiple stops.',
      ),
      NeedFormField.text(
        'destination_city',
        label: 'Destination city',
        hint: 'e.g. Dubai, Stockholm, Jeddah',
        helperText: 'Add the city or area you plan to visit, if known.',
      ),
      NeedFormField.text(
        'travel_date',
        label: 'Intended travel date or month',
        hint: 'e.g. December 2026',
        helperText:
            'An approximate month is fine; select flexible dates below if needed.',
      ),
      NeedFormField.date(
        'return_date',
        label: 'Return date (if applicable)',
        hint: 'e.g. 15 January 2027',
        helperText: 'Leave this blank if you are not sure of your return date.',
      ),
      NeedFormField.number(
        'travellers',
        label: 'Number of travellers',
        hint: 'e.g. 1',
        helperText: 'Include everyone travelling, including children.',
      ),
      NeedFormField.text(
        'purpose',
        label: 'Purpose of travel',
        hint: 'e.g. Tourism, business, study, family visit',
        helperText:
            'This helps providers suggest relevant bookings and requirements.',
      ),
      NeedFormField.text(
        'service_needed',
        label: 'Service needed',
        hint: 'e.g. Visa assistance, flight ticket, Hajj / Umrah support',
        helperText:
            'List each service you need, such as tickets, accommodation, or itinerary help.',
      ),
      NeedFormField.text(
        'visa_type',
        label: 'Visa type',
        hint: 'e.g. Tourist visa, business visa, transit visa',
        helperText:
            'If you are unsure, describe your trip purpose instead of guessing.',
      ),
      NeedFormField.text(
        'nationality',
        label: 'Traveller nationality',
        hint: 'e.g. Ugandan, Kenyan',
        helperText:
            'Visa requirements can depend on nationality. Do not enter passport numbers.',
      ),
      NeedFormField.text(
        'departure_city',
        label: 'Departure city',
        hint: 'e.g. Kampala, Nairobi',
        helperText: 'Enter the city you expect to start your journey from.',
      ),
      NeedFormField.boolean(
        'flexible_dates',
        label: 'Flexible dates are acceptable',
        helperText:
            'Turn this on if you can travel on nearby dates for better options.',
      ),
      NeedFormField.text(
        'additional_requirements',
        label: 'Additional requirements',
        hint: 'e.g. Hotel booking, passport renewal help, visa checklist',
        helperText:
            'Add preferences or constraints, but do not share private document details.',
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
