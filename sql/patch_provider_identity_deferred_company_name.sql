-- Allow an identity switch to proceed before company details are entered.
-- Apply after patch_provider_company_name_single_source.sql.
begin;

create or replace function private.switch_provider_identity_internal(
  p_category_slug text, p_to_identity text, p_presentation jsonb
) returns jsonb language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare
  v_user uuid:=auth.uid();
  v_from text;
  v_enabled text;
  v_company_name text;
  v_deactivated int:=0;
  v_reactivated int:=0;
  v_pending int:=0;
  v_active int:=0;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode='42501'; end if;
  if p_to_identity is null or p_to_identity not in ('individual','company') then
    raise exception 'Invalid target identity.' using errcode='P0216';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text || ':' || p_category_slug,0));
  select provider_type into v_from from public.provider_category_profiles
    where user_id=v_user and category_slug=p_category_slug for update;
  if not found or v_from=p_to_identity then
    raise exception 'Identity switch is unavailable.' using errcode='P0216';
  end if;
  select setting_value into v_enabled from public.system_settings
    where setting_key='capability_profiles_enabled' and is_public
    order by (country=(select country from public.profiles where id=v_user)) desc nulls last
    limit 1;
  if lower(coalesce(v_enabled,'false')) not in ('true','1') then
    raise exception 'Provider profiles are disabled.' using errcode='P0216';
  end if;
  if (select count(*) from public.audit_logs a where a.user_id=v_user
      and a.entity_type='provider_identity' and a.action='switch'
      and a.new_values->>'category_slug'=p_category_slug
      and a.created_at>now()-interval '24 hours')>=5 then
    raise exception 'You have reached the identity switch limit for this category.'
      using errcode='P0216';
  end if;
  if not exists(select 1 from public.need_categories
      where slug=p_category_slug and is_active) then
    raise exception 'Provider category is unavailable.' using errcode='P0216';
  end if;

  if p_to_identity='company' then
    select coalesce(
      nullif(btrim(p_presentation->>'display_name'),''),
      nullif(btrim(cp.company_name),''),
      nullif(btrim(ip.display_name),''))
      into v_company_name
      from (select 1) seed
      left join public.provider_company_profiles cp
        on cp.user_id=v_user and cp.category_slug=p_category_slug
      left join public.provider_identity_presentations ip
        on ip.user_id=v_user and ip.category_slug=p_category_slug
        and ip.identity_type='company';
  end if;

  update public.provider_category_profiles
    set provider_type=p_to_identity, identity_changed_at=now(), updated_at=now()
    where user_id=v_user and category_slug=p_category_slug;

  if p_to_identity<>'company' or v_company_name is not null then
    perform private.save_provider_identity_presentation_internal(
      p_category_slug, p_to_identity,
      coalesce(p_presentation,'{}'::jsonb) ||
        case when p_to_identity='company'
          then jsonb_build_object('display_name',v_company_name)
          else '{}'::jsonb end);
  end if;

  update public.provider_capabilities pc set is_active=false
    from public.need_capabilities nc
    where nc.slug=pc.capability_slug and pc.user_id=v_user
      and nc.category_slug=p_category_slug and nc.capability_type='service'
      and pc.identity_type=v_from and pc.is_active;
  get diagnostics v_deactivated=row_count;

  if p_to_identity='company' and v_company_name is null then
    update public.provider_capabilities pc set is_active=false
      from public.need_capabilities nc
      where nc.slug=pc.capability_slug and pc.user_id=v_user
        and nc.category_slug=p_category_slug and nc.capability_type='service'
        and pc.identity_type='company' and pc.is_active;
  else
    update public.provider_capabilities pc set is_active=true
      from public.need_capabilities nc
      where nc.slug=pc.capability_slug and pc.user_id=v_user
        and nc.category_slug=p_category_slug and nc.capability_type='service'
        and pc.identity_type=p_to_identity;
  end if;

  select count(*) into v_reactivated from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug=pc.capability_slug
    where pc.user_id=v_user and nc.category_slug=p_category_slug
      and nc.capability_type='service' and pc.identity_type=p_to_identity and pc.is_active;
  select count(*) into v_pending from public.need_offers o
    join public.needs_requests n on n.request_id=o.need_id
    where o.offer_maker_id=v_user and n.category_slug=p_category_slug and o.status='pending';
  select count(*) into v_active from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug=pc.capability_slug
    where pc.user_id=v_user and nc.category_slug=p_category_slug
      and nc.capability_type='service' and pc.is_active;

  insert into public.audit_logs(user_id,event_type,entity_type,action,old_values,new_values)
    values(v_user,'admin_action','provider_identity','switch',
      jsonb_build_object('category_slug',p_category_slug,'from',v_from),
      jsonb_build_object('category_slug',p_category_slug,'to',p_to_identity,
        'deactivated',v_deactivated,'reactivated',v_reactivated,'pending_offers',v_pending,
        'representative_authorized',
          coalesce((p_presentation->>'representative_authorized')::boolean,false)));
  return jsonb_build_object('provider_type',p_to_identity,'deactivated',v_deactivated,
    'reactivated',v_reactivated,'pending_offers',v_pending,'active_capabilities',v_active);
end;
$$;
revoke all on function private.switch_provider_identity_internal(text,text,jsonb)
  from public,anon;
grant execute on function private.switch_provider_identity_internal(text,text,jsonb)
  to authenticated;

create or replace function public.switch_provider_identity(
  p_category_slug text,
  p_to_identity text,
  p_presentation jsonb
) returns jsonb language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare
  v_name text:=nullif(btrim(coalesce(p_presentation->>'display_name','')),'');
  v_result jsonb;
begin
  if p_to_identity='company' and v_name is null then
    select coalesce(
      nullif(btrim(cp.company_name),''),
      nullif(btrim(ip.display_name),''))
      into v_name
      from (select 1) seed
      left join public.provider_company_profiles cp
        on cp.user_id=auth.uid() and cp.category_slug=p_category_slug
      left join public.provider_identity_presentations ip
        on ip.user_id=auth.uid() and ip.category_slug=p_category_slug
        and ip.identity_type='company';
  end if;
  if p_to_identity='company' and char_length(v_name)>80 then
    raise exception 'Company name must be 80 characters or fewer.' using errcode='P0218';
  end if;

  v_result:=private.switch_provider_identity_internal(
    p_category_slug,
    p_to_identity,
    coalesce(p_presentation,'{}'::jsonb) ||
      case when p_to_identity='company' and v_name is not null
        then jsonb_build_object('display_name',v_name)
        else '{}'::jsonb end);

  if p_to_identity='company' and v_name is not null then
    insert into public.provider_company_profiles(user_id,category_slug,company_name)
      values(auth.uid(),p_category_slug,v_name)
      on conflict(user_id,category_slug) do update
        set company_name=excluded.company_name,updated_at=now();
  end if;
  return v_result;
end;
$$;
revoke all on function public.switch_provider_identity(text,text,jsonb)
  from public,anon;
grant execute on function public.switch_provider_identity(text,text,jsonb)
  to authenticated;

commit;
