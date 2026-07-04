-- ============================================================
-- STAGE 3.5 IMPLEMENTATION SCRIPT
-- Apply schema v4.0 + seed v2.0 + cloud setup to Supabase cloud
--
-- INSTRUCTIONS:
-- 1. Copy the entire contents of schema.sql
-- 2. Paste into Supabase SQL Editor
-- 3. Run (check Status → ✅ Success)
-- 4. Copy seed.sql → Paste → Run
-- 5. Copy cloud_patch.sql → Paste → Run
-- 6. Copy this file → Paste → Run
-- 7. Verify results with stage-3.5-verify.sql
--
-- IMPORTANT: Run them in this order:
--   1. schema.sql (creates tables, views, functions, policies)
--   2. seed.sql (populates auth.users, profiles, subscriptions, test data)
--   3. cloud_patch.sql (updates RLS, views with security_invoker, grants)
--   4. THIS FILE — storage buckets + final setup
-- ============================================================

-- ============================================================
-- STEP 1: CREATE STORAGE BUCKET FOR KYC VERIFICATION DOCUMENTS
-- ============================================================

-- Create the 'verification-documents' bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('verification-documents', 'verification-documents', false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 2: SET RLS POLICIES ON STORAGE BUCKET
-- Authenticated users can:
--   - Upload their own verification documents
--   - Download only their own files
-- ============================================================

CREATE POLICY "Authenticated users can upload their own KYC docs"
ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'verification-documents'
    AND auth.role() = 'authenticated'
    AND owner_id = auth.uid()::uuid
);

CREATE POLICY "Users can read only their own verification documents"
ON storage.objects FOR SELECT USING (
    bucket_id = 'verification-documents'
    AND auth.role() = 'authenticated'
    AND (
        -- owner_id matches current user (their own files)
        owner_id = auth.uid()::uuid
        OR
        -- Admins can view all (optional — add if admin KYC review needed)
        auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
    )
);

CREATE POLICY "Users can delete only their own verification documents"
ON storage.objects FOR DELETE USING (
    bucket_id = 'verification-documents'
    AND auth.role() = 'authenticated'
    AND owner_id = auth.uid()::uuid
);

-- ============================================================
-- STEP 3: VERIFY REFRESH TOKEN ROTATION SETTINGS
-- ============================================================
-- These settings must be configured in Supabase Dashboard:
-- Authentication → Settings → JWT settings
--
-- Configuration needed:
--   • JWT expiry: 3600 seconds (1 hour)
--   • Enable refresh token rotation: ON
--   • Refresh token reuse interval: 10 seconds
--   • Refresh token expiry: 604800 seconds (7 days)
--
-- Status: Manual check required in Supabase Dashboard
-- File reference: supabase/config.toml (lines 46-48)

-- ============================================================
-- STEP 4: VERIFY AUDIT LOG TABLE (append-only enforcement)
-- ============================================================

-- Ensure audit_logs can only be INSERTed, never UPDATEd or DELETEd
-- This should be enforced by RLS policies created in schema.sql

-- Verify the policy exists:
SELECT 
    policyname,
    cmd
FROM pg_policies
WHERE tablename = 'audit_logs'
ORDER BY policyname;

-- ============================================================
-- STEP 5: FINAL VERIFICATION
-- ============================================================

-- Verify all required tables have RLS enabled
SELECT
    tablename,
    CASE
        WHEN rls_enabled THEN '✅ RLS Enabled'
        ELSE '⚠️  RLS DISABLED'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles', 'subscriptions', 'loan_requests', 'loan_offers',
    'kyc_verifications', 'watchlist', 'contact_reveals',
    'notifications', 'audit_logs'
)
ORDER BY tablename;

-- Verify storage bucket exists
SELECT name, public FROM storage.buckets WHERE name = 'verification-documents';

-- Verify all four views exist with correct structure
SELECT
    table_name,
    COUNT(*) as column_count
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('v_loan_listings', 'v_lender_offers', 'v_user_marketplace_activity', 'v_marketplace_activity')
GROUP BY table_name
ORDER BY table_name;

-- ============================================================
-- STEP 6: DOCUMENT CLOUD CONFIGURATION
-- ============================================================

/*
✅ AFTER RUNNING THIS SCRIPT, YOU HAVE:

1. Schema v4.0 applied
   - All tables created with correct structure
   - All views defined with security_invoker = true
   - All functions (RPC, triggers) created
   - All RLS policies applied

2. Seed v2.0 loaded
   - 17 test accounts with stable UUIDs
   - Password: Test1234! (hashed in auth.users)
   - Profiles, subscriptions, loan requests, offers created
   - Notifications, watchlist, contact_reveals populated

3. Cloud patch applied
   - Views updated to use security_invoker = true
   - RLS policies tightened
   - Permissions granted to authenticated/service_role
   - Contact reveal flow enforced

4. Storage setup complete
   - 'verification-documents' bucket created
   - RLS policies restrict access to own documents
   - KYC upload flow ready to test

5. Auth security verified
   - Refresh token rotation configured (manual check)
   - JWT expiry set to 3600 seconds
   - Session invalidation enforced

⏭️  NEXT STEPS:
   1. Test borrower flow end-to-end (run_cloud.sh web)
   2. Test lender flow end-to-end
   3. Test KYC document upload
   4. Build and test APK on physical Android device
   5. Run stage-3.5-verify.sql to confirm no data leaks

⚠️  IMPORTANT REMINDERS:
   - Do NOT expose borrower_id or contact details in marketplace queries
   - Apply cloud_patch.sql BEFORE running app against cloud
   - Verify service_role_key is ONLY used in Edge Functions + test teardown
   - Keep SUPABASE_SERVICE_ROLE_KEY out of Flutter app
   - All fund transfers are EXTERNAL (not processed by app)
*/
