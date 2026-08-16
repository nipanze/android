-- Nipanze Referral & Marketer/Referral Agent System
-- Standalone additive patch. Run after schema.sql and patch_marketer_department.sql.
-- Keeps marketer rewards separate from P2P loan and forex funds.

ALTER TABLE public.referrals
    ADD COLUMN IF NOT EXISTS campaign_id UUID REFERENCES public.referral_campaigns(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS referral_code TEXT,
    ADD COLUMN IF NOT EXISTS source TEXT,
    ADD COLUMN IF NOT EXISTS country TEXT REFERENCES public.countries(code),
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'registered',
    ADD COLUMN IF NOT EXISTS registered_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS qualifying_event TEXT,
    ADD COLUMN IF NOT EXISTS qualified_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS reward_amount BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS reward_currency TEXT,
    ADD COLUMN IF NOT EXISTS reward_status TEXT NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS payout_status TEXT NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS fraud_status TEXT NOT NULL DEFAULT 'clear',
    ADD COLUMN IF NOT EXISTS fraud_reason TEXT,
    ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS referral_status TEXT NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS marketing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS marketing_country TEXT REFERENCES public.countries(code),
    ADD COLUMN IF NOT EXISTS marketing_joined_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS referred_at TIMESTAMP;

ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_status CHECK (status IN ('clicked', 'registered', 'verified', 'qualified', 'reward_pending', 'reward_earned', 'paid', 'rejected', 'fraud_flagged', 'fraud_hold', 'cancelled'));
ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_reward_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_reward_status CHECK (reward_status IN ('none', 'pending', 'earned', 'approved', 'rejected', 'paid', 'cancelled', 'fraud_hold'));
ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_payout_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_payout_status CHECK (payout_status IN ('none', 'requested', 'under_review', 'approved', 'processing', 'paid', 'failed', 'cancelled'));
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS chk_profiles_referral_status;
ALTER TABLE public.profiles
    ADD CONSTRAINT chk_profiles_referral_status CHECK (referral_status IN ('none', 'registered', 'verified', 'qualified', 'rejected', 'fraud_flagged', 'cancelled'));

CREATE INDEX IF NOT EXISTS idx_referrals_referred_user ON public.referrals(referred_user_id);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_referrals_referred_user_once
    ON public.referrals(referred_user_id)
    WHERE referred_user_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uidx_referral_rewards_once_per_campaign
    ON public.referral_rewards(referral_id, campaign_id)
    WHERE referral_id IS NOT NULL AND campaign_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_referral_code ON public.profiles(referral_code);
CREATE INDEX IF NOT EXISTS idx_profiles_referred_by ON public.profiles(referred_by);

DO $$
BEGIN
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_registered';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_verified';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_qualified';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_available';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_approved';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_paid';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_rejected';
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DROP POLICY IF EXISTS "referrals: own insert" ON public.referrals;
DROP POLICY IF EXISTS "referrals: own or admin read" ON public.referrals;
DROP POLICY IF EXISTS "referrals: own participant or admin read" ON public.referrals;
CREATE POLICY "referrals: own participant or admin read" ON public.referrals
    FOR SELECT TO authenticated
    USING (referrer_id = auth.uid() OR referred_user_id = auth.uid() OR private.is_admin());
DROP POLICY IF EXISTS "referrals: admin write" ON public.referrals;
CREATE POLICY "referrals: admin write" ON public.referrals
    FOR ALL TO authenticated USING (private.is_admin()) WITH CHECK (private.is_admin());

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
        v_code := 'NIPANZE-' || v_seed || SUBSTRING(REPLACE(uuid_generate_v4()::TEXT, '-', '') FROM 1 FOR 4);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.referral_marketers WHERE referral_code = v_code
        ) AND NOT EXISTS (
            SELECT 1 FROM public.profiles WHERE referral_code = v_code
        );
    END LOOP;

    RETURN v_code;
END;
$$;

CREATE OR REPLACE FUNCTION public.ensure_my_referral_marketer(p_country TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile public.profiles%ROWTYPE;
    v_marketer public.referral_marketers%ROWTYPE;
    v_campaign_id UUID;
    v_country TEXT;
    v_code TEXT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile not found';
    END IF;

    v_country := UPPER(COALESCE(NULLIF(p_country, ''), v_profile.country, 'UG'));
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE code = v_country) THEN
        v_country := v_profile.country;
    END IF;

    SELECT id INTO v_campaign_id
    FROM public.referral_campaigns
    WHERE status = 'active'
      AND (country IS NULL OR country = v_country)
      AND (start_date IS NULL OR start_date <= CURRENT_DATE)
      AND (end_date IS NULL OR end_date >= CURRENT_DATE)
    ORDER BY country NULLS LAST, created_at DESC
    LIMIT 1;

    SELECT * INTO v_marketer
    FROM public.referral_marketers
    WHERE profile_id = v_profile.id;

    IF NOT FOUND THEN
        v_code := COALESCE(v_profile.referral_code, private.generate_referral_code(v_profile.full_name));
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
        v_code := v_marketer.referral_code;
        UPDATE public.referral_marketers
        SET default_campaign_id = COALESCE(default_campaign_id, v_campaign_id),
            last_activity_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_marketer.id
        RETURNING * INTO v_marketer;
    END IF;

    UPDATE public.profiles
    SET referral_code = COALESCE(referral_code, v_code),
        marketing_enabled = TRUE,
        marketing_country = COALESCE(marketing_country, v_country),
        marketing_joined_at = COALESCE(marketing_joined_at, CURRENT_TIMESTAMP),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_profile.id
    RETURNING * INTO v_profile;

    RETURN jsonb_build_object(
        'marketer_id', v_marketer.id,
        'user_id', v_profile.id,
        'referral_code', v_marketer.referral_code,
        'referral_link', 'https://nipanze.app/r/' || v_marketer.referral_code,
        'status', v_marketer.status,
        'marketing_enabled', v_profile.marketing_enabled,
        'marketing_country', v_profile.marketing_country,
        'joined_at', v_marketer.joined_at
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_my_referral_marketer(TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.attribute_my_referral(
    p_referral_code TEXT,
    p_source TEXT DEFAULT 'registration'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code TEXT;
    v_source TEXT;
    v_user public.profiles%ROWTYPE;
    v_referrer_id UUID;
    v_marketer_id UUID;
    v_campaign_id UUID;
    v_referral_id UUID;
    v_referred_email TEXT;
BEGIN
    v_code := UPPER(TRIM(COALESCE(p_referral_code, '')));
    IF v_code = '' THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'missing_code');
    END IF;

    SELECT * INTO v_user FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile not found';
    END IF;

    IF v_user.referred_by IS NOT NULL THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'already_attributed');
    END IF;

    SELECT rm.profile_id, rm.id, rm.default_campaign_id
    INTO v_referrer_id, v_marketer_id, v_campaign_id
    FROM public.referral_marketers rm
    WHERE UPPER(rm.referral_code) = v_code
      AND rm.status IN ('new', 'active')
    LIMIT 1;

    IF v_referrer_id IS NULL THEN
        SELECT p.id INTO v_referrer_id
        FROM public.profiles p
        WHERE UPPER(p.referral_code) = v_code
        LIMIT 1;

        IF v_referrer_id IS NOT NULL THEN
            SELECT rm.id, rm.default_campaign_id
            INTO v_marketer_id, v_campaign_id
            FROM public.referral_marketers rm
            WHERE rm.profile_id = v_referrer_id
            LIMIT 1;

            IF v_marketer_id IS NULL THEN
                INSERT INTO public.referral_marketers (
                    profile_id, referral_code, status, joined_at, last_activity_at
                )
                VALUES (v_referrer_id, v_code, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                RETURNING id, default_campaign_id INTO v_marketer_id, v_campaign_id;
            END IF;
        END IF;
    END IF;

    IF v_referrer_id IS NULL THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'code_not_found');
    END IF;

    IF v_referrer_id = v_user.id THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'self_referral');
    END IF;

    IF EXISTS (SELECT 1 FROM public.referrals WHERE referred_user_id = v_user.id) THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'already_recorded');
    END IF;

    IF v_campaign_id IS NULL THEN
        SELECT id INTO v_campaign_id
        FROM public.referral_campaigns
        WHERE status = 'active'
          AND (country IS NULL OR country = v_user.country)
          AND (start_date IS NULL OR start_date <= CURRENT_DATE)
          AND (end_date IS NULL OR end_date >= CURRENT_DATE)
        ORDER BY country NULLS LAST, created_at DESC
        LIMIT 1;
    END IF;

    SELECT email INTO v_referred_email FROM auth.users WHERE id = v_user.id;
    v_source := COALESCE(NULLIF(TRIM(p_source), ''), 'registration');

    INSERT INTO public.referrals (
        referrer_id, referred_email, referred_user_id, code, referral_code,
        campaign_id, source, country, status, registered_at, metadata
    )
    VALUES (
        v_referrer_id,
        COALESCE(v_referred_email, v_user.phone, v_user.id::TEXT),
        v_user.id,
        'ATTR-' || SUBSTRING(REPLACE(uuid_generate_v4()::TEXT, '-', '') FROM 1 FOR 12),
        v_code,
        v_campaign_id,
        v_source,
        v_user.country,
        'registered',
        CURRENT_TIMESTAMP,
        jsonb_build_object('attributed_by', 'attribute_my_referral')
    )
    RETURNING id INTO v_referral_id;

    UPDATE public.profiles
    SET referred_by = v_referrer_id,
        referral_status = 'registered',
        referred_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user.id
      AND referred_by IS NULL;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        v_referrer_id,
        'system',
        'New referral registered',
        COALESCE(NULLIF(v_user.full_name, ''), 'Someone') || ' joined Nipanze using your referral code.',
        jsonb_build_object('notification_kind', 'referral_registered', 'referral_id', v_referral_id, 'referred_user_id', v_user.id)
    );

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (
        v_user.id,
        'register',
        'referrals',
        v_referral_id,
        'referral_attributed',
        jsonb_build_object('referrer_id', v_referrer_id, 'referral_code', v_code, 'source', v_source)
    );

    RETURN jsonb_build_object('attributed', TRUE, 'referral_id', v_referral_id);
EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'already_recorded');
END;
$$;

GRANT EXECUTE ON FUNCTION public.attribute_my_referral(TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.qualify_referral_for_event(
    p_referred_user_id UUID,
    p_event TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_referral public.referrals%ROWTYPE;
    v_campaign public.referral_campaigns%ROWTYPE;
    v_marketer_id UUID;
    v_reward_id UUID;
BEGIN
    SELECT * INTO v_referral
    FROM public.referrals
    WHERE referred_user_id = p_referred_user_id
      AND status NOT IN ('rejected', 'fraud_flagged', 'fraud_hold', 'cancelled', 'paid')
    ORDER BY created_at ASC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('qualified', FALSE, 'reason', 'no_referral');
    END IF;

    SELECT * INTO v_campaign
    FROM public.referral_campaigns
    WHERE id = v_referral.campaign_id
      AND status = 'active'
      AND qualification_event = p_event
      AND (country IS NULL OR country = v_referral.country)
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('qualified', FALSE, 'reason', 'no_matching_campaign');
    END IF;

    SELECT id INTO v_marketer_id
    FROM public.referral_marketers
    WHERE profile_id = v_referral.referrer_id
    LIMIT 1;

    IF v_marketer_id IS NULL THEN
        RETURN jsonb_build_object('qualified', FALSE, 'reason', 'marketer_missing');
    END IF;

    UPDATE public.referrals
    SET status = 'qualified',
        qualifying_event = p_event,
        qualified_at = COALESCE(qualified_at, CURRENT_TIMESTAMP),
        reward_amount = v_campaign.reward_amount,
        reward_currency = v_campaign.reward_currency,
        reward_status = CASE WHEN v_campaign.reward_amount > 0 THEN 'pending' ELSE 'none' END,
        payout_status = 'none',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_referral.id
    RETURNING * INTO v_referral;

    UPDATE public.profiles
    SET referral_status = 'qualified',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_referred_user_id;

    IF v_campaign.reward_amount > 0 THEN
        INSERT INTO public.referral_rewards (
            marketer_id, referral_id, campaign_id, referred_user_id,
            reward_type, amount, currency, status, reason, campaign_reward_snapshot
        )
        VALUES (
            v_marketer_id,
            v_referral.id,
            v_campaign.id,
            p_referred_user_id,
            v_campaign.reward_type,
            v_campaign.reward_amount,
            v_campaign.reward_currency,
            'pending',
            'Qualified by event: ' || p_event,
            jsonb_build_object(
                'campaign_id', v_campaign.id,
                'campaign', v_campaign.name,
                'reward_type', v_campaign.reward_type,
                'amount', v_campaign.reward_amount,
                'currency', v_campaign.reward_currency,
                'qualification_event', v_campaign.qualification_event
            )
        )
        ON CONFLICT DO NOTHING
        RETURNING id INTO v_reward_id;
    END IF;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        v_referral.referrer_id,
        'system',
        'Referral qualified',
        'One of your referrals qualified for a Nipanze marketing reward.',
        jsonb_build_object('notification_kind', 'referral_qualified', 'referral_id', v_referral.id, 'reward_id', v_reward_id)
    );

    RETURN jsonb_build_object('qualified', TRUE, 'referral_id', v_referral.id, 'reward_id', v_reward_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.qualify_referral_for_event(UUID, TEXT) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.get_my_referral_dashboard()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_marketer JSONB;
    v_profile_id UUID;
    v_summary JSONB;
    v_history JSONB;
BEGIN
    v_marketer := public.ensure_my_referral_marketer(NULL);
    v_profile_id := auth.uid();

    SELECT jsonb_build_object(
        'total_referrals', COUNT(*)::INT,
        'registered', COUNT(*) FILTER (WHERE r.status = 'registered')::INT,
        'verified', COUNT(*) FILTER (WHERE r.status = 'verified')::INT,
        'qualified', COUNT(*) FILTER (WHERE r.status IN ('qualified', 'reward_pending', 'reward_earned', 'paid'))::INT,
        'pending_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'pending'), 0),
        'available_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'approved'), 0),
        'paid_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'total_earned', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status IN ('pending', 'approved', 'paid')), 0),
        'total_paid', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'currency', COALESCE(MAX(rr.currency), MAX(r.reward_currency), 'UGX')
    )
    INTO v_summary
    FROM public.referrals r
    LEFT JOIN public.referral_rewards rr ON rr.referral_id = r.id
    WHERE r.referrer_id = v_profile_id;

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', r.id,
            'display_name', COALESCE(NULLIF(SPLIT_PART(TRIM(p.full_name), ' ', 1), ''), 'Nipanze user'),
            'registered_at', COALESCE(r.registered_at, r.created_at),
            'status', r.status,
            'qualification_status', CASE WHEN r.qualified_at IS NULL THEN 'pending' ELSE 'qualified' END,
            'reward_amount', COALESCE(rr.amount, r.reward_amount, 0),
            'reward_currency', COALESCE(rr.currency, r.reward_currency, c.reward_currency, 'UGX'),
            'reward_status', COALESCE(rr.status, r.reward_status, 'none'),
            'payout_status', r.payout_status,
            'source', r.source
        )
        ORDER BY COALESCE(r.registered_at, r.created_at) DESC
    ), '[]'::JSONB)
    INTO v_history
    FROM public.referrals r
    LEFT JOIN public.profiles p ON p.id = r.referred_user_id
    LEFT JOIN public.referral_campaigns c ON c.id = r.campaign_id
    LEFT JOIN public.referral_rewards rr ON rr.referral_id = r.id
    WHERE r.referrer_id = v_profile_id;

    RETURN jsonb_build_object(
        'marketer', v_marketer,
        'summary', COALESCE(v_summary, '{}'::JSONB),
        'history', COALESCE(v_history, '[]'::JSONB)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_referral_dashboard() TO authenticated;

CREATE OR REPLACE FUNCTION public.trg_referral_kyc_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'approved' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM NEW.status) THEN
        PERFORM public.qualify_referral_for_event(NEW.user_id, 'kyc_approved');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_referral_kyc_event ON public.kyc_verifications;
CREATE TRIGGER trg_referral_kyc_event
    AFTER INSERT OR UPDATE OF status ON public.kyc_verifications
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_referral_kyc_event();

CREATE OR REPLACE FUNCTION public.trg_referral_subscription_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'active' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM NEW.status OR OLD.plan IS DISTINCT FROM NEW.plan) THEN
        PERFORM public.qualify_referral_for_event(NEW.user_id, 'first_paid_subscription');
        IF NEW.plan IN ('lender', 'pro') THEN
            PERFORM public.qualify_referral_for_event(NEW.user_id, 'first_lender_or_pro_subscription');
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_referral_subscription_event ON public.subscriptions;
CREATE TRIGGER trg_referral_subscription_event
    AFTER INSERT OR UPDATE OF status, plan ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_referral_subscription_event();
