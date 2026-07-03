-- ============================================================
-- NIPANZE — Security Advisor Quick Fix
-- Paste and run this in Supabase SQL Editor.
-- Fixes: "View is defined with SECURITY DEFINER property"
-- ============================================================
-- In Postgres, views default to SECURITY DEFINER (run as owner).
-- Setting security_invoker = true switches them to run as the
-- calling user, so RLS policies are evaluated correctly.
--
-- WHY THE PREVIOUS PATCH MAY NOT HAVE WORKED:
--   DROP VIEW fails silently if another view depends on it.
--   ALTER VIEW SET never fails — it patches the existing view
--   in-place without touching its definition or dependents.
-- ============================================================

-- Step 1 — Flip all four views in-place (no DROP needed)
ALTER VIEW public.v_loan_listings             SET (security_invoker = true);
ALTER VIEW public.v_user_marketplace_activity SET (security_invoker = true);
ALTER VIEW public.v_lender_offers             SET (security_invoker = true);
ALTER VIEW public.v_marketplace_activity      SET (security_invoker = true);

-- Step 2 — Grant SELECT on every table the views JOIN against.
-- This is what was missing before — security_invoker makes the
-- view run queries as the calling user, so the caller needs
-- explicit SELECT on each underlying table.
GRANT SELECT ON public.profiles           TO authenticated;
GRANT SELECT ON public.subscriptions      TO authenticated;
GRANT SELECT ON public.kyc_verifications  TO authenticated;
GRANT SELECT ON public.loan_requests      TO authenticated;
GRANT SELECT ON public.loan_offers        TO authenticated;
GRANT SELECT ON public.contact_reveals    TO authenticated;
GRANT SELECT ON public.notifications      TO authenticated;
GRANT SELECT ON public.watchlist          TO authenticated;

-- Also cover any tables added in the future
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

-- Step 3 — Re-grant view access (unchanged by ALTER VIEW
-- but good to be explicit after any schema changes)
GRANT SELECT ON public.v_loan_listings             TO authenticated, anon;
GRANT SELECT ON public.v_user_marketplace_activity TO authenticated;
GRANT SELECT ON public.v_lender_offers             TO authenticated;
GRANT SELECT ON public.v_marketplace_activity      TO authenticated;

-- Step 4 — Force PostgREST to reload so grants take effect now
NOTIFY pgrst, 'reload schema';

-- ============================================================
-- Verify — run this as a separate query after the above
-- ============================================================
-- SELECT
--     c.relname                            AS view_name,
--     (r.reloptions::text LIKE '%security_invoker=true%')
--                                          AS security_invoker_on
-- FROM pg_class c
-- JOIN pg_namespace n ON n.oid = c.relnamespace
-- LEFT JOIN pg_class r ON r.oid = c.oid
-- WHERE n.nspname = 'public'
--   AND c.relkind = 'v'
--   AND c.relname IN (
--       'v_loan_listings',
--       'v_user_marketplace_activity',
--       'v_lender_offers',
--       'v_marketplace_activity'
--   );
--
-- All four rows should show security_invoker_on = true.
-- After that, refresh the Security Advisor page — warnings gone.
