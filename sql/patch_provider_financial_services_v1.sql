-- Standalone SQL Patch: patch_provider_financial_services_v1.sql
-- Purpose: Add the 'financial_services' category and its 6 capabilities
--          to the need_categories and need_capabilities reference tables.
--          These capabilities reuse the existing provider_capabilities architecture.
--          No new tables are created.

-- 1. Insert 'financial_services' category
insert into public.need_categories (slug, name, icon, description, sort_order, is_active, provider_verification_required)
values (
  'financial_services',
  'Financial Services',
  '💰',
  'Loan services, forex exchange, bank agents, SACCO, microfinance, and financial advisory.',
  1,
  true,
  false
)
on conflict (slug) do update
  set
    name = excluded.name,
    icon = excluded.icon,
    description = excluded.description,
    sort_order = excluded.sort_order,
    is_active = excluded.is_active;

-- 2. Insert the 6 financial capabilities
insert into public.need_capabilities (slug, category_slug, name, is_active)
values
  ('loan_services',            'financial_services', 'Loan Services',                  true),
  ('forex_currency_exchange',  'financial_services', 'Forex / Currency Exchange',       true),
  ('bank_loan_agent',          'financial_services', 'Bank Loan Agent',                 true),
  ('sacco_microfinance',       'financial_services', 'SACCO / Microfinance Services',   true),
  ('financial_advisory',       'financial_services', 'Financial Advisory',              true),
  ('other_financial_services', 'financial_services', 'Other Financial Services',        true)
on conflict (slug) do update
  set
    name = excluded.name,
    category_slug = excluded.category_slug,
    is_active = excluded.is_active;

-- Done. Existing provider_capabilities RLS policies, indexes, and grants cover these
-- new capability slugs automatically.
