-- Nipanze: migrate existing marketplace posts to the approved expiry rules.
-- Run after sql/schema.sql, sql/patch.sql, and the Needs layer are installed.
-- Run as the database owner in staging first, then production.
--
-- The migration uses listed_at (never created_at or updated_at) and the
-- approved global system_settings values. It fails before changing data if
-- those settings or any country overrides disagree with the approved rules.
-- Only active posts with a reliable listed_at and a recognized Needs category
-- are changed. Terminal statuses, offers, reviews, and audit records are not.

BEGIN;

SET LOCAL lock_timeout = '10s';
CREATE SCHEMA IF NOT EXISTS private;
SET search_path = public, private;

DO $preflight$
DECLARE
  v_expected record;
  v_setting text;
BEGIN
  IF to_regclass('public.loan_requests') IS NULL
     OR to_regclass('public.forex_requests') IS NULL
     OR to_regclass('public.needs_requests') IS NULL
     OR to_regclass('public.system_settings') IS NULL THEN
    RAISE EXCEPTION 'Expiry migration requires loan_requests, forex_requests, needs_requests, and system_settings.';
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
    RAISE EXCEPTION 'Needs expiry migration requires the Needs layer (category_slug and expires_at). Apply the Needs schema patch first.';
  END IF;

  FOR v_expected IN
    SELECT * FROM (VALUES
      ('listing_duration_days', 30),
      ('forex_listing_duration_days', 7),
      ('needs_default_duration_machinery_equipment_days', 14),
      ('needs_default_duration_professional_services_days', 14),
      ('needs_default_duration_transport_logistics_days', 7),
      ('needs_default_duration_specialized_products_days', 14),
      ('needs_default_duration_travel_international_days', 14)
    ) AS approved(setting_key, days)
  LOOP
    SELECT setting_value INTO v_setting
    FROM public.system_settings
    WHERE setting_key = v_expected.setting_key
      AND country IS NULL;

    IF v_setting IS NULL OR v_setting !~ '^[0-9]+$' THEN
      RAISE EXCEPTION 'Approved expiry setting % must be % days; found %.',
        v_expected.setting_key, v_expected.days, COALESCE(v_setting, '<missing>');
    END IF;

    IF v_setting::integer <> v_expected.days THEN
      RAISE EXCEPTION 'Approved expiry setting % must be % days; found %.',
        v_expected.setting_key, v_expected.days, COALESCE(v_setting, '<missing>');
    END IF;

    IF EXISTS (
      SELECT 1
      FROM public.system_settings
      WHERE setting_key = v_expected.setting_key
        AND country IS NOT NULL
        AND (setting_value IS NULL OR setting_value !~ '^[0-9]+$')
    ) THEN
      RAISE EXCEPTION 'A country override for % is not a valid positive integer.',
        v_expected.setting_key;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM public.system_settings
      WHERE setting_key = v_expected.setting_key
        AND country IS NOT NULL
        AND setting_value::integer <> v_expected.days
    ) THEN
      RAISE EXCEPTION 'A country override for % differs from the approved % day duration.',
        v_expected.setting_key, v_expected.days;
    END IF;
  END LOOP;
END;
$preflight$;

DROP TABLE IF EXISTS private.expiry_duration_v1;
CREATE TABLE private.expiry_duration_v1 (
  market text NOT NULL,
  category_slug text,
  setting_key text NOT NULL,
  days integer NOT NULL
);

INSERT INTO private.expiry_duration_v1 (market, category_slug, setting_key, days)
SELECT x.market, x.category_slug, x.setting_key, s.setting_value::integer
FROM (VALUES
  ('Loans', NULL::text, 'listing_duration_days'),
  ('Forex', NULL::text, 'forex_listing_duration_days'),
  ('Needs', 'machinery_equipment', 'needs_default_duration_machinery_equipment_days'),
  ('Needs', 'professional_services', 'needs_default_duration_professional_services_days'),
  ('Needs', 'transport_logistics', 'needs_default_duration_transport_logistics_days'),
  ('Needs', 'specialized_products', 'needs_default_duration_specialized_products_days'),
  ('Needs', 'travel_international', 'needs_default_duration_travel_international_days')
) AS x(market, category_slug, setting_key)
JOIN public.system_settings s
  ON s.setting_key = x.setting_key
 AND s.country IS NULL;

LOCK TABLE public.loan_requests, public.forex_requests, public.needs_requests
  IN SHARE ROW EXCLUSIVE MODE;

DROP TABLE IF EXISTS private.expiry_terminal_before_v1;
CREATE TABLE private.expiry_terminal_before_v1 AS
SELECT 'Loans' AS market, status::text AS status, count(*) AS posts
FROM public.loan_requests
WHERE status::text NOT IN ('active', 'expired')
GROUP BY status
UNION ALL
SELECT 'Forex', status::text, count(*)
FROM public.forex_requests
WHERE status::text NOT IN ('active', 'expired')
GROUP BY status
UNION ALL
SELECT 'Needs', status::text, count(*)
FROM public.needs_requests
WHERE status::text NOT IN ('active', 'expired')
GROUP BY status;

-- Before-migration audit: status counts, missing data, overdue candidates,
-- sample/development indicators, and rows requiring manual review.
SELECT 'Loans' AS market, status::text AS status, count(*) AS posts,
       count(*) FILTER (WHERE expires_at IS NULL) AS missing_expiry,
       count(*) FILTER (WHERE listed_at IS NULL) AS missing_listed_at,
       count(*) FILTER (WHERE status::text = 'active'
                         AND listed_at + make_interval(days => (
                           SELECT days FROM private.expiry_duration_v1 WHERE market = 'Loans'
                         )) <= transaction_timestamp())
         AS overdue_at_approved_duration,
       count(*) FILTER (WHERE borrower_id::text LIKE '10000000-%') AS likely_seed_posts
FROM public.loan_requests
GROUP BY status
UNION ALL
SELECT 'Forex', status::text, count(*),
       count(*) FILTER (WHERE expires_at IS NULL),
       count(*) FILTER (WHERE listed_at IS NULL),
       count(*) FILTER (WHERE status::text = 'active'
                         AND listed_at + make_interval(days => (
                           SELECT days FROM private.expiry_duration_v1 WHERE market = 'Forex'
                         )) <= transaction_timestamp()),
       count(*) FILTER (WHERE requester_id::text LIKE '10000000-%')
FROM public.forex_requests
GROUP BY status
UNION ALL
SELECT 'Needs', status::text, count(*),
       count(*) FILTER (WHERE expires_at IS NULL),
       count(*) FILTER (WHERE listed_at IS NULL),
       count(*) FILTER (WHERE status::text = 'active'
                         AND EXISTS (
                           SELECT 1 FROM private.expiry_duration_v1 d
                           WHERE d.market = 'Needs'
                             AND d.category_slug = needs_requests.category_slug
                             AND needs_requests.listed_at + make_interval(days => d.days)
                                 <= transaction_timestamp()
                         )),
       count(*) FILTER (WHERE requester_id IS NULL)
FROM public.needs_requests
GROUP BY status
ORDER BY 1, 2;

SELECT market, count(*) AS total_posts_examined
FROM (
  SELECT 'Loans' AS market FROM public.loan_requests
  UNION ALL SELECT 'Forex' FROM public.forex_requests
  UNION ALL SELECT 'Needs' FROM public.needs_requests
) all_posts
GROUP BY market
ORDER BY market;

SELECT 'Loans' AS market, id AS post_id, borrower_id AS owner_id,
       listed_at, expires_at, status::text AS status
FROM public.loan_requests
WHERE borrower_id::text LIKE '10000000-%'
UNION ALL
SELECT 'Forex', id, requester_id, listed_at, expires_at, status::text
FROM public.forex_requests
WHERE requester_id::text LIKE '10000000-%'
UNION ALL
SELECT 'Needs', request_id, requester_id, listed_at, expires_at, status::text
FROM public.needs_requests
WHERE requester_id IS NULL
ORDER BY market, listed_at NULLS FIRST, post_id;

SELECT 'Needs' AS market, request_id, category_slug, listed_at, expires_at,
       status, requester_id IS NULL AS likely_sample
FROM public.needs_requests
WHERE listed_at IS NULL
   OR category_slug IS NULL
   OR category_slug NOT IN (
     'machinery_equipment', 'professional_services', 'transport_logistics',
     'specialized_products', 'travel_international'
   )
ORDER BY listed_at NULLS FIRST, request_id;

SELECT 'Loans' AS market,
       count(*) FILTER (WHERE listed_at IS NULL) AS skipped_missing_listed_at,
       0::bigint AS skipped_unmapped_category
FROM public.loan_requests
UNION ALL
SELECT 'Forex', count(*) FILTER (WHERE listed_at IS NULL), 0::bigint
FROM public.forex_requests
UNION ALL
SELECT 'Needs',
       count(*) FILTER (WHERE listed_at IS NULL),
       count(*) FILTER (
         WHERE category_slug IS NULL
            OR category_slug NOT IN (
              'machinery_equipment', 'professional_services', 'transport_logistics',
              'specialized_products', 'travel_international'
            )
       )
FROM public.needs_requests
ORDER BY 1;

SELECT 'Loans' AS market, id AS request_id, listed_at, expires_at, status::text AS status
FROM public.loan_requests
WHERE listed_at IS NULL
UNION ALL
SELECT 'Forex', id, listed_at, expires_at, status::text
FROM public.forex_requests
WHERE listed_at IS NULL;

SELECT 'Loans' AS market, count(*) AS active_expiry_mismatches
FROM public.loan_requests lr
JOIN private.expiry_duration_v1 d ON d.market = 'Loans'
WHERE lr.status::text = 'active'
  AND lr.listed_at IS NOT NULL
  AND lr.expires_at IS DISTINCT FROM lr.listed_at + make_interval(days => d.days)
UNION ALL
SELECT 'Forex', count(*)
FROM public.forex_requests fr
JOIN private.expiry_duration_v1 d ON d.market = 'Forex'
WHERE fr.status::text = 'active'
  AND fr.listed_at IS NOT NULL
  AND fr.expires_at IS DISTINCT FROM fr.listed_at + make_interval(days => d.days)
UNION ALL
SELECT 'Needs', count(*)
FROM public.needs_requests nr
WHERE nr.status::text = 'active'
  AND nr.listed_at IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM private.expiry_duration_v1 d
    WHERE d.market = 'Needs' AND d.category_slug = nr.category_slug
      AND nr.expires_at IS NOT DISTINCT FROM nr.listed_at + make_interval(days => d.days)
  )
ORDER BY 1;

-- Preserve the current expiry function and trigger names while applying the
-- table-specific configured setting. Existing Loan and Forex trigger wiring
-- remains in place; Needs receives the matching insert trigger.
CREATE OR REPLACE FUNCTION public.trg_fn_set_listing_expiry()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $function$
DECLARE
  v_setting_key text;
  v_days integer;
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

  NEW.expires_at := NEW.listed_at + make_interval(days => v_days);
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_set_needs_listing_expiry ON public.needs_requests;
CREATE TRIGGER trg_set_needs_listing_expiry
  BEFORE INSERT ON public.needs_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_set_listing_expiry();

-- Existing feeds and recommendation queries already filter on active status.
-- The migration expires overdue rows below and schedules future status sweeps,
-- so their output schemas, grants, and dependent functions remain untouched.

-- Fail closed for new offers and offer acceptance when a parent listing is
-- inactive, expired, or has no reliable expiry value. Existing validation and
-- acceptance RPC security checks remain in force.
CREATE OR REPLACE FUNCTION private.trg_guard_offer_live_listing_expiry_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $function$
DECLARE
  v_status text;
  v_expires_at timestamptz;
BEGIN
  IF TG_TABLE_NAME = 'loan_offers' THEN
    SELECT status::text, expires_at INTO v_status, v_expires_at
    FROM public.loan_requests WHERE id = NEW.request_id;
  ELSIF TG_TABLE_NAME = 'forex_offers' THEN
    SELECT status::text, expires_at INTO v_status, v_expires_at
    FROM public.forex_requests WHERE id = NEW.request_id;
  ELSIF TG_TABLE_NAME = 'need_offers' THEN
    SELECT status::text, expires_at INTO v_status, v_expires_at
    FROM public.needs_requests WHERE request_id = NEW.need_id;
  ELSE
    RAISE EXCEPTION 'Unsupported offer table for expiry guard: %', TG_TABLE_NAME;
  END IF;

  IF v_status IS DISTINCT FROM 'active'
     OR v_expires_at IS NULL
     OR v_expires_at <= clock_timestamp() THEN
    RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE_OR_EXPIRED: Offers require an active, unexpired listing.'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_offer_listing_expiry_v1 ON public.loan_offers;
CREATE TRIGGER trg_guard_offer_listing_expiry_v1
  BEFORE INSERT ON public.loan_offers
  FOR EACH ROW EXECUTE FUNCTION private.trg_guard_offer_live_listing_expiry_v1();

DROP TRIGGER IF EXISTS trg_guard_offer_listing_expiry_v1 ON public.forex_offers;
CREATE TRIGGER trg_guard_offer_listing_expiry_v1
  BEFORE INSERT ON public.forex_offers
  FOR EACH ROW EXECUTE FUNCTION private.trg_guard_offer_live_listing_expiry_v1();

DROP TRIGGER IF EXISTS trg_guard_offer_listing_expiry_v1 ON public.need_offers;
CREATE TRIGGER trg_guard_offer_listing_expiry_v1
  BEFORE INSERT ON public.need_offers
  FOR EACH ROW EXECUTE FUNCTION private.trg_guard_offer_live_listing_expiry_v1();

CREATE OR REPLACE FUNCTION private.trg_guard_listing_acceptance_expiry_v1()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $function$
BEGIN
  IF NEW.status::text IN ('contracted', 'matched')
     AND (OLD.status::text <> 'active'
          OR NEW.expires_at IS NULL
          OR NEW.expires_at <= clock_timestamp()) THEN
    RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE_OR_EXPIRED: An inactive or expired listing cannot accept an offer.'
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_listing_acceptance_expiry_v1 ON public.loan_requests;
CREATE TRIGGER trg_guard_listing_acceptance_expiry_v1
  BEFORE UPDATE OF status ON public.loan_requests
  FOR EACH ROW EXECUTE FUNCTION private.trg_guard_listing_acceptance_expiry_v1();

DROP TRIGGER IF EXISTS trg_guard_listing_acceptance_expiry_v1 ON public.forex_requests;
CREATE TRIGGER trg_guard_listing_acceptance_expiry_v1
  BEFORE UPDATE OF status ON public.forex_requests
  FOR EACH ROW EXECUTE FUNCTION private.trg_guard_listing_acceptance_expiry_v1();

DROP TRIGGER IF EXISTS trg_guard_listing_acceptance_expiry_v1 ON public.needs_requests;
CREATE TRIGGER trg_guard_listing_acceptance_expiry_v1
  BEFORE UPDATE OF status ON public.needs_requests
  FOR EACH ROW EXECUTE FUNCTION private.trg_guard_listing_acceptance_expiry_v1();

-- Recalculate only active, classifiable rows. Re-running computes the same
-- listed_at-relative deadline and writes only rows whose value actually differs.
CREATE OR REPLACE FUNCTION private.expire_marketplace_posts_v1()
RETURNS TABLE (loan_posts_expired integer, forex_posts_expired integer, needs_posts_expired integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $function$
BEGIN
  UPDATE public.loan_requests
  SET status = 'expired'
  WHERE status::text = 'active'
    AND expires_at IS NOT NULL
    AND expires_at <= clock_timestamp();
  GET DIAGNOSTICS loan_posts_expired = ROW_COUNT;

  UPDATE public.forex_requests
  SET status = 'expired'
  WHERE status::text = 'active'
    AND expires_at IS NOT NULL
    AND expires_at <= clock_timestamp();
  GET DIAGNOSTICS forex_posts_expired = ROW_COUNT;

  UPDATE public.needs_requests
  SET status = 'expired'
  WHERE status::text = 'active'
    AND expires_at IS NOT NULL
    AND expires_at <= clock_timestamp();
  GET DIAGNOSTICS needs_posts_expired = ROW_COUNT;

  RETURN NEXT;
END;
$function$;

REVOKE ALL ON FUNCTION private.expire_marketplace_posts_v1()
  FROM PUBLIC, anon, authenticated;

DO $backfill$
DECLARE
  v_loan_days integer;
  v_forex_days integer;
  v_loan_expired integer;
  v_forex_expired integer;
  v_needs_expired integer;
  v_loan_updates integer;
  v_forex_updates integer;
  v_needs_updates integer;
BEGIN
  SELECT days INTO v_loan_days FROM private.expiry_duration_v1 WHERE market = 'Loans';
  SELECT days INTO v_forex_days FROM private.expiry_duration_v1 WHERE market = 'Forex';

  UPDATE public.loan_requests lr
  SET expires_at = lr.listed_at + make_interval(days => v_loan_days)
  WHERE lr.status::text = 'active'
    AND lr.listed_at IS NOT NULL
    AND lr.expires_at IS DISTINCT FROM lr.listed_at + make_interval(days => v_loan_days);
  GET DIAGNOSTICS v_loan_updates = ROW_COUNT;

  UPDATE public.forex_requests fr
  SET expires_at = fr.listed_at + make_interval(days => v_forex_days)
  WHERE fr.status::text = 'active'
    AND fr.listed_at IS NOT NULL
    AND fr.expires_at IS DISTINCT FROM fr.listed_at + make_interval(days => v_forex_days);
  GET DIAGNOSTICS v_forex_updates = ROW_COUNT;

  UPDATE public.needs_requests nr
  SET expires_at = nr.listed_at + make_interval(days => d.days)
  FROM private.expiry_duration_v1 d
  WHERE d.market = 'Needs'
    AND d.category_slug = nr.category_slug
    AND nr.status::text = 'active'
    AND nr.listed_at IS NOT NULL
    AND nr.expires_at IS DISTINCT FROM nr.listed_at + make_interval(days => d.days);
  GET DIAGNOSTICS v_needs_updates = ROW_COUNT;

  SELECT loan_posts_expired, forex_posts_expired, needs_posts_expired
    INTO v_loan_expired, v_forex_expired, v_needs_expired
  FROM private.expire_marketplace_posts_v1();
  RAISE NOTICE 'Expiry backfill: Loans expiry updated %, Forex expiry updated %, Needs expiry updated %.',
    v_loan_updates, v_forex_updates, v_needs_updates;
  RAISE NOTICE 'Newly expired active posts: Loans %, Forex %, Needs %.',
    v_loan_expired, v_forex_expired, v_needs_expired;
END;
$backfill$;

-- Install or refresh the periodic lifecycle sweep when pg_cron is available.
-- Public feeds and offer guards independently enforce expiry if it is not.
DO $schedule$
DECLARE
  v_job_id bigint;
  v_existing_job_id bigint;
BEGIN
  IF to_regnamespace('cron') IS NOT NULL THEN
    FOR v_existing_job_id IN EXECUTE
      'SELECT jobid FROM cron.job WHERE jobname = $1'
      USING 'nipanze-expire-marketplace-posts-v1'
    LOOP
      EXECUTE 'SELECT cron.unschedule($1)' USING v_existing_job_id;
    END LOOP;

    EXECUTE
      'SELECT cron.schedule($1, $2, $3)'
      INTO v_job_id
      USING 'nipanze-expire-marketplace-posts-v1',
            '*/5 * * * *',
      'SELECT * FROM private.expire_marketplace_posts_v1()';
    RAISE NOTICE 'Scheduled marketplace expiry sweep as pg_cron job %.', v_job_id;
  ELSE
    RAISE NOTICE 'pg_cron is not installed: posts remain hidden and offer/acceptance-guarded at expiry, but automatic status transitions require scheduling private.expire_marketplace_posts_v1().';
  END IF;
END;
$schedule$;

-- After-migration audit and invariants.
SELECT 'Loans' AS market, status::text AS status, count(*) AS posts,
       count(*) FILTER (WHERE expires_at IS NULL) AS missing_expiry,
       count(*) FILTER (WHERE listed_at IS NULL) AS missing_listed_at
FROM public.loan_requests
GROUP BY status
UNION ALL
SELECT 'Forex', status::text, count(*),
       count(*) FILTER (WHERE expires_at IS NULL),
       count(*) FILTER (WHERE listed_at IS NULL)
FROM public.forex_requests
GROUP BY status
UNION ALL
SELECT 'Needs', status::text, count(*),
       count(*) FILTER (WHERE expires_at IS NULL),
       count(*) FILTER (WHERE listed_at IS NULL)
FROM public.needs_requests
GROUP BY status
ORDER BY 1, 2;

SELECT market, count(*) AS active_posts_with_invalid_expiry
FROM (
  SELECT 'Loans' AS market
  FROM public.loan_requests lr
  JOIN private.expiry_duration_v1 d ON d.market = 'Loans'
  WHERE lr.status::text = 'active'
    AND (lr.listed_at IS NULL
         OR lr.expires_at IS DISTINCT FROM lr.listed_at + make_interval(days => d.days))
  UNION ALL
  SELECT 'Forex'
  FROM public.forex_requests fr
  JOIN private.expiry_duration_v1 d ON d.market = 'Forex'
  WHERE fr.status::text = 'active'
    AND (fr.listed_at IS NULL
         OR fr.expires_at IS DISTINCT FROM fr.listed_at + make_interval(days => d.days))
  UNION ALL
  SELECT 'Needs'
  FROM public.needs_requests nr
  WHERE nr.status::text = 'active'
    AND NOT EXISTS (
      SELECT 1 FROM private.expiry_duration_v1 d
      WHERE d.market = 'Needs' AND d.category_slug = nr.category_slug
        AND nr.listed_at IS NOT NULL
        AND nr.expires_at IS NOT DISTINCT FROM nr.listed_at + make_interval(days => d.days)
    )
) invalid_rows
GROUP BY market
ORDER BY market;

SELECT before_count.market, before_count.status,
       before_count.posts AS terminal_posts_before,
       COALESCE(after_count.posts, 0) AS terminal_posts_after,
       before_count.posts = COALESCE(after_count.posts, 0) AS unchanged
FROM private.expiry_terminal_before_v1 before_count
LEFT JOIN (
  SELECT 'Loans' AS market, status::text AS status, count(*) AS posts
  FROM public.loan_requests WHERE status::text NOT IN ('active', 'expired') GROUP BY status
  UNION ALL
  SELECT 'Forex', status::text, count(*)
  FROM public.forex_requests WHERE status::text NOT IN ('active', 'expired') GROUP BY status
  UNION ALL
  SELECT 'Needs', status::text, count(*)
  FROM public.needs_requests WHERE status::text NOT IN ('active', 'expired') GROUP BY status
) after_count USING (market, status)
ORDER BY market, status;

SELECT
  NOT EXISTS (
    SELECT 1 FROM public.v_loan_listings
    WHERE expires_at IS NULL OR expires_at <= NOW()
  ) AS loan_feed_excludes_expired,
  NOT EXISTS (
    SELECT 1 FROM public.v_forex_listings
    WHERE expires_at IS NULL OR expires_at <= NOW()
  ) AS forex_feed_excludes_expired,
  NOT EXISTS (
    SELECT 1 FROM public.v_needs_listings
    WHERE expires_at IS NULL OR expires_at <= NOW()
  ) AS needs_feed_excludes_expired,
  position(
    'nr.status = ''active'''
    IN lower(pg_get_functiondef('public.get_provider_opportunities(uuid,integer)'::regprocedure))
  ) > 0
  AND position(
    'nr.expires_at is null or nr.expires_at > now()'
    IN lower(pg_get_functiondef('public.get_provider_opportunities(uuid,integer)'::regprocedure))
  ) > 0 AS needs_provider_recommendations_exclude_expired,
  EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid = 'public.loan_offers'::regclass
      AND tgname = 'trg_validate_offer'
      AND tgenabled <> 'D'
  ) AS loan_offer_validation_trigger_preserved,
  EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid = 'public.forex_offers'::regclass
      AND tgname = 'trg_validate_forex_offer'
      AND tgenabled <> 'D'
  ) AS forex_offer_validation_trigger_preserved,
  to_regprocedure('public.accept_offer(uuid,uuid,uuid)') IS NOT NULL
    AS loan_accept_rpc_preserved,
  to_regprocedure('public.accept_forex_offer(uuid,uuid,uuid)') IS NOT NULL
    AS forex_accept_rpc_preserved,
  to_regprocedure('public.accept_need_offer(uuid,uuid)') IS NOT NULL
    AS needs_accept_rpc_preserved;

-- The migration contains no DELETE/TRUNCATE operations and never updates offer,
-- review, or audit tables. Keep that invariant visible in execution output.
DO $no_deletes$
BEGIN
  RAISE NOTICE 'No posts, offers, reviews, or audit records were deleted or reset.';
END;
$no_deletes$;

-- Leave the scratch audit tables in private for SQL-editor reruns and
-- post-run inspection. The next run recreates them from current settings/data.

COMMIT;
