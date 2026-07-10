-- Upsert James Okello subscription to 'pro'
-- Usage: paste this into Supabase SQL Editor and Run

-- 1) Inspect current row
SELECT u.id AS user_id, u.email, s.*
FROM auth.users u
LEFT JOIN public.subscriptions s ON s.user_id = u.id
WHERE u.email = 'james.okello@outlook.com';

-- 2) Upsert to `pro` (safe transaction)
BEGIN;
UPDATE public.subscriptions
SET
  plan       = 'pro',
  status     = 'active',
  amount_ugx = 150000,
  started_at = NOW(),
  expires_at = NOW() + INTERVAL '1 year',
  auto_renew = TRUE,
  updated_at = NOW()
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'james.okello@outlook.com');

INSERT INTO public.subscriptions (
  user_id, plan, status, amount_ugx, started_at, expires_at, auto_renew, created_at, updated_at
)
SELECT id, 'pro', 'active', 150000, NOW(), NOW() + INTERVAL '1 year', TRUE, NOW(), NOW()
FROM auth.users
WHERE email = 'james.okello@outlook.com'
  AND NOT EXISTS (
    SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.users.id
  );
COMMIT;

-- 3) Verify
SELECT u.email, s.plan, s.status, s.amount_ugx, s.expires_at
FROM auth.users u
JOIN public.subscriptions s ON s.user_id = u.id
WHERE u.email = 'james.okello@outlook.com';
