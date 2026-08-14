-- Additional seed data: more loan_requests, loan_offers, forex_requests, forex_offers
-- Idempotent INSERTs safe to paste into Supabase SQL editor.

-- ======= LOAN REQUESTS =======
INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period, repayment_timeline,
    has_collateral, collateral_details, collateral_estimated_value, collateral_location,
    suggested_interest_rate_pct, suggested_late_fee_pct, suggested_repayment_frequency, suggested_installment_amount,
    terms_locked_at, district, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'UG', 'Working capital for shop', 'Top-up inventory and supplier payments', 1500000, 6, 'Monthly salary and shop takings', 'monthly', 250000, '6 monthly instalments', TRUE, 'Stock as collateral', 2000000, 'Kampala - Makindye', 8.5, 2.0, 'monthly', 250000, NOW(), 'Central', 0, 'active', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period, repayment_timeline,
    has_collateral, district, suggested_interest_rate_pct, suggested_late_fee_pct, suggested_repayment_frequency, suggested_installment_amount,
    terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'UG', 'Motorbike purchase', 'Buy a motorbike for deliveries', 3000000, 12, 'Delivery income', 'monthly', 260000, '12 monthly instalments', FALSE, 'Central', 10.0, 2.5, 'monthly', 260000, NOW(), 0, 'active', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period, repayment_timeline,
    has_collateral, district, suggested_interest_rate_pct, suggested_late_fee_pct, suggested_repayment_frequency, suggested_installment_amount,
    terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000018', 'KE', 'Seed capital for kiosk', 'Initial stock and rent', 80000, 3, 'Small kiosk sales', 'weekly', 7000, '12 weekly instalments', FALSE, 'Nairobi West', 12.0, 3.0, 'weekly', 7000, NOW(), 0, 'active', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period, repayment_timeline,
    has_collateral, district, suggested_interest_rate_pct, suggested_late_fee_pct, suggested_repayment_frequency, suggested_installment_amount,
    terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000003', 'UG', 'School fees advance', 'Pay term fees for children', 600000, 4, 'Salary and side business', 'monthly', 150000, '4 monthly instalments', FALSE, 'Central', 9.0, 1.5, 'monthly', 150000, NOW(), 0, 'active', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period, repayment_timeline,
    has_collateral, district, suggested_interest_rate_pct, suggested_late_fee_pct, suggested_repayment_frequency, suggested_installment_amount,
    terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000005', 'UG', 'Expand workshop', 'Buy tools and rent larger workspace', 5000000, 18, 'Workshop income', 'monthly', 277777, '18 monthly instalments', TRUE, 'Wakiso', 11.0, 2.0, 'monthly', 277777, NOW(), 0, 'active', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days')
ON CONFLICT (id) DO NOTHING;

-- ======= LOAN OFFERS =======
INSERT INTO loan_offers (
    id, request_id, lender_id, offer_amount, interest_rate_pct, late_fee_pct,
    repayment_frequency, installment_amount, proposed_expectations, terms_locked_at, status, offered_at, created_at, updated_at
) VALUES
('21000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000006', 1500000, 9.0, 1.5, 'monthly', 260000, 'Collateral appraisal required', NOW(), 'pending', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO loan_offers (
    id, request_id, lender_id, offer_amount, interest_rate_pct, late_fee_pct,
    repayment_frequency, installment_amount, proposed_expectations, terms_locked_at, status, offered_at, created_at, updated_at
) VALUES
('21000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000007', 3000000, 10.0, 2.0, 'monthly', 275000, 'Proof of ownership for collateral', NOW(), 'pending', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO loan_offers (
    id, request_id, lender_id, offer_amount, interest_rate_pct, late_fee_pct,
    repayment_frequency, installment_amount, proposed_expectations, terms_locked_at, status, offered_at, created_at, updated_at
) VALUES
('21000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 100000, 7.5, 1.0, 'weekly', 10000, 'Quick settlement preferred', NOW(), 'pending', NOW() - INTERVAL '1 days', NOW() - INTERVAL '1 days', NOW() - INTERVAL '1 days')
ON CONFLICT (id) DO NOTHING;


-- ======= FOREX REQUESTS =======
INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount, preferred_rate,
    settlement_preference, is_urgent, terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'UG', 'UGX', 'USD', 5000000, NULL, 'Bank transfer', FALSE, NOW(), 0, 'active', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount, preferred_rate,
    settlement_preference, is_urgent, terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'UG', 'UGX', 'KES', 2000000, NULL, 'Mobile money', TRUE, NOW(), 0, 'active', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount, preferred_rate,
    settlement_preference, is_urgent, terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000006', 'UG', 'UGX', 'NGN', 10000000, NULL, 'In-person', FALSE, NOW(), 0, 'active', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount, preferred_rate,
    settlement_preference, is_urgent, terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000018', 'KE', 'KES', 'UGX', 150000, NULL, 'Bank transfer', FALSE, NOW(), 0, 'active', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days')
ON CONFLICT (id) DO NOTHING;

-- ======= FOREX OFFERS =======
INSERT INTO forex_offers (
    id, request_id, offer_maker_id, rate_offered, amount_available, terms, terms_locked_at, status, offered_at, created_at, updated_at
) VALUES
('31000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000008', 0.00028, 5000000, 'Bank transfer next day', NOW(), 'pending', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_offers (
    id, request_id, offer_maker_id, rate_offered, amount_available, terms, terms_locked_at, status, offered_at, created_at, updated_at
) VALUES
('31000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000007', 0.000101, 2000000, 'Mobile money within 2 hours', NOW(), 'pending', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours')
ON CONFLICT (id) DO NOTHING;

-- End of additional marketplace seeds
