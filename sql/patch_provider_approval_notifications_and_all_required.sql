-- Require ALL required evidence items to be approved before activating a
-- required-proof provider capability, and send instant in-app notifications
-- when capability evidence, company verification documents, or role
-- qualifications are approved.
-- Apply after patch_financial_services_provider_capabilities.sql,
-- patch_provider_capability_evidence_security.sql,
-- patch_provider_profile_documents.sql, and patch_catalog_expansion_v3.sql.
begin;

-- 1. Enforce all-required-evidence activation in the capability policy trigger.
create or replace function private.enforce_provider_capability_policy()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_category text;
  v_policy text;
  v_type text;
  v_scope_type text;
  v_scope_id text;
  v_rule_provider_type text;
  v_required text[] := array[]::text[];
begin
  select category_slug, verification_policy, capability_type
    into v_category, v_policy, v_type
    from public.need_capabilities where slug = new.capability_slug;
  if not found then
    raise exception 'Provider capability is unavailable.' using errcode = 'P0203';
  end if;

  if v_category = 'financial_services' and v_policy = 'required_proof' then
    select coalesce(new.identity_type, pcp.provider_type, 'company') into v_type
    from (select 1) seed
    left join public.provider_category_profiles pcp
      on pcp.user_id = new.user_id and pcp.category_slug = v_category;
    if v_type = 'individual' then
      -- Individual loan providers can offer loan products without capability
      -- proof. Account/KYC checks still apply when an offer is published.
      new.is_active := true;
    else
      new.is_active := new.verification_level = 'provider_verified'
        and exists (
          select 1 from public.verification_requirements vr
          where vr.scope_type = 'capability' and vr.scope_id = new.capability_slug
            and vr.is_active and vr.provider_type in ('both', v_type)
            and cardinality(vr.required_evidence) > 0
            and not exists (
              select 1 from unnest(vr.required_evidence) as required(key)
              where not exists (
                select 1 from public.provider_capability_evidence e
                where e.provider_capability_id = new.id
                  and e.provider_type in ('both', v_type)
                  and e.requirement_key = required.key and e.status = 'approved'
                  and (e.expires_at is null or e.expires_at > now())
              )
            )
        );
    end if;
  elsif v_policy = 'required_proof' then
    select coalesce(new.identity_type, pcp.provider_type, 'both') into v_type
    from (select 1) seed
    left join public.provider_category_profiles pcp
      on pcp.user_id = new.user_id and pcp.category_slug = v_category;

    select 'capability', new.capability_slug into v_scope_type, v_scope_id
      where exists (
        select 1 from public.verification_requirements r
        where r.scope_type = 'capability' and r.scope_id = new.capability_slug
          and r.is_active and r.provider_type in (v_type, 'both')
      );
    if not found then
      select 'category', v_category into v_scope_type, v_scope_id
        where exists (
          select 1 from public.verification_requirements r
          where r.scope_type = 'category' and r.scope_id = v_category
            and r.is_active and r.provider_type in (v_type, 'both')
        );
    end if;

    if v_scope_type is not null then
      select case when exists (
        select 1 from public.verification_requirements r
        where r.scope_type = v_scope_type and r.scope_id = v_scope_id
          and r.provider_type = v_type and r.is_active
      ) then v_type else 'both' end into v_rule_provider_type;

      select coalesce(array_agg(distinct x.value), array[]::text[]) into v_required
        from public.verification_requirements r
        cross join lateral unnest(
          coalesce(r.required_evidence, array[]::text[]) || coalesce(
            (select array_agg(j.value) from jsonb_array_elements_text(
              case when jsonb_typeof(r.evidence_requirements) = 'array'
                then r.evidence_requirements else '[]'::jsonb end
            ) j(value)), array[]::text[]
          )
        ) x(value)
        where r.scope_type = v_scope_type and r.scope_id = v_scope_id
          and r.is_active and r.provider_type = v_rule_provider_type;
    end if;
    v_required := coalesce(v_required, array[]::text[]);

    new.is_active := new.verification_level = 'provider_verified'
      and (
        (cardinality(v_required) > 0 and not exists (
          select 1 from unnest(v_required) as req(key)
          where not exists (
            select 1 from public.provider_capability_evidence e
            where e.provider_capability_id = new.id
              and e.provider_type in (v_type, 'both')
              and e.requirement_key = req.key
              and e.status = 'approved'
              and (e.expires_at is null or e.expires_at > now())
          )
        ))
        or (cardinality(v_required) = 0 and (
          exists (
            select 1 from public.provider_capability_evidence e
            where e.provider_capability_id = new.id and e.status = 'approved'
              and (e.expires_at is null or e.expires_at > now())
          )
          or exists (
            select 1 from public.provider_role_qualification_claims claim
            where claim.provider_capability_id = new.id
              and claim.status = 'verified'
              and (claim.expires_at is null or claim.expires_at > now())
          )
        ))
      );
  else
    new.is_active := true;
  end if;

  if not private.is_admin() and new.verification_level = 'provider_verified' then
    if tg_op = 'UPDATE' and old.verification_level = 'provider_verified' then
      new.verified_by := old.verified_by;
      new.verified_at := old.verified_at;
    else
      new.verification_level := 'self_declared';
      new.verified_by := null;
      new.verified_at := null;
      if v_policy = 'required_proof'
         and not (v_category = 'financial_services' and new.identity_type = 'individual') then
        new.is_active := false;
      end if;
    end if;
  end if;
  return new;
end;
$$;

-- 2. Only activate capability when ALL required evidence items are approved,
--    and send an instant notification on approval.
create or replace function public.admin_review_provider_capability_evidence(
  p_evidence_id uuid,
  p_action text,
  p_reject_reason text default null,
  p_expires_at timestamptz default null
) returns boolean
language plpgsql security definer
set search_path = public, private, pg_temp
as $$
declare
  v_admin uuid := auth.uid();
  v_evidence record;
  v_required text[] := array[]::text[];
  v_scope_type text;
  v_scope_id text;
  v_provider_type text := 'both';
  v_rule_provider_type text := 'both';
  v_expiry_days integer;
  v_review_expiry timestamptz;
  v_all_approved boolean := false;
  v_cap_name text;
begin
  if not private.is_admin() then
    raise exception 'Unauthorized: Admin access required' using errcode = '42501';
  end if;
  if p_action not in ('approve', 'reject', 'expire') then
    raise exception 'Invalid evidence review action.' using errcode = '22023';
  end if;

  select e.*, pc.user_id as provider_user_id, pc.capability_slug,
         nc.category_slug, nc.name as capability_name
    into v_evidence
    from public.provider_capability_evidence e
    join public.provider_capabilities pc on pc.id = e.provider_capability_id
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where e.id = p_evidence_id for update of e;
  if not found then
    raise exception 'Provider capability evidence not found.' using errcode = 'P0212';
  end if;

  v_provider_type := coalesce(v_evidence.provider_type, 'both');
  v_cap_name := coalesce(nullif(btrim(v_evidence.capability_name), ''), v_evidence.capability_slug);

  update public.provider_capability_evidence set
    status = case when p_action = 'approve' then 'approved'
                  when p_action = 'reject' then 'rejected' else 'expired' end,
    reject_reason = case when p_action = 'reject' then coalesce(p_reject_reason, '') else null end,
    expires_at = case when p_action = 'approve' then p_expires_at else expires_at end,
    reviewed_by = v_admin, reviewed_at = now(), updated_at = now()
    where id = p_evidence_id;

  select 'capability', v_evidence.capability_slug into v_scope_type, v_scope_id
    where exists (select 1 from public.verification_requirements r
      where r.scope_type = 'capability' and r.scope_id = v_evidence.capability_slug and r.is_active
        and r.provider_type in (v_provider_type, 'both'));
  if not found then
    select 'category', v_evidence.category_slug into v_scope_type, v_scope_id
      where exists (select 1 from public.verification_requirements r
        where r.scope_type = 'category' and r.scope_id = v_evidence.category_slug and r.is_active
          and r.provider_type in (v_provider_type, 'both'));
  end if;

  if v_scope_type is not null then
    select case when exists (
        select 1 from public.verification_requirements r
        where r.scope_type = v_scope_type and r.scope_id = v_scope_id
          and r.provider_type = v_provider_type and r.is_active
      ) then v_provider_type else 'both' end into v_rule_provider_type;

    select coalesce(array_agg(distinct x.value), array[]::text[]) into v_required
      from public.verification_requirements r
      cross join lateral unnest(coalesce(r.required_evidence, array[]::text[]) || coalesce(
        (select array_agg(j.value) from jsonb_array_elements_text(
          case when jsonb_typeof(r.evidence_requirements) = 'array' then r.evidence_requirements else '[]'::jsonb end
        ) j(value)), array[]::text[]
      )) x(value)
      where r.scope_type = v_scope_type and r.scope_id = v_scope_id and r.is_active
        and r.provider_type = v_rule_provider_type;

    select r.expires_after_days into v_expiry_days
      from public.verification_requirements r
      where r.scope_type = v_scope_type and r.scope_id = v_scope_id and r.is_active
        and r.provider_type = v_rule_provider_type
      order by (r.provider_type = v_provider_type) desc
      limit 1;
  end if;
  v_required := coalesce(v_required, array[]::text[]);

  v_review_expiry := coalesce(p_expires_at,
    case when v_expiry_days is not null then now() + make_interval(days => v_expiry_days) end);
  if p_action = 'approve' and p_expires_at is null and v_review_expiry is not null then
    update public.provider_capability_evidence
      set expires_at = v_review_expiry where id = p_evidence_id;
  end if;

  -- Check if ALL required evidence items are currently approved and unexpired.
  v_all_approved := (
    cardinality(v_required) > 0 and not exists (
      select 1 from unnest(v_required) req(key)
      where not exists (
        select 1 from public.provider_capability_evidence e
        where e.provider_capability_id = v_evidence.provider_capability_id
          and e.provider_type in (v_provider_type, 'both')
          and e.requirement_key = req.key
          and e.status = 'approved'
          and (e.expires_at is null or e.expires_at > now())
      )
    )
  ) or (
    cardinality(v_required) = 0 and exists (
      select 1 from public.provider_capability_evidence e
      where e.provider_capability_id = v_evidence.provider_capability_id
        and e.status = 'approved'
        and (e.expires_at is null or e.expires_at > now())
    )
  );

  if p_action = 'approve' and v_all_approved then
    update public.provider_capabilities
      set verification_level = 'provider_verified',
          verified_by = v_admin, verified_at = now()
      where id = v_evidence.provider_capability_id;
  elsif p_action in ('reject', 'expire')
      and not v_all_approved
      and not exists (
        select 1 from public.provider_role_qualification_claims claim
        where claim.provider_capability_id = v_evidence.provider_capability_id
          and claim.status = 'verified'
          and (claim.expires_at is null or claim.expires_at > now())
      ) then
    update public.provider_capabilities
      set verification_level = 'self_declared',
          verified_by = null, verified_at = null
      where id = v_evidence.provider_capability_id;
  end if;

  if p_action = 'approve' then
    insert into public.notifications(user_id, type, title, body, data)
    values (
      v_evidence.provider_user_id,
      'system',
      case when v_all_approved then 'Service approved and active'
           else 'Verification document approved' end,
      case when v_all_approved then
        'Your verification for ' || v_cap_name || ' is approved and now live.'
      else
        'A document for ' || v_cap_name || ' was approved. All required documents must be approved to activate.'
      end,
      jsonb_build_object(
        'kind', 'provider_capability_approved',
        'capability_slug', v_evidence.capability_slug,
        'category_slug', v_evidence.category_slug,
        'requirement_key', v_evidence.requirement_key,
        'activated', v_all_approved
      )
    );
  end if;

  insert into public.audit_logs(user_id, event_type, entity_type, entity_id, action, new_values)
  values (v_admin, 'admin_action', 'provider_capability_evidence', p_evidence_id,
    'review_provider_capability_evidence', jsonb_build_object(
      'action', p_action, 'provider_capability_id', v_evidence.provider_capability_id,
      'capability_slug', v_evidence.capability_slug, 'requirement_key', v_evidence.requirement_key,
      'provider_type', v_provider_type, 'reject_reason', p_reject_reason,
      'expires_at', v_review_expiry, 'activated', v_all_approved));
  return true;
end;
$$;
revoke all on function public.admin_review_provider_capability_evidence(uuid, text, text, timestamptz) from public, anon;
grant execute on function public.admin_review_provider_capability_evidence(uuid, text, text, timestamptz) to authenticated;

-- 3. Notify provider immediately when a company verification document is approved.
create or replace function public.admin_review_provider_company_document(
  p_submission_id uuid,
  p_action text,
  p_reject_reason text default null
) returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_admin uuid := auth.uid();
  v_row public.provider_company_verification_submissions%rowtype;
  v_all_approved boolean := false;
  v_doc_label text;
begin
  if not private.is_admin() then
    raise exception 'Admin access required.' using errcode = '42501';
  end if;
  if p_action not in ('approve', 'reject') then
    raise exception 'Invalid company verification action.' using errcode = 'P0204';
  end if;
  if p_action = 'reject' and nullif(btrim(p_reject_reason), '') is null then
    raise exception 'A rejection reason is required.' using errcode = 'P0204';
  end if;
  update public.provider_company_verification_submissions
  set status = case when p_action = 'approve' then 'approved' else 'rejected' end,
      reject_reason = case when p_action = 'reject'
        then left(btrim(p_reject_reason), 300) else null end,
      reviewed_by = v_admin,
      reviewed_at = now(),
      updated_at = now()
  where id = p_submission_id
  returning * into v_row;
  if not found then
    raise exception 'Company document was not found.' using errcode = 'P0212';
  end if;

  if p_action = 'approve' then
    v_doc_label := case v_row.document_type
      when 'business_registration' then 'Business registration certificate'
      when 'business_licence' then 'Licences or authorization documents'
      else 'Company verification document'
    end;
    v_all_approved := not exists (
      select 1 from public.provider_company_verification_submissions s
      where s.user_id = v_row.user_id
        and s.category_slug = v_row.category_slug
        and s.status <> 'approved'
    );
    insert into public.notifications(user_id, type, title, body, data)
    values (
      v_row.user_id,
      'system',
      case when v_all_approved then 'Company verification approved'
           else 'Company document approved' end,
      case when v_all_approved then
        v_doc_label || ' approved. Your company verification is now approved.'
      else
        v_doc_label || ' was approved.'
      end,
      jsonb_build_object(
        'kind', 'provider_company_document_approved',
        'category_slug', v_row.category_slug,
        'document_type', v_row.document_type,
        'submission_id', v_row.id,
        'all_approved', v_all_approved
      )
    );
  end if;

  insert into public.audit_logs(
    user_id, event_type, entity_type, action, old_values, new_values
  ) values (
    v_admin, 'admin_action', 'provider_company_verification',
    'review_company_document', null,
    jsonb_build_object(
      'provider_user_id', v_row.user_id,
      'submission_id', v_row.id,
      'category_slug', v_row.category_slug,
      'document_type', v_row.document_type,
      'action', p_action,
      'reject_reason', p_reject_reason,
      'reviewed_at', now()
    )
  );
  return true;
end;
$$;
revoke all on function public.admin_review_provider_company_document(uuid, text, text)
  from public, anon;
grant execute on function public.admin_review_provider_company_document(uuid, text, text)
  to authenticated;

-- 4. Notify provider immediately when a role qualification claim is approved.
create or replace function public.admin_review_provider_role_qualification(
  p_claim_id uuid,
  p_action text,
  p_reject_reason text default null,
  p_expires_at timestamptz default null
) returns boolean
language plpgsql security definer
set search_path = public, private, pg_temp
as $$
declare
  v_admin uuid := auth.uid();
  v_claim record;
  v_effective_expiry timestamptz := p_expires_at;
begin
  if not private.is_admin() then
    raise exception 'Unauthorized: Admin access required.' using errcode = '42501';
  end if;
  if p_action not in ('approve', 'reject', 'expire') then
    raise exception 'Action must be approve, reject, or expire.' using errcode = '22023';
  end if;
  select claim.*, pc.capability_slug, pc.user_id, rq.expires_after_days,
         nc.name as capability_name
  into v_claim
  from public.provider_role_qualification_claims claim
  join public.provider_capabilities pc on pc.id = claim.provider_capability_id
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  join public.role_qualifications rq
    on rq.role_slug = claim.role_slug and rq.slug = claim.qualification_slug
  where claim.id = p_claim_id
  for update of claim;
  if not found then
    raise exception 'Provider role qualification claim not found.' using errcode = 'P0212';
  end if;
  if p_action = 'approve' and v_claim.status <> 'pending_review' then
    raise exception 'Only submitted qualification evidence can be approved.' using errcode = '22023';
  end if;
  if p_action = 'approve' and v_effective_expiry is null
     and v_claim.expires_after_days is not null then
    v_effective_expiry := now() + make_interval(days => v_claim.expires_after_days);
  end if;
  if p_action = 'approve' and v_effective_expiry is not null
     and v_effective_expiry <= now() then
    raise exception 'Evidence expiry must be in the future.' using errcode = '22023';
  end if;
  update public.provider_role_qualification_claims
  set status = case when p_action = 'approve' then 'verified'
                    when p_action = 'reject' then 'rejected' else 'expired' end,
      reject_reason = case when p_action = 'reject' then coalesce(p_reject_reason, '') else null end,
      expires_at = case when p_action = 'approve' then v_effective_expiry else expires_at end,
      reviewed_by = v_admin, reviewed_at = now(), updated_at = now()
  where id = p_claim_id;

  if p_action = 'approve' then
    insert into public.notifications(user_id, type, title, body, data)
    values (
      v_claim.user_id,
      'system',
      'Role qualification approved',
      'Your qualification for ' || coalesce(nullif(btrim(v_claim.capability_name), ''), v_claim.capability_slug) || ' was approved.',
      jsonb_build_object(
        'kind', 'provider_role_qualification_approved',
        'capability_slug', v_claim.capability_slug,
        'role_slug', v_claim.role_slug,
        'qualification_slug', v_claim.qualification_slug,
        'claim_id', p_claim_id
      )
    );
  end if;

  insert into public.audit_logs
    (user_id, event_type, entity_type, entity_id, action, new_values)
  values
    (v_admin, 'admin_action', 'provider_role_qualification_claim', p_claim_id,
     'review_provider_role_qualification', jsonb_build_object(
       'action', p_action, 'provider_capability_id', v_claim.provider_capability_id,
       'capability_slug', v_claim.capability_slug, 'role_slug', v_claim.role_slug,
       'qualification_slug', v_claim.qualification_slug,
       'reject_reason', p_reject_reason, 'expires_at', v_effective_expiry));
  return true;
end;
$$;
revoke all on function public.admin_review_provider_role_qualification(uuid, text, text, timestamptz)
  from public, anon;
grant execute on function public.admin_review_provider_role_qualification(uuid, text, text, timestamptz)
  to authenticated;

commit;
