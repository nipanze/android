-- Part C: capability coverage, request matching, provider notifications and
-- product enquiries. Apply after Part B and the Financial Services patches.

begin;

create table if not exists public.financial_capability_loan_product_coverage (
  capability_slug text not null references public.need_capabilities(slug) on delete cascade,
  category_slug text not null,
  purpose_slug text not null,
  primary key(capability_slug,category_slug,purpose_slug),
  foreign key(category_slug,purpose_slug)
    references public.loan_product_purposes(category_slug,slug) on delete cascade
);
alter table public.financial_capability_loan_product_coverage enable row level security;
revoke all on public.financial_capability_loan_product_coverage from public,anon,authenticated;
grant select on public.financial_capability_loan_product_coverage to authenticated;
drop policy if exists financial_loan_coverage_read on public.financial_capability_loan_product_coverage;
create policy financial_loan_coverage_read on public.financial_capability_loan_product_coverage
  for select to authenticated using(private.loan_products_feature_enabled());
grant insert,update,delete on public.financial_capability_loan_product_coverage to authenticated;
drop policy if exists financial_loan_coverage_admin_write on public.financial_capability_loan_product_coverage;
create policy financial_loan_coverage_admin_write on public.financial_capability_loan_product_coverage
  for all to authenticated using(private.is_admin()) with check(private.is_admin());

insert into public.financial_capability_loan_product_coverage values
 ('personal_loan_services','personal','general_personal_expenses'),
 ('personal_loan_services','personal','family_support'),
 ('personal_loan_services','personal','debt_consolidation'),
 ('personal_loan_services','personal','other_personal_needs'),
 ('emergency_loan_services','personal','general_personal_expenses'),
 ('emergency_loan_services','personal','medical_expenses'),
 ('salary_loan_services','personal','salary_advance'),
 ('medical_financing','personal','medical_expenses'),
 ('business_startup_financing','business','business_startup'),
 ('working_capital_financing','business','working_capital'),
 ('working_capital_financing','business','inventory_stock_purchase'),
 ('business_expansion_financing','business','business_expansion'),
 ('sme_financing','business','business_startup'),
 ('sme_financing','business','business_expansion'),
 ('sme_financing','business','working_capital'),
 ('sme_financing','business','inventory_stock_purchase'),
 ('sme_financing','business','equipment_for_business'),
 ('sme_financing','business','contract_financing'),
 ('sme_financing','business','invoice_financing'),
 ('sme_financing','business','other_business_needs'),
 ('boda_boda_financing','asset_financing','boda_boda'),
 ('car_financing','asset_financing','car'),
 ('tuk_tuk_financing','asset_financing','tuk_tuk'),
 ('motorcycle_financing','asset_financing','motorcycle'),
 ('smartphone_financing','asset_financing','smartphone'),
 ('laptop_financing','asset_financing','laptop'),
 ('heavy_machinery_financing','asset_financing','heavy_machinery'),
 ('equipment_financing','business','equipment_for_business'),
 ('equipment_financing','asset_financing','other_asset_financing'),
 ('agricultural_loan_services','agricultural','crop_production'),
 ('agricultural_loan_services','agricultural','greenhouse_farming'),
 ('agricultural_loan_services','agricultural','livestock'),
 ('agricultural_loan_services','agricultural','poultry_farming'),
 ('agricultural_loan_services','agricultural','farm_inputs'),
 ('agricultural_loan_services','agricultural','irrigation'),
 ('agricultural_loan_services','agricultural','tractor_financing'),
 ('agricultural_loan_services','agricultural','agricultural_equipment'),
 ('agricultural_loan_services','agricultural','other_agricultural_needs'),
 ('livestock_financing','agricultural','livestock'),
 ('livestock_financing','agricultural','poultry_farming'),
 ('crop_financing','agricultural','crop_production'),
 ('crop_financing','agricultural','farm_inputs'),
 ('crop_financing','agricultural','greenhouse_farming'),
 ('crop_financing','agricultural','irrigation'),
 ('farm_equipment_financing','agricultural','tractor_financing'),
 ('farm_equipment_financing','agricultural','agricultural_equipment'),
 ('farm_equipment_financing','asset_financing','agricultural_equipment'),
 ('mortgage_financing','property','mortgage_financing'),
 ('mortgage_financing','property','home_construction'),
 ('mortgage_financing','property','home_improvement'),
 ('land_financing','property','land_purchase'),
 ('property_development_financing','property','property_development'),
 ('property_development_financing','property','commercial_property'),
 ('school_fees_financing','education','school_fees'),
 ('university_financing','education','university_tuition'),
 ('education_loan_services','education','school_fees'),
 ('education_loan_services','education','university_tuition'),
 ('education_loan_services','education','vocational_training'),
 ('education_loan_services','education','professional_courses'),
 ('education_loan_services','education','study_abroad'),
 ('education_loan_services','education','educational_equipment'),
 ('education_loan_services','education','other_education_needs'),
 ('travel_financing','lifestyle','travel_holiday'),
 ('wedding_financing','lifestyle','wedding_expenses'),
 ('other_lifestyle_financing','lifestyle','events_celebrations'),
 ('other_lifestyle_financing','lifestyle','family_events'),
 ('other_lifestyle_financing','lifestyle','relocation_expenses'),
 ('other_lifestyle_financing','lifestyle','other_lifestyle_needs')
on conflict do nothing;

-- Only products whose linked capability covers their exact purpose are
-- publicly browseable. Individual products need no capability proof;
-- Company products still require approved proof.
create or replace view public.v_active_loan_products with(security_barrier=true) as
select lp.id,lp.identity_type,lp.category_slug,lc.name as category_name,
  lp.purpose_slug,pu.name as purpose_name,lp.product_title,lp.short_description,
  lp.minimum_amount,lp.maximum_amount,lp.currency_code,lp.terms,lp.is_featured,
  lp.published_at,lp.views_count,lp.enquiries_count,
  case when lp.identity_type='company' then cp.company_name
       else coalesce(ip.display_name,pr.full_name,'Individual provider') end as provider_name,
  case when lp.identity_type='company' then cp.logo_path else null end as provider_logo_url,
  pc.verification_level='provider_verified' as provider_verified
from public.loan_products lp
join public.loan_product_categories lc on lc.slug=lp.category_slug
join public.loan_product_purposes pu on pu.category_slug=lp.category_slug and pu.slug=lp.purpose_slug
join public.provider_capabilities pc on pc.id=lp.provider_capability_id
join public.provider_category_profiles pcp on pcp.user_id=lp.provider_id
  and pcp.category_slug='financial_services' and pcp.provider_type=lp.identity_type
left join public.provider_company_profiles cp on cp.user_id=lp.provider_id
  and cp.category_slug='financial_services'
left join public.provider_identity_presentations ip on ip.user_id=lp.provider_id
  and ip.category_slug='financial_services' and ip.identity_type='individual'
left join public.profiles pr on pr.id=lp.provider_id
where lp.status='active' and private.loan_products_feature_enabled(lp.provider_id)
  and pc.user_id=lp.provider_id and pc.identity_type=lp.identity_type and pc.is_active
  and exists(select 1 from public.financial_capability_loan_product_coverage cov
    where cov.capability_slug=pc.capability_slug and cov.category_slug=lp.category_slug
      and cov.purpose_slug=lp.purpose_slug)
  and (lp.identity_type='individual' or
    (pc.verification_level='provider_verified' and private.provider_capability_is_eligible(pc.id)));
grant select on public.v_active_loan_products to anon,authenticated;

create or replace function private.guard_loan_product_coverage()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
begin
  if new.status <> 'active' then return new; end if;
  if not exists (
    select 1 from public.provider_capabilities pc
    join public.financial_capability_loan_product_coverage cov
      on cov.capability_slug=pc.capability_slug
    where pc.id=new.provider_capability_id and pc.user_id=new.provider_id
      and pc.identity_type=new.identity_type
      and cov.category_slug=new.category_slug and cov.purpose_slug=new.purpose_slug
  ) then
    raise exception 'This Financial Services capability does not cover the selected loan purpose.'
      using errcode='P0216';
  end if;
  return new;
end;
$$;
revoke all on function private.guard_loan_product_coverage() from public,anon,authenticated;
drop trigger if exists trg_guard_loan_product_coverage on public.loan_products;
create trigger trg_guard_loan_product_coverage
  before insert or update of status,provider_capability_id,category_slug,purpose_slug
  on public.loan_products for each row execute function private.guard_loan_product_coverage();

alter table public.loan_requests
  add column if not exists loan_category text,
  add column if not exists loan_purpose text;
create index if not exists idx_loan_requests_product_pair
  on public.loan_requests(loan_category,loan_purpose,status);

create or replace function private.loan_product_term_number(p_terms jsonb,p_key text)
returns numeric language plpgsql immutable
set search_path=pg_catalog as $$
begin
  if coalesce(p_terms->>p_key,'') !~ '^-?[0-9]+([.][0-9]+)?$' then return null; end if;
  return (p_terms->>p_key)::numeric;
exception when others then return null;
end;
$$;
revoke all on function private.loan_product_term_number(jsonb,text) from public,anon,authenticated;

create or replace function private.guard_structured_loan_request_classification()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
begin
  if new.status::text='active' and private.loan_products_feature_enabled(new.borrower_id) then
    if new.loan_category is null or new.loan_purpose is null then
      raise exception 'Choose a loan category and purpose so providers can match suitable products.'
        using errcode='22023';
    end if;
    if not exists(select 1 from public.loan_product_purposes p
      join public.loan_product_categories c on c.slug=p.category_slug
      where p.category_slug=new.loan_category and p.slug=new.loan_purpose
        and p.is_active and c.is_active) then
      raise exception 'Choose an active loan purpose from the selected category.'
        using errcode='22023';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function private.guard_structured_loan_request_classification() from public,anon,authenticated;
drop trigger if exists trg_guard_structured_loan_request_classification on public.loan_requests;
create trigger trg_guard_structured_loan_request_classification
  before insert or update of status,loan_category,loan_purpose on public.loan_requests
  for each row execute function private.guard_structured_loan_request_classification();

create table if not exists public.loan_product_match_notifications (
  provider_id uuid not null references public.profiles(id) on delete cascade,
  request_id uuid not null references public.loan_requests(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(provider_id,request_id)
);
alter table public.loan_product_match_notifications enable row level security;
revoke all on public.loan_product_match_notifications from public,anon,authenticated;

create or replace function private.loan_product_matches_request(
  p_product public.loan_products,p_request public.loan_requests
) returns boolean language sql stable security definer
set search_path=public,private,pg_temp as $$
  select p_product.status='active' and p_request.status='active'
    and p_request.borrower_id<>p_product.provider_id
    and p_request.loan_category=p_product.category_slug
    and p_request.loan_purpose=p_product.purpose_slug
    and p_request.requested_amount between p_product.minimum_amount and p_product.maximum_amount
    and p_product.currency_code=(select c.currency_code from public.countries c where c.code=p_request.country)
    and coalesce(p_product.terms->>'repayment_frequency','') in
      (p_request.preferred_repayment_plan,'custom')
    and case coalesce(p_product.terms->>'period_unit','month')
      when 'day' then p_request.duration_months*30 between
        coalesce(private.loan_product_term_number(p_product.terms,'minimum_period'),0)
        and coalesce(private.loan_product_term_number(p_product.terms,'maximum_period'),2147483647)
      when 'week' then p_request.duration_months*4.35 between
        coalesce(private.loan_product_term_number(p_product.terms,'minimum_period'),0)
        and coalesce(private.loan_product_term_number(p_product.terms,'maximum_period'),2147483647)
      when 'year' then p_request.duration_months/12.0 between
        coalesce(private.loan_product_term_number(p_product.terms,'minimum_period'),0)
        and coalesce(private.loan_product_term_number(p_product.terms,'maximum_period'),2147483647)
      else p_request.duration_months between
        coalesce(private.loan_product_term_number(p_product.terms,'minimum_period'),0)
        and coalesce(private.loan_product_term_number(p_product.terms,'maximum_period'),2147483647)
    end
    and (coalesce(p_product.terms->>'secured','false')<>'true' or p_request.has_collateral)
    and (
      coalesce(private.loan_product_term_number(p_product.terms,'minimum_income'),0)=0
      or exists (
        select 1 from public.borrower_information bi
        where bi.user_id=p_request.borrower_id
          and bi.income_currency=p_product.currency_code
          and case bi.monthly_income_range
            when 'no_regular_income' then 0
            when 'under_500k' then 0
            when '500k_1m' then 500000
            when '1m_2m' then 1000000
            when '2m_3m' then 2000000
            when 'over_3m' then 3000000
          end >= private.loan_product_term_number(p_product.terms,'minimum_income')
      )
    )
    and (
      coalesce(nullif(btrim(p_product.terms->>'employment_requirement'),''),'any') in ('any','Any','all','All')
      or exists (
        select 1 from public.borrower_information bi
        where bi.user_id=p_request.borrower_id
          and (lower(p_product.terms->>'employment_requirement') like '%' ||
            replace(bi.employment_status,'_',' ') || '%'
            or lower(p_product.terms->>'employment_requirement') like '%' ||
              replace(bi.employment_status,'_','%') || '%')
      )
    )
    and (coalesce(jsonb_array_length(p_product.terms->'eligible_locations'),0)=0
      or (jsonb_typeof(p_product.terms->'eligible_locations')='array'
        and exists(select 1 from jsonb_array_elements_text(p_product.terms->'eligible_locations') loc
          where lower(loc) in (lower(p_request.district),lower(p_request.country)))))
    and not private.is_blocked_from_future_request(p_request.borrower_id,p_product.provider_id,p_request.listed_at)
    and not exists(select 1 from public.loan_offers lo
      where lo.request_id=p_request.id and lo.lender_id=p_product.provider_id
        and lo.status in ('pending','accepted'))
    and exists(select 1 from public.provider_capabilities pc
      join public.financial_capability_loan_product_coverage cov on cov.capability_slug=pc.capability_slug
      join public.provider_category_profiles pcp on pcp.user_id=pc.user_id
        and pcp.category_slug='financial_services' and pcp.provider_type=pc.identity_type
      where pc.id=p_product.provider_capability_id and pc.user_id=p_product.provider_id and pc.is_active
        and private.loan_products_feature_enabled(pc.user_id)
        and exists(select 1 from public.provider_category_profiles pcp
          where pcp.user_id=pc.user_id and pcp.category_slug='financial_services'
            and pcp.provider_type=pc.identity_type)
        and cov.category_slug=p_request.loan_category and cov.purpose_slug=p_request.loan_purpose
        and (pc.identity_type='individual' or
          (pc.verification_level='provider_verified' and private.provider_capability_is_eligible(pc.id))))
$$;
revoke all on function private.loan_product_matches_request(public.loan_products,public.loan_requests)
  from public,anon,authenticated;

create or replace function public.get_my_loan_product_matches(p_product_id uuid default null)
returns table(product_id uuid,product_title text,request_id uuid,request_title text,
  category_slug text,purpose_slug text,country text,currency_code text,district text,
  requested_amount bigint,preferred_repayment_plan text,duration_months integer,
  has_collateral boolean,listed_at timestamp)
language plpgsql security definer set search_path=public,private,pg_temp as $$
begin
  if auth.uid() is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(auth.uid()) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  return query select lp.id,lp.product_title,lr.id,lr.title,lr.loan_category,lr.loan_purpose,
    lr.country,c.currency_code,lr.district,lr.requested_amount,lr.preferred_repayment_plan,
    lr.duration_months,lr.has_collateral,lr.listed_at
  from public.loan_products lp
  join public.loan_requests lr on private.loan_product_matches_request(lp,lr)
  join public.countries c on c.code=lr.country
  where lp.provider_id=auth.uid() and lp.status='active'
    and (p_product_id is null or lp.id=p_product_id)
  order by lr.listed_at desc;
end;
$$;
revoke all on function public.get_my_loan_product_matches(uuid) from public,anon;
grant execute on function public.get_my_loan_product_matches(uuid) to authenticated;

create or replace function public.get_matching_products_for_request(p_request_id uuid)
returns table(product_id uuid,identity_type text,provider_name text,product_title text,
  category_name text,purpose_name text,minimum_amount bigint,maximum_amount bigint,
  currency_code text,terms jsonb,provider_verified boolean)
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_request public.loan_requests%rowtype;
begin
  if auth.uid() is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(auth.uid()) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  select * into v_request from public.loan_requests
    where id=p_request_id and borrower_id=auth.uid() and status='active';
  if not found then raise exception 'Active request not found.' using errcode='P0212'; end if;
  return query
  select lp.id,lp.identity_type,
    case when lp.identity_type='company' then cp.company_name
      else coalesce(ip.display_name,pr.full_name,'Individual provider') end,
    lp.product_title,lc.name,pu.name,lp.minimum_amount,lp.maximum_amount,
    lp.currency_code,lp.terms,pc.verification_level='provider_verified'
  from public.loan_products lp
  join public.loan_product_categories lc on lc.slug=lp.category_slug
  join public.loan_product_purposes pu on pu.category_slug=lp.category_slug and pu.slug=lp.purpose_slug
  join public.provider_capabilities pc on pc.id=lp.provider_capability_id
  join public.provider_category_profiles pcp on pcp.user_id=lp.provider_id
    and pcp.category_slug='financial_services' and pcp.provider_type=lp.identity_type
  left join public.provider_company_profiles cp on cp.user_id=lp.provider_id
    and cp.category_slug='financial_services'
  left join public.provider_identity_presentations ip on ip.user_id=lp.provider_id
    and ip.category_slug='financial_services' and ip.identity_type='individual'
  left join public.profiles pr on pr.id=lp.provider_id
  where private.loan_product_matches_request(lp,v_request)
  order by lp.is_featured desc,lp.published_at desc;
end;
$$;
revoke all on function public.get_matching_products_for_request(uuid) from public,anon;
grant execute on function public.get_matching_products_for_request(uuid) to authenticated;

create or replace function private.notify_matching_loan_products()
returns trigger language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_owner uuid;
begin
  if new.status<>'active' or new.loan_category is null or new.loan_purpose is null then return new; end if;
  for v_owner in select distinct lp.provider_id from public.loan_products lp
    where private.loan_product_matches_request(lp,new)
  loop
    insert into public.loan_product_match_notifications(provider_id,request_id)
      values(v_owner,new.id) on conflict do nothing;
    if found then
      insert into public.notifications(user_id,type,title,body,request_id,data)
      values(v_owner,'system','A loan request matches your product',
        'A new borrower request matches one of your active loan products.',new.id,
        jsonb_build_object('kind','loan_product_match','request_id',new.id));
    end if;
  end loop;
  return new;
end;
$$;
revoke all on function private.notify_matching_loan_products() from public,anon,authenticated;
drop trigger if exists trg_notify_matching_loan_products on public.loan_requests;
create trigger trg_notify_matching_loan_products
  after insert or update of status,loan_category,loan_purpose,requested_amount,
    preferred_repayment_plan,country,district,has_collateral
  on public.loan_requests for each row execute function private.notify_matching_loan_products();

create table if not exists public.loan_product_enquiries (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.loan_products(id) on delete cascade,
  borrower_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check(char_length(btrim(message)) between 5 and 2000),
  created_at timestamptz not null default now(),
  unique(product_id,borrower_id)
);
alter table public.loan_product_enquiries enable row level security;
revoke all on public.loan_product_enquiries from public,anon,authenticated;
drop policy if exists loan_product_enquiries_borrower_read on public.loan_product_enquiries;
create policy loan_product_enquiries_borrower_read on public.loan_product_enquiries
  for select to authenticated using(borrower_id=auth.uid());
drop policy if exists loan_product_enquiries_provider_read on public.loan_product_enquiries;
create policy loan_product_enquiries_provider_read on public.loan_product_enquiries
  for select to authenticated using(exists(
    select 1 from public.loan_products lp where lp.id=product_id and lp.provider_id=auth.uid()));

create or replace function public.enquire_loan_product(p_product_id uuid,p_message text)
returns uuid language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_user uuid:=auth.uid();v_owner uuid;v_id uuid;v_is_new boolean;
begin
  if v_user is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(v_user) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  if p_message is null or char_length(btrim(p_message)) not between 5 and 2000 then
    raise exception 'Enter an enquiry between 5 and 2000 characters.' using errcode='22023'; end if;
  select lp.provider_id into v_owner from public.loan_products lp
    where lp.id=p_product_id and lp.status='active'
      and exists(select 1 from public.v_active_loan_products v where v.id=lp.id)
    for update;
  if v_owner is null then raise exception 'Product is no longer available.' using errcode='P0212'; end if;
  if v_owner=v_user then raise exception 'You cannot enquire about your own product.' using errcode='22023'; end if;
  select not exists(select 1 from public.loan_product_enquiries e
    where e.product_id=p_product_id and e.borrower_id=v_user) into v_is_new;
  insert into public.loan_product_enquiries(product_id,borrower_id,message)
    values(p_product_id,v_user,btrim(p_message))
    on conflict(product_id,borrower_id) do update set message=excluded.message,created_at=now()
    returning id into v_id;
  if v_is_new then
    update public.loan_products set enquiries_count=enquiries_count+1,updated_at=now()
      where id=p_product_id;
  end if;
  insert into public.notifications(user_id,type,title,body,data)
    values(v_owner,'system','New loan product enquiry',
      'Someone sent an enquiry about one of your loan products.',
      jsonb_build_object('kind','loan_product_enquiry','product_id',p_product_id,'enquiry_id',v_id));
  return v_id;
end;
$$;
revoke all on function public.enquire_loan_product(uuid,text) from public,anon;
grant execute on function public.enquire_loan_product(uuid,text) to authenticated;

create or replace view public.v_my_loan_product_enquiries with(security_barrier=true) as
select e.id,e.product_id,lp.product_title,e.message,e.created_at
from public.loan_product_enquiries e join public.loan_products lp on lp.id=e.product_id
where lp.provider_id=auth.uid();
grant select on public.v_my_loan_product_enquiries to authenticated;

commit;
notify pgrst,'reload schema';
