-- Mark high-risk individual work roles with one required credential.
-- Apply after provider work-profile, profile-documents, verification-policy,
-- and provider-type verification-matrix patches. Safe to rerun.
begin;

-- Keep this temp mapping for the session so SQL editors that commit between
-- selected statements do not drop it before the updates below use it.
create temporary table if not exists required_role_proofs (
  role_slug text primary key,
  qualification_slug text not null,
  capability_slug text not null
);
truncate table required_role_proofs;

alter table public.role_qualifications
  add column if not exists is_required_proof boolean not null default false;

-- Visa work was previously mixed into general travel and operations roles.
-- Give it a dedicated work role so its credential gate does not apply to
-- ordinary travel bookings or tour operations.
insert into public.need_capabilities (
  slug, category_slug, name, is_active, ui_group_slug, sort_order,
  service_group_slug, service_group_name, service_sort_order,
  capability_type, verification_policy
)
values (
  'work_visa_assistance_specialist', 'travel_international',
  'Visa Assistance Specialist', true, 'travel_international', 50,
  'work_roles', 'Work Roles', 50, 'work', 'required_proof'
)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = true,
  ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  capability_type = excluded.capability_type,
  verification_policy = excluded.verification_policy;

insert into public.capability_roles (
  slug, category_slug, capability_slug, name, kind_question, is_active
)
values (
  'visa_assistance_specialist', 'travel_international',
  'work_visa_assistance_specialist', 'Visa Assistance Specialist',
  'What visa support do you provide?', true
)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = true;

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('visa_assistance_specialist', 'visa_applications', 'Visa applications', 10),
  ('visa_assistance_specialist', 'document_review', 'Document review', 20),
  ('visa_assistance_specialist', 'appointment_support', 'Appointment support', 30)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

delete from public.role_kinds
where (role_slug = 'travel_agent_consultant' and slug = 'visas')
   or (role_slug = 'operations_manager' and slug = 'visa_documentation')
   or (role_slug = 'architect_designer' and slug in ('interiors', 'landscape'))
   or (role_slug = 'teacher_tutor' and slug in ('languages', 'exam_prep'))
   or (role_slug = 'trainer_instructor' and
       slug in ('vocational_technical', 'driving'));

update public.need_capabilities
set name = 'Architect'
where slug = 'work_architect_designer';
update public.capability_roles
set name = 'Architect'
where slug = 'architect_designer';
update public.need_capabilities
set name = 'Teacher'
where slug = 'work_teacher_tutor';
update public.capability_roles
set name = 'Teacher'
where slug = 'teacher_tutor';

-- Separate design work and informal tutoring from regulated professions.
insert into public.need_capabilities (
  slug, category_slug, name, is_active, ui_group_slug, sort_order,
  service_group_slug, service_group_name, service_sort_order,
  capability_type, verification_policy
)
values
  ('work_interior_designer', 'professional_services', 'Interior Designer',
   true, 'business_professional_services', 45, 'work_roles', 'Work Roles',
   45, 'work', 'open'),
  ('work_landscape_designer', 'professional_services', 'Landscape Designer',
   true, 'business_professional_services', 46, 'work_roles', 'Work Roles',
   46, 'work', 'open'),
  ('work_private_tutor', 'education_training', 'Private Tutor / Exam Coach',
   true, 'education_training', 15, 'work_roles', 'Work Roles',
   15, 'work', 'open'),
  ('work_vocational_trainer', 'education_training',
   'Vocational / Technical Trainer', true, 'education_training', 25,
   'work_roles', 'Work Roles', 25, 'work', 'required_proof')
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = true,
  ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  capability_type = excluded.capability_type,
  verification_policy = excluded.verification_policy;

insert into public.capability_roles (
  slug, category_slug, capability_slug, name, kind_question, is_active
)
values
  ('interior_designer', 'professional_services', 'work_interior_designer',
   'Interior Designer', 'What do you design?', true),
  ('landscape_designer', 'professional_services', 'work_landscape_designer',
   'Landscape Designer', 'What do you design?', true),
  ('private_tutor', 'education_training', 'work_private_tutor',
   'Private Tutor / Exam Coach', 'What do you teach?', true),
  ('vocational_trainer', 'education_training', 'work_vocational_trainer',
   'Vocational / Technical Trainer', 'What trade do you teach?', true)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = true;

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('private_tutor', 'languages', 'Languages', 10),
  ('private_tutor', 'exam_prep', 'Exam prep', 20),
  ('vocational_trainer', 'vocational_technical', 'Trades', 10)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

insert into public.role_qualifications (
  role_slug, slug, name, is_evidence, is_required_proof, sort_order
)
values
  ('interior_designer', 'portfolio', 'Portfolio', false, false, 10),
  ('landscape_designer', 'portfolio', 'Portfolio', false, false, 10),
  ('private_tutor', 'subject_specialisation', 'Subject specialisation',
   false, false, 10),
  ('vocational_trainer', 'trade_certificate', 'Trade certificate',
   true, true, 10)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  is_evidence = excluded.is_evidence,
  is_required_proof = excluded.is_required_proof,
  sort_order = excluded.sort_order;

insert into public.role_qualifications (
  role_slug, slug, name, is_evidence, is_required_proof, sort_order
)
values (
  'visa_assistance_specialist', 'travel_agency_licence',
  'Travel agency or visa agent authorisation', true, true, 10
)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  is_evidence = true,
  is_required_proof = true,
  sort_order = excluded.sort_order;

insert into required_role_proofs (role_slug, qualification_slug, capability_slug)
values
  ('security_specialist', 'cissp_cism', 'work_security_specialist'),
  ('accountant_finance_officer', 'practising_certificate', 'work_accountant_finance_officer'),
  ('lawyer_legal_officer', 'bar_admission_practising_certificate', 'work_lawyer_legal_officer'),
  ('engineer', 'registered_with_engineers_board', 'work_engineer'),
  ('architect_designer', 'registered_architect', 'work_architect_designer'),
  ('teacher_tutor', 'registered_with_teaching_board', 'work_teacher_tutor'),
  ('vocational_trainer', 'trade_certificate', 'work_vocational_trainer'),
  ('site_manager', 'safety_certification_osha', 'work_site_manager'),
  ('foreman_supervisor', 'trade_test_certificate', 'work_foreman_supervisor'),
  ('skilled_tradesperson', 'trade_test_grade_i_ii_iii', 'work_skilled_tradesperson'),
  ('surveyor', 'registered_surveyor', 'work_surveyor'),
  ('solar_electrical_technician', 'electrical_licence', 'work_solar_electrical_technician'),
  ('energy_engineer', 'registered_engineer', 'work_energy_engineer'),
  ('driver', 'valid_driving_licence_class', 'work_driver'),
  ('driving_instructor', 'instructor_licence', 'work_driving_instructor'),
  ('machine_operator', 'operator_licence_certificate', 'work_machine_operator'),
  ('equipment_mechanic', 'mechanic_trade_certificate', 'work_equipment_mechanic'),
  ('site_supervisor', 'safety_certification', 'work_site_supervisor'),
  ('veterinary_livestock_officer', 'veterinary_licence', 'work_veterinary_livestock_officer'),
  ('clearing_customs_agent', 'customs_clearing_licence', 'work_clearing_customs_agent'),
  ('visa_assistance_specialist', 'travel_agency_licence', 'work_visa_assistance_specialist'),
  ('tour_guide', 'tourism_board_guide_licence', 'work_tour_guide'),
  ('driver_guide', 'valid_driving_licence_class', 'work_driver_guide'),
  ('house_help', 'national_id', 'work_house_help'),
  ('nanny', 'police_clearance', 'work_nanny'),
  ('home_carer', 'caregiving_certificate', 'work_home_carer'),
  ('home_cook', 'food_handler_certificate', 'work_home_cook'),
  ('doctor', 'council_registration', 'work_doctor'),
  ('nurse', 'council_registration', 'work_nurse'),
  ('clinician', 'practising_licence', 'work_clinician'),
  ('medical_specialist', 'specialist_registration', 'work_medical_specialist'),
  ('optometrist', 'optometry_registration', 'work_optometrist'),
  ('dentist', 'dental_council_registration', 'work_dentist'),
  ('pharmacist', 'pharmacy_board_registration', 'work_pharmacist'),
  ('lab_technician', 'lab_council_registration', 'work_lab_technician'),
  ('physiotherapist', 'physiotherapy_registration', 'work_physiotherapist'),
  ('counsellor', 'professional_registration', 'work_counsellor'),
  ('nursing_assistant', 'assistant_certificate', 'work_nursing_assistant'),
  ('hiv_counsellor', 'facility_authorisation', 'work_hiv_counsellor'),
  ('caterer_chef', 'food_handler_certificate', 'work_caterer_chef'),
  ('massage_therapist', 'massage_therapy_certificate', 'work_massage_therapist'),
  ('spa_therapist', 'cosmetology_spa_certificate', 'work_spa_therapist'),
  ('traditional_healer', 'association_registration', 'work_traditional_healer'),
  ('duwah_practitioner', 'endorsement', 'work_duwah_practitioner'),
  ('ceremony_officiant', 'endorsement', 'work_ceremony_officiant'),
  ('angel_investor', 'identity_verification', 'work_angel_investor');

do $$
begin
  if exists (
    select 1
    from required_role_proofs required
    left join public.role_qualifications qualification
      on qualification.role_slug = required.role_slug
     and qualification.slug = required.qualification_slug
    left join public.need_capabilities capability
      on capability.slug = required.capability_slug
     and capability.capability_type = 'work'
    where qualification.slug is null or capability.slug is null
  ) then
    raise exception 'A required work-role proof mapping is missing from the provider catalogs.';
  end if;
end;
$$;

update public.role_qualifications qualification
set is_evidence = true, is_required_proof = true
from required_role_proofs required
where qualification.role_slug = required.role_slug
  and qualification.slug = required.qualification_slug;

update public.need_capabilities capability
set verification_policy = 'required_proof'
from required_role_proofs required
where capability.slug = required.capability_slug;

insert into public.verification_requirements (
  scope_type, scope_id, provider_type, identity_required, phone_required,
  provider_verification_required, evidence_requirements, required_evidence,
  is_active
)
select
  'capability', required.capability_slug, 'individual', false, false, true,
  jsonb_build_array(required.qualification_slug),
  array[required.qualification_slug]::text[], true
from required_role_proofs required
on conflict (scope_type, scope_id, provider_type) do update set
  provider_verification_required = excluded.provider_verification_required,
  evidence_requirements = excluded.evidence_requirements,
  required_evidence = excluded.required_evidence,
  is_active = true,
  updated_at = now();

-- Existing declarations remain saved, but high-risk roles stay off offers
-- until their required credential has been reviewed and approved.
update public.provider_capabilities capability
set is_active = false, updated_at = now()
from required_role_proofs required
where capability.capability_slug = required.capability_slug
  and capability.verification_level <> 'provider_verified'
  and not exists (
    select 1 from public.provider_capability_evidence evidence
    where evidence.provider_capability_id = capability.id
      and evidence.requirement_key = required.qualification_slug
      and evidence.status = 'approved'
      and (evidence.expires_at is null or evidence.expires_at > now())
  )
  and not exists (
    select 1 from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = capability.id
      and claim.role_slug = required.role_slug
      and claim.qualification_slug = required.qualification_slug
      and claim.is_claimed and claim.status = 'verified'
      and (claim.expires_at is null or claim.expires_at > now())
  );

commit;
notify pgrst, 'reload schema';
