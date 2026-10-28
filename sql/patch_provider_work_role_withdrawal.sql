-- Confirmed, atomic deactivation and proof withdrawal for individual work roles.
-- Withdrawn files stay in the private provider-evidence bucket for retention.
begin;

alter table public.provider_role_qualification_claims
  drop constraint if exists provider_role_qualification_claims_status_check;
alter table public.provider_role_qualification_claims
  add constraint provider_role_qualification_claims_status_check
  check (status in (
    'self_declared', 'pending_review', 'verified', 'rejected', 'expired', 'withdrawn'
  ));
alter table public.provider_role_qualification_claims
  drop constraint if exists provider_role_qualification_claims_review_state_check;
alter table public.provider_role_qualification_claims
  add constraint provider_role_qualification_claims_review_state_check
  check (
    status = 'withdrawn'
    or (status in ('self_declared', 'pending_review') and reviewed_by is null and reviewed_at is null)
    or (status in ('verified', 'rejected', 'expired') and reviewed_by is not null and reviewed_at is not null)
  );

-- Mark the admin-review mirror withdrawn instead of deleting it. An existing
-- cleanup trigger deletes the underlying storage object when this row is
-- deleted, and Supabase requires storage deletion to go through its Storage API.
alter table public.provider_capability_evidence
  drop constraint if exists provider_capability_evidence_status_check;
alter table public.provider_capability_evidence
  add constraint provider_capability_evidence_status_check
  check (status in ('pending', 'approved', 'rejected', 'expired', 'withdrawn'));

create or replace function public.set_provider_work_role_active(
  p_provider_capability_id uuid,
  p_role_slug text,
  p_active boolean,
  p_expected_claim_states jsonb default '[]'::jsonb
) returns jsonb
language plpgsql security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_cap public.provider_capabilities%rowtype;
  v_current_states jsonb;
  v_claim_states jsonb;
  v_withdrawn_slugs text[] := array[]::text[];
  v_metadata jsonb;
begin
  if v_user is null then
    raise exception 'Not authenticated.' using errcode = '42501';
  end if;
  select pc.* into v_cap
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  where pc.id = p_provider_capability_id
    and pc.user_id = v_user
    and nc.capability_type = 'work'
    and coalesce(pc.metadata->>'role_id', '') = p_role_slug
  for update of pc;
  if not found then
    raise exception 'Work role not found.' using errcode = 'P0212';
  end if;

  if not p_active then
    select coalesce(jsonb_agg(jsonb_build_object(
        'role_slug', claim.role_slug,
        'qualification_slug', claim.qualification_slug,
        'status', claim.status
      ) order by claim.role_slug, claim.qualification_slug), '[]'::jsonb)
    into v_current_states
    from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = v_cap.id
      and claim.role_slug = p_role_slug
      and claim.is_claimed
      and claim.evidence_object_path is not null
      and (claim.status = 'pending_review'
        or (claim.status = 'verified'
          and (claim.expires_at is null or claim.expires_at > now())));

    if coalesce(p_expected_claim_states, '[]'::jsonb) <> v_current_states then
      select coalesce(jsonb_agg(jsonb_build_object(
          'role_slug', claim.role_slug,
          'qualification_slug', claim.qualification_slug,
          'status', case
            when claim.status = 'verified'
                 and claim.expires_at is not null
                 and claim.expires_at <= now() then 'expired'
            else claim.status end,
          'has_evidence', claim.evidence_object_path is not null
        ) order by claim.role_slug, claim.qualification_slug), '[]'::jsonb)
      into v_claim_states
      from public.provider_role_qualification_claims claim
      where claim.provider_capability_id = v_cap.id and claim.is_claimed;
      return jsonb_build_object('changed', false, 'active', true,
        'claim_states', coalesce(v_claim_states, '[]'::jsonb));
    end if;

    select coalesce(array_agg(claim.qualification_slug), array[]::text[])
    into v_withdrawn_slugs
    from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = v_cap.id
      and claim.role_slug = p_role_slug
      and claim.is_claimed
      and claim.evidence_object_path is not null
      and (claim.status = 'pending_review'
        or (claim.status = 'verified'
          and (claim.expires_at is null or claim.expires_at > now())));

    update public.provider_role_qualification_claims claim
    set status = 'withdrawn', is_claimed = false, updated_at = now()
    where claim.provider_capability_id = v_cap.id
      and claim.role_slug = p_role_slug
      and claim.is_claimed
      and claim.evidence_object_path is not null
      and (claim.status = 'pending_review'
        or (claim.status = 'verified'
          and (claim.expires_at is null or claim.expires_at > now())));

    -- Remove withdrawn proofs from the pending review queue without deleting
    -- their mirror rows; a DELETE trigger would remove the private file.
    update public.provider_capability_evidence evidence
    set status = 'withdrawn', updated_at = now()
    from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = v_cap.id
      and claim.role_slug = p_role_slug
      and claim.status = 'withdrawn'
      and evidence.provider_capability_id = v_cap.id
      and evidence.requirement_key = claim.qualification_slug
      and evidence.file_url = claim.evidence_object_path;

    v_metadata := coalesce(v_cap.metadata, '{}'::jsonb);
    if jsonb_typeof(v_metadata->'qualification_ids') = 'array'
       and cardinality(v_withdrawn_slugs) > 0 then
      select coalesce(jsonb_agg(to_jsonb(q.slug) order by q.ordinality), '[]'::jsonb)
      into v_metadata
      from jsonb_array_elements_text(v_metadata->'qualification_ids')
        with ordinality as q(slug, ordinality)
      where not (q.slug = any(v_withdrawn_slugs));
      v_metadata := jsonb_set(coalesce(v_cap.metadata, '{}'::jsonb),
        '{qualification_ids}', coalesce(v_metadata, '[]'::jsonb), true);
    else
      v_metadata := coalesce(v_cap.metadata, '{}'::jsonb);
    end if;
    v_metadata := jsonb_set(v_metadata, '{is_role_active}', 'false'::jsonb, true);
    update public.provider_capabilities
    set metadata = v_metadata, updated_at = now()
    where id = v_cap.id;

    if not exists (
      select 1 from public.provider_role_qualification_claims claim
      where claim.provider_capability_id = v_cap.id
        and claim.is_claimed and claim.status = 'verified'
        and (claim.expires_at is null or claim.expires_at > now())
    ) and not exists (
      select 1 from public.provider_capability_evidence evidence
      where evidence.provider_capability_id = v_cap.id
        and evidence.status = 'approved'
        and (evidence.expires_at is null or evidence.expires_at > now())
    ) then
      update public.provider_capabilities
      set verification_level = 'self_declared', verified_by = null, verified_at = null
      where id = v_cap.id and verification_level = 'provider_verified';
    end if;
  else
    v_metadata := jsonb_set(coalesce(v_cap.metadata, '{}'::jsonb),
      '{is_role_active}', 'true'::jsonb, true);
    update public.provider_capabilities
    set metadata = v_metadata, updated_at = now()
    where id = v_cap.id;
  end if;

  update public.job_profile_roles jpr
  set is_active = p_active, updated_at = now()
  from public.job_profiles jp, public.need_capabilities nc
  where jpr.job_profile_id = jp.id
    and jp.user_id = v_user
    and nc.slug = v_cap.capability_slug
    and jp.category_slug = nc.category_slug
    and jpr.role_slug = p_role_slug;

  select coalesce(jsonb_agg(jsonb_build_object(
      'role_slug', claim.role_slug,
      'qualification_slug', claim.qualification_slug,
      'status', case
        when claim.status = 'verified'
             and claim.expires_at is not null
             and claim.expires_at <= now() then 'expired'
        else claim.status end,
      'has_evidence', claim.evidence_object_path is not null
    ) order by claim.role_slug, claim.qualification_slug), '[]'::jsonb)
  into v_claim_states
  from public.provider_role_qualification_claims claim
  where claim.provider_capability_id = v_cap.id and claim.is_claimed;

  insert into public.audit_logs(user_id, event_type, entity_type, entity_id, action, new_values)
  values (v_user, 'admin_action', 'provider_work_role', v_cap.id,
    case when p_active then 'reactivate_work_role' else 'deactivate_work_role' end,
    jsonb_build_object('role_slug', p_role_slug, 'active', p_active,
      'withdrawn_qualification_slugs', to_jsonb(v_withdrawn_slugs)));

  return jsonb_build_object('changed', true, 'active', p_active,
    'claim_states', coalesce(v_claim_states, '[]'::jsonb));
end;
$$;
revoke all on function public.set_provider_work_role_active(uuid, text, boolean, jsonb)
  from public, anon;
grant execute on function public.set_provider_work_role_active(uuid, text, boolean, jsonb)
  to authenticated;

create or replace function public.withdraw_provider_role_qualification(
  p_provider_capability_id uuid,
  p_role_slug text,
  p_qualification_slug text,
  p_expected_status text
) returns jsonb
language plpgsql security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_cap public.provider_capabilities%rowtype;
  v_claim public.provider_role_qualification_claims%rowtype;
begin
  if v_user is null then
    raise exception 'Not authenticated.' using errcode = '42501';
  end if;
  select pc.* into v_cap
  from public.provider_capabilities pc
  where pc.id = p_provider_capability_id and pc.user_id = v_user
  for update;
  if not found then
    raise exception 'Work profile not found.' using errcode = 'P0212';
  end if;
  select claim.* into v_claim
  from public.provider_role_qualification_claims claim
  where claim.provider_capability_id = v_cap.id
    and claim.role_slug = p_role_slug
    and claim.qualification_slug = p_qualification_slug
    and claim.is_claimed
  for update;
  if not found then
    return jsonb_build_object('withdrawn', false, 'status', 'self_declared');
  end if;
  if v_claim.status <> p_expected_status
     or v_claim.status not in ('pending_review', 'verified')
     or v_claim.evidence_object_path is null
     or (v_claim.status = 'verified' and v_claim.expires_at is not null
         and v_claim.expires_at <= now()) then
    return jsonb_build_object('withdrawn', false, 'status',
      case when v_claim.status = 'verified' and v_claim.expires_at is not null
                 and v_claim.expires_at <= now() then 'expired'
           else v_claim.status end,
      'has_evidence', v_claim.evidence_object_path is not null);
  end if;

  update public.provider_role_qualification_claims
  set status = 'withdrawn', is_claimed = false, updated_at = now()
  where id = v_claim.id;
  update public.provider_capability_evidence evidence
  set status = 'withdrawn', updated_at = now()
  where evidence.provider_capability_id = v_cap.id
    and evidence.requirement_key = p_qualification_slug
    and evidence.file_url = v_claim.evidence_object_path;

  update public.provider_capabilities pc
  set metadata = jsonb_set(
        coalesce(pc.metadata, '{}'::jsonb), '{qualification_ids}',
        coalesce((select jsonb_agg(to_jsonb(q.slug) order by q.ordinality)
          from jsonb_array_elements_text(
            case when jsonb_typeof(pc.metadata->'qualification_ids') = 'array'
              then pc.metadata->'qualification_ids' else '[]'::jsonb end
          ) with ordinality q(slug, ordinality)
          where q.slug <> p_qualification_slug), '[]'::jsonb), true),
      updated_at = now()
  where pc.id = v_cap.id;

  if not exists (
    select 1 from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = v_cap.id and claim.is_claimed
      and claim.status = 'verified'
      and (claim.expires_at is null or claim.expires_at > now())
  ) and not exists (
    select 1 from public.provider_capability_evidence evidence
    where evidence.provider_capability_id = v_cap.id
      and evidence.status = 'approved'
      and (evidence.expires_at is null or evidence.expires_at > now())
  ) then
    update public.provider_capabilities
    set verification_level = 'self_declared', verified_by = null, verified_at = null
    where id = v_cap.id and verification_level = 'provider_verified';
  end if;

  insert into public.audit_logs(user_id, event_type, entity_type, entity_id, action, new_values)
  values (v_user, 'admin_action', 'provider_role_qualification_claim', v_claim.id,
    'withdraw_role_qualification_proof', jsonb_build_object(
      'role_slug', p_role_slug, 'qualification_slug', p_qualification_slug,
      'previous_status', v_claim.status));
  return jsonb_build_object('withdrawn', true, 'status', 'withdrawn',
    'has_evidence', true);
end;
$$;
revoke all on function public.withdraw_provider_role_qualification(uuid, text, text, text)
  from public, anon;
grant execute on function public.withdraw_provider_role_qualification(uuid, text, text, text)
  to authenticated;

create or replace function private.provider_capability_is_eligible(p_capability_id uuid)
returns boolean language plpgsql security definer stable
set search_path = public, private, pg_catalog as $$
declare
  v_slug text;
  v_policy text;
  v_type text := 'both';
  v_rule_type text := 'both';
  v_active boolean;
  v_role_active boolean;
  v_has_requirements boolean := false;
  v_key text;
begin
  select pc.capability_slug, nc.verification_policy, pc.is_active,
         coalesce(pc.metadata->>'is_role_active' <> 'false', true)
    into v_slug, v_policy, v_active, v_role_active
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  where pc.id = p_capability_id;
  if not found or not v_active or not v_role_active then return false; end if;
  if v_policy <> 'required_proof' then return true; end if;

  select coalesce(pcp.provider_type, 'both') into v_type
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  left join public.provider_category_profiles pcp
    on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
  where pc.id = p_capability_id;
  if exists (select 1 from public.verification_requirements r
    where r.scope_type = 'capability' and r.scope_id = v_slug
      and r.provider_type = v_type and r.is_active) then
    v_rule_type := v_type;
  end if;
  for v_key in
    select distinct keys.value from (
      select unnest(coalesce(r.required_evidence, array[]::text[])) as value
      from public.verification_requirements r
      where r.scope_type = 'capability' and r.scope_id = v_slug
        and r.provider_type = v_rule_type and r.is_active
      union
      select jsonb_array_elements_text(case
        when jsonb_typeof(r.evidence_requirements) = 'array'
          then r.evidence_requirements else '[]'::jsonb end)
      from public.verification_requirements r
      where r.scope_type = 'capability' and r.scope_id = v_slug
        and r.provider_type = v_rule_type and r.is_active
    ) keys
  loop
    v_has_requirements := true;
    if not exists (select 1 from public.provider_capability_evidence e
      where e.provider_capability_id = p_capability_id
        and e.requirement_key = v_key and e.status = 'approved'
        and (e.expires_at is null or e.expires_at > now())) then
      return false;
    end if;
  end loop;
  return v_has_requirements and exists (
    select 1 from public.provider_capabilities pc
    where pc.id = p_capability_id and pc.verification_level = 'provider_verified'
  );
end;
$$;
revoke all on function private.provider_capability_is_eligible(uuid) from public;
grant execute on function private.provider_capability_is_eligible(uuid)
  to authenticated, anon;

commit;
notify pgrst, 'reload schema';
