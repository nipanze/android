-- ============================================
-- NIPANZE Seed Patch v2.1
-- Updates income_source to show only income type (no employer names)
-- Apply AFTER seed.sql is already loaded
-- ============================================

-- STEP 5: UPDATE loan_requests income_source
-- Remove employer names, keep only income type + amount

UPDATE loan_requests SET 
  income_source='Salary — UGX 4,500,000'
WHERE id='c1000000-0000-0000-0000-000000000001';

UPDATE loan_requests SET 
  income_source='Salary — UGX 3,200,000'
WHERE id='c1000000-0000-0000-0000-000000000002';

UPDATE loan_requests SET 
  income_source='Salary — UGX 5,800,000'
WHERE id='c1000000-0000-0000-0000-000000000003';

UPDATE loan_requests SET 
  income_source='Business income — UGX 2,800,000'
WHERE id='c1000000-0000-0000-0000-000000000004';

UPDATE loan_requests SET 
  income_source='Salary — UGX 3,300,000'
WHERE id='c1000000-0000-0000-0000-000000000005';

UPDATE loan_requests SET 
  income_source='Salary — UGX 2,900,000'
WHERE id='c1000000-0000-0000-0000-000000000006';

UPDATE loan_requests SET 
  income_source='Salary — UGX 5,200,000'
WHERE id='c1000000-0000-0000-0000-000000000007';

UPDATE loan_requests SET 
  income_source='Salary — UGX 6,500,000'
WHERE id='c1000000-0000-0000-0000-000000000008';

-- ============================================
-- VERIFICATION
-- ============================================

SELECT COUNT(*) as updated_records
FROM loan_requests 
WHERE income_source LIKE '% — UGX %'
  AND income_source NOT LIKE '%From%'
  AND income_source NOT LIKE '%salary from%';

SELECT '✅ Patch v2.1 applied successfully' AS status;