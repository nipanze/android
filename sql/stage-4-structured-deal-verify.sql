-- ============================================================
-- NIPANZE Stage 4 — Structured Deal verification
-- Paste into Supabase SQL Editor after stage-4-structured-deal-cloud-patch.sql
-- ============================================================

SELECT
    'loan_requests Stage 4 columns' AS check_name,
    COUNT(*) = 5 AS ok,
    ARRAY_AGG(column_name ORDER BY column_name) AS found
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'loan_requests'
  AND column_name IN (
      'suggested_interest_rate_pct',
      'suggested_late_fee_pct',
      'suggested_repayment_frequency',
      'suggested_installment_amount',
      'terms_locked_at'
  );

SELECT
    'loan_offers Stage 4 columns' AS check_name,
    COUNT(*) = 5 AS ok,
    ARRAY_AGG(column_name ORDER BY column_name) AS found
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'loan_offers'
  AND column_name IN (
      'interest_rate_pct',
      'late_fee_pct',
      'repayment_frequency',
      'installment_amount',
      'terms_locked_at'
  );

SELECT
    'Stage 4 triggers' AS check_name,
    COUNT(*) = 4 AS ok,
    ARRAY_AGG(trigger_name ORDER BY trigger_name) AS found
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN ('loan_requests', 'loan_offers')
  AND trigger_name IN (
      'trg_validate_request_terms',
      'trg_lock_request_terms',
      'trg_lock_accepted_offer',
      'trg_lock_offer_terms'
  );

SELECT
    'accept_offer RPC exists' AS check_name,
    EXISTS (
        SELECT 1
          FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'public'
           AND p.proname = 'accept_offer'
           AND pg_get_function_identity_arguments(p.oid) = 'p_request_id uuid, p_offer_id uuid, p_borrower_id uuid'
    ) AS ok;

SELECT
    'public listing view exposes borrower suggestions' AS check_name,
    COUNT(*) = 5 AS ok,
    ARRAY_AGG(column_name ORDER BY column_name) AS found
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'v_loan_listings'
  AND column_name IN (
      'suggested_interest_rate_pct',
      'suggested_late_fee_pct',
      'suggested_repayment_frequency',
      'suggested_installment_amount',
      'terms_locked_at'
  );

SELECT
    'locked contracts generated' AS check_name,
    COUNT(*) AS locked_agreement_count
FROM public.agreements
WHERE status = 'locked';

SELECT
    'pending bids missing required terms' AS check_name,
    COUNT(*) = 0 AS ok,
    COUNT(*) AS bad_row_count
FROM public.loan_offers
WHERE status = 'pending'
  AND (
      interest_rate_pct IS NULL OR
      late_fee_pct IS NULL OR
      repayment_frequency IS NULL OR
      installment_amount IS NULL OR
      terms_locked_at IS NULL
  );

SELECT
    'get_public_listing_offers RPC exists' AS check_name,
    EXISTS (
        SELECT 1
          FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'public'
           AND p.proname = 'get_public_listing_offers'
           AND pg_get_function_identity_arguments(p.oid) = 'p_request_id uuid'
    ) AS ok;
