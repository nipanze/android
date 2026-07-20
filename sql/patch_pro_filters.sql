-- ============================================
-- NIPANZE PATCH — Pro Advanced Marketplace Filters
-- Schema v4.1 → v4.2 (additive, non-breaking)
-- ============================================
--
-- WHAT THIS ADDS
-- Pro-plan users get an "Advanced Filters" layer on the marketplace feed:
--   - employment_type   (category: government_employee / employed / self_employed /
--                         small_business_owner / business_owner / student / other)
--   - income_bracket     (bucketed: under_2m / 2m_5m / 5m_10m / over_10m)
--   - has_suggested_terms (Pro-posted listings with locked interest/late fee/schedule)
--   - owner_verified      (KYC-approved flag — same signal already public elsewhere)
--
-- WHAT THIS DELIBERATELY DOES NOT ADD
-- - employer_name is never exposed via any marketplace-facing view or RPC.
-- - No "bank name" field is introduced. There is no bank_name column on profiles,
--   and this patch does not add one. Exposing a specific bank/employer would
--   re-identify borrowers and conflicts with the Anonymity-by-default and
--   Selective Transparency principles already committed in BUILD_PLAN.md /
--   README.md. employment_type (category) + income_bracket (bucketed) give
--   Pro users real signal without that risk.
-- - monthly_income_ugx itself is never exposed — only its bucket.
--
-- GATING MODEL
-- Mirrors v_trust_profile_pro: the view is NOT security_invoker, so it can read
-- across profiles (bypassing the "own row only" RLS policy on profiles), but it
-- gates itself with an explicit EXISTS(...) check against the caller's own
-- active Pro subscription. A non-Pro caller querying this view directly
-- (bypassing the Flutter UI entirely) gets zero rows — enforced at the DB
-- layer, not the client, consistent with constraint 3 ("DB is the gate").
-- ============================================


-- --------------------------------------------
-- 1. Income bucketing helper
-- Never returns the exact figure — only a coarse bracket.
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_income_bracket(p_monthly_income_ugx BIGINT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN p_monthly_income_ugx IS NULL THEN NULL
        WHEN p_monthly_income_ugx < 2000000  THEN 'under_2m'
        WHEN p_monthly_income_ugx < 5000000  THEN '2m_5m'
        WHEN p_monthly_income_ugx < 10000000 THEN '5m_10m'
        ELSE 'over_10m'
    END;
$$;

COMMENT ON FUNCTION public.fn_income_bracket(BIGINT) IS
'Buckets monthly_income_ugx into a coarse range. Used only to power Pro-tier
 marketplace filters — never returns or logs the exact figure.';


-- --------------------------------------------
-- 2. Pro-gated filter view
-- --------------------------------------------
CREATE OR REPLACE VIEW public.v_marketplace_pro_filters AS
SELECT
    lr.id                                            AS request_id,
    p.employment_type,
    public.fn_income_bracket(p.monthly_income_ugx)   AS income_bracket,
    (lr.suggested_interest_rate_pct IS NOT NULL
        OR lr.suggested_late_fee_pct IS NOT NULL
        OR lr.suggested_repayment_frequency IS NOT NULL)
                                                      AS has_suggested_terms,
    (k.status = 'approved')                          AS owner_verified
FROM  public.loan_requests lr
JOIN  public.profiles p ON p.id = lr.borrower_id
LEFT  JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid()
        AND s.status = 'active'
        AND s.plan = 'pro'
  );

COMMENT ON VIEW public.v_marketplace_pro_filters IS
'Pro-only marketplace filter signals: employment category, bucketed income range,
 whether the request carries Pro-suggested terms, and owner KYC-verified status.
 Never exposes employer_name, bank name, or exact income. Self-gated: returns
 zero rows to any caller without an active Pro subscription, so a non-Pro user
 querying this view directly (bypassing the app UI) gets nothing — same pattern
 as v_trust_profile_pro.';

GRANT SELECT ON public.v_marketplace_pro_filters TO authenticated;
REVOKE SELECT ON public.v_marketplace_pro_filters FROM anon;


-- --------------------------------------------
-- 3. Supporting index (employment_type filter will be queried often by Pro users)
-- --------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profiles_employment_type
    ON public.profiles (employment_type);


-- --------------------------------------------
-- 4. Optional convenience RPC
-- Returns just the matching request_ids for a given filter set, so the Flutter
-- client can pass filters in one call instead of pulling the whole view and
-- filtering client-side. Same Pro-gating as the view (belt and suspenders —
-- RLS-less views can't be policy-gated the normal way, so the gate lives in
-- the WHERE EXISTS above; this RPC just adds a friendlier client contract).
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.get_marketplace_pro_filtered(
    p_employment_types employment_type_enum[] DEFAULT NULL,
    p_income_brackets  TEXT[]                 DEFAULT NULL,
    p_suggested_terms_only BOOLEAN            DEFAULT FALSE,
    p_verified_only         BOOLEAN           DEFAULT FALSE
)
RETURNS TABLE (request_id UUID)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT f.request_id
    FROM v_marketplace_pro_filters f
    WHERE (p_employment_types IS NULL OR f.employment_type = ANY (p_employment_types))
      AND (p_income_brackets  IS NULL OR f.income_bracket  = ANY (p_income_brackets))
      AND (p_suggested_terms_only = FALSE OR f.has_suggested_terms = TRUE)
      AND (p_verified_only         = FALSE OR f.owner_verified = TRUE);
$$;

COMMENT ON FUNCTION public.get_marketplace_pro_filtered IS
'Pro-tier advanced filter RPC. Delegates gating to v_marketplace_pro_filters,
 which returns no rows for non-Pro callers, so a Free/Lender caller hitting
 this RPC directly simply gets an empty result set — never an error that
 leaks plan-gating logic, and never partial data.';

REVOKE EXECUTE ON FUNCTION public.get_marketplace_pro_filtered FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.get_marketplace_pro_filtered TO authenticated, service_role;
