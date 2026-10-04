-- =============================================================================
-- Driving School / Driver Training capability
-- Adds the capability to Transport & Logistics and validates declared
-- licence-class and transmission metadata on matching need offers.
-- Safe to re-run: catalog and verification rows are upserted by their keys.
-- =============================================================================

begin;

insert into public.need_capabilities
  (slug, category_slug, name, is_active, country_labels)
values (
  'driving_school',
  'transport_logistics',
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
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = excluded.is_active,
  country_labels = excluded.country_labels;

insert into public.verification_requirements (
  scope_type,
  scope_id,
  identity_required,
  phone_required,
  provider_verification_required,
  evidence_requirements,
  is_active
)
values (
  'capability',
  'driving_school',
  true,
  false,
  true,
  '[
    "Driving school license / accreditation",
    "Driving instructor license or certification",
    "Training vehicle registration, roadworthiness, and insurance where applicable"
  ]'::jsonb,
  true
)
on conflict (scope_type, scope_id) do update set
  identity_required = excluded.identity_required,
  phone_required = excluded.phone_required,
  provider_verification_required = excluded.provider_verification_required,
  evidence_requirements = excluded.evidence_requirements,
  is_active = excluded.is_active;

create or replace function private.trg_validate_driving_school_need_offer()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_need record;
  v_provider_metadata jsonb;
  v_requested_class text;
  v_requested_transmission text;
  v_provider_transmission text;
  v_provider_classes jsonb;
  v_class_matched boolean;
begin
  select nr.category_slug, nr.capability_slug, nr.details
  into v_need
  from public.needs_requests nr
  where nr.request_id = new.need_id;

  -- The existing offer-validation trigger reports a missing request.
  if not found or v_need.capability_slug is distinct from 'driving_school' then
    return new;
  end if;

  select pc.metadata
  into v_provider_metadata
  from public.provider_capabilities pc
  where pc.user_id = new.offer_maker_id
    and pc.capability_slug = 'driving_school';

  -- The existing offer-validation trigger reports a missing capability.
  if not found then
    return new;
  end if;

  v_requested_class := coalesce(
    nullif(btrim(v_need.details->>'licence_class'), ''),
    nullif(btrim(v_need.details->>'license_class'), '')
  );
  v_requested_transmission := nullif(
    btrim(v_need.details->>'transmission'),
    ''
  );
  v_provider_classes := coalesce(
    v_provider_metadata->'licence_classes',
    v_provider_metadata->'license_classes'
  );
  v_provider_transmission := nullif(
    btrim(v_provider_metadata->>'transmission'),
    ''
  );

  if v_requested_class is not null
     and lower(v_requested_class) not in ('either', 'any') then
    select exists (
      select 1
      from jsonb_array_elements_text(
        case
          when jsonb_typeof(v_provider_classes) = 'array'
            then v_provider_classes
          else '[]'::jsonb
        end
      ) as declared(class_name)
      where lower(btrim(regexp_replace(
              regexp_replace(declared.class_name, '\s*\([^)]*\)\s*$', '', 'i'),
              '^class\s+', '', 'i'
            ))) =
            lower(btrim(regexp_replace(
              regexp_replace(v_requested_class, '\s*\([^)]*\)\s*$', '', 'i'),
              '^class\s+', '', 'i'
            )))
    ) into v_class_matched;

    if not v_class_matched then
      raise exception
        'Your Driving School service does not cover the requested licence class (%)',
        v_requested_class
        using errcode = 'P0203';
    end if;
  end if;

  if v_requested_transmission is not null
     and lower(v_requested_transmission) not in ('either', 'any')
     and v_provider_transmission is not null
     and lower(v_provider_transmission) not in ('both', 'either', 'any')
     and lower(v_provider_transmission) <> lower(v_requested_transmission) then
    raise exception
      'Your Driving School service transmission (%) does not match the requested transmission (%)',
      v_provider_transmission,
      v_requested_transmission
      using errcode = 'P0203';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_need_offer_driving_school
  on public.need_offers;
create trigger trg_validate_need_offer_driving_school
  before insert on public.need_offers
  for each row
  execute function private.trg_validate_driving_school_need_offer();

grant select on public.need_capabilities to anon, authenticated;

commit;
