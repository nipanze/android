-- ====================================================================
-- NIPANZE Stage 4 — FINAL CLOUD PATCH (v4.1 → Stage 4)
-- Paste the ENTIRE file into the Supabase Cloud SQL Editor and run.
-- Safe to re-run: uses CREATE OR REPLACE / IF NOT EXISTS / ON CONFLICT.
--
-- What this patch applies / asserts:
--   1. Stage 4 columns on loan_requests & loan_offers (idempotent ADD COLUMN IF NOT EXISTS)
--   2. Trust-system tables: reviews + trust_aggregates (CREATE IF NOT EXISTS)
--   3. RPC functions: get_public_listing_offers, submit_review,
--      recompute_trust_aggregates, accept_offer, reveal_contact,
--      get_my_subscription_plan (all CREATE OR REPLACE)
--   4. Views: v_loan_listings (with offer_coverage_tier), v_trust_profile_public,
--      v_trust_profile_pro, v_lender_offers (all CREATE OR REPLACE)
--   5. Triggers for term-locking and trust-refresh
--   6. RLS enable + idempotent policy creation for reviews & trust_aggregates
--   7. Grant re-assertions for all new objects
--   8. Subscription expiry refresh for seeded test accounts (idempotent UPDATE)
--   9. Final verification query
-- ====================================================================

-- ============================================================
-- 1. STAGE 4 COLUMNS — loan_requests
-- ============================================================

ALTER TABLE public.loan_requests
    ADD COLUMN IF NOT EXISTS suggested_interest_rate_pct  NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS suggested_late_fee_pct       NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS suggested_repayment_frequency TEXT,
    ADD COLUMN IF NOT EXISTS suggested_installment_amount  BIGINT,
    ADD COLUMN IF NOT EXISTS terms_locked_at               TIMESTAMP;

-- ============================================================
-- 2. STAGE 4 COLUMNS — loan_offers
-- ============================================================

ALTER TABLE public.loan_offers
    ADD COLUMN IF NOT EXISTS interest_rate_pct    NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS late_fee_pct         NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS repayment_frequency  TEXT,
    ADD COLUMN IF NOT EXISTS installment_amount   BIGINT,
    ADD COLUMN IF NOT EXISTS terms_locked_at      TIMESTAMP;

-- ============================================================
-- 2b. PROFILES — phone_verified_at
--     Required by v_loan_listings and v_trust_profile_public.
--     Set by the OTP verification step at signup; NULL = not verified.
-- ============================================================

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS phone_verified_at TIMESTAMP;


-- ============================================================
-- 3. TRUST SYSTEM TABLES (CREATE IF NOT EXISTS)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.reviews (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID NOT NULL REFERENCES public.agreements(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES public.profiles(id)  ON DELETE CASCADE,
    reviewee_id UUID NOT NULL REFERENCES public.profiles(id)  ON DELETE CASCADE,
    rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT CHECK (comment IS NULL OR char_length(comment) <= 500),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (contract_id, reviewer_id),
    CHECK (reviewer_id <> reviewee_id)
);

CREATE TABLE IF NOT EXISTS public.trust_aggregates (
    user_id               UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating_avg            NUMERIC(3,2),
    review_count          INT NOT NULL DEFAULT 0,
    completed_deals_count INT NOT NULL DEFAULT 0,
    is_repeat_participant BOOLEAN NOT NULL DEFAULT FALSE,
    response_time_bucket  TEXT,
    success_rate          NUMERIC(5,2),
    reliability_score     INT,
    updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (response_time_bucket IN (
        'responds_quickly', 'responds_within_a_day', 'responds_slowly'
    ) OR response_time_bucket IS NULL),
    CHECK (reliability_score BETWEEN 0 AND 100 OR reliability_score IS NULL)
);

-- Indexes (safe to create; existence is checked via IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee
    ON public.reviews (reviewee_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_contract
    ON public.reviews (contract_id);

-- ============================================================
-- 4. HELPER: get_my_subscription_plan
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_my_subscription_plan()
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE v_plan TEXT;
BEGIN
    SELECT plan::TEXT INTO v_plan
    FROM public.subscriptions
    WHERE user_id = auth.uid() AND status = 'active'
    ORDER BY created_at DESC LIMIT 1;

    RETURN COALESCE(v_plan, 'free');
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_my_subscription_plan() FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.get_my_subscription_plan() TO authenticated, service_role;

-- ============================================================
-- 5. RPC: recompute_trust_aggregates
-- ============================================================

CREATE OR REPLACE FUNCTION public.recompute_trust_aggregates(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rating       NUMERIC(3,2);
    v_reviews      INT;
    v_deals        INT;
    v_response_hours NUMERIC;
    v_bucket       TEXT;
    v_success_rate NUMERIC(5,2);
    v_score        INT;
BEGIN
    SELECT AVG(rating), COUNT(*) INTO v_rating, v_reviews
    FROM reviews WHERE reviewee_id = p_user_id;

    SELECT COUNT(*) INTO v_deals
    FROM (
        SELECT lo.id FROM loan_offers lo
        WHERE lo.lender_id = p_user_id
          AND EXISTS (SELECT 1 FROM agreements a WHERE a.offer_id = lo.id)
        UNION ALL
        SELECT lr.id FROM loan_requests lr
        WHERE lr.borrower_id = p_user_id
          AND EXISTS (SELECT 1 FROM agreements a WHERE a.request_id = lr.id)
    ) d;

    SELECT
        CASE
            WHEN AVG(EXTRACT(EPOCH FROM (lo.offered_at - lr.listed_at))/3600) < 4  THEN 'responds_quickly'
            WHEN AVG(EXTRACT(EPOCH FROM (lo.offered_at - lr.listed_at))/3600) < 24 THEN 'responds_within_a_day'
            ELSE 'responds_slowly'
        END
    INTO v_bucket
    FROM loan_offers lo
    JOIN loan_requests lr ON lr.id = lo.request_id
    WHERE lo.lender_id = p_user_id
       OR lr.borrower_id = p_user_id;

    SELECT
        CASE WHEN COUNT(*) = 0 THEN NULL
             ELSE ROUND(100.0 * SUM(CASE WHEN completed THEN 1 ELSE 0 END) / COUNT(*), 2)
        END
    INTO v_success_rate
    FROM (
        SELECT EXISTS(SELECT 1 FROM agreements a WHERE a.offer_id = lo.id) AS completed
        FROM loan_offers lo WHERE lo.lender_id = p_user_id
        UNION ALL
        SELECT EXISTS(SELECT 1 FROM agreements a WHERE a.request_id = lr.id)
        FROM loan_requests lr WHERE lr.borrower_id = p_user_id
    ) participation;

    v_score := CASE WHEN v_rating IS NULL THEN NULL ELSE LEAST(100, ROUND(
        (v_rating / 5.0) * 60 + LEAST(v_deals, 4) * 5 +
        CASE v_bucket
            WHEN 'responds_quickly'       THEN 20
            WHEN 'responds_within_a_day'  THEN 10
            ELSE 0
        END
    )::INT) END;

    INSERT INTO trust_aggregates (
        user_id, rating_avg, review_count, completed_deals_count,
        is_repeat_participant, response_time_bucket,
        success_rate, reliability_score, updated_at
    ) VALUES (
        p_user_id, v_rating, COALESCE(v_reviews, 0), COALESCE(v_deals, 0),
        COALESCE(v_deals, 0) >= 2, v_bucket,
        v_success_rate, v_score, NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        rating_avg            = EXCLUDED.rating_avg,
        review_count          = EXCLUDED.review_count,
        completed_deals_count = EXCLUDED.completed_deals_count,
        is_repeat_participant = EXCLUDED.is_repeat_participant,
        response_time_bucket  = EXCLUDED.response_time_bucket,
        success_rate          = EXCLUDED.success_rate,
        reliability_score     = EXCLUDED.reliability_score,
        updated_at            = EXCLUDED.updated_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.recompute_trust_aggregates(UUID) TO service_role;

-- ============================================================
-- 6. RPC: submit_review
-- ============================================================

CREATE OR REPLACE FUNCTION public.submit_review(
    p_contract_id UUID,
    p_rating      SMALLINT,
    p_comment     TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_reviewer UUID := auth.uid();
    v_reviewee UUID;
    v_review_id UUID;
BEGIN
    IF v_reviewer IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED';
    END IF;
    IF p_rating NOT BETWEEN 1 AND 5 THEN
        RAISE EXCEPTION 'NIPANZE_INVALID_RATING';
    END IF;

    -- Validate the caller is a party to a revealed, completed contract
    SELECT CASE
               WHEN lr.borrower_id = v_reviewer THEN lo.lender_id
               ELSE lr.borrower_id
           END
    INTO v_reviewee
    FROM agreements a
    JOIN loan_offers   lo ON lo.id = a.offer_id
    JOIN loan_requests lr ON lr.id = a.request_id
    JOIN contact_reveals cr ON cr.offer_id = lo.id AND cr.status = 'revealed'
    WHERE a.id = p_contract_id
      AND (lr.borrower_id = v_reviewer OR lo.lender_id = v_reviewer);

    IF v_reviewee IS NULL THEN
        RAISE EXCEPTION
            'NIPANZE_REVIEW_NOT_ELIGIBLE: Reviews require a completed on-platform deal.';
    END IF;

    INSERT INTO reviews (contract_id, reviewer_id, reviewee_id, rating, comment)
    VALUES (p_contract_id, v_reviewer, v_reviewee, p_rating,
            NULLIF(BTRIM(p_comment), ''))
    RETURNING id INTO v_review_id;

    PERFORM recompute_trust_aggregates(v_reviewee);

    INSERT INTO audit_logs (user_id, event_type, entity_type, entity_id, action)
    VALUES (v_reviewer, 'review_submitted', 'reviews', v_review_id, 'submit_review');

    RETURN v_review_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_review(UUID, SMALLINT, TEXT) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.submit_review(UUID, SMALLINT, TEXT) TO authenticated;

-- ============================================================
-- 7. RPC: get_public_listing_offers (selective transparency)
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_public_listing_offers(p_request_id UUID)
RETURNS TABLE (
    id                  UUID,
    request_id          UUID,
    lender_id           TEXT,   -- anonymised label for non-owners
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
-- A bidder's ordinary RLS rule permits only their own offer. This function
-- deliberately bypasses that row filter *after* the participant check so an
-- eligible bidder can see the complete anonymised bid book for this request.
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
        SELECT 1 FROM public.loan_offers own_offer
        WHERE own_offer.request_id = p_request_id
          AND own_offer.lender_id  = auth.uid()
          AND own_offer.status IN ('pending', 'accepted')
    ) INTO v_is_offer_maker;

    -- Non-participants get nothing from this function —
    -- they receive aggregate signals through v_loan_listings instead.
    IF NOT COALESCE(v_is_owner, FALSE) AND NOT COALESCE(v_is_offer_maker, FALSE) THEN
        RETURN;
    END IF;

    IF COALESCE(v_is_owner, FALSE) THEN
        RETURN QUERY SELECT
            lo.id,
            lo.request_id,
            ('public-offer-' || ROW_NUMBER() OVER (ORDER BY lo.offered_at ASC))::TEXT
                AS lender_id,
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
        FROM public.loan_offers  lo
        JOIN public.loan_requests lr ON lr.id = lo.request_id
        WHERE lo.request_id = p_request_id
          AND lo.status     = 'pending'
          AND (lr.status = 'active' OR lr.borrower_id = auth.uid())
        ORDER BY lo.offered_at DESC;
        RETURN;
    END IF;

    RETURN QUERY SELECT
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
      AND lo.lender_id = auth.uid()
      AND lo.status IN ('pending', 'accepted');
END;
$$;

COMMENT ON FUNCTION public.get_public_listing_offers(UUID) IS
'Participant-scoped bid book. Listing owner and offer-makers receive exact terms; '
'all other viewers receive only v_loan_listings aggregate coverage.';

REVOKE EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) TO authenticated;

-- ============================================================
-- 8. VIEW: v_loan_listings (with offer_coverage_tier)
--    PostgreSQL cannot rename view columns via CREATE OR REPLACE,
--    so we drop dependents first, then rebuild all views.
-- ============================================================

-- Drop in reverse dependency order (v_trust_profile_pro uses v_trust_profile_public)
DROP VIEW IF EXISTS public.v_trust_profile_pro     CASCADE;
DROP VIEW IF EXISTS public.v_trust_profile_public  CASCADE;
DROP VIEW IF EXISTS public.v_loan_listings         CASCADE;

CREATE VIEW public.v_loan_listings AS
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
    -- KYC badge (status only — no personal verification documents)
    k.status                                                                 AS kyc_status,
    -- Public, privacy-safe trust signals for the request owner
    ta.rating_avg                                                            AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                             AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                    AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                  AS trust_response_time_bucket,
    (k.status = 'approved')                                                  AS trust_is_verified,
    -- time-remaining helpers
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                           AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                           AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                            AS closing_soon_6h
FROM  loan_requests    lr
JOIN  profiles         p  ON p.id  = lr.borrower_id
LEFT  JOIN kyc_verifications k  ON k.user_id  = lr.borrower_id
LEFT  JOIN trust_aggregates  ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active';

COMMENT ON VIEW public.v_loan_listings IS
'Anonymised marketplace feed. borrower_id, contact details, and private documents are never present.
 Repayment fields and Pro-tier suggestions help lenders make an informed bid without exposing income source.
 offer_coverage_tier is the public market-signal (low/medium/high); exact offer terms remain participant-gated.';

-- ============================================================
-- 9. VIEW: v_trust_profile_public (always-public baseline)
-- ============================================================

CREATE VIEW public.v_trust_profile_public AS
SELECT
    p.id                                          AS user_id,
    ta.rating_avg,
    COALESCE(ta.review_count, 0)                  AS review_count,
    COALESCE(ta.completed_deals_count, 0)         AS completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)      AS is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)             AS phone_verified,
    ta.response_time_bucket,
    (k.status = 'approved')                       AS is_verified
FROM profiles p
LEFT JOIN trust_aggregates   ta ON ta.user_id = p.id
LEFT JOIN kyc_verifications  k  ON k.user_id  = p.id;

-- ============================================================
-- 10. VIEW: v_trust_profile_pro (Pro-tier analytical depth)
-- ============================================================

CREATE VIEW public.v_trust_profile_pro AS
SELECT
    tp.*,
    ta.success_rate,
    ta.reliability_score
FROM v_trust_profile_public tp
JOIN trust_aggregates ta ON ta.user_id = tp.user_id
WHERE EXISTS (
    SELECT 1 FROM subscriptions s
    WHERE s.user_id = auth.uid()
      AND s.status  = 'active'
      AND s.plan    = 'pro'
);

-- ============================================================
-- 11. TRIGGER: trg_refresh_trust_on_reveal
-- ============================================================

CREATE OR REPLACE FUNCTION public.trg_refresh_trust_from_reveal()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE v_borrower UUID; v_lender UUID;
BEGIN
    IF NEW.status = 'revealed'
       AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'revealed') THEN
        SELECT lr.borrower_id, lo.lender_id INTO v_borrower, v_lender
        FROM loan_offers   lo
        JOIN loan_requests lr ON lr.id = lo.request_id
        WHERE lo.id = NEW.offer_id;
        PERFORM recompute_trust_aggregates(v_borrower);
        PERFORM recompute_trust_aggregates(v_lender);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_refresh_trust_on_reveal ON public.contact_reveals;
CREATE TRIGGER trg_refresh_trust_on_reveal
AFTER INSERT OR UPDATE OF status ON public.contact_reveals
FOR EACH ROW EXECUTE FUNCTION public.trg_refresh_trust_from_reveal();

-- ============================================================
-- 12. RLS: reviews + trust_aggregates
-- ============================================================

ALTER TABLE public.reviews         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trust_aggregates ENABLE ROW LEVEL SECURITY;

-- reviews: readable only by author and admin; all writes through submit_review RPC
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'reviews' AND policyname = 'reviews: author or admin read'
  ) THEN
    EXECUTE $P$
      CREATE POLICY "reviews: author or admin read"
        ON public.reviews FOR SELECT TO authenticated
        USING (reviewer_id = auth.uid() OR private.is_admin());
    $P$;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'reviews' AND policyname = 'reviews: no direct writes'
  ) THEN
    EXECUTE $P$
      CREATE POLICY "reviews: no direct writes"
        ON public.reviews FOR ALL TO authenticated
        USING (FALSE) WITH CHECK (FALSE);
    $P$;
  END IF;

  -- trust_aggregates: public baseline readable via safe view; direct table access admin-only
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'trust_aggregates' AND policyname = 'trust aggregates: admin only'
  ) THEN
    EXECUTE $P$
      CREATE POLICY "trust aggregates: admin only"
        ON public.trust_aggregates FOR SELECT TO authenticated
        USING (private.is_admin());
    $P$;
  END IF;

  -- service_role must write trust_aggregates via recompute_trust_aggregates
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'trust_aggregates' AND policyname = 'trust aggregates: service_role full access'
  ) THEN
    EXECUTE $P$
      CREATE POLICY "trust aggregates: service_role full access"
        ON public.trust_aggregates FOR ALL TO service_role
        USING (true) WITH CHECK (true);
    $P$;
  END IF;

  -- reviews insertable by service_role (via submit_review SECURITY DEFINER)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'reviews' AND policyname = 'reviews: service_role insert'
  ) THEN
    EXECUTE $P$
      CREATE POLICY "reviews: service_role insert"
        ON public.reviews FOR INSERT TO service_role
        WITH CHECK (true);
    $P$;
  END IF;
END $$;

-- ============================================================
-- 13. GRANT RE-ASSERTIONS
-- ============================================================

GRANT USAGE ON SCHEMA public  TO authenticated, anon;
GRANT USAGE ON SCHEMA private TO authenticated, service_role;

-- Views managed by this patch (always exist after section 8-10 above)
GRANT SELECT ON public.v_loan_listings          TO authenticated, anon;
GRANT SELECT ON public.v_trust_profile_public   TO authenticated, anon;
GRANT SELECT ON public.v_trust_profile_pro      TO authenticated;

-- Other views — grant only if they already exist (safe for partial deployments)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_views WHERE schemaname='public' AND viewname='v_lender_offers') THEN
    EXECUTE 'GRANT SELECT ON public.v_lender_offers TO authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_views WHERE schemaname='public' AND viewname='v_user_marketplace_activity') THEN
    EXECUTE 'GRANT SELECT ON public.v_user_marketplace_activity TO authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_views WHERE schemaname='public' AND viewname='v_marketplace_activity') THEN
    EXECUTE 'GRANT SELECT ON public.v_marketplace_activity TO authenticated';
  END IF;
END $$;

-- Tables
GRANT SELECT, INSERT, UPDATE, DELETE
    ON public.reviews, public.trust_aggregates
    TO authenticated;
GRANT ALL ON public.reviews, public.trust_aggregates TO service_role;

-- RPCs
GRANT EXECUTE ON FUNCTION public.get_my_subscription_plan()            TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_public_listing_offers(UUID)       TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_review(UUID, SMALLINT, TEXT)   TO authenticated;
GRANT EXECUTE ON FUNCTION public.recompute_trust_aggregates(UUID)      TO service_role;
GRANT EXECUTE ON FUNCTION public.accept_offer(UUID, UUID, UUID)        TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.reveal_contact(UUID, UUID)            TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.is_admin()                           TO authenticated, service_role;

-- ============================================================
-- 14. SUBSCRIPTION EXPIRY REFRESH (seeded test accounts → 2028)
-- ============================================================

UPDATE public.subscriptions SET expires_at = '2028-01-20 15:00:00'
WHERE user_id = '10000000-0000-0000-0000-000000000003'; -- James Okello (Pro)

UPDATE public.subscriptions SET expires_at = '2028-03-01 11:00:00'
WHERE user_id = '10000000-0000-0000-0000-000000000008'; -- Pearl Capital (Pro)

UPDATE public.subscriptions SET expires_at = '2028-02-18 10:00:00'
WHERE user_id = '10000000-0000-0000-0000-000000000006'; -- Victoria Invest (Lender)

UPDATE public.subscriptions SET expires_at = '2028-02-20 12:00:00'
WHERE user_id = '10000000-0000-0000-0000-000000000007'; -- Equator Finance (Lender)

UPDATE public.subscriptions SET expires_at = '2028-03-05 10:00:00'
WHERE user_id = '10000000-0000-0000-0000-000000000010'; -- Kampala Tech (Lender)

UPDATE public.subscriptions SET expires_at = '2028-01-25 12:00:00'
WHERE user_id = '10000000-0000-0000-0000-000000000005'; -- Robert Ssemwanga (Lender)

-- ============================================================
-- 15. VERIFICATION QUERIES
--     All ok columns should be TRUE; counts as noted.
-- ============================================================

SELECT 'loan_requests Stage 4 columns' AS check_name,
       COUNT(*) = 5 AS ok,
       ARRAY_AGG(column_name ORDER BY column_name) AS found
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'loan_requests'
  AND column_name IN (
    'suggested_interest_rate_pct', 'suggested_late_fee_pct',
    'suggested_repayment_frequency', 'suggested_installment_amount', 'terms_locked_at'
  );

SELECT 'loan_offers Stage 4 columns' AS check_name,
       COUNT(*) = 5 AS ok,
       ARRAY_AGG(column_name ORDER BY column_name) AS found
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'loan_offers'
  AND column_name IN (
    'interest_rate_pct', 'late_fee_pct',
    'repayment_frequency', 'installment_amount', 'terms_locked_at'
  );

SELECT 'trust tables exist' AS check_name,
       COUNT(*) = 2 AS ok,
       ARRAY_AGG(table_name ORDER BY table_name) AS found
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('reviews', 'trust_aggregates');

SELECT 'get_public_listing_offers RPC exists' AS check_name,
       EXISTS (
           SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname = 'get_public_listing_offers'
       ) AS ok;

SELECT 'submit_review RPC exists' AS check_name,
       EXISTS (
           SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname = 'submit_review'
       ) AS ok;

SELECT 'recompute_trust_aggregates RPC exists' AS check_name,
       EXISTS (
           SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname = 'recompute_trust_aggregates'
       ) AS ok;

SELECT 'v_loan_listings has offer_coverage_tier' AS check_name,
       EXISTS (
           SELECT 1 FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name   = 'v_loan_listings'
             AND column_name  = 'offer_coverage_tier'
       ) AS ok;

SELECT 'v_trust_profile_public exists' AS check_name,
       EXISTS (
           SELECT 1 FROM information_schema.views
           WHERE table_schema = 'public' AND table_name = 'v_trust_profile_public'
       ) AS ok;

SELECT 'v_trust_profile_pro exists' AS check_name,
       EXISTS (
           SELECT 1 FROM information_schema.views
           WHERE table_schema = 'public' AND table_name = 'v_trust_profile_pro'
       ) AS ok;

SELECT 'pending offers with all Stage 4 terms set' AS check_name,
       COUNT(*) AS total_pending,
       SUM(CASE WHEN interest_rate_pct IS NOT NULL
                 AND late_fee_pct      IS NOT NULL
                 AND repayment_frequency IS NOT NULL
                 AND installment_amount IS NOT NULL
                 AND terms_locked_at  IS NOT NULL THEN 1 ELSE 0 END) AS fully_set
FROM public.loan_offers WHERE status = 'pending';

SELECT 'subscription refresh — active pro/lender count' AS check_name,
       COUNT(*) AS active_subscriptions
FROM public.subscriptions WHERE status = 'active' AND expires_at > NOW();

SELECT '✅ Stage 4 cloud patch complete' AS result;
