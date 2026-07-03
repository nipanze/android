-- ============================================================
-- NIPANZE -- Demo offers for Supabase Cloud
-- Run after sql/public_offer_book_patch.sql.
-- Safe to run multiple times.
-- ============================================================

INSERT INTO loan_offers (
    id,
    request_id,
    lender_id,
    offer_amount,
    proposed_expectations,
    status,
    offered_at,
    created_at
) VALUES
-- Farm Equipment Purchase: partial + full offers
(
    'd1000000-0000-0000-0000-000000000101',
    'c1000000-0000-0000-0000-000000000006',
    '10000000-0000-0000-0000-000000000006',
    3000000,
    'Can fund UGX 3M now for the pump purchase. Comfortable with the 24-month repayment timeline.',
    'pending',
    NOW() - INTERVAL '3 days 7 hours',
    NOW() - INTERVAL '3 days 7 hours'
),
(
    'd1000000-0000-0000-0000-000000000102',
    'c1000000-0000-0000-0000-000000000006',
    '10000000-0000-0000-0000-000000000008',
    6000000,
    'Can fund the full equipment amount if repayments begin as proposed in February.',
    'pending',
    NOW() - INTERVAL '2 days 18 hours',
    NOW() - INTERVAL '2 days 18 hours'
),
(
    'd1000000-0000-0000-0000-000000000103',
    'c1000000-0000-0000-0000-000000000006',
    '10000000-0000-0000-0000-000000000010',
    4000000,
    'Can cover UGX 4M for the tilling equipment, with monthly payments over 24 months.',
    'pending',
    NOW() - INTERVAL '1 day 9 hours',
    NOW() - INTERVAL '1 day 9 hours'
),

-- Vehicle Purchase - Delivery Van: partial + full offers
(
    'd1000000-0000-0000-0000-000000000104',
    'c1000000-0000-0000-0000-000000000007',
    '10000000-0000-0000-0000-000000000006',
    9000000,
    'Happy to fund the full van purchase. Expecting 11% per annum over 24 months.',
    'pending',
    NOW() - INTERVAL '4 days 23 hours',
    NOW() - INTERVAL '4 days 23 hours'
),
(
    'd1000000-0000-0000-0000-000000000105',
    'c1000000-0000-0000-0000-000000000007',
    '10000000-0000-0000-0000-000000000008',
    3000000,
    'Can offer UGX 3M as partial funding for the van deposit and initial repairs.',
    'pending',
    NOW() - INTERVAL '3 days 12 hours',
    NOW() - INTERVAL '3 days 12 hours'
),
(
    'd1000000-0000-0000-0000-000000000106',
    'c1000000-0000-0000-0000-000000000007',
    '10000000-0000-0000-0000-000000000009',
    5000000,
    'Can fund UGX 5M toward the van purchase with slightly faster monthly repayment preferred.',
    'pending',
    NOW() - INTERVAL '2 days 6 hours',
    NOW() - INTERVAL '2 days 6 hours'
)
ON CONFLICT (request_id, lender_id) DO UPDATE
SET
    offer_amount = EXCLUDED.offer_amount,
    proposed_expectations = EXCLUDED.proposed_expectations,
    status = 'pending',
    offered_at = EXCLUDED.offered_at,
    updated_at = NOW();

-- If the sync trigger from public_offer_book_patch.sql is not installed yet,
-- this keeps the marketplace count correct anyway.
UPDATE loan_requests lr
   SET number_of_offers = counts.pending_count
  FROM (
      SELECT request_id, COUNT(*)::INT AS pending_count
        FROM loan_offers
       WHERE status = 'pending'
       GROUP BY request_id
  ) counts
 WHERE lr.id = counts.request_id;

UPDATE loan_requests lr
   SET number_of_offers = 0
 WHERE NOT EXISTS (
     SELECT 1
       FROM loan_offers lo
      WHERE lo.request_id = lr.id
        AND lo.status = 'pending'
 );
