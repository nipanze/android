-- Part B follow-up: require approved financial capability proof for Companies
-- (Individuals do not require capability proof) and expose Company logos.
-- Apply after patch_loan_products.sql and the Financial Services provider
-- identity / verification / company-logo patches.

begin;

create or replace function private.guard_loan_product_activation()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if new.status <> 'active' then
    return new;
  end if;

  if not private.loan_products_feature_enabled(new.provider_id) then
    raise exception 'Provider loan products are disabled.' using errcode = 'P0216';
  end if;

  if not exists (
    select 1
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    join public.provider_category_profiles pcp
      on pcp.user_id = pc.user_id
     and pcp.category_slug = nc.category_slug
    where pc.id = new.provider_capability_id
      and pc.user_id = new.provider_id
      and pc.identity_type = new.identity_type
      and pcp.provider_type = new.identity_type
      and nc.category_slug = 'financial_services'
      and pc.is_active
      and (
        new.identity_type = 'individual'
        or (
          pc.verification_level = 'provider_verified'
          and private.provider_capability_is_eligible(pc.id)
        )
      )
  ) then
    raise exception 'Choose a Financial Services capability under this identity; Company capabilities must have approved proof.'
      using errcode = 'P0216';
  end if;

  return new;
end;
$$;

revoke all on function private.guard_loan_product_activation() from public, anon, authenticated;
drop trigger if exists trg_guard_loan_product_activation on public.loan_products;
create trigger trg_guard_loan_product_activation
  before insert or update of status, provider_capability_id, identity_type
  on public.loan_products
  for each row execute function private.guard_loan_product_activation();

create or replace function private.loan_product_logo_is_public(p_object_name text)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1
    from public.provider_company_profiles cp
    join public.provider_category_profiles pcp
      on pcp.user_id = cp.user_id and pcp.category_slug = cp.category_slug
    join public.loan_products lp
      on lp.provider_id = cp.user_id and lp.identity_type = 'company'
    join public.provider_capabilities pc
      on pc.id = lp.provider_capability_id
    where cp.category_slug = 'financial_services'
      and cp.logo_path = p_object_name
      and pcp.provider_type = 'company'
      and lp.status = 'active'
      and private.loan_products_feature_enabled(lp.provider_id)
      and pc.is_active
      and pc.verification_level = 'provider_verified'
      and private.provider_capability_is_eligible(pc.id)
  );
$$;

revoke all on function private.loan_product_logo_is_public(text) from public;
grant execute on function private.loan_product_logo_is_public(text) to anon, authenticated;
drop policy if exists financial_loan_product_logo_marketplace_read on storage.objects;
create policy financial_loan_product_logo_marketplace_read
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'provider-evidence'
    and private.loan_product_logo_is_public(name)
  );

create or replace view public.v_active_loan_products
with (security_barrier = true) as
select lp.id, lp.identity_type, lp.category_slug, lc.name as category_name,
  lp.purpose_slug, pu.name as purpose_name, lp.product_title,
  lp.short_description, lp.minimum_amount, lp.maximum_amount,
  lp.currency_code, lp.terms, lp.is_featured, lp.published_at,
  lp.views_count, lp.enquiries_count,
  case when lp.identity_type = 'company' then cp.company_name
       else coalesce(ip.display_name, pr.full_name, 'Individual provider')
  end as provider_name,
  case when lp.identity_type = 'company' then cp.logo_path else null end
    as provider_logo_url,
  pc.verification_level = 'provider_verified' as provider_verified
from public.loan_products lp
join public.loan_product_categories lc on lc.slug = lp.category_slug
join public.loan_product_purposes pu
  on pu.category_slug = lp.category_slug and pu.slug = lp.purpose_slug
join public.provider_capabilities pc on pc.id = lp.provider_capability_id
left join public.provider_category_profiles pcp
  on pcp.user_id = lp.provider_id and pcp.category_slug = 'financial_services'
left join public.provider_company_profiles cp
  on cp.user_id = lp.provider_id and cp.category_slug = 'financial_services'
left join public.provider_identity_presentations ip
  on ip.user_id = lp.provider_id
 and ip.category_slug = 'financial_services'
 and ip.identity_type = 'individual'
left join public.profiles pr on pr.id = lp.provider_id
where lp.status = 'active'
  and private.loan_products_feature_enabled(lp.provider_id)
  and pcp.provider_type = lp.identity_type
  and pc.identity_type = lp.identity_type
  and pc.is_active
  and (
    lp.identity_type = 'individual'
    or (
      pc.verification_level = 'provider_verified'
      and private.provider_capability_is_eligible(pc.id)
    )
  );

grant select on public.v_active_loan_products to anon, authenticated;

commit;
notify pgrst, 'reload schema';
