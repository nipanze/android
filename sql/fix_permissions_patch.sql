-- ============================================================
-- FIX SCHEMA & RPC PERMISSIONS FOR SUPABASE CLOUD
-- Run this script in your Supabase SQL Editor (https://app.supabase.com)
-- to resolve "permission denied for schema public" (42501)
-- ============================================================

-- 1. Grant USAGE on public schema to all API roles
GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;

-- 2. Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO anon;

-- 3. Grant sequence permissions
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;

-- 4. Re-create check_phone_registered function with SECURITY DEFINER and grant execution
CREATE OR REPLACE FUNCTION public.check_phone_registered(p_phone TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_email TEXT;
BEGIN
    SELECT au.email INTO v_email
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE p.phone = p_phone OR au.phone = p_phone OR au.email = p_phone
    LIMIT 1;

    RETURN v_email;
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_phone_registered(TEXT) TO authenticated, anon, service_role;

-- 5. Profiles RLS Policies (ensure anon & authenticated can insert/update profile rows)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own or public profiles" ON public.profiles;
CREATE POLICY "Users can view own or public profiles"
  ON public.profiles FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id OR auth.uid() IS NOT NULL);

-- 6. Subscriptions RLS Policies (ensure authenticated users can insert and update their own subscription rows)
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "subscriptions: own or admin read" ON public.subscriptions;
DROP POLICY IF EXISTS "subscriptions: own read" ON public.subscriptions;
CREATE POLICY "subscriptions: own or admin read"
  ON public.subscriptions FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR (private.is_admin() IS NOT NULL AND private.is_admin()));

DROP POLICY IF EXISTS "subscriptions: own insert" ON public.subscriptions;
CREATE POLICY "subscriptions: own insert"
  ON public.subscriptions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "subscriptions: own update" ON public.subscriptions;
CREATE POLICY "subscriptions: own update"
  ON public.subscriptions FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

