-- ================================================================
-- NIPANZE Stage 4 — participant bid-book fix
-- Paste into the Supabase Cloud SQL Editor and run once.
-- Safe to re-run.
--
-- Why: an offer-maker's normal RLS policy permits only their own offer.
-- The guarded RPC below must be SECURITY DEFINER to return all anonymised
-- competing offers after it has verified participation on this request.
-- ================================================================

CREATE OR REPLACE FUNCTION public.get_public_listing_offers(p_request_id UUID)
RETURNS TABLE (
    id                    UUID,
    request_id            UUID,
    lender_id             TEXT,
    offer_amount          BIGINT,
    interest_rate_pct     NUMERIC,
    late_fee_pct          NUMERIC,
    repayment_frequency   TEXT,
    installment_amount    BIGINT,
    proposed_expectations TEXT,
    terms_locked_at       TIMESTAMP,
    status                TEXT,
    offered_at            TIMESTAMP,
    accepted_at           TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_can_view_terms BOOLEAN;
BEGIN
    -- The caller must own the listing or have made an offer on it.
    SELECT lr.borrower_id = auth.uid()
        OR EXISTS (
            SELECT 1
            FROM public.loan_offers own_offer
            WHERE own_offer.request_id = lr.id
              AND own_offer.lender_id = auth.uid()
        )
    INTO v_can_view_terms
    FROM public.loan_requests lr
    WHERE lr.id = p_request_id;

    -- Never return partial rows to a non-participant: public aggregate
    -- signals come from v_loan_listings instead.
    IF NOT COALESCE(v_can_view_terms, FALSE) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        lo.id,
        lo.request_id,
        ('public-offer-' || ROW_NUMBER() OVER (ORDER BY lo.offered_at ASC))::TEXT,
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
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) TO authenticated;

SELECT
    p.prosecdef AS runs_as_definer,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_can_execute
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'get_public_listing_offers'
  AND pg_get_function_identity_arguments(p.oid) = 'p_request_id uuid';
