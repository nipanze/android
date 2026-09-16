-- Enable authenticated users to post Needs requests.
-- This leaves existing seeded rows intact while adding ownership for new rows.

alter table if exists public.needs_requests
  add column if not exists requester_id uuid references auth.users(id)
    on delete set null;

create index if not exists needs_requests_requester_id_idx
  on public.needs_requests(requester_id);

create index if not exists needs_requests_active_country_idx
  on public.needs_requests(country, listed_at desc)
  where status = 'active';

alter table if exists public.needs_requests enable row level security;

drop policy if exists "Anyone can read active needs requests"
  on public.needs_requests;
create policy "Anyone can read active needs requests"
  on public.needs_requests
  for select
  to anon, authenticated
  using (status = 'active');

drop policy if exists "Authenticated users can create own needs requests"
  on public.needs_requests;
create policy "Authenticated users can create own needs requests"
  on public.needs_requests
  for insert
  to authenticated
  with check (requester_id = auth.uid());

drop policy if exists "Users can update own needs requests"
  on public.needs_requests;
create policy "Users can update own needs requests"
  on public.needs_requests
  for update
  to authenticated
  using (requester_id = auth.uid())
  with check (requester_id = auth.uid());

create or replace view public.v_needs_listings as
select
  request_id,
  title,
  specification,
  category,
  budget,
  currency,
  location,
  country,
  urgency,
  status,
  listed_at,
  created_at,
  trust_is_verified
from public.needs_requests
where status = 'active';

grant select on public.needs_requests to anon, authenticated;
grant insert, update on public.needs_requests to authenticated;
grant select on public.v_needs_listings to anon, authenticated;
