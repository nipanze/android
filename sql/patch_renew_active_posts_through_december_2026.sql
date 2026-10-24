-- Extend active Loan, Forex, and Needs requests through December 31, 2026
-- (Africa/Kampala time). New requests posted before that deadline use the
-- same expiry; after it, the configured per-market duration applies again.

BEGIN;

DO $preflight$
BEGIN
  IF to_regclass('public.loan_requests') IS NULL
     OR to_regclass('public.forex_requests') IS NULL
     OR to_regclass('public.needs_requests') IS NULL
     OR to_regclass('public.system_settings') IS NULL THEN
    RAISE EXCEPTION
      'Post renewal requires loan_requests, forex_requests, needs_requests, and system_settings.';
  END IF;

  IF NOT EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'needs_requests'
         AND column_name = 'category_slug'
     )
     OR NOT EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'needs_requests'
         AND column_name = 'expires_at'
     ) THEN
    RAISE EXCEPTION
      'Post renewal requires the Needs expiry schema (category_slug and expires_at).';
  END IF;
END;
$preflight$;

LOCK TABLE public.loan_requests, public.forex_requests, public.needs_requests
  IN SHARE ROW EXCLUSIVE MODE;

UPDATE public.loan_requests
SET expires_at = TIMESTAMPTZ '2027-01-01 00:00:00 Africa/Kampala'
WHERE status::text = 'active';

UPDATE public.forex_requests
SET expires_at = TIMESTAMPTZ '2027-01-01 00:00:00 Africa/Kampala'
WHERE status::text = 'active';

UPDATE public.needs_requests
SET expires_at = TIMESTAMPTZ '2027-01-01 00:00:00 Africa/Kampala'
WHERE status::text = 'active';

CREATE OR REPLACE FUNCTION public.trg_fn_set_listing_expiry()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $function$
DECLARE
  v_setting_key text;
  v_days integer;
  v_december_deadline constant timestamptz :=
    TIMESTAMPTZ '2027-01-01 00:00:00 Africa/Kampala';
BEGIN
  CASE TG_TABLE_NAME
    WHEN 'loan_requests' THEN
      v_setting_key := 'listing_duration_days';
    WHEN 'forex_requests' THEN
      v_setting_key := 'forex_listing_duration_days';
    WHEN 'needs_requests' THEN
      v_setting_key := CASE NEW.category_slug
        WHEN 'machinery_equipment' THEN 'needs_default_duration_machinery_equipment_days'
        WHEN 'professional_services' THEN 'needs_default_duration_professional_services_days'
        WHEN 'transport_logistics' THEN 'needs_default_duration_transport_logistics_days'
        WHEN 'specialized_products' THEN 'needs_default_duration_specialized_products_days'
        WHEN 'travel_international' THEN 'needs_default_duration_travel_international_days'
        ELSE NULL
      END;
    ELSE
      RAISE EXCEPTION 'Unsupported listing table for expiry: %', TG_TABLE_NAME;
  END CASE;

  IF v_setting_key IS NULL THEN
    RAISE EXCEPTION 'No approved expiry duration is configured for Needs category %.',
      NEW.category_slug;
  END IF;

  SELECT setting_value::integer INTO v_days
  FROM public.system_settings
  WHERE setting_key = v_setting_key
    AND (country = NEW.country OR country IS NULL)
  ORDER BY country NULLS LAST
  LIMIT 1;

  IF v_days IS NULL OR v_days <= 0 THEN
    RAISE EXCEPTION 'Missing or invalid expiry setting % for country %.',
      v_setting_key, NEW.country;
  END IF;

  NEW.expires_at := CASE
    WHEN transaction_timestamp() < v_december_deadline THEN v_december_deadline
    ELSE NEW.listed_at + make_interval(days => v_days)
  END;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_set_listing_expiry ON public.loan_requests;
CREATE TRIGGER trg_set_listing_expiry
  BEFORE INSERT ON public.loan_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_set_listing_expiry();

DROP TRIGGER IF EXISTS trg_set_forex_listing_expiry ON public.forex_requests;
CREATE TRIGGER trg_set_forex_listing_expiry
  BEFORE INSERT ON public.forex_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_set_listing_expiry();

DROP TRIGGER IF EXISTS trg_set_needs_listing_expiry ON public.needs_requests;
CREATE TRIGGER trg_set_needs_listing_expiry
  BEFORE INSERT ON public.needs_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_set_listing_expiry();

COMMIT;
