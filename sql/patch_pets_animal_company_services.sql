-- Add company-selectable offerings for Pets & Animal Services.
-- Run after the Pets & Animal Services catalog patch has created the category
-- and added capability_type/service group columns to need_capabilities.
begin;

insert into public.need_capabilities (
  slug,
  category_slug,
  name,
  is_active,
  ui_group_slug,
  sort_order,
  service_group_slug,
  service_group_name,
  service_sort_order,
  capability_type,
  verification_policy
) values
  ('animal_veterinary_care', 'pets_animal_services', 'Veterinary care', true,
   'pets_animal_services', 1, 'clinical_care', 'Clinical care', 10, 'service', 'open'),
  ('animal_herd_health', 'pets_animal_services', 'Livestock herd health and vaccination', true,
   'pets_animal_services', 2, 'clinical_care', 'Clinical care', 20, 'service', 'open'),
  ('pet_training_behaviour', 'pets_animal_services', 'Pet training and behaviour support', true,
   'pets_animal_services', 3, 'pet_care', 'Pet care', 10, 'service', 'open'),
  ('pet_grooming', 'pets_animal_services', 'Pet grooming', true,
   'pets_animal_services', 4, 'pet_care', 'Pet care', 20, 'service', 'open'),
  ('pet_sitting', 'pets_animal_services', 'In-home pet sitting and visits', true,
   'pets_animal_services', 5, 'pet_care', 'Pet care', 30, 'service', 'open'),
  ('pet_boarding', 'pets_animal_services', 'Pet boarding', true,
   'pets_animal_services', 6, 'pet_care', 'Pet care', 40, 'service', 'open'),
  ('dog_walking', 'pets_animal_services', 'Dog walking', true,
   'pets_animal_services', 7, 'pet_care', 'Pet care', 50, 'service', 'open'),
  ('animal_transport', 'pets_animal_services', 'Animal transport', true,
   'pets_animal_services', 8, 'animal_services', 'Animal services', 10, 'service', 'open'),
  ('animal_breeding', 'pets_animal_services', 'Responsible animal breeding', true,
   'pets_animal_services', 9, 'animal_services', 'Animal services', 20, 'service', 'open'),
  ('animal_nutrition_advice', 'pets_animal_services', 'Animal nutrition advice', true,
   'pets_animal_services', 10, 'animal_services', 'Animal services', 30, 'service', 'open')
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = excluded.is_active,
  ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  capability_type = excluded.capability_type,
  verification_policy = excluded.verification_policy;

commit;
