-- Plan-based active loan request limits.
-- Paste this patch by itself after the base schema/patches are already applied.
--
-- Policy:
--   Free   = 2 active loan requests
--   Lender = 5 active loan requests
--   Pro    = 15 active loan requests
--
-- Only status = 'active' counts. Contracted, expired, and cancelled requests
-- free up capacity automatically.

INSERT INTO system_settings (
  setting_key,
  country,
  setting_value,
  setting_type,
  category,
  description,
  is_public
)
VALUES
  ('max_active_requests_free', NULL, '2', 'number', 'limits', 'Maximum active loan requests for Free subscribers', TRUE),
  ('max_active_requests_lender', NULL, '5', 'number', 'limits', 'Maximum active loan requests for Lender subscribers', TRUE),
  ('max_active_requests_pro', NULL, '15', 'number', 'limits', 'Maximum active loan requests for Pro subscribers', TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO UPDATE
SET setting_value = EXCLUDED.setting_value,
    setting_type = EXCLUDED.setting_type,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    is_public = EXCLUDED.is_public,
    updated_at = NOW();

UPDATE system_settings
SET setting_value = '2',
    description = 'Legacy fallback maximum active loan requests per borrower',
    updated_at = NOW()
WHERE setting_key = 'max_concurrent_requests'
  AND country IS NULL;

CREATE OR REPLACE FUNCTION trg_fn_max_concurrent_requests()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_active_count INT;
    v_max          INT;
    v_plan         subscription_plan_enum;
BEGIN
    SELECT COALESCE(s.plan, 'free'::subscription_plan_enum) INTO v_plan
    FROM profiles p
    LEFT JOIN subscriptions s
      ON s.user_id = p.id
     AND s.status = 'active'
     AND (s.expires_at IS NULL OR s.expires_at > NOW())
    WHERE p.id = NEW.borrower_id
    LIMIT 1;

    v_plan := COALESCE(v_plan, 'free'::subscription_plan_enum);

    SELECT setting_value::INT INTO v_max
    FROM system_settings
    WHERE setting_key = ('max_active_requests_' || v_plan::TEXT)
      AND (country = NEW.country OR country IS NULL)
    ORDER BY country NULLS LAST
    LIMIT 1;

    IF v_max IS NULL THEN
        SELECT setting_value::INT INTO v_max
        FROM system_settings
        WHERE setting_key = 'max_concurrent_requests'
          AND (country = NEW.country OR country IS NULL)
        ORDER BY country NULLS LAST
        LIMIT 1;
    END IF;

    v_max := COALESCE(v_max, 2);

    SELECT COUNT(*) INTO v_active_count
    FROM loan_requests
    WHERE borrower_id = NEW.borrower_id
      AND status = 'active';

    IF v_active_count >= v_max THEN
        RAISE EXCEPTION 'NIPANZE_MAX_REQUESTS: You have reached the maximum of % active listings.', v_max
            USING ERRCODE = 'P0002';
    END IF;

    RETURN NEW;
END;
$$;
