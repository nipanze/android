-- ====================================================================
-- NIPANZE CLOUD DB PATCH (v4.2)
-- Run this in the Supabase Cloud SQL Editor to fix:
-- 1. Missing get_my_subscription_plan() function & credentials
-- 2. Expired subscription lifetimes for seeded users (pro/lender)
-- ====================================================================

-- ── 1. CREATE HELPER FUNCTION ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_subscription_plan()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_plan TEXT;
BEGIN
    SELECT plan::TEXT INTO v_plan
    FROM public.subscriptions
    WHERE user_id = auth.uid()
      AND status = 'active'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_plan IS NULL THEN
        RETURN 'free';
    END IF;
    RETURN v_plan;
END;
$$;

-- ── 2. GRANT FUNCTION PERMISSIONS ───────────────────────────────────
REVOKE EXECUTE ON FUNCTION public.get_my_subscription_plan() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.get_my_subscription_plan() TO authenticated, service_role;

-- ── 3. UPDATE SUBSCRIPTION LIFETIMES TO 2028 (ACTIVE STATUS) ────────
UPDATE public.subscriptions 
SET expires_at = '2028-01-20 15:00:00' 
WHERE user_id = '10000000-0000-0000-0000-000000000003'; -- James Okello (Pro)

UPDATE public.subscriptions 
SET expires_at = '2028-03-01 11:00:00' 
WHERE user_id = '10000000-0000-0000-0000-000000000008'; -- Pearl Capital (Pro)

UPDATE public.subscriptions 
SET expires_at = '2028-02-18 10:00:00' 
WHERE user_id = '10000000-0000-0000-0000-000000000006'; -- Lender 6 (Lender)

UPDATE public.subscriptions 
SET expires_at = '2028-02-20 12:00:00' 
WHERE user_id = '10000000-0000-0000-0000-000000000007'; -- Lender 7 (Lender)

UPDATE public.subscriptions 
SET expires_at = '2028-03-05 10:00:00' 
WHERE user_id = '10000000-0000-0000-0000-000000000010'; -- Lender 10 (Lender)

UPDATE public.subscriptions 
SET expires_at = '2028-01-25 12:00:00' 
WHERE user_id = '10000000-0000-0000-0000-000000000005'; -- Robert Ssemwanga (Lender)

-- ── 4. CONFIRM SUCCESS ───────────────────────────────────────────────
SELECT 'Cloud Patch v4.2 applied successfully ✓' AS result;
