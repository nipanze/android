-- =============================================================================
-- Standalone SQL Patch: patch_add_money_lender_capability.sql
-- Purpose : Add the 'money_lender_private_lender' provider capability so that
--           individual money lenders (who lend their own capital and do NOT
--           represent a bank, SACCO, or other institution) have a proper
--           capability/service to select in the Provider Services screen.
--
-- Context : The 6 existing financial capabilities were seeded by
--           patch_provider_financial_services_v1.sql.  This patch adds the 7th.
--           No existing rows are modified.
--
-- Apply to: Supabase → SQL Editor (or via migration tool).
--           Safe to run multiple times (idempotent via ON CONFLICT DO UPDATE).
-- =============================================================================

insert into public.need_capabilities
  (slug, category_slug, name, is_active)
values
  ('money_lender_private_lender', 'financial_services', 'Money Lender / Private Lender', true)
on conflict (slug) do update
  set name          = excluded.name,
      category_slug = excluded.category_slug,
      is_active     = excluded.is_active;

