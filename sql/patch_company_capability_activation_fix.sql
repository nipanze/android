-- Fix company provider capability activation.
--
-- Root causes fixed by this patch:
--  1. provider_capability_is_eligible() returned false immediately when
--     is_active=false, so company-verified rows were never re-evaluated.
--  2. The backfill in the previous patch set is_active = pc.is_active (no-op)
--     instead of is_active = true for company-verified rows.
--  3. admin_review_provider_company_document() correctly sets is_active=true on
--     approval, but existing rows approved before the patch were never updated.
--
-- Apply AFTER patch_provider_approval_notifications_and_all_required.sql.
-- Safe to re-apply (idempotent via create or replace + explicit updates).

begin;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Fix provider_capability_is_eligible so it evaluates company verification
--    BEFORE checking is_active.  A company whose docs are both approved should
--    always be considered eligible regardless of the stored is_active flag.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function private.provider_capability_is_eligible(p_capability_id uuid)
returns boolean language plpgsql security definer stable
set search_path = public, private, pg_catalog as $$
declare
  v_user         uuid;
  v_slug         text;
  v_policy       text;
  v_type         text := 'both';
  v_rule_type    text := 'both';
  v_active       boolean;
  v_role_active  boolean;
  v_has_req      boolean := false;
  v_key          text;
begin
  select pc.user_id, pc.capability_slug, nc.verification_policy, pc.is_active,
         coalesce(pc.metadata->>'is_role_active' <> 'false', true),
         coalesce(pc.identity_type, pcp.provider_type, 'both')
    into v_user, v_slug, v_policy, v_active, v_role_active, v_type
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  left join public.provider_category_profiles pcp
    on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
  where pc.id = p_capability_id;

  if not found then return false; end if;

  -- Company providers with both docs approved are always eligible —
  -- check this BEFORE the is_active gate so stale flags don't block them.
  if v_type = 'company' and private.has_approved_company_verification(v_user) then
    return true;
  end if;

  -- For all other cases, respect the stored active flag.
  if not v_active or not v_role_active then return false; end if;
  if v_policy <> 'required_proof' then return true; end if;

  -- Capability-scoped requirements
  if exists (
    select 1 from public.verification_requirements r
    where r.scope_type = 'capability' and r.scope_id = v_slug
      and r.provider_type = v_type and r.is_active
  ) then
    v_rule_type := v_type;
  end if;

  for v_key in
    select distinct keys.value from (
      select unnest(coalesce(r.required_evidence, array[]::text[])) as value
      from public.verification_requirements r
      where r.scope_type = 'capability' and r.scope_id = v_slug
        and r.provider_type = v_rule_type and r.is_active
      union
      select jsonb_array_elements_text(
        case when jsonb_typeof(r.evidence_requirements) = 'array'
             then r.evidence_requirements else '[]'::jsonb end)
      from public.verification_requirements r
      where r.scope_type = 'capability' and r.scope_id = v_slug
        and r.provider_type = v_rule_type and r.is_active
    ) keys
  loop
    v_has_req := true;
    if not exists (
      select 1 from public.provider_capability_evidence e
      where e.provider_capability_id = p_capability_id
        and e.requirement_key = v_key and e.status = 'approved'
        and (e.expires_at is null or e.expires_at > now())
    ) then
      return false;
    end if;
  end loop;

  return v_has_req and exists (
    select 1 from public.provider_capabilities pc
    where pc.id = p_capability_id and pc.verification_level = 'provider_verified'
  );
end;
$$;
revoke all on function private.provider_capability_is_eligible(uuid) from public;
grant execute on function private.provider_capability_is_eligible(uuid)
  to authenticated, anon;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Backfill: activate ALL company provider_capabilities for every user whose
--    has_approved_company_verification() returns true.
--    This fixes rows that were created before the approval patch ran.
-- ─────────────────────────────────────────────────────────────────────────────
update public.provider_capabilities pc
set verification_level = 'provider_verified',
    verified_at        = coalesce(pc.verified_at, now()),
    is_active          = true
where pc.identity_type = 'company'
  and private.has_approved_company_verification(pc.user_id)
  and (pc.is_active = false or pc.verification_level <> 'provider_verified');

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Diagnostic: show the rows just updated (runs inside the transaction so
--    you can verify before commit — the result is visible in the SQL editor).
-- ─────────────────────────────────────────────────────────────────────────────
select
  pc.id,
  p.full_name,
  pc.capability_slug,
  pc.identity_type,
  pc.verification_level,
  pc.is_active,
  private.has_approved_company_verification(pc.user_id) as company_verified
from public.provider_capabilities pc
join public.profiles p on p.id = pc.user_id
where pc.identity_type = 'company'
  and private.has_approved_company_verification(pc.user_id)
order by p.full_name, pc.capability_slug;

commit;
