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
-- 6. Copy fix_functions.sql → Paste → Run  (private schema + wrapper pattern)
-- 7. Copy this file → Paste → Run
-- 8. Verify results with stage-3.5-verify.sql
--
-- IMPORTANT: Run them in this order:
--   1. schema.sql       (creates tables, views, functions, policies)
--   2. seed.sql         (populates auth.users, profiles, subscriptions, test data)
--   3. cloud_patch.sql  (updates RLS, views with security_invoker, grants)
--   4. fix_functions.sql (private schema, wrapper pattern for accept_offer/reveal_contact)
--   5. THIS FILE        (storage buckets + final setup)
-- ============================================================


-- ============================================================
-- STEP 1: CREATE STORAGE BUCKET FOR KYC VERIFICATION DOCUMENTS
-- ============================================================

-- Create the 'verification-documents' bucket (idempotent)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'verification-documents',
    'verification-documents',
    FALSE,
    10485760,  -- 10 MB per file
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public            = EXCLUDED.public,
    file_size_limit   = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;


-- ============================================================
-- STEP 2: SET RLS POLICIES ON STORAGE BUCKET
-- Authenticated users can:
--   - Upload their own verification documents
--   - Download only their own files
--   - Delete their own pending uploads
-- Admins can view all documents for KYC review (Stage 5)
--
-- NOTE: owner_id in storage.objects is UUID, auth.uid() is UUID.
--       Do NOT cast to text — use direct UUID comparison.
-- ============================================================

-- Drop existing policies first (idempotent)
DROP POLICY IF EXISTS "Authenticated users can upload their own KYC docs"      ON storage.objects;
DROP POLICY IF EXISTS "Users can read only their own verification documents"    ON storage.objects;
DROP POLICY IF EXISTS "Users can delete only their own verification documents"  ON storage.objects;
DROP POLICY IF EXISTS "Admins can read all verification documents"              ON storage.objects;

-- Upload: authenticated user's files go under their own user_id folder
-- Path convention: verification-documents/{user_id}/{filename}
CREATE POLICY "Authenticated users can upload their own KYC docs"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'verification-documents'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Download: user sees only their own files; admins can see all
CREATE POLICY "Users can read only their own verification documents"
    ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'verification-documents'
        AND (
            (storage.foldername(name))[1] = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM public.profiles
                WHERE id = auth.uid() AND role = 'admin'
            )
        )
    );

-- Delete: user can remove only their own uploads
CREATE POLICY "Users can delete only their own verification documents"
    ON storage.objects FOR DELETE TO authenticated
    USING (
        bucket_id = 'verification-documents'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );


-- ============================================================
-- STEP 3: GRANT STORAGE SCHEMA ACCESS
-- Ensure authenticated users can interact with storage
-- ============================================================

GRANT USAGE ON SCHEMA storage TO authenticated;


-- ============================================================
-- STEP 4: ENSURE ALL CORE TABLES HAVE RLS ENABLED
-- (belt-and-suspenders — schema.sql already does this,
--  but safe to re-run after any DROP TABLE / recreation)
-- ============================================================

ALTER TABLE public.profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_requests      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_offers        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kyc_verifications  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlist          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_reveals    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refresh_tokens     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals          ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 5: AUDIT LOGS — append-only enforcement
-- Ensure audit_logs can only be INSERTed, never UPDATEd or DELETEd
-- ============================================================

DROP POLICY IF EXISTS "audit_logs: no update" ON public.audit_logs;
DROP POLICY IF EXISTS "audit_logs: no delete" ON public.audit_logs;
DROP POLICY IF EXISTS "audit_logs: service role insert" ON public.audit_logs;

-- Block UPDATE and DELETE for everyone (append-only)
CREATE POLICY "audit_logs: no update"
    ON public.audit_logs FOR UPDATE TO authenticated
    USING (FALSE);

CREATE POLICY "audit_logs: no delete"
    ON public.audit_logs FOR DELETE TO authenticated
    USING (FALSE);

-- Allow internal INSERT via service_role (triggers / RPCs)
CREATE POLICY "audit_logs: service role insert"
    ON public.audit_logs FOR INSERT TO service_role
    WITH CHECK (TRUE);


-- ============================================================
-- STEP 6: NOTIFICATIONS — ensure write access for RPCs
-- The accept_offer and reveal_contact RPCs insert notifications.
-- Those RPCs run via private schema SECURITY DEFINER functions.
-- service_role needs INSERT access.
-- ============================================================

DROP POLICY IF EXISTS "notifications: service role insert" ON public.notifications;

CREATE POLICY "notifications: service role insert"
    ON public.notifications FOR INSERT TO service_role
    WITH CHECK (TRUE);

-- Allow authenticated users to mark their own notifications as read
DROP POLICY IF EXISTS "notifications: own update read" ON public.notifications;

CREATE POLICY "notifications: own update read"
    ON public.notifications FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());


-- ============================================================
-- STEP 7: REALTIME — ensure key tables are in the publication
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'loan_offers')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.loan_offers; END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'loan_requests')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.loan_requests; END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications; END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'contact_reveals')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.contact_reveals; END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'watchlist')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.watchlist; END IF;
END $$;


-- ============================================================
-- STEP 8: FORCE POSTGREST SCHEMA CACHE RELOAD
-- ============================================================

NOTIFY pgrst, 'reload schema';


-- ============================================================
-- ✅ SUMMARY — What this script does:
--
-- 1. Creates 'verification-documents' storage bucket (private, 10 MB limit)
-- 2. Sets RLS policies on storage.objects (path-based ownership)
-- 3. Ensures all 12 core tables have RLS enabled
-- 4. Enforces audit_logs as append-only (no UPDATE/DELETE)
-- 5. Adds notification write access for service_role + mark-as-read for users
-- 6. Adds watchlist to Realtime publication
-- 7. Forces PostgREST schema cache reload
--
-- MANUAL STEPS (Supabase Dashboard):
--   • Authentication → Settings → JWT:
--       JWT expiry: 3600 s
--       Enable refresh token rotation: ON
--       Refresh token reuse interval: 10 s
--   • Authentication → Settings → Security:
--       Enable "Prevent use of leaked passwords": ON
--
-- NEXT: Run stage-3.5-verify.sql to confirm all checks pass.
-- ============================================================
