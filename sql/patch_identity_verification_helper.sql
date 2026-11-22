-- Compatibility fix for projects where KYC is stored only in
-- public.kyc_verifications and profiles has no kyc_status column.
-- This preserves strict identity verification: only approved, unexpired KYC
-- rows satisfy the check. It does not approve users or bypass KYC.

CREATE OR REPLACE FUNCTION private.is_identity_verified(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT COALESCE(
    EXISTS (
      SELECT 1
      FROM public.kyc_verifications kv
      WHERE kv.user_id = p_user_id
        AND kv.status = 'approved'
        AND (kv.expires_at IS NULL OR kv.expires_at > now())
    ),
    false
  );
$$;

COMMENT ON FUNCTION private.is_identity_verified(uuid) IS
  'Returns true only for users with approved, unexpired KYC in public.kyc_verifications.';
