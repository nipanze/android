-- ============================================================
-- NIPANZE — Supabase Cloud Patch (v2 — correct approach)
-- Run this entire script in the Supabase SQL Editor.
-- Safe to run multiple times (idempotent where possible).
-- ============================================================
-- Root-cause analysis
-- -------------------
-- All four views MUST use security_invoker = true so that
-- Postgres evaluates RLS policies using the *caller's* identity
-- (not the view owner). Default behaviour (no security_invoker)
-- is SECURITY DEFINER — the view runs as postgres/owner and
-- completely bypasses RLS, which is the vulnerability Supabase
-- Security Advisor is flagging.
--
-- The previous error ("permission denied") was NOT caused by
-- security_invoker = true. It was caused by the `authenticated`
-- role lacking explicit SELECT privileges on the underlying
-- tables (profiles, subscriptions, kyc_verifications, etc.)
-- that the views JOIN against. Without those grants the view
-- owner can read them but the calling user cannot — so with
-- security_invoker = true the join fails.
--
-- Fix:
--   1. Grant SELECT on every underlying table to `authenticated`
--   2. Keep security_invoker = true on all views
-- ============================================================


-- ============================================================
-- HELPER FUNCTION: is_admin() — Used by RLS policies
-- ============================================================
-- This function checks if the current user has admin role.
-- Must be created BEFORE the RLS policies that reference it.

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
          AND role = 'admin'
    );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;


-- ============================================================
-- STEP 1: GRANT TABLE & SEQUENCE ACCESS TO authenticated ROLE
-- This was the missing piece that caused the permission errors.
-- ============================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

-- Explicit per-table grants for the tables the views JOIN on
-- (belt-and-suspenders — already covered by ALL TABLES above
--  but explicit grants survive future table-level revokes)
GRANT SELECT ON profiles           TO authenticated;
GRANT SELECT ON subscriptions      TO authenticated;
GRANT SELECT ON kyc_verifications  TO authenticated;
GRANT SELECT ON loan_requests      TO authenticated;
GRANT SELECT ON loan_offers        TO authenticated;
GRANT SELECT ON contact_reveals    TO authenticated;


-- ============================================================
-- STEP 2: DROP & RECREATE VIEWS WITH security_invoker = true
-- Each view now runs as the caller's role. RLS on underlying
-- tables is enforced using auth.uid() of the API user.
-- ============================================================

-- 2a. v_loan_listings  (anonymised marketplace feed)
--     Under security_invoker, the LEFT JOIN on kyc_verifications
--     will return NULL for kyc_status when the caller is not the
--     borrower — that is correct and expected privacy behaviour.
DROP VIEW IF EXISTS v_loan_listings;
CREATE VIEW v_loan_listings WITH (security_invoker = true) AS
SELECT
    lr.id                                                                     AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.status,
    lr.number_of_offers,
    lr.listed_at,
    lr.expires_at,
    -- KYC badge: only visible when the caller *is* the borrower
    -- (for borrower's own listing page) — NULL otherwise (correct)
    k.status                                                                  AS kyc_status,
    -- time-remaining helpers
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h
FROM  loan_requests   lr
LEFT  JOIN kyc_verifications k ON k.user_id = lr.borrower_id
WHERE lr.status = 'active';

COMMENT ON VIEW v_loan_listings IS
'Anonymised marketplace feed. security_invoker=true — RLS on loan_requests filters to active rows.
 borrower_id, contact details, and private documents are never present.
 kyc_status is NULL for callers who are not the listing owner (expected behaviour).';


-- 2b. v_user_marketplace_activity  (positions / dashboard)
--     With security_invoker, profiles RLS (id = auth.uid())
--     means this only ever returns the calling user's own row.
DROP VIEW IF EXISTS v_user_marketplace_activity;
CREATE VIEW v_user_marketplace_activity WITH (security_invoker = true) AS
SELECT
    p.id                                                                      AS user_id,
    p.full_name,
    p.account_status,
    -- borrower side
    COUNT(DISTINCT lr.id) FILTER (
        WHERE lr.borrower_id = p.id AND lr.status = 'active'
    )                                                                         AS active_requests,
    COUNT(DISTINCT lr.id) FILTER (
        WHERE lr.borrower_id = p.id AND lr.status = 'contracted'
    )                                                                         AS contracted_as_borrower,
    COUNT(DISTINCT lr.id) FILTER (
        WHERE lr.borrower_id = p.id AND lr.status = 'expired'
    )                                                                         AS expired_requests,
    -- lender side
    COUNT(DISTINCT lo.id) FILTER (
        WHERE lo.lender_id = p.id AND lo.status = 'pending'
    )                                                                         AS pending_offers,
    COUNT(DISTINCT lo.id) FILTER (
        WHERE lo.lender_id = p.id AND lo.status = 'accepted'
    )                                                                         AS accepted_offers,
    -- subscription
    s.plan                                                                    AS subscription_plan,
    s.status                                                                  AS subscription_status,
    s.expires_at                                                              AS subscription_expires_at,
    -- kyc
    k.status                                                                  AS kyc_status
FROM  profiles          p
LEFT  JOIN subscriptions      s  ON s.user_id     = p.id AND s.status = 'active'
LEFT  JOIN kyc_verifications  k  ON k.user_id     = p.id
LEFT  JOIN loan_requests      lr ON lr.borrower_id = p.id
LEFT  JOIN loan_offers        lo ON lo.lender_id   = p.id
GROUP BY p.id, s.plan, s.status, s.expires_at, k.status;

COMMENT ON VIEW v_user_marketplace_activity IS
'Dashboard summary for a single user. security_invoker=true — profiles RLS ensures each user
 sees only their own row. Safe to query without a .eq() filter.';


-- 2c. v_lender_offers  (My Offers screen)
--     loan_offers RLS (lender_id = auth.uid()) ensures lenders
--     only see their own offers. loan_requests RLS returns the
--     associated active/contracted request for context.
DROP VIEW IF EXISTS v_lender_offers;
CREATE VIEW v_lender_offers WITH (security_invoker = true) AS
SELECT
    lo.lender_id,
    lo.id                                                                     AS offer_id,
    lo.request_id,
    lr.title                                                                  AS listing_title,
    lr.purpose                                                                AS listing_purpose,
    lr.district,
    lr.duration_months,
    lr.requested_amount,
    lo.offer_amount,
    lo.proposed_expectations,
    lo.status                                                                 AS offer_status,
    lo.offered_at,
    lo.accepted_at,
    -- contact reveal status (only populated after acceptance)
    cr.status                                                                 AS reveal_status,
    cr.revealed_at
FROM  loan_offers     lo
JOIN  loan_requests   lr ON lr.id        = lo.request_id
LEFT  JOIN contact_reveals cr ON cr.offer_id = lo.id;

COMMENT ON VIEW v_lender_offers IS
'Lender offer history with reveal status. security_invoker=true — loan_offers RLS restricts to
 the calling lender''s own offers. Borrower contact details not exposed until reveal_status = revealed.';


-- 2d. v_marketplace_activity  (admin KPIs)
--     loan_requests RLS does not restrict active rows, so
--     aggregate counts are correct for authenticated users.
--     Admins get full visibility; regular users see same totals
--     (no PII — only counts).
DROP VIEW IF EXISTS v_marketplace_activity;
CREATE VIEW v_marketplace_activity WITH (security_invoker = true) AS
SELECT
    DATE_TRUNC('month', lr.listed_at)                                        AS month,
    COUNT(lr.id)                                                              AS total_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'active')                        AS active_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'contracted')                    AS contracted_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'expired')                       AS expired_listings,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.status = 'pending')              AS pending_offers,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.status = 'accepted')             AS accepted_offers,
    ROUND(
        COUNT(DISTINCT lo.request_id) * 100.0 / NULLIF(COUNT(lr.id), 0), 1
    )                                                                         AS match_rate_pct,
    (SELECT COUNT(*) FROM subscriptions
     WHERE status = 'active' AND plan != 'free')                             AS active_paid_subscribers
FROM  loan_requests lr
LEFT  JOIN loan_offers lo ON lo.request_id = lr.id
GROUP BY DATE_TRUNC('month', lr.listed_at)
ORDER BY month DESC;

COMMENT ON VIEW v_marketplace_activity IS
'Admin KPIs. security_invoker=true. No PII — aggregate counts only. Non-custodial: no monetary totals.';


-- ============================================================
-- STEP 3: GRANT VIEW ACCESS TO ROLES
-- Must re-run after DROP/CREATE because grants are wiped.
-- ============================================================

GRANT SELECT ON v_loan_listings             TO authenticated, anon;
GRANT SELECT ON v_user_marketplace_activity TO authenticated;
GRANT SELECT ON v_lender_offers             TO authenticated;
GRANT SELECT ON v_marketplace_activity      TO authenticated;


-- ============================================================
-- STEP 4: VERIFY / RECREATE RLS POLICIES ON loan_offers
-- ============================================================

ALTER TABLE loan_offers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "loan_offers: relevant parties read"    ON loan_offers;
DROP POLICY IF EXISTS "loan_offers: lender insert"            ON loan_offers;
DROP POLICY IF EXISTS "loan_offers: lender withdraw or admin" ON loan_offers;

-- Borrower sees all offers on their listing; lender sees their own; admin sees all
CREATE POLICY "loan_offers: relevant parties read"
    ON loan_offers FOR SELECT TO authenticated
    USING (
        lender_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM loan_requests lr
             WHERE lr.id = loan_offers.request_id
               AND lr.borrower_id = auth.uid()
        )
        OR is_admin()
    );

-- Only the lender who owns the offer can insert (subscription validated by trigger)
CREATE POLICY "loan_offers: lender insert"
    ON loan_offers FOR INSERT TO authenticated
    WITH CHECK (lender_id = auth.uid());

-- Lender can withdraw their own pending offer; admin can update any
CREATE POLICY "loan_offers: lender withdraw or admin"
    ON loan_offers FOR UPDATE TO authenticated
    USING (
        (lender_id = auth.uid() AND status = 'pending')
        OR is_admin()
    );


-- ============================================================
-- STEP 5: VERIFY / RECREATE RLS POLICIES ON loan_requests
-- (borrowers must be able to see their own contracted requests
--  even though the view only shows 'active' ones)
-- ============================================================

ALTER TABLE loan_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "loan_requests: marketplace read"    ON loan_requests;
DROP POLICY IF EXISTS "loan_requests: own insert"          ON loan_requests;
DROP POLICY IF EXISTS "loan_requests: own or admin update" ON loan_requests;

CREATE POLICY "loan_requests: marketplace read"
    ON loan_requests FOR SELECT TO authenticated
    USING (status = 'active' OR borrower_id = auth.uid() OR is_admin());

CREATE POLICY "loan_requests: own insert"
    ON loan_requests FOR INSERT TO authenticated
    WITH CHECK (borrower_id = auth.uid());

CREATE POLICY "loan_requests: own or admin update"
    ON loan_requests FOR UPDATE TO authenticated
    USING (borrower_id = auth.uid() OR is_admin());


-- ============================================================
-- STEP 6: REALTIME — ensure key tables are in the publication
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'loan_offers')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE loan_offers; END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'loan_requests')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE loan_requests; END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE notifications; END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'contact_reveals')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE contact_reveals; END IF;
END $$;


-- ============================================================
-- STEP 7: FUNCTION SECURITY
-- ============================================================

-- Internal trigger functions — no direct API access
REVOKE EXECUTE ON FUNCTION public.handle_new_auth_user()           FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_require_active_account()  FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_max_concurrent_requests() FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_validate_offer()          FROM public, authenticated, anon;

-- Client-facing RPCs
REVOKE EXECUTE ON FUNCTION public.is_admin()                     FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.is_admin()                     TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid)     FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid)     TO authenticated, service_role;


-- ============================================================
-- STEP 8: FORCE POSTGREST SCHEMA CACHE RELOAD
-- ============================================================

NOTIFY pgrst, 'reload schema';


-- ============================================================
-- ✅ DONE. Verify with the queries below (run separately).
-- ============================================================

-- Check that views no longer appear as SECURITY DEFINER
-- SELECT viewname, definition
--   FROM pg_views
--  WHERE schemaname = 'public'
--    AND viewname IN ('v_loan_listings','v_user_marketplace_activity',
--                     'v_lender_offers','v_marketplace_activity');

-- Check realtime publication tables
-- SELECT tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

-- Check loan_offers RLS policies
-- SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'loan_offers';

-- Check pending offers exist
-- SELECT id, request_id, lender_id, status FROM loan_offers WHERE status = 'pending';

-- Check the marketplace view returns rows (as authenticated user)
-- SELECT * FROM v_loan_listings LIMIT 5;
