-- Patch: hide listings a user has offered on; restrict public bidbook to owners
-- Run this on Supabase Cloud SQL editor. Safe to re-run.

-- 1) Recreate v_loan_listings as caller-aware so authenticated users
--    do not see listings they have an active offer on.
DO $$ BEGIN
  -- Drop existing view if present
  IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema = 'public' AND table_name = 'v_loan_listings') THEN
    EXECUTE 'DROP VIEW IF EXISTS public.v_loan_listings CASCADE';
  END IF;
END $$;

CREATE VIEW public.v_loan_listings
WITH (security_invoker = true) AS
SELECT
    lr.id                                                                    AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    CASE
        WHEN lr.number_of_offers = 0 THEN 'low'
        WHEN lr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                      AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status                                                                 AS kyc_status,
    ta.rating_avg                                                            AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                             AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                    AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                  AS trust_response_time_bucket,
    (k.status = 'approved')                                                  AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h
FROM  loan_requests   lr
JOIN  profiles p ON p.id = lr.borrower_id
LEFT  JOIN kyc_verifications k ON k.user_id = lr.borrower_id
LEFT  JOIN trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  -- hide listings where calling user has an active offer (pending/accepted)
  AND NOT EXISTS (
    SELECT 1 FROM public.loan_offers lo
    WHERE lo.request_id = lr.id
      AND lo.lender_id = auth.uid()
      AND lo.status IN ('pending','accepted')
  );

COMMENT ON VIEW public.v_loan_listings IS
'Anonymised marketplace feed. caller-aware: excludes listings the caller has an active offer on.';


-- 2) Replace get_public_listing_offers RPC so only listing owners see the full
--    anonymised bidbook. Offer-makers may retrieve only their own offer(s).
CREATE OR REPLACE FUNCTION public.get_public_listing_offers(p_request_id UUID)
RETURNS TABLE (
    id                  UUID,
    request_id          UUID,
    lender_id           TEXT,
    offer_amount        BIGINT,
    interest_rate_pct   NUMERIC,
    late_fee_pct        NUMERIC,
    repayment_frequency TEXT,
    installment_amount  BIGINT,
    proposed_expectations TEXT,
    terms_locked_at     TIMESTAMP,
    status              TEXT,
    offered_at          TIMESTAMP,
    accepted_at         TIMESTAMP
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_is_owner BOOLEAN := FALSE;
    v_is_offer_maker BOOLEAN := FALSE;
BEGIN
    SELECT lr.borrower_id = auth.uid() INTO v_is_owner
    FROM public.loan_requests lr
    WHERE lr.id = p_request_id;

    SELECT EXISTS (
        SELECT 1 FROM public.loan_offers own
        WHERE own.request_id = p_request_id
          AND own.lender_id = auth.uid()
          AND own.status IN ('pending','accepted')
    ) INTO v_is_offer_maker;

    -- Non-participants get nothing.
    IF NOT COALESCE(v_is_owner, FALSE) AND NOT COALESCE(v_is_offer_maker, FALSE) THEN
        RETURN;
    END IF;

    -- Listing owner: full anonymised bidbook (same as before)
    IF COALESCE(v_is_owner, FALSE) THEN
        RETURN QUERY
        SELECT
            lo.id,
            lo.request_id,
            ('public-offer-' || ROW_NUMBER() OVER (ORDER BY lo.offered_at ASC))::TEXT AS lender_id,
            lo.offer_amount,
            lo.interest_rate_pct,
            lo.late_fee_pct,
            lo.repayment_frequency,
            lo.installment_amount,
            lo.proposed_expectations,
            lo.terms_locked_at,
            lo.status::TEXT,
            lo.offered_at,
            lo.accepted_at
        FROM public.loan_offers lo
        JOIN public.loan_requests lr ON lr.id = lo.request_id
        WHERE lo.request_id = p_request_id
          AND lo.status = 'pending'
          AND (lr.status = 'active' OR lr.borrower_id = auth.uid())
        ORDER BY lo.offered_at DESC;
        RETURN;
    END IF;

    -- Offer-maker: return only their own offer(s) for this request
    RETURN QUERY
    SELECT
        lo.id,
        lo.request_id,
        ('your-offer')::TEXT AS lender_id,
        lo.offer_amount,
        lo.interest_rate_pct,
        lo.late_fee_pct,
        lo.repayment_frequency,
        lo.installment_amount,
        lo.proposed_expectations,
        lo.terms_locked_at,
        lo.status::TEXT,
        lo.offered_at,
        lo.accepted_at
    FROM public.loan_offers lo
    WHERE lo.request_id = p_request_id
      AND lo.lender_id = auth.uid();
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) TO authenticated;
