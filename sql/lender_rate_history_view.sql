-- sql/lender_rate_history_view.sql
-- Safe, identity-preserving view for lender rate sparklines.
-- Exposes only numeric trend data — no borrower info, no PII.

CREATE OR REPLACE VIEW public.v_lender_rate_history
WITH (security_invoker = true) AS
SELECT
    lender_id,
    interest_rate_pct,
    late_fee_pct,
    installment_amount,
    offered_at,
    ROW_NUMBER() OVER (
        PARTITION BY lender_id ORDER BY offered_at DESC
    ) AS rn
FROM public.loan_offers
WHERE status IN ('pending', 'accepted', 'rejected');

GRANT SELECT ON public.v_lender_rate_history TO authenticated;
ALTER VIEW public.v_lender_rate_history OWNER TO postgres;
