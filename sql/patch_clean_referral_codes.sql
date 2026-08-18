-- ==============================================================================
-- NIPANZE REFERRAL SYSTEM — CLEANUP & UPPERCASE PATCH (v2)
-- ==============================================================================
-- Run this script in your Supabase SQL Editor.
-- 1. Strips 'NIPANZE-' prefix from existing codes in profiles, marketers, & referrals.
-- 2. Converts all referral codes to UPPERCASE (so lowercase/caps lock won't confuse anyone).
-- 3. Updates generate_referral_code and ensure_my_referral_marketer functions.
-- ==============================================================================

-- 1. UPDATE EXISTING CODES IN DATABASE
--------------------------------------------------------------------------------

UPDATE public.referral_marketers
SET referral_code = UPPER(REGEXP_REPLACE(referral_code, '^NIPANZE-', '', 'i')),
    updated_at = CURRENT_TIMESTAMP
WHERE referral_code ILIKE 'NIPANZE-%' OR referral_code != UPPER(referral_code);

UPDATE public.profiles
SET referral_code = UPPER(REGEXP_REPLACE(referral_code, '^NIPANZE-', '', 'i')),
    updated_at = CURRENT_TIMESTAMP
WHERE referral_code ILIKE 'NIPANZE-%' OR referral_code != UPPER(referral_code);

UPDATE public.referrals
SET referral_code = UPPER(REGEXP_REPLACE(referral_code, '^NIPANZE-', '', 'i')),
    updated_at = CURRENT_TIMESTAMP
WHERE referral_code ILIKE 'NIPANZE-%' OR referral_code != UPPER(referral_code);


-- 2. UPDATE CODE GENERATOR (NO NIPANZE PREFIX & ALWAYS UPPERCASE)
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.generate_referral_code(p_full_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_seed TEXT;
    v_code TEXT;
BEGIN
    v_seed := UPPER(REGEXP_REPLACE(COALESCE(NULLIF(SPLIT_PART(TRIM(p_full_name), ' ', 1), ''), 'USER'), '[^A-Z0-9]', '', 'g'));
    v_seed := LEFT(COALESCE(NULLIF(v_seed, ''), 'USER'), 5);

    LOOP
        v_code := v_seed || UPPER(SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', '') FROM 1 FOR 4));
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.referral_marketers WHERE UPPER(referral_code) = v_code
        ) AND NOT EXISTS (
            SELECT 1 FROM public.profiles WHERE UPPER(referral_code) = v_code
        );
    END LOOP;

    RETURN v_code;
END;
$$;


-- 3. UPDATE ENSURE FUNCTION TO AUTO-CLEAN EXISTING RECORDS ON FETCH
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.ensure_my_referral_marketer(p_country TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile  public.profiles%ROWTYPE;
    v_marketer public.referral_marketers%ROWTYPE;
    v_campaign_id UUID;
    v_country TEXT;
    v_code    TEXT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND THEN
        INSERT INTO public.profiles (id, email, full_name, account_status)
        VALUES (
            auth.uid(),
            COALESCE((SELECT email FROM auth.users WHERE id = auth.uid()), 'user@nipanze.app'),
            'Nipanze User',
            'active'
        )
        ON CONFLICT (id) DO NOTHING;
        SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    END IF;

    v_country := UPPER(COALESCE(NULLIF(p_country, ''), v_profile.country, 'UG'));
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE code = v_country) THEN
        v_country := v_profile.country;
    END IF;

    -- Clean up legacy prefix / mixed-case on v_profile.referral_code if present
    IF v_profile.referral_code IS NOT NULL AND (v_profile.referral_code ILIKE 'NIPANZE-%' OR v_profile.referral_code != UPPER(v_profile.referral_code)) THEN
        v_profile.referral_code := UPPER(REGEXP_REPLACE(v_profile.referral_code, '^NIPANZE-', '', 'i'));
        UPDATE public.profiles
        SET referral_code = v_profile.referral_code
        WHERE id = v_profile.id;
    END IF;

    SELECT id INTO v_campaign_id
    FROM public.referral_campaigns
    WHERE status = 'active'
      AND (country IS NULL OR country = v_country)
      AND (start_date IS NULL OR start_date <= CURRENT_DATE)
      AND (end_date   IS NULL OR end_date   >= CURRENT_DATE)
    ORDER BY country NULLS LAST, created_at DESC
    LIMIT 1;

    SELECT * INTO v_marketer
    FROM public.referral_marketers
    WHERE profile_id = v_profile.id;

    IF NOT FOUND THEN
        v_code := UPPER(COALESCE(v_profile.referral_code, private.generate_referral_code(v_profile.full_name)));
        INSERT INTO public.referral_marketers (
            profile_id, referral_code, status, default_campaign_id,
            joined_at, last_activity_at, metadata
        )
        VALUES (
            v_profile.id, v_code, 'active', v_campaign_id,
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '{}'::JSONB
        )
        RETURNING * INTO v_marketer;
    ELSE
        -- Auto-clean existing marketer record if it still has NIPANZE- or lowercase
        IF v_marketer.referral_code ILIKE 'NIPANZE-%' OR v_marketer.referral_code != UPPER(v_marketer.referral_code) THEN
            v_code := UPPER(REGEXP_REPLACE(v_marketer.referral_code, '^NIPANZE-', '', 'i'));
            UPDATE public.referral_marketers
            SET referral_code = v_code,
                default_campaign_id = COALESCE(default_campaign_id, v_campaign_id),
                last_activity_at    = CURRENT_TIMESTAMP,
                updated_at          = CURRENT_TIMESTAMP
            WHERE id = v_marketer.id
            RETURNING * INTO v_marketer;
        ELSE
            v_code := v_marketer.referral_code;
            UPDATE public.referral_marketers
            SET default_campaign_id = COALESCE(default_campaign_id, v_campaign_id),
                last_activity_at    = CURRENT_TIMESTAMP,
                updated_at          = CURRENT_TIMESTAMP
            WHERE id = v_marketer.id
            RETURNING * INTO v_marketer;
        END IF;
    END IF;

    UPDATE public.profiles
    SET referral_code        = COALESCE(referral_code, v_code),
        marketing_enabled    = TRUE,
        marketing_country    = COALESCE(marketing_country, v_country),
        marketing_joined_at  = COALESCE(marketing_joined_at, CURRENT_TIMESTAMP),
        updated_at           = CURRENT_TIMESTAMP
    WHERE id = v_profile.id
    RETURNING * INTO v_profile;

    RETURN jsonb_build_object(
        'marketer_id',       v_marketer.id,
        'user_id',           v_profile.id,
        'referral_code',     v_marketer.referral_code,
        'referral_link',     'https://nipanze.app/r/' || v_marketer.referral_code,
        'status',            v_marketer.status,
        'marketing_enabled', v_profile.marketing_enabled,
        'marketing_country', v_profile.marketing_country,
        'joined_at',         v_marketer.joined_at
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_my_referral_marketer(TEXT) TO authenticated;
