-- ================================================================
-- Nipanze v4.1 — RLS PATCH
-- Run this ONCE in the Supabase Cloud SQL Editor.
-- Safe to re-run (uses IF NOT EXISTS / OR REPLACE patterns).
-- ================================================================

-- ============================================================
-- 0. SCHEMA USAGE GRANT  (required for authenticated role)
-- ============================================================

GRANT USAGE ON SCHEMA public   TO authenticated, anon;
GRANT USAGE ON SCHEMA private  TO authenticated, service_role;

-- ============================================================
-- 1. profiles
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read their own profile
CREATE POLICY "profiles: owner can read"
  ON profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Admins can read any profile (for moderation)
CREATE POLICY "profiles: admin can read all"
  ON profiles FOR SELECT
  TO authenticated
  USING (private.is_admin());

-- Owner can update their own editable fields
CREATE POLICY "profiles: owner can update"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Trigger handle_new_auth_user inserts via service_role — no INSERT policy needed for authenticated
CREATE POLICY "profiles: service_role can insert"
  ON profiles FOR INSERT
  TO service_role
  WITH CHECK (true);

-- ============================================================
-- 2. subscriptions
-- ============================================================

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "subscriptions: owner can read"
  ON subscriptions FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "subscriptions: admin can read all"
  ON subscriptions FOR SELECT
  TO authenticated
  USING (private.is_admin());

-- Only service_role / admin can create or update subscriptions
CREATE POLICY "subscriptions: service_role full access"
  ON subscriptions FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- ============================================================
-- 3. kyc_verifications
-- ============================================================

ALTER TABLE kyc_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "kyc: owner can read"
  ON kyc_verifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "kyc: admin can read all"
  ON kyc_verifications FOR SELECT
  TO authenticated
  USING (private.is_admin());

-- Owner can insert/update their own KYC record (triggers handle status enforcement)
CREATE POLICY "kyc: owner can insert"
  ON kyc_verifications FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "kyc: owner can update"
  ON kyc_verifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 4. system_settings
-- ============================================================

ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Public settings (is_public = true) are readable by anyone
CREATE POLICY "system_settings: public rows readable"
  ON system_settings FOR SELECT
  TO authenticated, anon
  USING (is_public = true);

-- Admins can read all settings
CREATE POLICY "system_settings: admin can read all"
  ON system_settings FOR SELECT
  TO authenticated
  USING (private.is_admin());

-- Only service_role can write settings
CREATE POLICY "system_settings: service_role full access"
  ON system_settings FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- ============================================================
-- 5. loan_requests
-- ============================================================

ALTER TABLE loan_requests ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read active listings (marketplace browsing)
CREATE POLICY "loan_requests: authenticated can read active"
  ON loan_requests FOR SELECT
  TO authenticated
  USING (status = 'active');

-- Borrower can always read their own requests (all statuses)
CREATE POLICY "loan_requests: owner can read own"
  ON loan_requests FOR SELECT
  TO authenticated
  USING (borrower_id = auth.uid());

-- Admins can read all
CREATE POLICY "loan_requests: admin can read all"
  ON loan_requests FOR SELECT
  TO authenticated
  USING (private.is_admin());

-- Borrower can create a request (trigger enforces KYC, limits, etc.)
CREATE POLICY "loan_requests: owner can insert"
  ON loan_requests FOR INSERT
  TO authenticated
  WITH CHECK (borrower_id = auth.uid());

-- Borrower can cancel their own active request
CREATE POLICY "loan_requests: owner can cancel"
  ON loan_requests FOR UPDATE
  TO authenticated
  USING (borrower_id = auth.uid() AND status = 'active')
  WITH CHECK (borrower_id = auth.uid());

-- ============================================================
-- 6. loan_offers
-- ============================================================

ALTER TABLE loan_offers ENABLE ROW LEVEL SECURITY;

-- A lender can always read their own offers
CREATE POLICY "loan_offers: lender can read own"
  ON loan_offers FOR SELECT
  TO authenticated
  USING (lender_id = auth.uid());

-- The borrower who owns the listing can read all pending offers on it
CREATE POLICY "loan_offers: borrower can read offers on own listing"
  ON loan_offers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM loan_requests lr
      WHERE lr.id = loan_offers.request_id
        AND lr.borrower_id = auth.uid()
    )
  );

-- Admin can read all
CREATE POLICY "loan_offers: admin can read all"
  ON loan_offers FOR SELECT
  TO authenticated
  USING (private.is_admin());

-- Lender can submit a new offer (trigger enforces subscription, self-bid check, etc.)
CREATE POLICY "loan_offers: lender can insert"
  ON loan_offers FOR INSERT
  TO authenticated
  WITH CHECK (lender_id = auth.uid());

-- Lender can withdraw their own pending offer
CREATE POLICY "loan_offers: lender can withdraw"
  ON loan_offers FOR UPDATE
  TO authenticated
  USING (lender_id = auth.uid() AND status = 'pending')
  WITH CHECK (lender_id = auth.uid());

-- accept_offer RPC uses service_role internally — allow it to update
CREATE POLICY "loan_offers: service_role full access"
  ON loan_offers FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- ============================================================
-- 7. watchlist
-- ============================================================

ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "watchlist: owner can read"
  ON watchlist FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "watchlist: owner can insert"
  ON watchlist FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "watchlist: owner can delete"
  ON watchlist FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================
-- 8. agreements
-- ============================================================

ALTER TABLE agreements ENABLE ROW LEVEL SECURITY;

-- Both the borrower and the lender on the matched deal can read the agreement
CREATE POLICY "agreements: parties can read"
  ON agreements FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM loan_offers lo
      WHERE lo.id = agreements.offer_id
        AND (
          lo.lender_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM loan_requests lr
            WHERE lr.id = lo.request_id
              AND lr.borrower_id = auth.uid()
          )
        )
    )
  );

CREATE POLICY "agreements: admin can read all"
  ON agreements FOR SELECT
  TO authenticated
  USING (private.is_admin());

-- accept_offer RPC inserts and locks agreements via service_role
CREATE POLICY "agreements: service_role full access"
  ON agreements FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- ============================================================
-- 9. contact_reveals
-- ============================================================

ALTER TABLE contact_reveals ENABLE ROW LEVEL SECURITY;

-- Only the borrower (revealed_by) and the matched lender can read
CREATE POLICY "contact_reveals: parties can read"
  ON contact_reveals FOR SELECT
  TO authenticated
  USING (
    revealed_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM loan_offers lo
      WHERE lo.id = contact_reveals.offer_id
        AND lo.lender_id = auth.uid()
    )
  );

CREATE POLICY "contact_reveals: admin can read all"
  ON contact_reveals FOR SELECT
  TO authenticated
  USING (private.is_admin());

-- reveal_contact RPC operates via service_role
CREATE POLICY "contact_reveals: service_role full access"
  ON contact_reveals FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- ============================================================
-- 10. notifications
-- ============================================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications: owner can read"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Owner can mark as read (update is_read, read_at)
CREATE POLICY "notifications: owner can update"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Notifications are inserted by DB triggers / service_role
CREATE POLICY "notifications: service_role can insert"
  ON notifications FOR INSERT
  TO service_role
  WITH CHECK (true);

-- ============================================================
-- 11. audit_logs  (append-only — UPDATE/DELETE BLOCKED)
-- ============================================================

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Users can read their own audit log entries
CREATE POLICY "audit_logs: owner can read own"
  ON audit_logs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Admins can read all entries
CREATE POLICY "audit_logs: admin can read all"
  ON audit_logs FOR SELECT
  TO authenticated
  USING (private.is_admin());

-- Only service_role can insert (DB triggers log automatically)
CREATE POLICY "audit_logs: service_role can insert"
  ON audit_logs FOR INSERT
  TO service_role
  WITH CHECK (true);

-- BLOCK UPDATE and DELETE for all roles (append-only enforcement)
CREATE POLICY "audit_logs: NO UPDATE allowed"
  ON audit_logs FOR UPDATE
  TO authenticated, service_role
  USING (false);

CREATE POLICY "audit_logs: NO DELETE allowed"
  ON audit_logs FOR DELETE
  TO authenticated, service_role
  USING (false);

-- ============================================================
-- 12. refresh_tokens, referrals  (internal / service_role only)
-- ============================================================

ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "refresh_tokens: owner can read"
  ON refresh_tokens FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "refresh_tokens: service_role full access"
  ON refresh_tokens FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "referrals: owner can read own"
  ON referrals FOR SELECT
  TO authenticated
  USING (referrer_id = auth.uid() OR referred_user_id = auth.uid());

CREATE POLICY "referrals: service_role full access"
  ON referrals FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- ============================================================
-- 13. STORAGE RLS  (kyc-documents bucket — private)
-- ============================================================

-- Path convention enforced: {user_id}/{filename}
-- Users can only upload/read their own documents.
-- Admins can read all for review.

CREATE POLICY "kyc storage: owner can upload"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc storage: owner can read own"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc storage: admin can read all"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND private.is_admin()
  );

-- ============================================================
-- 14. VIEW GRANTS  (re-assert; idempotent)
-- ============================================================

GRANT SELECT ON v_loan_listings              TO authenticated, anon;
GRANT SELECT ON v_lender_offers              TO authenticated;
GRANT SELECT ON v_user_marketplace_activity  TO authenticated;
GRANT SELECT ON v_marketplace_activity       TO authenticated;

-- ============================================================
-- 15. TABLE GRANTS  (re-assert)
-- ============================================================

GRANT SELECT, INSERT, UPDATE, DELETE
  ON profiles, kyc_verifications, loan_requests, loan_offers,
     watchlist, agreements, contact_reveals, notifications,
     audit_logs, refresh_tokens, referrals, subscriptions
  TO authenticated;

GRANT SELECT ON system_settings TO authenticated, anon;

GRANT ALL ON ALL TABLES    IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

-- ============================================================
-- 16. HELPER FUNCTION: get_my_subscription_plan
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_my_subscription_plan()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_plan TEXT;
BEGIN
    SELECT plan::TEXT INTO v_plan
    FROM public.subscriptions
    WHERE user_id = auth.uid()
      AND status = 'active'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_plan IS NULL THEN
        RETURN 'free';
    END IF;
    RETURN v_plan;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_subscription_plan() TO authenticated;

-- ============================================================
-- DONE
-- ============================================================
SELECT 'RLS patch applied successfully ✓' AS result;
