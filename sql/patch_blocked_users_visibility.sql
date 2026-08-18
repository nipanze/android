-- ============================================================
-- SQL PATCH: Blocked Users & Request Visibility
-- Directional account-level blocking shared by Loans and Forex.
-- Enforces database-level visibility, offer restrictions, and notification filters.
-- Does NOT delete historical contracts, reviews, or audit logs.
-- ============================================================

-- 1. Create table user_blocks
CREATE TABLE IF NOT EXISTS public.user_blocks (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_user_blocks_pair UNIQUE (blocker_id, blocked_id),
    CONSTRAINT chk_user_blocks_not_self CHECK (blocker_id <> blocked_id)
);

COMMENT ON TABLE public.user_blocks IS
'Directional account-level blocks. If A blocks B, B cannot discover, deep-link, or offer on
 A''s future loan or forex requests. Existing contracts, reviews, and audit history are kept.';

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker_id ON public.user_blocks (blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked_id ON public.user_blocks (blocked_id);

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

-- 2. Helper function to check directional block for future requests
CREATE OR REPLACE FUNCTION private.is_blocked_from_future_request(
    p_owner_id UUID,
    p_viewer_id UUID,
    p_listed_at TIMESTAMP
)
RETURNS BOOLEAN LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public AS $$
    SELECT p_owner_id IS NOT NULL
       AND p_viewer_id IS NOT NULL
       AND p_owner_id <> p_viewer_id
       AND EXISTS (
           SELECT 1
           FROM public.user_blocks ub
           WHERE ub.blocker_id = p_owner_id
             AND ub.blocked_id = p_viewer_id
             AND ub.created_at <= COALESCE(p_listed_at, CURRENT_TIMESTAMP)
       );
$$;

GRANT EXECUTE ON FUNCTION private.is_blocked_from_future_request(UUID, UUID, TIMESTAMP)
    TO authenticated, service_role;

-- 3. RLS policy for user_blocks
DROP POLICY IF EXISTS "user_blocks: blocker manages rows" ON public.user_blocks;
CREATE POLICY "user_blocks: blocker manages rows"
    ON public.user_blocks FOR ALL TO authenticated
    USING (blocker_id = auth.uid() OR private.is_admin())
    WITH CHECK (blocker_id = auth.uid() OR private.is_admin());

-- 4. RLS policy for loan_requests
DROP POLICY IF EXISTS "loan_requests: marketplace read" ON public.loan_requests;
CREATE POLICY "loan_requests: marketplace read"
    ON public.loan_requests FOR SELECT TO authenticated
    USING (
        borrower_id = auth.uid()
        OR private.is_admin()
        OR (
            status = 'active'
            AND NOT private.is_blocked_from_future_request(borrower_id, auth.uid(), listed_at)
        )
    );

-- 5. RLS policy for loan_offers
DROP POLICY IF EXISTS "loan_offers: lender insert" ON public.loan_offers;
CREATE POLICY "loan_offers: lender insert"
    ON public.loan_offers FOR INSERT TO authenticated
    WITH CHECK (
        lender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.loan_requests lr
             WHERE lr.id = loan_offers.request_id
               AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
        )
    );

-- 6. Offer validation trigger for loan_offers
CREATE OR REPLACE FUNCTION public.trg_fn_validate_offer()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_listing    loan_requests%ROWTYPE;
    v_min_offer  BIGINT;
    v_plan       subscription_plan_enum;
BEGIN
    SELECT * INTO v_listing FROM loan_requests WHERE id = NEW.request_id;

    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE: This listing is no longer accepting bids.'
            USING ERRCODE = 'P0010';
    END IF;

    IF v_listing.expires_at < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_EXPIRED: This listing has expired.'
            USING ERRCODE = 'P0011';
    END IF;

    IF v_listing.borrower_id = NEW.lender_id THEN
        RAISE EXCEPTION 'NIPANZE_SELF_OFFER: You cannot make a bid on your own listing.'
            USING ERRCODE = 'P0012';
    END IF;

    IF private.is_blocked_from_future_request(v_listing.borrower_id, NEW.lender_id, v_listing.listed_at) THEN
        RAISE EXCEPTION 'NIPANZE_BLOCKED: You cannot make a bid on this listing.'
            USING ERRCODE = 'P0017';
    END IF;

    SELECT setting_value::BIGINT INTO v_min_offer
    FROM system_settings
    WHERE setting_key = 'min_offer_amount'
      AND (country = v_listing.country OR country IS NULL)
    ORDER BY country NULLS LAST
    LIMIT 1;

    IF NEW.offer_amount < v_min_offer THEN
        RAISE EXCEPTION 'NIPANZE_MIN_OFFER: Bid amount must be at least %.', v_min_offer
            USING ERRCODE = 'P0013';
    END IF;

    SELECT plan INTO v_plan
    FROM subscriptions
    WHERE user_id = NEW.lender_id AND status = 'active';

    IF v_plan NOT IN ('lender', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Lender or Pro subscription is required to make bids.'
            USING ERRCODE = 'P0014';
    END IF;

    IF NEW.interest_rate_pct IS NULL OR NEW.late_fee_pct IS NULL OR
       NEW.repayment_frequency IS NULL OR NEW.installment_amount IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_BID_TERMS_REQUIRED: Interest, late fee, repayment schedule, and installment amount are required.'
            USING ERRCODE = 'P0016';
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

-- 7. Views for Loan listings
CREATE OR REPLACE VIEW public.v_loan_listings AS
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
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.preferred_bank ELSE NULL END AS preferred_bank,
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

CREATE OR REPLACE VIEW public.v_loan_listing_details AS
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
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.preferred_bank ELSE NULL END AS preferred_bank,
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

-- 8. Policies, triggers, and views for Forex requests (if forex_requests exists)
DO $$
BEGIN
    IF to_regclass('public.forex_requests') IS NOT NULL THEN
        DROP POLICY IF EXISTS "forex_requests: marketplace read" ON public.forex_requests;
        CREATE POLICY "forex_requests: marketplace read"
            ON public.forex_requests FOR SELECT TO authenticated
            USING (
                requester_id = auth.uid()
                OR private.is_admin()
                OR (
                    status = 'active'
                    AND NOT private.is_blocked_from_future_request(requester_id, auth.uid(), listed_at)
                )
            );

        DROP POLICY IF EXISTS "forex_offers: offer_maker insert" ON public.forex_offers;
        CREATE POLICY "forex_offers: offer_maker insert"
            ON public.forex_offers FOR INSERT TO authenticated
            WITH CHECK (
                offer_maker_id = auth.uid()
                AND EXISTS (
                    SELECT 1 FROM public.forex_requests fr
                     WHERE fr.id = forex_offers.request_id
                       AND NOT private.is_blocked_from_future_request(fr.requester_id, auth.uid(), fr.listed_at)
                )
            );
    END IF;
END $$;

CREATE OR REPLACE FUNCTION public.trg_fn_validate_forex_offer()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_listing forex_requests%ROWTYPE;
    v_plan subscription_plan_enum;
BEGIN
    SELECT * INTO v_listing FROM forex_requests WHERE id = NEW.request_id;

    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_LISTING_NOT_ACTIVE: This forex request is no longer accepting offers.'
            USING ERRCODE = 'P0010';
    END IF;

    IF v_listing.expires_at < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_LISTING_EXPIRED: This forex request has expired.'
            USING ERRCODE = 'P0011';
    END IF;

    IF v_listing.requester_id = NEW.offer_maker_id THEN
        RAISE EXCEPTION 'NIPANZE_SELF_OFFER: You cannot make an offer on your own forex request.'
            USING ERRCODE = 'P0012';
    END IF;

    IF private.is_blocked_from_future_request(v_listing.requester_id, NEW.offer_maker_id, v_listing.listed_at) THEN
        RAISE EXCEPTION 'NIPANZE_BLOCKED: You cannot make an offer on this forex request.'
            USING ERRCODE = 'P0017';
    END IF;

    SELECT plan INTO v_plan
    FROM subscriptions
    WHERE user_id = NEW.offer_maker_id AND status = 'active';

    IF v_plan NOT IN ('lender', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Lender or Pro subscription is required to make forex offers.'
            USING ERRCODE = 'P0014';
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

CREATE OR REPLACE VIEW public.v_forex_listings AS
SELECT
    fr.id AS request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount,
    fr.country,
    fr.settlement_preference,
    fr.is_urgent,
    fr.preferred_rate,
    fr.terms_locked_at,
    fr.status,
    fr.number_of_offers,
    CASE WHEN fr.number_of_offers = 0 THEN 'low' WHEN fr.number_of_offers <= 2 THEN 'medium' ELSE 'high' END AS rate_coverage_tier,
    fr.listed_at,
    fr.expires_at,
    k.status AS kyc_status,
    ta.rating_avg AS trust_rating_avg,
    COALESCE(ta.review_count, 0) AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0) AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE) AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL) AS trust_phone_verified,
    ta.response_time_bucket AS trust_response_time_bucket,
    (k.status = 'approved') AS trust_is_verified,
    GREATEST(fr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
    (fr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
    (fr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.preferred_bank ELSE NULL END AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.institution_type ELSE NULL END AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.is_bank_agent ELSE FALSE END AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN TRUE ELSE FALSE END AS show_professional_tag
FROM public.forex_requests fr
JOIN public.profiles p ON p.id = fr.requester_id
LEFT JOIN public.kyc_verifications k ON k.user_id = fr.requester_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = fr.requester_id
WHERE fr.status = 'active'
  AND (auth.uid() IS NULL OR fr.requester_id <> auth.uid())
  AND NOT private.is_blocked_from_future_request(fr.requester_id, auth.uid(), fr.listed_at)
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.forex_offers fo
      WHERE fo.request_id = fr.id
        AND fo.offer_maker_id = auth.uid()
        AND fo.status IN ('pending', 'accepted')
    )
  );

-- 9. Notification filtering for blocked requests
DROP POLICY IF EXISTS "notifications: own rows" ON public.notifications;
CREATE POLICY "notifications: own rows"
    ON public.notifications FOR SELECT TO authenticated USING (
        user_id = auth.uid()
        AND (
            request_id IS NULL
            OR NOT EXISTS (
                SELECT 1 FROM public.loan_requests lr
                 WHERE lr.id = notifications.request_id
                   AND private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
            )
        )
        AND (
            forex_request_id IS NULL
            OR NOT EXISTS (
                SELECT 1 FROM public.forex_requests fr
                 WHERE fr.id = notifications.forex_request_id
                   AND private.is_blocked_from_future_request(fr.requester_id, auth.uid(), fr.listed_at)
            )
        )
    );

-- 10. Table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_blocks TO authenticated, service_role;
GRANT SELECT ON public.v_loan_listings, public.v_loan_listing_details, public.v_forex_listings TO authenticated, anon;
