-- ====================================================================
-- NIPANZE CLOUD DB PATCH (v4.3)
-- Run this in the Supabase Cloud SQL Editor to add missing locked
-- repayment terms to existing agreements:
--   1. repayment_period (duration in months)
--   2. total_repayment_amount (principal + interest)
-- ====================================================================

-- ============================================================
-- 1. ADD MISSING COLUMNS (nullable first to avoid constraint
--    violations on existing rows that still have NULL/0)
-- ============================================================

ALTER TABLE public.agreements
    ADD COLUMN IF NOT EXISTS repayment_period       INT,
    ADD COLUMN IF NOT EXISTS total_repayment_amount BIGINT;

-- ============================================================
-- 2. BACKFILL EXISTING LOCKED AGREREEMENTS
--    Derive period from loan_requests.duration_months and
--    total from offer_amount * (1 + interest_rate_pct/100).
-- ============================================================

UPDATE public.agreements a
SET    repayment_period         = lr.duration_months,
       total_repayment_amount   = ROUND(lo.offer_amount * (1 + (lo.interest_rate_pct / 100.0)))::BIGINT
FROM   public.loan_offers   lo
JOIN   public.loan_requests lr ON lr.id = lo.request_id
WHERE  a.offer_id = lo.id
  AND  (a.repayment_period IS NULL OR a.total_repayment_amount IS NULL);

-- ============================================================
-- 3. ENFORCE NOT NULL + CHECK CONSTRAINTS (safe now that data
--    is backfilled)
-- ============================================================

ALTER TABLE public.agreements
    ALTER COLUMN repayment_period       SET NOT NULL,
    ALTER COLUMN total_repayment_amount SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_agr_period_positive'
          AND conrelid = 'public.agreements'::regclass
    ) THEN
        ALTER TABLE public.agreements
            ADD CONSTRAINT chk_agr_period_positive CHECK (repayment_period > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_agr_total_positive'
          AND conrelid = 'public.agreements'::regclass
    ) THEN
        ALTER TABLE public.agreements
            ADD CONSTRAINT chk_agr_total_positive CHECK (total_repayment_amount > 0);
    END IF;
END $$;

-- ============================================================
-- 4. VERIFICATION
-- ============================================================

SELECT 'agreements — repayment_period missing' AS check_name,
       COUNT(*) = 0 AS ok,
       COUNT(*) AS missing_rows
FROM   public.agreements
WHERE  repayment_period IS NULL;

SELECT 'agreements — total_repayment_amount missing' AS check_name,
       COUNT(*) = 0 AS ok,
       COUNT(*) AS missing_rows
FROM   public.agreements
WHERE  total_repayment_amount IS NULL;

SELECT '✅ Cloud Patch v4.3 applied successfully — locked agreements now expose period & total' AS result;
