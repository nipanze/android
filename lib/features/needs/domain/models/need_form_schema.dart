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

  String get guidance {
    final helper = helperText?.trim();
    if (helper != null && helper.isNotEmpty) return helper;
    final fieldHint = hint.trim();
    if (fieldHint.isNotEmpty) {
      final examplePrefix = RegExp(r'^e\.g\.\s*', caseSensitive: false);
      if (examplePrefix.hasMatch(fieldHint)) {
        return 'For example, ${fieldHint.replaceFirst(examplePrefix, '')}';
      }
      return fieldHint;
    }
    return 'Select this if it applies to your request.';
  }
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

class NeedFormPreset {
  const NeedFormPreset({
    required this.label,
    required this.title,
    required this.specification,
    this.specificationVariants = const [],
    this.details = const {},
    this.budget,
    this.urgency,
  });

  final String label;
  final String title;
  final String specification;
  final List<String> specificationVariants;
  final Map<String, String> details;
  final int? budget;
  final String? urgency;
}

class NeedFormSchema {
  static String _canonicalCategorySlug(String slug) =>
      slug == 'photo_video_music_talent' ? 'photo_video_talent' : slug;

  static const Map<String, NeedFormGuidance> categoryGuidance = {
    'machinery_equipment': NeedFormGuidance(
      titleHint: 'Looking for [equipment needed]',
      specificationHint: 'Add machine or rental requirements not covered above',
      specificationHelper:
          'Mention required capacity, attachments, condition, or site constraints.',
    ),
    'professional_services': NeedFormGuidance(
      titleHint: 'e.g. I need an accountant for my small business',
      specificationHint:
          'Add any extra requirements not covered by the fields above',
      specificationHelper:
          'Mention required qualifications, relevant experience, or special constraints.',
    ),
    'transport_logistics': NeedFormGuidance(
      titleHint: 'I need transport for [cargo needed]',
      specificationHint: 'Add cargo or handling requirements not covered above',
      specificationHelper:
          'Mention fragile items, loading support, or special handling needs.',
    ),
    'specialized_products': NeedFormGuidance(
      titleHint: 'Looking for [product or part needed]',
      specificationHint:
          'Add any other requirements not covered by the fields above',
      specificationHelper:
          'Include compatibility, quality standards, packaging, or acceptable alternatives.',
    ),
    'education_training': NeedFormGuidance(
      titleHint: 'e.g. I need help reaching a learning goal',
      specificationHint: 'Add learning requirements not covered above',
      specificationHelper:
          'Include learning goals, preferred teaching approach, or any constraints.',
    ),
    'travel_international': NeedFormGuidance(
      titleHint: 'e.g. I want help planning a December trip to Sweden',
      specificationHint: 'Add preferences or constraints not covered above',
      specificationHelper:
          'Mention travel preferences not covered above. Do not share passport numbers or private document details.',
    ),
    'construction_building': NeedFormGuidance(
      titleHint: 'e.g. Need a contractor to replace my house roof',
      specificationHint:
          'Add any extra requirements not covered by the fields above',
      specificationHelper:
          'Mention access constraints, finish preferences, or special site conditions.',
    ),
    'agriculture_agribusiness': NeedFormGuidance(
      titleHint: 'e.g. I need a maize harvester for my farm',
      specificationHint: 'Add farm, supply, or service requirements',
      specificationHelper:
          'Mention quality, delivery, production volume, or timing preferences.',
    ),
    'technology_digital': NeedFormGuidance(
      titleHint: 'e.g. I want an online shop for my business',
      specificationHint: 'Add other requirements not covered above',
      specificationHelper:
          'Include important features, users or devices, and any constraints.',
    ),
    'marketing_promotion': NeedFormGuidance(
      titleHint: 'e.g. I need to promote my new product',
      specificationHint: 'Add campaign requirements not covered above',
      specificationHelper:
          'Include brand guidelines, campaign constraints, or success measures.',
    ),
    'events_production': NeedFormGuidance(
      titleHint: 'e.g. Looking for catering for a 200-guest gala',
      specificationHint: 'Add requirements not covered by the event fields',
      specificationHelper:
          'Include service details, setup, or special requests.',
    ),
    'music_video': NeedFormGuidance(
      titleHint: 'e.g. I need a videographer for a music video',
      specificationHint: 'Add creative or production requirements',
      specificationHelper:
          'Describe the concept, style, crew, equipment, or delivery needs.',
    ),
    'weddings_celebrations': NeedFormGuidance(
      titleHint: 'e.g. Looking to book a wedding photographer in Kampala',
      specificationHint: 'Add style or service requirements not covered above',
      specificationHelper:
          'Mention package preferences, setup needs, or special requests.',
    ),
    'energy_utilities': NeedFormGuidance(
      titleHint: 'e.g. I need a reliable power system for my site',
      specificationHint: 'Add power or water requirements not covered above',
      specificationHelper:
          'Include expected demand, usage patterns, or special site constraints.',
    ),
    'events_celebrations': NeedFormGuidance(
      titleHint: 'e.g. I need catering for a family celebration',
      specificationHint:
          'Add event requirements not covered by the fields above',
      specificationHelper:
          'Mention service details, setup, or special requests.',
    ),
    'photo_video_talent': NeedFormGuidance(
      titleHint: 'e.g. I need a photographer for a product launch',
      specificationHint:
          'Add style, skills, schedule, or usage rights not in your title',
      specificationHelper:
          'For talent bookings, include role-related skills, style, language, availability, and usage rights.',
    ),
    'beauty_fashion_styling': NeedFormGuidance(
      titleHint: 'e.g. I need a massage therapist for a wellness day',
      specificationHint: 'Add wellness or preparation preferences',
      specificationHelper:
          'Mention service style, duration, products, accessibility, or preferred setting.',
    ),
    'domestic_household': NeedFormGuidance(
      titleHint: 'e.g. I need help cleaning my home each week',
      specificationHint: 'Add household requirements not covered above',
      specificationHelper:
          'Mention routines, access needs, or household preferences.',
    ),
    'health_medical': NeedFormGuidance(
      titleHint: 'e.g. I need help arranging a dental appointment',
      specificationHint: 'Add care or access requirements not covered above',
      specificationHelper:
          'Share scheduling or accessibility needs. Avoid posting private medical records.',
    ),
    'traditional_cultural': NeedFormGuidance(
      titleHint: 'e.g. I need performers for a cultural celebration',
      specificationHint: 'Add cultural or event requirements',
      specificationHelper:
          'Mention traditions, program details, or participant needs.',
    ),
    'financial_services': NeedFormGuidance(
      titleHint: 'e.g. I want to compare business financing options',
      specificationHint: 'Add financial requirements not covered above',
      specificationHelper:
          'Mention timing, repayment preferences, or eligibility questions. Do not share account numbers.',
    ),
  };

  static NeedFormGuidance guidanceForCategory(String slug) {
    return categoryGuidance[_canonicalCategorySlug(slug)] ??
        const NeedFormGuidance(
          titleHint: 'e.g. Briefly describe what you need',
          specificationHint: 'Add requirements not covered by the fields above',
          specificationHelper:
              'Mention special constraints, preferences, or expected outcomes.',
        );
  }

  static const Map<String, List<NeedFormPreset>> categoryPresets = {
    'education_training': [
      NeedFormPreset(
        label: 'Private tutor',
        title: 'I need a private tutor for [learner or learning goal]',
        specification:
            'My child is in Primary 5 and needs help with fractions and reading comprehension. I would like clear explanations, short practice exercises, and a progress update after each week.',
      ),
      NeedFormPreset(
        label: 'Tutor for a child',
        title: 'I need a tutor for my child',
        specification:
            'My child is 9 years old and needs patient support with reading and basic mathematics. Please use age-appropriate activities and share a short progress update after each lesson.',
      ),
      NeedFormPreset(
        label: 'School teacher',
        title: 'Our school needs a teacher for [class or learner group]',
        specification:
            'Our school needs a teacher for a class of 35 learners. The teacher should prepare weekly lesson plans, teach the national curriculum, and give a short learner progress report each month.',
      ),
      NeedFormPreset(
        label: 'School tutor',
        title: 'Our school needs a tutor for [class or learner group]',
        specification:
            'Our school needs extra mathematics support for 20 learners preparing for their end-of-term exams. Please include weekly practice and a simple way to track improvement.',
      ),
      NeedFormPreset(
        label: 'Lecturer',
        title: 'Our institution needs a lecturer for [learner group or level]',
        specification:
            'Our institution needs a lecturer to teach an introductory business course to diploma students. The work includes lesson preparation, assignments, marking, and learner feedback.',
      ),
      NeedFormPreset(
        label: 'Internship',
        title: 'Looking for an internship in [field]',
        specification:
            'I am seeking an eight-week business administration internship with supervised office tasks, practical record-keeping experience, and feedback from a mentor.',
        details: {
          'preferred_format': 'In-person',
          'duration': '8 weeks',
          'schedule': 'Full-time',
        },
      ),
      NeedFormPreset(
        label: 'Online course',
        title: 'I want an online course for [learner or learning goal]',
        specification:
            'I want an online digital marketing course with short guided lessons, practical assignments, and a certificate when I complete the work.',
        details: {
          'preferred_format': 'Online',
          'schedule': 'Flexible',
        },
      ),
      NeedFormPreset(
        label: 'Exam preparation',
        title: 'I want to prepare for [exam or qualification]',
        specification:
            'I am preparing for my nursing entrance exam and want a weekly study plan, practice questions, and feedback on the topics I find difficult.',
        details: {
          'preferred_format': 'Either',
          'schedule': 'Weekends',
        },
      ),
      NeedFormPreset(
        label: 'Language lessons',
        title: 'I want language lessons for [learner or learning goal]',
        specification:
            'I can hold a basic conversation and want to improve my listening and speaking for work. Please include conversation practice and simple exercises between lessons.',
        details: {
          'preferred_format': 'Online',
          'schedule': 'Flexible',
        },
      ),
      NeedFormPreset(
        label: 'Vocational training',
        title: 'I need vocational training for [learner or team]',
        specification:
            'I want hands-on tailoring training, including supervised practice with sewing equipment and a final project that shows the skills I have learned.',
        details: {
          'preferred_format': 'In-person',
        },
      ),
      NeedFormPreset(
        label: 'Career mentorship',
        title: 'I want guidance to grow in [career or field]',
        specification:
            'I am early in my career and want monthly guidance on building experience, improving my CV, and preparing for interviews.',
        details: {
          'preferred_format': 'Online',
          'schedule': 'Flexible',
        },
      ),
      NeedFormPreset(
        label: 'Skills instructor',
        title: 'I need an instructor for [learner or team]',
        specification:
            'I want learners to complete practical exercises and demonstrate each skill in a final hands-on assessment.',
      ),
    ],
    'travel_international': [
      NeedFormPreset(
        label: 'Guided tour',
        title: 'I want a guided tour of [destination]',
        specification:
            'I would like a relaxed half-day tour with time for photos and short walks. Please include a knowledgeable guide and tell me what activities are included.',
        details: {
          'travel_scope': 'Local tour',
          'purpose': 'Tourism',
        },
      ),
      NeedFormPreset(
        label: 'School trip van',
        title: 'I need a van for a school trip to [destination]',
        specification:
            'Our school is taking 35 students and 3 staff members from Kampala to Murchison Falls National Park for an educational day trip. We need passenger transport with seat belts and enough room for the group. Please confirm vehicle capacity, driver availability, pickup and return times, and space for bags.',
        specificationVariants: [
          'I am arranging a school visit for 28 students and 2 teachers from [pickup area] to [destination]. Please tell me how many passengers your van can carry, whether a driver is included, and what pickup and return times you can offer.',
          'Our class needs transport for a day trip to [destination] on [date]. We expect 32 students and 3 adults. Please share the available van capacity, safety features such as seat belts, and whether you can make the return trip.',
        ],
        details: {
          'travel_scope': 'Local tour',
          'destination_city': 'Murchison Falls National Park',
          'travellers': '38',
          'purpose': 'Tourism',
          'departure_city': 'Kampala',
          'tour_activities': 'Educational visit and nature walk',
        },
      ),
      NeedFormPreset(
        label: 'Visa help',
        title: 'Need help with a visa application',
        specification:
            'I am applying for a visitor visa and need help understanding the required documents, completing the application, and preparing for the appointment. Please explain each step clearly.',
        details: {
          'purpose': 'Tourism',
          'visa_type': 'Tourist visa',
        },
        urgency: 'Within 30 days',
      ),
      NeedFormPreset(
        label: 'Hajj package',
        title: 'Looking for a Hajj package',
        specification:
            'I am travelling for Hajj and need help with visa guidance, flights, accommodation, transport between sites, and support with the pilgrimage schedule.',
        details: {
          'destination_country': 'Saudi Arabia',
          'destination_city': 'Makkah and Madinah',
          'travellers': '1',
          'purpose': 'Hajj',
          'visa_type': 'Hajj visa',
          'flexible_dates': 'true',
        },
        urgency: 'Within 30 days',
      ),
      NeedFormPreset(
        label: 'Umrah package',
        title: 'I need an Umrah package',
        specification:
            'I am planning an Umrah trip and need visa guidance, flights, accommodation near the holy sites, local transport, and help understanding the trip schedule.',
        details: {
          'destination_country': 'Saudi Arabia',
          'destination_city': 'Makkah and Madinah',
          'travellers': '1',
          'purpose': 'Umrah',
          'visa_type': 'Umrah visa',
          'flexible_dates': 'true',
        },
        urgency: 'Within 30 days',
      ),
      NeedFormPreset(
        label: 'Flight package',
        title: 'I want to arrange flights and accommodation',
        specification:
            'I need help comparing flight times and accommodation options, then putting together a simple itinerary with time for sightseeing and rest.',
        details: {
          'travellers': '1',
          'purpose': 'Tourism',
          'flexible_dates': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Study abroad',
        title: 'Planning a study abroad trip',
        specification:
            'I have been accepted to study abroad and need help organizing travel documents, arrival-day instructions, and temporary accommodation for my first week.',
        details: {
          'purpose': 'Study',
          'visa_type': 'Student visa',
        },
      ),
      NeedFormPreset(
        label: 'Family visit',
        title: 'I need help planning an international family visit',
        specification:
            'I am arranging an international visit with my family and need help coordinating travel dates, accommodation, entry requirements, and transport after arrival.',
        details: {
          'purpose': 'Family visit',
          'flexible_dates': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Business trip',
        title: 'Looking for a business trip itinerary',
        specification:
            'I need a business trip plan that fits two meetings and one free afternoon. Please coordinate flight options, accommodation, and transport between appointments.',
        details: {
          'purpose': 'Business',
          'flexible_dates': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Medical travel',
        title: 'I want to travel abroad for medical care',
        specification:
            'I am travelling for scheduled medical appointments and need help coordinating travel dates, nearby accommodation, and transport that allows time to rest between visits.',
        details: {
          'purpose': 'Medical',
        },
      ),
      NeedFormPreset(
        label: 'Holiday trip',
        title: 'Planning a holiday abroad',
        specification:
            'I am planning a one-week holiday with a mix of sightseeing and rest days. Please suggest a practical itinerary and suitable travel and accommodation options.',
        details: {
          'purpose': 'Tourism',
          'flexible_dates': 'true',
        },
      ),
    ],
    'machinery_equipment': [
      NeedFormPreset(
        label: 'Equipment rental',
        title: 'I need [equipment needed] for a job site',
        specification:
            'I need reliable equipment for a two-week construction job. Please confirm the machine condition, included attachments, operator arrangements, and what happens if it needs repairs.',
        details: {
          'duration_days': '14',
          'operator_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Generator',
        title: 'I want a [generator type and capacity]',
        specification:
            'I need a generator to keep our shop refrigerators, lights, and point-of-sale system running during outages. Please recommend a suitable capacity and explain setup and fuel use.',
        details: {
          'duration_days': '7',
          'operator_needed': 'false',
        },
      ),
      NeedFormPreset(
        label: 'Excavator',
        title: 'Looking for an excavator for [project or site]',
        specification:
            'I need an excavator for foundation digging and soil removal. Please confirm bucket options, operator availability, daily working hours, and maintenance support.',
        details: {
          'duration_days': '7',
          'operator_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Farm machinery',
        title: 'I want farm machinery for [field work or acreage]',
        specification:
            'I need a tractor and plough for preparing five acres before planting. Please confirm the implement options, operator availability, and working hours per day.',
        details: {
          'duration_days': '3',
          'operator_needed': 'true',
        },
      ),
    ],
    'professional_services': [
      NeedFormPreset(
        label: 'Accounting',
        title: 'I need an accountant for [bookkeeping, tax, or audit]',
        specification:
            'I need monthly bookkeeping for a small shop, including sales, expenses, bank reconciliation, and a simple report I can review each month.',
        details: {
          'service_type': 'Accounting / tax support',
          'deadline': 'End of this month',
          'deliverable': 'Completed filing and summary report',
        },
      ),
      NeedFormPreset(
        label: 'Legal docs',
        title: 'Looking for legal document support for [document type]',
        specification:
            'I need a service agreement reviewed for payment terms, cancellation conditions, responsibilities, and any unclear clauses. Please provide a plain-language summary of suggested changes.',
        details: {
          'service_type': 'Legal document review',
          'deadline': 'Within 2 weeks',
          'deliverable': 'Reviewed documents and advice note',
        },
      ),
      NeedFormPreset(
        label: 'Tax filing',
        title: 'Need help with tax filing',
        specification:
            'I need help preparing and submitting this year’s business tax return. Please review my sales records, expense receipts, and prior filing before submission.',
        details: {
          'service_type': 'Tax filing',
          'deadline': 'End of this month',
          'deliverable': 'Completed tax return and filing confirmation',
        },
      ),
      NeedFormPreset(
        label: 'Business registration',
        title: 'I want help registering a [business type]',
        specification:
            'I am registering a small catering business. Please help prepare the registration forms, confirm the required supporting documents, and provide copies of the completed filings.',
        details: {
          'service_type': 'Business registration',
          'deadline': 'Within 2 weeks',
          'deliverable': 'Completed registration and required documents',
        },
      ),
      NeedFormPreset(
        label: 'Contract review',
        title: 'Looking for legal support to review a [contract type]',
        specification:
            'I need a supplier contract checked for delivery obligations, payment terms, renewal conditions, and termination clauses. Please explain any risks in straightforward language.',
        details: {
          'service_type': 'Legal support',
          'deadline': 'Within 2 weeks',
          'deliverable': 'Reviewed contract and summary of key risks',
        },
      ),
      NeedFormPreset(
        label: 'Business consulting',
        title: 'I need a business consultant for [business challenge]',
        specification:
            'My small shop has many customers but few repeat purchases. I need practical recommendations for improving customer retention and a simple action plan my team can follow.',
        details: {
          'service_type': 'Business consulting',
          'deadline': 'Within 2 weeks',
          'deliverable': 'Recommendations and an actionable plan',
        },
      ),
      NeedFormPreset(
        label: 'HR support',
        title: 'Looking for support with [hiring or HR need]',
        specification:
            'I need help writing a clear job description, screening applications, and preparing interview questions for a sales assistant role.',
        details: {
          'service_type': 'HR services',
          'deadline': 'Within 2 weeks',
          'deliverable': 'Hiring plan or improved HR process',
        },
      ),
      NeedFormPreset(
        label: 'Engineering advice',
        title: 'Need an engineer for [discipline or project]',
        specification:
            'I need a structural engineer to review a proposed two-storey extension, check the drawings and load assumptions, and provide written recommendations before construction.',
        details: {
          'service_type': 'Engineering consulting',
          'deadline': 'Within 2 weeks',
          'deliverable': 'Technical assessment and recommendations',
        },
      ),
      NeedFormPreset(
        label: 'Architectural design',
        title: 'I want an architect for [building or interior project]',
        specification:
            'I need concept drawings for a three-bedroom family home with good natural light, cross-ventilation, and an open kitchen and living area.',
        details: {
          'service_type': 'Architecture',
          'deadline': 'Within 2 weeks',
          'deliverable': 'Concept design and drawing package',
        },
      ),
      NeedFormPreset(
        label: 'Business administration',
        title: 'Looking for help with [business administration task]',
        specification:
            'I need help organizing invoices, updating customer records, and preparing a weekly task list so our small office can find documents quickly.',
        details: {
          'service_type': 'Business administration',
          'deadline': 'Within 2 weeks',
          'deliverable': 'Organized records and documented admin process',
        },
      ),
      NeedFormPreset(
        label: 'Project management',
        title: 'I need a project manager for [project type]',
        specification:
            'I need a project manager to coordinate a website launch across design, development, content, and review. Please maintain a task schedule and send a short progress update each week.',
        details: {
          'service_type': 'Project management',
          'deadline': 'Within 2 weeks',
          'deliverable': 'Project plan, schedule, and progress reporting',
        },
      ),
    ],
    'transport_logistics': [
      NeedFormPreset(
        label: 'Cargo move',
        title: 'Looking for transport for [cargo needed]',
        specification:
            'I need a covered truck to move boxed household goods and two fragile appliances. Please secure the load and confirm when it has been collected and delivered.',
        details: const {},
      ),
      NeedFormPreset(
        label: 'Delivery run',
        title: 'I need delivery for [items needed]',
        specification:
            'I need three cartons and a small package collected, delivered without damage, and handed to the recipient with confirmation.',
        details: const {},
      ),
      NeedFormPreset(
        label: 'House move',
        title: 'Looking for help moving [household or office items]',
        specification:
            'I am moving a two-bedroom home with a sofa, beds, and fragile kitchen items. I need help loading, protecting the fragile items, and unloading everything carefully.',
      ),
      NeedFormPreset(
        label: 'Building materials',
        title: 'I need transport for [building materials]',
        specification:
            'I need cement bags and steel bars delivered for a building project. Please keep the materials dry, secure the load, and unload them safely.',
      ),
      NeedFormPreset(
        label: 'Farm produce',
        title: 'Looking for transport for [produce or livestock]',
        specification:
            'I need fresh tomatoes and leafy vegetables transported in ventilated crates to reduce bruising and heat damage. Please handle the produce carefully and deliver it promptly.',
      ),
      NeedFormPreset(
        label: 'Business deliveries',
        title: 'I need regular deliveries for [business or route]',
        specification:
            'Our shop needs weekday deliveries of packaged orders, with each parcel checked against a collection list and handed to the named recipient.',
      ),
    ],
    'specialized_products': [
      NeedFormPreset(
        label: 'Bulk purchase',
        title: 'Need [product] in bulk',
        specification:
            'I need 50 stainless-steel water bottles for staff use. Please confirm the material grade, leak-proof lids, and whether the bottles can be supplied in mixed colors.',
        details: {
          'quantity': '50 units',
        },
      ),
      NeedFormPreset(
        label: 'Hard-to-find part',
        title: 'Looking for [part needed]',
        specification:
            'I need a replacement alternator for a Toyota Hilux. Please confirm the part number and compatibility with the vehicle model before supply.',
        details: {
          'quantity': '1 unit',
        },
      ),
      NeedFormPreset(
        label: 'Office equipment',
        title: 'I need [office equipment needed]',
        specification:
            'I need a heavy-duty office printer that supports network printing and duplex pages. Please include the condition, included accessories, and warranty details.',
        details: {
          'quantity': '1 unit',
        },
      ),
      NeedFormPreset(
        label: 'Building supplies',
        title: 'Looking for [building supplies needed]',
        specification:
            'I need roofing sheets and timber for a small house. Please confirm the sheet gauge, timber dimensions, treatment, and whether equivalent grades are available.',
        details: {
          'quantity': '50 units',
        },
      ),
      NeedFormPreset(
        label: 'Safety supplies',
        title: 'Need [safety supplies needed]',
        specification:
            'I need construction safety helmets, reflective vests, and gloves for a work crew. Please confirm available sizes and the safety standards each item meets.',
        details: {
          'quantity': '10 units',
        },
      ),
    ],
    'construction_building': [
      NeedFormPreset(
        label: 'Replace a roof',
        title: 'I need a contractor for a roof replacement',
        specification:
            'The existing iron-sheet roof leaks in several places. I need the damaged sheets removed, a durable replacement installed, and the occupied rooms protected from dust and rain during the work.',
        details: {
          'project_type': 'Roofing',
          'project_scope':
              'Remove the old roof and install new roofing materials',
        },
      ),
      NeedFormPreset(
        label: 'Repair water pipes',
        title: 'Looking for a plumber to repair water pipes',
        specification:
            'A water pipe under the kitchen sink is leaking. I need the source identified, the damaged section replaced, and the area checked for leaks before the work is finished.',
        details: {
          'project_type': 'Plumbing',
          'project_scope': 'Find and repair leaks in the water supply pipes',
        },
      ),
      NeedFormPreset(
        label: 'Install electrical wiring',
        title: 'Need an electrician for new wiring',
        specification:
            'I need new wiring, outlets, and light switches installed in two rooms. Please test each circuit and clearly label the breaker connections when finished.',
        details: {
          'project_type': 'Electrical',
          'project_scope':
              'Install wiring, outlets, and switches in the property',
        },
      ),
      NeedFormPreset(
        label: 'Paint a property',
        title: 'I want a painter for my property',
        specification:
            'I need the interior walls and ceilings repainted with a smooth, washable finish. Please prepare small cracks first and protect the floors and furniture while working.',
        details: {
          'project_type': 'Painting',
          'project_scope': 'Prepare and paint interior and exterior surfaces',
        },
      ),
    ],
    'agriculture_agribusiness': [
      NeedFormPreset(
        label: 'Veterinary care',
        title: 'I need a veterinary doctor for [animal or concern]',
        specification:
            'I have 12 goats with reduced appetite and coughing. I need an examination, treatment advice, and a vaccination plan for the rest of the herd.',
        details: {'agri_item': 'Veterinary care'},
      ),
      NeedFormPreset(
        label: 'Produce wholesaler',
        title: 'Looking for a wholesale buyer for [produce]',
        specification:
            'I have 800 kg of dried coffee beans ready for sale. I am looking for a wholesale buyer and can provide samples to confirm the quality grade.',
        details: {'agri_item': 'Wholesale produce buyer'},
      ),
      NeedFormPreset(
        label: 'Supply food produce',
        title: 'I need [produce] supplied to my school or hospital',
        specification:
            'Our school kitchen needs fresh beans, tomatoes, onions, and greens delivered twice each week. Produce should be clean, fresh, and packed in food-safe crates.',
        details: {'agri_item': 'Institutional produce supply'},
      ),
      NeedFormPreset(
        label: 'Lease farmland',
        title: 'Looking to lease land for [crop or farming activity]',
        specification:
            'I am looking for farmland to grow maize for two seasons. I need cultivable soil, access to water, and permission to build a temporary storage shed.',
        details: {'agri_item': 'Farmland lease'},
      ),
      NeedFormPreset(
        label: 'Farm tour or expo',
        title: 'I want to arrange an agriculture tour or expo for [group]',
        specification:
            'Our school agriculture club is planning a one-day farm learning visit for 30 students. We would like a crop-growing demonstration, livestock-care session, and time for questions.',
        details: {'agri_item': 'Agriculture tours and expos'},
      ),
      NeedFormPreset(
        label: 'Farm inputs',
        title: 'I need [farm input] for my farm',
        specification:
            'I need certified maize seed, bean seed, and suitable fertilizer for the next planting season. Please include application instructions and product labels.',
        details: {
          'agri_item': 'Seeds / fertilizer / chemicals',
          'volume_or_acres': 'For 5 acres',
        },
      ),
      NeedFormPreset(
        label: 'Harvester',
        title: 'Looking for farm machinery to hire',
        specification:
            'I need a combine harvester for maize harvesting. Please confirm the machine capacity, operator experience, daily working hours, and crop-loss prevention measures.',
        details: {
          'agri_item': 'Combine harvester hire',
          'volume_or_acres': '10 acres',
        },
      ),
      NeedFormPreset(
        label: 'Irrigation',
        title: 'I want irrigation equipment for [crop or acreage]',
        specification:
            'I want drip irrigation for a five-acre vegetable plot. The system should include filters, main lines, drip lines, and a simple guide for daily operation.',
        details: {
          'agri_item': 'Irrigation equipment',
          'volume_or_acres': 'For 5 acres',
        },
      ),
      NeedFormPreset(
        label: 'Livestock feed',
        title: 'Looking for feed for [animal type]',
        specification:
            'I need dairy feed for 50 cattle, including a balanced ration for lactating cows. Please list ingredients, feeding guidance, and storage instructions.',
        details: {
          'agri_item': 'Livestock feed',
          'volume_or_acres': 'For 50 animals',
        },
      ),
      NeedFormPreset(
        label: 'Crop spraying',
        title: 'Need crop spraying for [crop or acreage]',
        specification:
            'I need safe treatment for fall armyworm in my maize crop. Please identify the recommended product, protective equipment, re-entry time, and application steps.',
        details: {
          'agri_item': 'Crop spraying / pest control',
          'volume_or_acres': 'For 5 acres',
        },
      ),
      NeedFormPreset(
        label: 'Tractor hire',
        title: 'I need a tractor for [farm task]',
        specification:
            'I need a tractor with a plough to prepare five acres before planting. Please confirm the implement type, operator availability, and expected work time.',
        details: {
          'agri_item': 'Tractor / farm implement hire',
          'volume_or_acres': '10 acres',
        },
      ),
      NeedFormPreset(
        label: 'Find a produce buyer',
        title: 'I need a buyer for [crop or produce]',
        specification:
            'I have 50 bags of dry beans ready for sale. Please share the quality and moisture standards you accept, how grading works, and whether you collect from farms.',
        details: {
          'agri_item': 'Buyer for farm produce',
          'volume_or_acres': '50 bags',
        },
      ),
    ],
    'technology_digital': [
      NeedFormPreset(
        label: 'Website',
        title: 'I want a [type of website] for my business',
        specification:
            'I need a mobile-friendly website for my bakery with a menu, photo gallery, opening hours, and a WhatsApp order button. Please show me how to update the menu after launch.',
        details: {
          'deliverables': 'Website, domain setup, contact form',
          'timeline': '4 weeks',
        },
      ),
      NeedFormPreset(
        label: 'Mobile app',
        title: 'Need a mobile app for [purpose]',
        specification:
            'I need an Android app where customers can create accounts, browse products, place orders, and receive updates. I also need an admin view to manage products and orders.',
        details: {
          'deliverables': 'Android app, admin portal, launch support',
          'timeline': '8 weeks',
        },
      ),
      NeedFormPreset(
        label: 'IT support',
        title: 'I need help with [computer or network issue]',
        specification:
            'Our office computers keep disconnecting from the shared printer and internet. Please check the router and five computers, restore reliable connections, and explain what caused the problem.',
        details: {
          'deliverables': 'Diagnosis, repair, and recommended next steps',
        },
      ),
      NeedFormPreset(
        label: 'Device repair',
        title: 'I need phone, laptop, or tablet repair for [device and issue]',
        specification:
            'My [phone, laptop, or tablet] has [screen, battery, charging, or software issue]. Please diagnose the problem, explain the repair and parts needed, and let me know the expected turnaround. I will back up my data and discuss device access directly with the repairer.',
        specificationVariants: [
          'I need help repairing a [device model] with [fault or symptoms]. Please explain the diagnostic process, whether parts are available, and how long the repair may take.',
          'My [device] needs repair because [what happened and what no longer works]. I would like a diagnosis, repair options, and an estimate of the turnaround before proceeding.',
        ],
      ),
      NeedFormPreset(
        label: 'Digital marketing',
        title: 'Looking for help to [marketing goal]',
        specification:
            'I want to reach local small-business owners through Instagram and Facebook. Please create a four-week campaign and report on enquiries, reach, and engagement.',
        details: {
          'deliverables': 'Campaign plan, content, and performance report',
        },
      ),
      NeedFormPreset(
        label: 'Software setup',
        title: 'I want to set up [software or system]',
        specification:
            'I need our team set up on a shared customer-management system with staff accounts, a customer import, and a short training session on tracking follow-ups.',
        details: {
          'deliverables': 'Installation, configuration, and user training',
        },
      ),
      NeedFormPreset(
        label: 'Data & cloud',
        title: 'I need help with [data or cloud task]',
        specification:
            'I need our files moved from several staff laptops into shared cloud folders. Please organize folders by department, set staff access, and show us how to restore deleted files.',
        details: {
          'deliverables':
              'Setup or migration, access configuration, and handover',
        },
      ),
    ],
    'marketing_promotion': [
      NeedFormPreset(
        label: 'Social media',
        title: 'I need help promoting [brand or offer] on social media',
        specification:
            'I need a four-week social media plan for my new clothing collection, with three posts each week, product photos, captions, and a summary of engagement at the end.',
        details: {
          'deliverables':
              'Content plan, creative assets, and performance summary',
          'timeline': '4 weeks',
        },
      ),
      NeedFormPreset(
        label: 'Paid advertising',
        title: 'I want to reach [target audience] with paid advertising',
        specification:
            'I want to run Facebook and Instagram ads for a new lunch menu. Please create two ad versions, target people interested in local dining, and report clicks and enquiries.',
        details: {
          'deliverables':
              'Ad setup, creative, optimization, and results report',
          'timeline': '4 weeks',
        },
      ),
      NeedFormPreset(
        label: 'Influencer campaign',
        title: 'I need one creator to promote [product or service]',
        specification:
            'I run a local restaurant and need one food creator to make two short videos featuring our new menu and post them on [platform]. Please share your audience location, engagement on food posts, rate, and availability, then provide reach and engagement results after the campaign.',
        specificationVariants: [
          'I am looking for one local food creator to visit our restaurant, film a short tasting video about [menu item], and post it to [platform]. Please share your audience location, availability, and a sample of similar work.',
          'I need one creator to introduce [product or service] to their audience through [video, post, or story]. Please describe the content you would make, when you are available, and how you can share its reach and engagement afterward.',
        ],
        details: {
          'deliverables': 'Two short videos and campaign performance results',
        },
      ),
      NeedFormPreset(
        label: 'Brand identity',
        title: 'I need a brand identity for [business or product]',
        specification:
            'I need a fresh identity for my natural skincare line, including a logo, colors, fonts, product label style, and social profile graphics that feel clean and botanical.',
        details: {
          'deliverables':
              'Logo, color and type guide, and reusable brand files',
        },
      ),
      NeedFormPreset(
        label: 'Content creation',
        title: 'I want content for [campaign or platform]',
        specification:
            'I need four short product videos and eight matching social graphics for an upcoming launch. Keep the style bright and friendly, with clear product benefits in each piece.',
        details: {
          'deliverables': 'Campaign-ready copy, graphics, or video content',
        },
      ),
      NeedFormPreset(
        label: 'Public relations',
        title: 'I need help sharing news about [brand or announcement]',
        specification:
            'Our organization is opening a new youth learning center. I need a clear press release, a short media fact sheet, and help sharing the announcement with community news outlets.',
        details: {
          'deliverables':
              'Press materials, media outreach, and coverage summary',
        },
      ),
    ],
    'events_production': [
      NeedFormPreset(
        label: 'Catering',
        title: 'Looking for catering for [event type]',
        specification:
            'I need a buffet with chicken, rice, vegetables, and a vegetarian option. Please provide serving staff, plates, and a clear plan for keeping food warm.',
      ),
      NeedFormPreset(
        label: 'Sound & stage',
        title: 'I need sound and stage equipment for [event type]',
        specification:
            'I need microphones for the host and speakers, clear sound for a crowd of 200, stage lighting, and a technician to run a sound check before the program.',
      ),
      NeedFormPreset(
        label: 'Event decor',
        title: 'I want decor for [event type]',
        specification:
            'I want a modern green-and-gold theme with a decorated entrance, stage backdrop, table centerpieces, and setup completed before guests arrive.',
      ),
      NeedFormPreset(
        label: 'Event photography',
        title: 'Looking for a photographer for [event type]',
        specification:
            'I need candid photos of the ceremony, group portraits, and edited digital images delivered in a shareable online gallery after the event.',
      ),
      NeedFormPreset(
        label: 'DJ & entertainment',
        title: 'I need entertainment for [event type]',
        specification:
            'I need a DJ to play a mix of Afrobeats, classics, and family-friendly dance music, make announcements, and coordinate key moments in the program.',
      ),
      NeedFormPreset(
        label: 'Event planning',
        title: 'I want help planning [event type]',
        specification:
            'I need help building the event schedule, coordinating suppliers, managing setup, and keeping the program on time from guest arrival through closing.',
      ),
      NeedFormPreset(
        label: 'Venue hire',
        title: 'Looking for a venue for [event type]',
        specification:
            'I need a covered space with seating, accessible restrooms, reliable power, and room for a stage and dining tables.',
      ),
      NeedFormPreset(
        label: 'Event equipment',
        title: 'I need equipment for [event type]',
        specification:
            'I need 20 tables, 200 chairs, a portable stage, and a PA system. Please set everything up before the event and collect it afterward.',
      ),
    ],
    'music_video': [
      NeedFormPreset(
        label: 'Music video',
        title: 'Looking for a music video team for [artist or track]',
        specification:
            'I want a story-led music video with performance shots, warm cinematic lighting, and a few outdoor scenes. Please handle filming, editing, color grading, and a final version for YouTube.',
      ),
      NeedFormPreset(
        label: 'Live session',
        title: 'I want to record a live session for [artist or group]',
        specification:
            'I need a live session recorded with three camera angles, clean vocal and instrument audio, a full edited performance, and short clips for social media.',
      ),
      NeedFormPreset(
        label: 'Short film',
        title: 'I need a production team for [short film project]',
        specification:
            'I need a small crew to film a 10-minute drama with natural performances, clear dialogue recording, and a polished final edit with opening and closing credits.',
      ),
      NeedFormPreset(
        label: 'Event coverage',
        title: 'Looking for video coverage of [event]',
        specification:
            'I need video coverage of the speeches, performances, and key audience moments, edited into a full event film and a one-minute highlight reel.',
      ),
      NeedFormPreset(
        label: 'Product video',
        title: 'I want a video to showcase [product or service]',
        specification:
            'I need a 30-second product video showing how the item works, three key benefits on screen, subtitles, and square and vertical versions for social platforms.',
      ),
      NeedFormPreset(
        label: 'Interview or podcast',
        title: 'I need recording and editing for [interview or podcast]',
        specification:
            'I need a two-person podcast recorded with clear separate microphone tracks, a lightly edited full episode, and three short clips with captions.',
      ),
    ],
    'events_celebrations': [
      NeedFormPreset(
        label: 'Catering',
        title: 'I need catering for [celebration]',
        specification:
            'I need a family-style meal with rice, chicken, vegetables, and a vegetarian option. Please include serving utensils and a simple way to label dishes with common allergens.',
      ),
      NeedFormPreset(
        label: 'Decor',
        title: 'Looking for decor for [celebration]',
        specification:
            'I want a blue-and-white celebration theme with a photo backdrop, table flowers, and simple matching centerpieces. Please complete setup before guests arrive and clear decorations afterward.',
      ),
      NeedFormPreset(
        label: 'Photography',
        title: 'I need a photographer for [celebration]',
        specification:
            'I need candid ceremony photos, family portraits, and edited digital pictures organized in an online gallery that relatives can share.',
      ),
      NeedFormPreset(
        label: 'Sound & music',
        title: 'Looking for sound and music for [celebration]',
        specification:
            'I need upbeat music for the entrance and dancing, with a short live performance during the evening. Please coordinate sound levels with the program host.',
      ),
      NeedFormPreset(
        label: 'Event planning',
        title: 'I want help planning [celebration]',
        specification:
            'I need help creating the event schedule, confirming suppliers, organizing setup, and coordinating the program so the day runs smoothly.',
      ),
      NeedFormPreset(
        label: 'Venue setup',
        title: 'I need a venue for [celebration]',
        specification:
            'I need an event space with seating, accessible restrooms, reliable power, and room for dining and a small performance area.',
      ),
    ],
    'photo_video_talent': [
      NeedFormPreset(
        label: 'Photography',
        title: 'I need a photographer for [project or event]',
        specification:
            'Describe the style, coverage, editing, and delivery format you need.',
      ),
      NeedFormPreset(
        label: 'Videography',
        title: 'Looking for a video team for [project or event]',
        specification:
            'Share the concept, filming needs, editing style, and final formats.',
      ),
      NeedFormPreset(
        label: 'Music video',
        title: 'I want a music video for [artist or track]',
        specification:
            'Describe the creative direction, crew, equipment, and deliverables.',
      ),
      NeedFormPreset(
        label: 'Live performance',
        title: 'I need performers for [event or occasion]',
        specification:
            'Share the performance type, duration, technical setup, and audience.',
      ),
      NeedFormPreset(
        label: 'Recording session',
        title: 'Looking for a recording session for [artist or group]',
        specification:
            'Describe the recording setup, number of tracks, mixing, and final files.',
      ),
      NeedFormPreset(
        label: 'Content creator',
        title: 'I need one content creator for [brand or platform]',
        specification:
            'I need one creator to film three 20-second vertical videos showing how customers can use our new product. Please share your filming and editing style, relevant examples, turnaround time, and whether you can provide captions.',
        specificationVariants: [
          'I am looking for one creator to make a short demo of [product] for [platform]. Please share your filming style, an example video, and when you could deliver the edited clip.',
          'I need one person to create [number] short videos about [brand or product], with captions and a clear call to action. Please describe your approach and show a relevant sample.',
        ],
      ),
      NeedFormPreset(
        label: 'Presenter or MC',
        title: 'I need a presenter for [program or event]',
        specification:
            'Describe the audience, language, program length, and hosting style.',
      ),
      NeedFormPreset(
        label: 'Backup dancers',
        title: 'I need backup dancers for [artist or performance]',
        specification:
            'Share the number of dancers, dance style, rehearsal schedule, and performance date.',
      ),
      NeedFormPreset(
        label: 'Video vixen / music video model',
        title: 'Looking for a video model for [music video or campaign]',
        specification:
            'Describe the concept, role, shoot schedule, wardrobe, and usage requirements.',
      ),
      NeedFormPreset(
        label: 'Skaters',
        title: 'I need skaters for [event, shoot, or performance]',
        specification:
            'Share the skating style, number of performers, surface requirements, safety setup, and timing.',
      ),
      NeedFormPreset(
        label: 'Stunt performers',
        title: 'Looking for stunt performers for [production]',
        specification:
            'Describe the planned stunts, performer experience, safety coordination, and shoot schedule.',
      ),
      NeedFormPreset(
        label: 'Actors and extras',
        title: 'I need actors or extras for [production]',
        specification:
            'Share the number of roles, age range, scripts or call times, and experience needed.',
      ),
      NeedFormPreset(
        label: 'Songwriter or composer',
        title: 'I need a songwriter for [artist, project, or occasion]',
        specification:
            'Describe the genre, theme, writing or composition support, ownership terms, and deadline.',
      ),
      NeedFormPreset(
        label: 'Music and performance trainer',
        title: 'Looking for a trainer in [music or performance skill]',
        specification:
            'Share the learner age group, skill level, class size, training goals, and schedule.',
      ),
      NeedFormPreset(
        label: 'School arts workshop',
        title: 'I want an arts workshop for [school or student group]',
        specification:
            'Describe the activity, student age range, group size, materials, and session length.',
      ),
      NeedFormPreset(
        label: 'Influencer campaign',
        title: 'I need one creator to promote [brand, product, or event]',
        specification:
            'I am looking for one creator whose audience is interested in [topic or customer group] to publish [number and type of posts] on [platform] during [campaign period]. Please share your audience location, engagement on related posts, availability, and content usage terms.',
        specificationVariants: [
          'I need one creator to make [content format] about [product or event] for [platform]. Please share who your content reaches, examples of related posts, your availability, and whether I may reuse the content.',
          'I am looking for one creator to publish [number] posts for [campaign] during [dates]. Please tell me your usual content style, audience location, and how you report post performance.',
        ],
      ),
      NeedFormPreset(
        label: 'Influencer content collaboration',
        title: 'I want to collaborate with one creator on [content idea]',
        specification:
            'I would like to work with one creator on [specific content idea], such as a short video showing [product or activity]. Please share your approach, audience fit, the content you can deliver, and whether we can both share the finished post.',
        specificationVariants: [
          'I have an idea for a [video, photo, or live session] about [topic] and would like one creator to shape and make it with me. Please share a related example, your creative approach, and the deliverables you can provide.',
          'I am looking for one creator to collaborate on [content idea] for [platform]. Please describe your role, how we can coordinate production, and the final content we would each be able to share.',
        ],
      ),
      NeedFormPreset(
        label: 'UGC creator',
        title: 'I need user-style content for [product or service]',
        specification:
            'I need one creator to make a 30-second vertical video showing [product] in everyday use, with a clear opening, captions, and a short call to action. Please share a relevant sample and confirm whether the delivered video can be used on [platform].',
        specificationVariants: [
          'I am looking for one UGC creator to record a 20–30 second vertical video showing [product] solving [customer need]. Please include clear captions and share a sample in a similar style.',
          'I need a short, natural product video from one creator: show [product feature], explain [key point], and finish with [call to action]. Please confirm your delivery format and content usage terms.',
        ],
      ),
      NeedFormPreset(
        label: 'Influencer event coverage',
        title: 'I need one creator to cover [event or launch]',
        specification:
            'I need one local creator to attend [event] on [date], capture short behind-the-scenes clips, and publish [number] stories or posts on [platform]. Please share your availability, audience location, and how long you would need at the event.',
        specificationVariants: [
          'I am looking for one creator to attend our [launch or event] in [area], capture a few short moments, and post them to [platform]. Please share your availability and the content format you recommend.',
          'I need one local creator to cover [event] on [date] with [number] stories and one recap post. Please describe your approach, expected time on site, and how you share performance insights.',
        ],
      ),
      NeedFormPreset(
        label: 'Voice-over artist',
        title: 'I need a voice-over artist for [project]',
        specification:
            'Share the script length, language, voice style, recording format, and usage rights.',
      ),
      NeedFormPreset(
        label: 'Choreographer',
        title: 'Looking for a choreographer for [performance or production]',
        specification:
            'Describe the dance style, performer count, rehearsal time, and stage or filming setup.',
      ),
      NeedFormPreset(
        label: 'Session musicians',
        title: 'I need musicians for [recording or live performance]',
        specification:
            'List instruments, genre, set or session length, rehearsal needs, and equipment.',
      ),
      NeedFormPreset(
        label: 'Sound engineer',
        title: 'Looking for a sound engineer for [event or recording]',
        specification:
            'Share equipment, schedule, and live or post-production needs.',
      ),
      NeedFormPreset(
        label: 'Commercial models',
        title: 'I need models for [brand, product, or campaign]',
        specification:
            'Describe the role, styling, skills, shoot dates, and where the images or video will be used.',
      ),
      NeedFormPreset(
        label: 'Influencer product review',
        title: 'I want one creator to review [product or service]',
        specification:
            'I would like one creator to try [product or service] and share an honest [video, photo, or written] review with an audience interested in [topic]. Please share your review format, relevant audience insights, availability, and content usage terms.',
        specificationVariants: [
          'I am looking for one reviewer to try [product] and create an honest [short video or photo] review for [platform]. Please share an example review and tell me how you disclose gifted or sponsored products.',
          'I need one creator to test [service or product] and explain their experience to an audience interested in [topic]. Please suggest a format, share a related sample, and confirm your availability and usage terms.',
        ],
      ),
    ],
    'beauty_fashion_styling': [
      NeedFormPreset(
        label: 'Makeup artist',
        title: 'I need makeup for [occasion or look]',
        specification:
            'Describe the desired look, number of people, products, and preparation time.',
      ),
      NeedFormPreset(
        label: 'Lashes and brows',
        title: 'I am looking for [lash or brow service]',
        specification:
            'I would like [lash extensions, a lash lift, brow shaping, or tinting] for [occasion or everyday wear]. Please share the style options, appointment length, and any preparation or aftercare instructions.',
      ),
      NeedFormPreset(
        label: 'Facial or skincare',
        title: 'I want a facial or skincare service for [goal]',
        specification:
            'I am looking for a gentle facial focused on [hydration, cleansing, or a refreshed look]. Please describe the products and steps used, and let me know whether I should mention sensitivities before the appointment.',
      ),
      NeedFormPreset(
        label: 'Skin tone care',
        title: 'I am looking for care for [uneven tone or dark spots]',
        specification:
            'I would like advice about uneven skin tone and dark spots on [area]. Please explain your approach, the products or ingredients you use, and whether you recommend a clinician assessment before treatment. I have [sensitive skin or no known sensitivities].',
        specificationVariants: [
          'I am looking for a skincare consultation about [dark spots or uneven tone] and would like to understand the available options, ingredients, and expected care routine before choosing a service.',
          'I would like help with [post-acne marks or uneven tone] on [area]. Please describe the service, products used, and any suitability questions you would discuss with me first.',
        ],
      ),
      NeedFormPreset(
        label: 'Hair styling',
        title: 'Looking for a hairstylist for [occasion or style]',
        specification:
            'Share the style, hair length, products, and appointment needs.',
      ),
      NeedFormPreset(
        label: 'Tailoring',
        title: 'I need tailoring for [garment or outfit]',
        specification:
            'Describe the garment, fit changes, fabric, and completion timing.',
      ),
      NeedFormPreset(
        label: 'Personal styling',
        title: 'I want help styling outfits for [occasion or need]',
        specification:
            'Share the occasion, preferred styles, and sizing needs.',
      ),
      NeedFormPreset(
        label: 'Nails',
        title: 'Looking for nail services for [occasion or style]',
        specification:
            'I need French-tip gel manicures for 20 people before our event. Please include nail prep, polish, and a neat, long-lasting finish.',
      ),
      NeedFormPreset(
        label: 'Tattoo artist',
        title: 'I am looking for a tattoo artist for [design or idea]',
        specification:
            'I would like a [small black-ink floral design] on my [upper arm], about [5 cm] wide. Please share similar work, how you plan the design, and what to expect at the appointment.',
        specificationVariants: [
          'I want a [fine-line name or symbol] tattoo on my [wrist or forearm], around [size]. Please discuss the design options, placement, and appointment process with me.',
          'I am looking for an artist to create a [style and subject] tattoo in [black and grey or color] for my [body area]. I can share a reference image and would like to discuss sizing and placement.',
        ],
      ),
      NeedFormPreset(
        label: 'Fashion design',
        title: 'I need an outfit designed for [occasion]',
        specification:
            'Share the design direction, fabric preferences, fitting needs, and deadline.',
      ),
      NeedFormPreset(
        label: 'Massage therapy',
        title: 'I’m looking for a massage therapist for [wellness need]',
        specification:
            'I would like a relaxing 60-minute massage at home or in a quiet studio. Please share your available massage styles, what is included, and your earliest appointment times.',
      ),
      NeedFormPreset(
        label: 'Spa or wellness day',
        title: 'I want to arrange a wellness day for [group or occasion]',
        specification:
            'I am planning a wellness day for a small group and would like treatment options and a schedule. Please let me know what services can be provided at our event.',
      ),
      NeedFormPreset(
        label: 'Personal trainer',
        title: 'I need a personal trainer for [fitness goal]',
        specification:
            'I am looking for a trainer to help me build strength and improve my fitness. I am available for two sessions each week and would like to discuss a suitable training plan.',
      ),
      NeedFormPreset(
        label: 'Yoga or meditation',
        title:
            'Looking for a yoga or meditation instructor for [group or goal]',
        specification:
            'We are looking for a beginner-friendly instructor for a 45-minute group session. Please share your teaching style, what participants should bring, and your availability.',
      ),
      NeedFormPreset(
        label: 'Nutrition coaching',
        title: 'I want nutrition coaching for [wellness goal]',
        specification:
            'I would like practical nutrition coaching to support my wellness goals and everyday meals. Please share how your sessions work and whether they are online or in person. I will discuss any private health information directly with the coach.',
      ),
      NeedFormPreset(
        label: 'Cosmetic body contouring',
        title: 'I am looking for [non-surgical body contouring service]',
        specification:
            'I would like information about [service] for [area of interest]. Please explain what the appointment involves, expected recovery or aftercare, and who provides the service. I am looking for a consultation before deciding.',
      ),
    ],
    'domestic_household': [
      NeedFormPreset(
        label: 'Home cleaning',
        title: 'I need help cleaning [home or rooms]',
        specification:
            'I need a weekly clean of the kitchen, bathroom, and living room, including sweeping, mopping, and wiping surfaces. Please bring basic cleaning supplies.',
      ),
      NeedFormPreset(
        label: 'Childcare',
        title: 'Looking for childcare for [child or schedule]',
        specification:
            'I need a patient caregiver to supervise my 4-year-old after school, prepare a simple snack, and follow the child’s usual reading and play routine.',
      ),
      NeedFormPreset(
        label: 'Home cooking',
        title: 'I need a cook for [household or occasion]',
        specification:
            'I need lunch and dinner prepared for a family of five, with vegetables included and mild seasoning. Please help with meal preparation and leave the kitchen tidy.',
      ),
      NeedFormPreset(
        label: 'Laundry',
        title: 'Looking for laundry help for [household or business]',
        specification:
            'I need weekly washing, drying, folding, and ironing for everyday family clothes. Please separate delicate items and return everything neatly folded.',
      ),
      NeedFormPreset(
        label: 'Household support',
        title: 'I need household help with [routine or task]',
        specification:
            'I need help with weekday tidying, dishes, sweeping, and changing bed linens. Please follow a consistent checklist and let me know when each task is complete.',
      ),
      NeedFormPreset(
        label: 'Home organization',
        title: 'I want help organizing [room or household area]',
        specification:
            'I want to organize a crowded bedroom wardrobe by sorting clothes, folding items, and arranging shoes and accessories so they are easy to find.',
      ),
    ],
    'health_medical': [
      NeedFormPreset(
        label: 'Consultation',
        title: 'I am looking for a consultation about [health concern]',
        specification:
            'I would like a consultation to discuss my concern, understand possible next steps, and learn whether follow-up care may be needed. I will share private health details directly with the provider.',
        specificationVariants: [
          'I have had [symptom or concern] for [time period] and would like an initial consultation to discuss what care or follow-up may be appropriate. I will share health details privately with the provider.',
          'I would like a consultation about [health concern], including what information to bring and whether another appointment or test may be needed. I will discuss personal details directly with the provider.',
        ],
      ),
      NeedFormPreset(
        label: 'Dental braces',
        title: 'I am looking for a dentist or orthodontist about braces',
        specification:
            'I would like an assessment to learn whether braces are suitable, compare treatment options, and understand the follow-up care involved. I will share dental records directly with the provider.',
        specificationVariants: [
          'I would like an orthodontic assessment for [teeth or bite concern], with an explanation of suitable braces, expected check-up frequency, and care at home.',
          'I am considering braces for [child or adult] and would like to know what the first assessment involves and which treatment options may fit.',
        ],
      ),
      NeedFormPreset(
        label: 'Circumcision for a child',
        title: 'I am looking for circumcision care for my child',
        specification:
            'I am looking for a qualified pediatric clinician to assess my child and explain the procedure, guardian consent, pain management, infection prevention, aftercare, and follow-up. Please confirm the child’s age eligibility and what I should prepare as the parent or guardian.',
        specificationVariants: [
          'My child is [age] and I would like a qualified pediatric clinician to explain whether circumcision is appropriate, what the procedure and recovery involve, and what a guardian should prepare.',
          'I am seeking child circumcision care for [child’s age]. Please explain the assessment, guardian consent, pain relief, aftercare, and when follow-up is needed.',
        ],
      ),
      NeedFormPreset(
        label: 'Medical worker recruit',
        title:
            'Our clinic needs one [clinician, nurse, midwife, or pharmacist]',
        specification:
            'Our clinic needs one qualified [role] to support patient care. Please share relevant experience, usual duties, and availability for the role.',
        specificationVariants: [
          'Our clinic in [area] is looking for one [clinician, nurse, midwife, or pharmacist] for [shift or days per week]. The role will support [main service]. Please share relevant experience and availability.',
          'We need one [medical worker role] at our clinic to help with [patient service]. The expected start is [date] and schedule is [hours or shifts]. Please describe your relevant experience and availability.',
        ],
      ),
      NeedFormPreset(
        label: 'Bone and joint specialist',
        title: 'I am looking for a specialist for [bone or joint concern]',
        specification:
            'I need an assessment for ongoing joint pain and would like to understand what examination or imaging may be recommended and what follow-up care could involve. I will share medical records directly with the specialist.',
        specificationVariants: [
          'I am looking for a specialist about [bone or joint concern] affecting [body area] for [time period]. I would like an assessment and advice on possible next steps.',
          'I need specialist care for [bone, joint, or back concern]. Please let me know what to bring to the first appointment and how follow-up is arranged.',
        ],
      ),
      NeedFormPreset(
        label: 'Cancer specialist',
        title: 'I am seeking a cancer specialist for [care or second opinion]',
        specification:
            'I am looking for a specialist consultation to review my diagnosis or care plan and discuss possible next steps. I will share test results and medical records directly with the provider.',
        specificationVariants: [
          'I am seeking a cancer specialist for [type of cancer or care question] and would like a consultation to review the current care plan and explain possible next steps.',
          'I need a specialist opinion about [diagnosis or treatment decision]. I can share relevant test results and records privately with the provider.',
        ],
      ),
      NeedFormPreset(
        label: 'Stomach and ulcer specialist',
        title: 'I need a specialist for [stomach or ulcer concern]',
        specification:
            'I need an assessment for recurring stomach discomfort or an ulcer concern, with advice on appropriate tests and follow-up. I will discuss symptoms and records privately with the clinician.',
        specificationVariants: [
          'I am looking for specialist advice about [stomach or ulcer concern] that has been happening for [time period]. Please explain what the first assessment may involve.',
          'I need an assessment for recurring [stomach symptom or known ulcer] and guidance on whether tests or a follow-up visit may be appropriate.',
        ],
      ),
      NeedFormPreset(
        label: 'Heart specialist',
        title: 'I am looking for a heart specialist for [concern]',
        specification:
            'I need a specialist consultation about a heart-related concern and guidance on what assessment or follow-up may be appropriate. I will provide relevant medical information directly to the clinician.',
        specificationVariants: [
          'I am looking for a heart specialist about [concern or referral question]. Please explain what information or test results to bring to the consultation.',
          'I need a specialist assessment for [heart-related concern] and would like to understand possible checks and follow-up options.',
        ],
      ),
      NeedFormPreset(
        label: 'Eye care specialist',
        title: 'I need an eye care specialist for [concern or exam]',
        specification:
            'I would like an eye assessment for [vision change, eye discomfort, or routine check-up]. Please let me know what the appointment includes and what information or glasses prescription I should bring.',
        specificationVariants: [
          'I am looking for an eye care professional for [eye concern] that started [time period]. I would like an assessment and advice on appropriate next steps.',
          'I need an eye examination for [routine check or vision concern] in [area]. Please share appointment availability and what to bring.',
        ],
      ),
      NeedFormPreset(
        label: 'Skin condition specialist',
        title: 'I am looking for a skin specialist for [condition or concern]',
        specification:
            'I would like a clinician to assess [skin concern] that has been present for [time period]. Please explain what the first consultation involves. I will share photos or health details privately with the provider.',
        specificationVariants: [
          'I need an appointment about [rash, acne, eczema, or other skin concern] affecting [area] for [time period]. Please let me know what details to bring to the assessment.',
          'I am looking for a skin specialist to discuss [skin condition or treatment question] and possible care options. I will provide personal health information directly to the clinician.',
        ],
      ),
      NeedFormPreset(
        label: 'Cosmetic surgery consultation',
        title: 'I am seeking a consultation about [cosmetic procedure]',
        specification:
            'I would like a consultation to discuss [procedure, such as a Brazilian butt lift (BBL)], candidacy, potential risks, alternatives, recovery, and follow-up. Please explain the clinician’s qualifications and where the procedure would be performed. I will decide after discussing it with the provider.',
        specificationVariants: [
          'I am considering [cosmetic procedure] and want an in-person consultation to discuss whether it may be suitable, the risks and alternatives, recovery, and follow-up care before making a decision.',
          'I would like to speak with a qualified clinician about [procedure or goal]. Please explain the assessment process, where care is provided, possible risks, and what recovery may involve.',
        ],
      ),
      NeedFormPreset(
        label: 'Lab tests',
        title: 'I need help arranging [medical test]',
        specification:
            'I need to arrange a blood test and have the results shared securely with my clinician. Please explain preparation instructions, sample handling, and how results are delivered.',
        specificationVariants: [
          'I need [test name] and would like to know whether fasting or other preparation is required, when results are ready, and how they can be sent securely to my clinician.',
          'Please help me arrange [medical test] at [preferred area]. Let me know what referral or preparation is needed and how I will receive the results.',
        ],
      ),
      NeedFormPreset(
        label: 'Dental support',
        title: 'I need a dental professional for [care or procedure]',
        specification:
            'I need a dental check-up and cleaning, and would like advice about a sensitive tooth. Please explain what the visit includes; I will share dental records directly with the provider.',
        specificationVariants: [
          'I need help with [tooth or gum concern] and would like to know what a first dental visit includes and whether follow-up care may be needed.',
          'I am looking for dental care for [check-up, cleaning, or tooth concern]. Please explain the available service and what I should bring.',
        ],
      ),
      NeedFormPreset(
        label: 'Home nursing',
        title: 'I need a home care provider for [support needed]',
        specification:
            'I need a trained caregiver to help my parent with daily mobility, medication reminders, and meal support for a few hours each morning. Please describe your relevant training and care approach.',
        specificationVariants: [
          'I need home nursing support for [person] with [daily care task] on [days and hours]. Please describe your relevant experience and the support you can provide.',
          'I am looking for a home care provider to help with [mobility, wound care, or daily routine] at [area] for [time period]. Please outline your availability and approach.',
        ],
      ),
      NeedFormPreset(
        label: 'Physiotherapy',
        title: 'Looking for physiotherapy support for [goal]',
        specification:
            'I need guided physiotherapy exercises to improve knee mobility after an injury. Please explain how you assess progress and adapt exercises during recovery.',
        specificationVariants: [
          'I need physiotherapy for [injury or mobility goal] and can attend [days or times] in [area]. Please explain how an initial assessment and progress reviews work.',
          'I am looking for help improving [movement or strength goal] after [injury or surgery]. Please share your approach to guided exercises and follow-up.',
        ],
      ),
      NeedFormPreset(
        label: 'Medical equipment',
        title: 'Looking for [medical equipment needed]',
        specification:
            'I need a walking aid that adjusts to the user’s height and folds for storage. Please explain how to choose the correct size and demonstrate safe use.',
        specificationVariants: [
          'I am looking for [equipment] for a [adult or child] who needs support with [daily activity]. Please advise on sizing, safe use, and delivery or collection.',
          'I need [medical equipment] with [important feature] for use at [home or clinic]. Please share available options and fitting guidance.',
        ],
      ),
    ],
    'traditional_cultural': [
      NeedFormPreset(
        label: 'Cultural ceremony',
        title: 'I need support with [cultural ceremony]',
        specification:
            'I need help coordinating a family introduction ceremony, including the order of greetings, cultural acknowledgements, and coordination with elders during the program.',
      ),
      NeedFormPreset(
        label: 'Traditional attire',
        title: 'Looking for traditional attire for [occasion]',
        specification:
            'I need matching traditional outfits for a family celebration, with coordinated fabric, clean finishing, and fittings arranged before the event.',
      ),
      NeedFormPreset(
        label: 'Music and dance',
        title: 'I need cultural performers for [occasion]',
        specification:
            'I need a traditional dance group to perform two short sets with live drums. Please include an appropriate program introduction and coordinate the start cues with the host.',
      ),
      NeedFormPreset(
        label: 'Ceremony host',
        title: 'Looking for a host for [traditional occasion]',
        specification:
            'I need a host who can guide a traditional ceremony in both English and Luganda, introduce family representatives respectfully, and keep the program moving.',
      ),
      NeedFormPreset(
        label: 'Cultural instruction',
        title: 'I want instruction in [cultural skill or practice]',
        specification:
            'I want beginner lessons in traditional drumming, including instrument technique, rhythm practice, and a short performance piece at the end of the course.',
      ),
      NeedFormPreset(
        label: 'Ceremony supplies',
        title: 'I need supplies for [cultural occasion]',
        specification:
            'I need woven baskets, serving mats, and locally made decorations for a cultural celebration. Please confirm the materials and finishing details for each item.',
      ),
      NeedFormPreset(
        label: 'Traditional healer',
        title:
            'I am seeking a traditional healer for [cultural or wellness guidance]',
        specification:
            'I am looking for a respectful consultation about a traditional practice and its cultural meaning. Please explain the approach, what the session involves, and any preparation expected. I will seek qualified medical care for health concerns.',
      ),
      NeedFormPreset(
        label: 'Religious or spiritual guidance',
        title:
            'I am looking for religious guidance about [personal or community need]',
        specification:
            'I would like a private, respectful conversation with a trusted religious guide, with time to explain my situation and discuss relevant teachings or community support.',
      ),
      NeedFormPreset(
        label: 'Herbal tradition consultation',
        title: 'I want to learn about [traditional herbs or practice]',
        specification:
            'I am seeking an educational consultation about the cultural use, preparation, and safety considerations of traditional herbs. Please explain possible risks and interactions, and do not replace medical advice.',
      ),
    ],
    'financial_services': [
      NeedFormPreset(
        label: 'SACCO membership',
        title: 'I want to join a SACCO for [goal]',
        specification:
            'I want to join a savings and credit cooperative to build a regular savings habit and learn how member loans work. Please explain membership steps and meeting expectations.',
      ),
      NeedFormPreset(
        label: 'Savings group',
        title: 'Looking for a savings group for [goal]',
        specification:
            'I am looking for a community savings group that meets monthly, keeps clear contribution records, and agrees together on how members can access their savings.',
      ),
      NeedFormPreset(
        label: 'Financial planning',
        title: 'I want financial planning support for [goal]',
        specification:
            'I want help creating a practical savings plan, organizing monthly expenses, and setting milestones for an emergency fund and future education costs.',
      ),
    ],
    'weddings_celebrations': [
      NeedFormPreset(
        label: 'Photography',
        title: 'I need a photographer for [celebration]',
        specification:
            'Share coverage hours, photo style, editing, and delivery or album preferences.',
      ),
      NeedFormPreset(
        label: 'Decor',
        title: 'Looking for decor for [celebration]',
        specification:
            'Share the theme, colors, decoration style, setup, and teardown needs.',
      ),
      NeedFormPreset(
        label: 'Catering',
        title: 'I want catering for [celebration]',
        specification:
            'Share menu preferences, dietary needs, service style, and setup requirements.',
      ),
      NeedFormPreset(
        label: 'Makeup & styling',
        title: 'I need makeup and styling for [celebration]',
        specification:
            'Describe the look, number of people, preparation schedule, and any products or styling needs.',
      ),
      NeedFormPreset(
        label: 'Sound & music',
        title: 'Looking for sound and music for [celebration]',
        specification:
            'Share music preferences, equipment, performance length, and program details.',
      ),
      NeedFormPreset(
        label: 'Event planning',
        title: 'I want help planning [celebration]',
        specification:
            'List the planning, coordination, staffing, and supplier support you need.',
      ),
    ],
    'energy_utilities': [
      NeedFormPreset(
        label: 'Solar install',
        title: 'I need a reliable power system for my site',
        specification:
            'I need solar power for lights, a refrigerator, and phone charging. Please recommend a suitable panel and battery setup, install it, and show me how to monitor the system.',
        details: {
          'system_type': 'Solar system',
          'installation_labor_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Water pump',
        title: 'Looking for a reliable water supply for my site',
        specification:
            'I need a water pump that can fill an overhead tank each day. Please recommend a suitable pump, connect the controls, and demonstrate safe operation.',
        details: {
          'system_type': 'Water pump',
          'installation_labor_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Solar maintenance',
        title: 'I need maintenance for [solar system or issue]',
        specification:
            'My solar system switches off at night even when the battery indicator shows a charge. Please test the battery and connections, identify the fault, and explain the repair.',
        details: {'system_type': 'Solar system'},
      ),
      NeedFormPreset(
        label: 'Water treatment',
        title: 'I need water treatment for [home or business]',
        specification:
            'I need a filter for drinking and cooking water from a storage tank. Please explain which treatment stages are included and how often the filters need replacing.',
        details: {'system_type': 'Water treatment / filtration system'},
      ),
      NeedFormPreset(
        label: 'Borehole pump',
        title: 'Looking for a borehole pump for [site]',
        specification:
            'I need a borehole pump to supply water to a household storage tank. Please confirm the pump size for the borehole depth and include the control box and safety protections.',
        details: {'system_type': 'Borehole pump'},
      ),
      NeedFormPreset(
        label: 'Backup power',
        title: 'I need backup power for [property or equipment]',
        specification:
            'I need backup power for a refrigerator, lights, and internet router during outages. Please estimate the battery runtime, install the system, and explain routine maintenance.',
        details: {
          'system_type': 'Backup power',
          'installation_labor_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Borehole pump',
        title: 'Looking for a pump for [water source or use]',
        specification:
            'I need a pump for a borehole that will supply a storage tank and small garden. Please confirm the suitable pump capacity, control equipment, and installation steps.',
        details: {
          'system_type': 'Borehole pump',
          'installation_labor_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Solar repair',
        title: 'Need help repairing an existing power system',
        specification:
            'My solar inverter keeps showing an overload warning. Please inspect the inverter and wiring, identify the cause, and test the system after repairs.',
        details: {
          'system_type': 'Solar system inspection / repair',
        },
      ),
      NeedFormPreset(
        label: 'Water filtration',
        title: 'I want safer water for [household or business]',
        specification:
            'I need a drinking-water filtration system for a small office. Please include sediment and taste treatment, explain filter replacement, and show staff how to maintain it.',
        details: {
          'system_type': 'Water treatment / filtration system',
          'installation_labor_needed': 'true',
        },
      ),
    ],
  };

  static List<NeedFormPreset> presetsForCategory(String slug) {
    return categoryPresets[_canonicalCategorySlug(slug)] ??
        const [
          NeedFormPreset(
            label: 'Standard request',
            title: 'I need help with a specific request',
            specification:
                'I need a reliable provider who can understand the requirement, share options, and complete the work within the agreed timeline.',
          ),
          NeedFormPreset(
            label: 'Compare quotes',
            title: 'Looking to compare provider quotes',
            specification:
                'I want providers to send clear quotes with timelines, deliverables, and any requirements from my side.',
          ),
        ];
  }

  static const Map<String, List<NeedFormField>> categoryFields = {
    'education_training': [
      NeedFormField.text(
        'subject_or_skill',
        label: 'Subject(s) or skill needed',
        hint: 'Choose one or enter one or more subjects or skills',
      ),
      NeedFormField.text(
        'training_level',
        label: "Learner or applicant's current level",
        hint: 'Choose a school stage or enter another level',
      ),
      NeedFormField.text(
        'preferred_format',
        label: 'Lesson format',
        hint: 'Choose online, in-person, or either',
      ),
      NeedFormField.text(
        'max_travel_distance',
        label: 'Maximum travel distance',
        hint: 'Choose a maximum distance',
      ),
      NeedFormField.text(
        'start_date',
        label: 'When do you want to start?',
        hint: 'e.g. Next month or as soon as possible',
      ),
      NeedFormField.text(
        'duration',
        label: 'Course or support duration',
        hint: 'e.g. 8 weeks, 3 months, or flexible',
      ),
      NeedFormField.text(
        'schedule',
        label: 'Preferred schedule',
        hint: 'e.g. Full-time, part-time, weekends, flexible',
      ),
      NeedFormField.text(
        'required_qualifications',
        label: 'Required Qualifications / Experience',
        hint: 'e.g. Current university student, prior experience',
        isRequired: false,
      ),
    ],
    'travel_international': [
      NeedFormField.text(
        'travel_scope',
        label: 'Trip type',
        hint: 'Choose local or international travel',
      ),
      NeedFormField.text(
        'destination_country',
        label: 'Destination country',
        hint: 'e.g. UAE, Sweden, Saudi Arabia',
        helperText: 'Enter each country if your trip has multiple stops.',
      ),
      NeedFormField.text(
        'destination_city',
        label: 'Destination',
        hint: 'e.g. Murchison Falls or Dubai',
        helperText: 'Add a city, landmark, or place on your trip.',
      ),
      NeedFormField.text(
        'travel_date',
        label: 'Travel date',
        hint: 'e.g. Dec 2026',
        helperText: 'An approximate date is fine.',
      ),
      NeedFormField.date(
        'return_date',
        label: 'Return date',
        hint: 'e.g. 15 Jan 2027',
        helperText: 'Optional.',
        isRequired: false,
      ),
      NeedFormField.number(
        'travellers',
        label: 'Number of travellers',
        hint: 'e.g. 1',
        helperText: 'Include everyone in your group.',
      ),
      NeedFormField.boolean(
        'children_travelling',
        label: 'Children are travelling',
        helperText: 'Turn on if anyone under 18 is travelling.',
      ),
      NeedFormField.text(
        'purpose',
        label: 'Purpose of travel',
        hint: 'e.g. Tourism, business, study, family visit',
        helperText:
            'This helps providers suggest relevant bookings and requirements.',
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
        label: 'Departure city or pickup point',
        hint: 'e.g. Kampala',
        helperText: 'Optional for a local tour.',
        isRequired: false,
      ),
      NeedFormField.text(
        'tour_activities',
        label: 'Activities or interests',
        hint: 'e.g. Wildlife, culture, hiking',
        isRequired: false,
      ),
      NeedFormField.boolean(
        'flexible_dates',
        label: 'Flexible dates are acceptable',
        helperText:
            'Turn this on if you can travel on nearby dates for better options.',
      ),
    ],
    'machinery_equipment': [
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
        hint: 'e.g. Town A',
      ),
      NeedFormField.text(
        'to_location',
        label: 'Dropoff destination',
        hint: 'e.g. Town B',
      ),
    ],
    'specialized_products': [
      NeedFormField.text(
        'quantity',
        label: 'Quantity or volume',
        hint: 'e.g. 50 units',
      ),
    ],
    'construction_building': [
      NeedFormField.text(
        'project_type',
        label: 'Construction or work type',
        hint: 'e.g. Residential roofing, Commercial plumbing',
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
        label: 'Farm item or service',
        hint: 'e.g. Soil testing, veterinary care, farm labour',
      ),
      NeedFormField.text(
        'volume_or_acres',
        label: 'Quantity, acreage or duration',
        hint: 'e.g. 50 bags / 20 acres',
      ),
    ],
    'technology_digital': [
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
    'marketing_promotion': [
      NeedFormField.text(
        'deliverables',
        label: 'Key deliverables',
        hint: 'e.g. Content, ad creatives, campaign report',
      ),
      NeedFormField.text(
        'timeline',
        label: 'Desired campaign timeline',
        hint: 'e.g. 4 weeks',
      ),
    ],
    'events_production': [
      NeedFormField.number(
        'guest_count',
        label: 'Expected guest count',
        hint: 'e.g. 200',
      ),
      NeedFormField.date(
        'event_date',
        label: 'Event date',
        hint: 'e.g. 15 November 2026',
      ),
    ],
    'events_celebrations': [
      NeedFormField.number(
        'guest_count',
        label: 'Expected guest count',
        hint: 'e.g. 80',
        isRequired: false,
      ),
      NeedFormField.date(
        'event_date',
        label: 'Event date',
        hint: 'e.g. 15 November 2026',
        isRequired: false,
      ),
    ],
    'music_video': [
      NeedFormField.date(
        'shoot_date',
        label: 'Shoot or performance date',
        hint: 'e.g. 15 November 2026',
        isRequired: false,
      ),
    ],
    'photo_video_talent': [
      NeedFormField.date(
        'shoot_date',
        label: 'Shoot or performance date',
        hint: 'e.g. 15 November 2026',
        isRequired: false,
      ),
    ],
    'domestic_household': [],
    'financial_services': [],
    'beauty_fashion_styling': [
      NeedFormField.date(
        'appointment_date',
        label: 'Appointment or event date',
        hint: 'e.g. 15 November 2026',
        isRequired: false,
      ),
    ],
    'health_medical': [
      NeedFormField.date(
        'appointment_date',
        label: 'Preferred appointment date',
        hint: 'e.g. 15 November 2026',
        isRequired: false,
      ),
    ],
    'traditional_cultural': [
      NeedFormField.date(
        'event_date',
        label: 'Event date',
        hint: 'e.g. 15 November 2026',
        isRequired: false,
      ),
    ],
    'weddings_celebrations': [
      NeedFormField.number(
        'guest_count',
        label: 'Expected guest count',
        hint: 'e.g. 150',
      ),
      NeedFormField.date(
        'event_date',
        label: 'Event date',
        hint: 'e.g. 15 November 2026',
      ),
    ],
    'energy_utilities': [
      NeedFormField.text(
        'system_type',
        label: 'Power or utility system',
        hint: 'e.g. 10kW Commercial Solar System, Borehole pump',
      ),
      NeedFormField.boolean(
        'installation_labor_needed',
        label: 'Installation & commissioning labor required',
        helperText: 'Turn on if the provider should handle the setup.',
      ),
    ],
  };

  static List<NeedFormField> fieldsForCategory(String slug) {
    return categoryFields[_canonicalCategorySlug(slug)] ??
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
