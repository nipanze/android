-- ============================================================
-- NIPANZE Stage 4 — Structured Deal Agreement & Contact Sharing
-- Supabase Cloud SQL Editor patch
-- Safe to paste after Stage 3.5/cloud patches.
-- ============================================================

-- 0) Agreement infrastructure. These objects may already exist if an older
-- Stage 4 draft was applied; this keeps the updated patch self-contained.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type
         WHERE typnamespace = 'public'::regnamespace
           AND typname = 'repayment_frequency_enum'
    ) THEN
        CREATE TYPE public.repayment_frequency_enum AS ENUM ('weekly', 'monthly', 'one_time');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_type
         WHERE typnamespace = 'public'::regnamespace
           AND typname = 'agreement_status_enum'
    ) THEN
        CREATE TYPE public.agreement_status_enum AS ENUM ('pending', 'borrower_agreed', 'lender_agreed', 'locked');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.agreements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id UUID NOT NULL UNIQUE REFERENCES public.loan_offers(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES public.loan_requests(id) ON DELETE CASCADE,
    repayment_frequency public.repayment_frequency_enum NOT NULL,
    repayment_amount BIGINT NOT NULL CONSTRAINT chk_agr_repayment_positive CHECK (repayment_amount > 0),
    late_payment_penalty_pct NUMERIC(5,2) NOT NULL DEFAULT 0 CONSTRAINT chk_agr_penalty_range CHECK (late_payment_penalty_pct >= 0 AND late_payment_penalty_pct <= 100),
    agreement_text TEXT NOT NULL,
    agreement_snapshot JSONB,
    status public.agreement_status_enum NOT NULL DEFAULT 'pending',
    borrower_agreed_at TIMESTAMP,
    lender_agreed_at TIMESTAMP,
    locked_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agr_offer_id ON public.agreements (offer_id);
CREATE INDEX IF NOT EXISTS idx_agr_request_id ON public.agreements (request_id);
CREATE INDEX IF NOT EXISTS idx_agr_status ON public.agreements (status);

ALTER TABLE public.agreements ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
         WHERE tgname = 'trg_agreements_updated_at'
           AND tgrelid = 'public.agreements'::regclass
    ) THEN
        CREATE TRIGGER trg_agreements_updated_at
            BEFORE UPDATE ON public.agreements
            FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();
    END IF;
END $$;

DROP POLICY IF EXISTS "agreements: matched parties read" ON public.agreements;
CREATE POLICY "agreements: matched parties read"
    ON public.agreements FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.loan_requests lr
             WHERE lr.id = agreements.request_id
               AND lr.borrower_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.loan_offers lo
             WHERE lo.id = agreements.offer_id
               AND lo.lender_id = auth.uid()
        )
        OR private.is_admin()
    );

DROP POLICY IF EXISTS "agreements: service role insert" ON public.agreements;
CREATE POLICY "agreements: service role insert"
    ON public.agreements FOR INSERT TO service_role WITH CHECK (TRUE);

DROP POLICY IF EXISTS "agreements: service role update" ON public.agreements;
CREATE POLICY "agreements: service role update"
    ON public.agreements FOR UPDATE TO service_role USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "agreements: admin all" ON public.agreements;
CREATE POLICY "agreements: admin all"
    ON public.agreements FOR ALL TO authenticated USING (private.is_admin());

GRANT SELECT ON public.agreements TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.agreements TO service_role;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
         WHERE pubname = 'supabase_realtime'
           AND schemaname = 'public'
           AND tablename = 'agreements'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.agreements;
    END IF;
END $$;

-- 1) Locked borrower suggestions on loan_requests.
DROP TRIGGER IF EXISTS trg_lock_request_terms ON public.loan_requests;
DROP TRIGGER IF EXISTS trg_validate_request_terms ON public.loan_requests;

ALTER TABLE public.loan_requests
    ADD COLUMN IF NOT EXISTS suggested_interest_rate_pct NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS suggested_late_fee_pct NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS suggested_repayment_frequency TEXT,
    ADD COLUMN IF NOT EXISTS suggested_installment_amount BIGINT,
    ADD COLUMN IF NOT EXISTS terms_locked_at TIMESTAMP;

UPDATE public.loan_requests
   SET terms_locked_at = COALESCE(terms_locked_at, created_at, listed_at, NOW())
 WHERE terms_locked_at IS NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'chk_lr_suggested_interest_rate_range'
    ) THEN
        ALTER TABLE public.loan_requests
            ADD CONSTRAINT chk_lr_suggested_interest_rate_range
            CHECK (suggested_interest_rate_pct IS NULL OR
                   (suggested_interest_rate_pct >= 0 AND suggested_interest_rate_pct <= 100));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'chk_lr_suggested_late_fee_range'
    ) THEN
        ALTER TABLE public.loan_requests
            ADD CONSTRAINT chk_lr_suggested_late_fee_range
            CHECK (suggested_late_fee_pct IS NULL OR
                   (suggested_late_fee_pct >= 0 AND suggested_late_fee_pct <= 100));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'chk_lr_suggested_repayment_frequency'
    ) THEN
        ALTER TABLE public.loan_requests
            ADD CONSTRAINT chk_lr_suggested_repayment_frequency
            CHECK (suggested_repayment_frequency IS NULL OR
                   suggested_repayment_frequency IN ('weekly', 'monthly', 'one_time'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'chk_lr_suggested_installment_positive'
    ) THEN
        ALTER TABLE public.loan_requests
            ADD CONSTRAINT chk_lr_suggested_installment_positive
            CHECK (suggested_installment_amount IS NULL OR suggested_installment_amount > 0);
    END IF;
END $$;

COMMENT ON COLUMN public.loan_requests.terms_locked_at IS
'Stage 4: request terms are locked when the borrower publishes the request.';

-- 2) Locked lender bid terms on loan_offers.
DROP TRIGGER IF EXISTS trg_lock_accepted_offer ON public.loan_offers;
DROP TRIGGER IF EXISTS trg_lock_offer_terms ON public.loan_offers;

ALTER TABLE public.loan_offers
    ADD COLUMN IF NOT EXISTS interest_rate_pct NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS late_fee_pct NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS repayment_frequency TEXT,
    ADD COLUMN IF NOT EXISTS installment_amount BIGINT,
    ADD COLUMN IF NOT EXISTS terms_locked_at TIMESTAMP;

UPDATE public.loan_offers lo
   SET interest_rate_pct = COALESCE(lo.interest_rate_pct, 0),
       late_fee_pct = COALESCE(lo.late_fee_pct, 0),
       repayment_frequency = COALESCE(lo.repayment_frequency, lr.preferred_repayment_plan, 'monthly'),
       installment_amount = COALESCE(lo.installment_amount, lr.repayment_amount_per_period, lo.offer_amount),
       terms_locked_at = COALESCE(lo.terms_locked_at, lo.created_at, lo.offered_at, NOW())
  FROM public.loan_requests lr
 WHERE lr.id = lo.request_id;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'chk_lo_interest_rate_range'
    ) THEN
        ALTER TABLE public.loan_offers
            ADD CONSTRAINT chk_lo_interest_rate_range
            CHECK (interest_rate_pct >= 0 AND interest_rate_pct <= 100);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'chk_lo_late_fee_range'
    ) THEN
        ALTER TABLE public.loan_offers
            ADD CONSTRAINT chk_lo_late_fee_range
            CHECK (late_fee_pct >= 0 AND late_fee_pct <= 100);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'chk_lo_repayment_frequency'
    ) THEN
        ALTER TABLE public.loan_offers
            ADD CONSTRAINT chk_lo_repayment_frequency
            CHECK (repayment_frequency IN ('weekly', 'monthly', 'one_time'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'chk_lo_installment_positive'
    ) THEN
        ALTER TABLE public.loan_offers
            ADD CONSTRAINT chk_lo_installment_positive
            CHECK (installment_amount > 0);
    END IF;
END $$;

ALTER TABLE public.loan_offers
    ALTER COLUMN interest_rate_pct SET NOT NULL,
    ALTER COLUMN late_fee_pct SET NOT NULL,
    ALTER COLUMN repayment_frequency SET NOT NULL,
    ALTER COLUMN installment_amount SET NOT NULL,
    ALTER COLUMN terms_locked_at SET NOT NULL;

COMMENT ON COLUMN public.loan_offers.terms_locked_at IS
'Stage 4: lender bid terms are locked when the bid is submitted.';

-- 3) Request validation: basic borrowing is free; Pro borrowers may add suggested terms.
CREATE OR REPLACE FUNCTION public.trg_fn_validate_request_terms()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_plan public.subscription_plan_enum;
    v_has_suggestions BOOLEAN;
BEGIN
    v_has_suggestions :=
        NEW.suggested_interest_rate_pct IS NOT NULL OR
        NEW.suggested_late_fee_pct IS NOT NULL OR
        NEW.suggested_repayment_frequency IS NOT NULL OR
        NEW.suggested_installment_amount IS NOT NULL;

    IF v_has_suggestions THEN
        SELECT s.plan INTO v_plan
          FROM public.subscriptions s
         WHERE s.user_id = NEW.borrower_id
           AND s.status = 'active'
         ORDER BY s.created_at DESC
         LIMIT 1;

        IF v_plan IS DISTINCT FROM 'pro'::public.subscription_plan_enum THEN
            RAISE EXCEPTION 'NIPANZE_PRO_REQUIRED: A Pro borrower subscription is required to suggest interest, late fee, or repayment terms.'
                USING ERRCODE = 'P0004';
        END IF;
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_request_terms ON public.loan_requests;
CREATE TRIGGER trg_validate_request_terms
    BEFORE INSERT ON public.loan_requests
    FOR EACH ROW EXECUTE FUNCTION public.trg_fn_validate_request_terms();

CREATE OR REPLACE FUNCTION public.trg_fn_lock_request_terms()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.terms_locked_at IS NOT NULL AND (
        OLD.suggested_interest_rate_pct IS DISTINCT FROM NEW.suggested_interest_rate_pct OR
        OLD.suggested_late_fee_pct IS DISTINCT FROM NEW.suggested_late_fee_pct OR
        OLD.suggested_repayment_frequency IS DISTINCT FROM NEW.suggested_repayment_frequency OR
        OLD.suggested_installment_amount IS DISTINCT FROM NEW.suggested_installment_amount
    ) THEN
        RAISE EXCEPTION 'NIPANZE_REQUEST_TERMS_LOCKED: Borrower terms cannot be edited after publish.'
            USING ERRCODE = 'P0005';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_lock_request_terms ON public.loan_requests;
CREATE TRIGGER trg_lock_request_terms
    BEFORE UPDATE ON public.loan_requests
    FOR EACH ROW EXECUTE FUNCTION public.trg_fn_lock_request_terms();

-- 4) Bid validation: lender subscription remains required; structured terms are mandatory and locked.
CREATE OR REPLACE FUNCTION public.trg_fn_validate_offer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_listing public.loan_requests%ROWTYPE;
    v_min_offer BIGINT;
    v_plan public.subscription_plan_enum;
BEGIN
    SELECT * INTO v_listing FROM public.loan_requests WHERE id = NEW.request_id;

    IF NOT FOUND OR v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE: This listing is no longer accepting bids.'
            USING ERRCODE = 'P0010';
    END IF;

    IF v_listing.expires_at < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_EXPIRED: This listing has expired.'
            USING ERRCODE = 'P0011';
    END IF;

    IF v_listing.borrower_id = NEW.lender_id THEN
        RAISE EXCEPTION 'NIPANZE_SELF_OFFER: You cannot bid on your own listing.'
            USING ERRCODE = 'P0012';
    END IF;

    SELECT setting_value::BIGINT INTO v_min_offer
      FROM public.system_settings
     WHERE setting_key = 'min_offer_amount';

    IF NEW.offer_amount < COALESCE(v_min_offer, 0) THEN
        RAISE EXCEPTION 'NIPANZE_MIN_OFFER: Bid amount must be at least UGX %.', v_min_offer
            USING ERRCODE = 'P0013';
    END IF;

    SELECT s.plan INTO v_plan
      FROM public.subscriptions s
     WHERE s.user_id = NEW.lender_id
       AND s.status = 'active'
     ORDER BY s.created_at DESC
     LIMIT 1;

    IF v_plan NOT IN ('lender'::public.subscription_plan_enum, 'pro'::public.subscription_plan_enum) THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Lender or Pro subscription is required to make bids.'
            USING ERRCODE = 'P0014';
    END IF;

    IF NEW.interest_rate_pct IS NULL OR NEW.late_fee_pct IS NULL OR
       NEW.repayment_frequency IS NULL OR NEW.installment_amount IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_BID_TERMS_REQUIRED: Interest, late fee, repayment schedule, and installment amount are required.'
            USING ERRCODE = 'P0016';
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_fn_lock_accepted_offer()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.status = 'accepted' THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_LOCKED: An accepted offer cannot be modified.'
            USING ERRCODE = 'P0015';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_lock_accepted_offer ON public.loan_offers;
CREATE TRIGGER trg_lock_accepted_offer
    BEFORE UPDATE ON public.loan_offers
    FOR EACH ROW
    WHEN (OLD.status = 'accepted')
    EXECUTE FUNCTION public.trg_fn_lock_accepted_offer();

CREATE OR REPLACE FUNCTION public.trg_fn_lock_offer_terms()
RETURNS TRIGGER
LANGUAGE plpgsql
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
        RAISE EXCEPTION 'NIPANZE_BID_TERMS_LOCKED: Bid terms cannot be edited after submit.'
            USING ERRCODE = 'P0017';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_lock_offer_terms ON public.loan_offers;
CREATE TRIGGER trg_lock_offer_terms
    BEFORE UPDATE ON public.loan_offers
    FOR EACH ROW EXECUTE FUNCTION public.trg_fn_lock_offer_terms();

-- 5) Public marketplace feed and anonymized bid book include public term fields only.
DROP VIEW IF EXISTS public.v_loan_listings;
CREATE VIEW public.v_loan_listings WITH (security_invoker = true) AS
SELECT
    lr.id AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    lr.listed_at,
    lr.expires_at,
    k.status AS kyc_status,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h
FROM public.loan_requests lr
LEFT JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
WHERE lr.status = 'active';

GRANT SELECT ON public.v_loan_listings TO anon, authenticated;

DROP FUNCTION IF EXISTS public.get_public_listing_offers(UUID);

CREATE OR REPLACE FUNCTION public.get_public_listing_offers(p_request_id UUID)
RETURNS TABLE (
    id UUID,
    request_id UUID,
    lender_id TEXT,
    offer_amount BIGINT,
    interest_rate_pct NUMERIC,
    late_fee_pct NUMERIC,
    repayment_frequency TEXT,
    installment_amount BIGINT,
    proposed_expectations TEXT,
    terms_locked_at TIMESTAMP,
    status TEXT,
    offered_at TIMESTAMP,
    accepted_at TIMESTAMP
)
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT
        lo.id,
        lo.request_id,
        ('public-offer-' || ROW_NUMBER() OVER (ORDER BY lo.offered_at ASC))::TEXT AS lender_id,
        lo.offer_amount,
        lo.interest_rate_pct,
        lo.late_fee_pct,
        lo.repayment_frequency,
        lo.installment_amount,
        lo.proposed_expectations,
        lo.terms_locked_at,
        lo.status::TEXT,
        lo.offered_at,
        lo.accepted_at
    FROM public.loan_offers lo
    JOIN public.loan_requests lr ON lr.id = lo.request_id
    WHERE lo.request_id = p_request_id
      AND lo.status = 'pending'
      AND lr.status = 'active'
    ORDER BY lo.offered_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) TO anon, authenticated;

-- 6) Locked contract generation on bid acceptance.
CREATE OR REPLACE FUNCTION public.fn_generate_locked_contract_text(
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
RETURNS TEXT
LANGUAGE plpgsql
STABLE AS $$
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
        p_loan_amount,
        p_interest_rate_pct,
        p_total_repayment,
        p_repayment_frequency,
        p_installment_amount,
        p_duration_months,
        CURRENT_DATE,
        CURRENT_DATE + (p_duration_months || ' months')::INTERVAL,
        p_late_fee_pct,
        NOW()
    );
END;
$$;

DROP FUNCTION IF EXISTS public.accept_offer(uuid, uuid, uuid);
DROP FUNCTION IF EXISTS private.accept_offer_internal(uuid, uuid, uuid, uuid);
DROP FUNCTION IF EXISTS public.confirm_agreement(uuid);
DROP FUNCTION IF EXISTS private.confirm_agreement_internal(uuid, uuid);
DROP POLICY IF EXISTS "agreements: matched parties update" ON public.agreements;

CREATE OR REPLACE FUNCTION private.accept_offer_internal(
    p_request_id UUID,
    p_offer_id UUID,
    p_borrower_id UUID,
    p_caller_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_listing public.loan_requests%ROWTYPE;
    v_offer public.loan_offers%ROWTYPE;
    v_borrower public.profiles%ROWTYPE;
    v_lender public.profiles%ROWTYPE;
    v_agreement_id UUID;
    v_total_repayment BIGINT;
    v_agreement_text TEXT;
    v_snapshot JSONB;
BEGIN
    IF p_caller_id IS NULL OR p_caller_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the borrower.'
            USING ERRCODE = 'P0021';
    END IF;

    SELECT * INTO v_listing
      FROM public.loan_requests
     WHERE id = p_request_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_FOUND' USING ERRCODE = 'P0020';
    END IF;

    IF v_listing.borrower_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the listing owner can accept a bid.'
            USING ERRCODE = 'P0021';
    END IF;

    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE' USING ERRCODE = 'P0022';
    END IF;

    SELECT * INTO v_offer
      FROM public.loan_offers
     WHERE id = p_offer_id
       AND request_id = p_request_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_FOUND' USING ERRCODE = 'P0023';
    END IF;

    IF v_offer.status != 'pending' THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_PENDING: This bid is no longer available.'
            USING ERRCODE = 'P0024';
    END IF;

    SELECT * INTO v_borrower FROM public.profiles WHERE id = p_borrower_id;
    SELECT * INTO v_lender FROM public.profiles WHERE id = v_offer.lender_id;

    v_total_repayment := ROUND(v_offer.offer_amount * (1 + (v_offer.interest_rate_pct / 100.0)))::BIGINT;

    v_snapshot := JSONB_BUILD_OBJECT(
        'request_id', p_request_id,
        'offer_id', p_offer_id,
        'borrower_id', p_borrower_id,
        'lender_id', v_offer.lender_id,
        'loan_amount', v_offer.offer_amount,
        'interest_rate_pct', v_offer.interest_rate_pct,
        'total_repayment_amount', v_total_repayment,
        'repayment_frequency', v_offer.repayment_frequency,
        'installment_amount', v_offer.installment_amount,
        'late_fee_pct', v_offer.late_fee_pct,
        'late_fee_rule', 'Late fee applies only to missed installment amount, not total balance.',
        'start_date', CURRENT_DATE,
        'end_date', CURRENT_DATE + (v_listing.duration_months || ' months')::INTERVAL,
        'duration_months', v_listing.duration_months,
        'legal_disclaimer', 'Nipanze provides this agreement for convenience only. The final obligation is solely between borrower and lender. Nipanze does not enforce repayment or hold funds.',
        'locked_at', NOW()
    );

    v_agreement_text := public.fn_generate_locked_contract_text(
        v_borrower.full_name,
        v_lender.full_name,
        v_offer.offer_amount,
        v_offer.interest_rate_pct,
        v_total_repayment,
        v_offer.repayment_frequency,
        v_offer.installment_amount,
        v_listing.duration_months,
        v_offer.late_fee_pct
    );

    UPDATE public.loan_offers
       SET status = 'accepted',
           accepted_at = NOW()
     WHERE id = p_offer_id;

    UPDATE public.loan_offers
       SET status = 'rejected',
           updated_at = NOW()
     WHERE request_id = p_request_id
       AND id != p_offer_id
       AND status = 'pending';

    UPDATE public.loan_requests
       SET status = 'contracted',
           contracted_at = NOW()
     WHERE id = p_request_id;

    INSERT INTO public.agreements (
        offer_id,
        request_id,
        repayment_frequency,
        repayment_amount,
        late_payment_penalty_pct,
        agreement_text,
        agreement_snapshot,
        status,
        borrower_agreed_at,
        lender_agreed_at,
        locked_at
    )
    VALUES (
        p_offer_id,
        p_request_id,
        v_offer.repayment_frequency::public.repayment_frequency_enum,
        v_offer.installment_amount,
        v_offer.late_fee_pct,
        v_agreement_text,
        v_snapshot,
        'locked'::public.agreement_status_enum,
        NOW(),
        NOW(),
        NOW()
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
        (p_borrower_id, 'system'::public.notification_type_enum, 'Contract generated',
         'Your selected bid is locked into a contract. Unlock contact details to connect.',
         p_request_id, p_offer_id),
        (v_offer.lender_id, 'system'::public.notification_type_enum, 'Contract generated',
         'Your bid was accepted and locked into a contract. Contact unlock is now available.',
         p_request_id, p_offer_id);

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES
        (p_borrower_id, 'offer_accepted'::public.audit_event_type_enum, 'loan_offers', p_offer_id, 'accept_offer', v_snapshot),
        (p_borrower_id, 'offer_accepted'::public.audit_event_type_enum, 'agreements', v_agreement_id, 'generate_locked_contract', v_snapshot);

    RETURN v_agreement_id;
END;
$$;

GRANT EXECUTE ON FUNCTION private.accept_offer_internal(uuid, uuid, uuid, uuid) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.accept_offer(
    p_request_id UUID,
    p_offer_id UUID,
    p_borrower_id UUID
)
RETURNS UUID
LANGUAGE sql
SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.accept_offer_internal(p_request_id, p_offer_id, p_borrower_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.accept_offer IS
'Stage 4: accepts a locked lender bid, rejects competing bids, marks the request contracted, and creates a locked agreement. Returns agreement_id.';

-- 7) Contact unlock notification copy. The existing unlock_contact RPC remains
-- the API gate for contact details; this patch keeps the existing enum value.
DO $$
BEGIN
    RAISE NOTICE 'Stage 4 structured deal cloud patch applied.';
    RAISE NOTICE 'Next: paste/run sql/stage-4-structured-deal-verify.sql to verify columns, triggers, RPCs, and views.';
END $$;
