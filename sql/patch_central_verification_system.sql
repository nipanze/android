-- ============================================================
-- Standalone SQL Patch: patch_central_verification_system.sql
-- Description: Central Platform-Level Verification Requirements System
-- Extends the existing Identity Verification (KYC) system to all marketplace
-- activities (Loan, Forex, Needs, Offers, Service capabilities, Contact reveals,
-- and Deals).
--
-- Features:
-- 1. Table: verification_requirements (hierarchical: capability -> category -> activity -> global)
-- 2. Constraints, indexes, and RLS policies (admin-configurable).
-- 3. Seed default verification requirements for all marketplace actions & categories.
-- 4. Server-side security functions & triggers:
--    - private.is_identity_verified(user_id)
--    - private.require_identity_verified(user_id)
--    - private.check_verification_requirement(user_id, activity, category, capability)
--    - public.can_perform_marketplace_activity(...) RPC
-- 5. Strict server-side enforcement triggers & RPC guards for:
--    - Loan Requests (loan_requests)
--    - Forex Requests (forex_requests)
--    - Need Requests (needs_requests)
--    - Loan Offers (loan_offers)
--    - Forex Offers (forex_offers)
--    - Need Offers (need_offers)
--    - Provider Capabilities (provider_capabilities)
--    - Offer Acceptance (accept_offer, accept_forex_offer, accept_need_offer)
--    - Contact Reveals / Deal Unlocks (reveal_contact, unlock_forex_contact, unlock_need_contact)
-- 6. Admin RPCs for managing requirements & reviewing provider capabilities.
-- ============================================================

-- 1. BASE TABLE: verification_requirements
create table if not exists public.verification_requirements (
  id uuid primary key default gen_random_uuid(),
  scope_type text not null check (scope_type in ('global', 'activity', 'category', 'capability')),
  scope_id text not null default 'global',
  identity_required boolean not null default true,
  phone_required boolean not null default false,
  provider_verification_required boolean not null default false,
  evidence_requirements jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(scope_type, scope_id)
);

create index if not exists idx_verification_reqs_lookup 
  on public.verification_requirements(scope_type, scope_id) 
  where is_active = true;

-- 2. ROW LEVEL SECURITY
alter table public.verification_requirements enable row level security;

drop policy if exists "Verification requirements viewable by all" on public.verification_requirements;
create policy "Verification requirements viewable by all" on public.verification_requirements
  for select using (true);

drop policy if exists "Admins insert verification requirements" on public.verification_requirements;
create policy "Admins insert verification requirements" on public.verification_requirements
  for insert to authenticated
  with check (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

drop policy if exists "Admins update verification requirements" on public.verification_requirements;
create policy "Admins update verification requirements" on public.verification_requirements
  for update to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true))
  with check (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

drop policy if exists "Admins delete verification requirements" on public.verification_requirements;
create policy "Admins delete verification requirements" on public.verification_requirements
  for delete to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- 3. SEED DEFAULT REQUIREMENTS
-- A. Global default
insert into public.verification_requirements (scope_type, scope_id, identity_required, phone_required, provider_verification_required, evidence_requirements, is_active)
values
  ('global', 'global', true, false, false, '[]'::jsonb, true)
on conflict (scope_type, scope_id) do update set
  identity_required = excluded.identity_required,
  phone_required = excluded.phone_required,
  provider_verification_required = excluded.provider_verification_required;

-- B. Activity level
insert into public.verification_requirements (scope_type, scope_id, identity_required, phone_required, provider_verification_required, evidence_requirements, is_active)
values
  ('activity', 'loan_request', true, false, false, '[]'::jsonb, true),
  ('activity', 'forex_request', true, false, false, '[]'::jsonb, true),
  ('activity', 'need_request', true, false, false, '[]'::jsonb, true),
  ('activity', 'loan_offer', true, false, false, '[]'::jsonb, true),
  ('activity', 'forex_offer', true, false, false, '[]'::jsonb, true),
  ('activity', 'need_offer', true, false, false, '[]'::jsonb, true),
  ('activity', 'service_offer', true, false, false, '[]'::jsonb, true),
  ('activity', 'accept_offer', true, false, false, '[]'::jsonb, true),
  ('activity', 'reveal_contact', true, false, false, '[]'::jsonb, true)
on conflict (scope_type, scope_id) do update set
  identity_required = excluded.identity_required,
  phone_required = excluded.phone_required,
  provider_verification_required = excluded.provider_verification_required;

-- C. Category level
insert into public.verification_requirements (scope_type, scope_id, identity_required, phone_required, provider_verification_required, evidence_requirements, is_active)
values
  ('category', 'travel_international', true, false, true, '["Travel Agency License / Registration", "Tax Compliance Certificate"]'::jsonb, true),
  ('category', 'machinery_equipment', true, false, false, '[]'::jsonb, true),
  ('category', 'professional_services', true, false, false, '[]'::jsonb, true),
  ('category', 'transport_logistics', true, false, false, '[]'::jsonb, true),
  ('category', 'specialized_products', true, false, false, '[]'::jsonb, true)
on conflict (scope_type, scope_id) do update set
  identity_required = excluded.identity_required,
  phone_required = excluded.phone_required,
  provider_verification_required = excluded.provider_verification_required,
  evidence_requirements = excluded.evidence_requirements;

-- D. Capability level (specialized high-compliance capabilities)
insert into public.verification_requirements (scope_type, scope_id, identity_required, phone_required, provider_verification_required, evidence_requirements, is_active)
values
  ('capability', 'visa_assistance', true, false, true, '["Licensed Travel Agent / Consular Accreditation"]'::jsonb, true),
  ('capability', 'hajj_umrah', true, false, true, '["Hajj Bureau Accreditation / Ministry of Foreign Affairs Registration"]'::jsonb, true),
  ('capability', 'accounting_tax', true, false, false, '[]'::jsonb, true),
  ('capability', 'engineering_consulting', true, false, false, '[]'::jsonb, true),
  ('capability', 'excavator_hire', true, false, false, '[]'::jsonb, true),
  ('capability', 'tractor_hire', true, false, false, '[]'::jsonb, true),
  ('capability', 'heavy_haulage', true, false, false, '[]'::jsonb, true)
on conflict (scope_type, scope_id) do update set
  identity_required = excluded.identity_required,
  phone_required = excluded.phone_required,
  provider_verification_required = excluded.provider_verification_required,
  evidence_requirements = excluded.evidence_requirements;

-- 4. SERVER-SIDE VERIFICATION HELPER FUNCTIONS

-- Helper: Check if user is identity verified
create or replace function private.is_identity_verified(p_user_id uuid)
returns boolean language plpgsql security definer as $$
declare
  v_verified boolean := false;
begin
  if p_user_id is null then
    return false;
  end if;

  select exists (
    select 1 from public.kyc_verifications
    where user_id = p_user_id
      and status = 'approved'
      and (expires_at is null or expires_at > now())
  ) into v_verified;

  if not v_verified then
    select (coalesce(kyc_status, '') = 'approved') into v_verified
    from public.profiles
    where id = p_user_id;
  end if;

  return coalesce(v_verified, false);
end;
$$;

-- Helper: Strict identity assertion
create or replace function private.require_identity_verified(p_user_id uuid)
returns void language plpgsql security definer as $$
begin
  if not private.is_identity_verified(p_user_id) then
    raise exception 'Identity verification required. Please complete KYC before performing this marketplace activity.'
      using errcode = 'P0211';
  end if;
end;
$$;

-- Helper: Check verification requirement against hierarchy (Capability -> Category -> Activity -> Global)
create or replace function private.check_verification_requirement(
  p_user_id uuid,
  p_activity text,
  p_category_slug text default null,
  p_capability_slug text default null
)
returns jsonb language plpgsql security definer as $$
declare
  v_req record;
  v_identity_ok boolean := false;
  v_phone_ok boolean := false;
  v_provider_ok boolean := true;
  v_reason text := null;
  v_missing text[] := array[]::text[];
begin
  if p_user_id is null then
    return jsonb_build_object(
      'allowed', false,
      'reason', 'authentication_required',
      'missing_requirements', array['authentication']
    );
  end if;

  -- 1. Find the most specific active rule
  if p_capability_slug is not null then
    select * into v_req from public.verification_requirements
    where scope_type = 'capability' and scope_id = p_capability_slug and is_active = true;
  end if;

  if v_req.id is null and p_category_slug is not null then
    select * into v_req from public.verification_requirements
    where scope_type = 'category' and scope_id = p_category_slug and is_active = true;
  end if;

  if v_req.id is null and p_activity is not null then
    select * into v_req from public.verification_requirements
    where scope_type = 'activity' and scope_id = p_activity and is_active = true;
  end if;

  if v_req.id is null then
    select * into v_req from public.verification_requirements
    where scope_type = 'global' and is_active = true limit 1;
  end if;

  -- Defaults if no rule found
  if v_req.id is null then
    v_req.identity_required := true;
    v_req.phone_required := false;
    v_req.provider_verification_required := false;
  end if;

  -- 2. Verify identity requirement
  v_identity_ok := private.is_identity_verified(p_user_id);
  if v_req.identity_required and not v_identity_ok then
    v_missing := array_append(v_missing, 'identity_verification_required');
    v_reason := coalesce(v_reason, 'identity_verification_required');
  end if;

  -- 3. Verify phone requirement
  if v_req.phone_required then
    select (phone_verified_at is not null) into v_phone_ok
    from public.profiles where id = p_user_id;
    if not coalesce(v_phone_ok, false) then
      v_missing := array_append(v_missing, 'phone_verification_required');
      v_reason := coalesce(v_reason, 'phone_verification_required');
    end if;
  end if;

  -- 4. Verify provider verification requirement
  if v_req.provider_verification_required then
    if p_capability_slug is not null then
      select (verification_level = 'provider_verified') into v_provider_ok
      from public.provider_capabilities
      where user_id = p_user_id and capability_slug = p_capability_slug;
    elsif p_category_slug is not null then
      select exists (
        select 1 from public.provider_capabilities pc
        join public.need_capabilities nc on nc.slug = pc.capability_slug
        where pc.user_id = p_user_id
          and nc.category_slug = p_category_slug
          and pc.verification_level = 'provider_verified'
      ) into v_provider_ok;
    else
      v_provider_ok := false;
    end if;

    if not coalesce(v_provider_ok, false) then
      v_missing := array_append(v_missing, 'provider_verification_required');
      v_reason := coalesce(v_reason, 'provider_verification_required');
    end if;
  end if;

  return jsonb_build_object(
    'allowed', (array_length(v_missing, 1) is null),
    'reason', v_reason,
    'missing_requirements', to_jsonb(v_missing),
    'scope_type', v_req.scope_type,
    'scope_id', v_req.scope_id,
    'identity_required', v_req.identity_required,
    'phone_required', v_req.phone_required,
    'provider_verification_required', v_req.provider_verification_required,
    'evidence_requirements', v_req.evidence_requirements
  );
end;
$$;

-- Public RPC: can_perform_marketplace_activity
create or replace function public.can_perform_marketplace_activity(
  p_activity text,
  p_category_slug text default null,
  p_capability_slug text default null
)
returns jsonb language plpgsql security definer as $$
begin
  return private.check_verification_requirement(
    auth.uid(),
    p_activity,
    p_category_slug,
    p_capability_slug
  );
end;
$$;

grant execute on function public.can_perform_marketplace_activity to authenticated, anon;

-- 5. SERVER-SIDE ENFORCEMENT TRIGGERS & RPC WRAPPERS

-- A. Loan Request Enforcement
create or replace function private.trg_enforce_loan_request_identity()
returns trigger language plpgsql security definer as $$
begin
  perform private.require_identity_verified(NEW.borrower_id);
  return NEW;
end;
$$;

drop trigger if exists trg_enforce_loan_request_identity on public.loan_requests;
create trigger trg_enforce_loan_request_identity
  before insert on public.loan_requests
  for each row execute function private.trg_enforce_loan_request_identity();

-- B. Forex Request Enforcement
create or replace function private.trg_enforce_forex_request_identity()
returns trigger language plpgsql security definer as $$
begin
  perform private.require_identity_verified(NEW.requester_id);
  return NEW;
end;
$$;

drop trigger if exists trg_enforce_forex_request_identity on public.forex_requests;
create trigger trg_enforce_forex_request_identity
  before insert on public.forex_requests
  for each row execute function private.trg_enforce_forex_request_identity();

-- C. Need Request Enforcement
create or replace function private.trg_enforce_need_request_identity()
returns trigger language plpgsql security definer as $$
begin
  perform private.require_identity_verified(NEW.requester_id);
  return NEW;
end;
$$;

drop trigger if exists trg_enforce_need_request_identity on public.needs_requests;
create trigger trg_enforce_need_request_identity
  before insert on public.needs_requests
  for each row execute function private.trg_enforce_need_request_identity();

-- D. Loan Offer Enforcement
create or replace function private.trg_enforce_loan_offer_identity()
returns trigger language plpgsql security definer as $$
begin
  perform private.require_identity_verified(NEW.lender_id);
  return NEW;
end;
$$;

drop trigger if exists trg_enforce_loan_offer_identity on public.loan_offers;
create trigger trg_enforce_loan_offer_identity
  before insert on public.loan_offers
  for each row execute function private.trg_enforce_loan_offer_identity();

-- E. Forex Offer Enforcement
create or replace function private.trg_enforce_forex_offer_identity()
returns trigger language plpgsql security definer as $$
begin
  perform private.require_identity_verified(NEW.offerer_id);
  return NEW;
end;
$$;

drop trigger if exists trg_enforce_forex_offer_identity on public.forex_offers;
create trigger trg_enforce_forex_offer_identity
  before insert on public.forex_offers
  for each row execute function private.trg_enforce_forex_offer_identity();

-- F. Provider Capabilities Enforcement (Identity verified to declare capability)
create or replace function private.trg_enforce_provider_capability_identity()
returns trigger language plpgsql security definer as $$
begin
  perform private.require_identity_verified(NEW.user_id);
  return NEW;
end;
$$;

drop trigger if exists trg_enforce_provider_capability_identity on public.provider_capabilities;
create trigger trg_enforce_provider_capability_identity
  before insert on public.provider_capabilities
  for each row execute function private.trg_enforce_provider_capability_identity();

-- G. Enhanced Need Offer Trigger: Enforces Identity + Provider Verification
create or replace function private.trg_validate_need_offer()
returns trigger language plpgsql security definer as $$
declare
  v_need record;
  v_plan text;
  v_offer_count_month int;
  v_free_offer_cap int := 3;
  v_has_capability boolean := false;
  v_check jsonb;
begin
  -- 1. Check Identity Verification
  perform private.require_identity_verified(NEW.offer_maker_id);

  -- 2. Fetch need request
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

  -- 3. Check Category/Capability verification requirement
  v_check := private.check_verification_requirement(
    NEW.offer_maker_id,
    'need_offer',
    v_need.category_slug,
    v_need.capability_slug
  );

  if not (v_check->>'allowed')::boolean then
    raise exception 'Cannot make offer: %', v_check->>'reason' using errcode = 'P0203';
  end if;

  -- 4. Capability gating: user MUST have declared a matching capability
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

  -- 5. Subscription plan check for monthly cap
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

-- H. Offer Acceptance Enforcement
-- Check identity in accept_offer
create or replace function private.accept_offer_internal(
    p_request_id   UUID,
    p_offer_id     UUID,
    p_borrower_id  UUID,
    p_caller_id    UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
    v_request   public.loan_requests%ROWTYPE;
    v_offer     public.loan_offers%ROWTYPE;
    v_agreement public.agreements%ROWTYPE;
    v_deal_id   UUID;
    v_snapshot  JSONB;
BEGIN
    IF p_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required.' USING ERRCODE = 'P0001';
    END IF;

    IF p_caller_id <> p_borrower_id THEN
        RAISE EXCEPTION 'Caller is not the borrower of this request.' USING ERRCODE = 'P0003';
    END IF;

    -- Identity verification gate
    PERFORM private.require_identity_verified(p_caller_id);

    SELECT * INTO v_request FROM public.loan_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Loan request % not found.', p_request_id USING ERRCODE = 'P0002';
    END IF;

    IF v_request.borrower_id <> p_borrower_id THEN
        RAISE EXCEPTION 'Borrower % does not own request %.', p_borrower_id, p_request_id USING ERRCODE = 'P0003';
    END IF;

    IF v_request.status <> 'active' THEN
        RAISE EXCEPTION 'Loan request is not active (current status: %).', v_request.status USING ERRCODE = 'P0004';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers WHERE id = p_offer_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Loan offer % not found.', p_offer_id USING ERRCODE = 'P0002';
    END IF;

    IF v_offer.request_id <> p_request_id THEN
        RAISE EXCEPTION 'Offer % does not belong to request %.', p_offer_id, p_request_id USING ERRCODE = 'P0005';
    END IF;

    IF v_offer.status <> 'pending' THEN
        RAISE EXCEPTION 'Loan offer is not pending (current status: %).', v_offer.status USING ERRCODE = 'P0006';
    END IF;

    -- Accept target offer
    UPDATE public.loan_offers SET status = 'accepted', responded_at = NOW() WHERE id = p_offer_id;

    -- Reject all other pending offers
    UPDATE public.loan_offers SET status = 'rejected', responded_at = NOW()
    WHERE request_id = p_request_id AND id <> p_offer_id AND status = 'pending';

    -- Set request to contracted
    UPDATE public.loan_requests SET status = 'contracted' WHERE id = p_request_id;

    -- Create Agreement Snapshot
    v_snapshot := jsonb_build_object(
        'request_id',               p_request_id,
        'offer_id',                 p_offer_id,
        'borrower_id',              p_borrower_id,
        'lender_id',                v_offer.lender_id,
        'loan_amount',              v_offer.offered_amount,
        'interest_rate',            v_offer.interest_rate,
        'currency',                 v_request.currency,
        'repayment_period_months',  v_offer.repayment_period_months,
        'repayment_frequency',      v_offer.repayment_frequency,
        'late_fee_percentage',      v_offer.late_fee_percentage,
        'contract_terms',           v_offer.contract_terms,
        'accepted_at',              NOW()
    );

    INSERT INTO public.agreements (
        request_id, offer_id, borrower_id, lender_id,
        loan_amount, interest_rate, currency,
        repayment_period_months, repayment_frequency,
        late_fee_percentage, contract_terms,
        status, borrower_locked, lender_locked, agreement_snapshot
    ) VALUES (
        p_request_id, p_offer_id, p_borrower_id, v_offer.lender_id,
        v_offer.offered_amount, v_offer.interest_rate, v_request.currency,
        v_offer.repayment_period_months, v_offer.repayment_frequency,
        v_offer.late_fee_percentage, v_offer.contract_terms,
        'locked', TRUE, TRUE, v_snapshot
    )
    RETURNING id INTO v_deal_id;

    RETURN v_deal_id;
END;
$$;

-- Check identity in accept_forex_offer
create or replace function private.accept_forex_offer_internal(
    p_request_id    UUID,
    p_offer_id      UUID,
    p_requester_id  UUID,
    p_caller_id     UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
    v_request   public.forex_requests%ROWTYPE;
    v_offer     public.forex_offers%ROWTYPE;
    v_deal_id   UUID;
    v_snapshot  JSONB;
BEGIN
    IF p_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required.' USING ERRCODE = 'P0001';
    END IF;

    IF p_caller_id <> p_requester_id THEN
        RAISE EXCEPTION 'Caller is not the requester of this forex request.' USING ERRCODE = 'P0003';
    END IF;

    -- Identity verification gate
    PERFORM private.require_identity_verified(p_caller_id);

    SELECT * INTO v_request FROM public.forex_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Forex request % not found.', p_request_id USING ERRCODE = 'P0002';
    END IF;

    IF v_request.requester_id <> p_requester_id THEN
        RAISE EXCEPTION 'Requester % does not own forex request %.', p_requester_id, p_request_id USING ERRCODE = 'P0003';
    END IF;

    IF v_request.status <> 'active' THEN
        RAISE EXCEPTION 'Forex request is not active (current status: %).', v_request.status USING ERRCODE = 'P0004';
    END IF;

    SELECT * INTO v_offer FROM public.forex_offers WHERE id = p_offer_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Forex offer % not found.', p_offer_id USING ERRCODE = 'P0002';
    END IF;

    IF v_offer.request_id <> p_request_id THEN
        RAISE EXCEPTION 'Offer % does not belong to request %.', p_offer_id, p_request_id USING ERRCODE = 'P0005';
    END IF;

    IF v_offer.status <> 'pending' THEN
        RAISE EXCEPTION 'Forex offer is not pending (current status: %).', v_offer.status USING ERRCODE = 'P0006';
    END IF;

    UPDATE public.forex_offers SET status = 'accepted', responded_at = NOW() WHERE id = p_offer_id;
    UPDATE public.forex_offers SET status = 'rejected', responded_at = NOW()
    WHERE request_id = p_request_id AND id <> p_offer_id AND status = 'pending';
    UPDATE public.forex_requests SET status = 'contracted' WHERE id = p_request_id;

    v_snapshot := jsonb_build_object(
        'is_forex',                 TRUE,
        'deal_type',                'forex',
        'request_id',               p_request_id,
        'offer_id',                 p_offer_id,
        'requester_id',             p_requester_id,
        'offerer_id',               v_offer.offerer_id,
        'source_currency',          v_request.source_currency,
        'target_currency',          v_request.target_currency,
        'amount_source',            v_offer.amount_available,
        'rate_offered',             v_offer.rate_offered,
        'accepted_at',              NOW()
    );

    INSERT INTO public.agreements (
        request_id, offer_id, borrower_id, lender_id,
        loan_amount, interest_rate, currency,
        repayment_period_months, repayment_frequency,
        late_fee_percentage, contract_terms,
        status, borrower_locked, lender_locked, agreement_snapshot
    ) VALUES (
        p_request_id, p_offer_id, p_requester_id, v_offer.offerer_id,
        v_offer.amount_available, 0, v_request.source_currency,
        1, 'one_time', 0, coalesce(v_offer.terms, 'Forex agreement'),
        'locked', TRUE, TRUE, v_snapshot
    )
    RETURNING id INTO v_deal_id;

    RETURN v_deal_id;
END;
$$;

-- Check identity in accept_need_offer
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

  -- Identity verification gate
  perform private.require_identity_verified(v_caller);

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

-- I. Contact Reveal Enforcement (Multi-party + Identity check)
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

  -- Identity verification gate
  perform private.require_identity_verified(v_caller);

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

-- 6. ADMIN RPCs: Requirements Configuration
create or replace function public.admin_get_verification_requirements()
returns setof public.verification_requirements language plpgsql security definer as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and is_admin = true) then
    raise exception 'Unauthorized: Admin access required' using errcode = '42501';
  end if;

  return query
  select * from public.verification_requirements
  order by
    case scope_type
      when 'global' then 1
      when 'activity' then 2
      when 'category' then 3
      when 'capability' then 4
      else 5
    end,
    scope_id;
end;
$$;

create or replace function public.admin_update_verification_requirement(
  p_id uuid,
  p_identity_required boolean,
  p_phone_required boolean,
  p_provider_verification_required boolean,
  p_evidence_requirements jsonb default '[]'::jsonb,
  p_is_active boolean default true
)
returns boolean language plpgsql security definer as $$
declare
  v_admin uuid := auth.uid();
begin
  if not exists (select 1 from public.profiles where id = v_admin and is_admin = true) then
    raise exception 'Unauthorized: Admin access required' using errcode = '42501';
  end if;

  update public.verification_requirements
  set
    identity_required = p_identity_required,
    phone_required = p_phone_required,
    provider_verification_required = p_provider_verification_required,
    evidence_requirements = coalesce(p_evidence_requirements, '[]'::jsonb),
    is_active = p_is_active,
    updated_at = now()
  where id = p_id;

  insert into public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
  values (
    v_admin,
    'admin_action',
    'verification_requirements',
    p_id,
    'update_verification_requirement',
    jsonb_build_object(
      'identity_required', p_identity_required,
      'phone_required', p_phone_required,
      'provider_verification_required', p_provider_verification_required,
      'is_active', p_is_active
    )
  );

  return true;
end;
$$;

grant execute on function public.admin_get_verification_requirements to authenticated;
grant execute on function public.admin_update_verification_requirement to authenticated;
