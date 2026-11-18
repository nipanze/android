-- Add Property & Real Estate to Provider Services and the Needs catalog.
-- Safe to rerun; does not overwrite provider selections or evidence.
begin;

insert into public.need_categories
  (slug, name, icon, sort_order, description, is_active)
values
  ('property_real_estate', 'Property & Real Estate', '🏡', 19,
   'Land and homes to buy, rent or lease, and property agents.', true)
on conflict (slug) do update set
  name = excluded.name,
  icon = excluded.icon,
  sort_order = excluded.sort_order,
  description = excluded.description,
  is_active = true;

insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order, capability_type)
values
  ('property_sales', 'property_real_estate', 'Property Sales', true,
   'property_real_estate', 110, 'sales_rentals', 'Sales & Rentals', 10, 'service'),
  ('property_rentals', 'property_real_estate', 'Property Rentals', true,
   'property_real_estate', 120, 'sales_rentals', 'Sales & Rentals', 20, 'service'),
  ('land_sales_leasing', 'property_real_estate', 'Land Sales & Leasing', true,
   'property_real_estate', 130, 'sales_rentals', 'Sales & Rentals', 30, 'service'),
  ('property_agent_services', 'property_real_estate', 'Property Agents', true,
   'property_real_estate', 210, 'agent_support', 'Agent Support', 10, 'service'),
  ('property_management', 'property_real_estate', 'Property Management', true,
   'property_real_estate', 220, 'agent_support', 'Agent Support', 20, 'service'),
  ('other_property_services', 'property_real_estate', 'Other Property Services', true,
   'property_real_estate', 310, 'other', 'Other', 10, 'service')
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = true,
  ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  capability_type = 'service';

insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order, capability_type)
values
  ('work_property_agent', 'property_real_estate', 'Property Agent / Broker', true,
   'property_real_estate', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_landowner_seller', 'property_real_estate', 'Private Owner Selling Property', true,
   'property_real_estate', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_landlord', 'property_real_estate', 'Private Landlord Renting Property', true,
   'property_real_estate', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_property_manager', 'property_real_estate', 'Property Manager', true,
   'property_real_estate', 40, 'work_roles', 'Work Roles', 40, 'work')
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

insert into public.capability_roles
  (slug, category_slug, capability_slug, name, kind_question, is_active)
values
  ('property_agent', 'property_real_estate', 'work_property_agent', 'Property Agent / Broker', 'What properties do you handle?', true),
  ('landowner_seller', 'property_real_estate', 'work_landowner_seller', 'Private Owner / One-time Seller', 'What property do you offer directly?', true),
  ('landlord', 'property_real_estate', 'work_landlord', 'Private Landlord / Direct Rental', 'What rentals do you offer directly?', true),
  ('property_manager', 'property_real_estate', 'work_property_manager', 'Property Manager', 'What do you manage?', true)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = true;

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('property_agent', 'land_purchase', 'Land purchase', 10),
  ('property_agent', 'home_purchase', 'Home purchase', 20),
  ('property_agent', 'rentals', 'Rentals', 30),
  ('property_agent', 'leasing', 'Leasing', 40),
  ('landowner_seller', 'residential_plots', 'Residential plots', 10),
  ('landowner_seller', 'farmland', 'Farmland', 20),
  ('landowner_seller', 'houses', 'Houses', 30),
  ('landlord', 'houses', 'Houses', 10),
  ('landlord', 'apartments', 'Apartments', 20),
  ('landlord', 'commercial_property', 'Commercial property', 30),
  ('property_manager', 'tenant_management', 'Tenant management', 10),
  ('property_manager', 'rent_collection', 'Rent collection', 20),
  ('property_manager', 'maintenance_coordination', 'Maintenance coordination', 30)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

commit;
notify pgrst, 'reload schema';
