-- =============================================================================
-- Standalone Supabase patch: allow an authenticated provider to remove their
-- own service or work capability from Provider Services.
-- Safe to re-run. Does not grant direct DELETE access to the table.
-- =============================================================================

begin;

create or replace function public.remove_provider_capability(
  p_capability_slug text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated'
      using errcode = '42501';
  end if;

  if p_capability_slug is null or btrim(p_capability_slug) = '' then
    raise exception 'Capability slug is required'
      using errcode = '22023';
  end if;

  delete from public.provider_capabilities
  where user_id = v_user_id
    and capability_slug = p_capability_slug;
end;
$$;

revoke all on function public.remove_provider_capability(text)
  from public, anon;
grant execute on function public.remove_provider_capability(text)
  to authenticated;

commit;
