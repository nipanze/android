-- 01_multi_currency_migration.sql
-- Run this in Supabase SQL editor to migrate the schema to support multiple currencies

-- Disable triggers temporarily during migration
SET session_replication_role = 'replica';

-- 1. Profiles: Rename monthly_income_ugx and add income_currency
ALTER TABLE public.profiles RENAME COLUMN monthly_income_ugx TO monthly_income;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS income_currency VARCHAR(3) NOT NULL DEFAULT 'UGX';

-- 2. Subscriptions: Rename amount_ugx and add currency
ALTER TABLE public.subscriptions RENAME COLUMN amount_ugx TO amount;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT 'UGX';

-- 3. Loan Requests: Add currency
ALTER TABLE public.loan_requests ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT 'UGX';

-- 4. Loan Offers: Add currency
ALTER TABLE public.loan_offers ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT 'UGX';

-- 5. Dynamic Country Settings Configuration Table (optional, for scalable limits)
CREATE TABLE IF NOT EXISTS public.country_settings (
    country_code VARCHAR(2) PRIMARY KEY,
    currency VARCHAR(3) NOT NULL,
    min_loan_amount BIGINT NOT NULL,
    max_loan_amount BIGINT NOT NULL,
    lender_price BIGINT NOT NULL,
    pro_price BIGINT NOT NULL
);

INSERT INTO public.country_settings (country_code, currency, min_loan_amount, max_loan_amount, lender_price, pro_price) VALUES
    ('UG', 'UGX', 100000, 50000000, 19900, 49900),
    ('KE', 'KES', 3000, 1500000, 690, 1790),
    ('TZ', 'TZS', 60000, 30000000, 12900, 32900),
    ('RW', 'RWF', 30000, 15000000, 6900, 17900),
    ('SS', 'SSP', 35000, 17500000, 7900, 19900),
    ('BI', 'BIF', 75000, 37500000, 15900, 39900)
ON CONFLICT (country_code) DO UPDATE SET
    currency = EXCLUDED.currency,
    min_loan_amount = EXCLUDED.min_loan_amount,
    max_loan_amount = EXCLUDED.max_loan_amount,
    lender_price = EXCLUDED.lender_price,
    pro_price = EXCLUDED.pro_price;

-- 6. Update handle_new_auth_user to use renamed column
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_currency VARCHAR(3) := 'UGX';
BEGIN
    INSERT INTO public.profiles (
        id, full_name, account_status, is_admin
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        'pending_verification',
        FALSE
    )
    ON CONFLICT (id) DO NOTHING;

    -- Every new user gets a free subscription (can browse marketplace and post requests)
    INSERT INTO public.subscriptions (user_id, plan, status, amount, currency)
    VALUES (NEW.id, 'free', 'active', 0, v_currency)
    ON CONFLICT DO NOTHING;

    RETURN NEW;
END;
$$;

-- Re-enable triggers
SET session_replication_role = 'origin';
