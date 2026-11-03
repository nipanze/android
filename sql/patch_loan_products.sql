-- Provider loan products (Part B).
-- Apply after provider identities, capability verification policies, and the
-- Financial Services provider patch. This adds a separate lender product
-- catalogue; borrower loan_requests and loan_offers are not modified.

begin;

create table if not exists public.loan_product_categories (
  slug text primary key,
  name text not null,
  sort_order integer not null,
  is_active boolean not null default true
);

create table if not exists public.loan_product_purposes (
  category_slug text not null references public.loan_product_categories(slug),
  slug text not null,
  name text not null,
  sort_order integer not null,
  is_active boolean not null default true,
  primary key(category_slug, slug)
);

create table if not exists public.loan_product_interest_methods (
  slug text primary key,
  name text not null,
  sort_order integer not null,
  is_active boolean not null default true
);

create table if not exists public.loan_product_repayment_frequencies (
  slug text primary key,
  name text not null,
  sort_order integer not null,
  is_active boolean not null default true
);

insert into public.loan_product_categories(slug,name,sort_order) values
 ('personal','Personal',10),('business','Business',20),
 ('asset_financing','Asset Financing',30),('agricultural','Agricultural',40),
 ('property','Property',50),('education','Education',60),('lifestyle','Lifestyle',70)
on conflict(slug) do update set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

insert into public.loan_product_purposes(category_slug,slug,name,sort_order) values
 ('personal','general_personal_expenses','General Personal Expenses',10),
 ('personal','salary_advance','Salary Advance',20),
 ('personal','medical_expenses','Medical Expenses',30),
 ('personal','debt_consolidation','Debt Consolidation',40),
 ('personal','family_support','Family Support',50),
 ('personal','other_personal_needs','Other Personal Needs',60),
 ('business','business_startup','Business Startup',10),
 ('business','business_expansion','Business Expansion',20),
 ('business','working_capital','Working Capital',30),
 ('business','inventory_stock_purchase','Inventory / Stock Purchase',40),
 ('business','equipment_for_business','Equipment for Business',50),
 ('business','contract_financing','Contract Financing',60),
 ('business','invoice_financing','Invoice Financing',70),
 ('business','other_business_needs','Other Business Needs',80),
 ('asset_financing','boda_boda','Boda Boda',10),
 ('asset_financing','car','Car',20),
 ('asset_financing','tuk_tuk','Tuk-tuk',30),
 ('asset_financing','motorcycle','Motorcycle',40),
 ('asset_financing','smartphone','Smartphone',50),
 ('asset_financing','laptop','Laptop',60),
 ('asset_financing','heavy_machinery','Heavy Machinery',70),
 ('asset_financing','agricultural_equipment','Agricultural Equipment',80),
 ('asset_financing','other_asset_financing','Other Asset Financing',90),
 ('agricultural','crop_production','Crop Production',10),
 ('agricultural','greenhouse_farming','Greenhouse Farming',20),
 ('agricultural','livestock','Livestock',30),
 ('agricultural','poultry_farming','Poultry Farming',40),
 ('agricultural','farm_inputs','Farm Inputs',50),
 ('agricultural','irrigation','Irrigation',60),
 ('agricultural','tractor_financing','Tractor Financing',70),
 ('agricultural','agricultural_equipment','Agricultural Equipment',80),
 ('agricultural','other_agricultural_needs','Other Agricultural Needs',90),
 ('property','land_purchase','Land Purchase',10),
 ('property','home_construction','Home Construction',20),
 ('property','home_improvement','Home Improvement',30),
 ('property','mortgage_financing','Mortgage Financing',40),
 ('property','property_development','Property Development',50),
 ('property','commercial_property','Commercial Property',60),
 ('property','other_property_needs','Other Property Needs',70),
 ('education','school_fees','School Fees',10),
 ('education','university_tuition','University Tuition',20),
 ('education','vocational_training','Vocational Training',30),
 ('education','professional_courses','Professional Courses',40),
 ('education','study_abroad','Study Abroad',50),
 ('education','educational_equipment','Educational Equipment',60),
 ('education','other_education_needs','Other Education Needs',70),
 ('lifestyle','wedding_expenses','Wedding Expenses',10),
 ('lifestyle','travel_holiday','Travel / Holiday',20),
 ('lifestyle','events_celebrations','Events and Celebrations',30),
 ('lifestyle','family_events','Family Events',40),
 ('lifestyle','relocation_expenses','Relocation Expenses',50),
 ('lifestyle','other_lifestyle_needs','Other Lifestyle Needs',60)
on conflict(category_slug,slug) do update set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

insert into public.loan_product_interest_methods(slug,name,sort_order) values
 ('flat_rate','Flat rate',10),('reducing_balance','Reducing balance',20),
 ('compound_interest','Compound interest',30),('simple_interest','Simple interest',40),
 ('custom','Custom / explain in terms',50)
on conflict(slug) do update set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

insert into public.loan_product_repayment_frequencies(slug,name,sort_order) values
 ('daily','Daily',10),('weekly','Weekly',20),('biweekly','Biweekly',30),
 ('monthly','Monthly',40),('custom','Custom',50)
on conflict(slug) do update set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

create table if not exists public.loan_products (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.profiles(id) on delete cascade,
  identity_type text not null check(identity_type in ('individual','company')),
  provider_capability_id uuid not null references public.provider_capabilities(id) on delete restrict,
  category_slug text not null references public.loan_product_categories(slug),
  purpose_slug text,
  product_title text not null check(char_length(product_title) between 3 and 100),
  short_description text not null default '' check(char_length(short_description) <= 1000),
  minimum_amount bigint,
  maximum_amount bigint,
  currency_code text references public.currencies(code),
  terms jsonb not null default '{}'::jsonb check(jsonb_typeof(terms)='object'),
  status text not null default 'draft'
    check(status in ('draft','active','paused','unavailable','archived')),
  is_featured boolean not null default false,
  views_count bigint not null default 0 check(views_count >= 0),
  enquiries_count bigint not null default 0 check(enquiries_count >= 0),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key(category_slug,purpose_slug)
    references public.loan_product_purposes(category_slug,slug),
  check(minimum_amount is null or minimum_amount > 0),
  check(maximum_amount is null or maximum_amount > 0),
  check(minimum_amount is null or maximum_amount is null or minimum_amount <= maximum_amount)
);

create index if not exists idx_loan_products_owner_status
  on public.loan_products(provider_id,status,updated_at desc);
create index if not exists idx_loan_products_category_purpose
  on public.loan_products(category_slug,purpose_slug,status);
create index if not exists idx_loan_products_capability
  on public.loan_products(provider_capability_id,status);

alter table public.loan_products enable row level security;
revoke all on public.loan_products from public,anon,authenticated;
grant select on public.loan_products to authenticated;
drop policy if exists loan_products_owner_read on public.loan_products;
create policy loan_products_owner_read on public.loan_products
  for select to authenticated using(provider_id=auth.uid());

grant select on public.loan_product_categories,public.loan_product_purposes,
  public.loan_product_interest_methods,public.loan_product_repayment_frequencies
  to anon,authenticated;

insert into public.system_settings(setting_key,country,setting_value,setting_type,category,description,is_public)
values
 ('loan_products_max_active_free',null,'1','number','provider','Maximum active loan products for Free provider plan',true),
 ('loan_products_max_active_lender',null,'3','number','provider','Maximum active loan products for Lender provider plan',true),
 ('loan_products_max_active_pro',null,'10','number','provider','Maximum active loan products for Pro provider plan',true),
 ('loan_products_max_featured_free',null,'0','number','provider','Maximum featured loan products for Free provider plan',true),
 ('loan_products_max_featured_lender',null,'1','number','provider','Maximum featured loan products for Lender provider plan',true),
 ('loan_products_max_featured_pro',null,'3','number','provider','Maximum featured loan products for Pro provider plan',true)
on conflict(setting_key,coalesce(country,'__global__')) do nothing;

create or replace function private.loan_products_feature_enabled(p_user_id uuid default auth.uid())
returns boolean language sql stable security definer
set search_path=public,pg_temp as $$
  select coalesce((
    select lower(s.setting_value) in ('true','1')
    from public.system_settings s
    join public.profiles p on p.id=p_user_id
    where s.setting_key='capability_profiles_enabled' and s.is_public
      and (s.country=p.country or s.country is null)
    order by (s.country=p.country) desc nulls last limit 1
  ),false)
$$;

revoke all on function private.loan_products_feature_enabled(uuid) from public,anon;
grant execute on function private.loan_products_feature_enabled(uuid) to authenticated;
drop policy if exists loan_products_active_market_read on public.loan_products;
create policy loan_products_active_market_read on public.loan_products
  for select to authenticated using(
    status='active' and private.loan_products_feature_enabled()
    and private.provider_capability_is_eligible(provider_capability_id)
  );

create or replace function public.save_loan_product_draft(
  p_product_id uuid,
  p_payload jsonb
) returns uuid language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare
  v_user uuid:=auth.uid(); v_id uuid; v_identity text; v_capability uuid;
  v_category text; v_purpose text; v_title text; v_description text;
  v_min bigint; v_max bigint; v_currency text; v_terms jsonb;
begin
  if v_user is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(v_user) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  if jsonb_typeof(p_payload)<>'object' then raise exception 'Invalid product draft.' using errcode='22023'; end if;
  v_identity:=p_payload->>'identity_type'; v_capability:=(p_payload->>'provider_capability_id')::uuid;
  v_category:=p_payload->>'category_slug'; v_purpose:=nullif(p_payload->>'purpose_slug','');
  v_title:=coalesce(nullif(btrim(p_payload->>'product_title'),''),'Untitled loan product');
  v_description:=coalesce(p_payload->>'short_description','');
  v_min:=nullif(p_payload->>'minimum_amount','')::bigint;
  v_max:=nullif(p_payload->>'maximum_amount','')::bigint;
  v_currency:=nullif(p_payload->>'currency_code','');
  v_terms:=coalesce(p_payload->'terms','{}'::jsonb);
  if v_identity not in ('individual','company') or v_capability is null
     or not exists(select 1 from public.provider_category_profiles pcp
       where pcp.user_id=v_user and pcp.category_slug='financial_services'
         and pcp.provider_type=v_identity) then
    raise exception 'Choose the matching Individual or Company financial identity first.' using errcode='P0216';
  end if;
  if not exists(select 1 from public.provider_capabilities pc
       join public.need_capabilities nc on nc.slug=pc.capability_slug
       where pc.id=v_capability and pc.user_id=v_user
         and pc.identity_type=v_identity and nc.category_slug='financial_services') then
    raise exception 'Choose a Financial Services capability saved under this identity.' using errcode='P0216';
  end if;
  if not exists(select 1 from public.loan_product_categories c where c.slug=v_category and c.is_active) then
    raise exception 'Choose an available product category.' using errcode='22023'; end if;
  if v_purpose is not null and not exists(select 1 from public.loan_product_purposes p
      where p.category_slug=v_category and p.slug=v_purpose and p.is_active) then
    raise exception 'Choose a purpose from this category.' using errcode='22023'; end if;
  if v_min is not null and v_min<=0 or v_max is not null and v_max<=0
     or v_min is not null and v_max is not null and v_min>v_max then
    raise exception 'Enter a valid minimum and maximum amount.' using errcode='22023'; end if;
  if v_currency is not null and not exists(select 1 from public.currencies c where c.code=v_currency) then
    raise exception 'Choose an available currency.' using errcode='22023'; end if;
  if jsonb_typeof(v_terms)<>'object' then raise exception 'Invalid product terms.' using errcode='22023'; end if;
  if p_product_id is null then
    insert into public.loan_products(provider_id,identity_type,provider_capability_id,category_slug,
      purpose_slug,product_title,short_description,minimum_amount,maximum_amount,currency_code,terms,is_featured)
    values(v_user,v_identity,v_capability,v_category,v_purpose,v_title,v_description,
      v_min,v_max,v_currency,v_terms,coalesce((v_terms->>'featured')::boolean,false)) returning id into v_id;
  else
    update public.loan_products set identity_type=v_identity,provider_capability_id=v_capability,
      category_slug=v_category,purpose_slug=v_purpose,product_title=v_title,
      short_description=v_description,minimum_amount=v_min,maximum_amount=v_max,
      currency_code=v_currency,terms=v_terms,
      is_featured=coalesce((v_terms->>'featured')::boolean,false),
      status=case when status='archived' then status else 'draft' end,
      updated_at=now()
    where id=p_product_id and provider_id=v_user and status<>'archived'
    returning id into v_id;
    if v_id is null then raise exception 'Product not found or archived.' using errcode='P0212'; end if;
  end if;
  return v_id;
end;
$$;
revoke all on function public.save_loan_product_draft(uuid,jsonb) from public,anon;
grant execute on function public.save_loan_product_draft(uuid,jsonb) to authenticated;

create or replace function public.publish_loan_product(p_product_id uuid)
returns jsonb language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare v_user uuid:=auth.uid(); v_product public.loan_products%rowtype;
  v_plan text; v_country text; v_max int; v_featured_max int; v_active int; v_featured int;
  v_setting text; v_required text[]:=array['interest_method','repayment_frequency','minimum_period',
    'maximum_period','secured','guarantor_required','minimum_age','eligible_locations'];
  v_key text;
begin
  if v_user is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text||':loan_products',0));
  if not private.loan_products_feature_enabled(v_user) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  select * into v_product from public.loan_products where id=p_product_id and provider_id=v_user for update;
  if not found then raise exception 'Product not found.' using errcode='P0212'; end if;
  if v_product.status='archived' then raise exception 'Archived products cannot be published.' using errcode='22023'; end if;
  if v_product.purpose_slug is null or v_product.minimum_amount is null or v_product.maximum_amount is null
     or v_product.currency_code is null or v_product.product_title='Untitled loan product'
     or length(btrim(v_product.short_description))<10 then
    raise exception 'Complete category, purpose, title, description, amount range, and currency.' using errcode='22023'; end if;
  if v_product.minimum_amount>v_product.maximum_amount then
    raise exception 'Minimum amount cannot exceed maximum amount.' using errcode='22023'; end if;
  for v_key in select unnest(v_required) loop
    if not (v_product.terms ? v_key) or v_product.terms->v_key is null then
      raise exception 'Complete all required loan terms before publishing.' using errcode='22023'; end if;
  end loop;
  if not exists(select 1 from public.provider_category_profiles pcp
       where pcp.user_id=v_user and pcp.category_slug='financial_services'
         and pcp.provider_type=v_product.identity_type) then
    raise exception 'This provider identity is no longer selected.' using errcode='P0216'; end if;
  if not exists(select 1 from public.provider_capabilities pc
       where pc.id=v_product.provider_capability_id and pc.user_id=v_user
         and pc.identity_type=v_product.identity_type and pc.verification_level='provider_verified'
         and pc.is_active and private.provider_capability_is_eligible(pc.id)) then
    raise exception 'An approved Financial Services capability under this identity is required to publish.' using errcode='P0216'; end if;
  if not exists(select 1 from public.profiles p join public.kyc_verifications k on k.user_id=p.id
       where p.id=v_user and p.account_status='active' and p.phone_verified_at is not null
         and k.status='approved' and (k.expires_at is null or k.expires_at>now())) then
    raise exception 'Complete the existing account and identity verification checks to publish.' using errcode='P0216'; end if;
  select coalesce(s.plan::text,'free'),p.country into v_plan,v_country
    from public.profiles p left join lateral (select plan from public.subscriptions
      where user_id=p.id and status='active' order by created_at desc limit 1) s on true
    where p.id=v_user;
  select setting_value::int into v_max from public.system_settings
    where setting_key='loan_products_max_active_'||v_plan and (country=v_country or country is null)
    order by (country=v_country) desc nulls last limit 1;
  select setting_value::int into v_featured_max from public.system_settings
    where setting_key='loan_products_max_featured_'||v_plan and (country=v_country or country is null)
    order by (country=v_country) desc nulls last limit 1;
  if v_max is null or v_featured_max is null then raise exception 'Loan product limits are not configured.' using errcode='P0206'; end if;
  select count(*) into v_active from public.loan_products where provider_id=v_user and status='active' and id<>p_product_id;
  select count(*) into v_featured from public.loan_products where provider_id=v_user and status='active' and is_featured and id<>p_product_id;
  if v_active>=v_max then raise exception 'LOAN_PRODUCT_LIMIT: You have reached the active product limit for your plan.' using errcode='P0206'; end if;
  if v_product.is_featured and v_featured>=v_featured_max then raise exception 'LOAN_PRODUCT_FEATURED_LIMIT: Your plan has no featured placements available.' using errcode='P0206'; end if;
  update public.loan_products set status='active',published_at=coalesce(published_at,now()),updated_at=now()
    where id=p_product_id;
  return jsonb_build_object('id',p_product_id,'status','active','active_count',v_active+1,'active_limit',v_max);
end;
$$;
revoke all on function public.publish_loan_product(uuid) from public,anon;
grant execute on function public.publish_loan_product(uuid) to authenticated;

create or replace function public.set_loan_product_status(p_product_id uuid,p_status text)
returns boolean language plpgsql security definer
set search_path=public,private,pg_temp as $$
begin
  if auth.uid() is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if p_status not in ('paused','unavailable','archived') then raise exception 'Invalid product status.' using errcode='22023'; end if;
  update public.loan_products set status=p_status,updated_at=now()
    where id=p_product_id and provider_id=auth.uid() and status<>'archived';
  if not found then raise exception 'Product not found.' using errcode='P0212'; end if;
  return true;
end;
$$;
revoke all on function public.set_loan_product_status(uuid,text) from public,anon;
grant execute on function public.set_loan_product_status(uuid,text) to authenticated;

create or replace function public.get_my_loan_product_quota()
returns jsonb language plpgsql security definer stable
set search_path=public,private,pg_temp as $$
declare v_plan text;v_country text;v_limit int;v_count int;v_featured_limit int;v_featured int;
begin
  if auth.uid() is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(auth.uid()) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  select coalesce(s.plan::text,'free'),p.country into v_plan,v_country from public.profiles p
   left join lateral(select plan from public.subscriptions where user_id=p.id and status='active'
   order by created_at desc limit 1)s on true where p.id=auth.uid();
  select setting_value::int into v_limit from public.system_settings where setting_key='loan_products_max_active_'||v_plan
   and(country=v_country or country is null) order by(country=v_country) desc nulls last limit 1;
  select setting_value::int into v_featured_limit from public.system_settings where setting_key='loan_products_max_featured_'||v_plan
   and(country=v_country or country is null) order by(country=v_country) desc nulls last limit 1;
  select count(*) into v_count from public.loan_products where provider_id=auth.uid() and status='active';
  select count(*) into v_featured from public.loan_products where provider_id=auth.uid() and status='active' and is_featured;
  return jsonb_build_object('plan',v_plan,'active_count',v_count,'active_limit',v_limit,
    'featured_count',v_featured,'featured_limit',v_featured_limit);
end;
$$;
revoke all on function public.get_my_loan_product_quota() from public,anon;
grant execute on function public.get_my_loan_product_quota() to authenticated;

create or replace view public.v_active_loan_products
with (security_barrier=true) as
select lp.id,lp.identity_type,lp.category_slug,lc.name as category_name,
  lp.purpose_slug,pu.name as purpose_name,lp.product_title,lp.short_description,
  lp.minimum_amount,lp.maximum_amount,lp.currency_code,lp.terms,lp.is_featured,
  lp.published_at,lp.views_count,lp.enquiries_count,
  case when lp.identity_type='company' then cp.company_name
       else coalesce(ip.display_name,pr.full_name,'Individual provider') end as provider_name,
  null::text as provider_logo_url,
  pc.verification_level='provider_verified' as provider_verified
from public.loan_products lp
join public.loan_product_categories lc on lc.slug=lp.category_slug
join public.loan_product_purposes pu on pu.category_slug=lp.category_slug and pu.slug=lp.purpose_slug
join public.provider_capabilities pc on pc.id=lp.provider_capability_id
left join public.provider_category_profiles pcp on pcp.user_id=lp.provider_id and pcp.category_slug='financial_services'
left join public.provider_company_profiles cp on cp.user_id=lp.provider_id and cp.category_slug='financial_services'
left join public.provider_identity_presentations ip on ip.user_id=lp.provider_id and ip.category_slug='financial_services' and ip.identity_type='individual'
left join public.profiles pr on pr.id=lp.provider_id
where lp.status='active' and private.loan_products_feature_enabled(lp.provider_id)
  and pcp.provider_type=lp.identity_type and pc.identity_type=lp.identity_type
  and pc.is_active and pc.verification_level='provider_verified'
  and private.provider_capability_is_eligible(pc.id);
grant select on public.v_active_loan_products to anon,authenticated;

commit;
notify pgrst,'reload schema';
