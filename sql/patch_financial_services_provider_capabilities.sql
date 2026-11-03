-- Enable Financial Services as a provider-only category with capability-level
-- proof requirements. Apply after the v2 catalog, provider work-profile,
-- capability verification-policy, provider-type verification matrix, company
-- provider path, category-type, and identity-switch patches. Safe to rerun; no
-- existing rows are removed. This does not expose Financial Services in Needs.

begin;

update public.need_categories
set name = 'Financial Services', icon = '💰',
    description = 'Loans and financing you offer', sort_order = 19, is_active = true
where slug = 'financial_services';

insert into public.need_categories
  (slug, name, icon, description, sort_order, is_active, provider_verification_required)
values
  ('financial_services', 'Financial Services', '💰',
   'Loans and financing you offer', 19, true, false)
on conflict (slug) do update set
  name = excluded.name, icon = excluded.icon,
  description = excluded.description, sort_order = excluded.sort_order,
  is_active = true;

insert into public.need_capabilities (
  slug, category_slug, name, is_active, capability_type, ui_group_slug,
  sort_order, service_group_slug, service_group_name, service_sort_order,
  verification_policy
) values
  ('personal_loan_services','financial_services','Personal Loan Services',true,'service','financial_services',110,'personal_financing','Personal Financing',10,'required_proof'),
  ('emergency_loan_services','financial_services','Emergency Loan Services',true,'service','financial_services',120,'personal_financing','Personal Financing',20,'required_proof'),
  ('salary_loan_services','financial_services','Salary Loan Services',true,'service','financial_services',130,'personal_financing','Personal Financing',30,'required_proof'),
  ('medical_financing','financial_services','Medical Financing',true,'service','financial_services',140,'personal_financing','Personal Financing',40,'required_proof'),
  ('business_startup_financing','financial_services','Business Startup Financing',true,'service','financial_services',210,'business_financing','Business Financing',10,'required_proof'),
  ('working_capital_financing','financial_services','Working Capital Financing',true,'service','financial_services',220,'business_financing','Business Financing',20,'required_proof'),
  ('business_expansion_financing','financial_services','Business Expansion Financing',true,'service','financial_services',230,'business_financing','Business Financing',30,'required_proof'),
  ('sme_financing','financial_services','SME Financing',true,'service','financial_services',240,'business_financing','Business Financing',40,'required_proof'),
  ('boda_boda_financing','financial_services','Boda Boda Financing',true,'service','financial_services',310,'asset_financing','Asset Financing',10,'required_proof'),
  ('car_financing','financial_services','Car Financing',true,'service','financial_services',320,'asset_financing','Asset Financing',20,'required_proof'),
  ('tuk_tuk_financing','financial_services','Tuk-tuk Financing',true,'service','financial_services',330,'asset_financing','Asset Financing',30,'required_proof'),
  ('motorcycle_financing','financial_services','Motorcycle Financing',true,'service','financial_services',340,'asset_financing','Asset Financing',40,'required_proof'),
  ('smartphone_financing','financial_services','Smartphone Financing',true,'service','financial_services',350,'asset_financing','Asset Financing',50,'required_proof'),
  ('laptop_financing','financial_services','Laptop Financing',true,'service','financial_services',360,'asset_financing','Asset Financing',60,'required_proof'),
  ('heavy_machinery_financing','financial_services','Heavy Machinery Financing',true,'service','financial_services',370,'asset_financing','Asset Financing',70,'required_proof'),
  ('equipment_financing','financial_services','Equipment Financing',true,'service','financial_services',380,'asset_financing','Asset Financing',80,'required_proof'),
  ('agricultural_loan_services','financial_services','Agricultural Loans',true,'service','financial_services',410,'agricultural_financing','Agricultural Financing',10,'required_proof'),
  ('livestock_financing','financial_services','Livestock Financing',true,'service','financial_services',420,'agricultural_financing','Agricultural Financing',20,'required_proof'),
  ('crop_financing','financial_services','Crop Financing',true,'service','financial_services',430,'agricultural_financing','Agricultural Financing',30,'required_proof'),
  ('farm_equipment_financing','financial_services','Farm Equipment Financing',true,'service','financial_services',440,'agricultural_financing','Agricultural Financing',40,'required_proof'),
  ('mortgage_financing','financial_services','Mortgage Financing',true,'service','financial_services',510,'property_financing','Property Financing',10,'required_proof'),
  ('land_financing','financial_services','Land Financing',true,'service','financial_services',520,'property_financing','Property Financing',20,'required_proof'),
  ('property_development_financing','financial_services','Property Development Financing',true,'service','financial_services',530,'property_financing','Property Financing',30,'required_proof'),
  ('school_fees_financing','financial_services','School Fees Financing',true,'service','financial_services',610,'education_financing','Education Financing',10,'required_proof'),
  ('university_financing','financial_services','University Financing',true,'service','financial_services',620,'education_financing','Education Financing',20,'required_proof'),
  ('education_loan_services','financial_services','Education Loans',true,'service','financial_services',630,'education_financing','Education Financing',30,'required_proof'),
  ('travel_financing','financial_services','Travel Financing',true,'service','financial_services',710,'lifestyle_financing','Lifestyle Financing',10,'required_proof'),
  ('wedding_financing','financial_services','Wedding Financing',true,'service','financial_services',720,'lifestyle_financing','Lifestyle Financing',20,'required_proof'),
  ('other_lifestyle_financing','financial_services','Other Lifestyle Financing',true,'service','financial_services',730,'lifestyle_financing','Lifestyle Financing',30,'required_proof')
on conflict (slug) do update set
  category_slug = excluded.category_slug, name = excluded.name,
  is_active = excluded.is_active, capability_type = excluded.capability_type,
  ui_group_slug = excluded.ui_group_slug, sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  verification_policy = excluded.verification_policy;

-- These verification requirements make capabilities saveable as inactive
-- drafts. They become visible only after an authorized reviewer approves the
-- required evidence. KYC identity checks remain part of the existing gate.
insert into public.verification_requirements (
  scope_type, scope_id, provider_type, identity_required, phone_required,
  provider_verification_required, evidence_requirements, required_evidence,
  expires_after_days, is_active
)
select 'capability', nc.slug, requirements.provider_type, true, false, true,
       to_jsonb(requirements.required_evidence), requirements.required_evidence,
       365, true
from public.need_capabilities nc
cross join (values
  ('individual'::text, array['supporting_information']::text[]),
  ('company'::text, array['business_registration','financial_authorization']::text[])
) as requirements(provider_type, required_evidence)
where nc.category_slug = 'financial_services'
  and not exists (
    select 1 from public.verification_requirements vr
    where vr.scope_type = 'capability' and vr.scope_id = nc.slug
      and vr.provider_type = requirements.provider_type and vr.is_active
  );

update public.need_capabilities
set verification_policy = 'required_proof'
where category_slug = 'financial_services';

-- Keep independent selections and proof records for the two existing identity
-- types. Legacy rows remain unchanged and retain their ids and evidence links.
alter table public.provider_capabilities
  drop constraint if exists provider_capabilities_user_id_capability_slug_key;
create unique index if not exists provider_capabilities_service_identity_uidx
  on public.provider_capabilities(user_id, capability_slug, identity_type)
  where identity_type is not null;
create unique index if not exists provider_capabilities_work_identity_uidx
  on public.provider_capabilities(user_id, capability_slug)
  where identity_type is null;

create or replace function private.enforce_provider_capability_policy()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_category text; v_policy text; v_type text;
begin
  select category_slug, verification_policy, capability_type
    into v_category, v_policy, v_type
    from public.need_capabilities where slug = new.capability_slug;
  if not found then
    raise exception 'Provider capability is unavailable.' using errcode = 'P0203';
  end if;
  if v_category = 'financial_services' and v_policy = 'required_proof' then
    select coalesce(new.identity_type, pcp.provider_type, 'company') into v_type
    from (select 1) seed
    left join public.provider_category_profiles pcp
      on pcp.user_id = new.user_id and pcp.category_slug = v_category;
    new.is_active := new.verification_level = 'provider_verified'
      and exists (
        select 1 from public.verification_requirements vr
        where vr.scope_type = 'capability' and vr.scope_id = new.capability_slug
          and vr.is_active and vr.provider_type in ('both', v_type)
          and cardinality(vr.required_evidence) > 0
          and not exists (
            select 1 from unnest(vr.required_evidence) as required(key)
            where not exists (
              select 1 from public.provider_capability_evidence e
              where e.provider_capability_id = new.id
                and e.provider_type in ('both', v_type)
                and e.requirement_key = required.key and e.status = 'approved'
                and (e.expires_at is null or e.expires_at > now())
            )
          )
      );
  elsif v_policy = 'required_proof' then
    new.is_active := new.verification_level = 'provider_verified'
      and exists (
        select 1 from public.provider_capability_evidence e
        where e.provider_capability_id = new.id and e.status = 'approved'
          and (e.expires_at is null or e.expires_at > now())
      );
  else
    new.is_active := true;
  end if;
  if not private.is_admin() and new.verification_level = 'provider_verified' then
    if tg_op = 'UPDATE' and old.verification_level = 'provider_verified' then
      new.verified_by := old.verified_by;
      new.verified_at := old.verified_at;
    else
      new.verification_level := 'self_declared';
      new.verified_by := null;
      new.verified_at := null;
      if v_policy = 'required_proof' then new.is_active := false; end if;
    end if;
  end if;
  return new;
end;
$$;

-- Re-evaluate legacy Financial Services rows against the complete evidence
-- checklist; keep their records and proof history while hiding unapproved rows.
update public.provider_capabilities pc
set is_active = pc.is_active
from public.need_capabilities nc
where nc.slug = pc.capability_slug and nc.category_slug = 'financial_services';

-- Provider-only: the existing Needs repository and SQL guard continue hiding
-- and rejecting this category for Needs requests.

-- Financial services are offered by either existing provider identity. Other
-- service capabilities remain Company-only.
create or replace function private.enforce_provider_identity_capability()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare v_category text; v_kind text; v_current text;
begin
  select category_slug, capability_type into v_category, v_kind
    from public.need_capabilities where slug = new.capability_slug;
  if v_kind = 'service' then
    if tg_op = 'UPDATE' and old.identity_type is not null
       and new.identity_type is distinct from old.identity_type
       and not private.is_admin() then
      raise exception 'A service identity cannot be changed directly.' using errcode = 'P0216';
    end if;
    select provider_type into v_current from public.provider_category_profiles
    where user_id = new.user_id and category_slug = v_category;
    if new.identity_type is null then new.identity_type := coalesce(v_current, 'company'); end if;
    if new.identity_type not in ('individual', 'company') then
      raise exception 'Invalid capability identity.' using errcode = 'P0216';
    end if;
    if new.is_active and new.identity_type is distinct from coalesce(v_current, 'company') then
      new.is_active := false;
    elsif new.is_active and v_category <> 'financial_services'
        and coalesce(v_current, 'company') = 'individual' then
      new.is_active := false;
    end if;
  else
    new.identity_type := null;
  end if;
  return new;
end;
$$;

create or replace function private.set_provider_category_type_internal(
  p_category_slug text, p_provider_type text
) returns void language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare v_user uuid := auth.uid(); v_old text; v_enabled text;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if p_provider_type is null or p_provider_type not in ('individual', 'company') then
    raise exception 'Invalid provider type.' using errcode = 'P0216';
  end if;
  if not exists (select 1 from public.need_categories
      where slug = p_category_slug and is_active) then
    raise exception 'Unknown or retired provider category.' using errcode = 'P0216';
  end if;
  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled' and is_public
      and (country is null or country = (select p.country from public.profiles p where p.id = v_user))
    order by (country = (select p.country from public.profiles p where p.id = v_user)) desc nulls last
    limit 1;
  if lower(coalesce(v_enabled, 'false')) not in ('true', '1') then
    raise exception 'Provider capability profiles are disabled.' using errcode = 'P0216';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text || ':' || p_category_slug, 0));
  select provider_type into v_old from public.provider_category_profiles
    where user_id = v_user and category_slug = p_category_slug for update;
  if v_old is not null and v_old <> p_provider_type then
    raise exception 'Use the identity switch review to change this category.' using errcode = 'P0216';
  end if;
  if v_old = p_provider_type then return; end if;
  insert into public.provider_category_profiles(user_id, category_slug, provider_type)
    values (v_user, p_category_slug, p_provider_type)
    on conflict (user_id, category_slug) do nothing;
  insert into public.audit_logs(user_id, event_type, entity_type, action, new_values)
    values (v_user, 'admin_action', 'provider_category_profile', 'set_initial_provider_identity',
      jsonb_build_object('category_slug', p_category_slug, 'provider_type', p_provider_type));
end;
$$;
revoke all on function private.set_provider_category_type_internal(text, text) from public, anon;
grant execute on function private.set_provider_category_type_internal(text, text) to authenticated;

create or replace function public.save_provider_capabilities(
  p_items jsonb default '[]'::jsonb,
  p_category_slug text default null,
  p_remove_slugs text[] default array[]::text[]
) returns setof public.provider_capabilities
language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_user uuid := auth.uid(); v_type text; v_max int := 30; v_count int;
  v_item record; v_kind text; v_category text;
  v_incoming text[] := array[]::text[];
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if jsonb_typeof(coalesce(p_items, '[]'::jsonb)) <> 'array' then
    raise exception 'Invalid capability selection.' using errcode = 'P0215';
  end if;
  if p_category_slug is not null then
    select provider_type into v_type from public.provider_category_profiles
      where user_id = v_user and category_slug = p_category_slug;
    if v_type is null then raise exception 'Choose a provider identity first.' using errcode = 'P0216'; end if;
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb))
    as x(capability_slug text, metadata jsonb)
  loop
    select nc.category_slug, nc.capability_type into v_category, v_kind
      from public.need_capabilities nc where nc.slug = v_item.capability_slug and nc.is_active;
    if not found or (p_category_slug is not null and v_category <> p_category_slug) then
      raise exception 'Invalid capability for category.' using errcode = 'P0215';
    end if;
    if v_kind = 'service' and coalesce(v_type, 'company') = 'individual'
       and v_category <> 'financial_services' then
      raise exception 'Individual providers cannot save company services.' using errcode = 'P0215';
    end if;
    v_incoming := array_append(v_incoming, v_item.capability_slug);
  end loop;
  select coalesce(nullif(setting_value, '')::int, 30) into v_max
    from public.system_settings where setting_key = 'max_provider_capabilities'
      and (country is null or country = '__global__') limit 1;
  select count(*) into v_count from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where pc.user_id = v_user
      and (p_category_slug is null or nc.category_slug <> p_category_slug
           or pc.identity_type = v_type or nc.capability_type = 'work')
      and (p_category_slug is not null
           or not (pc.capability_slug = any(coalesce(p_remove_slugs, array[]::text[]))));
  if v_count + cardinality(v_incoming) > coalesce(v_max, 30) then
    raise exception 'Maximum limit of % provider capabilities reached.', coalesce(v_max, 30) using errcode = 'P0206';
  end if;
  if coalesce(cardinality(p_remove_slugs), 0) > 0 then
    delete from public.provider_capabilities pc
      where pc.user_id = v_user and pc.capability_slug = any(p_remove_slugs)
        and (p_category_slug is null or pc.identity_type = v_type or pc.identity_type is null);
  end if;
  if p_category_slug is not null then
    delete from public.provider_capabilities pc using public.need_capabilities nc
      where pc.capability_slug = nc.slug and pc.user_id = v_user and nc.category_slug = p_category_slug
        and not (pc.capability_slug = any(v_incoming))
        and (nc.capability_type = 'work' or pc.identity_type = v_type);
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb))
    as x(capability_slug text, metadata jsonb)
  loop
    select capability_type into v_kind from public.need_capabilities
      where slug = v_item.capability_slug;
    if v_kind = 'work' then
      insert into public.provider_capabilities(user_id, capability_slug, verification_level, metadata, created_at)
        values (v_user, v_item.capability_slug, 'self_declared', coalesce(v_item.metadata, '{}'::jsonb), now())
      on conflict (user_id, capability_slug) where identity_type is null do update set metadata = case
        when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb then excluded.metadata
        else public.provider_capabilities.metadata end;
    else
      insert into public.provider_capabilities(user_id, capability_slug, identity_type, verification_level, metadata, created_at)
        values (v_user, v_item.capability_slug, v_type, 'self_declared', coalesce(v_item.metadata, '{}'::jsonb), now())
      on conflict (user_id, capability_slug, identity_type) where identity_type is not null do update set metadata = case
        when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb then excluded.metadata
        else public.provider_capabilities.metadata end;
    end if;
  end loop;
  return query select * from public.provider_capabilities where user_id = v_user;
end;
$$;
revoke all on function public.save_provider_capabilities(jsonb, text, text[]) from public, anon;
grant execute on function public.save_provider_capabilities(jsonb, text, text[]) to authenticated;

-- The existing Company flow saves a company profile and its selected service
-- rows atomically. Route Financial Services through the identity-aware save
-- RPC so these rows do not collide with the same capability under Individual.
create or replace function private.save_financial_company_category_internal(
  p_category_slug text,
  p_services text[],
  p_roles text[],
  p_profile jsonb,
  p_evidence jsonb
) returns void language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_type text;
  v_enabled text;
  v_profile jsonb := coalesce(p_profile, '{}'::jsonb);
  v_services text[] := coalesce(p_services, array[]::text[]);
  v_roles text[] := coalesce(p_roles, array[]::text[]);
  v_areas text[] := array[]::text[];
  v_old_profile jsonb;
  v_items jsonb;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if p_category_slug <> 'financial_services' or jsonb_typeof(v_profile) <> 'object'
     or jsonb_typeof(coalesce(p_evidence, '[]'::jsonb)) <> 'array'
     or jsonb_array_length(coalesce(p_evidence, '[]'::jsonb)) <> 0
     or cardinality(v_roles) <> 0
     or cardinality(v_services) = 0
     or cardinality(v_services) <> cardinality(array(select distinct x from unnest(v_services) x)) then
    raise exception 'Financial company profile or service selection is invalid.' using errcode = 'P0201';
  end if;
  select provider_type into v_type from public.provider_category_profiles
    where user_id = v_user and category_slug = p_category_slug;
  if v_type is distinct from 'company' then
    raise exception 'Choose Company / Organization for Financial Services first.' using errcode = 'P0202';
  end if;
  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled' and is_public
      and (country is null or country = (select country from public.profiles where id = v_user))
    order by (country = (select country from public.profiles where id = v_user)) desc nulls last limit 1;
  if lower(coalesce(v_enabled, 'false')) not in ('true', '1') then
    raise exception 'Provider capability profiles are disabled.' using errcode = 'P0202';
  end if;
  if not exists (select 1 from public.need_categories
      where slug = p_category_slug and is_active) then
    raise exception 'Financial Services is not available.' using errcode = 'P0202';
  end if;
  if length(coalesce(v_profile->>'company_name', '')) not between 1 and 80
     or length(coalesce(v_profile->>'registration_number', '')) > 40
     or (v_profile ? 'team_size' and v_profile->>'team_size' not in ('1-5','6-20','21-50','50+'))
     or (v_profile ? 'years_in_business' and v_profile->>'years_in_business' not in ('<1','1-2','3-5','6-10','10+'))
     or (v_profile ? 'service_areas' and jsonb_typeof(v_profile->'service_areas') <> 'array') then
    raise exception 'Company profile details are invalid.' using errcode = 'P0204';
  end if;
  if exists (select 1 from unnest(v_services) selected(slug)
      where not exists (select 1 from public.need_capabilities nc
        where nc.slug = selected.slug and nc.category_slug = p_category_slug
          and nc.is_active and nc.capability_type = 'service')) then
    raise exception 'A selected financial service is invalid.' using errcode = 'P0203';
  end if;
  select coalesce(array_agg(distinct btrim(value)), array[]::text[]) into v_areas
    from jsonb_array_elements_text(coalesce(v_profile->'service_areas', '[]'::jsonb)) x(value)
    where btrim(value) <> '';
  if exists (select 1 from unnest(v_areas) area where length(area) > 80) then
    raise exception 'Service areas must be district or city names.' using errcode = 'P0204';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
      'capability_slug', slug, 'metadata', '{}'::jsonb)), '[]'::jsonb)
    into v_items from unnest(v_services) selected(slug);
  perform public.save_provider_capabilities(v_items, p_category_slug, array[]::text[]);

  select to_jsonb(cp) into v_old_profile from public.provider_company_profiles cp
    where cp.user_id = v_user and cp.category_slug = p_category_slug;
  insert into public.provider_company_profiles(
    user_id, category_slug, company_name, registration_number, team_size,
    years_in_business, service_areas
  ) values (
    v_user, p_category_slug, nullif(btrim(v_profile->>'company_name'), ''),
    nullif(btrim(v_profile->>'registration_number'), ''),
    nullif(v_profile->>'team_size', ''), nullif(v_profile->>'years_in_business', ''), v_areas
  ) on conflict (user_id, category_slug) do update set
    company_name = excluded.company_name,
    registration_number = excluded.registration_number,
    team_size = excluded.team_size,
    years_in_business = excluded.years_in_business,
    service_areas = excluded.service_areas,
    updated_at = now();
  insert into public.audit_logs(user_id, event_type, entity_type, action, old_values, new_values)
    values (v_user, 'admin_action', 'provider_company_profile', 'save_financial_company_category',
      v_old_profile, jsonb_build_object('category_slug', p_category_slug,
        'services', to_jsonb(v_services), 'service_count', cardinality(v_services)));
end;
$$;
revoke all on function private.save_financial_company_category_internal(text, text[], text[], jsonb, jsonb)
  from public, anon;
grant execute on function private.save_financial_company_category_internal(text, text[], text[], jsonb, jsonb)
  to authenticated;

create or replace function public.save_company_category(
  p_category_slug text,
  p_services text[] default array[]::text[],
  p_roles text[] default array[]::text[],
  p_profile jsonb default '{}'::jsonb,
  p_evidence jsonb default '[]'::jsonb
) returns void language plpgsql security invoker
set search_path = public, private, pg_temp as $$
begin
  if p_category_slug = 'financial_services' then
    perform private.save_financial_company_category_internal(
      p_category_slug, p_services, p_roles, p_profile, p_evidence);
  else
    perform private.save_company_category_internal(
      p_category_slug, p_services, p_roles, p_profile, p_evidence);
  end if;
end;
$$;
revoke all on function public.save_company_category(text, text[], text[], jsonb, jsonb)
  from public, anon;
grant execute on function public.save_company_category(text, text[], text[], jsonb, jsonb)
  to authenticated;

-- Reuse the existing Company document review. For Financial Services only,
-- reviewed registration/authorization documents satisfy the matching
-- capability evidence keys; no separate company-proof store is introduced.
create or replace function private.sync_financial_company_document_evidence()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_key text;
  v_evidence_status text;
begin
  if new.category_slug <> 'financial_services' then return new; end if;
  v_key := case new.document_type
    when 'business_registration' then 'business_registration'
    when 'business_licence' then 'financial_authorization'
    when 'certificate' then 'financial_authorization'
    else null end;
  if v_key is null then return new; end if;

  if tg_op = 'UPDATE' and old.file_path is distinct from new.file_path then
    update public.provider_capability_evidence e
      set status = 'expired', updated_at = now()
      from public.provider_capabilities pc
      join public.need_capabilities nc on nc.slug = pc.capability_slug
      where e.provider_capability_id = pc.id and pc.user_id = new.user_id
        and pc.identity_type = 'company' and nc.category_slug = 'financial_services'
        and e.file_url = old.file_path and e.requirement_key = v_key
        and e.provider_type = 'company' and e.status = 'approved';
    update public.provider_capabilities pc
      set verification_level = 'self_declared', verified_by = null, verified_at = null,
          is_active = false
      from public.need_capabilities nc
      where nc.slug = pc.capability_slug and nc.category_slug = 'financial_services'
        and pc.user_id = new.user_id and pc.identity_type = 'company'
        and pc.verification_level = 'provider_verified';
  end if;

  v_evidence_status := case new.status
    when 'approved' then 'approved'
    when 'rejected' then 'rejected'
    else 'pending' end;
  update public.provider_capability_evidence e
    set status = v_evidence_status,
        reject_reason = case when v_evidence_status = 'rejected' then new.reject_reason else null end,
        reviewed_by = new.reviewed_by, reviewed_at = new.reviewed_at, updated_at = now()
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where e.provider_capability_id = pc.id and pc.user_id = new.user_id
      and pc.identity_type = 'company' and nc.category_slug = 'financial_services'
      and e.requirement_key = v_key and e.file_url = new.file_path
      and e.provider_type = 'company';
  insert into public.provider_capability_evidence(
    provider_capability_id, requirement_key, file_url, status, reject_reason,
    reviewed_by, reviewed_at, provider_type
  )
  select pc.id, v_key, new.file_path, v_evidence_status,
         case when v_evidence_status = 'rejected' then new.reject_reason else null end,
         new.reviewed_by, new.reviewed_at, 'company'
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  where pc.user_id = new.user_id and pc.identity_type = 'company'
    and nc.category_slug = 'financial_services'
    and not exists (select 1 from public.provider_capability_evidence e
      where e.provider_capability_id = pc.id and e.requirement_key = v_key
        and e.file_url = new.file_path);

  if v_evidence_status = 'approved' then
    update public.provider_capabilities pc
      set verification_level = 'provider_verified',
          verified_by = new.reviewed_by, verified_at = coalesce(new.reviewed_at, now())
      from public.need_capabilities nc
      where nc.slug = pc.capability_slug and nc.category_slug = 'financial_services'
        and pc.user_id = new.user_id and pc.identity_type = 'company'
        and exists (select 1 from public.verification_requirements vr
          where vr.scope_type = 'capability' and vr.scope_id = pc.capability_slug
            and vr.provider_type = 'company' and vr.is_active
            and cardinality(vr.required_evidence) > 0
            and not exists (
              select 1 from unnest(vr.required_evidence) required(key)
              where not exists (select 1 from public.provider_capability_evidence e
                where e.provider_capability_id = pc.id and e.provider_type = 'company'
                  and e.requirement_key = required.key and e.status = 'approved'
                  and (e.expires_at is null or e.expires_at > now()))
            ));
  end if;
  return new;
end;
$$;
drop trigger if exists trg_sync_financial_company_document_evidence
  on public.provider_company_verification_submissions;
create trigger trg_sync_financial_company_document_evidence
  after insert or update of status, file_path, document_type
  on public.provider_company_verification_submissions
  for each row execute function private.sync_financial_company_document_evidence();

update public.provider_company_verification_submissions
set status = status
where category_slug = 'financial_services';

commit;

notify pgrst, 'reload schema';
