-- Align Loans & Financing provider selection with the four supported
-- top-level services. Capability slugs and provider records remain unchanged.
BEGIN;

UPDATE public.need_capabilities
SET service_group_slug = 'personal_financing',
    service_group_name = 'Personal Loans',
    service_sort_order = CASE
      WHEN slug IN ('personal_loan_services', 'emergency_loan_services',
                    'salary_loan_services', 'medical_financing') THEN service_sort_order
      ELSE 50 + service_sort_order
    END
WHERE category_slug = 'financial_services'
  AND service_group_slug IN (
    'personal_financing',
    'agricultural_financing',
    'education_financing',
    'lifestyle_financing'
  );

UPDATE public.need_capabilities
SET service_group_name = 'Business Financing'
WHERE category_slug = 'financial_services'
  AND service_group_slug = 'business_financing';

UPDATE public.need_capabilities
SET service_group_name = 'Asset Financing'
WHERE category_slug = 'financial_services'
  AND service_group_slug = 'asset_financing';

UPDATE public.need_capabilities
SET service_group_name = 'Property Financing'
WHERE category_slug = 'financial_services'
  AND service_group_slug = 'property_financing';

COMMIT;
