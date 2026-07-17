-- ============================================================
-- PATCH: free_contact_unlock_credits
-- Adds welcome-gift unlock credit system to Nipanze.
--
-- Rules:
--   • Free plan users get 1 free unlock on registration (default=1).
--   • Lender / Pro subscribers skip this column entirely (checked at app layer).
--   • consume_free_unlock() decrements the count atomically and returns the
--     new remaining value. Raises if the caller has no credits left.
--
-- Apply once against the live Supabase cloud database.
-- Idempotent: uses IF NOT EXISTS / OR REPLACE.
-- ============================================================

-- 1. Add column (idempotent)
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS free_unlocks_remaining INT NOT NULL DEFAULT 1;

COMMENT ON COLUMN public.profiles.free_unlocks_remaining IS
'Welcome-gift contact-unlock credits. Free plan users start with 1. '
'Lender/Pro subscribers bypass this limit entirely (checked at app layer). '
'Decremented atomically by consume_free_unlock().';


-- 2. Back-fill existing users that have never unlocked anything yet.
--    Give them 1 credit if they don't already have a contact reveal.
UPDATE public.profiles p
SET    free_unlocks_remaining = 1
WHERE  free_unlocks_remaining = 1   -- already default, but explicit
  AND  NOT EXISTS (
          SELECT 1
          FROM   public.contact_reveals cr
          JOIN   public.loan_offers lo ON lo.id = cr.offer_id
          WHERE  lo.lender_id = p.id
             OR  EXISTS (
                   SELECT 1 FROM public.loan_requests lr
                   WHERE lr.id = cr.request_id AND lr.borrower_id = p.id
                 )
       );


-- 3. RPC: consume_free_unlock()
--    Decrements free_unlocks_remaining by 1 for the calling user.
--    Returns the new remaining count.
--    Raises 'NIPANZE_NO_FREE_UNLOCKS' if the count is already 0.
CREATE OR REPLACE FUNCTION public.consume_free_unlock()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id   UUID := auth.uid();
    v_remaining INT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED';
    END IF;

    -- Lock the row and read current value
    SELECT free_unlocks_remaining
      INTO v_remaining
      FROM profiles
     WHERE id = v_user_id
       FOR UPDATE;

    IF v_remaining IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_PROFILE_NOT_FOUND';
    END IF;

    IF v_remaining <= 0 THEN
        RAISE EXCEPTION 'NIPANZE_NO_FREE_UNLOCKS';
    END IF;

    UPDATE profiles
       SET free_unlocks_remaining = free_unlocks_remaining - 1,
           updated_at             = NOW()
     WHERE id = v_user_id
    RETURNING free_unlocks_remaining INTO v_remaining;

    RETURN v_remaining;
END;
$$;

COMMENT ON FUNCTION public.consume_free_unlock() IS
'Atomically decrements free_unlocks_remaining for the calling authenticated user. '
'Returns new remaining count. Raises NIPANZE_NO_FREE_UNLOCKS if count is already 0.';


-- 4. Grant execute to authenticated users only
GRANT EXECUTE ON FUNCTION public.consume_free_unlock() TO authenticated;

-- ============================================================
-- END OF PATCH
-- ============================================================
