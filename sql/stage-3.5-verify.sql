-- ============================================================
-- STAGE 3.5 VERIFICATION & AUDIT SCRIPT
-- Run this in Supabase SQL Editor to verify cloud setup
-- ============================================================

-- ============================================================
-- SECTION 1: CHECK SCHEMA & TABLES EXIST
-- ============================================================
-- If any of these return 0, the schema hasn't been applied yet.

SELECT 'Tables' as check_type, COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('profiles', 'subscriptions', 'loan_requests', 'loan_offers', 'kyc_verifications', 'contact_reveals', 'notifications', 'watchlist', 'audit_logs');

-- ============================================================
-- SECTION 2: VERIFY VIEWS & SECURITY_INVOKER
-- ============================================================

SELECT
    table_name,
    table_type,
    CASE
        WHEN creation_expression ILIKE '%security_invoker = true%' THEN '✅ security_invoker=true'
        ELSE '⚠️  security_invoker NOT set'
    END as security_status
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN ('v_loan_listings', 'v_lender_offers', 'v_user_marketplace_activity', 'v_marketplace_activity');

-- ============================================================
-- SECTION 3: VERIFY v_loan_listings COLUMNS (no borrower_id)
-- ============================================================

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'v_loan_listings'
ORDER BY ordinal_position;

-- Check if borrower_id is in the view (it should NOT be)
SELECT COUNT(*) as borrower_id_exposed
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'v_loan_listings'
  AND column_name = 'borrower_id';

-- ============================================================
-- SECTION 4: VERIFY v_lender_offers COLUMNS
-- ============================================================

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'v_lender_offers'
ORDER BY ordinal_position;

-- Check if lender contact details are exposed before reveal
SELECT COUNT(*) as contact_details_exposed
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'v_lender_offers'
  AND column_name IN ('lender_phone', 'lender_email', 'lender_name');

-- ============================================================
-- SECTION 5: VERIFY RLS POLICIES EXIST
-- ============================================================

SELECT
    schemaname,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- ============================================================
-- SECTION 6: VERIFY STORAGE BUCKETS
-- ============================================================

SELECT
    id,
    name,
    public
FROM storage.buckets
WHERE name LIKE '%verification%' OR name LIKE '%kyc%' OR name LIKE '%documents%';

-- ============================================================
-- SECTION 7: CHECK SEED DATA (test accounts)
-- ============================================================

SELECT COUNT(*) as test_account_count
FROM auth.users
WHERE email IN (
    'david.mukasa@gmail.com',
    'sarah.namukasa@yahoo.com',
    'james.okello@outlook.com',
    'maria.nakato@gmail.com',
    'admin1@nipanze.ug'
);

-- ============================================================
-- SECTION 8: VERIFY REFRESH TOKEN ROTATION IN JWT
-- ============================================================
-- Check auth config (this may not be queryable via SQL)
-- You'll need to check in Supabase Dashboard → Authentication → Settings

SELECT
    current_setting('app.jwt_exp') as jwt_expiry_setting,
    current_setting('app.settings.jwt_exp_sec', true) as jwt_exp_seconds;

-- ============================================================
-- SECTION 9: SAMPLE RLS TESTS (as authenticated user)
-- ============================================================
-- These will behave differently based on who is running them

-- Test: Can a user see v_loan_listings?
SELECT COUNT(*) as visible_listings FROM v_loan_listings LIMIT 1;

-- Test: Can a user see their own profile?
SELECT id, full_name FROM profiles WHERE id = auth.uid()::uuid LIMIT 1;

-- Test: Can a user see other users' profiles? (should be blocked)
SELECT COUNT(*) as other_profiles FROM profiles WHERE id != auth.uid()::uuid LIMIT 1;

-- ============================================================
-- SUMMARY: Expected Results
-- ============================================================
/*
✅ If the script runs without major errors:
   - All core tables exist (profiles, loan_requests, loan_offers, etc.)
   - All four views are defined with security_invoker = true
   - v_loan_listings does NOT have borrower_id column
   - v_lender_offers does NOT have lender contact columns
   - RLS policies are defined on all tables
   - Seed data has been loaded (test accounts visible)
   - Storage bucket 'verification-documents' exists

⚠️  If you see warnings or 0 counts:
   - Schema has NOT been applied yet → run schema.sql + cloud_patch.sql
   - Seed data missing → run seed.sql
   - Storage buckets missing → create manually via Supabase Dashboard
   - RLS audit issues → review RLS policies section
*/
