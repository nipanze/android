-- ============================================================
-- Standalone SQL Patch: patch_provider_capabilities_v1.sql
-- Description: Provider Services / Provider Capabilities (Stage 4.8 / Phase 4)
-- Enforces:
-- 1. provider_capabilities schema with metadata and unique index.
-- 2. Security trigger: Only admins can elevate verification_level to 'provider_verified'.
-- 3. Capability-gated offers validation trigger on need_offers with code 'P0203'.
-- 4. Atomic get_provider_opportunities RPC grouping by capability.
-- 5. Admin capability review RPC and moderation queries.
-- ============================================================

-- 1. BASE TABLE: provider_capabilities
create table if not exists public.provider_capabilities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  capability_slug text not null references public.need_capabilities(slug) on delete cascade,
  verification_level text not null default 'self_declared' check (verification_level in ('self_declared', 'provider_verified')),
  evidence_url text,
  metadata jsonb not null default '{}'::jsonb,
  verified_by uuid references auth.users(id) on delete set null,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  unique(user_id, capability_slug)
);

-- Ensure metadata column exists if table was created earlier without it
alter table if exists public.provider_capabilities
  add column if not exists metadata jsonb not null default '{}'::jsonb;

-- Indexes
create index if not exists idx_provider_capabilities_user on public.provider_capabilities(user_id);
create index if not exists idx_provider_capabilities_capability on public.provider_capabilities(capability_slug);
create index if not exists idx_provider_capabilities_level on public.provider_capabilities(verification_level);

-- 2. TRIGGER: Enforce progressive verification level
-- Users can NEVER elevate themselves to 'provider_verified'. Only an admin can approve.
drop function if exists private.trg_enforce_provider_capability_verification() cascade;
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
    -- Non-admin cannot set verification_level to provider_verified
    NEW.verification_level := 'self_declared';
    NEW.verified_by := null;
    NEW.verified_at := null;
  else
    if NEW.verification_level = 'provider_verified' and (OLD is null or OLD.verification_level <> 'provider_verified') then
      NEW.verified_by := coalesce(NEW.verified_by, auth.uid());
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

-- 3. ROW LEVEL SECURITY POLICIES
alter table public.provider_capabilities enable row level security;

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

drop policy if exists "Admins update all provider capabilities" on public.provider_capabilities;
create policy "Admins update all provider capabilities" on public.provider_capabilities
  for update to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- 4. SERVER-SIDE OFFER VALIDATION TRIGGER (Capability Gating: P0203)
drop function if exists private.trg_validate_need_offer() cascade;
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

  -- Capability gating: user MUST have declared a matching capability
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
    select coalesce(nullif(setting_value, '')::int, 3) into v_free_offer_cap
    from public.system_settings where setting_key = 'needs_free_offers_per_month';

    select count(*) into v_offer_count_month
    from public.need_offers
    where offer_maker_id = NEW.offer_maker_id
      and created_at >= date_trunc('month', now());

    if v_offer_count_month >= v_free_offer_cap then
      raise exception 'Free plan limit of % offers/month reached. Upgrade to make unlimited offers.', v_free_offer_cap using errcode = 'P0204';
    end if;
  end if;

  NEW.terms_locked_at := coalesce(NEW.terms_locked_at, now());
  return NEW;
end;
$$;

drop trigger if exists trg_validate_need_offer on public.need_offers;
create trigger trg_validate_need_offer
  before insert on public.need_offers
  for each row execute function private.trg_validate_need_offer();

-- 5. RPC: get_provider_opportunities
-- Finds active Needs that match the caller's declared capabilities.
drop function if exists public.get_provider_opportunities cascade;
drop function if exists public.get_provider_opportunities(int) cascade;
drop function if exists public.get_provider_opportunities(uuid, int) cascade;
create or replace function public.get_provider_opportunities(p_user_id uuid default null, p_limit int default 20)
returns table (
  capability_slug text,
  capability_name text,
  category_slug text,
  category_name text,
  category_icon text,
  open_needs_count bigint,
  latest_need_id uuid,
  latest_need_title text,
  latest_need_budget bigint,
  latest_need_currency text,
  latest_need_location text,
  latest_need_created_at timestamptz
) language plpgsql security definer as $$
declare
  v_caller uuid := coalesce(p_user_id, auth.uid());
begin
  if v_caller is null then
    return;
  end if;

  return query
  with user_caps as (
    select
      pc.capability_slug,
      nc.name as capability_name,
      nc.category_slug,
      cat.name as category_name,
      cat.icon as category_icon
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    join public.need_categories cat on cat.slug = nc.category_slug
    where pc.user_id = v_caller
  ),
  matching_needs as (
    select
      uc.capability_slug,
      nr.request_id,
      nr.title,
      nr.budget,
      nr.currency,
      nr.location,
      nr.listed_at
    from user_caps uc
    join public.needs_requests nr
      on (nr.capability_slug = uc.capability_slug or (nr.capability_slug is null and nr.category_slug = uc.category_slug))
    where nr.status = 'active'
      and nr.requester_id is distinct from v_caller
      and (nr.expires_at is null or nr.expires_at > now())
      and not exists (
        select 1 from public.need_offers nof
        where nof.need_id = nr.request_id and nof.offer_maker_id = v_caller
      )
  ),
  capability_counts as (
    select
      mn.capability_slug,
      count(*) as cnt,
      max(mn.listed_at) as max_listed
    from matching_needs mn
    group by mn.capability_slug
  )
  select
    uc.capability_slug,
    uc.capability_name,
    uc.category_slug,
    uc.category_name,
    uc.category_icon,
    cc.cnt as open_needs_count,
    latest.request_id as latest_need_id,
    latest.title as latest_need_title,
    latest.budget as latest_need_budget,
    latest.currency as latest_need_currency,
    latest.location as latest_need_location,
    latest.listed_at as latest_need_created_at
  from capability_counts cc
  join user_caps uc on uc.capability_slug = cc.capability_slug
  cross join lateral (
    select mn.request_id, mn.title, mn.budget, mn.currency, mn.location, mn.listed_at
    from matching_needs mn
    where mn.capability_slug = cc.capability_slug
    order by mn.listed_at desc
    limit 1
  ) latest
  order by cc.cnt desc, latest.listed_at desc
  limit p_limit;
end;
$$;

-- 6. ADMIN RPCs: Moderation of Provider Capabilities
drop function if exists public.admin_get_provider_capabilities cascade;
create or replace function public.admin_get_provider_capabilities(
  p_filter_level text default null,
  p_limit int default 50
)
returns table (
  capability_id uuid,
  user_id uuid,
  user_name text,
  user_email text,
  user_phone text,
  phone_verified boolean,
  kyc_status text,
  rating_avg numeric,
  completed_deals_count integer,
  capability_slug text,
  capability_name text,
  category_slug text,
  category_name text,
  category_icon text,
  verification_level text,
  evidence_url text,
  metadata jsonb,
  verified_by uuid,
  verified_at timestamptz,
  created_at timestamptz
) language plpgsql security definer as $$
begin
  -- Validate caller is admin
  if not exists (select 1 from public.profiles where id = auth.uid() and is_admin = true) then
    raise exception 'Unauthorized: Admin access required' using errcode = '42501';
  end if;

  return query
  select
    pc.id as capability_id,
    pc.user_id,
    p.full_name as user_name,
    p.email as user_email,
    p.phone as user_phone,
    (p.phone_verified_at is not null) as phone_verified,
    coalesce(p.kyc_status, 'none') as kyc_status,
    p.rating_avg,
    coalesce(p.completed_deals_count, 0) as completed_deals_count,
    pc.capability_slug,
    nc.name as capability_name,
    nc.category_slug,
    cat.name as category_name,
    cat.icon as category_icon,
    pc.verification_level,
    pc.evidence_url,
    pc.metadata,
    pc.verified_by,
    pc.verified_at,
    pc.created_at
  from public.provider_capabilities pc
  join public.profiles p on p.id = pc.user_id
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  join public.need_categories cat on cat.slug = nc.category_slug
  where (p_filter_level is null or pc.verification_level = p_filter_level)
  order by
    case when pc.verification_level = 'self_declared' then 0 else 1 end,
    pc.created_at desc
  limit p_limit;
end;
$$;

drop function if exists public.admin_review_provider_capability cascade;
create or replace function public.admin_review_provider_capability(
  p_capability_id uuid,
  p_action text,
  p_rejection_reason text default null
)
returns boolean language plpgsql security definer as $$
declare
  v_admin uuid := auth.uid();
  v_is_admin boolean := false;
  v_old_level text;
  v_user_id uuid;
begin
  select exists (
    select 1 from public.profiles where id = v_admin and is_admin = true
  ) into v_is_admin;

  if not v_is_admin then
    raise exception 'Unauthorized: Admin access required' using errcode = '42501';
  end if;

  select verification_level, user_id into v_old_level, v_user_id
  from public.provider_capabilities
  where id = p_capability_id;

  if not found then
    raise exception 'Provider capability not found' using errcode = 'P0210';
  end if;

  if p_action = 'approve' then
    update public.provider_capabilities
    set
      verification_level = 'provider_verified',
      verified_by = v_admin,
      verified_at = now()
    where id = p_capability_id;

    insert into public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    values (
      v_admin,
      'admin_action',
      'provider_capabilities',
      p_capability_id,
      'approve_capability',
      jsonb_build_object('verification_level', 'provider_verified', 'approved_by', v_admin)
    );
    return true;
  elsif p_action = 'reject' then
    update public.provider_capabilities
    set
      verification_level = 'self_declared',
      verified_by = null,
      verified_at = null,
      metadata = jsonb_set(
        coalesce(metadata, '{}'::jsonb),
        '{last_rejection}',
        jsonb_build_object('rejected_at', now(), 'reason', coalesce(p_rejection_reason, ''))
      )
    where id = p_capability_id;

    insert into public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    values (
      v_admin,
      'admin_action',
      'provider_capabilities',
      p_capability_id,
      'reject_capability',
      jsonb_build_object('reason', p_rejection_reason, 'rejected_by', v_admin)
    );
    return true;
  else
    raise exception 'Invalid action: must be approve or reject' using errcode = '22023';
  end if;
end;
$$;

-- Permissions
grant select, insert, update, delete on public.provider_capabilities to authenticated;
grant execute on function public.get_provider_opportunities to authenticated;
grant execute on function public.admin_get_provider_capabilities to authenticated;
grant execute on function public.admin_review_provider_capability to authenticated;
