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
    this.details = const {},
    this.budget,
    this.urgency,
  });

  final String label;
  final String title;
  final String specification;
  final Map<String, String> details;
  final int? budget;
  final String? urgency;
}

class NeedFormSchema {
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
      specificationHint: 'Add other requirements not covered above',
      specificationHelper: 'Mention quality, delivery, or timing preferences.',
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
      specificationHint: 'Add creative or production requirements',
      specificationHelper:
          'Describe the style, crew, equipment, or delivery needs.',
    ),
    'beauty_fashion_styling': NeedFormGuidance(
      titleHint: 'e.g. I need a makeup artist for a wedding',
      specificationHint: 'Add style or preparation requirements',
      specificationHelper:
          'Mention the desired look, products, or preparation schedule.',
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
    return categoryGuidance[slug] ??
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
            'I need tutoring support for a learner and want a provider who can explain clearly, track progress, and recommend practice work.',
      ),
      NeedFormPreset(
        label: 'Tutor for a child',
        title: 'I need a tutor for my child',
        specification:
            'I am looking for patient, age-appropriate lessons with regular feedback on my child’s progress.',
      ),
      NeedFormPreset(
        label: 'School teacher',
        title: 'Our school needs a teacher for [class or learner group]',
        specification:
            'We need a qualified teacher who can plan lessons, teach the group, and assess learner progress.',
      ),
      NeedFormPreset(
        label: 'School tutor',
        title: 'Our school needs a tutor for [class or learner group]',
        specification:
            'We need focused support for learners, with a clear teaching plan and progress updates.',
      ),
      NeedFormPreset(
        label: 'Lecturer',
        title: 'Our institution needs a lecturer for [learner group or level]',
        specification:
            'We need a lecturer to prepare and deliver lessons, assess learners, and support the course programme.',
      ),
      NeedFormPreset(
        label: 'Internship',
        title: 'Looking for an internship in [field]',
        specification:
            'I need help finding a structured internship with supervision, practical tasks, and a clear start date.',
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
            'I need a practical online course with guided lessons, assignments, and proof of completion.',
        details: {
          'preferred_format': 'Online',
          'schedule': 'Flexible',
        },
      ),
      NeedFormPreset(
        label: 'Exam preparation',
        title: 'I want to prepare for [exam or qualification]',
        specification:
            'I need a study plan, guided practice, and feedback to prepare for an upcoming exam.',
        details: {
          'preferred_format': 'Either',
          'schedule': 'Weekends',
        },
      ),
      NeedFormPreset(
        label: 'Language lessons',
        title: 'I want language lessons for [learner or learning goal]',
        specification:
            'Share your current level, the skills you want to improve, and how you plan to use the language.',
        details: {
          'preferred_format': 'Online',
          'schedule': 'Flexible',
        },
      ),
      NeedFormPreset(
        label: 'Vocational training',
        title: 'I need vocational training for [learner or team]',
        specification:
            'Describe the practical skills, equipment access, and qualification or experience you need.',
        details: {
          'preferred_format': 'In-person',
        },
      ),
      NeedFormPreset(
        label: 'Career mentorship',
        title: 'I want guidance to grow in [career or field]',
        specification:
            'Share your goals, experience, and the kind of guidance or feedback you want.',
        details: {
          'preferred_format': 'Online',
          'schedule': 'Flexible',
        },
      ),
      NeedFormPreset(
        label: 'Skills instructor',
        title: 'I need an instructor for [learner or team]',
        specification:
            'Describe the practical learning outcomes and how learners should demonstrate their skills.',
      ),
    ],
    'travel_international': [
      NeedFormPreset(
        label: 'Visa help',
        title: 'Need help with a visa application',
        specification:
            'I need a verified travel provider to guide me through visa requirements, appointment steps, and supporting documents.',
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
            'I need a verified provider for a Hajj package including visa guidance, flights, accommodation, transport, and pilgrim support.',
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
            'I need an Umrah package with visa support, flights, hotel options near the holy sites, local transport, and clear pricing.',
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
            'I need help comparing flight options, accommodation, and an itinerary that fits my budget and travel dates.',
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
            'I need support with school travel planning, admissions-related travel steps, accommodation, and arrival guidance.',
        details: {
          'purpose': 'Study',
          'visa_type': 'Student visa',
        },
      ),
      NeedFormPreset(
        label: 'Family visit',
        title: 'I need help planning an international family visit',
        specification:
            'I need help arranging travel and accommodation for a family visit, including any entry requirements and local transport.',
        details: {
          'purpose': 'Family visit',
          'flexible_dates': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Business trip',
        title: 'Looking for a business trip itinerary',
        specification:
            'I need an itinerary for business travel, including suitable flights, accommodation, local transport, and schedule coordination.',
        details: {
          'purpose': 'Business',
          'flexible_dates': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Medical travel',
        title: 'I want to travel abroad for medical care',
        specification:
            'I need help planning medical travel, including suitable accommodation, local transport, and coordination around appointments.',
        details: {
          'purpose': 'Medical',
        },
      ),
      NeedFormPreset(
        label: 'Holiday trip',
        title: 'Planning a holiday abroad',
        specification:
            'I need help planning a holiday, comparing travel and accommodation options, and arranging an itinerary that fits my budget.',
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
            'I need reliable equipment for site work, delivered on time, with clear rental terms and maintenance support.',
        details: {
          'duration_days': '14',
          'operator_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Generator',
        title: 'I want a [generator type and capacity]',
        specification:
            'I need a generator with enough capacity for business use, including delivery, setup, and fuel guidance.',
        details: {
          'duration_days': '7',
          'operator_needed': 'false',
        },
      ),
      NeedFormPreset(
        label: 'Excavator',
        title: 'Looking for an excavator for [project or site]',
        specification:
            'I need an excavator suited to the job, with availability, operator terms, transport, and total rental cost clearly stated.',
        details: {
          'duration_days': '7',
          'operator_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Farm machinery',
        title: 'I want farm machinery for [field work or acreage]',
        specification:
            'I need machinery for farm work with availability, capacity, operator terms, transport, and total cost explained.',
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
            'Please note any required accounting standards, software, or business-specific constraints.',
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
            'Please note any jurisdiction, document format, or confidentiality requirements.',
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
            'Please note any reporting requirements, supporting records, or filing constraints.',
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
            'Please note any ownership, licensing, or registration requirements specific to the business.',
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
            'Please note the governing jurisdiction, preferred review format, or confidentiality requirements.',
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
            'Please note any preferred approach, industry experience, or constraints on the recommendations.',
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
            'Please note any required HR standards, confidentiality needs, or experience with your organization type.',
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
            'Please note any required registrations, applicable standards, or relevant site experience.',
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
            'Please note any preferred design style, approval requirements, or accessibility needs.',
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
            'Please note any required software, reporting preferences, or confidentiality constraints.',
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
            'Please note any preferred project method, reporting cadence, or required certifications.',
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
            'I need safe transport for goods with clear pickup timing, delivery timing, and handling requirements.',
        details: const {},
      ),
      NeedFormPreset(
        label: 'Delivery run',
        title: 'I need delivery for [items needed]',
        specification:
            'I need a provider to collect items, confirm receipt, and deliver them safely to the destination.',
        details: const {},
      ),
      NeedFormPreset(
        label: 'House move',
        title: 'Looking for help moving [household or office items]',
        specification:
            'Describe fragile or bulky items, access at both ends, and any packing or loading help required.',
      ),
      NeedFormPreset(
        label: 'Building materials',
        title: 'I need transport for [building materials]',
        specification:
            'Share the material type, load size, handling needs, and delivery timing.',
      ),
      NeedFormPreset(
        label: 'Farm produce',
        title: 'Looking for transport for [produce or livestock]',
        specification:
            'Describe the load, any temperature or animal care needs, and collection timing.',
      ),
      NeedFormPreset(
        label: 'Business deliveries',
        title: 'I need regular deliveries for [business or route]',
        specification:
            'Share delivery frequency, load size, handling requirements, and service hours.',
      ),
    ],
    'specialized_products': [
      NeedFormPreset(
        label: 'Bulk purchase',
        title: 'Need [product] in bulk',
        specification:
            'Please confirm product quality and current pricing, and share any suitable alternatives.',
        details: {
          'quantity': '50 units',
        },
      ),
      NeedFormPreset(
        label: 'Hard-to-find part',
        title: 'Looking for [part needed]',
        specification:
            'Please confirm compatibility with my equipment and suggest suitable replacement options.',
        details: {
          'quantity': '1 unit',
        },
      ),
      NeedFormPreset(
        label: 'Office equipment',
        title: 'I need [office equipment needed]',
        specification:
            'Please confirm the condition, warranty, and compatibility with the equipment I already use.',
        details: {
          'quantity': '1 unit',
        },
      ),
      NeedFormPreset(
        label: 'Building supplies',
        title: 'Looking for [building supplies needed]',
        specification:
            'Please confirm material grade, size, and whether equivalent products are acceptable.',
        details: {
          'quantity': '50 units',
        },
      ),
      NeedFormPreset(
        label: 'Safety supplies',
        title: 'Need [safety supplies needed]',
        specification:
            'Please confirm applicable safety standards, sizes, and product certifications.',
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
            'Please note any site access constraints, preferred roofing finish, or requirements for protecting occupied areas.',
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
            'Please note any access constraints, preferred fixtures or finishes, or work-hour restrictions.',
        details: {
          'project_type': 'Plumbing',
          'project_scope': 'Find and repair leaks in the water supply pipes',
        },
      ),
      NeedFormPreset(
        label: 'Install electrical wiring',
        title: 'Need an electrician for new wiring',
        specification:
            'Please note any access constraints, preferred work hours, or safety requirements.',
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
            'Please note any access constraints, preferred finish, or requirements for protecting furniture and floors.',
        details: {
          'project_type': 'Painting',
          'project_scope': 'Prepare and paint interior and exterior surfaces',
        },
      ),
    ],
    'agriculture_agribusiness': [
      NeedFormPreset(
        label: 'Farm inputs',
        title: 'I need [farm input] for my farm',
        specification:
            'I need reliable farm inputs with confirmed quantity, quality, price, and delivery timing.',
        details: {
          'agri_item': 'Seeds / fertilizer / chemicals',
          'volume_or_acres': 'For 5 acres',
        },
      ),
      NeedFormPreset(
        label: 'Harvester',
        title: 'Looking for farm machinery to hire',
        specification:
            'I need farm machinery for field work, including availability, operator terms, transport, and total cost.',
        details: {
          'agri_item': 'Combine harvester hire',
          'volume_or_acres': '10 acres',
        },
      ),
      NeedFormPreset(
        label: 'Irrigation',
        title: 'I want irrigation equipment for [crop or acreage]',
        specification:
            'I need an irrigation setup suited to the crop and farm size, with installation, water source, and running costs clearly explained.',
        details: {
          'agri_item': 'Irrigation equipment',
          'volume_or_acres': 'For 5 acres',
        },
      ),
      NeedFormPreset(
        label: 'Livestock feed',
        title: 'Looking for feed for [animal type]',
        specification:
            'I need suitable livestock feed with clear ingredients, quantity, quality, and delivery details.',
        details: {
          'agri_item': 'Livestock feed',
          'volume_or_acres': 'For 50 animals',
        },
      ),
      NeedFormPreset(
        label: 'Crop spraying',
        title: 'Need crop spraying for [crop or acreage]',
        specification:
            'I need crop spraying or pest control with the treatment, safety steps, timing, and total cost explained.',
        details: {
          'agri_item': 'Crop spraying / pest control',
          'volume_or_acres': 'For 5 acres',
        },
      ),
      NeedFormPreset(
        label: 'Tractor hire',
        title: 'I need a tractor for [farm task]',
        specification:
            'I need a tractor and suitable implement for farm work, with availability, operator terms, transport, and total cost confirmed.',
        details: {
          'agri_item': 'Tractor / farm implement hire',
          'volume_or_acres': '10 acres',
        },
      ),
      NeedFormPreset(
        label: 'Find a produce buyer',
        title: 'I need a buyer for [crop or produce]',
        specification:
            'I am looking for buyers and want to compare prices, quality requirements, quantities, and collection or delivery terms.',
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
            'I need a provider to design and launch a business website with mobile-friendly pages, contact options, and basic training.',
        details: {
          'deliverables': 'Website, domain setup, contact form',
          'timeline': '4 weeks',
        },
      ),
      NeedFormPreset(
        label: 'Mobile app',
        title: 'Need a mobile app for [purpose]',
        specification:
            'I need a team to build a mobile app with user accounts, core workflows, admin tools, testing, and launch support.',
        details: {
          'deliverables': 'Android app, admin portal, launch support',
          'timeline': '8 weeks',
        },
      ),
      NeedFormPreset(
        label: 'IT support',
        title: 'I need help with [computer or network issue]',
        specification:
            'Describe the issue, affected devices, and whether support is needed on site or remotely.',
        details: {
          'deliverables': 'Diagnosis, repair, and recommended next steps',
        },
      ),
      NeedFormPreset(
        label: 'Digital marketing',
        title: 'Looking for help to [marketing goal]',
        specification:
            'Share the audience, channels, and results you want to achieve.',
        details: {
          'deliverables': 'Campaign plan, content, and performance report',
        },
      ),
      NeedFormPreset(
        label: 'Software setup',
        title: 'I want to set up [software or system]',
        specification:
            'Include the tools involved, number of users, and any integrations needed.',
        details: {
          'deliverables': 'Installation, configuration, and user training',
        },
      ),
      NeedFormPreset(
        label: 'Data & cloud',
        title: 'I need help with [data or cloud task]',
        specification:
            'Describe the data or service, access needs, and expected outcome.',
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
            'I want a social media campaign with a content plan, creative assets, posting schedule, and performance summary.',
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
            'Include campaign setup, audience targeting, ad creatives, budget monitoring, and results reporting.',
        details: {
          'deliverables':
              'Ad setup, creative, optimization, and results report',
          'timeline': '4 weeks',
        },
      ),
      NeedFormPreset(
        label: 'Influencer campaign',
        title: 'Looking for creators to promote [product or service]',
        specification:
            'Share the audience, creator type, content format, and campaign goals.',
        details: {
          'deliverables':
              'Creator shortlist, agreed content, and campaign report',
        },
      ),
      NeedFormPreset(
        label: 'Brand identity',
        title: 'I need a brand identity for [business or product]',
        specification:
            'Describe the audience, brand style, and where the identity will be used.',
        details: {
          'deliverables':
              'Logo, color and type guide, and reusable brand files',
        },
      ),
      NeedFormPreset(
        label: 'Content creation',
        title: 'I want content for [campaign or platform]',
        specification:
            'List the content formats, quantity, publishing channels, and preferred style.',
        details: {
          'deliverables': 'Campaign-ready copy, graphics, or video content',
        },
      ),
      NeedFormPreset(
        label: 'Public relations',
        title: 'I need help sharing news about [brand or announcement]',
        specification:
            'Include the announcement, audiences, media targets, and desired coverage.',
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
            'Share menu preferences, dietary needs, service style, and setup requirements.',
      ),
      NeedFormPreset(
        label: 'Sound & stage',
        title: 'I need sound and stage equipment for [event type]',
        specification:
            'Describe the sound, stage, lighting, setup, and technical support needed.',
      ),
      NeedFormPreset(
        label: 'Event decor',
        title: 'I want decor for [event type]',
        specification:
            'Share the theme, colors, decoration style, setup, and teardown needs.',
      ),
      NeedFormPreset(
        label: 'Event photography',
        title: 'Looking for a photographer for [event type]',
        specification:
            'Describe coverage hours, photo style, editing, and delivery needs.',
      ),
      NeedFormPreset(
        label: 'DJ & entertainment',
        title: 'I need entertainment for [event type]',
        specification:
            'Share music preferences, performance length, equipment, and program needs.',
      ),
      NeedFormPreset(
        label: 'Event planning',
        title: 'I want help planning [event type]',
        specification:
            'List the planning, coordination, staffing, and supplier support you need.',
      ),
      NeedFormPreset(
        label: 'Venue hire',
        title: 'Looking for a venue for [event type]',
        specification:
            'Share your setup, accessibility, and facility requirements for the venue.',
      ),
      NeedFormPreset(
        label: 'Event equipment',
        title: 'I need equipment for [event type]',
        specification:
            'Name any equipment, delivery, setup, and collection requirements.',
      ),
    ],
    'music_video': [
      NeedFormPreset(
        label: 'Music video',
        title: 'Looking for a music video team for [artist or track]',
        specification:
            'Share the creative concept, visual style, crew, and final video formats you need.',
      ),
      NeedFormPreset(
        label: 'Live session',
        title: 'I want to record a live session for [artist or group]',
        specification:
            'Describe the audio and video setup, number of cameras, editing, and final files.',
      ),
      NeedFormPreset(
        label: 'Short film',
        title: 'I need a production team for [short film project]',
        specification:
            'Share the visual style, crew roles, equipment, and editing or delivery requirements.',
      ),
      NeedFormPreset(
        label: 'Event coverage',
        title: 'Looking for video coverage of [event]',
        specification:
            'Describe coverage hours, key moments, editing, and the final video format.',
      ),
      NeedFormPreset(
        label: 'Product video',
        title: 'I want a video to showcase [product or service]',
        specification:
            'Share the audience, style, key messages, and versions needed for each platform.',
      ),
      NeedFormPreset(
        label: 'Interview or podcast',
        title: 'I need recording and editing for [interview or podcast]',
        specification:
            'Describe the recording setup, number of speakers, editing, and audio or video deliverables.',
      ),
    ],
    'events_celebrations': [
      NeedFormPreset(
        label: 'Catering',
        title: 'I need catering for [celebration]',
        specification:
            'Share menu preferences, dietary needs, service style, and setup requirements.',
      ),
      NeedFormPreset(
        label: 'Decor',
        title: 'Looking for decor for [celebration]',
        specification:
            'Share the theme, colors, decoration style, setup, and teardown needs.',
      ),
      NeedFormPreset(
        label: 'Photography',
        title: 'I need a photographer for [celebration]',
        specification:
            'Describe coverage hours, photo style, editing, and delivery preferences.',
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
      NeedFormPreset(
        label: 'Venue setup',
        title: 'I need a venue for [celebration]',
        specification:
            'Share setup, accessibility, and facility requirements for the venue.',
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
        title: 'I need content created for [brand or platform]',
        specification:
            'Share the content format, style, publishing channels, and quantity.',
      ),
      NeedFormPreset(
        label: 'Presenter or MC',
        title: 'I need a presenter for [program or event]',
        specification:
            'Describe the audience, language, program length, and hosting style.',
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
            'Share the occasion, preferred styles, sizing needs, and budget range.',
      ),
      NeedFormPreset(
        label: 'Nails',
        title: 'Looking for nail services for [occasion or style]',
        specification:
            'Describe the design, products, and number of people to be served.',
      ),
      NeedFormPreset(
        label: 'Fashion design',
        title: 'I need an outfit designed for [occasion]',
        specification:
            'Share the design direction, fabric preferences, fitting needs, and deadline.',
      ),
    ],
    'domestic_household': [
      NeedFormPreset(
        label: 'Home cleaning',
        title: 'I need help cleaning [home or rooms]',
        specification:
            'Describe the areas, cleaning frequency, supplies, and any special care needs.',
      ),
      NeedFormPreset(
        label: 'Childcare',
        title: 'Looking for childcare for [child or schedule]',
        specification:
            'Share the schedule, routine, relevant experience, and care preferences.',
      ),
      NeedFormPreset(
        label: 'Home cooking',
        title: 'I need a cook for [household or occasion]',
        specification:
            'Mention meal preferences, dietary needs, and preparation schedule.',
      ),
      NeedFormPreset(
        label: 'Laundry',
        title: 'Looking for laundry help for [household or business]',
        specification:
            'Describe the volume, collection needs, and garment care preferences.',
      ),
      NeedFormPreset(
        label: 'Household support',
        title: 'I need household help with [routine or task]',
        specification:
            'List the regular tasks, schedule, and any access or household preferences.',
      ),
      NeedFormPreset(
        label: 'Home organization',
        title: 'I want help organizing [room or household area]',
        specification:
            'Share the areas, sorting needs, and preferred storage approach.',
      ),
    ],
    'health_medical': [
      NeedFormPreset(
        label: 'Dental care',
        title: 'I need help arranging dental care for [need]',
        specification:
            'Share appointment preferences and accessibility needs. Avoid posting private medical records.',
      ),
      NeedFormPreset(
        label: 'Clinic appointment',
        title: 'Looking to arrange a clinic appointment for [need]',
        specification:
            'Mention scheduling or accessibility needs. Share private records directly with the provider.',
      ),
      NeedFormPreset(
        label: 'Home nursing',
        title: 'I need a home care provider for [support needed]',
        specification:
            'Describe the type of support, schedule, and relevant provider qualifications.',
      ),
      NeedFormPreset(
        label: 'Physiotherapy',
        title: 'Looking for physiotherapy support for [goal]',
        specification:
            'Share appointment preferences, mobility access needs, and provider requirements.',
      ),
      NeedFormPreset(
        label: 'Lab services',
        title: 'I need help arranging [lab service]',
        specification:
            'Mention timing or collection needs. Share any private medical information directly with the provider.',
      ),
      NeedFormPreset(
        label: 'Medical equipment',
        title: 'Looking for [medical equipment needed]',
        specification:
            'Describe compatibility, delivery, setup, or training requirements.',
      ),
    ],
    'traditional_cultural': [
      NeedFormPreset(
        label: 'Cultural ceremony',
        title: 'I need support with [cultural ceremony]',
        specification:
            'Share the ceremony program, traditions to observe, and participant needs.',
      ),
      NeedFormPreset(
        label: 'Traditional attire',
        title: 'Looking for traditional attire for [occasion]',
        specification:
            'Describe the style, number of outfits, sizing, and completion date.',
      ),
      NeedFormPreset(
        label: 'Music and dance',
        title: 'I need cultural performers for [occasion]',
        specification:
            'Share the performance type, duration, group size, and technical setup.',
      ),
      NeedFormPreset(
        label: 'Ceremony host',
        title: 'Looking for a host for [traditional occasion]',
        specification:
            'Mention language, program length, audience, and traditions to observe.',
      ),
      NeedFormPreset(
        label: 'Cultural instruction',
        title: 'I want instruction in [cultural skill or practice]',
        specification:
            'Describe the learning goal, experience level, and preferred schedule.',
      ),
      NeedFormPreset(
        label: 'Ceremony supplies',
        title: 'I need supplies for [cultural occasion]',
        specification:
            'List the items, quantities, quality preferences, and delivery timing.',
      ),
    ],
    'financial_services': [
      NeedFormPreset(
        label: 'Business financing',
        title: 'I want to compare financing for [business need]',
        specification:
            'Share the intended use, timing, and repayment preferences. Do not include account numbers.',
      ),
      NeedFormPreset(
        label: 'Personal loan',
        title: 'Looking for a personal loan for [purpose]',
        specification:
            'Mention the amount range and timing. Do not share account or identity numbers.',
      ),
      NeedFormPreset(
        label: 'SACCO membership',
        title: 'I want to join a SACCO for [goal]',
        specification:
            'Share your preferred area, membership questions, and savings goals.',
      ),
      NeedFormPreset(
        label: 'Savings group',
        title: 'Looking for a savings group for [goal]',
        specification:
            'Mention contribution preferences, meeting schedule, and membership questions.',
      ),
      NeedFormPreset(
        label: 'Currency exchange',
        title: 'I need help exchanging [currency or amount]',
        specification:
            'Share the currencies, timing, and preferred transaction method. Do not include account numbers.',
      ),
      NeedFormPreset(
        label: 'Financial planning',
        title: 'I want financial planning support for [goal]',
        specification:
            'Describe your goals, preferred support, and any qualifications you expect.',
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
            'I need a provider to size, quote, install, and commission a solar power system for my site.',
        details: {
          'system_type': 'Solar system',
          'installation_labor_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Water pump',
        title: 'Looking for a reliable water supply for my site',
        specification:
            'I need a provider to supply or install a water pump system with clear capacity, materials, and commissioning support.',
        details: {
          'system_type': 'Water pump',
          'installation_labor_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Solar maintenance',
        title: 'I need maintenance for [solar system or issue]',
        specification:
            'Describe the system, symptoms, previous repairs, and any parts you suspect need attention.',
        details: {'system_type': 'Solar system'},
      ),
      NeedFormPreset(
        label: 'Water treatment',
        title: 'I need water treatment for [home or business]',
        specification:
            'Describe the water source, intended use, and any known quality concerns.',
        details: {'system_type': 'Water treatment / filtration system'},
      ),
      NeedFormPreset(
        label: 'Borehole pump',
        title: 'Looking for a borehole pump for [site]',
        specification:
            'Share the borehole depth, required flow, power availability, and installation needs.',
        details: {'system_type': 'Borehole pump'},
      ),
      NeedFormPreset(
        label: 'Backup power',
        title: 'I need backup power for [property or equipment]',
        specification:
            'I need a backup power system sized for my essential equipment, with runtime, installation, and maintenance needs covered.',
        details: {
          'system_type': 'Backup power',
          'installation_labor_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Borehole pump',
        title: 'Looking for a pump for [water source or use]',
        specification:
            'I need a pump suited to the water source and expected demand, with capacity, materials, and installation costs explained.',
        details: {
          'system_type': 'Borehole pump',
          'installation_labor_needed': 'true',
        },
      ),
      NeedFormPreset(
        label: 'Solar repair',
        title: 'Need help repairing an existing power system',
        specification:
            'I need a provider to inspect and repair an existing system, identify faulty components, and explain the repair cost and warranty.',
        details: {
          'system_type': 'Solar system inspection / repair',
        },
      ),
      NeedFormPreset(
        label: 'Water filtration',
        title: 'I want safer water for [household or business]',
        specification:
            'I need a water treatment or filtration solution suited to the source and usage, with maintenance needs clearly explained.',
        details: {
          'system_type': 'Water treatment / filtration system',
          'installation_labor_needed': 'true',
        },
      ),
    ],
  };

  static List<NeedFormPreset> presetsForCategory(String slug) {
    return categoryPresets[slug] ??
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
                'I want providers to send clear quotes with price, timeline, deliverables, and any requirements from my side.',
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
        helperText: 'An approximate month is fine.',
      ),
      NeedFormField.date(
        'return_date',
        label: 'Return date (if applicable)',
        hint: 'e.g. 15 January 2027',
        helperText: 'Optional if unknown.',
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
        label: 'Departure city',
        hint: 'Town or city you are travelling from',
        helperText: 'Used to find relevant routes and providers.',
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
