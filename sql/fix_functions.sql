-- ============================================================
-- NIPANZE — Function Security Fix (v3 — Wrapper Pattern)
-- Run in Supabase SQL Editor.
-- ============================================================
-- Resolves the following Security Advisor warnings:
--   ❌ public.accept_offer()    — "SECURITY DEFINER function can be executed by authenticated role"
--   ❌ public.reveal_contact()  — "SECURITY DEFINER function can be executed by authenticated role"
--
-- Solution:
--   1. Create internal _internal functions in the `private` schema
--      defined as `SECURITY DEFINER` (which can access auth.users,
--      notifications, audit logs, etc.).
--   2. Define the public-facing `public` functions as `SECURITY INVOKER`
--      which simply pass `auth.uid()` and arguments to the private
--      functions.
--   3. Since the public-facing endpoints are `SECURITY INVOKER`, the
--      Security Advisor warnings are completely cleared.
-- ============================================================


-- ============================================================
-- STEP 1: Create private schema and private.is_admin()
-- ============================================================

CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS BOOLEAN LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
         WHERE id = auth.uid() AND role = 'admin'
    );
$$;

GRANT USAGE  ON SCHEMA  private                 TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.is_admin()    TO authenticated, service_role;


-- ============================================================
-- STEP 2: Drop public.is_admin() with CASCADE
-- This automatically drops every RLS policy that references it.
-- ============================================================

DROP FUNCTION IF EXISTS public.is_admin() CASCADE;


-- ============================================================
-- STEP 3: Recreate ALL RLS policies using private.is_admin()
-- ============================================================

-- system_settings
DROP POLICY IF EXISTS "system_settings: authenticated read" ON system_settings;
DROP POLICY IF EXISTS "system_settings: admin write"        ON system_settings;
CREATE POLICY "system_settings: authenticated read"
    ON system_settings FOR SELECT TO authenticated
    USING (is_public = TRUE OR private.is_admin());
CREATE POLICY "system_settings: admin write"
    ON system_settings FOR ALL TO authenticated
    USING (private.is_admin());

-- profiles
DROP POLICY IF EXISTS "profiles: own or admin read" ON profiles;
DROP POLICY IF EXISTS "profiles: own update"         ON profiles;
CREATE POLICY "profiles: own or admin read"
    ON profiles FOR SELECT TO authenticated
    USING (id = auth.uid() OR private.is_admin());
CREATE POLICY "profiles: own update"
    ON profiles FOR UPDATE TO authenticated
    USING (id = auth.uid());

-- subscriptions
DROP POLICY IF EXISTS "subscriptions: own or admin read" ON subscriptions;
DROP POLICY IF EXISTS "subscriptions: admin write"       ON subscriptions;
CREATE POLICY "subscriptions: own or admin read"
    ON subscriptions FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "subscriptions: admin write"
    ON subscriptions FOR ALL TO authenticated
    USING (private.is_admin());

-- kyc_verifications
DROP POLICY IF EXISTS "kyc: own or admin read"   ON kyc_verifications;
DROP POLICY IF EXISTS "kyc: own insert"          ON kyc_verifications;
DROP POLICY IF EXISTS "kyc: own or admin update" ON kyc_verifications;
CREATE POLICY "kyc: own or admin read"
    ON kyc_verifications FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "kyc: own insert"
    ON kyc_verifications FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
CREATE POLICY "kyc: own or admin update"
    ON kyc_verifications FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());

-- loan_requests
DROP POLICY IF EXISTS "loan_requests: marketplace read"    ON loan_requests;
DROP POLICY IF EXISTS "loan_requests: own insert"          ON loan_requests;
DROP POLICY IF EXISTS "loan_requests: own or admin update" ON loan_requests;
DROP POLICY IF EXISTS "loan_requests: admin delete"        ON loan_requests;
CREATE POLICY "loan_requests: marketplace read"
    ON loan_requests FOR SELECT TO authenticated
    USING (status = 'active' OR borrower_id = auth.uid() OR private.is_admin());
CREATE POLICY "loan_requests: own insert"
    ON loan_requests FOR INSERT TO authenticated
    WITH CHECK (borrower_id = auth.uid());
CREATE POLICY "loan_requests: own or admin update"
    ON loan_requests FOR UPDATE TO authenticated
    USING (borrower_id = auth.uid() OR private.is_admin());
CREATE POLICY "loan_requests: admin delete"
    ON loan_requests FOR DELETE TO authenticated
    USING (private.is_admin());

-- loan_offers
DROP POLICY IF EXISTS "loan_offers: relevant parties read"    ON loan_offers;
DROP POLICY IF EXISTS "loan_offers: lender insert"            ON loan_offers;
DROP POLICY IF EXISTS "loan_offers: lender withdraw or admin" ON loan_offers;
CREATE POLICY "loan_offers: relevant parties read"
    ON loan_offers FOR SELECT TO authenticated
    USING (
        lender_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM loan_requests lr
             WHERE lr.id = loan_offers.request_id
               AND lr.borrower_id = auth.uid()
        )
        OR private.is_admin()
    );
CREATE POLICY "loan_offers: lender insert"
    ON loan_offers FOR INSERT TO authenticated
    WITH CHECK (lender_id = auth.uid());
CREATE POLICY "loan_offers: lender withdraw or admin"
    ON loan_offers FOR UPDATE TO authenticated
    USING (
        (lender_id = auth.uid() AND status = 'pending')
        OR private.is_admin()
    );

-- contact_reveals
DROP POLICY IF EXISTS "contact_reveals: matched parties read" ON contact_reveals;
DROP POLICY IF EXISTS "contact_reveals: admin write"          ON contact_reveals;
CREATE POLICY "contact_reveals: matched parties read"
    ON contact_reveals FOR SELECT TO authenticated
    USING (revealed_by = auth.uid() OR private.is_admin());
CREATE POLICY "contact_reveals: admin write"
    ON contact_reveals FOR ALL TO authenticated
    USING (private.is_admin());

-- notifications
DROP POLICY IF EXISTS "notifications: own read"  ON notifications;
DROP POLICY IF EXISTS "notifications: admin write" ON notifications;
CREATE POLICY "notifications: own read"
    ON notifications FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "notifications: admin write"
    ON notifications FOR ALL TO authenticated
    USING (private.is_admin());

-- audit_logs
DROP POLICY IF EXISTS "audit_logs: own or admin read" ON audit_logs;
CREATE POLICY "audit_logs: own or admin read"
    ON audit_logs FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());

-- watchlist
DROP POLICY IF EXISTS "watchlist: own read"   ON watchlist;
DROP POLICY IF EXISTS "watchlist: own insert" ON watchlist;
DROP POLICY IF EXISTS "watchlist: own delete" ON watchlist;
CREATE POLICY "watchlist: own read"
    ON watchlist FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "watchlist: own insert"
    ON watchlist FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
CREATE POLICY "watchlist: own delete"
    ON watchlist FOR DELETE TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());

-- refresh_tokens
DROP POLICY IF EXISTS "refresh_tokens: own or admin read" ON refresh_tokens;
DROP POLICY IF EXISTS "refresh_tokens: own insert"        ON refresh_tokens;
DROP POLICY IF EXISTS "refresh_tokens: own update"        ON refresh_tokens;
CREATE POLICY "refresh_tokens: own or admin read"
    ON refresh_tokens FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "refresh_tokens: own insert"
    ON refresh_tokens FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
CREATE POLICY "refresh_tokens: own update"
    ON refresh_tokens FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

-- referrals
DROP POLICY IF EXISTS "referrals: own or admin read" ON referrals;
DROP POLICY IF EXISTS "referrals: own insert"        ON referrals;
DROP POLICY IF EXISTS "referrals: admin write"       ON referrals;
CREATE POLICY "referrals: own or admin read"
    ON referrals FOR SELECT TO authenticated
    USING (referrer_id = auth.uid() OR private.is_admin());
CREATE POLICY "referrals: own insert"
    ON referrals FOR INSERT TO authenticated
    WITH CHECK (referrer_id = auth.uid());
CREATE POLICY "referrals: admin write"
    ON referrals FOR ALL TO authenticated
    USING (private.is_admin());


-- ============================================================
-- STEP 4: Create accept_offer internal and wrapper
-- ============================================================

-- Drop old clean public functions to avoid syntax clash
DROP FUNCTION IF EXISTS public.accept_offer(uuid, uuid, uuid) CASCADE;

CREATE OR REPLACE FUNCTION private.accept_offer_internal(
    p_request_id  UUID,
    p_offer_id    UUID,
    p_borrower_id UUID,
    p_caller_id   UUID
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_listing    public.loan_requests%ROWTYPE;
    v_offer      public.loan_offers%ROWTYPE;
    v_reveal_id  UUID;
BEGIN
    -- Caller validation (must be the borrower)
    IF p_caller_id IS NULL OR p_caller_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the borrower.'
            USING ERRCODE = 'P0021';
    END IF;

    SELECT * INTO v_listing FROM public.loan_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_FOUND' USING ERRCODE = 'P0020';
    END IF;
    IF v_listing.borrower_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the listing owner can accept an offer.'
            USING ERRCODE = 'P0021';
    END IF;
    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE' USING ERRCODE = 'P0022';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers
     WHERE id = p_offer_id AND request_id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_FOUND' USING ERRCODE = 'P0023';
    END IF;
    IF v_offer.status != 'pending' THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_PENDING: This offer is no longer available.'
            USING ERRCODE = 'P0024';
    END IF;

    -- Accept chosen offer
    UPDATE public.loan_offers SET status = 'accepted', accepted_at = NOW() WHERE id = p_offer_id;

    -- Reject all other pending offers
    UPDATE public.loan_offers
       SET status = 'rejected', updated_at = NOW()
     WHERE request_id = p_request_id AND id != p_offer_id AND status = 'pending';

    -- Mark listing contracted
    UPDATE public.loan_requests
       SET status = 'contracted', contracted_at = NOW() WHERE id = p_request_id;

    -- Create pending contact_reveal
    INSERT INTO public.contact_reveals (offer_id, request_id, revealed_by)
    VALUES (p_offer_id, p_request_id, p_borrower_id)
    RETURNING id INTO v_reveal_id;

    -- Notify both parties
    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (p_borrower_id, 'offer_accepted', 'Offer accepted',
         'You accepted an offer. Reveal contact details to connect with your lender.',
         p_request_id, p_offer_id),
        (v_offer.lender_id, 'offer_accepted', 'Your offer was accepted',
         'Your offer was accepted. Waiting for contact details to be revealed.',
         p_request_id, p_offer_id);

    -- Audit
    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_borrower_id, 'offer_accepted', 'loan_offers', p_offer_id, 'accept_offer',
        JSONB_BUILD_OBJECT(
            'request_id',  p_request_id,
            'offer_id',    p_offer_id,
            'lender_id',   v_offer.lender_id,
            'accepted_at', NOW()
        ));

    RETURN v_reveal_id;
END;
$$;

GRANT EXECUTE ON FUNCTION private.accept_offer_internal(uuid, uuid, uuid, uuid) TO authenticated, service_role;

-- Wrapper: SECURITY INVOKER
CREATE OR REPLACE FUNCTION public.accept_offer(
    p_request_id  UUID,
    p_offer_id    UUID,
    p_borrower_id UUID
)
RETURNS UUID
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.accept_offer_internal(p_request_id, p_offer_id, p_borrower_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) TO authenticated, service_role;


-- ============================================================
-- STEP 5: Create reveal_contact internal and wrapper
-- ============================================================

DROP FUNCTION IF EXISTS public.reveal_contact(uuid, uuid) CASCADE;

CREATE OR REPLACE FUNCTION private.reveal_contact_internal(
    p_reveal_id   UUID,
    p_borrower_id UUID,
    p_caller_id   UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_reveal        public.contact_reveals%ROWTYPE;
    v_offer         public.loan_offers%ROWTYPE;
    v_borrower      public.profiles%ROWTYPE;
    v_lender        public.profiles%ROWTYPE;
    v_borrower_auth RECORD;
    v_lender_auth   RECORD;
    v_result        JSONB;
BEGIN
    -- Caller validation (must be the borrower)
    IF p_caller_id IS NULL OR p_caller_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the borrower.'
            USING ERRCODE = 'P0031';
    END IF;

    SELECT * INTO v_reveal FROM public.contact_reveals WHERE id = p_reveal_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_REVEAL_NOT_FOUND' USING ERRCODE = 'P0030';
    END IF;
    IF v_reveal.revealed_by != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the borrower who accepted can trigger reveal.'
            USING ERRCODE = 'P0031';
    END IF;
    IF v_reveal.status = 'revealed' THEN
        RAISE EXCEPTION 'NIPANZE_ALREADY_REVEALED: Contact details already revealed.'
            USING ERRCODE = 'P0032';
    END IF;

    SELECT * INTO v_offer    FROM public.loan_offers WHERE id = v_reveal.offer_id;
    SELECT * INTO v_borrower FROM public.profiles    WHERE id = p_borrower_id;
    SELECT * INTO v_lender   FROM public.profiles    WHERE id = v_offer.lender_id;

    -- auth.users requires service-role — SECURITY DEFINER gives this
    SELECT email INTO v_borrower_auth FROM auth.users WHERE id = p_borrower_id;
    SELECT email INTO v_lender_auth   FROM auth.users WHERE id = v_offer.lender_id;

    UPDATE public.contact_reveals SET status = 'revealed', revealed_at = NOW() WHERE id = p_reveal_id;

    v_result := JSONB_BUILD_OBJECT(
        'borrower', JSONB_BUILD_OBJECT(
            'full_name', v_borrower.full_name, 'phone', v_borrower.phone, 'email', v_borrower_auth.email),
        'lender', JSONB_BUILD_OBJECT(
            'full_name', v_lender.full_name, 'phone', v_lender.phone, 'email', v_lender_auth.email)
    );

    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (p_borrower_id, 'contact_revealed', 'Contact details revealed',
         'You can now connect with your lender directly.', v_reveal.request_id, v_reveal.offer_id),
        (v_offer.lender_id, 'contact_revealed', 'Contact details revealed',
         'The borrower accepted your offer. You can now connect directly.', v_reveal.request_id, v_reveal.offer_id);

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_borrower_id, 'contact_revealed', 'contact_reveals', p_reveal_id, 'reveal_contact',
        JSONB_BUILD_OBJECT(
            'offer_id',   v_reveal.offer_id,
            'request_id', v_reveal.request_id,
            'lender_id',  v_offer.lender_id,
            'revealed_at', NOW()
        ));

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION private.reveal_contact_internal(uuid, uuid, uuid) TO authenticated, service_role;

-- Wrapper: SECURITY INVOKER
CREATE OR REPLACE FUNCTION public.reveal_contact(
    p_reveal_id   UUID,
    p_borrower_id UUID
)
RETURNS JSONB
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.reveal_contact_internal(p_reveal_id, p_borrower_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) TO authenticated, service_role;


-- ============================================================
-- STEP 6: Force PostgREST schema cache reload
-- ============================================================

NOTIFY pgrst, 'reload schema';
