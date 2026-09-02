-- ============================================================
-- Patch: Allow both Borrower and Lender in a locked deal to unlock contact details
-- Date: 2026-09-02
-- Description: Updates private.unlock_contact_internal to validate p_caller_id
--              against both borrower and lender IDs, and records p_caller_id
--              as revealed_by in contact_reveals.
-- ============================================================

CREATE OR REPLACE FUNCTION private.unlock_contact_internal(
    p_agreement_id UUID,
    p_caller_id UUID
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

    -- Caller validation (must be either borrower or lender)
    IF p_caller_id != v_borrower_id AND p_caller_id != v_lender_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only deal participants can unlock contact details.'
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
        VALUES (v_agreement.offer_id, v_agreement.request_id, p_caller_id, 'revealed', NOW())
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
        (v_borrower_id, 'contact_revealed', 'Contact details unlocked',
         'You can now connect with your lender directly.',
         v_agreement.request_id, v_agreement.offer_id),
        (v_lender_id, 'contact_revealed', 'Borrower unlocked contact',
         'You can now connect with the borrower directly.',
         v_agreement.request_id, v_agreement.offer_id);

    -- Audit
    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_caller_id, 'contact_revealed', 'contact_reveals', v_reveal.id, 'unlock_contact',
        JSONB_BUILD_OBJECT(
            'agreement_id', p_agreement_id,
            'revealed_at', NOW()
        ));

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION private.unlock_contact_internal(uuid, uuid) TO authenticated, service_role;
