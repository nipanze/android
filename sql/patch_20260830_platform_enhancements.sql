-- Platform enhancements: referral validation and account safety helpers.

CREATE OR REPLACE FUNCTION public.validate_referral_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code          TEXT;
    v_user_id       UUID;
    v_referrer_id   UUID;
    v_referrer_name TEXT;
BEGIN
    v_code := UPPER(TRIM(COALESCE(p_code, '')));
    v_user_id := auth.uid();

    IF v_code = '' THEN
        RETURN jsonb_build_object(
            'valid', FALSE,
            'reason', 'missing_code',
            'message', 'Enter a referral code.',
            'referrer_name', NULL
        );
    END IF;

    SELECT rm.profile_id, COALESCE(p.full_name, 'Nipanze member')
    INTO   v_referrer_id, v_referrer_name
    FROM   public.referral_marketers rm
    LEFT JOIN public.profiles p ON p.id = rm.profile_id
    WHERE  UPPER(rm.referral_code) = v_code
      AND  rm.status IN ('new', 'active')
    LIMIT  1;

    IF v_referrer_id IS NULL THEN
        SELECT p.id, COALESCE(p.full_name, 'Nipanze member')
        INTO   v_referrer_id, v_referrer_name
        FROM   public.profiles p
        WHERE  UPPER(p.referral_code) = v_code
        LIMIT  1;
    END IF;

    IF v_referrer_id IS NULL THEN
        RETURN jsonb_build_object(
            'valid', FALSE,
            'reason', 'code_not_found',
            'message', 'Referral code was not found.',
            'referrer_name', NULL
        );
    END IF;

    IF v_user_id IS NOT NULL AND v_referrer_id = v_user_id THEN
        RETURN jsonb_build_object(
            'valid', FALSE,
            'reason', 'self_referral',
            'message', 'You cannot use your own referral code.',
            'referrer_name', v_referrer_name
        );
    END IF;

    IF v_user_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.referrals WHERE referred_user_id = v_user_id
    ) THEN
        RETURN jsonb_build_object(
            'valid', FALSE,
            'reason', 'already_recorded',
            'message', 'A referral code has already been used on this account.',
            'referrer_name', v_referrer_name
        );
    END IF;

    RETURN jsonb_build_object(
        'valid', TRUE,
        'reason', 'ok',
        'message', 'Referral code accepted.',
        'referrer_name', v_referrer_name
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.validate_referral_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_referral_code(TEXT) TO anon;
