-- ============================================================
-- NIPANZE — Security Advisor: Function Warnings Fix
-- Paste and run in Supabase SQL Editor.
-- ============================================================
-- Warnings being fixed:
--
--   ✅ is_admin()            — move to private schema so it is
--                              NOT reachable via /rpc/is_admin
--                              but still works inside RLS policies
--                              (RLS evaluates in the table-owner
--                              context which can call private fns)
--
--   ✅ accept_offer()        — intentional SECURITY DEFINER RPC.
--                              Warning cannot be fully suppressed
--                              without breaking the app. We harden
--                              it with SET search_path = '' and
--                              verify the caller IS the borrower.
--
--   ✅ reveal_contact()      — same as accept_offer: intentional.
--                              Hardened with SET search_path = ''.
--
--   ℹ️  Leaked passwords     — cannot be fixed via SQL.
--                              See step at the bottom of this file.
-- ============================================================


-- ============================================================
-- STEP 1: Move is_admin() to a non-exposed schema
-- ============================================================
-- PostgREST only exposes functions in the `public` schema
-- (by default). Moving is_admin to a `private` schema means:
--   • It cannot be called via /rest/v1/rpc/is_admin  ✅
--   • It CAN still be called by RLS USING clauses     ✅
--     (Postgres evaluates RLS using the table owner's
--      search_path which includes all schemas)
--   • It CAN still be called by our SECURITY DEFINER
--     RPCs (accept_offer, reveal_contact) via the
--     fully-qualified name private.is_admin()         ✅
-- ============================================================

-- Create the private schema (idempotent)
CREATE SCHEMA IF NOT EXISTS private;

-- Recreate is_admin in the private schema
-- (same body — just different schema)
CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS BOOLEAN LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
         WHERE id = auth.uid() AND role = 'admin'
    );
$$;

-- Remove the old public.is_admin — this kills the RPC exposure
-- and the security advisor warning.
-- NOTE: we drop after creating private.is_admin to avoid
-- a gap where the function doesn't exist.
DROP FUNCTION IF EXISTS public.is_admin();

-- Re-create public.is_admin as a thin SECURITY INVOKER wrapper
-- that just calls private.is_admin(). This keeps backward
-- compatibility if any Dart code ever calls it directly,
-- but PostgREST won't warn about SECURITY DEFINER on wrappers
-- that call other functions — they run as the caller.
-- Actually: just drop it. No Dart code calls is_admin() directly;
-- it is only used in RLS policies and the RPCs below.


-- ============================================================
-- STEP 2: Update ALL RLS policies that call is_admin()
--         to use private.is_admin() instead
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
DROP POLICY IF EXISTS "kyc: own or admin read"    ON kyc_verifications;
DROP POLICY IF EXISTS "kyc: own insert"           ON kyc_verifications;
DROP POLICY IF EXISTS "kyc: own or admin update"  ON kyc_verifications;
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
DROP POLICY IF EXISTS "contact_reveals: own or admin read" ON contact_reveals;
DROP POLICY IF EXISTS "contact_reveals: admin all"         ON contact_reveals;
CREATE POLICY "contact_reveals: own or admin read"
    ON contact_reveals FOR SELECT TO authenticated
    USING (revealed_by = auth.uid() OR private.is_admin());
CREATE POLICY "contact_reveals: admin all"
    ON contact_reveals FOR ALL TO authenticated
    USING (private.is_admin());

-- notifications
DROP POLICY IF EXISTS "notifications: own read"  ON notifications;
DROP POLICY IF EXISTS "notifications: admin all" ON notifications;
CREATE POLICY "notifications: own read"
    ON notifications FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "notifications: admin all"
    ON notifications FOR ALL TO authenticated
    USING (private.is_admin());

-- audit_logs
DROP POLICY IF EXISTS "audit_logs: own or admin read" ON audit_logs;
CREATE POLICY "audit_logs: own or admin read"
    ON audit_logs FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());

-- watchlist
DROP POLICY IF EXISTS "watchlist: own or admin read" ON watchlist;
DROP POLICY IF EXISTS "watchlist: own insert"        ON watchlist;
DROP POLICY IF EXISTS "watchlist: own or admin delete" ON watchlist;
CREATE POLICY "watchlist: own or admin read"
    ON watchlist FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "watchlist: own insert"
    ON watchlist FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
CREATE POLICY "watchlist: own or admin delete"
    ON watchlist FOR DELETE TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());

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
-- STEP 3: Rebuild accept_offer using private.is_admin()
--         and SET search_path = '' for maximum security
-- ============================================================
-- SET search_path = '' prevents search-path injection:
-- all table/function references must be fully qualified.
-- ============================================================

CREATE OR REPLACE FUNCTION public.accept_offer(
    p_request_id  UUID,
    p_offer_id    UUID,
    p_borrower_id UUID
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_listing        public.loan_requests%ROWTYPE;
    v_offer          public.loan_offers%ROWTYPE;
    v_reveal_id      UUID;
BEGIN
    -- Enforce: only the authenticated borrower can call this
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Not authenticated.'
            USING ERRCODE = 'P0001';
    END IF;
    IF auth.uid() != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the borrower.'
            USING ERRCODE = 'P0021';
    END IF;

    -- Lock and validate listing
    SELECT * INTO v_listing FROM public.loan_requests
     WHERE id = p_request_id FOR UPDATE;
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

    -- Lock and validate offer
    SELECT * INTO v_offer FROM public.loan_offers
     WHERE id = p_offer_id AND request_id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_FOUND' USING ERRCODE = 'P0023';
    END IF;
    IF v_offer.status != 'pending' THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_PENDING: This offer is no longer available.'
            USING ERRCODE = 'P0024';
    END IF;

    -- 1. Accept the chosen offer
    UPDATE public.loan_offers
       SET status = 'accepted', accepted_at = NOW()
     WHERE id = p_offer_id;

    -- 2. Reject all other pending offers on this listing
    UPDATE public.loan_offers
       SET status = 'rejected', updated_at = NOW()
     WHERE request_id = p_request_id
       AND id         != p_offer_id
       AND status     = 'pending';

    -- 3. Mark listing as contracted
    UPDATE public.loan_requests
       SET status = 'contracted', contracted_at = NOW()
     WHERE id = p_request_id;

    -- 4. Create a pending contact_reveal record
    INSERT INTO public.contact_reveals (offer_id, request_id, revealed_by)
    VALUES (p_offer_id, p_request_id, p_borrower_id)
    RETURNING id INTO v_reveal_id;

    -- 5. Notify both parties
    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (p_borrower_id,
         'offer_accepted',
         'Offer accepted',
         'You accepted an offer. Reveal contact details to connect with your lender.',
         p_request_id, p_offer_id),
        (v_offer.lender_id,
         'offer_accepted',
         'Your offer was accepted',
         'Your offer has been accepted. Waiting for contact details to be revealed.',
         p_request_id, p_offer_id);

    -- 6. Audit (immutable)
    INSERT INTO public.audit_logs (
        user_id, event_type, entity_type, entity_id, action, new_values
    )
    VALUES (
        p_borrower_id,
        'offer_accepted',
        'loan_offers',
        p_offer_id,
        'accept_offer',
        JSONB_BUILD_OBJECT(
            'request_id',    p_request_id,
            'offer_id',      p_offer_id,
            'lender_id',     v_offer.lender_id,
            'accepted_at',   NOW()
        )
    );

    RETURN v_reveal_id;
END;
$$;

COMMENT ON FUNCTION public.accept_offer IS
'Atomic offer acceptance. Requires caller to be the borrower (auth.uid() = p_borrower_id enforced inside).
 Marks offer accepted, rejects others, sets listing to contracted, creates contact_reveal record.
 Contact details are NOT revealed here — borrower calls reveal_contact() separately.
 Platform never holds or moves funds.';

-- Re-apply grants (SECURITY DEFINER — keep accessible by authenticated)
REVOKE EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) TO authenticated, service_role;


-- ============================================================
-- STEP 4: Rebuild reveal_contact with SET search_path = ''
-- ============================================================

CREATE OR REPLACE FUNCTION public.reveal_contact(
    p_reveal_id   UUID,
    p_borrower_id UUID
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
    -- Enforce: only the authenticated borrower can call this
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Not authenticated.'
            USING ERRCODE = 'P0001';
    END IF;
    IF auth.uid() != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the borrower.'
            USING ERRCODE = 'P0031';
    END IF;

    SELECT * INTO v_reveal FROM public.contact_reveals
     WHERE id = p_reveal_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_REVEAL_NOT_FOUND' USING ERRCODE = 'P0030';
    END IF;
    IF v_reveal.revealed_by != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the borrower who accepted can trigger contact reveal.'
            USING ERRCODE = 'P0031';
    END IF;
    IF v_reveal.status = 'revealed' THEN
        RAISE EXCEPTION 'NIPANZE_ALREADY_REVEALED: Contact details have already been revealed.'
            USING ERRCODE = 'P0032';
    END IF;

    SELECT * INTO v_offer    FROM public.loan_offers WHERE id = v_reveal.offer_id;
    SELECT * INTO v_borrower FROM public.profiles    WHERE id = p_borrower_id;
    SELECT * INTO v_lender   FROM public.profiles    WHERE id = v_offer.lender_id;

    -- auth.users requires service-role — SECURITY DEFINER grants this
    SELECT email INTO v_borrower_auth FROM auth.users WHERE id = p_borrower_id;
    SELECT email INTO v_lender_auth   FROM auth.users WHERE id = v_offer.lender_id;

    -- Mark revealed
    UPDATE public.contact_reveals
       SET status = 'revealed', revealed_at = NOW()
     WHERE id = p_reveal_id;

    v_result := JSONB_BUILD_OBJECT(
        'borrower', JSONB_BUILD_OBJECT(
            'full_name', v_borrower.full_name,
            'phone',     v_borrower.phone,
            'email',     v_borrower_auth.email
        ),
        'lender', JSONB_BUILD_OBJECT(
            'full_name', v_lender.full_name,
            'phone',     v_lender.phone,
            'email',     v_lender_auth.email
        )
    );

    -- Notify both parties
    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (p_borrower_id,
         'contact_revealed',
         'Contact details revealed',
         'You can now connect with your lender directly.',
         v_reveal.request_id, v_reveal.offer_id),
        (v_offer.lender_id,
         'contact_revealed',
         'Contact details revealed',
         'The borrower has accepted your offer. You can now connect directly.',
         v_reveal.request_id, v_reveal.offer_id);

    -- Audit (immutable)
    INSERT INTO public.audit_logs (
        user_id, event_type, entity_type, entity_id, action, new_values
    )
    VALUES (
        p_borrower_id,
        'contact_revealed',
        'contact_reveals',
        p_reveal_id,
        'reveal_contact',
        JSONB_BUILD_OBJECT(
            'offer_id',    v_reveal.offer_id,
            'request_id',  v_reveal.request_id,
            'lender_id',   v_offer.lender_id,
            'revealed_at', NOW()
        )
    );

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.reveal_contact IS
'Reveals contact details for both parties after an offer is accepted.
 Requires caller to be the borrower (auth.uid() = p_borrower_id enforced inside).
 Returns { borrower: { full_name, phone, email }, lender: { full_name, phone, email } }.
 Platform never holds or moves funds.';

REVOKE EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) TO authenticated, service_role;


-- ============================================================
-- STEP 5: Grant execute on private.is_admin to authenticated
--         so RLS policies can still invoke it
-- ============================================================

GRANT USAGE  ON SCHEMA private TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.is_admin() TO authenticated, service_role;


-- ============================================================
-- STEP 6: Force PostgREST schema cache reload
-- ============================================================

NOTIFY pgrst, 'reload schema';


-- ============================================================
-- ✅ SQL done. One manual step remains:
-- ============================================================
-- LEAKED PASSWORD PROTECTION (cannot be done via SQL):
--
--   1. Go to Supabase Dashboard
--   2. Authentication → Settings → Password Protection
--   3. Toggle ON "Enable HaveIBeenPwned password check"
--   4. Save
--
-- This makes Auth reject passwords found in data breaches.
-- ============================================================
