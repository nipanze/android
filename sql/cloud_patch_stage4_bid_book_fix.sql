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
    v_is_owner BOOLEAN := FALSE;
    v_is_offer_maker BOOLEAN := FALSE;
BEGIN
    -- The caller must own the listing or have made an active offer on it.
    SELECT lr.borrower_id = auth.uid() INTO v_is_owner
    FROM public.loan_requests lr
    WHERE lr.id = p_request_id;

    SELECT EXISTS (
        SELECT 1
        FROM public.loan_offers own_offer
        WHERE own_offer.request_id = p_request_id
          AND own_offer.lender_id = auth.uid()
          AND own_offer.status IN ('pending', 'accepted')
    ) INTO v_is_offer_maker;

    IF NOT COALESCE(v_is_owner, FALSE) AND NOT COALESCE(v_is_offer_maker, FALSE) THEN
        RETURN;
    END IF;

    IF COALESCE(v_is_owner, FALSE) THEN
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
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        lo.id,
        lo.request_id,
        ('your-offer')::TEXT,
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
      AND lo.lender_id = auth.uid()
      AND lo.status IN ('pending', 'accepted');
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
