-- Expand the currencies available in Forex filters, listings, and offers.
-- Apply this patch to existing databases. It is safe to run more than once.

INSERT INTO currencies (
    code,
    name,
    is_market_currency,
    market_country,
    forex_trading_enabled
) VALUES
    ('BIF', 'Burundian Franc',      FALSE, NULL, TRUE),
    ('SSP', 'South Sudanese Pound', FALSE, NULL, TRUE),
    ('CDF', 'Congolese Franc',      FALSE, NULL, TRUE),
    ('SOS', 'Somali Shilling',      FALSE, NULL, TRUE),
    ('ETB', 'Ethiopian Birr',       FALSE, NULL, TRUE),
    ('DJF', 'Djiboutian Franc',     FALSE, NULL, TRUE),
    ('ERN', 'Eritrean Nakfa',       FALSE, NULL, TRUE),
    ('SDG', 'Sudanese Pound',       FALSE, NULL, TRUE),
    ('KMF', 'Comorian Franc',       FALSE, NULL, TRUE),
    ('MGA', 'Malagasy Ariary',      FALSE, NULL, TRUE),
    ('MWK', 'Malawian Kwacha',      FALSE, NULL, TRUE),
    ('MUR', 'Mauritian Rupee',      FALSE, NULL, TRUE),
    ('SCR', 'Seychellois Rupee',    FALSE, NULL, TRUE),
    ('ZMW', 'Zambian Kwacha',       FALSE, NULL, TRUE),
    ('ZWG', 'Zimbabwe Gold',        FALSE, NULL, TRUE),
    ('MZN', 'Mozambican Metical',   FALSE, NULL, TRUE),
    ('EUR', 'Euro',                 FALSE, NULL, TRUE),
    ('GBP', 'British Pound',        FALSE, NULL, TRUE),
    ('AED', 'UAE Dirham',           FALSE, NULL, TRUE),
    ('INR', 'Indian Rupee',         FALSE, NULL, TRUE),
    ('JPY', 'Japanese Yen',         FALSE, NULL, TRUE),
    ('CAD', 'Canadian Dollar',      FALSE, NULL, TRUE),
    ('AUD', 'Australian Dollar',    FALSE, NULL, TRUE),
    ('CHF', 'Swiss Franc',          FALSE, NULL, TRUE),
    ('CNY', 'Chinese Yuan',         FALSE, NULL, TRUE)
ON CONFLICT (code) DO UPDATE
SET forex_trading_enabled = TRUE;
