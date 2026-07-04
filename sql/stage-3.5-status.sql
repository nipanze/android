-- ============================================================
-- STAGE 3.5 STATUS CHECK — Quick Health Report
-- Run this to see what's already been completed
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

SELECT 'SCHEMA STATUS' as section, COUNT(*) as table_count,
  CASE
    WHEN COUNT(*) >= 9 THEN '✅ Core tables present (9+)'
    WHEN COUNT(*) >= 5 THEN '⏳ Partial schema present'
    ELSE '❌ Missing core tables'
  END as status
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'profiles', 'subscriptions', 'loan_requests', 'loan_offers',
  'kyc_verifications', 'watchlist', 'contact_reveals',
  'notifications', 'audit_logs', 'system_settings'
);

-- ============================================================
-- SECTION 2: VIEW STATUS (security_invoker)
-- ============================================================

SELECT
  'VIEWS & SECURITY' as section,
  COUNT(*) as view_count,
  SUM(CASE WHEN creation_expression ILIKE '%security_invoker = true%' THEN 1 ELSE 0 END) as with_security_invoker,
  CASE
    WHEN COUNT(*) = 4 AND SUM(CASE WHEN creation_expression ILIKE '%security_invoker = true%' THEN 1 ELSE 0 END) = 4
      THEN '✅ All 4 views with security_invoker=true'
    WHEN COUNT(*) = 4 THEN '⚠️  4 views exist but security_invoker not all set'
    WHEN COUNT(*) > 0 THEN '⏳ Partial views (need 4)'
    ELSE '❌ No views found'
  END as status
FROM information_schema.views
WHERE table_schema = 'public'
AND table_name IN ('v_loan_listings', 'v_lender_offers', 'v_user_marketplace_activity', 'v_marketplace_activity');

-- ============================================================
-- SECTION 3: RLS ENFORCEMENT
-- ============================================================

SELECT
  'RLS POLICIES' as section,
  COUNT(DISTINCT tablename) as tables_with_rls,
  COUNT(*) as total_policies,
  CASE
    WHEN COUNT(DISTINCT tablename) >= 9 THEN '✅ RLS on 9+ tables'
    WHEN COUNT(DISTINCT tablename) >= 5 THEN '⏳ RLS on 5+ tables'
    ELSE '❌ RLS incomplete'
  END as status
FROM pg_policies
WHERE schemaname = 'public';

-- ============================================================
-- SECTION 4: SEED DATA (TEST ACCOUNTS)
-- ============================================================

SELECT
  'SEED DATA' as section,
  COUNT(*) as user_count,
  CASE
    WHEN COUNT(*) = 17 THEN '✅ All 17 test accounts loaded'
    WHEN COUNT(*) > 10 THEN '⏳ Most seed data loaded'
    WHEN COUNT(*) > 0 THEN '⏳ Partial seed data'
    ELSE '❌ No seed data'
  END as status
FROM auth.users
WHERE email IN (
  'david.mukasa@gmail.com', 'sarah.namukasa@yahoo.com', 'james.okello@outlook.com',
  'maria.nakato@gmail.com', 'robert.ssemwanga@gmail.com', 'info@greenleafagro.co.ug',
  'contact@kampalatech.ug', 'invest@pearlcapital.ug', 'funds@victoriainvest.co.ug',
  'lending@equatorfinance.ug', 'alice.namuli@gmail.com', 'admin1@nipanze.ug',
  'test.user@gmail.com'
);

-- ============================================================
-- SECTION 5: STORAGE BUCKET
-- ============================================================

SELECT
  'STORAGE SETUP' as section,
  CASE
    WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'verification-documents')
      THEN '✅ verification-documents bucket exists'
    ELSE '❌ verification-documents bucket missing'
  END as status,
  (SELECT COUNT(*) FROM storage.buckets WHERE name = 'verification-documents') as bucket_count;

-- ============================================================
-- SECTION 6: DATA MASKING CHECK
-- ============================================================

-- v_loan_listings should NOT have borrower_id
SELECT
  'DATA MASKING' as section,
  'v_loan_listings' as view_name,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ borrower_id NOT exposed'
    ELSE '❌ borrower_id EXPOSED (SECURITY RISK)'
  END as status
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'v_loan_listings'
AND column_name = 'borrower_id'

UNION ALL

-- v_lender_offers should NOT have lender contact details
SELECT
  'DATA MASKING' as section,
  'v_lender_offers' as view_name,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ No lender contact columns'
    ELSE '⚠️  Lender contact columns present (check if pre-reveal)'
  END as status
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'v_lender_offers'
AND column_name IN ('lender_phone', 'lender_email', 'lender_name');

-- ============================================================
-- SECTION 7: SYSTEM SETTINGS
-- ============================================================

SELECT
  'SYSTEM CONFIG' as section,
  COUNT(*) as setting_count,
  CASE
    WHEN COUNT(*) >= 10 THEN '✅ System settings configured'
    WHEN COUNT(*) > 0 THEN '⏳ Partial system settings'
    ELSE '❌ No system settings'
  END as status
FROM system_settings;

-- ============================================================
-- SECTION 8: ACTIVE LISTINGS (TEST)
-- ============================================================

SELECT
  'TEST DATA' as section,
  COUNT(*) as active_listings,
  CASE
    WHEN COUNT(*) >= 5 THEN '✅ Seed data includes active listings'
    WHEN COUNT(*) > 0 THEN '⏳ Some active listings present'
    ELSE '⚠️  No active listings (expected if seed not applied)'
  END as status
FROM loan_requests
WHERE status = 'active';

-- ============================================================
-- SUMMARY REPORT
-- ============================================================

/*
NEXT STEPS:
  - If ALL sections show ✅: Stage 3.5 is COMPLETE! Proceed to Stage 4.
  - If some show ❌ or ⏳: Follow STAGE_3.5_GUIDE.md to complete.
  - If you see ⚠️  warnings: Review the specific section and remediate.

EXECUTION ORDER (if not complete):
  1. Apply schema.sql (if ❌ table count)
  2. Apply seed.sql (if ❌ user count)
  3. Apply cloud_patch.sql (if ⚠️  in RLS policies)
  4. Apply stage-3.5-apply.sql (if ❌ storage bucket)
  5. Re-run this status check

Contact: contact@nipanze.ug
*/
