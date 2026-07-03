-- ============================================
-- NIPANZE Seed Data
-- Version: 2.0 (Schema v4.0 Aligned)
-- ============================================
--
-- Aligned to schema v4.0:
--   • profiles: removed credit_score, reputation_tier, lender_token
--   • subscriptions: borrower plan removed — borrowing is free (plan = 'free')
--   • loan_requests: removed max_interest_rate, risk_category, credit_score_band
--     Added: income_source, preferred_repayment_plan,
--            repayment_amount_per_period, repayment_timeline
--   • loan_bids → loan_offers: offer_amount, proposed_expectations
--   • negotiators, contracts, repayment_schedules,
--     negotiator_assignments removed (not in schema v4.0)
--   • contact_reveals added (tied to offer_id, not contract_id)
--   • notifications: bid_id → offer_id; updated enum values
--   • Notification types aligned to v4.0 enum
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
-- creating public.profiles rows and free subscriptions automatically.


-- ============================================
-- STEP 2: UPDATE public.profiles
-- NOTE: credit_score, reputation_tier, lender_token removed in v4.0.
-- ============================================

-- Borrowers
UPDATE profiles SET
    full_name='David Mukasa', phone='+256701234567', district='Central',
    employment_type='government_employee', employer_name='Uganda Revenue Authority',
    monthly_income_ugx=4500000, account_status='active',
    created_at='2024-01-15 08:30:00'
WHERE id='10000000-0000-0000-0000-000000000001';

UPDATE profiles SET
    full_name='Sarah Namukasa', phone='+256702345678', district='Central',
    employment_type='employed', employer_name='Stanbic Bank Uganda',
    monthly_income_ugx=3200000, account_status='active',
    created_at='2024-01-18 10:45:00'
WHERE id='10000000-0000-0000-0000-000000000002';

UPDATE profiles SET
    full_name='James Okello', phone='+256703456789', district='Central',
    employment_type='employed', employer_name='MTN Uganda',
    monthly_income_ugx=5800000, account_status='active',
    created_at='2024-01-20 14:20:00'
WHERE id='10000000-0000-0000-0000-000000000003';

UPDATE profiles SET
    full_name='Maria Nakato', phone='+256704567890', district='Central',
    employment_type='small_business_owner', employer_name='Nakato Boutique',
    monthly_income_ugx=2800000, account_status='active',
    created_at='2024-01-22 09:10:00'
WHERE id='10000000-0000-0000-0000-000000000004';

UPDATE profiles SET
    full_name='Robert Ssemwanga', phone='+256705678901', district='Central',
    employment_type='employed', employer_name='DFCU Bank',
    monthly_income_ugx=6500000, account_status='active',
    created_at='2024-01-25 11:30:00'
WHERE id='10000000-0000-0000-0000-000000000005';

-- Lenders
UPDATE profiles SET
    full_name='Michael Semakula', phone='+256711234567', district='Central',
    employment_type='business_owner', employer_name='GreenLeaf Agro Solutions Ltd',
    monthly_income_ugx=15000000, account_status='active',
    created_at='2024-02-18 09:20:00'
WHERE id='10000000-0000-0000-0000-000000000006';

UPDATE profiles SET
    full_name='Sandra Namutebi', phone='+256712345678', district='Central',
    employment_type='business_owner', employer_name='Kampala Tech Innovations',
    monthly_income_ugx=12000000, account_status='active',
    created_at='2024-02-20 11:40:00'
WHERE id='10000000-0000-0000-0000-000000000007';

UPDATE profiles SET
    full_name='William Kasujja', phone='+256716789012', district='Central',
    employment_type='business_owner', employer_name='Pearl Capital Investment Fund',
    monthly_income_ugx=25000000, account_status='active',
    created_at='2024-03-01 10:10:00'
WHERE id='10000000-0000-0000-0000-000000000008';

UPDATE profiles SET
    full_name='Catherine Namboze', phone='+256717890123', district='Central',
    employment_type='business_owner', employer_name='Victoria Investment Group',
    monthly_income_ugx=22000000, account_status='active',
    created_at='2024-03-03 12:30:00'
WHERE id='10000000-0000-0000-0000-000000000009';

UPDATE profiles SET
    full_name='George Mulindwa', phone='+256718901234', district='Central',
    employment_type='business_owner', employer_name='Equator Finance Corporation',
    monthly_income_ugx=28000000, account_status='active',
    created_at='2024-03-05 09:45:00'
WHERE id='10000000-0000-0000-0000-000000000010';

-- Borrowers continued
UPDATE profiles SET
    full_name='Frank Omondi', phone='+256719012345', district='Eastern',
    employment_type='employed', employer_name='Bank of Africa',
    monthly_income_ugx=3300000, account_status='active',
    created_at='2024-03-08 14:15:00'
WHERE id='10000000-0000-0000-0000-000000000011';

UPDATE profiles SET
    full_name='Lucy Nambi', phone='+256720123456', district='Central',
    employment_type='employed', employer_name='National Social Security Fund',
    monthly_income_ugx=2900000, account_status='active',
    created_at='2024-03-10 11:20:00'
WHERE id='10000000-0000-0000-0000-000000000012';

UPDATE profiles SET
    full_name='Charles Mwesigwa', phone='+256721234567', district='Western',
    employment_type='employed', employer_name='Shell Uganda',
    monthly_income_ugx=5200000, account_status='active',
    created_at='2024-03-12 16:40:00'
WHERE id='10000000-0000-0000-0000-000000000013';

-- Alice Namuli — pending_verification (tests the account-status gate)
UPDATE profiles SET
    full_name='Alice Namuli', phone='+256726789012', district='Central',
    employment_type='employed', employer_name='Equity Bank',
    monthly_income_ugx=2700000, account_status='pending_verification',
    created_at='2026-01-25 09:15:00'
WHERE id='10000000-0000-0000-0000-000000000014';

-- Admins
UPDATE profiles SET
    full_name='Admin One', phone='+256700000001', district='Central',
    account_status='active', role='admin',
    created_at='2024-01-01 08:00:00'
WHERE id='10000000-0000-0000-0000-000000000015';

UPDATE profiles SET
    full_name='Admin Two', phone='+256700000002', district='Central',
    account_status='active', role='admin',
    created_at='2024-01-01 08:00:00'
WHERE id='10000000-0000-0000-0000-000000000016';

-- Test user — no profile edits; tests onboarding gate
UPDATE profiles SET
    full_name='Test User', phone='+256799999999', district='Central',
    account_status='active',
    created_at='2026-02-06 10:00:00'
WHERE id='10000000-0000-0000-0000-000000000017';


-- ============================================
-- STEP 3: KYC VERIFICATIONS
-- Optional verification — not required to post a request.
-- Alice Namuli stays 'pending' to test the KYC badge flow.
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
-- Alice Namuli — pending (tests KYC badge; she can still post requests since KYC is optional)
('a1000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000014', 'pending',  'national_id', 'CM93255NM789013', 'https://storage.nipanze.ug/kyc/user-014-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-014-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-014-selfie.jpg', FALSE, FALSE, NULL, '2026-01-25 10:30:00', NULL, NULL, '2026-01-25 10:30:00')
ON CONFLICT (user_id) DO NOTHING;


-- ============================================
-- STEP 4: SUBSCRIPTIONS
-- Free plan = browse marketplace + post requests (no cost).
-- Lender / Pro plan required to make offers.
-- Borrowers stay on the auto-provisioned 'free' plan — no update needed.
-- Lenders are upgraded to 'lender' or 'pro'.
-- ============================================

-- Lenders — upgrade from free to lender/pro
UPDATE subscriptions SET plan='lender', status='active', amount_ugx=35000,  started_at='2024-02-18 10:00:00', expires_at='2025-02-18 10:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000006';
UPDATE subscriptions SET plan='lender', status='active', amount_ugx=35000,  started_at='2024-02-20 12:00:00', expires_at='2025-02-20 12:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000007';
UPDATE subscriptions SET plan='pro',    status='active', amount_ugx=150000, started_at='2024-03-01 11:00:00', expires_at='2025-03-01 11:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000008';
UPDATE subscriptions SET plan='pro',    status='active', amount_ugx=150000, started_at='2024-03-03 13:00:00', expires_at='2025-03-03 13:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000009';
UPDATE subscriptions SET plan='lender', status='active', amount_ugx=35000,  started_at='2024-03-05 10:00:00', expires_at='2025-03-05 10:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000010';

-- James Okello acts as both borrower and lender — upgrade to pro
UPDATE subscriptions SET plan='pro',    status='active', amount_ugx=150000, started_at='2024-01-20 15:00:00', expires_at='2025-01-20 15:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000003';

-- Robert Ssemwanga acts as both — upgrade to lender
UPDATE subscriptions SET plan='lender', status='active', amount_ugx=35000,  started_at='2024-01-25 12:00:00', expires_at='2025-01-25 12:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000005';

-- All remaining borrowers (001, 002, 004, 011, 012, 013, 014, 017)
-- stay on the auto-provisioned free plan. No update required.


-- ============================================
-- STEP 5: LOAN REQUESTS
-- Triggers bypassed via session_replication_role for back-dated /
-- non-active rows. Active rows use future expires_at values.
-- New columns: income_source, preferred_repayment_plan,
--              repayment_amount_per_period, repayment_timeline
-- Removed: max_interest_rate, risk_category, credit_score_band
-- ============================================

SET session_replication_role = 'replica';

INSERT INTO loan_requests (
    id, borrower_id,
    title, purpose,
    requested_amount, duration_months,
    income_source,
    preferred_repayment_plan,
    repayment_amount_per_period,
    repayment_timeline,
    district,
    status, listed_at, expires_at, contracted_at,
    number_of_offers, views_count, created_at
) VALUES

-- David Mukasa — contracted (offer accepted, contact revealed)
('c1000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000001',
 'Home Renovation Loan',
 'Kitchen and bathroom upgrade at family home in Kampala',
 5000000, 12,
 'Salary — UGX 4,500,000',
 'Monthly instalments',
 450000,
 '12 months starting March 2024',
 'Central',
 'contracted', '2024-02-01 09:00:00', NOW() + INTERVAL '10 days', '2024-02-06 14:30:00',
 2, 87, '2024-02-01 08:45:00'),

-- Sarah Namukasa — contracted (offer accepted, contact pending reveal)
('c1000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000002',
 'Professional Certification',
 'Financial management certification at Makerere University Business School',
 3500000, 12,
 'Salary — UGX 3,200,000',
 'Monthly instalments',
 320000,
 '12 months starting April 2024',
 'Central',
 'contracted', '2024-03-01 10:00:00', NOW() + INTERVAL '12 days', '2024-03-05 11:00:00',
 1, 54, '2024-03-01 09:45:00'),

-- James Okello — active, three pending offers (full + partial)
('c1000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000003',
 'Business Expansion — IT Equipment',
 'Purchase servers and networking equipment for growing IT consultancy',
 8000000, 18,
 'Salary — UGX 5,800,000',
 'Monthly instalments',
 500000,
 '18 months starting February 2026',
 'Central',
 'active',
 NOW() - INTERVAL '2 days', NOW() + INTERVAL '15 days', NULL,
 3, 112, NOW() - INTERVAL '2 days 15 minutes'),

-- Maria Nakato — active, one pending offer
('c1000000-0000-0000-0000-000000000004',
 '10000000-0000-0000-0000-000000000004',
 'Boutique Inventory Stock',
 'Pre-season clothing stock purchase for Nakato Boutique ahead of Easter season',
 3500000, 12,
 'Business income — UGX 2,800,000',
 'Monthly instalments',
 320000,
 '12 months starting February 2026',
 'Central',
 'active',
 NOW() - INTERVAL '3 days', NOW() + INTERVAL '14 days', NULL,
 1, 35, NOW() - INTERVAL '3 days 15 minutes'),

-- Frank Omondi — active, one pending offer
('c1000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000011',
 'Medical Expense Cover',
 'Surgery and recovery costs at Mulago National Referral Hospital',
 4500000, 18,
 'Salary — UGX 3,300,000',
 'Monthly instalments',
 280000,
 '18 months starting February 2026',
 'Eastern',
 'active',
 NOW() - INTERVAL '1 day', NOW() + INTERVAL '16 days', NULL,
 1, 41, NOW() - INTERVAL '1 day 15 minutes'),

-- Lucy Nambi — active, three pending offers (full + partial)
('c1000000-0000-0000-0000-000000000006',
 '10000000-0000-0000-0000-000000000012',
 'Farm Equipment Purchase',
 'Irrigation pump and tilling equipment for family farm in Wakiso district',
 6000000, 24,
 'Salary — UGX 2,900,000',
 'Monthly instalments',
 280000,
 '24 months starting February 2026',
 'Central',
 'active',
 NOW() - INTERVAL '4 days', NOW() + INTERVAL '13 days', NULL,
 3, 18, NOW() - INTERVAL '4 days 15 minutes'),

-- Charles Mwesigwa — active (converted from expired), three pending offers
('c1000000-0000-0000-0000-000000000007',
 '10000000-0000-0000-0000-000000000013',
 'Vehicle Purchase — Delivery Van',
 'Toyota Hiace for goods delivery business serving Mbarara and Kampala',
 9000000, 24,
 'Salary — UGX 5,200,000',
 'Monthly instalments',
 420000,
 '24 months starting January 2026',
 'Western',
 'active', NOW() - INTERVAL '5 days', NOW() + INTERVAL '15 days', NULL,
 3, 67, NOW() - INTERVAL '5 days 15 minutes'),

-- Robert Ssemwanga — active (expires in 14 days), two pending offers
('c1000000-0000-0000-0000-000000000008',
 '10000000-0000-0000-0000-000000000005',
 'Business Working Capital',
 'Short-term working capital to fulfil supplier contracts at DFCU Bank',
 7000000, 6,
 'Salary — UGX 6,500,000',
 'Monthly instalments',
 1200000,
 '6 months starting February 2026',
 'Central',
 'active',
 NOW() - INTERVAL '6 days 20 hours',
 NOW() + INTERVAL '14 days',
 NULL, 2, 29, NOW() - INTERVAL '6 days 21 hours');

SET session_replication_role = 'origin';


-- ============================================
-- STEP 6: LOAN OFFERS
-- Replaces loan_bids. Columns: offer_amount, proposed_expectations.
-- Bypasses triggers for historical/non-active rows.
-- ============================================

SET session_replication_role = 'replica';

INSERT INTO loan_offers (
    id, request_id, lender_id,
    offer_amount, proposed_expectations,
    status, offered_at, accepted_at, created_at
) VALUES

-- David Mukasa's contracted listing — two offers, one accepted
('d1000000-0000-0000-0000-000000000001',
 'c1000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000008',
 5000000,
 'I can provide the full amount at 11% per annum. Monthly instalments work for me.',
 'accepted', '2024-02-02 10:30:00', '2024-02-06 14:30:00', '2024-02-02 10:30:00'),

('d1000000-0000-0000-0000-000000000002',
 'c1000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000009',
 5000000,
 'Happy to lend the full amount. Expecting 11.5% per annum with monthly repayments.',
 'rejected', '2024-02-03 09:00:00', NULL, '2024-02-03 09:00:00'),

-- Sarah Namukasa's contracted listing — one offer, accepted
('d1000000-0000-0000-0000-000000000003',
 'c1000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000009',
 3500000,
 'Willing to fund the full amount at 14% per annum. Monthly repayments as proposed.',
 'accepted', '2024-03-02 11:00:00', '2024-03-05 11:00:00', '2024-03-02 11:00:00'),

-- James Okello's active listing — two pending offers
('d1000000-0000-0000-0000-000000000004',
 'c1000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000008',
 8000000,
 'Can cover the full amount at 10% per annum. Happy with 18-month monthly instalments.',
 'pending', '2026-01-21 11:20:00', NULL, '2026-01-21 11:20:00'),

('d1000000-0000-0000-0000-000000000005',
 'c1000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000010',
 8000000,
 'Offering full amount at 10.5% per annum. Monthly instalments over 18 months.',
 'pending', '2026-01-23 13:15:00', NULL, '2026-01-23 13:15:00'),

('d1000000-0000-0000-0000-000000000010',
 'c1000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000009',
 3000000,
 'Can contribute UGX 3M toward the equipment purchase at 9.5% per annum, repayable monthly.',
 'pending', '2026-01-24 08:40:00', NULL, '2026-01-24 08:40:00'),

-- Maria Nakato's active listing — one pending offer
('d1000000-0000-0000-0000-000000000006',
 'c1000000-0000-0000-0000-000000000004',
 '10000000-0000-0000-0000-000000000006',
 3500000,
 'Can fund the full requested amount at 14% per annum. Monthly repayments as stated.',
 'pending', '2026-01-27 10:30:00', NULL, '2026-01-27 10:30:00'),

-- Frank Omondi's active listing — one pending offer
('d1000000-0000-0000-0000-000000000007',
 'c1000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000007',
 4500000,
 'Prepared to lend the full amount at 14.5% per annum given the medical urgency.',
 'pending', '2026-01-28 09:15:00', NULL, '2026-01-28 09:15:00'),

-- Lucy Nambi's active listing — multiple pending offers (partial + full)
('d1000000-0000-0000-0000-000000000011',
 'c1000000-0000-0000-0000-000000000006',
 '10000000-0000-0000-0000-000000000006',
 3000000,
 'Can fund UGX 3M now for the pump purchase. Comfortable with the 24-month repayment timeline.',
 'pending', NOW() - INTERVAL '3 days 7 hours', NULL, NOW() - INTERVAL '3 days 7 hours'),

('d1000000-0000-0000-0000-000000000012',
 'c1000000-0000-0000-0000-000000000006',
 '10000000-0000-0000-0000-000000000008',
 6000000,
 'Can fund the full equipment amount if repayments begin as proposed in February.',
 'pending', NOW() - INTERVAL '2 days 18 hours', NULL, NOW() - INTERVAL '2 days 18 hours'),

('d1000000-0000-0000-0000-000000000013',
 'c1000000-0000-0000-0000-000000000006',
 '10000000-0000-0000-0000-000000000010',
 4000000,
 'Can cover UGX 4M for the tilling equipment, with monthly payments over 24 months.',
 'pending', NOW() - INTERVAL '1 day 9 hours', NULL, NOW() - INTERVAL '1 day 9 hours'),

-- Charles Mwesigwa's active listing — multiple pending offers (partial + full)
('d1000000-0000-0000-0000-000000000008',
 'c1000000-0000-0000-0000-000000000007',
 '10000000-0000-0000-0000-000000000006',
 9000000,
 'Happy to fund the full van purchase. Expecting 11% per annum over 24 months.',
 'pending', NOW() - INTERVAL '4 days 23 hours', NULL, NOW() - INTERVAL '4 days 23 hours'),

('d1000000-0000-0000-0000-000000000014',
 'c1000000-0000-0000-0000-000000000007',
 '10000000-0000-0000-0000-000000000008',
 3000000,
 'Can offer UGX 3M as partial funding for the van deposit and initial repairs.',
 'pending', NOW() - INTERVAL '3 days 12 hours', NULL, NOW() - INTERVAL '3 days 12 hours'),

('d1000000-0000-0000-0000-000000000015',
 'c1000000-0000-0000-0000-000000000007',
 '10000000-0000-0000-0000-000000000009',
 5000000,
 'Can fund UGX 5M toward the van purchase with slightly faster monthly repayment preferred.',
 'pending', NOW() - INTERVAL '2 days 6 hours', NULL, NOW() - INTERVAL '2 days 6 hours'),

-- Robert Ssemwanga's closing-soon listing — two pending offers
('d1000000-0000-0000-0000-000000000009',
 'c1000000-0000-0000-0000-000000000008',
 '10000000-0000-0000-0000-000000000010',
 7000000,
 'Can provide full working capital at 9.5% per annum. Six monthly repayments.',
 'pending', NOW() - INTERVAL '2 hours', NULL, NOW() - INTERVAL '2 hours'),

('d1000000-0000-0000-0000-000000000016',
 'c1000000-0000-0000-0000-000000000008',
 '10000000-0000-0000-0000-000000000008',
 3000000,
 'Can cover UGX 3M of the working capital need if the supplier contract is confirmed.',
 'pending', NOW() - INTERVAL '45 minutes', NULL, NOW() - INTERVAL '45 minutes');

SET session_replication_role = 'origin';


-- ============================================
-- STEP 7: CONTACT REVEALS
-- Created only for accepted offers.
-- David Mukasa's deal: revealed (both parties connected).
-- Sarah Namukasa's deal: pending (borrower has not yet triggered reveal).
-- ============================================

INSERT INTO contact_reveals (
    id, offer_id, request_id, revealed_by,
    status, revealed_at, created_at
) VALUES
-- David Mukasa accepted Pearl Capital's offer — contact revealed
('f1000000-0000-0000-0000-000000000001',
 'd1000000-0000-0000-0000-000000000001',
 'c1000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000001',
 'revealed', '2024-02-07 10:00:00', '2024-02-06 14:31:00'),

-- Sarah Namukasa accepted Victoria's offer — reveal pending
('f1000000-0000-0000-0000-000000000002',
 'd1000000-0000-0000-0000-000000000003',
 'c1000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000002',
 'pending', NULL, '2024-03-05 11:01:00')
ON CONFLICT (offer_id) DO NOTHING;


-- ============================================
-- STEP 8: WATCHLIST
-- ============================================

INSERT INTO watchlist (id, user_id, request_id, added_at) VALUES
('e3000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000003', '2026-01-21 08:00:00'),
('e3000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000005', '2026-01-26 11:00:00'),
('e3000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000009', 'c1000000-0000-0000-0000-000000000004', '2026-01-25 14:00:00'),
('e3000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000008', NOW() - INTERVAL '3 hours'),
('e3000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000012', 'c1000000-0000-0000-0000-000000000003', '2026-01-22 10:00:00')
ON CONFLICT (user_id, request_id) DO NOTHING;


-- ============================================
-- STEP 9: NOTIFICATIONS
-- Columns aligned to v4.0: offer_id replaces bid_id.
-- No contract_id (contracts table removed).
-- Enum values aligned to notification_type_enum v4.0.
-- ============================================

INSERT INTO notifications (
    id, user_id, type, title, body,
    is_read, request_id, offer_id, created_at
) VALUES

-- David Mukasa — offer accepted, contact revealed
('e4000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000001',
 'offer_accepted', 'Offer accepted',
 'You accepted Pearl Capital''s offer. Contact details have been shared.',
 TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001',
 '2024-02-06 14:31:00'),

('e4000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000008',
 'offer_accepted', 'Your offer was accepted',
 'David Mukasa accepted your offer. Contact details have been shared.',
 TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001',
 '2024-02-06 14:31:00'),

('e4000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000001',
 'contact_revealed', 'Contact details revealed',
 'You can now connect with Pearl Capital Investment Fund directly.',
 TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001',
 '2024-02-07 10:00:00'),

('e4000000-0000-0000-0000-000000000004',
 '10000000-0000-0000-0000-000000000008',
 'contact_revealed', 'Contact details revealed',
 'The borrower has revealed contact details. You can now connect directly.',
 TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001',
 '2024-02-07 10:00:00'),

-- Sarah Namukasa — offer accepted, contact pending reveal
('e4000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000002',
 'offer_accepted', 'Offer accepted',
 'You accepted Victoria Investment Group''s offer. Reveal contact details to connect.',
 FALSE, 'c1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000003',
 '2024-03-05 11:01:00'),

('e4000000-0000-0000-0000-000000000006',
 '10000000-0000-0000-0000-000000000009',
 'offer_accepted', 'Your offer was accepted',
 'Sarah Namukasa accepted your offer. Waiting for contact details to be revealed.',
 FALSE, 'c1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000003',
 '2024-03-05 11:01:00'),

-- James Okello — two offers received on active listing
('e4000000-0000-0000-0000-000000000007',
 '10000000-0000-0000-0000-000000000003',
 'offer_received', 'New offer received',
 'Pearl Capital Investment Fund made an offer on your listing.',
 FALSE, 'c1000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000004',
 '2026-01-21 11:21:00'),

('e4000000-0000-0000-0000-000000000008',
 '10000000-0000-0000-0000-000000000003',
 'offer_received', 'New offer received',
 'Equator Finance Corporation made an offer on your listing.',
 FALSE, 'c1000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000005',
 '2026-01-23 13:16:00'),

-- Maria Nakato — one offer received
('e4000000-0000-0000-0000-000000000009',
 '10000000-0000-0000-0000-000000000004',
 'offer_received', 'New offer received',
 'GreenLeaf Agro Solutions made an offer on your listing.',
 FALSE, 'c1000000-0000-0000-0000-000000000004', 'd1000000-0000-0000-0000-000000000006',
 '2026-01-27 10:31:00'),

-- Robert Ssemwanga — closing soon alert
('e4000000-0000-0000-0000-000000000010',
 '10000000-0000-0000-0000-000000000005',
 'closing_soon_6h', 'Listing closing soon',
 'Your listing "Business Working Capital" closes in under 6 hours.',
 FALSE, 'c1000000-0000-0000-0000-000000000008', NULL,
 NOW() - INTERVAL '1 hour'),

-- Offer rejected notification (David's second lender)
('e4000000-0000-0000-0000-000000000011',
 '10000000-0000-0000-0000-000000000009',
 'offer_rejected', 'Your offer was not selected',
 'David Mukasa selected a different offer. Your offer on "Home Renovation Loan" was not chosen.',
 TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000002',
 '2024-02-06 14:32:00')

ON CONFLICT DO NOTHING;


-- ============================================
-- STEP 10: REFERRALS
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
    SELECT 'auth.users'           AS table_name, COUNT(*) AS record_count FROM auth.users           WHERE id::text LIKE '10000000%'
    UNION ALL SELECT 'profiles',                 COUNT(*) FROM profiles                              WHERE id::text LIKE '10000000%'
    UNION ALL SELECT 'subscriptions',            COUNT(*) FROM subscriptions
    UNION ALL SELECT 'kyc_verifications',        COUNT(*) FROM kyc_verifications
    UNION ALL SELECT 'loan_requests',            COUNT(*) FROM loan_requests
    UNION ALL SELECT 'loan_offers',              COUNT(*) FROM loan_offers
    UNION ALL SELECT 'contact_reveals',          COUNT(*) FROM contact_reveals
    UNION ALL SELECT 'watchlist',                COUNT(*) FROM watchlist
    UNION ALL SELECT 'notifications',            COUNT(*) FROM notifications
    UNION ALL SELECT 'referrals',                COUNT(*) FROM referrals
) t ORDER BY table_name;


SELECT p.full_name, au.email,
       au.email_confirmed_at IS NOT NULL AS confirmed,
       p.account_status, p.role,
       s.plan AS subscription_plan, s.status AS subscription_status
FROM profiles p
LEFT JOIN auth.users  au ON au.id = p.id
LEFT JOIN subscriptions s ON s.user_id = p.id AND s.status = 'active'
WHERE p.id::text LIKE '10000000%'
ORDER BY p.created_at;


SELECT lr.title, lr.district, lr.requested_amount,
       lr.income_source, lr.repayment_amount_per_period,
       lr.number_of_offers, lr.status, lr.expires_at,
       (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon
FROM loan_requests lr
WHERE lr.status = 'active'
ORDER BY lr.listed_at DESC;


SELECT lo.status AS offer_status, lo.offer_amount,
       lr.title AS listing_title,
       cr.status AS reveal_status
FROM loan_offers lo
JOIN loan_requests  lr ON lr.id      = lo.request_id
LEFT JOIN contact_reveals cr ON cr.offer_id = lo.id
ORDER BY lo.offered_at;


SELECT '✅ Nipanze seed v2.0 inserted successfully' AS status;
