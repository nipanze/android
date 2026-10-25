-- Finish a company identity switch and save its details without requiring
-- service selections. Apply after patch_company_provider_path.sql,
-- patch_provider_identity_switch.sql, patch_provider_company_name_single_source.sql,
-- and patch_provider_company_logo.sql.
begin;

create or replace function public.complete_provider_company_identity_switch(
  p_category_slug text,
  p_profile jsonb,
  p_presentation jsonb,
  p_logo_path text default null
) returns void
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_name text := btrim(coalesce(p_profile->>'company_name', ''));
  v_registration text := nullif(btrim(coalesce(p_profile->>'registration_number', '')), '');
  v_team_size text := nullif(p_profile->>'team_size', '');
  v_years text := nullif(p_profile->>'years_in_business', '');
  v_areas text[] := array[]::text[];
  v_old_logo text;
  v_size bigint;
  v_mime text;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  if jsonb_typeof(coalesce(p_profile, '{}'::jsonb)) <> 'object'
      or jsonb_typeof(coalesce(p_presentation, '{}'::jsonb)) <> 'object' then
    raise exception 'Company profile details are invalid.' using errcode = 'P0204';
  end if;
  if v_name = '' then
    raise exception 'Company name is required.' using errcode = 'P0217';
  end if;
  if char_length(v_name) > 80 or char_length(coalesce(v_registration, '')) > 40
      or (v_team_size is not null and v_team_size not in ('1-5','6-20','21-50','50+'))
      or (v_years is not null and v_years not in ('<1','1-2','3-5','6-10','10+'))
      or jsonb_typeof(coalesce(p_profile->'service_areas', '[]'::jsonb)) <> 'array' then
    raise exception 'Company profile details are invalid.' using errcode = 'P0204';
  end if;
  select coalesce(array_agg(distinct btrim(value)), array[]::text[])
    into v_areas
    from jsonb_array_elements_text(coalesce(p_profile->'service_areas', '[]'::jsonb)) x(value)
    where btrim(value) <> '';
  if exists(select 1 from unnest(v_areas) area where char_length(area) > 80) then
    raise exception 'Service areas must be district or city names.' using errcode = 'P0204';
  end if;

  if p_logo_path is not null then
    if p_logo_path not like
        'evidence/' || v_user::text || '/' || p_category_slug || '/company/logo/%' then
      raise exception 'Company logo path is invalid.' using errcode = 'P0204';
    end if;
    select (o.metadata->>'size')::bigint,
        lower(coalesce(o.metadata->>'mimetype', ''))
      into v_size, v_mime
      from storage.objects o
      where o.bucket_id = 'provider-evidence'
        and o.name = p_logo_path and o.owner_id = v_user::text;
    if not found or v_size is null or v_size < 1 or v_size > 2097152
        or v_mime not in ('image/jpeg', 'image/png') then
      raise exception 'Company logos must be JPG or PNG files no larger than 2 MB.'
        using errcode = 'P0205';
    end if;
  end if;

  perform public.switch_provider_identity(
    p_category_slug, 'company',
    coalesce(p_presentation, '{}'::jsonb) ||
      jsonb_build_object('display_name', v_name));

  select logo_path into v_old_logo
    from public.provider_company_profiles
    where user_id = v_user and category_slug = p_category_slug
    for update;
  insert into public.provider_company_profiles(
    user_id, category_slug, company_name, registration_number, team_size,
    years_in_business, service_areas, logo_path
  ) values (
    v_user, p_category_slug, v_name, v_registration, v_team_size,
    v_years, v_areas, p_logo_path
  )
  on conflict(user_id, category_slug) do update set
    company_name = excluded.company_name,
    registration_number = excluded.registration_number,
    team_size = excluded.team_size,
    years_in_business = excluded.years_in_business,
    service_areas = excluded.service_areas,
    logo_path = coalesce(excluded.logo_path, provider_company_profiles.logo_path),
    updated_at = now();

  if p_logo_path is not null and v_old_logo is not null
      and v_old_logo <> p_logo_path then
    delete from storage.objects
      where bucket_id = 'provider-evidence'
        and name = v_old_logo and owner_id = v_user::text;
  end if;
end;
$$;

revoke all on function public.complete_provider_company_identity_switch(
  text, jsonb, jsonb, text
) from public, anon;
grant execute on function public.complete_provider_company_identity_switch(
  text, jsonb, jsonb, text
) to authenticated;

commit;
