-- Keep the company category save RPC aligned with the Flutter client. Apply
-- after patch_financial_services_provider_capabilities.sql and
-- patch_provider_identity_switch.sql. The app passes six named RPC arguments
-- and saves the company profile, service selection, and identity presentation
-- in one transaction.
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

  perform private.set_provider_category_type_internal(p_category_slug, 'company');
  if p_category_slug = 'financial_services' then
    perform private.save_financial_company_category_internal(
      p_category_slug, p_services, p_roles, p_profile, p_evidence);
  else
    perform private.save_company_category_internal(
      p_category_slug, p_services, p_roles, p_profile, p_evidence);
  end if;

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

commit;
