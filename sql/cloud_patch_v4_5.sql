-- ====================================================================
-- NIPANZE CLOUD DB PATCH (v4.5)
-- Add marketplace filter preference columns to profiles so Edit Profile
-- can mirror Advanced Filters settings:
--
--   preferred_employment_types  = text[] — employment categories the
--                                  user wants to default to in filters
--   preferred_income_bracket    = text    — bucketed income range
--   prefers_suggested_terms     = boolean — default to Pro-posted listings
--   prefers_verified_only       = boolean — default to KYC-approved owners
-- ====================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS preferred_employment_types text[],
  ADD COLUMN IF NOT EXISTS preferred_income_bracket text,
  ADD COLUMN IF NOT EXISTS prefers_suggested_terms boolean NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS prefers_verified_only boolean NOT NULL DEFAULT FALSE;

SELECT '✅ Cloud Patch v4.5 applied successfully' AS result;
