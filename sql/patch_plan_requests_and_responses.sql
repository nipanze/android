-- Plan request and response limits shown on Plans & pricing.
-- Active request capacity is shared by Loans and Needs. Forex is excluded.
-- Apply manually after reviewing; this patch is not run by the app.

BEGIN;

INSERT INTO public.system_settings (
  setting_key, country, setting_value, setting_type, category, description, is_public
)
VALUES
  ('max_active_requests_free', NULL, '3', 'number', 'limits', 'Maximum active requests across Loans and Needs for Free subscribers', TRUE),
  ('max_active_requests_lender', NULL, '8', 'number', 'limits', 'Maximum active requests across Loans and Needs for Provider subscribers', TRUE),
  ('max_active_requests_pro', NULL, '20', 'number', 'limits', 'Maximum active requests across Loans and Needs for Pro subscribers', TRUE),
  ('max_active_responses_lender', NULL, '10', 'number', 'limits', 'Maximum active Needs responses for Provider subscribers', TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO UPDATE
SET setting_value = EXCLUDED.setting_value,
    setting_type = EXCLUDED.setting_type,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    is_public = EXCLUDED.is_public,
    updated_at = NOW();

CREATE OR REPLACE FUNCTION public.get_my_active_request_count()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT (
    (SELECT count(*) FROM public.loan_requests lr
      WHERE lr.borrower_id = auth.uid() AND lr.status::text = 'active') +
    (SELECT count(*) FROM public.needs_requests nr
      WHERE nr.requester_id = auth.uid() AND nr.status::text = 'active')
  )::integer;
$function$;
REVOKE ALL ON FUNCTION public.get_my_active_request_count() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_active_request_count() TO authenticated;

CREATE OR REPLACE FUNCTION public.assert_pro_advanced_filters()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.subscriptions s
    WHERE s.user_id = auth.uid()
      AND s.status = 'active'
      AND (s.expires_at IS NULL OR s.expires_at > now())
      AND s.plan = 'pro'
  ) THEN
    RAISE EXCEPTION 'NIPANZE_PRO_REQUIRED: Advanced marketplace filters require a Pro subscription.'
      USING ERRCODE = 'P0050';
  END IF;
  RETURN true;
END;
$function$;

REVOKE ALL ON FUNCTION public.assert_pro_advanced_filters() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assert_pro_advanced_filters() TO authenticated;

CREATE OR REPLACE FUNCTION public.trg_fn_max_concurrent_requests()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_user_id uuid;
  v_country text;
  v_plan public.subscription_plan_enum;
  v_limit integer;
  v_active integer;
BEGIN
  IF TG_TABLE_NAME = 'loan_requests' THEN
    v_user_id := NEW.borrower_id;
  ELSIF TG_TABLE_NAME = 'needs_requests' THEN
    v_user_id := NEW.requester_id;
  ELSE
    RAISE EXCEPTION 'Unsupported request table: %', TG_TABLE_NAME;
  END IF;
  v_country := NEW.country;

  -- Serialize simultaneous posts for the same account before counting.
  PERFORM pg_advisory_xact_lock(hashtextextended(v_user_id::text, 0));

  SELECT COALESCE(s.plan, 'free'::public.subscription_plan_enum)
    INTO v_plan
  FROM public.profiles p
  LEFT JOIN public.subscriptions s
    ON s.user_id = p.id
   AND s.status = 'active'
   AND (s.expires_at IS NULL OR s.expires_at > now())
  WHERE p.id = v_user_id
  ORDER BY s.created_at DESC NULLS LAST
  LIMIT 1;
  v_plan := COALESCE(v_plan, 'free'::public.subscription_plan_enum);

  SELECT setting_value::integer INTO v_limit
  FROM public.system_settings
  WHERE setting_key = 'max_active_requests_' || v_plan::text
    AND (country = v_country OR country IS NULL)
  ORDER BY country NULLS LAST
  LIMIT 1;
  v_limit := COALESCE(v_limit, CASE v_plan
    WHEN 'free' THEN 3 WHEN 'lender' THEN 8 WHEN 'pro' THEN 20 END);

  SELECT
    (SELECT count(*) FROM public.loan_requests lr
      WHERE lr.borrower_id = v_user_id AND lr.status::text = 'active') +
    (SELECT count(*) FROM public.needs_requests nr
      WHERE nr.requester_id = v_user_id AND nr.status::text = 'active')
    INTO v_active;

  -- An update that keeps the row active does not consume another slot.
  IF TG_OP = 'UPDATE' AND OLD.status::text = 'active'
     AND NEW.status::text = 'active' THEN
    RETURN NEW;
  END IF;

  IF NEW.status::text = 'active' AND v_active >= v_limit THEN
    RAISE EXCEPTION 'NIPANZE_MAX_REQUESTS: You have % of % active requests.', v_active, v_limit
      USING ERRCODE = 'P0002';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_max_concurrent_requests ON public.loan_requests;
CREATE TRIGGER trg_max_concurrent_requests
  BEFORE INSERT OR UPDATE OF status ON public.loan_requests
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_max_concurrent_requests();

DROP TRIGGER IF EXISTS trg_max_concurrent_needs_requests ON public.needs_requests;
CREATE TRIGGER trg_max_concurrent_needs_requests
  BEFORE INSERT OR UPDATE OF status ON public.needs_requests
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_max_concurrent_requests();

CREATE OR REPLACE FUNCTION public.trg_fn_limit_active_need_responses()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_plan public.subscription_plan_enum;
  v_limit integer;
  v_active integer;
BEGIN
  IF NEW.status <> 'pending' OR
     (TG_OP = 'UPDATE' AND OLD.status = 'pending') THEN
    RETURN NEW;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(NEW.offer_maker_id::text, 0));

  SELECT COALESCE(s.plan, 'free'::public.subscription_plan_enum)
    INTO v_plan
  FROM public.profiles p
  LEFT JOIN public.subscriptions s
    ON s.user_id = p.id AND s.status = 'active'
   AND (s.expires_at IS NULL OR s.expires_at > now())
  WHERE p.id = NEW.offer_maker_id
  ORDER BY s.created_at DESC NULLS LAST
  LIMIT 1;
  v_plan := COALESCE(v_plan, 'free'::public.subscription_plan_enum);

  IF v_plan = 'pro' THEN RETURN NEW; END IF;
  IF v_plan <> 'lender' THEN
    RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: Provider or Pro is required to respond to Needs.'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT setting_value::integer INTO v_limit
  FROM public.system_settings
  WHERE setting_key = 'max_active_responses_lender' AND country IS NULL
  LIMIT 1;
  v_limit := COALESCE(v_limit, 10);

  SELECT count(*) INTO v_active
  FROM public.need_offers nof
  JOIN public.needs_requests nr ON nr.request_id = nof.need_id
  WHERE nof.offer_maker_id = NEW.offer_maker_id
    AND nof.status = 'pending'
    AND nr.status::text = 'active'
    AND (nof.expires_at IS NULL OR nof.expires_at > now());

  IF v_active >= v_limit THEN
    RAISE EXCEPTION 'NIPANZE_MAX_RESPONSES: You have % of % active responses.', v_active, v_limit
      USING ERRCODE = 'P0002';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_limit_active_need_responses ON public.need_offers;
CREATE TRIGGER trg_limit_active_need_responses
  BEFORE INSERT OR UPDATE OF status ON public.need_offers
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_limit_active_need_responses();

COMMIT;
