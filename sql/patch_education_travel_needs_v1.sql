-- =============================================================================
-- Standalone SQL Patch: patch_education_travel_needs_v1.sql
-- Created: 2026-10-03
-- Purpose: Add the Education & Training and Travel & International Need
--          categories plus the corresponding capability rows.
-- Safe to re-run: inserts use ON CONFLICT DO UPDATE.
-- =============================================================================

-- 1) Add/update the new Need categories
insert into public.need_categories (slug, name, icon, sort_order, description, is_active)
values
  (
    'education_training',
    'Education & Training',
    '🎓',
    6,
    'Education, internships, professional training, admissions, academic support, and skills development.',
    true
  ),
  (
    'travel_international',
    'Travel & International',
    '✈️',
    10,
    'Travel, visa assistance, flights, accommodation, Hajj & Umrah, study abroad, and international relocation services.',
    true
  )
on conflict (slug) do update
set
  name = excluded.name,
  icon = excluded.icon,
  sort_order = excluded.sort_order,
  description = excluded.description,
  is_active = excluded.is_active;

-- 2) Add/update Education & Training capability rows
insert into public.need_capabilities (slug, category_slug, name, is_active)
values
  ('internship_placement', 'education_training', 'Internship Placement', true),
  ('private_tutoring', 'education_training', 'Private Tutoring', true),
  ('online_classes', 'education_training', 'Online Classes', true),
  ('professional_training', 'education_training', 'Professional Training', true),
  ('vocational_training', 'education_training', 'Vocational Training', true),
  ('university_admissions', 'education_training', 'University Admissions', true),
  ('study_abroad_guidance', 'education_training', 'Study Abroad Guidance', true),
  ('academic_consulting', 'education_training', 'Academic Consulting', true),
  ('exam_preparation', 'education_training', 'Exam Preparation', true),
  ('language_training', 'education_training', 'Language Training', true),
  ('computer_training', 'education_training', 'Computer Training', true),

  ('it_internships', 'education_training', 'IT Internships', true),
  ('software_development_internships', 'education_training', 'Software Development Internships', true),
  ('it_support_internships', 'education_training', 'IT Support Internships', true),
  ('accounting_internships', 'education_training', 'Accounting Internships', true),
  ('engineering_internships', 'education_training', 'Engineering Internships', true),
  ('marketing_internships', 'education_training', 'Marketing Internships', true),
  ('business_internships', 'education_training', 'Business Internships', true),
  ('health_nursing_placements', 'education_training', 'Health/Nursing Placements', true),
  ('hospitality_internships', 'education_training', 'Hospitality Internships', true),
  ('administrative_internships', 'education_training', 'Administrative Internships', true)
on conflict (slug) do update
set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = excluded.is_active;

-- 3) Add/update Travel & International capability rows
insert into public.need_capabilities (slug, category_slug, name, is_active)
values
  ('visa_assistance', 'travel_international', 'Visa Assistance', true),
  ('flight_tickets', 'travel_international', 'Flight Tickets & Bookings', true),
  ('travel_agency_services', 'travel_international', 'Travel Agency Services', true),
  ('hajj_umrah', 'travel_international', 'Hajj & Umrah', true),
  ('hotel_accommodation', 'travel_international', 'Hotel & Accommodation', true),
  ('airport_transfers', 'travel_international', 'Airport Transfers', true),
  ('travel_insurance', 'travel_international', 'Travel Insurance', true),
  ('tour_packages', 'travel_international', 'Tour Packages', true),
  ('study_abroad', 'travel_international', 'Study Abroad', true),
  ('international_relocation', 'travel_international', 'International Relocation', true)
on conflict (slug) do update
set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = excluded.is_active;

-- 4) Optional: High-trust verification requirements for travel-related items
insert into public.verification_requirements (
  scope_type,
  scope_id,
  identity_required,
  phone_required,
  provider_verification_required,
  evidence_requirements,
  is_active
)
values
  (
    'category',
    'travel_international',
    true,
    false,
    true,
    '["Travel Agency License / Registration", "Tax Compliance Certificate"]'::jsonb,
    true
  ),
  (
    'capability',
    'visa_assistance',
    true,
    false,
    true,
    '["Licensed Travel Agent / Consular Accreditation"]'::jsonb,
    true
  )
on conflict (scope_type, scope_id) do update
set
  identity_required = excluded.identity_required,
  phone_required = excluded.phone_required,
  provider_verification_required = excluded.provider_verification_required,
  evidence_requirements = excluded.evidence_requirements,
  is_active = excluded.is_active;
