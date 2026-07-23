-- Upsert patch for test users (can be run multiple times)
-- Password for all accounts: Test1234!

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
    -- Uganda user
    ('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000000', 'uganda.user@nipanze.ug', crypt('Test1234!', gen_salt('bf')),
     NOW(), NOW(), NOW(),
     '{"provider":"email","providers":["email"]}', '{"full_name":"Uganda Test User"}',
     FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
    -- Kenya user (original)
    ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000000', 'kenya.user@nipanze.ug', crypt('Test1234!', gen_salt('bf')),
     NOW(), NOW(), NOW(),
     '{"provider":"email","providers":["email"]}', '{"full_name":"Kenya Test User"}',
     FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
    -- Kenyan user (example.com)
    ('10000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000000', 'kenyan.user@example.com', crypt('Test1234!', gen_salt('bf')),
     NOW(), NOW(), NOW(),
     '{"provider":"email","providers":["email"]}', '{"full_name":"Kenyan Test User"}',
     FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
    -- Tanzania user
    ('10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000000', 'tanzania.user@nipanze.ug', crypt('Test1234!', gen_salt('bf')),
     NOW(), NOW(), NOW(),
     '{"provider":"email","providers":["email"]}', '{"full_name":"Tanzania Test User"}',
     FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
    -- Rwanda user
    ('10000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000000', 'rwanda.user@nipanze.ug', crypt('Test1234!', gen_salt('bf')),
     NOW(), NOW(), NOW(),
     '{"provider":"email","providers":["email"]}', '{"full_name":"Rwanda Test User"}',
     FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
    -- South Sudan user
    ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000000', 'southsudan.user@nipanze.ug', crypt('Test1234!', gen_salt('bf')),
     NOW(), NOW(), NOW(),
     '{"provider":"email","providers":["email"]}', '{"full_name":"South Sudan Test User"}',
     FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
    -- Burundi user
    ('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000000', 'burundi.user@nipanze.ug', crypt('Test1234!', gen_salt('bf')),
     NOW(), NOW(), NOW(),
     '{"provider":"email","providers":["email"]}', '{"full_name":"Burundi Test User"}',
     FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    updated_at = NOW();

-- Upsert profiles for the same users
INSERT INTO public.profiles (id, full_name, account_status, is_admin)
SELECT au.id,
       COALESCE(au.raw_user_meta_data->>'full_name', SPLIT_PART(au.email, '@', 1)),
       'active', FALSE
FROM auth.users au
WHERE au.id IN (
    '10000000-0000-0000-0000-000000000019',
    '10000000-0000-0000-0000-000000000020',
    '10000000-0000-0000-0000-000000000021',
    '10000000-0000-0000-0000-000000000022',
    '10000000-0000-0000-0000-000000000023',
    '10000000-0000-0000-0000-000000000024',
    '10000000-0000-0000-0000-000000000025'
) ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    account_status = EXCLUDED.account_status,
    is_admin = EXCLUDED.is_admin;

-- Upsert subscriptions for the same users
INSERT INTO public.subscriptions (user_id, plan, status, amount_ugx)
SELECT au.id, 'free', 'active', 0
FROM auth.users au
WHERE au.id IN (
    '10000000-0000-0000-0000-000000000019',
    '10000000-0000-0000-0000-000000000020',
    '10000000-0000-0000-0000-000000000021',
    '10000000-0000-0000-0000-000000000022',
    '10000000-0000-0000-0000-000000000023',
    '10000000-0000-0000-0000-000000000024',
    '10000000-0000-0000-0000-000000000025'
) ON CONFLICT (user_id) DO UPDATE SET
    plan = EXCLUDED.plan,
    status = EXCLUDED.status,
    amount_ugx = EXCLUDED.amount_ugx;

-- Ensure posts table exists
CREATE TABLE IF NOT EXISTS public.posts (
    id SERIAL PRIMARY KEY,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_published BOOLEAN DEFAULT FALSE
);

-- Upsert sample posts (one per user)
INSERT INTO public.posts (author_id, title, content, is_published)
VALUES
    ('10000000-0000-0000-0000-000000000019', 'Welcome to Nipanze Uganda', 'This is a test post for Uganda user.', TRUE),
    ('10000000-0000-0000-0000-000000000020', 'Welcome to Nipanze Kenya', 'This is a test post for Kenya user.', TRUE),
    ('10000000-0000-0000-0000-000000000025', 'Welcome to Nipanze Kenya (example.com)', 'This is a test post for Kenyan example.com user.', TRUE),
    ('10000000-0000-0000-0000-000000000021', 'Welcome to Nipanze Tanzania', 'This is a test post for Tanzania user.', TRUE),
    ('10000000-0000-0000-0000-000000000022', 'Welcome to Nipanze Rwanda', 'This is a test post for Rwanda user.', TRUE),
    ('10000000-0000-0000-0000-000000000023', 'Welcome to Nipanze South Sudan', 'This is a test post for South Sudan user.', TRUE),
    ('10000000-0000-0000-0000-000000000024', 'Welcome to Nipanze Burundi', 'This is a test post for Burundi user.', TRUE)
ON CONFLICT (author_id) DO UPDATE SET
    title = EXCLUDED.title,
    content = EXCLUDED.content,
    is_published = EXCLUDED.is_published,
    updated_at = NOW();
