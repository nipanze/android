-- KYC-aware concurrency limits (loan + forex)
-- Idempotent patch suitable for Supabase Cloud SQL editor.

-- Insert configurable limits (idempotent)
INSERT INTO system_settings (setting_key, country, setting_value, setting_type, category, description, is_public)
VALUES
  ('max_concurrent_requests_verified', NULL, '5', 'number', 'limits', 'Maximum active loan requests per borrower when KYC is approved', TRUE),
  ('max_concurrent_forex_requests', NULL, '3', 'number', 'limits', 'Maximum active forex requests per requester (global default)', TRUE),
  ('max_concurrent_forex_requests_verified', NULL, '5', 'number', 'limits', 'Maximum active forex requests per requester when KYC is approved', TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO NOTHING;

-- Replace loan max-concurrent function to respect KYC approval
CREATE OR REPLACE FUNCTION trg_fn_max_concurrent_requests()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_active_count INT;
    v_max          INT;
    v_kyc_status   kyc_status_enum;
    v_setting_key  TEXT := 'max_concurrent_requests';
BEGIN
    SELECT status INTO v_kyc_status FROM kyc_verifications WHERE user_id = NEW.borrower_id;
    IF v_kyc_status = 'approved' THEN
        v_setting_key := 'max_concurrent_requests_verified';
    END IF;

    SELECT setting_value::INT INTO v_max
    FROM system_settings WHERE setting_key = v_setting_key AND country IS NULL
    ORDER BY country NULLS LAST LIMIT 1;

    SELECT COUNT(*) INTO v_active_count
    FROM loan_requests
    WHERE borrower_id = NEW.borrower_id AND status = 'active';

    IF v_active_count >= COALESCE(v_max, 0) THEN
        RAISE EXCEPTION 'NIPANZE_MAX_REQUESTS: You have reached the maximum of % active listings.', COALESCE(v_max, 0)
            USING ERRCODE = 'P0002';
    END IF;

    RETURN NEW;
END;
$$;

-- Add forex max-concurrent enforcement (new function + trigger)
CREATE OR REPLACE FUNCTION trg_fn_max_concurrent_forex_requests()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_active_count INT;
    v_max          INT;
    v_kyc_status   kyc_status_enum;
    v_setting_key  TEXT := 'max_concurrent_forex_requests';
BEGIN
    SELECT status INTO v_kyc_status FROM kyc_verifications WHERE user_id = NEW.requester_id;
    IF v_kyc_status = 'approved' THEN
        v_setting_key := 'max_concurrent_forex_requests_verified';
    END IF;

    SELECT setting_value::INT INTO v_max
    FROM system_settings WHERE setting_key = v_setting_key AND country IS NULL
    ORDER BY country NULLS LAST LIMIT 1;

    SELECT COUNT(*) INTO v_active_count
    FROM forex_requests
    WHERE requester_id = NEW.requester_id AND status = 'active';

    IF v_active_count >= COALESCE(v_max, 0) THEN
        RAISE EXCEPTION 'NIPANZE_MAX_FOREX_REQUESTS: You have reached the maximum of % active forex listings.', COALESCE(v_max, 0)
            USING ERRCODE = 'P0102';
    END IF;

    RETURN NEW;
END;
$$;

-- Attach trigger to forex_requests
DROP TRIGGER IF EXISTS trg_max_concurrent_forex_requests ON forex_requests;
CREATE TRIGGER trg_max_concurrent_forex_requests
    BEFORE INSERT ON forex_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_max_concurrent_forex_requests();
