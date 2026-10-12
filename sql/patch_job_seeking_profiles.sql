-- =============================================================================
-- Standalone SQL Patch: patch_job_seeking_profiles.sql
-- Purpose:
--   Separate job-seeking profiles from provider service capabilities.
--
-- Apply after the Needs/provider capability patches, especially
-- patch_capability_profiles.sql, because this patch reuses:
--   need_categories, capability_roles, role_kinds, role_qualifications.
--
-- This patch is additive and re-runnable. It does not change Need offer
-- validation, contact reveal, Loans, or Forex behavior.
-- =============================================================================

begin;

create schema if not exists private;

do $preflight$
begin
  if to_regclass('public.profiles') is null
     or to_regclass('public.need_categories') is null
     or to_regclass('public.capability_roles') is null
     or to_regclass('public.role_kinds') is null
     or to_regclass('public.role_qualifications') is null then
    raise exception
      'Apply the Needs and capability profile SQL patches before patch_job_seeking_profiles.sql.';
  end if;

  if to_regprocedure('private.is_admin()') is null then
    raise exception 'private.is_admin() is required before patch_job_seeking_profiles.sql.';
  end if;
end;
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Feature flag. Disabled by default until the Flutter flow and admin review
--    workflow have been verified in the target environment.
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
  'job_profiles_enabled',
  'false',
  'boolean',
  'provider',
  'Enables independent job-seeking profiles beside provider service capabilities.',
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
-- 2. Owner-private job profile per user/category.
-- ---------------------------------------------------------------------------
create table if not exists public.job_profiles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_slug text not null references public.need_categories(slug) on delete restrict,
  is_active boolean not null default true,
  employment_preferences text[] not null default array[]::text[],
  availability text,
  preferred_location text,
  remote_preference text not null default 'flexible',
  preferred_currency text not null default 'UGX',
  expected_pay_amount integer,
  expected_pay_period text,
  languages text[] not null default array[]::text[],
  summary text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint job_profiles_user_category_unique unique (user_id, category_slug),
  constraint job_profiles_remote_preference_check check (
    remote_preference in ('onsite', 'remote', 'hybrid', 'flexible')
  ),
  constraint job_profiles_expected_pay_amount_check check (
    expected_pay_amount is null or expected_pay_amount >= 0
  ),
  constraint job_profiles_expected_pay_period_check check (
    expected_pay_period is null
    or expected_pay_period in ('hour', 'day', 'week', 'month', 'project')
  ),
  constraint job_profiles_preferred_currency_check check (
    preferred_currency ~ '^[A-Z]{3}$'
  )
);

create index if not exists idx_job_profiles_user_active
  on public.job_profiles(user_id, is_active);

create index if not exists idx_job_profiles_category_active
  on public.job_profiles(category_slug, is_active);

-- ---------------------------------------------------------------------------
-- 3. Role assignments are separate from provider_capabilities.
-- ---------------------------------------------------------------------------
create table if not exists public.job_profile_roles (
  id uuid primary key default uuid_generate_v4(),
  job_profile_id uuid not null references public.job_profiles(id) on delete cascade,
  role_slug text not null references public.capability_roles(slug) on delete restrict,
  is_active boolean not null default true,
  years_experience text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint job_profile_roles_unique unique (job_profile_id, role_slug)
);

create index if not exists idx_job_profile_roles_profile_active
  on public.job_profile_roles(job_profile_id, is_active);

create index if not exists idx_job_profile_roles_role_active
  on public.job_profile_roles(role_slug, is_active);

create table if not exists public.job_profile_role_work_types (
  id uuid primary key default uuid_generate_v4(),
  job_profile_role_id uuid not null references public.job_profile_roles(id) on delete cascade,
  role_slug text not null,
  work_type_slug text not null,
  created_at timestamptz not null default now(),
  constraint job_profile_role_work_types_unique
    unique (job_profile_role_id, role_slug, work_type_slug),
  constraint job_profile_role_work_types_kind_fk
    foreign key (role_slug, work_type_slug)
    references public.role_kinds(role_slug, slug)
    on delete restrict
);

create index if not exists idx_job_profile_role_work_types_role
  on public.job_profile_role_work_types(role_slug, work_type_slug);

create table if not exists public.job_profile_qualification_answers (
  id uuid primary key default uuid_generate_v4(),
  job_profile_role_id uuid not null references public.job_profile_roles(id) on delete cascade,
  role_slug text not null,
  qualification_slug text not null,
  answer jsonb not null default '{"declared": true}'::jsonb,
  evidence_object_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint job_profile_qualification_answers_unique
    unique (job_profile_role_id, role_slug, qualification_slug),
  constraint job_profile_qualification_answers_fk
    foreign key (role_slug, qualification_slug)
    references public.role_qualifications(role_slug, slug)
    on delete restrict
);

create index if not exists idx_job_profile_qualification_answers_role
  on public.job_profile_qualification_answers(role_slug, qualification_slug);

comment on table public.job_profiles is
  'Owner-private work-seeking profile. Separate from provider_capabilities so service permission never implies job qualification.';
comment on table public.job_profile_roles is
  'Roles a user wants work for within a job profile. Does not grant Need offer permissions.';
comment on table public.job_profile_role_work_types is
  'Role-specific work types, such as machines an operator can operate.';
comment on table public.job_profile_qualification_answers is
  'Self-declared qualification answers and optional private evidence references. Not an admin verification badge.';

-- ---------------------------------------------------------------------------
-- 4. Updated-at triggers. Use the existing public.fn_set_updated_at() when
--    present; otherwise create a local compatible helper.
-- ---------------------------------------------------------------------------
create or replace function public.fn_job_profiles_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_job_profiles_updated_at on public.job_profiles;
create trigger trg_job_profiles_updated_at
  before update on public.job_profiles
  for each row execute function public.fn_job_profiles_set_updated_at();

drop trigger if exists trg_job_profile_roles_updated_at on public.job_profile_roles;
create trigger trg_job_profile_roles_updated_at
  before update on public.job_profile_roles
  for each row execute function public.fn_job_profiles_set_updated_at();

drop trigger if exists trg_job_profile_qualification_answers_updated_at
  on public.job_profile_qualification_answers;
create trigger trg_job_profile_qualification_answers_updated_at
  before update on public.job_profile_qualification_answers
  for each row execute function public.fn_job_profiles_set_updated_at();

-- ---------------------------------------------------------------------------
-- 5. RLS and grants. Profiles are private to the owner and admins.
-- ---------------------------------------------------------------------------
alter table public.job_profiles enable row level security;
alter table public.job_profile_roles enable row level security;
alter table public.job_profile_role_work_types enable row level security;
alter table public.job_profile_qualification_answers enable row level security;

drop policy if exists "job profiles owner or admin select" on public.job_profiles;
create policy "job profiles owner or admin select"
  on public.job_profiles for select to authenticated
  using (user_id = auth.uid() or private.is_admin());

drop policy if exists "job profiles owner insert" on public.job_profiles;
create policy "job profiles owner insert"
  on public.job_profiles for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "job profiles owner update" on public.job_profiles;
create policy "job profiles owner update"
  on public.job_profiles for update to authenticated
  using (user_id = auth.uid() or private.is_admin())
  with check (user_id = auth.uid() or private.is_admin());

drop policy if exists "job profiles owner delete" on public.job_profiles;
create policy "job profiles owner delete"
  on public.job_profiles for delete to authenticated
  using (user_id = auth.uid() or private.is_admin());

drop policy if exists "job profile roles owner or admin select" on public.job_profile_roles;
create policy "job profile roles owner or admin select"
  on public.job_profile_roles for select to authenticated
  using (
    exists (
      select 1 from public.job_profiles jp
      where jp.id = job_profile_roles.job_profile_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  );

drop policy if exists "job profile roles owner insert" on public.job_profile_roles;
create policy "job profile roles owner insert"
  on public.job_profile_roles for insert to authenticated
  with check (
    exists (
      select 1 from public.job_profiles jp
      where jp.id = job_profile_roles.job_profile_id
        and jp.user_id = auth.uid()
    )
  );

drop policy if exists "job profile roles owner update" on public.job_profile_roles;
create policy "job profile roles owner update"
  on public.job_profile_roles for update to authenticated
  using (
    exists (
      select 1 from public.job_profiles jp
      where jp.id = job_profile_roles.job_profile_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  )
  with check (
    exists (
      select 1 from public.job_profiles jp
      where jp.id = job_profile_roles.job_profile_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  );

drop policy if exists "job profile roles owner delete" on public.job_profile_roles;
create policy "job profile roles owner delete"
  on public.job_profile_roles for delete to authenticated
  using (
    exists (
      select 1 from public.job_profiles jp
      where jp.id = job_profile_roles.job_profile_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  );

drop policy if exists "job profile work types owner or admin select" on public.job_profile_role_work_types;
create policy "job profile work types owner or admin select"
  on public.job_profile_role_work_types for select to authenticated
  using (
    exists (
      select 1
      from public.job_profile_roles jpr
      join public.job_profiles jp on jp.id = jpr.job_profile_id
      where jpr.id = job_profile_role_work_types.job_profile_role_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  );

drop policy if exists "job profile work types owner all" on public.job_profile_role_work_types;
create policy "job profile work types owner all"
  on public.job_profile_role_work_types for all to authenticated
  using (
    exists (
      select 1
      from public.job_profile_roles jpr
      join public.job_profiles jp on jp.id = jpr.job_profile_id
      where jpr.id = job_profile_role_work_types.job_profile_role_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  )
  with check (
    exists (
      select 1
      from public.job_profile_roles jpr
      join public.job_profiles jp on jp.id = jpr.job_profile_id
      where jpr.id = job_profile_role_work_types.job_profile_role_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  );

drop policy if exists "job profile qualifications owner or admin select" on public.job_profile_qualification_answers;
create policy "job profile qualifications owner or admin select"
  on public.job_profile_qualification_answers for select to authenticated
  using (
    exists (
      select 1
      from public.job_profile_roles jpr
      join public.job_profiles jp on jp.id = jpr.job_profile_id
      where jpr.id = job_profile_qualification_answers.job_profile_role_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  );

drop policy if exists "job profile qualifications owner all" on public.job_profile_qualification_answers;
create policy "job profile qualifications owner all"
  on public.job_profile_qualification_answers for all to authenticated
  using (
    exists (
      select 1
      from public.job_profile_roles jpr
      join public.job_profiles jp on jp.id = jpr.job_profile_id
      where jpr.id = job_profile_qualification_answers.job_profile_role_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  )
  with check (
    exists (
      select 1
      from public.job_profile_roles jpr
      join public.job_profiles jp on jp.id = jpr.job_profile_id
      where jpr.id = job_profile_qualification_answers.job_profile_role_id
        and (jp.user_id = auth.uid() or private.is_admin())
    )
  );

grant select, insert, update, delete on public.job_profiles to authenticated;
grant select, insert, update, delete on public.job_profile_roles to authenticated;
grant select, insert, update, delete on public.job_profile_role_work_types to authenticated;
grant select, insert, update, delete on public.job_profile_qualification_answers to authenticated;

-- ---------------------------------------------------------------------------
-- Seed reference roles, work types, and qualifications for all 14 categories.
-- Uses ON CONFLICT DO NOTHING to remain idempotent and non-destructive.
-- ---------------------------------------------------------------------------
insert into public.capability_roles
  (slug, category_slug, capability_slug, name, kind_question, is_active)
values
  -- 1. Technology & Digital
  ('software_developer', 'technology_digital', null, 'Software Developer', 'What kind of development?', true),
  ('mobile_developer', 'technology_digital', null, 'Mobile Developer', 'Which platforms?', true),
  ('it_technician', 'technology_digital', null, 'IT Support Technician', 'What systems do you support?', true),
  ('network_technician', 'technology_digital', null, 'Network Technician', 'What infrastructure?', true),
  ('database_administrator', 'technology_digital', null, 'Database Administrator', 'Which databases?', true),

  -- 2. Marketing & Promotion
  ('digital_marketer', 'professional_services', null, 'Digital Marketer', 'Which channels?', true),
  ('social_media_manager', 'professional_services', null, 'Social Media Manager', 'Which platforms?', true),
  ('graphic_designer', 'professional_services', null, 'Graphic Designer', 'What design work?', true),
  ('marketing_officer', 'professional_services', null, 'Marketing Officer', 'What campaigns?', true),

  -- 3. Business & Professional
  ('business_consultant', 'professional_services', null, 'Business Consultant', 'Which focus area?', true),
  ('accountant_finance_officer', 'professional_services', null, 'Accountant', 'What accounting functions?', true),
  ('bookkeeper', 'professional_services', null, 'Bookkeeper', 'What bookkeeping systems?', true),
  ('hr_officer', 'professional_services', null, 'HR Officer', 'Which HR areas?', true),
  ('business_analyst', 'professional_services', null, 'Business Analyst', 'What domain?', true),

  -- 4. Education & Training
  ('teacher_tutor', 'education_training', null, 'Tutor', 'What subjects or levels?', true),
  ('trainer_instructor', 'education_training', null, 'Trainer / Instructor', 'Which training field?', true),
  ('academic_coach', 'education_training', null, 'Academic Coach', 'Which coaching areas?', true),
  ('teaching_assistant', 'education_training', null, 'Teaching Assistant', 'What grade levels?', true),

  -- 5. Events & Celebrations
  ('event_manager_planner', 'weddings_celebrations', null, 'Event Planner', 'What type of events?', true),
  ('event_decorator', 'weddings_celebrations', null, 'Decorator', 'What decoration styles?', true),
  ('event_caterer', 'weddings_celebrations', null, 'Caterer', 'What cuisine / service?', true),
  ('sound_technician', 'weddings_celebrations', null, 'Sound Technician', 'What equipment setup?', true),
  ('event_coordinator', 'weddings_celebrations', null, 'Event Coordinator', 'What scope?', true),

  -- 6. Photo, Video, Music & Talent
  ('photographer_videographer', 'music_video', null, 'Photographer', 'What photography style?', true),
  ('videographer', 'music_video', null, 'Videographer', 'What video production?', true),
  ('video_editor', 'music_video', null, 'Video Editor', 'What editing tools?', true),
  ('mc_dj', 'music_video', null, 'DJ', 'What genres / events?', true),
  ('musician_performer', 'music_video', null, 'Musician', 'What performance style?', true),

  -- 7. Beauty, Fashion & Styling
  ('hair_stylist', 'weddings_celebrations', null, 'Hairdresser', 'What hair services?', true),
  ('makeup_artist', 'weddings_celebrations', null, 'Makeup Artist', 'What makeup specialty?', true),
  ('tailor_fashion_designer', 'weddings_celebrations', null, 'Tailor', 'What garments?', true),
  ('fashion_designer', 'weddings_celebrations', null, 'Fashion Designer', 'What design focus?', true),
  ('wardrobe_stylist', 'weddings_celebrations', null, 'Stylist', 'What styling context?', true),

  -- 8. Construction & Building
  ('mason', 'construction_building', null, 'Mason', 'What masonry work?', true),
  ('plumber', 'construction_building', null, 'Plumber', 'What plumbing installations?', true),
  ('electrician', 'construction_building', null, 'Electrician', 'What electrical systems?', true),
  ('site_manager', 'construction_building', null, 'Site Supervisor', 'What project scale?', true),
  ('land_surveyor', 'construction_building', null, 'Surveyor', 'What surveying type?', true),
  ('construction_worker', 'construction_building', null, 'Construction Worker', 'What construction tasks?', true),

  -- 9. Energy & Water
  ('solar_electrical_technician', 'energy_utilities', null, 'Solar Technician', 'What systems do you install?', true),
  ('electrical_maintenance_technician', 'energy_utilities', null, 'Electrical Maintenance Technician', 'What equipment?', true),
  ('water_systems_technician', 'energy_utilities', null, 'Water Systems Technician', 'What water installations?', true),
  ('pump_technician', 'energy_utilities', null, 'Pump Technician', 'What pump types?', true),

  -- 10. Transport & Logistics
  ('driver', 'transport_logistics', null, 'Truck Driver', 'What vehicles do you drive?', true),
  ('delivery_driver', 'transport_logistics', null, 'Delivery Driver', 'What delivery routes?', true),
  ('logistics_officer', 'transport_logistics', null, 'Logistics Officer', 'What logistics operations?', true),
  ('fleet_manager', 'transport_logistics', null, 'Fleet Manager', 'What fleet size?', true),
  ('transport_coordinator', 'transport_logistics', null, 'Transport Coordinator', 'What transport types?', true),

  -- 11. Machinery & Equipment
  ('machine_operator', 'machinery_equipment', null, 'Machine Operator', 'Which machines can you operate?', true),
  ('equipment_mechanic', 'machinery_equipment', null, 'Equipment Mechanic', 'Which machinery do you service?', true),
  ('fleet_equipment_manager', 'machinery_equipment', null, 'Fleet / Equipment Manager', 'What equipment fleet?', true),
  ('site_supervisor_machinery', 'machinery_equipment', null, 'Site Supervisor', 'What site operations?', true),

  -- 12. Agriculture & Agribusiness
  ('farm_manager', 'agriculture_agribusiness', null, 'Farm Manager', 'What farm operations?', true),
  ('tractor_operator', 'agriculture_agribusiness', null, 'Tractor Operator', 'What implements and tasks?', true),
  ('agronomist', 'agriculture_agribusiness', null, 'Agronomist', 'What crop specialties?', true),
  ('irrigation_technician', 'agriculture_agribusiness', null, 'Irrigation Technician', 'What irrigation systems?', true),
  ('agricultural_worker', 'agriculture_agribusiness', null, 'Agricultural Worker', 'What farm tasks?', true),

  -- 13. Procurement & Sourcing
  ('procurement_officer_manager', 'specialized_products', null, 'Procurement Officer', 'What sourcing domains?', true),
  ('sourcing_agent', 'specialized_products', null, 'Sourcing Agent', 'What supplier markets?', true),
  ('purchasing_officer', 'specialized_products', null, 'Purchasing Officer', 'What product categories?', true),
  ('supply_chain_assistant', 'specialized_products', null, 'Supply Chain Assistant', 'What supply workflows?', true),

  -- 14. Travel & International
  ('travel_agent_consultant', 'travel_international', null, 'Travel Consultant', 'What travel assistance?', true),
  ('travel_coordinator', 'travel_international', null, 'Travel Coordinator', 'What trips and groups?', true),
  ('ticketing_agent', 'travel_international', null, 'Ticketing Agent', 'What reservation systems?', true),
  ('visa_documentation_assistant', 'travel_international', null, 'Visa Documentation Assistant', 'Which destinations?', true)
on conflict (slug) do nothing;

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('machine_operator', 'excavator', 'Excavator', 10),
  ('machine_operator', 'loader', 'Loader', 20),
  ('machine_operator', 'grader', 'Grader', 30),
  ('machine_operator', 'crane', 'Crane', 40),
  ('machine_operator', 'tractor', 'Tractor', 50),
  ('machine_operator', 'roller', 'Roller', 60),
  ('machine_operator', 'forklift', 'Forklift', 70),
  ('machine_operator', 'bulldozer', 'Bulldozer', 80),
  ('machine_operator', 'concrete_mixer_pump', 'Concrete Mixer / Pump', 90),
  ('machine_operator', 'generator', 'Generator', 100),
  ('machine_operator', 'other_machinery', 'Other Machinery', 110),
  ('equipment_mechanic', 'heavy_plant', 'Heavy plant', 10),
  ('equipment_mechanic', 'generators', 'Generators', 20),
  ('equipment_mechanic', 'hydraulics', 'Hydraulics', 30),
  ('driver', 'truck_heavy', 'Truck / Heavy haulage', 10),
  ('driver', 'pickup_van', 'Pickup / Delivery van', 20),
  ('driver', 'bus_minibus', 'Bus / Minibus', 30),
  ('driver', 'motorcycle_courier', 'Motorcycle courier', 40),
  ('software_developer', 'frontend', 'Frontend', 10),
  ('software_developer', 'backend', 'Backend', 20),
  ('software_developer', 'full_stack', 'Full-stack', 30),
  ('software_developer', 'mobile', 'Mobile (Flutter / Android / iOS)', 40),
  ('photographer_videographer', 'weddings', 'Weddings', 10),
  ('photographer_videographer', 'corporate', 'Corporate events', 20),
  ('photographer_videographer', 'fashion_portraits', 'Fashion & portraits', 30)
on conflict (role_slug, slug) do nothing;

insert into public.role_qualifications (role_slug, slug, name, is_evidence, sort_order)
values
  ('machine_operator', 'operator_licence', 'Operator licence / certificate', true, 10),
  ('machine_operator', 'safety_certificate', 'Safety / OSHA certificate', true, 20),
  ('machine_operator', 'medical_fitness', 'Medical fitness (where applicable)', true, 30),
  ('machine_operator', 'travel_flexibility', 'Ability to work away from home', false, 40),
  ('equipment_mechanic', 'mechanic_trade_certificate', 'Mechanic trade certificate', true, 10),
  ('equipment_mechanic', 'safety_training', 'Safety training', true, 20),
  ('driver', 'driving_licence_class', 'Valid commercial driving licence', true, 10),
  ('driver', 'defensive_driving', 'Defensive driving certificate', true, 20),
  ('software_developer', 'portfolio_github', 'Portfolio or GitHub link', false, 10),
  ('software_developer', 'technical_degree', 'CS / IT degree or diploma', true, 20),
  ('photographer_videographer', 'portfolio_link', 'Portfolio link', false, 10),
  ('photographer_videographer', 'own_camera_drone', 'Own camera / drone equipment', false, 20),
  ('travel_agent_consultant', 'iata_certification', 'IATA certification', true, 10),
  ('travel_agent_consultant', 'travel_agency_licence', 'Travel agency licence', true, 20)
on conflict (role_slug, slug) do nothing;

-- ---------------------------------------------------------------------------
-- 6. Private owner view for the Flutter account screen. It exposes only the
--    signed-in user's own profile rows through security_invoker RLS.
-- ---------------------------------------------------------------------------
create or replace view public.v_my_job_profiles
with (security_invoker = true)
as
select
  jp.id,
  jp.user_id,
  jp.category_slug,
  nc.name as category_name,
  nc.icon as category_icon,
  jp.is_active,
  jp.employment_preferences,
  jp.availability,
  jp.preferred_location,
  jp.remote_preference,
  jp.preferred_currency,
  jp.expected_pay_amount,
  jp.expected_pay_period,
  jp.languages,
  jp.summary,
  jp.created_at,
  jp.updated_at,
  coalesce(
    jsonb_agg(
      distinct jsonb_build_object(
        'id', jpr.id,
        'role_slug', jpr.role_slug,
        'role_name', cr.name,
        'is_active', jpr.is_active,
        'years_experience', jpr.years_experience,
        'work_types', coalesce(work_types.items, '[]'::jsonb),
        'qualifications', coalesce(qualifications.items, '[]'::jsonb)
      )
    ) filter (where jpr.id is not null),
    '[]'::jsonb
  ) as roles
from public.job_profiles jp
join public.need_categories nc on nc.slug = jp.category_slug
left join public.job_profile_roles jpr on jpr.job_profile_id = jp.id
left join public.capability_roles cr on cr.slug = jpr.role_slug
left join lateral (
  select jsonb_agg(
    jsonb_build_object(
      'slug', wt.work_type_slug,
      'name', rk.name
    )
    order by rk.sort_order, rk.name
  ) as items
  from public.job_profile_role_work_types wt
  join public.role_kinds rk
    on rk.role_slug = wt.role_slug
   and rk.slug = wt.work_type_slug
  where wt.job_profile_role_id = jpr.id
) work_types on true
left join lateral (
  select jsonb_agg(
    jsonb_build_object(
      'slug', qa.qualification_slug,
      'name', rq.name,
      'answer', qa.answer,
      'has_evidence', qa.evidence_object_path is not null
    )
    order by rq.sort_order, rq.name
  ) as items
  from public.job_profile_qualification_answers qa
  join public.role_qualifications rq
    on rq.role_slug = qa.role_slug
   and rq.slug = qa.qualification_slug
  where qa.job_profile_role_id = jpr.id
) qualifications on true
where jp.user_id = auth.uid() or private.is_admin()
group by jp.id, nc.name, nc.icon;

grant select on public.v_my_job_profiles to authenticated;

select 'job_seeking_profiles_patch_applied' as check_name, now() as checked_at;

commit;
