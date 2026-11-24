-- Split the former Finance & Investments provider category into independent
-- top-level provider categories while keeping the financial_services slug for
-- Loans & Financing so existing loan product checks and matching remain valid.
-- Apply after patch_provider_catalog_one_word_hierarchy.sql,
-- patch_financial_services_provider_capabilities.sql, and the provider
-- identity / verification patches. This patch has not been run.

begin;

insert into public.need_categories
  (slug, name, icon, description, sort_order, is_active, provider_verification_required)
values
  ('investment_services', 'Investment Services', '📈',
   'Investment brokerage, investment guidance and related services.', 20, true, false),
  ('investment_opportunities', 'Investment Opportunities', '🤝',
   'Investor networks, introductions and startup support services.', 21, true, false),
  ('forex_money_services', 'Forex & Money Services', '💱',
   'Currency exchange, forex services and money transfer.', 22, true, false),
  ('savings_cooperatives', 'Savings & Cooperatives', '🏦',
   'SACCOs, savings groups, VSLAs and cooperatives.', 23, true, false)
on conflict (slug) do update set
  name = excluded.name,
  icon = excluded.icon,
  description = excluded.description,
  sort_order = excluded.sort_order,
  is_active = true;

update public.need_categories
set name = 'Loans & Financing', icon = '💰',
    description = 'Personal, business, asset and other loan financing services.',
   sort_order = 18, is_active = true
where slug = 'financial_services';

-- Move catalog rows by their stable capability slugs. Provider capability rows
-- reference these slugs, so their verification history and IDs remain intact.
WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
update public.need_capabilities nc
set category_slug = m.target_category_slug,
    ui_group_slug = m.target_category_slug
from finance_category_moves m
where nc.slug = m.capability_slug
  and nc.category_slug = 'financial_services';

-- Startup advisory is a business mentor work role in older catalogs. Keep the
-- capability in the Investment Opportunities category if that legacy slug is
-- still present there.
update public.need_capabilities
set category_slug = 'investment_opportunities', ui_group_slug = 'investment_opportunities'
where slug = 'work_business_mentor' and category_slug = 'financial_services';
update public.need_capabilities
set service_group_name = case category_slug
  when 'investment_services' then 'Brokerage & Advisory'
  when 'investment_opportunities' then 'Investor Networks & Startup Support'
  when 'forex_money_services' then 'Currency Exchange & Transfers'
  when 'savings_cooperatives' then 'Savings Groups & Cooperatives'
end
where category_slug in ('investment_services', 'investment_opportunities',
  'forex_money_services', 'savings_cooperatives');
update public.capability_roles
set category_slug = 'investment_opportunities'
where slug in ('work_angel_investor', 'work_business_mentor')
  and category_slug = 'financial_services';

-- Give Individual Forex providers role choices like Education providers have.
alter table public.role_qualifications
  add column if not exists is_required_proof boolean not null default false;

insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order,
   capability_type, policy, aliases)
values
  ('work_forex_bureau_operator', 'forex_money_services', 'Currency Exchange / Forex Bureau Operator', true, 'forex_money_services', 22300, 'work_roles', 'Work roles', 10, 'work', 'required_proof', array['forex bureau','currency exchange']),
  ('work_forex_trainer', 'forex_money_services', 'Forex Trading Trainer', true, 'forex_money_services', 22310, 'work_roles', 'Work roles', 20, 'work', 'optional_proof', array['forex instructor']),
  ('work_forex_broker', 'forex_money_services', 'Forex Broker / Dealer', true, 'forex_money_services', 22320, 'work_roles', 'Work roles', 30, 'work', 'required_proof', array['forex dealer']),
  ('work_money_transfer_agent', 'forex_money_services', 'Money Transfer Agent', true, 'forex_money_services', 22330, 'work_roles', 'Work roles', 40, 'work', 'required_proof', array['remittance agent','transfer agent'])
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = excluded.is_active,
  ui_group_slug = excluded.ui_group_slug,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  capability_type = excluded.capability_type,
  policy = excluded.policy,
  aliases = excluded.aliases;

insert into public.capability_roles
  (slug, category_slug, capability_slug, name, kind_question, is_active, aliases)
values
  ('forex_bureau_operator', 'forex_money_services', 'work_forex_bureau_operator', 'Currency Exchange / Forex Bureau Operator', 'Which currency services do you provide?', true, array['forex bureau','currency exchange']),
  ('forex_trainer', 'forex_money_services', 'work_forex_trainer', 'Forex Trading Trainer', 'What do you teach?', true, array['forex instructor']),
  ('forex_broker', 'forex_money_services', 'work_forex_broker', 'Forex Broker / Dealer', 'Which brokerage services do you provide?', true, array['forex dealer']),
  ('money_transfer_agent', 'forex_money_services', 'work_money_transfer_agent', 'Money Transfer Agent', 'Which transfer services do you handle?', true, array['remittance agent','transfer agent'])
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = excluded.is_active,
  aliases = excluded.aliases;

insert into public.role_kinds (role_slug, slug, name, sort_order) values
  ('forex_bureau_operator', 'cash_exchange', 'Cash currency exchange', 10),
  ('forex_bureau_operator', 'business_exchange', 'Business currency exchange', 20),
  ('forex_bureau_operator', 'rate_quotations', 'Rate quotations', 30),
  ('forex_trainer', 'forex_basics', 'Forex basics', 10),
  ('forex_trainer', 'technical_analysis', 'Technical analysis', 20),
  ('forex_trainer', 'risk_management', 'Risk management', 30),
  ('forex_broker', 'trade_execution', 'Trade execution', 10),
  ('forex_broker', 'client_onboarding', 'Client onboarding', 20),
  ('forex_broker', 'account_support', 'Account support', 30),
  ('money_transfer_agent', 'domestic_transfers', 'Domestic transfers', 10),
  ('money_transfer_agent', 'international_transfers', 'International transfers', 20),
  ('money_transfer_agent', 'mobile_money_transfers', 'Mobile money transfers', 30)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

insert into public.role_qualifications
  (role_slug, slug, name, is_evidence, sort_order, is_required_proof) values
  ('forex_bureau_operator', 'exchange_authorisation', 'Forex bureau or dealer authorisation', true, 10, true),
  ('forex_bureau_operator', 'aml_training', 'AML / financial crime training', true, 20, false),
  ('forex_bureau_operator', 'cash_handling_experience', 'Cash handling experience', false, 30, false),
  ('forex_trainer', 'forex_training_experience', 'Forex teaching experience', false, 10, false),
  ('forex_trainer', 'training_materials', 'Training materials or course outline', false, 20, false),
  ('forex_trainer', 'trading_track_record', 'Trading track record', false, 30, false),
  ('forex_broker', 'broker_authorisation', 'Broker or dealer authorisation', true, 10, true),
  ('forex_broker', 'aml_training', 'AML / financial crime training', true, 20, false),
  ('forex_broker', 'brokerage_experience', 'Brokerage experience', false, 30, false),
  ('money_transfer_agent', 'agent_authorisation', 'Money transfer agent authorisation', true, 10, true),
  ('money_transfer_agent', 'aml_training', 'AML / financial crime training', true, 20, false),
  ('money_transfer_agent', 'customer_service_experience', 'Customer service experience', false, 30, false)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  is_evidence = excluded.is_evidence,
  sort_order = excluded.sort_order,
  is_required_proof = excluded.is_required_proof;

-- Carry each selected category's identity, company details and presentation
-- into the new category rows. The old profile remains for Loans & Financing.
WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
insert into public.provider_category_profiles (user_id, category_slug, provider_type)
select distinct pc.user_id, m.target_category_slug,
       coalesce(pc.identity_type, pcp.provider_type, 'company')
from public.provider_capabilities pc
join finance_category_moves m on m.capability_slug = pc.capability_slug
left join public.provider_category_profiles pcp
  on pcp.user_id = pc.user_id and pcp.category_slug = 'financial_services'
where pc.identity_type is not null or pcp.provider_type is not null
on conflict (user_id, category_slug) do nothing;

WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
insert into public.provider_company_profiles (
  user_id, category_slug, company_name, registration_number, team_size,
  years_in_business, service_areas, created_at, updated_at
)
select distinct cp.user_id, m.target_category_slug, cp.company_name,
       cp.registration_number, cp.team_size, cp.years_in_business,
       cp.service_areas, cp.created_at, cp.updated_at
from public.provider_company_profiles cp
join public.provider_capabilities pc on pc.user_id = cp.user_id
join finance_category_moves m on m.capability_slug = pc.capability_slug
where cp.category_slug = 'financial_services'
  and coalesce(pc.identity_type, 'company') = 'company'
on conflict (user_id, category_slug) do nothing;

WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
insert into public.provider_identity_presentations (
  user_id, category_slug, identity_type, display_mode, display_name,
  representative_name, representative_authorized, created_at, updated_at
)
select distinct ip.user_id, m.target_category_slug, ip.identity_type,
       ip.display_mode, ip.display_name, ip.representative_name,
       ip.representative_authorized, ip.created_at, ip.updated_at
from public.provider_identity_presentations ip
join public.provider_capabilities pc on pc.user_id = ip.user_id
join finance_category_moves m on m.capability_slug = pc.capability_slug
where ip.category_slug = 'financial_services'
  and ip.identity_type = coalesce(pc.identity_type, 'company')
on conflict (user_id, category_slug, identity_type) do nothing;

WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
insert into public.provider_company_verification_submissions (
  user_id, category_slug, document_type, file_path, status, reject_reason,
  reviewed_by, reviewed_at, created_at, updated_at
)
select distinct submission.user_id, moves.target_category_slug,
       submission.document_type, submission.file_path, submission.status,
       submission.reject_reason, submission.reviewed_by, submission.reviewed_at,
       submission.created_at, submission.updated_at
from public.provider_company_verification_submissions submission
join public.provider_capabilities pc on pc.user_id = submission.user_id
join finance_category_moves moves on moves.capability_slug = pc.capability_slug
where submission.category_slug = 'financial_services'
  and coalesce(pc.identity_type, 'company') = 'company'
  and not exists (
    select 1 from public.provider_company_verification_submissions existing
    where existing.user_id = submission.user_id
      and existing.category_slug = moves.target_category_slug
      and existing.document_type = submission.document_type
  );

-- Keep the capability-save RPC's category ownership checks and limits while
-- extending Individual service support to the four new finance categories.
create or replace function public.save_provider_capabilities(
  p_items jsonb default '[]'::jsonb,
  p_category_slug text default null,
  p_remove_slugs text[] default array[]::text[]
) returns setof public.provider_capabilities
language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_user uuid := auth.uid(); v_type text; v_max int := 30; v_count int;
  v_item record; v_kind text; v_category text;
  v_incoming text[] := array[]::text[];
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if jsonb_typeof(coalesce(p_items, '[]'::jsonb)) <> 'array' then
    raise exception 'Invalid capability selection.' using errcode = 'P0215';
  end if;
  if p_category_slug is not null then
    select provider_type into v_type from public.provider_category_profiles
    where user_id = v_user and category_slug = p_category_slug;
    if v_type is null then raise exception 'Choose a provider identity first.' using errcode = 'P0216'; end if;
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb))
    as x(capability_slug text, metadata jsonb)
  loop
    select nc.category_slug, nc.capability_type into v_category, v_kind
    from public.need_capabilities nc
    where nc.slug = v_item.capability_slug and nc.is_active;
    if not found or (p_category_slug is not null and v_category <> p_category_slug) then
      raise exception 'Invalid capability for category.' using errcode = 'P0215';
    end if;
    if v_kind = 'service' and coalesce(v_type, 'company') = 'individual'
       and v_category not in ('financial_services', 'investment_services',
         'investment_opportunities', 'forex_money_services', 'savings_cooperatives') then
      raise exception 'Individual providers cannot save company services.' using errcode = 'P0215';
    end if;
    v_incoming := array_append(v_incoming, v_item.capability_slug);
  end loop;
  select coalesce(nullif(setting_value, '')::int, 30) into v_max
  from public.system_settings where setting_key = 'max_provider_capabilities'
    and (country is null or country = '__global__') limit 1;
  select count(*) into v_count from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  where pc.user_id = v_user
    and (p_category_slug is null or nc.category_slug <> p_category_slug
      or pc.identity_type = v_type or nc.capability_type = 'work')
    and (p_category_slug is not null
      or not (pc.capability_slug = any(coalesce(p_remove_slugs, array[]::text[]))));
  if v_count + cardinality(v_incoming) > coalesce(v_max, 30) then
    raise exception 'Maximum limit of % provider capabilities reached.', coalesce(v_max, 30)
      using errcode = 'P0206';
  end if;
  if coalesce(cardinality(p_remove_slugs), 0) > 0 then
    delete from public.provider_capabilities pc
    where pc.user_id = v_user and pc.capability_slug = any(p_remove_slugs)
      and (p_category_slug is null or pc.identity_type = v_type or pc.identity_type is null);
  end if;
  if p_category_slug is not null then
    delete from public.provider_capabilities pc using public.need_capabilities nc
    where pc.capability_slug = nc.slug and pc.user_id = v_user
      and nc.category_slug = p_category_slug
      and not (pc.capability_slug = any(v_incoming))
      and (nc.capability_type = 'work' or pc.identity_type = v_type);
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb))
    as x(capability_slug text, metadata jsonb)
  loop
    select capability_type into v_kind from public.need_capabilities
    where slug = v_item.capability_slug;
    if v_kind = 'work' then
      insert into public.provider_capabilities(user_id, capability_slug, verification_level, metadata, created_at)
      values (v_user, v_item.capability_slug, 'self_declared', coalesce(v_item.metadata, '{}'::jsonb), now())
      on conflict (user_id, capability_slug) where identity_type is null do update set
        metadata = case when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb
          then excluded.metadata else public.provider_capabilities.metadata end;
    else
      insert into public.provider_capabilities(user_id, capability_slug, identity_type, verification_level, metadata, created_at)
      values (v_user, v_item.capability_slug, v_type, 'self_declared', coalesce(v_item.metadata, '{}'::jsonb), now())
      on conflict (user_id, capability_slug, identity_type) where identity_type is not null do update set
        metadata = case when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb
          then excluded.metadata else public.provider_capabilities.metadata end;
    end if;
  end loop;
  return query select * from public.provider_capabilities where user_id = v_user;
end;
$$;
revoke all on function public.save_provider_capabilities(jsonb, text, text[]) from public, anon;
grant execute on function public.save_provider_capabilities(jsonb, text, text[]) to authenticated;

-- Financial capabilities can be offered under either provider identity. The
-- legacy rule allowed individual identities only under financial_services;
-- extend that rule to the new finance category slugs.
create or replace function private.enforce_provider_identity_capability()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare v_category text; v_kind text; v_current text;
begin
  select category_slug, capability_type into v_category, v_kind
  from public.need_capabilities where slug = new.capability_slug;
  if v_kind = 'service' then
    if tg_op = 'UPDATE' and old.identity_type is not null
       and new.identity_type is distinct from old.identity_type
       and not private.is_admin() then
      raise exception 'A service identity cannot be changed directly.' using errcode = 'P0216';
    end if;
    select provider_type into v_current from public.provider_category_profiles
    where user_id = new.user_id and category_slug = v_category;
    if new.identity_type is null then new.identity_type := coalesce(v_current, 'company'); end if;
    if new.identity_type not in ('individual', 'company') then
      raise exception 'Invalid capability identity.' using errcode = 'P0216';
    end if;
    if new.is_active and new.identity_type is distinct from coalesce(v_current, 'company') then
      new.is_active := false;
    elsif new.is_active
       and v_category not in ('financial_services', 'investment_services',
         'investment_opportunities', 'forex_money_services', 'savings_cooperatives')
       and coalesce(v_current, 'company') = 'individual' then
      new.is_active := false;
    end if;
  else
    new.identity_type := null;
  end if;
  return new;
end;
$$;

-- Re-run the existing per-capability proof gate under each category's identity
-- and verification policy. This hides moved services that lack approved proof.
WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
update public.provider_capabilities pc
set is_active = pc.is_active
from public.need_capabilities nc
join finance_category_moves moves on moves.capability_slug = nc.slug
where pc.capability_slug = nc.slug
  and moves.target_category_slug <> 'financial_services';

-- Keep the new provider-only categories out of borrower Needs even though
-- their catalog rows remain active for Provider Services.
create or replace function public.reject_financial_needs_category()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.category_slug in (
    'financial_services', 'investment_services', 'investment_opportunities',
    'forex_money_services', 'savings_cooperatives'
  ) then
    raise exception 'Financial service categories belong in Provider Services, Loans or Forex, not Needs.'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

commit;

notify pgrst, 'reload schema';
