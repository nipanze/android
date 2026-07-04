-- ============================================================
-- STAGE 3.5 VERIFICATION & AUDIT SCRIPT
-- Run this in Supabase SQL Editor to verify cloud setup.
-- Safe to run at any time — read-only queries only.
--
-- Expected: every query returns the ✅ result described below.
-- ============================================================


-- ============================================================
-- SECTION 1: CHECK SCHEMA & TABLES EXIST
-- Expected: count = 9
-- ============================================================

SELECT
    'TABLES' AS check_type,
    COUNT(*) AS count,
    CASE
        WHEN COUNT(*) = 9 THEN '✅ All 9 core tables exist'
        ELSE '❌ Missing tables — run schema.sql'
    END AS result
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'profiles', 'subscriptions', 'loan_requests', 'loan_offers',
      'kyc_verifications', 'contact_reveals', 'notifications',
      'watchlist', 'audit_logs'
  );


-- ============================================================
-- SECTION 2: VERIFY VIEWS & SECURITY_INVOKER
-- Expected: 4 rows, all showing ✅ security_invoker=true
-- NOTE: pg_views.definition contains the full view DDL including
--       the WITH (security_invoker = true) clause.
-- ============================================================

SELECT
    pv.viewname                         AS view_name,
    CASE
        WHEN pv.definition ILIKE '%security_invoker = true%'
            THEN '✅ security_invoker=true'
        ELSE    '⚠️  security_invoker NOT set — re-run cloud_patch.sql'
    END                                 AS security_status
FROM pg_views pv
WHERE pv.schemaname = 'public'
  AND pv.viewname IN (
      'v_loan_listings',
      'v_lender_offers',
      'v_user_marketplace_activity',
      'v_marketplace_activity'
  )
ORDER BY pv.viewname;


-- ============================================================
-- SECTION 3: VERIFY v_loan_listings COLUMNS (no borrower_id)
-- Expected: borrower_id_exposed = 0
-- ============================================================

-- List all columns (for visual inspection)
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'v_loan_listings'
ORDER BY ordinal_position;

-- Scalar check — must return 0
SELECT
    COUNT(*) AS borrower_id_exposed,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ borrower_id NOT in v_loan_listings'
        ELSE                   '❌ SECURITY RISK: borrower_id exposed!'
    END AS result
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'v_loan_listings'
  AND column_name  = 'borrower_id';


-- ============================================================
-- SECTION 4: VERIFY v_lender_offers COLUMNS
-- Expected: contact_details_exposed = 0
-- ============================================================

-- List all columns (for visual inspection)
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'v_lender_offers'
ORDER BY ordinal_position;

-- Scalar check — must return 0
SELECT
    COUNT(*) AS contact_details_exposed,
    CASE
        WHEN COUNT(*) = 0 THEN '✅ No lender contact columns in v_lender_offers'
        ELSE                   '⚠️  Lender contact columns found (verify pre-reveal gating)'
    END AS result
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'v_lender_offers'
  AND column_name IN ('lender_phone', 'lender_email', 'lender_name');


-- ============================================================
-- SECTION 5: VERIFY RLS POLICIES
-- Expected: all core tables have at least 1 policy
-- ============================================================

SELECT
    pt.tablename,
    COALESCE(p.policy_count, 0)        AS policy_count,
    CASE
        WHEN COALESCE(p.policy_count, 0) > 0
            THEN '✅ RLS policies present'
        ELSE    '❌ No RLS policy — table may be unprotected'
    END                                AS result
FROM (
    VALUES
        ('profiles'),('subscriptions'),('loan_requests'),('loan_offers'),
        ('kyc_verifications'),('watchlist'),('contact_reveals'),
        ('notifications'),('audit_logs')
) AS pt(tablename)
LEFT JOIN (
    SELECT tablename, COUNT(*) AS policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY tablename
) p ON p.tablename = pt.tablename
ORDER BY pt.tablename;


-- ============================================================
-- SECTION 6: VERIFY STORAGE BUCKET
-- Expected: verification-documents bucket exists, public=false
-- ============================================================

SELECT
    id,
    name,
    public              AS is_public,
    file_size_limit,
    CASE
        WHEN public = FALSE THEN '✅ Private bucket (correct)'
        ELSE                     '⚠️  Bucket is public — should be private'
    END AS result
FROM storage.buckets
WHERE name LIKE '%verification%'
   OR name LIKE '%kyc%'
   OR name LIKE '%documents%';


-- ============================================================
-- SECTION 7: CHECK SEED DATA (test accounts)
-- Expected: count = 5 (5 key test accounts checked here)
-- Full seed check: SELECT COUNT(*) FROM auth.users = 17
-- ============================================================

SELECT
    COUNT(*) AS key_accounts_present,
    CASE
        WHEN COUNT(*) = 5 THEN '✅ All key test accounts present'
        ELSE                   '⚠️  Missing some test accounts — run seed.sql'
    END AS result
FROM auth.users
WHERE email IN (
    'david.mukasa@gmail.com',
    'sarah.namukasa@yahoo.com',
    'james.okello@outlook.com',
    'maria.nakato@gmail.com',
    'admin1@nipanze.ug'
);

-- Total user count sanity check
SELECT
    COUNT(*) AS total_auth_users,
    CASE
        WHEN COUNT(*) >= 17 THEN '✅ 17+ users in auth.users'
        WHEN COUNT(*) > 0   THEN '⏳ Some users present (' || COUNT(*) || '/17)'
        ELSE                     '❌ No users — run seed.sql'
    END AS result
FROM auth.users;


-- ============================================================
-- SECTION 8: VERIFY PRIVATE SCHEMA FUNCTIONS
-- Expected: 3 functions in private schema
-- (is_admin, accept_offer_internal, reveal_contact_internal)
-- ============================================================

SELECT
    routine_schema,
    routine_name,
    routine_type,
    '✅ private function present' AS result
FROM information_schema.routines
WHERE routine_schema = 'private'
  AND routine_name IN (
      'is_admin',
      'accept_offer_internal',
      'reveal_contact_internal'
  )
ORDER BY routine_name;


-- ============================================================
-- SECTION 9: VERIFY REALTIME PUBLICATION
-- Expected: at least 5 tables in supabase_realtime
-- ============================================================

SELECT
    tablename,
    '✅ In Realtime publication' AS result
FROM pg_publication_tables
WHERE pubname   = 'supabase_realtime'
  AND tablename IN (
      'loan_offers', 'loan_requests',
      'notifications', 'contact_reveals', 'watchlist'
  )
ORDER BY tablename;


-- ============================================================
-- SECTION 10: LIVE QUERY — v_loan_listings accessible
-- Expected: returns a count >= 0 without error
-- Note: when run as postgres role in SQL Editor (not as
--       an authenticated user), RLS is bypassed by default.
--       A zero result means no active listings exist.
-- ============================================================

SELECT
    COUNT(*) AS visible_listings,
    CASE
        WHEN COUNT(*) > 0 THEN '✅ Active listings visible in v_loan_listings'
        ELSE                   '⚠️  0 active listings (seed may not be applied)'
    END AS result
FROM public.v_loan_listings;


-- ============================================================
-- SECTION 11: RLS ON audit_logs (append-only check)
-- Expected: no UPDATE or DELETE policy exists for authenticated
-- ============================================================

SELECT
    policyname,
    cmd,
    CASE
        WHEN cmd IN ('UPDATE', 'DELETE')
          AND roles::text LIKE '%authenticated%'
            THEN '⚠️  Authenticated role can ' || cmd || ' audit_logs!'
        WHEN cmd IN ('SELECT', 'INSERT')
            THEN '✅ ' || cmd || ' policy — ok'
        ELSE     'ℹ️  ' || cmd || ' policy (service_role only)'
    END AS result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'audit_logs'
ORDER BY cmd, policyname;


-- ============================================================
-- SUMMARY: Expected Results
-- ============================================================
/*
✅ ALL CLEAR when:
   Section 1:  count = 9 (core tables)
   Section 2:  4 views, all with security_invoker=true
   Section 3:  borrower_id_exposed = 0
   Section 4:  contact_details_exposed = 0
   Section 5:  All 9 tables have policy_count > 0
   Section 6:  verification-documents bucket exists, public = false
   Section 7:  5 key accounts + 17 total users
   Section 8:  3 private schema functions
   Section 9:  5 tables in Realtime publication
   Section 10: visible_listings >= 0 (no error)
   Section 11: No UPDATE/DELETE policies for authenticated on audit_logs

⚠️  WARNINGS — remediation:
   Views missing security_invoker  → re-run cloud_patch.sql
   borrower_id exposed             → re-run cloud_patch.sql (view recreate)
   Missing storage bucket          → re-run stage-3.5-apply.sql
   Missing private functions       → run fix_functions.sql
   Missing test accounts           → run seed.sql
*/
