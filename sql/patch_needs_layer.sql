-- ============================================================
-- Standalone SQL Patch: patch_needs_layer.sql
-- Description: Adds the Needs Layer (Stage 4.8) — Categories,
-- Capabilities, Extended Needs Requests, Need Offers, Contact Reveals,
-- Provider Capabilities with verification levels, Interests,
-- Views, Triggers, and Atomic RPCs.
-- ============================================================

-- 1. DROP OLD VIEW FIRST (to allow modifying column types)
drop view if exists public.v_needs_listings cascade;

-- 2. BASE TABLE MODIFICATIONS & PRIVACY FIX
alter table if exists public.needs_requests
  alter column budget type bigint,
  add column if not exists category_slug text default 'specialized_products',
  add column if not exists capability_slug text,
  add column if not exists details jsonb default '{}'::jsonb,
  add column if not exists number_of_offers integer not null default 0,
  add column if not exists expires_at timestamptz default (now() + interval '30 days'),
  add column if not exists terms_locked_at timestamptz,
  add column if not exists contracted_at timestamptz,
  add column if not exists cancelled_at timestamptz,
  add column if not exists views_count integer not null default 0;

-- Ensure status constraint is valid
alter table if exists public.needs_requests drop constraint if exists chk_needs_requests_status;
alter table if exists public.needs_requests
  add constraint chk_needs_requests_status
  check (status in ('active', 'matched', 'expired', 'cancelled'));

-- 3. REFERENCE TABLES: need_categories & need_capabilities
create table if not exists public.need_categories (
  slug text primary key,
  name text not null,
  icon text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.need_categories (slug, name, icon, sort_order, is_active)
values
  ('travel_international', 'Travel & International', '✈️', 1, false),
  ('machinery_equipment', 'Machinery & Equipment', '🚜', 2, true),
  ('professional_services', 'Professional Services', '🧑‍💼', 3, true),
  ('transport_logistics', 'Transport & Logistics', '🚚', 4, true),
  ('specialized_products', 'Specialized Products & Procurement', '🔎', 5, true)
on conflict (slug) do update set
  name = excluded.name,
  icon = excluded.icon,
  sort_order = excluded.sort_order;

create table if not exists public.need_capabilities (
  slug text primary key,
  category_slug text not null references public.need_categories(slug) on delete cascade,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.need_capabilities (slug, category_slug, name, is_active)
values
  ('visa_assistance', 'travel_international', 'Visa Assistance', true),
  ('flight_tickets', 'travel_international', 'Flight Tickets & Bookings', true),
  ('hajj_umrah', 'travel_international', 'Hajj & Umrah Travel', true),
  ('excavator_hire', 'machinery_equipment', 'Excavator Hire', true),
  ('tractor_hire', 'machinery_equipment', 'Tractor & Farm Machinery', true),
  ('generator_hire', 'machinery_equipment', 'Industrial Generators', true),
  ('company_registration', 'professional_services', 'Company Registration & Legal', true),
  ('accounting_tax', 'professional_services', 'Accounting & Tax Advisory', true),
  ('engineering_consulting', 'professional_services', 'Engineering Consulting', true),
  ('heavy_haulage', 'transport_logistics', 'Heavy Freight & Bulk Haulage', true),
  ('courier_delivery', 'transport_logistics', 'Courier & Express Delivery', true),
  ('cold_chain_transport', 'transport_logistics', 'Cold Chain & Refrigerated', true),
  ('bulk_procurement', 'specialized_products', 'Bulk Industrial Procurement', true),
  ('medical_supplies', 'specialized_products', 'Medical & Lab Supplies', true),
  ('electronic_hardware', 'specialized_products', 'Specialized Electronics & Parts', true)
on conflict (slug) do update set
  name = excluded.name,
  category_slug = excluded.category_slug;

-- Foreign key from needs_requests to need_categories
alter table if exists public.needs_requests drop constraint if exists fk_needs_requests_category_slug;
alter table if exists public.needs_requests
  add constraint fk_needs_requests_category_slug
  foreign key (category_slug) references public.need_categories(slug)
  on update cascade on delete set default;

-- 4. PROVIDER CAPABILITIES & PROGRESSIVE VERIFICATION
create table if not exists public.provider_capabilities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  capability_slug text not null references public.need_capabilities(slug) on delete cascade,
  verification_level text not null default 'self_declared' check (verification_level in ('self_declared', 'provider_verified')),
  evidence_url text,
  verified_by uuid references auth.users(id) on delete set null,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  unique(user_id, capability_slug)
);

create index if not exists idx_provider_capabilities_user on public.provider_capabilities(user_id);
create index if not exists idx_provider_capabilities_capability on public.provider_capabilities(capability_slug);

-- Trigger: enforce verification level cannot be elevated by non-admin
create or replace function private.trg_enforce_provider_capability_verification()
returns trigger language plpgsql security definer as $$
declare
  v_is_admin boolean := false;
begin
  begin
    v_is_admin := exists (
      select 1 from public.profiles
      where id = auth.uid() and is_admin = true
    );
  exception when others then
    v_is_admin := false;
  end;

  if not v_is_admin then
    NEW.verification_level := 'self_declared';
    NEW.verified_by := null;
    NEW.verified_at := null;
  else
    if NEW.verification_level = 'provider_verified' and (OLD is null or OLD.verification_level <> 'provider_verified') then
      NEW.verified_by := auth.uid();
      NEW.verified_at := coalesce(NEW.verified_at, now());
    end if;
  end if;

  return NEW;
end;
$$;

drop trigger if exists trg_provider_capability_verification on public.provider_capabilities;
create trigger trg_provider_capability_verification
  before insert or update on public.provider_capabilities
  for each row execute function private.trg_enforce_provider_capability_verification();

-- 5. NEED OFFERS TABLE
create table if not exists public.need_offers (
  id uuid primary key default gen_random_uuid(),
  need_id uuid not null references public.needs_requests(request_id) on delete cascade,
  offer_maker_id uuid not null references auth.users(id) on delete cascade,
  price bigint not null check (price >= 0),
  currency text not null default 'UGX',
  timeline_text text not null default '',
  message text not null default '',
  terms_locked_at timestamptz,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'withdrawn', 'expired')),
  offered_at timestamptz not null default now(),
  accepted_at timestamptz,
  withdrawn_at timestamptz,
  expires_at timestamptz default (now() + interval '14 days'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(need_id, offer_maker_id)
);

create index if not exists idx_need_offers_need_id on public.need_offers(need_id);
create index if not exists idx_need_offers_maker on public.need_offers(offer_maker_id);

-- 6. NEED CONTACT REVEALS
create table if not exists public.need_contact_reveals (
  id uuid primary key default gen_random_uuid(),
  need_id uuid not null references public.needs_requests(request_id) on delete cascade,
  offer_id uuid not null references public.need_offers(id) on delete cascade,
  requester_id uuid not null references auth.users(id),
  provider_id uuid not null references auth.users(id),
  unlocked_by uuid not null references auth.users(id),
  unlocked_at timestamptz not null default now(),
  unique(offer_id)
);

create index if not exists idx_need_contact_reveals_need on public.need_contact_reveals(need_id);
create index if not exists idx_need_contact_reveals_parties on public.need_contact_reveals(requester_id, provider_id);

-- 7. USER INTERESTS & INTEREST EVENTS
create table if not exists public.user_interests (
  user_id uuid not null references auth.users(id) on delete cascade,
  category_slug text not null references public.need_categories(slug) on delete cascade,
  kind text not null default 'explicit' check (kind in ('explicit', 'follow', 'mute')),
  created_at timestamptz not null default now(),
  primary key (user_id, category_slug)
);

create table if not exists public.user_interest_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_slug text not null references public.need_categories(slug) on delete cascade,
  event text not null check (event in ('view', 'watchlist', 'post', 'offer')),
  created_at timestamptz not null default now()
);

create index if not exists idx_user_interest_events_user on public.user_interest_events(user_id, created_at desc);

-- 8. SYSTEM SETTINGS FOR NEEDS
insert into public.system_settings (key, value, description)
values
  ('needs_free_offers_per_month', '3', 'Free subscription plan monthly offer cap on Needs'),
  ('max_active_needs_free', '3', 'Max active Needs for free plan'),
  ('max_active_needs_lender', '8', 'Max active Needs for lender plan'),
  ('max_active_needs_pro', '20', 'Max active Needs for pro plan')
on conflict (key) do nothing;

-- 9. BACKFILL EXISTING SAMPLE REQUESTS
update public.needs_requests
set category_slug = case
  when lower(title) ~ 'pump|mill|oven|mixer|fridge|machine|tank|generator|huller|sheller|freezer|chiller' then 'machinery_equipment'
  when lower(title) ~ 'truck|van|delivery|transport|haulage|cement' then 'transport_logistics'
  when lower(title) ~ 'visa|flight|travel|hajj|umrah|passport' then 'travel_international'
  when lower(title) ~ 'registration|audit|legal|lawyer|accounting|consulting|tax' then 'professional_services'
  when lower(category) ~ 'business equipment|home & energy|agriculture|community|technology' then 'machinery_equipment'
  when lower(category) ~ 'education|health' then 'professional_services'
  when lower(category) ~ 'transport' then 'transport_logistics'
  else 'specialized_products'
end,
expires_at = coalesce(expires_at, now() + interval '30 days')
where category_slug is null or category_slug = 'specialized_products';

-- 10. REBUILD v_needs_listings (Excludes requester_id from public read, joins trust)
create or replace view public.v_needs_listings as
select
  nr.request_id,
  nr.title,
  nr.specification,
  nr.category_slug,
  nc.name as category,
  nc.icon as category_icon,
  nr.capability_slug,
  nr.details,
  nr.budget,
  nr.currency,
  nr.location,
  nr.country,
  nr.urgency,
  nr.status,
  nr.number_of_offers,
  case
    when nr.number_of_offers = 0 then 'no_offers'
    when nr.number_of_offers between 1 and 2 then 'low_coverage'
    when nr.number_of_offers between 3 and 5 then 'good_coverage'
    else 'high_coverage'
  end as offer_coverage_tier,
  nr.expires_at,
  case
    when nr.expires_at <= now() then 'Expired'
    when nr.expires_at - now() < interval '1 day' then
      concat(extract(hour from (nr.expires_at - now()))::int, 'h left')
    else
      concat(extract(day from (nr.expires_at - now()))::int, 'd left')
  end as time_remaining,
  nr.listed_at,
  nr.created_at,
  coalesce(p.kyc_status = 'approved', nr.trust_is_verified) as trust_is_verified,
  coalesce(p.phone_verified_at is not null, false) as trust_phone_verified,
  ta.rating_avg as trust_rating_avg,
  ta.review_count as trust_review_count,
  ta.completed_deals_count as trust_completed_deals_count,
  coalesce(ta.completed_deals_count > 1, false) as trust_is_repeat_participant
from public.needs_requests nr
left join public.need_categories nc on nc.slug = nr.category_slug
left join public.profiles p on p.id = nr.requester_id
left join public.trust_aggregates ta on ta.user_id = nr.requester_id
where nr.status = 'active'
  and (nr.expires_at is null or nr.expires_at > now())
  and (
    auth.uid() is null
    or (
      nr.requester_id is distinct from auth.uid()
      and not exists (
        select 1 from public.user_blocks ub
        where (
          (ub.blocker_id = auth.uid() and ub.blocked_id = nr.requester_id)
          or (ub.blocker_id = nr.requester_id and ub.blocked_id = auth.uid())
        )
        and ub.created_at <= nr.listed_at::timestamp
      )
    )
  );

create or replace view public.v_provider_badges as
select
  pc.user_id,
  pc.capability_slug,
  nc.name as capability_name,
  nc.category_slug,
  cat.name as category_name,
  cat.icon as category_icon,
  pc.verification_level,
  p.kyc_status = 'approved' as kyc_verified,
  p.phone_verified_at is not null as phone_verified
from public.provider_capabilities pc
join public.need_capabilities nc on nc.slug = pc.capability_slug
join public.need_categories cat on cat.slug = nc.category_slug
join public.profiles p on p.id = pc.user_id;

-- 11. ROW LEVEL SECURITY & PRIVACY POLICIES

-- Privacy fix on needs_requests: revoke direct anon select
revoke select on public.needs_requests from anon;

alter table public.needs_requests enable row level security;
alter table public.need_categories enable row level security;
alter table public.need_capabilities enable row level security;
alter table public.provider_capabilities enable row level security;
alter table public.need_offers enable row level security;
alter table public.need_contact_reveals enable row level security;
alter table public.user_interests enable row level security;
alter table public.user_interest_events enable row level security;

-- Policies for need_categories & need_capabilities: public read
drop policy if exists "Categories are viewable by everyone" on public.need_categories;
create policy "Categories are viewable by everyone" on public.need_categories for select using (true);

drop policy if exists "Capabilities are viewable by everyone" on public.need_capabilities;
create policy "Capabilities are viewable by everyone" on public.need_capabilities for select using (true);

-- Policies for needs_requests
drop policy if exists "Owner or admin can view own needs base rows" on public.needs_requests;
create policy "Owner or admin can view own needs base rows" on public.needs_requests
  for select to authenticated
  using (requester_id = auth.uid() or exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

drop policy if exists "Authenticated users can create own needs requests" on public.needs_requests;
create policy "Authenticated users can create own needs requests" on public.needs_requests
  for insert to authenticated
  with check (requester_id = auth.uid());

drop policy if exists "Users can update own needs requests" on public.needs_requests;
create policy "Users can update own needs requests" on public.needs_requests
  for update to authenticated
  using (requester_id = auth.uid())
  with check (requester_id = auth.uid());

-- Policies for provider_capabilities
drop policy if exists "Provider capabilities viewable by all" on public.provider_capabilities;
create policy "Provider capabilities viewable by all" on public.provider_capabilities
  for select using (true);

drop policy if exists "Users manage own provider capabilities" on public.provider_capabilities;
create policy "Users manage own provider capabilities" on public.provider_capabilities
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Users update own provider capabilities" on public.provider_capabilities;
create policy "Users update own provider capabilities" on public.provider_capabilities
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users delete own provider capabilities" on public.provider_capabilities;
create policy "Users delete own provider capabilities" on public.provider_capabilities
  for delete to authenticated using (user_id = auth.uid());

-- Policies for need_offers
drop policy if exists "Participants and admins can view need offers" on public.need_offers;
create policy "Participants and admins can view need offers" on public.need_offers
  for select to authenticated
  using (
    offer_maker_id = auth.uid()
    or exists (select 1 from public.needs_requests nr where nr.request_id = need_offers.need_id and nr.requester_id = auth.uid())
    or exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
  );

drop policy if exists "Providers can submit need offers" on public.need_offers;
create policy "Providers can submit need offers" on public.need_offers
  for insert to authenticated with check (offer_maker_id = auth.uid());

drop policy if exists "Providers can update own pending need offers" on public.need_offers;
create policy "Providers can update own pending need offers" on public.need_offers
  for update to authenticated using (offer_maker_id = auth.uid()) with check (offer_maker_id = auth.uid());

-- Policies for need_contact_reveals
drop policy if exists "Deal participants can view contact reveal" on public.need_contact_reveals;
create policy "Deal participants can view contact reveal" on public.need_contact_reveals
  for select to authenticated
  using (requester_id = auth.uid() or provider_id = auth.uid() or exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- Policies for user_interests & user_interest_events
drop policy if exists "Users manage own interests" on public.user_interests;
create policy "Users manage own interests" on public.user_interests
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users manage own interest events" on public.user_interest_events;
create policy "Users manage own interest events" on public.user_interest_events
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 12. TRIGGERS ON need_offers (Offer Validation & Sync Offer Count)

create or replace function private.trg_validate_need_offer()
returns trigger language plpgsql security definer as $$
declare
  v_need record;
  v_plan text;
  v_offer_count_month int;
  v_free_offer_cap int := 3;
  v_has_capability boolean := false;
begin
  -- Fetch need request
  select * into v_need from public.needs_requests where request_id = NEW.need_id;
  if not found then
    raise exception 'Need request not found' using errcode = 'P0201';
  end if;

  if v_need.status <> 'active' or (v_need.expires_at is not null and v_need.expires_at <= now()) then
    raise exception 'Cannot offer on inactive or expired need request' using errcode = 'P0202';
  end if;

  if v_need.requester_id = NEW.offer_maker_id then
    raise exception 'Cannot make an offer on your own need request' using errcode = 'P0205';
  end if;

  -- Check capability: must have matching capability in the category or specific capability
  if v_need.capability_slug is not null then
    select exists (
      select 1 from public.provider_capabilities
      where user_id = NEW.offer_maker_id and capability_slug = v_need.capability_slug
    ) into v_has_capability;
  else
    select exists (
      select 1 from public.provider_capabilities pc
      join public.need_capabilities nc on nc.slug = pc.capability_slug
      where pc.user_id = NEW.offer_maker_id and nc.category_slug = v_need.category_slug
    ) into v_has_capability;
  end if;

  if not v_has_capability then
    raise exception 'You must declare a capability in this category before making offers' using errcode = 'P0203';
  end if;

  -- Subscription plan check for monthly cap
  select subscription_plan into v_plan from public.profiles where id = NEW.offer_maker_id;
  if coalesce(v_plan, 'free') = 'free' then
    select coalesce(nullif(value, '')::int, 3) into v_free_offer_cap
    from public.system_settings where key = 'needs_free_offers_per_month';

    select count(*) into v_offer_count_month
    from public.need_offers
    where offer_maker_id = NEW.offer_maker_id
      and created_at >= date_trunc('month', now());

    if v_offer_count_month >= v_free_offer_cap then
      raise exception 'Free plan limit of % offers/month reached. Upgrade to make unlimited offers.', v_free_offer_cap using errcode = 'P0204';
    end if;
  end if;

  NEW.terms_locked_at := now();
  return NEW;
end;
$$;

drop trigger if exists trg_validate_need_offer on public.need_offers;
create trigger trg_validate_need_offer
  before insert on public.need_offers
  for each row execute function private.trg_validate_need_offer();

-- Sync offer count on needs_requests
create or replace function private.trg_sync_need_offer_count()
returns trigger language plpgsql security definer as $$
declare
  v_need_id uuid;
begin
  v_need_id := coalesce(NEW.need_id, OLD.need_id);
  update public.needs_requests
  set number_of_offers = (
    select count(*) from public.need_offers
    where need_id = v_need_id and status in ('pending', 'accepted')
  )
  where request_id = v_need_id;
  return null;
end;
$$;

drop trigger if exists trg_sync_need_offer_count on public.need_offers;
create trigger trg_sync_need_offer_count
  after insert or update or delete on public.need_offers
  for each row execute function private.trg_sync_need_offer_count();

-- 13. RPCS: ACCEPT OFFER, UNLOCK CONTACT, PUBLIC OFFERS, FOR YOU, PROVIDER OPPORTUNITIES

-- Public offers RPC (selective transparency)
create or replace function public.get_public_need_offers(p_need_id uuid)
returns table (
  id uuid,
  public_offer_id text,
  price bigint,
  currency text,
  timeline_text text,
  message text,
  status text,
  offered_at timestamptz,
  is_own_offer boolean,
  provider_verification_level text,
  provider_rating_avg numeric,
  provider_review_count int,
  provider_completed_deals int,
  provider_phone_verified boolean
) language plpgsql security definer as $$
declare
  v_caller uuid := auth.uid();
  v_is_requester boolean := false;
  v_is_admin boolean := false;
  v_has_offered boolean := false;
begin
  select exists (
    select 1 from public.needs_requests
    where request_id = p_need_id and requester_id = v_caller
  ) into v_is_requester;

  select exists (
    select 1 from public.profiles
    where id = v_caller and is_admin = true
  ) into v_is_admin;

  select exists (
    select 1 from public.need_offers
    where need_id = p_need_id and offer_maker_id = v_caller and status in ('pending', 'accepted')
  ) into v_has_offered;

  -- Only requester, admin, or providers who have submitted an offer can see individual offers
  if not (v_is_requester or v_is_admin or v_has_offered) then
    return;
  end if;

  return query
  select
    case when (v_is_requester or v_is_admin or o.offer_maker_id = v_caller) then o.id else null::uuid end as id,
    'public-offer-' || dense_rank() over (order by o.price asc, o.offered_at asc)::text as public_offer_id,
    o.price,
    o.currency,
    o.timeline_text,
    case when (v_is_requester or v_is_admin or o.offer_maker_id = v_caller) then o.message else 'Offer details available to requester' end as message,
    o.status,
    o.offered_at,
    (o.offer_maker_id = v_caller) as is_own_offer,
    coalesce(pc.verification_level, 'self_declared') as provider_verification_level,
    ta.rating_avg as provider_rating_avg,
    coalesce(ta.review_count, 0) as provider_review_count,
    coalesce(ta.completed_deals_count, 0) as provider_completed_deals,
    coalesce(p.phone_verified_at is not null, false) as provider_phone_verified
  from public.need_offers o
  join public.needs_requests nr on nr.request_id = o.need_id
  left join public.profiles p on p.id = o.offer_maker_id
  left join public.trust_aggregates ta on ta.user_id = o.offer_maker_id
  left join public.provider_capabilities pc on pc.user_id = o.offer_maker_id
    and pc.capability_slug in (
      select nc.slug from public.need_capabilities nc where nc.category_slug = nr.category_slug
    )
  where o.need_id = p_need_id
    and o.status in ('pending', 'accepted')
  order by o.price asc, o.offered_at asc;
end;
$$;

-- Accept Offer RPC
create or replace function public.accept_need_offer(p_need_id uuid, p_offer_id uuid)
returns uuid language plpgsql security definer as $$
declare
  v_caller uuid := auth.uid();
  v_need record;
  v_offer record;
  v_reveal_id uuid;
begin
  if v_caller is null then
    raise exception 'Authentication required' using errcode = 'P0001';
  end if;

  select * into v_need from public.needs_requests where request_id = p_need_id for update;
  if not found or v_need.requester_id <> v_caller then
    raise exception 'Need request not found or not authorized' using errcode = 'P0201';
  end if;

  if v_need.status <> 'active' then
    raise exception 'Need request is not active' using errcode = 'P0202';
  end if;

  select * into v_offer from public.need_offers where id = p_offer_id and need_id = p_need_id for update;
  if not found or v_offer.status <> 'pending' then
    raise exception 'Offer is not pending' using errcode = 'P0206';
  end if;

  -- 1. Accept target offer
  update public.need_offers
  set status = 'accepted', accepted_at = now(), updated_at = now()
  where id = p_offer_id;

  -- 2. Reject remaining offers
  update public.need_offers
  set status = 'rejected', updated_at = now()
  where need_id = p_need_id and id <> p_offer_id and status = 'pending';

  -- 3. Update need request status to matched
  update public.needs_requests
  set status = 'matched', contracted_at = now()
  where request_id = p_need_id;

  -- 4. Create contact reveal record
  insert into public.need_contact_reveals (
    need_id, offer_id, requester_id, provider_id, unlocked_by, unlocked_at
  ) values (
    p_need_id, p_offer_id, v_caller, v_offer.offer_maker_id, v_caller, now()
  ) returning id into v_reveal_id;

  return v_reveal_id;
end;
$$;

-- Unlock Need Contact RPC (Multi-Party Safe: either participant can unlock)
create or replace function public.unlock_need_contact(p_offer_id uuid)
returns uuid language plpgsql security definer as $$
declare
  v_caller uuid := auth.uid();
  v_offer record;
  v_need record;
  v_reveal_id uuid;
begin
  if v_caller is null then
    raise exception 'Authentication required' using errcode = 'P0001';
  end if;

  select * into v_offer from public.need_offers where id = p_offer_id;
  if not found or v_offer.status <> 'accepted' then
    raise exception 'Accepted offer not found' using errcode = 'P0207';
  end if;

  select * into v_need from public.needs_requests where request_id = v_offer.need_id;
  if not found then
    raise exception 'Need request not found' using errcode = 'P0201';
  end if;

  if v_caller <> v_need.requester_id and v_caller <> v_offer.offer_maker_id then
    raise exception 'Only deal participants can unlock contact' using errcode = 'P0003';
  end if;

  insert into public.need_contact_reveals (
    need_id, offer_id, requester_id, provider_id, unlocked_by, unlocked_at
  ) values (
    v_need.request_id, p_offer_id, v_need.requester_id, v_offer.offer_maker_id, v_caller, now()
  ) on conflict (offer_id) do update set unlocked_at = excluded.unlocked_at
  returning id into v_reveal_id;

  return v_reveal_id;
end;
$$;

-- Get Provider Opportunities RPC
create or replace function public.get_provider_opportunities(p_limit int default 10)
returns table (
  category_slug text,
  category_name text,
  category_icon text,
  open_needs_count bigint,
  latest_need_title text,
  latest_need_budget bigint,
  latest_need_currency text,
  latest_need_location text
) language plpgsql security definer as $$
declare
  v_caller uuid := auth.uid();
begin
  if v_caller is null then
    return;
  end if;

  return query
  with user_caps as (
    select distinct nc.category_slug
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where pc.user_id = v_caller
  ),
  active_needs as (
    select
      nr.category_slug,
      count(*) as cnt,
      max(nr.listed_at) as max_listed
    from public.needs_requests nr
    where nr.status = 'active'
      and nr.category_slug in (select uc.category_slug from user_caps uc)
      and nr.requester_id is distinct from v_caller
      and (nr.expires_at is null or nr.expires_at > now())
    group by nr.category_slug
  )
  select
    an.category_slug,
    cat.name as category_name,
    cat.icon as category_icon,
    an.cnt as open_needs_count,
    latest.title as latest_need_title,
    latest.budget as latest_need_budget,
    latest.currency as latest_need_currency,
    latest.location as latest_need_location
  from active_needs an
  join public.need_categories cat on cat.slug = an.category_slug
  cross join lateral (
    select nr.title, nr.budget, nr.currency, nr.location
    from public.needs_requests nr
    where nr.category_slug = an.category_slug
      and nr.status = 'active'
      and nr.requester_id is distinct from v_caller
    order by nr.listed_at desc
    limit 1
  ) latest
  limit p_limit;
end;
$$;

-- Get For You Needs RPC
create or replace function public.get_for_you_needs(p_country text default 'UG', p_limit int default 20)
returns setof public.v_needs_listings language plpgsql security definer as $$
declare
  v_caller uuid := auth.uid();
begin
  return query
  select vl.*
  from public.v_needs_listings vl
  where vl.country = p_country
    and not exists (
      select 1 from public.user_interests ui
      where ui.user_id = v_caller
        and ui.category_slug = vl.category_slug
        and ui.kind = 'mute'
    )
  order by
    case
      when exists (
        select 1 from public.user_interests ui
        where ui.user_id = v_caller and ui.category_slug = vl.category_slug and ui.kind in ('explicit', 'follow')
      ) then 100
      else 0
    end desc,
    vl.listed_at desc
  limit p_limit;
end;
$$;

-- Record Interest Event RPC
create or replace function public.record_interest_event(p_category_slug text, p_event text)
returns void language plpgsql security definer as $$
declare
  v_caller uuid := auth.uid();
begin
  if v_caller is null then return; end if;

  insert into public.user_interest_events (user_id, category_slug, event, created_at)
  values (v_caller, p_category_slug, p_event, now());
end;
$$;

-- Grants
grant select on public.need_categories to anon, authenticated;
grant select on public.need_capabilities to anon, authenticated;
grant select on public.v_needs_listings to anon, authenticated;
grant select on public.v_provider_badges to anon, authenticated;
grant select, insert, update, delete on public.provider_capabilities to authenticated;
grant select, insert, update on public.need_offers to authenticated;
grant select, insert, update on public.need_contact_reveals to authenticated;
grant select, insert, update, delete on public.user_interests to authenticated;
grant select, insert on public.user_interest_events to authenticated;

grant execute on function public.get_public_need_offers(uuid) to authenticated;
grant execute on function public.accept_need_offer(uuid, uuid) to authenticated;
grant execute on function public.unlock_need_contact(uuid) to authenticated;
grant execute on function public.get_provider_opportunities(int) to authenticated;
grant execute on function public.get_for_you_needs(text, int) to anon, authenticated;
grant execute on function public.record_interest_event(text, text) to authenticated;
