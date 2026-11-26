-- Pets & Animal Services provider category and role catalogue.
-- Apply after provider service/work-profile catalogue patches. Safe to rerun.
-- Existing Veterinary / Livestock Officer role and capability slugs are kept;
-- moving their catalogue category preserves provider capability rows and offers.
begin;

do $$
begin
  if to_regclass('public.need_categories') is null
     or to_regclass('public.need_capabilities') is null
     or to_regclass('public.capability_roles') is null
     or to_regclass('public.role_kinds') is null
     or to_regclass('public.role_qualifications') is null then
    raise exception 'Apply provider services and work-profile catalogue patches first.';
  end if;
end;
$$;

alter table public.role_qualifications
  add column if not exists is_required_proof boolean not null default false;
alter table public.need_categories
  add column if not exists description text;
alter table public.need_capabilities
  add column if not exists capability_type text not null default 'service',
  add column if not exists ui_group_slug text,
  add column if not exists sort_order integer not null default 1000,
  add column if not exists service_group_slug text,
  add column if not exists service_group_name text,
  add column if not exists service_sort_order integer not null default 1000,
  add column if not exists verification_policy text not null default 'open';

insert into public.need_categories
  (slug, name, icon, sort_order, description, is_active)
values
  ('pets_animal_services', 'Pets & Animal Services', '🐾', 24,
   'Veterinary care, pet training, grooming, boarding and animal care.', true)
on conflict (slug) do update set
  name = excluded.name, icon = excluded.icon,
  description = excluded.description, is_active = true;

insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order,
   capability_type, verification_policy)
values
  ('work_veterinarian','pets_animal_services','Veterinarian (clinical care)',true,'pets_animal_services',10,'work_roles','Work Roles',10,'work','required_proof'),
  ('work_veterinary_assistant','pets_animal_services','Veterinary Assistant',true,'pets_animal_services',20,'work_roles','Work Roles',20,'work','optional_proof'),
  ('work_pet_trainer_behaviour_specialist','pets_animal_services','Pet Trainer / Behaviour Specialist',true,'pets_animal_services',30,'work_roles','Work Roles',30,'work','optional_proof'),
  ('work_pet_groomer','pets_animal_services','Pet Groomer',true,'pets_animal_services',50,'work_roles','Work Roles',50,'work','open'),
  ('work_pet_sitter','pets_animal_services','Pet Sitter',true,'pets_animal_services',60,'work_roles','Work Roles',60,'work','open'),
  ('work_pet_boarding_provider','pets_animal_services','Pet Boarding Provider',true,'pets_animal_services',70,'work_roles','Work Roles',70,'work','optional_proof'),
  ('work_dog_walker','pets_animal_services','Dog Walker',true,'pets_animal_services',80,'work_roles','Work Roles',80,'work','open'),
  ('work_animal_transport_provider','pets_animal_services','Animal Transport Provider',true,'pets_animal_services',90,'work_roles','Work Roles',90,'work','open'),
  ('work_animal_breeder','pets_animal_services','Animal Breeder',true,'pets_animal_services',100,'work_roles','Work Roles',100,'work','optional_proof'),
  ('work_animal_nutritionist','pets_animal_services','Animal Nutritionist',true,'pets_animal_services',110,'work_roles','Work Roles',110,'work','optional_proof')
on conflict (slug) do update set
  category_slug=excluded.category_slug, name=excluded.name, is_active=true,
  ui_group_slug=excluded.ui_group_slug, sort_order=excluded.sort_order,
  service_group_slug=excluded.service_group_slug,
  service_group_name=excluded.service_group_name,
  service_sort_order=excluded.service_sort_order,
  capability_type=excluded.capability_type,
  verification_policy=excluded.verification_policy;

-- Preserve old provider_capabilities and saved role metadata under the same
-- identifiers, while exposing the legacy role only in the new category.
update public.need_capabilities
set category_slug='pets_animal_services', ui_group_slug='pets_animal_services',
    sort_order=15, service_group_slug='work_roles',
    service_group_name='Work Roles', service_sort_order=15, is_active=true
where slug='work_veterinary_livestock_officer';

-- Dog training is already covered by Pet Trainer / Behaviour Specialist,
-- whose animal-kind selector includes dogs. Retire the duplicate catalog
-- entry without deleting its capability or any providers' saved records.
update public.need_capabilities
set is_active=false
where slug='work_dog_trainer';

insert into public.capability_roles
  (slug, category_slug, capability_slug, name, kind_question, is_active)
values
  ('veterinarian','pets_animal_services','work_veterinarian','Veterinarian (clinical care)','What animals do you treat?',true),
  ('veterinary_assistant','pets_animal_services','work_veterinary_assistant','Veterinary Assistant','Which animals can you assist with?',true),
  ('pet_trainer_behaviour_specialist','pets_animal_services','work_pet_trainer_behaviour_specialist','Pet Trainer / Behaviour Specialist','Which animals do you train?',true),
  ('pet_groomer','pets_animal_services','work_pet_groomer','Pet Groomer','Which animals do you groom?',true),
  ('pet_sitter','pets_animal_services','work_pet_sitter','Pet Sitter','Which animals do you care for?',true),
  ('pet_boarding_provider','pets_animal_services','work_pet_boarding_provider','Pet Boarding Provider','Which animals can you accommodate?',true),
  ('dog_walker','pets_animal_services','work_dog_walker','Dog Walker','Which dogs do you walk?',true),
  ('animal_transport_provider','pets_animal_services','work_animal_transport_provider','Animal Transport Provider','What animals can you transport?',true),
  ('animal_breeder','pets_animal_services','work_animal_breeder','Animal Breeder','Which animals do you breed?',true),
  ('animal_nutritionist','pets_animal_services','work_animal_nutritionist','Animal Nutritionist','Which animals do you advise on?',true)
on conflict (slug) do update set
  category_slug=excluded.category_slug, capability_slug=excluded.capability_slug,
  name=excluded.name, kind_question=excluded.kind_question, is_active=true;

update public.capability_roles
set is_active=false
where slug='dog_trainer';

update public.capability_roles
set category_slug='pets_animal_services',
    name='Livestock Officer (herd health)',
    kind_question='Which livestock do you support with herd health and vaccination?', is_active=true
where slug='veterinary_livestock_officer';

insert into public.role_kinds (role_slug, slug, name, sort_order)
select roles.slug, kinds.slug, kinds.name, kinds.sort_order
from (values
  ('veterinarian'),('veterinary_assistant'),('pet_trainer_behaviour_specialist'),
  ('pet_groomer'),('pet_sitter'),('pet_boarding_provider'),
  ('dog_walker'),('animal_transport_provider'),('animal_breeder'),('animal_nutritionist'),
  ('veterinary_livestock_officer')
) roles(slug)
cross join (values
  ('dogs','Dogs',10),('cats','Cats',20),('cattle','Cattle',30),
  ('poultry','Poultry',40),('goats','Goats',50),('sheep','Sheep',60),
  ('rabbits','Rabbits',70),('horses','Horses',80),('other_animals','Other animals',90)
) kinds(slug,name,sort_order)
where (roles.slug in ('veterinarian','veterinary_assistant','animal_breeder','animal_nutritionist')
       or (roles.slug='veterinary_livestock_officer' and kinds.slug in ('cattle','poultry','goats','sheep','rabbits','horses','other_animals'))
       or (roles.slug in ('pet_trainer_behaviour_specialist','pet_groomer') and kinds.slug in ('dogs','cats','other_animals'))
       or (roles.slug in ('pet_sitter','pet_boarding_provider') and kinds.slug in ('dogs','cats','rabbits','other_animals'))
       or (roles.slug='dog_trainer' and kinds.slug='dogs')
       or (roles.slug='dog_walker' and kinds.slug='dogs')
       or (roles.slug='animal_transport_provider' and kinds.slug in ('dogs','cats','cattle','poultry','goats','sheep','horses','other_animals')))
on conflict (role_slug,slug) do update set
  name=excluded.name, sort_order=excluded.sort_order;

delete from public.role_kinds
where role_slug='veterinary_livestock_officer'
  and slug in ('dogs','cats');

insert into public.role_qualifications
  (role_slug,slug,name,is_evidence,is_required_proof,sort_order)
values
  ('veterinarian','veterinary_licence','Veterinary professional registration and authorization',true,true,10),
  ('veterinary_assistant','animal_care_qualification','Animal care qualification',true,false,10),
  ('veterinary_assistant','animal_care_experience','Animal care experience',false,false,20),
  ('pet_trainer_behaviour_specialist','training_qualification','Training qualification',true,false,10),
  ('pet_trainer_behaviour_specialist','training_references','Client references',true,false,20),
  ('pet_trainer_behaviour_specialist','training_experience','Training experience',false,false,30),
  ('dog_trainer','training_qualification','Training qualification',true,false,10),
  ('dog_trainer','training_references','Client references',true,false,20),
  ('dog_trainer','training_experience','Training experience',false,false,30),
  ('pet_boarding_provider','boarding_facility','Boarding facility information',true,false,10),
  ('pet_boarding_provider','animal_welfare_practices','Animal welfare practices',true,false,20),
  ('animal_breeder','breeding_welfare_practices','Breeding and animal welfare practices',true,false,10),
  ('animal_breeder','breeding_authorization','Applicable breeder authorization',true,false,20)
on conflict (role_slug,slug) do update set
  name=excluded.name, is_evidence=excluded.is_evidence,
  is_required_proof=excluded.is_required_proof, sort_order=excluded.sort_order;

-- Retain and extend legacy evidence choices; veterinarian's licence remains a
-- required proof. Optional evidence supports role-specific review in the
-- existing admin verification workflow.
update public.role_qualifications
set is_evidence=true, is_required_proof=false
where role_slug='veterinary_livestock_officer'
  and slug in ('veterinary_licence','vaccination_certification');
update public.role_qualifications
set is_required_proof=true, is_evidence=true
where role_slug='veterinarian' and slug='veterinary_licence';

insert into public.system_settings
  (setting_key,country,setting_value,setting_type,category,description,is_public)
values
  ('work_profiles_enabled_pets_animal_services',null,'true','boolean','provider',
   'Enables role registration for Pets & Animal Services when work profiles are enabled.',true)
on conflict (setting_key,coalesce(country,'__global__')) do update set
  setting_value=excluded.setting_value, setting_type=excluded.setting_type,
  category=excluded.category, description=excluded.description,
  is_public=excluded.is_public, updated_at=now();

-- Match animal requests to the selected work role and declared animal kinds.
-- The existing needs/offer pipeline remains in place; this narrows opportunity
-- notifications and validates offers when an animal_type is supplied.
create or replace function private.pet_animal_kind_slug(p_value text)
returns text
language sql
immutable
as $$
  select case when nullif(btrim(coalesce(p_value,'')),'') is null then null else
    case lower(regexp_replace(btrim(p_value), '\s+', '_', 'g'))
      when 'dog' then 'dogs' when 'dogs' then 'dogs'
      when 'cat' then 'cats' when 'cats' then 'cats'
      when 'cow' then 'cattle' when 'cattle' then 'cattle'
      when 'chicken' then 'poultry' when 'poultry' then 'poultry'
      when 'goat' then 'goats' when 'goats' then 'goats'
      when 'sheep' then 'sheep' when 'rabbit' then 'rabbits'
      when 'rabbits' then 'rabbits' when 'horse' then 'horses'
      when 'horses' then 'horses' when 'other_animals' then 'other_animals'
      else 'other_animals'
    end
  end;
$$;

create or replace function private.trg_notify_matching_providers_on_need_request()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_provider_id uuid;
  v_animal_kind text := private.pet_animal_kind_slug(new.details->>'animal_type');
begin
  for v_provider_id in
    select distinct pc.user_id
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug=pc.capability_slug
    where (
      (new.capability_slug is not null and pc.capability_slug=new.capability_slug)
      or (new.capability_slug is null and nc.category_slug=new.category_slug)
    )
    and pc.user_id <> new.requester_id
    and (
      new.category_slug <> 'pets_animal_services'
      or v_animal_kind is null
      or private.jsonb_text_array(pc.metadata->'kind_ids') @> array[v_animal_kind]
      or (v_animal_kind in ('goats','sheep') and
          private.jsonb_text_array(pc.metadata->'kind_ids') @> array['small_ruminants'])
      or exists (
        select 1
        from jsonb_array_elements(
          case when jsonb_typeof(pc.metadata->'roles')='array'
            then pc.metadata->'roles' else '[]'::jsonb end
        ) role_data
        where private.jsonb_text_array(role_data->'kind_ids') @> array[v_animal_kind]
           or (v_animal_kind in ('goats','sheep') and
               private.jsonb_text_array(role_data->'kind_ids') @> array['small_ruminants'])
      )
    )
  loop
    insert into public.notifications
      (user_id,type,title,body,data,is_read,created_at)
    values
      (v_provider_id,'new_opportunity','New Opportunity',
       coalesce(new.title,'New opportunity'),
       jsonb_build_object('need_id',new.request_id,'category_slug',new.category_slug,
                          'capability_slug',new.capability_slug),false,now());
  end loop;
  return new;
end;
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
  v_role_id text := nullif(btrim(coalesce(p_need_details->>'role_id','')), '');
  v_need_kinds text[] := private.jsonb_text_array(p_need_details->'kind_ids');
  v_animal_kind text := private.pet_animal_kind_slug(p_need_details->>'animal_type');
  v_required_quals text[] := private.jsonb_text_array(p_need_details->'required_qualification_ids');
  v_role jsonb;
  v_role_kinds text[];
  v_role_quals text[];
  v_matched_quals integer := 0;
  v_total_quals integer := coalesce(array_length(v_required_quals,1),0);
begin
  if coalesce(p_need_details->>'engagement','') <> 'hire_person'
     and v_animal_kind is null then return 100; end if;
  -- Work capability saves store one role directly in metadata; support the
  -- nested roles representation used by older profiles as well.
  if p_provider_metadata ? 'role_id' then
    v_role_kinds := private.jsonb_text_array(p_provider_metadata->'kind_ids');
    v_role_quals := private.jsonb_text_array(p_provider_metadata->'qualification_ids');
    if (v_role_id is null or p_provider_metadata->>'role_id'=v_role_id)
       and (v_animal_kind is null or v_animal_kind=any(v_role_kinds)
         or (v_animal_kind in ('goats','sheep') and 'small_ruminants'=any(v_role_kinds)))
       and (coalesce(array_length(v_need_kinds,1),0)=0 or v_need_kinds && v_role_kinds) then
      if v_total_quals=0 then return 100; end if;
      select count(*)::integer into v_matched_quals from unnest(v_required_quals) q where q=any(v_role_quals);
      return round((v_matched_quals::numeric/v_total_quals::numeric)*100)::integer;
    end if;
  end if;
  for v_role in
    select jsonb_array_elements(case when jsonb_typeof(p_provider_metadata->'roles')='array'
      then p_provider_metadata->'roles' else '[]'::jsonb end)
  loop
    if v_role_id is not null and v_role->>'role_id' <> v_role_id then continue; end if;
    v_role_kinds := private.jsonb_text_array(v_role->'kind_ids');
    v_role_quals := private.jsonb_text_array(v_role->'qualification_ids');
    if v_animal_kind is not null
       and not (v_animal_kind = any(v_role_kinds)
         or (v_animal_kind in ('goats','sheep') and 'small_ruminants'=any(v_role_kinds))) then continue; end if;
    if coalesce(array_length(v_need_kinds,1),0)>0 and not (v_need_kinds && v_role_kinds) then continue; end if;
    if v_total_quals=0 then return 100; end if;
    select count(*)::integer into v_matched_quals from unnest(v_required_quals) q where q=any(v_role_quals);
    return round((v_matched_quals::numeric/v_total_quals::numeric)*100)::integer;
  end loop;
  return 0;
end;
$$;

create or replace function private.validate_pet_animal_need_offer()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_need public.needs_requests%rowtype;
  v_capability public.provider_capabilities%rowtype;
begin
  select * into v_need from public.needs_requests where request_id=new.need_id;
  if not found or v_need.category_slug <> 'pets_animal_services'
     or private.pet_animal_kind_slug(v_need.details->>'animal_type') is null then
    return new;
  end if;
  select pc.* into v_capability
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug=pc.capability_slug
  where pc.user_id=new.offer_maker_id
    and nc.category_slug='pets_animal_services'
    and (v_need.capability_slug is null or pc.capability_slug=v_need.capability_slug)
    and private.capability_match_score(v_need.details,coalesce(pc.metadata,'{}'::jsonb))>0
  limit 1;
  if not found then
    raise exception 'Your declared animal specialization does not match this request.'
      using errcode='P0203';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_pet_animal_need_offer on public.need_offers;
create trigger trg_validate_pet_animal_need_offer
  before insert on public.need_offers
  for each row execute function private.validate_pet_animal_need_offer();

commit;
