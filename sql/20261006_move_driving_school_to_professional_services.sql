-- =============================================================================
-- Standalone SQL Patch: 20261006_move_driving_school_to_professional_services.sql
-- Move "Driving School / Driver Training" from Transport & Logistics (transport_logistics)
-- to Professional Services (professional_services).
-- =============================================================================

begin;

-- 1. Update the need_capabilities catalog entry
update public.need_capabilities
set category_slug = 'professional_services'
where slug = 'driving_school';

-- Ensure the row exists with category_slug = 'professional_services'
insert into public.need_capabilities
  (slug, category_slug, name, is_active, country_labels)
values (
  'driving_school',
  'professional_services',
  'Driving School / Driver Training',
  true,
  '{
    "UG": {"name": "Driving School / Driver Training"},
    "KE": {"name": "Driving School & Driver Training"},
    "TZ": {"name": "Mafunzo ya Udereva / Chuo cha Udereva"},
    "RW": {"name": "Amashuri yo Gutwara Ibinyabiziga"},
    "SS": {"name": "Driving School / Driver Training"},
    "BI": {"name": "Auto-École / Formation des Conducteurs"}
  }'::jsonb
)
on conflict (slug) do update set
  category_slug = 'professional_services',
  name = excluded.name,
  is_active = excluded.is_active,
  country_labels = excluded.country_labels;

-- 2. Update existing needs_requests that were filed with capability_slug = 'driving_school'
update public.needs_requests
set category_slug = 'professional_services',
    category = coalesce(
      (select name from public.need_categories where slug = 'professional_services'),
      'Professional Services'
    )
where capability_slug = 'driving_school'
  and category_slug = 'transport_logistics';

commit;