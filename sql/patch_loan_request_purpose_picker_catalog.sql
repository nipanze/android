-- Add the single-purpose-picker display labels and legacy property purposes.
-- Apply after patch_loan_products_part_c_matching.sql.

begin;

alter table public.loan_product_categories
  add column if not exists request_picker_name text;

-- The borrower app reads these public lookup tables with the Supabase anon
-- key. Explicit read policies are needed when the project has RLS enabled.
alter table public.loan_product_categories enable row level security;
alter table public.loan_product_purposes enable row level security;

grant select on public.loan_product_categories, public.loan_product_purposes
  to anon, authenticated;

drop policy if exists loan_product_categories_picker_read
  on public.loan_product_categories;
create policy loan_product_categories_picker_read
  on public.loan_product_categories
  for select to anon, authenticated
  using (true);

drop policy if exists loan_product_purposes_picker_read
  on public.loan_product_purposes;
create policy loan_product_purposes_picker_read
  on public.loan_product_purposes
  for select to anon, authenticated
  using (true);

update public.loan_product_categories
set request_picker_name = case slug
  when 'personal' then 'Personal Loans'
  when 'business' then 'Business Loans'
  when 'asset_financing' then 'Asset Financing'
  when 'agricultural' then 'Agricultural Loans'
  when 'property' then 'Property Loans'
  when 'education' then 'Education Loans'
  when 'lifestyle' then 'Lifestyle Loans'
  else name
end
where request_picker_name is null;

insert into public.loan_product_purposes(category_slug,slug,name,sort_order,is_active)
values
  ('property','solar_energy','Solar / Energy',80,true),
  ('property','water_sanitation','Water & Sanitation',90,true)
on conflict(category_slug,slug) do update
set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

insert into public.financial_capability_loan_product_coverage(
  capability_slug,category_slug,purpose_slug
) values
  ('mortgage_financing','property','solar_energy'),
  ('mortgage_financing','property','water_sanitation')
on conflict do nothing;

commit;
notify pgrst,'reload schema';
