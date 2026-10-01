-- =============================================================================
-- Standalone SQL Patch: patch_needs_categories_v2.sql
-- Created: 2026-10-01
-- Purpose: Expand Needs category system from 5 to 10 categories with
--          full starter capabilities (~75 entries) across all categories.
--          Also adds description column to need_categories and sort_order
--          correction so categories appear in the intended display order.
-- Safe to re-run: all inserts use ON CONFLICT DO UPDATE
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Add optional description column to need_categories (idempotent)
-- ---------------------------------------------------------------------------
alter table public.need_categories
  add column if not exists description text;

-- ---------------------------------------------------------------------------
-- 2. Upsert all 10 main categories
--    Sort order follows the spec. is_active flags reflect phased launch:
--    Phase 1 (immediate): machinery, professional, transport, specialized
--    Phase 2 (soon):      construction, agriculture, technology, events, energy
--    High-trust (later):  travel_international
-- ---------------------------------------------------------------------------
insert into public.need_categories (slug, name, icon, sort_order, description, is_active)
values
  ('machinery_equipment',       'Machinery & Equipment',                 '🚜', 1,
   'Hire or source heavy machinery, industrial equipment, and generators.',
   true),
  ('professional_services',     'Professional & Business Services',      '🧑‍💼', 2,
   'Find lawyers, accountants, consultants, engineers, and business professionals.',
   true),
  ('transport_logistics',       'Transport & Logistics',                 '🚚', 3,
   'Heavy haulage, cargo, courier, moving, and bulk delivery services.',
   true),
  ('specialized_products',      'Specialized Products & Procurement',    '🔎', 4,
   'Bulk procurement, imported goods, industrial parts, and hard-to-find items.',
   true),
  ('construction_building',     'Construction & Building',               '🏗️', 5,
   'Contractors, materials, roofing, plumbing, electrical, and civil works.',
   false),
  ('agriculture_agribusiness',  'Agriculture & Agribusiness',            '🌾', 6,
   'Farm machinery, seeds, livestock, irrigation, and produce buyers.',
   false),
  ('technology_digital',        'Technology & Digital',                  '💻', 7,
   'Software, websites, mobile apps, IT support, networking, and digital marketing.',
   false),
  ('events_production',         'Events & Production',                   '🎉', 8,
   'Event planning, tents, sound, lighting, photography, catering, and MCs.',
   false),
  ('energy_utilities',          'Energy & Utilities',                    '⚡', 9,
   'Solar systems, generators, batteries, electrical installation, and water systems.',
   false),
  ('travel_international',      'Travel & International',                '✈️', 10,
   'Visa assistance, flight tickets, Hajj/Umrah, travel packages, and airport transfers.',
   false)
on conflict (slug) do update set
  name        = excluded.name,
  icon        = excluded.icon,
  sort_order  = excluded.sort_order,
  description = excluded.description,
  is_active   = excluded.is_active;

-- ---------------------------------------------------------------------------
-- 3. Upsert full starter capabilities for all 10 categories
-- ---------------------------------------------------------------------------
insert into public.need_capabilities (slug, category_slug, name, is_active)
values
  -- ── Machinery & Equipment ─────────────────────────────────────────────
  ('excavator_hire',            'machinery_equipment',       'Excavator Hire',          true),
  ('tractor_hire',              'machinery_equipment',       'Tractor Hire',             true),
  ('crane_hire',                'machinery_equipment',       'Crane Hire',               true),
  ('loader_hire',               'machinery_equipment',       'Loader Hire',              true),
  ('grader_hire',               'machinery_equipment',       'Grader Hire',              true),
  ('generator_hire',            'machinery_equipment',       'Generator Hire',           true),
  ('agricultural_equipment',    'machinery_equipment',       'Agricultural Equipment',   true),
  ('industrial_equipment',      'machinery_equipment',       'Industrial Equipment',     true),
  ('other_machinery',           'machinery_equipment',       'Other Machinery',          true),

  -- ── Professional & Business Services ─────────────────────────────────
  ('company_registration',      'professional_services',     'Company Registration',     true),
  ('legal_services',            'professional_services',     'Legal Services',           true),
  ('accounting_tax',            'professional_services',     'Accounting & Tax',         true),
  ('business_consulting',       'professional_services',     'Business Consulting',      true),
  ('hr_services',               'professional_services',     'HR Services',              true),
  ('marketing_services',        'professional_services',     'Marketing',                true),
  ('engineering_consulting',    'professional_services',     'Engineering',              true),
  ('architecture_services',     'professional_services',     'Architecture',             true),
  ('other_professional',        'professional_services',     'Other Professional Services', true),

  -- ── Transport & Logistics ─────────────────────────────────────────────
  ('heavy_haulage',             'transport_logistics',       'Heavy Haulage',            true),
  ('truck_hire',                'transport_logistics',       'Truck Hire',               true),
  ('cargo_transport',           'transport_logistics',       'Cargo Transport',          true),
  ('courier_delivery',          'transport_logistics',       'Courier',                  true),
  ('moving_services',           'transport_logistics',       'Moving Services',          true),
  ('vehicle_transport',         'transport_logistics',       'Vehicle Transport',        true),
  ('bulk_delivery',             'transport_logistics',       'Bulk Delivery',            true),
  ('other_logistics',           'transport_logistics',       'Other Logistics',          true),

  -- ── Specialized Products & Procurement ───────────────────────────────
  ('bulk_procurement',          'specialized_products',      'Bulk Procurement',         true),
  ('imported_products',         'specialized_products',      'Imported Products',        true),
  ('industrial_parts',          'specialized_products',      'Industrial Parts',         true),
  ('spare_parts',               'specialized_products',      'Spare Parts',              true),
  ('electronics_procurement',   'specialized_products',      'Electronics Procurement',  true),
  ('hard_to_find_products',     'specialized_products',      'Hard-to-Find Products',    true),
  ('equipment_sourcing',        'specialized_products',      'Equipment Sourcing',       true),
  ('other_procurement',         'specialized_products',      'Other Procurement',        true),

  -- ── Construction & Building ───────────────────────────────────────────
  ('building_contractors',      'construction_building',     'Building Contractors',     true),
  ('construction_materials',    'construction_building',     'Construction Materials',   true),
  ('roofing_services',          'construction_building',     'Roofing',                  true),
  ('plumbing_services',         'construction_building',     'Plumbing',                 true),
  ('electrical_works',          'construction_building',     'Electrical Works',         true),
  ('concrete_works',            'construction_building',     'Concrete',                 true),
  ('surveying_services',        'construction_building',     'Surveying',                true),
  ('excavation_works',          'construction_building',     'Excavation',               true),
  ('other_construction',        'construction_building',     'Other Construction',       true),

  -- ── Agriculture & Agribusiness ────────────────────────────────────────
  ('farm_machinery',            'agriculture_agribusiness',  'Farm Machinery',           true),
  ('seeds_inputs',              'agriculture_agribusiness',  'Seeds & Inputs',           true),
  ('livestock_sourcing',        'agriculture_agribusiness',  'Livestock Sourcing',       true),
  ('irrigation_services',       'agriculture_agribusiness',  'Irrigation',               true),
  ('produce_buyers',            'agriculture_agribusiness',  'Produce Buyers',           true),
  ('farm_services',             'agriculture_agribusiness',  'Farm Services',            true),
  ('agricultural_transport',    'agriculture_agribusiness',  'Agricultural Transport',   true),
  ('other_agriculture',         'agriculture_agribusiness',  'Other Agriculture',        true),

  -- ── Technology & Digital ──────────────────────────────────────────────
  ('software_development',      'technology_digital',        'Software Development',     true),
  ('website_development',       'technology_digital',        'Website Development',      true),
  ('mobile_app_development',    'technology_digital',        'Mobile App Development',   true),
  ('it_support',                'technology_digital',        'IT Support',               true),
  ('networking_services',       'technology_digital',        'Networking',               true),
  ('cybersecurity_services',    'technology_digital',        'Cybersecurity',            true),
  ('digital_marketing',         'technology_digital',        'Digital Marketing',        true),
  ('automation_services',       'technology_digital',        'Automation',               true),
  ('other_technology',          'technology_digital',        'Other Technology',         true),

  -- ── Events & Production ───────────────────────────────────────────────
  ('event_planning',            'events_production',         'Event Planning',           true),
  ('tent_hire',                 'events_production',         'Tents',                    true),
  ('sound_systems',             'events_production',         'Sound Systems',            true),
  ('lighting_hire',             'events_production',         'Lighting',                 true),
  ('photography_services',      'events_production',         'Photography',              true),
  ('videography_services',      'events_production',         'Videography',              true),
  ('mc_services',               'events_production',         'MCs',                      true),
  ('catering_services',         'events_production',         'Catering',                 true),
  ('event_equipment',           'events_production',         'Event Equipment',          true),
  ('other_events',              'events_production',         'Other Events',             true),

  -- ── Energy & Utilities ────────────────────────────────────────────────
  ('solar_systems',             'energy_utilities',          'Solar Systems',            true),
  ('generator_supply',          'energy_utilities',          'Generators',               true),
  ('battery_supply',            'energy_utilities',          'Batteries',                true),
  ('electrical_installation',   'energy_utilities',          'Electrical Installation',  true),
  ('water_systems',             'energy_utilities',          'Water Systems',            true),
  ('borehole_drilling',         'energy_utilities',          'Boreholes',                true),
  ('backup_power',              'energy_utilities',          'Backup Power',             true),
  ('energy_consulting',         'energy_utilities',          'Energy Consulting',        true),
  ('other_energy',              'energy_utilities',          'Other Energy Services',    true),

  -- ── Travel & International ────────────────────────────────────────────
  ('visa_assistance',           'travel_international',      'Visa Assistance',          true),
  ('flight_tickets',            'travel_international',      'Flight Tickets',           true),
  ('hajj_umrah',                'travel_international',      'Hajj & Umrah',             true),
  ('travel_packages',           'travel_international',      'Travel Packages',          true),
  ('accommodation',             'travel_international',      'Accommodation',            true),
  ('airport_transfers',         'travel_international',      'Airport Transfers',        true),
  ('travel_documentation',      'travel_international',      'Travel Documentation',     true),
  ('other_travel',              'travel_international',      'Other Travel Services',    true)

on conflict (slug) do update set
  name          = excluded.name,
  category_slug = excluded.category_slug,
  is_active     = excluded.is_active;

-- ---------------------------------------------------------------------------
-- 4. Refresh the offer validation trigger to include category-level fallback
--    A provider satisfies a Need if:
--      (a) the Need has a specific capability_slug AND the provider holds it, OR
--      (b) the Need only specifies a category_slug AND the provider holds ANY
--          capability in that category.
--    This replaces the function defined in patch_provider_capabilities_v1.sql
-- ---------------------------------------------------------------------------
drop function if exists private.trg_validate_need_offer() cascade;

create or replace function private.trg_validate_need_offer()
returns trigger
language plpgsql
security definer
as $$
declare
  v_need public.needs_requests%rowtype;
begin
  -- Load the target need
  select * into v_need
  from public.needs_requests
  where id = NEW.need_id;

  if not found then
    raise exception 'P0201: Need not found';
  end if;

  -- Block offers on non-open needs
  if v_need.status <> 'open' then
    raise exception 'P0202: Need is no longer open for offers';
  end if;

  -- Block self-offers
  if v_need.requester_id = NEW.offer_maker_id then
    raise exception 'P0200: Cannot make an offer on your own Need';
  end if;

  -- Capability gate ─────────────────────────────────────────────────────────
  if v_need.capability_slug is not null then
    -- Need requires a specific capability
    if not exists (
      select 1
      from public.provider_capabilities
      where user_id       = NEW.offer_maker_id
        and capability_slug = v_need.capability_slug
    ) then
      raise exception 'P0203: You do not have the required capability to offer on this Need';
    end if;

  elsif v_need.category_slug is not null then
    -- Need only specifies a category — provider must hold at least one
    -- capability within that category
    if not exists (
      select 1
      from public.provider_capabilities pc
      join public.need_capabilities nc on nc.slug = pc.capability_slug
      where pc.user_id        = NEW.offer_maker_id
        and nc.category_slug  = v_need.category_slug
    ) then
      raise exception 'P0203: You do not have any capability in this category to offer on this Need';
    end if;
  end if;
  -- ──────────────────────────────────────────────────────────────────────────

  return NEW;
end;
$$;

-- Re-attach trigger
drop trigger if exists trg_validate_need_offer on public.need_offers;
create trigger trg_validate_need_offer
  before insert on public.need_offers
  for each row execute function private.trg_validate_need_offer();

-- ---------------------------------------------------------------------------
-- 5. Grants (idempotent)
-- ---------------------------------------------------------------------------
grant select on public.need_categories   to anon, authenticated;
grant select on public.need_capabilities to anon, authenticated;

-- =============================================================================
-- End of patch_needs_categories_v2.sql
-- =============================================================================
