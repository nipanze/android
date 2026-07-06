-- ============================================================
-- Request Form Alignment Patch
-- ============================================================
-- Use in Supabase Cloud SQL Editor when an existing project was
-- created before borrower request creation was aligned to:
--   borrower need + income/repayment context
-- while lender offers carry the interest/return terms.
--
-- Safe to run more than once.

BEGIN;

-- Ensure the borrower request fields required by the app exist.
ALTER TABLE public.loan_requests
  ADD COLUMN IF NOT EXISTS income_source TEXT,
  ADD COLUMN IF NOT EXISTS preferred_repayment_plan TEXT,
  ADD COLUMN IF NOT EXISTS repayment_amount_per_period BIGINT,
  ADD COLUMN IF NOT EXISTS repayment_timeline TEXT;

-- Backfill existing rows so NOT NULL constraints can be applied.
UPDATE public.loan_requests
SET
  income_source = COALESCE(NULLIF(income_source, ''), 'Not provided'),
  preferred_repayment_plan = CASE
    WHEN LOWER(COALESCE(preferred_repayment_plan, '')) IN ('weekly', 'week') THEN 'weekly'
    WHEN LOWER(COALESCE(preferred_repayment_plan, '')) LIKE '%week%' THEN 'weekly'
    WHEN LOWER(COALESCE(preferred_repayment_plan, '')) IN ('one_time', 'one-time', 'one time') THEN 'one_time'
    WHEN LOWER(COALESCE(preferred_repayment_plan, '')) LIKE '%one%' THEN 'one_time'
    WHEN LOWER(COALESCE(preferred_repayment_plan, '')) LIKE '%single%' THEN 'one_time'
    ELSE 'monthly'
  END,
  repayment_amount_per_period = COALESCE(
    NULLIF(repayment_amount_per_period, 0),
    GREATEST(requested_amount / GREATEST(duration_months, 1), 1)
  ),
  repayment_timeline = COALESCE(
    NULLIF(repayment_timeline, ''),
    duration_months::TEXT || ' months'
  );

ALTER TABLE public.loan_requests
  ALTER COLUMN income_source SET NOT NULL,
  ALTER COLUMN preferred_repayment_plan SET NOT NULL,
  ALTER COLUMN repayment_amount_per_period SET NOT NULL,
  ALTER COLUMN repayment_timeline SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'chk_lr_repayment_plan'
      AND conrelid = 'public.loan_requests'::regclass
  ) THEN
    ALTER TABLE public.loan_requests
      ADD CONSTRAINT chk_lr_repayment_plan
      CHECK (preferred_repayment_plan IN ('weekly', 'monthly', 'one_time'));
  END IF;

  -- Older schemas made borrower-side interest/risk fields mandatory.
  -- The app no longer sends these values when creating a request.
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'loan_requests'
      AND column_name = 'max_interest_rate'
  ) THEN
    ALTER TABLE public.loan_requests
      ALTER COLUMN max_interest_rate DROP NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'loan_requests'
      AND column_name = 'risk_category'
  ) THEN
    ALTER TABLE public.loan_requests
      ALTER COLUMN risk_category DROP NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'loan_requests'
      AND column_name = 'credit_score_band'
  ) THEN
    ALTER TABLE public.loan_requests
      ALTER COLUMN credit_score_band DROP NOT NULL;
  END IF;
END $$;

-- Keep public marketplace listings aligned with the request fields.
DROP VIEW IF EXISTS public.v_loan_listings;

CREATE VIEW public.v_loan_listings WITH (security_invoker = true) AS
SELECT
  lr.id AS request_id,
  lr.title,
  lr.purpose,
  lr.district,
  lr.duration_months,
  lr.requested_amount,
  lr.preferred_repayment_plan,
  lr.repayment_amount_per_period,
  lr.repayment_timeline,
  lr.status,
  lr.number_of_offers,
  lr.listed_at,
  lr.expires_at,
  k.status AS kyc_status,
  GREATEST(lr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
  (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
  (lr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h
FROM public.loan_requests lr
LEFT JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
WHERE lr.status = 'active';

COMMENT ON VIEW public.v_loan_listings IS
'Anonymised marketplace feed. Borrower contact details, income source, and private documents are not exposed.';

GRANT SELECT ON public.v_loan_listings TO authenticated, anon;

COMMIT;
