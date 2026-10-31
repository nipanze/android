-- Allow daily repayment schedules and the Retired borrower status.
-- Safe to re-run.

begin;

alter type public.repayment_frequency_enum
  add value if not exists 'daily';

alter table public.loan_requests
  drop constraint if exists chk_lr_repayment_plan,
  drop constraint if exists chk_lr_suggested_repayment_frequency;

alter table public.loan_requests
  add constraint chk_lr_repayment_plan
    check (preferred_repayment_plan in ('daily', 'weekly', 'monthly', 'one_time')),
  add constraint chk_lr_suggested_repayment_frequency
    check (
      suggested_repayment_frequency is null or
      suggested_repayment_frequency in ('daily', 'weekly', 'monthly', 'one_time')
    );

alter table public.loan_offers
  drop constraint if exists chk_lo_repayment_frequency;

alter table public.loan_offers
  add constraint chk_lo_repayment_frequency
    check (repayment_frequency in ('daily', 'weekly', 'monthly', 'one_time'));

-- Upgrade older borrower_information tables that predate currency tracking.
alter table public.borrower_information
  add column if not exists income_currency varchar(3);

update public.borrower_information bi
set income_currency = upper(
  coalesce(nullif(p.income_currency, ''), c.currency_code, 'UGX')
)
from public.profiles p
left join public.countries c on c.code = p.country
where bi.user_id = p.id
  and (bi.income_currency is null or bi.income_currency !~ '^[A-Z]{3}$');

update public.borrower_information
set income_currency = 'UGX'
where income_currency is null or income_currency !~ '^[A-Z]{3}$';

alter table public.borrower_information
  alter column income_currency set default 'UGX',
  alter column income_currency set not null;

alter table public.borrower_information
  drop constraint if exists borrower_information_income_currency_check;

alter table public.borrower_information
  add constraint borrower_information_income_currency_check
    check (income_currency ~ '^[A-Z]{3}$') not valid;

alter table public.borrower_information
  drop constraint if exists borrower_information_employment_status_check;

alter table public.borrower_information
  add constraint borrower_information_employment_status_check
    check (employment_status in (
      'government_employed',
      'private_sector',
      'self_employed',
      'business_owner',
      'student',
      'retired',
      'unemployed'
    )) not valid;

commit;

notify pgrst, 'reload schema';
