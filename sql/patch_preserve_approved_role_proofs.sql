-- Preserve approved role proofs when roles are removed.
-- Apply after patch_provider_work_role_withdrawal.sql and
-- patch_provider_profile_documents.sql. Safe to rerun.
begin;

-- Earlier role-removal code marked approved claims withdrawn but kept their
-- reviewed state and private object path. Restore those retained approvals.
update public.provider_role_qualification_claims claim
set status = 'verified', is_claimed = true, updated_at = now()
where claim.status = 'withdrawn'
  and claim.evidence_object_path is not null
  and claim.reviewed_by is not null
  and claim.reviewed_at is not null
  and exists (
    select 1 from storage.objects object
    where object.bucket_id = 'provider-evidence'
      and object.name = claim.evidence_object_path
  );

update public.provider_capability_evidence evidence
set status = case
      when claim.expires_at is not null and claim.expires_at <= now()
        then 'expired'
      else 'approved'
    end,
    updated_at = now()
from public.provider_role_qualification_claims claim
where claim.status = 'verified'
  and claim.is_claimed
  and claim.evidence_object_path is not null
  and claim.reviewed_by is not null
  and claim.reviewed_at is not null
  and evidence.provider_capability_id = claim.provider_capability_id
  and evidence.requirement_key = claim.qualification_slug
  and evidence.file_url = claim.evidence_object_path
  and evidence.status = 'withdrawn';

update public.provider_capabilities capability
set metadata = jsonb_set(
      coalesce(capability.metadata, '{}'::jsonb),
      '{qualification_ids}',
      coalesce((
        select jsonb_agg(to_jsonb(qualifications.slug)
                         order by qualifications.slug)
        from (
          select distinct qualification.slug
          from (
            select jsonb_array_elements_text(
              case
                when jsonb_typeof(capability.metadata->'qualification_ids') = 'array'
                  then capability.metadata->'qualification_ids'
                else '[]'::jsonb
              end
            ) as slug
            union all
            select claim.qualification_slug as slug
            from public.provider_role_qualification_claims claim
            where claim.provider_capability_id = capability.id
              and claim.is_claimed
              and claim.status = 'verified'
              and claim.evidence_object_path is not null
              and claim.reviewed_by is not null
              and claim.reviewed_at is not null
          ) qualification
        ) qualifications
      ), '[]'::jsonb), true),
    updated_at = now()
where exists (
  select 1
  from public.provider_role_qualification_claims claim
  where claim.provider_capability_id = capability.id
    and claim.is_claimed
    and claim.status = 'verified'
    and claim.evidence_object_path is not null
    and claim.reviewed_by is not null
    and claim.reviewed_at is not null
);

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
      and claim.status = 'pending_review';

    update public.provider_role_qualification_claims claim
    set status = 'withdrawn', is_claimed = false, updated_at = now()
    where claim.provider_capability_id = v_cap.id
      and claim.role_slug = p_role_slug
      and claim.is_claimed
      and claim.evidence_object_path is not null
      and claim.status = 'pending_review';

    -- Approved claims remain claimed and stored while the role is inactive.
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

create or replace function public.submit_provider_role_qualification_evidence(
  p_provider_capability_id uuid,
  p_role_slug text,
  p_qualification_slug text,
  p_evidence_object_path text
)
returns uuid
language plpgsql
security definer
set search_path = public, private, storage
as $$
declare
  v_user_id uuid := auth.uid();
  v_capability_slug text;
  v_claim_id uuid;
  v_claim_status text;
begin
  if v_user_id is null then
    raise exception 'Not authenticated.' using errcode = '42501';
  end if;

  select pc.capability_slug, claim.id, claim.status
  into v_capability_slug, v_claim_id, v_claim_status
  from public.provider_capabilities pc
  join public.provider_role_qualification_claims claim
    on claim.provider_capability_id = pc.id
  join public.role_qualifications rq
    on rq.role_slug = claim.role_slug
   and rq.slug = claim.qualification_slug
  where pc.id = p_provider_capability_id
    and pc.user_id = v_user_id
    and claim.role_slug = p_role_slug
    and claim.qualification_slug = p_qualification_slug
    and claim.is_claimed
    and rq.is_evidence
  for update of claim;

  if not found then
    raise exception 'Claim not found or this qualification does not accept evidence.'
      using errcode = 'P0212';
  end if;
  if v_claim_status = 'verified' then
    raise exception 'Approved qualification evidence cannot be replaced.'
      using errcode = 'P0206';
  end if;

  if p_evidence_object_path is null
     or position('..' in p_evidence_object_path) > 0
     or left(
       p_evidence_object_path,
       length('evidence/' || v_user_id::text || '/' || v_capability_slug || '/')
     ) <> ('evidence/' || v_user_id::text || '/' || v_capability_slug || '/') then
    raise exception 'Evidence must be stored in the provider''s private capability folder.'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from storage.objects so
    where so.bucket_id = 'provider-evidence'
      and so.name = p_evidence_object_path
  ) then
    raise exception 'Uploaded provider evidence was not found in private storage.'
      using errcode = 'P0213';
  end if;

  update public.provider_role_qualification_claims
  set status = 'pending_review',
      evidence_object_path = p_evidence_object_path,
      reject_reason = null,
      expires_at = null,
      reviewed_by = null,
      reviewed_at = null,
      updated_at = now()
  where id = v_claim_id;

  return v_claim_id;
end;
$$;

revoke all on function public.submit_provider_role_qualification_evidence(uuid, text, text, text)
  from public, anon;
grant execute on function public.submit_provider_role_qualification_evidence(uuid, text, text, text)
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
  if v_claim.status = 'verified' then
    return jsonb_build_object('withdrawn', false, 'status', 'verified',
      'has_evidence', v_claim.evidence_object_path is not null);
  end if;
  if v_claim.status <> p_expected_status
     or v_claim.status <> 'pending_review'
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

create or replace function public.remove_provider_role_qualification_evidence(
  p_provider_capability_id uuid,
  p_role_slug text,
  p_qualification_slug text
) returns void
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_claim public.provider_role_qualification_claims%rowtype;
begin
  if v_user is null then
    raise exception 'Not authenticated.' using errcode = '42501';
  end if;
  select claim.* into v_claim
  from public.provider_role_qualification_claims claim
  join public.provider_capabilities pc
    on pc.id = claim.provider_capability_id
  where claim.provider_capability_id = p_provider_capability_id
    and pc.user_id = v_user
    and claim.role_slug = p_role_slug
    and claim.qualification_slug = p_qualification_slug
    and claim.is_claimed
  for update of claim;
  if not found or v_claim.evidence_object_path is null then
    raise exception 'Qualification evidence was not found.' using errcode = 'P0212';
  end if;
  if v_claim.status = 'verified' then
    raise exception 'Approved qualification evidence cannot be removed.'
      using errcode = 'P0206';
  end if;
  delete from storage.objects
  where bucket_id = 'provider-evidence'
    and name = v_claim.evidence_object_path;
  update public.provider_role_qualification_claims
  set evidence_object_path = null,
      status = 'self_declared',
      reject_reason = null,
      reviewed_by = null,
      reviewed_at = null,
      expires_at = null,
      updated_at = now()
  where id = v_claim.id;
  insert into public.audit_logs(
    user_id, event_type, entity_type, action, old_values
  ) values (
    v_user, 'admin_action', 'provider_role_qualification_claim',
    'remove_qualification_evidence',
    jsonb_build_object(
      'provider_capability_id', p_provider_capability_id,
      'role_slug', p_role_slug,
      'qualification_slug', p_qualification_slug
    )
  );
end;
$$;
revoke all on function public.remove_provider_role_qualification_evidence(uuid, text, text)
  from public, anon;
grant execute on function public.remove_provider_role_qualification_evidence(uuid, text, text)
  to authenticated;

commit;
notify pgrst, 'reload schema';
