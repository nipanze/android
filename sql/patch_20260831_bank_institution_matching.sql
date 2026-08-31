-- SQL Patch: Bank & Credit Institution Matching
-- Enables borrowers to opt into institution matching for free, and allows Pro agents to filter matching listings.

-- 1. Add allow_institution_matching to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS allow_institution_matching BOOLEAN DEFAULT FALSE NOT NULL;
COMMENT ON COLUMN public.profiles.allow_institution_matching IS
'When true, user opts into having their loan requests tagged and discoverable by verified bank/institution agents.';

-- 2. Update v_loan_listings to expose allow_institution_matching & preferred_bank when matching is enabled
-- DROP first because CREATE OR REPLACE cannot reorder/rename existing view columns
DROP VIEW IF EXISTS public.v_loan_listing_details CASCADE;
DROP VIEW IF EXISTS public.v_loan_listings CASCADE;
CREATE VIEW public.v_loan_listings AS
SELECT
    lr.id AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
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
    CASE WHEN lr.number_of_offers = 0 THEN 'low' WHEN lr.number_of_offers <= 2 THEN 'medium' ELSE 'high' END AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status AS kyc_status,
    ta.rating_avg AS trust_rating_avg,
    COALESCE(ta.review_count, 0) AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0) AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE) AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL) AS trust_phone_verified,
    ta.response_time_bucket AS trust_response_time_bucket,
    (k.status = 'approved') AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h,
    p.allow_institution_matching,
    CASE
        WHEN p.allow_institution_matching THEN p.preferred_bank
        WHEN p.show_professional_tag AND EXISTS (
            SELECT 1 FROM public.subscriptions s
            WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
        ) THEN p.preferred_bank
        ELSE NULL
    END AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.institution_type ELSE NULL END AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.is_bank_agent ELSE FALSE END AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN TRUE ELSE FALSE END AS show_professional_tag,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.has_collateral ELSE FALSE END AS has_collateral,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_details ELSE NULL END AS collateral_details,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_estimated_value ELSE NULL END AS collateral_estimated_value,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_location ELSE NULL END AS collateral_location
FROM public.loan_requests lr
JOIN public.profiles p ON p.id = lr.borrower_id
JOIN public.countries c ON c.code = lr.country
LEFT JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND (auth.uid() IS NULL OR lr.borrower_id <> auth.uid())
  AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.loan_offers lo
      WHERE lo.request_id = lr.id
        AND lo.lender_id = auth.uid()
        AND lo.status IN ('pending', 'accepted')
    )
  );

-- 3. Update v_loan_listing_details
CREATE VIEW public.v_loan_listing_details AS
SELECT
    lr.id AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
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
    CASE WHEN lr.number_of_offers = 0 THEN 'low' WHEN lr.number_of_offers <= 2 THEN 'medium' ELSE 'high' END AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status AS kyc_status,
    ta.rating_avg AS trust_rating_avg,
    COALESCE(ta.review_count, 0) AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0) AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE) AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL) AS trust_phone_verified,
    ta.response_time_bucket AS trust_response_time_bucket,
    (k.status = 'approved') AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h,
    p.allow_institution_matching,
    CASE
        WHEN p.allow_institution_matching THEN p.preferred_bank
        WHEN p.show_professional_tag AND EXISTS (
            SELECT 1 FROM public.subscriptions s
            WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
        ) THEN p.preferred_bank
        ELSE NULL
    END AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.institution_type ELSE NULL END AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.is_bank_agent ELSE FALSE END AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN TRUE ELSE FALSE END AS show_professional_tag,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.has_collateral ELSE FALSE END AS has_collateral,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_details ELSE NULL END AS collateral_details,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_estimated_value ELSE NULL END AS collateral_estimated_value,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_location ELSE NULL END AS collateral_location
FROM public.loan_requests lr
JOIN public.profiles p ON p.id = lr.borrower_id
JOIN public.countries c ON c.code = lr.country
LEFT JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at);

-- 4. Update get_marketplace_pro_filtered to support p_institution_match_only
CREATE OR REPLACE FUNCTION get_marketplace_pro_filtered(
    p_employment_type        employment_type_enum DEFAULT NULL,
    p_income_bracket         TEXT                  DEFAULT NULL,
    p_suggested_terms_only   BOOLEAN               DEFAULT FALSE,
    p_verified_only          BOOLEAN               DEFAULT FALSE,
    p_country                TEXT                  DEFAULT NULL,
    p_institution_match_only BOOLEAN               DEFAULT FALSE
)
RETURNS SETOF v_loan_listings
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM subscriptions
        WHERE user_id = auth.uid() AND status = 'active' AND plan = 'pro'
    ) THEN
        RAISE EXCEPTION 'NIPANZE_PRO_REQUIRED: Advanced marketplace filters require a Pro subscription.'
            USING ERRCODE = 'P0050';
    END IF;

    RETURN QUERY
    SELECT vl.*
    FROM v_loan_listings vl
    JOIN loan_requests lr ON lr.id = vl.request_id
    JOIN profiles p ON p.id = lr.borrower_id
    LEFT JOIN kyc_verifications k ON k.user_id = lr.borrower_id
    WHERE (p_employment_type IS NULL OR p.employment_type = p_employment_type)
      AND (p_income_bracket IS NULL OR fn_income_bracket(p.monthly_income) = p_income_bracket)
      AND (NOT p_suggested_terms_only OR lr.suggested_interest_rate_pct IS NOT NULL)
      AND (NOT p_verified_only OR k.status = 'approved')
      AND (p_country IS NULL OR vl.country = p_country)
      AND (NOT p_institution_match_only OR p.allow_institution_matching = TRUE);
END;
$$;

GRANT SELECT ON public.v_loan_listings, public.v_loan_listing_details TO authenticated, anon;

COMMENT ON VIEW public.v_loan_listings IS
'Anonymised marketplace feed. allow_institution_matching and preferred_bank are now included.
 preferred_bank is exposed when the borrower opts in (allow_institution_matching = true)
 OR when the viewing agent is Pro. Collateral and professional tags remain Pro-masked.';

COMMENT ON VIEW public.v_loan_listing_details IS
'Single-listing detail view for active loan requests. Adds allow_institution_matching
 and conditional preferred_bank exposure matching v_loan_listings logic.';
