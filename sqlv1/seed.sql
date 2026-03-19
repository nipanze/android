-- ============================================
-- OpenCapital Sample Data (Seed Data)
-- PostgreSQL compatible
--
-- Patch v1 integrated (correctly).
--
-- Bid lifecycle follows the trigger architecture:
--   1. WALLET BALANCES — set full deposit amounts
--   2. BIDS — all inserted as 'pending'
--      (trg_fn_enforce_lendable_on_bid checks
--       lendable_balance >= bid_amount on INSERT)
--   3. BID ACCEPTANCE — UPDATE pending → accepted
--      for the 7 bids that should be accepted;
--      trg_fn_lock_funds_on_accept fires on AFTER
--      UPDATE and moves lendable → locked_repayment
--      automatically, with correct timestamps.
--
-- Accepted bid totals per lender (after step 3):
--   Pearl Capital    : bid1(2M) + bid7(5M) = 7,000,000
--   Victoria Invest  : bid2(2M)            = 2,000,000
--   Robert Ssemwanga : bid3(1M) + bid4(1.5M) = 2,500,000
--   Charles Mwesigwa : bid5(1.8M)          = 1,800,000
--   Equator Finance  : bid8(3M)            = 3,000,000
--   GreenLeaf Agro   : no accepted bids
--   Kampala Tech     : no accepted bids
--
-- Expected wallet state after seed:
--   charles.mwesigwa      : lendable=1,200,000  locked=1,800,000
--   contact@kampalatech   : lendable=1,000,000  locked=0
--   funds@victoriainvest  : lendable=3,000,000  locked=2,000,000
--   info@greenleafagro    : lendable=1,500,000  locked=0
--   invest@pearlcapital   : lendable=3,000,000  locked=7,000,000
--   lending@equatorfinance: lendable=2,000,000  locked=3,000,000
--   robert.ssemwanga      : lendable=2,500,000  locked=2,500,000
-- ============================================


-- ============================================
-- USERS
-- ============================================

INSERT INTO users (user_id, email, phone_number, password_hash, role, status,
    email_verified, phone_verified, two_factor_enabled, last_login_at, last_login_ip,
    created_at) VALUES
(
    gen_random_uuid(),
    'david.mukasa@gmail.com', '+256701234567',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'borrower', 'active', TRUE, TRUE, FALSE,
    '2026-01-28 14:22:00', '102.168.1.45', '2024-01-15 08:30:00'
),
(
    gen_random_uuid(),
    'sarah.namukasa@yahoo.com', '+256702345678',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'borrower', 'active', TRUE, TRUE, FALSE,
    '2026-01-29 09:15:00', '102.168.1.67', '2024-01-18 10:45:00'
),
(
    gen_random_uuid(),
    'james.okello@outlook.com', '+256703456789',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'both', 'active', TRUE, TRUE, TRUE,
    '2026-01-27 16:40:00', '102.168.1.89', '2024-01-20 14:20:00'
),
(
    gen_random_uuid(),
    'maria.nakato@gmail.com', '+256704567890',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'borrower', 'active', TRUE, TRUE, FALSE,
    '2026-01-28 11:30:00', '102.168.1.102', '2024-01-22 09:10:00'
),
(
    gen_random_uuid(),
    'robert.ssemwanga@gmail.com', '+256705678901',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'both', 'active', TRUE, TRUE, TRUE,
    '2026-01-29 08:20:00', '102.168.1.125', '2024-01-25 11:30:00'
),
(
    gen_random_uuid(),
    'info@greenleafagro.co.ug', '+256711234567',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'lender', 'active', TRUE, TRUE, TRUE,
    '2026-01-28 16:30:00', '102.168.2.10', '2024-02-18 09:20:00'
),
(
    gen_random_uuid(),
    'contact@kampalatech.ug', '+256712345678',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'lender', 'active', TRUE, TRUE, TRUE,
    '2026-01-29 10:20:00', '102.168.2.20', '2024-02-20 11:40:00'
),
(
    gen_random_uuid(),
    'invest@pearlcapital.ug', '+256716789012',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'lender', 'active', TRUE, TRUE, TRUE,
    '2026-01-28 17:20:00', '102.168.2.30', '2024-03-01 10:10:00'
),
(
    gen_random_uuid(),
    'funds@victoriainvest.co.ug', '+256717890123',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'lender', 'active', TRUE, TRUE, TRUE,
    '2026-01-29 08:50:00', '102.168.2.40', '2024-03-03 12:30:00'
),
(
    gen_random_uuid(),
    'lending@equatorfinance.ug', '+256718901234',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'lender', 'active', TRUE, TRUE, TRUE,
    '2026-01-27 15:30:00', '102.168.2.50', '2024-03-05 09:45:00'
),
(
    gen_random_uuid(),
    'frank.omondi@gmail.com', '+256719012345',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'borrower', 'active', TRUE, TRUE, FALSE,
    '2026-01-28 12:40:00', '102.168.3.10', '2024-03-08 14:15:00'
),
(
    gen_random_uuid(),
    'lucy.nambi@yahoo.com', '+256720123456',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'both', 'active', TRUE, TRUE, TRUE,
    '2026-01-29 13:25:00', '102.168.3.20', '2024-03-10 11:20:00'
),
(
    gen_random_uuid(),
    'charles.mwesigwa@gmail.com', '+256721234567',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'both', 'active', TRUE, TRUE, FALSE,
    '2026-01-28 08:15:00', '102.168.3.30', '2024-03-12 16:40:00'
),
(
    gen_random_uuid(),
    'alice.namuli@gmail.com', '+256726789012',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'borrower', 'pending_verification', TRUE, FALSE, FALSE,
    NULL, NULL, '2026-01-25 09:15:00'
),
(
    gen_random_uuid(),
    'admin1@opencapital.ug', '+256700000001',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'admin', 'active', TRUE, TRUE, TRUE,
    '2026-01-29 18:00:00', '10.0.0.1', '2024-01-01 08:00:00'
),
(
    gen_random_uuid(),
    'admin2@opencapital.ug', '+256700000002',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'admin', 'active', TRUE, TRUE, TRUE,
    '2026-01-29 17:30:00', '10.0.0.2', '2024-01-01 08:00:00'
),
(
    gen_random_uuid(),
    'admin3@opencapital.ug', '+256700000003',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'admin', 'active', TRUE, TRUE, TRUE,
    '2026-01-29 17:00:00', '10.0.0.3', '2024-01-01 08:00:00'
),
(
    gen_random_uuid(),
    'test.user@gmail.com', '+256799999999',
    '$2b$10$IXGSfHBcvEpctfKDXu6.7OH.UTPOu.f8lCMtOQ5Rf7HM3/7Ry9biO',
    'borrower', 'active', TRUE, TRUE, FALSE,
    '2026-02-06 10:00:00', '127.0.0.1', '2026-02-06 10:00:00'
)
ON CONFLICT (email) DO NOTHING;


-- ============================================
-- USER PROFILES
-- ============================================

-- David Mukasa
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'David', 'Mukasa', '1988-03-15', 'male',
    'Plot 23, Kololo Heights', 'P.O. Box 12345', 'Kampala', 'Central', 'Uganda', '00256',
    'employed', 'Uganda Revenue Authority', 'Tax Officer', 4500000.00,
    NULL, NULL, NULL, NULL,
    TRUE, 100, '2024-01-15 08:30:00'
FROM users u WHERE u.email = 'david.mukasa@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- Sarah Namukasa
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Sarah', 'Namukasa', '1992-07-22', 'female',
    'Block 12, Ntinda Estate', 'P.O. Box 23456', 'Kampala', 'Central', 'Uganda', '00256',
    'employed', 'Stanbic Bank Uganda', 'Bank Teller', 3200000.00,
    NULL, NULL, NULL, NULL,
    TRUE, 100, '2024-01-18 10:45:00'
FROM users u WHERE u.email = 'sarah.namukasa@yahoo.com'
ON CONFLICT (user_id) DO NOTHING;

-- James Okello
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'James', 'Okello', '1985-11-08', 'male',
    'House 45, Bugolobi', 'P.O. Box 34567', 'Kampala', 'Central', 'Uganda', '00256',
    'employed', 'MTN Uganda', 'Network Engineer', 5800000.00,
    NULL, NULL, NULL, NULL,
    TRUE, 100, '2024-01-20 14:20:00'
FROM users u WHERE u.email = 'james.okello@outlook.com'
ON CONFLICT (user_id) DO NOTHING;

-- Maria Nakato
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Maria', 'Nakato', '1990-05-14', 'female',
    'Apartment 7, Nakasero', NULL, 'Kampala', 'Central', 'Uganda', '00256',
    'self_employed', NULL, 'Boutique Owner', 2800000.00,
    'Nakato Boutique', 'UG-BIZ-2020-012345', 'Retail', 4,
    TRUE, 100, '2024-01-22 09:10:00'
FROM users u WHERE u.email = 'maria.nakato@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- Robert Ssemwanga
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Robert', 'Ssemwanga', '1987-09-30', 'male',
    'Villa 18, Muyenga', NULL, 'Kampala', 'Central', 'Uganda', '00256',
    'employed', 'DFCU Bank', 'Branch Manager', 6500000.00,
    NULL, NULL, NULL, NULL,
    TRUE, 100, '2024-01-25 11:30:00'
FROM users u WHERE u.email = 'robert.ssemwanga@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- GreenLeaf Agro (Michael Semakula)
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Michael', 'Semakula', '1980-01-20', 'male',
    'Industrial Area, Plot 123', 'P.O. Box 1000', 'Kampala', 'Central', 'Uganda', '00256',
    'self_employed', NULL, 'CEO', 15000000.00,
    'GreenLeaf Agro Solutions Ltd', 'UG-BIZ-2019-045678', 'Agriculture', 5,
    TRUE, 100, '2024-02-18 09:20:00'
FROM users u WHERE u.email = 'info@greenleafagro.co.ug'
ON CONFLICT (user_id) DO NOTHING;

-- Kampala Tech (Sandra Namutebi)
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Sandra', 'Namutebi', '1983-07-15', 'female',
    'Plot 45, Nakawa', 'P.O. Box 2000', 'Kampala', 'Central', 'Uganda', '00256',
    'self_employed', NULL, 'Managing Director', 12000000.00,
    'Kampala Tech Innovations', 'UG-BIZ-2020-056789', 'Technology', 4,
    TRUE, 100, '2024-02-20 11:40:00'
FROM users u WHERE u.email = 'contact@kampalatech.ug'
ON CONFLICT (user_id) DO NOTHING;

-- Pearl Capital (William Kasujja)
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'William', 'Kasujja', '1975-05-18', 'male',
    'Pearl House, 14th Floor', 'P.O. Box 3000', 'Kampala', 'Central', 'Uganda', '00256',
    'self_employed', NULL, 'Investment Manager', 25000000.00,
    'Pearl Capital Investment Fund', 'UG-INV-2015-001234', 'Financial Services', 9,
    TRUE, 100, '2024-03-01 10:10:00'
FROM users u WHERE u.email = 'invest@pearlcapital.ug'
ON CONFLICT (user_id) DO NOTHING;

-- Victoria Investment (Catherine Namboze)
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Catherine', 'Namboze', '1977-12-03', 'female',
    'Crown Tower, Suite 1201', 'P.O. Box 4000', 'Kampala', 'Central', 'Uganda', '00256',
    'self_employed', NULL, 'Fund Manager', 22000000.00,
    'Victoria Investment Group', 'UG-INV-2014-002345', 'Investment Management', 10,
    TRUE, 100, '2024-03-03 12:30:00'
FROM users u WHERE u.email = 'funds@victoriainvest.co.ug'
ON CONFLICT (user_id) DO NOTHING;

-- Equator Finance (George Mulindwa)
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'George', 'Mulindwa', '1979-08-25', 'male',
    'Finance Plaza, 8th Floor', 'P.O. Box 5000', 'Kampala', 'Central', 'Uganda', '00256',
    'self_employed', NULL, 'Director', 28000000.00,
    'Equator Finance Corporation', 'UG-INV-2016-003456', 'Financial Services', 8,
    TRUE, 100, '2024-03-05 09:45:00'
FROM users u WHERE u.email = 'lending@equatorfinance.ug'
ON CONFLICT (user_id) DO NOTHING;

-- Frank Omondi
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Frank', 'Omondi', '1991-10-14', 'male',
    'Plot 12, Makindye', NULL, 'Kampala', 'Central', 'Uganda', '00256',
    'employed', 'Bank of Africa', 'Credit Officer', 3300000.00,
    NULL, NULL, NULL, NULL,
    TRUE, 100, '2024-03-08 14:15:00'
FROM users u WHERE u.email = 'frank.omondi@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- Lucy Nambi
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Lucy', 'Nambi', '1988-04-07', 'female',
    'House 78, Najanankumbi', NULL, 'Kampala', 'Central', 'Uganda', '00256',
    'employed', 'National Social Security Fund', 'Accountant', 2900000.00,
    NULL, NULL, NULL, NULL,
    TRUE, 100, '2024-03-10 11:20:00'
FROM users u WHERE u.email = 'lucy.nambi@yahoo.com'
ON CONFLICT (user_id) DO NOTHING;

-- Charles Mwesigwa
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Charles', 'Mwesigwa', '1984-06-21', 'male',
    'Apartment 15, Kabalagala', NULL, 'Kampala', 'Central', 'Uganda', '00256',
    'employed', 'Shell Uganda', 'Operations Manager', 5200000.00,
    NULL, NULL, NULL, NULL,
    TRUE, 100, '2024-03-12 16:40:00'
FROM users u WHERE u.email = 'charles.mwesigwa@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- Alice Namuli
INSERT INTO user_profiles (
    profile_id, user_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, district, country, postal_code,
    employment_status, employer_name, job_title, monthly_income,
    business_name, business_registration_number, business_type, years_in_business,
    profile_completed, profile_completion_percentage, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'Alice', 'Namuli', '1993-09-12', 'female',
    'House 34, Mutungo', NULL, 'Kampala', 'Central', 'Uganda', '00256',
    'employed', 'Equity Bank', 'Customer Service', 2700000.00,
    NULL, NULL, NULL, NULL,
    FALSE, 65, '2026-01-25 09:15:00'
FROM users u WHERE u.email = 'alice.namuli@gmail.com'
ON CONFLICT (user_id) DO NOTHING;


-- ============================================
-- KYC VERIFICATIONS
-- ============================================

-- David Mukasa
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'approved', 'national_id', 'CM88015KL234567',
    'https://storage.opencapital.ug/kyc/user-001-id-front.jpg',
    'https://storage.opencapital.ug/kyc/user-001-id-back.jpg',
    TRUE, '2024-01-16 10:30:00',
    'https://storage.opencapital.ug/kyc/user-001-selfie.jpg',
    TRUE, '2024-01-16 10:30:00',
    'https://storage.opencapital.ug/kyc/user-001-address.pdf',
    TRUE, '2024-01-16 10:30:00',
    (SELECT user_id FROM users WHERE email = 'admin1@opencapital.ug'),
    '2024-01-15 09:15:00', '2024-01-16 10:30:00', '2029-01-15', '2024-01-15 09:15:00'
FROM users u WHERE u.email = 'david.mukasa@gmail.com';

-- Sarah Namukasa
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'approved', 'national_id', 'CM92022NM345678',
    'https://storage.opencapital.ug/kyc/user-002-id-front.jpg',
    'https://storage.opencapital.ug/kyc/user-002-id-back.jpg',
    TRUE, '2024-01-19 11:45:00',
    'https://storage.opencapital.ug/kyc/user-002-selfie.jpg',
    TRUE, '2024-01-19 11:45:00',
    'https://storage.opencapital.ug/kyc/user-002-address.pdf',
    TRUE, '2024-01-19 11:45:00',
    (SELECT user_id FROM users WHERE email = 'admin1@opencapital.ug'),
    '2024-01-18 11:00:00', '2024-01-19 11:45:00', '2029-01-18', '2024-01-18 11:00:00'
FROM users u WHERE u.email = 'sarah.namukasa@yahoo.com';

-- James Okello
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'approved', 'national_id', 'CM85011OK345679',
    'https://storage.opencapital.ug/kyc/user-003-id-front.jpg',
    'https://storage.opencapital.ug/kyc/user-003-id-back.jpg',
    TRUE, '2024-01-21 09:30:00',
    'https://storage.opencapital.ug/kyc/user-003-selfie.jpg',
    TRUE, '2024-01-21 09:30:00',
    'https://storage.opencapital.ug/kyc/user-003-address.pdf',
    TRUE, '2024-01-21 09:30:00',
    (SELECT user_id FROM users WHERE email = 'admin2@opencapital.ug'),
    '2024-01-20 14:30:00', '2024-01-21 09:30:00', '2029-01-20', '2024-01-20 14:30:00'
FROM users u WHERE u.email = 'james.okello@outlook.com';

-- Maria Nakato
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'approved', 'national_id', 'CM90014NK567890',
    'https://storage.opencapital.ug/kyc/user-004-id-front.jpg',
    'https://storage.opencapital.ug/kyc/user-004-id-back.jpg',
    TRUE, '2024-01-23 14:30:00',
    'https://storage.opencapital.ug/kyc/user-004-selfie.jpg',
    TRUE, '2024-01-23 14:30:00',
    'https://storage.opencapital.ug/kyc/user-004-address.pdf',
    TRUE, '2024-01-23 14:30:00',
    (SELECT user_id FROM users WHERE email = 'admin2@opencapital.ug'),
    '2024-01-22 09:30:00', '2024-01-23 14:30:00', '2029-01-22', '2024-01-22 09:30:00'
FROM users u WHERE u.email = 'maria.nakato@gmail.com';

-- Robert Ssemwanga
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'approved', 'national_id', 'CM87030SS678901',
    'https://storage.opencapital.ug/kyc/user-005-id-front.jpg',
    'https://storage.opencapital.ug/kyc/user-005-id-back.jpg',
    TRUE, '2024-01-25 16:00:00',
    'https://storage.opencapital.ug/kyc/user-005-selfie.jpg',
    TRUE, '2024-01-25 16:00:00',
    'https://storage.opencapital.ug/kyc/user-005-address.pdf',
    TRUE, '2024-01-25 16:00:00',
    (SELECT user_id FROM users WHERE email = 'admin1@opencapital.ug'),
    '2024-01-25 11:45:00', '2024-01-25 16:00:00', '2029-01-25', '2024-01-25 11:45:00'
FROM users u WHERE u.email = 'robert.ssemwanga@gmail.com';

-- GreenLeaf Agro
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    business_registration_url, business_license_url, tax_clearance_url,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'approved', 'business_registration', 'UG-BIZ-2019-045678',
    'https://storage.opencapital.ug/kyc/user-011-license.pdf',
    NULL, TRUE, '2024-02-19 10:30:00',
    NULL, FALSE, NULL,
    'https://storage.opencapital.ug/kyc/user-011-address.pdf',
    TRUE, '2024-02-19 10:30:00',
    'https://storage.opencapital.ug/kyc/user-011-registration.pdf',
    'https://storage.opencapital.ug/kyc/user-011-license.pdf',
    'https://storage.opencapital.ug/kyc/user-011-tax.pdf',
    (SELECT user_id FROM users WHERE email = 'admin3@opencapital.ug'),
    '2024-02-19 09:00:00', '2024-02-19 10:30:00', '2027-02-19', '2024-02-19 09:00:00'
FROM users u WHERE u.email = 'info@greenleafagro.co.ug';

-- Frank Omondi
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'approved', 'national_id', 'CM91114OM789012',
    'https://storage.opencapital.ug/kyc/user-011-id-front.jpg',
    'https://storage.opencapital.ug/kyc/user-011-id-back.jpg',
    TRUE, '2024-03-09 14:00:00',
    'https://storage.opencapital.ug/kyc/user-011-selfie.jpg',
    TRUE, '2024-03-09 14:00:00',
    'https://storage.opencapital.ug/kyc/user-011-address.pdf',
    TRUE, '2024-03-09 14:00:00',
    (SELECT user_id FROM users WHERE email = 'admin2@opencapital.ug'),
    '2024-03-09 09:30:00', '2024-03-09 14:00:00', '2029-03-09', '2024-03-09 09:30:00'
FROM users u WHERE u.email = 'frank.omondi@gmail.com';

-- Lucy Nambi
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'approved', 'national_id', 'CM88047NB890123',
    'https://storage.opencapital.ug/kyc/user-012-id-front.jpg',
    'https://storage.opencapital.ug/kyc/user-012-id-back.jpg',
    TRUE, '2024-03-11 11:00:00',
    'https://storage.opencapital.ug/kyc/user-012-selfie.jpg',
    TRUE, '2024-03-11 11:00:00',
    'https://storage.opencapital.ug/kyc/user-012-address.pdf',
    TRUE, '2024-03-11 11:00:00',
    (SELECT user_id FROM users WHERE email = 'admin3@opencapital.ug'),
    '2024-03-11 09:00:00', '2024-03-11 11:00:00', '2029-03-11', '2024-03-11 09:00:00'
FROM users u WHERE u.email = 'lucy.nambi@yahoo.com';

-- Charles Mwesigwa
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'approved', 'national_id', 'CM84021MW901234',
    'https://storage.opencapital.ug/kyc/user-013-id-front.jpg',
    'https://storage.opencapital.ug/kyc/user-013-id-back.jpg',
    TRUE, '2024-03-13 15:00:00',
    'https://storage.opencapital.ug/kyc/user-013-selfie.jpg',
    TRUE, '2024-03-13 15:00:00',
    'https://storage.opencapital.ug/kyc/user-013-address.pdf',
    TRUE, '2024-03-13 15:00:00',
    (SELECT user_id FROM users WHERE email = 'admin3@opencapital.ug'),
    '2024-03-13 12:00:00', '2024-03-13 15:00:00', '2029-03-13', '2024-03-13 12:00:00'
FROM users u WHERE u.email = 'charles.mwesigwa@gmail.com';

-- Alice Namuli (pending)
INSERT INTO kyc_verifications (
    verification_id, user_id, status, id_type, id_number,
    id_front_url, id_back_url, id_verified, id_verified_at,
    selfie_url, selfie_verified, selfie_verified_at,
    proof_of_address_url, proof_of_address_verified, proof_of_address_verified_at,
    verified_by, submitted_at, verified_at, expires_at, created_at
)
SELECT gen_random_uuid(), u.user_id,
    'pending', 'national_id', 'CM93255NM789012',
    'https://storage.opencapital.ug/kyc/user-026-id-front.jpg',
    'https://storage.opencapital.ug/kyc/user-026-id-back.jpg',
    FALSE, NULL,
    'https://storage.opencapital.ug/kyc/user-026-selfie.jpg',
    FALSE, NULL,
    'https://storage.opencapital.ug/kyc/user-026-address.pdf',
    FALSE, NULL,
    NULL,
    '2026-01-25 10:30:00', NULL, NULL, '2026-01-25 10:30:00'
FROM users u WHERE u.email = 'alice.namuli@gmail.com';


-- ============================================
-- RISK ASSESSMENTS
-- ============================================

-- David Mukasa
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    750, 91.0, 'low',
    95, 88, 15.2, 90,
    (SELECT user_id FROM users WHERE email = 'admin1@opencapital.ug'),
    '2024-01-16 11:00:00', '2026-07-15', TRUE, '2024-01-16 11:00:00'
FROM users u WHERE u.email = 'david.mukasa@gmail.com';

-- Sarah Namukasa
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    720, 74.0, 'low',
    78, 72, 22.5, 70,
    NULL,
    '2024-01-19 12:00:00', '2026-07-18', TRUE, '2024-01-19 12:00:00'
FROM users u WHERE u.email = 'sarah.namukasa@yahoo.com';

-- James Okello
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    780, 88.0, 'low',
    92, 85, 18.7, 87,
    NULL,
    '2024-01-21 09:00:00', '2026-07-20', TRUE, '2024-01-21 09:00:00'
FROM users u WHERE u.email = 'james.okello@outlook.com';

-- Maria Nakato
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    650, 61.0, 'medium',
    65, 58, 35.0, 60,
    NULL,
    '2024-01-23 14:00:00', '2026-07-22', TRUE, '2024-01-23 14:00:00'
FROM users u WHERE u.email = 'maria.nakato@gmail.com';

-- Robert Ssemwanga
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    790, 85.0, 'low',
    90, 88, 12.0, 85,
    NULL,
    '2024-01-25 17:00:00', '2026-07-25', TRUE, '2024-01-25 17:00:00'
FROM users u WHERE u.email = 'robert.ssemwanga@gmail.com';

-- GreenLeaf Agro
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    710, 79.0, 'low',
    82, 78, 28.0, 75,
    (SELECT user_id FROM users WHERE email = 'admin3@opencapital.ug'),
    '2024-02-20 09:00:00', '2026-08-18', TRUE, '2024-02-20 09:00:00'
FROM users u WHERE u.email = 'info@greenleafagro.co.ug';

-- Pearl Capital
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    850, 95.0, 'low',
    98, 95, 10.0, 96,
    NULL,
    '2024-03-02 10:00:00', '2026-09-01', TRUE, '2024-03-02 10:00:00'
FROM users u WHERE u.email = 'invest@pearlcapital.ug';

-- Victoria Investment
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    845, 95.0, 'low',
    96, 93, 12.0, 95,
    NULL,
    '2024-03-04 11:00:00', '2026-09-03', TRUE, '2024-03-04 11:00:00'
FROM users u WHERE u.email = 'funds@victoriainvest.co.ug';

-- Frank Omondi
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    580, 44.0, 'high',
    48, 42, 45.0, 40,
    NULL,
    '2024-03-09 10:00:00', '2026-09-18', TRUE, '2024-03-09 10:00:00'
FROM users u WHERE u.email = 'frank.omondi@gmail.com';

-- Lucy Nambi
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    690, 68.0, 'medium',
    70, 65, 28.0, 65,
    NULL,
    '2024-03-11 12:00:00', '2026-09-11', TRUE, '2024-03-11 12:00:00'
FROM users u WHERE u.email = 'lucy.nambi@yahoo.com';

-- Charles Mwesigwa
INSERT INTO risk_assessments (
    assessment_id, user_id, credit_score, risk_score, risk_category,
    income_verification_score, employment_stability_score,
    debt_to_income_ratio, previous_loan_performance_score,
    assessed_by, assessment_date, valid_until, is_current, created_at
)
SELECT gen_random_uuid(), u.user_id,
    760, 82.0, 'low',
    85, 80, 16.0, 80,
    NULL,
    '2024-03-13 16:00:00', '2026-09-13', TRUE, '2024-03-13 16:00:00'
FROM users u WHERE u.email = 'charles.mwesigwa@gmail.com';


-- ============================================
-- LOAN REQUESTS
-- ============================================

-- David Mukasa — Home Renovation
-- Funding progress starts at zero; triggers populate
-- total_bid_amount, number_of_bids, funding_percentage,
-- and status as bids are accepted in the accept block.
INSERT INTO loan_requests (
    request_id, borrower_id, requested_amount, purpose,
    purpose_description, duration_months, max_interest_rate,
    total_bid_amount, number_of_bids, funding_percentage,
    status, listed_at, expires_at, funded_at,
    supporting_documents, views_count, created_at
)
SELECT gen_random_uuid(), u.user_id,
    5000000.00, 'Home Renovation',
    'Complete home renovation including kitchen and bathroom upgrades',
    12, 12.0,
    0.00, 0, 0.00,
    'active', '2025-11-15 11:00:00', '2025-11-22 11:00:00', NULL,
    '{"renovation_plan": "plan.pdf", "quotes": ["quote1.pdf", "quote2.pdf"]}',
    45, '2025-11-14 14:20:00'
FROM users u WHERE u.email = 'david.mukasa@gmail.com';

-- Sarah Namukasa — Education
-- Funding progress starts at zero; triggers populate via bid accepts.
INSERT INTO loan_requests (
    request_id, borrower_id, requested_amount, purpose,
    purpose_description, duration_months, max_interest_rate,
    total_bid_amount, number_of_bids, funding_percentage,
    status, listed_at, expires_at, funded_at,
    supporting_documents, views_count, created_at
)
SELECT gen_random_uuid(), u.user_id,
    5500000.00, 'Education',
    'Professional certification courses in financial management',
    12, 15.0,
    0.00, 0, 0.00,
    'active', '2026-01-20 11:30:00', '2026-01-27 11:30:00', NULL,
    '{"course_brochure": "course.pdf", "fee_structure": "fees.pdf"}',
    28, '2026-01-19 14:15:00'
FROM users u WHERE u.email = 'sarah.namukasa@yahoo.com';

-- James Okello — Business Expansion
-- Funding progress starts at zero; triggers populate via bid accepts.
INSERT INTO loan_requests (
    request_id, borrower_id, requested_amount, purpose,
    purpose_description, duration_months, max_interest_rate,
    total_bid_amount, number_of_bids, funding_percentage,
    status, listed_at, expires_at, funded_at,
    supporting_documents, views_count, created_at
)
SELECT gen_random_uuid(), u.user_id,
    8000000.00, 'Business Expansion',
    'Equipment purchase for IT consultancy expansion',
    18, 10.5,
    0.00, 0, 0.00,
    'active', '2025-11-20 10:00:00', '2025-11-27 10:00:00', NULL,
    '{"business_plan": "plan.pdf", "equipment_quotes": "quotes.pdf"}',
    52, '2025-11-19 16:30:00'
FROM users u WHERE u.email = 'james.okello@outlook.com';

-- Maria Nakato — Business Inventory (active, no bids yet)
INSERT INTO loan_requests (
    request_id, borrower_id, requested_amount, purpose,
    purpose_description, duration_months, max_interest_rate,
    total_bid_amount, number_of_bids, funding_percentage,
    status, listed_at, expires_at, funded_at,
    supporting_documents, views_count, created_at
)
SELECT gen_random_uuid(), u.user_id,
    3500000.00, 'Business Inventory',
    'Inventory expansion for boutique store',
    12, 15.0,
    0.00, 0, 0.00,
    'active', '2026-01-24 15:00:00', '2026-01-31 15:00:00', NULL,
    '{"inventory_list": "inventory.pdf", "supplier_quotes": "quotes.pdf"}',
    15, '2026-01-23 11:45:00'
FROM users u WHERE u.email = 'maria.nakato@gmail.com';

-- Robert Ssemwanga — Vehicle Purchase (draft)
INSERT INTO loan_requests (
    request_id, borrower_id, requested_amount, purpose,
    purpose_description, duration_months, max_interest_rate,
    total_bid_amount, number_of_bids, funding_percentage,
    status, listed_at, expires_at, funded_at,
    supporting_documents, views_count, created_at
)
SELECT gen_random_uuid(), u.user_id,
    6000000.00, 'Vehicle Purchase',
    'Purchase of delivery van for business',
    24, 13.0,
    0.00, 0, 0.00,
    'draft', NULL, NULL, NULL,
    '{"vehicle_quote": "quote.pdf"}',
    3, '2026-01-28 14:30:00'
FROM users u WHERE u.email = 'robert.ssemwanga@gmail.com';

-- Frank Omondi — Medical Expenses (active, no bids yet)
INSERT INTO loan_requests (
    request_id, borrower_id, requested_amount, purpose,
    purpose_description, duration_months, max_interest_rate,
    total_bid_amount, number_of_bids, funding_percentage,
    status, listed_at, expires_at, funded_at,
    supporting_documents, views_count, created_at
)
SELECT gen_random_uuid(), u.user_id,
    4500000.00, 'Medical Expenses',
    'Medical treatment and recovery expenses',
    18, 14.5,
    0.00, 0, 0.00,
    'active', '2026-01-26 10:00:00', '2026-02-02 10:00:00', NULL,
    '{"medical_reports": "reports.pdf", "hospital_quotes": "quotes.pdf"}',
    22, '2026-01-25 15:50:00'
FROM users u WHERE u.email = 'frank.omondi@gmail.com';


-- ============================================
-- WALLET BALANCES  (deposit phase)
-- Set each lender's lendable_balance to their
-- full deposit amount BEFORE any bids are
-- inserted. This ensures trg_fn_enforce_lendable_on_bid
-- passes for every bid INSERT.
--
-- trg_fn_lock_funds_on_accept fires on AFTER UPDATE
-- (pending → accepted), NOT on INSERT. So we must
-- not pre-subtract accepted amounts here — the
-- accept UPDATEs below will move funds automatically.
--
-- Deposit = max single-lender bid total + buffer:
--   Pearl Capital    : 7M bids (2M+5M)   → deposit 10M
--   Victoria Invest  : 2M bid             → deposit  5M
--   Robert Ssemwanga : 3.5M bids (1M+1.5M+1M) → deposit  5M
--   Charles Mwesigwa : 1.8M bid           → deposit  3M
--   Equator Finance  : 3M bid             → deposit  5M
--   GreenLeaf Agro   : 1.5M bid           → deposit  3M
--   Kampala Tech     : 2M bid             → deposit  3M
-- ============================================

UPDATE wallet_balances SET lendable_balance = 10000000.00
WHERE user_id = (SELECT user_id FROM users WHERE email = 'invest@pearlcapital.ug');

UPDATE wallet_balances SET lendable_balance = 5000000.00
WHERE user_id = (SELECT user_id FROM users WHERE email = 'funds@victoriainvest.co.ug');

UPDATE wallet_balances SET lendable_balance = 5000000.00
WHERE user_id = (SELECT user_id FROM users WHERE email = 'robert.ssemwanga@gmail.com');

UPDATE wallet_balances SET lendable_balance = 3000000.00
WHERE user_id = (SELECT user_id FROM users WHERE email = 'charles.mwesigwa@gmail.com');

UPDATE wallet_balances SET lendable_balance = 5000000.00
WHERE user_id = (SELECT user_id FROM users WHERE email = 'lending@equatorfinance.ug');

UPDATE wallet_balances SET lendable_balance = 3000000.00
WHERE user_id = (SELECT user_id FROM users WHERE email = 'info@greenleafagro.co.ug');

UPDATE wallet_balances SET lendable_balance = 3000000.00
WHERE user_id = (SELECT user_id FROM users WHERE email = 'contact@kampalatech.ug');


-- ============================================
-- BIDS  (all inserted as 'pending')
-- Inserting as pending ensures trg_fn_enforce_lendable_on_bid
-- checks the full deposit balance (always passes).
-- trg_fn_lock_funds_on_accept fires on AFTER UPDATE
-- only, so no wallet movement happens here.
--
-- The ACCEPT block immediately below UPDATEs the
-- correct bids to 'accepted', which fires the
-- lock trigger and moves lendable → locked_repayment
-- automatically with correct timestamps.
-- ============================================

-- Bid 1 — David's loan (Pearl Capital, 2,000,000)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    2000000.00, 11.0,
    'pending', TRUE, '2025-11-15 12:30:00', NULL, NULL, NULL
FROM loan_requests lr
JOIN users l ON l.email = 'invest@pearlcapital.ug'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'david.mukasa@gmail.com')
LIMIT 1;

-- Bid 2 — David's loan (Victoria Investment, 2,000,000)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    2000000.00, 11.5,
    'pending', FALSE, '2025-11-16 09:15:00', NULL, NULL, NULL
FROM loan_requests lr
JOIN users l ON l.email = 'funds@victoriainvest.co.ug'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'david.mukasa@gmail.com')
LIMIT 1;

-- Bid 3 — David's loan (Robert Ssemwanga, 1,000,000)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    1000000.00, 12.0,
    'pending', FALSE, '2025-11-18 08:45:00', NULL, NULL, NULL
FROM loan_requests lr
JOIN users l ON l.email = 'robert.ssemwanga@gmail.com'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'david.mukasa@gmail.com')
LIMIT 1;

-- Bid 4 — Sarah's loan (Robert Ssemwanga, 1,500,000)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    1500000.00, 14.5,
    'pending', FALSE, '2026-01-21 11:20:00', NULL, NULL, NULL
FROM loan_requests lr
JOIN users l ON l.email = 'robert.ssemwanga@gmail.com'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'sarah.namukasa@yahoo.com')
LIMIT 1;

-- Bid 5 — Sarah's loan (Charles Mwesigwa, 1,800,000)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    1800000.00, 15.0,
    'pending', FALSE, '2026-01-24 08:45:00', NULL, NULL, NULL
FROM loan_requests lr
JOIN users l ON l.email = 'charles.mwesigwa@gmail.com'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'sarah.namukasa@yahoo.com')
LIMIT 1;

-- Bid 6 — Sarah's loan (Robert Ssemwanga, 1,000,000 — stays pending)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    1000000.00, 15.0,
    'pending', FALSE, '2026-01-26 14:20:00', NULL, NULL, '2026-02-02 14:20:00'
FROM loan_requests lr
JOIN users l ON l.email = 'robert.ssemwanga@gmail.com'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'sarah.namukasa@yahoo.com')
LIMIT 1;

-- Bid 7 — James' loan (Pearl Capital, 5,000,000)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    5000000.00, 10.0,
    'pending', TRUE, '2025-11-20 11:20:00', NULL, NULL, NULL
FROM loan_requests lr
JOIN users l ON l.email = 'invest@pearlcapital.ug'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'james.okello@outlook.com')
LIMIT 1;

-- Bid 8 — James' loan (Equator Finance, 3,000,000)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    3000000.00, 10.5,
    'pending', TRUE, '2025-11-23 13:15:00', NULL, NULL, NULL
FROM loan_requests lr
JOIN users l ON l.email = 'lending@equatorfinance.ug'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'james.okello@outlook.com')
LIMIT 1;

-- Bid 9 — Maria's loan (GreenLeaf Agro, 1,500,000 — stays pending)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    1500000.00, 14.0,
    'pending', FALSE, '2026-01-27 10:30:00', NULL, NULL, '2026-02-03 10:30:00'
FROM loan_requests lr
JOIN users l ON l.email = 'info@greenleafagro.co.ug'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'maria.nakato@gmail.com')
LIMIT 1;

-- Bid 10 — Frank's loan (Kampala Tech, 2,000,000 — stays pending)
INSERT INTO bids (
    bid_id, request_id, lender_id, bid_amount, interest_rate,
    status, auto_accept, created_at, accepted_at, withdrawn_at, expires_at
)
SELECT gen_random_uuid(), lr.request_id, l.user_id,
    2000000.00, 14.5,
    'pending', FALSE, '2026-01-28 09:15:00', NULL, NULL, '2026-02-04 09:15:00'
FROM loan_requests lr
JOIN users l ON l.email = 'contact@kampalatech.ug'
WHERE lr.borrower_id = (SELECT user_id FROM users WHERE email = 'frank.omondi@gmail.com')
LIMIT 1;


-- ============================================
-- BID ACCEPTANCE
-- UPDATE pending → accepted for the 5 bids that
-- should be accepted. This fires
-- trg_fn_lock_funds_on_accept (AFTER UPDATE) for
-- each row, automatically moving bid_amount from
-- lendable_balance → locked_repayment.
--
-- Also fires trg_fn_update_funding_progress, which
-- increments loan_requests.total_bid_amount,
-- number_of_bids, and funding_percentage.
--
-- Bids identified by lender + loan + amount to
-- avoid relying on insertion order.
-- ============================================

-- Bid 1: Pearl Capital → David's loan (2,000,000)
UPDATE bids SET
    status      = 'accepted',
    accepted_at = '2025-11-15 12:30:00'
WHERE lender_id  = (SELECT user_id FROM users WHERE email = 'invest@pearlcapital.ug')
  AND request_id = (SELECT request_id FROM loan_requests
                    WHERE borrower_id = (SELECT user_id FROM users WHERE email = 'david.mukasa@gmail.com'))
  AND bid_amount = 2000000.00
  AND status     = 'pending';

-- Bid 2: Victoria Investment → David's loan (2,000,000)
UPDATE bids SET
    status      = 'accepted',
    accepted_at = '2025-11-16 14:20:00'
WHERE lender_id  = (SELECT user_id FROM users WHERE email = 'funds@victoriainvest.co.ug')
  AND request_id = (SELECT request_id FROM loan_requests
                    WHERE borrower_id = (SELECT user_id FROM users WHERE email = 'david.mukasa@gmail.com'))
  AND bid_amount = 2000000.00
  AND status     = 'pending';

-- Bid 3: Robert Ssemwanga → David's loan (1,000,000)
UPDATE bids SET
    status      = 'accepted',
    accepted_at = '2025-11-18 09:45:00'
WHERE lender_id  = (SELECT user_id FROM users WHERE email = 'robert.ssemwanga@gmail.com')
  AND request_id = (SELECT request_id FROM loan_requests
                    WHERE borrower_id = (SELECT user_id FROM users WHERE email = 'david.mukasa@gmail.com'))
  AND bid_amount = 1000000.00
  AND status     = 'pending';

-- Bid 4: Robert Ssemwanga → Sarah's loan (1,500,000)
UPDATE bids SET
    status      = 'accepted',
    accepted_at = '2026-01-21 15:30:00'
WHERE lender_id  = (SELECT user_id FROM users WHERE email = 'robert.ssemwanga@gmail.com')
  AND request_id = (SELECT request_id FROM loan_requests
                    WHERE borrower_id = (SELECT user_id FROM users WHERE email = 'sarah.namukasa@yahoo.com'))
  AND bid_amount = 1500000.00
  AND status     = 'pending';

-- Bid 5: Charles Mwesigwa → Sarah's loan (1,800,000)
UPDATE bids SET
    status      = 'accepted',
    accepted_at = '2026-01-24 09:30:00'
WHERE lender_id  = (SELECT user_id FROM users WHERE email = 'charles.mwesigwa@gmail.com')
  AND request_id = (SELECT request_id FROM loan_requests
                    WHERE borrower_id = (SELECT user_id FROM users WHERE email = 'sarah.namukasa@yahoo.com'))
  AND bid_amount = 1800000.00
  AND status     = 'pending';

-- Bid 7: Pearl Capital → James' loan (5,000,000)
UPDATE bids SET
    status      = 'accepted',
    accepted_at = '2025-11-20 11:20:00'
WHERE lender_id  = (SELECT user_id FROM users WHERE email = 'invest@pearlcapital.ug')
  AND request_id = (SELECT request_id FROM loan_requests
                    WHERE borrower_id = (SELECT user_id FROM users WHERE email = 'james.okello@outlook.com'))
  AND bid_amount = 5000000.00
  AND status     = 'pending';

-- Bid 8: Equator Finance → James' loan (3,000,000)
UPDATE bids SET
    status      = 'accepted',
    accepted_at = '2025-11-23 13:15:00'
WHERE lender_id  = (SELECT user_id FROM users WHERE email = 'lending@equatorfinance.ug')
  AND request_id = (SELECT request_id FROM loan_requests
                    WHERE borrower_id = (SELECT user_id FROM users WHERE email = 'james.okello@outlook.com'))
  AND bid_amount = 3000000.00
  AND status     = 'pending';


-- ============================================
-- POST-ACCEPT FIXUPS
-- trg_fn_update_funding_progress sets status and
-- funding_percentage but does not set funded_at
-- (that field is application-layer concern).
-- Stamp it here for the two fully-funded loans.
-- ============================================

UPDATE loan_requests
SET funded_at = '2025-11-20 14:30:00'
WHERE borrower_id = (SELECT user_id FROM users WHERE email = 'david.mukasa@gmail.com')
  AND status = 'fully_funded';

UPDATE loan_requests
SET funded_at = '2025-11-25 15:45:00'
WHERE borrower_id = (SELECT user_id FROM users WHERE email = 'james.okello@outlook.com')
  AND status = 'fully_funded';


-- ============================================
-- VERIFICATION
-- ============================================

SELECT table_name, record_count FROM (
    SELECT 'users'            AS table_name, COUNT(*) AS record_count FROM users
    UNION ALL
    SELECT 'user_profiles',                  COUNT(*) FROM user_profiles
    UNION ALL
    SELECT 'kyc_verifications',              COUNT(*) FROM kyc_verifications
    UNION ALL
    SELECT 'risk_assessments',              COUNT(*) FROM risk_assessments
    UNION ALL
    SELECT 'loan_requests',                  COUNT(*) FROM loan_requests
    UNION ALL
    SELECT 'bids',                           COUNT(*) FROM bids
) t
ORDER BY table_name;

-- Wallet state verification — expected results:
--   charles.mwesigwa      : lendable=1,200,000   locked=1,800,000
--   contact@kampalatech   : lendable=1,000,000   locked=0        (pending bid, no lock)
--   funds@victoriainvest  : lendable=3,000,000   locked=2,000,000
--   info@greenleafagro    : lendable=1,500,000   locked=0        (pending bid, no lock)
--   invest@pearlcapital   : lendable=3,000,000   locked=7,000,000
--   james.okello          : lendable=0           locked=0        (no bids placed)
--   lending@equatorfinance: lendable=2,000,000   locked=3,000,000
--   lucy.nambi            : lendable=0           locked=0
--   robert.ssemwanga      : lendable=2,500,000   locked=2,500,000 (1M pending still unlocked)
SELECT
    u.email,
    wb.lendable_balance,
    wb.locked_repayment,
    wb.non_lendable_borrowed,
    COUNT(b.bid_id)                                                    AS total_bids,
    COALESCE(SUM(b.bid_amount) FILTER (WHERE b.status = 'accepted'),0) AS accepted_total,
    COALESCE(SUM(b.bid_amount) FILTER (WHERE b.status = 'pending'), 0) AS pending_total
FROM users u
JOIN wallet_balances wb ON u.user_id = wb.user_id
LEFT JOIN bids b        ON u.user_id = b.lender_id
WHERE u.role IN ('lender', 'both')
GROUP BY u.email, wb.lendable_balance, wb.locked_repayment, wb.non_lendable_borrowed
ORDER BY u.email;

SELECT '✅ Seed data inserted successfully — 0 bid errors expected' AS status;