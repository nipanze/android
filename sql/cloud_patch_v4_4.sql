-- ====================================================================
-- NIPANZE CLOUD DB PATCH (v4.4)
-- Fix v_user_marketplace_activity so the account screen and positions
-- screen read the expected column names:
--
--   active_listings      = ALL listings posted by the user (any status)
--   active_offers        = lender offers still pending or accepted
--   revealed_contacts    = accepted lender offers + contracted borrower
--                          listings (successful matches)
-- ====================================================================

DROP VIEW IF EXISTS public.v_user_marketplace_activity;

CREATE VIEW public.v_user_marketplace_activity
WITH (security_invoker = true) AS
SELECT
    p.id                                                                      AS user_id,
    p.full_name,
    p.account_status,
    COUNT(DISTINCT lr.id) FILTER (WHERE lr.borrower_id = p.id AND lr.status = 'active')        AS active_requests,
    COUNT(DISTINCT lr.id) FILTER (WHERE lr.borrower_id = p.id AND lr.status = 'contracted')     AS contracted_as_borrower,
    COUNT(DISTINCT lr.id) FILTER (WHERE lr.borrower_id = p.id AND lr.status = 'expired')        AS expired_requests,
    -- expected by ProfileRepository + PositionsPage:
    COUNT(DISTINCT lr.id) FILTER (WHERE lr.borrower_id = p.id)                                  AS active_listings,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.lender_id = p.id AND lo.status = 'pending')          AS pending_offers,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.lender_id = p.id AND lo.status = 'accepted')         AS accepted_offers,
    -- expected by ProfileRepository + PositionsPage:
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.lender_id = p.id AND lo.status IN ('pending','accepted')) AS active_offers,
    -- expected by AccountPage "Matches" stat:
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.lender_id = p.id AND lo.status = 'accepted')
      + COUNT(DISTINCT lr.id) FILTER (WHERE lr.borrower_id = p.id AND lr.status = 'contracted')   AS revealed_contacts,
    s.plan                                                                    AS subscription_plan,
    s.status                                                                  AS subscription_status,
    s.expires_at                                                              AS subscription_expires_at,
    k.status                                                                  AS kyc_status
FROM  profiles          p
LEFT  JOIN subscriptions      s  ON s.user_id     = p.id AND s.status = 'active'
LEFT  JOIN kyc_verifications  k  ON k.user_id     = p.id
LEFT  JOIN loan_requests      lr ON lr.borrower_id = p.id
LEFT  JOIN loan_offers        lo ON lo.lender_id   = p.id
GROUP BY p.id, s.plan, s.status, s.expires_at, k.status;

GRANT SELECT ON public.v_user_marketplace_activity TO authenticated;

SELECT '✅ Cloud Patch v4.4 applied successfully' AS result;
