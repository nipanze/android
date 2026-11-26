-- Add the latest Provider Services finance categories to Needs posting.
-- Safe to apply alongside the provider catalog split patch; all statements
-- are idempotent.

begin;

insert into public.need_categories
  (slug, name, icon, description, sort_order, is_active,
   provider_verification_required)
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
  is_active = true,
  provider_verification_required = excluded.provider_verification_required;

-- These capabilities already exist in the Needs catalog under the former
-- financial_services category. Keep their stable slugs and IDs for existing
-- provider declarations while making them available under their new categories.
with category_moves(capability_slug, target_category_slug) as (values
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
update public.need_capabilities capability
set category_slug = move.target_category_slug,
    ui_group_slug = move.target_category_slug
from category_moves move
where capability.slug = move.capability_slug
  and capability.category_slug = 'financial_services';

commit;
