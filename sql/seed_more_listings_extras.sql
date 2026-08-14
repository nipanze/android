-- Extra marketplace seeds separated from seed_more_listings.sql
-- Paste this after running seed_more_listings.sql to avoid duplication.

-- Additional seeded rows

-- Ensure currencies used by these extras exist and are enabled for forex trading.
-- Idempotent: safe to run multiple times in Supabase SQL editor.
INSERT INTO currencies (code, name, is_market_currency, market_country, forex_trading_enabled)
VALUES
    ('EUR', 'Euro', FALSE, NULL, TRUE),
    ('USD', 'US Dollar', FALSE, NULL, TRUE),
    ('UGX', 'Ugandan Shilling', TRUE, 'UG', TRUE),
    ('KES', 'Kenyan Shilling', TRUE, 'KE', TRUE),
    ('NGN', 'Nigerian Naira', TRUE, 'NG', TRUE)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    is_market_currency = EXCLUDED.is_market_currency,
    market_country = EXCLUDED.market_country,
    forex_trading_enabled = EXCLUDED.forex_trading_enabled;


-- Extra loan requests
INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period, repayment_timeline,
    has_collateral, district, suggested_interest_rate_pct, suggested_late_fee_pct, suggested_repayment_frequency, suggested_installment_amount,
    terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000002', 'UG', 'Inventory restock', 'Restock fast-moving goods', 800000, 4, 'Shop sales', 'monthly', 200000, '4 monthly instalments', TRUE, 'Kampala', 9.0, 1.5, 'monthly', 200000, NOW(), 0, 'active', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period, repayment_timeline,
    has_collateral, district, suggested_interest_rate_pct, suggested_late_fee_pct, suggested_repayment_frequency, suggested_installment_amount,
    terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000003', 'KE', 'Kiosk expansion', 'Build additional stall space', 250000, 6, 'Kiosk sales', 'monthly', 41666, '6 monthly instalments', FALSE, 'Nairobi Central', 12.0, 2.0, 'monthly', 41666, NOW(), 0, 'active', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days')
ON CONFLICT (id) DO NOTHING;

-- Extra loan offers
INSERT INTO loan_offers (
    id, request_id, lender_id, offer_amount, interest_rate_pct, late_fee_pct,
    repayment_frequency, installment_amount, proposed_expectations, terms_locked_at, status, offered_at, created_at, updated_at
) VALUES
('21000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000007', 800000, 9.5, 1.5, 'monthly', 210000, 'Standard approval', NOW(), 'pending', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO loan_offers (
    id, request_id, lender_id, offer_amount, interest_rate_pct, late_fee_pct,
    repayment_frequency, installment_amount, proposed_expectations, terms_locked_at, status, offered_at, created_at, updated_at
) VALUES
('21000000-0000-0000-0000-000000000005', '20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000008', 260000, 11.0, 2.0, 'monthly', 43333, 'Fast disbursement', NOW(), 'pending', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

-- Extra forex requests
INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount, preferred_rate,
    settlement_preference, is_urgent, terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', 'UG', 'UGX', 'EUR', 1000000, NULL, 'Bank transfer', FALSE, NOW(), 0, 'active', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount, preferred_rate,
    settlement_preference, is_urgent, terms_locked_at, number_of_offers, status, listed_at, created_at, updated_at
) VALUES
('30000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000003', 'KE', 'KES', 'USD', 50000, NULL, 'Mobile money', TRUE, NOW(), 0, 'active', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

-- Extra forex offers
INSERT INTO forex_offers (
    id, request_id, offer_maker_id, rate_offered, amount_available, terms, terms_locked_at, status, offered_at, created_at, updated_at
) VALUES
('31000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000008', 0.00026, 1000000, 'Bank transfer same day', NOW(), 'pending', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_offers (
    id, request_id, offer_maker_id, rate_offered, amount_available, terms, terms_locked_at, status, offered_at, created_at, updated_at
) VALUES
('31000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000007', 0.0095, 50000, 'Mobile money within 1 hour', NOW(), 'pending', NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours')
ON CONFLICT (id) DO NOTHING;

-- End of additional marketplace seeds
