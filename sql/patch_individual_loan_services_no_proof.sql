-- Individual Financial Services are active without service evidence.
-- Company Financial Services keep the existing proof and review requirements.
-- Apply in Supabase SQL Editor after patch_financial_services_provider_capabilities.sql.
-- Safe to re-run.

begin;

do $$
begin
  if to_regclass('public.provider_capabilities') is null
     or to_regclass('public.need_capabilities') is null then
    raise exception 'Provider capability tables are missing. Apply the Financial Services provider patch first.';
  end if;
end;
$$;

create or replace function private.activate_individual_financial_service_without_proof()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if new.identity_type = 'individual' and exists (
    select 1
    from public.need_capabilities nc
    where nc.slug = new.capability_slug
      and nc.category_slug = 'financial_services'
      and nc.capability_type = 'service'
      and nc.is_active
  ) then
    new.is_active := true;
  end if;
  return new;
end;
$$;

drop trigger if exists zz_activate_individual_financial_service_without_proof
  on public.provider_capabilities;
create trigger zz_activate_individual_financial_service_without_proof
  before insert or update of is_active, verification_level, identity_type, capability_slug
  on public.provider_capabilities
  for each row
  execute function private.activate_individual_financial_service_without_proof();

-- Re-evaluate existing Individual service rows through the policy triggers.
update public.provider_capabilities pc
set is_active = true
from public.need_capabilities nc
where nc.slug = pc.capability_slug
  and nc.category_slug = 'financial_services'
  and nc.capability_type = 'service'
  and pc.identity_type = 'individual';

commit;
