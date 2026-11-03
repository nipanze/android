-- Add structured classifications while retaining the existing free-text purpose.
-- Safe to re-run; existing requests remain available.

begin;

alter table public.loan_requests
  add column if not exists loan_category text,
  add column if not exists loan_purpose text;

-- Backfill only rows with recognizable legacy titles. Unrecognized records stay
-- available with null structured fields for later review.
update public.loan_requests
set loan_category = case
  when lower(title) ~ 'school|university|tuition|certification|education' then 'Education Loans'
  when lower(title) ~ 'medical|clinic|surgery|health' then 'Personal Loans'
  when lower(title) ~ 'boda|motorcycle|vehicle|van|car|commercial van' then 'Asset Financing'
  when lower(title) ~ 'farm|irrigation|crop|tractor|agri' then 'Agricultural Loans'
  when lower(title) ~ 'land|home|property|mortgage|renovation' then 'Property Loans'
  when lower(title) ~ 'inventory|stock|working capital|working|business|bakery|shop|tailor|equipment upgrade|startup|expansion|agribusiness|phone repair' then 'Business Loans'
  else 'Personal Loans' end,
    loan_purpose = case
  when lower(title) ~ 'school|university|tuition|certification|education' then case
      when lower(title) ~ 'certification|professional' then 'Professional Courses'
      when lower(title) ~ 'university|tuition' then 'University Tuition'
      else 'School Fees' end
  when lower(title) ~ 'medical|clinic|surgery|health' then 'Medical Expenses'
  when lower(title) ~ 'boda|motorcycle|vehicle|van|car|commercial van' then case
      when lower(title) ~ 'boda' then 'Boda Boda Financing'
      when lower(title) ~ 'motorcycle' then 'Motorcycle Financing'
      else 'Car Financing' end
  when lower(title) ~ 'farm|irrigation|crop|tractor|agri' then case
      when lower(title) ~ 'irrigation|equipment' then 'Agricultural Equipment'
      else 'Crop Production' end
  when lower(title) ~ 'land|home|property|mortgage|renovation' then case
      when lower(title) ~ 'renovation|improvement' then 'Home Improvement'
      when lower(title) ~ 'construction' then 'Home Construction'
      else 'Other Property Needs' end
  when lower(title) ~ 'inventory|stock|working capital|working|business|bakery|shop|tailor|equipment upgrade|startup|expansion|agribusiness|phone repair' then case
      when lower(title) ~ 'inventory|stock|restock' then 'Inventory / Stock Purchase'
      when lower(title) ~ 'working capital' then 'Working Capital'
      when lower(title) ~ 'equipment|machine|tailor|phone repair' then 'Equipment for Business'
      when lower(title) ~ 'expansion|boost' then 'Business Expansion'
      else 'Other Business Needs' end
  else 'Other Personal Needs' end
where loan_category is null or loan_purpose is null;

create index if not exists idx_loan_requests_category_purpose
  on public.loan_requests (loan_category, loan_purpose);

commit;

notify pgrst, 'reload schema';
