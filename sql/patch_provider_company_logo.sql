-- Persist optional company logos in the private provider-evidence bucket.
begin;

alter table public.provider_company_profiles
  add column if not exists logo_path text;

create or replace function public.save_provider_company_logo(
  p_category_slug text,
  p_logo_path text
) returns void
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_old_path text;
  v_size bigint;
  v_mime text;
  v_expected_prefix text;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  v_expected_prefix := 'evidence/' || v_user::text || '/' ||
    p_category_slug || '/company/logo/';
  if p_logo_path is null or p_logo_path not like v_expected_prefix || '%' then
    raise exception 'Company logo path is invalid.' using errcode = 'P0204';
  end if;
  if not exists (
    select 1 from public.provider_category_profiles p
    where p.user_id = v_user and p.category_slug = p_category_slug
      and p.provider_type = 'company'
  ) then
    raise exception 'Choose Company / Organization for this category first.'
      using errcode = 'P0202';
  end if;

  select (o.metadata->>'size')::bigint, lower(coalesce(o.metadata->>'mimetype', ''))
    into v_size, v_mime
    from storage.objects o
    where o.bucket_id = 'provider-evidence'
      and o.name = p_logo_path
      and o.owner_id = v_user::text;
  if not found or v_size is null or v_size < 1 or v_size > 2097152
      or v_mime not in ('image/jpeg', 'image/png') then
    raise exception 'Company logos must be JPG or PNG files no larger than 2 MB.'
      using errcode = 'P0205';
  end if;

  select logo_path into v_old_path
    from public.provider_company_profiles
    where user_id = v_user and category_slug = p_category_slug
    for update;
  update public.provider_company_profiles
    set logo_path = p_logo_path, updated_at = now()
    where user_id = v_user and category_slug = p_category_slug;

  if v_old_path is not null and v_old_path <> p_logo_path
      and v_old_path like v_expected_prefix || '%' then
    delete from storage.objects
      where bucket_id = 'provider-evidence'
        and name = v_old_path and owner_id = v_user::text;
  end if;
end;
$$;

revoke all on function public.save_provider_company_logo(text, text)
  from public, anon;
grant execute on function public.save_provider_company_logo(text, text)
  to authenticated;

commit;
