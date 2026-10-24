-- Keep the company name in provider_company_profiles and commit the company
-- profile plus identity presentation in one RPC transaction.
-- Apply after patch_company_provider_path.sql and patch_provider_identity_switch.sql.
begin;

create or replace function public.save_company_category(
  p_category_slug text,
  p_services text[],
  p_roles text[],
  p_profile jsonb,
  p_evidence jsonb,
  p_presentation jsonb
) returns void
language plpgsql security invoker
set search_path = public, private, pg_temp
as $$
declare
  v_name text := btrim(coalesce(p_profile->>'company_name', ''));
  v_mode text := coalesce(p_presentation->>'display_mode', 'company');
  v_rep text := btrim(coalesce(p_presentation->>'representative_name', ''));
  v_authorized boolean := coalesce(
    (p_presentation->>'representative_authorized')::boolean, false);
  v_presentation jsonb;
begin
  if v_name = '' then
    raise exception 'Company name is required.' using errcode = 'P0217';
  end if;
  if char_length(v_name) > 80 then
    raise exception 'Company name must be 80 characters or fewer.' using errcode = 'P0218';
  end if;
  if v_mode not in ('company', 'company_with_representative') then
    raise exception 'Invalid company display mode.' using errcode = 'P0216';
  end if;
  if v_mode = 'company_with_representative'
     and (v_rep = '' or not v_authorized) then
    raise exception 'Representative name and authorization are required.'
      using errcode = 'P0219';
  end if;

  -- For first-time setup this creates the selected identity inside this same
  -- transaction. Existing company profiles pass through unchanged.
  perform private.set_provider_category_type_internal(p_category_slug, 'company');
  perform private.save_company_category_internal(
    p_category_slug, p_services, p_roles, p_profile, p_evidence);

  v_presentation := coalesce(p_presentation, '{}'::jsonb) || jsonb_build_object(
    'display_mode', v_mode,
    'display_name', v_name,
    'representative_name', case when v_mode = 'company_with_representative'
      then v_rep else null end,
    'representative_authorized', case when v_mode = 'company_with_representative'
      then v_authorized else false end);
  perform private.save_provider_identity_presentation_internal(
    p_category_slug, 'company', v_presentation);
end;
$$;

revoke all on function public.save_company_category(text,text[],text[],jsonb,jsonb,jsonb)
  from public, anon;
grant execute on function public.save_company_category(text,text[],text[],jsonb,jsonb,jsonb)
  to authenticated;

-- Identity switches also save their company name into the canonical company
-- profile row in the same transaction as the identity presentation.
create or replace function public.switch_provider_identity(
  p_category_slug text,
  p_to_identity text,
  p_presentation jsonb
) returns jsonb
language plpgsql security definer
set search_path = public, private, pg_temp
as $$
declare
  v_name text := btrim(coalesce(p_presentation->>'display_name', ''));
  v_result jsonb;
begin
  if p_to_identity = 'company' then
    if v_name = '' then
      raise exception 'Company name is required.' using errcode = 'P0217';
    end if;
    if char_length(v_name) > 80 then
      raise exception 'Company name must be 80 characters or fewer.' using errcode = 'P0218';
    end if;
  end if;

  v_result := private.switch_provider_identity_internal(
    p_category_slug, p_to_identity, p_presentation);

  if p_to_identity = 'company' then
    insert into public.provider_company_profiles(user_id, category_slug, company_name)
    values (auth.uid(), p_category_slug, v_name)
    on conflict (user_id, category_slug) do update
      set company_name = excluded.company_name, updated_at = now();
  end if;
  return v_result;
end;
$$;

revoke all on function public.switch_provider_identity(text,text,jsonb)
  from public, anon;
grant execute on function public.switch_provider_identity(text,text,jsonb)
  to authenticated;

commit;
