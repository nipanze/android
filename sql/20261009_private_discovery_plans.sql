-- Standalone SQL Patch: 20261009_private_discovery_plans.sql
-- Purpose: Private discovery plans, configurable question templates, and
-- per-user frequency controls for the lightweight Nipanze discovery engine.
-- Do not merge this into sql/patch.sql.

create table if not exists public.discovery_question_templates (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  question text not null,
  category text not null,
  need_category_slug text references public.need_categories(slug) on delete set null,
  plan_type text not null check (plan_type in (
    'travel',
    'education_career',
    'business',
    'financial',
    'general'
  )),
  answer_type text not null default 'single_select' check (answer_type in (
    'single_select',
    'multi_select'
  )),
  options jsonb not null default '[]'::jsonb,
  follow_up_rules jsonb not null default '{}'::jsonb,
  country_codes text[],
  priority int not null default 100,
  active_from timestamptz,
  active_until timestamptz,
  cta_label text,
  deep_link text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint discovery_template_options_array check (jsonb_typeof(options) = 'array'),
  constraint discovery_template_followups_object check (jsonb_typeof(follow_up_rules) = 'object')
);

create index if not exists idx_discovery_templates_active
  on public.discovery_question_templates(is_active, priority, active_from, active_until);
create index if not exists idx_discovery_templates_category
  on public.discovery_question_templates(category, need_category_slug);

create table if not exists public.user_discovery_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  template_id uuid references public.discovery_question_templates(id) on delete set null,
  category text not null,
  need_category_slug text references public.need_categories(slug) on delete set null,
  plan_type text not null check (plan_type in (
    'travel',
    'education_career',
    'business',
    'financial',
    'general'
  )),
  title text not null,
  answers jsonb not null default '{}'::jsonb,
  destination text,
  preferred_location text,
  expected_date date,
  timeframe text,
  reminder_preference text not null default 'none' check (reminder_preference in (
    'none',
    'one_week_before',
    'one_month_before'
  )),
  expires_at timestamptz,
  review_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_discovery_plans_answers_object check (jsonb_typeof(answers) = 'object')
);

create index if not exists idx_user_discovery_plans_user
  on public.user_discovery_plans(user_id, updated_at desc);
create index if not exists idx_user_discovery_plans_review
  on public.user_discovery_plans(user_id, review_at)
  where review_at is not null;

create table if not exists public.user_discovery_interactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  template_id uuid not null references public.discovery_question_templates(id) on delete cascade,
  action text not null check (action in (
    'view',
    'answer',
    'save',
    'skip',
    'dismiss',
    'mute'
  )),
  answer jsonb not null default '{}'::jsonb,
  dismissed_until timestamptz,
  muted_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_discovery_interactions_answer_object check (jsonb_typeof(answer) = 'object')
);

alter table if exists public.user_discovery_interactions
  drop constraint if exists user_discovery_interactions_action_check;
alter table if exists public.user_discovery_interactions
  add constraint user_discovery_interactions_action_check
  check (action in (
    'view',
    'answer',
    'save',
    'skip',
    'dismiss',
    'mute'
  ));

create index if not exists idx_user_discovery_interactions_user
  on public.user_discovery_interactions(user_id, created_at desc);
create index if not exists idx_user_discovery_interactions_template
  on public.user_discovery_interactions(user_id, template_id, action, created_at desc);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_discovery_question_templates_updated_at
  on public.discovery_question_templates;
create trigger trg_discovery_question_templates_updated_at
  before update on public.discovery_question_templates
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_user_discovery_plans_updated_at
  on public.user_discovery_plans;
create trigger trg_user_discovery_plans_updated_at
  before update on public.user_discovery_plans
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_user_discovery_interactions_updated_at
  on public.user_discovery_interactions;
create trigger trg_user_discovery_interactions_updated_at
  before update on public.user_discovery_interactions
  for each row execute function public.touch_updated_at();

alter table public.discovery_question_templates enable row level security;
alter table public.user_discovery_plans enable row level security;
alter table public.user_discovery_interactions enable row level security;

drop policy if exists "Discovery templates readable by authenticated users"
  on public.discovery_question_templates;
create policy "Discovery templates readable by authenticated users"
  on public.discovery_question_templates
  for select to authenticated
  using (
    is_active = true
    and (active_from is null or active_from <= now())
    and (active_until is null or active_until >= now())
  );

drop policy if exists "Admins manage discovery templates"
  on public.discovery_question_templates;
create policy "Admins manage discovery templates"
  on public.discovery_question_templates
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

drop policy if exists "Users manage own discovery plans"
  on public.user_discovery_plans;
create policy "Users manage own discovery plans"
  on public.user_discovery_plans
  for all to authenticated
  using (user_id = auth.uid() or private.is_admin())
  with check (user_id = auth.uid() or private.is_admin());

drop policy if exists "Users manage own discovery interactions"
  on public.user_discovery_interactions;
create policy "Users manage own discovery interactions"
  on public.user_discovery_interactions
  for all to authenticated
  using (user_id = auth.uid() or private.is_admin())
  with check (user_id = auth.uid() or private.is_admin());

grant select on public.discovery_question_templates to authenticated;
grant insert, update, delete on public.discovery_question_templates to authenticated;
grant select, insert, update, delete on public.user_discovery_plans to authenticated;
grant select, insert, update, delete on public.user_discovery_interactions to authenticated;

insert into public.need_categories (slug, name, icon, sort_order, is_active)
values
  ('travel_international', 'Travel & International', '✈️', 10, true),
  ('education_training', 'Education & Training', '🎓', 20, true)
on conflict (slug) do nothing;

insert into public.discovery_question_templates (
  slug,
  title,
  question,
  category,
  need_category_slug,
  plan_type,
  answer_type,
  options,
  follow_up_rules,
  country_codes,
  priority,
  cta_label,
  deep_link
) values
  (
    'travel_planning_basic',
    'A quick question',
    'Are you planning travel in the next few months?',
    'travel',
    'travel_international',
    'travel',
    'single_select',
    '[
      {"value": "yes", "label": "Yes", "save_plan": true},
      {"value": "later", "label": "Maybe later"},
      {"value": "no", "label": "No"}
    ]'::jsonb,
    '{"yes": ["destination", "timeframe", "assistance_needed"]}'::jsonb,
    array['UG','KE','TZ','RW','NG','ZA','EG'],
    10,
    'Explore travel help',
    '/marketplace'
  ),
  (
    'internship_interest_basic',
    'A quick question',
    'Would internship or professional development opportunities be useful to you?',
    'education',
    'education_training',
    'education_career',
    'single_select',
    '[
      {"value": "yes", "label": "Yes", "save_plan": true},
      {"value": "not_now", "label": "Not now"}
    ]'::jsonb,
    '{"yes": ["industry", "preferred_location", "timeframe"]}'::jsonb,
    array['UG','KE','TZ','RW','NG','ZA','EG'],
    20,
    'Explore education',
    '/marketplace'
  ),
  (
    'business_equipment_basic',
    'Planning something ahead?',
    'Do you need equipment, logistics, procurement or business services soon?',
    'business',
    'professional_services',
    'business',
    'multi_select',
    '[
      {"value": "equipment", "label": "Equipment", "category_slug": "machinery_equipment"},
      {"value": "logistics", "label": "Logistics", "category_slug": "transport_logistics"},
      {"value": "services", "label": "Services", "category_slug": "professional_services"},
      {"value": "procurement", "label": "Procurement", "category_slug": "specialized_products"}
    ]'::jsonb,
    '{"equipment": ["preferred_location", "timeframe"], "logistics": ["preferred_location", "timeframe"], "services": ["preferred_location", "timeframe"], "procurement": ["preferred_location", "timeframe"]}'::jsonb,
    array['UG','KE','TZ','RW','NG','ZA','EG'],
    30,
    'Discover opportunities',
    '/marketplace'
  ),
  (
    'financial_interest_basic',
    'Would this be useful to you?',
    'Are you interested in loans, financing or Forex opportunities?',
    'financial',
    null,
    'financial',
    'single_select',
    '[
      {"value": "loans", "label": "Loans", "save_plan": true},
      {"value": "forex", "label": "Forex", "save_plan": true},
      {"value": "both", "label": "Both", "save_plan": true},
      {"value": "no", "label": "No"}
    ]'::jsonb,
    '{"loans": ["timeframe"], "forex": ["timeframe"], "both": ["timeframe"]}'::jsonb,
    array['UG','KE','TZ','RW','NG','ZA','EG'],
    40,
    'Open marketplace',
    '/marketplace'
  )
on conflict (slug) do update
set
  title = excluded.title,
  question = excluded.question,
  category = excluded.category,
  need_category_slug = excluded.need_category_slug,
  plan_type = excluded.plan_type,
  answer_type = excluded.answer_type,
  options = excluded.options,
  follow_up_rules = excluded.follow_up_rules,
  country_codes = excluded.country_codes,
  priority = excluded.priority,
  cta_label = excluded.cta_label,
  deep_link = excluded.deep_link,
  is_active = true,
  updated_at = now();
