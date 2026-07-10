-- ============================================
-- NIPANZE — Cloud Patch v4.1
-- Brings an already-deployed Supabase Cloud project up to the
-- unified-model / Stage 4 schema described in README.md and BUILD_PLAN.md.
--
-- SAFE TO RE-RUN: every statement is guarded (IF NOT EXISTS / DO blocks
-- that check pg_catalog first). Nothing here drops data.
--
-- Run this in Supabase Dashboard → SQL Editor, as a single script.
-- The SQL Editor runs as the `postgres` role, so DDL should succeed even
-- where the CLI-applied objects are owned by a different migration role.
-- Where trigger-firing during backfill would reject legacy rows, this
-- script disables triggers locally via session_replication_role, exactly
-- like the AmbuLink workaround — never for permanent policy changes.
-- ============================================


-- ============================================
-- STEP 0 — Pre-flight notice
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Nipanze cloud_patch_v4_1.sql starting — target: unified subscription model + Stage 4 (agreements, locked terms, unlock_contact)';
END $$;


-- ============================================
-- STEP 1 — Enum alignment
-- Older cloud deployments may still carry the pre-unification
-- "dual subscription" labels described in BUILD_PLAN's migration
-- notes (e.g. a 'premium_borrower' plan). Rename them onto the
-- current free | lender | pro model instead of dropping history.
-- ============================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
        WHERE t.typname = 'subscription_plan_enum' AND e.enumlabel = 'premium_borrower'
    ) THEN
        ALTER TYPE subscription_plan_enum RENAME VALUE 'premium_borrower' TO 'pro';
        RAISE NOTICE 'Renamed subscription_plan_enum: premium_borrower -> pro';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
        WHERE t.typname = 'subscription_plan_enum' AND e.enumlabel = 'borrower'
    ) THEN
        ALTER TYPE subscription_plan_enum RENAME VALUE 'borrower' TO 'free';
        RAISE NOTICE 'Renamed subscription_plan_enum: borrower -> free';
    END IF;
END $$;

-- Ensure all three plan values exist even on a fresh/partial enum
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid WHERE t.typname = 'subscription_plan_enum' AND e.enumlabel = 'free')   THEN ALTER TYPE subscription_plan_enum ADD VALUE 'free';   END IF;
END $$;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid WHERE t.typname = 'subscription_plan_enum' AND e.enumlabel = 'lender') THEN ALTER TYPE subscription_plan_enum ADD VALUE 'lender'; END IF;
END $$;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid WHERE t.typname = 'subscription_plan_enum' AND e.enumlabel = 'pro')    THEN ALTER TYPE subscription_plan_enum ADD VALUE 'pro';    END IF;
END $$;

-- notification_type_enum: Stage 4 introduces 'agreement_locked'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
        WHERE t.typname = 'notification_type_enum' AND e.enumlabel = 'agreement_locked'
    ) THEN
        ALTER TYPE notification_type_enum ADD VALUE 'agreement_locked';
        RAISE NOTICE 'Added notification_type_enum value: agreement_locked';
    END IF;
END $$;

-- audit_event_type_enum: ensure agreement_locked is a loggable event
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
        WHERE t.typname = 'audit_event_type_enum' AND e.enumlabel = 'agreement_locked'
    ) THEN
        ALTER TYPE audit_event_type_enum ADD VALUE 'agreement_locked';
        RAISE NOTICE 'Added audit_event_type_enum value: agreement_locked';
    END IF;
END $$;

-- repayment_frequency_enum / agreement_status_enum: create only if entirely missing
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'repayment_frequency_enum') THEN
        CREATE TYPE repayment_frequency_enum AS ENUM ('weekly', 'monthly', 'one_time');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'agreement_status_enum') THEN
        CREATE TYPE agreement_status_enum AS ENUM ('pending', 'borrower_agreed', 'lender_agreed', 'locked');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reveal_status_enum') THEN
        CREATE TYPE reveal_status_enum AS ENUM ('pending', 'revealed');
    END IF;
END $$;


-- ============================================
-- STEP 2 — profiles: align `is_admin` naming from README/BUILD_PLAN
-- Keeps the existing `role` column (no breaking changes for clients
-- that already read it) and adds a generated `is_admin` boolean so
-- RLS/RPCs and app code can standardise on the README's terminology.
-- ============================================

ALTER TABLE profiles
    ADD COLUMN IF NOT EXISTS is_admin BOOLEAN GENERATED ALWAYS AS (role = 'admin') STORED;

COMMENT ON COLUMN profiles.is_admin IS
'Generated from role = ''admin''. The only stored role in the system per the unified marketplace model — everything else is gated by subscription_plan.';


-- ============================================
-- STEP 3 — loan_requests: Pro-tier term-suggestion columns
-- (posting leverage, locked on publish)
-- ============================================

ALTER TABLE loan_requests
    ADD COLUMN IF NOT EXISTS suggested_interest_rate_pct   NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS suggested_late_fee_pct        NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS suggested_repayment_frequency TEXT,
    ADD COLUMN IF NOT EXISTS suggested_installment_amount  BIGINT,
    ADD COLUMN IF NOT EXISTS terms_locked_at                TIMESTAMP;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_lr_suggested_interest_rate_range') THEN
        ALTER TABLE loan_requests ADD CONSTRAINT chk_lr_suggested_interest_rate_range
            CHECK (suggested_interest_rate_pct IS NULL OR
                   (suggested_interest_rate_pct >= 0 AND suggested_interest_rate_pct <= 100));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_lr_suggested_late_fee_range') THEN
        ALTER TABLE loan_requests ADD CONSTRAINT chk_lr_suggested_late_fee_range
            CHECK (suggested_late_fee_pct IS NULL OR
                   (suggested_late_fee_pct >= 0 AND suggested_late_fee_pct <= 100));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_lr_suggested_repayment_frequency') THEN
        ALTER TABLE loan_requests ADD CONSTRAINT chk_lr_suggested_repayment_frequency
            CHECK (suggested_repayment_frequency IS NULL OR
                   suggested_repayment_frequency IN ('weekly', 'monthly', 'one_time'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_lr_suggested_installment_positive') THEN
        ALTER TABLE loan_requests ADD CONSTRAINT chk_lr_suggested_installment_positive
            CHECK (suggested_installment_amount IS NULL OR suggested_installment_amount > 0);
    END IF;
END $$;


-- ============================================
-- STEP 4 — loan_offers: locked-term bidding columns
-- Backfill existing pending/legacy rows with safe defaults, then
-- enforce NOT NULL going forward. Triggers are disabled for the
-- backfill UPDATE only, so historical rows aren't rejected by the
-- new validate/lock triggers created in Step 6.
-- ============================================

ALTER TABLE loan_offers
    ADD COLUMN IF NOT EXISTS interest_rate_pct     NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS late_fee_pct          NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS repayment_frequency   TEXT,
    ADD COLUMN IF NOT EXISTS installment_amount    BIGINT,
    ADD COLUMN IF NOT EXISTS proposed_expectations TEXT,
    ADD COLUMN IF NOT EXISTS terms_locked_at       TIMESTAMP;

SET session_replication_role = 'replica';

-- Backfill any legacy rows that predate Stage 4 so NOT NULL can be applied safely.
UPDATE loan_offers
   SET interest_rate_pct   = COALESCE(interest_rate_pct, 0),
       late_fee_pct        = COALESCE(late_fee_pct, 0),
       repayment_frequency = COALESCE(repayment_frequency, 'monthly'),
       installment_amount  = COALESCE(installment_amount, offer_amount),
       terms_locked_at     = COALESCE(terms_locked_at, offered_at, created_at, CURRENT_TIMESTAMP)
 WHERE interest_rate_pct IS NULL
    OR late_fee_pct IS NULL
    OR repayment_frequency IS NULL
    OR installment_amount IS NULL
    OR terms_locked_at IS NULL;

SET session_replication_role = 'origin';

ALTER TABLE loan_offers
    ALTER COLUMN interest_rate_pct   SET NOT NULL,
    ALTER COLUMN late_fee_pct        SET NOT NULL,
    ALTER COLUMN repayment_frequency SET NOT NULL,
    ALTER COLUMN installment_amount  SET NOT NULL,
    ALTER COLUMN terms_locked_at     SET NOT NULL,
    ALTER COLUMN terms_locked_at     SET DEFAULT CURRENT_TIMESTAMP;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_lo_interest_rate_range') THEN
        ALTER TABLE loan_offers ADD CONSTRAINT chk_lo_interest_rate_range
            CHECK (interest_rate_pct >= 0 AND interest_rate_pct <= 100);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_lo_late_fee_range') THEN
        ALTER TABLE loan_offers ADD CONSTRAINT chk_lo_late_fee_range
            CHECK (late_fee_pct >= 0 AND late_fee_pct <= 100);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_lo_repayment_frequency') THEN
        ALTER TABLE loan_offers ADD CONSTRAINT chk_lo_repayment_frequency
            CHECK (repayment_frequency IN ('weekly', 'monthly', 'one_time'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_lo_installment_positive') THEN
        ALTER TABLE loan_offers ADD CONSTRAINT chk_lo_installment_positive
            CHECK (installment_amount > 0);
    END IF;
END $$;


-- ============================================
-- STEP 5 — agreements table (Stage 4)
-- Auto-generated locked contract, created only if it doesn't exist yet.
-- ============================================

CREATE TABLE IF NOT EXISTS agreements (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id                    UUID NOT NULL UNIQUE REFERENCES loan_offers(id) ON DELETE CASCADE,
    request_id                  UUID NOT NULL REFERENCES loan_requests(id) ON DELETE CASCADE,

    repayment_frequency         repayment_frequency_enum NOT NULL,
    repayment_amount            BIGINT NOT NULL CONSTRAINT chk_agr_repayment_positive CHECK (repayment_amount > 0),
    late_payment_penalty_pct    NUMERIC(5,2) NOT NULL DEFAULT 0
                                    CONSTRAINT chk_agr_penalty_range CHECK (late_payment_penalty_pct >= 0 AND late_payment_penalty_pct <= 100),

    agreement_text              TEXT NOT NULL,
    agreement_snapshot          JSONB,

    status                      agreement_status_enum NOT NULL DEFAULT 'locked',
    borrower_agreed_at          TIMESTAMP,
    lender_agreed_at            TIMESTAMP,
    locked_at                   TIMESTAMP,

    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (offer_id)
);

COMMENT ON TABLE agreements IS
'Locked loan agreement. Auto-generated after offer acceptance.
 Late payment penalty applies only to missed installments, not the total loan.
 Read-only after generation (snapshot captured immediately). All events logged in audit_logs.';

CREATE INDEX IF NOT EXISTS idx_agr_offer_id   ON agreements (offer_id);
CREATE INDEX IF NOT EXISTS idx_agr_request_id ON agreements (request_id);
CREATE INDEX IF NOT EXISTS idx_agr_status     ON agreements (status);


-- ============================================
-- STEP 6 — Functions & triggers (unified model + Stage 4 locking rules)
-- All CREATE OR REPLACE — safe to re-run.
-- ============================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION fn_generate_locked_contract_text(
    p_borrower_name TEXT,
    p_lender_name TEXT,
    p_loan_amount BIGINT,
    p_interest_rate_pct NUMERIC,
    p_total_repayment BIGINT,
    p_repayment_frequency TEXT,
    p_installment_amount BIGINT,
    p_duration_months INT,
    p_late_fee_pct NUMERIC
)
RETURNS TEXT LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN FORMAT(
'LOAN AGREEMENT

PARTIES
Borrower: %s
Lender: %s

LOCKED TERMS
Loan amount: UGX %s
Interest rate: %s%%
Total repayment amount: UGX %s
Repayment schedule: %s
Installment amount: UGX %s
Duration: %s months
Start date: %s
End date: %s

LATE PAYMENT RULE
A %s%% penalty applies only to a missed installment amount, not to the total loan balance.

DISCLAIMER
Nipanze provides this agreement for convenience only. The final obligation is solely between borrower and lender. Nipanze does not enforce repayment or hold funds.

Audit timestamp: %s',
        COALESCE(p_borrower_name, 'Borrower'),
        COALESCE(p_lender_name, 'Lender'),
        p_loan_amount, p_interest_rate_pct, p_total_repayment, p_repayment_frequency,
        p_installment_amount, p_duration_months, CURRENT_DATE,
        CURRENT_DATE + (p_duration_months || ' months')::INTERVAL,
        p_late_fee_pct, NOW()
    );
END;
$$;

-- Validate optional Pro-tier term suggestions before insert.
CREATE OR REPLACE FUNCTION trg_fn_validate_request_terms()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_plan subscription_plan_enum;
    v_has_suggestions BOOLEAN;
BEGIN
    v_has_suggestions :=
        NEW.suggested_interest_rate_pct IS NOT NULL OR
        NEW.suggested_late_fee_pct IS NOT NULL OR
        NEW.suggested_repayment_frequency IS NOT NULL OR
        NEW.suggested_installment_amount IS NOT NULL;

    IF v_has_suggestions THEN
        SELECT plan INTO v_plan
        FROM subscriptions
        WHERE user_id = NEW.borrower_id AND status = 'active'
        ORDER BY created_at DESC LIMIT 1;

        IF v_plan IS DISTINCT FROM 'pro'::subscription_plan_enum THEN
            RAISE EXCEPTION 'NIPANZE_PRO_REQUIRED: A Pro plan is required to suggest interest, late fee, or repayment terms.'
                USING ERRCODE = 'P0004';
        END IF;
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

-- Lock Pro-tier suggestions after publish — no post-publish edits.
CREATE OR REPLACE FUNCTION trg_fn_lock_request_terms()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.terms_locked_at IS NOT NULL AND (
        OLD.suggested_interest_rate_pct IS DISTINCT FROM NEW.suggested_interest_rate_pct OR
        OLD.suggested_late_fee_pct IS DISTINCT FROM NEW.suggested_late_fee_pct OR
        OLD.suggested_repayment_frequency IS DISTINCT FROM NEW.suggested_repayment_frequency OR
        OLD.suggested_installment_amount IS DISTINCT FROM NEW.suggested_installment_amount
    ) THEN
        RAISE EXCEPTION 'NIPANZE_REQUEST_TERMS_LOCKED: Terms cannot be edited after publish.'
            USING ERRCODE = 'P0005';
    END IF;
    RETURN NEW;
END;
$$;

-- Validate an offer before insert — requires Lender or Pro plan (unified model: no stored role).
CREATE OR REPLACE FUNCTION trg_fn_validate_offer()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_listing   loan_requests%ROWTYPE;
    v_min_offer BIGINT;
    v_plan      subscription_plan_enum;
BEGIN
    SELECT * INTO v_listing FROM loan_requests WHERE id = NEW.request_id;

    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE: This listing is no longer accepting offers.'
            USING ERRCODE = 'P0010';
    END IF;

    IF v_listing.expires_at < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_EXPIRED: This listing has expired.'
            USING ERRCODE = 'P0011';
    END IF;

    IF v_listing.borrower_id = NEW.lender_id THEN
        RAISE EXCEPTION 'NIPANZE_SELF_OFFER: You cannot make an offer on your own listing.'
            USING ERRCODE = 'P0012';
    END IF;

    SELECT setting_value::BIGINT INTO v_min_offer
    FROM system_settings WHERE setting_key = 'min_offer_amount';

    IF NEW.offer_amount < v_min_offer THEN
        RAISE EXCEPTION 'NIPANZE_MIN_OFFER: Offer amount must be at least UGX %.', v_min_offer
            USING ERRCODE = 'P0013';
    END IF;

    SELECT plan INTO v_plan
    FROM subscriptions
    WHERE user_id = NEW.lender_id AND status = 'active';

    IF v_plan NOT IN ('lender', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Lender or Pro plan is required to make offers.'
            USING ERRCODE = 'P0014';
    END IF;

    IF NEW.interest_rate_pct IS NULL OR NEW.late_fee_pct IS NULL OR
       NEW.repayment_frequency IS NULL OR NEW.installment_amount IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_TERMS_REQUIRED: Interest, late fee, repayment schedule, and installment amount are required.'
            USING ERRCODE = 'P0016';
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_fn_lock_accepted_offer()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.status = 'accepted' THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_LOCKED: An accepted offer cannot be modified.'
            USING ERRCODE = 'P0015';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_fn_lock_offer_terms()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.terms_locked_at IS NOT NULL AND (
        OLD.offer_amount IS DISTINCT FROM NEW.offer_amount OR
        OLD.interest_rate_pct IS DISTINCT FROM NEW.interest_rate_pct OR
        OLD.late_fee_pct IS DISTINCT FROM NEW.late_fee_pct OR
        OLD.repayment_frequency IS DISTINCT FROM NEW.repayment_frequency OR
        OLD.installment_amount IS DISTINCT FROM NEW.installment_amount OR
        OLD.proposed_expectations IS DISTINCT FROM NEW.proposed_expectations
    ) THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_TERMS_LOCKED: Offer terms cannot be edited after submit.'
            USING ERRCODE = 'P0017';
    END IF;
    RETURN NEW;
END;
$$;

-- (Re)install triggers using the definitions above. Dropped first so this
-- block is safe to re-run without duplicate-trigger errors.
DROP TRIGGER IF EXISTS trg_validate_request_terms ON loan_requests;
CREATE TRIGGER trg_validate_request_terms
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_validate_request_terms();

DROP TRIGGER IF EXISTS trg_lock_request_terms ON loan_requests;
CREATE TRIGGER trg_lock_request_terms
    BEFORE UPDATE ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_lock_request_terms();

DROP TRIGGER IF EXISTS trg_validate_offer ON loan_offers;
CREATE TRIGGER trg_validate_offer
    BEFORE INSERT ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_validate_offer();

DROP TRIGGER IF EXISTS trg_lock_accepted_offer ON loan_offers;
CREATE TRIGGER trg_lock_accepted_offer
    BEFORE UPDATE ON loan_offers
    FOR EACH ROW
    WHEN (OLD.status = 'accepted')
    EXECUTE FUNCTION trg_fn_lock_accepted_offer();

DROP TRIGGER IF EXISTS trg_lock_offer_terms ON loan_offers;
CREATE TRIGGER trg_lock_offer_terms
    BEFORE UPDATE ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_lock_offer_terms();

DROP TRIGGER IF EXISTS trg_agreements_updated_at ON agreements;
CREATE TRIGGER trg_agreements_updated_at
    BEFORE UPDATE ON agreements
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- ============================================
-- STEP 7 — RPCs: accept_offer / reveal_contact / unlock_contact
-- private.* internals + SECURITY INVOKER public wrappers, exactly as
-- established in Stage 3.5's private-schema wrapper pattern.
-- ============================================

CREATE SCHEMA IF NOT EXISTS private;
GRANT USAGE ON SCHEMA private TO authenticated, service_role;

CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS BOOLEAN LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public AS $$
    SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin');
$$;
REVOKE EXECUTE ON FUNCTION private.is_admin() FROM public, anon;
GRANT  EXECUTE ON FUNCTION private.is_admin() TO authenticated, service_role;

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
    v_listing loan_requests%ROWTYPE;
    v_offer   loan_offers%ROWTYPE;
    v_borrower profiles%ROWTYPE;
    v_lender   profiles%ROWTYPE;
    v_agreement_id UUID;
    v_total_repayment BIGINT;
    v_agreement_text TEXT;
    v_snapshot JSONB;
BEGIN
    IF p_caller_id IS NULL OR p_caller_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the request owner.' USING ERRCODE = 'P0021';
    END IF;

    SELECT * INTO v_listing FROM public.loan_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'NIPANZE_LISTING_NOT_FOUND' USING ERRCODE = 'P0020'; END IF;
    IF v_listing.borrower_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the listing owner can accept an offer.' USING ERRCODE = 'P0021';
    END IF;
    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE' USING ERRCODE = 'P0022';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers WHERE id = p_offer_id AND request_id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'NIPANZE_OFFER_NOT_FOUND' USING ERRCODE = 'P0023'; END IF;
    IF v_offer.status != 'pending' THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_PENDING: This offer is no longer available.' USING ERRCODE = 'P0024';
    END IF;

    SELECT * INTO v_borrower FROM public.profiles WHERE id = p_borrower_id;
    SELECT * INTO v_lender   FROM public.profiles WHERE id = v_offer.lender_id;

    v_total_repayment := ROUND(v_offer.offer_amount * (1 + (v_offer.interest_rate_pct / 100.0)))::BIGINT;

    v_snapshot := JSONB_BUILD_OBJECT(
        'request_id', p_request_id, 'offer_id', p_offer_id,
        'borrower_id', p_borrower_id, 'lender_id', v_offer.lender_id,
        'loan_amount', v_offer.offer_amount, 'interest_rate_pct', v_offer.interest_rate_pct,
        'total_repayment_amount', v_total_repayment, 'repayment_frequency', v_offer.repayment_frequency,
        'installment_amount', v_offer.installment_amount, 'late_fee_pct', v_offer.late_fee_pct,
        'late_fee_rule', 'Late fee applies only to missed installment amount, not total balance.',
        'start_date', CURRENT_DATE,
        'end_date', CURRENT_DATE + (v_listing.duration_months || ' months')::INTERVAL,
        'duration_months', v_listing.duration_months,
        'legal_disclaimer', 'Nipanze provides this agreement for convenience only. The final obligation is solely between the two parties. Nipanze does not enforce repayment or hold funds.',
        'locked_at', NOW()
    );

    v_agreement_text := public.fn_generate_locked_contract_text(
        v_borrower.full_name, v_lender.full_name, v_offer.offer_amount, v_offer.interest_rate_pct,
        v_total_repayment, v_offer.repayment_frequency, v_offer.installment_amount,
        v_listing.duration_months, v_offer.late_fee_pct
    );

    UPDATE public.loan_offers SET status = 'accepted', accepted_at = NOW() WHERE id = p_offer_id;
    UPDATE public.loan_offers SET status = 'rejected', updated_at = NOW()
     WHERE request_id = p_request_id AND id != p_offer_id AND status = 'pending';
    UPDATE public.loan_requests SET status = 'contracted', contracted_at = NOW() WHERE id = p_request_id;

    INSERT INTO public.agreements (
        offer_id, request_id, repayment_frequency, repayment_amount,
        late_payment_penalty_pct, agreement_text, agreement_snapshot,
        status, borrower_agreed_at, lender_agreed_at, locked_at
    )
    VALUES (
        p_offer_id, p_request_id, v_offer.repayment_frequency::public.repayment_frequency_enum,
        v_offer.installment_amount, v_offer.late_fee_pct, v_agreement_text, v_snapshot,
        'locked'::public.agreement_status_enum, NOW(), NOW(), NOW()
    )
    ON CONFLICT (offer_id) DO UPDATE
       SET agreement_text = EXCLUDED.agreement_text,
           agreement_snapshot = EXCLUDED.agreement_snapshot,
           status = 'locked'::public.agreement_status_enum,
           borrower_agreed_at = COALESCE(public.agreements.borrower_agreed_at, NOW()),
           lender_agreed_at = COALESCE(public.agreements.lender_agreed_at, NOW()),
           locked_at = COALESCE(public.agreements.locked_at, NOW())
    RETURNING id INTO v_agreement_id;

    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (p_borrower_id, 'agreement_locked', 'Contract generated',
         'Your selected offer is locked into a contract. Unlock contact details to connect.', p_request_id, p_offer_id),
        (v_offer.lender_id, 'agreement_locked', 'Contract generated',
         'Your offer was accepted and locked into a contract. Contact unlock is now available.', p_request_id, p_offer_id);

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES
        (p_borrower_id, 'offer_accepted', 'loan_offers', p_offer_id, 'accept_offer', v_snapshot),
        (p_borrower_id, 'agreement_locked', 'agreements', v_agreement_id, 'generate_locked_contract', v_snapshot);

    RETURN v_agreement_id;
END;
$$;
GRANT EXECUTE ON FUNCTION private.accept_offer_internal(uuid, uuid, uuid, uuid) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.accept_offer(p_request_id UUID, p_offer_id UUID, p_borrower_id UUID)
RETURNS UUID LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.accept_offer_internal(p_request_id, p_offer_id, p_borrower_id, auth.uid());
$$;
REVOKE EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION private.unlock_contact_internal(p_agreement_id UUID, p_caller_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_agreement agreements%ROWTYPE;
    v_offer     loan_offers%ROWTYPE;
    v_reveal    contact_reveals%ROWTYPE;
    v_borrower  profiles%ROWTYPE;
    v_lender    profiles%ROWTYPE;
    v_borrower_auth RECORD;
    v_lender_auth   RECORD;
    v_borrower_id UUID;
    v_lender_id   UUID;
    v_result JSONB;
BEGIN
    SELECT * INTO v_agreement FROM public.agreements WHERE id = p_agreement_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_FOUND' USING ERRCODE = 'P0041'; END IF;
    IF v_agreement.status != 'locked' THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_LOCKED: Agreement must be locked before unlocking contact.'
            USING ERRCODE = 'P0045';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers WHERE id = v_agreement.offer_id;
    SELECT borrower_id INTO v_borrower_id FROM public.loan_requests WHERE id = v_agreement.request_id;
    v_lender_id := v_offer.lender_id;

    IF p_caller_id != v_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the request owner can unlock contact details.'
            USING ERRCODE = 'P0046';
    END IF;

    SELECT * INTO v_borrower FROM public.profiles WHERE id = v_borrower_id;
    SELECT * INTO v_lender   FROM public.profiles WHERE id = v_lender_id;
    SELECT email INTO v_borrower_auth FROM auth.users WHERE id = v_borrower_id;
    SELECT email INTO v_lender_auth   FROM auth.users WHERE id = v_lender_id;

    SELECT * INTO v_reveal FROM public.contact_reveals WHERE offer_id = v_agreement.offer_id;
    IF v_reveal IS NULL THEN
        INSERT INTO public.contact_reveals (offer_id, request_id, revealed_by, status, revealed_at)
        VALUES (v_agreement.offer_id, v_agreement.request_id, v_borrower_id, 'revealed', NOW())
        RETURNING * INTO v_reveal;
    ELSE
        UPDATE public.contact_reveals SET status = 'revealed', revealed_at = NOW() WHERE id = v_reveal.id;
        v_reveal.status := 'revealed';
        v_reveal.revealed_at := NOW();
    END IF;

    v_result := JSONB_BUILD_OBJECT(
        'agreement_id', v_agreement.id, 'revealed_at', v_reveal.revealed_at,
        'borrower', JSONB_BUILD_OBJECT('full_name', v_borrower.full_name, 'phone', v_borrower.phone, 'email', v_borrower_auth.email),
        'lender',   JSONB_BUILD_OBJECT('full_name', v_lender.full_name,   'phone', v_lender.phone,   'email', v_lender_auth.email)
    );

    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (v_borrower_id, 'contact_revealed', 'Contact details unlocked', 'You can now connect with your lender directly.', v_agreement.request_id, v_agreement.offer_id),
        (v_lender_id,   'contact_revealed', 'Borrower unlocked contact', 'You can now connect with the request owner directly.', v_agreement.request_id, v_agreement.offer_id);

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_caller_id, 'contact_revealed', 'contact_reveals', v_reveal.id, 'unlock_contact',
        JSONB_BUILD_OBJECT('agreement_id', p_agreement_id, 'revealed_at', NOW()));

    RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION private.unlock_contact_internal(uuid, uuid) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.unlock_contact(p_agreement_id UUID)
RETURNS JSONB LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.unlock_contact_internal(p_agreement_id, auth.uid());
$$;
REVOKE EXECUTE ON FUNCTION public.unlock_contact(uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.unlock_contact(uuid) TO authenticated, service_role;


-- ============================================
-- STEP 8 — RLS for the agreements table
-- Guarded creation: skips a policy if one with the same name exists.
-- ============================================

ALTER TABLE agreements ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'agreements' AND policyname = 'agreements: matched parties read') THEN
        CREATE POLICY "agreements: matched parties read"
            ON agreements FOR SELECT TO authenticated
            USING (
                EXISTS (SELECT 1 FROM loan_requests lr WHERE lr.id = agreements.request_id AND lr.borrower_id = auth.uid())
                OR EXISTS (SELECT 1 FROM loan_offers lo WHERE lo.id = agreements.offer_id AND lo.lender_id = auth.uid())
                OR private.is_admin()
            );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'agreements' AND policyname = 'agreements: service role insert') THEN
        CREATE POLICY "agreements: service role insert" ON agreements FOR INSERT TO service_role WITH CHECK (TRUE);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'agreements' AND policyname = 'agreements: service role update') THEN
        CREATE POLICY "agreements: service role update" ON agreements FOR UPDATE TO service_role USING (TRUE) WITH CHECK (TRUE);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'agreements' AND policyname = 'agreements: admin all') THEN
        CREATE POLICY "agreements: admin all" ON agreements FOR ALL TO authenticated USING (private.is_admin());
    END IF;
END $$;


-- ============================================
-- STEP 9 — Views: recreate with security_invoker and the new columns
-- (request-owner id remains masked; Pro-tier suggested terms exposed
-- publicly since they're meant to attract offers)
-- ============================================

CREATE OR REPLACE VIEW v_loan_listings WITH (security_invoker = true) AS
SELECT
    lr.id                                                AS request_id,
    lr.title, lr.purpose, lr.district, lr.duration_months, lr.requested_amount,
    lr.preferred_repayment_plan, lr.repayment_amount_per_period, lr.repayment_timeline,
    lr.suggested_interest_rate_pct, lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency, lr.suggested_installment_amount, lr.terms_locked_at,
    lr.status, lr.number_of_offers, lr.listed_at, lr.expires_at,
    k.status                                             AS kyc_status,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')       AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')       AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')        AS closing_soon_6h
FROM  loan_requests   lr
LEFT  JOIN kyc_verifications k ON k.user_id = lr.borrower_id
WHERE lr.status = 'active';

COMMENT ON VIEW v_loan_listings IS
'Anonymised marketplace feed. Request-owner id, contact details, and private documents are never present.
 Pro-tier suggested terms are shown publicly to attract aligned offers.';

CREATE OR REPLACE VIEW v_lender_offers WITH (security_invoker = true) AS
SELECT
    lo.lender_id, lo.id AS offer_id, lo.request_id,
    lr.title AS listing_title, lr.purpose AS listing_purpose, lr.district, lr.duration_months, lr.requested_amount,
    lo.offer_amount, lo.interest_rate_pct, lo.late_fee_pct, lo.repayment_frequency,
    lo.installment_amount, lo.proposed_expectations, lo.terms_locked_at,
    lo.status AS offer_status, lo.offered_at, lo.accepted_at,
    cr.status AS reveal_status, cr.revealed_at
FROM  loan_offers     lo
JOIN  loan_requests   lr ON lr.id = lo.request_id
LEFT  JOIN contact_reveals cr ON cr.offer_id = lo.id;

COMMENT ON VIEW v_lender_offers IS
'Offer activity for the current account. Counterparty contact details not exposed until reveal_status = revealed.';

CREATE OR REPLACE VIEW v_marketplace_activity WITH (security_invoker = true) AS
SELECT
    DATE_TRUNC('month', lr.listed_at)                                         AS month,
    COUNT(lr.id)                                                              AS total_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'active')                        AS active_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'contracted')                    AS contracted_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'expired')                       AS expired_listings,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.status = 'pending')              AS pending_offers,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.status = 'accepted')             AS accepted_offers,
    ROUND(COUNT(DISTINCT lo.request_id) * 100.0 / NULLIF(COUNT(lr.id), 0), 1) AS match_rate_pct,
    (SELECT COUNT(*) FROM subscriptions WHERE status = 'active' AND plan != 'free') AS active_paid_subscribers
FROM  loan_requests lr
LEFT  JOIN loan_offers lo ON lo.request_id = lr.id
GROUP BY DATE_TRUNC('month', lr.listed_at)
ORDER BY month DESC;

CREATE OR REPLACE VIEW v_user_marketplace_activity WITH (security_invoker = true) AS
SELECT
    p.id AS user_id, p.full_name, p.account_status,
    COUNT(DISTINCT lr.id) FILTER (WHERE lr.borrower_id = p.id AND lr.status = 'active')      AS active_requests,
    COUNT(DISTINCT lr.id) FILTER (WHERE lr.borrower_id = p.id AND lr.status = 'contracted')  AS contracted_as_owner,
    COUNT(DISTINCT lr.id) FILTER (WHERE lr.borrower_id = p.id AND lr.status = 'expired')     AS expired_requests,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.lender_id = p.id AND lo.status = 'pending')       AS pending_offers,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.lender_id = p.id AND lo.status = 'accepted')      AS accepted_offers,
    s.plan AS subscription_plan, s.status AS subscription_status, s.expires_at AS subscription_expires_at,
    k.status AS kyc_status
FROM  profiles          p
LEFT  JOIN subscriptions      s  ON s.user_id = p.id AND s.status = 'active'
LEFT  JOIN kyc_verifications  k  ON k.user_id = p.id
LEFT  JOIN loan_requests      lr ON lr.borrower_id = p.id
LEFT  JOIN loan_offers        lo ON lo.lender_id   = p.id
GROUP BY p.id, s.plan, s.status, s.expires_at, k.status;

GRANT SELECT ON v_loan_listings              TO authenticated, anon;
GRANT SELECT ON v_lender_offers              TO authenticated, anon;
GRANT SELECT ON v_marketplace_activity       TO authenticated, anon;
GRANT SELECT ON v_user_marketplace_activity  TO authenticated, anon;


-- ============================================
-- STEP 10 — Realtime: add agreements to the publication if missing
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'agreements'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE agreements;
    END IF;
END $$;


-- ============================================
-- STEP 11 — Function security sweep
-- Keep internal/definer functions off anon/public per Stage 3.5's
-- Security Advisor pattern.
-- ============================================

REVOKE EXECUTE ON FUNCTION trg_fn_validate_request_terms() FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION trg_fn_lock_request_terms()     FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION trg_fn_validate_offer()         FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION trg_fn_lock_accepted_offer()    FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION trg_fn_lock_offer_terms()       FROM public, authenticated, anon;


-- ============================================
-- VERIFICATION
-- ============================================

SELECT table_name, exists_ok FROM (
    SELECT 'agreements'      AS table_name, EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'agreements') AS exists_ok
    UNION ALL SELECT 'loan_offers.terms_locked_at',
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'loan_offers' AND column_name = 'terms_locked_at')
    UNION ALL SELECT 'loan_requests.suggested_interest_rate_pct',
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'loan_requests' AND column_name = 'suggested_interest_rate_pct')
    UNION ALL SELECT 'profiles.is_admin',
        EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_admin')
    UNION ALL SELECT 'public.unlock_contact RPC',
        EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'unlock_contact')
    UNION ALL SELECT 'agreements in realtime publication',
        EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'agreements')
) t;

SELECT '✅ Nipanze cloud_patch_v4_1.sql applied — unified model + Stage 4 locking/agreements live on this project.' AS status;
