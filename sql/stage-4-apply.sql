-- ============================================================
-- NIPANZE Stage 4 — Contact Sharing & Deal Agreement (v4.0)
-- Supabase Cloud Patch — to apply via SQL Editor
-- ============================================================
-- This patch adds:
-- 1. New enums for repayment frequency and agreement status
-- 2. agreements table for structured deal agreements
-- 3. RPC functions for agreement workflow and contact unlock
-- 4. RLS policies for agreement access
-- 5. Realtime publication for agreements
-- 6. Updates to notification types
-- 7. Updates to audit event types
-- ============================================================


-- ============================================================
-- STEP 1: CREATE NEW ENUMS
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type WHERE typname = 'repayment_frequency_enum'
    ) THEN
        CREATE TYPE public.repayment_frequency_enum AS ENUM (
            'weekly', 'monthly', 'one_time'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_type WHERE typname = 'agreement_status_enum'
    ) THEN
        CREATE TYPE public.agreement_status_enum AS ENUM (
            'pending', 'borrower_agreed', 'lender_agreed', 'locked'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public'
          AND t.typname = 'notification_type_enum'
          AND e.enumlabel = 'agreement_generated'
    ) THEN
        ALTER TYPE public.notification_type_enum ADD VALUE 'agreement_generated' BEFORE 'kyc_approved';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public'
          AND t.typname = 'notification_type_enum'
          AND e.enumlabel = 'agreement_accepted'
    ) THEN
        ALTER TYPE public.notification_type_enum ADD VALUE 'agreement_accepted' BEFORE 'kyc_approved';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public'
          AND t.typname = 'notification_type_enum'
          AND e.enumlabel = 'agreement_locked'
    ) THEN
        ALTER TYPE public.notification_type_enum ADD VALUE 'agreement_locked' BEFORE 'kyc_approved';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public'
          AND t.typname = 'audit_event_type_enum'
          AND e.enumlabel = 'agreement_generated'
    ) THEN
        ALTER TYPE public.audit_event_type_enum ADD VALUE 'agreement_generated' AFTER 'offer_accepted';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public'
          AND t.typname = 'audit_event_type_enum'
          AND e.enumlabel = 'agreement_borrower_agreed'
    ) THEN
        ALTER TYPE public.audit_event_type_enum ADD VALUE 'agreement_borrower_agreed' AFTER 'agreement_generated';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public'
          AND t.typname = 'audit_event_type_enum'
          AND e.enumlabel = 'agreement_lender_agreed'
    ) THEN
        ALTER TYPE public.audit_event_type_enum ADD VALUE 'agreement_lender_agreed' AFTER 'agreement_borrower_agreed';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public'
          AND t.typname = 'audit_event_type_enum'
          AND e.enumlabel = 'agreement_locked'
    ) THEN
        ALTER TYPE public.audit_event_type_enum ADD VALUE 'agreement_locked' AFTER 'agreement_lender_agreed';
    END IF;
END$$;


-- ============================================================
-- STEP 2: CREATE AGREEMENTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.agreements (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id                    UUID NOT NULL UNIQUE REFERENCES public.loan_offers(id) ON DELETE CASCADE,
    request_id                  UUID NOT NULL REFERENCES public.loan_requests(id) ON DELETE CASCADE,

    -- Repayment terms (editable before both parties lock)
    repayment_frequency         public.repayment_frequency_enum NOT NULL,
    repayment_amount            BIGINT NOT NULL CONSTRAINT chk_agr_repayment_positive CHECK (repayment_amount > 0),
    late_payment_penalty_pct    NUMERIC(5,2) NOT NULL DEFAULT 0 CONSTRAINT chk_agr_penalty_range CHECK (late_payment_penalty_pct >= 0 AND late_payment_penalty_pct <= 100),

    -- Agreement text + snapshot (for audit trail)
    agreement_text              TEXT NOT NULL,
    agreement_snapshot          JSONB,  -- Full snapshot at lock time for immutability

    -- Confirmation tracking
    status                      public.agreement_status_enum NOT NULL DEFAULT 'pending',
    borrower_agreed_at          TIMESTAMP,
    lender_agreed_at            TIMESTAMP,
    locked_at                   TIMESTAMP,

    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- only one agreement per accepted offer
    UNIQUE (offer_id)
);

COMMENT ON TABLE public.agreements IS
'Loan agreement template & confirmation workflow. Auto-generated after offer acceptance.
 Both borrower and lender must agree before the agreement locks and contact details can be revealed.
 Late payment penalty applies only to missed installments, not the total loan.
 Agreement becomes read-only (snapshot captured) after both parties confirm.
 All agreement events are logged in audit_logs for traceability.';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_agr_offer_id    ON public.agreements (offer_id);
CREATE INDEX IF NOT EXISTS idx_agr_request_id  ON public.agreements (request_id);
CREATE INDEX IF NOT EXISTS idx_agr_status      ON public.agreements (status);

-- Auto-trigger updated_at
CREATE OR REPLACE TRIGGER trg_agreements_updated_at
    BEFORE UPDATE ON public.agreements
    FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();

-- Enable RLS
ALTER TABLE public.agreements ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 3: CREATE UTILITY FUNCTION (if not exists)
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_generate_agreement_text(
    p_borrower_name TEXT,
    p_lender_name TEXT,
    p_loan_amount BIGINT,
    p_repayment_frequency TEXT,
    p_repayment_amount BIGINT,
    p_duration_months INT,
    p_penalty_pct NUMERIC
)
RETURNS TEXT LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN FORMAT(
        '
LOAN AGREEMENT TEMPLATE

This document is a non-binding template provided by Nipanze for convenience.
The final agreement and all legal obligations are solely between the borrower and lender.

PARTIES:
- Borrower: %s
- Lender: %s

LOAN TERMS:
- Principal Amount: UGX %s
- Repayment Frequency: %s
- Repayment Amount Per Period: UGX %s
- Total Loan Duration: %s months

LATE PAYMENT PENALTY:
A penalty of %s%% applies ONLY to the amount of a missed installment, NOT to the total loan.
This ensures fair treatment and prevents excessive debt growth.

DISCLAIMER:
Nipanze does not hold or move funds. Both parties agree to complete all financial transactions
directly and outside this platform. This agreement is for reference only. The parties alone are
responsible for all repayment obligations and dispute resolution.

Generated on: %s
',
        p_borrower_name,
        p_lender_name,
        p_loan_amount,
        p_repayment_frequency,
        p_repayment_amount,
        p_duration_months,
        p_penalty_pct,
        NOW()
    );
END;
$$;


-- ============================================================
-- STEP 4: UPDATE accept_offer RPC (Stage 4 version)
-- Now returns agreement_id instead of reveal_id
-- Auto-generates structured agreement
-- ============================================================

-- Drop existing wrappers first
DROP FUNCTION IF EXISTS public.accept_offer(uuid, uuid, uuid);
DROP FUNCTION IF EXISTS private.accept_offer_internal(uuid, uuid, uuid, uuid);

-- Create updated internal function
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
    v_listing       public.loan_requests%ROWTYPE;
    v_offer         public.loan_offers%ROWTYPE;
    v_borrower      public.profiles%ROWTYPE;
    v_lender        public.profiles%ROWTYPE;
    v_agreement_id  UUID;
    v_agreement_text TEXT;
    v_penalty_pct   NUMERIC;
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

    -- Get party profiles
    SELECT * INTO v_borrower FROM public.profiles WHERE id = p_borrower_id;
    SELECT * INTO v_lender FROM public.profiles WHERE id = v_offer.lender_id;

    -- Accept chosen offer
    UPDATE public.loan_offers SET status = 'accepted', accepted_at = NOW() WHERE id = p_offer_id;

    -- Reject all other pending offers
    UPDATE public.loan_offers
       SET status = 'rejected', updated_at = NOW()
     WHERE request_id = p_request_id AND id != p_offer_id AND status = 'pending';

    -- Mark listing contracted
    UPDATE public.loan_requests
       SET status = 'contracted', contracted_at = NOW() WHERE id = p_request_id;

    -- Default penalty is 0% (will be editable by parties)
    v_penalty_pct := 0;

    -- Generate default agreement text
    v_agreement_text := public.fn_generate_agreement_text(
        v_borrower.full_name,
        v_lender.full_name,
        v_offer.offer_amount,
        v_listing.preferred_repayment_plan,
        v_listing.repayment_amount_per_period,
        v_listing.duration_months,
        v_penalty_pct
    );

    -- Create agreement (in 'pending' status — both parties must confirm)
    INSERT INTO public.agreements (
        offer_id, request_id,
        repayment_frequency, repayment_amount, late_payment_penalty_pct,
        agreement_text
    )
    VALUES (
        p_offer_id, p_request_id,
        v_listing.preferred_repayment_plan::public.repayment_frequency_enum,
        v_listing.repayment_amount_per_period,
        v_penalty_pct,
        v_agreement_text
    )
    RETURNING id INTO v_agreement_id;

    -- Notify both parties
    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (p_borrower_id, 'agreement_generated'::public.notification_type_enum, 'Deal agreement ready',
         'Review and confirm the structured loan agreement to unlock contact details.',
         p_request_id, p_offer_id),
        (v_offer.lender_id, 'agreement_generated'::public.notification_type_enum, 'Deal agreement ready',
         'Review and confirm the structured loan agreement to connect with the borrower.',
         p_request_id, p_offer_id);

    -- Audit
    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_borrower_id, 'offer_accepted'::public.audit_event_type_enum, 'loan_offers', p_offer_id, 'accept_offer',
        JSONB_BUILD_OBJECT(
            'request_id',  p_request_id,
            'offer_id',    p_offer_id,
            'agreement_id', v_agreement_id,
            'lender_id',   v_offer.lender_id,
            'accepted_at', NOW()
        ));

    RETURN v_agreement_id;
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

COMMENT ON FUNCTION public.accept_offer IS
'Atomically accepts an offer, rejects others, marks listing contracted, creates agreement.
 Returns agreement_id. Both parties must confirm agreement before contact reveal.
 Platform never holds or moves funds.';


-- ============================================================
-- STEP 5: CREATE confirm_agreement RPC
-- ============================================================

CREATE OR REPLACE FUNCTION private.confirm_agreement_internal(
    p_agreement_id UUID,
    p_caller_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_agreement  public.agreements%ROWTYPE;
    v_offer      public.loan_offers%ROWTYPE;
    v_borrower_id UUID;
    v_lender_id  UUID;
    v_result     JSONB;
BEGIN
    SELECT * INTO v_agreement FROM public.agreements WHERE id = p_agreement_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_FOUND' USING ERRCODE = 'P0041';
    END IF;
   
    IF v_agreement.status = 'locked' THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_LOCKED: This agreement has already been locked.'
            USING ERRCODE = 'P0042';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers WHERE id = v_agreement.offer_id;
    
    SELECT borrower_id INTO v_borrower_id FROM public.loan_requests WHERE id = v_agreement.request_id;
    v_lender_id := v_offer.lender_id;

    -- Determine who is confirming
    IF p_caller_id = v_borrower_id THEN
        -- Borrower confirming
        IF v_agreement.status IN ('pending', 'lender_agreed') THEN
            UPDATE public.agreements
               SET status = CASE
                       WHEN status = 'pending' THEN 'borrower_agreed'::public.agreement_status_enum
                       WHEN status = 'lender_agreed' THEN 'locked'::public.agreement_status_enum
                   END,
                   borrower_agreed_at = COALESCE(borrower_agreed_at, NOW()),
                   locked_at = CASE WHEN status = 'lender_agreed' THEN NOW() ELSE NULL END,
                   agreement_snapshot = CASE WHEN status = 'lender_agreed' THEN JSONB_BUILD_OBJECT(
                       'payment_frequency', repayment_frequency::TEXT,
                       'payment_amount', repayment_amount,
                       'penalty_pct', late_payment_penalty_pct,
                       'locked_at', NOW()
                   ) ELSE NULL END
             WHERE id = p_agreement_id;
        ELSE
            RAISE EXCEPTION 'NIPANZE_AGREEMENT_INVALID_STATE: Cannot confirm agreement in this state.'
                USING ERRCODE = 'P0043';
        END IF;
    ELSIF p_caller_id = v_lender_id THEN
        -- Lender confirming
        IF v_agreement.status IN ('pending', 'borrower_agreed') THEN
            UPDATE public.agreements
               SET status = CASE
                       WHEN status = 'pending' THEN 'lender_agreed'::public.agreement_status_enum
                       WHEN status = 'borrower_agreed' THEN 'locked'::public.agreement_status_enum
                   END,
                   lender_agreed_at = COALESCE(lender_agreed_at, NOW()),
                   locked_at = CASE WHEN status = 'borrower_agreed' THEN NOW() ELSE NULL END,
                   agreement_snapshot = CASE WHEN status = 'borrower_agreed' THEN JSONB_BUILD_OBJECT(
                       'payment_frequency', repayment_frequency::TEXT,
                       'payment_amount', repayment_amount,
                       'penalty_pct', late_payment_penalty_pct,
                       'locked_at', NOW()
                   ) ELSE NULL END
             WHERE id = p_agreement_id;
        ELSE
            RAISE EXCEPTION 'NIPANZE_AGREEMENT_INVALID_STATE: Cannot confirm agreement in this state.'
                USING ERRCODE = 'P0043';
        END IF;
    ELSE
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only borrower or lender can confirm this agreement.'
            USING ERRCODE = 'P0044';
    END IF;

    -- Re-fetch to get updated state
    SELECT * INTO v_agreement FROM public.agreements WHERE id = p_agreement_id;

    -- If now locked, create contact_reveal record
    IF v_agreement.status = 'locked' THEN
        INSERT INTO public.contact_reveals (offer_id, request_id, revealed_by)
        VALUES (v_agreement.offer_id, v_agreement.request_id, v_borrower_id)
        ON CONFLICT DO NOTHING;

        -- Notify both parties that agreement is locked
        INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
        VALUES
            (v_borrower_id, 'agreement_locked'::public.notification_type_enum, 'Deal agreement locked',
             'Both parties confirmed the agreement. You can now unlock contact details to connect.',
             v_agreement.request_id, v_agreement.offer_id),
            (v_lender_id, 'agreement_locked'::public.notification_type_enum, 'Deal agreement locked',
             'Both parties confirmed the agreement. Waiting for contact details to be unlocked.',
             v_agreement.request_id, v_agreement.offer_id);

        -- Audit
        INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
        VALUES (p_caller_id, 'agreement_locked'::public.audit_event_type_enum, 'agreements', p_agreement_id, 'confirm_agreement',
            JSONB_BUILD_OBJECT(
                'agreement_id', p_agreement_id,
                'locked_at', NOW()
            ));
    ELSE
        -- Notify the other party that one party has agreed
        IF p_caller_id = v_borrower_id THEN
            INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
            VALUES
                (v_lender_id, 'agreement_accepted'::public.notification_type_enum, 'Borrower confirmed agreement',
                 'The borrower confirmed the deal agreement. Please review and confirm to proceed.',
                 v_agreement.request_id, v_agreement.offer_id);
        ELSE
            INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
            VALUES
                (v_borrower_id, 'agreement_accepted'::public.notification_type_enum, 'Lender confirmed agreement',
                 'The lender confirmed the deal agreement. Please review and confirm to proceed.',
                 v_agreement.request_id, v_agreement.offer_id);
        END IF;

        -- Audit
        INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
        VALUES (p_caller_id,
            CASE WHEN p_caller_id = v_borrower_id THEN 'agreement_borrower_agreed'::public.audit_event_type_enum ELSE 'agreement_lender_agreed'::public.audit_event_type_enum END,
            'agreements', p_agreement_id, 'confirm_agreement',
            JSONB_BUILD_OBJECT('caller_id', p_caller_id, 'agreed_at', NOW()));
    END IF;

    v_result := JSONB_BUILD_OBJECT(
        'agreement_id', v_agreement.id,
        'status', v_agreement.status::TEXT,
        'borrower_agreed', (v_agreement.borrower_agreed_at IS NOT NULL),
        'lender_agreed', (v_agreement.lender_agreed_at IS NOT NULL),
        'locked', (v_agreement.status = 'locked')
    );

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION private.confirm_agreement_internal(uuid, uuid) TO authenticated, service_role;

-- Wrapper: SECURITY INVOKER
CREATE OR REPLACE FUNCTION public.confirm_agreement(p_agreement_id UUID)
RETURNS JSONB
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.confirm_agreement_internal(p_agreement_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.confirm_agreement(uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.confirm_agreement(uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.confirm_agreement IS
'Party (borrower or lender) confirms they agree to the structured loan agreement.
 Once both parties confirm, the agreement locks and contact_reveal is created.
 Returns agreement status. Contact reveal happens via unlock_contact only after lock.';


-- ============================================================
-- STEP 6: CREATE unlock_contact RPC
-- ============================================================

CREATE OR REPLACE FUNCTION private.unlock_contact_internal(
    p_agreement_id UUID,
    p_caller_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_agreement  public.agreements%ROWTYPE;
    v_offer      public.loan_offers%ROWTYPE;
    v_reveal     public.contact_reveals%ROWTYPE;
    v_borrower   public.profiles%ROWTYPE;
    v_lender     public.profiles%ROWTYPE;
    v_borrower_auth RECORD;
    v_lender_auth RECORD;
    v_borrower_id UUID;
    v_lender_id UUID;
    v_result JSONB;
BEGIN
    SELECT * INTO v_agreement FROM public.agreements WHERE id = p_agreement_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_FOUND' USING ERRCODE = 'P0041';
    END IF;

    IF v_agreement.status != 'locked' THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_LOCKED: Agreement must be locked before unlocking contact.'
            USING ERRCODE = 'P0045';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers WHERE id = v_agreement.offer_id;
    SELECT borrower_id INTO v_borrower_id FROM public.loan_requests WHERE id = v_agreement.request_id;
    v_lender_id := v_offer.lender_id;

    -- Caller validation (must be the borrower)
    IF p_caller_id != v_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the borrower can unlock contact details.'
            USING ERRCODE = 'P0046';
    END IF;

    -- Get profiles
    SELECT * INTO v_borrower FROM public.profiles WHERE id = v_borrower_id;
    SELECT * INTO v_lender FROM public.profiles WHERE id = v_lender_id;

    -- Get email from auth.users (requires SECURITY DEFINER)
    SELECT email INTO v_borrower_auth FROM auth.users WHERE id = v_borrower_id;
    SELECT email INTO v_lender_auth FROM auth.users WHERE id = v_lender_id;

    -- Get or create contact_reveal
    SELECT * INTO v_reveal FROM public.contact_reveals WHERE offer_id = v_agreement.offer_id;
    IF v_reveal IS NULL THEN
        INSERT INTO public.contact_reveals (offer_id, request_id, revealed_by, status, revealed_at)
        VALUES (v_agreement.offer_id, v_agreement.request_id, v_borrower_id, 'revealed', NOW())
        RETURNING * INTO v_reveal;
    ELSE
        UPDATE public.contact_reveals
           SET status = 'revealed', revealed_at = NOW()
         WHERE id = v_reveal.id;
        v_reveal.status := 'revealed';
        v_reveal.revealed_at := NOW();
    END IF;

    -- Result includes contact details
    v_result := JSONB_BUILD_OBJECT(
        'agreement_id', v_agreement.id,
        'revealed_at', v_reveal.revealed_at,
        'borrower', JSONB_BUILD_OBJECT(
            'full_name', v_borrower.full_name,
            'phone', v_borrower.phone,
            'email', v_borrower_auth.email
        ),
        'lender', JSONB_BUILD_OBJECT(
            'full_name', v_lender.full_name,
            'phone', v_lender.phone,
            'email', v_lender_auth.email
        )
    );

    -- Notify both parties
    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (v_borrower_id, 'contact_revealed'::public.notification_type_enum, 'Contact details unlocked',
         'You can now connect with your lender directly.',
         v_agreement.request_id, v_agreement.offer_id),
        (v_lender_id, 'contact_revealed'::public.notification_type_enum, 'Borrower unlocked contact',
         'You can now connect with the borrower directly.',
         v_agreement.request_id, v_agreement.offer_id);

    -- Audit
    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_caller_id, 'contact_revealed'::public.audit_event_type_enum, 'contact_reveals', v_reveal.id, 'unlock_contact',
        JSONB_BUILD_OBJECT(
            'agreement_id', p_agreement_id,
            'revealed_at', NOW()
        ));

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION private.unlock_contact_internal(uuid, uuid) TO authenticated, service_role;

-- Wrapper: SECURITY INVOKER
CREATE OR REPLACE FUNCTION public.unlock_contact(p_agreement_id UUID)
RETURNS JSONB
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.unlock_contact_internal(p_agreement_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.unlock_contact(uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.unlock_contact(uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.unlock_contact IS
'Borrower unlocks contact details after agreement is locked and both parties have confirmed.
 Reveals legal name, phone, and email of both parties. Irreversible. Returns contact JSONB.
 Platform never stores or retransmits these details after this point.';


--  ============================================================
-- STEP 7: CREATE RLS POLICIES FOR AGREEMENTS
-- ============================================================

-- Agreements: matched parties can read and update
CREATE POLICY "agreements: matched parties read"
    ON public.agreements FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.loan_requests lr
             WHERE lr.id = agreements.request_id AND lr.borrower_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.loan_offers lo
             WHERE lo.id = agreements.offer_id AND lo.lender_id = auth.uid()
        )
        OR private.is_admin()
    );

CREATE POLICY "agreements: matched parties update"
    ON public.agreements FOR UPDATE TO authenticated
    USING (
        (
            EXISTS (
                SELECT 1 FROM public.loan_requests lr
                 WHERE lr.id = agreements.request_id AND lr.borrower_id = auth.uid()
            )
            OR EXISTS (
                SELECT 1 FROM public.loan_offers lo
                 WHERE lo.id = agreements.offer_id AND lo.lender_id = auth.uid()
            )
        )
        AND status != 'locked'  -- Locked agreements cannot be updated
    );

CREATE POLICY "agreements: service role insert"
    ON public.agreements FOR INSERT TO service_role WITH CHECK (TRUE);

CREATE POLICY "agreements: admin all"
    ON public.agreements FOR ALL TO authenticated USING (private.is_admin());


-- ============================================================
-- STEP 8: ADD AGREEMENTS TO REALTIME PUBLICATION
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                    WHERE pubname = 'supabase_realtime' AND tablename = 'agreements')
    THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.agreements; END IF;
END $$;


-- ============================================================
-- STEP 9: GRANT TABLE PERMISSIONS
-- ============================================================

GRANT SELECT, INSERT, UPDATE ON public.agreements TO authenticated, service_role;


-- ============================================================
-- VERIFICATION & SUMMARY
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Stage 4 patch applied successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'New enums created:';
    RAISE NOTICE '  • repayment_frequency_enum (weekly, monthly, one_time)';
    RAISE NOTICE '  • agreement_status_enum (pending, borrower_agreed, lender_agreed, locked)';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables created/updated:';
    RAISE NOTICE '  • agreements (main deal agreement table)';
    RAISE NOTICE '  • notification_type_enum (added agreement events)';
    RAISE NOTICE '  • audit_event_type_enum (added agreement audit events)';
    RAISE NOTICE '';
    RAISE NOTICE 'RPC functions created:';
    RAISE NOTICE '  • accept_offer() — now returns agreement_id';
    RAISE NOTICE '  • confirm_agreement() — party confirms agreement terms';
    RAISE NOTICE '  • unlock_contact() — reveals contact after both agree';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS policies added for agreement access control';
    RAISE NOTICE 'Realtime publication updated with agreements table';
    RAISE NOTICE '';
END $$;
