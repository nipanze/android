-- Clean repeated Kenya forex settlement strings so the marketplace card shows either:
--   - a single settlement label, and
--   - the Nairobi location separately,
-- without duplicate bank names or repeated labels in one string.

BEGIN;

-- Generic bank settlement: keep the location in the city field, not repeated in the label.
UPDATE public.forex_requests
SET settlement_preference = 'Bank transfer, Nairobi'
WHERE country = 'KE' AND (
    lower(settlement_preference) LIKE '%equity bank%' OR
    lower(settlement_preference) LIKE '%kcb%' OR
    lower(settlement_preference) LIKE '%bank transfer%'
);

-- M-Pesa settlement: no repeated mobile label or extra bank wording.
UPDATE public.forex_requests
SET settlement_preference = 'M-Pesa transfer, Nairobi'
WHERE country = 'KE' AND (
    lower(settlement_preference) LIKE '%m-pesa%' OR
    lower(settlement_preference) LIKE '%mpesa%' OR
    lower(settlement_preference) LIKE '%mobile money%'
);

-- Keep only a single Nairobi city entry for Kenya examples.
UPDATE public.forex_requests
SET settlement_preference = 'M-Pesa transfer, Nairobi'
WHERE country = 'KE'
  AND lower(settlement_preference) = 'm-pesa transfer, nairobi';

COMMIT;
