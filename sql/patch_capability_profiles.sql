-- =============================================================================
-- Standalone SQL Patch: patch_capability_profiles.sql
-- Purpose:
--   Capability-based provider profiles for Nipanze.
--
-- Paste this into Supabase SQL Editor after the existing Needs/provider patches.
-- The patch is additive, re-runnable, and ships behind:
--   system_settings.capability_profiles_enabled = false
--
-- Protected surfaces:
--   This patch does not change Home/feed views or RPC output columns:
--   v_loan_listings, v_forex_listings, v_needs_listings,
--   get_for_you_needs, get_provider_opportunities.
-- =============================================================================

begin;

create schema if not exists private;

grant usage on schema private to authenticated, service_role;

do $preflight$
begin
  if to_regclass('public.need_categories') is null
     or to_regclass('public.need_capabilities') is null
     or to_regclass('public.provider_capabilities') is null
     or to_regclass('public.needs_requests') is null
     or to_regclass('public.need_offers') is null
     or to_regclass('public.verification_requirements') is null then
    raise exception
      'Apply the existing Needs/provider/verification SQL patches before patch_capability_profiles.sql.';
  end if;

  if to_regprocedure('private.is_admin()') is null
     or to_regprocedure('private.require_identity_verified(uuid)') is null
     or to_regprocedure('private.check_verification_requirement(uuid,text,text,text)') is null then
    raise exception
      'Apply the central verification SQL patch before patch_capability_profiles.sql.';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'needs_requests'
      and column_name = 'details'
  )
  or not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'needs_requests'
      and column_name = 'capability_slug'
  ) then
    raise exception
      'needs_requests.details and needs_requests.capability_slug are required. Apply the Needs layer patch first.';
  end if;
end;
$preflight$;

-- ---------------------------------------------------------------------------
-- 0. Feature flag, off by default
-- ---------------------------------------------------------------------------
insert into public.system_settings (
  setting_key,
  setting_value,
  setting_type,
  category,
  description,
  is_public
)
values (
  'capability_profiles_enabled',
  'false',
  'boolean',
  'provider',
  'Enables capability profile details, roles, per-document evidence, and hire-person Needs UI.',
  true
)
on conflict (setting_key, coalesce(country, '__global__')) do update set
  setting_value = coalesce(public.system_settings.setting_value, excluded.setting_value),
  setting_type = excluded.setting_type,
  category = excluded.category,
  description = excluded.description,
  is_public = excluded.is_public,
  updated_at = now();

-- ---------------------------------------------------------------------------
-- 1. Catalog presentation fields. Keep existing category/capability slugs.
-- ---------------------------------------------------------------------------
alter table public.need_capabilities
  add column if not exists ui_group_slug text,
  add column if not exists sort_order integer not null default 1000;

create index if not exists idx_need_capabilities_ui_group
  on public.need_capabilities(ui_group_slug, sort_order, slug);

update public.need_capabilities
set ui_group_slug = case category_slug
  when 'technology_digital' then 'technology_digital'
  when 'professional_services' then 'business_professional_services'
  when 'education_training' then 'education_training'
  when 'events_production' then 'events_celebrations'
  when 'weddings_celebrations' then
    case
      when slug in (
        'celebration_makeup', 'hair_styling', 'bridal_styling',
        'dresses_bridesmaid_outfits'
      ) then 'beauty_fashion_styling'
      else 'events_celebrations'
    end
  when 'music_video' then 'photo_video_music_talent'
  when 'construction_building' then 'construction_building'
  when 'energy_utilities' then 'energy_water'
  when 'agriculture_agribusiness' then 'agriculture_agribusiness'
  when 'transport_logistics' then 'transport_logistics'
  when 'machinery_equipment' then 'machinery_equipment'
  when 'specialized_products' then 'procurement_sourcing'
  when 'travel_international' then 'travel_international'
  when 'financial_services' then 'financial_services'
  else coalesce(ui_group_slug, category_slug)
end
where ui_group_slug is null
   or ui_group_slug in (
     'professional_services',
     'events_production',
     'weddings_celebrations',
     'music_video',
     'energy_utilities',
     'specialized_products'
   );

with ordered as (
  select
    slug,
    row_number() over (
      partition by coalesce(ui_group_slug, category_slug)
      order by name, slug
    ) as rn
  from public.need_capabilities
)
update public.need_capabilities nc
set sort_order = ordered.rn * 10
from ordered
where ordered.slug = nc.slug
  and nc.sort_order = 1000;

comment on column public.need_capabilities.ui_group_slug is
  'Presentation grouping for Provider Services v2. Existing category_slug remains the stable backend/business key.';

-- Ensure role-seed categories exist even if the cloud catalog is between
-- historical patch versions. Keep launch-control behavior conservative:
-- new category rows are inactive unless an earlier patch already enabled them.
insert into public.need_categories
  (slug, name, icon, sort_order, is_active)
values
  ('technology_digital', 'Technology & Digital', '💻', 1, true),
  ('marketing_promotion', 'Marketing & Promotion', '📣', 2, true),
  ('education_training', 'Education & Training', '🎓', 4, true),
  ('events_production', 'Events & Celebrations', '🎉', 5, true),
  ('photo_video_music_talent', 'Photo, Video, Music & Talent', '🎬', 6, true),
  ('beauty_fashion_styling', 'Beauty, Fashion & Styling', '💄', 7, true),
  ('construction_building', 'Construction & Building', '🏗️', 8, true),
  ('energy_utilities', 'Energy & Water', '⚡', 9, true),
  ('agriculture_agribusiness', 'Agriculture', '🌾', 12, true),
  ('weddings_celebrations', 'Weddings & Celebrations', '🎉', 120, false),
  ('music_video', 'Music & Video', '🎬', 110, false)
on conflict (slug) do nothing;

-- ---------------------------------------------------------------------------
-- 2. Verification requirements: additive evidence keys and expiry duration.
--    Existing evidence_requirements jsonb remains for backward compatibility.
-- ---------------------------------------------------------------------------
alter table public.verification_requirements
  add column if not exists required_evidence text[] not null default array[]::text[],
  add column if not exists expires_after_days integer;

alter table public.verification_requirements
  drop constraint if exists chk_verification_requirements_expires_after_days;

alter table public.verification_requirements
  add constraint chk_verification_requirements_expires_after_days
  check (expires_after_days is null or expires_after_days > 0);

create index if not exists idx_verification_requirements_required_evidence
  on public.verification_requirements using gin(required_evidence);

-- Seed only specific examples. Admins can edit these rows.
insert into public.verification_requirements (
  scope_type,
  scope_id,
  identity_required,
  phone_required,
  provider_verification_required,
  evidence_requirements,
  required_evidence,
  expires_after_days,
  is_active
)
values
  ('capability', 'excavator_hire', true, false, true,
   '["fleet_photos", "ownership_or_logbook"]'::jsonb,
   array['fleet_photos', 'ownership_or_logbook'], 365, true),
  ('capability', 'visa_assistance', true, false, true,
   '["agency_registration", "business_licence"]'::jsonb,
   array['agency_registration', 'business_licence'], 365, true),
  ('capability', 'company_registration', true, false, true,
   '["professional_registration"]'::jsonb,
   array['professional_registration'], 365, true),
  ('capability', 'legal_services', true, false, true,
   '["practising_certificate"]'::jsonb,
   array['practising_certificate'], 365, true),
  ('capability', 'heavy_haulage', true, false, true,
   '["transport_licence", "vehicle_photos"]'::jsonb,
   array['transport_licence', 'vehicle_photos'], 365, true),
  ('capability', 'solar_systems', true, false, true,
   '["installer_certificate"]'::jsonb,
   array['installer_certificate'], null, true),
  ('category', 'travel_international', true, false, true,
   '["provider_verified"]'::jsonb,
   array[]::text[], null, true)
on conflict (scope_type, scope_id) do update set
  identity_required = excluded.identity_required,
  phone_required = excluded.phone_required,
  provider_verification_required = excluded.provider_verification_required,
  evidence_requirements = excluded.evidence_requirements,
  required_evidence = excluded.required_evidence,
  expires_after_days = excluded.expires_after_days,
  is_active = excluded.is_active,
  updated_at = now();

-- ---------------------------------------------------------------------------
-- 3. Provider capability profile metadata validation.
--    Preserves existing audience/financial metadata keys. Unknown keys are
--    tolerated; this validates only the v2 keys when present.
-- ---------------------------------------------------------------------------
alter table public.provider_capabilities
  add column if not exists metadata jsonb not null default '{}'::jsonb;

create or replace function private.trg_validate_provider_capability_metadata()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_role jsonb;
  v_engagement text;
begin
  new.metadata := coalesce(new.metadata, '{}'::jsonb);

  if jsonb_typeof(new.metadata) <> 'object' then
    raise exception 'Provider capability metadata must be a JSON object.'
      using errcode = '22023';
  end if;

  if pg_column_size(new.metadata) > 16384 then
    raise exception 'Provider capability metadata is too large.'
      using errcode = '22023';
  end if;

  if new.metadata ? 'engagements' then
    if jsonb_typeof(new.metadata->'engagements') <> 'array' then
      raise exception 'metadata.engagements must be an array.'
        using errcode = '22023';
    end if;

    for v_engagement in
      select jsonb_array_elements_text(new.metadata->'engagements')
    loop
      if v_engagement not in ('service', 'work') then
        raise exception 'Unknown engagement value: %', v_engagement
          using errcode = '22023';
      end if;
    end loop;
  end if;

  if new.metadata ? 'roles' then
    if jsonb_typeof(new.metadata->'roles') <> 'array' then
      raise exception 'metadata.roles must be an array.'
        using errcode = '22023';
    end if;

    for v_role in
      select jsonb_array_elements(new.metadata->'roles')
    loop
      if jsonb_typeof(v_role) <> 'object' then
        raise exception 'Each metadata.roles item must be an object.'
          using errcode = '22023';
      end if;

      if nullif(btrim(v_role->>'role_id'), '') is null then
        raise exception 'Each metadata.roles item requires role_id.'
          using errcode = '22023';
      end if;

      if v_role ? 'kind_ids'
         and jsonb_typeof(v_role->'kind_ids') <> 'array' then
        raise exception 'metadata.roles[].kind_ids must be an array.'
          using errcode = '22023';
      end if;

      if v_role ? 'qualification_ids'
         and jsonb_typeof(v_role->'qualification_ids') <> 'array' then
        raise exception 'metadata.roles[].qualification_ids must be an array.'
          using errcode = '22023';
      end if;
    end loop;
  end if;

  if new.metadata ? 'expected_pay'
     and jsonb_typeof(new.metadata->'expected_pay') <> 'object' then
    raise exception 'metadata.expected_pay must be an object.'
      using errcode = '22023';
  end if;

  if new.metadata ? 'languages'
     and jsonb_typeof(new.metadata->'languages') <> 'array' then
    raise exception 'metadata.languages must be an array.'
      using errcode = '22023';
  end if;

  if new.metadata ? 'occasion_tags'
     and jsonb_typeof(new.metadata->'occasion_tags') <> 'array' then
    raise exception 'metadata.occasion_tags must be an array.'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_provider_capability_metadata
  on public.provider_capabilities;

create trigger trg_validate_provider_capability_metadata
  before insert or update of metadata on public.provider_capabilities
  for each row
  execute function private.trg_validate_provider_capability_metadata();

-- ---------------------------------------------------------------------------
-- 4. Per-document provider evidence table.
-- ---------------------------------------------------------------------------
create table if not exists public.provider_capability_evidence (
  id uuid primary key default gen_random_uuid(),
  provider_capability_id uuid not null
    references public.provider_capabilities(id) on delete cascade,
  requirement_key text not null,
  file_url text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'expired')),
  reject_reason text,
  expires_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_provider_capability_evidence_capability
  on public.provider_capability_evidence(provider_capability_id, requirement_key, created_at desc);

create index if not exists idx_provider_capability_evidence_status
  on public.provider_capability_evidence(status, expires_at);

alter table public.provider_capability_evidence enable row level security;

drop policy if exists "provider evidence owner select"
  on public.provider_capability_evidence;
create policy "provider evidence owner select"
  on public.provider_capability_evidence
  for select to authenticated
  using (
    exists (
      select 1
      from public.provider_capabilities pc
      where pc.id = provider_capability_evidence.provider_capability_id
        and (pc.user_id = auth.uid() or private.is_admin())
    )
  );

drop policy if exists "provider evidence owner insert"
  on public.provider_capability_evidence;
create policy "provider evidence owner insert"
  on public.provider_capability_evidence
  for insert to authenticated
  with check (
    exists (
      select 1
      from public.provider_capabilities pc
      where pc.id = provider_capability_evidence.provider_capability_id
        and pc.user_id = auth.uid()
    )
  );

drop policy if exists "provider evidence owner resubmit"
  on public.provider_capability_evidence;
create policy "provider evidence owner resubmit"
  on public.provider_capability_evidence
  for update to authenticated
  using (
    status in ('pending', 'rejected', 'expired')
    and exists (
      select 1
      from public.provider_capabilities pc
      where pc.id = provider_capability_evidence.provider_capability_id
        and pc.user_id = auth.uid()
    )
  )
  with check (
    status = 'pending'
    and reviewed_by is null
    and reviewed_at is null
    and exists (
      select 1
      from public.provider_capabilities pc
      where pc.id = provider_capability_evidence.provider_capability_id
        and pc.user_id = auth.uid()
    )
  );

drop policy if exists "provider evidence admin all"
  on public.provider_capability_evidence;
create policy "provider evidence admin all"
  on public.provider_capability_evidence
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

revoke all on public.provider_capability_evidence from anon, public;
grant select, insert, update on public.provider_capability_evidence to authenticated;

create or replace function public.touch_provider_capability_evidence_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_provider_capability_evidence_updated_at
  on public.provider_capability_evidence;
create trigger trg_provider_capability_evidence_updated_at
  before update on public.provider_capability_evidence
  for each row
  execute function public.touch_provider_capability_evidence_updated_at();

-- Private storage bucket for provider evidence. Files should be uploaded under:
-- evidence/<user_id>/<capability_slug>/<filename>
insert into storage.buckets (id, name, public, file_size_limit)
values ('provider-evidence', 'provider-evidence', false, 52428800)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit;

drop policy if exists "provider evidence storage owner upload"
  on storage.objects;
create policy "provider evidence storage owner upload"
  on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'provider-evidence'
    and (storage.foldername(name))[1] = 'evidence'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "provider evidence storage owner read"
  on storage.objects;
create policy "provider evidence storage owner read"
  on storage.objects
  for select to authenticated
  using (
    bucket_id = 'provider-evidence'
    and (
      ((storage.foldername(name))[1] = 'evidence'
       and (storage.foldername(name))[2] = auth.uid()::text)
      or private.is_admin()
    )
  );

drop policy if exists "provider evidence storage admin all"
  on storage.objects;
create policy "provider evidence storage admin all"
  on storage.objects
  for all to authenticated
  using (bucket_id = 'provider-evidence' and private.is_admin())
  with check (bucket_id = 'provider-evidence' and private.is_admin());

-- ---------------------------------------------------------------------------
-- 5. Roles, kinds, qualifications catalog.
-- ---------------------------------------------------------------------------
create table if not exists public.capability_roles (
  slug text primary key,
  capability_slug text references public.need_capabilities(slug) on delete cascade,
  category_slug text references public.need_categories(slug) on delete cascade,
  name text not null,
  kind_question text,
  is_active boolean not null default true,
  country_labels jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint capability_roles_scope_check check (
    capability_slug is not null or category_slug is not null
  )
);

create table if not exists public.role_kinds (
  role_slug text not null references public.capability_roles(slug) on delete cascade,
  slug text not null,
  name text not null,
  sort_order integer not null default 1000,
  country_labels jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (role_slug, slug)
);

create table if not exists public.role_qualifications (
  role_slug text not null references public.capability_roles(slug) on delete cascade,
  slug text not null,
  name text not null,
  is_evidence boolean not null default false,
  sort_order integer not null default 1000,
  country_labels jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (role_slug, slug)
);

alter table public.capability_roles enable row level security;
alter table public.role_kinds enable row level security;
alter table public.role_qualifications enable row level security;

drop policy if exists "capability roles public read" on public.capability_roles;
create policy "capability roles public read"
  on public.capability_roles for select using (true);

drop policy if exists "role kinds public read" on public.role_kinds;
create policy "role kinds public read"
  on public.role_kinds for select using (true);

drop policy if exists "role qualifications public read" on public.role_qualifications;
create policy "role qualifications public read"
  on public.role_qualifications for select using (true);

drop policy if exists "capability roles admin write" on public.capability_roles;
create policy "capability roles admin write"
  on public.capability_roles for all to authenticated
  using (private.is_admin()) with check (private.is_admin());

drop policy if exists "role kinds admin write" on public.role_kinds;
create policy "role kinds admin write"
  on public.role_kinds for all to authenticated
  using (private.is_admin()) with check (private.is_admin());

drop policy if exists "role qualifications admin write" on public.role_qualifications;
create policy "role qualifications admin write"
  on public.role_qualifications for all to authenticated
  using (private.is_admin()) with check (private.is_admin());

grant select on public.capability_roles to anon, authenticated;
grant select on public.role_kinds to anon, authenticated;
grant select on public.role_qualifications to anon, authenticated;
grant insert, update, delete on public.capability_roles to authenticated;
grant insert, update, delete on public.role_kinds to authenticated;
grant insert, update, delete on public.role_qualifications to authenticated;

insert into public.capability_roles
  (slug, category_slug, capability_slug, name, kind_question, is_active)
values
  ('developer', 'technology_digital', null, 'Developer', 'What do you build?', true),
  ('it_technician', 'technology_digital', null, 'IT Technician', 'What do you do?', true),
  ('security_specialist', 'technology_digital', null, 'Security Specialist', 'Which area?', true),
  ('marketer_specialist', 'marketing_promotion', null, 'Marketer / Specialist', 'Which channel?', true),
  ('content_creator', 'marketing_promotion', null, 'Content Creator', 'What do you produce?', true),
  ('accountant_finance_officer', 'professional_services', null, 'Accountant / Finance Officer', 'What area?', true),
  ('lawyer_legal_officer', 'professional_services', null, 'Lawyer / Legal Officer', 'What area?', true),
  ('engineer', 'professional_services', null, 'Engineer', 'Which discipline?', true),
  ('teacher_tutor', 'education_training', null, 'Teacher / Tutor', 'What do you teach?', true),
  ('trainer_instructor', 'education_training', null, 'Trainer / Instructor', 'Training field?', true),
  ('event_manager_planner', 'events_production', null, 'Event Manager / Planner', 'What events?', true),
  ('mc_dj', 'events_production', null, 'MC / DJ', 'Which role?', true),
  ('photographer_videographer', 'photo_video_music_talent', null, 'Photographer / Videographer', 'What do you shoot?', true),
  ('performer_talent', 'photo_video_music_talent', null, 'Performer / Talent', 'What kind?', true),
  ('makeup_artist', 'beauty_fashion_styling', null, 'Makeup Artist', 'Specialty?', true),
  ('hair_stylist', 'beauty_fashion_styling', null, 'Hair Stylist', 'Specialty?', true),
  ('site_manager', 'construction_building', null, 'Site Manager', 'What type of sites?', true),
  ('skilled_tradesperson', 'construction_building', null, 'Skilled Tradesperson', 'Which trade?', true),
  ('solar_electrical_technician', 'energy_utilities', null, 'Solar / Electrical Technician', 'What do you install?', true),
  ('driver', 'transport_logistics', null, 'Driver', 'What do you drive?', true),
  ('machine_operator', 'machinery_equipment', null, 'Machine Operator', 'Which machine do you operate?', true),
  ('equipment_mechanic', 'machinery_equipment', null, 'Equipment Mechanic', 'What do you service?', true),
  ('farm_manager', 'agriculture_agribusiness', null, 'Farm Manager', 'What farm?', true),
  ('procurement_officer_manager', 'specialized_products', null, 'Procurement Officer / Manager', 'What do you buy?', true),
  ('travel_agent_consultant', 'travel_international', null, 'Travel Agent / Consultant', 'What do you handle?', true)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = excluded.is_active;

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('developer', 'frontend', 'Frontend', 10),
  ('developer', 'backend', 'Backend', 20),
  ('developer', 'full_stack', 'Full-stack', 30),
  ('developer', 'mobile', 'Mobile', 40),
  ('developer', 'qa_tester', 'QA / Tester', 50),
  ('developer', 'devops', 'DevOps', 60),
  ('it_technician', 'helpdesk', 'Helpdesk', 10),
  ('it_technician', 'hardware_repair', 'Hardware repair', 20),
  ('it_technician', 'network_installation', 'Network installation', 30),
  ('it_technician', 'cctv_access_control', 'CCTV & access control', 40),
  ('security_specialist', 'network_security', 'Network security', 10),
  ('security_specialist', 'penetration_testing', 'Penetration testing', 20),
  ('security_specialist', 'security_audits', 'Security audits', 30),
  ('marketer_specialist', 'social_media', 'Social media', 10),
  ('marketer_specialist', 'seo_sem', 'SEO / SEM', 20),
  ('marketer_specialist', 'email', 'Email', 30),
  ('marketer_specialist', 'brand', 'Brand', 40),
  ('content_creator', 'video', 'Video', 10),
  ('content_creator', 'photo', 'Photo', 20),
  ('content_creator', 'writing', 'Writing', 30),
  ('content_creator', 'design', 'Design', 40),
  ('accountant_finance_officer', 'bookkeeping', 'Bookkeeping', 10),
  ('accountant_finance_officer', 'tax', 'Tax', 20),
  ('accountant_finance_officer', 'audit', 'Audit', 30),
  ('lawyer_legal_officer', 'corporate', 'Corporate', 10),
  ('lawyer_legal_officer', 'property', 'Property', 20),
  ('lawyer_legal_officer', 'contracts', 'Contracts', 30),
  ('engineer', 'civil', 'Civil', 10),
  ('engineer', 'electrical', 'Electrical', 20),
  ('engineer', 'mechanical', 'Mechanical', 30),
  ('teacher_tutor', 'primary', 'Primary', 10),
  ('teacher_tutor', 'secondary', 'Secondary', 20),
  ('teacher_tutor', 'university', 'University', 30),
  ('teacher_tutor', 'languages', 'Languages', 40),
  ('trainer_instructor', 'computer_it', 'Computer / IT', 10),
  ('trainer_instructor', 'vocational_technical', 'Vocational / technical', 20),
  ('trainer_instructor', 'professional_corporate', 'Professional / corporate', 30),
  ('event_manager_planner', 'weddings', 'Weddings', 10),
  ('event_manager_planner', 'corporate', 'Corporate', 20),
  ('event_manager_planner', 'birthdays_parties', 'Birthdays & parties', 30),
  ('mc_dj', 'mc', 'MC', 10),
  ('mc_dj', 'dj', 'DJ', 20),
  ('mc_dj', 'both', 'Both', 30),
  ('photographer_videographer', 'weddings', 'Weddings', 10),
  ('photographer_videographer', 'corporate', 'Corporate', 20),
  ('photographer_videographer', 'fashion_portraits', 'Fashion & portraits', 30),
  ('photographer_videographer', 'music_videos', 'Music videos', 40),
  ('performer_talent', 'singer', 'Singer', 10),
  ('performer_talent', 'dancer', 'Dancer', 20),
  ('performer_talent', 'actor', 'Actor', 30),
  ('performer_talent', 'model', 'Model', 40),
  ('makeup_artist', 'bridal', 'Bridal', 10),
  ('makeup_artist', 'fashion_editorial', 'Fashion / editorial', 20),
  ('hair_stylist', 'braiding', 'Braiding', 10),
  ('hair_stylist', 'salon_styling', 'Salon styling', 20),
  ('site_manager', 'residential', 'Residential', 10),
  ('site_manager', 'commercial', 'Commercial', 20),
  ('site_manager', 'infrastructure', 'Infrastructure', 30),
  ('skilled_tradesperson', 'mason', 'Mason', 10),
  ('skilled_tradesperson', 'plumber', 'Plumber', 20),
  ('skilled_tradesperson', 'electrician', 'Electrician', 30),
  ('solar_electrical_technician', 'solar_pv', 'Solar PV', 10),
  ('solar_electrical_technician', 'batteries_inverters', 'Batteries & inverters', 20),
  ('solar_electrical_technician', 'generators', 'Generators', 30),
  ('driver', 'truck_heavy', 'Truck / heavy', 10),
  ('driver', 'pickup_van', 'Pickup / van', 20),
  ('driver', 'bus_minibus', 'Bus / minibus', 30),
  ('driver', 'motorcycle_courier', 'Motorcycle courier', 40),
  ('machine_operator', 'excavator', 'Excavator', 10),
  ('machine_operator', 'loader', 'Loader', 20),
  ('machine_operator', 'grader', 'Grader', 30),
  ('machine_operator', 'crane', 'Crane', 40),
  ('machine_operator', 'tractor', 'Tractor', 50),
  ('machine_operator', 'forklift', 'Forklift', 60),
  ('equipment_mechanic', 'heavy_plant', 'Heavy plant', 10),
  ('equipment_mechanic', 'generators', 'Generators', 20),
  ('farm_manager', 'crops', 'Crops', 10),
  ('farm_manager', 'dairy', 'Dairy', 20),
  ('farm_manager', 'poultry', 'Poultry', 30),
  ('procurement_officer_manager', 'industrial', 'Industrial', 10),
  ('procurement_officer_manager', 'electronics', 'Electronics', 20),
  ('procurement_officer_manager', 'medical_lab', 'Medical & lab', 30),
  ('travel_agent_consultant', 'flights', 'Flights', 10),
  ('travel_agent_consultant', 'tours_packages', 'Tours & packages', 20),
  ('travel_agent_consultant', 'visas', 'Visas', 30),
  ('travel_agent_consultant', 'relocation', 'Relocation', 40)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

insert into public.role_qualifications (role_slug, slug, name, is_evidence, sort_order)
values
  ('developer', 'it_cs_degree_diploma', 'Degree / Diploma in IT or CS', true, 10),
  ('developer', 'portfolio_github', 'Portfolio or GitHub link', true, 20),
  ('developer', 'cloud_certification', 'Cloud certification', true, 30),
  ('it_technician', 'comptia_a_n', 'CompTIA A+ / N+', true, 10),
  ('it_technician', 'ccna', 'CCNA', true, 20),
  ('security_specialist', 'ceh', 'CEH', true, 10),
  ('security_specialist', 'cissp_cism', 'CISSP / CISM', true, 20),
  ('marketer_specialist', 'marketing_degree', 'Marketing diploma / degree', true, 10),
  ('marketer_specialist', 'ads_certified', 'Google Ads / Meta certified', true, 20),
  ('content_creator', 'portfolio', 'Portfolio', true, 10),
  ('content_creator', 'own_equipment', 'Own equipment', false, 20),
  ('accountant_finance_officer', 'cpa_acca', 'CPA / ACCA / CPA-U', true, 10),
  ('lawyer_legal_officer', 'practising_certificate', 'Bar admission / practising certificate', true, 10),
  ('engineer', 'engineering_degree', 'Degree in engineering', true, 10),
  ('engineer', 'engineers_board_registration', 'Registered with engineers board', true, 20),
  ('teacher_tutor', 'teaching_certificate', 'Teaching certificate / degree', true, 10),
  ('trainer_instructor', 'trade_certificate', 'Trade certificate', true, 10),
  ('event_manager_planner', 'event_certificate', 'Event planning certificate', true, 10),
  ('event_manager_planner', 'event_portfolio', 'Portfolio of 5+ events', true, 20),
  ('mc_dj', 'own_equipment', 'Own equipment', false, 10),
  ('mc_dj', 'sample_video_mix', 'Sample mix / video', true, 20),
  ('photographer_videographer', 'portfolio_link', 'Portfolio link', true, 10),
  ('photographer_videographer', 'own_camera_drone', 'Own camera / drone kit', false, 20),
  ('performer_talent', 'showreel', 'Showreel / audition clip', true, 10),
  ('makeup_artist', 'cosmetology_certificate', 'Cosmetology certificate', true, 10),
  ('hair_stylist', 'cosmetology_certificate', 'Cosmetology certificate', true, 10),
  ('site_manager', 'construction_degree', 'Civil/Construction diploma or degree', true, 10),
  ('site_manager', 'safety_certification', 'Safety certification', true, 20),
  ('skilled_tradesperson', 'trade_test', 'Trade test', true, 10),
  ('solar_electrical_technician', 'electrical_licence', 'Electrical licence', true, 10),
  ('solar_electrical_technician', 'solar_installer_certificate', 'Solar installer certificate', true, 20),
  ('driver', 'driving_licence_class', 'Valid driving licence (class)', true, 10),
  ('driver', 'psv_badge', 'PSV badge', true, 20),
  ('machine_operator', 'operator_licence', 'Operator licence / certificate', true, 10),
  ('machine_operator', 'safety_certificate', 'Safety / OSHA certificate', true, 20),
  ('machine_operator', 'medical_fitness', 'Medical fitness', true, 30),
  ('equipment_mechanic', 'mechanic_trade_certificate', 'Mechanic trade certificate', true, 10),
  ('farm_manager', 'agriculture_degree_diploma', 'Agriculture diploma / degree', true, 10),
  ('procurement_officer_manager', 'procurement_diploma', 'Procurement diploma / CIPS', true, 10),
  ('travel_agent_consultant', 'iata_certification', 'IATA certification', true, 10),
  ('travel_agent_consultant', 'travel_agency_licence', 'Travel agency licence', true, 20)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  is_evidence = excluded.is_evidence,
  sort_order = excluded.sort_order;

-- ---------------------------------------------------------------------------
-- 6. Per-capability status view. Evidence URLs never appear in public badges.
-- ---------------------------------------------------------------------------
create or replace view public.v_my_capability_status
with (security_invoker = true)
as
with latest_rejection as (
  select distinct on (e.provider_capability_id)
    e.provider_capability_id,
    e.reject_reason,
    e.reviewed_at
  from public.provider_capability_evidence e
  where e.status = 'rejected'
  order by e.provider_capability_id, e.reviewed_at desc nulls last, e.created_at desc
),
evidence_summary as (
  select
    e.provider_capability_id,
    count(*) filter (where e.status = 'pending') as pending_count,
    count(*) filter (where e.status = 'approved') as approved_count,
    count(*) filter (where e.status = 'rejected') as rejected_count,
    count(*) filter (where e.status = 'expired') as expired_count
  from public.provider_capability_evidence e
  group by e.provider_capability_id
)
select
  pc.id as provider_capability_id,
  pc.user_id,
  pc.capability_slug,
  nc.name as capability_name,
  nc.category_slug,
  cat.name as category_name,
  cat.icon as category_icon,
  pc.verification_level,
  pc.metadata,
  case
    when pc.verification_level = 'provider_verified' then 'provider_verified'
    when coalesce(es.pending_count, 0) > 0 then 'pending_review'
    when coalesce(es.rejected_count, 0) > 0 then 'rejected'
    when coalesce(es.expired_count, 0) > 0 then 'expired'
    else 'self_declared'
  end as capability_status,
  coalesce(es.pending_count, 0)::int as pending_evidence_count,
  coalesce(es.approved_count, 0)::int as approved_evidence_count,
  coalesce(es.rejected_count, 0)::int as rejected_evidence_count,
  coalesce(es.expired_count, 0)::int as expired_evidence_count,
  lr.reject_reason as latest_reject_reason,
  pc.verified_by,
  pc.verified_at,
  pc.created_at
from public.provider_capabilities pc
join public.need_capabilities nc on nc.slug = pc.capability_slug
join public.need_categories cat on cat.slug = nc.category_slug
left join evidence_summary es on es.provider_capability_id = pc.id
left join latest_rejection lr on lr.provider_capability_id = pc.id
where pc.user_id = auth.uid() or private.is_admin();

grant select on public.v_my_capability_status to authenticated;

-- ---------------------------------------------------------------------------
-- 7. User evidence submission. Uploading evidence only creates a pending
--    review item; it never grants a verified badge.
-- ---------------------------------------------------------------------------
create or replace function public.submit_provider_capability_evidence(
  p_provider_capability_id uuid,
  p_requirement_key text,
  p_file_url text
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_evidence_id uuid;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  if nullif(btrim(p_requirement_key), '') is null then
    raise exception 'Evidence requirement key is required.'
      using errcode = '22023';
  end if;

  if nullif(btrim(p_file_url), '') is null then
    raise exception 'Evidence file URL is required.'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.provider_capabilities pc
    where pc.id = p_provider_capability_id
      and pc.user_id = v_user
  ) then
    raise exception 'Provider capability not found for current user.'
      using errcode = 'P0212';
  end if;

  insert into public.provider_capability_evidence (
    provider_capability_id,
    requirement_key,
    file_url,
    status
  )
  values (
    p_provider_capability_id,
    btrim(p_requirement_key),
    btrim(p_file_url),
    'pending'
  )
  returning id into v_evidence_id;

  return v_evidence_id;
end;
$$;

grant execute on function public.submit_provider_capability_evidence(uuid, text, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 8. Matching helpers for hire-person Needs.
-- ---------------------------------------------------------------------------
create schema if not exists private;

create or replace function private.jsonb_text_array(p_value jsonb)
returns text[]
language sql
immutable
as $$
  select coalesce(array_agg(value), array[]::text[])
  from jsonb_array_elements_text(
    case when jsonb_typeof(p_value) = 'array' then p_value else '[]'::jsonb end
  ) as item(value);
$$;

create or replace function private.capability_match_score(
  p_need_details jsonb,
  p_provider_metadata jsonb
)
returns integer
language plpgsql
immutable
as $$
declare
  v_role_id text := nullif(btrim(coalesce(p_need_details->>'role_id', '')), '');
  v_need_kinds text[] := private.jsonb_text_array(p_need_details->'kind_ids');
  v_required_quals text[] := private.jsonb_text_array(p_need_details->'required_qualification_ids');
  v_role jsonb;
  v_role_kinds text[];
  v_role_quals text[];
  v_matched_quals int := 0;
  v_total_quals int := coalesce(array_length(v_required_quals, 1), 0);
begin
  if coalesce(p_need_details->>'engagement', '') <> 'hire_person' then
    return 100;
  end if;

  if v_role_id is null then
    return 0;
  end if;

  for v_role in
    select jsonb_array_elements(
      case
        when jsonb_typeof(p_provider_metadata->'roles') = 'array'
          then p_provider_metadata->'roles'
        else '[]'::jsonb
      end
    )
  loop
    if v_role->>'role_id' = v_role_id then
      v_role_kinds := private.jsonb_text_array(v_role->'kind_ids');
      v_role_quals := private.jsonb_text_array(v_role->'qualification_ids');

      if coalesce(array_length(v_need_kinds, 1), 0) > 0
         and not (v_need_kinds && v_role_kinds) then
        continue;
      end if;

      if v_total_quals = 0 then
        return 100;
      end if;

      select count(*)::int
      into v_matched_quals
      from unnest(v_required_quals) q
      where q = any(v_role_quals);

      return round((v_matched_quals::numeric / v_total_quals::numeric) * 100)::int;
    end if;
  end loop;

  return 0;
end;
$$;

-- ---------------------------------------------------------------------------
-- 9. Need-offer validation extension for hire-person Needs.
--    Keeps existing capability + central verification behavior, adds role/kind.
-- ---------------------------------------------------------------------------
create or replace function private.trg_validate_need_offer()
returns trigger
language plpgsql
security definer
as $$
declare
  v_need record;
  v_plan text;
  v_offer_count_month int;
  v_free_offer_cap int := 3;
  v_has_capability boolean := false;
  v_capability public.provider_capabilities%rowtype;
  v_check jsonb;
  v_match_score int;
begin
  perform private.require_identity_verified(new.offer_maker_id);

  select * into v_need
  from public.needs_requests
  where request_id = new.need_id;

  if not found then
    raise exception 'Need request not found' using errcode = 'P0201';
  end if;

  if v_need.status <> 'active'
     or (v_need.expires_at is not null and v_need.expires_at <= now()) then
    raise exception 'Cannot offer on inactive or expired need request'
      using errcode = 'P0202';
  end if;

  if v_need.requester_id = new.offer_maker_id then
    raise exception 'Cannot make an offer on your own need request'
      using errcode = 'P0205';
  end if;

  v_check := private.check_verification_requirement(
    new.offer_maker_id,
    'need_offer',
    v_need.category_slug,
    v_need.capability_slug
  );

  if not coalesce((v_check->>'allowed')::boolean, false) then
    raise exception 'Cannot make offer: %', v_check->>'reason'
      using errcode = 'P0203';
  end if;

  if v_need.capability_slug is not null then
    select pc.* into v_capability
    from public.provider_capabilities pc
    where pc.user_id = new.offer_maker_id
      and pc.capability_slug = v_need.capability_slug
    limit 1;

    v_has_capability := found;
  else
    select pc.* into v_capability
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where pc.user_id = new.offer_maker_id
      and nc.category_slug = v_need.category_slug
    order by pc.created_at desc
    limit 1;

    v_has_capability := found;
  end if;

  if not v_has_capability then
    raise exception 'You must declare a capability in this category before making offers'
      using errcode = 'P0203';
  end if;

  if coalesce(v_need.details->>'engagement', '') = 'hire_person' then
    v_match_score := private.capability_match_score(
      coalesce(v_need.details, '{}'::jsonb),
      coalesce(v_capability.metadata, '{}'::jsonb)
    );

    if v_match_score <= 0 then
      raise exception 'Your service profile does not match the requested role or kind'
        using errcode = 'P0203';
    end if;
  end if;

  select subscription_plan into v_plan
  from public.profiles
  where id = new.offer_maker_id;

  if coalesce(v_plan, 'free') = 'free' then
    select coalesce(nullif(setting_value, '')::int, 3)
    into v_free_offer_cap
    from public.system_settings
    where setting_key = 'needs_free_offers_per_month'
      and country is null;

    select count(*)
    into v_offer_count_month
    from public.need_offers
    where offer_maker_id = new.offer_maker_id
      and created_at >= date_trunc('month', now());

    if v_offer_count_month >= v_free_offer_cap then
      raise exception 'Free plan limit of % offers/month reached. Upgrade to make unlimited offers.', v_free_offer_cap
        using errcode = 'P0204';
    end if;
  end if;

  new.terms_locked_at := coalesce(new.terms_locked_at, now());
  return new;
end;
$$;

drop trigger if exists trg_validate_need_offer on public.need_offers;
create trigger trg_validate_need_offer
  before insert on public.need_offers
  for each row
  execute function private.trg_validate_need_offer();

-- ---------------------------------------------------------------------------
-- 10. Evidence review RPCs and expiry downgrade job.
-- ---------------------------------------------------------------------------
create or replace function public.admin_review_provider_capability_evidence(
  p_evidence_id uuid,
  p_action text,
  p_reject_reason text default null,
  p_expires_at timestamptz default null
)
returns boolean
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_admin uuid := auth.uid();
  v_evidence record;
  v_required text[];
  v_approved_required_count int;
  v_required_count int;
begin
  if not private.is_admin() then
    raise exception 'Unauthorized: Admin access required' using errcode = '42501';
  end if;

  if p_action not in ('approve', 'reject', 'expire') then
    raise exception 'Invalid action: approve, reject, or expire required.'
      using errcode = '22023';
  end if;

  select
    e.*,
    pc.user_id,
    pc.capability_slug
  into v_evidence
  from public.provider_capability_evidence e
  join public.provider_capabilities pc on pc.id = e.provider_capability_id
  where e.id = p_evidence_id
  for update;

  if not found then
    raise exception 'Provider capability evidence not found.'
      using errcode = 'P0212';
  end if;

  update public.provider_capability_evidence
  set
    status = case
      when p_action = 'approve' then 'approved'
      when p_action = 'reject' then 'rejected'
      else 'expired'
    end,
    reject_reason = case when p_action = 'reject' then coalesce(p_reject_reason, '') else null end,
    expires_at = case when p_action = 'approve' then p_expires_at else expires_at end,
    reviewed_by = v_admin,
    reviewed_at = now(),
    updated_at = now()
  where id = p_evidence_id;

  select coalesce(required_evidence, array[]::text[])
  into v_required
  from public.verification_requirements
  where scope_type = 'capability'
    and scope_id = v_evidence.capability_slug
    and is_active = true
  limit 1;

  v_required_count := coalesce(array_length(v_required, 1), 0);

  if p_action = 'approve' and v_required_count > 0 then
    select count(distinct e.requirement_key)
    into v_approved_required_count
    from public.provider_capability_evidence e
    where e.provider_capability_id = v_evidence.provider_capability_id
      and e.status = 'approved'
      and e.requirement_key = any(v_required)
      and (e.expires_at is null or e.expires_at > now());

    if v_approved_required_count = v_required_count then
      update public.provider_capabilities
      set
        verification_level = 'provider_verified',
        verified_by = v_admin,
        verified_at = now()
      where id = v_evidence.provider_capability_id;
    end if;
  end if;

  if p_action in ('reject', 'expire') then
    update public.provider_capabilities
    set
      verification_level = 'self_declared',
      verified_by = null,
      verified_at = null
    where id = v_evidence.provider_capability_id;
  end if;

  insert into public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
  values (
    v_admin,
    'admin_action',
    'provider_capability_evidence',
    p_evidence_id,
    'review_provider_capability_evidence',
    jsonb_build_object(
      'action', p_action,
      'provider_capability_id', v_evidence.provider_capability_id,
      'capability_slug', v_evidence.capability_slug,
      'requirement_key', v_evidence.requirement_key,
      'reject_reason', p_reject_reason,
      'expires_at', p_expires_at
    )
  );

  return true;
end;
$$;

grant execute on function public.admin_review_provider_capability_evidence(uuid, text, text, timestamptz)
  to authenticated;

create or replace function public.expire_provider_capability_evidence()
returns integer
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_count integer;
begin
  if not private.is_admin()
     and coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'Unauthorized: Admin or service role access required'
      using errcode = '42501';
  end if;

  update public.provider_capability_evidence
  set
    status = 'expired',
    updated_at = now()
  where status = 'approved'
    and expires_at is not null
    and expires_at <= now();

  get diagnostics v_count = row_count;

  update public.provider_capabilities pc
  set
    verification_level = 'self_declared',
    verified_by = null,
    verified_at = null
  where pc.verification_level = 'provider_verified'
    and exists (
      select 1
      from public.provider_capability_evidence e
      where e.provider_capability_id = pc.id
        and e.status = 'expired'
    );

  return v_count;
end;
$$;

grant execute on function public.expire_provider_capability_evidence()
  to authenticated;

-- ---------------------------------------------------------------------------
-- 11. Dry-run/report queries for Supabase SQL Editor.
-- ---------------------------------------------------------------------------
select 'capability_profiles_patch_applied' as check_name, now() as checked_at;

select
  'provider_capabilities_total' as metric,
  count(*)::text as value
from public.provider_capabilities
union all
select
  'needs_with_capability_slug_total',
  count(*)::text
from public.needs_requests
where capability_slug is not null
union all
select
  'role_catalog_roles',
  count(*)::text
from public.capability_roles
union all
select
  'role_catalog_kinds',
  count(*)::text
from public.role_kinds
union all
select
  'role_catalog_qualifications',
  count(*)::text
from public.role_qualifications;

commit;
