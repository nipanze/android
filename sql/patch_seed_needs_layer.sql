-- ============================================================
-- Standalone SQL Patch: patch_seed_needs_layer.sql
-- Description: Test capabilities, seed provider relations, and sample
-- need interactions for Stage 4.8 verification.
-- ============================================================

-- Ensure test seed providers have capabilities
insert into public.provider_capabilities (user_id, capability_slug, verification_level)
select p.id, c.slug, 'self_declared'
from public.profiles p
cross join (
  select 'excavator_hire' as slug union all
  select 'company_registration' union all
  select 'heavy_haulage' union all
  select 'bulk_procurement'
) c
where p.id in (
  select id from public.profiles limit 3
)
on conflict (user_id, capability_slug) do nothing;
