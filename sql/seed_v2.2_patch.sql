-- ============================================
-- NIPANZE Seed Patch v2.2
-- Adds government / small business employment type options
-- Apply AFTER seed.sql is already loaded
-- ============================================

BEGIN;
ALTER TYPE employment_type_enum ADD VALUE IF NOT EXISTS 'government_employee';
ALTER TYPE employment_type_enum ADD VALUE IF NOT EXISTS 'small_business_owner';
COMMIT;

BEGIN;
UPDATE profiles SET
  employment_type='government_employee',
  employer_name='Uganda Revenue Authority'
WHERE id='10000000-0000-0000-0000-000000000001';

UPDATE profiles SET
  employment_type='small_business_owner',
  employer_name='Nakato Boutique'
WHERE id='10000000-0000-0000-0000-000000000004';
COMMIT;

SELECT '✅ Patch v2.2 applied successfully' AS status;
