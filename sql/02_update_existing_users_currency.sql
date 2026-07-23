-- 02_update_existing_users_currency.sql
-- Updates existing test users to have their correct local currency

SET session_replication_role = 'replica';

-- Kenya users
UPDATE public.profiles SET income_currency = 'KES' WHERE id IN ('10000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000025');
UPDATE public.subscriptions SET currency = 'KES' WHERE user_id IN ('10000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000025');
UPDATE public.loan_requests SET currency = 'KES' WHERE borrower_id IN ('10000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000025');

-- Tanzania user
UPDATE public.profiles SET income_currency = 'TZS' WHERE id = '10000000-0000-0000-0000-000000000021';
UPDATE public.subscriptions SET currency = 'TZS' WHERE user_id = '10000000-0000-0000-0000-000000000021';
UPDATE public.loan_requests SET currency = 'TZS' WHERE borrower_id = '10000000-0000-0000-0000-000000000021';

-- Rwanda user
UPDATE public.profiles SET income_currency = 'RWF' WHERE id = '10000000-0000-0000-0000-000000000022';
UPDATE public.subscriptions SET currency = 'RWF' WHERE user_id = '10000000-0000-0000-0000-000000000022';
UPDATE public.loan_requests SET currency = 'RWF' WHERE borrower_id = '10000000-0000-0000-0000-000000000022';

-- South Sudan user
UPDATE public.profiles SET income_currency = 'SSP' WHERE id = '10000000-0000-0000-0000-000000000023';
UPDATE public.subscriptions SET currency = 'SSP' WHERE user_id = '10000000-0000-0000-0000-000000000023';
UPDATE public.loan_requests SET currency = 'SSP' WHERE borrower_id = '10000000-0000-0000-0000-000000000023';

-- Burundi user
UPDATE public.profiles SET income_currency = 'BIF' WHERE id = '10000000-0000-0000-0000-000000000024';
UPDATE public.subscriptions SET currency = 'BIF' WHERE user_id = '10000000-0000-0000-0000-000000000024';
UPDATE public.loan_requests SET currency = 'BIF' WHERE borrower_id = '10000000-0000-0000-0000-000000000024';

SET session_replication_role = 'origin';
