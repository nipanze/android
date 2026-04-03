-- ============================================
-- RLS AUDIT QUERIES — Nipanze v5.0
-- Run these against the cloud project to verify
-- no data leaks before going live.
-- ============================================

-- 1. Confirm v_loan_listings has no borrower_id column
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'v_loan_listings'
  AND column_name IN ('borrower_id', 'email', 'phone', 'full_name', 'credit_score');
-- Expected: 0 rows

-- 2. Confirm audit_logs UPDATE is blocked (run as any authenticated user)
UPDATE audit_logs SET description = 'tamper test' WHERE id IS NOT NULL;
-- Expected: ERROR or 0 rows affected

-- 3. Confirm audit_logs DELETE is blocked
DELETE FROM audit_logs WHERE id IS NOT NULL;
-- Expected: ERROR or 0 rows affected

-- 4. Confirm loan_bids exposes lender_token not lender_id in order book query
SELECT lb.id, lb.interest_rate, lb.amount, p.lender_token
FROM loan_bids lb
JOIN profiles p ON p.id = lb.lender_id
WHERE lb.status = 'pending'
LIMIT 5;
-- Expected: lender_token column (e.g. L-#482), no name/email/phone

-- 5. Confirm a user cannot read another user's profile
-- (run as user A, substitute user_B_id with a real UUID)
SELECT * FROM profiles WHERE id != auth.uid();
-- Expected: 0 rows (RLS blocks cross-user reads)

-- 6. Confirm v_user_portfolio only returns the calling user's row
SELECT * FROM v_user_portfolio;
-- Expected: exactly 1 row matching auth.uid()

-- 7. Confirm watchlist rows are user-scoped
SELECT * FROM watchlist WHERE user_id != auth.uid();
-- Expected: 0 rows

-- 8. Confirm notifications are user-scoped
SELECT * FROM notifications WHERE user_id != auth.uid();
-- Expected: 0 rows

-- 9. Confirm contracts only visible to matched parties
-- (run as a user not in borrower_id or lender_id)
SELECT * FROM contracts
WHERE borrower_id != auth.uid() AND lender_id != auth.uid();
-- Expected: 0 rows

-- 10. Check refresh token rotation chain is intact
SELECT id, replaced_by, revoked, expires_at
FROM refresh_tokens
WHERE user_id = auth.uid()
ORDER BY issued_at DESC
LIMIT 5;
-- Expected: most recent token has replaced_by = NULL, earlier tokens have it set

-- 11. Confirm kyc-documents bucket is private
-- (verify via Supabase dashboard Storage → kyc-documents → policies)
-- No public read policy should exist.

-- 12. Active subscription count sanity check
SELECT COUNT(*) FROM subscriptions
WHERE status = 'active'
GROUP BY user_id
HAVING COUNT(*) > 1;
-- Expected: 0 rows (unique index uidx_sub_active_user enforces one active sub per user)