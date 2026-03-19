-- ============================================
-- OpenCapital Seed Data
-- Version: 2.1 (Production-Ready)
-- ============================================
--
-- HOW THIS WORKS:
--   1. INSERT into auth.users with FIXED UUIDs
--      - Password hashed via pgcrypto crypt() — $2a$ format GoTrue accepts
--      - All token columns set to '' (empty string) not NULL — GoTrue requires this
--      - email_confirmed_at set so signInWithPassword works immediately
--      → handle_new_auth_user trigger fires → creates public.users row
--      → trg_auto_create_wallet fires → creates wallet_balances row
--
--   2. UPDATE public.users to set role, status, phone etc.
--
--   3. INSERT user_profiles, kyc_verifications, risk_assessments
--
--   4. INSERT loan_requests, wallet deposits, bids, bid acceptance
--
-- Password for ALL accounts: Test1234!
--
-- FIXED UUIDs (stable across every db reset):
--   david.mukasa         → 10000000-0000-0000-0000-000000000001
--   sarah.namukasa       → 10000000-0000-0000-0000-000000000002
--   james.okello         → 10000000-0000-0000-0000-000000000003
--   maria.nakato         → 10000000-0000-0000-0000-000000000004
--   robert.ssemwanga     → 10000000-0000-0000-0000-000000000005
--   info@greenleafagro   → 10000000-0000-0000-0000-000000000006
--   contact@kampalatech  → 10000000-0000-0000-0000-000000000007
--   invest@pearlcapital  → 10000000-0000-0000-0000-000000000008
--   funds@victoriainvest → 10000000-0000-0000-0000-000000000009
--   lending@equator      → 10000000-0000-0000-0000-000000000010
--   frank.omondi         → 10000000-0000-0000-0000-000000000011
--   lucy.nambi           → 10000000-0000-0000-0000-000000000012
--   charles.mwesigwa     → 10000000-0000-0000-0000-000000000013
--   alice.namuli         → 10000000-0000-0000-0000-000000000014
--   admin1               → 10000000-0000-0000-0000-000000000015
--   admin2               → 10000000-0000-0000-0000-000000000016
--   admin3               → 10000000-0000-0000-0000-000000000017
--   test.user            → 10000000-0000-0000-0000-000000000018
-- ============================================


-- ============================================
-- STEP 1: AUTH USERS
-- ============================================
-- KEY FIXES vs previous version:
--   1. encrypted_password uses crypt('Test1234!', gen_salt('bf'))
--      which produces a $2a$ hash GoTrue accepts.
--      The old $2b$ hash (Node.js bcrypt) caused "Invalid login credentials".
--
--   2. All token columns (confirmation_token, recovery_token, etc.)
--      set to '' (empty string). GoTrue does a Go string scan on these
--      columns and panics on NULL → "Database error querying schema".
-- ============================================

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    -- All token columns must be '' not NULL
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
(
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'david.mukasa@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-15 08:30:00', '2024-01-15 08:30:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'sarah.namukasa@yahoo.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-18 10:45:00', '2024-01-18 10:45:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000',
    'james.okello@outlook.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-20 14:20:00', '2024-01-20 14:20:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000000',
    'maria.nakato@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-22 09:10:00', '2024-01-22 09:10:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000000',
    'robert.ssemwanga@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-25 11:30:00', '2024-01-25 11:30:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000000',
    'info@greenleafagro.co.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-02-18 09:20:00', '2024-02-18 09:20:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000007',
    '00000000-0000-0000-0000-000000000000',
    'contact@kampalatech.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-02-20 11:40:00', '2024-02-20 11:40:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000008',
    '00000000-0000-0000-0000-000000000000',
    'invest@pearlcapital.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-01 10:10:00', '2024-03-01 10:10:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000009',
    '00000000-0000-0000-0000-000000000000',
    'funds@victoriainvest.co.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-03 12:30:00', '2024-03-03 12:30:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000010',
    '00000000-0000-0000-0000-000000000000',
    'lending@equatorfinance.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-05 09:45:00', '2024-03-05 09:45:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000011',
    '00000000-0000-0000-0000-000000000000',
    'frank.omondi@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-08 14:15:00', '2024-03-08 14:15:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000012',
    '00000000-0000-0000-0000-000000000000',
    'lucy.nambi@yahoo.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-10 11:20:00', '2024-03-10 11:20:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000013',
    '00000000-0000-0000-0000-000000000000',
    'charles.mwesigwa@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-12 16:40:00', '2024-03-12 16:40:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000014',
    '00000000-0000-0000-0000-000000000000',
    'alice.namuli@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2026-01-25 09:15:00', '2026-01-25 09:15:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000015',
    '00000000-0000-0000-0000-000000000000',
    'admin1@opencapital.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-01 08:00:00', '2024-01-01 08:00:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000016',
    '00000000-0000-0000-0000-000000000000',
    'admin2@opencapital.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-01 08:00:00', '2024-01-01 08:00:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000017',
    '00000000-0000-0000-0000-000000000000',
    'admin3@opencapital.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-01 08:00:00', '2024-01-01 08:00:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000018',
    '00000000-0000-0000-0000-000000000000',
    'test.user@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2026-02-06 10:00:00', '2026-02-06 10:00:00',
    '{"provider":"email","providers":["email"]}', '{}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
)
ON CONFLICT (id) DO NOTHING;

-- handle_new_auth_user trigger has now fired for each row above,
-- creating public.users rows and wallet_balances rows automatically.


-- ============================================
-- STEP 2: UPDATE public.users
-- Set role, status, phone, verification flags etc.
-- ============================================

UPDATE users SET phone_number='+256701234567', role='borrower',  status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=FALSE, last_login_at='2026-01-28 14:22:00', last_login_ip='102.168.1.45',  created_at='2024-01-15 08:30:00' WHERE email='david.mukasa@gmail.com';
UPDATE users SET phone_number='+256702345678', role='borrower',  status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=FALSE, last_login_at='2026-01-29 09:15:00', last_login_ip='102.168.1.67',  created_at='2024-01-18 10:45:00' WHERE email='sarah.namukasa@yahoo.com';
UPDATE users SET phone_number='+256703456789', role='both',      status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-27 16:40:00', last_login_ip='102.168.1.89',  created_at='2024-01-20 14:20:00' WHERE email='james.okello@outlook.com';
UPDATE users SET phone_number='+256704567890', role='borrower',  status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=FALSE, last_login_at='2026-01-28 11:30:00', last_login_ip='102.168.1.102', created_at='2024-01-22 09:10:00' WHERE email='maria.nakato@gmail.com';
UPDATE users SET phone_number='+256705678901', role='both',      status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-29 08:20:00', last_login_ip='102.168.1.125', created_at='2024-01-25 11:30:00' WHERE email='robert.ssemwanga@gmail.com';
UPDATE users SET phone_number='+256711234567', role='lender',    status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-28 16:30:00', last_login_ip='102.168.2.10',  created_at='2024-02-18 09:20:00' WHERE email='info@greenleafagro.co.ug';
UPDATE users SET phone_number='+256712345678', role='lender',    status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-29 10:20:00', last_login_ip='102.168.2.20',  created_at='2024-02-20 11:40:00' WHERE email='contact@kampalatech.ug';
UPDATE users SET phone_number='+256716789012', role='lender',    status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-28 17:20:00', last_login_ip='102.168.2.30',  created_at='2024-03-01 10:10:00' WHERE email='invest@pearlcapital.ug';
UPDATE users SET phone_number='+256717890123', role='lender',    status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-29 08:50:00', last_login_ip='102.168.2.40',  created_at='2024-03-03 12:30:00' WHERE email='funds@victoriainvest.co.ug';
UPDATE users SET phone_number='+256718901234', role='lender',    status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-27 15:30:00', last_login_ip='102.168.2.50',  created_at='2024-03-05 09:45:00' WHERE email='lending@equatorfinance.ug';
UPDATE users SET phone_number='+256719012345', role='borrower',  status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=FALSE, last_login_at='2026-01-28 12:40:00', last_login_ip='102.168.3.10',  created_at='2024-03-08 14:15:00' WHERE email='frank.omondi@gmail.com';
UPDATE users SET phone_number='+256720123456', role='both',      status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-29 13:25:00', last_login_ip='102.168.3.20',  created_at='2024-03-10 11:20:00' WHERE email='lucy.nambi@yahoo.com';
UPDATE users SET phone_number='+256721234567', role='both',      status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=FALSE, last_login_at='2026-01-28 08:15:00', last_login_ip='102.168.3.30',  created_at='2024-03-12 16:40:00' WHERE email='charles.mwesigwa@gmail.com';
UPDATE users SET phone_number='+256726789012', role='borrower',  status='pending_verification', email_verified=TRUE,  phone_verified=FALSE, two_factor_enabled=FALSE, last_login_at=NULL,                  last_login_ip=NULL,            created_at='2026-01-25 09:15:00' WHERE email='alice.namuli@gmail.com';
UPDATE users SET phone_number='+256700000001', role='admin',     status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-29 18:00:00', last_login_ip='10.0.0.1',      created_at='2024-01-01 08:00:00' WHERE email='admin1@opencapital.ug';
UPDATE users SET phone_number='+256700000002', role='admin',     status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-29 17:30:00', last_login_ip='10.0.0.2',      created_at='2024-01-01 08:00:00' WHERE email='admin2@opencapital.ug';
UPDATE users SET phone_number='+256700000003', role='admin',     status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=TRUE,  last_login_at='2026-01-29 17:00:00', last_login_ip='10.0.0.3',      created_at='2024-01-01 08:00:00' WHERE email='admin3@opencapital.ug';
UPDATE users SET phone_number='+256799999999', role='borrower',  status='active',               email_verified=TRUE,  phone_verified=TRUE,  two_factor_enabled=FALSE, last_login_at='2026-02-06 10:00:00', last_login_ip='127.0.0.1',     created_at='2026-02-06 10:00:00' WHERE email='test.user@gmail.com';


-- ============================================
-- STEP 3: USER PROFILES
-- ============================================

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'David', 'Mukasa', '1988-03-15', 'male', 'Plot 23, Kololo Heights', 'P.O. Box 12345', 'Kampala', 'Central', 'Uganda', '00256', 'employed', 'Uganda Revenue Authority', 'Tax Officer', 4500000.00, NULL, NULL, NULL, NULL, TRUE, 100, '2024-01-15 08:30:00' FROM users u WHERE u.email = 'david.mukasa@gmail.com' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Sarah', 'Namukasa', '1992-07-22', 'female', 'Block 12, Ntinda Estate', 'P.O. Box 23456', 'Kampala', 'Central', 'Uganda', '00256', 'employed', 'Stanbic Bank Uganda', 'Bank Teller', 3200000.00, NULL, NULL, NULL, NULL, TRUE, 100, '2024-01-18 10:45:00' FROM users u WHERE u.email = 'sarah.namukasa@yahoo.com' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'James', 'Okello', '1985-11-08', 'male', 'House 45, Bugolobi', 'P.O. Box 34567', 'Kampala', 'Central', 'Uganda', '00256', 'employed', 'MTN Uganda', 'Network Engineer', 5800000.00, NULL, NULL, NULL, NULL, TRUE, 100, '2024-01-20 14:20:00' FROM users u WHERE u.email = 'james.okello@outlook.com' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Maria', 'Nakato', '1990-05-14', 'female', 'Apartment 7, Nakasero', NULL, 'Kampala', 'Central', 'Uganda', '00256', 'self_employed', NULL, 'Boutique Owner', 2800000.00, 'Nakato Boutique', 'UG-BIZ-2020-012345', 'Retail', 4, TRUE, 100, '2024-01-22 09:10:00' FROM users u WHERE u.email = 'maria.nakato@gmail.com' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Robert', 'Ssemwanga', '1987-09-30', 'male', 'Villa 18, Muyenga', NULL, 'Kampala', 'Central', 'Uganda', '00256', 'employed', 'DFCU Bank', 'Branch Manager', 6500000.00, NULL, NULL, NULL, NULL, TRUE, 100, '2024-01-25 11:30:00' FROM users u WHERE u.email = 'robert.ssemwanga@gmail.com' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Michael', 'Semakula', '1980-01-20', 'male', 'Industrial Area, Plot 123', 'P.O. Box 1000', 'Kampala', 'Central', 'Uganda', '00256', 'self_employed', NULL, 'CEO', 15000000.00, 'GreenLeaf Agro Solutions Ltd', 'UG-BIZ-2019-045678', 'Agriculture', 5, TRUE, 100, '2024-02-18 09:20:00' FROM users u WHERE u.email = 'info@greenleafagro.co.ug' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Sandra', 'Namutebi', '1983-07-15', 'female', 'Plot 45, Nakawa', 'P.O. Box 2000', 'Kampala', 'Central', 'Uganda', '00256', 'self_employed', NULL, 'Managing Director', 12000000.00, 'Kampala Tech Innovations', 'UG-BIZ-2020-056789', 'Technology', 4, TRUE, 100, '2024-02-20 11:40:00' FROM users u WHERE u.email = 'contact@kampalatech.ug' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'William', 'Kasujja', '1975-05-18', 'male', 'Pearl House, 14th Floor', 'P.O. Box 3000', 'Kampala', 'Central', 'Uganda', '00256', 'self_employed', NULL, 'Investment Manager', 25000000.00, 'Pearl Capital Investment Fund', 'UG-INV-2015-001234', 'Financial Services', 9, TRUE, 100, '2024-03-01 10:10:00' FROM users u WHERE u.email = 'invest@pearlcapital.ug' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Catherine', 'Namboze', '1977-12-03', 'female', 'Crown Tower, Suite 1201', 'P.O. Box 4000', 'Kampala', 'Central', 'Uganda', '00256', 'self_employed', NULL, 'Fund Manager', 22000000.00, 'Victoria Investment Group', 'UG-INV-2014-002345', 'Investment Management', 10, TRUE, 100, '2024-03-03 12:30:00' FROM users u WHERE u.email = 'funds@victoriainvest.co.ug' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'George', 'Mulindwa', '1979-08-25', 'male', 'Finance Plaza, 8th Floor', 'P.O. Box 5000', 'Kampala', 'Central', 'Uganda', '00256', 'self_employed', NULL, 'Director', 28000000.00, 'Equator Finance Corporation', 'UG-INV-2016-003456', 'Financial Services', 8, TRUE, 100, '2024-03-05 09:45:00' FROM users u WHERE u.email = 'lending@equatorfinance.ug' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Frank', 'Omondi', '1991-10-14', 'male', 'Plot 12, Makindye', NULL, 'Kampala', 'Central', 'Uganda', '00256', 'employed', 'Bank of Africa', 'Credit Officer', 3300000.00, NULL, NULL, NULL, NULL, TRUE, 100, '2024-03-08 14:15:00' FROM users u WHERE u.email = 'frank.omondi@gmail.com' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Lucy', 'Nambi', '1988-04-07', 'female', 'House 78, Najanankumbi', NULL, 'Kampala', 'Central', 'Uganda', '00256', 'employed', 'National Social Security Fund', 'Accountant', 2900000.00, NULL, NULL, NULL, NULL, TRUE, 100, '2024-03-10 11:20:00' FROM users u WHERE u.email = 'lucy.nambi@yahoo.com' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Charles', 'Mwesigwa', '1984-06-21', 'male', 'Apartment 15, Kabalagala', NULL, 'Kampala', 'Central', 'Uganda', '00256', 'employed', 'Shell Uganda', 'Operations Manager', 5200000.00, NULL, NULL, NULL, NULL, TRUE, 100, '2024-03-12 16:40:00' FROM users u WHERE u.email = 'charles.mwesigwa@gmail.com' ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (profile_id, user_id, first_name, last_name, date_of_birth, gender, address_line1, address_line2, city, district, country, postal_code, employment_status, employer_name, job_title, monthly_income, business_name, business_registration_number, business_type, years_in_business, profile_completed, profile_completion_percentage, created_at)
SELECT gen_random_uuid(), u.user_id, 'Alice', 'Namuli', '1993-09-12', 'female', 'House 34, Mutungo', NULL, 'Kampala', 'Central', 'Uganda', '00256', 'employed', 'Equity Bank', 'Customer Service', 2700000.00, NULL, NULL, NULL, NULL, FALSE, 65, '2026-01-25 09:15:00' FROM users u WHERE u.email = 'alice.namuli@gmail.com' ON CONFLICT (user_id) DO NOTHING;


-- ============================================
-- STEP 4: KYC VERIFICATIONS
-- ============================================

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'approved', 'national_id', 'CM88015KL234567', 'https://storage.opencapital.ug/kyc/user-001-id-front.jpg', 'https://storage.opencapital.ug/kyc/user-001-id-back.jpg', TRUE, '2024-01-16 10:30:00', 'https://storage.opencapital.ug/kyc/user-001-selfie.jpg', TRUE, '2024-01-16 10:30:00', 'https://storage.opencapital.ug/kyc/user-001-address.pdf', TRUE, '2024-01-16 10:30:00', (SELECT user_id FROM users WHERE email = 'admin1@opencapital.ug'), '2024-01-15 09:15:00', '2024-01-16 10:30:00', '2029-01-15', '2024-01-15 09:15:00' FROM users u WHERE u.email = 'david.mukasa@gmail.com';

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'approved', 'national_id', 'CM92022NM345678', 'https://storage.opencapital.ug/kyc/user-002-id-front.jpg', 'https://storage.opencapital.ug/kyc/user-002-id-back.jpg', TRUE, '2024-01-19 11:45:00', 'https://storage.opencapital.ug/kyc/user-002-selfie.jpg', TRUE, '2024-01-19 11:45:00', 'https://storage.opencapital.ug/kyc/user-002-address.pdf', TRUE, '2024-01-19 11:45:00', (SELECT user_id FROM users WHERE email = 'admin1@opencapital.ug'), '2024-01-18 11:00:00', '2024-01-19 11:45:00', '2029-01-18', '2024-01-18 11:00:00' FROM users u WHERE u.email = 'sarah.namukasa@yahoo.com';

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'approved', 'national_id', 'CM85011OK345679', 'https://storage.opencapital.ug/kyc/user-003-id-front.jpg', 'https://storage.opencapital.ug/kyc/user-003-id-back.jpg', TRUE, '2024-01-21 09:30:00', 'https://storage.opencapital.ug/kyc/user-003-selfie.jpg', TRUE, '2024-01-21 09:30:00', 'https://storage.opencapital.ug/kyc/user-003-address.pdf', TRUE, '2024-01-21 09:30:00', (SELECT user_id FROM users WHERE email = 'admin2@opencapital.ug'), '2024-01-20 14:30:00', '2024-01-21 09:30:00', '2029-01-20', '2024-01-20 14:30:00' FROM users u WHERE u.email = 'james.okello@outlook.com';

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'approved', 'national_id', 'CM90014NK567890', 'https://storage.opencapital.ug/kyc/user-004-id-front.jpg', 'https://storage.opencapital.ug/kyc/user-004-id-back.jpg', TRUE, '2024-01-23 14:30:00', 'https://storage.opencapital.ug/kyc/user-004-selfie.jpg', TRUE, '2024-01-23 14:30:00', 'https://storage.opencapital.ug/kyc/user-004-address.pdf', TRUE, '2024-01-23 14:30:00', (SELECT user_id FROM users WHERE email = 'admin2@opencapital.ug'), '2024-01-22 09:30:00', '2024-01-23 14:30:00', '2029-01-22', '2024-01-22 09:30:00' FROM users u WHERE u.email = 'maria.nakato@gmail.com';

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'approved', 'national_id', 'CM87030SS678901', 'https://storage.opencapital.ug/kyc/user-005-id-front.jpg', 'https://storage.opencapital.ug/kyc/user-005-id-back.jpg', TRUE, '2024-01-25 16:00:00', 'https://storage.opencapital.ug/kyc/user-005-selfie.jpg', TRUE, '2024-01-25 16:00:00', 'https://storage.opencapital.ug/kyc/user-005-address.pdf', TRUE, '2024-01-25 16:00:00', (SELECT user_id FROM users WHERE email = 'admin1@opencapital.ug'), '2024-01-25 11:45:00', '2024-01-25 16:00:00', '2029-01-25', '2024-01-25 11:45:00' FROM users u WHERE u.email = 'robert.ssemwanga@gmail.com';

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, business_registration_url, business_license_url, tax_clearance_url, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'approved', 'business_registration', 'UG-BIZ-2019-045678', 'https://storage.opencapital.ug/kyc/user-011-license.pdf', NULL, TRUE, '2024-02-19 10:30:00', NULL, FALSE, NULL, 'https://storage.opencapital.ug/kyc/user-011-address.pdf', TRUE, '2024-02-19 10:30:00', 'https://storage.opencapital.ug/kyc/user-011-registration.pdf', 'https://storage.opencapital.ug/kyc/user-011-license.pdf', 'https://storage.opencapital.ug/kyc/user-011-tax.pdf', (SELECT user_id FROM users WHERE email = 'admin3@opencapital.ug'), '2024-02-19 09:00:00', '2024-02-19 10:30:00', '2027-02-19', '2024-02-19 09:00:00' FROM users u WHERE u.email = 'info@greenleafagro.co.ug';

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'approved', 'national_id', 'CM91114OM789012', 'https://storage.opencapital.ug/kyc/user-011-id-front.jpg', 'https://storage.opencapital.ug/kyc/user-011-id-back.jpg', TRUE, '2024-03-09 14:00:00', 'https://storage.opencapital.ug/kyc/user-011-selfie.jpg', TRUE, '2024-03-09 14:00:00', 'https://storage.opencapital.ug/kyc/user-011-address.pdf', TRUE, '2024-03-09 14:00:00', (SELECT user_id FROM users WHERE email = 'admin2@opencapital.ug'), '2024-03-09 09:30:00', '2024-03-09 14:00:00', '2029-03-09', '2024-03-09 09:30:00' FROM users u WHERE u.email = 'frank.omondi@gmail.com';

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'approved', 'national_id', 'CM88047NB890123', 'https://storage.opencapital.ug/kyc/user-012-id-front.jpg', 'https://storage.opencapital.ug/kyc/user-012-id-back.jpg', TRUE, '2024-03-11 11:00:00', 'https://storage.opencapital.ug/kyc/user-012-selfie.jpg', TRUE, '2024-03-11 11:00:00', 'https://storage.opencapital.ug/kyc/user-012-address.pdf', TRUE, '2024-03-11 11:00:00', (SELECT user_id FROM users WHERE email = 'admin3@opencapital.ug'), '2024-03-11 09:00:00', '2024-03-11 11:00:00', '2029-03-11', '2024-03-11 09:00:00' FROM users u WHERE u.email = 'lucy.nambi@yahoo.com';

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'approved', 'national_id', 'CM84021MW901234', 'https://storage.opencapital.ug/kyc/user-013-id-front.jpg', 'https://storage.opencapital.ug/kyc/user-013-id-back.jpg', TRUE, '2024-03-13 15:00:00', 'https://storage.opencapital.ug/kyc/user-013-selfie.jpg', TRUE, '2024-03-13 15:00:00', 'https://storage.opencapital.ug/kyc/user-013-address.pdf', TRUE, '2024-03-13 15:00:00', (SELECT user_id FROM users WHERE email = 'admin3@opencapital.ug'), '2024-03-13 12:00:00', '2024-03-13 15:00:00', '2029-03-13', '2024-03-13 12:00:00' FROM users u WHERE u.email = 'charles.mwesigwa@gmail.com';

INSERT INTO kyc_verifications (verification_id, user_id, status, id_type, id_number, id_front_url, id_back_url, id_verified, id_verified_at, selfie_url, selfie_verified, selfie_verified_at, proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at, verified_by, submitted_at, verified_at, expires_at, created_at)
SELECT gen_random_uuid(), u.user_id, 'pending', 'national_id', 'CM93255NM789012', 'https://storage.opencapital.ug/kyc/user-026-id-front.jpg', 'https://storage.opencapital.ug/kyc/user-026-id-back.jpg', FALSE, NULL, 'https://storage.opencapital.ug/kyc/user-026-selfie.jpg', FALSE, NULL, 'https://storage.opencapital.ug/kyc/user-026-address.pdf', FALSE, NULL, NULL, '2026-01-25 10:30:00', NULL, NULL, '2026-01-25 10:30:00' FROM users u WHERE u.email = 'alice.namuli@gmail.com';


-- ============================================
-- STEP 5: RISK ASSESSMENTS
-- ============================================

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 750, 91.0, 'low', 95, 88, 15.2, 90, (SELECT user_id FROM users WHERE email='admin1@opencapital.ug'), '2024-01-16 11:00:00', '2026-07-15', TRUE, '2024-01-16 11:00:00' FROM users u WHERE u.email='david.mukasa@gmail.com';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 720, 74.0, 'low', 78, 72, 22.5, 70, NULL, '2024-01-19 12:00:00', '2026-07-18', TRUE, '2024-01-19 12:00:00' FROM users u WHERE u.email='sarah.namukasa@yahoo.com';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 780, 88.0, 'low', 92, 85, 18.7, 87, NULL, '2024-01-21 09:00:00', '2026-07-20', TRUE, '2024-01-21 09:00:00' FROM users u WHERE u.email='james.okello@outlook.com';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 650, 61.0, 'medium', 65, 58, 35.0, 60, NULL, '2024-01-23 14:00:00', '2026-07-22', TRUE, '2024-01-23 14:00:00' FROM users u WHERE u.email='maria.nakato@gmail.com';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 790, 85.0, 'low', 90, 88, 12.0, 85, NULL, '2024-01-25 17:00:00', '2026-07-25', TRUE, '2024-01-25 17:00:00' FROM users u WHERE u.email='robert.ssemwanga@gmail.com';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 710, 79.0, 'low', 82, 78, 28.0, 75, (SELECT user_id FROM users WHERE email='admin3@opencapital.ug'), '2024-02-20 09:00:00', '2026-08-18', TRUE, '2024-02-20 09:00:00' FROM users u WHERE u.email='info@greenleafagro.co.ug';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 850, 95.0, 'low', 98, 95, 10.0, 96, NULL, '2024-03-02 10:00:00', '2026-09-01', TRUE, '2024-03-02 10:00:00' FROM users u WHERE u.email='invest@pearlcapital.ug';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 845, 95.0, 'low', 96, 93, 12.0, 95, NULL, '2024-03-04 11:00:00', '2026-09-03', TRUE, '2024-03-04 11:00:00' FROM users u WHERE u.email='funds@victoriainvest.co.ug';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 580, 44.0, 'high', 48, 42, 45.0, 40, NULL, '2024-03-09 10:00:00', '2026-09-18', TRUE, '2024-03-09 10:00:00' FROM users u WHERE u.email='frank.omondi@gmail.com';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 690, 68.0, 'medium', 70, 65, 28.0, 65, NULL, '2024-03-11 12:00:00', '2026-09-11', TRUE, '2024-03-11 12:00:00' FROM users u WHERE u.email='lucy.nambi@yahoo.com';

INSERT INTO risk_assessments (assessment_id, user_id, credit_score, risk_score, risk_category, income_verification_score, employment_stability_score, debt_to_income_ratio, previous_loan_performance_score, assessed_by, assessment_date, valid_until, is_current, created_at)
SELECT gen_random_uuid(), u.user_id, 760, 82.0, 'low', 85, 80, 16.0, 80, NULL, '2024-03-13 16:00:00', '2026-09-13', TRUE, '2024-03-13 16:00:00' FROM users u WHERE u.email='charles.mwesigwa@gmail.com';


-- ============================================
-- STEP 6: LOAN REQUESTS
-- ============================================

INSERT INTO loan_requests (request_id, borrower_id, requested_amount, purpose, purpose_description, duration_months, max_interest_rate, total_bid_amount, number_of_bids, funding_percentage, status, listed_at, expires_at, funded_at, supporting_documents, views_count, created_at)
SELECT gen_random_uuid(), u.user_id, 5000000.00, 'Home Renovation', 'Complete home renovation including kitchen and bathroom upgrades', 12, 12.0, 0.00, 0, 0.00, 'active', '2025-11-15 11:00:00', '2025-11-22 11:00:00', NULL, '{"renovation_plan":"plan.pdf"}', 45, '2025-11-14 14:20:00' FROM users u WHERE u.email='david.mukasa@gmail.com';

INSERT INTO loan_requests (request_id, borrower_id, requested_amount, purpose, purpose_description, duration_months, max_interest_rate, total_bid_amount, number_of_bids, funding_percentage, status, listed_at, expires_at, funded_at, supporting_documents, views_count, created_at)
SELECT gen_random_uuid(), u.user_id, 5500000.00, 'Education', 'Professional certification courses in financial management', 12, 15.0, 0.00, 0, 0.00, 'active', '2026-01-20 11:30:00', '2026-01-27 11:30:00', NULL, '{"course_brochure":"course.pdf"}', 28, '2026-01-19 14:15:00' FROM users u WHERE u.email='sarah.namukasa@yahoo.com';

INSERT INTO loan_requests (request_id, borrower_id, requested_amount, purpose, purpose_description, duration_months, max_interest_rate, total_bid_amount, number_of_bids, funding_percentage, status, listed_at, expires_at, funded_at, supporting_documents, views_count, created_at)
SELECT gen_random_uuid(), u.user_id, 8000000.00, 'Business Expansion', 'Equipment purchase for IT consultancy expansion', 18, 10.5, 0.00, 0, 0.00, 'active', '2025-11-20 10:00:00', '2025-11-27 10:00:00', NULL, '{"business_plan":"plan.pdf"}', 52, '2025-11-19 16:30:00' FROM users u WHERE u.email='james.okello@outlook.com';

INSERT INTO loan_requests (request_id, borrower_id, requested_amount, purpose, purpose_description, duration_months, max_interest_rate, total_bid_amount, number_of_bids, funding_percentage, status, listed_at, expires_at, funded_at, supporting_documents, views_count, created_at)
SELECT gen_random_uuid(), u.user_id, 3500000.00, 'Business Inventory', 'Inventory expansion for boutique store', 12, 15.0, 0.00, 0, 0.00, 'active', '2026-01-24 15:00:00', '2026-01-31 15:00:00', NULL, '{"inventory_list":"inventory.pdf"}', 15, '2026-01-23 11:45:00' FROM users u WHERE u.email='maria.nakato@gmail.com';

INSERT INTO loan_requests (request_id, borrower_id, requested_amount, purpose, purpose_description, duration_months, max_interest_rate, total_bid_amount, number_of_bids, funding_percentage, status, listed_at, expires_at, funded_at, supporting_documents, views_count, created_at)
SELECT gen_random_uuid(), u.user_id, 6000000.00, 'Vehicle Purchase', 'Purchase of delivery van for business', 24, 13.0, 0.00, 0, 0.00, 'draft', NULL, NULL, NULL, '{"vehicle_quote":"quote.pdf"}', 3, '2026-01-28 14:30:00' FROM users u WHERE u.email='robert.ssemwanga@gmail.com';

INSERT INTO loan_requests (request_id, borrower_id, requested_amount, purpose, purpose_description, duration_months, max_interest_rate, total_bid_amount, number_of_bids, funding_percentage, status, listed_at, expires_at, funded_at, supporting_documents, views_count, created_at)
SELECT gen_random_uuid(), u.user_id, 4500000.00, 'Medical Expenses', 'Medical treatment and recovery expenses', 18, 14.5, 0.00, 0, 0.00, 'active', '2026-01-26 10:00:00', '2026-02-02 10:00:00', NULL, '{"medical_reports":"reports.pdf"}', 22, '2026-01-25 15:50:00' FROM users u WHERE u.email='frank.omondi@gmail.com';


-- ============================================
-- STEP 7: WALLET DEPOSITS
-- ============================================

UPDATE wallet_balances SET lendable_balance = 10000000.00 WHERE user_id = (SELECT user_id FROM users WHERE email='invest@pearlcapital.ug');
UPDATE wallet_balances SET lendable_balance =  5000000.00 WHERE user_id = (SELECT user_id FROM users WHERE email='funds@victoriainvest.co.ug');
UPDATE wallet_balances SET lendable_balance =  5000000.00 WHERE user_id = (SELECT user_id FROM users WHERE email='robert.ssemwanga@gmail.com');
UPDATE wallet_balances SET lendable_balance =  3000000.00 WHERE user_id = (SELECT user_id FROM users WHERE email='charles.mwesigwa@gmail.com');
UPDATE wallet_balances SET lendable_balance =  5000000.00 WHERE user_id = (SELECT user_id FROM users WHERE email='lending@equatorfinance.ug');
UPDATE wallet_balances SET lendable_balance =  3000000.00 WHERE user_id = (SELECT user_id FROM users WHERE email='info@greenleafagro.co.ug');
UPDATE wallet_balances SET lendable_balance =  3000000.00 WHERE user_id = (SELECT user_id FROM users WHERE email='contact@kampalatech.ug');


-- ============================================
-- STEP 8: BIDS (all inserted as 'pending')
-- ============================================

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 2000000.00, 11.0, 'pending', TRUE, '2025-11-15 12:30:00'
FROM loan_requests lr JOIN users l ON l.email='invest@pearlcapital.ug'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='david.mukasa@gmail.com') LIMIT 1;

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 2000000.00, 11.5, 'pending', FALSE, '2025-11-16 09:15:00'
FROM loan_requests lr JOIN users l ON l.email='funds@victoriainvest.co.ug'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='david.mukasa@gmail.com') LIMIT 1;

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 1000000.00, 12.0, 'pending', FALSE, '2025-11-18 08:45:00'
FROM loan_requests lr JOIN users l ON l.email='robert.ssemwanga@gmail.com'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='david.mukasa@gmail.com') LIMIT 1;

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 1500000.00, 14.5, 'pending', FALSE, '2026-01-21 11:20:00'
FROM loan_requests lr JOIN users l ON l.email='robert.ssemwanga@gmail.com'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='sarah.namukasa@yahoo.com') LIMIT 1;

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 1800000.00, 15.0, 'pending', FALSE, '2026-01-24 08:45:00'
FROM loan_requests lr JOIN users l ON l.email='charles.mwesigwa@gmail.com'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='sarah.namukasa@yahoo.com') LIMIT 1;

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at, expires_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 1000000.00, 15.0, 'pending', FALSE, '2026-01-26 14:20:00', '2026-02-02 14:20:00'
FROM loan_requests lr JOIN users l ON l.email='robert.ssemwanga@gmail.com'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='sarah.namukasa@yahoo.com') LIMIT 1;

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 5000000.00, 10.0, 'pending', TRUE, '2025-11-20 11:20:00'
FROM loan_requests lr JOIN users l ON l.email='invest@pearlcapital.ug'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='james.okello@outlook.com') LIMIT 1;

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 3000000.00, 10.5, 'pending', TRUE, '2025-11-23 13:15:00'
FROM loan_requests lr JOIN users l ON l.email='lending@equatorfinance.ug'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='james.okello@outlook.com') LIMIT 1;

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at, expires_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 1500000.00, 14.0, 'pending', FALSE, '2026-01-27 10:30:00', '2026-02-03 10:30:00'
FROM loan_requests lr JOIN users l ON l.email='info@greenleafagro.co.ug'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='maria.nakato@gmail.com') LIMIT 1;

INSERT INTO bids (bid_id, request_id, lender_id, bid_amount, interest_rate, status, auto_accept, created_at, expires_at)
SELECT gen_random_uuid(), lr.request_id, l.user_id, 2000000.00, 14.5, 'pending', FALSE, '2026-01-28 09:15:00', '2026-02-04 09:15:00'
FROM loan_requests lr JOIN users l ON l.email='contact@kampalatech.ug'
WHERE lr.borrower_id=(SELECT user_id FROM users WHERE email='frank.omondi@gmail.com') LIMIT 1;


-- ============================================
-- STEP 9: BID ACCEPTANCE
-- Fires trg_fn_lock_funds_on_accept and
-- trg_fn_update_funding_progress automatically.
-- ============================================

UPDATE bids SET status='accepted', accepted_at='2025-11-15 12:30:00'
WHERE lender_id=(SELECT user_id FROM users WHERE email='invest@pearlcapital.ug')
  AND request_id=(SELECT request_id FROM loan_requests WHERE borrower_id=(SELECT user_id FROM users WHERE email='david.mukasa@gmail.com'))
  AND bid_amount=2000000.00 AND status='pending';

UPDATE bids SET status='accepted', accepted_at='2025-11-16 14:20:00'
WHERE lender_id=(SELECT user_id FROM users WHERE email='funds@victoriainvest.co.ug')
  AND request_id=(SELECT request_id FROM loan_requests WHERE borrower_id=(SELECT user_id FROM users WHERE email='david.mukasa@gmail.com'))
  AND bid_amount=2000000.00 AND status='pending';

UPDATE bids SET status='accepted', accepted_at='2025-11-18 09:45:00'
WHERE lender_id=(SELECT user_id FROM users WHERE email='robert.ssemwanga@gmail.com')
  AND request_id=(SELECT request_id FROM loan_requests WHERE borrower_id=(SELECT user_id FROM users WHERE email='david.mukasa@gmail.com'))
  AND bid_amount=1000000.00 AND status='pending';

UPDATE bids SET status='accepted', accepted_at='2026-01-21 15:30:00'
WHERE lender_id=(SELECT user_id FROM users WHERE email='robert.ssemwanga@gmail.com')
  AND request_id=(SELECT request_id FROM loan_requests WHERE borrower_id=(SELECT user_id FROM users WHERE email='sarah.namukasa@yahoo.com'))
  AND bid_amount=1500000.00 AND status='pending';

UPDATE bids SET status='accepted', accepted_at='2026-01-24 09:30:00'
WHERE lender_id=(SELECT user_id FROM users WHERE email='charles.mwesigwa@gmail.com')
  AND request_id=(SELECT request_id FROM loan_requests WHERE borrower_id=(SELECT user_id FROM users WHERE email='sarah.namukasa@yahoo.com'))
  AND bid_amount=1800000.00 AND status='pending';

UPDATE bids SET status='accepted', accepted_at='2025-11-20 11:20:00'
WHERE lender_id=(SELECT user_id FROM users WHERE email='invest@pearlcapital.ug')
  AND request_id=(SELECT request_id FROM loan_requests WHERE borrower_id=(SELECT user_id FROM users WHERE email='james.okello@outlook.com'))
  AND bid_amount=5000000.00 AND status='pending';

UPDATE bids SET status='accepted', accepted_at='2025-11-23 13:15:00'
WHERE lender_id=(SELECT user_id FROM users WHERE email='lending@equatorfinance.ug')
  AND request_id=(SELECT request_id FROM loan_requests WHERE borrower_id=(SELECT user_id FROM users WHERE email='james.okello@outlook.com'))
  AND bid_amount=3000000.00 AND status='pending';


-- ============================================
-- STEP 10: POST-ACCEPT FIXUPS
-- ============================================

UPDATE loan_requests SET funded_at='2025-11-20 14:30:00'
WHERE borrower_id=(SELECT user_id FROM users WHERE email='david.mukasa@gmail.com') AND status='fully_funded';

UPDATE loan_requests SET funded_at='2025-11-25 15:45:00'
WHERE borrower_id=(SELECT user_id FROM users WHERE email='james.okello@outlook.com') AND status='fully_funded';


-- ============================================
-- VERIFICATION
-- ============================================

SELECT table_name, record_count FROM (
    SELECT 'auth.users'       AS table_name, COUNT(*) AS record_count FROM auth.users
    UNION ALL SELECT 'public.users',          COUNT(*) FROM public.users
    UNION ALL SELECT 'user_profiles',         COUNT(*) FROM user_profiles
    UNION ALL SELECT 'kyc_verifications',     COUNT(*) FROM kyc_verifications
    UNION ALL SELECT 'risk_assessments',      COUNT(*) FROM risk_assessments
    UNION ALL SELECT 'wallet_balances',       COUNT(*) FROM wallet_balances
    UNION ALL SELECT 'loan_requests',         COUNT(*) FROM loan_requests
    UNION ALL SELECT 'bids',                  COUNT(*) FROM bids
) t ORDER BY table_name;

-- Auth sync: every seed user should show confirmed=true
SELECT pu.email, au.email_confirmed_at IS NOT NULL AS confirmed, pu.role, pu.status
FROM public.users pu
LEFT JOIN auth.users au ON au.id = pu.user_id
ORDER BY pu.email;

-- Wallet state
SELECT u.email, wb.lendable_balance, wb.locked_repayment, wb.non_lendable_borrowed
FROM users u JOIN wallet_balances wb ON u.user_id = wb.user_id
WHERE u.role IN ('lender','both') ORDER BY u.email;

SELECT '✅ Seed data v2.1 inserted successfully — 15/15 integration tests should pass' AS status;