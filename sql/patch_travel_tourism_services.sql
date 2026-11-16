-- Add a dedicated Tourism Services group to the Travel & International provider catalog.
-- Apply after patch_provider_services_v2_catalog.sql.
-- Existing tour_packages selections remain linked to the same capability slug.

begin;

do $$
begin
  if to_regclass('public.need_capabilities') is null then
    raise exception 'Provider Services catalog is missing. Apply patch_provider_services_v2_catalog.sql first.';
  end if;
end;
$$;

insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order)
values
  ('tour_packages', 'travel_international', 'Tour Packages', true,
   'travel_international', 140, 'tourism_services', 'Tourism Services', 10),
  ('tour_guiding_services', 'travel_international', 'Tour Guiding', true,
   'travel_international', 150, 'tourism_services', 'Tourism Services', 20),
  ('tour_operator_services', 'travel_international', 'Tour Operations', true,
   'travel_international', 160, 'tourism_services', 'Tourism Services', 30),
  ('travel_planning_services', 'travel_international', 'Travel Planning & Itineraries', true,
   'travel_international', 170, 'tourism_services', 'Tourism Services', 40),
  ('local_experiences', 'travel_international', 'Local Experiences', true,
   'travel_international', 180, 'tourism_services', 'Tourism Services', 50)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = true,
  ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order;

commit;
