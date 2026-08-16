-- ==============================================================================
-- NIPANZE REFERRALS: CLIENT-FACING AVAILABLE REWARD STATUS
-- ==============================================================================
-- Paste this once after the referral/marketer tables and RPCs already exist.
-- Keeps existing "approved" reward rows working while exposing "available" to
-- normal users as the claimable reward state: pending -> available -> paid.
-- ==============================================================================

ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_reward_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_reward_status
    CHECK (reward_status IN (
        'none',
        'pending',
        'earned',
        'available',
        'approved',
        'rejected',
        'paid',
        'cancelled',
        'fraud_hold'
    ));

ALTER TABLE public.referral_rewards DROP CONSTRAINT IF EXISTS chk_referral_reward_status;
ALTER TABLE public.referral_rewards
    ADD CONSTRAINT chk_referral_reward_status
    CHECK (status IN (
        'pending',
        'available',
        'approved',
        'rejected',
        'paid',
        'cancelled',
        'fraud_hold'
    ));

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
    v_default_currency TEXT;
BEGIN
    v_marketer := public.ensure_my_referral_marketer(NULL);
    v_profile_id := auth.uid();

    SELECT COALESCE(c.currency_code, 'UGX') INTO v_default_currency
    FROM public.profiles p
    LEFT JOIN public.countries c ON c.code = COALESCE(p.country, p.marketing_country, 'UG')
    WHERE p.id = v_profile_id;
    v_default_currency := COALESCE(v_default_currency, 'UGX');

    SELECT jsonb_build_object(
        'total_referrals', COUNT(*)::INT,
        'registered', COUNT(*) FILTER (WHERE r.status = 'registered')::INT,
        'verified', COUNT(*) FILTER (WHERE r.status = 'verified')::INT,
        'qualified', COUNT(*) FILTER (WHERE r.status IN ('qualified', 'reward_pending', 'reward_earned', 'paid'))::INT,
        'pending_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'pending'), 0),
        'available_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status IN ('available', 'approved')), 0),
        'paid_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'total_earned', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status IN ('pending', 'available', 'approved', 'paid')), 0),
        'total_paid', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'currency', COALESCE(MAX(rr.currency), MAX(r.reward_currency), v_default_currency)
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
            'reward_status', CASE
                WHEN COALESCE(rr.status, r.reward_status, 'none') = 'approved' THEN 'available'
                ELSE COALESCE(rr.status, r.reward_status, 'none')
            END,
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
        'marketer', COALESCE(v_marketer, '{}'::JSONB),
        'summary', COALESCE(v_summary, '{}'::JSONB),
        'history', COALESCE(v_history, '[]'::JSONB)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_referral_dashboard() TO authenticated;
