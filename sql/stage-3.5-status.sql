-- ============================================================
-- STAGE 3.5 STATUS CHECK — Quick Health Report
-- Run this in Supabase SQL Editor to see what's already complete.
-- Safe to run at any time — read-only queries only.
-- ============================================================

/*
LEGEND:
  ✅ = Complete
  ⏳ = In Progress / Partial
  ⚠️  = Warning / Needs Review
  ❌ = Not Started / Missing
*/

-- ============================================================
-- SECTION 1: OVERALL SCHEMA STATUS
-- ============================================================

SELECT
    'SCHEMA STATUS' AS section,
    COUNT(*) AS table_count,
    CASE
        WHEN COUNT(*) >= 9  THEN '✅ Core tables present (9+)'
        WHEN COUNT(*) >= 5  THEN '⏳ Partial schema present'
        ELSE                     '❌ Missing core tables'
    END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'profiles', 'subscriptions', 'loan_requests', 'loan_offers',
      'kyc_verifications', 'watchlist', 'contact_reveals',
      'notifications', 'audit_logs', 'system_settings'
  );


-- ============================================================
-- SECTION 2: VIEW STATUS (security_invoker)
-- NOTE: information_schema.views does not have creation_expression.
--       We inspect pg_views.definition instead.
-- ============================================================

SELECT
    'VIEWS & SECURITY'                        AS section,
    COUNT(*)                                  AS view_count,
    SUM(CASE WHEN pv.definition ILIKE '%security_invoker = true%' THEN 1 ELSE 0 END) AS with_security_invoker,
    CASE
        WHEN COUNT(*) = 4
          AND SUM(CASE WHEN pv.definition ILIKE '%security_invoker = true%' THEN 1 ELSE 0 END) = 4
            THEN '✅ All 4 views with security_invoker=true'
        WHEN COUNT(*) = 4
            THEN '⚠️  4 views exist but security_invoker not all set'
        WHEN COUNT(*) > 0
            THEN '⏳ Partial views (need 4)'
        ELSE     '❌ No views found'
    END AS status
FROM pg_views pv
WHERE pv.schemaname = 'public'
  AND pv.viewname IN (
      'v_loan_listings',
      'v_lender_offers',
      'v_user_marketplace_activity',
      'v_marketplace_activity'
  );


-- ============================================================
-- SECTION 3: RLS ENFORCEMENT
-- ============================================================

SELECT
    'RLS POLICIES'                        AS section,
    COUNT(DISTINCT tablename)             AS tables_with_rls,
    COUNT(*)                              AS total_policies,
    CASE
        WHEN COUNT(DISTINCT tablename) >= 9 THEN '✅ RLS on 9+ tables'
        WHEN COUNT(DISTINCT tablename) >= 5 THEN '⏳ RLS on 5+ tables'
        ELSE                                     '❌ RLS incomplete'
    END AS status
FROM pg_policies
WHERE schemaname = 'public';


-- ============================================================
-- SECTION 4: SEED DATA (TEST ACCOUNTS)
-- ============================================================

SELECT
    'SEED DATA'             AS section,
    COUNT(*)                AS user_count,
    CASE
        WHEN COUNT(*) = 17  THEN '✅ All 17 test accounts loaded'
        WHEN COUNT(*) >= 13 THEN '⏳ Most seed data loaded'
        WHEN COUNT(*) > 0   THEN '⏳ Partial seed data'
        ELSE                     '❌ No seed data'
    END AS status
FROM auth.users
WHERE email IN (
    'david.mukasa@gmail.com',    'sarah.namukasa@yahoo.com',
    'james.okello@outlook.com',  'maria.nakato@gmail.com',
    'robert.ssemwanga@gmail.com','info@greenleafagro.co.ug',
    'contact@kampalatech.ug',    'invest@pearlcapital.ug',
    'funds@victoriainvest.co.ug','lending@equatorfinance.ug',
    'alice.namuli@gmail.com',    'admin1@nipanze.ug',
    'test.user@gmail.com'
);


-- ============================================================
-- SECTION 5: STORAGE BUCKET
-- ============================================================

SELECT
    'STORAGE SETUP' AS section,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM storage.buckets
             WHERE name = 'verification-documents'
        ) THEN '✅ verification-documents bucket exists'
        ELSE   '❌ verification-documents bucket missing'
    END AS status,
    (SELECT COUNT(*) FROM storage.buckets
      WHERE name = 'verification-documents') AS bucket_count;


-- ============================================================
-- SECTION 6: DATA MASKING CHECK
-- ============================================================

-- v_loan_listings must NOT expose borrower_id
SELECT
    'DATA MASKING'           AS section,
    'v_loan_listings'        AS view_name,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ borrower_id NOT exposed'
        ELSE                   '❌ borrower_id EXPOSED (SECURITY RISK)'
    END AS status
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'v_loan_listings'
  AND column_name  = 'borrower_id'

UNION ALL

-- v_lender_offers must NOT expose lender contact details
SELECT
    'DATA MASKING'    AS section,
    'v_lender_offers' AS view_name,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ No lender contact columns'
        ELSE                   '⚠️  Lender contact columns present (check if pre-reveal)'
    END AS status
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'v_lender_offers'
  AND column_name IN ('lender_phone', 'lender_email', 'lender_name');


-- ============================================================
-- SECTION 7: SYSTEM SETTINGS
-- ============================================================

SELECT
    'SYSTEM CONFIG'         AS section,
    COUNT(*)                AS setting_count,
    CASE
        WHEN COUNT(*) >= 10 THEN '✅ System settings configured'
        WHEN COUNT(*) > 0   THEN '⏳ Partial system settings'
        ELSE                     '❌ No system settings'
    END AS status
FROM public.system_settings;


-- ============================================================
-- SECTION 8: ACTIVE LISTINGS
-- ============================================================

SELECT
    'TEST DATA'             AS section,
    COUNT(*)                AS active_listings,
    CASE
        WHEN COUNT(*) >= 5  THEN '✅ Seed data includes active listings'
        WHEN COUNT(*) > 0   THEN '⏳ Some active listings present'
        ELSE                     '⚠️  No active listings (expected if seed not applied)'
    END AS status
FROM public.loan_requests
WHERE status = 'active';


-- ============================================================
-- SECTION 9: PRIVATE SCHEMA (fix_functions.sql)
-- ============================================================

SELECT
    'PRIVATE SCHEMA'        AS section,
    COUNT(*)                AS private_functions,
    CASE
        WHEN COUNT(*) >= 3  THEN '✅ private schema functions present'
        WHEN COUNT(*) > 0   THEN '⏳ Some private functions (expected 3+)'
        ELSE                     '❌ private schema functions missing — run fix_functions.sql'
    END AS status
FROM information_schema.routines
WHERE routine_schema = 'private'
  AND routine_name IN ('is_admin', 'accept_offer_internal', 'reveal_contact_internal');


-- ============================================================
-- SECTION 10: REALTIME PUBLICATION
-- ============================================================

SELECT
    'REALTIME'  AS section,
    COUNT(*)    AS subscribed_tables,
    CASE
        WHEN COUNT(*) >= 5 THEN '✅ Key tables in Realtime publication'
        WHEN COUNT(*) > 0  THEN '⏳ Some tables in Realtime (' || COUNT(*) || '/5)'
        ELSE                    '❌ No tables in Realtime publication'
    END AS status
FROM pg_publication_tables
WHERE pubname   = 'supabase_realtime'
  AND tablename IN (
      'loan_offers', 'loan_requests',
      'notifications', 'contact_reveals', 'watchlist'
  );


-- ============================================================
-- SUMMARY REPORT
-- ============================================================

/*
NEXT STEPS:
  - If ALL sections show ✅: Stage 3.5 is COMPLETE! Proceed to Stage 4.
  - If some show ❌ or ⏳:   Follow STAGE_3.5_GUIDE.md to complete.
  - If you see ⚠️  warnings: Review that specific section and remediate.

EXECUTION ORDER (if not complete):
  1. Apply schema.sql          (if ❌ table count)
  2. Apply seed.sql            (if ❌ user count)
  3. Apply cloud_patch.sql     (if ⚠️  in RLS / views)
  4. Apply fix_functions.sql   (if ❌ private schema)
  5. Apply stage-3.5-apply.sql (if ❌ storage bucket)
  6. Re-run this status check

Contact: contact@nipanze.ug
*/
