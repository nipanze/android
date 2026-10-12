-- =============================================================================
-- patch_deactivate_marketing_services_placeholder_v1.sql
-- =============================================================================
-- Deactivates the redundant 'marketing_services' capability placeholder now that
-- 'marketing_promotion' is a top-level category with granular capabilities.
--
-- Safe to re-run.
-- =============================================================================

UPDATE public.need_capabilities
SET is_active = false
WHERE slug = 'marketing_services';

