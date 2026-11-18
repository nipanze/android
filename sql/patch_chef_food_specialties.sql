-- Add restaurant chefs and food specialties to Provider Services.
-- Safe to re-run. Apply after patch_provider_services_work_profiles.sql.

begin;

insert into public.need_capabilities (
  slug, category_slug, name, is_active, ui_group_slug, sort_order,
  service_group_slug, service_group_name, service_sort_order, capability_type
)
values
  ('work_restaurant_chef', 'events_production', 'Chef (Restaurant & Kitchen)',
   true, 'events_production', 60, 'work_roles', 'Work Roles', 60, 'work')
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = true,
  ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  capability_type = 'work';

insert into public.capability_roles (
  slug, category_slug, capability_slug, name, kind_question, is_active
)
values
  ('restaurant_chef', 'events_production', 'work_restaurant_chef',
   'Chef (Restaurant & Kitchen)', 'What foods can you prepare?', true),
  ('caterer_chef', 'events_production', 'work_caterer_chef',
   'Caterer / Chef', 'What cuisine or service?', true)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = true;

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('caterer_chef', 'african_cuisine', 'African foods', 40),
  ('caterer_chef', 'east_african', 'East African foods', 50),
  ('caterer_chef', 'muchomo', 'Muchomo & grilled meats', 60),
  ('caterer_chef', 'italian_cuisine', 'Italian foods', 70),
  ('caterer_chef', 'arabian_cuisine', 'Arabian & Middle Eastern foods', 80),
  ('caterer_chef', 'asian_cuisine', 'Asian foods', 90),
  ('caterer_chef', 'continental_cuisine', 'Continental', 100),
  ('caterer_chef', 'vegetarian', 'Vegetarian dishes', 110),
  ('caterer_chef', 'other_cuisine', 'Other cuisines', 120),
  ('restaurant_chef', 'african_cuisine', 'African foods', 10),
  ('restaurant_chef', 'east_african', 'East African foods', 20),
  ('restaurant_chef', 'muchomo', 'Muchomo & grilled meats', 30),
  ('restaurant_chef', 'italian_cuisine', 'Italian foods', 40),
  ('restaurant_chef', 'arabian_cuisine', 'Arabian & Middle Eastern foods', 50),
  ('restaurant_chef', 'asian_cuisine', 'Asian foods', 60),
  ('restaurant_chef', 'continental_cuisine', 'Continental', 70),
  ('restaurant_chef', 'vegetarian', 'Vegetarian dishes', 80),
  ('restaurant_chef', 'pastries_baking', 'Pastries & baking', 90),
  ('restaurant_chef', 'other_cuisine', 'Other cuisines', 100)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

commit;
