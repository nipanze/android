// lib/features/provider/domain/entities/provider_service_role.dart

class ProviderServiceRole {
  const ProviderServiceRole({
    required this.slug,
    required this.name,
    this.description,
    this.kindQuestion,
    this.categorySlug,
    this.capabilitySlug,
    this.kinds = const [],
    this.qualifications = const [],
  });

  factory ProviderServiceRole.fromMap(Map<String, dynamic> map) {
    final qualificationsByMeaning = <String, ProviderRoleQualification>{};
    for (final value in ((map['role_qualifications'] as List?) ?? const [])) {
      final qualification = ProviderRoleQualification.fromMap(value);
      final normalizedName = qualification.name
          .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .toLowerCase();
      final key = normalizedName.isEmpty ? qualification.slug : normalizedName;
      final existing = qualificationsByMeaning[key];
      if (existing == null) {
        qualificationsByMeaning[key] = qualification;
      } else {
        qualificationsByMeaning[key] = ProviderRoleQualification(
          // Keep the first catalog key so saved answers and proof submissions
          // continue to use a valid qualification slug.
          slug: existing.slug,
          name: qualification.name.length > existing.name.length
              ? qualification.name
              : existing.name,
          isEvidence: existing.isEvidence || qualification.isEvidence,
        );
      }
    }
    return ProviderServiceRole(
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      kindQuestion: map['kind_question'] as String?,
      categorySlug: map['category_slug'] as String?,
      capabilitySlug: map['capability_slug'] as String?,
      kinds: ((map['role_kinds'] as List?) ?? const [])
          .map(ProviderRoleOption.fromMap)
          .toList(),
      qualifications: qualificationsByMeaning.values.toList(),
    );
  }

  final String slug;
  final String name;
  final String? description;
  final String? kindQuestion;
  final String? categorySlug;
  final String? capabilitySlug;
  final List<ProviderRoleOption> kinds;
  final List<ProviderRoleQualification> qualifications;

  static List<ProviderServiceRole> defaultsForCategory(String? categorySlug) {
    if (categorySlug == null) return const [];
    final normalized = switch (categorySlug) {
      'music_video' || 'photo_video_talent' => 'photo_video_music_talent',
      'weddings_celebrations' || 'events_celebrations' => 'events_production',
      'beauty_fashion' => 'beauty_fashion_styling',
      _ => categorySlug,
    };
    return defaults.where((r) => r.categorySlug == normalized).toList();
  }

  static const List<ProviderServiceRole> defaults = [
    ProviderServiceRole(
      slug: 'developer',
      name: 'Developer',
      description: 'Build web, mobile, and software applications',
      kindQuestion: 'What do you build?',
      categorySlug: 'technology_digital',
      capabilitySlug: 'work_developer',
      kinds: [
        ProviderRoleOption(slug: 'frontend', name: 'Frontend'),
        ProviderRoleOption(slug: 'backend', name: 'Backend'),
        ProviderRoleOption(slug: 'full_stack', name: 'Full-stack'),
        ProviderRoleOption(slug: 'mobile', name: 'Mobile'),
        ProviderRoleOption(slug: 'qa_tester', name: 'QA / Tester'),
        ProviderRoleOption(slug: 'devops', name: 'DevOps'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'degree_diploma_in_it_or_cs',
            name: 'Degree / Diploma in IT or CS',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'portfolio_or_github_link',
            name: 'Portfolio or GitHub link',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'cloud_certification_aws_azure_gcp',
            name: 'Cloud certification (AWS/Azure/GCP)',
            isEvidence: false),
        ProviderRoleQualification(
            slug: '3_years_experience',
            name: '3+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'it_technician',
      name: 'IT Technician',
      description: 'Hardware maintenance, helpdesk, and networks',
      kindQuestion: 'What do you do?',
      categorySlug: 'technology_digital',
      capabilitySlug: 'work_it_technician',
      kinds: [
        ProviderRoleOption(slug: 'helpdesk', name: 'Helpdesk'),
        ProviderRoleOption(slug: 'hardware_repair', name: 'Hardware repair'),
        ProviderRoleOption(
            slug: 'network_installation', name: 'Network installation'),
        ProviderRoleOption(
            slug: 'cctv_access_control', name: 'CCTV & access control'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'comptia_a_n', name: 'CompTIA A+ / N+', isEvidence: false),
        ProviderRoleQualification(
            slug: 'ccna', name: 'CCNA', isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_toolkit', name: 'Own toolkit', isEvidence: false),
        ProviderRoleQualification(
            slug: '2_years_experience',
            name: '2+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'security_specialist',
      name: 'Security Specialist',
      description: 'Cybersecurity, compliance, and systems audits',
      kindQuestion: 'Which area?',
      categorySlug: 'technology_digital',
      capabilitySlug: 'work_security_specialist',
      kinds: [
        ProviderRoleOption(slug: 'network_security', name: 'Network security'),
        ProviderRoleOption(
            slug: 'penetration_testing', name: 'Penetration testing'),
        ProviderRoleOption(slug: 'security_audits', name: 'Security audits'),
      ],
      qualifications: [
        ProviderRoleQualification(slug: 'ceh', name: 'CEH', isEvidence: false),
        ProviderRoleQualification(
            slug: 'cissp_cism', name: 'CISSP / CISM', isEvidence: false),
        ProviderRoleQualification(
            slug: 'iso_27001', name: 'ISO 27001', isEvidence: false),
        ProviderRoleQualification(
            slug: 'police_clearance',
            name: 'Police clearance',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'project_manager',
      name: 'Project Manager',
      description: 'Lead project scope, timelines, and deliverables',
      kindQuestion: 'What kind of projects?',
      categorySlug: 'technology_digital',
      capabilitySlug: 'work_project_manager',
      kinds: [
        ProviderRoleOption(slug: 'software', name: 'Software'),
        ProviderRoleOption(
            slug: 'it_infrastructure', name: 'IT infrastructure'),
        ProviderRoleOption(
            slug: 'digital_transformation', name: 'Digital transformation'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'pmp_prince2', name: 'PMP / PRINCE2', isEvidence: false),
        ProviderRoleQualification(
            slug: 'agile_scrum_certified',
            name: 'Agile / Scrum certified',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'led_3_projects', name: 'Led 3+ projects', isEvidence: false),
        ProviderRoleQualification(
            slug: 'degree', name: 'Degree', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'team_lead_manager',
      name: 'Team Lead / Manager',
      description: 'Lead technical teams, processes, and delivery',
      kindQuestion: 'What do you lead?',
      categorySlug: 'technology_digital',
      capabilitySlug: 'work_team_lead_manager',
      kinds: [
        ProviderRoleOption(slug: 'dev_team', name: 'Dev team'),
        ProviderRoleOption(slug: 'it_support_team', name: 'IT / support team'),
        ProviderRoleOption(slug: 'product', name: 'Product'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'managed_5_people',
            name: 'Managed 5+ people',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'degree', name: 'Degree', isEvidence: false),
        ProviderRoleQualification(
            slug: '3_years_leadership',
            name: '3+ years leadership',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'marketer_specialist',
      name: 'Marketer / Specialist',
      description: 'Digital marketing, growth, and campaigns',
      kindQuestion: 'Which channel?',
      categorySlug: 'marketing_promotion',
      capabilitySlug: 'work_marketer_specialist',
      kinds: [
        ProviderRoleOption(slug: 'social_media', name: 'Social media'),
        ProviderRoleOption(slug: 'seo_sem', name: 'SEO / SEM'),
        ProviderRoleOption(slug: 'email', name: 'Email'),
        ProviderRoleOption(slug: 'brand', name: 'Brand'),
        ProviderRoleOption(
            slug: 'community_management', name: 'Community management'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'marketing_diploma_degree',
            name: 'Marketing diploma / degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'google_ads_meta_certified',
            name: 'Google Ads / Meta certified',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'case_studies_or_portfolio',
            name: 'Case studies or portfolio',
            isEvidence: false),
        ProviderRoleQualification(
            slug: '2_years_experience',
            name: '2+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'content_creator',
      name: 'Content Creator',
      description: 'Social media content, copy, video, and design',
      kindQuestion: 'What do you produce?',
      categorySlug: 'marketing_promotion',
      capabilitySlug: 'work_content_creator',
      kinds: [
        ProviderRoleOption(slug: 'video', name: 'Video'),
        ProviderRoleOption(slug: 'photo', name: 'Photo'),
        ProviderRoleOption(slug: 'writing', name: 'Writing'),
        ProviderRoleOption(slug: 'design', name: 'Design'),
        ProviderRoleOption(slug: 'podcast', name: 'Podcast'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'portfolio', name: 'Portfolio', isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_equipment', name: 'Own equipment', isEvidence: false),
        ProviderRoleQualification(
            slug: 'audience_size_proof',
            name: 'Audience size proof',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'marketing_manager',
      name: 'Marketing Manager',
      description: 'Brand strategy, marketing teams, and budgets',
      kindQuestion: 'What scope?',
      categorySlug: 'marketing_promotion',
      capabilitySlug: 'work_marketing_manager',
      kinds: [
        ProviderRoleOption(slug: 'brand', name: 'Brand'),
        ProviderRoleOption(slug: 'digital', name: 'Digital'),
        ProviderRoleOption(
            slug: 'events_promotions', name: 'Events & promotions'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'degree', name: 'Degree', isEvidence: false),
        ProviderRoleQualification(
            slug: 'managed_budgets',
            name: 'Managed budgets',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'managed_3_people',
            name: 'Managed 3+ people',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'campaign_project_manager',
      name: 'Campaign Project Manager',
      description: 'Manage advertising campaigns end-to-end',
      kindQuestion: 'Campaign type?',
      categorySlug: 'marketing_promotion',
      capabilitySlug: 'work_campaign_project_manager',
      kinds: [
        ProviderRoleOption(slug: 'digital', name: 'Digital'),
        ProviderRoleOption(
            slug: 'field_activation', name: 'Field / activation'),
        ProviderRoleOption(slug: 'event', name: 'Event'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'pmp_prince2', name: 'PMP / PRINCE2', isEvidence: false),
        ProviderRoleQualification(
            slug: 'led_3_campaigns',
            name: 'Led 3+ campaigns',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'accountant_finance_officer',
      name: 'Accountant / Finance Officer',
      description: 'Bookkeeping, tax compliance, and auditing',
      kindQuestion: 'What area?',
      categorySlug: 'professional_services',
      capabilitySlug: 'work_accountant_finance_officer',
      kinds: [
        ProviderRoleOption(slug: 'bookkeeping', name: 'Bookkeeping'),
        ProviderRoleOption(slug: 'tax', name: 'Tax'),
        ProviderRoleOption(slug: 'audit', name: 'Audit'),
        ProviderRoleOption(slug: 'payroll', name: 'Payroll'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'cpa_acca_cpa_u',
            name: 'CPA / ACCA / CPA-U',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'degree', name: 'Degree', isEvidence: false),
        ProviderRoleQualification(
            slug: 'practising_certificate',
            name: 'Practising certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: '3_years_experience',
            name: '3+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'lawyer_legal_officer',
      name: 'Lawyer / Legal Officer',
      description: 'Contracts, company law, and dispute advisory',
      kindQuestion: 'What area?',
      categorySlug: 'professional_services',
      capabilitySlug: 'work_lawyer_legal_officer',
      kinds: [
        ProviderRoleOption(slug: 'corporate', name: 'Corporate'),
        ProviderRoleOption(slug: 'property', name: 'Property'),
        ProviderRoleOption(slug: 'contracts', name: 'Contracts'),
        ProviderRoleOption(slug: 'compliance', name: 'Compliance'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'bar_admission_practising_certificate',
            name: 'Bar admission / practising certificate',
            isEvidence: false),
        ProviderRoleQualification(slug: 'llb', name: 'LLB', isEvidence: false),
        ProviderRoleQualification(
            slug: '3_years_experience',
            name: '3+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'engineer',
      name: 'Engineer',
      description: 'Civil, structural, electrical, or mechanical engineering',
      kindQuestion: 'Which discipline?',
      categorySlug: 'professional_services',
      capabilitySlug: 'work_engineer',
      kinds: [
        ProviderRoleOption(slug: 'civil', name: 'Civil'),
        ProviderRoleOption(slug: 'electrical', name: 'Electrical'),
        ProviderRoleOption(slug: 'mechanical', name: 'Mechanical'),
        ProviderRoleOption(slug: 'mining', name: 'Mining'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'degree_in_engineering',
            name: 'Degree in engineering',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'registered_with_engineers_board',
            name: 'Registered with engineers board',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'site_experience',
            name: 'Site experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'architect_designer',
      name: 'Architect / Designer',
      description: 'Architectural design, drawings, and approvals',
      kindQuestion: 'What do you design?',
      categorySlug: 'professional_services',
      capabilitySlug: 'work_architect_designer',
      kinds: [
        ProviderRoleOption(slug: 'buildings', name: 'Buildings'),
        ProviderRoleOption(slug: 'interiors', name: 'Interiors'),
        ProviderRoleOption(slug: 'landscape', name: 'Landscape'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'registered_architect',
            name: 'Registered architect',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'portfolio', name: 'Portfolio', isEvidence: false),
        ProviderRoleQualification(
            slug: 'cad_bim_skills', name: 'CAD/BIM skills', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'hr_officer_manager',
      name: 'HR Officer / Manager',
      description: 'Recruitment, payroll, and staff management',
      kindQuestion: 'What area?',
      categorySlug: 'professional_services',
      capabilitySlug: 'work_hr_officer_manager',
      kinds: [
        ProviderRoleOption(slug: 'recruitment', name: 'Recruitment'),
        ProviderRoleOption(
            slug: 'payroll_benefits', name: 'Payroll & benefits'),
        ProviderRoleOption(
            slug: 'training_compliance', name: 'Training & compliance'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'hr_diploma_degree',
            name: 'HR diploma / degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'ihrm_cipd', name: 'IHRM / CIPD', isEvidence: false),
        ProviderRoleQualification(
            slug: '3_years_experience',
            name: '3+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'business_administrator_office_manager',
      name: 'Business Administrator / Office Manager',
      description: 'Day-to-day office operations and admin',
      kindQuestion: 'What kind of admin work?',
      categorySlug: 'professional_services',
      capabilitySlug: 'work_business_administrator_office_manager',
      kinds: [
        ProviderRoleOption(
            slug: 'office_administration', name: 'Office administration'),
        ProviderRoleOption(
            slug: 'operations_support', name: 'Operations support'),
        ProviderRoleOption(
            slug: 'executive_assistant', name: 'Executive assistant'),
        ProviderRoleOption(
            slug: 'records_documentation', name: 'Records & documentation'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'diploma_degree_in_business_administration',
            name: 'Diploma / degree in business administration',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'office_software_skills_documents_spreadsheets_email',
            name: 'Office software skills (documents, spreadsheets, email)',
            isEvidence: false),
        ProviderRoleQualification(
            slug: '2_years_experience',
            name: '2+ years experience',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'references', name: 'References', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'consultant',
      name: 'Consultant',
      description: 'Strategic, management, or financial consulting',
      kindQuestion: 'Advisory area?',
      categorySlug: 'professional_services',
      capabilitySlug: 'work_consultant',
      kinds: [
        ProviderRoleOption(slug: 'strategy', name: 'Strategy'),
        ProviderRoleOption(slug: 'operations', name: 'Operations'),
        ProviderRoleOption(slug: 'finance', name: 'Finance'),
        ProviderRoleOption(slug: 'compliance', name: 'Compliance'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'degree', name: 'Degree', isEvidence: false),
        ProviderRoleQualification(
            slug: 'case_studies', name: 'Case studies', isEvidence: false),
        ProviderRoleQualification(
            slug: '5_years_experience',
            name: '5+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'professional_services_project_manager',
      name: 'Project Manager',
      description: 'Manage professional client projects',
      kindQuestion: 'What kind of projects?',
      categorySlug: 'professional_services',
      capabilitySlug: 'work_professional_services_project_manager',
      kinds: [
        ProviderRoleOption(slug: 'business', name: 'Business'),
        ProviderRoleOption(slug: 'compliance', name: 'Compliance'),
        ProviderRoleOption(slug: 'operations', name: 'Operations'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'pmp_prince2', name: 'PMP / PRINCE2', isEvidence: false),
        ProviderRoleQualification(
            slug: 'led_3_projects', name: 'Led 3+ projects', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'teacher_tutor',
      name: 'Teacher / Tutor',
      description: 'Curriculum instruction, tutoring, and exam prep',
      kindQuestion: 'What do you teach?',
      categorySlug: 'education_training',
      capabilitySlug: 'work_teacher_tutor',
      kinds: [
        ProviderRoleOption(slug: 'primary', name: 'Primary'),
        ProviderRoleOption(slug: 'secondary', name: 'Secondary'),
        ProviderRoleOption(slug: 'university', name: 'University'),
        ProviderRoleOption(slug: 'languages', name: 'Languages'),
        ProviderRoleOption(slug: 'exam_prep', name: 'Exam prep'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'teaching_certificate_degree',
            name: 'Teaching certificate / degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'registered_with_teaching_board',
            name: 'Registered with teaching board',
            isEvidence: false),
        ProviderRoleQualification(
            slug: '2_years_teaching',
            name: '2+ years teaching',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'subject_specialisation',
            name: 'Subject specialisation',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'trainer_instructor',
      name: 'Trainer / Instructor',
      description: 'Corporate, technical, or vocational skills training',
      kindQuestion: 'Training field?',
      categorySlug: 'education_training',
      capabilitySlug: 'work_trainer_instructor',
      kinds: [
        ProviderRoleOption(slug: 'computer_it', name: 'Computer / IT'),
        ProviderRoleOption(
            slug: 'vocational_technical', name: 'Vocational / technical'),
        ProviderRoleOption(
            slug: 'professional_corporate', name: 'Professional / corporate'),
        ProviderRoleOption(slug: 'driving', name: 'Driving'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'trade_certificate',
            name: 'Trade certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'trainer_of_trainers_tot',
            name: 'Trainer-of-trainers (ToT)',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'industry_experience_3_years',
            name: 'Industry experience 3+ years',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'placement_coordinator',
      name: 'Placement Coordinator',
      description: 'Student placements, internships, and admissions',
      kindQuestion: 'What placements?',
      categorySlug: 'education_training',
      capabilitySlug: 'work_placement_coordinator',
      kinds: [
        ProviderRoleOption(slug: 'internships', name: 'Internships'),
        ProviderRoleOption(slug: 'nursing_health', name: 'Nursing / health'),
        ProviderRoleOption(slug: 'study_abroad', name: 'Study abroad'),
        ProviderRoleOption(slug: 'university', name: 'University'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'education_or_hr_background',
            name: 'Education or HR background',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'partner_network',
            name: 'Partner network',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'counselling_certificate',
            name: 'Counselling certificate',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'programme_manager',
      name: 'Programme Manager',
      description: 'Manage educational programmes and courses',
      kindQuestion: 'What programmes?',
      categorySlug: 'education_training',
      capabilitySlug: 'work_programme_manager',
      kinds: [
        ProviderRoleOption(
            slug: 'training_programmes', name: 'Training programmes'),
        ProviderRoleOption(
            slug: 'placement_programmes', name: 'Placement programmes'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'degree', name: 'Degree', isEvidence: false),
        ProviderRoleQualification(
            slug: 'managed_3_programmes',
            name: 'Managed 3+ programmes',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'event_manager_planner',
      name: 'Event Manager / Planner',
      description: 'Full event planning, vendors, and coordination',
      kindQuestion: 'What events?',
      categorySlug: 'events_production',
      capabilitySlug: 'work_event_manager_planner',
      kinds: [
        ProviderRoleOption(slug: 'weddings', name: 'Weddings'),
        ProviderRoleOption(slug: 'corporate', name: 'Corporate'),
        ProviderRoleOption(
            slug: 'birthdays_parties', name: 'Birthdays & parties'),
        ProviderRoleOption(slug: 'graduations', name: 'Graduations'),
        ProviderRoleOption(
            slug: 'funerals_memorials', name: 'Funerals & memorials'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'event_planning_certificate',
            name: 'Event planning certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'portfolio_of_5_events',
            name: 'Portfolio of 5+ events',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'insurance_permit',
            name: 'Insurance / permit',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'team_of_3_staff',
            name: 'Team of 3+ staff',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'mc_dj',
      name: 'MC / DJ',
      description: 'Event hosting, emcee, DJ, and entertainment',
      kindQuestion: 'Which role?',
      categorySlug: 'events_production',
      capabilitySlug: 'work_mc_dj',
      kinds: [
        ProviderRoleOption(slug: 'mc', name: 'MC'),
        ProviderRoleOption(slug: 'dj', name: 'DJ'),
        ProviderRoleOption(slug: 'both', name: 'Both'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'own_equipment', name: 'Own equipment', isEvidence: false),
        ProviderRoleQualification(
            slug: 'sample_mix_video',
            name: 'Sample mix / video',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'references', name: 'References', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'event_crew_technician',
      name: 'Event Crew / Technician',
      description: 'Stage, sound, lighting, and AV technician',
      kindQuestion: 'What do you operate?',
      categorySlug: 'events_production',
      capabilitySlug: 'work_event_crew_technician',
      kinds: [
        ProviderRoleOption(slug: 'sound', name: 'Sound'),
        ProviderRoleOption(slug: 'lighting', name: 'Lighting'),
        ProviderRoleOption(slug: 'tents_setup', name: 'Tents & setup'),
        ProviderRoleOption(slug: 'stage', name: 'Stage'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'technical_training',
            name: 'Technical training',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_tools', name: 'Own tools', isEvidence: false),
        ProviderRoleQualification(
            slug: 'event_experience_1_year',
            name: 'Event experience 1+ year',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'caterer_chef',
      name: 'Caterer / Chef',
      description: 'Food preparation and event catering',
      kindQuestion: 'What kind?',
      categorySlug: 'events_production',
      capabilitySlug: 'work_caterer_chef',
      kinds: [
        ProviderRoleOption(slug: 'event_catering', name: 'Event catering'),
        ProviderRoleOption(slug: 'cakes_baking', name: 'Cakes & baking'),
        ProviderRoleOption(slug: 'buffet_plated', name: 'Buffet / plated'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'food_handler_certificate',
            name: 'Food handler certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'health_permit', name: 'Health permit', isEvidence: false),
        ProviderRoleQualification(
            slug: 'culinary_diploma',
            name: 'Culinary diploma',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'event_supervisor',
      name: 'Event Supervisor',
      description: 'On-site event supervision and logistics',
      kindQuestion: 'What scope?',
      categorySlug: 'events_production',
      capabilitySlug: 'work_event_supervisor',
      kinds: [
        ProviderRoleOption(slug: 'venue', name: 'Venue'),
        ProviderRoleOption(slug: 'logistics', name: 'Logistics'),
        ProviderRoleOption(slug: 'guest_management', name: 'Guest management'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'managed_5_events',
            name: 'Managed 5+ events',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'team_leadership',
            name: 'Team leadership',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'photographer_videographer',
      name: 'Photographer / Videographer',
      description: 'Photo shoots, video production, and editing',
      kindQuestion: 'What do you shoot?',
      categorySlug: 'photo_video_music_talent',
      capabilitySlug: 'work_photographer_videographer',
      kinds: [
        ProviderRoleOption(slug: 'weddings', name: 'Weddings'),
        ProviderRoleOption(slug: 'corporate', name: 'Corporate'),
        ProviderRoleOption(
            slug: 'fashion_portraits', name: 'Fashion & portraits'),
        ProviderRoleOption(slug: 'music_videos', name: 'Music videos'),
        ProviderRoleOption(slug: 'real_estate', name: 'Real estate'),
        ProviderRoleOption(slug: 'graduations', name: 'Graduations'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'portfolio_link', name: 'Portfolio link', isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_camera_drone_kit',
            name: 'Own camera / drone kit',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'drone_licence', name: 'Drone licence', isEvidence: false),
        ProviderRoleQualification(
            slug: 'editing_skills', name: 'Editing skills', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'audio_engineer_producer',
      name: 'Audio Engineer / Producer',
      description: 'Music recording, sound design, and mixing',
      kindQuestion: 'What do you do?',
      categorySlug: 'photo_video_music_talent',
      capabilitySlug: 'work_audio_engineer_producer',
      kinds: [
        ProviderRoleOption(slug: 'recording', name: 'Recording'),
        ProviderRoleOption(
            slug: 'mixing_mastering', name: 'Mixing & mastering'),
        ProviderRoleOption(slug: 'beat_production', name: 'Beat production'),
        ProviderRoleOption(slug: 'live_sound', name: 'Live sound'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'own_studio_daw',
            name: 'Own studio / DAW',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'portfolio', name: 'Portfolio', isEvidence: false),
        ProviderRoleQualification(
            slug: 'audio_engineering_diploma',
            name: 'Audio engineering diploma',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'performer_talent',
      name: 'Performer / Talent',
      description: 'Musician, vocalist, voice artist, or actor',
      kindQuestion: 'What kind?',
      categorySlug: 'photo_video_music_talent',
      capabilitySlug: 'work_performer_talent',
      kinds: [
        ProviderRoleOption(slug: 'singer', name: 'Singer'),
        ProviderRoleOption(slug: 'dancer', name: 'Dancer'),
        ProviderRoleOption(slug: 'actor', name: 'Actor'),
        ProviderRoleOption(slug: 'model', name: 'Model'),
        ProviderRoleOption(slug: 'extra', name: 'Extra'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'showreel_audition_clip',
            name: 'Showreel / audition clip',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'agency_representation',
            name: 'Agency representation',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'performance_experience',
            name: 'Performance experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'production_manager',
      name: 'Production Manager',
      description: 'Manage video, shoot, and production crews',
      kindQuestion: 'What productions?',
      categorySlug: 'photo_video_music_talent',
      capabilitySlug: 'work_production_manager',
      kinds: [
        ProviderRoleOption(slug: 'video_film', name: 'Video / film'),
        ProviderRoleOption(slug: 'music', name: 'Music'),
        ProviderRoleOption(slug: 'live_events', name: 'Live events'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'managed_3_productions',
            name: 'Managed 3+ productions',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'budget_handling',
            name: 'Budget handling',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'crew_network', name: 'Crew network', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'makeup_artist',
      name: 'Makeup Artist',
      description: 'Bridal, event, and editorial makeup',
      kindQuestion: 'Specialty?',
      categorySlug: 'beauty_fashion_styling',
      capabilitySlug: 'work_makeup_artist',
      kinds: [
        ProviderRoleOption(slug: 'bridal', name: 'Bridal'),
        ProviderRoleOption(
            slug: 'fashion_editorial', name: 'Fashion / editorial'),
        ProviderRoleOption(slug: 'film_stage', name: 'Film / stage'),
        ProviderRoleOption(slug: 'everyday', name: 'Everyday'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'cosmetology_certificate',
            name: 'Cosmetology certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'portfolio', name: 'Portfolio', isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_kit', name: 'Own kit', isEvidence: false),
        ProviderRoleQualification(
            slug: 'hygiene_certification',
            name: 'Hygiene certification',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'hair_stylist',
      name: 'Hair Stylist',
      description: 'Haircuts, styling, weaving, and treatments',
      kindQuestion: 'Specialty?',
      categorySlug: 'beauty_fashion_styling',
      capabilitySlug: 'work_hair_stylist',
      kinds: [
        ProviderRoleOption(slug: 'braiding', name: 'Braiding'),
        ProviderRoleOption(slug: 'salon_styling', name: 'Salon styling'),
        ProviderRoleOption(slug: 'bridal_hair', name: 'Bridal hair'),
        ProviderRoleOption(slug: 'barbering', name: 'Barbering'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'cosmetology_certificate',
            name: 'Cosmetology certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'portfolio', name: 'Portfolio', isEvidence: false),
        ProviderRoleQualification(
            slug: 'salon_licence', name: 'Salon licence', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'stylist_designer',
      name: 'Stylist / Designer',
      description: 'Fashion design, tailoring, and wardrobe styling',
      kindQuestion: 'Specialty?',
      categorySlug: 'beauty_fashion_styling',
      capabilitySlug: 'work_stylist_designer',
      kinds: [
        ProviderRoleOption(slug: 'wardrobe_styling', name: 'Wardrobe styling'),
        ProviderRoleOption(slug: 'tailoring', name: 'Tailoring'),
        ProviderRoleOption(slug: 'bridal_wear', name: 'Bridal wear'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'fashion_diploma',
            name: 'Fashion diploma',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'portfolio', name: 'Portfolio', isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_workshop', name: 'Own workshop', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'salon_studio_manager',
      name: 'Salon / Studio Manager',
      description: 'Manage salon, spa, or studio operations',
      kindQuestion: 'What scope?',
      categorySlug: 'beauty_fashion_styling',
      capabilitySlug: 'work_salon_studio_manager',
      kinds: [
        ProviderRoleOption(slug: 'salon', name: 'Salon'),
        ProviderRoleOption(slug: 'fashion_studio', name: 'Fashion studio'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'managed_3_staff',
            name: 'Managed 3+ staff',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'business_licence',
            name: 'Business licence',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'site_manager',
      name: 'Site Manager',
      description: 'Overall construction site execution and safety',
      kindQuestion: 'What type of sites?',
      categorySlug: 'construction_building',
      capabilitySlug: 'work_site_manager',
      kinds: [
        ProviderRoleOption(slug: 'residential', name: 'Residential'),
        ProviderRoleOption(slug: 'commercial', name: 'Commercial'),
        ProviderRoleOption(slug: 'infrastructure', name: 'Infrastructure'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'civil_construction_diploma_or_degree',
            name: 'Civil/Construction diploma or degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'registered_with_engineers_contractors_board',
            name: 'Registered with engineers/contractors board',
            isEvidence: false),
        ProviderRoleQualification(
            slug: '5_years_on_site',
            name: '5+ years on site',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'safety_certification_osha',
            name: 'Safety certification (OSHA)',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'construction_building_project_manager',
      name: 'Project Manager',
      description: 'Manage construction timelines and contractors',
      kindQuestion: 'What kind of projects?',
      categorySlug: 'construction_building',
      capabilitySlug: 'work_construction_building_project_manager',
      kinds: [
        ProviderRoleOption(slug: 'residential', name: 'Residential'),
        ProviderRoleOption(slug: 'commercial', name: 'Commercial'),
        ProviderRoleOption(slug: 'roads_civil', name: 'Roads & civil'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'pmp_prince2', name: 'PMP / PRINCE2', isEvidence: false),
        ProviderRoleQualification(
            slug: 'degree', name: 'Degree', isEvidence: false),
        ProviderRoleQualification(
            slug: 'delivered_3_projects',
            name: 'Delivered 3+ projects',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'foreman_supervisor',
      name: 'Foreman / Supervisor',
      description: 'Supervise building trades and daily tasks',
      kindQuestion: 'Which trade?',
      categorySlug: 'construction_building',
      capabilitySlug: 'work_foreman_supervisor',
      kinds: [
        ProviderRoleOption(slug: 'masonry', name: 'Masonry'),
        ProviderRoleOption(slug: 'roofing', name: 'Roofing'),
        ProviderRoleOption(slug: 'concrete', name: 'Concrete'),
        ProviderRoleOption(slug: 'finishing', name: 'Finishing'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'trade_test_certificate',
            name: 'Trade test certificate',
            isEvidence: true),
        ProviderRoleQualification(
            slug: 'managed_10_workers',
            name: 'Managed 10+ workers',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'safety_training',
            name: 'Safety training',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'skilled_tradesperson',
      name: 'Skilled Tradesperson',
      description: 'Carpentry, masonry, plumbing, electrical, welding',
      kindQuestion: 'Which trade?',
      categorySlug: 'construction_building',
      capabilitySlug: 'work_skilled_tradesperson',
      kinds: [
        ProviderRoleOption(slug: 'mason', name: 'Mason'),
        ProviderRoleOption(slug: 'plumber', name: 'Plumber'),
        ProviderRoleOption(slug: 'electrician', name: 'Electrician'),
        ProviderRoleOption(slug: 'carpenter', name: 'Carpenter'),
        ProviderRoleOption(slug: 'welder', name: 'Welder'),
        ProviderRoleOption(slug: 'painter', name: 'Painter'),
        ProviderRoleOption(slug: 'roofer', name: 'Roofer'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'trade_test_grade_i_ii_iii',
            name: 'Trade test (Grade I/II/III)',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'licence_electrical_plumbing',
            name: 'Licence (electrical/plumbing)',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_tools', name: 'Own tools', isEvidence: false),
        ProviderRoleQualification(
            slug: '2_years_experience',
            name: '2+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'surveyor',
      name: 'Surveyor',
      description: 'Land surveying, quantity surveying, and mapping',
      kindQuestion: 'What type?',
      categorySlug: 'construction_building',
      capabilitySlug: 'work_surveyor',
      kinds: [
        ProviderRoleOption(slug: 'land', name: 'Land'),
        ProviderRoleOption(slug: 'quantity', name: 'Quantity'),
        ProviderRoleOption(slug: 'topographic', name: 'Topographic'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'registered_surveyor',
            name: 'Registered surveyor',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'degree_diploma',
            name: 'Degree / diploma',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_instruments',
            name: 'Own instruments',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'solar_electrical_technician',
      name: 'Solar / Electrical Technician',
      description: 'Solar installation, inverters, and battery systems',
      kindQuestion: 'What do you install?',
      categorySlug: 'energy_utilities',
      capabilitySlug: 'work_solar_electrical_technician',
      kinds: [
        ProviderRoleOption(slug: 'solar_pv', name: 'Solar PV'),
        ProviderRoleOption(
            slug: 'batteries_inverters', name: 'Batteries & inverters'),
        ProviderRoleOption(slug: 'generators', name: 'Generators'),
        ProviderRoleOption(slug: 'wiring', name: 'Wiring'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'electrical_licence',
            name: 'Electrical licence',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'solar_installer_certificate',
            name: 'Solar installer certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'safety_training',
            name: 'Safety training',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_tools', name: 'Own tools', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'borehole_water_technician',
      name: 'Borehole / Water Technician',
      description: 'Borehole drilling, pumps, and water systems',
      kindQuestion: 'What do you do?',
      categorySlug: 'energy_utilities',
      capabilitySlug: 'work_borehole_water_technician',
      kinds: [
        ProviderRoleOption(slug: 'drilling', name: 'Drilling'),
        ProviderRoleOption(
            slug: 'pump_installation', name: 'Pump installation'),
        ProviderRoleOption(slug: 'plumbing_tanks', name: 'Plumbing & tanks'),
        ProviderRoleOption(slug: 'water_treatment', name: 'Water treatment'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'water_technician_certificate',
            name: 'Water technician certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'drilling_permit',
            name: 'Drilling permit',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_equipment', name: 'Own equipment', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'energy_engineer',
      name: 'Energy Engineer',
      description: 'Power systems, renewable energy, and grid design',
      kindQuestion: 'Which area?',
      categorySlug: 'energy_utilities',
      capabilitySlug: 'work_energy_engineer',
      kinds: [
        ProviderRoleOption(slug: 'solar_design', name: 'Solar design'),
        ProviderRoleOption(slug: 'energy_audits', name: 'Energy audits'),
        ProviderRoleOption(slug: 'grid_mini_grid', name: 'Grid / mini-grid'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'engineering_degree',
            name: 'Engineering degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'registered_engineer',
            name: 'Registered engineer',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'design_software_skills',
            name: 'Design software skills',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'energy_utilities_project_manager',
      name: 'Project Manager',
      description: 'Manage energy and utility installations',
      kindQuestion: 'What kind of projects?',
      categorySlug: 'energy_utilities',
      capabilitySlug: 'work_energy_utilities_project_manager',
      kinds: [
        ProviderRoleOption(slug: 'solar', name: 'Solar'),
        ProviderRoleOption(slug: 'water', name: 'Water'),
        ProviderRoleOption(slug: 'electrification', name: 'Electrification'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'pmp_prince2', name: 'PMP / PRINCE2', isEvidence: false),
        ProviderRoleQualification(
            slug: 'delivered_3_projects',
            name: 'Delivered 3+ projects',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'driver',
      name: 'Driver',
      description: 'Professional passenger or commercial driving',
      kindQuestion: 'What do you drive?',
      categorySlug: 'transport_logistics',
      capabilitySlug: 'work_driver',
      kinds: [
        ProviderRoleOption(slug: 'truck_heavy', name: 'Truck / heavy'),
        ProviderRoleOption(slug: 'pickup_van', name: 'Pickup / van'),
        ProviderRoleOption(slug: 'bus_minibus', name: 'Bus / minibus'),
        ProviderRoleOption(
            slug: 'motorcycle_courier', name: 'Motorcycle courier'),
        ProviderRoleOption(slug: 'tanker', name: 'Tanker'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'valid_driving_licence_class',
            name: 'Valid driving licence (class)',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'psv_badge', name: 'PSV badge', isEvidence: false),
        ProviderRoleQualification(
            slug: 'clean_driving_record',
            name: 'Clean driving record',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'defensive_driving_certificate',
            name: 'Defensive driving certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_vehicle', name: 'Own vehicle', isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'fleet_operations_manager',
      name: 'Fleet / Operations Manager',
      description: 'Oversee vehicle fleets, drivers, and schedules',
      kindQuestion: 'What fleet?',
      categorySlug: 'transport_logistics',
      capabilitySlug: 'work_fleet_operations_manager',
      kinds: [
        ProviderRoleOption(slug: 'trucks', name: 'Trucks'),
        ProviderRoleOption(slug: 'vans_couriers', name: 'Vans & couriers'),
        ProviderRoleOption(slug: 'mixed', name: 'Mixed'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'logistics_diploma_degree',
            name: 'Logistics diploma / degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'managed_10_vehicles',
            name: 'Managed 10+ vehicles',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'transport_licence',
            name: 'Transport licence',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'dispatcher_coordinator',
      name: 'Dispatcher / Coordinator',
      description: 'Coordinate deliveries, routes, and customs',
      kindQuestion: 'What area?',
      categorySlug: 'transport_logistics',
      capabilitySlug: 'work_dispatcher_coordinator',
      kinds: [
        ProviderRoleOption(slug: 'route_planning', name: 'Route planning'),
        ProviderRoleOption(
            slug: 'customs_clearing', name: 'Customs & clearing'),
        ProviderRoleOption(slug: 'warehouse', name: 'Warehouse'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'logistics_experience',
            name: 'Logistics experience',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'customs_clearing_licence',
            name: 'Customs clearing licence',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'loader_mover',
      name: 'Loader / Mover',
      description: 'Physical loading, offloading, and moving services',
      kindQuestion: 'What work?',
      categorySlug: 'transport_logistics',
      capabilitySlug: 'work_loader_mover',
      kinds: [
        ProviderRoleOption(slug: 'moving', name: 'Moving'),
        ProviderRoleOption(slug: 'warehouse', name: 'Warehouse'),
        ProviderRoleOption(slug: 'loading', name: 'Loading'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'physical_fitness',
            name: 'Physical fitness',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'experience_1_year',
            name: 'Experience 1+ year',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'machine_operator',
      name: 'Machine Operator',
      description: 'Drive or run heavy machines',
      kindQuestion: 'Which machine do you operate?',
      categorySlug: 'machinery_equipment',
      capabilitySlug: 'work_machine_operator',
      kinds: [
        ProviderRoleOption(slug: 'excavator', name: 'Excavator'),
        ProviderRoleOption(slug: 'loader', name: 'Loader'),
        ProviderRoleOption(slug: 'grader', name: 'Grader'),
        ProviderRoleOption(slug: 'crane', name: 'Crane'),
        ProviderRoleOption(slug: 'tractor', name: 'Tractor'),
        ProviderRoleOption(slug: 'roller', name: 'Roller'),
        ProviderRoleOption(slug: 'forklift', name: 'Forklift'),
        ProviderRoleOption(slug: 'bulldozer', name: 'Bulldozer'),
        ProviderRoleOption(
            slug: 'concrete_mixer_pump', name: 'Concrete mixer / pump'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'operator_licence_certificate',
            name: 'Operator licence / certificate',
            isEvidence: true),
        ProviderRoleQualification(
            slug: 'safety_osha_certificate',
            name: 'Safety / OSHA certificate',
            isEvidence: true),
        ProviderRoleQualification(
            slug: '3_years_experience',
            name: '3+ years experience',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'medical_fitness',
            name: 'Medical fitness',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'can_work_away_from_home',
            name: 'Can work away from home',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'equipment_mechanic',
      name: 'Equipment Mechanic',
      description: 'Service and repair plant and generators',
      kindQuestion: 'What do you service?',
      categorySlug: 'machinery_equipment',
      capabilitySlug: 'work_equipment_mechanic',
      kinds: [
        ProviderRoleOption(slug: 'heavy_plant', name: 'Heavy plant'),
        ProviderRoleOption(slug: 'generators', name: 'Generators'),
        ProviderRoleOption(slug: 'hydraulics', name: 'Hydraulics'),
        ProviderRoleOption(
            slug: 'electrical_systems', name: 'Electrical systems'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'mechanic_trade_certificate',
            name: 'Mechanic trade certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'own_tools', name: 'Own tools', isEvidence: false),
        ProviderRoleQualification(
            slug: 'field_repair_experience',
            name: 'Field repair experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'fleet_equipment_manager',
      name: 'Fleet / Equipment Manager',
      description: 'Run a fleet of machines and crews',
      kindQuestion: 'What fleet?',
      categorySlug: 'machinery_equipment',
      capabilitySlug: 'work_fleet_equipment_manager',
      kinds: [
        ProviderRoleOption(
            slug: 'construction_plant', name: 'Construction plant'),
        ProviderRoleOption(slug: 'farm_machinery', name: 'Farm machinery'),
        ProviderRoleOption(
            slug: 'industrial_equipment', name: 'Industrial equipment'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'managed_fleet_of_5_machines',
            name: 'Managed fleet of 5+ machines',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'diploma_degree',
            name: 'Diploma / degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'maintenance_scheduling',
            name: 'Maintenance scheduling',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'site_supervisor',
      name: 'Site Supervisor',
      description: 'Lead machine work on a site',
      kindQuestion: 'Which sites?',
      categorySlug: 'machinery_equipment',
      capabilitySlug: 'work_site_supervisor',
      kinds: [
        ProviderRoleOption(slug: 'earthworks', name: 'Earthworks'),
        ProviderRoleOption(slug: 'quarry_mining', name: 'Quarry / mining'),
        ProviderRoleOption(slug: 'farm', name: 'Farm'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'plant_experience',
            name: 'Plant experience',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'team_leadership',
            name: 'Team leadership',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'safety_certification',
            name: 'Safety certification',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'farm_manager',
      name: 'Farm Manager',
      description: 'Crop and livestock production management',
      kindQuestion: 'What farm?',
      categorySlug: 'agriculture_agribusiness',
      capabilitySlug: 'work_farm_manager',
      kinds: [
        ProviderRoleOption(slug: 'crops', name: 'Crops'),
        ProviderRoleOption(slug: 'dairy', name: 'Dairy'),
        ProviderRoleOption(slug: 'poultry', name: 'Poultry'),
        ProviderRoleOption(slug: 'mixed', name: 'Mixed'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'agriculture_diploma_degree',
            name: 'Agriculture diploma / degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'managed_5_workers',
            name: 'Managed 5+ workers',
            isEvidence: false),
        ProviderRoleQualification(
            slug: '5_years_farming_experience',
            name: '5+ years farming experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'agronomist_extension_officer',
      name: 'Agronomist / Extension Officer',
      description: 'Crop advisory, soil health, and farm visits',
      kindQuestion: 'What focus?',
      categorySlug: 'agriculture_agribusiness',
      capabilitySlug: 'work_agronomist_extension_officer',
      kinds: [
        ProviderRoleOption(slug: 'crops', name: 'Crops'),
        ProviderRoleOption(slug: 'soil_irrigation', name: 'Soil & irrigation'),
        ProviderRoleOption(slug: 'pest_management', name: 'Pest management'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'degree_diploma_in_agronomy',
            name: 'Degree / diploma in agronomy',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'field_experience',
            name: 'Field experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'veterinary_livestock_officer',
      name: 'Veterinary / Livestock Officer',
      description: 'Animal health, treatment, and breeding advisory',
      kindQuestion: 'What animals?',
      categorySlug: 'agriculture_agribusiness',
      capabilitySlug: 'work_veterinary_livestock_officer',
      kinds: [
        ProviderRoleOption(slug: 'cattle', name: 'Cattle'),
        ProviderRoleOption(slug: 'poultry', name: 'Poultry'),
        ProviderRoleOption(slug: 'small_ruminants', name: 'Small ruminants'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'veterinary_licence',
            name: 'Veterinary licence',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'diploma_degree',
            name: 'Diploma / degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'vaccination_certification',
            name: 'Vaccination certification',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'farm_worker_operator',
      name: 'Farm Worker / Operator',
      description: 'Day-to-day farm labour and equipment operation',
      kindQuestion: 'What work?',
      categorySlug: 'agriculture_agribusiness',
      capabilitySlug: 'work_farm_worker_operator',
      kinds: [
        ProviderRoleOption(
            slug: 'tractor_operation', name: 'Tractor operation'),
        ProviderRoleOption(slug: 'irrigation', name: 'Irrigation'),
        ProviderRoleOption(slug: 'harvesting', name: 'Harvesting'),
        ProviderRoleOption(slug: 'spraying', name: 'Spraying'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'tractor_licence',
            name: 'Tractor licence',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'pesticide_handling_certificate',
            name: 'Pesticide handling certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'experience_1_year',
            name: 'Experience 1+ year',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'procurement_officer_manager',
      name: 'Procurement Officer / Manager',
      description: 'Sourcing, purchasing, and vendor contracts',
      kindQuestion: 'What do you buy?',
      categorySlug: 'specialized_products',
      capabilitySlug: 'work_procurement_officer_manager',
      kinds: [
        ProviderRoleOption(slug: 'industrial', name: 'Industrial'),
        ProviderRoleOption(slug: 'electronics', name: 'Electronics'),
        ProviderRoleOption(slug: 'medical_lab', name: 'Medical & lab'),
        ProviderRoleOption(slug: 'general_supplies', name: 'General supplies'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'procurement_diploma_cips_or_similar',
            name: 'Procurement diploma (CIPS or similar)',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'supplier_network',
            name: 'Supplier network',
            isEvidence: false),
        ProviderRoleQualification(
            slug: '3_years_experience',
            name: '3+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'sourcing_agent',
      name: 'Sourcing Agent',
      description: 'Product finding, supplier vetting, and quality check',
      kindQuestion: 'Where do you source?',
      categorySlug: 'specialized_products',
      capabilitySlug: 'work_sourcing_agent',
      kinds: [
        ProviderRoleOption(slug: 'local', name: 'Local'),
        ProviderRoleOption(slug: 'china', name: 'China'),
        ProviderRoleOption(slug: 'dubai', name: 'Dubai'),
        ProviderRoleOption(slug: 'india', name: 'India'),
        ProviderRoleOption(slug: 'europe_usa', name: 'Europe / USA'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'import_export_experience',
            name: 'Import/export experience',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'language_skills',
            name: 'Language skills',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'supplier_contacts',
            name: 'Supplier contacts',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'clearing_customs_agent',
      name: 'Clearing & Customs Agent',
      description: 'Customs clearance, port documentation, and import duties',
      kindQuestion: 'What do you handle?',
      categorySlug: 'specialized_products',
      capabilitySlug: 'work_clearing_customs_agent',
      kinds: [
        ProviderRoleOption(slug: 'imports', name: 'Imports'),
        ProviderRoleOption(slug: 'exports', name: 'Exports'),
        ProviderRoleOption(
            slug: 'freight_forwarding', name: 'Freight forwarding'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'customs_clearing_licence',
            name: 'Customs clearing licence',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'logistics_experience',
            name: 'Logistics experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'travel_agent_consultant',
      name: 'Travel Agent / Consultant',
      description: 'Flights, itineraries, and visa guidance',
      kindQuestion: 'What do you handle?',
      categorySlug: 'travel_international',
      capabilitySlug: 'work_travel_agent_consultant',
      kinds: [
        ProviderRoleOption(slug: 'flights', name: 'Flights'),
        ProviderRoleOption(slug: 'tours_packages', name: 'Tours & packages'),
        ProviderRoleOption(slug: 'visas', name: 'Visas'),
        ProviderRoleOption(slug: 'hajj_umrah', name: 'Hajj & Umrah'),
        ProviderRoleOption(slug: 'relocation', name: 'Relocation'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'iata_certification',
            name: 'IATA certification',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'travel_agency_licence',
            name: 'Travel agency licence',
            isEvidence: false),
        ProviderRoleQualification(
            slug: '2_years_experience',
            name: '2+ years experience',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'tour_guide',
      name: 'Tour Guide',
      description: 'Lead tours, safaris, and cultural excursions',
      kindQuestion: 'What tours?',
      categorySlug: 'travel_international',
      capabilitySlug: 'work_tour_guide',
      kinds: [
        ProviderRoleOption(slug: 'wildlife_safari', name: 'Wildlife safari'),
        ProviderRoleOption(slug: 'cultural', name: 'Cultural'),
        ProviderRoleOption(slug: 'city_tours', name: 'City tours'),
        ProviderRoleOption(slug: 'adventure', name: 'Adventure'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'tourism_board_guide_licence',
            name: 'Tourism board guide licence',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'first_aid_certificate',
            name: 'First aid certificate',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'languages_spoken',
            name: 'Languages spoken',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'driver_guide',
      name: 'Driver-Guide',
      description: 'Safari driver-guide with passenger vehicle',
      kindQuestion: 'What vehicle?',
      categorySlug: 'travel_international',
      capabilitySlug: 'work_driver_guide',
      kinds: [
        ProviderRoleOption(slug: 'safari_vehicle', name: 'Safari vehicle'),
        ProviderRoleOption(slug: 'minibus', name: 'Minibus'),
        ProviderRoleOption(
            slug: 'airport_transfers', name: 'Airport transfers'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'valid_driving_licence_class',
            name: 'Valid driving licence (class)',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'tourism_licence',
            name: 'Tourism licence',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'clean_driving_record',
            name: 'Clean driving record',
            isEvidence: false),
      ],
    ),
    ProviderServiceRole(
      slug: 'operations_manager',
      name: 'Operations Manager',
      description: 'Tour operations, bookings, and fleet logistics',
      kindQuestion: 'What scope?',
      categorySlug: 'travel_international',
      capabilitySlug: 'work_operations_manager',
      kinds: [
        ProviderRoleOption(slug: 'tours', name: 'Tours'),
        ProviderRoleOption(
            slug: 'visa_documentation', name: 'Visa & documentation'),
        ProviderRoleOption(slug: 'travel_desk', name: 'Travel desk'),
      ],
      qualifications: [
        ProviderRoleQualification(
            slug: 'tourism_diploma_degree',
            name: 'Tourism diploma / degree',
            isEvidence: false),
        ProviderRoleQualification(
            slug: 'managed_3_staff',
            name: 'Managed 3+ staff',
            isEvidence: false),
      ],
    ),
  ];
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
