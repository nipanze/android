-- More Uganda + Kenya loan requests for demo/testing
-- Safe to run multiple times: uses ON CONFLICT DO NOTHING.

BEGIN;

-- -----------------------------------------------------------------------------
-- Uganda loan requests
-- -----------------------------------------------------------------------------
INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period,
    repayment_timeline, district, status, listed_at, expires_at, contracted_at,
    number_of_offers, views_count, created_at
) VALUES
    (
        'c1000000-0000-0000-0000-000000001101', '10000000-0000-0000-0000-000000000005', 'UG',
        'School Fees Top-Up', 'Pay the second semester tuition balance for my diploma at Kyambogo University',
        2200000, 12, 'Salary — UGX 4,500,000', 'monthly', 210000,
        '12 months starting April 2026', 'Kampala', 'active',
        NOW() - INTERVAL '1 day', NOW() + INTERVAL '18 days', NULL, 0, 44,
        NOW() - INTERVAL '1 day'
    ),
    (
        'c1000000-0000-0000-0000-000000001102', '10000000-0000-0000-0000-000000000006', 'UG',
        'Clinic Equipment Upgrade', 'Replace old clinic devices and buy basic diagnostic tools for a small family clinic',
        4800000, 18, 'Salary — UGX 3,200,000', 'monthly', 280000,
        '18 months starting May 2026', 'Wakiso', 'active',
        NOW() - INTERVAL '2 days', NOW() + INTERVAL '17 days', NULL, 1, 57,
        NOW() - INTERVAL '2 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001103', '10000000-0000-0000-0000-000000000007', 'UG',
        'Agribusiness Expansion', 'Expand maize and cassava trading with a second pickup truck route to western Uganda',
        7600000, 24, 'Salary — UGX 5,800,000', 'monthly', 360000,
        '24 months starting April 2026', 'Mukono', 'active',
        NOW() - INTERVAL '3 days', NOW() + INTERVAL '16 days', NULL, 2, 62,
        NOW() - INTERVAL '3 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001104', '10000000-0000-0000-0000-000000000008', 'UG',
        'Bakery Working Capital', 'Buy flour, packaging, and fuel for a growing bakery serving weekend orders in Ntinda',
        3100000, 9, 'Business income — UGX 2,800,000', 'monthly', 390000,
        '9 months starting May 2026', 'Central', 'active',
        NOW() - INTERVAL '4 days', NOW() + INTERVAL '14 days', NULL, 0, 31,
        NOW() - INTERVAL '4 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001105', '10000000-0000-0000-0000-000000000010', 'UG',
        'Emergency Medical Treatment', 'Cover emergency surgery and post-op care after a recent accident',
        4200000, 12, 'Salary — UGX 3,300,000', 'monthly', 390000,
        '12 months starting April 2026', 'Eastern', 'active',
        NOW() - INTERVAL '1 day', NOW() + INTERVAL '20 days', NULL, 1, 49,
        NOW() - INTERVAL '1 day'
    ),
    (
        'c1000000-0000-0000-0000-000000001106', '10000000-0000-0000-0000-000000000015', 'UG',
        'Solar Home Installation', 'Install a rooftop solar setup for my family home and small office in Entebbe',
        5400000, 18, 'Salary — UGX 2,900,000', 'monthly', 330000,
        '18 months starting June 2026', 'Entebbe', 'active',
        NOW() - INTERVAL '5 days', NOW() + INTERVAL '12 days', NULL, 1, 28,
        NOW() - INTERVAL '5 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001107', '10000000-0000-0000-0000-000000000016', 'UG',
        'Commercial Van Deposit', 'Pay the deposit for a second delivery van to support a growing logistics business',
        8800000, 24, 'Salary — UGX 5,200,000', 'monthly', 410000,
        '24 months starting May 2026', 'Mbarara', 'active',
        NOW() - INTERVAL '6 days', NOW() + INTERVAL '15 days', NULL, 2, 54,
        NOW() - INTERVAL '6 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001108', '10000000-0000-0000-0000-000000000017', 'UG',
        'Short-Term Inventory Finance', 'Restock hardware items and construction supplies before the wet-season market rush',
        6500000, 6, 'Salary — UGX 6,500,000', 'monthly', 1150000,
        '6 months starting April 2026', 'Mbale', 'active',
        NOW() - INTERVAL '7 days', NOW() + INTERVAL '11 days', NULL, 1, 36,
        NOW() - INTERVAL '7 days'
    )
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Kenya loan requests
-- -----------------------------------------------------------------------------
INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period,
    repayment_timeline, district, status, listed_at, expires_at, contracted_at,
    number_of_offers, views_count, created_at
) VALUES
    (
        'c2000000-0000-0000-0000-000000001101', '10000000-0000-0000-0000-000000000018', 'KE',
        'Phone Repair Business Boost', 'Buy spare parts and tools for a growing phone repair kiosk in Westlands',
        180000, 12, 'Salary — KES 150,000', 'monthly', 17000,
        '12 months starting May 2026', 'Nairobi', 'active',
        NOW() - INTERVAL '2 days', NOW() + INTERVAL '19 days', NULL, 1, 52,
        NOW() - INTERVAL '2 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001102', '10000000-0000-0000-0000-000000000019', 'KE',
        'School Fees Support', 'Pay school fees for my daughter in her final year of high school',
        240000, 10, 'Salary — KES 195,000', 'monthly', 26000,
        '10 months starting April 2026', 'Nairobi', 'active',
        NOW() - INTERVAL '3 days', NOW() + INTERVAL '18 days', NULL, 0, 41,
        NOW() - INTERVAL '3 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001103', '10000000-0000-0000-0000-000000000020', 'KE',
        'Furniture Shop Inventory', 'Buy stock and display furniture for a growing home-furnishing kiosk',
        360000, 12, 'Salary — KES 120,000', 'monthly', 32000,
        '12 months starting June 2026', 'Mombasa', 'active',
        NOW() - INTERVAL '4 days', NOW() + INTERVAL '17 days', NULL, 1, 38,
        NOW() - INTERVAL '4 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001104', '10000000-0000-0000-0000-000000000021', 'KE',
        'Taxi Insurance Renewal', 'Renew insurance and buy an extra tyre kit for my matatu business',
        420000, 18, 'Salary — KES 165,000', 'monthly', 28000,
        '18 months starting May 2026', 'Nakuru', 'active',
        NOW() - INTERVAL '2 days', NOW() + INTERVAL '15 days', NULL, 2, 46,
        NOW() - INTERVAL '2 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001105', '10000000-0000-0000-0000-000000000022', 'KE',
        'Small Shop Refit', 'Upgrade shelves, paint work, and signage for a small retail shop in Kisumu',
        560000, 15, 'Salary — KES 135,000', 'monthly', 42000,
        '15 months starting April 2026', 'Kisumu', 'active',
        NOW() - INTERVAL '5 days', NOW() + INTERVAL '13 days', NULL, 1, 35,
        NOW() - INTERVAL '5 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001106', '10000000-0000-0000-0000-000000000023', 'KE',
        'Micro-Clinic Setup', 'Set up a basic maternity and consultation room for a community clinic',
        690000, 24, 'Salary — KES 225,000', 'monthly', 33000,
        '24 months starting June 2026', 'Nairobi', 'active',
        NOW() - INTERVAL '6 days', NOW() + INTERVAL '12 days', NULL, 2, 60,
        NOW() - INTERVAL '6 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001107', '10000000-0000-0000-0000-000000000024', 'KE',
        'Car Repair and Spare Parts', 'Fix my delivery van and buy essential spare parts for my courier route',
        310000, 12, 'Salary — KES 105,000', 'monthly', 29000,
        '12 months starting May 2026', 'Eldoret', 'active',
        NOW() - INTERVAL '1 day', NOW() + INTERVAL '20 days', NULL, 0, 27,
        NOW() - INTERVAL '1 day'
    ),
    (
        'c2000000-0000-0000-0000-000000001108', '10000000-0000-0000-0000-000000000025', 'KE',
        'Second-Hand Machinery Purchase', 'Buy used milling equipment to expand a family grain business in Nakuru',
        820000, 18, 'Salary — KES 180,000', 'monthly', 48000,
        '18 months starting April 2026', 'Nakuru', 'active',
        NOW() - INTERVAL '3 days', NOW() + INTERVAL '16 days', NULL, 1, 44,
        NOW() - INTERVAL '3 days'
    )
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- A few matching offers so they show up in the UI immediately
-- -----------------------------------------------------------------------------
INSERT INTO loan_offers (
    id, request_id, lender_id, offer_amount, interest_rate_pct, late_fee_pct,
    repayment_frequency, installment_amount, proposed_expectations,
    terms_locked_at, status, offered_at, accepted_at, created_at
) VALUES
    (
        'd1000000-0000-0000-0000-000000001101', 'c1000000-0000-0000-0000-000000001101', '10000000-0000-0000-0000-000000000026',
        2200000, 13.5, 2.0, 'monthly', 210000,
        'Can fund the full school fee gap with monthly repayments over 12 months.',
        NOW() - INTERVAL '18 hours', 'pending', NOW() - INTERVAL '18 hours', NULL,
        NOW() - INTERVAL '18 hours'
    ),
    (
        'd1000000-0000-0000-0000-000000001102', 'c1000000-0000-0000-0000-000000001103', '10000000-0000-0000-0000-000000000027',
        7600000, 15.0, 2.0, 'monthly', 340000,
        'Can support the agri-expansion plan at 15% APR with a monthly structure.',
        NOW() - INTERVAL '22 hours', 'pending', NOW() - INTERVAL '22 hours', NULL,
        NOW() - INTERVAL '22 hours'
    ),
    (
        'd1000000-0000-0000-0000-000000001103', 'c1000000-0000-0000-0000-000000001106', '10000000-0000-0000-0000-000000000028',
        5400000, 14.0, 2.0, 'monthly', 320000,
        'Happy to finance the solar installation as a clean-energy related request.',
        NOW() - INTERVAL '16 hours', 'pending', NOW() - INTERVAL '16 hours', NULL,
        NOW() - INTERVAL '16 hours'
    ),
    (
        'd2000000-0000-0000-0000-000000001101', 'c2000000-0000-0000-0000-000000001101', '10000000-0000-0000-0000-000000000026',
        180000, 15.0, 2.0, 'monthly', 17000,
        'Can support the repair business growth with a simple monthly plan.',
        NOW() - INTERVAL '20 hours', 'pending', NOW() - INTERVAL '20 hours', NULL,
        NOW() - INTERVAL '20 hours'
    ),
    (
        'd2000000-0000-0000-0000-000000001102', 'c2000000-0000-0000-0000-000000001104', '10000000-0000-0000-0000-000000000027',
        420000, 16.0, 2.0, 'monthly', 28000,
        'Can offer a flexible plan for the taxi insurance and tyre equipment cost.',
        NOW() - INTERVAL '14 hours', 'pending', NOW() - INTERVAL '14 hours', NULL,
        NOW() - INTERVAL '14 hours'
    ),
    (
        'd2000000-0000-0000-0000-000000001103', 'c2000000-0000-0000-0000-000000001106', '10000000-0000-0000-0000-000000000028',
        690000, 15.5, 2.0, 'monthly', 33000,
        'I can support the community health setup with a structured monthly plan.',
        NOW() - INTERVAL '19 hours', 'pending', NOW() - INTERVAL '19 hours', NULL,
        NOW() - INTERVAL '19 hours'
    )
ON CONFLICT (id) DO NOTHING;

COMMIT;
