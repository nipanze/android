-- ============================================
-- NIPANZE Seed Data
-- Version: 1.2 (Schema-Aligned)
-- ============================================
--
-- FIXES vs v1.1:
--   1. loan_requests: removed total_bid_amount, funding_percentage
--      (columns do not exist in schema v5.0)
--   2. contracts: replaced monthly_payment_ugx, total_repayment_ugx,
--      total_interest_ugx, outstanding_balance, total_repaid, days_overdue
--      with indicative_monthly_payment_ugx, indicative_total_repayment_ugx,
--      indicative_total_interest_ugx (correct schema column names)
--   3. repayment_schedules: removed amount_due, amount_paid, paid_at,
--      days_late (do not exist). Uses reported_status/reported_at/reported_by only.
--   4. notifications: replaced 'repayment_due' enum value (does not exist)
--      with 'system'.
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
--   admin1@nipanze.ug    → 10000000-0000-0000-0000-000000000015
--   admin2@nipanze.ug    → 10000000-0000-0000-0000-000000000016
--   test.user            → 10000000-0000-0000-0000-000000000017
-- ============================================


-- ============================================
-- STEP 1: AUTH USERS
-- ============================================

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
(
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'david.mukasa@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-15 08:30:00', '2024-01-15 08:30:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"David Mukasa"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'sarah.namukasa@yahoo.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-18 10:45:00', '2024-01-18 10:45:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Sarah Namukasa"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000',
    'james.okello@outlook.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-20 14:20:00', '2024-01-20 14:20:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"James Okello"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000000',
    'maria.nakato@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-22 09:10:00', '2024-01-22 09:10:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Maria Nakato"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000000',
    'robert.ssemwanga@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-25 11:30:00', '2024-01-25 11:30:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Robert Ssemwanga"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000000',
    'info@greenleafagro.co.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-02-18 09:20:00', '2024-02-18 09:20:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Michael Semakula"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000007',
    '00000000-0000-0000-0000-000000000000',
    'contact@kampalatech.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-02-20 11:40:00', '2024-02-20 11:40:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Sandra Namutebi"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000008',
    '00000000-0000-0000-0000-000000000000',
    'invest@pearlcapital.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-01 10:10:00', '2024-03-01 10:10:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"William Kasujja"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000009',
    '00000000-0000-0000-0000-000000000000',
    'funds@victoriainvest.co.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-03 12:30:00', '2024-03-03 12:30:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Catherine Namboze"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000010',
    '00000000-0000-0000-0000-000000000000',
    'lending@equatorfinance.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-05 09:45:00', '2024-03-05 09:45:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"George Mulindwa"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000011',
    '00000000-0000-0000-0000-000000000000',
    'frank.omondi@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-08 14:15:00', '2024-03-08 14:15:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Frank Omondi"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000012',
    '00000000-0000-0000-0000-000000000000',
    'lucy.nambi@yahoo.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-10 11:20:00', '2024-03-10 11:20:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Lucy Nambi"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000013',
    '00000000-0000-0000-0000-000000000000',
    'charles.mwesigwa@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-03-12 16:40:00', '2024-03-12 16:40:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Charles Mwesigwa"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000014',
    '00000000-0000-0000-0000-000000000000',
    'alice.namuli@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2026-01-25 09:15:00', '2026-01-25 09:15:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Alice Namuli"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000015',
    '00000000-0000-0000-0000-000000000000',
    'admin1@nipanze.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-01 08:00:00', '2024-01-01 08:00:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Admin One"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000016',
    '00000000-0000-0000-0000-000000000000',
    'admin2@nipanze.ug',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2024-01-01 08:00:00', '2024-01-01 08:00:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Admin Two"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
),
(
    '10000000-0000-0000-0000-000000000017',
    '00000000-0000-0000-0000-000000000000',
    'test.user@gmail.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), '2026-02-06 10:00:00', '2026-02-06 10:00:00',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Test User"}',
    FALSE, 'authenticated', 'authenticated',
    '', '', '', '', '', '', '', ''
)
ON CONFLICT (id) DO NOTHING;

-- handle_new_auth_user trigger has now fired for each row above,
-- creating public.profiles rows and free watchlist subscriptions automatically.


-- ============================================
-- STEP 2: UPDATE public.profiles
-- ============================================

-- Borrowers
UPDATE profiles SET
    full_name='David Mukasa', phone='+256701234567', district='Central',
    employment_type='employed', employer_name='Uganda Revenue Authority', monthly_income_ugx=4500000,
    account_status='active', credit_score=75, lender_token='L-#4821',
    created_at='2024-01-15 08:30:00'
WHERE id='10000000-0000-0000-0000-000000000001';

UPDATE profiles SET
    full_name='Sarah Namukasa', phone='+256702345678', district='Central',
    employment_type='employed', employer_name='Stanbic Bank Uganda', monthly_income_ugx=3200000,
    account_status='active', credit_score=68, lender_token='L-#3947',
    created_at='2024-01-18 10:45:00'
WHERE id='10000000-0000-0000-0000-000000000002';

UPDATE profiles SET
    full_name='James Okello', phone='+256703456789', district='Central',
    employment_type='employed', employer_name='MTN Uganda', monthly_income_ugx=5800000,
    account_status='active', credit_score=82, lender_token='L-#7263',
    created_at='2024-01-20 14:20:00'
WHERE id='10000000-0000-0000-0000-000000000003';

UPDATE profiles SET
    full_name='Maria Nakato', phone='+256704567890', district='Central',
    employment_type='self_employed', employer_name='Nakato Boutique', monthly_income_ugx=2800000,
    account_status='active', credit_score=55, lender_token='L-#5519',
    created_at='2024-01-22 09:10:00'
WHERE id='10000000-0000-0000-0000-000000000004';

UPDATE profiles SET
    full_name='Robert Ssemwanga', phone='+256705678901', district='Central',
    employment_type='employed', employer_name='DFCU Bank', monthly_income_ugx=6500000,
    account_status='active', credit_score=85, lender_token='L-#1038',
    created_at='2024-01-25 11:30:00'
WHERE id='10000000-0000-0000-0000-000000000005';

-- Lenders
UPDATE profiles SET
    full_name='Michael Semakula', phone='+256711234567', district='Central',
    employment_type='business_owner', employer_name='GreenLeaf Agro Solutions Ltd', monthly_income_ugx=15000000,
    account_status='active', credit_score=72, lender_token='L-#6641',
    created_at='2024-02-18 09:20:00'
WHERE id='10000000-0000-0000-0000-000000000006';

UPDATE profiles SET
    full_name='Sandra Namutebi', phone='+256712345678', district='Central',
    employment_type='business_owner', employer_name='Kampala Tech Innovations', monthly_income_ugx=12000000,
    account_status='active', credit_score=78, lender_token='L-#2290',
    created_at='2024-02-20 11:40:00'
WHERE id='10000000-0000-0000-0000-000000000007';

UPDATE profiles SET
    full_name='William Kasujja', phone='+256716789012', district='Central',
    employment_type='business_owner', employer_name='Pearl Capital Investment Fund', monthly_income_ugx=25000000,
    account_status='active', credit_score=91, lender_token='L-#9002',
    created_at='2024-03-01 10:10:00'
WHERE id='10000000-0000-0000-0000-000000000008';

UPDATE profiles SET
    full_name='Catherine Namboze', phone='+256717890123', district='Central',
    employment_type='business_owner', employer_name='Victoria Investment Group', monthly_income_ugx=22000000,
    account_status='active', credit_score=88, lender_token='L-#3375',
    created_at='2024-03-03 12:30:00'
WHERE id='10000000-0000-0000-0000-000000000009';

UPDATE profiles SET
    full_name='George Mulindwa', phone='+256718901234', district='Central',
    employment_type='business_owner', employer_name='Equator Finance Corporation', monthly_income_ugx=28000000,
    account_status='active', credit_score=89, lender_token='L-#7714',
    created_at='2024-03-05 09:45:00'
WHERE id='10000000-0000-0000-0000-000000000010';

-- Borrowers continued
UPDATE profiles SET
    full_name='Frank Omondi', phone='+256719012345', district='Eastern',
    employment_type='employed', employer_name='Bank of Africa', monthly_income_ugx=3300000,
    account_status='active', credit_score=42, lender_token='L-#8831',
    created_at='2024-03-08 14:15:00'
WHERE id='10000000-0000-0000-0000-000000000011';

UPDATE profiles SET
    full_name='Lucy Nambi', phone='+256720123456', district='Central',
    employment_type='employed', employer_name='National Social Security Fund', monthly_income_ugx=2900000,
    account_status='active', credit_score=60, lender_token='L-#4402',
    created_at='2024-03-10 11:20:00'
WHERE id='10000000-0000-0000-0000-000000000012';

UPDATE profiles SET
    full_name='Charles Mwesigwa', phone='+256721234567', district='Western',
    employment_type='employed', employer_name='Shell Uganda', monthly_income_ugx=5200000,
    account_status='active', credit_score=77, lender_token='L-#5566',
    created_at='2024-03-12 16:40:00'
WHERE id='10000000-0000-0000-0000-000000000013';

-- KYC-pending borrower (tests the KYC gate)
UPDATE profiles SET
    full_name='Alice Namuli', phone='+256726789012', district='Central',
    employment_type='employed', employer_name='Equity Bank', monthly_income_ugx=2700000,
    account_status='pending_verification', credit_score=50, lender_token='L-#1193',
    created_at='2026-01-25 09:15:00'
WHERE id='10000000-0000-0000-0000-000000000014';

-- Admins
UPDATE profiles SET
    full_name='Admin One', phone='+256700000001', district='Central',
    account_status='active', role='admin', credit_score=50, lender_token='L-#0001',
    created_at='2024-01-01 08:00:00'
WHERE id='10000000-0000-0000-0000-000000000015';

UPDATE profiles SET
    full_name='Admin Two', phone='+256700000002', district='Central',
    account_status='active', role='admin', credit_score=50, lender_token='L-#0002',
    created_at='2024-01-01 08:00:00'
WHERE id='10000000-0000-0000-0000-000000000016';

-- Test user
UPDATE profiles SET
    full_name='Test User', phone='+256799999999', district='Central',
    account_status='active', credit_score=50, lender_token='L-#9999',
    created_at='2026-02-06 10:00:00'
WHERE id='10000000-0000-0000-0000-000000000017';


-- ============================================
-- STEP 3: KYC VERIFICATIONS
-- expires_at set to 2027 so trg_fn_require_kyc_for_loan
-- does not raise NIPANZE_KYC_EXPIRED.
-- Alice Namuli stays 'pending' to test the KYC gate.
-- ============================================

INSERT INTO kyc_verifications (
    id, user_id, status,
    national_id_type, national_id_number,
    national_id_front_url, national_id_back_url, selfie_url,
    id_verified, selfie_verified, verified_by,
    submitted_at, reviewed_at, expires_at, created_at
) VALUES
('a1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'approved', 'national_id', 'CM88015KL234567', 'https://storage.nipanze.ug/kyc/user-001-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-001-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-001-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000015', '2024-01-15 09:15:00', '2024-01-16 10:30:00', '2027-01-15 00:00:00', '2024-01-15 09:15:00'),
('a1000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'approved', 'national_id', 'CM92022NM345678', 'https://storage.nipanze.ug/kyc/user-002-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-002-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-002-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000015', '2024-01-18 11:00:00', '2024-01-19 11:45:00', '2027-01-18 00:00:00', '2024-01-18 11:00:00'),
('a1000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'approved', 'national_id', 'CM85011OK345679', 'https://storage.nipanze.ug/kyc/user-003-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-003-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-003-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000016', '2024-01-20 14:30:00', '2024-01-21 09:30:00', '2027-01-20 00:00:00', '2024-01-20 14:30:00'),
('a1000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', 'approved', 'national_id', 'CM90014NK567890', 'https://storage.nipanze.ug/kyc/user-004-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-004-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-004-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000016', '2024-01-22 09:30:00', '2024-01-23 14:30:00', '2027-01-22 00:00:00', '2024-01-22 09:30:00'),
('a1000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000005', 'approved', 'national_id', 'CM87030SS678901', 'https://storage.nipanze.ug/kyc/user-005-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-005-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-005-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000015', '2024-01-25 11:45:00', '2024-01-25 16:00:00', '2027-01-25 00:00:00', '2024-01-25 11:45:00'),
('a1000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000006', 'approved', 'national_id', 'CM80020SM456789', 'https://storage.nipanze.ug/kyc/user-006-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-006-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-006-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000016', '2024-02-18 09:00:00', '2024-02-19 10:30:00', '2027-02-18 00:00:00', '2024-02-18 09:00:00'),
('a1000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000007', 'approved', 'national_id', 'CM83015SN789012', 'https://storage.nipanze.ug/kyc/user-007-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-007-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-007-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000015', '2024-02-20 10:00:00', '2024-02-21 11:00:00', '2027-02-20 00:00:00', '2024-02-20 10:00:00'),
('a1000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000008', 'approved', 'national_id', 'CM75018WK890123', 'https://storage.nipanze.ug/kyc/user-008-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-008-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-008-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000015', '2024-03-01 09:00:00', '2024-03-02 10:00:00', '2027-03-01 00:00:00', '2024-03-01 09:00:00'),
('a1000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000009', 'approved', 'national_id', 'CM77012CN901234', 'https://storage.nipanze.ug/kyc/user-009-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-009-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-009-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000016', '2024-03-03 11:00:00', '2024-03-04 11:00:00', '2027-03-03 00:00:00', '2024-03-03 11:00:00'),
('a1000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000010', 'approved', 'national_id', 'CM79025GM012345', 'https://storage.nipanze.ug/kyc/user-010-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-010-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-010-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000015', '2024-03-05 09:00:00', '2024-03-06 10:00:00', '2027-03-05 00:00:00', '2024-03-05 09:00:00'),
('a1000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000011', 'approved', 'national_id', 'CM91114OM789012', 'https://storage.nipanze.ug/kyc/user-011-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-011-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-011-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000016', '2024-03-08 09:30:00', '2024-03-09 14:00:00', '2027-03-08 00:00:00', '2024-03-08 09:30:00'),
('a1000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000012', 'approved', 'national_id', 'CM88047NB890123', 'https://storage.nipanze.ug/kyc/user-012-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-012-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-012-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000015', '2024-03-10 09:00:00', '2024-03-11 11:00:00', '2027-03-10 00:00:00', '2024-03-10 09:00:00'),
('a1000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000013', 'approved', 'national_id', 'CM84021MW901234', 'https://storage.nipanze.ug/kyc/user-013-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-013-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-013-selfie.jpg', TRUE,  TRUE,  '10000000-0000-0000-0000-000000000016', '2024-03-12 12:00:00', '2024-03-13 15:00:00', '2027-03-12 00:00:00', '2024-03-12 12:00:00'),
-- Alice Namuli — pending (tests KYC gate)
('a1000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000014', 'pending',  'national_id', 'CM93255NM789013', 'https://storage.nipanze.ug/kyc/user-014-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-014-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-014-selfie.jpg', FALSE, FALSE, NULL,                                          '2026-01-25 10:30:00', NULL,                  NULL,                  '2026-01-25 10:30:00')
ON CONFLICT (user_id) DO NOTHING;


-- ============================================
-- STEP 4: NEGOTIATORS
-- ============================================

INSERT INTO negotiators (
    id, full_name, phone, email, credentials, specialisation,
    status, deals_completed, avg_rating, created_at
) VALUES
('b1000000-0000-0000-0000-000000000001', 'Amos Tukahirwa',  '+256701000001', 'amos.tukahirwa@nipanze.ug',  'Licensed Attorney · KCCA No. 00123', 'Loan agreements & debt recovery',   'available', 18, 4.7, '2024-01-10 09:00:00'),
('b1000000-0000-0000-0000-000000000002', 'Phiona Nassanga', '+256701000002', 'phiona.nassanga@nipanze.ug', 'Certified Mediator · ULS No. 04521', 'Financial disputes & contract law', 'available', 12, 4.5, '2024-01-10 09:00:00'),
('b1000000-0000-0000-0000-000000000003', 'Isaac Byaruhanga','+256701000003', 'isaac.b@nipanze.ug',         'ICPAU Registered · ULS No. 07812',  'SME lending & agri-finance',        'busy',       9, 4.3, '2024-02-01 09:00:00')
ON CONFLICT DO NOTHING;


-- ============================================
-- STEP 5: SUBSCRIPTIONS
-- ============================================

-- Borrowers
UPDATE subscriptions SET plan='borrower', status='active', amount_ugx=20000,  started_at='2024-01-15 09:00:00', expires_at='2025-01-15 09:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000001';
UPDATE subscriptions SET plan='borrower', status='active', amount_ugx=20000,  started_at='2024-01-18 11:00:00', expires_at='2025-01-18 11:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000002';
UPDATE subscriptions SET plan='borrower', status='active', amount_ugx=20000,  started_at='2024-01-20 15:00:00', expires_at='2025-01-20 15:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000003';
UPDATE subscriptions SET plan='borrower', status='active', amount_ugx=20000,  started_at='2024-01-22 10:00:00', expires_at='2025-01-22 10:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000004';
UPDATE subscriptions SET plan='borrower', status='active', amount_ugx=20000,  started_at='2024-01-25 12:00:00', expires_at='2025-01-25 12:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000005';
UPDATE subscriptions SET plan='borrower', status='active', amount_ugx=20000,  started_at='2024-03-08 15:00:00', expires_at='2025-03-08 15:00:00', auto_renew=FALSE WHERE user_id='10000000-0000-0000-0000-000000000011';
UPDATE subscriptions SET plan='borrower', status='active', amount_ugx=20000,  started_at='2024-03-10 12:00:00', expires_at='2025-03-10 12:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000012';
UPDATE subscriptions SET plan='borrower', status='active', amount_ugx=20000,  started_at='2024-03-12 17:00:00', expires_at='2025-03-12 17:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000013';

-- Lenders
UPDATE subscriptions SET plan='lender', status='active', amount_ugx=35000,  started_at='2024-02-18 10:00:00', expires_at='2025-02-18 10:00:00', auto_renew=TRUE WHERE user_id='10000000-0000-0000-0000-000000000006';
UPDATE subscriptions SET plan='lender', status='active', amount_ugx=35000,  started_at='2024-02-20 12:00:00', expires_at='2025-02-20 12:00:00', auto_renew=TRUE WHERE user_id='10000000-0000-0000-0000-000000000007';
UPDATE subscriptions SET plan='pro',    status='active', amount_ugx=150000, started_at='2024-03-01 11:00:00', expires_at='2025-03-01 11:00:00', auto_renew=TRUE WHERE user_id='10000000-0000-0000-0000-000000000008';
UPDATE subscriptions SET plan='pro',    status='active', amount_ugx=150000, started_at='2024-03-03 13:00:00', expires_at='2025-03-03 13:00:00', auto_renew=TRUE WHERE user_id='10000000-0000-0000-0000-000000000009';
UPDATE subscriptions SET plan='lender', status='active', amount_ugx=35000,  started_at='2024-03-05 10:00:00', expires_at='2025-03-05 10:00:00', auto_renew=TRUE WHERE user_id='10000000-0000-0000-0000-000000000010';

-- Alice Namuli and test.user remain on free watchlist (no UPDATE needed)


-- ============================================
-- STEP 6: LOAN REQUESTS
-- FIX: Removed total_bid_amount and funding_percentage
--      (columns do not exist in schema v5.0).
-- Uses session_replication_role to bypass triggers
-- for back-dated / non-active status rows.
-- ============================================

SET session_replication_role = 'replica';

INSERT INTO loan_requests (
    id, borrower_id, title, purpose,
    requested_amount, duration_months, max_interest_rate,
    district, risk_category, credit_score_band,
    status, listed_at, expires_at, contracted_at,
    number_of_bids, views_count, created_at
) VALUES

-- David Mukasa — contracted
('c1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
 'Home Renovation Loan', 'Home improvement — kitchen and bathroom upgrade',
 5000000, 12, 12.00, 'Central', 'low', 'A', 'contracted',
 '2024-02-01 09:00:00', '2024-02-08 09:00:00', '2024-02-06 14:30:00',
 2, 87, '2024-02-01 08:45:00'),

-- Sarah Namukasa — contracted
('c1000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002',
 'Professional Certification', 'Financial management certification courses at Makerere',
 3500000, 12, 15.00, 'Central', 'medium', 'B+', 'contracted',
 '2024-03-01 10:00:00', '2024-03-08 10:00:00', '2024-03-05 11:00:00',
 1, 54, '2024-03-01 09:45:00'),

-- James Okello — active, high bid activity
('c1000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003',
 'Business Expansion — IT Equipment', 'Purchase servers and networking equipment for IT consultancy',
 8000000, 18, 10.50, 'Central', 'low', 'A+', 'active',
 '2026-01-20 10:00:00', '2026-01-27 10:00:00', NULL,
 2, 112, '2026-01-20 09:45:00'),

-- Maria Nakato — active, one bid
('c1000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004',
 'Boutique Inventory Stock', 'Pre-season stock purchase for Nakato Boutique',
 3500000, 12, 15.00, 'Central', 'medium', 'B', 'active',
 '2026-01-24 15:00:00', '2026-01-31 15:00:00', NULL,
 1, 35, '2026-01-24 14:45:00'),

-- Frank Omondi — active, high risk
('c1000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000011',
 'Medical Expense Cover', 'Surgery and recovery expenses at Mulago Hospital',
 4500000, 18, 14.50, 'Eastern', 'high', 'C', 'active',
 '2026-01-26 10:00:00', '2026-02-02 10:00:00', NULL,
 1, 41, '2026-01-26 09:45:00'),

-- Lucy Nambi — active, no bids
('c1000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000012',
 'Farm Equipment Purchase', 'Irrigation pump and tilling equipment for family farm in Wakiso',
 6000000, 24, 13.00, 'Central', 'medium', 'B', 'active',
 '2026-01-28 09:00:00', '2026-02-04 09:00:00', NULL,
 0, 18, '2026-01-28 08:45:00'),

-- Charles Mwesigwa — expired
('c1000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000013',
 'Vehicle Purchase — Delivery Van', 'Toyota Hiace for goods delivery business in Mbarara',
 9000000, 24, 11.00, 'Western', 'low', 'A', 'expired',
 '2025-12-10 11:00:00', '2025-12-17 11:00:00', NULL,
 1, 67, '2025-12-10 10:45:00'),

-- Robert Ssemwanga — active, closing soon
('c1000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000005',
 'Business Working Capital', 'Short-term working capital for DFCU supplier contracts',
 7000000, 6, 9.50, 'Central', 'low', 'A+', 'active',
 NOW() - INTERVAL '6 days 20 hours',
 NOW() + INTERVAL '4 hours',
 NULL, 1, 29, NOW() - INTERVAL '6 days 21 hours');

SET session_replication_role = 'origin';


-- ============================================
-- STEP 7: LOAN BIDS
-- ============================================

SET session_replication_role = 'replica';

INSERT INTO loan_bids (
    id, request_id, lender_id,
    amount, interest_rate, status,
    placed_at, accepted_at, created_at
) VALUES

-- David Mukasa's contracted listing
('d1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000008', 3000000, 11.00, 'accepted', '2024-02-02 10:30:00', '2024-02-06 14:30:00', '2024-02-02 10:30:00'),
('d1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000009', 2000000, 11.50, 'rejected', '2024-02-03 09:00:00', NULL,                   '2024-02-03 09:00:00'),

-- Sarah Namukasa's contracted listing
('d1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000009', 3500000, 14.00, 'accepted', '2024-03-02 11:00:00', '2024-03-05 11:00:00', '2024-03-02 11:00:00'),

-- James Okello's active listing — live order book
('d1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 5000000, 10.00, 'pending', '2026-01-21 11:20:00', NULL, '2026-01-21 11:20:00'),
('d1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000010', 3000000, 10.50, 'pending', '2026-01-23 13:15:00', NULL, '2026-01-23 13:15:00'),

-- Maria Nakato's active listing
('d1000000-0000-0000-0000-000000000006', 'c1000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000006', 1500000, 14.00, 'pending', '2026-01-27 10:30:00', NULL, '2026-01-27 10:30:00'),

-- Frank Omondi's active listing
('d1000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000007', 2000000, 14.50, 'pending', '2026-01-28 09:15:00', NULL, '2026-01-28 09:15:00'),

-- Charles Mwesigwa's expired listing
('d1000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000006', 4000000, 10.50, 'expired', '2025-12-11 10:00:00', NULL, '2025-12-11 10:00:00'),

-- Robert Ssemwanga's closing-soon listing
('d1000000-0000-0000-0000-000000000009', 'c1000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000010', 3000000,  9.50, 'pending', NOW() - INTERVAL '2 hours', NULL, NOW() - INTERVAL '2 hours');

SET session_replication_role = 'origin';


-- ============================================
-- STEP 8: CONTRACTS
-- FIX: Uses indicative_* column names from schema v5.0.
--      Removed outstanding_balance, total_repaid, days_overdue
--      (not in schema). Added borrower_confirmed_at / lender_confirmed_at.
-- ============================================

-- Contract 1: David Mukasa ↔ Pearl Capital (in_execution)
INSERT INTO contracts (
    id, request_id, bid_id,
    borrower_id, lender_id, negotiator_id,
    status, amount, interest_rate, duration_months,
    purpose, district,
    indicative_monthly_payment_ugx,
    indicative_total_repayment_ugx,
    indicative_total_interest_ugx,
    repayment_start_date, maturity_date,
    borrower_confirmed, borrower_confirmed_at,
    lender_confirmed,   lender_confirmed_at,
    contract_activated_at, created_at
) VALUES (
    'e1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001',
    'd1000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000008',
    'b1000000-0000-0000-0000-000000000001',
    'in_execution',
    3000000, 11.00, 12,
    'Home Renovation Loan', 'Central',
    265000, 3180000, 180000,
    '2024-03-01', '2025-02-01',
    TRUE, '2024-02-09 10:00:00',
    TRUE, '2024-02-09 14:00:00',
    '2024-02-10 09:00:00', '2024-02-06 14:30:00'
);

-- Contract 2: Sarah Namukasa ↔ Victoria Investment (draft)
INSERT INTO contracts (
    id, request_id, bid_id,
    borrower_id, lender_id, negotiator_id,
    status, amount, interest_rate, duration_months,
    purpose, district,
    indicative_monthly_payment_ugx,
    indicative_total_repayment_ugx,
    indicative_total_interest_ugx,
    borrower_confirmed, lender_confirmed,
    created_at
) VALUES (
    'e1000000-0000-0000-0000-000000000002',
    'c1000000-0000-0000-0000-000000000002',
    'd1000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000009',
    'b1000000-0000-0000-0000-000000000002',
    'draft',
    3500000, 14.00, 12,
    'Professional Certification', 'Central',
    314000, 3768000, 268000,
    FALSE, FALSE,
    '2024-03-05 11:00:00'
);


-- ============================================
-- STEP 8b: NEGOTIATOR ASSIGNMENTS
-- ============================================

INSERT INTO negotiator_assignments (id, contract_id, negotiator_id, assigned_at) VALUES
('e1000000-0000-0000-0000-000000000003', 'e1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', '2024-02-06 15:00:00'),
('e1000000-0000-0000-0000-000000000004', 'e1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000002', '2024-03-05 11:30:00');


-- ============================================
-- STEP 8c: REPAYMENT SCHEDULES
-- FIX: Removed amount_due, amount_paid, paid_at, days_late.
--      Only columns in schema: contract_id, instalment_number,
--      due_date, principal_ugx, interest_ugx,
--      reported_status, reported_at, reported_by, created_at.
--      total_ugx is a generated column — omit from INSERT.
-- ============================================

INSERT INTO repayment_schedules (
    id, contract_id, instalment_number, due_date,
    principal_ugx, interest_ugx,
    reported_status, reported_at, reported_by,
    created_at
) VALUES
('e2000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000001',  1, '2024-03-01', 237500, 27500, 'reported_paid', '2024-03-01 09:00:00', '10000000-0000-0000-0000-000000000001', '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000002', 'e1000000-0000-0000-0000-000000000001',  2, '2024-04-01', 239700, 25300, 'reported_paid', '2024-04-01 10:00:00', '10000000-0000-0000-0000-000000000001', '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000003', 'e1000000-0000-0000-0000-000000000001',  3, '2024-05-01', 241900, 23100, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000004', 'e1000000-0000-0000-0000-000000000001',  4, '2024-06-01', 244100, 20900, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000005', 'e1000000-0000-0000-0000-000000000001',  5, '2024-07-01', 246400, 18600, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000006', 'e1000000-0000-0000-0000-000000000001',  6, '2024-08-01', 248700, 16300, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000007', 'e1000000-0000-0000-0000-000000000001',  7, '2024-09-01', 251000, 14000, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000008', 'e1000000-0000-0000-0000-000000000001',  8, '2024-10-01', 253300, 11700, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000009', 'e1000000-0000-0000-0000-000000000001',  9, '2024-11-01', 255700,  9300, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000010', 'e1000000-0000-0000-0000-000000000001', 10, '2024-12-01', 258100,  6900, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000011', 'e1000000-0000-0000-0000-000000000001', 11, '2025-01-01', 260500,  4500, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00'),
('e2000000-0000-0000-0000-000000000012', 'e1000000-0000-0000-0000-000000000001', 12, '2025-02-01', 262800,  2200, 'pending',       NULL,                  NULL,                                   '2024-02-10 09:00:00');


-- ============================================
-- STEP 9: WATCHLIST
-- ============================================

INSERT INTO watchlist (id, user_id, request_id, added_at) VALUES
('e3000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000003', '2026-01-21 08:00:00'),
('e3000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000005', '2026-01-26 11:00:00'),
('e3000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000009', 'c1000000-0000-0000-0000-000000000004', '2026-01-25 14:00:00'),
('e3000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000008', NOW() - INTERVAL '3 hours'),
('e3000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000012', 'c1000000-0000-0000-0000-000000000003', '2026-01-22 10:00:00')
ON CONFLICT (user_id, request_id) DO NOTHING;


-- ============================================
-- STEP 10: NOTIFICATIONS
-- FIX: 'repayment_due' is not in notification_type_enum.
--      Replaced with 'system'.
-- ============================================

INSERT INTO notifications (
    id, user_id, type, title, body,
    is_read, request_id, contract_id, bid_id, created_at
) VALUES
('e4000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'bid_accepted',            'Bid accepted',             'Your listing has been matched. A negotiator has been assigned.',      TRUE,  'c1000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', '2024-02-06 14:31:00'),
('e4000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000008', 'bid_accepted',            'Your bid was accepted',    'Your offer has been accepted. A negotiator will be in touch.',        TRUE,  'c1000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', '2024-02-06 14:31:00'),
('e4000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'negotiator_assigned',     'Negotiator assigned',      'Amos Tukahirwa has been assigned to facilitate your deal.',           TRUE,  NULL,                                   'e1000000-0000-0000-0000-000000000001', NULL,                                   '2024-02-06 15:00:00'),
('e4000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000008', 'negotiator_assigned',     'Negotiator assigned',      'Amos Tukahirwa has been assigned to facilitate your deal.',           TRUE,  NULL,                                   'e1000000-0000-0000-0000-000000000001', NULL,                                   '2024-02-06 15:00:00'),
('e4000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', 'contract_draft_available','Contract draft ready',     'Your contract draft is available for review. Please confirm.',       FALSE, NULL,                                   'e1000000-0000-0000-0000-000000000002', NULL,                                   '2024-03-05 12:00:00'),
('e4000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000009', 'contract_draft_available','Contract draft ready',     'Your contract draft is available for review. Please confirm.',       FALSE, NULL,                                   'e1000000-0000-0000-0000-000000000002', NULL,                                   '2024-03-05 12:00:00'),
('e4000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000003', 'bid_received',            'New bid received',         'Pearl Capital (L-#9002) placed a bid at 10.00% on your listing.',    FALSE, 'c1000000-0000-0000-0000-000000000003', NULL,                                   'd1000000-0000-0000-0000-000000000004', '2026-01-21 11:21:00'),
('e4000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000003', 'bid_received',            'New bid received',         'Equator Finance (L-#7714) placed a bid at 10.50% on your listing.',  FALSE, 'c1000000-0000-0000-0000-000000000003', NULL,                                   'd1000000-0000-0000-0000-000000000005', '2026-01-23 13:16:00'),
('e4000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000005', 'closing_soon_6h',         'Listing closing soon',     'Your listing "Business Working Capital" closes in under 6 hours.',   FALSE, 'c1000000-0000-0000-0000-000000000008', NULL,                                   NULL,                                   NOW() - INTERVAL '1 hour'),
-- FIX: was 'repayment_due' (not in enum) → replaced with 'system'
('e4000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000001', 'system',                  'Repayment due soon',       'Instalment 3 of UGX 265,000 is due on 1 May 2024.',                  FALSE, NULL,                                   'e1000000-0000-0000-0000-000000000001', NULL,                                   '2024-04-25 08:00:00')
ON CONFLICT DO NOTHING;


-- ============================================
-- STEP 11: REFERRALS
-- ============================================

INSERT INTO referrals (
    id, referrer_id, referred_email, referred_user_id,
    code, is_activated, activated_at, reward_applied, created_at
) VALUES
('e5000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'frank.omondi@gmail.com',     '10000000-0000-0000-0000-000000000011', 'NIP-DAVID-01', TRUE,  '2024-03-08 15:00:00', TRUE,  '2024-03-01 10:00:00'),
('e5000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000008', 'lucy.nambi@yahoo.com',       '10000000-0000-0000-0000-000000000012', 'NIP-PEARL-01', TRUE,  '2024-03-10 12:00:00', TRUE,  '2024-03-05 09:00:00'),
('e5000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'charles.mwesigwa@gmail.com', '10000000-0000-0000-0000-000000000013', 'NIP-JAMES-01', TRUE,  '2024-03-12 17:00:00', FALSE, '2024-03-08 11:00:00'),
('e5000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', 'newuser@example.com',        NULL,                                   'NIP-DAVID-02', FALSE, NULL,                  FALSE, '2026-01-20 09:00:00')
ON CONFLICT DO NOTHING;


-- ============================================
-- VERIFICATION
-- ============================================

SELECT table_name, record_count FROM (
    SELECT 'auth.users'             AS table_name, COUNT(*) AS record_count FROM auth.users             WHERE id::text LIKE '10000000%'
    UNION ALL SELECT 'profiles',                   COUNT(*) FROM profiles                                WHERE id::text LIKE '10000000%'
    UNION ALL SELECT 'subscriptions',              COUNT(*) FROM subscriptions
    UNION ALL SELECT 'kyc_verifications',          COUNT(*) FROM kyc_verifications
    UNION ALL SELECT 'negotiators',                COUNT(*) FROM negotiators
    UNION ALL SELECT 'loan_requests',              COUNT(*) FROM loan_requests
    UNION ALL SELECT 'loan_bids',                  COUNT(*) FROM loan_bids
    UNION ALL SELECT 'contracts',                  COUNT(*) FROM contracts
    UNION ALL SELECT 'negotiator_assignments',     COUNT(*) FROM negotiator_assignments
    UNION ALL SELECT 'repayment_schedules',        COUNT(*) FROM repayment_schedules
    UNION ALL SELECT 'watchlist',                  COUNT(*) FROM watchlist
    UNION ALL SELECT 'notifications',              COUNT(*) FROM notifications
    UNION ALL SELECT 'referrals',                  COUNT(*) FROM referrals
) t ORDER BY table_name;


SELECT p.full_name, au.email, au.email_confirmed_at IS NOT NULL AS confirmed,
       p.account_status, p.role, p.credit_score, p.reputation_tier
FROM profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE p.id::text LIKE '10000000%'
ORDER BY p.created_at;


SELECT au.email, s.plan, s.status, s.expires_at
FROM subscriptions s
JOIN profiles p ON p.id = s.user_id
JOIN auth.users au ON au.id = p.id
WHERE s.status = 'active'
ORDER BY s.plan, au.email;


SELECT lr.title, lr.district, lr.risk_category, lr.requested_amount,
       lr.number_of_bids, lr.status, lr.expires_at,
       (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon
FROM loan_requests lr
WHERE lr.status = 'active'
ORDER BY lr.listed_at DESC;


SELECT '✅ Nipanze seed v1.2 inserted successfully' AS status;