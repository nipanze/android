-- =============================================================================
-- Patch: Provider verification requirements for all Provider Services categories
-- Created: 2026-10-04
-- Purpose:
--   1. Add provider_verification_required to need_categories when missing.
--   2. Mark every existing Need category as eligible for provider verification.
--   3. Seed/update central verification_requirements so need_offer checks can
--      require provider_verified capabilities across all Provider Services
--      categories, not just Travel & International.
-- Safe to re-run: yes.
-- =============================================================================

alter table public.need_categories
  add column if not exists provider_verification_required boolean not null default true;

update public.need_categories
set provider_verification_required = true;

insert into public.verification_requirements (
  scope_type,
  scope_id,
  identity_required,
  phone_required,
  provider_verification_required,
  evidence_requirements,
  is_active
)
select
  'category',
  category.slug,
  true,
  false,
  true,
  case category.slug
    when 'travel_international' then
      '["Travel Agency License / Registration", "Tax Compliance Certificate"]'::jsonb
    when 'machinery_equipment' then
      '["Equipment ownership or hire agreement", "Equipment photos / fleet list", "Operator certification where applicable"]'::jsonb
    when 'professional_services' then
      '["Professional license / registration", "Portfolio or work references", "Business registration where applicable"]'::jsonb
    when 'transport_logistics' then
      '["Vehicle or fleet documents", "Driving / operating license", "Insurance or transport permit where applicable"]'::jsonb
    when 'specialized_products' then
      '["Supplier or business registration", "Product catalog / invoices", "Compliance certificate where applicable"]'::jsonb
    when 'education_training' then
      '["Academic or training credentials", "Institution / tutor registration where applicable", "Portfolio or references"]'::jsonb
    when 'music_video' then
      '["Portfolio or showreel", "Professional references", "Equipment / studio proof where applicable"]'::jsonb
    when 'weddings_celebrations' then
      '["Portfolio or event references", "Business registration where applicable", "Venue / supplier proof where applicable"]'::jsonb
    when 'construction_building' then
      '["Contractor registration or trade license", "Portfolio / site references", "Safety or engineering certification where applicable"]'::jsonb
    when 'agriculture_agribusiness' then
      '["Farm or business registration", "Product / equipment proof", "Relevant permits where applicable"]'::jsonb
    when 'technology_digital' then
      '["Portfolio or project references", "Business registration where applicable", "Technical certification where applicable"]'::jsonb
    when 'events_production' then
      '["Portfolio or event references", "Equipment proof", "Business registration where applicable"]'::jsonb
    when 'energy_utilities' then
      '["Technical license or certification", "Product / installation references", "Safety compliance where applicable"]'::jsonb
    else
      '["Business registration or professional proof", "Portfolio or references"]'::jsonb
  end,
  true
from public.need_categories category
on conflict (scope_type, scope_id) do update set
  identity_required = excluded.identity_required,
  phone_required = excluded.phone_required,
  provider_verification_required = excluded.provider_verification_required,
  evidence_requirements = excluded.evidence_requirements,
  is_active = excluded.is_active,
  updated_at = now();

-- Verification check: should return zero rows after this patch.
select category.slug as missing_provider_verification_requirement
from public.need_categories category
left join public.verification_requirements requirement
  on requirement.scope_type = 'category'
 and requirement.scope_id = category.slug
 and requirement.is_active = true
 and requirement.provider_verification_required = true
where coalesce(category.provider_verification_required, false) is not true
   or requirement.id is null;
