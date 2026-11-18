-- Add restaurant chefs and food specialties to Provider Services.
-- Safe to re-run. Apply after patch_provider_services_work_profiles.sql.

begin;

insert into public.need_capabilities (
  slug, category_slug, name, is_active, ui_group_slug, sort_order,
  service_group_slug, service_group_name, service_sort_order, capability_type
)
values
  ('work_restaurant_chef', 'events_production', 'Chef (Restaurant & Kitchen)',
   true, 'events_production', 60, 'work_roles', 'Work Roles', 60, 'work'),
  ('work_barista', 'events_production', 'Barista',
   true, 'events_production', 61, 'work_roles', 'Work Roles', 61, 'work'),
  ('work_baker_pastry_chef', 'events_production', 'Baker / Pastry Chef',
   true, 'events_production', 62, 'work_roles', 'Work Roles', 62, 'work'),
  ('work_kitchen_assistant', 'events_production', 'Kitchen Assistant / Food Prep',
   true, 'events_production', 63, 'work_roles', 'Work Roles', 63, 'work'),
  ('work_food_server', 'events_production', 'Food Server / Waiter',
   true, 'events_production', 64, 'work_roles', 'Work Roles', 64, 'work')
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
   'Caterer / Chef', 'What cuisine or service?', true),
  ('barista', 'events_production', 'work_barista',
   'Barista', 'Which drinks can you prepare?', true),
  ('baker_pastry_chef', 'events_production', 'work_baker_pastry_chef',
   'Baker / Pastry Chef', 'What baked goods do you make?', true),
  ('kitchen_assistant', 'events_production', 'work_kitchen_assistant',
   'Kitchen Assistant / Food Prep', 'Which kitchen tasks can you do?', true),
  ('food_server', 'events_production', 'work_food_server',
   'Food Server / Waiter', 'What service can you provide?', true)
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
  ('restaurant_chef', 'other_cuisine', 'Other cuisines', 100),
  ('barista', 'coffee_espresso', 'Coffee & espresso', 10),
  ('barista', 'tea_drinks', 'Tea drinks', 20),
  ('barista', 'cold_drinks', 'Cold drinks', 30),
  ('barista', 'smoothies', 'Smoothies', 40),
  ('baker_pastry_chef', 'bread', 'Bread', 10),
  ('baker_pastry_chef', 'cakes', 'Cakes', 20),
  ('baker_pastry_chef', 'pastries', 'Pastries', 30),
  ('baker_pastry_chef', 'custom_cakes', 'Custom cakes', 40),
  ('kitchen_assistant', 'ingredient_prep', 'Ingredient prep', 10),
  ('kitchen_assistant', 'food_packing', 'Food packing', 20),
  ('kitchen_assistant', 'kitchen_cleaning', 'Kitchen cleaning', 30),
  ('kitchen_assistant', 'service_support', 'Service support', 40),
  ('food_server', 'table_service', 'Table service', 10),
  ('food_server', 'counter_service', 'Counter service', 20),
  ('food_server', 'event_service', 'Event service', 30),
  ('food_server', 'meal_delivery', 'Meal delivery', 40)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

commit;
