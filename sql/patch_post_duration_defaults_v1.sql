-- ============================================================
-- Standalone patch: post duration defaults and expiry configuration
-- Description: Aligns loan, forex, and needs lifecycle defaults with the
-- current marketplace configuration model and keeps values in
-- system_settings so they can be overridden by market or plan.
-- Idempotent: safe to re-run with UPSERT semantics.
-- ============================================================

INSERT INTO public.system_settings (
  setting_key,
  setting_value,
  setting_type,
  category,
  description,
  is_public
)
VALUES
  ('listing_duration_days', '30', 'number', 'marketplace', 'Default days a loan request stays active before expiry', TRUE),
  ('forex_listing_duration_days', '7', 'number', 'marketplace', 'Default days a forex request stays active before expiry', TRUE),
  ('needs_default_duration_machinery_equipment_days', '14', 'number', 'marketplace', 'Default days for Machinery & Equipment needs requests', TRUE),
  ('needs_default_duration_professional_services_days', '14', 'number', 'marketplace', 'Default days for Professional Services needs requests', TRUE),
  ('needs_default_duration_transport_logistics_days', '7', 'number', 'marketplace', 'Default days for Transport & Logistics needs requests', TRUE),
  ('needs_default_duration_specialized_products_days', '14', 'number', 'marketplace', 'Default days for Specialized Products & Procurement needs requests', TRUE),
  ('needs_default_duration_travel_international_days', '14', 'number', 'marketplace', 'Default days for Travel & International needs requests', TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO UPDATE SET
  setting_value = EXCLUDED.setting_value,
  setting_type = EXCLUDED.setting_type,
  category = EXCLUDED.category,
  description = EXCLUDED.description,
  is_public = EXCLUDED.is_public,
  updated_at = NOW();
