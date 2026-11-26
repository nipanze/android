-- ============================================================================
-- NIPANZE Combined Database Patch (sql/patch.sql)
--
-- Apply after sql/schema.sql for an existing database (or before sql/seed.sql
-- on a fresh database).
-- This file consolidates all 52 incremental patch scripts into one canonical
-- patch file so sql/ contains only: schema.sql, seed.sql, and patch.sql.
--
-- Sections are ordered chronologically and by dependency so later sections can
-- rely on objects and enum values created by earlier sections.
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (1/52): patch_provider_services_v2_catalog.sql
-- ============================================================================

-- Provider Services v2 catalog synchronization.
-- Source: provider_services_v2.json
-- Apply in Supabase SQL Editor after the base schema and capability-profile patch.
-- Safe to re-run. Existing capability slugs are preserved when they already
-- represent the same service, so provider_capabilities and saved offers remain linked.
-- The repeated Project Manager role gets category-scoped slugs because
-- capability_roles.slug is globally unique in the existing schema.

begin;

do $$
begin
  if to_regclass('public.need_categories') is null
     or to_regclass('public.need_capabilities') is null
     or to_regclass('public.capability_roles') is null
     or to_regclass('public.role_kinds') is null
     or to_regclass('public.role_qualifications') is null
     or to_regclass('public.system_settings') is null then
    raise exception 'Provider Services base tables are missing. Apply the base schema and capability-profile patch first.';
  end if;
end;
$$;

alter table public.need_categories
  add column if not exists description text;

alter table public.need_capabilities
  add column if not exists ui_group_slug text,
  add column if not exists sort_order integer not null default 1000,
  add column if not exists service_group_slug text,
  add column if not exists service_group_name text,
  add column if not exists service_sort_order integer not null default 1000;

comment on column public.need_capabilities.ui_group_slug is
  'Provider Services v2 top-level category id from provider_services_v2.json.';
comment on column public.need_capabilities.service_group_slug is
  'Provider Services v2 service-group id, scoped by category_slug.';
comment on column public.need_capabilities.service_group_name is
  'Provider Services v2 service-group display label.';
comment on column public.need_capabilities.service_sort_order is
  'Display order of the service within its Provider Services v2 group.';

-- Use existing backend category slugs to avoid changing foreign keys and saved data.
insert into public.need_categories
  (slug, name, icon, sort_order, description, is_active)
values
  ('machinery_equipment', 'Machinery & Equipment', '🚜', 1, 'Heavy machinery and equipment hire, with or without an operator', true),
  ('transport_logistics', 'Transport & Logistics', '🚚', 2, 'Moving, hauling, delivery and cold chain', true),
  ('specialized_products', 'Procurement & Sourcing', '🔎', 3, 'Buying, importing and finding hard-to-get products', true),
  ('construction_building', 'Construction & Building', '🏗️', 4, 'Contractors, trades and surveying', true),
  ('professional_services', 'Business & Professional Services', '💼', 5, 'Consulting, legal, accounting, HR and design', true),
  ('travel_international', 'Travel & International', '✈️', 6, 'Bookings, visas, tours and relocation', true),
  ('agriculture_agribusiness', 'Agriculture & Agribusiness', '🌾', 7, 'Farm services, inputs and produce', true),
  ('energy_utilities', 'Energy & Water', '⚡', 8, 'Solar, power backup, boreholes and water systems', true),
  ('technology_digital', 'Technology & Digital', '💻', 9, 'Software, websites, IT support and security', true),
  ('marketing_promotion', 'Marketing & Promotion', '📣', 10, 'Advertising, content and influencer work', true),
  ('education_training', 'Education & Training', '🎓', 11, 'Learning, admissions and placements', true),
  ('events_production', 'Events & Celebrations', '🎉', 12, 'Weddings, parties, corporate events and the services behind them', true),
  ('photo_video_music_talent', 'Photo, Video, Music & Talent', '🎬', 13, 'Creative production and performers for any occasion', true),
  ('beauty_fashion_styling', 'Beauty, Fashion & Styling', '💄', 14, 'Makeup, hair, styling and clothing', true)
on conflict (slug) do update set
  name = excluded.name,
  icon = excluded.icon,
  sort_order = excluded.sort_order,
  description = excluded.description,
  is_active = true;

-- Canonical v2 offers, reusing established database slugs for equivalent services.
insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order)
values
  ('software_development', 'technology_digital', 'Software Development', true, 'technology_digital', 110, 'build', 'Build', 10),
  ('website_development', 'technology_digital', 'Website Development', true, 'technology_digital', 120, 'build', 'Build', 20),
  ('mobile_app_development', 'technology_digital', 'Mobile App Development', true, 'technology_digital', 130, 'build', 'Build', 30),
  ('automation_services', 'technology_digital', 'Automation', true, 'technology_digital', 140, 'build', 'Build', 40),
  ('it_support', 'technology_digital', 'IT Support', true, 'technology_digital', 210, 'support_infrastructure', 'Support & Infrastructure', 10),
  ('networking_services', 'technology_digital', 'Networking', true, 'technology_digital', 220, 'support_infrastructure', 'Support & Infrastructure', 20),
  ('cybersecurity_services', 'technology_digital', 'Cybersecurity', true, 'technology_digital', 230, 'support_infrastructure', 'Support & Infrastructure', 30),
  ('other_technology', 'technology_digital', 'Other Technology', true, 'technology_digital', 310, 'other', 'Other', 10),
  ('digital_marketing', 'marketing_promotion', 'Digital Marketing', true, 'marketing_promotion', 110, 'campaigns', 'Campaigns', 10),
  ('social_media_marketing', 'marketing_promotion', 'Social Media Marketing', true, 'marketing_promotion', 120, 'campaigns', 'Campaigns', 20),
  ('advertising_campaigns', 'marketing_promotion', 'Advertising Campaigns', true, 'marketing_promotion', 130, 'campaigns', 'Campaigns', 30),
  ('brand_promotion', 'marketing_promotion', 'Brand Promotion', true, 'marketing_promotion', 140, 'campaigns', 'Campaigns', 40),
  ('event_promotion', 'marketing_promotion', 'Event Promotion', true, 'marketing_promotion', 150, 'campaigns', 'Campaigns', 50),
  ('affiliate_marketing', 'marketing_promotion', 'Affiliate Marketing', true, 'marketing_promotion', 160, 'campaigns', 'Campaigns', 60),
  ('content_creation', 'marketing_promotion', 'Content Creation', true, 'marketing_promotion', 210, 'content_reach', 'Content & Reach', 10),
  ('influencer_marketing', 'marketing_promotion', 'Influencer Marketing', true, 'marketing_promotion', 220, 'content_reach', 'Content & Reach', 20),
  ('product_reviews', 'marketing_promotion', 'Product Reviews', true, 'marketing_promotion', 230, 'content_reach', 'Content & Reach', 30),
  ('i_have_an_audience', 'marketing_promotion', 'I Have an Audience', true, 'marketing_promotion', 240, 'content_reach', 'Content & Reach', 40),
  ('other_marketing_services', 'marketing_promotion', 'Other Marketing Services', true, 'marketing_promotion', 310, 'other', 'Other', 10),
  ('accounting_tax', 'professional_services', 'Accounting & Tax', true, 'business_professional_services', 110, 'finance_legal', 'Finance & Legal', 10),
  ('legal_services', 'professional_services', 'Legal Services', true, 'business_professional_services', 120, 'finance_legal', 'Finance & Legal', 20),
  ('company_registration', 'professional_services', 'Company Registration', true, 'business_professional_services', 130, 'finance_legal', 'Finance & Legal', 30),
  ('business_consulting', 'professional_services', 'Business Consulting', true, 'business_professional_services', 210, 'advisory', 'Advisory', 10),
  ('hr_services', 'professional_services', 'HR Services', true, 'business_professional_services', 220, 'advisory', 'Advisory', 20),
  ('architecture_services', 'professional_services', 'Architecture', true, 'business_professional_services', 310, 'design_engineering', 'Design & Engineering', 10),
  ('engineering_consulting', 'professional_services', 'Engineering', true, 'business_professional_services', 320, 'design_engineering', 'Design & Engineering', 20),
  ('driving_school', 'professional_services', 'Driving School / Driver Training', true, 'business_professional_services', 330, 'design_engineering', 'Design & Engineering', 30),
  ('other_professional', 'professional_services', 'Other Professional Services', true, 'business_professional_services', 410, 'other', 'Other', 10),
  ('private_tutoring', 'education_training', 'Private Tutoring', true, 'education_training', 110, 'learning', 'Learning', 10),
  ('online_classes', 'education_training', 'Online Classes', true, 'education_training', 120, 'learning', 'Learning', 20),
  ('exam_preparation', 'education_training', 'Exam Preparation', true, 'education_training', 130, 'learning', 'Learning', 30),
  ('language_training', 'education_training', 'Language Training', true, 'education_training', 140, 'learning', 'Learning', 40),
  ('computer_training', 'education_training', 'Computer Training', true, 'education_training', 150, 'learning', 'Learning', 50),
  ('professional_training', 'education_training', 'Professional Training', true, 'education_training', 160, 'learning', 'Learning', 60),
  ('vocational_training', 'education_training', 'Vocational Training', true, 'education_training', 170, 'learning', 'Learning', 70),
  ('academic_consulting', 'education_training', 'Academic Consulting', true, 'education_training', 180, 'learning', 'Learning', 80),
  ('university_admissions', 'education_training', 'University Admissions', true, 'education_training', 210, 'admissions_placements', 'Admissions & Placements', 10),
  ('study_abroad_guidance', 'education_training', 'Study Abroad Guidance', true, 'education_training', 220, 'admissions_placements', 'Admissions & Placements', 20),
  ('internship_placement', 'education_training', 'Internship Placement', true, 'education_training', 230, 'admissions_placements', 'Admissions & Placements', 30),
  ('health_nursing_placements', 'education_training', 'Health / Nursing Placements', true, 'education_training', 240, 'admissions_placements', 'Admissions & Placements', 40),
  ('event_planning', 'events_production', 'Event Planning', true, 'events_celebrations', 110, 'planning_styling', 'Planning & Styling', 10),
  ('event_decoration', 'events_production', 'Decoration', true, 'events_celebrations', 120, 'planning_styling', 'Planning & Styling', 20),
  ('celebration_cakes', 'events_production', 'Cakes', true, 'events_celebrations', 130, 'planning_styling', 'Planning & Styling', 30),
  ('celebration_catering', 'events_production', 'Catering', true, 'events_celebrations', 140, 'planning_styling', 'Planning & Styling', 40),
  ('tent_hire', 'events_production', 'Tents', true, 'events_celebrations', 210, 'equipment_venue_setup', 'Equipment & Venue Setup', 10),
  ('event_equipment', 'events_production', 'Event Equipment', true, 'events_celebrations', 220, 'equipment_venue_setup', 'Equipment & Venue Setup', 20),
  ('sound_systems', 'events_production', 'Sound Systems', true, 'events_celebrations', 230, 'equipment_venue_setup', 'Equipment & Venue Setup', 30),
  ('lighting_hire', 'events_production', 'Lighting', true, 'events_celebrations', 240, 'equipment_venue_setup', 'Equipment & Venue Setup', 40),
  ('celebration_mc_dj', 'events_production', 'DJs / MCs', true, 'events_celebrations', 310, 'entertainment_hosting', 'Entertainment & Hosting', 10),
  ('event_transport', 'events_production', 'Event Transport', true, 'events_celebrations', 320, 'entertainment_hosting', 'Entertainment & Hosting', 20),
  ('other_events', 'events_production', 'Other Events', true, 'events_celebrations', 410, 'other', 'Other', 10),
  ('photography_services', 'photo_video_music_talent', 'Photography', true, 'photo_video_music_talent', 110, 'photo_video', 'Photo & Video', 10),
  ('videography_services', 'photo_video_music_talent', 'Videography', true, 'photo_video_music_talent', 120, 'photo_video', 'Photo & Video', 20),
  ('video_editors', 'photo_video_music_talent', 'Video Editors', true, 'photo_video_music_talent', 130, 'photo_video', 'Photo & Video', 30),
  ('recording_studios', 'photo_video_music_talent', 'Recording Studios', true, 'photo_video_music_talent', 210, 'music_production', 'Music Production', 10),
  ('music_producers', 'photo_video_music_talent', 'Music Producers', true, 'photo_video_music_talent', 220, 'music_production', 'Music Production', 20),
  ('mixing_mastering', 'photo_video_music_talent', 'Mixing & Mastering', true, 'photo_video_music_talent', 230, 'music_production', 'Music Production', 30),
  ('songwriters', 'photo_video_music_talent', 'Songwriters', true, 'photo_video_music_talent', 240, 'music_production', 'Music Production', 40),
  ('singers_vocalists', 'photo_video_music_talent', 'Singers / Vocalists', true, 'photo_video_music_talent', 250, 'music_production', 'Music Production', 50),
  ('actors_actresses', 'photo_video_music_talent', 'Actors / Actresses', true, 'photo_video_music_talent', 310, 'on_screen_performers', 'On-screen & Performers', 10),
  ('dancers', 'photo_video_music_talent', 'Dancers', true, 'photo_video_music_talent', 320, 'on_screen_performers', 'On-screen & Performers', 20),
  ('background_extras', 'photo_video_music_talent', 'Background Extras', true, 'photo_video_music_talent', 330, 'on_screen_performers', 'On-screen & Performers', 30),
  ('music_video_models', 'photo_video_music_talent', 'Music Video Models', true, 'photo_video_music_talent', 340, 'on_screen_performers', 'On-screen & Performers', 40),
  ('celebration_makeup', 'beauty_fashion_styling', 'Makeup Artists', true, 'beauty_fashion_styling', 110, 'beauty', 'Beauty', 10),
  ('hair_styling', 'beauty_fashion_styling', 'Hair Stylists', true, 'beauty_fashion_styling', 120, 'beauty', 'Beauty', 20),
  ('bridal_styling', 'beauty_fashion_styling', 'Bridal Styling', true, 'beauty_fashion_styling', 210, 'fashion', 'Fashion', 10),
  ('music_video_stylists', 'beauty_fashion_styling', 'Stylists', true, 'beauty_fashion_styling', 220, 'fashion', 'Fashion', 20),
  ('dresses_bridesmaid_outfits', 'beauty_fashion_styling', 'Wedding Dresses / Bridesmaid Outfits', true, 'beauty_fashion_styling', 230, 'fashion', 'Fashion', 30),
  ('building_contractors', 'construction_building', 'Building Contractors', true, 'construction_building', 110, 'contracting', 'Contracting', 10),
  ('roofing_services', 'construction_building', 'Roofing', true, 'construction_building', 120, 'contracting', 'Contracting', 20),
  ('excavation_works', 'construction_building', 'Excavation', true, 'construction_building', 130, 'contracting', 'Contracting', 30),
  ('concrete_works', 'construction_building', 'Concrete', true, 'construction_building', 140, 'contracting', 'Contracting', 40),
  ('plumbing_services', 'construction_building', 'Plumbing', true, 'construction_building', 210, 'trades', 'Trades', 10),
  ('electrical_works', 'construction_building', 'Electrical Works', true, 'construction_building', 220, 'trades', 'Trades', 20),
  ('construction_materials', 'construction_building', 'Construction Materials', true, 'construction_building', 310, 'materials_survey', 'Materials & Survey', 10),
  ('surveying_services', 'construction_building', 'Surveying', true, 'construction_building', 320, 'materials_survey', 'Materials & Survey', 20),
  ('other_construction', 'construction_building', 'Other Construction', true, 'construction_building', 410, 'other', 'Other', 10),
  ('solar_systems', 'energy_utilities', 'Solar Systems', true, 'energy_water', 110, 'power', 'Power', 10),
  ('battery_supply', 'energy_utilities', 'Batteries', true, 'energy_water', 120, 'power', 'Power', 20),
  ('backup_power', 'energy_utilities', 'Backup Power', true, 'energy_water', 130, 'power', 'Power', 30),
  ('generator_supply', 'energy_utilities', 'Generators', true, 'energy_water', 140, 'power', 'Power', 40),
  ('electrical_installation', 'energy_utilities', 'Electrical Installation', true, 'energy_water', 150, 'power', 'Power', 50),
  ('borehole_drilling', 'energy_utilities', 'Boreholes', true, 'energy_water', 210, 'water', 'Water', 10),
  ('water_systems', 'energy_utilities', 'Water Systems', true, 'energy_water', 220, 'water', 'Water', 20),
  ('energy_consulting', 'energy_utilities', 'Energy Consulting', true, 'energy_water', 310, 'advisory', 'Advisory', 10),
  ('other_energy', 'energy_utilities', 'Other Energy Services', true, 'energy_water', 320, 'advisory', 'Advisory', 20),
  ('cargo_transport', 'transport_logistics', 'Cargo Transport', true, 'transport_logistics', 110, 'freight', 'Freight', 10),
  ('bulk_delivery', 'transport_logistics', 'Bulk Delivery', true, 'transport_logistics', 120, 'freight', 'Freight', 20),
  ('heavy_haulage', 'transport_logistics', 'Heavy Haulage', true, 'transport_logistics', 130, 'freight', 'Freight', 30),
  ('agricultural_transport', 'transport_logistics', 'Agricultural Transport', true, 'transport_logistics', 140, 'freight', 'Freight', 40),
  ('cold_chain_transport', 'transport_logistics', 'Cold Chain & Refrigerated', true, 'transport_logistics', 150, 'freight', 'Freight', 50),
  ('courier_delivery', 'transport_logistics', 'Courier', true, 'transport_logistics', 210, 'delivery_moving', 'Delivery & Moving', 10),
  ('moving_services', 'transport_logistics', 'Moving Services', true, 'transport_logistics', 220, 'delivery_moving', 'Delivery & Moving', 20),
  ('truck_hire', 'transport_logistics', 'Truck Hire', true, 'transport_logistics', 310, 'vehicles', 'Vehicles', 10),
  ('vehicle_transport', 'transport_logistics', 'Vehicle Transport', true, 'transport_logistics', 320, 'vehicles', 'Vehicles', 20),
  ('other_logistics', 'transport_logistics', 'Other Logistics', true, 'transport_logistics', 410, 'other', 'Other', 10),
  ('excavator_hire', 'machinery_equipment', 'Excavator Hire', true, 'machinery_equipment', 110, 'earthmoving', 'Earthmoving', 10),
  ('loader_hire', 'machinery_equipment', 'Loader Hire', true, 'machinery_equipment', 120, 'earthmoving', 'Earthmoving', 20),
  ('grader_hire', 'machinery_equipment', 'Grader Hire', true, 'machinery_equipment', 130, 'earthmoving', 'Earthmoving', 30),
  ('crane_hire', 'machinery_equipment', 'Crane Hire', true, 'machinery_equipment', 210, 'lifting_power', 'Lifting & Power', 10),
  ('generator_hire', 'machinery_equipment', 'Generator Hire', true, 'machinery_equipment', 220, 'lifting_power', 'Lifting & Power', 20),
  ('tractor_hire', 'machinery_equipment', 'Tractor Hire', true, 'machinery_equipment', 310, 'farm_industrial', 'Farm & Industrial', 10),
  ('industrial_equipment', 'machinery_equipment', 'Industrial Equipment', true, 'machinery_equipment', 320, 'farm_industrial', 'Farm & Industrial', 20),
  ('other_machinery', 'machinery_equipment', 'Other Machinery', true, 'machinery_equipment', 410, 'other', 'Other', 10),
  ('farm_services', 'agriculture_agribusiness', 'Farm Services', true, 'agriculture_agribusiness', 110, 'farm_operations', 'Farm Operations', 10),
  ('irrigation_services', 'agriculture_agribusiness', 'Irrigation', true, 'agriculture_agribusiness', 120, 'farm_operations', 'Farm Operations', 20),
  ('seeds_inputs', 'agriculture_agribusiness', 'Seeds & Inputs', true, 'agriculture_agribusiness', 210, 'inputs_livestock', 'Inputs & Livestock', 10),
  ('livestock_sourcing', 'agriculture_agribusiness', 'Livestock Sourcing', true, 'agriculture_agribusiness', 220, 'inputs_livestock', 'Inputs & Livestock', 20),
  ('produce_buyers', 'agriculture_agribusiness', 'Produce Buyers', true, 'agriculture_agribusiness', 310, 'market', 'Market', 10),
  ('other_agriculture', 'agriculture_agribusiness', 'Other Agriculture', true, 'agriculture_agribusiness', 320, 'market', 'Market', 20),
  ('bulk_procurement', 'specialized_products', 'Bulk Procurement', true, 'procurement_sourcing', 110, 'sourcing', 'Sourcing', 10),
  ('equipment_sourcing', 'specialized_products', 'Equipment Sourcing', true, 'procurement_sourcing', 120, 'sourcing', 'Sourcing', 20),
  ('imported_products', 'specialized_products', 'Imported Products', true, 'procurement_sourcing', 130, 'sourcing', 'Sourcing', 30),
  ('hard_to_find_products', 'specialized_products', 'Hard-to-Find Products', true, 'procurement_sourcing', 140, 'sourcing', 'Sourcing', 40),
  ('electronics_procurement', 'specialized_products', 'Electronics Procurement', true, 'procurement_sourcing', 210, 'parts_supplies', 'Parts & Supplies', 10),
  ('industrial_parts', 'specialized_products', 'Industrial Parts', true, 'procurement_sourcing', 220, 'parts_supplies', 'Parts & Supplies', 20),
  ('spare_parts', 'specialized_products', 'Spare Parts', true, 'procurement_sourcing', 230, 'parts_supplies', 'Parts & Supplies', 30),
  ('medical_supplies', 'specialized_products', 'Medical & Lab Supplies', true, 'procurement_sourcing', 240, 'parts_supplies', 'Parts & Supplies', 40),
  ('other_procurement', 'specialized_products', 'Other Procurement', true, 'procurement_sourcing', 310, 'other', 'Other', 10),
  ('flight_tickets', 'travel_international', 'Flight Tickets & Bookings', true, 'travel_international', 110, 'bookings', 'Bookings', 10),
  ('accommodation', 'travel_international', 'Accommodation', true, 'travel_international', 120, 'bookings', 'Bookings', 20),
  ('airport_transfers', 'travel_international', 'Airport Transfers', true, 'travel_international', 130, 'bookings', 'Bookings', 30),
  ('tour_packages', 'travel_international', 'Tour Packages', true, 'travel_international', 140, 'bookings', 'Bookings', 40),
  ('visa_assistance', 'travel_international', 'Visa Assistance', true, 'travel_international', 210, 'documents_cover', 'Documents & Cover', 10),
  ('travel_documentation', 'travel_international', 'Travel Documentation', true, 'travel_international', 220, 'documents_cover', 'Documents & Cover', 20),
  ('travel_insurance', 'travel_international', 'Travel Insurance', true, 'travel_international', 230, 'documents_cover', 'Documents & Cover', 30),
  ('hajj_umrah', 'travel_international', 'Hajj & Umrah', true, 'travel_international', 310, 'specialised', 'Specialised', 10),
  ('international_relocation', 'travel_international', 'International Relocation', true, 'travel_international', 320, 'specialised', 'Specialised', 20),
  ('travel_consultation', 'travel_international', 'Travel Consultation', true, 'travel_international', 330, 'specialised', 'Specialised', 30),
  ('other_travel', 'travel_international', 'Other Travel Services', true, 'travel_international', 340, 'specialised', 'Specialised', 40)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = true,
  ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order;

-- Hide legacy extras in these Provider Services categories so the picker shows
-- the unified v2 catalog, while retaining rows and existing provider selections.
update public.need_capabilities
set is_active = false
where category_slug in ('agriculture_agribusiness', 'beauty_fashion_styling', 'construction_building', 'education_training', 'energy_utilities', 'events_production', 'machinery_equipment', 'marketing_promotion', 'photo_video_music_talent', 'professional_services', 'specialized_products', 'technology_digital', 'transport_logistics', 'travel_international')
  and slug not in ('academic_consulting', 'accommodation', 'accounting_tax', 'actors_actresses', 'advertising_campaigns', 'affiliate_marketing', 'agricultural_transport', 'airport_transfers', 'architecture_services', 'automation_services', 'background_extras', 'backup_power', 'battery_supply', 'borehole_drilling', 'brand_promotion', 'bridal_styling', 'building_contractors', 'bulk_delivery', 'bulk_procurement', 'business_consulting', 'cargo_transport', 'celebration_cakes', 'celebration_catering', 'celebration_makeup', 'celebration_mc_dj', 'cold_chain_transport', 'company_registration', 'computer_training', 'concrete_works', 'construction_materials', 'content_creation', 'courier_delivery', 'crane_hire', 'cybersecurity_services', 'dancers', 'digital_marketing', 'dresses_bridesmaid_outfits', 'driving_school', 'electrical_installation', 'electrical_works', 'electronics_procurement', 'energy_consulting', 'engineering_consulting', 'equipment_sourcing', 'event_decoration', 'event_equipment', 'event_planning', 'event_promotion', 'event_transport', 'exam_preparation', 'excavation_works', 'excavator_hire', 'farm_services', 'flight_tickets', 'generator_hire', 'generator_supply', 'grader_hire', 'hair_styling', 'hajj_umrah', 'hard_to_find_products', 'health_nursing_placements', 'heavy_haulage', 'hr_services', 'i_have_an_audience', 'imported_products', 'industrial_equipment', 'industrial_parts', 'influencer_marketing', 'international_relocation', 'internship_placement', 'irrigation_services', 'it_support', 'language_training', 'legal_services', 'lighting_hire', 'livestock_sourcing', 'loader_hire', 'medical_supplies', 'mixing_mastering', 'mobile_app_development', 'moving_services', 'music_producers', 'music_video_models', 'music_video_stylists', 'networking_services', 'online_classes', 'other_agriculture', 'other_construction', 'other_energy', 'other_events', 'other_logistics', 'other_machinery', 'other_marketing_services', 'other_procurement', 'other_professional', 'other_technology', 'other_travel', 'photography_services', 'plumbing_services', 'private_tutoring', 'produce_buyers', 'product_reviews', 'professional_training', 'recording_studios', 'roofing_services', 'seeds_inputs', 'singers_vocalists', 'social_media_marketing', 'software_development', 'solar_systems', 'songwriters', 'sound_systems', 'spare_parts', 'study_abroad_guidance', 'surveying_services', 'tent_hire', 'tour_packages', 'tractor_hire', 'travel_consultation', 'travel_documentation', 'travel_insurance', 'truck_hire', 'university_admissions', 'vehicle_transport', 'video_editors', 'videography_services', 'visa_assistance', 'vocational_training', 'water_systems', 'website_development');

insert into public.capability_roles
  (slug, category_slug, capability_slug, name, kind_question, is_active)
values
  ('developer', 'technology_digital', null, 'Developer', 'What do you build?', true),
  ('it_technician', 'technology_digital', null, 'IT Technician', 'What do you do?', true),
  ('security_specialist', 'technology_digital', null, 'Security Specialist', 'Which area?', true),
  ('project_manager', 'technology_digital', null, 'Project Manager', 'What kind of projects?', true),
  ('team_lead_manager', 'technology_digital', null, 'Team Lead / Manager', 'What do you lead?', true),
  ('marketer_specialist', 'marketing_promotion', null, 'Marketer / Specialist', 'Which channel?', true),
  ('content_creator', 'marketing_promotion', null, 'Content Creator', 'What do you produce?', true),
  ('marketing_manager', 'marketing_promotion', null, 'Marketing Manager', 'What scope?', true),
  ('campaign_project_manager', 'marketing_promotion', null, 'Campaign Project Manager', 'Campaign type?', true),
  ('accountant_finance_officer', 'professional_services', null, 'Accountant / Finance Officer', 'What area?', true),
  ('lawyer_legal_officer', 'professional_services', null, 'Lawyer / Legal Officer', 'What area?', true),
  ('engineer', 'professional_services', null, 'Engineer', 'Which discipline?', true),
  ('architect_designer', 'professional_services', null, 'Architect / Designer', 'What do you design?', true),
  ('hr_officer_manager', 'professional_services', null, 'HR Officer / Manager', 'What area?', true),
  ('consultant', 'professional_services', null, 'Consultant', 'Advisory area?', true),
  ('business_professional_services_project_manager', 'professional_services', null, 'Project Manager', 'What kind of projects?', true),
  ('teacher_tutor', 'education_training', null, 'Teacher / Tutor', 'What do you teach?', true),
  ('trainer_instructor', 'education_training', null, 'Trainer / Instructor', 'Training field?', true),
  ('placement_coordinator', 'education_training', null, 'Placement Coordinator', 'What placements?', true),
  ('programme_manager', 'education_training', null, 'Programme Manager', 'What programmes?', true),
  ('event_manager_planner', 'events_production', null, 'Event Manager / Planner', 'What events?', true),
  ('mc_dj', 'events_production', null, 'MC / DJ', 'Which role?', true),
  ('event_crew_technician', 'events_production', null, 'Event Crew / Technician', 'What do you operate?', true),
  ('caterer_chef', 'events_production', null, 'Caterer / Chef', 'What kind?', true),
  ('event_supervisor', 'events_production', null, 'Event Supervisor', 'What scope?', true),
  ('photographer_videographer', 'photo_video_music_talent', null, 'Photographer / Videographer', 'What do you shoot?', true),
  ('audio_engineer_producer', 'photo_video_music_talent', null, 'Audio Engineer / Producer', 'What do you do?', true),
  ('performer_talent', 'photo_video_music_talent', null, 'Performer / Talent', 'What kind?', true),
  ('production_manager', 'photo_video_music_talent', null, 'Production Manager', 'What productions?', true),
  ('makeup_artist', 'beauty_fashion_styling', null, 'Makeup Artist', 'Specialty?', true),
  ('hair_stylist', 'beauty_fashion_styling', null, 'Hair Stylist', 'Specialty?', true),
  ('stylist_designer', 'beauty_fashion_styling', null, 'Stylist / Designer', 'Specialty?', true),
  ('salon_studio_manager', 'beauty_fashion_styling', null, 'Salon / Studio Manager', 'What scope?', true),
  ('site_manager', 'construction_building', null, 'Site Manager', 'What type of sites?', true),
  ('construction_building_project_manager', 'construction_building', null, 'Project Manager', 'What kind of projects?', true),
  ('foreman_supervisor', 'construction_building', null, 'Foreman / Supervisor', 'Which trade?', true),
  ('skilled_tradesperson', 'construction_building', null, 'Skilled Tradesperson', 'Which trade?', true),
  ('surveyor', 'construction_building', null, 'Surveyor', 'What type?', true),
  ('solar_electrical_technician', 'energy_utilities', null, 'Solar / Electrical Technician', 'What do you install?', true),
  ('borehole_water_technician', 'energy_utilities', null, 'Borehole / Water Technician', 'What do you do?', true),
  ('energy_engineer', 'energy_utilities', null, 'Energy Engineer', 'Which area?', true),
  ('energy_water_project_manager', 'energy_utilities', null, 'Project Manager', 'What kind of projects?', true),
  ('driver', 'transport_logistics', null, 'Driver', 'What do you drive?', true),
  ('fleet_operations_manager', 'transport_logistics', null, 'Fleet / Operations Manager', 'What fleet?', true),
  ('dispatcher_coordinator', 'transport_logistics', null, 'Dispatcher / Coordinator', 'What area?', true),
  ('loader_mover', 'transport_logistics', null, 'Loader / Mover', 'What work?', true),
  ('driving_instructor', 'transport_logistics', null, 'Driving Instructor', 'What do you teach?', true),
  ('machine_operator', 'machinery_equipment', null, 'Machine Operator', 'Which machine do you operate?', true),
  ('equipment_mechanic', 'machinery_equipment', null, 'Equipment Mechanic', 'What do you service?', true),
  ('fleet_equipment_manager', 'machinery_equipment', null, 'Fleet / Equipment Manager', 'What fleet?', true),
  ('site_supervisor', 'machinery_equipment', null, 'Site Supervisor', 'Which sites?', true),
  ('farm_manager', 'agriculture_agribusiness', null, 'Farm Manager', 'What farm?', true),
  ('agronomist_extension_officer', 'agriculture_agribusiness', null, 'Agronomist / Extension Officer', 'What focus?', true),
  ('veterinary_livestock_officer', 'agriculture_agribusiness', null, 'Veterinary / Livestock Officer', 'What animals?', true),
  ('farm_worker_operator', 'agriculture_agribusiness', null, 'Farm Worker / Operator', 'What work?', true),
  ('procurement_officer_manager', 'specialized_products', null, 'Procurement Officer / Manager', 'What do you buy?', true),
  ('sourcing_agent', 'specialized_products', null, 'Sourcing Agent', 'Where do you source?', true),
  ('clearing_customs_agent', 'specialized_products', null, 'Clearing & Customs Agent', 'What do you handle?', true),
  ('travel_agent_consultant', 'travel_international', null, 'Travel Agent / Consultant', 'What do you handle?', true),
  ('tour_guide', 'travel_international', null, 'Tour Guide', 'What tours?', true),
  ('driver_guide', 'travel_international', null, 'Driver-Guide', 'What vehicle?', true),
  ('operations_manager', 'travel_international', null, 'Operations Manager', 'What scope?', true)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = null,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = true;

-- Roles are category-scoped by the existing query path. The repeated
-- Project Manager entries therefore use distinct category-prefixed slugs.
update public.capability_roles
set is_active = false
where category_slug in ('agriculture_agribusiness', 'beauty_fashion_styling', 'construction_building', 'education_training', 'energy_utilities', 'events_production', 'machinery_equipment', 'marketing_promotion', 'photo_video_music_talent', 'professional_services', 'specialized_products', 'technology_digital', 'transport_logistics', 'travel_international')
  and slug not in ('accountant_finance_officer', 'agronomist_extension_officer', 'architect_designer', 'audio_engineer_producer', 'borehole_water_technician', 'business_professional_services_project_manager', 'campaign_project_manager', 'caterer_chef', 'clearing_customs_agent', 'construction_building_project_manager', 'consultant', 'content_creator', 'developer', 'dispatcher_coordinator', 'driver', 'driving_instructor', 'driver_guide', 'energy_engineer', 'energy_water_project_manager', 'engineer', 'equipment_mechanic', 'event_crew_technician', 'event_manager_planner', 'event_supervisor', 'farm_manager', 'farm_worker_operator', 'fleet_equipment_manager', 'fleet_operations_manager', 'foreman_supervisor', 'hair_stylist', 'hr_officer_manager', 'it_technician', 'lawyer_legal_officer', 'loader_mover', 'machine_operator', 'makeup_artist', 'marketer_specialist', 'marketing_manager', 'mc_dj', 'operations_manager', 'performer_talent', 'photographer_videographer', 'placement_coordinator', 'procurement_officer_manager', 'production_manager', 'programme_manager', 'project_manager', 'salon_studio_manager', 'security_specialist', 'site_manager', 'site_supervisor', 'skilled_tradesperson', 'solar_electrical_technician', 'sourcing_agent', 'stylist_designer', 'surveyor', 'teacher_tutor', 'team_lead_manager', 'tour_guide', 'trainer_instructor', 'travel_agent_consultant', 'veterinary_livestock_officer');

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('developer', 'frontend', 'Frontend', 10),
  ('developer', 'backend', 'Backend', 20),
  ('developer', 'full_stack', 'Full-stack', 30),
  ('developer', 'mobile', 'Mobile', 40),
  ('developer', 'qa_tester', 'QA / Tester', 50),
  ('developer', 'devops', 'DevOps', 60),
  ('it_technician', 'helpdesk', 'Helpdesk', 10),
  ('it_technician', 'hardware_repair', 'Hardware repair', 20),
  ('it_technician', 'network_installation', 'Network installation', 30),
  ('it_technician', 'cctv_access_control', 'CCTV & access control', 40),
  ('security_specialist', 'network_security', 'Network security', 10),
  ('security_specialist', 'penetration_testing', 'Penetration testing', 20),
  ('security_specialist', 'security_audits', 'Security audits', 30),
  ('project_manager', 'software', 'Software', 10),
  ('project_manager', 'it_infrastructure', 'IT infrastructure', 20),
  ('project_manager', 'digital_transformation', 'Digital transformation', 30),
  ('team_lead_manager', 'dev_team', 'Dev team', 10),
  ('team_lead_manager', 'it_support_team', 'IT / support team', 20),
  ('team_lead_manager', 'product', 'Product', 30),
  ('marketer_specialist', 'social_media', 'Social media', 10),
  ('marketer_specialist', 'seo_sem', 'SEO / SEM', 20),
  ('marketer_specialist', 'email', 'Email', 30),
  ('marketer_specialist', 'brand', 'Brand', 40),
  ('marketer_specialist', 'community_management', 'Community management', 50),
  ('content_creator', 'video', 'Video', 10),
  ('content_creator', 'photo', 'Photo', 20),
  ('content_creator', 'writing', 'Writing', 30),
  ('content_creator', 'design', 'Design', 40),
  ('content_creator', 'podcast', 'Podcast', 50),
  ('marketing_manager', 'brand', 'Brand', 10),
  ('marketing_manager', 'digital', 'Digital', 20),
  ('marketing_manager', 'events_promotions', 'Events & promotions', 30),
  ('campaign_project_manager', 'digital', 'Digital', 10),
  ('campaign_project_manager', 'field_activation', 'Field / activation', 20),
  ('campaign_project_manager', 'event', 'Event', 30),
  ('accountant_finance_officer', 'bookkeeping', 'Bookkeeping', 10),
  ('accountant_finance_officer', 'tax', 'Tax', 20),
  ('accountant_finance_officer', 'audit', 'Audit', 30),
  ('accountant_finance_officer', 'payroll', 'Payroll', 40),
  ('lawyer_legal_officer', 'corporate', 'Corporate', 10),
  ('lawyer_legal_officer', 'property', 'Property', 20),
  ('lawyer_legal_officer', 'contracts', 'Contracts', 30),
  ('lawyer_legal_officer', 'compliance', 'Compliance', 40),
  ('engineer', 'civil', 'Civil', 10),
  ('engineer', 'electrical', 'Electrical', 20),
  ('engineer', 'mechanical', 'Mechanical', 30),
  ('engineer', 'mining', 'Mining', 40),
  ('architect_designer', 'buildings', 'Buildings', 10),
  ('architect_designer', 'interiors', 'Interiors', 20),
  ('architect_designer', 'landscape', 'Landscape', 30),
  ('hr_officer_manager', 'recruitment', 'Recruitment', 10),
  ('hr_officer_manager', 'payroll_benefits', 'Payroll & benefits', 20),
  ('hr_officer_manager', 'training_compliance', 'Training & compliance', 30),
  ('consultant', 'strategy', 'Strategy', 10),
  ('consultant', 'operations', 'Operations', 20),
  ('consultant', 'finance', 'Finance', 30),
  ('consultant', 'compliance', 'Compliance', 40),
  ('business_professional_services_project_manager', 'business', 'Business', 10),
  ('business_professional_services_project_manager', 'compliance', 'Compliance', 20),
  ('business_professional_services_project_manager', 'operations', 'Operations', 30),
  ('teacher_tutor', 'primary', 'Primary', 10),
  ('teacher_tutor', 'secondary', 'Secondary', 20),
  ('teacher_tutor', 'university', 'University', 30),
  ('teacher_tutor', 'languages', 'Languages', 40),
  ('teacher_tutor', 'exam_prep', 'Exam prep', 50),
  ('trainer_instructor', 'computer_it', 'Computer / IT', 10),
  ('trainer_instructor', 'vocational_technical', 'Vocational / technical', 20),
  ('trainer_instructor', 'professional_corporate', 'Professional / corporate', 30),
  ('trainer_instructor', 'driving', 'Driving', 40),
  ('placement_coordinator', 'internships', 'Internships', 10),
  ('placement_coordinator', 'nursing_health', 'Nursing / health', 20),
  ('placement_coordinator', 'study_abroad', 'Study abroad', 30),
  ('placement_coordinator', 'university', 'University', 40),
  ('programme_manager', 'training_programmes', 'Training programmes', 10),
  ('programme_manager', 'placement_programmes', 'Placement programmes', 20),
  ('event_manager_planner', 'weddings', 'Weddings', 10),
  ('event_manager_planner', 'corporate', 'Corporate', 20),
  ('event_manager_planner', 'birthdays_parties', 'Birthdays & parties', 30),
  ('event_manager_planner', 'graduations', 'Graduations', 40),
  ('event_manager_planner', 'funerals_memorials', 'Funerals & memorials', 50),
  ('mc_dj', 'mc', 'MC', 10),
  ('mc_dj', 'dj', 'DJ', 20),
  ('mc_dj', 'both', 'Both', 30),
  ('event_crew_technician', 'sound', 'Sound', 10),
  ('event_crew_technician', 'lighting', 'Lighting', 20),
  ('event_crew_technician', 'tents_setup', 'Tents & setup', 30),
  ('event_crew_technician', 'stage', 'Stage', 40),
  ('caterer_chef', 'event_catering', 'Event catering', 10),
  ('caterer_chef', 'cakes_baking', 'Cakes & baking', 20),
  ('caterer_chef', 'buffet_plated', 'Buffet / plated', 30),
  ('event_supervisor', 'venue', 'Venue', 10),
  ('event_supervisor', 'logistics', 'Logistics', 20),
  ('event_supervisor', 'guest_management', 'Guest management', 30),
  ('photographer_videographer', 'weddings', 'Weddings', 10),
  ('photographer_videographer', 'corporate', 'Corporate', 20),
  ('photographer_videographer', 'fashion_portraits', 'Fashion & portraits', 30),
  ('photographer_videographer', 'music_videos', 'Music videos', 40),
  ('photographer_videographer', 'real_estate', 'Real estate', 50),
  ('photographer_videographer', 'graduations', 'Graduations', 60),
  ('audio_engineer_producer', 'recording', 'Recording', 10),
  ('audio_engineer_producer', 'mixing_mastering', 'Mixing & mastering', 20),
  ('audio_engineer_producer', 'beat_production', 'Beat production', 30),
  ('audio_engineer_producer', 'live_sound', 'Live sound', 40),
  ('performer_talent', 'singer', 'Singer', 10),
  ('performer_talent', 'dancer', 'Dancer', 20),
  ('performer_talent', 'actor', 'Actor', 30),
  ('performer_talent', 'model', 'Model', 40),
  ('performer_talent', 'extra', 'Extra', 50),
  ('production_manager', 'video_film', 'Video / film', 10),
  ('production_manager', 'music', 'Music', 20),
  ('production_manager', 'live_events', 'Live events', 30),
  ('makeup_artist', 'bridal', 'Bridal', 10),
  ('makeup_artist', 'fashion_editorial', 'Fashion / editorial', 20),
  ('makeup_artist', 'film_stage', 'Film / stage', 30),
  ('makeup_artist', 'everyday', 'Everyday', 40),
  ('hair_stylist', 'braiding', 'Braiding', 10),
  ('hair_stylist', 'salon_styling', 'Salon styling', 20),
  ('hair_stylist', 'bridal_hair', 'Bridal hair', 30),
  ('hair_stylist', 'barbering', 'Barbering', 40),
  ('stylist_designer', 'wardrobe_styling', 'Wardrobe styling', 10),
  ('stylist_designer', 'tailoring', 'Tailoring', 20),
  ('stylist_designer', 'bridal_wear', 'Bridal wear', 30),
  ('salon_studio_manager', 'salon', 'Salon', 10),
  ('salon_studio_manager', 'fashion_studio', 'Fashion studio', 20),
  ('site_manager', 'residential', 'Residential', 10),
  ('site_manager', 'commercial', 'Commercial', 20),
  ('site_manager', 'infrastructure', 'Infrastructure', 30),
  ('construction_building_project_manager', 'residential', 'Residential', 10),
  ('construction_building_project_manager', 'commercial', 'Commercial', 20),
  ('construction_building_project_manager', 'roads_civil', 'Roads & civil', 30),
  ('foreman_supervisor', 'masonry', 'Masonry', 10),
  ('foreman_supervisor', 'roofing', 'Roofing', 20),
  ('foreman_supervisor', 'concrete', 'Concrete', 30),
  ('foreman_supervisor', 'finishing', 'Finishing', 40),
  ('skilled_tradesperson', 'mason', 'Mason', 10),
  ('skilled_tradesperson', 'plumber', 'Plumber', 20),
  ('skilled_tradesperson', 'electrician', 'Electrician', 30),
  ('skilled_tradesperson', 'carpenter', 'Carpenter', 40),
  ('skilled_tradesperson', 'welder', 'Welder', 50),
  ('skilled_tradesperson', 'painter', 'Painter', 60),
  ('skilled_tradesperson', 'roofer', 'Roofer', 70),
  ('surveyor', 'land', 'Land', 10),
  ('surveyor', 'quantity', 'Quantity', 20),
  ('surveyor', 'topographic', 'Topographic', 30),
  ('solar_electrical_technician', 'solar_pv', 'Solar PV', 10),
  ('solar_electrical_technician', 'batteries_inverters', 'Batteries & inverters', 20),
  ('solar_electrical_technician', 'generators', 'Generators', 30),
  ('solar_electrical_technician', 'wiring', 'Wiring', 40),
  ('borehole_water_technician', 'drilling', 'Drilling', 10),
  ('borehole_water_technician', 'pump_installation', 'Pump installation', 20),
  ('borehole_water_technician', 'plumbing_tanks', 'Plumbing & tanks', 30),
  ('borehole_water_technician', 'water_treatment', 'Water treatment', 40),
  ('energy_engineer', 'solar_design', 'Solar design', 10),
  ('energy_engineer', 'energy_audits', 'Energy audits', 20),
  ('energy_engineer', 'grid_mini_grid', 'Grid / mini-grid', 30),
  ('energy_water_project_manager', 'solar', 'Solar', 10),
  ('energy_water_project_manager', 'water', 'Water', 20),
  ('energy_water_project_manager', 'electrification', 'Electrification', 30),
  ('driver', 'truck_heavy', 'Truck / heavy', 10),
  ('driver', 'pickup_van', 'Pickup / van', 20),
  ('driver', 'bus_minibus', 'Bus / minibus', 30),
  ('driver', 'motorcycle_courier', 'Motorcycle courier', 40),
  ('driver', 'tanker', 'Tanker', 50),
  ('fleet_operations_manager', 'trucks', 'Trucks', 10),
  ('fleet_operations_manager', 'vans_couriers', 'Vans & couriers', 20),
  ('fleet_operations_manager', 'mixed', 'Mixed', 30),
  ('dispatcher_coordinator', 'route_planning', 'Route planning', 10),
  ('dispatcher_coordinator', 'customs_clearing', 'Customs & clearing', 20),
  ('dispatcher_coordinator', 'warehouse', 'Warehouse', 30),
  ('loader_mover', 'moving', 'Moving', 10),
  ('loader_mover', 'warehouse', 'Warehouse', 20),
  ('loader_mover', 'loading', 'Loading', 30),
  ('driving_instructor', 'cars', 'Cars', 10),
  ('driving_instructor', 'motorcycles', 'Motorcycles', 20),
  ('driving_instructor', 'trucks', 'Trucks', 30),
  ('driving_instructor', 'defensive_driving', 'Defensive driving', 40),
  ('machine_operator', 'excavator', 'Excavator', 10),
  ('machine_operator', 'loader', 'Loader', 20),
  ('machine_operator', 'grader', 'Grader', 30),
  ('machine_operator', 'crane', 'Crane', 40),
  ('machine_operator', 'tractor', 'Tractor', 50),
  ('machine_operator', 'roller', 'Roller', 60),
  ('machine_operator', 'forklift', 'Forklift', 70),
  ('machine_operator', 'bulldozer', 'Bulldozer', 80),
  ('machine_operator', 'concrete_mixer_pump', 'Concrete mixer / pump', 90),
  ('equipment_mechanic', 'heavy_plant', 'Heavy plant', 10),
  ('equipment_mechanic', 'generators', 'Generators', 20),
  ('equipment_mechanic', 'hydraulics', 'Hydraulics', 30),
  ('equipment_mechanic', 'electrical_systems', 'Electrical systems', 40),
  ('fleet_equipment_manager', 'construction_plant', 'Construction plant', 10),
  ('fleet_equipment_manager', 'farm_machinery', 'Farm machinery', 20),
  ('fleet_equipment_manager', 'industrial_equipment', 'Industrial equipment', 30),
  ('site_supervisor', 'earthworks', 'Earthworks', 10),
  ('site_supervisor', 'quarry_mining', 'Quarry / mining', 20),
  ('site_supervisor', 'farm', 'Farm', 30),
  ('farm_manager', 'crops', 'Crops', 10),
  ('farm_manager', 'dairy', 'Dairy', 20),
  ('farm_manager', 'poultry', 'Poultry', 30),
  ('farm_manager', 'mixed', 'Mixed', 40),
  ('agronomist_extension_officer', 'crops', 'Crops', 10),
  ('agronomist_extension_officer', 'soil_irrigation', 'Soil & irrigation', 20),
  ('agronomist_extension_officer', 'pest_management', 'Pest management', 30),
  ('veterinary_livestock_officer', 'cattle', 'Cattle', 10),
  ('veterinary_livestock_officer', 'poultry', 'Poultry', 20),
  ('veterinary_livestock_officer', 'small_ruminants', 'Small ruminants', 30),
  ('farm_worker_operator', 'tractor_operation', 'Tractor operation', 10),
  ('farm_worker_operator', 'irrigation', 'Irrigation', 20),
  ('farm_worker_operator', 'harvesting', 'Harvesting', 30),
  ('farm_worker_operator', 'spraying', 'Spraying', 40),
  ('procurement_officer_manager', 'industrial', 'Industrial', 10),
  ('procurement_officer_manager', 'electronics', 'Electronics', 20),
  ('procurement_officer_manager', 'medical_lab', 'Medical & lab', 30),
  ('procurement_officer_manager', 'general_supplies', 'General supplies', 40),
  ('sourcing_agent', 'local', 'Local', 10),
  ('sourcing_agent', 'china', 'China', 20),
  ('sourcing_agent', 'dubai', 'Dubai', 30),
  ('sourcing_agent', 'india', 'India', 40),
  ('sourcing_agent', 'europe_usa', 'Europe / USA', 50),
  ('clearing_customs_agent', 'imports', 'Imports', 10),
  ('clearing_customs_agent', 'exports', 'Exports', 20),
  ('clearing_customs_agent', 'freight_forwarding', 'Freight forwarding', 30),
  ('travel_agent_consultant', 'flights', 'Flights', 10),
  ('travel_agent_consultant', 'tours_packages', 'Tours & packages', 20),
  ('travel_agent_consultant', 'visas', 'Visas', 30),
  ('travel_agent_consultant', 'hajj_umrah', 'Hajj & Umrah', 40),
  ('travel_agent_consultant', 'relocation', 'Relocation', 50),
  ('tour_guide', 'wildlife_safari', 'Wildlife safari', 10),
  ('tour_guide', 'cultural', 'Cultural', 20),
  ('tour_guide', 'city_tours', 'City tours', 30),
  ('tour_guide', 'adventure', 'Adventure', 40),
  ('driver_guide', 'safari_vehicle', 'Safari vehicle', 10),
  ('driver_guide', 'minibus', 'Minibus', 20),
  ('driver_guide', 'airport_transfers', 'Airport transfers', 30),
  ('operations_manager', 'tours', 'Tours', 10),
  ('operations_manager', 'visa_documentation', 'Visa & documentation', 20),
  ('operations_manager', 'travel_desk', 'Travel desk', 30)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

insert into public.role_qualifications
  (role_slug, slug, name, is_evidence, sort_order)
values
  ('developer', 'degree_diploma_in_it_or_cs', 'Degree / Diploma in IT or CS', false, 10),
  ('developer', 'portfolio_or_github_link', 'Portfolio or GitHub link', false, 20),
  ('developer', 'cloud_certification_aws_azure_gcp', 'Cloud certification (AWS/Azure/GCP)', true, 30),
  ('developer', '3_years_experience', '3+ years experience', false, 40),
  ('it_technician', 'comptia_a_n', 'CompTIA A+ / N+', false, 10),
  ('it_technician', 'ccna', 'CCNA', false, 20),
  ('it_technician', 'own_toolkit', 'Own toolkit', false, 30),
  ('it_technician', '2_years_experience', '2+ years experience', false, 40),
  ('security_specialist', 'ceh', 'CEH', false, 10),
  ('security_specialist', 'cissp_cism', 'CISSP / CISM', false, 20),
  ('security_specialist', 'iso_27001', 'ISO 27001', false, 30),
  ('security_specialist', 'police_clearance', 'Police clearance', false, 40),
  ('project_manager', 'pmp_prince2', 'PMP / PRINCE2', false, 10),
  ('project_manager', 'agile_scrum_certified', 'Agile / Scrum certified', true, 20),
  ('project_manager', 'led_3_projects', 'Led 3+ projects', false, 30),
  ('project_manager', 'degree', 'Degree', false, 40),
  ('team_lead_manager', 'managed_5_people', 'Managed 5+ people', false, 10),
  ('team_lead_manager', 'degree', 'Degree', false, 20),
  ('team_lead_manager', '3_years_leadership', '3+ years leadership', false, 30),
  ('marketer_specialist', 'marketing_diploma_degree', 'Marketing diploma / degree', false, 10),
  ('marketer_specialist', 'google_ads_meta_certified', 'Google Ads / Meta certified', true, 20),
  ('marketer_specialist', 'case_studies_or_portfolio', 'Case studies or portfolio', false, 30),
  ('marketer_specialist', '2_years_experience', '2+ years experience', false, 40),
  ('content_creator', 'portfolio', 'Portfolio', false, 10),
  ('content_creator', 'own_equipment', 'Own equipment', false, 20),
  ('content_creator', 'audience_size_proof', 'Audience size proof', false, 30),
  ('marketing_manager', 'degree', 'Degree', false, 10),
  ('marketing_manager', 'managed_budgets', 'Managed budgets', false, 20),
  ('marketing_manager', 'managed_3_people', 'Managed 3+ people', false, 30),
  ('campaign_project_manager', 'pmp_prince2', 'PMP / PRINCE2', false, 10),
  ('campaign_project_manager', 'led_3_campaigns', 'Led 3+ campaigns', false, 20),
  ('accountant_finance_officer', 'cpa_acca_cpa_u', 'CPA / ACCA / CPA-U', false, 10),
  ('accountant_finance_officer', 'degree', 'Degree', false, 20),
  ('accountant_finance_officer', 'practising_certificate', 'Practising certificate', true, 30),
  ('accountant_finance_officer', '3_years_experience', '3+ years experience', false, 40),
  ('lawyer_legal_officer', 'bar_admission_practising_certificate', 'Bar admission / practising certificate', true, 10),
  ('lawyer_legal_officer', 'llb', 'LLB', false, 20),
  ('lawyer_legal_officer', '3_years_experience', '3+ years experience', false, 30),
  ('engineer', 'degree_in_engineering', 'Degree in engineering', false, 10),
  ('engineer', 'registered_with_engineers_board', 'Registered with engineers board', true, 20),
  ('engineer', 'site_experience', 'Site experience', false, 30),
  ('architect_designer', 'registered_architect', 'Registered architect', true, 10),
  ('architect_designer', 'portfolio', 'Portfolio', false, 20),
  ('architect_designer', 'cad_bim_skills', 'CAD/BIM skills', false, 30),
  ('hr_officer_manager', 'hr_diploma_degree', 'HR diploma / degree', false, 10),
  ('hr_officer_manager', 'ihrm_cipd', 'IHRM / CIPD', false, 20),
  ('hr_officer_manager', '3_years_experience', '3+ years experience', false, 30),
  ('consultant', 'degree', 'Degree', false, 10),
  ('consultant', 'case_studies', 'Case studies', false, 20),
  ('consultant', '5_years_experience', '5+ years experience', false, 30),
  ('business_professional_services_project_manager', 'pmp_prince2', 'PMP / PRINCE2', false, 10),
  ('business_professional_services_project_manager', 'led_3_projects', 'Led 3+ projects', false, 20),
  ('teacher_tutor', 'teaching_certificate_degree', 'Teaching certificate / degree', true, 10),
  ('teacher_tutor', 'registered_with_teaching_board', 'Registered with teaching board', true, 20),
  ('teacher_tutor', '2_years_teaching', '2+ years teaching', false, 30),
  ('teacher_tutor', 'subject_specialisation', 'Subject specialisation', false, 40),
  ('trainer_instructor', 'trade_certificate', 'Trade certificate', true, 10),
  ('trainer_instructor', 'trainer_of_trainers_tot', 'Trainer-of-trainers (ToT)', false, 20),
  ('trainer_instructor', 'industry_experience_3_years', 'Industry experience 3+ years', false, 30),
  ('placement_coordinator', 'education_or_hr_background', 'Education or HR background', false, 10),
  ('placement_coordinator', 'partner_network', 'Partner network', false, 20),
  ('placement_coordinator', 'counselling_certificate', 'Counselling certificate', true, 30),
  ('programme_manager', 'degree', 'Degree', false, 10),
  ('programme_manager', 'managed_3_programmes', 'Managed 3+ programmes', false, 20),
  ('event_manager_planner', 'event_planning_certificate', 'Event planning certificate', true, 10),
  ('event_manager_planner', 'portfolio_of_5_events', 'Portfolio of 5+ events', false, 20),
  ('event_manager_planner', 'insurance_permit', 'Insurance / permit', false, 30),
  ('event_manager_planner', 'team_of_3_staff', 'Team of 3+ staff', false, 40),
  ('mc_dj', 'own_equipment', 'Own equipment', false, 10),
  ('mc_dj', 'sample_mix_video', 'Sample mix / video', false, 20),
  ('mc_dj', 'references', 'References', false, 30),
  ('event_crew_technician', 'technical_training', 'Technical training', false, 10),
  ('event_crew_technician', 'own_tools', 'Own tools', false, 20),
  ('event_crew_technician', 'event_experience_1_year', 'Event experience 1+ year', false, 30),
  ('caterer_chef', 'food_handler_certificate', 'Food handler certificate', true, 10),
  ('caterer_chef', 'health_permit', 'Health permit', false, 20),
  ('caterer_chef', 'culinary_diploma', 'Culinary diploma', false, 30),
  ('event_supervisor', 'managed_5_events', 'Managed 5+ events', false, 10),
  ('event_supervisor', 'team_leadership', 'Team leadership', false, 20),
  ('photographer_videographer', 'portfolio_link', 'Portfolio link', false, 10),
  ('photographer_videographer', 'own_camera_drone_kit', 'Own camera / drone kit', false, 20),
  ('photographer_videographer', 'drone_licence', 'Drone licence', true, 30),
  ('photographer_videographer', 'editing_skills', 'Editing skills', false, 40),
  ('audio_engineer_producer', 'own_studio_daw', 'Own studio / DAW', false, 10),
  ('audio_engineer_producer', 'portfolio', 'Portfolio', false, 20),
  ('audio_engineer_producer', 'audio_engineering_diploma', 'Audio engineering diploma', false, 30),
  ('performer_talent', 'showreel_audition_clip', 'Showreel / audition clip', false, 10),
  ('performer_talent', 'agency_representation', 'Agency representation', false, 20),
  ('performer_talent', 'performance_experience', 'Performance experience', false, 30),
  ('production_manager', 'managed_3_productions', 'Managed 3+ productions', false, 10),
  ('production_manager', 'budget_handling', 'Budget handling', false, 20),
  ('production_manager', 'crew_network', 'Crew network', false, 30),
  ('makeup_artist', 'cosmetology_certificate', 'Cosmetology certificate', true, 10),
  ('makeup_artist', 'portfolio', 'Portfolio', false, 20),
  ('makeup_artist', 'own_kit', 'Own kit', false, 30),
  ('makeup_artist', 'hygiene_certification', 'Hygiene certification', true, 40),
  ('hair_stylist', 'cosmetology_certificate', 'Cosmetology certificate', true, 10),
  ('hair_stylist', 'portfolio', 'Portfolio', false, 20),
  ('hair_stylist', 'salon_licence', 'Salon licence', true, 30),
  ('stylist_designer', 'fashion_diploma', 'Fashion diploma', false, 10),
  ('stylist_designer', 'portfolio', 'Portfolio', false, 20),
  ('stylist_designer', 'own_workshop', 'Own workshop', false, 30),
  ('salon_studio_manager', 'managed_3_staff', 'Managed 3+ staff', false, 10),
  ('salon_studio_manager', 'business_licence', 'Business licence', true, 20),
  ('site_manager', 'civil_construction_diploma_or_degree', 'Civil/Construction diploma or degree', false, 10),
  ('site_manager', 'registered_with_engineers_contractors_board', 'Registered with engineers/contractors board', true, 20),
  ('site_manager', '5_years_on_site', '5+ years on site', false, 30),
  ('site_manager', 'safety_certification_osha', 'Safety certification (OSHA)', true, 40),
  ('construction_building_project_manager', 'pmp_prince2', 'PMP / PRINCE2', false, 10),
  ('construction_building_project_manager', 'degree', 'Degree', false, 20),
  ('construction_building_project_manager', 'delivered_3_projects', 'Delivered 3+ projects', false, 30),
  ('foreman_supervisor', 'trade_test_certificate', 'Trade test certificate', true, 10),
  ('foreman_supervisor', 'managed_10_workers', 'Managed 10+ workers', false, 20),
  ('foreman_supervisor', 'safety_training', 'Safety training', false, 30),
  ('skilled_tradesperson', 'trade_test_grade_i_ii_iii', 'Trade test (Grade I/II/III)', false, 10),
  ('skilled_tradesperson', 'licence_electrical_plumbing', 'Licence (electrical/plumbing)', true, 20),
  ('skilled_tradesperson', 'own_tools', 'Own tools', false, 30),
  ('skilled_tradesperson', '2_years_experience', '2+ years experience', false, 40),
  ('surveyor', 'registered_surveyor', 'Registered surveyor', true, 10),
  ('surveyor', 'degree_diploma', 'Degree / diploma', false, 20),
  ('surveyor', 'own_instruments', 'Own instruments', false, 30),
  ('solar_electrical_technician', 'electrical_licence', 'Electrical licence', true, 10),
  ('solar_electrical_technician', 'solar_installer_certificate', 'Solar installer certificate', true, 20),
  ('solar_electrical_technician', 'safety_training', 'Safety training', false, 30),
  ('solar_electrical_technician', 'own_tools', 'Own tools', false, 40),
  ('borehole_water_technician', 'water_technician_certificate', 'Water technician certificate', true, 10),
  ('borehole_water_technician', 'drilling_permit', 'Drilling permit', false, 20),
  ('borehole_water_technician', 'own_equipment', 'Own equipment', false, 30),
  ('energy_engineer', 'engineering_degree', 'Engineering degree', false, 10),
  ('energy_engineer', 'registered_engineer', 'Registered engineer', true, 20),
  ('energy_engineer', 'design_software_skills', 'Design software skills', false, 30),
  ('energy_water_project_manager', 'pmp_prince2', 'PMP / PRINCE2', false, 10),
  ('energy_water_project_manager', 'delivered_3_projects', 'Delivered 3+ projects', false, 20),
  ('driver', 'valid_driving_licence_class', 'Valid driving licence (class)', true, 10),
  ('driver', 'psv_badge', 'PSV badge', false, 20),
  ('driver', 'clean_driving_record', 'Clean driving record', false, 30),
  ('driver', 'defensive_driving_certificate', 'Defensive driving certificate', true, 40),
  ('driver', 'own_vehicle', 'Own vehicle', false, 50),
  ('fleet_operations_manager', 'logistics_diploma_degree', 'Logistics diploma / degree', false, 10),
  ('fleet_operations_manager', 'managed_10_vehicles', 'Managed 10+ vehicles', false, 20),
  ('fleet_operations_manager', 'transport_licence', 'Transport licence', true, 30),
  ('dispatcher_coordinator', 'logistics_experience', 'Logistics experience', false, 10),
  ('dispatcher_coordinator', 'customs_clearing_licence', 'Customs clearing licence', true, 20),
  ('loader_mover', 'physical_fitness', 'Physical fitness', false, 10),
  ('loader_mover', 'experience_1_year', 'Experience 1+ year', false, 20),
  ('driving_instructor', 'instructor_licence', 'Instructor licence', true, 10),
  ('driving_instructor', 'valid_driving_licence', 'Valid driving licence', true, 20),
  ('driving_instructor', 'teaching_experience', '2+ years teaching', false, 30),
  ('machine_operator', 'operator_licence_certificate', 'Operator licence / certificate', true, 10),
  ('machine_operator', 'safety_osha_certificate', 'Safety / OSHA certificate', true, 20),
  ('machine_operator', '3_years_experience', '3+ years experience', false, 30),
  ('machine_operator', 'medical_fitness', 'Medical fitness', false, 40),
  ('machine_operator', 'can_work_away_from_home', 'Can work away from home', false, 50),
  ('equipment_mechanic', 'mechanic_trade_certificate', 'Mechanic trade certificate', true, 10),
  ('equipment_mechanic', 'own_tools', 'Own tools', false, 20),
  ('equipment_mechanic', 'field_repair_experience', 'Field repair experience', false, 30),
  ('fleet_equipment_manager', 'managed_fleet_of_5_machines', 'Managed fleet of 5+ machines', false, 10),
  ('fleet_equipment_manager', 'diploma_degree', 'Diploma / degree', false, 20),
  ('fleet_equipment_manager', 'maintenance_scheduling', 'Maintenance scheduling', false, 30),
  ('site_supervisor', 'plant_experience', 'Plant experience', false, 10),
  ('site_supervisor', 'team_leadership', 'Team leadership', false, 20),
  ('site_supervisor', 'safety_certification', 'Safety certification', true, 30),
  ('farm_manager', 'agriculture_diploma_degree', 'Agriculture diploma / degree', false, 10),
  ('farm_manager', 'managed_5_workers', 'Managed 5+ workers', false, 20),
  ('farm_manager', '5_years_farming_experience', '5+ years farming experience', false, 30),
  ('agronomist_extension_officer', 'degree_diploma_in_agronomy', 'Degree / diploma in agronomy', false, 10),
  ('agronomist_extension_officer', 'field_experience', 'Field experience', false, 20),
  ('veterinary_livestock_officer', 'veterinary_licence', 'Veterinary licence', true, 10),
  ('veterinary_livestock_officer', 'diploma_degree', 'Diploma / degree', false, 20),
  ('veterinary_livestock_officer', 'vaccination_certification', 'Vaccination certification', true, 30),
  ('farm_worker_operator', 'tractor_licence', 'Tractor licence', true, 10),
  ('farm_worker_operator', 'pesticide_handling_certificate', 'Pesticide handling certificate', true, 20),
  ('farm_worker_operator', 'experience_1_year', 'Experience 1+ year', false, 30),
  ('procurement_officer_manager', 'procurement_diploma_cips_or_similar', 'Procurement diploma (CIPS or similar)', false, 10),
  ('procurement_officer_manager', 'supplier_network', 'Supplier network', false, 20),
  ('procurement_officer_manager', '3_years_experience', '3+ years experience', false, 30),
  ('sourcing_agent', 'import_export_experience', 'Import/export experience', false, 10),
  ('sourcing_agent', 'language_skills', 'Language skills', false, 20),
  ('sourcing_agent', 'supplier_contacts', 'Supplier contacts', false, 30),
  ('clearing_customs_agent', 'customs_clearing_licence', 'Customs clearing licence', true, 10),
  ('clearing_customs_agent', 'logistics_experience', 'Logistics experience', false, 20),
  ('travel_agent_consultant', 'iata_certification', 'IATA certification', true, 10),
  ('travel_agent_consultant', 'travel_agency_licence', 'Travel agency licence', true, 20),
  ('travel_agent_consultant', '2_years_experience', '2+ years experience', false, 30),
  ('tour_guide', 'tourism_board_guide_licence', 'Tourism board guide licence', true, 10),
  ('tour_guide', 'first_aid_certificate', 'First aid certificate', true, 20),
  ('tour_guide', 'languages_spoken', 'Languages spoken', false, 30),
  ('driver_guide', 'valid_driving_licence_class', 'Valid driving licence (class)', true, 10),
  ('driver_guide', 'tourism_licence', 'Tourism licence', true, 20),
  ('driver_guide', 'clean_driving_record', 'Clean driving record', false, 30),
  ('operations_manager', 'tourism_diploma_degree', 'Tourism diploma / degree', false, 10),
  ('operations_manager', 'managed_3_staff', 'Managed 3+ staff', false, 20)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  is_evidence = excluded.is_evidence,
  sort_order = excluded.sort_order;

-- Provider-entered qualifications remain claims until Nipanze reviews evidence.
create table if not exists public.provider_role_qualification_claims (
  id uuid primary key default gen_random_uuid(),
  provider_capability_id uuid not null
    references public.provider_capabilities(id) on delete cascade,
  role_slug text not null,
  qualification_slug text not null,
  is_claimed boolean not null default true,
  status text not null default 'self_declared'
    check (status in ('self_declared', 'pending_review', 'verified', 'rejected', 'expired')),
  evidence_object_path text,
  reject_reason text,
  expires_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint provider_role_qualification_claims_unique
    unique (provider_capability_id, role_slug, qualification_slug),
  constraint provider_role_qualification_claims_qualification_fk
    foreign key (role_slug, qualification_slug)
    references public.role_qualifications(role_slug, slug)
    on delete restrict,
  constraint provider_role_qualification_claims_review_state_check
    check (
      (status in ('self_declared', 'pending_review') and reviewed_by is null and reviewed_at is null)
      or (status in ('verified', 'rejected', 'expired') and reviewed_by is not null and reviewed_at is not null)
    )
);

create index if not exists idx_provider_role_qualification_claims_owner
  on public.provider_role_qualification_claims(provider_capability_id, is_claimed);
create index if not exists idx_provider_role_qualification_claims_review
  on public.provider_role_qualification_claims(status, updated_at);

alter table public.provider_role_qualification_claims enable row level security;
drop policy if exists "provider role qualification claims owner select"
  on public.provider_role_qualification_claims;
create policy "provider role qualification claims owner select"
  on public.provider_role_qualification_claims
  for select to authenticated
  using (
    exists (
      select 1 from public.provider_capabilities pc
      where pc.id = provider_role_qualification_claims.provider_capability_id
        and (pc.user_id = auth.uid() or private.is_admin())
    )
  );
revoke all on public.provider_role_qualification_claims from anon, public, authenticated;
grant select on public.provider_role_qualification_claims to authenticated;

-- Keep qualification selections in metadata as the existing app contract,
-- while mirroring them into a reviewable per-qualification claim table.
create or replace function private.sync_provider_role_qualification_claims()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_category_slug text;
  v_roles jsonb;
  v_role jsonb;
  v_role_slug text;
  v_qualifications jsonb;
  v_qualification_slug text;
begin
  select nc.category_slug
  into v_category_slug
  from public.need_capabilities nc
  where nc.slug = new.capability_slug;

  -- Work profiles are stored one role per provider_capabilities row by the
  -- app (role_id + qualification_ids at the metadata root). Keep accepting
  -- the older/multi-role `roles` array shape as well so existing clients and
  -- rows can still be synchronized into individual claims.
  v_roles := case
    when jsonb_typeof(coalesce(new.metadata, '{}'::jsonb)->'roles') = 'array'
      then coalesce(new.metadata, '{}'::jsonb)->'roles'
    when jsonb_typeof(coalesce(new.metadata, '{}'::jsonb)->'role_id') = 'string'
      then jsonb_build_array(coalesce(new.metadata, '{}'::jsonb))
    else '[]'::jsonb
  end;

  update public.provider_role_qualification_claims
  set is_claimed = false,
      updated_at = now()
  where provider_capability_id = new.id
    and is_claimed;

  for v_role in select value from jsonb_array_elements(v_roles)
  loop
    v_role_slug := nullif(btrim(v_role->>'role_id'), '');
    if v_role_slug is null or not exists (
      select 1
      from public.capability_roles cr
      where cr.slug = v_role_slug
        and cr.is_active
        and (
          cr.capability_slug = new.capability_slug
          or (cr.capability_slug is null and cr.category_slug = v_category_slug)
        )
    ) then
      continue;
    end if;

    v_qualifications := case
      when jsonb_typeof(v_role->'qualification_ids') = 'array'
        then v_role->'qualification_ids'
      else '[]'::jsonb
    end;

    for v_qualification_slug in
      select jsonb_array_elements_text(v_qualifications)
    loop
      if exists (
        select 1
        from public.role_qualifications rq
        where rq.role_slug = v_role_slug
          and rq.slug = v_qualification_slug
      ) then
        insert into public.provider_role_qualification_claims
          (provider_capability_id, role_slug, qualification_slug, is_claimed)
        values
          (new.id, v_role_slug, v_qualification_slug, true)
        on conflict (provider_capability_id, role_slug, qualification_slug)
        do update set
          is_claimed = true,
          updated_at = now();
      end if;
    end loop;
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_sync_provider_role_qualification_claims
  on public.provider_capabilities;
create trigger trg_sync_provider_role_qualification_claims
  after insert or update of metadata, capability_slug
  on public.provider_capabilities
  for each row
  execute function private.sync_provider_role_qualification_claims();

-- Backfill existing self-declared role selections; invalid legacy option IDs
-- are left untouched in metadata and are not promoted into verified claims.
update public.provider_capabilities
set metadata = metadata
where metadata ? 'roles';

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
begin
  if v_user_id is null then
    raise exception 'Not authenticated.' using errcode = '42501';
  end if;

  select pc.capability_slug, claim.id
  into v_capability_slug, v_claim_id
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

create or replace function public.admin_review_provider_role_qualification(
  p_claim_id uuid,
  p_action text,
  p_reject_reason text default null,
  p_expires_at timestamptz default null
)
returns boolean
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_admin uuid := auth.uid();
  v_claim record;
begin
  if not private.is_admin() then
    raise exception 'Unauthorized: Admin access required.' using errcode = '42501';
  end if;
  if p_action not in ('approve', 'reject', 'expire') then
    raise exception 'Action must be approve, reject, or expire.' using errcode = '22023';
  end if;

  select claim.*, pc.capability_slug, pc.user_id
  into v_claim
  from public.provider_role_qualification_claims claim
  join public.provider_capabilities pc on pc.id = claim.provider_capability_id
  where claim.id = p_claim_id
  for update of claim;

  if not found then
    raise exception 'Provider role qualification claim not found.' using errcode = 'P0212';
  end if;
  if p_action = 'approve' and v_claim.status <> 'pending_review' then
    raise exception 'Only submitted qualification evidence can be approved.' using errcode = '22023';
  end if;
  if p_action = 'approve' and p_expires_at is not null and p_expires_at <= now() then
    raise exception 'Evidence expiry must be in the future.' using errcode = '22023';
  end if;

  update public.provider_role_qualification_claims
  set status = case
        when p_action = 'approve' then 'verified'
        when p_action = 'reject' then 'rejected'
        else 'expired'
      end,
      reject_reason = case when p_action = 'reject' then coalesce(p_reject_reason, '') else null end,
      expires_at = case when p_action = 'approve' then p_expires_at else expires_at end,
      reviewed_by = v_admin,
      reviewed_at = now(),
      updated_at = now()
  where id = p_claim_id;

  -- A reviewer approving evidence for this role completes the badge for its
  -- parent capability. A rejection/expiry only clears that badge when no
  -- other current approved evidence remains on the same capability.
  if p_action = 'approve' then
    update public.provider_capabilities
    set verification_level = 'provider_verified',
        verified_by = v_admin,
        verified_at = now()
    where id = v_claim.provider_capability_id;
  elsif not exists (
    select 1
    from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = v_claim.provider_capability_id
      and claim.is_claimed
      and claim.status = 'verified'
      and (claim.expires_at is null or claim.expires_at > now())
  ) and not exists (
    select 1
    from public.provider_capability_evidence evidence
    where evidence.provider_capability_id = v_claim.provider_capability_id
      and evidence.status = 'approved'
      and (evidence.expires_at is null or evidence.expires_at > now())
  ) then
    update public.provider_capabilities
    set verification_level = 'self_declared',
        verified_by = null,
        verified_at = null
    where id = v_claim.provider_capability_id;
  end if;

  insert into public.audit_logs
    (user_id, event_type, entity_type, entity_id, action, new_values)
  values
    (v_admin, 'admin_action', 'provider_role_qualification_claim', p_claim_id,
     'review_provider_role_qualification',
     jsonb_build_object(
       'action', p_action,
       'provider_capability_id', v_claim.provider_capability_id,
       'capability_slug', v_claim.capability_slug,
       'role_slug', v_claim.role_slug,
       'qualification_slug', v_claim.qualification_slug,
       'reject_reason', p_reject_reason,
       'expires_at', p_expires_at
     ));

  return true;
end;
$$;

revoke all on function public.admin_review_provider_role_qualification(uuid, text, text, timestamptz)
  from public, anon;
grant execute on function public.admin_review_provider_role_qualification(uuid, text, text, timestamptz)
  to authenticated;

-- Owner/admin status view: evidence paths stay private; status is safe to render in-app.
create or replace view public.v_my_capability_status
with (security_invoker = true)
as
with latest_rejection as (
  select distinct on (e.provider_capability_id)
    e.provider_capability_id, e.reject_reason, e.reviewed_at
  from public.provider_capability_evidence e
  where e.status = 'rejected'
  order by e.provider_capability_id, e.reviewed_at desc nulls last, e.created_at desc
),
evidence_summary as (
  select
    e.provider_capability_id,
    count(*) filter (where e.status = 'pending') as pending_count,
    count(*) filter (where e.status = 'approved') as approved_count,
    count(*) filter (where e.status = 'rejected') as rejected_count,
    count(*) filter (where e.status = 'expired') as expired_count
  from public.provider_capability_evidence e
  group by e.provider_capability_id
),
qualification_summary as (
  select
    claim.provider_capability_id,
    jsonb_agg(
      jsonb_build_object(
        'role_slug', claim.role_slug,
        'qualification_slug', claim.qualification_slug,
        'qualification_name', rq.name,
        'status', case
          when claim.status = 'verified'
               and claim.expires_at is not null
               and claim.expires_at <= now() then 'expired'
          else claim.status
        end,
        'has_evidence', claim.evidence_object_path is not null,
        'reject_reason', claim.reject_reason,
        'verified_at', claim.reviewed_at
      )
      order by claim.role_slug, claim.qualification_slug
    ) as claims
  from public.provider_role_qualification_claims claim
  join public.role_qualifications rq
    on rq.role_slug = claim.role_slug
   and rq.slug = claim.qualification_slug
  where claim.is_claimed
  group by claim.provider_capability_id
)
select
  pc.id as provider_capability_id,
  pc.user_id,
  pc.capability_slug,
  nc.name as capability_name,
  nc.category_slug,
  cat.name as category_name,
  cat.icon as category_icon,
  pc.verification_level,
  pc.metadata,
  case
    when pc.verification_level = 'provider_verified' then 'provider_verified'
    when coalesce(es.pending_count, 0) > 0 then 'pending_review'
    when coalesce(es.rejected_count, 0) > 0 then 'rejected'
    when coalesce(es.expired_count, 0) > 0 then 'expired'
    else 'self_declared'
  end as capability_status,
  coalesce(es.pending_count, 0)::int as pending_evidence_count,
  coalesce(es.approved_count, 0)::int as approved_evidence_count,
  coalesce(es.rejected_count, 0)::int as rejected_evidence_count,
  coalesce(es.expired_count, 0)::int as expired_evidence_count,
  lr.reject_reason as latest_reject_reason,
  pc.verified_by,
  pc.verified_at,
  pc.created_at,
  -- Keep this column in position 19: later verification/document patches
  -- already append capability_type before the qualification summary.
  nc.capability_type,
  coalesce(qs.claims, '[]'::jsonb) as role_qualification_claims
from public.provider_capabilities pc
join public.need_capabilities nc on nc.slug = pc.capability_slug
join public.need_categories cat on cat.slug = nc.category_slug
left join evidence_summary es on es.provider_capability_id = pc.id
left join latest_rejection lr on lr.provider_capability_id = pc.id
left join qualification_summary qs on qs.provider_capability_id = pc.id
where pc.user_id = auth.uid() or private.is_admin();

grant select on public.v_my_capability_status to authenticated;

-- The role/kind/qualification step is feature-flagged in the app.
-- Enable it so the pictured Provider Services flow is available after this patch.
insert into public.system_settings
  (setting_key, country, setting_value, setting_type, category, description, is_public)
values
  ('capability_profiles_enabled', null, 'true', 'boolean', 'provider',
   'Enables Provider Services v2 roles, kinds, qualifications, evidence, and hire-person matching.',
   true)
on conflict (setting_key, coalesce(country, '__global__')) do update set
  setting_value = excluded.setting_value,
  setting_type = excluded.setting_type,
  category = excluded.category,
  description = excluded.description,
  is_public = excluded.is_public,
  updated_at = now();

-- Keep the public catalog readable through Supabase/PostgREST.
grant select on public.need_categories, public.need_capabilities to anon, authenticated;
grant select on public.capability_roles, public.role_kinds, public.role_qualifications to anon, authenticated;

commit;

-- Refresh PostgREST's cached table/view columns after the catalog DDL.
notify pgrst, 'reload schema';

-- ============================================================================
-- END MERGED SECTION (1/52): patch_provider_services_v2_catalog.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (2/52): patch_provider_services_work_profiles.sql
-- ============================================================================

-- =============================================================================
-- Standalone SQL Patch: patch_provider_services_work_profiles.sql
-- Stage 4.14: Provider capability profiles and Work Profiles
-- 
-- Safe to re-run (idempotent).
-- Non-destructive: preserves existing capabilities, evidence, and audit logs.
-- Conforms strictly to .agents/AGENTS.md.
-- =============================================================================

begin;

-- 1. Table schema adjustments for need_capabilities
alter table public.need_capabilities
  add column if not exists capability_type text not null default 'service'
    check (capability_type in ('service', 'work')),
  add column if not exists ui_group_slug text,
  add column if not exists sort_order integer not null default 1000,
  add column if not exists service_group_slug text,
  add column if not exists service_group_name text,
  add column if not exists service_sort_order integer not null default 1000;

comment on column public.need_capabilities.capability_type is
  'Distinguishes offered services (service) from work-seeking profiles (work).';

alter table public.verification_requirements
  add column if not exists required_evidence text[] not null default array[]::text[],
  add column if not exists expires_after_days integer;

alter table public.provider_capabilities
  add column if not exists updated_at timestamptz not null default now();

-- 2. Evidence table
create table if not exists public.provider_capability_evidence (
  id uuid primary key default gen_random_uuid(),
  provider_capability_id uuid not null
    references public.provider_capabilities(id) on delete cascade,
  requirement_key text not null,
  file_url text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'expired')),
  reject_reason text,
  expires_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_provider_capability_evidence_capability
  on public.provider_capability_evidence(provider_capability_id, requirement_key, created_at desc);

create index if not exists idx_provider_capability_evidence_status
  on public.provider_capability_evidence(status, expires_at);

alter table public.provider_capability_evidence enable row level security;

drop policy if exists "provider evidence owner select" on public.provider_capability_evidence;
create policy "provider evidence owner select"
  on public.provider_capability_evidence
  for select to authenticated
  using (
    exists (
      select 1 from public.provider_capabilities pc
      where pc.id = provider_capability_evidence.provider_capability_id
        and (pc.user_id = auth.uid() or private.is_admin())
    )
  );

drop policy if exists "provider evidence owner insert" on public.provider_capability_evidence;
create policy "provider evidence owner insert"
  on public.provider_capability_evidence
  for insert to authenticated
  with check (
    exists (
      select 1 from public.provider_capabilities pc
      where pc.id = provider_capability_evidence.provider_capability_id
        and pc.user_id = auth.uid()
    )
  );

drop policy if exists "provider evidence owner resubmit" on public.provider_capability_evidence;
create policy "provider evidence owner resubmit"
  on public.provider_capability_evidence
  for update to authenticated
  using (
    status in ('pending', 'rejected', 'expired')
    and exists (
      select 1 from public.provider_capabilities pc
      where pc.id = provider_capability_evidence.provider_capability_id
        and pc.user_id = auth.uid()
    )
  )
  with check (
    status = 'pending'
    and reviewed_by is null
    and reviewed_at is null
    and exists (
      select 1 from public.provider_capabilities pc
      where pc.id = provider_capability_evidence.provider_capability_id
        and pc.user_id = auth.uid()
    )
  );

drop policy if exists "provider evidence admin all" on public.provider_capability_evidence;
create policy "provider evidence admin all"
  on public.provider_capability_evidence
  for all to authenticated
  using (private.is_admin());

grant select, insert, update on public.provider_capability_evidence to authenticated;

-- 3. Seed 14 categories
insert into public.need_categories (slug, name, icon, sort_order, description, is_active)
values
  ('machinery_equipment', 'Machinery & Equipment', '🚜', 1, 'Heavy machinery and equipment hire, with or without an operator', true),
  ('transport_logistics', 'Transport & Logistics', '🚚', 2, 'Moving, hauling, delivery and cold chain', true),
  ('specialized_products', 'Procurement & Sourcing', '🔎', 3, 'Buying, importing and finding hard-to-get products', true),
  ('construction_building', 'Construction & Building', '🏗️', 4, 'Contractors, trades and surveying', true),
  ('professional_services', 'Business & Professional Services', '💼', 5, 'Consulting, legal, accounting, HR and design', true),
  ('travel_international', 'Travel & International', '✈️', 6, 'Bookings, visas, tours and relocation', true),
  ('agriculture_agribusiness', 'Agriculture & Agribusiness', '🌾', 7, 'Farm services, inputs and produce', true),
  ('energy_utilities', 'Energy & Water', '⚡', 8, 'Solar, power backup, boreholes and water systems', true),
  ('technology_digital', 'Technology & Digital', '💻', 9, 'Software, websites, IT support and security', true),
  ('marketing_promotion', 'Marketing & Promotion', '📣', 10, 'Advertising, content and influencer work', true),
  ('education_training', 'Education & Training', '🎓', 11, 'Learning, admissions and placements', true),
  ('events_production', 'Events & Celebrations', '🎉', 12, 'Weddings, parties, corporate events and the services behind them', true),
  ('photo_video_music_talent', 'Photo, Video, Music & Talent', '🎬', 13, 'Creative production and performers for any occasion', true),
  ('beauty_fashion_styling', 'Beauty, Fashion & Styling', '💄', 14, 'Makeup, hair, styling and clothing', true)
on conflict (slug) do update set
  name = excluded.name,
  icon = excluded.icon,
  sort_order = excluded.sort_order,
  description = excluded.description,
  is_active = true;

-- 4. Canonical Services (need_capabilities with capability_type = service)
insert into public.need_capabilities (slug, category_slug, name, is_active, ui_group_slug, sort_order, service_group_slug, service_group_name, service_sort_order, capability_type)
values
  ('software_development', 'technology_digital', 'Software Development', true, 'technology_digital', 110, 'build', 'Build', 10, 'service'),
  ('website_development', 'technology_digital', 'Website Development', true, 'technology_digital', 120, 'build', 'Build', 20, 'service'),
  ('mobile_app_development', 'technology_digital', 'Mobile App Development', true, 'technology_digital', 130, 'build', 'Build', 30, 'service'),
  ('automation_services', 'technology_digital', 'Automation', true, 'technology_digital', 140, 'build', 'Build', 40, 'service'),
  ('it_support', 'technology_digital', 'IT Support', true, 'technology_digital', 210, 'support_infrastructure', 'Support & Infrastructure', 10, 'service'),
  ('networking_services', 'technology_digital', 'Networking', true, 'technology_digital', 220, 'support_infrastructure', 'Support & Infrastructure', 20, 'service'),
  ('cybersecurity_services', 'technology_digital', 'Cybersecurity', true, 'technology_digital', 230, 'support_infrastructure', 'Support & Infrastructure', 30, 'service'),
  ('other_technology', 'technology_digital', 'Other Technology', true, 'technology_digital', 310, 'other', 'Other', 10, 'service'),
  ('digital_marketing', 'marketing_promotion', 'Digital Marketing', true, 'marketing_promotion', 110, 'campaigns', 'Campaigns', 10, 'service'),
  ('social_media_marketing', 'marketing_promotion', 'Social Media Marketing', true, 'marketing_promotion', 120, 'campaigns', 'Campaigns', 20, 'service'),
  ('advertising_campaigns', 'marketing_promotion', 'Advertising Campaigns', true, 'marketing_promotion', 130, 'campaigns', 'Campaigns', 30, 'service'),
  ('brand_promotion', 'marketing_promotion', 'Brand Promotion', true, 'marketing_promotion', 140, 'campaigns', 'Campaigns', 40, 'service'),
  ('event_promotion', 'marketing_promotion', 'Event Promotion', true, 'marketing_promotion', 150, 'campaigns', 'Campaigns', 50, 'service'),
  ('affiliate_marketing', 'marketing_promotion', 'Affiliate Marketing', true, 'marketing_promotion', 160, 'campaigns', 'Campaigns', 60, 'service'),
  ('content_creation', 'marketing_promotion', 'Content Creation', true, 'marketing_promotion', 210, 'content_reach', 'Content & Reach', 10, 'service'),
  ('influencer_marketing', 'marketing_promotion', 'Influencer Marketing', true, 'marketing_promotion', 220, 'content_reach', 'Content & Reach', 20, 'service'),
  ('product_reviews', 'marketing_promotion', 'Product Reviews', true, 'marketing_promotion', 230, 'content_reach', 'Content & Reach', 30, 'service'),
  ('i_have_an_audience', 'marketing_promotion', 'I Have an Audience', true, 'marketing_promotion', 240, 'content_reach', 'Content & Reach', 40, 'service'),
  ('other_marketing_services', 'marketing_promotion', 'Other Marketing Services', true, 'marketing_promotion', 310, 'other', 'Other', 10, 'service'),
  ('accounting_tax', 'professional_services', 'Accounting & Tax', true, 'business_professional_services', 110, 'finance_legal', 'Finance & Legal', 10, 'service'),
  ('legal_services', 'professional_services', 'Legal Services', true, 'business_professional_services', 120, 'finance_legal', 'Finance & Legal', 20, 'service'),
  ('company_registration', 'professional_services', 'Company Registration', true, 'business_professional_services', 130, 'finance_legal', 'Finance & Legal', 30, 'service'),
  ('business_consulting', 'professional_services', 'Business Consulting', true, 'business_professional_services', 210, 'advisory', 'Advisory', 10, 'service'),
  ('hr_services', 'professional_services', 'HR Services', true, 'business_professional_services', 220, 'advisory', 'Advisory', 20, 'service'),
  ('architecture_services', 'professional_services', 'Architecture', true, 'business_professional_services', 310, 'design_engineering', 'Design & Engineering', 10, 'service'),
  ('engineering_consulting', 'professional_services', 'Engineering', true, 'business_professional_services', 320, 'design_engineering', 'Design & Engineering', 20, 'service'),
  ('driving_school_driver_training', 'professional_services', 'Driving School / Driver Training', true, 'business_professional_services', 330, 'design_engineering', 'Design & Engineering', 30, 'service'),
  ('other_professional', 'professional_services', 'Other Professional Services', true, 'business_professional_services', 410, 'other', 'Other', 10, 'service'),
  ('private_tutoring', 'education_training', 'Private Tutoring', true, 'education_training', 110, 'learning', 'Learning', 10, 'service'),
  ('online_classes', 'education_training', 'Online Classes', true, 'education_training', 120, 'learning', 'Learning', 20, 'service'),
  ('exam_preparation', 'education_training', 'Exam Preparation', true, 'education_training', 130, 'learning', 'Learning', 30, 'service'),
  ('language_training', 'education_training', 'Language Training', true, 'education_training', 140, 'learning', 'Learning', 40, 'service'),
  ('computer_training', 'education_training', 'Computer Training', true, 'education_training', 150, 'learning', 'Learning', 50, 'service'),
  ('professional_training', 'education_training', 'Professional Training', true, 'education_training', 160, 'learning', 'Learning', 60, 'service'),
  ('vocational_training', 'education_training', 'Vocational Training', true, 'education_training', 170, 'learning', 'Learning', 70, 'service'),
  ('academic_consulting', 'education_training', 'Academic Consulting', true, 'education_training', 180, 'learning', 'Learning', 80, 'service'),
  ('university_admissions', 'education_training', 'University Admissions', true, 'education_training', 210, 'admissions_placements', 'Admissions & Placements', 10, 'service'),
  ('study_abroad_guidance', 'education_training', 'Study Abroad Guidance', true, 'education_training', 220, 'admissions_placements', 'Admissions & Placements', 20, 'service'),
  ('internship_placement', 'education_training', 'Internship Placement', true, 'education_training', 230, 'admissions_placements', 'Admissions & Placements', 30, 'service'),
  ('health_nursing_placements', 'education_training', 'Health / Nursing Placements', true, 'education_training', 240, 'admissions_placements', 'Admissions & Placements', 40, 'service'),
  ('event_planning', 'events_production', 'Event Planning', true, 'events_celebrations', 110, 'planning_styling', 'Planning & Styling', 10, 'service'),
  ('event_decoration', 'events_production', 'Decoration', true, 'events_celebrations', 120, 'planning_styling', 'Planning & Styling', 20, 'service'),
  ('celebration_cakes', 'events_production', 'Cakes', true, 'events_celebrations', 130, 'planning_styling', 'Planning & Styling', 30, 'service'),
  ('celebration_catering', 'events_production', 'Catering', true, 'events_celebrations', 140, 'planning_styling', 'Planning & Styling', 40, 'service'),
  ('tent_hire', 'events_production', 'Tents', true, 'events_celebrations', 210, 'equipment_venue_setup', 'Equipment & Venue Setup', 10, 'service'),
  ('event_equipment', 'events_production', 'Event Equipment', true, 'events_celebrations', 220, 'equipment_venue_setup', 'Equipment & Venue Setup', 20, 'service'),
  ('sound_systems', 'events_production', 'Sound Systems', true, 'events_celebrations', 230, 'equipment_venue_setup', 'Equipment & Venue Setup', 30, 'service'),
  ('lighting_hire', 'events_production', 'Lighting', true, 'events_celebrations', 240, 'equipment_venue_setup', 'Equipment & Venue Setup', 40, 'service'),
  ('celebration_mc_dj', 'events_production', 'DJs / MCs', true, 'events_celebrations', 310, 'entertainment_hosting', 'Entertainment & Hosting', 10, 'service'),
  ('event_transport', 'events_production', 'Event Transport', true, 'events_celebrations', 320, 'entertainment_hosting', 'Entertainment & Hosting', 20, 'service'),
  ('other_events', 'events_production', 'Other Events', true, 'events_celebrations', 410, 'other', 'Other', 10, 'service'),
  ('photography_services', 'photo_video_music_talent', 'Photography', true, 'photo_video_music_talent', 110, 'photo_video', 'Photo & Video', 10, 'service'),
  ('videography_services', 'photo_video_music_talent', 'Videography', true, 'photo_video_music_talent', 120, 'photo_video', 'Photo & Video', 20, 'service'),
  ('video_editors', 'photo_video_music_talent', 'Video Editors', true, 'photo_video_music_talent', 130, 'photo_video', 'Photo & Video', 30, 'service'),
  ('recording_studios', 'photo_video_music_talent', 'Recording Studios', true, 'photo_video_music_talent', 210, 'music_production', 'Music Production', 10, 'service'),
  ('music_producers', 'photo_video_music_talent', 'Music Producers', true, 'photo_video_music_talent', 220, 'music_production', 'Music Production', 20, 'service'),
  ('mixing_mastering', 'photo_video_music_talent', 'Mixing & Mastering', true, 'photo_video_music_talent', 230, 'music_production', 'Music Production', 30, 'service'),
  ('songwriters', 'photo_video_music_talent', 'Songwriters', true, 'photo_video_music_talent', 240, 'music_production', 'Music Production', 40, 'service'),
  ('singers_vocalists', 'photo_video_music_talent', 'Singers / Vocalists', true, 'photo_video_music_talent', 250, 'music_production', 'Music Production', 50, 'service'),
  ('actors_actresses', 'photo_video_music_talent', 'Actors / Actresses', true, 'photo_video_music_talent', 310, 'on_screen_performers', 'On-screen & Performers', 10, 'service'),
  ('dancers', 'photo_video_music_talent', 'Dancers', true, 'photo_video_music_talent', 320, 'on_screen_performers', 'On-screen & Performers', 20, 'service'),
  ('background_extras', 'photo_video_music_talent', 'Background Extras', true, 'photo_video_music_talent', 330, 'on_screen_performers', 'On-screen & Performers', 30, 'service'),
  ('music_video_models', 'photo_video_music_talent', 'Music Video Models', true, 'photo_video_music_talent', 340, 'on_screen_performers', 'On-screen & Performers', 40, 'service'),
  ('celebration_makeup', 'beauty_fashion_styling', 'Makeup Artists', true, 'beauty_fashion_styling', 110, 'beauty', 'Beauty', 10, 'service'),
  ('hair_styling', 'beauty_fashion_styling', 'Hair Stylists', true, 'beauty_fashion_styling', 120, 'beauty', 'Beauty', 20, 'service'),
  ('bridal_styling', 'beauty_fashion_styling', 'Bridal Styling', true, 'beauty_fashion_styling', 210, 'fashion', 'Fashion', 10, 'service'),
  ('music_video_stylists', 'beauty_fashion_styling', 'Stylists', true, 'beauty_fashion_styling', 220, 'fashion', 'Fashion', 20, 'service'),
  ('dresses_bridesmaid_outfits', 'beauty_fashion_styling', 'Wedding Dresses / Bridesmaid Outfits', true, 'beauty_fashion_styling', 230, 'fashion', 'Fashion', 30, 'service'),
  ('building_contractors', 'construction_building', 'Building Contractors', true, 'construction_building', 110, 'contracting', 'Contracting', 10, 'service'),
  ('roofing_services', 'construction_building', 'Roofing', true, 'construction_building', 120, 'contracting', 'Contracting', 20, 'service'),
  ('excavation_works', 'construction_building', 'Excavation', true, 'construction_building', 130, 'contracting', 'Contracting', 30, 'service'),
  ('concrete_works', 'construction_building', 'Concrete', true, 'construction_building', 140, 'contracting', 'Contracting', 40, 'service'),
  ('plumbing_services', 'construction_building', 'Plumbing', true, 'construction_building', 210, 'trades', 'Trades', 10, 'service'),
  ('electrical_works', 'construction_building', 'Electrical Works', true, 'construction_building', 220, 'trades', 'Trades', 20, 'service'),
  ('construction_materials', 'construction_building', 'Construction Materials', true, 'construction_building', 310, 'materials_survey', 'Materials & Survey', 10, 'service'),
  ('surveying_services', 'construction_building', 'Surveying', true, 'construction_building', 320, 'materials_survey', 'Materials & Survey', 20, 'service'),
  ('other_construction', 'construction_building', 'Other Construction', true, 'construction_building', 410, 'other', 'Other', 10, 'service'),
  ('solar_systems', 'energy_utilities', 'Solar Systems', true, 'energy_water', 110, 'power', 'Power', 10, 'service'),
  ('battery_supply', 'energy_utilities', 'Batteries', true, 'energy_water', 120, 'power', 'Power', 20, 'service'),
  ('backup_power', 'energy_utilities', 'Backup Power', true, 'energy_water', 130, 'power', 'Power', 30, 'service'),
  ('generator_supply', 'energy_utilities', 'Generators', true, 'energy_water', 140, 'power', 'Power', 40, 'service'),
  ('electrical_installation', 'energy_utilities', 'Electrical Installation', true, 'energy_water', 150, 'power', 'Power', 50, 'service'),
  ('borehole_drilling', 'energy_utilities', 'Boreholes', true, 'energy_water', 210, 'water', 'Water', 10, 'service'),
  ('water_systems', 'energy_utilities', 'Water Systems', true, 'energy_water', 220, 'water', 'Water', 20, 'service'),
  ('energy_consulting', 'energy_utilities', 'Energy Consulting', true, 'energy_water', 310, 'advisory', 'Advisory', 10, 'service'),
  ('other_energy_services', 'energy_utilities', 'Other Energy Services', true, 'energy_water', 320, 'advisory', 'Advisory', 20, 'service'),
  ('cargo_transport', 'transport_logistics', 'Cargo Transport', true, 'transport_logistics', 110, 'freight', 'Freight', 10, 'service'),
  ('bulk_delivery', 'transport_logistics', 'Bulk Delivery', true, 'transport_logistics', 120, 'freight', 'Freight', 20, 'service'),
  ('heavy_haulage', 'transport_logistics', 'Heavy Haulage', true, 'transport_logistics', 130, 'freight', 'Freight', 30, 'service'),
  ('agricultural_transport', 'transport_logistics', 'Agricultural Transport', true, 'transport_logistics', 140, 'freight', 'Freight', 40, 'service'),
  ('cold_chain_transport', 'transport_logistics', 'Cold Chain & Refrigerated', true, 'transport_logistics', 150, 'freight', 'Freight', 50, 'service'),
  ('courier_delivery', 'transport_logistics', 'Courier', true, 'transport_logistics', 210, 'delivery_moving', 'Delivery & Moving', 10, 'service'),
  ('moving_services', 'transport_logistics', 'Moving Services', true, 'transport_logistics', 220, 'delivery_moving', 'Delivery & Moving', 20, 'service'),
  ('truck_hire', 'transport_logistics', 'Truck Hire', true, 'transport_logistics', 310, 'vehicles', 'Vehicles', 10, 'service'),
  ('vehicle_transport', 'transport_logistics', 'Vehicle Transport', true, 'transport_logistics', 320, 'vehicles', 'Vehicles', 20, 'service'),
  ('other_logistics', 'transport_logistics', 'Other Logistics', true, 'transport_logistics', 410, 'other', 'Other', 10, 'service'),
  ('excavator_hire', 'machinery_equipment', 'Excavator Hire', true, 'machinery_equipment', 110, 'earthmoving', 'Earthmoving', 10, 'service'),
  ('loader_hire', 'machinery_equipment', 'Loader Hire', true, 'machinery_equipment', 120, 'earthmoving', 'Earthmoving', 20, 'service'),
  ('grader_hire', 'machinery_equipment', 'Grader Hire', true, 'machinery_equipment', 130, 'earthmoving', 'Earthmoving', 30, 'service'),
  ('crane_hire', 'machinery_equipment', 'Crane Hire', true, 'machinery_equipment', 210, 'lifting_power', 'Lifting & Power', 10, 'service'),
  ('generator_hire', 'machinery_equipment', 'Generator Hire', true, 'machinery_equipment', 220, 'lifting_power', 'Lifting & Power', 20, 'service'),
  ('tractor_hire', 'machinery_equipment', 'Tractor Hire', true, 'machinery_equipment', 310, 'farm_industrial', 'Farm & Industrial', 10, 'service'),
  ('industrial_equipment', 'machinery_equipment', 'Industrial Equipment', true, 'machinery_equipment', 320, 'farm_industrial', 'Farm & Industrial', 20, 'service'),
  ('other_machinery', 'machinery_equipment', 'Other Machinery', true, 'machinery_equipment', 410, 'other', 'Other', 10, 'service'),
  ('farm_services', 'agriculture_agribusiness', 'Farm Services', true, 'agriculture_agribusiness', 110, 'farm_operations', 'Farm Operations', 10, 'service'),
  ('irrigation_services', 'agriculture_agribusiness', 'Irrigation', true, 'agriculture_agribusiness', 120, 'farm_operations', 'Farm Operations', 20, 'service'),
  ('seeds_inputs', 'agriculture_agribusiness', 'Seeds & Inputs', true, 'agriculture_agribusiness', 210, 'inputs_livestock', 'Inputs & Livestock', 10, 'service'),
  ('livestock_sourcing', 'agriculture_agribusiness', 'Livestock Sourcing', true, 'agriculture_agribusiness', 220, 'inputs_livestock', 'Inputs & Livestock', 20, 'service'),
  ('produce_buyers', 'agriculture_agribusiness', 'Produce Buyers', true, 'agriculture_agribusiness', 310, 'market', 'Market', 10, 'service'),
  ('other_agriculture', 'agriculture_agribusiness', 'Other Agriculture', true, 'agriculture_agribusiness', 320, 'market', 'Market', 20, 'service'),
  ('bulk_procurement', 'specialized_products', 'Bulk Procurement', true, 'procurement_sourcing', 110, 'sourcing', 'Sourcing', 10, 'service'),
  ('equipment_sourcing', 'specialized_products', 'Equipment Sourcing', true, 'procurement_sourcing', 120, 'sourcing', 'Sourcing', 20, 'service'),
  ('imported_products', 'specialized_products', 'Imported Products', true, 'procurement_sourcing', 130, 'sourcing', 'Sourcing', 30, 'service'),
  ('hard_to_find_products', 'specialized_products', 'Hard-to-Find Products', true, 'procurement_sourcing', 140, 'sourcing', 'Sourcing', 40, 'service'),
  ('electronics_procurement', 'specialized_products', 'Electronics Procurement', true, 'procurement_sourcing', 210, 'parts_supplies', 'Parts & Supplies', 10, 'service'),
  ('industrial_parts', 'specialized_products', 'Industrial Parts', true, 'procurement_sourcing', 220, 'parts_supplies', 'Parts & Supplies', 20, 'service'),
  ('spare_parts', 'specialized_products', 'Spare Parts', true, 'procurement_sourcing', 230, 'parts_supplies', 'Parts & Supplies', 30, 'service'),
  ('medical_lab_supplies', 'specialized_products', 'Medical & Lab Supplies', true, 'procurement_sourcing', 240, 'parts_supplies', 'Parts & Supplies', 40, 'service'),
  ('other_procurement', 'specialized_products', 'Other Procurement', true, 'procurement_sourcing', 310, 'other', 'Other', 10, 'service'),
  ('flight_tickets', 'travel_international', 'Flight Tickets & Bookings', true, 'travel_international', 110, 'bookings', 'Bookings', 10, 'service'),
  ('accommodation', 'travel_international', 'Accommodation', true, 'travel_international', 120, 'bookings', 'Bookings', 20, 'service'),
  ('airport_transfers', 'travel_international', 'Airport Transfers', true, 'travel_international', 130, 'bookings', 'Bookings', 30, 'service'),
  ('tour_packages', 'travel_international', 'Tour Packages', true, 'travel_international', 140, 'bookings', 'Bookings', 40, 'service'),
  ('visa_assistance', 'travel_international', 'Visa Assistance', true, 'travel_international', 210, 'documents_cover', 'Documents & Cover', 10, 'service'),
  ('travel_documentation', 'travel_international', 'Travel Documentation', true, 'travel_international', 220, 'documents_cover', 'Documents & Cover', 20, 'service'),
  ('travel_insurance', 'travel_international', 'Travel Insurance', true, 'travel_international', 230, 'documents_cover', 'Documents & Cover', 30, 'service'),
  ('hajj_umrah', 'travel_international', 'Hajj & Umrah', true, 'travel_international', 310, 'specialised', 'Specialised', 10, 'service'),
  ('international_relocation', 'travel_international', 'International Relocation', true, 'travel_international', 320, 'specialised', 'Specialised', 20, 'service'),
  ('travel_consultation', 'travel_international', 'Travel Consultation', true, 'travel_international', 330, 'specialised', 'Specialised', 30, 'service'),
  ('other_travel_services', 'travel_international', 'Other Travel Services', true, 'travel_international', 340, 'specialised', 'Specialised', 40, 'service')
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

-- 5. Work Roles (need_capabilities with capability_type = work, and capability_roles)
insert into public.need_capabilities (slug, category_slug, name, is_active, ui_group_slug, sort_order, service_group_slug, service_group_name, service_sort_order, capability_type)
values
  ('work_developer', 'technology_digital', 'Developer', true, 'technology_digital', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_it_technician', 'technology_digital', 'IT Technician', true, 'technology_digital', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_security_specialist', 'technology_digital', 'Security Specialist', true, 'technology_digital', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_project_manager', 'technology_digital', 'Project Manager', true, 'technology_digital', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_team_lead_manager', 'technology_digital', 'Team Lead / Manager', true, 'technology_digital', 50, 'work_roles', 'Work Roles', 50, 'work'),
  ('work_marketer_specialist', 'marketing_promotion', 'Marketer / Specialist', true, 'marketing_promotion', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_content_creator', 'marketing_promotion', 'Content Creator', true, 'marketing_promotion', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_marketing_manager', 'marketing_promotion', 'Marketing Manager', true, 'marketing_promotion', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_campaign_project_manager', 'marketing_promotion', 'Campaign Project Manager', true, 'marketing_promotion', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_accountant_finance_officer', 'professional_services', 'Accountant / Finance Officer', true, 'business_professional_services', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_lawyer_legal_officer', 'professional_services', 'Lawyer / Legal Officer', true, 'business_professional_services', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_engineer', 'professional_services', 'Engineer', true, 'business_professional_services', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_architect_designer', 'professional_services', 'Architect / Designer', true, 'business_professional_services', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_hr_officer_manager', 'professional_services', 'HR Officer / Manager', true, 'business_professional_services', 50, 'work_roles', 'Work Roles', 50, 'work'),
  ('work_business_administrator_office_manager', 'professional_services', 'Business Administrator / Office Manager', true, 'business_professional_services', 60, 'work_roles', 'Work Roles', 60, 'work'),
  ('work_consultant', 'professional_services', 'Consultant', true, 'business_professional_services', 70, 'work_roles', 'Work Roles', 70, 'work'),
  ('work_professional_services_project_manager', 'professional_services', 'Project Manager', true, 'business_professional_services', 80, 'work_roles', 'Work Roles', 80, 'work'),
  ('work_teacher_tutor', 'education_training', 'Teacher / Tutor', true, 'education_training', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_trainer_instructor', 'education_training', 'Trainer / Instructor', true, 'education_training', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_placement_coordinator', 'education_training', 'Placement Coordinator', true, 'education_training', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_programme_manager', 'education_training', 'Programme Manager', true, 'education_training', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_event_manager_planner', 'events_production', 'Event Manager / Planner', true, 'events_celebrations', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_mc_dj', 'events_production', 'MC / DJ', true, 'events_celebrations', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_event_crew_technician', 'events_production', 'Event Crew / Technician', true, 'events_celebrations', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_caterer_chef', 'events_production', 'Caterer / Chef', true, 'events_celebrations', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_event_supervisor', 'events_production', 'Event Supervisor', true, 'events_celebrations', 50, 'work_roles', 'Work Roles', 50, 'work'),
  ('work_photographer_videographer', 'photo_video_music_talent', 'Photographer / Videographer', true, 'photo_video_music_talent', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_audio_engineer_producer', 'photo_video_music_talent', 'Audio Engineer / Producer', true, 'photo_video_music_talent', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_performer_talent', 'photo_video_music_talent', 'Performer / Talent', true, 'photo_video_music_talent', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_production_manager', 'photo_video_music_talent', 'Production Manager', true, 'photo_video_music_talent', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_makeup_artist', 'beauty_fashion_styling', 'Makeup Artist', true, 'beauty_fashion_styling', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_hair_stylist', 'beauty_fashion_styling', 'Hair Stylist', true, 'beauty_fashion_styling', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_stylist_designer', 'beauty_fashion_styling', 'Stylist / Designer', true, 'beauty_fashion_styling', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_salon_studio_manager', 'beauty_fashion_styling', 'Salon / Studio Manager', true, 'beauty_fashion_styling', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_site_manager', 'construction_building', 'Site Manager', true, 'construction_building', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_construction_building_project_manager', 'construction_building', 'Project Manager', true, 'construction_building', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_foreman_supervisor', 'construction_building', 'Foreman / Supervisor', true, 'construction_building', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_skilled_tradesperson', 'construction_building', 'Skilled Tradesperson', true, 'construction_building', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_surveyor', 'construction_building', 'Surveyor', true, 'construction_building', 50, 'work_roles', 'Work Roles', 50, 'work'),
  ('work_solar_electrical_technician', 'energy_utilities', 'Solar / Electrical Technician', true, 'energy_water', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_borehole_water_technician', 'energy_utilities', 'Borehole / Water Technician', true, 'energy_water', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_energy_engineer', 'energy_utilities', 'Energy Engineer', true, 'energy_water', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_energy_utilities_project_manager', 'energy_utilities', 'Project Manager', true, 'energy_water', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_driver', 'transport_logistics', 'Driver', true, 'transport_logistics', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_fleet_operations_manager', 'transport_logistics', 'Fleet / Operations Manager', true, 'transport_logistics', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_dispatcher_coordinator', 'transport_logistics', 'Dispatcher / Coordinator', true, 'transport_logistics', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_loader_mover', 'transport_logistics', 'Loader / Mover', true, 'transport_logistics', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_driving_instructor', 'transport_logistics', 'Driving Instructor', true, 'transport_logistics', 50, 'work_roles', 'Work Roles', 50, 'work'),
  ('work_machine_operator', 'machinery_equipment', 'Machine Operator', true, 'machinery_equipment', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_equipment_mechanic', 'machinery_equipment', 'Equipment Mechanic', true, 'machinery_equipment', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_fleet_equipment_manager', 'machinery_equipment', 'Fleet / Equipment Manager', true, 'machinery_equipment', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_site_supervisor', 'machinery_equipment', 'Site Supervisor', true, 'machinery_equipment', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_farm_manager', 'agriculture_agribusiness', 'Farm Manager', true, 'agriculture_agribusiness', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_agronomist_extension_officer', 'agriculture_agribusiness', 'Agronomist / Extension Officer', true, 'agriculture_agribusiness', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_veterinary_livestock_officer', 'agriculture_agribusiness', 'Veterinary / Livestock Officer', true, 'agriculture_agribusiness', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_farm_worker_operator', 'agriculture_agribusiness', 'Farm Worker / Operator', true, 'agriculture_agribusiness', 40, 'work_roles', 'Work Roles', 40, 'work'),
  ('work_procurement_officer_manager', 'specialized_products', 'Procurement Officer / Manager', true, 'procurement_sourcing', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_sourcing_agent', 'specialized_products', 'Sourcing Agent', true, 'procurement_sourcing', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_clearing_customs_agent', 'specialized_products', 'Clearing & Customs Agent', true, 'procurement_sourcing', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_travel_agent_consultant', 'travel_international', 'Travel Agent / Consultant', true, 'travel_international', 10, 'work_roles', 'Work Roles', 10, 'work'),
  ('work_tour_guide', 'travel_international', 'Tour Guide', true, 'travel_international', 20, 'work_roles', 'Work Roles', 20, 'work'),
  ('work_driver_guide', 'travel_international', 'Driver-Guide', true, 'travel_international', 30, 'work_roles', 'Work Roles', 30, 'work'),
  ('work_operations_manager', 'travel_international', 'Operations Manager', true, 'travel_international', 40, 'work_roles', 'Work Roles', 40, 'work')
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

insert into public.capability_roles (slug, category_slug, capability_slug, name, kind_question, is_active)
values
  ('developer', 'technology_digital', 'work_developer', 'Developer', 'What do you build?', true),
  ('it_technician', 'technology_digital', 'work_it_technician', 'IT Technician', 'What do you do?', true),
  ('security_specialist', 'technology_digital', 'work_security_specialist', 'Security Specialist', 'Which area?', true),
  ('project_manager', 'technology_digital', 'work_project_manager', 'Project Manager', 'What kind of projects?', true),
  ('team_lead_manager', 'technology_digital', 'work_team_lead_manager', 'Team Lead / Manager', 'What do you lead?', true),
  ('marketer_specialist', 'marketing_promotion', 'work_marketer_specialist', 'Marketer / Specialist', 'Which channel?', true),
  ('content_creator', 'marketing_promotion', 'work_content_creator', 'Content Creator', 'What do you produce?', true),
  ('marketing_manager', 'marketing_promotion', 'work_marketing_manager', 'Marketing Manager', 'What scope?', true),
  ('campaign_project_manager', 'marketing_promotion', 'work_campaign_project_manager', 'Campaign Project Manager', 'Campaign type?', true),
  ('accountant_finance_officer', 'professional_services', 'work_accountant_finance_officer', 'Accountant / Finance Officer', 'What area?', true),
  ('lawyer_legal_officer', 'professional_services', 'work_lawyer_legal_officer', 'Lawyer / Legal Officer', 'What area?', true),
  ('engineer', 'professional_services', 'work_engineer', 'Engineer', 'Which discipline?', true),
  ('architect_designer', 'professional_services', 'work_architect_designer', 'Architect / Designer', 'What do you design?', true),
  ('hr_officer_manager', 'professional_services', 'work_hr_officer_manager', 'HR Officer / Manager', 'What area?', true),
  ('business_administrator_office_manager', 'professional_services', 'work_business_administrator_office_manager', 'Business Administrator / Office Manager', 'What kind of admin work?', true),
  ('consultant', 'professional_services', 'work_consultant', 'Consultant', 'Advisory area?', true),
  ('professional_services_project_manager', 'professional_services', 'work_professional_services_project_manager', 'Project Manager', 'What kind of projects?', true),
  ('teacher_tutor', 'education_training', 'work_teacher_tutor', 'Teacher / Tutor', 'What do you teach?', true),
  ('trainer_instructor', 'education_training', 'work_trainer_instructor', 'Trainer / Instructor', 'Training field?', true),
  ('placement_coordinator', 'education_training', 'work_placement_coordinator', 'Placement Coordinator', 'What placements?', true),
  ('programme_manager', 'education_training', 'work_programme_manager', 'Programme Manager', 'What programmes?', true),
  ('event_manager_planner', 'events_production', 'work_event_manager_planner', 'Event Manager / Planner', 'What events?', true),
  ('mc_dj', 'events_production', 'work_mc_dj', 'MC / DJ', 'Which role?', true),
  ('event_crew_technician', 'events_production', 'work_event_crew_technician', 'Event Crew / Technician', 'What do you operate?', true),
  ('caterer_chef', 'events_production', 'work_caterer_chef', 'Caterer / Chef', 'What kind?', true),
  ('event_supervisor', 'events_production', 'work_event_supervisor', 'Event Supervisor', 'What scope?', true),
  ('photographer_videographer', 'photo_video_music_talent', 'work_photographer_videographer', 'Photographer / Videographer', 'What do you shoot?', true),
  ('audio_engineer_producer', 'photo_video_music_talent', 'work_audio_engineer_producer', 'Audio Engineer / Producer', 'What do you do?', true),
  ('performer_talent', 'photo_video_music_talent', 'work_performer_talent', 'Performer / Talent', 'What kind?', true),
  ('production_manager', 'photo_video_music_talent', 'work_production_manager', 'Production Manager', 'What productions?', true),
  ('makeup_artist', 'beauty_fashion_styling', 'work_makeup_artist', 'Makeup Artist', 'Specialty?', true),
  ('hair_stylist', 'beauty_fashion_styling', 'work_hair_stylist', 'Hair Stylist', 'Specialty?', true),
  ('stylist_designer', 'beauty_fashion_styling', 'work_stylist_designer', 'Stylist / Designer', 'Specialty?', true),
  ('salon_studio_manager', 'beauty_fashion_styling', 'work_salon_studio_manager', 'Salon / Studio Manager', 'What scope?', true),
  ('site_manager', 'construction_building', 'work_site_manager', 'Site Manager', 'What type of sites?', true),
  ('construction_building_project_manager', 'construction_building', 'work_construction_building_project_manager', 'Project Manager', 'What kind of projects?', true),
  ('foreman_supervisor', 'construction_building', 'work_foreman_supervisor', 'Foreman / Supervisor', 'Which trade?', true),
  ('skilled_tradesperson', 'construction_building', 'work_skilled_tradesperson', 'Skilled Tradesperson', 'Which trade?', true),
  ('surveyor', 'construction_building', 'work_surveyor', 'Surveyor', 'What type?', true),
  ('solar_electrical_technician', 'energy_utilities', 'work_solar_electrical_technician', 'Solar / Electrical Technician', 'What do you install?', true),
  ('borehole_water_technician', 'energy_utilities', 'work_borehole_water_technician', 'Borehole / Water Technician', 'What do you do?', true),
  ('energy_engineer', 'energy_utilities', 'work_energy_engineer', 'Energy Engineer', 'Which area?', true),
  ('energy_utilities_project_manager', 'energy_utilities', 'work_energy_utilities_project_manager', 'Project Manager', 'What kind of projects?', true),
  ('driver', 'transport_logistics', 'work_driver', 'Driver', 'What do you drive?', true),
  ('fleet_operations_manager', 'transport_logistics', 'work_fleet_operations_manager', 'Fleet / Operations Manager', 'What fleet?', true),
  ('dispatcher_coordinator', 'transport_logistics', 'work_dispatcher_coordinator', 'Dispatcher / Coordinator', 'What area?', true),
  ('loader_mover', 'transport_logistics', 'work_loader_mover', 'Loader / Mover', 'What work?', true),
  ('driving_instructor', 'transport_logistics', 'work_driving_instructor', 'Driving Instructor', 'What do you teach?', true),
  ('machine_operator', 'machinery_equipment', 'work_machine_operator', 'Machine Operator', 'Which machine do you operate?', true),
  ('equipment_mechanic', 'machinery_equipment', 'work_equipment_mechanic', 'Equipment Mechanic', 'What do you service?', true),
  ('fleet_equipment_manager', 'machinery_equipment', 'work_fleet_equipment_manager', 'Fleet / Equipment Manager', 'What fleet?', true),
  ('site_supervisor', 'machinery_equipment', 'work_site_supervisor', 'Site Supervisor', 'Which sites?', true),
  ('farm_manager', 'agriculture_agribusiness', 'work_farm_manager', 'Farm Manager', 'What farm?', true),
  ('agronomist_extension_officer', 'agriculture_agribusiness', 'work_agronomist_extension_officer', 'Agronomist / Extension Officer', 'What focus?', true),
  ('veterinary_livestock_officer', 'agriculture_agribusiness', 'work_veterinary_livestock_officer', 'Veterinary / Livestock Officer', 'What animals?', true),
  ('farm_worker_operator', 'agriculture_agribusiness', 'work_farm_worker_operator', 'Farm Worker / Operator', 'What work?', true),
  ('procurement_officer_manager', 'specialized_products', 'work_procurement_officer_manager', 'Procurement Officer / Manager', 'What do you buy?', true),
  ('sourcing_agent', 'specialized_products', 'work_sourcing_agent', 'Sourcing Agent', 'Where do you source?', true),
  ('clearing_customs_agent', 'specialized_products', 'work_clearing_customs_agent', 'Clearing & Customs Agent', 'What do you handle?', true),
  ('travel_agent_consultant', 'travel_international', 'work_travel_agent_consultant', 'Travel Agent / Consultant', 'What do you handle?', true),
  ('tour_guide', 'travel_international', 'work_tour_guide', 'Tour Guide', 'What tours?', true),
  ('driver_guide', 'travel_international', 'work_driver_guide', 'Driver-Guide', 'What vehicle?', true),
  ('operations_manager', 'travel_international', 'work_operations_manager', 'Operations Manager', 'What scope?', true)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = true;

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('developer', 'frontend', 'Frontend', 10),
  ('developer', 'backend', 'Backend', 20),
  ('developer', 'full_stack', 'Full-stack', 30),
  ('developer', 'mobile', 'Mobile', 40),
  ('developer', 'qa_tester', 'QA / Tester', 50),
  ('developer', 'devops', 'DevOps', 60),
  ('it_technician', 'helpdesk', 'Helpdesk', 10),
  ('it_technician', 'hardware_repair', 'Hardware repair', 20),
  ('it_technician', 'network_installation', 'Network installation', 30),
  ('it_technician', 'cctv_access_control', 'CCTV & access control', 40),
  ('security_specialist', 'network_security', 'Network security', 10),
  ('security_specialist', 'penetration_testing', 'Penetration testing', 20),
  ('security_specialist', 'security_audits', 'Security audits', 30),
  ('project_manager', 'software', 'Software', 10),
  ('project_manager', 'it_infrastructure', 'IT infrastructure', 20),
  ('project_manager', 'digital_transformation', 'Digital transformation', 30),
  ('team_lead_manager', 'dev_team', 'Dev team', 10),
  ('team_lead_manager', 'it_support_team', 'IT / support team', 20),
  ('team_lead_manager', 'product', 'Product', 30),
  ('marketer_specialist', 'social_media', 'Social media', 10),
  ('marketer_specialist', 'seo_sem', 'SEO / SEM', 20),
  ('marketer_specialist', 'email', 'Email', 30),
  ('marketer_specialist', 'brand', 'Brand', 40),
  ('marketer_specialist', 'community_management', 'Community management', 50),
  ('content_creator', 'video', 'Video', 10),
  ('content_creator', 'photo', 'Photo', 20),
  ('content_creator', 'writing', 'Writing', 30),
  ('content_creator', 'design', 'Design', 40),
  ('content_creator', 'podcast', 'Podcast', 50),
  ('marketing_manager', 'brand', 'Brand', 10),
  ('marketing_manager', 'digital', 'Digital', 20),
  ('marketing_manager', 'events_promotions', 'Events & promotions', 30),
  ('campaign_project_manager', 'digital', 'Digital', 10),
  ('campaign_project_manager', 'field_activation', 'Field / activation', 20),
  ('campaign_project_manager', 'event', 'Event', 30),
  ('accountant_finance_officer', 'bookkeeping', 'Bookkeeping', 10),
  ('accountant_finance_officer', 'tax', 'Tax', 20),
  ('accountant_finance_officer', 'audit', 'Audit', 30),
  ('accountant_finance_officer', 'payroll', 'Payroll', 40),
  ('lawyer_legal_officer', 'corporate', 'Corporate', 10),
  ('lawyer_legal_officer', 'property', 'Property', 20),
  ('lawyer_legal_officer', 'contracts', 'Contracts', 30),
  ('lawyer_legal_officer', 'compliance', 'Compliance', 40),
  ('engineer', 'civil', 'Civil', 10),
  ('engineer', 'electrical', 'Electrical', 20),
  ('engineer', 'mechanical', 'Mechanical', 30),
  ('engineer', 'mining', 'Mining', 40),
  ('architect_designer', 'buildings', 'Buildings', 10),
  ('architect_designer', 'interiors', 'Interiors', 20),
  ('architect_designer', 'landscape', 'Landscape', 30),
  ('hr_officer_manager', 'recruitment', 'Recruitment', 10),
  ('hr_officer_manager', 'payroll_benefits', 'Payroll & benefits', 20),
  ('hr_officer_manager', 'training_compliance', 'Training & compliance', 30),
  ('business_administrator_office_manager', 'office_administration', 'Office administration', 10),
  ('business_administrator_office_manager', 'operations_support', 'Operations support', 20),
  ('business_administrator_office_manager', 'executive_assistant', 'Executive assistant', 30),
  ('business_administrator_office_manager', 'records_documentation', 'Records & documentation', 40),
  ('consultant', 'strategy', 'Strategy', 10),
  ('consultant', 'operations', 'Operations', 20),
  ('consultant', 'finance', 'Finance', 30),
  ('consultant', 'compliance', 'Compliance', 40),
  ('professional_services_project_manager', 'business', 'Business', 10),
  ('professional_services_project_manager', 'compliance', 'Compliance', 20),
  ('professional_services_project_manager', 'operations', 'Operations', 30),
  ('teacher_tutor', 'primary', 'Primary', 10),
  ('teacher_tutor', 'secondary', 'Secondary', 20),
  ('teacher_tutor', 'university', 'University', 30),
  ('teacher_tutor', 'languages', 'Languages', 40),
  ('teacher_tutor', 'exam_prep', 'Exam prep', 50),
  ('trainer_instructor', 'computer_it', 'Computer / IT', 10),
  ('trainer_instructor', 'vocational_technical', 'Vocational / technical', 20),
  ('trainer_instructor', 'professional_corporate', 'Professional / corporate', 30),
  ('trainer_instructor', 'driving', 'Driving', 40),
  ('placement_coordinator', 'internships', 'Internships', 10),
  ('placement_coordinator', 'nursing_health', 'Nursing / health', 20),
  ('placement_coordinator', 'study_abroad', 'Study abroad', 30),
  ('placement_coordinator', 'university', 'University', 40),
  ('programme_manager', 'training_programmes', 'Training programmes', 10),
  ('programme_manager', 'placement_programmes', 'Placement programmes', 20),
  ('event_manager_planner', 'weddings', 'Weddings', 10),
  ('event_manager_planner', 'corporate', 'Corporate', 20),
  ('event_manager_planner', 'birthdays_parties', 'Birthdays & parties', 30),
  ('event_manager_planner', 'graduations', 'Graduations', 40),
  ('event_manager_planner', 'funerals_memorials', 'Funerals & memorials', 50),
  ('mc_dj', 'mc', 'MC', 10),
  ('mc_dj', 'dj', 'DJ', 20),
  ('mc_dj', 'both', 'Both', 30),
  ('event_crew_technician', 'sound', 'Sound', 10),
  ('event_crew_technician', 'lighting', 'Lighting', 20),
  ('event_crew_technician', 'tents_setup', 'Tents & setup', 30),
  ('event_crew_technician', 'stage', 'Stage', 40),
  ('caterer_chef', 'event_catering', 'Event catering', 10),
  ('caterer_chef', 'cakes_baking', 'Cakes & baking', 20),
  ('caterer_chef', 'buffet_plated', 'Buffet / plated', 30),
  ('event_supervisor', 'venue', 'Venue', 10),
  ('event_supervisor', 'logistics', 'Logistics', 20),
  ('event_supervisor', 'guest_management', 'Guest management', 30),
  ('photographer_videographer', 'weddings', 'Weddings', 10),
  ('photographer_videographer', 'corporate', 'Corporate', 20),
  ('photographer_videographer', 'fashion_portraits', 'Fashion & portraits', 30),
  ('photographer_videographer', 'music_videos', 'Music videos', 40),
  ('photographer_videographer', 'real_estate', 'Real estate', 50),
  ('photographer_videographer', 'graduations', 'Graduations', 60),
  ('audio_engineer_producer', 'recording', 'Recording', 10),
  ('audio_engineer_producer', 'mixing_mastering', 'Mixing & mastering', 20),
  ('audio_engineer_producer', 'beat_production', 'Beat production', 30),
  ('audio_engineer_producer', 'live_sound', 'Live sound', 40),
  ('performer_talent', 'singer', 'Singer', 10),
  ('performer_talent', 'dancer', 'Dancer', 20),
  ('performer_talent', 'actor', 'Actor', 30),
  ('performer_talent', 'model', 'Model', 40),
  ('performer_talent', 'extra', 'Extra', 50),
  ('production_manager', 'video_film', 'Video / film', 10),
  ('production_manager', 'music', 'Music', 20),
  ('production_manager', 'live_events', 'Live events', 30),
  ('makeup_artist', 'bridal', 'Bridal', 10),
  ('makeup_artist', 'fashion_editorial', 'Fashion / editorial', 20),
  ('makeup_artist', 'film_stage', 'Film / stage', 30),
  ('makeup_artist', 'everyday', 'Everyday', 40),
  ('hair_stylist', 'braiding', 'Braiding', 10),
  ('hair_stylist', 'salon_styling', 'Salon styling', 20),
  ('hair_stylist', 'bridal_hair', 'Bridal hair', 30),
  ('hair_stylist', 'barbering', 'Barbering', 40),
  ('stylist_designer', 'wardrobe_styling', 'Wardrobe styling', 10),
  ('stylist_designer', 'tailoring', 'Tailoring', 20),
  ('stylist_designer', 'bridal_wear', 'Bridal wear', 30),
  ('salon_studio_manager', 'salon', 'Salon', 10),
  ('salon_studio_manager', 'fashion_studio', 'Fashion studio', 20),
  ('site_manager', 'residential', 'Residential', 10),
  ('site_manager', 'commercial', 'Commercial', 20),
  ('site_manager', 'infrastructure', 'Infrastructure', 30),
  ('construction_building_project_manager', 'residential', 'Residential', 10),
  ('construction_building_project_manager', 'commercial', 'Commercial', 20),
  ('construction_building_project_manager', 'roads_civil', 'Roads & civil', 30),
  ('foreman_supervisor', 'masonry', 'Masonry', 10),
  ('foreman_supervisor', 'roofing', 'Roofing', 20),
  ('foreman_supervisor', 'concrete', 'Concrete', 30),
  ('foreman_supervisor', 'finishing', 'Finishing', 40),
  ('skilled_tradesperson', 'mason', 'Mason', 10),
  ('skilled_tradesperson', 'plumber', 'Plumber', 20),
  ('skilled_tradesperson', 'electrician', 'Electrician', 30),
  ('skilled_tradesperson', 'carpenter', 'Carpenter', 40),
  ('skilled_tradesperson', 'welder', 'Welder', 50),
  ('skilled_tradesperson', 'painter', 'Painter', 60),
  ('skilled_tradesperson', 'roofer', 'Roofer', 70),
  ('surveyor', 'land', 'Land', 10),
  ('surveyor', 'quantity', 'Quantity', 20),
  ('surveyor', 'topographic', 'Topographic', 30),
  ('solar_electrical_technician', 'solar_pv', 'Solar PV', 10),
  ('solar_electrical_technician', 'batteries_inverters', 'Batteries & inverters', 20),
  ('solar_electrical_technician', 'generators', 'Generators', 30),
  ('solar_electrical_technician', 'wiring', 'Wiring', 40),
  ('borehole_water_technician', 'drilling', 'Drilling', 10),
  ('borehole_water_technician', 'pump_installation', 'Pump installation', 20),
  ('borehole_water_technician', 'plumbing_tanks', 'Plumbing & tanks', 30),
  ('borehole_water_technician', 'water_treatment', 'Water treatment', 40),
  ('energy_engineer', 'solar_design', 'Solar design', 10),
  ('energy_engineer', 'energy_audits', 'Energy audits', 20),
  ('energy_engineer', 'grid_mini_grid', 'Grid / mini-grid', 30),
  ('energy_utilities_project_manager', 'solar', 'Solar', 10),
  ('energy_utilities_project_manager', 'water', 'Water', 20),
  ('energy_utilities_project_manager', 'electrification', 'Electrification', 30),
  ('driver', 'truck_heavy', 'Truck / heavy', 10),
  ('driver', 'pickup_van', 'Pickup / van', 20),
  ('driver', 'bus_minibus', 'Bus / minibus', 30),
  ('driver', 'motorcycle_courier', 'Motorcycle courier', 40),
  ('driver', 'tanker', 'Tanker', 50),
  ('fleet_operations_manager', 'trucks', 'Trucks', 10),
  ('fleet_operations_manager', 'vans_couriers', 'Vans & couriers', 20),
  ('fleet_operations_manager', 'mixed', 'Mixed', 30),
  ('dispatcher_coordinator', 'route_planning', 'Route planning', 10),
  ('dispatcher_coordinator', 'customs_clearing', 'Customs & clearing', 20),
  ('dispatcher_coordinator', 'warehouse', 'Warehouse', 30),
  ('loader_mover', 'moving', 'Moving', 10),
  ('loader_mover', 'warehouse', 'Warehouse', 20),
  ('loader_mover', 'loading', 'Loading', 30),
  ('driving_instructor', 'cars', 'Cars', 10),
  ('driving_instructor', 'motorcycles', 'Motorcycles', 20),
  ('driving_instructor', 'trucks', 'Trucks', 30),
  ('driving_instructor', 'defensive_driving', 'Defensive driving', 40),
  ('machine_operator', 'excavator', 'Excavator', 10),
  ('machine_operator', 'loader', 'Loader', 20),
  ('machine_operator', 'grader', 'Grader', 30),
  ('machine_operator', 'crane', 'Crane', 40),
  ('machine_operator', 'tractor', 'Tractor', 50),
  ('machine_operator', 'roller', 'Roller', 60),
  ('machine_operator', 'forklift', 'Forklift', 70),
  ('machine_operator', 'bulldozer', 'Bulldozer', 80),
  ('machine_operator', 'concrete_mixer_pump', 'Concrete mixer / pump', 90),
  ('equipment_mechanic', 'heavy_plant', 'Heavy plant', 10),
  ('equipment_mechanic', 'generators', 'Generators', 20),
  ('equipment_mechanic', 'hydraulics', 'Hydraulics', 30),
  ('equipment_mechanic', 'electrical_systems', 'Electrical systems', 40),
  ('fleet_equipment_manager', 'construction_plant', 'Construction plant', 10),
  ('fleet_equipment_manager', 'farm_machinery', 'Farm machinery', 20),
  ('fleet_equipment_manager', 'industrial_equipment', 'Industrial equipment', 30),
  ('site_supervisor', 'earthworks', 'Earthworks', 10),
  ('site_supervisor', 'quarry_mining', 'Quarry / mining', 20),
  ('site_supervisor', 'farm', 'Farm', 30),
  ('farm_manager', 'crops', 'Crops', 10),
  ('farm_manager', 'dairy', 'Dairy', 20),
  ('farm_manager', 'poultry', 'Poultry', 30),
  ('farm_manager', 'mixed', 'Mixed', 40),
  ('agronomist_extension_officer', 'crops', 'Crops', 10),
  ('agronomist_extension_officer', 'soil_irrigation', 'Soil & irrigation', 20),
  ('agronomist_extension_officer', 'pest_management', 'Pest management', 30),
  ('veterinary_livestock_officer', 'cattle', 'Cattle', 10),
  ('veterinary_livestock_officer', 'poultry', 'Poultry', 20),
  ('veterinary_livestock_officer', 'small_ruminants', 'Small ruminants', 30),
  ('farm_worker_operator', 'tractor_operation', 'Tractor operation', 10),
  ('farm_worker_operator', 'irrigation', 'Irrigation', 20),
  ('farm_worker_operator', 'harvesting', 'Harvesting', 30),
  ('farm_worker_operator', 'spraying', 'Spraying', 40),
  ('procurement_officer_manager', 'industrial', 'Industrial', 10),
  ('procurement_officer_manager', 'electronics', 'Electronics', 20),
  ('procurement_officer_manager', 'medical_lab', 'Medical & lab', 30),
  ('procurement_officer_manager', 'general_supplies', 'General supplies', 40),
  ('sourcing_agent', 'local', 'Local', 10),
  ('sourcing_agent', 'china', 'China', 20),
  ('sourcing_agent', 'dubai', 'Dubai', 30),
  ('sourcing_agent', 'india', 'India', 40),
  ('sourcing_agent', 'europe_usa', 'Europe / USA', 50),
  ('clearing_customs_agent', 'imports', 'Imports', 10),
  ('clearing_customs_agent', 'exports', 'Exports', 20),
  ('clearing_customs_agent', 'freight_forwarding', 'Freight forwarding', 30),
  ('travel_agent_consultant', 'flights', 'Flights', 10),
  ('travel_agent_consultant', 'tours_packages', 'Tours & packages', 20),
  ('travel_agent_consultant', 'visas', 'Visas', 30),
  ('travel_agent_consultant', 'hajj_umrah', 'Hajj & Umrah', 40),
  ('travel_agent_consultant', 'relocation', 'Relocation', 50),
  ('tour_guide', 'wildlife_safari', 'Wildlife safari', 10),
  ('tour_guide', 'cultural', 'Cultural', 20),
  ('tour_guide', 'city_tours', 'City tours', 30),
  ('tour_guide', 'adventure', 'Adventure', 40),
  ('driver_guide', 'safari_vehicle', 'Safari vehicle', 10),
  ('driver_guide', 'minibus', 'Minibus', 20),
  ('driver_guide', 'airport_transfers', 'Airport transfers', 30),
  ('operations_manager', 'tours', 'Tours', 10),
  ('operations_manager', 'visa_documentation', 'Visa & documentation', 20),
  ('operations_manager', 'travel_desk', 'Travel desk', 30)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

alter table public.role_qualifications
  add column if not exists is_evidence boolean not null default false;

insert into public.role_qualifications (role_slug, slug, name, sort_order, is_evidence)
values
  ('developer', 'degree_diploma_in_it_or_cs', 'Degree / Diploma in IT or CS', 10, false),
  ('developer', 'portfolio_or_github_link', 'Portfolio or GitHub link', 20, false),
  ('developer', 'cloud_certification_aws_azure_gcp', 'Cloud certification (AWS/Azure/GCP)', 30, false),
  ('developer', '3_years_experience', '3+ years experience', 40, false),
  ('it_technician', 'comptia_a_n', 'CompTIA A+ / N+', 10, false),
  ('it_technician', 'ccna', 'CCNA', 20, false),
  ('it_technician', 'own_toolkit', 'Own toolkit', 30, false),
  ('it_technician', '2_years_experience', '2+ years experience', 40, false),
  ('security_specialist', 'ceh', 'CEH', 10, false),
  ('security_specialist', 'cissp_cism', 'CISSP / CISM', 20, false),
  ('security_specialist', 'iso_27001', 'ISO 27001', 30, false),
  ('security_specialist', 'police_clearance', 'Police clearance', 40, false),
  ('project_manager', 'pmp_prince2', 'PMP / PRINCE2', 10, false),
  ('project_manager', 'agile_scrum_certified', 'Agile / Scrum certified', 20, false),
  ('project_manager', 'led_3_projects', 'Led 3+ projects', 30, false),
  ('project_manager', 'degree', 'Degree', 40, false),
  ('team_lead_manager', 'managed_5_people', 'Managed 5+ people', 10, false),
  ('team_lead_manager', 'degree', 'Degree', 20, false),
  ('team_lead_manager', '3_years_leadership', '3+ years leadership', 30, false),
  ('marketer_specialist', 'marketing_diploma_degree', 'Marketing diploma / degree', 10, false),
  ('marketer_specialist', 'google_ads_meta_certified', 'Google Ads / Meta certified', 20, false),
  ('marketer_specialist', 'case_studies_or_portfolio', 'Case studies or portfolio', 30, false),
  ('marketer_specialist', '2_years_experience', '2+ years experience', 40, false),
  ('content_creator', 'portfolio', 'Portfolio', 10, false),
  ('content_creator', 'own_equipment', 'Own equipment', 20, false),
  ('content_creator', 'audience_size_proof', 'Audience size proof', 30, false),
  ('marketing_manager', 'degree', 'Degree', 10, false),
  ('marketing_manager', 'managed_budgets', 'Managed budgets', 20, false),
  ('marketing_manager', 'managed_3_people', 'Managed 3+ people', 30, false),
  ('campaign_project_manager', 'pmp_prince2', 'PMP / PRINCE2', 10, false),
  ('campaign_project_manager', 'led_3_campaigns', 'Led 3+ campaigns', 20, false),
  ('accountant_finance_officer', 'cpa_acca_cpa_u', 'CPA / ACCA / CPA-U', 10, false),
  ('accountant_finance_officer', 'degree', 'Degree', 20, false),
  ('accountant_finance_officer', 'practising_certificate', 'Practising certificate', 30, false),
  ('accountant_finance_officer', '3_years_experience', '3+ years experience', 40, false),
  ('lawyer_legal_officer', 'bar_admission_practising_certificate', 'Bar admission / practising certificate', 10, false),
  ('lawyer_legal_officer', 'llb', 'LLB', 20, false),
  ('lawyer_legal_officer', '3_years_experience', '3+ years experience', 30, false),
  ('engineer', 'degree_in_engineering', 'Degree in engineering', 10, false),
  ('engineer', 'registered_with_engineers_board', 'Registered with engineers board', 20, false),
  ('engineer', 'site_experience', 'Site experience', 30, false),
  ('architect_designer', 'registered_architect', 'Registered architect', 10, false),
  ('architect_designer', 'portfolio', 'Portfolio', 20, false),
  ('architect_designer', 'cad_bim_skills', 'CAD/BIM skills', 30, false),
  ('hr_officer_manager', 'hr_diploma_degree', 'HR diploma / degree', 10, false),
  ('hr_officer_manager', 'ihrm_cipd', 'IHRM / CIPD', 20, false),
  ('hr_officer_manager', '3_years_experience', '3+ years experience', 30, false),
  ('business_administrator_office_manager', 'diploma_degree_in_business_administration', 'Diploma / degree in business administration', 10, false),
  ('business_administrator_office_manager', 'office_software_skills_documents_spreadsheets_email', 'Office software skills (documents, spreadsheets, email)', 20, false),
  ('business_administrator_office_manager', '2_years_experience', '2+ years experience', 30, false),
  ('business_administrator_office_manager', 'references', 'References', 40, false),
  ('consultant', 'degree', 'Degree', 10, false),
  ('consultant', 'case_studies', 'Case studies', 20, false),
  ('consultant', '5_years_experience', '5+ years experience', 30, false),
  ('professional_services_project_manager', 'pmp_prince2', 'PMP / PRINCE2', 10, false),
  ('professional_services_project_manager', 'led_3_projects', 'Led 3+ projects', 20, false),
  ('teacher_tutor', 'teaching_certificate_degree', 'Teaching certificate / degree', 10, false),
  ('teacher_tutor', 'registered_with_teaching_board', 'Registered with teaching board', 20, false),
  ('teacher_tutor', '2_years_teaching', '2+ years teaching', 30, false),
  ('teacher_tutor', 'subject_specialisation', 'Subject specialisation', 40, false),
  ('trainer_instructor', 'trade_certificate', 'Trade certificate', 10, false),
  ('trainer_instructor', 'trainer_of_trainers_tot', 'Trainer-of-trainers (ToT)', 20, false),
  ('trainer_instructor', 'industry_experience_3_years', 'Industry experience 3+ years', 30, false),
  ('placement_coordinator', 'education_or_hr_background', 'Education or HR background', 10, false),
  ('placement_coordinator', 'partner_network', 'Partner network', 20, false),
  ('placement_coordinator', 'counselling_certificate', 'Counselling certificate', 30, false),
  ('programme_manager', 'degree', 'Degree', 10, false),
  ('programme_manager', 'managed_3_programmes', 'Managed 3+ programmes', 20, false),
  ('event_manager_planner', 'event_planning_certificate', 'Event planning certificate', 10, false),
  ('event_manager_planner', 'portfolio_of_5_events', 'Portfolio of 5+ events', 20, false),
  ('event_manager_planner', 'insurance_permit', 'Insurance / permit', 30, false),
  ('event_manager_planner', 'team_of_3_staff', 'Team of 3+ staff', 40, false),
  ('mc_dj', 'own_equipment', 'Own equipment', 10, false),
  ('mc_dj', 'sample_mix_video', 'Sample mix / video', 20, false),
  ('mc_dj', 'references', 'References', 30, false),
  ('event_crew_technician', 'technical_training', 'Technical training', 10, false),
  ('event_crew_technician', 'own_tools', 'Own tools', 20, false),
  ('event_crew_technician', 'event_experience_1_year', 'Event experience 1+ year', 30, false),
  ('caterer_chef', 'food_handler_certificate', 'Food handler certificate', 10, false),
  ('caterer_chef', 'health_permit', 'Health permit', 20, false),
  ('caterer_chef', 'culinary_diploma', 'Culinary diploma', 30, false),
  ('event_supervisor', 'managed_5_events', 'Managed 5+ events', 10, false),
  ('event_supervisor', 'team_leadership', 'Team leadership', 20, false),
  ('photographer_videographer', 'portfolio_link', 'Portfolio link', 10, false),
  ('photographer_videographer', 'own_camera_drone_kit', 'Own camera / drone kit', 20, false),
  ('photographer_videographer', 'drone_licence', 'Drone licence', 30, false),
  ('photographer_videographer', 'editing_skills', 'Editing skills', 40, false),
  ('audio_engineer_producer', 'own_studio_daw', 'Own studio / DAW', 10, false),
  ('audio_engineer_producer', 'portfolio', 'Portfolio', 20, false),
  ('audio_engineer_producer', 'audio_engineering_diploma', 'Audio engineering diploma', 30, false),
  ('performer_talent', 'showreel_audition_clip', 'Showreel / audition clip', 10, false),
  ('performer_talent', 'agency_representation', 'Agency representation', 20, false),
  ('performer_talent', 'performance_experience', 'Performance experience', 30, false),
  ('production_manager', 'managed_3_productions', 'Managed 3+ productions', 10, false),
  ('production_manager', 'budget_handling', 'Budget handling', 20, false),
  ('production_manager', 'crew_network', 'Crew network', 30, false),
  ('makeup_artist', 'cosmetology_certificate', 'Cosmetology certificate', 10, false),
  ('makeup_artist', 'portfolio', 'Portfolio', 20, false),
  ('makeup_artist', 'own_kit', 'Own kit', 30, false),
  ('makeup_artist', 'hygiene_certification', 'Hygiene certification', 40, false),
  ('hair_stylist', 'cosmetology_certificate', 'Cosmetology certificate', 10, false),
  ('hair_stylist', 'portfolio', 'Portfolio', 20, false),
  ('hair_stylist', 'salon_licence', 'Salon licence', 30, false),
  ('stylist_designer', 'fashion_diploma', 'Fashion diploma', 10, false),
  ('stylist_designer', 'portfolio', 'Portfolio', 20, false),
  ('stylist_designer', 'own_workshop', 'Own workshop', 30, false),
  ('salon_studio_manager', 'managed_3_staff', 'Managed 3+ staff', 10, false),
  ('salon_studio_manager', 'business_licence', 'Business licence', 20, false),
  ('site_manager', 'civil_construction_diploma_or_degree', 'Civil/Construction diploma or degree', 10, false),
  ('site_manager', 'registered_with_engineers_contractors_board', 'Registered with engineers/contractors board', 20, false),
  ('site_manager', '5_years_on_site', '5+ years on site', 30, false),
  ('site_manager', 'safety_certification_osha', 'Safety certification (OSHA)', 40, false),
  ('construction_building_project_manager', 'pmp_prince2', 'PMP / PRINCE2', 10, false),
  ('construction_building_project_manager', 'degree', 'Degree', 20, false),
  ('construction_building_project_manager', 'delivered_3_projects', 'Delivered 3+ projects', 30, false),
  ('foreman_supervisor', 'trade_test_certificate', 'Trade test certificate', 10, false),
  ('foreman_supervisor', 'managed_10_workers', 'Managed 10+ workers', 20, false),
  ('foreman_supervisor', 'safety_training', 'Safety training', 30, false),
  ('skilled_tradesperson', 'trade_test_grade_i_ii_iii', 'Trade test (Grade I/II/III)', 10, false),
  ('skilled_tradesperson', 'licence_electrical_plumbing', 'Licence (electrical/plumbing)', 20, false),
  ('skilled_tradesperson', 'own_tools', 'Own tools', 30, false),
  ('skilled_tradesperson', '2_years_experience', '2+ years experience', 40, false),
  ('surveyor', 'registered_surveyor', 'Registered surveyor', 10, false),
  ('surveyor', 'degree_diploma', 'Degree / diploma', 20, false),
  ('surveyor', 'own_instruments', 'Own instruments', 30, false),
  ('solar_electrical_technician', 'electrical_licence', 'Electrical licence', 10, false),
  ('solar_electrical_technician', 'solar_installer_certificate', 'Solar installer certificate', 20, false),
  ('solar_electrical_technician', 'safety_training', 'Safety training', 30, false),
  ('solar_electrical_technician', 'own_tools', 'Own tools', 40, false),
  ('borehole_water_technician', 'water_technician_certificate', 'Water technician certificate', 10, false),
  ('borehole_water_technician', 'drilling_permit', 'Drilling permit', 20, false),
  ('borehole_water_technician', 'own_equipment', 'Own equipment', 30, false),
  ('energy_engineer', 'engineering_degree', 'Engineering degree', 10, false),
  ('energy_engineer', 'registered_engineer', 'Registered engineer', 20, false),
  ('energy_engineer', 'design_software_skills', 'Design software skills', 30, false),
  ('energy_utilities_project_manager', 'pmp_prince2', 'PMP / PRINCE2', 10, false),
  ('energy_utilities_project_manager', 'delivered_3_projects', 'Delivered 3+ projects', 20, false),
  ('driver', 'valid_driving_licence_class', 'Valid driving licence (class)', 10, false),
  ('driver', 'psv_badge', 'PSV badge', 20, false),
  ('driver', 'clean_driving_record', 'Clean driving record', 30, false),
  ('driver', 'defensive_driving_certificate', 'Defensive driving certificate', 40, false),
  ('driver', 'own_vehicle', 'Own vehicle', 50, false),
  ('fleet_operations_manager', 'logistics_diploma_degree', 'Logistics diploma / degree', 10, false),
  ('fleet_operations_manager', 'managed_10_vehicles', 'Managed 10+ vehicles', 20, false),
  ('fleet_operations_manager', 'transport_licence', 'Transport licence', 30, false),
  ('dispatcher_coordinator', 'logistics_experience', 'Logistics experience', 10, false),
  ('dispatcher_coordinator', 'customs_clearing_licence', 'Customs clearing licence', 20, false),
  ('loader_mover', 'physical_fitness', 'Physical fitness', 10, false),
  ('loader_mover', 'experience_1_year', 'Experience 1+ year', 20, false),
  ('driving_instructor', 'instructor_licence', 'Instructor licence', 10, true),
  ('driving_instructor', 'valid_driving_licence', 'Valid driving licence', 20, true),
  ('driving_instructor', 'teaching_experience', '2+ years teaching', 30, false),
  ('machine_operator', 'operator_licence_certificate', 'Operator licence / certificate', 10, false),
  ('machine_operator', 'safety_osha_certificate', 'Safety / OSHA certificate', 20, false),
  ('machine_operator', '3_years_experience', '3+ years experience', 30, false),
  ('machine_operator', 'medical_fitness', 'Medical fitness', 40, false),
  ('machine_operator', 'can_work_away_from_home', 'Can work away from home', 50, false),
  ('equipment_mechanic', 'mechanic_trade_certificate', 'Mechanic trade certificate', 10, false),
  ('equipment_mechanic', 'own_tools', 'Own tools', 20, false),
  ('equipment_mechanic', 'field_repair_experience', 'Field repair experience', 30, false),
  ('fleet_equipment_manager', 'managed_fleet_of_5_machines', 'Managed fleet of 5+ machines', 10, false),
  ('fleet_equipment_manager', 'diploma_degree', 'Diploma / degree', 20, false),
  ('fleet_equipment_manager', 'maintenance_scheduling', 'Maintenance scheduling', 30, false),
  ('site_supervisor', 'plant_experience', 'Plant experience', 10, false),
  ('site_supervisor', 'team_leadership', 'Team leadership', 20, false),
  ('site_supervisor', 'safety_certification', 'Safety certification', 30, false),
  ('farm_manager', 'agriculture_diploma_degree', 'Agriculture diploma / degree', 10, false),
  ('farm_manager', 'managed_5_workers', 'Managed 5+ workers', 20, false),
  ('farm_manager', '5_years_farming_experience', '5+ years farming experience', 30, false),
  ('agronomist_extension_officer', 'degree_diploma_in_agronomy', 'Degree / diploma in agronomy', 10, false),
  ('agronomist_extension_officer', 'field_experience', 'Field experience', 20, false),
  ('veterinary_livestock_officer', 'veterinary_licence', 'Veterinary licence', 10, false),
  ('veterinary_livestock_officer', 'diploma_degree', 'Diploma / degree', 20, false),
  ('veterinary_livestock_officer', 'vaccination_certification', 'Vaccination certification', 30, false),
  ('farm_worker_operator', 'tractor_licence', 'Tractor licence', 10, false),
  ('farm_worker_operator', 'pesticide_handling_certificate', 'Pesticide handling certificate', 20, false),
  ('farm_worker_operator', 'experience_1_year', 'Experience 1+ year', 30, false),
  ('procurement_officer_manager', 'procurement_diploma_cips_or_similar', 'Procurement diploma (CIPS or similar)', 10, false),
  ('procurement_officer_manager', 'supplier_network', 'Supplier network', 20, false),
  ('procurement_officer_manager', '3_years_experience', '3+ years experience', 30, false),
  ('sourcing_agent', 'import_export_experience', 'Import/export experience', 10, false),
  ('sourcing_agent', 'language_skills', 'Language skills', 20, false),
  ('sourcing_agent', 'supplier_contacts', 'Supplier contacts', 30, false),
  ('clearing_customs_agent', 'customs_clearing_licence', 'Customs clearing licence', 10, false),
  ('clearing_customs_agent', 'logistics_experience', 'Logistics experience', 20, false),
  ('travel_agent_consultant', 'iata_certification', 'IATA certification', 10, false),
  ('travel_agent_consultant', 'travel_agency_licence', 'Travel agency licence', 20, false),
  ('travel_agent_consultant', '2_years_experience', '2+ years experience', 30, false),
  ('tour_guide', 'tourism_board_guide_licence', 'Tourism board guide licence', 10, false),
  ('tour_guide', 'first_aid_certificate', 'First aid certificate', 20, false),
  ('tour_guide', 'languages_spoken', 'Languages spoken', 30, false),
  ('driver_guide', 'valid_driving_licence_class', 'Valid driving licence (class)', 10, false),
  ('driver_guide', 'tourism_licence', 'Tourism licence', 20, false),
  ('driver_guide', 'clean_driving_record', 'Clean driving record', 30, false),
  ('operations_manager', 'tourism_diploma_degree', 'Tourism diploma / degree', 10, false),
  ('operations_manager', 'managed_3_staff', 'Managed 3+ staff', 20, false)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order,
  is_evidence = excluded.is_evidence;


-- 6. Atomic bulk save RPC for Provider Capabilities
create or replace function public.save_provider_capabilities(
  p_items jsonb default '[]'::jsonb,
  p_category_slug text default null,
  p_remove_slugs text[] default array[]::text[]
)
returns setof public.provider_capabilities
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_max_cap int := 30;
  v_current_count int;
  v_item record;
  v_slug text;
  v_meta jsonb;
  v_incoming_slugs text[] := array[]::text[];
begin
  if v_user_id is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select coalesce(nullif(setting_value, '')::int, 30)
  into v_max_cap
  from public.system_settings
  where setting_key = 'max_provider_capabilities'
    and (country is null or country = '__global__')
  limit 1;
  v_max_cap := coalesce(v_max_cap, 30);

  -- Extract incoming slugs
  for v_item in select * from jsonb_to_recordset(p_items) as x(capability_slug text, metadata jsonb)
  loop
    v_incoming_slugs := array_append(v_incoming_slugs, v_item.capability_slug);
  end loop;

  -- Calculate anticipated total
  select count(*)
  into v_current_count
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  where pc.user_id = v_user_id
    and (
      (p_category_slug is not null and nc.category_slug <> p_category_slug)
      or (p_category_slug is null and not (pc.capability_slug = any(p_remove_slugs)))
    );

  if (v_current_count + coalesce(array_length(v_incoming_slugs, 1), 0)) > v_max_cap then
    raise exception 'Maximum limit of % provider capabilities reached.' , v_max_cap
      using errcode = 'P0206';
  end if;

  -- Process explicit removals
  if p_remove_slugs is not null and array_length(p_remove_slugs, 1) > 0 then
    delete from public.provider_capabilities
    where user_id = v_user_id
      and capability_slug = any(p_remove_slugs);
  end if;

  -- Process category-scoped un-ticked removals
  if p_category_slug is not null then
    delete from public.provider_capabilities pc
    using public.need_capabilities nc
    where pc.capability_slug = nc.slug
      and pc.user_id = v_user_id
      and nc.category_slug = p_category_slug
      and not (pc.capability_slug = any(v_incoming_slugs));
  end if;

  -- Upsert items
  for v_item in select * from jsonb_to_recordset(p_items) as x(capability_slug text, metadata jsonb)
  loop
    insert into public.provider_capabilities (
      user_id,
      capability_slug,
      verification_level,
      metadata,
      created_at
    )
    values (
      v_user_id,
      v_item.capability_slug,
      'self_declared',
      coalesce(v_item.metadata, '{}'::jsonb),
      now()
    )
    on conflict (user_id, capability_slug) do update set
      metadata = case
        when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb
          then excluded.metadata
        else public.provider_capabilities.metadata
      end;
  end loop;

  return query
  select * from public.provider_capabilities
  where user_id = v_user_id;
end;
$$;

grant execute on function public.save_provider_capabilities to authenticated;

-- Helper to safely convert JSONB array to text array
create or replace function private.jsonb_text_array(p_value jsonb)
returns text[]
language sql
immutable
as $$
  select coalesce(array_agg(x.value), array[]::text[])
  from jsonb_array_elements_text(
    case
      when jsonb_typeof(p_value) = 'array' then p_value
      else '[]'::jsonb
    end
  ) as x(value);
$$;

-- 7. Matching Function
create or replace function private.capability_match_score(
  p_need_details jsonb,
  p_provider_metadata jsonb
)
returns integer
language plpgsql
immutable
as $$
declare
  v_role_id text := nullif(btrim(coalesce(p_need_details->>'role_id', '')), '');
  v_need_kinds text[] := private.jsonb_text_array(p_need_details->'kind_ids');
  v_required_quals text[] := private.jsonb_text_array(p_need_details->'required_qualification_ids');
  v_role jsonb;
  v_role_kinds text[];
  v_role_quals text[];
  v_matched_quals int := 0;
  v_total_quals int := coalesce(array_length(v_required_quals, 1), 0);
begin
  if coalesce(p_need_details->>'engagement', '') <> 'hire_person' then
    return 100;
  end if;

  -- Direct metadata format (single role work capability)
  if p_provider_metadata ? 'kind_ids' or p_provider_metadata ? 'qualification_ids' then
    v_role_kinds := private.jsonb_text_array(p_provider_metadata->'kind_ids');
    v_role_quals := private.jsonb_text_array(p_provider_metadata->'qualification_ids');

    if coalesce(array_length(v_need_kinds, 1), 0) > 0
       and not (v_need_kinds && v_role_kinds) then
      return 0;
    end if;

    if v_total_quals = 0 then
      return 100;
    end if;

    select count(*)::int
    into v_matched_quals
    from unnest(v_required_quals) q
    where q = any(v_role_quals);

    return round((v_matched_quals::numeric / v_total_quals::numeric) * 100)::int;
  end if;

  -- Array format fallback
  if p_provider_metadata ? 'roles' then
    for v_role in select jsonb_array_elements(p_provider_metadata->'roles')
    loop
      if v_role->>'role_id' = v_role_id then
        v_role_kinds := private.jsonb_text_array(v_role->'kind_ids');
        v_role_quals := private.jsonb_text_array(v_role->'qualification_ids');

        if coalesce(array_length(v_need_kinds, 1), 0) > 0
           and not (v_need_kinds && v_role_kinds) then
          continue;
        end if;

        if v_total_quals = 0 then
          return 100;
        end if;

        select count(*)::int
        into v_matched_quals
        from unnest(v_required_quals) q
        where q = any(v_role_quals);

        return round((v_matched_quals::numeric / v_total_quals::numeric) * 100)::int;
      end if;
    end loop;
  end if;

  return 0;
end;
$$;

-- 8. Status view
drop view if exists public.v_my_capability_status cascade;
create or replace view public.v_my_capability_status
with (security_invoker = true)
as
with latest_rejection as (
  select distinct on (e.provider_capability_id)
    e.provider_capability_id, e.reject_reason, e.reviewed_at
  from public.provider_capability_evidence e
  where e.status = 'rejected'
  order by e.provider_capability_id, e.reviewed_at desc nulls last, e.created_at desc
),
evidence_summary as (
  select
    e.provider_capability_id,
    count(*) filter (where e.status = 'pending') as pending_count,
    count(*) filter (where e.status = 'approved') as approved_count,
    count(*) filter (where e.status = 'rejected') as rejected_count,
    count(*) filter (where e.status = 'expired') as expired_count
  from public.provider_capability_evidence e
  group by e.provider_capability_id
)
select
  pc.id as provider_capability_id,
  pc.user_id,
  pc.capability_slug,
  nc.name as capability_name,
  nc.category_slug,
  cat.name as category_name,
  cat.icon as category_icon,
  pc.verification_level,
  pc.metadata,
  case
    when pc.verification_level = 'provider_verified' then 'provider_verified'
    when coalesce(es.pending_count, 0) > 0 then 'pending_review'
    when coalesce(es.rejected_count, 0) > 0 then 'rejected'
    when coalesce(es.expired_count, 0) > 0 then 'expired'
    else 'self_declared'
  end as capability_status,
  coalesce(es.pending_count, 0)::int as pending_evidence_count,
  coalesce(es.approved_count, 0)::int as approved_evidence_count,
  coalesce(es.rejected_count, 0)::int as rejected_evidence_count,
  coalesce(es.expired_count, 0)::int as expired_evidence_count,
  lr.reject_reason as latest_reject_reason,
  pc.verified_by,
  pc.verified_at,
  pc.created_at,
  nc.capability_type
from public.provider_capabilities pc
join public.need_capabilities nc on nc.slug = pc.capability_slug
join public.need_categories cat on cat.slug = nc.category_slug
left join evidence_summary es on es.provider_capability_id = pc.id
left join latest_rejection lr on lr.provider_capability_id = pc.id
where pc.user_id = auth.uid() or private.is_admin();

grant select on public.v_my_capability_status to authenticated;

-- 9. System settings flags
insert into public.system_settings
  (setting_key, country, setting_value, setting_type, category, description, is_public)
values
  ('capability_profiles_enabled', null, 'false', 'boolean', 'provider',
   'Enables Provider Services v2 multi-capability flow.', true),
  ('work_profiles_enabled', null, 'false', 'boolean', 'provider',
   'Enables Work Profiles and roles across categories.', true),
  ('max_provider_capabilities', null, '30', 'number', 'provider',
   'Maximum number of provider capabilities per user.', true),
  ('work_profile_requires_kyc', null, 'true', 'boolean', 'provider',
   'Requires approved KYC status for work profile marketplace matching.', true),
  ('hire_person_needs_enabled', null, 'false', 'boolean', 'provider',
   'Allows posting hire-person Needs.', true)
on conflict (setting_key, coalesce(country, '__global__')) do update set
  setting_type = excluded.setting_type,
  category = excluded.category,
  description = excluded.description,
  is_public = excluded.is_public,
  updated_at = now();

commit;

-- ============================================================================
-- END MERGED SECTION (2/52): patch_provider_services_work_profiles.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (3/52): patch_enable_provider_work_profiles.sql
-- ============================================================================

-- ============================================================================
-- Patch: sql/patch_enable_provider_work_profiles.sql
-- Enables Provider Services v2 and Work Profiles in system_settings by default.
-- ============================================================================

INSERT INTO public.system_settings
  (setting_key, country, setting_value, setting_type, category, description, is_public)
VALUES
  ('capability_profiles_enabled', null, 'true', 'boolean', 'provider',
   'Enables Provider Services v2 multi-capability flow.', true),
  ('work_profiles_enabled', null, 'true', 'boolean', 'provider',
   'Enables Work Profiles and roles across categories.', true)
ON CONFLICT (setting_key, coalesce(country, '__global__')) DO UPDATE SET
  setting_value = excluded.setting_value,
  setting_type = excluded.setting_type,
  category = excluded.category,
  description = excluded.description,
  is_public = excluded.is_public,
  updated_at = now();

-- ============================================================================
-- END MERGED SECTION (3/52): patch_enable_provider_work_profiles.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (4/52): patch_loan_request_descriptions.sql
-- ============================================================================

-- Persist optional borrower-written context from the loan request form.
-- Safe to re-run.

begin;

alter table public.loan_requests
  add column if not exists description text;

comment on column public.loan_requests.description is
  'Optional borrower-provided context describing how loan funds will be used.';

create or replace view public.v_loan_listing_descriptions as
select
  lr.id as request_id,
  lr.description
from public.loan_requests lr
where lr.status = 'active'
  and not private.is_blocked_from_future_request(
    lr.borrower_id,
    auth.uid(),
    lr.listed_at
  );

comment on view public.v_loan_listing_descriptions is
  'Optional borrower-written context for active Loan Requests. Exposes no borrower identity or private income information and follows the active-listing block visibility rule.';

grant select on public.v_loan_listing_descriptions to authenticated, anon;

commit;

notify pgrst, 'reload schema';

-- ============================================================================
-- END MERGED SECTION (4/52): patch_loan_request_descriptions.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (5/52): patch_provider_category_type.sql
-- ============================================================================

-- Provider type preference, scoped privately to the owner and category.
-- Rollback: drop the RPCs and provider_category_profiles table.

create table if not exists public.provider_category_profiles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_slug text not null references public.need_categories(slug),
  provider_type text not null check (provider_type in ('individual', 'company')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, category_slug)
);

alter table public.provider_category_profiles enable row level security;
revoke all on public.provider_category_profiles from anon, authenticated;
grant select on public.provider_category_profiles to authenticated;
drop policy if exists pcp_owner_select on public.provider_category_profiles;
create policy pcp_owner_select on public.provider_category_profiles
  for select to authenticated using (user_id = auth.uid());
drop policy if exists pcp_admin_select on public.provider_category_profiles;
create policy pcp_admin_select on public.provider_category_profiles
  for select to authenticated using (private.is_admin());

create or replace function private.set_provider_category_type_internal(
  p_category_slug text, p_provider_type text
) returns void
language plpgsql security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_old text;
  v_enabled text;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if p_provider_type is null or p_provider_type not in ('individual', 'company') then
    raise exception 'Invalid provider type' using errcode = 'P0214';
  end if;
  if p_category_slug is null or p_category_slug = 'financial_services'
    or not exists (select 1 from public.need_categories where slug = p_category_slug) then
    raise exception 'Unknown or retired provider category' using errcode = 'P0214';
  end if;
  select setting_value into v_enabled from public.system_settings
   where setting_key = 'capability_profiles_enabled' and is_public = true limit 1;
  if coalesce(lower(v_enabled), 'false') not in ('true', '1') then
    raise exception 'Provider capability profiles are disabled' using errcode = 'P0214';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_user::text, 0));
  select provider_type into v_old from public.provider_category_profiles
   where user_id = v_user and category_slug = p_category_slug for update;
  if v_old is not distinct from p_provider_type then return; end if;

  -- Per-user limit: reuse the audit trail to throttle changed preference writes.
  if (select count(*) from public.audit_logs
       where user_id = v_user and entity_type = 'provider_category_profile'
         and created_at > now() - interval '1 minute') >= 20 then
    raise exception 'Please wait before changing provider type again' using errcode = 'P0214';
  end if;
  insert into public.provider_category_profiles(user_id, category_slug, provider_type)
    values (v_user, p_category_slug, p_provider_type)
  on conflict (user_id, category_slug) do update
    set provider_type = excluded.provider_type, updated_at = now();
  insert into public.audit_logs(user_id, event_type, entity_type, action, old_values, new_values)
    values (v_user, 'admin_action', 'provider_category_profile', 'set_provider_category_type',
      case when v_old is null then null else jsonb_build_object('category_slug', p_category_slug, 'provider_type', v_old) end,
      jsonb_build_object('category_slug', p_category_slug, 'provider_type', p_provider_type));
end;
$$;
revoke all on function private.set_provider_category_type_internal(text, text) from public, anon;
grant execute on function private.set_provider_category_type_internal(text, text) to authenticated;

create or replace function public.set_provider_category_type(
  p_category_slug text, p_provider_type text
) returns void language plpgsql security invoker
set search_path = public, private, pg_temp
as $$ begin
  perform private.set_provider_category_type_internal(p_category_slug, p_provider_type);
end; $$;
revoke all on function public.set_provider_category_type(text, text) from public, anon;
grant execute on function public.set_provider_category_type(text, text) to authenticated;

create or replace function public.get_my_provider_category_types()
returns table(category_slug text, provider_type text)
language sql stable security invoker
set search_path = public, pg_temp
as $$
  select p.category_slug, p.provider_type
  from public.provider_category_profiles p
  where p.user_id = auth.uid()
  order by p.category_slug;
$$;
revoke all on function public.get_my_provider_category_types() from public, anon;
grant execute on function public.get_my_provider_category_types() to authenticated;

-- Provider type eligibility. Individual profiles may keep old service rows, but
-- those rows cannot be newly saved, shown publicly, matched, or offered against.
create or replace function public.save_provider_capabilities(
  p_items jsonb default '[]'::jsonb,
  p_category_slug text default null,
  p_remove_slugs text[] default array[]::text[]
) returns setof public.provider_capabilities
language plpgsql security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_type text;
  v_is_work boolean;
  v_max int := 30;
  v_count int;
  v_item record;
  v_incoming text[] := array[]::text[];
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if jsonb_typeof(coalesce(p_items, '[]'::jsonb)) <> 'array' then
    raise exception 'Invalid capability selection' using errcode = 'P0215';
  end if;
  if p_category_slug is not null then
    select provider_type into v_type from public.provider_category_profiles
     where user_id = v_user and category_slug = p_category_slug;
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb)) as x(capability_slug text, metadata jsonb)
  loop
    if v_item.capability_slug is null then
      raise exception 'Invalid capability for category' using errcode = 'P0215';
    end if;
    select pcp.provider_type, nc.capability_type = 'work' into v_type, v_is_work
      from public.need_capabilities nc left join public.provider_category_profiles pcp
        on pcp.user_id = v_user and pcp.category_slug = nc.category_slug
      where nc.slug = v_item.capability_slug
        and (p_category_slug is null or nc.category_slug = p_category_slug);
    if not found then raise exception 'Invalid capability for category' using errcode = 'P0215'; end if;
    if not coalesce(v_is_work, false) and coalesce(v_type, 'company') = 'individual' then
      raise exception 'Individual providers cannot save company services' using errcode = 'P0215';
    end if;
    v_incoming := array_append(v_incoming, v_item.capability_slug);
  end loop;
  select coalesce(nullif(setting_value, '')::int, 30) into v_max
    from public.system_settings where setting_key = 'max_provider_capabilities'
      and (country is null or country = '__global__') limit 1;
  select count(*) into v_count from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where pc.user_id = v_user and (
      (p_category_slug is not null and nc.category_slug <> p_category_slug)
      or (p_category_slug is null and not (pc.capability_slug = any(coalesce(p_remove_slugs, array[]::text[]))))
      or (p_category_slug is not null and coalesce(v_type, 'company') = 'individual'
          and nc.capability_type = 'service' and nc.category_slug = p_category_slug)
    );
  if v_count + cardinality(v_incoming) > coalesce(v_max, 30) then
    raise exception 'Maximum limit of % provider capabilities reached.', coalesce(v_max, 30) using errcode = 'P0206';
  end if;
  if coalesce(cardinality(p_remove_slugs), 0) > 0 then
    delete from public.provider_capabilities where user_id = v_user and capability_slug = any(p_remove_slugs);
  end if;
  if p_category_slug is not null then
    delete from public.provider_capabilities pc using public.need_capabilities nc
     where pc.capability_slug = nc.slug and pc.user_id = v_user and nc.category_slug = p_category_slug
       and not (pc.capability_slug = any(v_incoming))
       and (coalesce(v_type, 'company') <> 'individual' or nc.capability_type = 'work');
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb)) as x(capability_slug text, metadata jsonb)
  loop
    insert into public.provider_capabilities(user_id, capability_slug, verification_level, metadata, created_at)
      values (v_user, v_item.capability_slug, 'self_declared', coalesce(v_item.metadata, '{}'::jsonb), now())
    on conflict (user_id, capability_slug) do update set metadata = case
      when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb then excluded.metadata
      else public.provider_capabilities.metadata end;
  end loop;
  return query select * from public.provider_capabilities where user_id = v_user;
end;
$$;
grant execute on function public.save_provider_capabilities(jsonb, text, text[]) to authenticated;

create or replace view public.v_provider_badges as
select pc.user_id, pc.capability_slug, nc.name as capability_name,
       nc.category_slug, cat.name as category_name, cat.icon as category_icon,
       pc.verification_level, coalesce(k.status = 'approved', false) as kyc_verified,
       p.phone_verified_at is not null as phone_verified
from public.provider_capabilities pc
join public.need_capabilities nc on nc.slug = pc.capability_slug
join public.need_categories cat on cat.slug = nc.category_slug
join public.profiles p on p.id = pc.user_id
left join public.kyc_verifications k on k.user_id = pc.user_id
left join public.provider_category_profiles pcp on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
where nc.capability_type = 'work' or coalesce(pcp.provider_type, 'company') <> 'individual';

create or replace function public.get_provider_opportunities(p_user_id uuid default null, p_limit int default 20)
returns table(capability_slug text, capability_name text, category_slug text, category_name text,
 category_icon text, open_needs_count bigint, latest_need_id uuid, latest_need_title text,
 latest_need_budget bigint, latest_need_currency text, latest_need_location text,
 latest_need_created_at timestamptz)
language plpgsql security definer set search_path = public, private, pg_temp as $$
declare v_caller uuid := coalesce(p_user_id, auth.uid());
begin
 if v_caller is null then return; end if;
 return query
 with user_caps as (
  select pc.capability_slug, nc.name capability_name, nc.category_slug,
         cat.name category_name, cat.icon category_icon
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  join public.need_categories cat on cat.slug = nc.category_slug
  left join public.provider_category_profiles pcp on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
  where pc.user_id = v_caller
    and (nc.capability_type = 'work' or coalesce(pcp.provider_type, 'company') <> 'individual')
 ), matching_needs as (
  select uc.capability_slug, nr.request_id, nr.title, nr.budget, nr.currency, nr.location, nr.listed_at
  from user_caps uc join public.needs_requests nr
   on nr.capability_slug = uc.capability_slug or (nr.capability_slug is null and nr.category_slug = uc.category_slug)
  where nr.status = 'active' and nr.requester_id is distinct from v_caller
   and (nr.expires_at is null or nr.expires_at > now())
   and not exists(select 1 from public.need_offers nof where nof.need_id = nr.request_id and nof.offer_maker_id = v_caller)
 ), capability_counts as (
  select mn.capability_slug, count(*) cnt, max(mn.listed_at) max_listed from matching_needs mn group by mn.capability_slug
 )
 select uc.capability_slug, uc.capability_name, uc.category_slug, uc.category_name, uc.category_icon,
   cc.cnt, latest.request_id, latest.title, latest.budget, latest.currency, latest.location, latest.listed_at
 from capability_counts cc join user_caps uc on uc.capability_slug = cc.capability_slug
 cross join lateral(select mn.request_id,mn.title,mn.budget,mn.currency,mn.location,mn.listed_at from matching_needs mn
   where mn.capability_slug = cc.capability_slug order by mn.listed_at desc limit 1) latest
 order by cc.cnt desc, latest.listed_at desc limit p_limit;
end; $$;
grant execute on function public.get_provider_opportunities(uuid, int) to authenticated;

-- Keep the existing offer-validation checks while excluding retained hidden services.
create or replace function private.trg_validate_need_offer()
returns trigger language plpgsql security definer set search_path = public, private, pg_temp as $$
declare
 v_need record; v_plan text; v_offer_count_month int; v_free_offer_cap int := 3;
 v_has_capability boolean := false; v_capability public.provider_capabilities%rowtype;
 v_check jsonb; v_match_score int;
begin
 perform private.require_identity_verified(new.offer_maker_id);
 select * into v_need from public.needs_requests where request_id = new.need_id;
 if not found then raise exception 'Need request not found' using errcode = 'P0201'; end if;
 if v_need.status <> 'active' or (v_need.expires_at is not null and v_need.expires_at <= now()) then
  raise exception 'Cannot offer on inactive or expired need request' using errcode = 'P0202'; end if;
 if v_need.requester_id = new.offer_maker_id then raise exception 'Cannot make an offer on your own need request' using errcode = 'P0205'; end if;
 v_check := private.check_verification_requirement(new.offer_maker_id,'need_offer',v_need.category_slug,v_need.capability_slug);
 if not coalesce((v_check->>'allowed')::boolean,false) then raise exception 'Cannot make offer: %',v_check->>'reason' using errcode = 'P0203'; end if;
 if v_need.capability_slug is not null then
  select pc.* into v_capability from public.provider_capabilities pc join public.need_capabilities nc on nc.slug=pc.capability_slug
  left join public.provider_category_profiles pcp on pcp.user_id=pc.user_id and pcp.category_slug=nc.category_slug
  where pc.user_id=new.offer_maker_id and pc.capability_slug=v_need.capability_slug
   and (nc.capability_type = 'work' or coalesce(pcp.provider_type,'company') <> 'individual') limit 1;
 else
  select pc.* into v_capability from public.provider_capabilities pc join public.need_capabilities nc on nc.slug=pc.capability_slug
  left join public.provider_category_profiles pcp on pcp.user_id=pc.user_id and pcp.category_slug=nc.category_slug
  where pc.user_id=new.offer_maker_id and nc.category_slug=v_need.category_slug
   and (nc.capability_type = 'work' or coalesce(pcp.provider_type,'company') <> 'individual')
  order by pc.created_at desc limit 1;
 end if;
 v_has_capability := found;
 if not v_has_capability then raise exception 'You must declare an eligible capability in this category before making offers' using errcode='P0203'; end if;
 if coalesce(v_need.details->>'engagement','')='hire_person' then
  v_match_score := private.capability_match_score(coalesce(v_need.details,'{}'::jsonb),coalesce(v_capability.metadata,'{}'::jsonb));
  if v_match_score <= 0 then raise exception 'Your service profile does not match the requested role or kind' using errcode='P0203'; end if;
 end if;
 select subscription_plan into v_plan from public.profiles where id=new.offer_maker_id;
 if coalesce(v_plan,'free')='free' then
  select coalesce(nullif(setting_value,'')::int,3) into v_free_offer_cap from public.system_settings where setting_key='needs_free_offers_per_month' and country is null;
  select count(*) into v_offer_count_month from public.need_offers where offer_maker_id=new.offer_maker_id and created_at >= date_trunc('month',now());
  if v_offer_count_month >= v_free_offer_cap then raise exception 'Free plan limit of % offers/month reached. Upgrade to make unlimited offers.',v_free_offer_cap using errcode='P0204'; end if;
 end if;
 new.terms_locked_at := coalesce(new.terms_locked_at,now()); return new;
end; $$;

-- ============================================================================
-- END MERGED SECTION (5/52): patch_provider_category_type.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (6/52): patch_provider_capability_evidence_security.sql
-- ============================================================================

-- Harden capability evidence submission while retaining the existing review model.
-- Safe to re-run. Evidence stays private and only admins can write review state.
begin;

alter table public.verification_requirements
  add column if not exists provider_type text not null default 'both';
alter table public.provider_capability_evidence
  add column if not exists provider_type text not null default 'both';

drop policy if exists "provider evidence owner insert" on public.provider_capability_evidence;
drop policy if exists "provider evidence owner resubmit" on public.provider_capability_evidence;
drop policy if exists "provider evidence admin all" on public.provider_capability_evidence;
drop policy if exists "provider evidence owner select" on public.provider_capability_evidence;
create policy "provider evidence admin all"
  on public.provider_capability_evidence for all to authenticated
  using (private.is_admin()) with check (private.is_admin());
create policy "provider evidence owner select"
  on public.provider_capability_evidence for select to authenticated
  using (exists (select 1 from public.provider_capabilities pc
    where pc.id = provider_capability_evidence.provider_capability_id
      and (pc.user_id = auth.uid() or private.is_admin())));
revoke all on public.provider_capability_evidence from anon, public;
revoke insert, update, delete on public.provider_capability_evidence from authenticated;
grant select on public.provider_capability_evidence to authenticated;

create or replace function public.submit_provider_capability_evidence(
  p_provider_capability_id uuid,
  p_requirement_key text,
  p_file_url text
) returns uuid
language plpgsql security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_capability_slug text;
  v_category_slug text;
  v_id uuid;
  v_key text := btrim(coalesce(p_requirement_key, ''));
  v_path text := btrim(coalesce(p_file_url, ''));
  v_scope_type text;
  v_scope_id text;
  v_provider_type text := 'both';
  v_rule_provider_type text := 'both';
  v_allowed boolean := false;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  select pc.capability_slug, nc.category_slug into v_capability_slug, v_category_slug
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where pc.id = p_provider_capability_id and pc.user_id = v_user;
  if not found then raise exception 'Provider capability not found for current user.' using errcode = '42501'; end if;
  if v_key = '' or v_path = '' then raise exception 'Evidence key and object path are required.' using errcode = '22023'; end if;

  select coalesce(p.provider_type, 'both') into v_provider_type
    from public.provider_category_profiles p
    where p.user_id = v_user and p.category_slug = v_category_slug;
  v_provider_type := coalesce(v_provider_type, 'both');

  select 'capability', v_capability_slug into v_scope_type, v_scope_id
    where exists (select 1 from public.verification_requirements r
      where r.scope_type = 'capability' and r.scope_id = v_capability_slug and r.is_active
        and r.provider_type in (v_provider_type, 'both'));
  if not found then
    select 'category', v_category_slug into v_scope_type, v_scope_id
      where exists (select 1 from public.verification_requirements r
        where r.scope_type = 'category' and r.scope_id = v_category_slug and r.is_active
          and r.provider_type in (v_provider_type, 'both'));
  end if;
  select case when exists (
      select 1 from public.verification_requirements r
      where r.scope_type = v_scope_type and r.scope_id = v_scope_id
        and r.provider_type = v_provider_type and r.is_active
    ) then v_provider_type else 'both' end into v_rule_provider_type;
  select exists (
    select 1 from public.verification_requirements r
    where r.is_active and r.scope_type = v_scope_type and r.scope_id = v_scope_id
      and r.provider_type = v_rule_provider_type and (
      v_key = any(coalesce(r.required_evidence, array[]::text[]))
      or exists (select 1 from jsonb_array_elements_text(
        case when jsonb_typeof(r.evidence_requirements) = 'array' then r.evidence_requirements else '[]'::jsonb end
      ) x(value) where x.value = v_key)
    )
  ) into v_allowed;
  if not v_allowed then raise exception 'Evidence type is not configured for this capability.' using errcode = '22023'; end if;

  if v_path not like 'evidence/' || v_user::text || '/' || v_capability_slug || '/%' then
    raise exception 'Evidence object path must belong to the current user and capability.' using errcode = '42501';
  end if;
  -- Storage ownership metadata can be absent on some Storage deployments.
  -- The path is already bound to auth.uid() above, and the bucket's INSERT
  -- policy only permits authenticated users to upload into their own folder.
  if not exists (select 1 from storage.objects o
    where o.bucket_id = 'provider-evidence'
      and o.name = v_path
      and (storage.foldername(o.name))[1] = 'evidence'
      and (storage.foldername(o.name))[2] = v_user::text) then
    raise exception 'Private evidence upload not found for current user.' using errcode = '42501';
  end if;

  insert into public.provider_capability_evidence(
    provider_capability_id, requirement_key, file_url, status, provider_type
  ) values (p_provider_capability_id, v_key, v_path, 'pending', v_provider_type)
    returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.submit_provider_capability_evidence(uuid, text, text) from public, anon;
grant execute on function public.submit_provider_capability_evidence(uuid, text, text) to authenticated;

-- Keep the existing admin review flow, but include category-level configured
-- evidence and ensure an explicit admin approval promotes only this capability.
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
  v_approved_count int := 0;
  v_scope_type text;
  v_scope_id text;
  v_provider_type text := 'both';
  v_rule_provider_type text := 'both';
  v_expiry_days integer;
  v_review_expiry timestamptz;
begin
  if not private.is_admin() then
    raise exception 'Unauthorized: Admin access required' using errcode = '42501';
  end if;
  if p_action not in ('approve', 'reject', 'expire') then
    raise exception 'Invalid evidence review action.' using errcode = '22023';
  end if;
  select e.*, pc.user_id as provider_user_id, pc.capability_slug, nc.category_slug into v_evidence
    from public.provider_capability_evidence e
    join public.provider_capabilities pc on pc.id = e.provider_capability_id
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where e.id = p_evidence_id for update of e;
  if not found then raise exception 'Provider capability evidence not found.' using errcode = 'P0212'; end if;

  v_provider_type := coalesce(v_evidence.provider_type, 'both');

  update public.provider_capability_evidence set
    status = case when p_action = 'approve' then 'approved' when p_action = 'reject' then 'rejected' else 'expired' end,
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
  v_required := coalesce(v_required, array[]::text[]);

  select r.expires_after_days into v_expiry_days
    from public.verification_requirements r
    where r.scope_type = v_scope_type and r.scope_id = v_scope_id and r.is_active
      and r.provider_type = v_rule_provider_type
    order by (r.provider_type = v_provider_type) desc
    limit 1;
  v_review_expiry := coalesce(p_expires_at,
    case when v_expiry_days is not null then now() + make_interval(days => v_expiry_days) end);
  if p_action = 'approve' and p_expires_at is null and v_review_expiry is not null then
    update public.provider_capability_evidence
      set expires_at = v_review_expiry where id = p_evidence_id;
  end if;

  if p_action = 'approve' then
    -- Admin approval completes the badge for this exact capability.
    update public.provider_capabilities set verification_level = 'provider_verified',
      verified_by = v_admin, verified_at = now()
      where id = v_evidence.provider_capability_id;
  elsif p_action in ('reject', 'expire')
      and not exists (
        select 1 from public.provider_capability_evidence e
        where e.provider_capability_id = v_evidence.provider_capability_id
          and e.id <> p_evidence_id and e.status = 'approved'
          and (e.expires_at is null or e.expires_at > now())
      )
      and not exists (
        select 1 from public.provider_role_qualification_claims claim
        where claim.provider_capability_id = v_evidence.provider_capability_id
          and claim.status = 'verified'
          and (claim.expires_at is null or claim.expires_at > now())
      ) then
    update public.provider_capabilities set verification_level = 'self_declared',
      verified_by = null, verified_at = null where id = v_evidence.provider_capability_id;
  end if;

  insert into public.audit_logs(user_id, event_type, entity_type, entity_id, action, new_values)
  values (v_admin, 'admin_action', 'provider_capability_evidence', p_evidence_id,
    'review_provider_capability_evidence', jsonb_build_object(
      'action', p_action, 'provider_capability_id', v_evidence.provider_capability_id,
      'capability_slug', v_evidence.capability_slug, 'requirement_key', v_evidence.requirement_key,
      'provider_type', v_provider_type, 'reject_reason', p_reject_reason,
      'expires_at', v_review_expiry));
  return true;
end;
$$;
revoke all on function public.admin_review_provider_capability_evidence(uuid, text, text, timestamptz) from public, anon;
grant execute on function public.admin_review_provider_capability_evidence(uuid, text, text, timestamptz) to authenticated;

-- Keep the capability badge synchronized with any current, administrator-
-- approved proof attached to that capability, regardless of evidence type.
create or replace function private.sync_provider_capability_badge_from_approved_evidence()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_reviewer uuid;
  v_reviewed_at timestamptz;
begin
  if exists (
    select 1
    from public.provider_capability_evidence evidence
    where evidence.provider_capability_id = new.provider_capability_id
      and evidence.status = 'approved'
      and (evidence.expires_at is null or evidence.expires_at > now())
    union all
    select 1
    from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = new.provider_capability_id
      and claim.is_claimed
      and claim.status = 'verified'
      and (claim.expires_at is null or claim.expires_at > now())
  ) then
    select approved.reviewer, approved.reviewed_at
    into v_reviewer, v_reviewed_at
    from (
      select evidence.reviewed_by as reviewer, evidence.reviewed_at
      from public.provider_capability_evidence evidence
      where evidence.provider_capability_id = new.provider_capability_id
        and evidence.status = 'approved'
        and (evidence.expires_at is null or evidence.expires_at > now())
      union all
      select claim.reviewed_by as reviewer, claim.reviewed_at
      from public.provider_role_qualification_claims claim
      where claim.provider_capability_id = new.provider_capability_id
        and claim.is_claimed
        and claim.status = 'verified'
        and (claim.expires_at is null or claim.expires_at > now())
    ) approved
    order by approved.reviewed_at desc nulls last
    limit 1;

    update public.provider_capabilities
    set verification_level = 'provider_verified',
        verified_by = coalesce(v_reviewer, new.reviewed_by, auth.uid()),
        verified_at = coalesce(v_reviewed_at, new.reviewed_at, now())
    where id = new.provider_capability_id;
  else
    update public.provider_capabilities
    set verification_level = 'self_declared',
        verified_by = null,
        verified_at = null
    where id = new.provider_capability_id
      and verification_level = 'provider_verified';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_provider_capability_badge_from_approved_evidence
  on public.provider_capability_evidence;
create trigger trg_sync_provider_capability_badge_from_approved_evidence
  after insert or update of status, expires_at
  on public.provider_capability_evidence
  for each row
  execute function private.sync_provider_capability_badge_from_approved_evidence();

-- Also complete badges for evidence approved before this patch is installed.
with approvals as (
  select evidence.provider_capability_id, evidence.reviewed_by, evidence.reviewed_at
  from public.provider_capability_evidence evidence
  where evidence.status = 'approved'
    and (evidence.expires_at is null or evidence.expires_at > now())
  union all
  select claim.provider_capability_id, claim.reviewed_by, claim.reviewed_at
  from public.provider_role_qualification_claims claim
  where claim.is_claimed and claim.status = 'verified'
    and (claim.expires_at is null or claim.expires_at > now())
), latest_approval as (
  select distinct on (provider_capability_id)
    provider_capability_id, reviewed_by, reviewed_at
  from approvals
  order by provider_capability_id, reviewed_at desc nulls last
)
update public.provider_capabilities capability
set verification_level = 'provider_verified',
    verified_by = latest_approval.reviewed_by,
    verified_at = coalesce(latest_approval.reviewed_at, now())
from latest_approval
where capability.id = latest_approval.provider_capability_id;

commit;

-- ============================================================================
-- END MERGED SECTION (6/52): patch_provider_capability_evidence_security.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (7/52): patch_company_provider_path.sql
-- ============================================================================

-- Company provider category path: private profile, atomic service-only save,
-- and capability-specific evidence fan-out. Safe to rerun; this patch is additive.
begin;

alter table public.verification_requirements
  add column if not exists provider_type text not null default 'both';
alter table public.provider_capability_evidence
  add column if not exists provider_type text not null default 'both';

create table if not exists public.provider_company_profiles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_slug text not null references public.need_categories(slug) on delete cascade,
  company_name text check (char_length(company_name) <= 80),
  registration_number text check (char_length(registration_number) <= 40),
  team_size text check (team_size is null or team_size in ('1-5','6-20','21-50','50+')),
  years_in_business text check (years_in_business is null or years_in_business in ('<1','1-2','3-5','6-10','10+')),
  service_areas text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, category_slug)
);

alter table public.provider_company_profiles enable row level security;
revoke all on public.provider_company_profiles from public, anon, authenticated;
grant select on public.provider_company_profiles to authenticated;
drop policy if exists provider_company_profile_owner_select on public.provider_company_profiles;
create policy provider_company_profile_owner_select
  on public.provider_company_profiles for select to authenticated
  using (user_id = auth.uid());
drop policy if exists provider_company_profile_admin_select on public.provider_company_profiles;
create policy provider_company_profile_admin_select
  on public.provider_company_profiles for select to authenticated
  using (private.is_admin());

-- Move details from the previous Company review form into the private table,
-- then remove those values from capability metadata where summaries/views may
-- expose them. Re-running is safe because the profile insert is conflict-safe
-- and the metadata cleanup is idempotent.
with legacy_company_details as (
  select distinct on (pc.user_id, nc.category_slug)
    pc.user_id,
    nc.category_slug,
    nullif(btrim(pc.metadata->>'organization_name'), '') as company_name,
    nullif(btrim(pc.metadata->>'business_registration'), '') as registration_number
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  join public.provider_category_profiles pcp
    on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
  where pcp.provider_type = 'company'
    and (pc.metadata ? 'organization_name' or pc.metadata ? 'business_registration')
  order by pc.user_id, nc.category_slug, pc.created_at desc
), migrated as (
  insert into public.provider_company_profiles(
    user_id, category_slug, company_name, registration_number
  )
  select user_id, category_slug, company_name, registration_number
    from legacy_company_details
  on conflict (user_id, category_slug) do update set
    company_name = coalesce(provider_company_profiles.company_name, excluded.company_name),
    registration_number = coalesce(provider_company_profiles.registration_number, excluded.registration_number)
  returning user_id, category_slug
)
insert into public.audit_logs(user_id, event_type, entity_type, action, new_values)
select user_id, 'admin_action', 'provider_company_profile',
  'migrate_legacy_company_details',
  jsonb_build_object('category_slug', category_slug, 'source', 'capability_metadata')
from migrated;

update public.provider_capabilities pc
set metadata = coalesce(pc.metadata, '{}'::jsonb)
  - array['organization_name', 'business_registration', 'portfolio_url']::text[]
where coalesce(pc.metadata, '{}'::jsonb) ?| array[
  'organization_name', 'business_registration', 'portfolio_url'
];

create or replace function private.touch_provider_company_profile_updated_at()
returns trigger language plpgsql set search_path = public, pg_temp as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
drop trigger if exists trg_provider_company_profile_updated_at
  on public.provider_company_profiles;
create trigger trg_provider_company_profile_updated_at
  before update on public.provider_company_profiles
  for each row execute function private.touch_provider_company_profile_updated_at();

create or replace function private.save_company_category_internal(
  p_category_slug text,
  p_services text[],
  p_roles text[],
  p_profile jsonb,
  p_evidence jsonb
) returns void
language plpgsql security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_country text;
  v_type text;
  v_enabled text;
  v_limit integer := 30;
  v_count integer;
  v_services text[] := coalesce(p_services, array[]::text[]);
  v_roles text[] := coalesce(p_roles, array[]::text[]);
  v_service text;
  v_item jsonb;
  v_key text;
  v_path text;
  v_size bigint;
  v_mime text;
  v_recent_uploads integer := 0;
  v_profile jsonb := coalesce(p_profile, '{}'::jsonb);
  v_areas text[] := array[]::text[];
  v_old_profile jsonb;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  if p_category_slug is null or btrim(p_category_slug) = '' then
    raise exception 'A provider category is required.' using errcode = 'P0201';
  end if;
  if jsonb_typeof(v_profile) <> 'object'
     or jsonb_typeof(coalesce(p_evidence, '[]'::jsonb)) <> 'array' then
    raise exception 'Company profile or evidence payload is invalid.' using errcode = 'P0201';
  end if;
  if cardinality(v_services) <> cardinality(array(select distinct x from unnest(v_services) x))
     or cardinality(v_roles) <> cardinality(array(select distinct x from unnest(v_roles) x))
     or v_services && v_roles then
    raise exception 'Duplicate or conflicting provider selections.' using errcode = 'P0201';
  end if;
  if cardinality(v_roles) > 0 then
    raise exception 'Company providers can select services only.' using errcode = 'P0201';
  end if;
  if cardinality(v_services) = 0 then
    raise exception 'Select at least one service.' using errcode = 'P0201';
  end if;
  if not exists (select 1 from public.need_categories c
    where c.slug = p_category_slug and c.is_active) then
    raise exception 'This provider category is not active.' using errcode = 'P0201';
  end if;
  select country into v_country from public.profiles where id = v_user;
  if not found then raise exception 'Provider profile is unavailable.' using errcode = 'P0201'; end if;
  select provider_type into v_type from public.provider_category_profiles
    where user_id = v_user and category_slug = p_category_slug;
  if v_type is distinct from 'company' then
    raise exception 'Choose Company / Organization for this category first.' using errcode = 'P0202';
  end if;

  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled' and is_public
      and (country = v_country or country is null)
    order by (country = v_country) desc nulls last limit 1;
  if lower(coalesce(v_enabled, 'false')) not in ('true', '1') then
    raise exception 'Provider services are not enabled in your market.' using errcode = 'P0202';
  end if;
  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled_' || p_category_slug and is_public
      and (country = v_country or country is null)
    order by (country = v_country) desc nulls last limit 1;
  if lower(coalesce(v_enabled, 'true')) in ('false', '0') then
    raise exception 'This provider category is not enabled in your market.' using errcode = 'P0202';
  end if;

  foreach v_service in array v_services loop
    if not exists (select 1 from public.need_capabilities nc
      where nc.slug = v_service and nc.category_slug = p_category_slug
        and nc.is_active and nc.capability_type = 'service') then
      raise exception 'A selected service is invalid for this category.' using errcode = 'P0203';
    end if;
  end loop;
  if length(coalesce(v_profile->>'company_name', '')) > 80
     or length(coalesce(v_profile->>'registration_number', '')) > 40
     or (v_profile ? 'team_size' and v_profile->>'team_size' not in ('1-5','6-20','21-50','50+'))
     or (v_profile ? 'years_in_business' and v_profile->>'years_in_business' not in ('<1','1-2','3-5','6-10','10+'))
     or (v_profile ? 'service_areas' and jsonb_typeof(v_profile->'service_areas') <> 'array') then
    raise exception 'Company profile details are invalid.' using errcode = 'P0204';
  end if;
  select coalesce(array_agg(distinct btrim(value)), array[]::text[]) into v_areas
    from jsonb_array_elements_text(coalesce(v_profile->'service_areas', '[]'::jsonb)) x(value)
    where btrim(value) <> '';
  if exists (select 1 from unnest(v_areas) area where length(area) > 80) then
    raise exception 'Service areas must be district or city names.' using errcode = 'P0204';
  end if;

  select coalesce(nullif(setting_value, '')::integer, 30) into v_limit
    from public.system_settings
    where setting_key = 'max_provider_capabilities'
      and (country = v_country or country is null)
    order by (country = v_country) desc nulls last limit 1;
  v_limit := coalesce(v_limit, 30);
  select count(*) into v_count
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where pc.user_id = v_user
      and (nc.category_slug <> p_category_slug or nc.capability_type = 'work');
  if v_count + cardinality(v_services) > v_limit then
    raise exception 'Maximum limit of % provider capabilities reached.', v_limit using errcode = 'P0206';
  end if;

  if jsonb_array_length(coalesce(p_evidence, '[]'::jsonb)) > 0 then
    select count(distinct e.file_url) into v_recent_uploads
      from public.provider_capability_evidence e
      join public.provider_capabilities pc on pc.id = e.provider_capability_id
      where pc.user_id = v_user and e.created_at > now() - interval '1 hour';
    if v_recent_uploads >= 20 then
      raise exception 'Evidence upload limit reached. Try again later.' using errcode = 'P0213';
    end if;
  end if;

  -- The Company path edits services only. Existing personal work profiles in
  -- this category remain unchanged and are never presented as Company roles.
  delete from public.provider_capabilities pc using public.need_capabilities nc
    where pc.capability_slug = nc.slug and pc.user_id = v_user
      and nc.category_slug = p_category_slug and nc.capability_type = 'service'
      and not (pc.capability_slug = any(v_services));

  foreach v_service in array v_services loop
    insert into public.provider_capabilities(user_id, capability_slug, verification_level, metadata, created_at)
      values (v_user, v_service, 'self_declared', '{}'::jsonb, now())
    on conflict (user_id, capability_slug) do update
      set verification_level = case when provider_capabilities.verification_level = 'provider_verified'
        then provider_capabilities.verification_level else 'self_declared' end;
  end loop;
  select to_jsonb(cp) into v_old_profile from public.provider_company_profiles cp
    where cp.user_id = v_user and cp.category_slug = p_category_slug;
  insert into public.provider_company_profiles(
    user_id, category_slug, company_name, registration_number, team_size,
    years_in_business, service_areas
  ) values (
    v_user, p_category_slug, nullif(btrim(v_profile->>'company_name'), ''),
    nullif(btrim(v_profile->>'registration_number'), ''),
    nullif(v_profile->>'team_size', ''), nullif(v_profile->>'years_in_business', ''), v_areas
  ) on conflict(user_id, category_slug) do update set
    company_name = excluded.company_name,
    registration_number = excluded.registration_number,
    team_size = excluded.team_size,
    years_in_business = excluded.years_in_business,
    service_areas = excluded.service_areas,
    updated_at = now();

  for v_item in select value from jsonb_array_elements(coalesce(p_evidence, '[]'::jsonb))
  loop
    v_key := btrim(coalesce(v_item->>'requirement_key', ''));
    v_path := btrim(coalesce(v_item->>'file_path', ''));
    if v_key = '' or v_path = '' or
       v_path not like 'evidence/' || v_user::text || '/' || p_category_slug || '/%' then
      raise exception 'Company evidence path or requirement is invalid.' using errcode = 'P0205';
    end if;
    if not exists (
      select 1 from public.verification_requirements r
      where r.is_active and (
        r.provider_type = 'company' or (r.provider_type = 'both' and not exists (
          select 1 from public.verification_requirements specific
          where specific.scope_type = r.scope_type and specific.scope_id = r.scope_id
            and specific.provider_type = 'company' and specific.is_active
        ))
      ) and (
        (r.scope_type = 'category' and r.scope_id = p_category_slug)
        or (r.scope_type = 'capability' and r.scope_id = any(v_services))
      ) and (
        v_key = any(coalesce(r.required_evidence, array[]::text[]))
        or exists (select 1 from jsonb_array_elements_text(
              case when jsonb_typeof(r.evidence_requirements) = 'array'
                then r.evidence_requirements else '[]'::jsonb end
            ) ev(value)
              where ev.value = v_key))
      ) then
      raise exception 'Evidence type is not required for selected company services.' using errcode = 'P0205';
    end if;
    select (o.metadata->>'size')::bigint, lower(coalesce(o.metadata->>'mimetype', ''))
      into v_size, v_mime from storage.objects o
      where o.bucket_id = 'provider-evidence' and o.name = v_path and o.owner_id = v_user::text;
    if not found then
      raise exception 'Uploaded evidence file is not owned by this provider.' using errcode = 'P0205';
    end if;
    if v_size is null or v_size > 5242880 or v_mime not in ('image/jpeg', 'image/png', 'application/pdf') then
      raise exception 'Evidence must be JPG, PNG, or PDF and no larger than 5 MB.' using errcode = 'P0205';
    end if;
    for v_service in select unnest(v_services) loop
      if exists (
        select 1 from public.verification_requirements r
        where r.is_active and (
          r.provider_type = 'company' or (r.provider_type = 'both' and not exists (
            select 1 from public.verification_requirements specific
            where specific.scope_type = r.scope_type and specific.scope_id = r.scope_id
              and specific.provider_type = 'company' and specific.is_active
          ))
        ) and (
          (r.scope_type = 'category' and r.scope_id = p_category_slug)
          or (r.scope_type = 'capability' and r.scope_id = v_service)
        ) and (
          v_key = any(coalesce(r.required_evidence, array[]::text[]))
          or exists (select 1 from jsonb_array_elements_text(
                case when jsonb_typeof(r.evidence_requirements) = 'array'
                  then r.evidence_requirements else '[]'::jsonb end
              ) ev(value)
                where ev.value = v_key))
        ) then
        insert into public.provider_capability_evidence(
          provider_capability_id, requirement_key, file_url, status, provider_type
        )
        select pc.id, v_key, v_path, 'pending', 'company'
          from public.provider_capabilities pc
          where pc.user_id = v_user and pc.capability_slug = v_service
            and not exists (select 1 from public.provider_capability_evidence e
              where e.provider_capability_id = pc.id and e.requirement_key = v_key
                and e.file_url = v_path);
      end if;
    end loop;
  end loop;

  insert into public.audit_logs(user_id, event_type, entity_type, action, old_values, new_values)
  values (v_user, 'admin_action', 'provider_company_profile', 'save_company_category',
    v_old_profile,
    jsonb_build_object('category_slug', p_category_slug,
      'services', to_jsonb(v_services), 'roles', to_jsonb(v_roles),
      'service_count', cardinality(v_services), 'role_count', cardinality(v_roles)));
end;
$$;
revoke all on function private.save_company_category_internal(text, text[], text[], jsonb, jsonb)
  from public, anon;
grant execute on function private.save_company_category_internal(text, text[], text[], jsonb, jsonb)
  to authenticated;
grant usage on schema private to authenticated;

create or replace function public.save_company_category(
  p_category_slug text,
  p_services text[] default array[]::text[],
  p_roles text[] default array[]::text[],
  p_profile jsonb default '{}'::jsonb,
  p_evidence jsonb default '[]'::jsonb
) returns void
language plpgsql security invoker
set search_path = public, private, pg_temp
as $$
begin
  perform private.save_company_category_internal(
    p_category_slug, p_services, p_roles, p_profile, p_evidence
  );
end;
$$;
revoke all on function public.save_company_category(text, text[], text[], jsonb, jsonb)
  from public, anon;
grant execute on function public.save_company_category(text, text[], text[], jsonb, jsonb)
  to authenticated;

-- Keep shared evidence objects until the final capability-specific reference is removed.
create or replace function private.delete_orphan_provider_evidence_object()
returns trigger language plpgsql security definer
set search_path = public, storage, pg_temp as $$
begin
  if not exists (select 1 from public.provider_capability_evidence e where e.file_url = old.file_url) then
    delete from storage.objects o where o.bucket_id = 'provider-evidence' and o.name = old.file_url;
  end if;
  return old;
end;
$$;
drop trigger if exists trg_delete_orphan_provider_evidence_object
  on public.provider_capability_evidence;
create trigger trg_delete_orphan_provider_evidence_object
  after delete on public.provider_capability_evidence
  for each row execute function private.delete_orphan_provider_evidence_object();

commit;

-- Verification after applying to staging:
-- select relrowsecurity from pg_class where oid = 'public.provider_company_profiles'::regclass;
-- select policyname, cmd, roles from pg_policies where tablename = 'provider_company_profiles';
-- select proname, prosecdef from pg_proc where proname = 'save_company_category';
-- Rollback: drop the RPC and private helper/trigger/functions, then drop
-- provider_company_profiles. Existing company capability rows remain untouched.

-- ============================================================================
-- END MERGED SECTION (7/52): patch_company_provider_path.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (8/52): patch_provider_type_verification_matrix.sql
-- ============================================================================

-- Capability-level provider proof rules by provider type.
-- Apply after patch_provider_services_work_profiles.sql and
-- patch_provider_category_type.sql. Safe to rerun.
begin;

alter table public.verification_requirements
  add column if not exists provider_type text not null default 'both';

alter table public.provider_capability_evidence
  add column if not exists provider_type text not null default 'both';
alter table public.provider_capability_evidence
  drop constraint if exists provider_capability_evidence_provider_type_check;
alter table public.provider_capability_evidence
  add constraint provider_capability_evidence_provider_type_check
    check (provider_type in ('both', 'individual', 'company'));

alter table public.verification_requirements
  drop constraint if exists verification_requirements_provider_type_check;
alter table public.verification_requirements
  add constraint verification_requirements_provider_type_check
    check (provider_type in ('both', 'individual', 'company'));

-- Replace legacy uniqueness so a capability may have separate company and
-- individual requirements while preserving all existing rows as `both`.
alter table public.verification_requirements
  drop constraint if exists verification_requirements_scope_type_scope_id_key;
create unique index if not exists verification_requirements_scope_type_scope_id_provider_type_uidx
  on public.verification_requirements(scope_type, scope_id, provider_type);

comment on column public.verification_requirements.provider_type is
  'Provider type this evidence rule applies to: both, individual, or company.';

-- Do not make every listing require a licence. These are service-specific
-- gates. General categories continue to use self-declared status and optional
-- portfolio/references. Company rules require organization evidence and (when
-- relevant) proof of named qualified staff; individual rules require the
-- provider''s own credential. Expiring licences are reviewed annually.
insert into public.verification_requirements (
  scope_type, scope_id, provider_type, identity_required, phone_required,
  provider_verification_required, evidence_requirements, required_evidence,
  expires_after_days, is_active
) values
  ('capability','legal_services','individual',true,false,true,
   '["practising_certificate"]'::jsonb,array['practising_certificate'],365,true),
  ('capability','legal_services','company',true,false,true,
   '["law_firm_approval","named_advocate_practising_certificate"]'::jsonb,
   array['law_firm_approval','named_advocate_practising_certificate'],365,true),
  ('capability','company_registration','individual',true,false,true,
   '["company_secretarial_or_legal_practice_credential"]'::jsonb,
   array['company_secretarial_or_legal_practice_credential'],365,true),
  ('capability','company_registration','company',true,false,true,
   '["business_registration","named_qualified_company_secretary_or_advocate"]'::jsonb,
   array['business_registration','named_qualified_company_secretary_or_advocate'],365,true),
  ('capability','accounting_tax','individual',true,false,true,
   '["icpau_practising_certificate"]'::jsonb,array['icpau_practising_certificate'],365,true),
  ('capability','accounting_tax','company',true,false,true,
   '["icpau_firm_licence","named_accountant_practising_certificate"]'::jsonb,
   array['icpau_firm_licence','named_accountant_practising_certificate'],365,true),
  ('capability','architecture','individual',true,false,true,
   '["architect_registration_and_current_practising_certificate"]'::jsonb,
   array['architect_registration_and_current_practising_certificate'],365,true),
  ('capability','architecture','company',true,false,true,
   '["architecture_firm_registration","named_architect_practising_certificate"]'::jsonb,
   array['architecture_firm_registration','named_architect_practising_certificate'],365,true),
  ('capability','engineering','individual',true,false,true,
   '["engineer_registration_and_current_practising_certificate"]'::jsonb,
   array['engineer_registration_and_current_practising_certificate'],365,true),
  ('capability','engineering','company',true,false,true,
   '["engineering_firm_registration","named_engineer_practising_certificate"]'::jsonb,
   array['engineering_firm_registration','named_engineer_practising_certificate'],365,true),
  ('capability','surveying','individual',true,false,true,
   '["surveyor_registration_and_practising_certificate"]'::jsonb,
   array['surveyor_registration_and_practising_certificate'],365,true),
  ('capability','surveying','company',true,false,true,
   '["surveying_firm_registration","named_surveyor_practising_certificate"]'::jsonb,
   array['surveying_firm_registration','named_surveyor_practising_certificate'],365,true),
  ('capability','electrical_works','individual',true,false,true,
   '["era_installation_permit"]'::jsonb,array['era_installation_permit'],365,true),
  ('capability','electrical_works','company',true,false,true,
   '["era_company_installation_permit","named_installer_era_permit"]'::jsonb,
   array['era_company_installation_permit','named_installer_era_permit'],365,true),
  ('capability','electrical_installation','individual',true,false,true,
   '["era_installation_permit"]'::jsonb,array['era_installation_permit'],365,true),
  ('capability','electrical_installation','company',true,false,true,
   '["era_company_installation_permit","named_installer_era_permit"]'::jsonb,
   array['era_company_installation_permit','named_installer_era_permit'],365,true),
  ('capability','solar_systems','individual',true,false,true,
   '["era_solar_installation_permit_or_recognized_installer_certificate"]'::jsonb,
   array['era_solar_installation_permit_or_recognized_installer_certificate'],365,true),
  ('capability','solar_systems','company',true,false,true,
   '["era_company_permit_or_solar_business_authorization","named_solar_installer_credentials"]'::jsonb,
   array['era_company_permit_or_solar_business_authorization','named_solar_installer_credentials'],365,true),
  ('capability','building_contractors','individual',true,false,true,
   '["contractor_registration_or_trade_competency"]'::jsonb,
   array['contractor_registration_or_trade_competency'],365,true),
  ('capability','building_contractors','company',true,false,true,
   '["nbrb_contractor_registration","business_trading_licence","named_registered_professional_if_required"]'::jsonb,
   array['nbrb_contractor_registration','business_trading_licence','named_registered_professional_if_required'],365,true),
  ('capability','roofing','individual',true,false,true,
   '["roofing_trade_competency","work_at_height_safety_training"]'::jsonb,
   array['roofing_trade_competency','work_at_height_safety_training'],365,true),
  ('capability','roofing','company',true,false,true,
   '["contractor_registration_or_business_trading_licence","worker_safety_procedure"]'::jsonb,
   array['contractor_registration_or_business_trading_licence','worker_safety_procedure'],365,true),
  ('capability','concrete','individual',true,false,true,
   '["concrete_or_structural_trade_competency"]'::jsonb,
   array['concrete_or_structural_trade_competency'],365,true),
  ('capability','concrete','company',true,false,true,
   '["contractor_registration","named_registered_structural_professional_if_required"]'::jsonb,
   array['contractor_registration','named_registered_structural_professional_if_required'],365,true),
  ('capability','plumbing','individual',true,false,true,
   '["plumbing_trade_competency"]'::jsonb,array['plumbing_trade_competency'],365,true),
  ('capability','plumbing','company',true,false,true,
   '["plumbing_business_or_contractor_registration","named_qualified_plumber"]'::jsonb,
   array['plumbing_business_or_contractor_registration','named_qualified_plumber'],365,true),
  ('capability','excavation','individual',true,false,true,
   '["excavation_equipment_operator_competency"]'::jsonb,
   array['excavation_equipment_operator_competency'],365,true),
  ('capability','excavation','company',true,false,true,
   '["contractor_registration_or_trade_competency","equipment_ownership_or_hire_authority"]'::jsonb,
   array['contractor_registration_or_trade_competency','equipment_ownership_or_hire_authority'],365,true),
  ('capability','heavy_haulage','individual',true,false,true,
   '["correct_class_driving_licence","psv_or_operator_authorization_if_applicable"]'::jsonb,
   array['correct_class_driving_licence','psv_or_operator_authorization_if_applicable'],365,true),
  ('capability','heavy_haulage','company',true,false,true,
   '["transport_operator_licence","vehicle_registration_and_insurance"]'::jsonb,
   array['transport_operator_licence','vehicle_registration_and_insurance'],365,true),
  ('capability','driving_school_driver_training','individual',true,false,true,
   '["authorized_driving_instructor_credential"]'::jsonb,
   array['authorized_driving_instructor_credential'],365,true),
  ('capability','driving_school_driver_training','company',true,false,true,
   '["driving_school_licence","authorized_instructor_credentials","training_vehicle_documents"]'::jsonb,
   array['driving_school_licence','authorized_instructor_credentials','training_vehicle_documents'],365,true),
  ('capability','cargo_transport','individual',true,false,true,
   '["correct_class_driving_licence"]'::jsonb,array['correct_class_driving_licence'],365,true),
  ('capability','cargo_transport','company',true,false,true,
   '["transport_operator_licence","vehicle_registration_and_insurance"]'::jsonb,
   array['transport_operator_licence','vehicle_registration_and_insurance'],365,true),
  ('capability','truck_hire','individual',true,false,true,
   '["correct_class_driving_licence"]'::jsonb,array['correct_class_driving_licence'],365,true),
  ('capability','truck_hire','company',true,false,true,
   '["vehicle_registration_and_insurance","transport_operator_licence_if_applicable"]'::jsonb,
   array['vehicle_registration_and_insurance','transport_operator_licence_if_applicable'],365,true),
  ('capability','event_transport','individual',true,false,true,
   '["correct_class_driving_licence","psv_authorization_if_applicable"]'::jsonb,
   array['correct_class_driving_licence','psv_authorization_if_applicable'],365,true),
  ('capability','event_transport','company',true,false,true,
   '["vehicle_registration_and_insurance","transport_operator_licence_if_applicable"]'::jsonb,
   array['vehicle_registration_and_insurance','transport_operator_licence_if_applicable'],365,true),
  ('capability','excavator_hire','individual',true,false,true,
   '["excavator_operator_competency","equipment_ownership_or_hire_authority"]'::jsonb,
   array['excavator_operator_competency','equipment_ownership_or_hire_authority'],365,true),
  ('capability','excavator_hire','company',true,false,true,
   '["fleet_photos","ownership_or_logbook","operator_competency_if_operator_supplied"]'::jsonb,
   array['fleet_photos','ownership_or_logbook','operator_competency_if_operator_supplied'],365,true),
  ('capability','loader_hire','individual',true,false,true,
   '["loader_operator_competency","equipment_ownership_or_hire_authority"]'::jsonb,
   array['loader_operator_competency','equipment_ownership_or_hire_authority'],365,true),
  ('capability','loader_hire','company',true,false,true,
   '["fleet_photos","ownership_or_logbook","operator_competency_if_operator_supplied"]'::jsonb,
   array['fleet_photos','ownership_or_logbook','operator_competency_if_operator_supplied'],365,true),
  ('capability','grader_hire','individual',true,false,true,
   '["grader_operator_competency","equipment_ownership_or_hire_authority"]'::jsonb,
   array['grader_operator_competency','equipment_ownership_or_hire_authority'],365,true),
  ('capability','grader_hire','company',true,false,true,
   '["fleet_photos","ownership_or_logbook","operator_competency_if_operator_supplied"]'::jsonb,
   array['fleet_photos','ownership_or_logbook','operator_competency_if_operator_supplied'],365,true),
  ('capability','crane_hire','individual',true,false,true,
   '["crane_operator_competency","equipment_ownership_or_hire_authority"]'::jsonb,
   array['crane_operator_competency','equipment_ownership_or_hire_authority'],365,true),
  ('capability','crane_hire','company',true,false,true,
   '["fleet_photos","ownership_or_logbook","operator_competency_if_operator_supplied"]'::jsonb,
   array['fleet_photos','ownership_or_logbook','operator_competency_if_operator_supplied'],365,true),
  ('capability','visa_assistance','individual',true,false,true,
   '["licensed_travel_agency_authorization_or_employment_proof"]'::jsonb,
   array['licensed_travel_agency_authorization_or_employment_proof'],365,true),
  ('capability','visa_assistance','company',true,false,true,
   '["licensed_travel_agency_registration","business_licence"]'::jsonb,
   array['licensed_travel_agency_registration','business_licence'],365,true),
  ('capability','hajj_umrah','individual',true,false,true,
   '["authorized_hajj_operator_affiliation"]'::jsonb,
   array['authorized_hajj_operator_affiliation'],365,true),
  ('capability','hajj_umrah','company',true,false,true,
   '["hajj_operator_accreditation","business_licence"]'::jsonb,
   array['hajj_operator_accreditation','business_licence'],365,true),
  ('capability','seeds_inputs','individual',true,false,true,
   '["agrochemical_dealer_or_handler_authorization_if_applicable"]'::jsonb,
   array['agrochemical_dealer_or_handler_authorization_if_applicable'],365,true),
  ('capability','seeds_inputs','company',true,false,true,
   '["registered_agro_input_dealer_and_premises_if_applicable","product_registration_for_regulated_inputs"]'::jsonb,
   array['registered_agro_input_dealer_and_premises_if_applicable','product_registration_for_regulated_inputs'],365,true),
  ('capability','catering','individual',true,false,true,
   '["food_handler_health_certificate"]'::jsonb,array['food_handler_health_certificate'],365,true),
  ('capability','catering','company',true,false,true,
   '["food_business_health_permit","food_handler_certificates_for_food_staff"]'::jsonb,
   array['food_business_health_permit','food_handler_certificates_for_food_staff'],365,true)
on conflict (scope_type, scope_id, provider_type) do update set
  identity_required = excluded.identity_required,
  phone_required = excluded.phone_required,
  provider_verification_required = excluded.provider_verification_required,
  evidence_requirements = excluded.evidence_requirements,
  required_evidence = excluded.required_evidence,
  expires_after_days = excluded.expires_after_days,
  is_active = excluded.is_active,
  updated_at = now();

-- Specific rows override any older generic rule for the same capability.
update public.verification_requirements generic
set is_active = false, updated_at = now()
where generic.scope_type = 'capability'
  and generic.provider_type = 'both'
  and exists (
    select 1 from public.verification_requirements specific
    where specific.scope_type = generic.scope_type
      and specific.scope_id = generic.scope_id
      and specific.provider_type in ('individual','company')
      and specific.is_active
  );

-- Preserve pending proof ownership under the exact provider type it was
-- submitted for. This prevents a later type change from weakening review.
update public.provider_capability_evidence e
set provider_type = p.provider_type
from public.provider_capabilities pc
join public.need_capabilities nc on nc.slug = pc.capability_slug
join public.provider_category_profiles p
  on p.user_id = pc.user_id and p.category_slug = nc.category_slug
where e.provider_capability_id = pc.id
  and e.provider_type = 'both'
  and exists (
    select 1 from public.verification_requirements r
    where r.scope_type = 'capability'
      and r.scope_id = pc.capability_slug
      and r.provider_type = p.provider_type
      and r.is_active
  );

-- Remove the unsafe legacy travel sentinel and broad category-level proof rule;
-- travel verification is now configured against specific capabilities above.
update public.verification_requirements
set is_active = false, updated_at = now()
where (scope_type = 'category' and scope_id = 'travel_international')
   or (scope_type = 'capability' and scope_id = 'visa_assistance'
       and provider_type = 'both');

commit;

-- Rollback: deactivate the provider_type-specific rows, restore the prior
-- uniqueness constraint, then drop the provider_type column. Do not drop
-- evidence or provider capability records.

-- ============================================================================
-- END MERGED SECTION (8/52): patch_provider_type_verification_matrix.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (9/52): patch_provider_verification_policies.sql
-- ============================================================================

-- Configurable per-capability verification policies and separate company
-- document review. Apply after provider capability and evidence patches.
-- Safe to rerun; does not modify public listing or feed view signatures.
begin;

alter table public.need_capabilities
  add column if not exists verification_policy text not null default 'open';
alter table public.need_capabilities
  drop constraint if exists need_capabilities_verification_policy_check;
alter table public.need_capabilities
  add constraint need_capabilities_verification_policy_check
  check (verification_policy in ('open', 'optional_proof', 'required_proof'));

alter table public.provider_capabilities
  add column if not exists is_active boolean not null default true;
create index if not exists idx_provider_capabilities_active_slug
  on public.provider_capabilities(capability_slug, is_active);

create or replace function private.validate_provider_capability_evidence_object()
returns trigger language plpgsql security definer
set search_path = public, private, storage, pg_temp as $$
declare
  v_user uuid;
  v_slug text;
  v_owner text;
  v_size bigint;
  v_mime text;
begin
  select pc.user_id, pc.capability_slug into v_user, v_slug
  from public.provider_capabilities pc
  where pc.id = new.provider_capability_id;
  if not found then raise exception 'Provider capability not found.' using errcode = 'P0212'; end if;
  if new.file_url not like 'evidence/' || v_user::text || '/' || v_slug || '/%' then
    raise exception 'Evidence must use the provider capability folder.' using errcode = 'P0205';
  end if;
  select o.owner_id, (o.metadata->>'size')::bigint,
         lower(coalesce(o.metadata->>'mimetype', ''))
    into v_owner, v_size, v_mime
  from storage.objects o
  where o.bucket_id = 'provider-evidence' and o.name = new.file_url;
  if not found or v_owner is distinct from v_user::text then
    raise exception 'Evidence file is not owned by the capability provider.' using errcode = 'P0205';
  end if;
  if v_size is null or v_size < 1 or v_size > 5242880
     or v_mime not in ('image/jpeg', 'image/png', 'application/pdf') then
    raise exception 'Evidence must be JPG, PNG, or PDF and no larger than 5 MB.' using errcode = 'P0205';
  end if;
  return new;
end;
$$;
drop trigger if exists trg_validate_provider_capability_evidence_object
  on public.provider_capability_evidence;
create trigger trg_validate_provider_capability_evidence_object
  before insert or update of file_url, provider_capability_id
  on public.provider_capability_evidence
  for each row execute function private.validate_provider_capability_evidence_object();

-- Keep the initial matrix limited to individual capabilities where proof is
-- legally or operationally significant. Administrators may tune it later.
update public.need_capabilities
set verification_policy = 'required_proof'
where slug in (
  'legal_services', 'company_registration', 'accounting_tax',
  'architecture_services', 'architecture', 'engineering_consulting',
  'engineering', 'surveying', 'electrical_works', 'electrical_installation',
  'solar_systems', 'building_contractors', 'heavy_haulage', 'cargo_transport',
  'truck_hire', 'event_transport', 'driving_school_driver_training',
  'excavator_hire', 'loader_hire', 'grader_hire', 'crane_hire',
  'visa_assistance', 'hajj_umrah', 'seeds_inputs', 'catering'
) and verification_policy = 'open';
update public.need_capabilities
set verification_policy = 'optional_proof'
where slug in ('cybersecurity_services', 'cybersecurity')
  and verification_policy = 'open';

-- Ensure every configured policy has an upload key for the canonical catalog
-- slug, even where older verification rows use an alias.
insert into public.verification_requirements (
  scope_type, scope_id, provider_type, identity_required, phone_required,
  provider_verification_required, evidence_requirements, required_evidence,
  expires_after_days, is_active
)
select 'capability', nc.slug, 'both', true, false, true,
       jsonb_build_array(nc.slug || '_authorization'),
       array[nc.slug || '_authorization'], 365, true
from public.need_capabilities nc
where nc.verification_policy = 'required_proof'
  and not exists (
    select 1 from public.verification_requirements r
    where r.scope_type = 'capability' and r.scope_id = nc.slug and r.is_active
      and r.provider_type in ('both', 'individual', 'company')
  )
on conflict (scope_type, scope_id, provider_type) do nothing;

insert into public.verification_requirements (
  scope_type, scope_id, provider_type, identity_required, phone_required,
  provider_verification_required, evidence_requirements, required_evidence,
  expires_after_days, is_active
)
select 'capability', nc.slug, 'both', false, false, false,
       jsonb_build_array('security_certification_or_portfolio'),
       array[]::text[], null, true
from public.need_capabilities nc
where nc.verification_policy = 'optional_proof'
  and not exists (
    select 1 from public.verification_requirements r
    where r.scope_type = 'capability' and r.scope_id = nc.slug and r.is_active
      and r.provider_type in ('both', 'individual', 'company')
  )
on conflict (scope_type, scope_id, provider_type) do nothing;

-- Existing declarations in newly restricted capabilities remain saved, but
-- cannot be used until their per-capability evidence is approved.
update public.provider_capabilities pc
set is_active = false
from public.need_capabilities nc
where nc.slug = pc.capability_slug
  and nc.verification_policy = 'required_proof'
  and pc.verification_level <> 'provider_verified';

create table if not exists public.provider_company_verification_submissions (
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_slug text not null references public.need_categories(slug) on delete cascade,
  document_type text not null check (document_type in ('business_registration', 'business_licence')),
  file_path text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  reject_reason text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, category_slug, document_type)
);
alter table public.provider_company_verification_submissions enable row level security;
revoke all on public.provider_company_verification_submissions from public, anon, authenticated;
grant select on public.provider_company_verification_submissions to authenticated;
drop policy if exists provider_company_verification_owner_select
  on public.provider_company_verification_submissions;
create policy provider_company_verification_owner_select
  on public.provider_company_verification_submissions for select to authenticated
  using (user_id = auth.uid());
drop policy if exists provider_company_verification_admin_select
  on public.provider_company_verification_submissions;
create policy provider_company_verification_admin_select
  on public.provider_company_verification_submissions for select to authenticated
  using (private.is_admin());

create or replace function private.enforce_provider_capability_policy()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_category text;
  v_type text;
  v_policy text;
  v_admin boolean := private.is_admin();
begin
  select nc.category_slug, nc.verification_policy, nc.capability_type
    into v_category, v_policy, v_type
    from public.need_capabilities nc where nc.slug = new.capability_slug;
  if not found then
    raise exception 'Provider capability is unavailable.' using errcode = 'P0203';
  end if;
  if v_type = 'service' and exists (
    select 1 from public.provider_category_profiles pcp
    where pcp.user_id = new.user_id and pcp.category_slug = v_category
      and pcp.provider_type = 'individual'
  ) then
    raise exception 'Individual profiles cannot offer company services.' using errcode = 'P0214';
  end if;
  if v_policy = 'required_proof' then
    new.is_active := new.verification_level = 'provider_verified'
      and (v_admin or exists (
        select 1 from public.provider_capability_evidence e
        where e.provider_capability_id = new.id and e.status = 'approved'
          and (e.expires_at is null or e.expires_at > now())
      ));
  else
    new.is_active := true;
  end if;
  if not v_admin and new.verification_level = 'provider_verified' then
    if tg_op = 'UPDATE' and old.verification_level = 'provider_verified' then
      new.verified_by := old.verified_by;
      new.verified_at := old.verified_at;
    else
      new.verification_level := 'self_declared';
      new.verified_by := null;
      new.verified_at := null;
      if v_policy = 'required_proof' then new.is_active := false; end if;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_enforce_provider_capability_policy on public.provider_capabilities;
create trigger trg_enforce_provider_capability_policy
  before insert or update on public.provider_capabilities
  for each row execute function private.enforce_provider_capability_policy();

-- Preserve an existing admin grant when an owner edits capability metadata;
-- still reject any attempt to elevate an unverified row themselves.
create or replace function private.trg_enforce_provider_capability_verification()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_is_admin boolean := private.is_admin();
begin
  if not v_is_admin then
    if tg_op = 'UPDATE'
       and old.verification_level = 'provider_verified'
       and new.verification_level = 'provider_verified' then
      new.verification_level := old.verification_level;
      new.verified_by := old.verified_by;
      new.verified_at := old.verified_at;
    else
      new.verification_level := 'self_declared';
      new.verified_by := null;
      new.verified_at := null;
    end if;
  elsif new.verification_level = 'provider_verified'
        and (tg_op = 'INSERT' or old.verification_level <> 'provider_verified') then
    new.verified_by := auth.uid();
    new.verified_at := coalesce(new.verified_at, now());
  end if;
  return new;
end;
$$;

-- An approved, current capability evidence decision is the only event that can
-- activate a required-proof capability. A company document never touches this.
create or replace function private.refresh_provider_capability_policy_state()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_policy text;
  v_capability_type text;
  v_provider_type text := 'both';
  v_rule_provider_type text := 'both';
  v_required text[];
  v_approved text[];
begin
  select nc.verification_policy, nc.capability_type
    into v_policy, v_capability_type
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  where pc.id = new.provider_capability_id;
  if not found then return new; end if;

  select coalesce(pcp.provider_type, 'both') into v_provider_type
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  left join public.provider_category_profiles pcp
    on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
  where pc.id = new.provider_capability_id;
  if exists (
    select 1 from public.verification_requirements r
    join public.provider_capabilities pc on pc.id = new.provider_capability_id
    where r.scope_type = 'capability' and r.scope_id = pc.capability_slug
      and r.provider_type = v_provider_type and r.is_active
  ) then v_rule_provider_type := v_provider_type;
  else v_rule_provider_type := 'both'; end if;

  select coalesce(array_agg(distinct k), array[]::text[]) into v_required
  from (
    select unnest(coalesce(r.required_evidence, array[]::text[])) as k
    from public.verification_requirements r
    join public.provider_capabilities pc on pc.id = new.provider_capability_id
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where r.is_active and r.scope_type = 'capability' and r.scope_id = pc.capability_slug
      and r.provider_type = v_rule_provider_type
    union
    select jsonb_array_elements_text(case when jsonb_typeof(r.evidence_requirements) = 'array'
      then r.evidence_requirements else '[]'::jsonb end)
    from public.verification_requirements r
    join public.provider_capabilities pc on pc.id = new.provider_capability_id
    where r.is_active and r.scope_type = 'capability' and r.scope_id = pc.capability_slug
      and r.provider_type = v_rule_provider_type
  ) keys;
  select coalesce(array_agg(distinct e.requirement_key), array[]::text[]) into v_approved
  from public.provider_capability_evidence e
  where e.provider_capability_id = new.provider_capability_id
    and e.status = 'approved' and (e.expires_at is null or e.expires_at > now());

  if v_policy = 'required_proof' then
    if v_capability_type = 'work' and cardinality(v_required) > 0
       and v_approved @> v_required then
      update public.provider_capabilities pc set
        verification_level = 'provider_verified',
        verified_by = auth.uid(), verified_at = now(), is_active = true
      where pc.id = new.provider_capability_id;
    elsif new.status in ('pending', 'rejected', 'expired') then
      update public.provider_capabilities pc set
        verification_level = case when v_capability_type = 'work'
          then 'self_declared' else pc.verification_level end,
        verified_by = case when v_capability_type = 'work' then null else pc.verified_by end,
        verified_at = case when v_capability_type = 'work' then null else pc.verified_at end,
        is_active = false
      where pc.id = new.provider_capability_id;
    else
      update public.provider_capabilities pc set is_active = false
      where pc.id = new.provider_capability_id;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_refresh_provider_capability_policy_state
  on public.provider_capability_evidence;
create trigger trg_refresh_provider_capability_policy_state
  after insert or update of status, expires_at on public.provider_capability_evidence
  for each row execute function private.refresh_provider_capability_policy_state();

-- Qualification uploads in Individual F are mirrored to the common evidence
-- table so capability policy, status, and admin reporting share one source.
create or replace function private.sync_role_claim_to_capability_evidence()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_key text := new.qualification_slug;
  v_status text;
  v_provider_type text := 'both';
  v_category text;
begin
  if new.evidence_object_path is null or new.status not in
      ('pending_review', 'verified', 'rejected', 'expired') then
    return new;
  end if;
  v_status := case new.status
    when 'pending_review' then 'pending'
    when 'verified' then 'approved'
    when 'rejected' then 'rejected'
    else 'expired' end;
  select nc.category_slug, coalesce(pcp.provider_type, 'both')
    into v_category, v_provider_type
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  left join public.provider_category_profiles pcp
    on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
  where pc.id = new.provider_capability_id;

  update public.provider_capability_evidence set
    status = v_status, reject_reason = new.reject_reason,
    reviewed_by = new.reviewed_by, reviewed_at = new.reviewed_at,
    expires_at = new.expires_at, updated_at = now()
  where provider_capability_id = new.provider_capability_id
    and requirement_key = v_key and file_url = new.evidence_object_path;
  if not found then
    insert into public.provider_capability_evidence(
      provider_capability_id, requirement_key, file_url, status,
      reject_reason, expires_at, reviewed_by, reviewed_at, provider_type
    ) values (
      new.provider_capability_id, v_key, new.evidence_object_path, v_status,
      new.reject_reason, new.expires_at, new.reviewed_by, new.reviewed_at,
      v_provider_type
    );
  end if;
  return new;
end;
$$;
drop trigger if exists trg_sync_role_claim_to_capability_evidence
  on public.provider_role_qualification_claims;
create trigger trg_sync_role_claim_to_capability_evidence
  after insert or update of status, evidence_object_path
  on public.provider_role_qualification_claims
  for each row execute function private.sync_role_claim_to_capability_evidence();

create or replace function private.provider_capability_is_eligible(p_capability_id uuid)
returns boolean language plpgsql security definer stable
set search_path = public, private, pg_temp as $$
declare
  v_slug text;
  v_policy text;
  v_type text := 'both';
  v_rule_type text := 'both';
  v_active boolean;
  v_has_requirements boolean := false;
  v_key text;
begin
  select pc.capability_slug, nc.verification_policy, pc.is_active
    into v_slug, v_policy, v_active
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  where pc.id = p_capability_id;
  if not found or not v_active then return false; end if;
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
      select jsonb_array_elements_text(case when jsonb_typeof(r.evidence_requirements) = 'array'
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

create or replace function public.submit_provider_company_verification(
  p_category_slug text, p_document_type text, p_file_path text
) returns void language plpgsql security definer
set search_path = public, private, storage, pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_size bigint;
  v_mime text;
  v_country text;
  v_enabled text;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if p_document_type not in ('business_registration', 'business_licence') then
    raise exception 'Company verification document type is invalid.' using errcode = 'P0204';
  end if;
  if not exists (select 1 from public.provider_category_profiles pcp
    where pcp.user_id = v_user and pcp.category_slug = p_category_slug
      and pcp.provider_type = 'company') then
    raise exception 'Choose Company / Organization for this category first.' using errcode = 'P0202';
  end if;
  if not exists (select 1 from public.need_categories c
      where c.slug = p_category_slug and c.is_active) then
    raise exception 'This provider category is not active.' using errcode = 'P0201';
  end if;
  select country into v_country from public.profiles where id = v_user;
  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled' and is_public
      and (country = v_country or country is null)
    order by (country = v_country) desc nulls last limit 1;
  if lower(coalesce(v_enabled, 'false')) not in ('true', '1') then
    raise exception 'Provider services are not enabled in your market.' using errcode = 'P0202';
  end if;
  if p_file_path not like 'evidence/' || v_user::text || '/' || p_category_slug || '/company/%' then
    raise exception 'Company verification file path is invalid.' using errcode = 'P0205';
  end if;
  select (o.metadata->>'size')::bigint, lower(coalesce(o.metadata->>'mimetype', ''))
    into v_size, v_mime from storage.objects o
    where o.bucket_id = 'provider-evidence' and o.name = p_file_path
      and o.owner_id = v_user::text;
  if not found or v_size is null or v_size > 5242880
     or v_mime not in ('image/jpeg', 'image/png', 'application/pdf') then
    raise exception 'Company evidence must be an owned JPG, PNG, or PDF up to 5 MB.' using errcode = 'P0205';
  end if;
  insert into public.provider_company_verification_submissions(
    user_id, category_slug, document_type, file_path, status,
    reject_reason, reviewed_by, reviewed_at, created_at, updated_at
  ) values (v_user, p_category_slug, p_document_type, p_file_path, 'pending',
    null, null, null, now(), now())
  on conflict (user_id, category_slug, document_type) do update set
    file_path = excluded.file_path, status = 'pending', reject_reason = null,
    reviewed_by = null, reviewed_at = null, created_at = now(), updated_at = now();
  insert into public.audit_logs(user_id, event_type, entity_type, action, new_values)
  values (v_user, 'admin_action', 'provider_company_verification', 'submit_company_document',
    jsonb_build_object('category_slug', p_category_slug, 'document_type', p_document_type));
end;
$$;
revoke all on function public.submit_provider_company_verification(text, text, text)
  from public, anon;
grant execute on function public.submit_provider_company_verification(text, text, text)
  to authenticated;

create or replace function public.admin_review_provider_company_verification(
  p_user_id uuid, p_category_slug text, p_document_type text,
  p_action text, p_reject_reason text default null
) returns boolean language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_admin uuid := auth.uid();
  v_row public.provider_company_verification_submissions%rowtype;
begin
  if not private.is_admin() then raise exception 'Admin access required.' using errcode = '42501'; end if;
  if p_action not in ('approve', 'reject') then
    raise exception 'Invalid company verification action.' using errcode = 'P0204';
  end if;
  if p_action = 'reject' and nullif(btrim(p_reject_reason), '') is null then
    raise exception 'A rejection reason is required.' using errcode = 'P0204';
  end if;
  update public.provider_company_verification_submissions set
    status = case when p_action = 'approve' then 'approved' else 'rejected' end,
    reject_reason = case when p_action = 'reject' then left(btrim(p_reject_reason), 300) else null end,
    reviewed_by = v_admin, reviewed_at = now(), updated_at = now()
  where user_id = p_user_id and category_slug = p_category_slug
    and document_type = p_document_type
  returning * into v_row;
  if not found then raise exception 'Company verification submission not found.' using errcode = 'P0212'; end if;
  insert into public.audit_logs(user_id, event_type, entity_type, action, old_values, new_values)
  values (v_admin, 'admin_action', 'provider_company_verification',
    'review_company_document', null,
    jsonb_build_object('provider_user_id', p_user_id, 'category_slug', p_category_slug,
      'document_type', p_document_type, 'action', p_action,
      'reject_reason', p_reject_reason, 'reviewed_at', now()));
  return true;
end;
$$;
revoke all on function public.admin_review_provider_company_verification(uuid, text, text, text, text)
  from public, anon;
grant execute on function public.admin_review_provider_company_verification(uuid, text, text, text, text)
  to authenticated;

-- Private provider-facing status view: append policy and activity fields while
-- preserving all existing columns and their order for current clients.
create or replace view public.v_my_capability_policy_status
with (security_invoker = true) as
select v.*, nc.verification_policy,
       pc.is_active and private.provider_capability_is_eligible(pc.id) as is_active
from public.v_my_capability_status v
join public.provider_capabilities pc on pc.id = v.provider_capability_id
join public.need_capabilities nc on nc.slug = pc.capability_slug;
grant select on public.v_my_capability_policy_status to authenticated;

-- Filter private matching results without changing RPC columns or grants.
create or replace function public.get_provider_opportunities(p_user_id uuid default null, p_limit int default 20)
returns table(capability_slug text, capability_name text, category_slug text, category_name text,
 category_icon text, open_needs_count bigint, latest_need_id uuid, latest_need_title text,
 latest_need_budget bigint, latest_need_currency text, latest_need_location text,
 latest_need_created_at timestamptz)
language plpgsql security definer set search_path = public, private, pg_temp as $$
declare v_caller uuid := coalesce(p_user_id, auth.uid());
begin
 if v_caller is null or (v_caller <> auth.uid() and not private.is_admin()) then return; end if;
 return query
 with user_caps as (
  select pc.capability_slug, nc.name capability_name, nc.category_slug,
         cat.name category_name, cat.icon category_icon
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  join public.need_categories cat on cat.slug = nc.category_slug
  left join public.provider_category_profiles pcp
    on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
  where pc.user_id = v_caller and private.provider_capability_is_eligible(pc.id)
    and (nc.capability_type = 'work' or coalesce(pcp.provider_type, 'company') <> 'individual')
 ), matching_needs as (
  select uc.capability_slug, nr.request_id, nr.title, nr.budget, nr.currency, nr.location, nr.listed_at
  from user_caps uc join public.needs_requests nr
   on nr.capability_slug = uc.capability_slug or (nr.capability_slug is null and nr.category_slug = uc.category_slug)
  where nr.status = 'active' and nr.requester_id is distinct from v_caller
   and (nr.expires_at is null or nr.expires_at > now())
   and not exists(select 1 from public.need_offers nof where nof.need_id = nr.request_id and nof.offer_maker_id = v_caller)
 ), capability_counts as (
  select mn.capability_slug, count(*) cnt, max(mn.listed_at) max_listed
  from matching_needs mn group by mn.capability_slug
 )
 select uc.capability_slug, uc.capability_name, uc.category_slug, uc.category_name, uc.category_icon,
   cc.cnt, latest.request_id, latest.title, latest.budget, latest.currency, latest.location, latest.listed_at
 from capability_counts cc join user_caps uc on uc.capability_slug = cc.capability_slug
 cross join lateral(select mn.request_id,mn.title,mn.budget,mn.currency,mn.location,mn.listed_at
   from matching_needs mn where mn.capability_slug = cc.capability_slug
   order by mn.listed_at desc limit 1) latest
 order by cc.cnt desc, latest.listed_at desc limit p_limit;
end; $$;
revoke all on function public.get_provider_opportunities(uuid, int) from public, anon;
grant execute on function public.get_provider_opportunities(uuid, int) to authenticated;

-- The existing need-offer validator remains intact; this additive gate keeps
-- inactive restricted capabilities from being used even via direct RPC calls.
create or replace function private.require_active_provider_capability_for_offer()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare v_need public.needs_requests%rowtype;
begin
  select * into v_need from public.needs_requests where request_id = new.need_id;
  if not found then return new; end if;
  if not exists (
    select 1 from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where pc.user_id = new.offer_maker_id
      and private.provider_capability_is_eligible(pc.id)
      and (pc.capability_slug = v_need.capability_slug
        or (v_need.capability_slug is null and nc.category_slug = v_need.category_slug))
      and (nc.capability_type = 'work' or not exists (
        select 1 from public.provider_category_profiles pcp
        where pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
          and pcp.provider_type = 'individual'
      ))
  ) then
    raise exception 'An active provider capability is required to make this offer.' using errcode = 'P0215';
  end if;
  return new;
end;
$$;
drop trigger if exists trg_need_offer_requires_active_provider_capability on public.need_offers;
create trigger trg_need_offer_requires_active_provider_capability
  before insert on public.need_offers
  for each row execute function private.require_active_provider_capability_for_offer();

create or replace view public.v_provider_badges as
select pc.user_id, pc.capability_slug, nc.name as capability_name,
       nc.category_slug, cat.name as category_name, cat.icon as category_icon,
       pc.verification_level, coalesce(k.status = 'approved', false) as kyc_verified,
       p.phone_verified_at is not null as phone_verified
from public.provider_capabilities pc
join public.need_capabilities nc on nc.slug = pc.capability_slug
join public.need_categories cat on cat.slug = nc.category_slug
join public.profiles p on p.id = pc.user_id
left join public.kyc_verifications k on k.user_id = pc.user_id
left join public.provider_category_profiles pcp
  on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
where private.provider_capability_is_eligible(pc.id)
  and (nc.capability_type = 'work' or coalesce(pcp.provider_type, 'company') <> 'individual');

-- Company documents are submitted and reviewed separately from service
-- capability evidence. Ignore any legacy fan-out payload on the older RPC.
create or replace function public.save_company_category(
  p_category_slug text,
  p_services text[] default array[]::text[],
  p_roles text[] default array[]::text[],
  p_profile jsonb default '{}'::jsonb,
  p_evidence jsonb default '[]'::jsonb
) returns void language plpgsql security invoker
set search_path = public, private, pg_temp as $$
begin
  perform private.save_company_category_internal(
    p_category_slug, p_services, p_roles, p_profile, '[]'::jsonb
  );
end;
$$;
revoke all on function public.save_company_category(text, text[], text[], jsonb, jsonb)
  from public, anon;
grant execute on function public.save_company_category(text, text[], text[], jsonb, jsonb)
  to authenticated;

commit;

-- Staging checks: table RLS, RPC grants, trigger execution, policy transitions,
-- offer rejection for inactive service, and owner/admin/other user document access.

-- ============================================================================
-- END MERGED SECTION (9/52): patch_provider_verification_policies.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (10/52): patch_provider_identity_switch.sql
-- ============================================================================

-- Category-specific provider identity switching. Additive and safe to rerun.
-- Apply only after patch_provider_category_type.sql,
-- patch_company_provider_path.sql and patch_provider_verification_policies.sql.
begin;

alter table public.provider_category_profiles
  add column if not exists identity_changed_at timestamptz;

alter table public.provider_capabilities
  add column if not exists identity_type text;
alter table public.provider_capabilities
  drop constraint if exists provider_capabilities_identity_type_check;
alter table public.provider_capabilities
  add constraint provider_capabilities_identity_type_check
  check (identity_type is null or identity_type in ('individual','company'));

-- Keep the verification policy calculation, but let the identity guard below
-- retain legacy Individual service rows as inactive instead of aborting every
-- update to them. The previous policy trigger rejected the row before it
-- could be made inactive, which also blocked Company -> Individual switches.
create or replace function private.enforce_provider_capability_policy()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_category text;
  v_policy text;
  v_type text;
  v_admin boolean := private.is_admin();
begin
  select nc.category_slug, nc.verification_policy, nc.capability_type
    into v_category, v_policy, v_type
    from public.need_capabilities nc where nc.slug = new.capability_slug;
  if not found then
    raise exception 'Provider capability is unavailable.' using errcode = 'P0203';
  end if;
  if v_policy = 'required_proof' then
    new.is_active := new.verification_level = 'provider_verified'
      and (v_admin or exists (
        select 1 from public.provider_capability_evidence e
        where e.provider_capability_id = new.id and e.status = 'approved'
          and (e.expires_at is null or e.expires_at > now())
      ));
  else
    new.is_active := true;
  end if;
  if not v_admin and new.verification_level = 'provider_verified' then
    if tg_op = 'UPDATE' and old.verification_level = 'provider_verified' then
      new.verified_by := old.verified_by;
      new.verified_at := old.verified_at;
    else
      new.verification_level := 'self_declared';
      new.verified_by := null;
      new.verified_at := null;
      if v_policy = 'required_proof' then new.is_active := false; end if;
    end if;
  end if;
  return new;
end;
$$;

-- Apply identity ownership and inactive-state enforcement before the backfill,
-- so migration updates are evaluated under the same identity rules as writes.
create or replace function private.enforce_provider_identity_capability()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare v_category text; v_kind text; v_current text;
begin
  select category_slug,capability_type into v_category,v_kind
    from public.need_capabilities where slug=new.capability_slug;
  if v_kind='service' then
    if tg_op='UPDATE' and old.identity_type is not null
       and new.identity_type is distinct from old.identity_type
       and not private.is_admin() then
      raise exception 'A service identity cannot be changed directly.' using errcode='P0216';
    end if;
    select provider_type into v_current from public.provider_category_profiles
      where user_id=new.user_id and category_slug=v_category;
    if new.identity_type is null then new.identity_type:=coalesce(v_current,'company'); end if;
    if new.identity_type not in ('individual','company') then
      raise exception 'Invalid capability identity.' using errcode='P0216';
    end if;
    -- Individual providers offer personal roles, not company service tiles.
    if new.is_active and (v_current='individual' or new.identity_type is distinct from v_current) then
      new.is_active:=false;
    end if;
  else
    new.identity_type:=null;
  end if;
  return new;
end;
$$;
revoke all on function private.enforce_provider_identity_capability() from public,anon,authenticated;
drop trigger if exists trg_z_enforce_provider_identity_capability on public.provider_capabilities;
create trigger trg_z_enforce_provider_identity_capability
  before insert or update on public.provider_capabilities
  for each row execute function private.enforce_provider_identity_capability();

-- Work-role capabilities belong to the person's own profile. Service rows are
-- identity-bound; legacy rows inherit the category's saved identity.
update public.provider_capabilities pc
set identity_type = coalesce((select pcp.provider_type from public.provider_category_profiles pcp
  where pcp.user_id=pc.user_id and pcp.category_slug=nc.category_slug limit 1),'company')
from public.need_capabilities nc
where nc.slug = pc.capability_slug and nc.capability_type = 'service'
  and pc.identity_type is null;
create index if not exists provider_capabilities_identity_scope_idx
  on public.provider_capabilities(user_id, identity_type, capability_slug)
  where identity_type is not null;

create table if not exists public.provider_identity_presentations (
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_slug text not null references public.need_categories(slug) on delete cascade,
  identity_type text not null check (identity_type in ('individual','company')),
  display_mode text not null check (display_mode in ('personal','company','company_with_representative')),
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  representative_name text check (representative_name is null or char_length(representative_name) <= 80),
  representative_authorized boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, category_slug, identity_type),
  check ((identity_type = 'individual' and display_mode = 'personal') or
         (identity_type = 'company' and display_mode in ('company','company_with_representative'))),
  check (display_mode <> 'company_with_representative' or
         (representative_authorized and nullif(btrim(representative_name), '') is not null))
);
alter table public.provider_identity_presentations enable row level security;
revoke all on public.provider_identity_presentations from public, anon, authenticated;
grant select on public.provider_identity_presentations to authenticated;
drop policy if exists provider_identity_presentation_owner_select
  on public.provider_identity_presentations;
create policy provider_identity_presentation_owner_select
  on public.provider_identity_presentations for select to authenticated
  using (user_id = auth.uid());
drop policy if exists provider_identity_presentation_admin_select
  on public.provider_identity_presentations;
create policy provider_identity_presentation_admin_select
  on public.provider_identity_presentations for select to authenticated
  using (private.is_admin());

alter table public.need_offers
  add column if not exists provider_identity_type text,
  add column if not exists provider_display_name text;
alter table public.need_contact_reveals
  add column if not exists provider_identity_type text,
  add column if not exists provider_display_name text;
alter table public.need_offers drop constraint if exists need_offers_provider_identity_type_check;
alter table public.need_offers add constraint need_offers_provider_identity_type_check
  check (provider_identity_type is null or provider_identity_type in ('individual','company'));
alter table public.need_contact_reveals drop constraint if exists need_contact_reveals_provider_identity_type_check;
alter table public.need_contact_reveals add constraint need_contact_reveals_provider_identity_type_check
  check (provider_identity_type is null or provider_identity_type in ('individual','company'));

-- Existing profile type changes must go through the atomic switch RPC below.
create or replace function private.set_provider_category_type_internal(
  p_category_slug text, p_provider_type text
) returns void language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_old text;
  v_enabled text;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if p_provider_type is null or p_provider_type not in ('individual','company') then
    raise exception 'Invalid provider type.' using errcode = 'P0216';
  end if;
  if not exists (select 1 from public.need_categories c
    where c.slug = p_category_slug and c.is_active and c.slug <> 'financial_services') then
    raise exception 'Unknown or retired provider category.' using errcode = 'P0216';
  end if;
  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled' and is_public
      and (country is null or country = (select p.country from public.profiles p where p.id = v_user))
    order by (country = (select p.country from public.profiles p where p.id = v_user)) desc nulls last
    limit 1;
  if lower(coalesce(v_enabled,'false')) not in ('true','1') then
    raise exception 'Provider capability profiles are disabled.' using errcode = 'P0216';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text || ':' || p_category_slug, 0));
  select provider_type into v_old from public.provider_category_profiles
    where user_id = v_user and category_slug = p_category_slug for update;
  if v_old is not null and v_old <> p_provider_type then
    raise exception 'Use the identity switch review to change this category.' using errcode = 'P0216';
  end if;
  if v_old = p_provider_type then return; end if;
  insert into public.provider_category_profiles(user_id, category_slug, provider_type)
    values (v_user, p_category_slug, p_provider_type)
    on conflict (user_id, category_slug) do nothing;
  insert into public.audit_logs(user_id,event_type,entity_type,action,new_values)
    values (v_user,'admin_action','provider_category_profile','set_initial_provider_identity',
      jsonb_build_object('category_slug',p_category_slug,'provider_type',p_provider_type));
end;
$$;
revoke all on function private.set_provider_category_type_internal(text,text) from public, anon;
grant execute on function private.set_provider_category_type_internal(text,text) to authenticated;

create or replace function private.save_provider_identity_presentation_internal(
  p_category_slug text, p_identity_type text, p_presentation jsonb
) returns void language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_mode text := coalesce(p_presentation->>'display_mode',
    case when p_identity_type = 'individual' then 'personal' else 'company' end);
  v_name text := btrim(coalesce(p_presentation->>'display_name',''));
  v_rep text := nullif(btrim(coalesce(p_presentation->>'representative_name','')), '');
  v_authorized boolean := coalesce((p_presentation->>'representative_authorized')::boolean,false);
begin
  if v_user is null then raise exception 'Not authenticated' using errcode='42501'; end if;
  if p_identity_type is null or p_identity_type not in ('individual','company') or jsonb_typeof(coalesce(p_presentation,'{}'::jsonb)) <> 'object' then
    raise exception 'Invalid identity presentation.' using errcode='P0216';
  end if;
  if not exists (select 1 from public.provider_category_profiles p
      where p.user_id=v_user and p.category_slug=p_category_slug and p.provider_type=p_identity_type) then
    raise exception 'Choose this identity for the category first.' using errcode='P0216';
  end if;
  if p_identity_type='company' then
    if v_name='' then
      select nullif(btrim(cp.company_name),'') into v_name from public.provider_company_profiles cp
        where cp.user_id=v_user and cp.category_slug=p_category_slug;
    end if;
    if v_name='' or v_name is null then
      raise exception 'Company name is required.' using errcode='P0216';
    end if;
    if v_mode not in ('company','company_with_representative') or
       (v_mode='company_with_representative' and (not v_authorized or v_rep is null)) then
      raise exception 'Representative details and authorization are required.' using errcode='P0216';
    end if;
  else
    v_mode := 'personal';
    if v_name='' then
      select nullif(btrim(p.full_name),'') into v_name from public.profiles p where p.id=v_user;
    end if;
    if v_name='' or v_name is null then raise exception 'A display name is required.' using errcode='P0216'; end if;
    v_rep := null; v_authorized := false;
  end if;
  insert into public.provider_identity_presentations(
    user_id,category_slug,identity_type,display_mode,display_name,representative_name,representative_authorized
  ) values (v_user,p_category_slug,p_identity_type,v_mode,left(v_name,80),left(v_rep,80),v_authorized)
  on conflict(user_id,category_slug,identity_type) do update set
    display_mode=excluded.display_mode, display_name=excluded.display_name,
    representative_name=excluded.representative_name,
    representative_authorized=excluded.representative_authorized, updated_at=now();
end;
$$;
revoke all on function private.save_provider_identity_presentation_internal(text,text,jsonb) from public,anon;
grant execute on function private.save_provider_identity_presentation_internal(text,text,jsonb) to authenticated;

create or replace function public.save_provider_identity_presentation(
  p_category_slug text, p_identity_type text, p_presentation jsonb
) returns void language plpgsql security invoker
set search_path=public,private,pg_temp as $$ begin
  perform private.save_provider_identity_presentation_internal(p_category_slug,p_identity_type,p_presentation);
end; $$;
revoke all on function public.save_provider_identity_presentation(text,text,jsonb) from public,anon;
grant execute on function public.save_provider_identity_presentation(text,text,jsonb) to authenticated;

create or replace function public.get_my_provider_identity(
  p_category_slug text
) returns jsonb language plpgsql stable security invoker
set search_path=public,pg_temp as $$
declare v_user uuid:=auth.uid(); v_type text; v_presentation jsonb; v_company jsonb;
begin
  select provider_type into v_type from public.provider_category_profiles
    where user_id=v_user and category_slug=p_category_slug;
  select to_jsonb(p) into v_presentation from public.provider_identity_presentations p
    where p.user_id=v_user and p.category_slug=p_category_slug and p.identity_type=v_type;
  select to_jsonb(cp) into v_company from public.provider_company_profiles cp
    where cp.user_id=v_user and cp.category_slug=p_category_slug;
  return jsonb_build_object('provider_type',v_type,'presentation',coalesce(v_presentation,'{}'::jsonb),
    'company_profile',coalesce(v_company,'{}'::jsonb),
    'pending_offers',(select count(*) from public.need_offers o join public.needs_requests n on n.request_id=o.need_id
      where o.offer_maker_id=v_user and n.category_slug=$1 and o.status='pending'),
    'active_capabilities',(select count(*) from public.provider_capabilities pc
      join public.need_capabilities nc on nc.slug=pc.capability_slug where pc.user_id=v_user
      and nc.category_slug=$1 and nc.capability_type='service' and pc.is_active),
    'individual_active_capabilities',(select count(*) from public.provider_capabilities pc
      join public.need_capabilities nc on nc.slug=pc.capability_slug where pc.user_id=v_user
      and nc.category_slug=$1 and nc.capability_type='service' and pc.identity_type='individual' and pc.is_active),
    'company_active_capabilities',(select count(*) from public.provider_capabilities pc
      join public.need_capabilities nc on nc.slug=pc.capability_slug where pc.user_id=v_user
      and nc.category_slug=$1 and nc.capability_type='service' and pc.identity_type='company' and pc.is_active));
end; $$;
revoke all on function public.get_my_provider_identity(text) from public,anon;
grant execute on function public.get_my_provider_identity(text) to authenticated;

create or replace function private.switch_provider_identity_internal(
  p_category_slug text, p_to_identity text, p_presentation jsonb
) returns jsonb language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare
  v_user uuid:=auth.uid(); v_from text; v_enabled text; v_deactivated int:=0; v_reactivated int:=0;
  v_pending int:=0; v_active int:=0;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode='42501'; end if;
  if p_to_identity is null or p_to_identity not in ('individual','company') then raise exception 'Invalid target identity.' using errcode='P0216'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text || ':' || p_category_slug,0));
  select provider_type into v_from from public.provider_category_profiles
    where user_id=v_user and category_slug=p_category_slug for update;
  if not found or v_from=p_to_identity then raise exception 'Identity switch is unavailable.' using errcode='P0216'; end if;
  select setting_value into v_enabled from public.system_settings
    where setting_key='capability_profiles_enabled' and is_public
    order by (country=(select country from public.profiles where id=v_user)) desc nulls last limit 1;
  if lower(coalesce(v_enabled,'false')) not in ('true','1') then raise exception 'Provider profiles are disabled.' using errcode='P0216'; end if;
  if (select count(*) from public.audit_logs a where a.user_id=v_user and a.entity_type='provider_identity'
      and a.action='switch' and a.new_values->>'category_slug'=p_category_slug
      and a.created_at>now()-interval '24 hours')>=5 then
    raise exception 'You have reached the identity switch limit for this category.' using errcode='P0216';
  end if;
  if not exists(select 1 from public.need_categories where slug=p_category_slug and is_active) then
    raise exception 'Provider category is unavailable.' using errcode='P0216';
  end if;
  update public.provider_category_profiles set provider_type=p_to_identity, identity_changed_at=now(), updated_at=now()
    where user_id=v_user and category_slug=p_category_slug;
  -- The presentation helper verifies the category's selected identity. Set it
  -- first; the transaction still rolls back both changes together on error.
  perform private.save_provider_identity_presentation_internal(p_category_slug,p_to_identity,p_presentation);
  update public.provider_capabilities pc set is_active=false
    from public.need_capabilities nc where nc.slug=pc.capability_slug and pc.user_id=v_user
      and nc.category_slug=p_category_slug and nc.capability_type='service'
      and pc.identity_type=v_from and pc.is_active;
  get diagnostics v_deactivated=row_count;
  update public.provider_capabilities pc set is_active=true
    from public.need_capabilities nc where nc.slug=pc.capability_slug and pc.user_id=v_user
      and nc.category_slug=p_category_slug and nc.capability_type='service'
      and pc.identity_type=p_to_identity;
  select count(*) into v_reactivated from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug=pc.capability_slug
    where pc.user_id=v_user and nc.category_slug=p_category_slug
      and nc.capability_type='service' and pc.identity_type=p_to_identity and pc.is_active;

  select count(*) into v_pending from public.need_offers o
    join public.needs_requests n on n.request_id=o.need_id
    where o.offer_maker_id=v_user and n.category_slug=p_category_slug and o.status='pending';
  select count(*) into v_active from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug=pc.capability_slug
    where pc.user_id=v_user and nc.category_slug=p_category_slug and nc.capability_type='service' and pc.is_active;
  insert into public.audit_logs(user_id,event_type,entity_type,action,old_values,new_values)
    values(v_user,'admin_action','provider_identity','switch',
      jsonb_build_object('category_slug',p_category_slug,'from',v_from),
      jsonb_build_object('category_slug',p_category_slug,'to',p_to_identity,
        'deactivated',v_deactivated,'reactivated',v_reactivated,'pending_offers',v_pending,
        'representative_authorized',coalesce((p_presentation->>'representative_authorized')::boolean,false)));
  return jsonb_build_object('provider_type',p_to_identity,'deactivated',v_deactivated,
    'reactivated',v_reactivated,'pending_offers',v_pending,'active_capabilities',v_active);
end; $$;
revoke all on function private.switch_provider_identity_internal(text,text,jsonb) from public,anon;
grant execute on function private.switch_provider_identity_internal(text,text,jsonb) to authenticated;
create or replace function public.switch_provider_identity(
  p_category_slug text,p_to_identity text,p_presentation jsonb
) returns jsonb language plpgsql security invoker
set search_path=public,private,pg_temp as $$ begin
  return private.switch_provider_identity_internal(p_category_slug,p_to_identity,p_presentation);
end; $$;
revoke all on function public.switch_provider_identity(text,text,jsonb) from public,anon;
grant execute on function public.switch_provider_identity(text,text,jsonb) to authenticated;

create or replace function private.snapshot_need_offer_provider_identity()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare v_need record; v_type text; v_slug text; v_display text; v_kind text;
begin
  if tg_op='UPDATE' then
    new.provider_identity_type:=old.provider_identity_type;
    new.provider_display_name:=old.provider_display_name;
    return new;
  end if;
  -- Serialize offer creation with category identity switches. An offer is
  -- either included in the pending count before the switch or uses the new
  -- identity after it commits.
  perform pg_advisory_xact_lock(hashtextextended(new.offer_maker_id::text || ':' ||
    (select n.category_slug from public.needs_requests n where n.request_id=new.need_id),0));
  select request_id,category_slug,capability_slug into v_need from public.needs_requests where request_id=new.need_id;
  if not found then return new; end if;
  select provider_type into v_type from public.provider_category_profiles
    where user_id=new.offer_maker_id and category_slug=v_need.category_slug;
  if v_need.capability_slug is not null then
    v_slug:=v_need.capability_slug;
    select capability_type into v_kind from public.need_capabilities where slug=v_slug;
    if v_kind='service' and not exists(select 1 from public.provider_capabilities pc
      where pc.user_id=new.offer_maker_id and pc.capability_slug=v_slug and pc.is_active
        and pc.identity_type=v_type) then
      raise exception 'An active service under your current identity is required to make this offer.' using errcode='P0216';
    end if;
  else
    if not exists(select 1 from public.provider_capabilities pc join public.need_capabilities nc on nc.slug=pc.capability_slug
      where pc.user_id=new.offer_maker_id and nc.category_slug=v_need.category_slug and pc.is_active
        and (nc.capability_type='work' or pc.identity_type=v_type)) then
      raise exception 'An active capability under your current identity is required to make this offer.' using errcode='P0216';
    end if;
  end if;
  if v_kind='work' then
    v_type:='individual';
  end if;
  new.provider_identity_type:=v_type;
  select case when p.display_mode='company_with_representative'
    then p.display_name || ' · Represented by ' || p.representative_name
    else p.display_name end
    into v_display from public.provider_identity_presentations p
    where p.user_id=new.offer_maker_id and p.category_slug=v_need.category_slug and p.identity_type=v_type;
  if v_display is null then
    select case when v_type='company' then cp.company_name else pr.full_name end into v_display
    from public.profiles pr
    left join public.provider_company_profiles cp
      on cp.user_id=pr.id and cp.category_slug=v_need.category_slug
    where pr.id=new.offer_maker_id;
  end if;
  new.provider_display_name:=nullif(v_display,'');
  return new;
end; $$;
revoke all on function private.snapshot_need_offer_provider_identity() from public,anon,authenticated;
drop trigger if exists trg_provider_identity_offer_snapshot on public.need_offers;
create trigger trg_provider_identity_offer_snapshot before insert or update on public.need_offers
  for each row execute function private.snapshot_need_offer_provider_identity();

create or replace function private.snapshot_need_reveal_provider_identity()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
  if tg_op='UPDATE' then
    new.provider_identity_type:=old.provider_identity_type;
    new.provider_display_name:=old.provider_display_name;
    return new;
  end if;
  select o.provider_identity_type,o.provider_display_name into new.provider_identity_type,new.provider_display_name
    from public.need_offers o where o.id=new.offer_id;
  return new;
end; $$;
revoke all on function private.snapshot_need_reveal_provider_identity() from public,anon,authenticated;
drop trigger if exists trg_snapshot_need_reveal_provider_identity on public.need_contact_reveals;
create trigger trg_snapshot_need_reveal_provider_identity before insert or update on public.need_contact_reveals
  for each row execute function private.snapshot_need_reveal_provider_identity();

create or replace function public.get_public_need_offer_identities(p_need_id uuid)
returns table(offer_id uuid,provider_identity_type text,provider_display_name text)
language sql stable security definer set search_path=public,pg_temp as $$
  select o.id,o.provider_identity_type,o.provider_display_name from public.need_offers o
  where o.need_id=p_need_id and o.status in ('pending','accepted')
    and exists(select 1 from public.needs_requests n where n.request_id=o.need_id
      and n.status in ('active','matched','contracted','completed')
      and (n.requester_id=auth.uid() or o.offer_maker_id=auth.uid()));
$$;
revoke all on function public.get_public_need_offer_identities(uuid) from public,anon;
grant execute on function public.get_public_need_offer_identities(uuid) to authenticated;

-- Public presentation lookup for existing provider/listing clients. The input
-- provider ID is already available to authenticated listing clients; the result
-- contains only the approved name and identity label, never private profile data.
create or replace function public.get_public_provider_identity(
  p_provider_user_id uuid,p_category_slug text
) returns table(identity_type text,display_name text)
language sql stable security definer set search_path=public,private,pg_temp as $$
  select pcp.provider_type,
    coalesce(
      case when ip.display_mode='company_with_representative'
        then ip.display_name || ' · Represented by ' || ip.representative_name
        else ip.display_name end,
      case when pcp.provider_type='company' then cp.company_name else pr.full_name end
    )
  from public.provider_category_profiles pcp
  join public.profiles pr on pr.id=pcp.user_id
  left join public.provider_identity_presentations ip
    on ip.user_id=pcp.user_id and ip.category_slug=pcp.category_slug and ip.identity_type=pcp.provider_type
  left join public.provider_company_profiles cp
    on cp.user_id=pcp.user_id and cp.category_slug=pcp.category_slug
  where pcp.user_id=p_provider_user_id and pcp.category_slug=p_category_slug
    and exists(select 1 from public.provider_capabilities pc
      join public.need_capabilities nc on nc.slug=pc.capability_slug
      where pc.user_id=pcp.user_id and nc.category_slug=pcp.category_slug
        and nc.capability_type='service' and pc.identity_type=pcp.provider_type and pc.is_active)
  limit 1;
$$;
revoke all on function public.get_public_provider_identity(uuid,text) from public,anon;
grant execute on function public.get_public_provider_identity(uuid,text) to authenticated;

commit;

-- Historical offer/reveal snapshots remain null unless already captured.
-- Rollback: drop the new functions/triggers/view-like RPC, columns and table;
-- restore the previous provider type setter, then remove identity_type.

-- ============================================================================
-- END MERGED SECTION (10/52): patch_provider_identity_switch.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (11/52): patch_optional_provider_badge_proof.sql
-- ============================================================================

-- Let providers voluntarily submit a supporting document for a badge, even
-- where proof is not needed to keep an open capability active. Admin approval
-- remains the only way this evidence can award provider_verified.
-- Apply after provider capability evidence, verification policy, and provider
-- type verification matrix patches. Safe to rerun; never changes open/required
-- activation policy or adds proof requirements to offering services.
begin;

insert into public.verification_requirements (
  scope_type,
  scope_id,
  provider_type,
  identity_required,
  phone_required,
  provider_verification_required,
  evidence_requirements,
  required_evidence,
  expires_after_days,
  is_active
)
select
  'capability',
  nc.slug,
  'both',
  false,
  false,
  false,
  jsonb_build_array('supporting_document'),
  array[]::text[],
  null,
  true
from public.need_capabilities nc
where nc.is_active
  and nc.verification_policy = 'open'
on conflict (scope_type, scope_id, provider_type) do nothing;

commit;

-- Existing open capabilities remain active. Only admin-approved submissions
-- receive provider_verified; rejected or pending documents do not change access.

-- ============================================================================
-- END MERGED SECTION (11/52): patch_optional_provider_badge_proof.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (12/52): patch_catalog_expansion_v3.sql
-- ============================================================================

-- Additive catalog expansion. Safe to re-run; existing slugs are preserved.
begin;

alter table public.need_categories
  add column if not exists aliases text[] not null default array[]::text[],
  add column if not exists tagline text,
  add column if not exists description text;
alter table public.need_capabilities
  add column if not exists aliases text[] not null default array[]::text[],
  add column if not exists capability_type text not null default 'service'
    check (capability_type in ('service', 'work')),
  add column if not exists policy text not null default 'open'
    check (policy in ('open', 'optional_proof', 'required_proof'));
alter table public.need_capabilities
  add column if not exists ui_group_slugs text[] not null default array[]::text[];
alter table public.capability_roles
  add column if not exists aliases text[] not null default array[]::text[];
alter table public.role_kinds
  add column if not exists aliases text[] not null default array[]::text[];
alter table public.role_qualifications
  add column if not exists expires_after_days integer;
alter table public.verification_requirements
  add column if not exists provider_type text not null default 'both',
  add column if not exists required_evidence text[] not null default array[]::text[],
  add column if not exists expires_after_days integer;
alter table public.verification_requirements
  drop constraint if exists verification_requirements_scope_type_scope_id_key;
create unique index if not exists verification_requirements_scope_type_scope_id_provider_type_uidx
  on public.verification_requirements(scope_type, scope_id, provider_type);

create table if not exists public.catalog_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  query text not null check (length(btrim(query)) between 1 and 160),
  created_at timestamptz not null default now()
);
alter table public.catalog_requests enable row level security;
drop policy if exists "catalog requests owner insert" on public.catalog_requests;
create policy "catalog requests owner insert" on public.catalog_requests
  for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "catalog requests admin read" on public.catalog_requests;
create policy "catalog requests admin read" on public.catalog_requests
  for select to authenticated using (private.is_admin());
revoke all on public.catalog_requests from anon, public;
grant insert on public.catalog_requests to authenticated;
grant select on public.catalog_requests to authenticated;

create table if not exists public.provider_content_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_slug text not null references public.need_categories(slug) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.provider_content_reports enable row level security;
drop policy if exists "provider content report owner insert" on public.provider_content_reports;
create policy "provider content report owner insert" on public.provider_content_reports
  for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "provider content report admin read" on public.provider_content_reports;
create policy "provider content report admin read" on public.provider_content_reports
  for select to authenticated using (private.is_admin());
revoke all on public.provider_content_reports from anon, public;
grant insert on public.provider_content_reports to authenticated;
grant select on public.provider_content_reports to authenticated;

-- Keep new categories disabled until their per-category rollout flag is enabled.
insert into public.need_categories (slug, name, icon, sort_order, description, is_active)
values
  ('domestic_household', 'Domestic & Household', '🏠', 15, 'House help, childcare, home cooking and care at home', false),
  ('health_medical', 'Health & Medical', '⚕️', 16, 'Nurses, doctors, specialists, clinics and care', false),
  ('business_investment', 'Business & Investment', '💼', 17, 'Angel investors, mentors and startup support', false),
  ('traditional_cultural', 'Traditional & Cultural Services', '🪘', 18, 'Traditional ceremonies, prayers, healing and culture', false)
on conflict (slug) do update set name = excluded.name, icon = excluded.icon,
  sort_order = excluded.sort_order, description = excluded.description;
update public.need_categories set
  tagline = 'House help, childcare, home cooking and care at home',
  aliases = array['maid','house help','housegirl','dada','domestic worker']
where slug = 'domestic_household';
update public.need_categories set
  tagline = 'Nurses, doctors, specialists, clinics and care',
  aliases = array['clinic','health centre','dispensary','nurse','doctor','optician','oncologist']
where slug = 'health_medical';
update public.need_categories set
  tagline = 'Angel investors, mentors and startup support',
  aliases = array['angel investor','investor','seed funding','startup funding']
where slug = 'business_investment';
update public.need_categories set
  tagline = 'Traditional ceremonies, prayers, healing and culture',
  aliases = array['duwa','duwah']
where slug = 'traditional_cultural';
update public.need_categories set name = 'Beauty, Fashion, Styling & Wellness'
where slug = 'beauty_fashion_styling';

-- Reflect existing verification configuration in the additive policy field.
-- This is descriptive metadata only and does not change existing activation.
update public.need_capabilities nc set policy = case
  when exists (
    select 1 from public.verification_requirements vr
    where vr.is_active and vr.scope_type = 'capability'
      and vr.scope_id = nc.slug and vr.provider_verification_required
  ) then 'required_proof'
  when exists (
    select 1 from public.verification_requirements vr
    where vr.is_active and vr.scope_type = 'capability'
      and vr.scope_id = nc.slug and (
        coalesce(cardinality(vr.required_evidence), 0) > 0
        or case when jsonb_typeof(vr.evidence_requirements) = 'array'
          then jsonb_array_length(vr.evidence_requirements) > 0 else false end
      )
  ) then 'optional_proof'
  else 'open'
end
where nc.slug not in (
 'house_help_services','housekeeping_services','laundry_services','gardening_services',
 'childcare_nanny_services','home_cooking_services','elderly_home_care','other_domestic',
 'chauffeur_services','personal_driver_hire','boda_taxi_services',
 'massage_therapy','spa_services','salon_barber_services','nails_skincare_services','sauna_steam_services',
 'clinic_services','hospital_services','eye_clinic_optical','dental_clinic','diagnostic_lab',
 'pharmacy_services','physiotherapy_clinic','home_nursing_agency','medical_staffing_agency',
 'other_health','circumcision_services','maternity_care_services','family_planning_services',
 'hiv_testing_services','mobile_health_outreach','orthopaedic_care',
 'angel_investor_network','startup_advisory','investor_introductions','incubator_accelerator','other_investment',
 'duwah_services','traditional_ceremony_services','traditional_dance_drumming',
 'traditional_healing_herbal','traditional_attire_crafts','other_traditional',
 'final_year_project_support','research_dissertation_guidance','data_analysis_help',
 'proofreading_editing','coursework_tutoring'
);
insert into public.system_settings
  (setting_key, setting_value, setting_type, category, description, is_public)
values
 ('capability_profiles_enabled_domestic_household','false','boolean','providers','Domestic & Household provider catalog rollout flag',true),
 ('capability_profiles_enabled_health_medical','false','boolean','providers','Health & Medical provider catalog rollout flag',true),
 ('capability_profiles_enabled_business_investment','false','boolean','providers','Business & Investment provider catalog rollout flag',true),
 ('capability_profiles_enabled_traditional_cultural','false','boolean','providers','Traditional & Cultural provider catalog rollout flag',true)
on conflict (setting_key, coalesce(country, '__global__')) do update
  set setting_value = excluded.setting_value,
  is_public = excluded.is_public;

-- Requested discovery aliases on existing canonical rows.
update public.need_capabilities set aliases = array['driving lessons','learn to drive','instructor']
where slug in ('driving_school','driving_school_driver_training');
update public.need_capabilities set aliases = array['chauffeur','executive driver','personal driver']
where slug in ('chauffeur_services','personal_driver_hire');
update public.need_capabilities set aliases = array['massage','masseuse','masseur','therapeutic body rub']
where slug = 'massage_therapy';
update public.need_capabilities set aliases = array['wellness','sauna','steam']
where slug = 'spa_services';
update public.need_capabilities set aliases = array['clinic','health centre','dispensary']
where slug = 'clinic_services';
update public.need_capabilities set aliases = array['bone doctor','fracture','broken bone','back pain','joint pain','knee','arthritis','x-ray','physio']
where slug = 'orthopaedic_care';

-- Additive service catalog. Health, investment, and traditional categories are
-- inactive above; their rows remain inactive and cannot be offered at launch.
insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order,
   capability_type, policy, aliases)
values
 ('house_help_services','domestic_household','Maids & House Help',false,'domestic_household',10,'home_help','Home help',10,'service','optional_proof',array['maid','house help','housegirl','dada','domestic worker']),
 ('housekeeping_services','domestic_household','Housekeeping & Cleaning',false,'domestic_household',20,'home_help','Home help',20,'service','optional_proof',array['cleaner','house cleaner']),
 ('laundry_services','domestic_household','Laundry & Ironing',false,'domestic_household',30,'home_help','Home help',30,'service','open',array['laundry','ironing']),
 ('gardening_services','domestic_household','Gardening & Compound Care',false,'domestic_household',40,'home_help','Home help',40,'service','open',array['gardener','compound care']),
 ('childcare_nanny_services','domestic_household','Nannies & Childcare',false,'domestic_household',50,'family','Family',10,'service','optional_proof',array['nanny','babysitter','childcare']),
 ('home_cooking_services','domestic_household','Home Cooks',false,'domestic_household',60,'family','Family',20,'service','optional_proof',array['home cook','private cook']),
 ('elderly_home_care','domestic_household','Elderly Home Care',false,'domestic_household',70,'family','Family',30,'service','optional_proof',array['home carer','elder care']),
 ('other_domestic','domestic_household','Other Domestic',false,'domestic_household',80,'other','Other',10,'service','open',array[]::text[]),
 ('chauffeur_services','transport_logistics','Chauffeur Services',true,'transport_logistics',410,'passenger','Passenger transport',10,'service','optional_proof',array['chauffeur','executive driver']),
 ('personal_driver_hire','transport_logistics','Personal Driver Hire',true,'transport_logistics',420,'passenger','Passenger transport',20,'service','optional_proof',array['personal driver','private driver']),
 ('boda_taxi_services','transport_logistics','Boda Boda / Motorcycle Taxi',true,'transport_logistics',430,'passenger','Passenger transport',30,'service','optional_proof',array['boda','boda boda','motorcycle taxi']),
 ('massage_therapy','beauty_fashion_styling','Massage Therapy',true,'beauty_fashion_styling',710,'wellness_spa','Wellness & Spa',10,'service','optional_proof',array['massage','masseuse','masseur','therapeutic body rub']),
 ('spa_services','beauty_fashion_styling','Spa Services',true,'beauty_fashion_styling',720,'wellness_spa','Wellness & Spa',20,'service','optional_proof',array['wellness','sauna','steam']),
 ('salon_barber_services','beauty_fashion_styling','Salons & Barber Shops',true,'beauty_fashion_styling',730,'wellness_spa','Wellness & Spa',30,'service','optional_proof',array['salon','barber','barbershop']),
 ('nails_skincare_services','beauty_fashion_styling','Nails & Skincare',true,'beauty_fashion_styling',740,'wellness_spa','Wellness & Spa',40,'service','optional_proof',array['manicure','pedicure','skincare']),
 ('sauna_steam_services','beauty_fashion_styling','Sauna & Steam',true,'beauty_fashion_styling',750,'wellness_spa','Wellness & Spa',50,'service','optional_proof',array['sauna','steam room']),
 ('clinic_services','health_medical','Clinics & Health Centres',false,'health_medical',10,'facilities','Facilities',10,'service','required_proof',array['clinic','health centre','dispensary']),
 ('hospital_services','health_medical','Hospitals',false,'health_medical',20,'facilities','Facilities',20,'service','required_proof',array['hospital']),
 ('eye_clinic_optical','health_medical','Eye Clinics & Opticals',false,'health_medical',30,'facilities','Facilities',30,'service','required_proof',array['optician','optometrist','eye doctor','glasses']),
 ('dental_clinic','health_medical','Dental Clinics',false,'health_medical',40,'facilities','Facilities',40,'service','required_proof',array['dentist']),
 ('diagnostic_lab','health_medical','Diagnostic Labs & Imaging',false,'health_medical',50,'facilities','Facilities',50,'service','required_proof',array['lab','x-ray','imaging']),
 ('pharmacy_services','health_medical','Pharmacies',false,'health_medical',60,'facilities','Facilities',60,'service','required_proof',array['chemist','drug shop']),
 ('physiotherapy_clinic','health_medical','Physiotherapy Clinics',false,'health_medical',70,'facilities','Facilities',70,'service','required_proof',array['physio']),
 ('home_nursing_agency','health_medical','Home Nursing Agencies',false,'health_medical',80,'staffing','Staffing & home care',10,'service','required_proof',array['home nurse']),
 ('medical_staffing_agency','health_medical','Medical Staffing Agencies',false,'health_medical',90,'staffing','Staffing & home care',20,'service','required_proof',array[]::text[]),
 ('other_health','health_medical','Other Health Services',false,'health_medical',100,'other','Other',10,'service','required_proof',array[]::text[]),
 ('circumcision_services','health_medical','Circumcision Services',false,'health_medical',110,'procedures','Procedures',10,'service','required_proof',array['male circumcision','VMMC','mobile circumcision']),
 ('mobile_circumcision_services','health_medical','Mobile Circumcision',false,'health_medical',111,'procedures','Procedures',20,'service','required_proof',array['home visit circumcision','mobile circumcision provider','at-home circumcision']),
 ('maternity_care_services','health_medical','Antenatal & Maternity Care',false,'health_medical',120,'reproductive','Reproductive health',10,'service','required_proof',array['pregnancy','antenatal','ANC','maternity','midwife','prenatal','delivery','post-abortion care']),
 ('family_planning_services','health_medical','Family Planning & Reproductive Health',false,'health_medical',130,'reproductive','Reproductive health',20,'service','required_proof',array['contraception','family planning']),
 ('hiv_testing_services','health_medical','HIV Testing & Counselling',false,'health_medical',140,'reproductive','Reproductive health',30,'service','required_proof',array['HIV test','HCT','VCT','PrEP','PEP','STI test','sexual health']),
 ('mobile_health_outreach','health_medical','Mobile Health Outreach',false,'health_medical',150,'staffing','Staffing & home care',30,'service','required_proof',array['home visit']),
 ('orthopaedic_care','health_medical','Orthopaedic & Bone Care',false,'health_medical',160,'facilities','Facilities',80,'service','required_proof',array['bone doctor','fracture','broken bone','back pain','joint pain','knee','arthritis','x-ray','physio']),
 ('angel_investor_network','business_investment','Angel Investor Networks',false,'business_investment',10,'funding','Investor support',10,'service','required_proof',array['angel investor','investor','seed funding','startup funding']),
 ('startup_advisory','business_investment','Startup Advisory',false,'business_investment',20,'funding','Investor support',20,'service','optional_proof',array['startup mentor']),
 ('investor_introductions','business_investment','Investor Introductions',false,'business_investment',30,'funding','Investor support',30,'service','required_proof',array['investor introduction']),
 ('incubator_accelerator','business_investment','Incubators & Accelerators',false,'business_investment',40,'funding','Investor support',40,'service','required_proof',array['startup incubator','accelerator']),
 ('other_investment','business_investment','Other Investment Support',false,'business_investment',50,'other','Other',10,'service','open',array[]::text[]),
 ('duwah_services','traditional_cultural','Duwah Services',false,'traditional_cultural',10,'culture','Culture',10,'service','optional_proof',array['duwa','duwah']),
 ('traditional_ceremony_services','traditional_cultural','Traditional Ceremonies',false,'traditional_cultural',20,'culture','Culture',20,'service','optional_proof',array[]::text[]),
 ('traditional_dance_drumming','traditional_cultural','Traditional Dance & Drumming',false,'traditional_cultural',30,'culture','Culture',30,'service','open',array[]::text[]),
 ('traditional_healing_herbal','traditional_cultural','Herbal & Traditional Healing',false,'traditional_cultural',40,'healing','Healing',10,'service','required_proof',array['traditional healer','herbalist']),
 ('traditional_attire_crafts','traditional_cultural','Traditional Attire & Crafts',false,'traditional_cultural',50,'culture','Culture',40,'service','open',array[]::text[]),
 ('other_traditional','traditional_cultural','Other Traditional',false,'traditional_cultural',60,'other','Other',10,'service','open',array[]::text[]),
 ('final_year_project_support','education_training','Final Year Project Support',true,'education_training',810,'coursework','Coursework & projects',10,'service','optional_proof',array['FYP','capstone','project defence']),
 ('research_dissertation_guidance','education_training','Research Proposal & Dissertation Guidance',true,'education_training',820,'coursework','Coursework & projects',20,'service','optional_proof',array['thesis','research paper','proposal']),
 ('data_analysis_help','education_training','Data Analysis & Statistics Help',true,'education_training',830,'coursework','Coursework & projects',30,'service','open',array['SPSS','statistics','STATA']),
 ('proofreading_editing','education_training','Proofreading & Editing',true,'education_training',840,'coursework','Coursework & projects',40,'service','open',array['editing']),
 ('coursework_tutoring','education_training','Coursework Tutoring',true,'education_training',850,'coursework','Coursework & projects',50,'service','open',array['course work','coursework','assignment help','homework'])
on conflict (slug) do update set
  name = excluded.name, ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order, service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  aliases = excluded.aliases, policy = excluded.policy;

-- Personal work profiles. Categories stay inactive until their rollout flag
-- and country review are complete; role rows are seeded for discovery indexing.
insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order,
   capability_type, policy, aliases)
values
 ('work_house_help','domestic_household','House Help / Maid',false,'domestic_household',110,'work_roles','Work roles',10,'work','optional_proof',array['maid','housegirl','dada','domestic worker']),
 ('work_nanny','domestic_household','Nanny / Childcare',false,'domestic_household',120,'work_roles','Work roles',20,'work','required_proof',array['nanny','babysitter']),
 ('work_home_cook','domestic_household','Home Cook',false,'domestic_household',130,'work_roles','Work roles',30,'work','optional_proof',array['cook']),
 ('work_gardener','domestic_household','Gardener / Groundskeeper',false,'domestic_household',140,'work_roles','Work roles',40,'work','open',array['gardener']),
 ('work_home_carer','domestic_household','Home Carer',false,'domestic_household',150,'work_roles','Work roles',50,'work','optional_proof',array['caregiver','home care']),
 ('work_driving_instructor','transport_logistics','Driving Instructor',true,'transport_logistics',440,'work_roles','Work roles',60,'work','required_proof',array['driving lessons','instructor']),
 ('work_massage_therapist','beauty_fashion_styling','Massage Therapist',true,'beauty_fashion_styling',760,'work_roles','Work roles',60,'work','optional_proof',array['masseuse','masseur']),
 ('work_spa_therapist','beauty_fashion_styling','Spa Therapist',true,'beauty_fashion_styling',770,'work_roles','Work roles',70,'work','optional_proof',array[]::text[]),
 ('work_spa_manager','beauty_fashion_styling','Spa / Wellness Manager',true,'beauty_fashion_styling',780,'work_roles','Work roles',80,'work','optional_proof',array[]::text[]),
 ('work_nurse','health_medical','Nurse / Midwife',false,'health_medical',210,'work_roles','Work roles',10,'work','required_proof',array['sister','RN','enrolled nurse']),
 ('work_doctor','health_medical','Doctor',false,'health_medical',220,'work_roles','Work roles',20,'work','required_proof',array['physician','MD','medical officer']),
 ('work_clinician','health_medical','Clinical Officer / Clinician',false,'health_medical',230,'work_roles','Work roles',30,'work','required_proof',array[]::text[]),
 ('work_medical_specialist','health_medical','Medical Specialist',false,'health_medical',240,'work_roles','Work roles',40,'work','required_proof',array['oncologist','cancer specialist']),
 ('work_optometrist','health_medical','Optician / Optometrist',false,'health_medical',250,'work_roles','Work roles',50,'work','required_proof',array['optician','eye doctor','glasses']),
 ('work_dentist','health_medical','Dentist',false,'health_medical',260,'work_roles','Work roles',60,'work','required_proof',array[]::text[]),
 ('work_pharmacist','health_medical','Pharmacist',false,'health_medical',270,'work_roles','Work roles',70,'work','required_proof',array[]::text[]),
 ('work_lab_technician','health_medical','Lab Technician',false,'health_medical',280,'work_roles','Work roles',80,'work','required_proof',array[]::text[]),
 ('work_physiotherapist','health_medical','Physiotherapist',false,'health_medical',290,'work_roles','Work roles',90,'work','required_proof',array[]::text[]),
 ('work_counsellor','health_medical','Counsellor / Psychologist',false,'health_medical',300,'work_roles','Work roles',100,'work','required_proof',array[]::text[]),
 ('work_nursing_assistant','health_medical','Nursing Assistant / Caregiver',false,'health_medical',310,'work_roles','Work roles',110,'work','required_proof',array[]::text[]),
 ('work_hiv_counsellor','health_medical','HIV Counsellor / Testing Officer',false,'health_medical',320,'work_roles','Work roles',120,'work','required_proof',array['HIV testing counsellor','HCT']),
 ('work_angel_investor','business_investment','Angel Investor',false,'business_investment',110,'work_roles','Work roles',10,'work','required_proof',array['investor','seed funding']),
 ('work_business_mentor','business_investment','Business Mentor',false,'business_investment',120,'work_roles','Work roles',20,'work','optional_proof',array['startup mentor']),
 ('work_duwah_practitioner','traditional_cultural','Duwah Practitioner',false,'traditional_cultural',110,'work_roles','Work roles',10,'work','optional_proof',array['duwa','duwah']),
 ('work_ceremony_officiant','traditional_cultural','Ceremony Officiant / Elder',false,'traditional_cultural',120,'work_roles','Work roles',20,'work','optional_proof',array[]::text[]),
 ('work_traditional_performer','traditional_cultural','Traditional Performer',false,'traditional_cultural',130,'work_roles','Work roles',30,'work','open',array[]::text[]),
 ('work_traditional_healer','traditional_cultural','Traditional Healer / Herbalist',false,'traditional_cultural',140,'work_roles','Work roles',40,'work','required_proof',array['traditional healer','herbalist']),
 ('work_research_mentor','education_training','Project / Research Mentor',true,'education_training',860,'work_roles','Work roles',90,'work','optional_proof',array['FYP','capstone','thesis','research paper','proposal'])
on conflict (slug) do update set
  name = excluded.name, ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order, policy = excluded.policy,
  aliases = excluded.aliases;

insert into public.capability_roles
  (slug, category_slug, capability_slug, name, kind_question, is_active, aliases)
select substring(slug from 6), category_slug, slug, name, question, true, array[]::text[]
from (values
 ('work_house_help','domestic_household','House Help / Maid','What kind of help?'),
 ('work_nanny','domestic_household','Nanny / Childcare','Which ages?'),
 ('work_home_cook','domestic_household','Home Cook','What do you cook?'),
 ('work_gardener','domestic_household','Gardener / Groundskeeper','What work?'),
 ('work_home_carer','domestic_household','Home Carer','Whom do you care for?'),
 ('work_driving_instructor','transport_logistics','Driving Instructor','What do you teach?'),
 ('work_massage_therapist','beauty_fashion_styling','Massage Therapist','Which massage?'),
 ('work_spa_therapist','beauty_fashion_styling','Spa Therapist','What treatments?'),
 ('work_spa_manager','beauty_fashion_styling','Spa / Wellness Manager','What do you manage?'),
 ('work_nurse','health_medical','Nurse / Midwife','What nursing?'),
 ('work_doctor','health_medical','Doctor','What do you practise?'),
 ('work_clinician','health_medical','Clinical Officer / Clinician','What area?'),
 ('work_medical_specialist','health_medical','Medical Specialist','Which specialty?'),
 ('work_optometrist','health_medical','Optician / Optometrist','What do you do?'),
 ('work_dentist','health_medical','Dentist','What dentistry?'),
 ('work_pharmacist','health_medical','Pharmacist','Where do you work?'),
 ('work_lab_technician','health_medical','Lab Technician','What lab work?'),
 ('work_physiotherapist','health_medical','Physiotherapist','What therapy?'),
 ('work_counsellor','health_medical','Counsellor / Psychologist','What support?'),
 ('work_nursing_assistant','health_medical','Nursing Assistant / Caregiver','What care?'),
 ('work_hiv_counsellor','health_medical','HIV Counsellor / Testing Officer','What do you do?'),
 ('work_angel_investor','business_investment','Angel Investor','Which sectors?'),
 ('work_business_mentor','business_investment','Business Mentor','What do you help with?'),
 ('work_duwah_practitioner','traditional_cultural','Duwah Practitioner','What is your practice?'),
 ('work_ceremony_officiant','traditional_cultural','Ceremony Officiant / Elder','Which ceremonies?'),
 ('work_traditional_performer','traditional_cultural','Traditional Performer','What do you perform?'),
 ('work_traditional_healer','traditional_cultural','Traditional Healer / Herbalist','What is your practice?'),
 ('work_research_mentor','education_training','Project / Research Mentor','What do you help with?')
) as roles(slug, category_slug, name, question)
on conflict (slug) do update set category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug, name = excluded.name,
  kind_question = excluded.kind_question, is_active = excluded.is_active;
update public.capability_roles set aliases = array['foreman','supervisor','ganger']
where slug = 'foreman_supervisor';
update public.capability_roles set aliases = array['physician','MD','medical officer']
where slug = 'doctor';
update public.capability_roles set aliases = array['sister','RN','enrolled nurse']
where slug = 'nurse';
update public.capability_roles set aliases = array['oncologist','cancer specialist']
where slug = 'medical_specialist';
update public.need_capabilities set ui_group_slugs = array[
  'transport_logistics','education_training','professional_services'
], aliases = array['driving lessons','learn to drive','instructor']
where slug in ('driving_school','driving_school_driver_training');

insert into public.role_kinds (role_slug, slug, name, sort_order) values
 ('house_help','live_in','Live-in',10),('house_help','live_out','Live-out',20),('house_help','day_work','Day work',30),('house_help','part_time','Part-time',40),('house_help','cleaning_only','Cleaning only',50),
 ('nanny','newborn','Newborn',10),('nanny','toddler','Toddler',20),('nanny','school_age','School age',30),('nanny','special_needs','Special needs',40),
 ('home_cook','family_meals','Family meals',10),('home_cook','special_diets','Special diets',20),('home_cook','event_cooking','Event cooking',30),('home_cook','baking','Baking',40),
 ('gardener','lawn_garden','Lawn & garden',10),('gardener','landscaping','Landscaping',20),('gardener','compound_upkeep','Compound upkeep',30),
 ('home_carer','elderly','Elderly',10),('home_carer','disabled','Disabled',20),('home_carer','post_surgery','Post-surgery',30),
 ('driving_instructor','cars','Cars',10),('driving_instructor','motorcycles','Motorcycles',20),('driving_instructor','trucks','Trucks',30),('driving_instructor','defensive_driving','Defensive driving',40),
 ('massage_therapist','relaxation','Relaxation',10),('massage_therapist','deep_tissue','Deep tissue',20),('massage_therapist','sports','Sports',30),('massage_therapist','prenatal','Prenatal',40),('massage_therapist','mobile','Mobile / at-home',50),
 ('spa_therapist','facials','Facials',10),('spa_therapist','body_treatments','Body treatments',20),('spa_therapist','nails','Nails',30),('spa_therapist','waxing','Waxing',40),
 ('spa_manager','spa','Spa',10),('spa_manager','salon','Salon',20),('spa_manager','wellness_centre','Wellness centre',30),
 ('nurse','general','General',10),('nurse','theatre','Theatre',20),('nurse','paediatric','Paediatric',30),('nurse','icu','ICU / critical care',40),('nurse','midwifery','Midwifery',50),('nurse','community_health','Community health',60),
 ('doctor','general_practitioner','General practitioner',10),('doctor','surgeon','Surgeon',20),('doctor','emergency','Emergency',30),('doctor','locum','Locum',40),
 ('clinician','general_clinical','General clinical',10),('clinician','anaesthesia','Anaesthesia',20),('clinician','orthopaedic','Orthopaedic',30),('clinician','ophthalmic','Ophthalmic',40),('clinician','community','Community',50),('clinician','circumcision','Circumcision (adult and infant)',60),
 ('medical_specialist','dermatologist','Dermatologist',10),('medical_specialist','orthopaedic_surgeon','Orthopedic',20),('medical_specialist','paediatrician','Pediatrician',30),('medical_specialist','oncologist','Oncologist',40),('medical_specialist','cardiologist','Cardiologist',50),('medical_specialist','gynaecologist','Gynaecologist',60),('medical_specialist','ent','ENT',70),('medical_specialist','neurologist','Neurologist',80),('medical_specialist','urologist','Urologist',90),('medical_specialist','psychiatrist','Psychiatrist',100),('medical_specialist','radiologist','Radiologist',110),('medical_specialist','other_specialist','Other specialist',120),
 ('optometrist','eye_tests','Eye tests',10),('optometrist','contact_lenses','Contact lenses',20),('optometrist','dispensing_optician','Dispensing optician',30),('optometrist','low_vision','Low vision',40),
 ('dentist','general','General',10),('dentist','orthodontics','Orthodontics',20),('dentist','oral_surgery','Oral surgery',30),('dentist','paediatric','Paediatric',40),
 ('pharmacist','retail','Retail',10),('pharmacist','hospital','Hospital',20),('pharmacist','dispensing','Dispensing',30),('pharmacist','locum','Locum',40),
 ('lab_technician','medical_lab','Medical lab',10),('lab_technician','radiography','Radiography',20),('lab_technician','ultrasound','Ultrasound',30),
 ('physiotherapist','sports','Sports',10),('physiotherapist','neuro','Neuro',20),('physiotherapist','paediatric','Paediatric',30),('physiotherapist','geriatric','Geriatric',40),('physiotherapist','home_visits','Home visits',50),
 ('counsellor','individual','Individual',10),('counsellor','couples_family','Couples & family',20),('counsellor','trauma','Trauma',30),('counsellor','child_adolescent','Child & adolescent',40),
 ('nursing_assistant','bedside','Bedside',10),('nursing_assistant','home_care','Home care',20),('nursing_assistant','elderly','Elderly',30),('nursing_assistant','post_surgery','Post-surgery',40),
 ('hiv_counsellor','testing_counselling','Testing & counselling',10),('hiv_counsellor','peer_educator','Peer educator',20),('hiv_counsellor','community_outreach','Community outreach',30),
 ('angel_investor','technology','Technology',10),('angel_investor','agriculture','Agriculture',20),('angel_investor','retail_trade','Retail & trade',30),('angel_investor','health','Health',40),('angel_investor','energy','Energy',50),('angel_investor','real_estate','Real estate',60),('angel_investor','creative','Creative',70),('angel_investor','general','General',80),
 ('business_mentor','startup','Startup',10),('business_mentor','sme_growth','SME growth',20),('business_mentor','export','Export',30),('business_mentor','agribusiness','Agribusiness',40),
 ('ceremony_officiant','introduction_marriage','Introduction & marriage',10),('ceremony_officiant','naming','Naming',20),('ceremony_officiant','funeral_memorial','Funeral & memorial',30),('ceremony_officiant','cultural_rites','Cultural rites',40),
 ('traditional_performer','dancer','Dancer',10),('traditional_performer','drummer','Drummer',20),('traditional_performer','singer','Singer',30),('traditional_performer','storyteller','Storyteller',40),
 ('traditional_healer','herbalist','Herbalist',10),('traditional_healer','bone_setter','Bone setter',20),('traditional_healer','birth_attendant','Birth attendant',30),
 ('research_mentor','final_year_project','Final year project',10),('research_mentor','dissertation','Dissertation or thesis',20),('research_mentor','research_proposal','Research proposal',30),('research_mentor','data_analysis','Data analysis (SPSS, R, Excel, Stata)',40),('research_mentor','proofreading','Proofreading & editing',50),('research_mentor','presentation_defence','Presentation & defence coaching',60),('research_mentor','software_it_project','Software/IT project guidance',70)
on conflict (role_slug, slug) do update set name = excluded.name, sort_order = excluded.sort_order;

insert into public.role_qualifications (role_slug, slug, name, is_evidence, sort_order) values
 ('house_help','national_id','National ID',true,10),('house_help','references','References',false,20),('house_help','experience_one_year','Experience 1+ year',false,30),('house_help','languages','Languages',false,40),
 ('nanny','national_id','National ID',true,10),('nanny','police_clearance','Police clearance',true,20),('nanny','first_aid','First aid',true,30),('nanny','childcare_certificate','Childcare certificate',false,40),('nanny','references','References',false,50),
 ('home_cook','food_handler_certificate','Food handler certificate',true,10),('home_cook','references','References',false,20),('home_cook','experience_two_years','Experience 2+ years',false,30),
 ('gardener','experience','Experience',false,10),('gardener','references','References',false,20),('gardener','own_tools','Own tools',false,30),
 ('home_carer','caregiving_certificate','Caregiving certificate',true,10),('home_carer','first_aid','First aid',true,20),('home_carer','national_id','National ID',true,30),('home_carer','references','References',false,40),
 ('driving_instructor','instructor_licence','Instructor licence',true,10),('driving_instructor','valid_driving_licence','Valid driving licence',true,20),('driving_instructor','teaching_experience','2+ years teaching',false,30),
 ('massage_therapist','massage_therapy_certificate','Massage therapy certificate',true,10),('massage_therapist','hygiene_certification','Hygiene certification',true,20),('massage_therapist','own_equipment','Own equipment',false,30),('massage_therapist','experience_one_year','Experience 1+ year',false,40),
 ('spa_therapist','cosmetology_spa_certificate','Cosmetology or spa certificate',true,10),('spa_therapist','hygiene_certification','Hygiene certification',true,20),('spa_therapist','portfolio','Portfolio',false,30),
 ('spa_manager','business_licence','Business licence',true,10),('spa_manager','managed_three_staff','Managed 3+ staff',false,20),
 ('nurse','council_registration','Nursing council registration',true,10),('nurse','diploma_degree','Diploma / degree',true,20),('nurse','practising_certificate','Current practising certificate',true,30),('nurse','experience_two_years','2+ years',false,40),
 ('doctor','council_registration','Medical council registration',true,10),('doctor','medical_degree','MBChB / MD',true,20),('doctor','practising_certificate','Practising certificate',true,30),('doctor','internship_completed','Internship completed',false,40),
 ('clinician','council_registration','Clinical officers council registration',true,10),('clinician','diploma','Diploma',true,20),('clinician','practising_licence','Practising licence',true,30),
 ('medical_specialist','specialist_registration','Specialist registration',true,10),('medical_specialist','postgraduate_degree','Postgraduate degree or fellowship',true,20),('medical_specialist','medical_council_registration','Medical council registration',true,30),('medical_specialist','years_specialty','Years in specialty',false,40),
 ('optometrist','optometry_registration','Optometry registration',true,10),('optometrist','diploma_degree','Diploma / degree',true,20),('optometrist','practising_certificate','Practising certificate',true,30),
 ('dentist','dental_council_registration','Dental council registration',true,10),('dentist','bds','BDS',true,20),('dentist','practising_certificate','Practising certificate',true,30),
 ('pharmacist','pharmacy_board_registration','Pharmacy board registration',true,10),('pharmacist','degree','Degree',true,20),('pharmacist','practising_certificate','Practising certificate',true,30),
 ('lab_technician','lab_council_registration','Lab council registration',true,10),('lab_technician','diploma','Diploma',true,20),
 ('physiotherapist','physiotherapy_registration','Physiotherapy registration',true,10),('physiotherapist','degree','Degree',true,20),('physiotherapist','practising_certificate','Practising certificate',true,30),
 ('counsellor','professional_registration','Counselling or psychology registration',true,10),('counsellor','degree','Degree',true,20),('counsellor','supervised_hours','Supervised hours',false,30),
 ('nursing_assistant','assistant_certificate','Nursing assistant certificate',true,10),('nursing_assistant','first_aid','First aid',true,20),('nursing_assistant','national_id','National ID',true,30),
 ('hiv_counsellor','counselling_certificate','Counselling certificate',true,10),('hiv_counsellor','hiv_training','HIV testing and counselling training',true,20),('hiv_counsellor','facility_authorisation','Ministry of Health or facility authorisation',true,30),('hiv_counsellor','national_id','National ID',true,40),
 ('angel_investor','identity_verification','Identity verification',true,10),('angel_investor','investment_track_record','Proof of investment track record or portfolio',true,20),('angel_investor','ticket_size_range','Ticket size range',false,30),('angel_investor','stage_focus','Stage focus',false,40),
 ('business_mentor','experience_five_years','Experience 5+ years',false,10),('business_mentor','case_studies','Case studies',false,20),('business_mentor','referees','Referees',false,30),
 ('duwah_practitioner','endorsement','Community or religious endorsement letter',true,10),('duwah_practitioner','references','References',false,20),('duwah_practitioner','experience','Experience years',false,30),
 ('ceremony_officiant','endorsement','Endorsement',true,10),('ceremony_officiant','references','References',false,20),
 ('traditional_performer','showreel','Showreel',false,10),('traditional_performer','group_membership','Group membership',false,20),
 ('traditional_healer','association_registration','Registration with relevant association or local authority',true,10),('traditional_healer','referees','Referees',false,20),
 ('research_mentor','degree_in_field','Degree in the field',true,10),('research_mentor','masters_phd','Master’s or PhD',true,20),('research_mentor','published_work','Published work or portfolio',false,30),('research_mentor','subject_specialisation','Subject specialisation',false,40),('research_mentor','references','References',false,50)
on conflict (role_slug, slug) do update set name = excluded.name,
  is_evidence = excluded.is_evidence, sort_order = excluded.sort_order;

update public.role_kinds set name = name where role_slug = 'driver';
insert into public.role_kinds (role_slug, slug, name, sort_order) values
 ('driver','personal_driver','Personal driver',60),
 ('driver','chauffeur_executive','Chauffeur (executive)',70),
 ('driver','boda_rider','Boda rider',80),
 ('driver','airport_school_runs','Airport / school runs',90),
 ('doctor','circumcision_adult_infant','Circumcision (adult and infant)',90),
 ('nurse','antenatal_postnatal','Antenatal & postnatal care',70),
 ('nurse','family_planning','Family planning',80),
 ('nurse','hiv_testing_counselling','HIV testing & counselling',90)
on conflict (role_slug, slug) do update set name = excluded.name,
  sort_order = excluded.sort_order;
insert into public.role_qualifications (role_slug, slug, name, is_evidence, sort_order)
values
 ('driver','chauffeur_executive_experience','Chauffeur or executive driving experience',false,60),
 ('driver','certificate_good_conduct','Certificate of good conduct',true,70)
on conflict (role_slug, slug) do update set name = excluded.name,
  is_evidence = excluded.is_evidence, sort_order = excluded.sort_order;
update public.role_qualifications set expires_after_days = 365
where slug in ('council_registration','practising_certificate',
  'clinical_officers_council_registration','practising_licence',
  'specialist_registration','medical_council_registration',
  'optometry_registration','dental_council_registration',
  'pharmacy_board_registration','lab_council_registration',
  'physiotherapy_registration','professional_registration',
  'facility_authorisation','association_registration');

-- Licensing evidence is independent of company registration and expires yearly.
insert into public.verification_requirements
  (scope_type, scope_id, provider_type, identity_required, phone_required,
   provider_verification_required, evidence_requirements, required_evidence,
   expires_after_days, is_active)
values
 ('capability','driving_school','company',false,false,true,
  '["school_licence"]'::jsonb,array['school_licence'],365,true),
 ('capability','driving_school_driver_training','company',false,false,true,
  '["school_licence"]'::jsonb,array['school_licence'],365,true)
on conflict (scope_type, scope_id, provider_type) do update set
  provider_verification_required = true,
  evidence_requirements = excluded.evidence_requirements,
  required_evidence = excluded.required_evidence,
  expires_after_days = 365, is_active = true;

-- Keep the trust gate private: a proof policy is metadata and the verification
-- RPC remains the only path to a verified badge.
update public.need_capabilities set policy = 'required_proof'
where slug in ('driving_school','driving_school_driver_training');

-- Cross-category search data is exposed as one read-only catalog view.
create or replace view public.v_catalog_search as
select 'category'::text as result_type, c.slug, c.slug as category_slug,
       c.name as label, c.aliases, c.name as parent_category,
       c.sort_order, null::text as capability_type
from public.need_categories c where c.is_active
union all
select case when n.capability_type = 'work' then 'role' else 'service' end,
       n.slug, n.category_slug, n.name, n.aliases, c.name,
       n.sort_order, n.capability_type
from public.need_capabilities n
join public.need_categories c on c.slug = n.category_slug
where n.is_active and c.is_active
union all
select 'role', cr.capability_slug, cr.category_slug, cr.name, cr.aliases,
       c.name, n.sort_order, 'work'
from public.capability_roles cr
join public.need_capabilities n on n.slug = cr.capability_slug and n.is_active
join public.need_categories c on c.slug = cr.category_slug and c.is_active
where cr.is_active
union all
select 'kind', rk.role_slug || ':' || rk.slug, cr.category_slug, rk.name,
       rk.aliases || array[rk.slug], c.name, rk.sort_order, 'work'
from public.role_kinds rk
join public.capability_roles cr on cr.slug = rk.role_slug and cr.is_active
join public.need_categories c on c.slug = cr.category_slug and c.is_active;
grant select on public.v_catalog_search to authenticated;
revoke all on public.v_catalog_search from anon, public;

-- Fallback search aliases for existing catalog items called out in the plan.
update public.need_categories set aliases = array['angel investor','investor','seed funding','startup funding']
where slug = 'business_investment';
update public.need_categories set aliases = array['clinic','health centre','dispensary']
where slug = 'health_medical';
update public.need_capabilities set aliases = array['course work','coursework','assignment help','homework']
where slug = 'coursework_tutoring';
update public.need_capabilities set aliases = array['FYP','capstone','project defence']
where slug = 'final_year_project_support';
update public.need_capabilities set aliases = array['thesis','research paper','proposal']
where slug = 'research_dissertation_guidance';
update public.need_capabilities set aliases = array['SPSS','statistics','STATA']
where slug = 'data_analysis_help';
-- Preserve the stable driving-school slug and category; route it into all three
-- discovery groups without relocating its canonical category.
-- Foreman acceptance case: the seed previously marked its trade certificate as
-- non-evidence, so Screen F had no proof-enabled qualification to upload.
update public.role_qualifications set is_evidence = true
where role_slug = 'foreman_supervisor' and slug = 'trade_test_certificate';

-- The production upload component enforces 5 MB; make the storage bucket agree.
insert into storage.buckets (id, name, public, file_size_limit)
values ('provider-evidence', 'provider-evidence', false, 5242880)
on conflict (id) do update set public = false, file_size_limit = 5242880;

drop policy if exists "provider evidence storage owner upload"
  on storage.objects;
create policy "provider evidence storage owner upload" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'provider-evidence'
    and (storage.foldername(name))[1] = 'evidence'
    and (storage.foldername(name))[2] = auth.uid()::text
  );
drop policy if exists "provider evidence storage owner read"
  on storage.objects;
create policy "provider evidence storage owner read" on storage.objects
  for select to authenticated using (
    bucket_id = 'provider-evidence'
    and (((storage.foldername(name))[1] = 'evidence'
      and (storage.foldername(name))[2] = auth.uid()::text)
      or private.is_admin())
  );

create or replace function public.cleanup_unrecorded_provider_evidence(
  p_object_path text
) returns boolean
language plpgsql security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null or p_object_path not like 'evidence/' || v_user::text || '/%' then
    raise exception 'Evidence object does not belong to current user.'
      using errcode = '42501';
  end if;
  if exists (select 1 from public.provider_capability_evidence
      where file_url = p_object_path)
     or exists (select 1 from public.job_profile_qualification_answers
      where evidence_object_path = p_object_path)
     or exists (select 1 from public.provider_role_qualification_claims
      where evidence_object_path = p_object_path)
     or exists (select 1 from public.provider_company_verification_submissions
      where file_path = p_object_path) then
    return false;
  end if;
  delete from storage.objects
  where bucket_id = 'provider-evidence' and name = p_object_path
    and owner_id = v_user::text;
  return found;
end;
$$;
revoke all on function public.cleanup_unrecorded_provider_evidence(text)
  from public, anon;
grant execute on function public.cleanup_unrecorded_provider_evidence(text)
  to authenticated;

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
  select claim.*, pc.capability_slug, pc.user_id, rq.expires_after_days
  into v_claim
  from public.provider_role_qualification_claims claim
  join public.provider_capabilities pc on pc.id = claim.provider_capability_id
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

-- ============================================================================
-- END MERGED SECTION (12/52): patch_catalog_expansion_v3.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (13/52): patch_role_qualification_evidence_flags.sql
-- ============================================================================

-- Restore proof eligibility after role catalog seeds that default qualifications
-- to self-declared and overwrite the canonical evidence flags.
begin;

update public.role_qualifications rq
set is_evidence = true
from (
  values
    ('developer', 'cloud_certification_aws_azure_gcp'),
    ('project_manager', 'agile_scrum_certified'),
    ('marketer_specialist', 'google_ads_meta_certified'),
    ('accountant_finance_officer', 'practising_certificate'),
    ('lawyer_legal_officer', 'bar_admission_practising_certificate'),
    ('engineer', 'registered_with_engineers_board'),
    ('architect_designer', 'registered_architect'),
    ('teacher_tutor', 'teaching_certificate_degree'),
    ('teacher_tutor', 'registered_with_teaching_board'),
    ('trainer_instructor', 'trade_certificate'),
    ('placement_coordinator', 'counselling_certificate'),
    ('event_manager_planner', 'event_planning_certificate'),
    ('caterer_chef', 'food_handler_certificate'),
    ('photographer_videographer', 'drone_licence'),
    ('makeup_artist', 'cosmetology_certificate'),
    ('makeup_artist', 'hygiene_certification'),
    ('hair_stylist', 'cosmetology_certificate'),
    ('hair_stylist', 'salon_licence'),
    ('salon_studio_manager', 'business_licence'),
    ('site_manager', 'registered_with_engineers_contractors_board'),
    ('site_manager', 'safety_certification_osha'),
    ('foreman_supervisor', 'trade_test_certificate'),
    ('skilled_tradesperson', 'licence_electrical_plumbing'),
    ('surveyor', 'registered_surveyor'),
    ('solar_electrical_technician', 'electrical_licence'),
    ('solar_electrical_technician', 'solar_installer_certificate'),
    ('borehole_water_technician', 'water_technician_certificate'),
    ('energy_engineer', 'registered_engineer'),
    ('driver', 'valid_driving_licence_class'),
    ('driver', 'defensive_driving_certificate'),
    ('fleet_operations_manager', 'transport_licence'),
    ('dispatcher_coordinator', 'customs_clearing_licence'),
    ('machine_operator', 'operator_licence_certificate'),
    ('machine_operator', 'safety_osha_certificate'),
    ('equipment_mechanic', 'mechanic_trade_certificate'),
    ('site_supervisor', 'safety_certification'),
    ('veterinary_livestock_officer', 'veterinary_licence'),
    ('veterinary_livestock_officer', 'vaccination_certification'),
    ('farm_worker_operator', 'tractor_licence'),
    ('farm_worker_operator', 'pesticide_handling_certificate'),
    ('clearing_customs_agent', 'customs_clearing_licence'),
    ('travel_agent_consultant', 'iata_certification'),
    ('travel_agent_consultant', 'travel_agency_licence'),
    ('tour_guide', 'tourism_board_guide_licence'),
    ('tour_guide', 'first_aid_certificate'),
    ('driver_guide', 'valid_driving_licence_class'),
    ('driver_guide', 'tourism_licence'),
    ('massage_therapist', 'massage_therapy_certificate'),
    ('massage_therapist', 'hygiene_certification'),
    ('spa_therapist', 'cosmetology_spa_certificate'),
    ('spa_therapist', 'hygiene_certification')
) as eligible(role_slug, qualification_slug)
where rq.role_slug = eligible.role_slug
  and rq.slug = eligible.qualification_slug
  and not rq.is_evidence;

commit;

-- ============================================================================
-- END MERGED SECTION (13/52): patch_role_qualification_evidence_flags.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (14/52): patch_provider_profile_documents.sql
-- ============================================================================

-- Extend existing qualification claims and company verification submissions
-- to support user-managed evidence documents without introducing new tables.
begin;

update public.role_qualifications
set is_evidence = true
where (role_slug, slug) in (
  ('developer', 'cloud_certification_aws_azure_gcp'),
  ('project_manager', 'agile_scrum_certified'),
  ('marketer_specialist', 'google_ads_meta_certified'),
  ('accountant_finance_officer', 'practising_certificate'),
  ('lawyer_legal_officer', 'bar_admission_practising_certificate'),
  ('engineer', 'registered_with_engineers_board'),
  ('architect_designer', 'registered_architect'),
  ('teacher_tutor', 'teaching_certificate_degree'),
  ('teacher_tutor', 'registered_with_teaching_board'),
  ('trainer_instructor', 'trade_certificate'),
  ('placement_coordinator', 'counselling_certificate'),
  ('event_manager_planner', 'event_planning_certificate'),
  ('caterer_chef', 'food_handler_certificate'),
  ('photographer_videographer', 'drone_licence'),
  ('makeup_artist', 'cosmetology_certificate'),
  ('makeup_artist', 'hygiene_certification'),
  ('hair_stylist', 'cosmetology_certificate'),
  ('hair_stylist', 'salon_licence'),
  ('salon_studio_manager', 'business_licence'),
  ('site_manager', 'registered_with_engineers_contractors_board'),
  ('site_manager', 'safety_certification_osha'),
  ('foreman_supervisor', 'trade_test_certificate'),
  ('skilled_tradesperson', 'licence_electrical_plumbing'),
  ('surveyor', 'registered_surveyor'),
  ('solar_electrical_technician', 'electrical_licence'),
  ('solar_electrical_technician', 'solar_installer_certificate'),
  ('borehole_water_technician', 'water_technician_certificate'),
  ('energy_engineer', 'registered_engineer'),
  ('driver', 'valid_driving_licence_class'),
  ('driver', 'defensive_driving_certificate'),
  ('fleet_operations_manager', 'transport_licence'),
  ('dispatcher_coordinator', 'customs_clearing_licence'),
  ('machine_operator', 'operator_licence_certificate'),
  ('machine_operator', 'safety_osha_certificate'),
  ('equipment_mechanic', 'mechanic_trade_certificate'),
  ('site_supervisor', 'safety_certification'),
  ('veterinary_livestock_officer', 'veterinary_licence'),
  ('veterinary_livestock_officer', 'vaccination_certification'),
  ('farm_worker_operator', 'tractor_licence'),
  ('farm_worker_operator', 'pesticide_handling_certificate'),
  ('clearing_customs_agent', 'customs_clearing_licence'),
  ('travel_agent_consultant', 'iata_certification'),
  ('travel_agent_consultant', 'travel_agency_licence'),
  ('tour_guide', 'tourism_board_guide_licence'),
  ('tour_guide', 'first_aid_certificate'),
  ('driver_guide', 'valid_driving_licence_class'),
  ('driver_guide', 'tourism_licence'),
  ('house_help', 'national_id'),
  ('nanny', 'national_id'),
  ('nanny', 'police_clearance'),
  ('nanny', 'first_aid'),
  ('home_cook', 'food_handler_certificate'),
  ('home_carer', 'caregiving_certificate'),
  ('home_carer', 'first_aid'),
  ('home_carer', 'national_id'),
  ('driving_instructor', 'instructor_licence'),
  ('driving_instructor', 'valid_driving_licence'),
  ('massage_therapist', 'massage_therapy_certificate'),
  ('massage_therapist', 'hygiene_certification'),
  ('spa_therapist', 'cosmetology_spa_certificate'),
  ('spa_therapist', 'hygiene_certification'),
  ('spa_manager', 'business_licence'),
  ('nurse', 'council_registration'),
  ('nurse', 'diploma_degree'),
  ('nurse', 'practising_certificate'),
  ('doctor', 'council_registration'),
  ('doctor', 'medical_degree'),
  ('doctor', 'practising_certificate'),
  ('clinician', 'council_registration'),
  ('clinician', 'diploma'),
  ('clinician', 'practising_licence'),
  ('medical_specialist', 'specialist_registration'),
  ('medical_specialist', 'postgraduate_degree'),
  ('medical_specialist', 'medical_council_registration'),
  ('optometrist', 'optometry_registration'),
  ('optometrist', 'diploma_degree'),
  ('optometrist', 'practising_certificate'),
  ('dentist', 'dental_council_registration'),
  ('dentist', 'bds'),
  ('dentist', 'practising_certificate'),
  ('pharmacist', 'pharmacy_board_registration'),
  ('pharmacist', 'degree'),
  ('pharmacist', 'practising_certificate'),
  ('lab_technician', 'lab_council_registration'),
  ('lab_technician', 'diploma'),
  ('physiotherapist', 'physiotherapy_registration'),
  ('physiotherapist', 'degree'),
  ('physiotherapist', 'practising_certificate'),
  ('counsellor', 'professional_registration'),
  ('counsellor', 'degree'),
  ('nursing_assistant', 'assistant_certificate'),
  ('nursing_assistant', 'first_aid'),
  ('nursing_assistant', 'national_id'),
  ('hiv_counsellor', 'counselling_certificate'),
  ('hiv_counsellor', 'hiv_training'),
  ('hiv_counsellor', 'facility_authorisation'),
  ('hiv_counsellor', 'national_id'),
  ('angel_investor', 'identity_verification'),
  ('angel_investor', 'investment_track_record'),
  ('duwah_practitioner', 'endorsement'),
  ('ceremony_officiant', 'endorsement'),
  ('traditional_healer', 'association_registration'),
  ('research_mentor', 'degree_in_field'),
  ('research_mentor', 'masters_phd'),
  ('driver', 'certificate_good_conduct')
);

alter table public.provider_company_verification_submissions
  add column if not exists id uuid,
  add column if not exists file_name text;

update public.provider_company_verification_submissions
set id = gen_random_uuid()
where id is null;

update public.provider_company_verification_submissions
set file_name = regexp_replace(file_path, '^.*/', '')
where file_name is null or btrim(file_name) = '';

alter table public.provider_company_verification_submissions
  alter column id set default gen_random_uuid(),
  alter column id set not null,
  alter column file_name set default '',
  alter column file_name set not null;

do $$
declare
  v_primary_key text;
begin
  select constraint_row.conname
    into v_primary_key
  from pg_constraint constraint_row
  where constraint_row.conrelid =
      'public.provider_company_verification_submissions'::regclass
    and constraint_row.contype = 'p';

  if v_primary_key is not null then
    execute format(
      'alter table public.provider_company_verification_submissions drop constraint %I',
      v_primary_key
    );
  end if;
end;
$$;

alter table public.provider_company_verification_submissions
  add constraint provider_company_verification_submissions_pkey primary key (id);

alter table public.provider_company_verification_submissions
  drop constraint if exists provider_company_verification_submissions_document_type_check;
alter table public.provider_company_verification_submissions
  add constraint provider_company_verification_submissions_document_type_check
  check (document_type in (
    'business_registration',
    'business_licence',
    'certificate',
    'other'
  ));

create or replace function private.cleanup_provider_company_document_object()
returns trigger
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
begin
  if tg_op = 'DELETE' or old.file_path is distinct from new.file_path then
    delete from storage.objects
    where bucket_id = 'provider-evidence'
      and name = old.file_path
      and owner_id = old.user_id::text;
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_cleanup_provider_company_document_object
  on public.provider_company_verification_submissions;
create trigger trg_cleanup_provider_company_document_object
  before update of file_path or delete
  on public.provider_company_verification_submissions
  for each row execute function private.cleanup_provider_company_document_object();

create or replace function public.save_provider_company_document(
  p_category_slug text,
  p_document_type text,
  p_file_path text,
  p_file_name text,
  p_submission_id uuid default null
) returns uuid
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_submission_id uuid := p_submission_id;
  v_size bigint;
  v_mime text;
  v_country text;
  v_enabled text;
  v_existing_status text;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  if p_document_type not in (
    'business_registration', 'business_licence', 'certificate', 'other'
  ) or nullif(btrim(p_file_name), '') is null
     or length(p_file_name) > 255 then
    raise exception 'Company document details are invalid.' using errcode = 'P0204';
  end if;
  if not exists (
    select 1 from public.provider_category_profiles pcp
    where pcp.user_id = v_user
      and pcp.category_slug = p_category_slug
      and pcp.provider_type = 'company'
  ) then
    raise exception 'Choose Company / Organization for this category first.'
      using errcode = 'P0202';
  end if;
  if not exists (
    select 1 from public.need_categories c
    where c.slug = p_category_slug and c.is_active
  ) then
    raise exception 'This provider category is not active.' using errcode = 'P0201';
  end if;
  select country into v_country
  from public.profiles
  where id = v_user;
  select setting_value into v_enabled
  from public.system_settings
  where setting_key = 'capability_profiles_enabled'
    and is_public
    and (country = v_country or country is null)
  order by (country = v_country) desc nulls last
  limit 1;
  if lower(coalesce(v_enabled, 'false')) not in ('true', '1') then
    raise exception 'Provider services are not enabled in your market.'
      using errcode = 'P0202';
  end if;
  if p_file_path is null
     or position('..' in p_file_path) > 0
     or p_file_path not like
       'evidence/' || v_user::text || '/' || p_category_slug ||
       '/company/' || p_document_type || '/%' then
    raise exception 'Company document file path is invalid.' using errcode = 'P0205';
  end if;
  select (o.metadata->>'size')::bigint,
         lower(coalesce(o.metadata->>'mimetype', ''))
    into v_size, v_mime
  from storage.objects o
  where o.bucket_id = 'provider-evidence'
    and o.name = p_file_path
    and o.owner_id = v_user::text;
  if not found or v_size is null or v_size < 1 or v_size > 5242880
     or v_mime not in ('image/jpeg', 'image/png', 'application/pdf') then
    raise exception 'Company evidence must be an owned JPG, PNG, or PDF up to 5 MB.'
      using errcode = 'P0205';
  end if;

  if v_submission_id is not null then
    select status into v_existing_status
    from public.provider_company_verification_submissions
    where id = v_submission_id
      and user_id = v_user
      and category_slug = p_category_slug
    for update;
    if not found then
      raise exception 'Company document was not found.' using errcode = 'P0212';
    end if;
    if v_existing_status = 'approved' then
      raise exception 'Approved company documents are locked and cannot be replaced.'
        using errcode = 'P0206';
    end if;
    update public.provider_company_verification_submissions
    set document_type = p_document_type,
        file_path = p_file_path,
        file_name = p_file_name,
        status = 'pending',
        reject_reason = null,
        reviewed_by = null,
        reviewed_at = null,
        updated_at = now()
    where id = v_submission_id;
  else
    insert into public.provider_company_verification_submissions(
      user_id, category_slug, document_type, file_path, file_name, status,
      reject_reason, reviewed_by, reviewed_at
    ) values (
      v_user, p_category_slug, p_document_type, p_file_path, p_file_name,
      'pending', null, null, null
    )
    returning id into v_submission_id;
  end if;

  insert into public.audit_logs(
    user_id, event_type, entity_type, action, new_values
  ) values (
    v_user, 'admin_action', 'provider_company_verification',
    case when p_submission_id is null then 'submit_company_document'
      else 'replace_company_document' end,
    jsonb_build_object(
      'submission_id', v_submission_id,
      'category_slug', p_category_slug,
      'document_type', p_document_type,
      'file_name', p_file_name
    )
  );
  return v_submission_id;
end;
$$;
revoke all on function public.save_provider_company_document(text, text, text, text, uuid)
  from public, anon;
grant execute on function public.save_provider_company_document(text, text, text, text, uuid)
  to authenticated;

create or replace function public.delete_provider_company_document(
  p_submission_id uuid
) returns void
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_row public.provider_company_verification_submissions%rowtype;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  select * into v_row
  from public.provider_company_verification_submissions
  where id = p_submission_id and user_id = v_user
  for update;
  if not found then
    raise exception 'Company document was not found.' using errcode = 'P0212';
  end if;
  if v_row.status = 'approved' then
    raise exception 'Approved documents cannot be removed. Replace the document to request a new review.'
      using errcode = 'P0206';
  end if;
  insert into public.audit_logs(
    user_id, event_type, entity_type, action, old_values
  ) values (
    v_user, 'admin_action', 'provider_company_verification',
    'remove_company_document',
    jsonb_build_object(
      'submission_id', v_row.id,
      'category_slug', v_row.category_slug,
      'document_type', v_row.document_type,
      'file_name', v_row.file_name
    )
  );
  delete from public.provider_company_verification_submissions
  where id = v_row.id;
end;
$$;
revoke all on function public.delete_provider_company_document(uuid)
  from public, anon;
grant execute on function public.delete_provider_company_document(uuid)
  to authenticated;

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

create or replace function public.submit_provider_company_verification(
  p_category_slug text,
  p_document_type text,
  p_file_path text
) returns void
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
begin
  if p_document_type not in ('business_registration', 'business_licence') then
    raise exception 'Company verification document type is invalid.'
      using errcode = 'P0204';
  end if;
  perform public.save_provider_company_document(
    p_category_slug,
    p_document_type,
    p_file_path,
    regexp_replace(p_file_path, '^.*/', ''),
    null
  );
end;
$$;
revoke all on function public.submit_provider_company_verification(text, text, text)
  from public, anon;
grant execute on function public.submit_provider_company_verification(text, text, text)
  to authenticated;

create or replace function public.admin_review_provider_company_verification(
  p_user_id uuid,
  p_category_slug text,
  p_document_type text,
  p_action text,
  p_reject_reason text default null
) returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_submission_id uuid;
  v_count integer;
begin
  if not private.is_admin() then
    raise exception 'Admin access required.' using errcode = '42501';
  end if;
  select count(*), (array_agg(id))[1] into v_count, v_submission_id
  from public.provider_company_verification_submissions
  where user_id = p_user_id
    and category_slug = p_category_slug
    and document_type = p_document_type
    and status = 'pending';
  if v_count <> 1 then
    raise exception 'Review the individual company document by submission id.'
      using errcode = 'P0212';
  end if;
  return public.admin_review_provider_company_document(
    v_submission_id, p_action, p_reject_reason
  );
end;
$$;
revoke all on function public.admin_review_provider_company_verification(uuid, text, text, text, text)
  from public, anon;
grant execute on function public.admin_review_provider_company_verification(uuid, text, text, text, text)
  to authenticated;

create or replace view public.v_my_capability_status
with (security_invoker = true)
as
with latest_rejection as (
  select distinct on (e.provider_capability_id)
    e.provider_capability_id, e.reject_reason, e.reviewed_at
  from public.provider_capability_evidence e
  where e.status = 'rejected'
  order by e.provider_capability_id, e.reviewed_at desc nulls last, e.created_at desc
),
evidence_summary as (
  select
    e.provider_capability_id,
    count(*) filter (where e.status = 'pending') as pending_count,
    count(*) filter (where e.status = 'approved') as approved_count,
    count(*) filter (where e.status = 'rejected') as rejected_count,
    count(*) filter (where e.status = 'expired') as expired_count
  from public.provider_capability_evidence e
  group by e.provider_capability_id
),
qualification_summary as (
  select
    claim.provider_capability_id,
    jsonb_agg(
      jsonb_build_object(
        'role_slug', claim.role_slug,
        'qualification_slug', claim.qualification_slug,
        'qualification_name', rq.name,
        'is_evidence', rq.is_evidence,
        'status', case
          when claim.status = 'verified'
               and claim.expires_at is not null
               and claim.expires_at <= now() then 'expired'
          else claim.status
        end,
        'has_evidence', claim.evidence_object_path is not null,
        'reject_reason', claim.reject_reason,
        'verified_at', claim.reviewed_at
      )
      order by claim.role_slug, claim.qualification_slug
    ) as claims
  from public.provider_role_qualification_claims claim
  join public.role_qualifications rq
    on rq.role_slug = claim.role_slug
   and rq.slug = claim.qualification_slug
  where claim.is_claimed
  group by claim.provider_capability_id
)
select
  pc.id as provider_capability_id,
  pc.user_id,
  pc.capability_slug,
  nc.name as capability_name,
  nc.category_slug,
  cat.name as category_name,
  cat.icon as category_icon,
  pc.verification_level,
  pc.metadata,
  case
    when pc.verification_level = 'provider_verified' then 'provider_verified'
    when coalesce(es.pending_count, 0) > 0 then 'pending_review'
    when coalesce(es.rejected_count, 0) > 0 then 'rejected'
    when coalesce(es.expired_count, 0) > 0 then 'expired'
    else 'self_declared'
  end as capability_status,
  coalesce(es.pending_count, 0)::int as pending_evidence_count,
  coalesce(es.approved_count, 0)::int as approved_evidence_count,
  coalesce(es.rejected_count, 0)::int as rejected_evidence_count,
  coalesce(es.expired_count, 0)::int as expired_evidence_count,
  lr.reject_reason as latest_reject_reason,
  pc.verified_by,
  pc.verified_at,
  pc.created_at,
  nc.capability_type,
  coalesce(qs.claims, '[]'::jsonb) as role_qualification_claims
from public.provider_capabilities pc
join public.need_capabilities nc on nc.slug = pc.capability_slug
join public.need_categories cat on cat.slug = nc.category_slug
left join evidence_summary es on es.provider_capability_id = pc.id
left join latest_rejection lr on lr.provider_capability_id = pc.id
left join qualification_summary qs on qs.provider_capability_id = pc.id
where pc.user_id = auth.uid() or private.is_admin();
grant select on public.v_my_capability_status to authenticated;

create or replace view public.v_my_capability_policy_status
with (security_invoker = true)
as
select
  v.provider_capability_id,
  v.user_id,
  v.capability_slug,
  v.capability_name,
  v.category_slug,
  v.category_name,
  v.category_icon,
  v.verification_level,
  v.metadata,
  v.capability_status,
  v.pending_evidence_count,
  v.approved_evidence_count,
  v.rejected_evidence_count,
  v.expired_evidence_count,
  v.latest_reject_reason,
  v.verified_by,
  v.verified_at,
  v.created_at,
  v.capability_type,
  nc.verification_policy,
  pc.is_active and private.provider_capability_is_eligible(pc.id) as is_active,
  v.role_qualification_claims
from public.v_my_capability_status v
join public.provider_capabilities pc on pc.id = v.provider_capability_id
join public.need_capabilities nc on nc.slug = pc.capability_slug;
grant select on public.v_my_capability_policy_status to authenticated;

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
  if v_claim.status = 'verified'
     and (v_claim.expires_at is null or v_claim.expires_at > now()) then
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

-- Keep a verified company's legal identity consistent with its approved proof.
create or replace function private.lock_verified_company_identity()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if (new.company_name is distinct from old.company_name
      or new.registration_number is distinct from old.registration_number)
     and exists (
       select 1
       from public.provider_company_verification_submissions submission
       where submission.user_id = old.user_id
         and submission.category_slug = old.category_slug
         and submission.status = 'approved'
     ) then
    raise exception 'Verified company name and registration number are locked.'
      using errcode = 'P0206';
  end if;
  return new;
end;
$$;
revoke all on function private.lock_verified_company_identity()
  from public, anon, authenticated;
drop trigger if exists trg_lock_verified_company_identity
  on public.provider_company_profiles;
create trigger trg_lock_verified_company_identity
  before update of company_name, registration_number
  on public.provider_company_profiles
  for each row execute function private.lock_verified_company_identity();

commit;

-- ============================================================================
-- END MERGED SECTION (14/52): patch_provider_profile_documents.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (15/52): activate_provider_qualification_uploads.sql
-- ============================================================================

-- Repair qualification evidence submissions for work profiles.
--
-- The app stores one role per provider_capabilities row using root-level
-- role_id and qualification_ids fields. Older rows may store a `roles` array.
-- This function supports both shapes, refreshes the trigger, and backfills
-- both formats so submitted evidence can find its qualification claim.
-- Safe to rerun. Run in the Supabase SQL Editor for the same project as the app.

begin;

create or replace function private.sync_provider_role_qualification_claims()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_category_slug text;
  v_roles jsonb;
  v_role jsonb;
  v_role_slug text;
  v_qualifications jsonb;
  v_qualification_slug text;
begin
  select nc.category_slug
  into v_category_slug
  from public.need_capabilities nc
  where nc.slug = new.capability_slug;

  v_roles := case
    when jsonb_typeof(coalesce(new.metadata, '{}'::jsonb)->'roles') = 'array'
      then coalesce(new.metadata, '{}'::jsonb)->'roles'
    when jsonb_typeof(coalesce(new.metadata, '{}'::jsonb)->'role_id') = 'string'
      then jsonb_build_array(coalesce(new.metadata, '{}'::jsonb))
    else '[]'::jsonb
  end;

  update public.provider_role_qualification_claims
  set is_claimed = false,
      updated_at = now()
  where provider_capability_id = new.id
    and is_claimed;

  for v_role in select value from jsonb_array_elements(v_roles)
  loop
    v_role_slug := nullif(btrim(v_role->>'role_id'), '');
    if v_role_slug is null or not exists (
      select 1
      from public.capability_roles cr
      where cr.slug = v_role_slug
        and cr.is_active
        and (
          cr.capability_slug = new.capability_slug
          or (cr.capability_slug is null and cr.category_slug = v_category_slug)
        )
    ) then
      continue;
    end if;

    v_qualifications := case
      when jsonb_typeof(v_role->'qualification_ids') = 'array'
        then v_role->'qualification_ids'
      else '[]'::jsonb
    end;

    for v_qualification_slug in
      select jsonb_array_elements_text(v_qualifications)
    loop
      if exists (
        select 1
        from public.role_qualifications rq
        where rq.role_slug = v_role_slug
          and rq.slug = v_qualification_slug
      ) then
        insert into public.provider_role_qualification_claims
          (provider_capability_id, role_slug, qualification_slug, is_claimed)
        values (new.id, v_role_slug, v_qualification_slug, true)
        on conflict (provider_capability_id, role_slug, qualification_slug)
        do update set
          is_claimed = true,
          updated_at = now();
      end if;
    end loop;
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_sync_provider_role_qualification_claims
  on public.provider_capabilities;
create trigger trg_sync_provider_role_qualification_claims
  after insert or update of metadata, capability_slug
  on public.provider_capabilities
  for each row
  execute function private.sync_provider_role_qualification_claims();

-- Re-fire the trigger for existing profiles in either metadata shape.
update public.provider_capabilities
set metadata = metadata
where metadata ? 'roles'
   or metadata ? 'role_id';

commit;

-- ============================================================================
-- END MERGED SECTION (15/52): activate_provider_qualification_uploads.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (16/52): patch_provider_capability_badges.sql
-- ============================================================================

-- Complete the provider badge for the capability whose role evidence an admin
-- approves. Existing approved evidence on the same capability keeps its badge
-- if another item is rejected or expires. Safe to rerun.

begin;

create or replace function public.admin_review_provider_role_qualification(
  p_claim_id uuid,
  p_action text,
  p_reject_reason text default null,
  p_expires_at timestamptz default null
)
returns boolean
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_admin uuid := auth.uid();
  v_claim record;
begin
  if not private.is_admin() then
    raise exception 'Unauthorized: Admin access required.' using errcode = '42501';
  end if;
  if p_action not in ('approve', 'reject', 'expire') then
    raise exception 'Action must be approve, reject, or expire.' using errcode = '22023';
  end if;

  select claim.*, pc.capability_slug, pc.user_id
  into v_claim
  from public.provider_role_qualification_claims claim
  join public.provider_capabilities pc on pc.id = claim.provider_capability_id
  where claim.id = p_claim_id
  for update of claim;

  if not found then
    raise exception 'Provider role qualification claim not found.' using errcode = 'P0212';
  end if;
  if p_action = 'approve' and v_claim.status <> 'pending_review' then
    raise exception 'Only submitted qualification evidence can be approved.' using errcode = '22023';
  end if;
  if p_action = 'approve' and p_expires_at is not null and p_expires_at <= now() then
    raise exception 'Evidence expiry must be in the future.' using errcode = '22023';
  end if;

  update public.provider_role_qualification_claims
  set status = case
        when p_action = 'approve' then 'verified'
        when p_action = 'reject' then 'rejected'
        else 'expired'
      end,
      reject_reason = case when p_action = 'reject' then coalesce(p_reject_reason, '') else null end,
      expires_at = case when p_action = 'approve' then p_expires_at else expires_at end,
      reviewed_by = v_admin,
      reviewed_at = now(),
      updated_at = now()
  where id = p_claim_id;

  -- The approval belongs to this exact provider capability, not the whole
  -- account or category, so only that capability receives the badge.
  if p_action = 'approve' then
    update public.provider_capabilities
    set verification_level = 'provider_verified',
        verified_by = v_admin,
        verified_at = now()
    where id = v_claim.provider_capability_id;
  elsif not exists (
    select 1
    from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = v_claim.provider_capability_id
      and claim.is_claimed
      and claim.status = 'verified'
      and (claim.expires_at is null or claim.expires_at > now())
  ) and not exists (
    select 1
    from public.provider_capability_evidence evidence
    where evidence.provider_capability_id = v_claim.provider_capability_id
      and evidence.status = 'approved'
      and (evidence.expires_at is null or evidence.expires_at > now())
  ) then
    update public.provider_capabilities
    set verification_level = 'self_declared',
        verified_by = null,
        verified_at = null
    where id = v_claim.provider_capability_id;
  end if;

  insert into public.audit_logs
    (user_id, event_type, entity_type, entity_id, action, new_values)
  values
    (v_admin, 'admin_action', 'provider_role_qualification_claim', p_claim_id,
     'review_provider_role_qualification',
     jsonb_build_object(
       'action', p_action,
       'provider_capability_id', v_claim.provider_capability_id,
       'capability_slug', v_claim.capability_slug,
       'role_slug', v_claim.role_slug,
       'qualification_slug', v_claim.qualification_slug,
       'reject_reason', p_reject_reason,
       'expires_at', p_expires_at
     ));

  return true;
end;
$$;

revoke all on function public.admin_review_provider_role_qualification(uuid, text, text, timestamptz)
  from public, anon;
grant execute on function public.admin_review_provider_role_qualification(uuid, text, text, timestamptz)
  to authenticated;

-- Also keep badges synchronized for capability-level proof approvals. This
-- preserves the badge while any approved, unexpired proof remains on the same
-- capability, then clears it once none remain.
create or replace function private.sync_provider_capability_badge_from_approved_evidence()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_reviewer uuid;
  v_reviewed_at timestamptz;
begin
  if exists (
    select 1
    from public.provider_capability_evidence evidence
    where evidence.provider_capability_id = new.provider_capability_id
      and evidence.status = 'approved'
      and (evidence.expires_at is null or evidence.expires_at > now())
    union all
    select 1
    from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = new.provider_capability_id
      and claim.is_claimed
      and claim.status = 'verified'
      and (claim.expires_at is null or claim.expires_at > now())
  ) then
    select approved.reviewer, approved.reviewed_at
    into v_reviewer, v_reviewed_at
    from (
      select evidence.reviewed_by as reviewer, evidence.reviewed_at
      from public.provider_capability_evidence evidence
      where evidence.provider_capability_id = new.provider_capability_id
        and evidence.status = 'approved'
        and (evidence.expires_at is null or evidence.expires_at > now())
      union all
      select claim.reviewed_by as reviewer, claim.reviewed_at
      from public.provider_role_qualification_claims claim
      where claim.provider_capability_id = new.provider_capability_id
        and claim.is_claimed
        and claim.status = 'verified'
        and (claim.expires_at is null or claim.expires_at > now())
    ) approved
    order by approved.reviewed_at desc nulls last
    limit 1;

    update public.provider_capabilities
    set verification_level = 'provider_verified',
        verified_by = coalesce(v_reviewer, new.reviewed_by, auth.uid()),
        verified_at = coalesce(v_reviewed_at, new.reviewed_at, now())
    where id = new.provider_capability_id;
  else
    update public.provider_capabilities
    set verification_level = 'self_declared',
        verified_by = null,
        verified_at = null
    where id = new.provider_capability_id
      and verification_level = 'provider_verified';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_provider_capability_badge_from_approved_evidence
  on public.provider_capability_evidence;
create trigger trg_sync_provider_capability_badge_from_approved_evidence
  after insert or update of status, expires_at
  on public.provider_capability_evidence
  for each row
  execute function private.sync_provider_capability_badge_from_approved_evidence();

-- Backfill approved proofs reviewed before this patch is installed.
with approvals as (
  select evidence.provider_capability_id, evidence.reviewed_by, evidence.reviewed_at
  from public.provider_capability_evidence evidence
  where evidence.status = 'approved'
    and (evidence.expires_at is null or evidence.expires_at > now())
  union all
  select claim.provider_capability_id, claim.reviewed_by, claim.reviewed_at
  from public.provider_role_qualification_claims claim
  where claim.is_claimed and claim.status = 'verified'
    and (claim.expires_at is null or claim.expires_at > now())
), latest_approval as (
  select distinct on (provider_capability_id)
    provider_capability_id, reviewed_by, reviewed_at
  from approvals
  order by provider_capability_id, reviewed_at desc nulls last
)
update public.provider_capabilities capability
set verification_level = 'provider_verified',
    verified_by = latest_approval.reviewed_by,
    verified_at = coalesce(latest_approval.reviewed_at, now())
from latest_approval
where capability.id = latest_approval.provider_capability_id;

commit;

-- ============================================================================
-- END MERGED SECTION (16/52): patch_provider_capability_badges.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (17/52): patch_renew_active_posts_through_december_2026.sql
-- ============================================================================

-- Extend active Loan, Forex, and Needs requests through December 31, 2026
-- (Africa/Kampala time). New requests posted before that deadline use the
-- same expiry; after it, the configured per-market duration applies again.

BEGIN;

DO $preflight$
BEGIN
  IF to_regclass('public.loan_requests') IS NULL
     OR to_regclass('public.forex_requests') IS NULL
     OR to_regclass('public.needs_requests') IS NULL
     OR to_regclass('public.system_settings') IS NULL THEN
    RAISE EXCEPTION
      'Post renewal requires loan_requests, forex_requests, needs_requests, and system_settings.';
  END IF;

  IF NOT EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'needs_requests'
         AND column_name = 'category_slug'
     )
     OR NOT EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'needs_requests'
         AND column_name = 'expires_at'
     ) THEN
    RAISE EXCEPTION
      'Post renewal requires the Needs expiry schema (category_slug and expires_at).';
  END IF;
END;
$preflight$;

LOCK TABLE public.loan_requests, public.forex_requests, public.needs_requests
  IN SHARE ROW EXCLUSIVE MODE;

UPDATE public.loan_requests
SET expires_at = TIMESTAMPTZ '2027-01-01 00:00:00 Africa/Kampala'
WHERE status::text = 'active';

UPDATE public.forex_requests
SET expires_at = TIMESTAMPTZ '2027-01-01 00:00:00 Africa/Kampala'
WHERE status::text = 'active';

UPDATE public.needs_requests
SET expires_at = TIMESTAMPTZ '2027-01-01 00:00:00 Africa/Kampala'
WHERE status::text = 'active';

CREATE OR REPLACE FUNCTION public.trg_fn_set_listing_expiry()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $function$
DECLARE
  v_setting_key text;
  v_days integer;
  v_december_deadline constant timestamptz :=
    TIMESTAMPTZ '2027-01-01 00:00:00 Africa/Kampala';
BEGIN
  CASE TG_TABLE_NAME
    WHEN 'loan_requests' THEN
      v_setting_key := 'listing_duration_days';
    WHEN 'forex_requests' THEN
      v_setting_key := 'forex_listing_duration_days';
    WHEN 'needs_requests' THEN
      v_setting_key := CASE NEW.category_slug
        WHEN 'machinery_equipment' THEN 'needs_default_duration_machinery_equipment_days'
        WHEN 'professional_services' THEN 'needs_default_duration_professional_services_days'
        WHEN 'transport_logistics' THEN 'needs_default_duration_transport_logistics_days'
        WHEN 'specialized_products' THEN 'needs_default_duration_specialized_products_days'
        WHEN 'travel_international' THEN 'needs_default_duration_travel_international_days'
        ELSE NULL
      END;
    ELSE
      RAISE EXCEPTION 'Unsupported listing table for expiry: %', TG_TABLE_NAME;
  END CASE;

  IF v_setting_key IS NULL THEN
    RAISE EXCEPTION 'No approved expiry duration is configured for Needs category %.',
      NEW.category_slug;
  END IF;

  SELECT setting_value::integer INTO v_days
  FROM public.system_settings
  WHERE setting_key = v_setting_key
    AND (country = NEW.country OR country IS NULL)
  ORDER BY country NULLS LAST
  LIMIT 1;

  IF v_days IS NULL OR v_days <= 0 THEN
    RAISE EXCEPTION 'Missing or invalid expiry setting % for country %.',
      v_setting_key, NEW.country;
  END IF;

  NEW.expires_at := CASE
    WHEN transaction_timestamp() < v_december_deadline THEN v_december_deadline
    ELSE NEW.listed_at + make_interval(days => v_days)
  END;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_set_listing_expiry ON public.loan_requests;
CREATE TRIGGER trg_set_listing_expiry
  BEFORE INSERT ON public.loan_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_set_listing_expiry();

DROP TRIGGER IF EXISTS trg_set_forex_listing_expiry ON public.forex_requests;
CREATE TRIGGER trg_set_forex_listing_expiry
  BEFORE INSERT ON public.forex_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_set_listing_expiry();

DROP TRIGGER IF EXISTS trg_set_needs_listing_expiry ON public.needs_requests;
CREATE TRIGGER trg_set_needs_listing_expiry
  BEFORE INSERT ON public.needs_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_set_listing_expiry();

COMMIT;

-- ============================================================================
-- END MERGED SECTION (17/52): patch_renew_active_posts_through_december_2026.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (18/52): patch_provider_company_name_single_source.sql
-- ============================================================================

-- Keep the company name in provider_company_profiles and commit the company
-- profile plus identity presentation in one RPC transaction.
-- Apply after patch_company_provider_path.sql and patch_provider_identity_switch.sql.
begin;

create or replace function public.save_company_category(
  p_category_slug text,
  p_services text[],
  p_roles text[],
  p_profile jsonb,
  p_evidence jsonb,
  p_presentation jsonb
) returns void
language plpgsql security invoker
set search_path = public, private, pg_temp
as $$
declare
  v_name text := btrim(coalesce(p_profile->>'company_name', ''));
  v_mode text := coalesce(p_presentation->>'display_mode', 'company');
  v_rep text := btrim(coalesce(p_presentation->>'representative_name', ''));
  v_authorized boolean := coalesce(
    (p_presentation->>'representative_authorized')::boolean, false);
  v_presentation jsonb;
begin
  if v_name = '' then
    raise exception 'Company name is required.' using errcode = 'P0217';
  end if;
  if char_length(v_name) > 80 then
    raise exception 'Company name must be 80 characters or fewer.' using errcode = 'P0218';
  end if;
  if v_mode not in ('company', 'company_with_representative') then
    raise exception 'Invalid company display mode.' using errcode = 'P0216';
  end if;
  if v_mode = 'company_with_representative'
     and (v_rep = '' or not v_authorized) then
    raise exception 'Representative name and authorization are required.'
      using errcode = 'P0219';
  end if;

  -- For first-time setup this creates the selected identity inside this same
  -- transaction. Existing company profiles pass through unchanged.
  perform private.set_provider_category_type_internal(p_category_slug, 'company');
  perform private.save_company_category_internal(
    p_category_slug, p_services, p_roles, p_profile, p_evidence);

  v_presentation := coalesce(p_presentation, '{}'::jsonb) || jsonb_build_object(
    'display_mode', v_mode,
    'display_name', v_name,
    'representative_name', case when v_mode = 'company_with_representative'
      then v_rep else null end,
    'representative_authorized', case when v_mode = 'company_with_representative'
      then v_authorized else false end);
  perform private.save_provider_identity_presentation_internal(
    p_category_slug, 'company', v_presentation);
end;
$$;

revoke all on function public.save_company_category(text,text[],text[],jsonb,jsonb,jsonb)
  from public, anon;
grant execute on function public.save_company_category(text,text[],text[],jsonb,jsonb,jsonb)
  to authenticated;

-- Identity switches also save their company name into the canonical company
-- profile row in the same transaction as the identity presentation.
create or replace function public.switch_provider_identity(
  p_category_slug text,
  p_to_identity text,
  p_presentation jsonb
) returns jsonb
language plpgsql security definer
set search_path = public, private, pg_temp
as $$
declare
  v_name text := btrim(coalesce(p_presentation->>'display_name', ''));
  v_result jsonb;
begin
  if p_to_identity = 'company' then
    if v_name = '' then
      raise exception 'Company name is required.' using errcode = 'P0217';
    end if;
    if char_length(v_name) > 80 then
      raise exception 'Company name must be 80 characters or fewer.' using errcode = 'P0218';
    end if;
  end if;

  v_result := private.switch_provider_identity_internal(
    p_category_slug, p_to_identity, p_presentation);

  if p_to_identity = 'company' then
    insert into public.provider_company_profiles(user_id, category_slug, company_name)
    values (auth.uid(), p_category_slug, v_name)
    on conflict (user_id, category_slug) do update
      set company_name = excluded.company_name, updated_at = now();
  end if;
  return v_result;
end;
$$;

revoke all on function public.switch_provider_identity(text,text,jsonb)
  from public, anon;
grant execute on function public.switch_provider_identity(text,text,jsonb)
  to authenticated;

commit;

-- ============================================================================
-- END MERGED SECTION (18/52): patch_provider_company_name_single_source.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (19/52): patch_provider_identity_deferred_company_name.sql
-- ============================================================================

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

-- ============================================================================
-- END MERGED SECTION (19/52): patch_provider_identity_deferred_company_name.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (20/52): patch_provider_company_identity_setup.sql
-- ============================================================================

-- Finish a company identity switch and save its details without requiring
-- service selections. Apply after patch_company_provider_path.sql,
-- patch_provider_identity_switch.sql, patch_provider_company_name_single_source.sql,
-- and patch_provider_company_logo.sql.
begin;

create or replace function public.complete_provider_company_identity_switch(
  p_category_slug text,
  p_profile jsonb,
  p_presentation jsonb,
  p_logo_path text default null
) returns void
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_name text := btrim(coalesce(p_profile->>'company_name', ''));
  v_registration text := nullif(btrim(coalesce(p_profile->>'registration_number', '')), '');
  v_team_size text := nullif(p_profile->>'team_size', '');
  v_years text := nullif(p_profile->>'years_in_business', '');
  v_areas text[] := array[]::text[];
  v_old_logo text;
  v_size bigint;
  v_mime text;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  if jsonb_typeof(coalesce(p_profile, '{}'::jsonb)) <> 'object'
      or jsonb_typeof(coalesce(p_presentation, '{}'::jsonb)) <> 'object' then
    raise exception 'Company profile details are invalid.' using errcode = 'P0204';
  end if;
  if v_name = '' then
    raise exception 'Company name is required.' using errcode = 'P0217';
  end if;
  if char_length(v_name) > 80 or char_length(coalesce(v_registration, '')) > 40
      or (v_team_size is not null and v_team_size not in ('1-5','6-20','21-50','50+'))
      or (v_years is not null and v_years not in ('<1','1-2','3-5','6-10','10+'))
      or jsonb_typeof(coalesce(p_profile->'service_areas', '[]'::jsonb)) <> 'array' then
    raise exception 'Company profile details are invalid.' using errcode = 'P0204';
  end if;
  select coalesce(array_agg(distinct btrim(value)), array[]::text[])
    into v_areas
    from jsonb_array_elements_text(coalesce(p_profile->'service_areas', '[]'::jsonb)) x(value)
    where btrim(value) <> '';
  if exists(select 1 from unnest(v_areas) area where char_length(area) > 80) then
    raise exception 'Service areas must be district or city names.' using errcode = 'P0204';
  end if;

  if p_logo_path is not null then
    if p_logo_path not like
        'evidence/' || v_user::text || '/' || p_category_slug || '/company/logo/%' then
      raise exception 'Company logo path is invalid.' using errcode = 'P0204';
    end if;
    select (o.metadata->>'size')::bigint,
        lower(coalesce(o.metadata->>'mimetype', ''))
      into v_size, v_mime
      from storage.objects o
      where o.bucket_id = 'provider-evidence'
        and o.name = p_logo_path and o.owner_id = v_user::text;
    if not found or v_size is null or v_size < 1 or v_size > 2097152
        or v_mime not in ('image/jpeg', 'image/png') then
      raise exception 'Company logos must be JPG or PNG files no larger than 2 MB.'
        using errcode = 'P0205';
    end if;
  end if;

  perform public.switch_provider_identity(
    p_category_slug, 'company',
    coalesce(p_presentation, '{}'::jsonb) ||
      jsonb_build_object('display_name', v_name));

  select logo_path into v_old_logo
    from public.provider_company_profiles
    where user_id = v_user and category_slug = p_category_slug
    for update;
  insert into public.provider_company_profiles(
    user_id, category_slug, company_name, registration_number, team_size,
    years_in_business, service_areas, logo_path
  ) values (
    v_user, p_category_slug, v_name, v_registration, v_team_size,
    v_years, v_areas, p_logo_path
  )
  on conflict(user_id, category_slug) do update set
    company_name = excluded.company_name,
    registration_number = excluded.registration_number,
    team_size = excluded.team_size,
    years_in_business = excluded.years_in_business,
    service_areas = excluded.service_areas,
    logo_path = coalesce(excluded.logo_path, provider_company_profiles.logo_path),
    updated_at = now();

  if p_logo_path is not null and v_old_logo is not null
      and v_old_logo <> p_logo_path then
    delete from storage.objects
      where bucket_id = 'provider-evidence'
        and name = v_old_logo and owner_id = v_user::text;
  end if;
end;
$$;

revoke all on function public.complete_provider_company_identity_switch(
  text, jsonb, jsonb, text
) from public, anon;
grant execute on function public.complete_provider_company_identity_switch(
  text, jsonb, jsonb, text
) to authenticated;

commit;

-- ============================================================================
-- END MERGED SECTION (20/52): patch_provider_company_identity_setup.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (21/52): patch_provider_company_logo.sql
-- ============================================================================

-- Persist optional company logos in the private provider-evidence bucket.
begin;

alter table public.provider_company_profiles
  add column if not exists logo_path text;

create or replace function public.save_provider_company_logo(
  p_category_slug text,
  p_logo_path text
) returns void
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_old_path text;
  v_size bigint;
  v_mime text;
  v_expected_prefix text;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  v_expected_prefix := 'evidence/' || v_user::text || '/' ||
    p_category_slug || '/company/logo/';
  if p_logo_path is null or p_logo_path not like v_expected_prefix || '%' then
    raise exception 'Company logo path is invalid.' using errcode = 'P0204';
  end if;
  if not exists (
    select 1 from public.provider_category_profiles p
    where p.user_id = v_user and p.category_slug = p_category_slug
      and p.provider_type = 'company'
  ) then
    raise exception 'Choose Company / Organization for this category first.'
      using errcode = 'P0202';
  end if;

  select (o.metadata->>'size')::bigint, lower(coalesce(o.metadata->>'mimetype', ''))
    into v_size, v_mime
    from storage.objects o
    where o.bucket_id = 'provider-evidence'
      and o.name = p_logo_path
      and o.owner_id = v_user::text;
  if not found or v_size is null or v_size < 1 or v_size > 2097152
      or v_mime not in ('image/jpeg', 'image/png') then
    raise exception 'Company logos must be JPG or PNG files no larger than 2 MB.'
      using errcode = 'P0205';
  end if;

  select logo_path into v_old_path
    from public.provider_company_profiles
    where user_id = v_user and category_slug = p_category_slug
    for update;
  update public.provider_company_profiles
    set logo_path = p_logo_path, updated_at = now()
    where user_id = v_user and category_slug = p_category_slug;

  if v_old_path is not null and v_old_path <> p_logo_path
      and v_old_path like v_expected_prefix || '%' then
    delete from storage.objects
      where bucket_id = 'provider-evidence'
        and name = v_old_path and owner_id = v_user::text;
  end if;
end;
$$;

revoke all on function public.save_provider_company_logo(text, text)
  from public, anon;
grant execute on function public.save_provider_company_logo(text, text)
  to authenticated;

commit;

-- ============================================================================
-- END MERGED SECTION (21/52): patch_provider_company_logo.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (22/52): patch_remove_provider_capability.sql
-- ============================================================================

-- =============================================================================
-- Standalone Supabase patch: allow an authenticated provider to remove their
-- own service or work capability from Provider Services.
-- Safe to re-run. Does not grant direct DELETE access to the table.
-- =============================================================================

begin;

create or replace function public.remove_provider_capability(
  p_capability_slug text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated'
      using errcode = '42501';
  end if;

  if p_capability_slug is null or btrim(p_capability_slug) = '' then
    raise exception 'Capability slug is required'
      using errcode = '22023';
  end if;

  delete from public.provider_capabilities
  where user_id = v_user_id
    and capability_slug = p_capability_slug;
end;
$$;

revoke all on function public.remove_provider_capability(text)
  from public, anon;
grant execute on function public.remove_provider_capability(text)
  to authenticated;

commit;

-- ============================================================================
-- END MERGED SECTION (22/52): patch_remove_provider_capability.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (23/52): patch_remove_provider_capability_v2.sql
-- ============================================================================

-- =============================================================================
-- Patch v2: ensure authenticated users can delete their own provider_capabilities
-- rows directly via RLS (no RPC needed). Safe to re-run.
-- =============================================================================

begin;

-- Ensure the delete RLS policy exists on provider_capabilities
drop policy if exists "Users delete own provider capabilities" on public.provider_capabilities;
create policy "Users delete own provider capabilities" on public.provider_capabilities
  for delete to authenticated using (user_id = auth.uid());

commit;

-- ============================================================================
-- END MERGED SECTION (23/52): patch_remove_provider_capability_v2.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (24/52): patch_fix_provider_capability_delete.sql
-- ============================================================================

-- =============================================================================
-- Fix: ensure authenticated users can delete their own provider_capabilities rows.
-- Covers: missing table-level DELETE grant, missing/dropped RLS delete policy.
-- Safe to re-run.
-- =============================================================================

begin;

-- 1. Ensure table-level DELETE privilege is granted to authenticated role
grant delete on public.provider_capabilities to authenticated;

-- 2. Re-create the RLS delete policy (idempotent)
drop policy if exists "Users delete own provider capabilities" on public.provider_capabilities;
create policy "Users delete own provider capabilities"
  on public.provider_capabilities
  for delete to authenticated
  using (user_id = auth.uid());

commit;

-- ============================================================================
-- END MERGED SECTION (24/52): patch_fix_provider_capability_delete.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (25/52): patch_provider_work_role_withdrawal.sql
-- ============================================================================

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

-- ============================================================================
-- END MERGED SECTION (25/52): patch_provider_work_role_withdrawal.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (26/52): patch_required_role_proofs.sql
-- ============================================================================

-- Mark high-risk individual work roles with one required credential.
-- Apply after provider work-profile, profile-documents, verification-policy,
-- and provider-type verification-matrix patches. Safe to rerun.
begin;

-- Keep this temp mapping for the session so SQL editors that commit between
-- selected statements do not drop it before the updates below use it.
create temporary table if not exists required_role_proofs (
  role_slug text primary key,
  qualification_slug text not null,
  capability_slug text not null
);
truncate table required_role_proofs;

alter table public.role_qualifications
  add column if not exists is_required_proof boolean not null default false;

-- Visa work was previously mixed into general travel and operations roles.
-- Give it a dedicated work role so its credential gate does not apply to
-- ordinary travel bookings or tour operations.
insert into public.need_capabilities (
  slug, category_slug, name, is_active, ui_group_slug, sort_order,
  service_group_slug, service_group_name, service_sort_order,
  capability_type, verification_policy
)
values (
  'work_visa_assistance_specialist', 'travel_international',
  'Visa Assistance Specialist', true, 'travel_international', 50,
  'work_roles', 'Work Roles', 50, 'work', 'required_proof'
)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = true,
  ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  capability_type = excluded.capability_type,
  verification_policy = excluded.verification_policy;

insert into public.capability_roles (
  slug, category_slug, capability_slug, name, kind_question, is_active
)
values (
  'visa_assistance_specialist', 'travel_international',
  'work_visa_assistance_specialist', 'Visa Assistance Specialist',
  'What visa support do you provide?', true
)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = true;

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('visa_assistance_specialist', 'visa_applications', 'Visa applications', 10),
  ('visa_assistance_specialist', 'document_review', 'Document review', 20),
  ('visa_assistance_specialist', 'appointment_support', 'Appointment support', 30)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

delete from public.role_kinds
where (role_slug = 'travel_agent_consultant' and slug = 'visas')
   or (role_slug = 'operations_manager' and slug = 'visa_documentation')
   or (role_slug = 'architect_designer' and slug in ('interiors', 'landscape'))
   or (role_slug = 'teacher_tutor' and slug in ('languages', 'exam_prep'))
   or (role_slug = 'trainer_instructor' and
       slug in ('vocational_technical', 'driving'));

update public.need_capabilities
set name = 'Architect'
where slug = 'work_architect_designer';
update public.capability_roles
set name = 'Architect'
where slug = 'architect_designer';
update public.need_capabilities
set name = 'Teacher'
where slug = 'work_teacher_tutor';
update public.capability_roles
set name = 'Teacher'
where slug = 'teacher_tutor';

-- Separate design work and informal tutoring from regulated professions.
insert into public.need_capabilities (
  slug, category_slug, name, is_active, ui_group_slug, sort_order,
  service_group_slug, service_group_name, service_sort_order,
  capability_type, verification_policy
)
values
  ('work_interior_designer', 'professional_services', 'Interior Designer',
   true, 'business_professional_services', 45, 'work_roles', 'Work Roles',
   45, 'work', 'open'),
  ('work_landscape_designer', 'professional_services', 'Landscape Designer',
   true, 'business_professional_services', 46, 'work_roles', 'Work Roles',
   46, 'work', 'open'),
  ('work_private_tutor', 'education_training', 'Private Tutor / Exam Coach',
   true, 'education_training', 15, 'work_roles', 'Work Roles',
   15, 'work', 'open'),
  ('work_vocational_trainer', 'education_training',
   'Vocational / Technical Trainer', true, 'education_training', 25,
   'work_roles', 'Work Roles', 25, 'work', 'required_proof')
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = true,
  ui_group_slug = excluded.ui_group_slug,
  sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  capability_type = excluded.capability_type,
  verification_policy = excluded.verification_policy;

insert into public.capability_roles (
  slug, category_slug, capability_slug, name, kind_question, is_active
)
values
  ('interior_designer', 'professional_services', 'work_interior_designer',
   'Interior Designer', 'What do you design?', true),
  ('landscape_designer', 'professional_services', 'work_landscape_designer',
   'Landscape Designer', 'What do you design?', true),
  ('private_tutor', 'education_training', 'work_private_tutor',
   'Private Tutor / Exam Coach', 'What do you teach?', true),
  ('vocational_trainer', 'education_training', 'work_vocational_trainer',
   'Vocational / Technical Trainer', 'What trade do you teach?', true)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = true;

insert into public.role_kinds (role_slug, slug, name, sort_order)
values
  ('private_tutor', 'languages', 'Languages', 10),
  ('private_tutor', 'exam_prep', 'Exam prep', 20),
  ('vocational_trainer', 'vocational_technical', 'Trades', 10)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

insert into public.role_qualifications (
  role_slug, slug, name, is_evidence, is_required_proof, sort_order
)
values
  ('interior_designer', 'portfolio', 'Portfolio', false, false, 10),
  ('landscape_designer', 'portfolio', 'Portfolio', false, false, 10),
  ('private_tutor', 'subject_specialisation', 'Subject specialisation',
   false, false, 10),
  ('vocational_trainer', 'trade_certificate', 'Trade certificate',
   true, true, 10)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  is_evidence = excluded.is_evidence,
  is_required_proof = excluded.is_required_proof,
  sort_order = excluded.sort_order;

insert into public.role_qualifications (
  role_slug, slug, name, is_evidence, is_required_proof, sort_order
)
values (
  'visa_assistance_specialist', 'travel_agency_licence',
  'Travel agency or visa agent authorisation', true, true, 10
)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  is_evidence = true,
  is_required_proof = true,
  sort_order = excluded.sort_order;

insert into required_role_proofs (role_slug, qualification_slug, capability_slug)
values
  ('security_specialist', 'cissp_cism', 'work_security_specialist'),
  ('accountant_finance_officer', 'practising_certificate', 'work_accountant_finance_officer'),
  ('lawyer_legal_officer', 'bar_admission_practising_certificate', 'work_lawyer_legal_officer'),
  ('engineer', 'registered_with_engineers_board', 'work_engineer'),
  ('architect_designer', 'registered_architect', 'work_architect_designer'),
  ('teacher_tutor', 'registered_with_teaching_board', 'work_teacher_tutor'),
  ('vocational_trainer', 'trade_certificate', 'work_vocational_trainer'),
  ('site_manager', 'safety_certification_osha', 'work_site_manager'),
  ('foreman_supervisor', 'trade_test_certificate', 'work_foreman_supervisor'),
  ('skilled_tradesperson', 'trade_test_grade_i_ii_iii', 'work_skilled_tradesperson'),
  ('surveyor', 'registered_surveyor', 'work_surveyor'),
  ('solar_electrical_technician', 'electrical_licence', 'work_solar_electrical_technician'),
  ('energy_engineer', 'registered_engineer', 'work_energy_engineer'),
  ('driver', 'valid_driving_licence_class', 'work_driver'),
  ('driving_instructor', 'instructor_licence', 'work_driving_instructor'),
  ('machine_operator', 'operator_licence_certificate', 'work_machine_operator'),
  ('equipment_mechanic', 'mechanic_trade_certificate', 'work_equipment_mechanic'),
  ('site_supervisor', 'safety_certification', 'work_site_supervisor'),
  ('veterinary_livestock_officer', 'veterinary_licence', 'work_veterinary_livestock_officer'),
  ('clearing_customs_agent', 'customs_clearing_licence', 'work_clearing_customs_agent'),
  ('visa_assistance_specialist', 'travel_agency_licence', 'work_visa_assistance_specialist'),
  ('tour_guide', 'tourism_board_guide_licence', 'work_tour_guide'),
  ('driver_guide', 'valid_driving_licence_class', 'work_driver_guide'),
  ('house_help', 'national_id', 'work_house_help'),
  ('nanny', 'police_clearance', 'work_nanny'),
  ('home_carer', 'caregiving_certificate', 'work_home_carer'),
  ('home_cook', 'food_handler_certificate', 'work_home_cook'),
  ('doctor', 'council_registration', 'work_doctor'),
  ('nurse', 'council_registration', 'work_nurse'),
  ('clinician', 'practising_licence', 'work_clinician'),
  ('medical_specialist', 'specialist_registration', 'work_medical_specialist'),
  ('optometrist', 'optometry_registration', 'work_optometrist'),
  ('dentist', 'dental_council_registration', 'work_dentist'),
  ('pharmacist', 'pharmacy_board_registration', 'work_pharmacist'),
  ('lab_technician', 'lab_council_registration', 'work_lab_technician'),
  ('physiotherapist', 'physiotherapy_registration', 'work_physiotherapist'),
  ('counsellor', 'professional_registration', 'work_counsellor'),
  ('nursing_assistant', 'assistant_certificate', 'work_nursing_assistant'),
  ('hiv_counsellor', 'facility_authorisation', 'work_hiv_counsellor'),
  ('caterer_chef', 'food_handler_certificate', 'work_caterer_chef'),
  ('massage_therapist', 'massage_therapy_certificate', 'work_massage_therapist'),
  ('spa_therapist', 'cosmetology_spa_certificate', 'work_spa_therapist'),
  ('traditional_healer', 'association_registration', 'work_traditional_healer'),
  ('duwah_practitioner', 'endorsement', 'work_duwah_practitioner'),
  ('ceremony_officiant', 'endorsement', 'work_ceremony_officiant'),
  ('angel_investor', 'identity_verification', 'work_angel_investor');

do $$
begin
  if exists (
    select 1
    from required_role_proofs required
    left join public.role_qualifications qualification
      on qualification.role_slug = required.role_slug
     and qualification.slug = required.qualification_slug
    left join public.need_capabilities capability
      on capability.slug = required.capability_slug
     and capability.capability_type = 'work'
    where qualification.slug is null or capability.slug is null
  ) then
    raise exception 'A required work-role proof mapping is missing from the provider catalogs.';
  end if;
end;
$$;

update public.role_qualifications qualification
set is_evidence = true, is_required_proof = true
from required_role_proofs required
where qualification.role_slug = required.role_slug
  and qualification.slug = required.qualification_slug;

update public.need_capabilities capability
set verification_policy = 'required_proof'
from required_role_proofs required
where capability.slug = required.capability_slug;

insert into public.verification_requirements (
  scope_type, scope_id, provider_type, identity_required, phone_required,
  provider_verification_required, evidence_requirements, required_evidence,
  is_active
)
select
  'capability', required.capability_slug, 'individual', false, false, true,
  jsonb_build_array(required.qualification_slug),
  array[required.qualification_slug]::text[], true
from required_role_proofs required
on conflict (scope_type, scope_id, provider_type) do update set
  provider_verification_required = excluded.provider_verification_required,
  evidence_requirements = excluded.evidence_requirements,
  required_evidence = excluded.required_evidence,
  is_active = true,
  updated_at = now();

-- Existing declarations remain saved, but high-risk roles stay off offers
-- until their required credential has been reviewed and approved.
update public.provider_capabilities capability
set is_active = false, updated_at = now()
from required_role_proofs required
where capability.capability_slug = required.capability_slug
  and capability.verification_level <> 'provider_verified'
  and not exists (
    select 1 from public.provider_capability_evidence evidence
    where evidence.provider_capability_id = capability.id
      and evidence.requirement_key = required.qualification_slug
      and evidence.status = 'approved'
      and (evidence.expires_at is null or evidence.expires_at > now())
  )
  and not exists (
    select 1 from public.provider_role_qualification_claims claim
    where claim.provider_capability_id = capability.id
      and claim.role_slug = required.role_slug
      and claim.qualification_slug = required.qualification_slug
      and claim.is_claimed and claim.status = 'verified'
      and (claim.expires_at is null or claim.expires_at > now())
  );

commit;
notify pgrst, 'reload schema';

-- ============================================================================
-- END MERGED SECTION (26/52): patch_required_role_proofs.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (27/52): patch_preserve_approved_role_proofs.sql
-- ============================================================================

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

-- ============================================================================
-- END MERGED SECTION (27/52): patch_preserve_approved_role_proofs.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (28/52): patch_plan_requests_and_responses.sql
-- ============================================================================

-- Plan request and response limits shown on Plans & pricing.
-- Active request capacity is shared by Loans and Needs. Forex is excluded.
-- Apply manually after reviewing; this patch is not run by the app.

BEGIN;

INSERT INTO public.system_settings (
  setting_key, country, setting_value, setting_type, category, description, is_public
)
VALUES
  ('max_active_requests_free', NULL, '3', 'number', 'limits', 'Maximum active requests across Loans and Needs for Free subscribers', TRUE),
  ('max_active_requests_lender', NULL, '8', 'number', 'limits', 'Maximum active requests across Loans and Needs for Provider subscribers', TRUE),
  ('max_active_requests_pro', NULL, '20', 'number', 'limits', 'Maximum active requests across Loans and Needs for Pro subscribers', TRUE),
  ('max_active_responses_lender', NULL, '10', 'number', 'limits', 'Maximum active Needs responses for Provider subscribers', TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO UPDATE
SET setting_value = EXCLUDED.setting_value,
    setting_type = EXCLUDED.setting_type,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    is_public = EXCLUDED.is_public,
    updated_at = NOW();

CREATE OR REPLACE FUNCTION public.get_my_active_request_count()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT (
    (SELECT count(*) FROM public.loan_requests lr
      WHERE lr.borrower_id = auth.uid() AND lr.status::text = 'active') +
    (SELECT count(*) FROM public.needs_requests nr
      WHERE nr.requester_id = auth.uid() AND nr.status::text = 'active')
  )::integer;
$function$;
REVOKE ALL ON FUNCTION public.get_my_active_request_count() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_active_request_count() TO authenticated;

CREATE OR REPLACE FUNCTION public.assert_pro_advanced_filters()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.subscriptions s
    WHERE s.user_id = auth.uid()
      AND s.status = 'active'
      AND (s.expires_at IS NULL OR s.expires_at > now())
      AND s.plan = 'pro'
  ) THEN
    RAISE EXCEPTION 'NIPANZE_PRO_REQUIRED: Advanced marketplace filters require a Pro subscription.'
      USING ERRCODE = 'P0050';
  END IF;
  RETURN true;
END;
$function$;

REVOKE ALL ON FUNCTION public.assert_pro_advanced_filters() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assert_pro_advanced_filters() TO authenticated;

CREATE OR REPLACE FUNCTION public.trg_fn_max_concurrent_requests()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_user_id uuid;
  v_country text;
  v_plan public.subscription_plan_enum;
  v_limit integer;
  v_active integer;
BEGIN
  IF TG_TABLE_NAME = 'loan_requests' THEN
    v_user_id := NEW.borrower_id;
  ELSIF TG_TABLE_NAME = 'needs_requests' THEN
    v_user_id := NEW.requester_id;
  ELSE
    RAISE EXCEPTION 'Unsupported request table: %', TG_TABLE_NAME;
  END IF;
  v_country := NEW.country;

  -- Serialize simultaneous posts for the same account before counting.
  PERFORM pg_advisory_xact_lock(hashtextextended(v_user_id::text, 0));

  SELECT COALESCE(s.plan, 'free'::public.subscription_plan_enum)
    INTO v_plan
  FROM public.profiles p
  LEFT JOIN public.subscriptions s
    ON s.user_id = p.id
   AND s.status = 'active'
   AND (s.expires_at IS NULL OR s.expires_at > now())
  WHERE p.id = v_user_id
  ORDER BY s.created_at DESC NULLS LAST
  LIMIT 1;
  v_plan := COALESCE(v_plan, 'free'::public.subscription_plan_enum);

  SELECT setting_value::integer INTO v_limit
  FROM public.system_settings
  WHERE setting_key = 'max_active_requests_' || v_plan::text
    AND (country = v_country OR country IS NULL)
  ORDER BY country NULLS LAST
  LIMIT 1;
  v_limit := COALESCE(v_limit, CASE v_plan
    WHEN 'free' THEN 3 WHEN 'lender' THEN 8 WHEN 'pro' THEN 20 END);

  SELECT
    (SELECT count(*) FROM public.loan_requests lr
      WHERE lr.borrower_id = v_user_id AND lr.status::text = 'active') +
    (SELECT count(*) FROM public.needs_requests nr
      WHERE nr.requester_id = v_user_id AND nr.status::text = 'active')
    INTO v_active;

  -- An update that keeps the row active does not consume another slot.
  IF TG_OP = 'UPDATE' AND OLD.status::text = 'active'
     AND NEW.status::text = 'active' THEN
    RETURN NEW;
  END IF;

  IF NEW.status::text = 'active' AND v_active >= v_limit THEN
    RAISE EXCEPTION 'NIPANZE_MAX_REQUESTS: You have % of % active requests.', v_active, v_limit
      USING ERRCODE = 'P0002';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_max_concurrent_requests ON public.loan_requests;
CREATE TRIGGER trg_max_concurrent_requests
  BEFORE INSERT OR UPDATE OF status ON public.loan_requests
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_max_concurrent_requests();

DROP TRIGGER IF EXISTS trg_max_concurrent_needs_requests ON public.needs_requests;
CREATE TRIGGER trg_max_concurrent_needs_requests
  BEFORE INSERT OR UPDATE OF status ON public.needs_requests
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_max_concurrent_requests();

CREATE OR REPLACE FUNCTION public.trg_fn_limit_active_need_responses()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_plan public.subscription_plan_enum;
  v_limit integer;
  v_active integer;
BEGIN
  IF NEW.status <> 'pending' OR
     (TG_OP = 'UPDATE' AND OLD.status = 'pending') THEN
    RETURN NEW;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(NEW.offer_maker_id::text, 0));

  SELECT COALESCE(s.plan, 'free'::public.subscription_plan_enum)
    INTO v_plan
  FROM public.profiles p
  LEFT JOIN public.subscriptions s
    ON s.user_id = p.id AND s.status = 'active'
   AND (s.expires_at IS NULL OR s.expires_at > now())
  WHERE p.id = NEW.offer_maker_id
  ORDER BY s.created_at DESC NULLS LAST
  LIMIT 1;
  v_plan := COALESCE(v_plan, 'free'::public.subscription_plan_enum);

  IF v_plan = 'pro' THEN RETURN NEW; END IF;
  IF v_plan <> 'lender' THEN
    RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: Provider or Pro is required to respond to Needs.'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT setting_value::integer INTO v_limit
  FROM public.system_settings
  WHERE setting_key = 'max_active_responses_lender' AND country IS NULL
  LIMIT 1;
  v_limit := COALESCE(v_limit, 10);

  SELECT count(*) INTO v_active
  FROM public.need_offers nof
  JOIN public.needs_requests nr ON nr.request_id = nof.need_id
  WHERE nof.offer_maker_id = NEW.offer_maker_id
    AND nof.status = 'pending'
    AND nr.status::text = 'active'
    AND (nof.expires_at IS NULL OR nof.expires_at > now());

  IF v_active >= v_limit THEN
    RAISE EXCEPTION 'NIPANZE_MAX_RESPONSES: You have % of % active responses.', v_active, v_limit
      USING ERRCODE = 'P0002';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_limit_active_need_responses ON public.need_offers;
CREATE TRIGGER trg_limit_active_need_responses
  BEFORE INSERT OR UPDATE OF status ON public.need_offers
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_limit_active_need_responses();

COMMIT;

-- ============================================================================
-- END MERGED SECTION (28/52): patch_plan_requests_and_responses.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (29/52): patch_forex_expand_currency_options.sql
-- ============================================================================

-- Expand the currencies available in Forex filters, listings, and offers.
-- Apply this patch to existing databases. It is safe to run more than once.

INSERT INTO currencies (
    code,
    name,
    is_market_currency,
    market_country,
    forex_trading_enabled
) VALUES
    ('BIF', 'Burundian Franc',      FALSE, NULL, TRUE),
    ('SSP', 'South Sudanese Pound', FALSE, NULL, TRUE),
    ('CDF', 'Congolese Franc',      FALSE, NULL, TRUE),
    ('SOS', 'Somali Shilling',      FALSE, NULL, TRUE),
    ('ETB', 'Ethiopian Birr',       FALSE, NULL, TRUE),
    ('DJF', 'Djiboutian Franc',     FALSE, NULL, TRUE),
    ('ERN', 'Eritrean Nakfa',       FALSE, NULL, TRUE),
    ('SDG', 'Sudanese Pound',       FALSE, NULL, TRUE),
    ('KMF', 'Comorian Franc',       FALSE, NULL, TRUE),
    ('MGA', 'Malagasy Ariary',      FALSE, NULL, TRUE),
    ('MWK', 'Malawian Kwacha',      FALSE, NULL, TRUE),
    ('MUR', 'Mauritian Rupee',      FALSE, NULL, TRUE),
    ('SCR', 'Seychellois Rupee',    FALSE, NULL, TRUE),
    ('ZMW', 'Zambian Kwacha',       FALSE, NULL, TRUE),
    ('ZWG', 'Zimbabwe Gold',        FALSE, NULL, TRUE),
    ('MZN', 'Mozambican Metical',   FALSE, NULL, TRUE),
    ('EUR', 'Euro',                 FALSE, NULL, TRUE),
    ('GBP', 'British Pound',        FALSE, NULL, TRUE),
    ('AED', 'UAE Dirham',           FALSE, NULL, TRUE),
    ('INR', 'Indian Rupee',         FALSE, NULL, TRUE),
    ('JPY', 'Japanese Yen',         FALSE, NULL, TRUE),
    ('CAD', 'Canadian Dollar',      FALSE, NULL, TRUE),
    ('AUD', 'Australian Dollar',    FALSE, NULL, TRUE),
    ('CHF', 'Swiss Franc',          FALSE, NULL, TRUE),
    ('CNY', 'Chinese Yuan',         FALSE, NULL, TRUE)
ON CONFLICT (code) DO UPDATE
SET forex_trading_enabled = TRUE;

-- ============================================================================
-- END MERGED SECTION (29/52): patch_forex_expand_currency_options.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (30/52): patch_daily_repayment_frequency.sql
-- ============================================================================

-- Allow daily repayment schedules and the Retired borrower status.
-- Safe to re-run.

begin;

alter type public.repayment_frequency_enum
  add value if not exists 'daily';

alter table public.loan_requests
  drop constraint if exists chk_lr_repayment_plan,
  drop constraint if exists chk_lr_suggested_repayment_frequency;

alter table public.loan_requests
  add constraint chk_lr_repayment_plan
    check (preferred_repayment_plan in ('daily', 'weekly', 'monthly', 'one_time')),
  add constraint chk_lr_suggested_repayment_frequency
    check (
      suggested_repayment_frequency is null or
      suggested_repayment_frequency in ('daily', 'weekly', 'monthly', 'one_time')
    );

alter table public.loan_offers
  drop constraint if exists chk_lo_repayment_frequency;

alter table public.loan_offers
  add constraint chk_lo_repayment_frequency
    check (repayment_frequency in ('daily', 'weekly', 'monthly', 'one_time'));

-- Upgrade older borrower_information tables that predate currency tracking.
alter table public.borrower_information
  add column if not exists income_currency varchar(3);

update public.borrower_information bi
set income_currency = upper(
  coalesce(nullif(p.income_currency, ''), c.currency_code, 'UGX')
)
from public.profiles p
left join public.countries c on c.code = p.country
where bi.user_id = p.id
  and (bi.income_currency is null or bi.income_currency !~ '^[A-Z]{3}$');

update public.borrower_information
set income_currency = 'UGX'
where income_currency is null or income_currency !~ '^[A-Z]{3}$';

alter table public.borrower_information
  alter column income_currency set default 'UGX',
  alter column income_currency set not null;

alter table public.borrower_information
  drop constraint if exists borrower_information_income_currency_check;

alter table public.borrower_information
  add constraint borrower_information_income_currency_check
    check (income_currency ~ '^[A-Z]{3}$') not valid;

alter table public.borrower_information
  drop constraint if exists borrower_information_employment_status_check;

alter table public.borrower_information
  add constraint borrower_information_employment_status_check
    check (employment_status in (
      'government_employed',
      'private_sector',
      'self_employed',
      'business_owner',
      'student',
      'retired',
      'unemployed'
    )) not valid;

commit;

notify pgrst, 'reload schema';

-- ============================================================================
-- END MERGED SECTION (30/52): patch_daily_repayment_frequency.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (31/52): patch_financial_services_provider_capabilities.sql
-- ============================================================================

-- Enable Financial Services as a provider-only category with capability-level
-- proof requirements. Apply after the v2 catalog, provider work-profile,
-- capability verification-policy, provider-type verification matrix, company
-- provider path, category-type, and identity-switch patches. Safe to rerun; no
-- existing rows are removed. This does not expose Financial Services in Needs.

begin;

update public.need_categories
set name = 'Finance', icon = '💰',
    description = 'Loans, Forex, SACCOs, investments, and other financial services.',
    sort_order = 19, is_active = true
where slug = 'financial_services';

insert into public.need_categories
  (slug, name, icon, description, sort_order, is_active, provider_verification_required)
values
  ('financial_services', 'Finance', '💰',
   'Loans, Forex, SACCOs, investments, and other financial services.',
   19, true, false)
on conflict (slug) do update set
  name = excluded.name, icon = excluded.icon,
  description = excluded.description, sort_order = excluded.sort_order,
  is_active = true;

insert into public.need_capabilities (
  slug, category_slug, name, is_active, capability_type, ui_group_slug,
  sort_order, service_group_slug, service_group_name, service_sort_order,
  verification_policy
) values
  ('personal_loan_services','financial_services','Personal Loan Services',true,'service','financial_services',110,'personal_financing','Personal Financing',10,'required_proof'),
  ('emergency_loan_services','financial_services','Emergency Loan Services',true,'service','financial_services',120,'personal_financing','Personal Financing',20,'required_proof'),
  ('salary_loan_services','financial_services','Salary Loan Services',true,'service','financial_services',130,'personal_financing','Personal Financing',30,'required_proof'),
  ('medical_financing','financial_services','Medical Financing',true,'service','financial_services',140,'personal_financing','Personal Financing',40,'required_proof'),
  ('business_startup_financing','financial_services','Business Startup Financing',true,'service','financial_services',210,'business_financing','Business Financing',10,'required_proof'),
  ('working_capital_financing','financial_services','Working Capital Financing',true,'service','financial_services',220,'business_financing','Business Financing',20,'required_proof'),
  ('business_expansion_financing','financial_services','Business Expansion Financing',true,'service','financial_services',230,'business_financing','Business Financing',30,'required_proof'),
  ('sme_financing','financial_services','SME Financing',true,'service','financial_services',240,'business_financing','Business Financing',40,'required_proof'),
  ('boda_boda_financing','financial_services','Boda Boda Financing',true,'service','financial_services',310,'asset_financing','Asset Financing',10,'required_proof'),
  ('car_financing','financial_services','Car Financing',true,'service','financial_services',320,'asset_financing','Asset Financing',20,'required_proof'),
  ('tuk_tuk_financing','financial_services','Tuk-tuk Financing',true,'service','financial_services',330,'asset_financing','Asset Financing',30,'required_proof'),
  ('motorcycle_financing','financial_services','Motorcycle Financing',true,'service','financial_services',340,'asset_financing','Asset Financing',40,'required_proof'),
  ('smartphone_financing','financial_services','Smartphone Financing',true,'service','financial_services',350,'asset_financing','Asset Financing',50,'required_proof'),
  ('laptop_financing','financial_services','Laptop Financing',true,'service','financial_services',360,'asset_financing','Asset Financing',60,'required_proof'),
  ('heavy_machinery_financing','financial_services','Heavy Machinery Financing',true,'service','financial_services',370,'asset_financing','Asset Financing',70,'required_proof'),
  ('equipment_financing','financial_services','Equipment Financing',true,'service','financial_services',380,'asset_financing','Asset Financing',80,'required_proof'),
  ('agricultural_loan_services','financial_services','Agricultural Loans',true,'service','financial_services',410,'agricultural_financing','Agricultural Financing',10,'required_proof'),
  ('livestock_financing','financial_services','Livestock Financing',true,'service','financial_services',420,'agricultural_financing','Agricultural Financing',20,'required_proof'),
  ('crop_financing','financial_services','Crop Financing',true,'service','financial_services',430,'agricultural_financing','Agricultural Financing',30,'required_proof'),
  ('farm_equipment_financing','financial_services','Farm Equipment Financing',true,'service','financial_services',440,'agricultural_financing','Agricultural Financing',40,'required_proof'),
  ('mortgage_financing','financial_services','Mortgage Financing',true,'service','financial_services',510,'property_financing','Property Financing',10,'required_proof'),
  ('land_financing','financial_services','Land Financing',true,'service','financial_services',520,'property_financing','Property Financing',20,'required_proof'),
  ('property_development_financing','financial_services','Property Development Financing',true,'service','financial_services',530,'property_financing','Property Financing',30,'required_proof'),
  ('school_fees_financing','financial_services','School Fees Financing',true,'service','financial_services',610,'education_financing','Education Financing',10,'required_proof'),
  ('university_financing','financial_services','University Financing',true,'service','financial_services',620,'education_financing','Education Financing',20,'required_proof'),
  ('education_loan_services','financial_services','Education Loans',true,'service','financial_services',630,'education_financing','Education Financing',30,'required_proof'),
  ('travel_financing','financial_services','Travel Financing',true,'service','financial_services',710,'lifestyle_financing','Lifestyle Financing',10,'required_proof'),
  ('wedding_financing','financial_services','Wedding Financing',true,'service','financial_services',720,'lifestyle_financing','Lifestyle Financing',20,'required_proof'),
  ('other_lifestyle_financing','financial_services','Other Lifestyle Financing',true,'service','financial_services',730,'lifestyle_financing','Lifestyle Financing',30,'required_proof')
on conflict (slug) do update set
  category_slug = excluded.category_slug, name = excluded.name,
  is_active = excluded.is_active, capability_type = excluded.capability_type,
  ui_group_slug = excluded.ui_group_slug, sort_order = excluded.sort_order,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  verification_policy = excluded.verification_policy;

-- These verification requirements make capabilities saveable as inactive
-- drafts. They become visible only after an authorized reviewer approves the
-- required evidence. KYC identity checks remain part of the existing gate.
insert into public.verification_requirements (
  scope_type, scope_id, provider_type, identity_required, phone_required,
  provider_verification_required, evidence_requirements, required_evidence,
  expires_after_days, is_active
)
select 'capability', nc.slug, requirements.provider_type, true, false, true,
       to_jsonb(requirements.required_evidence), requirements.required_evidence,
       365, true
from public.need_capabilities nc
cross join (values
  ('individual'::text, array['supporting_information']::text[]),
  ('company'::text, array['business_registration','financial_authorization']::text[])
) as requirements(provider_type, required_evidence)
where nc.category_slug = 'financial_services'
  and not exists (
    select 1 from public.verification_requirements vr
    where vr.scope_type = 'capability' and vr.scope_id = nc.slug
      and vr.provider_type = requirements.provider_type and vr.is_active
  );

update public.need_capabilities
set verification_policy = 'required_proof'
where category_slug = 'financial_services';

-- Keep independent selections and proof records for the two existing identity
-- types. Legacy rows remain unchanged and retain their ids and evidence links.
alter table public.provider_capabilities
  drop constraint if exists provider_capabilities_user_id_capability_slug_key;
create unique index if not exists provider_capabilities_service_identity_uidx
  on public.provider_capabilities(user_id, capability_slug, identity_type)
  where identity_type is not null;
create unique index if not exists provider_capabilities_work_identity_uidx
  on public.provider_capabilities(user_id, capability_slug)
  where identity_type is null;

create or replace function private.enforce_provider_capability_policy()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_category text; v_policy text; v_type text;
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
    new.is_active := new.verification_level = 'provider_verified'
      and exists (
        select 1 from public.provider_capability_evidence e
        where e.provider_capability_id = new.id and e.status = 'approved'
          and (e.expires_at is null or e.expires_at > now())
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

-- Re-evaluate legacy Financial Services rows against the complete evidence
-- checklist; keep their records and proof history while hiding unapproved rows.
update public.provider_capabilities pc
set is_active = pc.is_active
from public.need_capabilities nc
where nc.slug = pc.capability_slug and nc.category_slug = 'financial_services';

-- Provider-only: the existing Needs repository and SQL guard continue hiding
-- and rejecting this category for Needs requests.

-- Financial services are offered by either existing provider identity. Other
-- service capabilities remain Company-only.
create or replace function private.enforce_provider_identity_capability()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare v_category text; v_kind text; v_current text;
begin
  select category_slug, capability_type into v_category, v_kind
    from public.need_capabilities where slug = new.capability_slug;
  if v_kind = 'service' then
    if tg_op = 'UPDATE' and old.identity_type is not null
       and new.identity_type is distinct from old.identity_type
       and not private.is_admin() then
      raise exception 'A service identity cannot be changed directly.' using errcode = 'P0216';
    end if;
    select provider_type into v_current from public.provider_category_profiles
    where user_id = new.user_id and category_slug = v_category;
    if new.identity_type is null then new.identity_type := coalesce(v_current, 'company'); end if;
    if new.identity_type not in ('individual', 'company') then
      raise exception 'Invalid capability identity.' using errcode = 'P0216';
    end if;
    if new.is_active and new.identity_type is distinct from coalesce(v_current, 'company') then
      new.is_active := false;
    elsif new.is_active and v_category <> 'financial_services'
        and coalesce(v_current, 'company') = 'individual' then
      new.is_active := false;
    end if;
  else
    new.identity_type := null;
  end if;
  return new;
end;
$$;

create or replace function private.set_provider_category_type_internal(
  p_category_slug text, p_provider_type text
) returns void language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare v_user uuid := auth.uid(); v_old text; v_enabled text;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if p_provider_type is null or p_provider_type not in ('individual', 'company') then
    raise exception 'Invalid provider type.' using errcode = 'P0216';
  end if;
  if not exists (select 1 from public.need_categories
      where slug = p_category_slug and is_active) then
    raise exception 'Unknown or retired provider category.' using errcode = 'P0216';
  end if;
  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled' and is_public
      and (country is null or country = (select p.country from public.profiles p where p.id = v_user))
    order by (country = (select p.country from public.profiles p where p.id = v_user)) desc nulls last
    limit 1;
  if lower(coalesce(v_enabled, 'false')) not in ('true', '1') then
    raise exception 'Provider capability profiles are disabled.' using errcode = 'P0216';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text || ':' || p_category_slug, 0));
  select provider_type into v_old from public.provider_category_profiles
    where user_id = v_user and category_slug = p_category_slug for update;
  if v_old is not null and v_old <> p_provider_type then
    raise exception 'Use the identity switch review to change this category.' using errcode = 'P0216';
  end if;
  if v_old = p_provider_type then return; end if;
  insert into public.provider_category_profiles(user_id, category_slug, provider_type)
    values (v_user, p_category_slug, p_provider_type)
    on conflict (user_id, category_slug) do nothing;
  insert into public.audit_logs(user_id, event_type, entity_type, action, new_values)
    values (v_user, 'admin_action', 'provider_category_profile', 'set_initial_provider_identity',
      jsonb_build_object('category_slug', p_category_slug, 'provider_type', p_provider_type));
end;
$$;
revoke all on function private.set_provider_category_type_internal(text, text) from public, anon;
grant execute on function private.set_provider_category_type_internal(text, text) to authenticated;

create or replace function public.save_provider_capabilities(
  p_items jsonb default '[]'::jsonb,
  p_category_slug text default null,
  p_remove_slugs text[] default array[]::text[]
) returns setof public.provider_capabilities
language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_user uuid := auth.uid(); v_type text; v_max int := 30; v_count int;
  v_item record; v_kind text; v_category text;
  v_incoming text[] := array[]::text[];
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if jsonb_typeof(coalesce(p_items, '[]'::jsonb)) <> 'array' then
    raise exception 'Invalid capability selection.' using errcode = 'P0215';
  end if;
  if p_category_slug is not null then
    select provider_type into v_type from public.provider_category_profiles
      where user_id = v_user and category_slug = p_category_slug;
    if v_type is null then raise exception 'Choose a provider identity first.' using errcode = 'P0216'; end if;
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb))
    as x(capability_slug text, metadata jsonb)
  loop
    select nc.category_slug, nc.capability_type into v_category, v_kind
      from public.need_capabilities nc where nc.slug = v_item.capability_slug and nc.is_active;
    if not found or (p_category_slug is not null and v_category <> p_category_slug) then
      raise exception 'Invalid capability for category.' using errcode = 'P0215';
    end if;
    if v_kind = 'service' and coalesce(v_type, 'company') = 'individual'
       and v_category <> 'financial_services' then
      raise exception 'Individual providers cannot save company services.' using errcode = 'P0215';
    end if;
    v_incoming := array_append(v_incoming, v_item.capability_slug);
  end loop;
  select coalesce(nullif(setting_value, '')::int, 30) into v_max
    from public.system_settings where setting_key = 'max_provider_capabilities'
      and (country is null or country = '__global__') limit 1;
  select count(*) into v_count from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where pc.user_id = v_user
      and (p_category_slug is null or nc.category_slug <> p_category_slug
           or pc.identity_type = v_type or nc.capability_type = 'work')
      and (p_category_slug is not null
           or not (pc.capability_slug = any(coalesce(p_remove_slugs, array[]::text[]))));
  if v_count + cardinality(v_incoming) > coalesce(v_max, 30) then
    raise exception 'Maximum limit of % provider capabilities reached.', coalesce(v_max, 30) using errcode = 'P0206';
  end if;
  if coalesce(cardinality(p_remove_slugs), 0) > 0 then
    delete from public.provider_capabilities pc
      where pc.user_id = v_user and pc.capability_slug = any(p_remove_slugs)
        and (p_category_slug is null or pc.identity_type = v_type or pc.identity_type is null);
  end if;
  if p_category_slug is not null then
    delete from public.provider_capabilities pc using public.need_capabilities nc
      where pc.capability_slug = nc.slug and pc.user_id = v_user and nc.category_slug = p_category_slug
        and not (pc.capability_slug = any(v_incoming))
        and (nc.capability_type = 'work' or pc.identity_type = v_type);
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb))
    as x(capability_slug text, metadata jsonb)
  loop
    select capability_type into v_kind from public.need_capabilities
      where slug = v_item.capability_slug;
    if v_kind = 'work' then
      insert into public.provider_capabilities(user_id, capability_slug, verification_level, metadata, created_at)
        values (v_user, v_item.capability_slug, 'self_declared', coalesce(v_item.metadata, '{}'::jsonb), now())
      on conflict (user_id, capability_slug) where identity_type is null do update set metadata = case
        when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb then excluded.metadata
        else public.provider_capabilities.metadata end;
    else
      insert into public.provider_capabilities(user_id, capability_slug, identity_type, verification_level, metadata, created_at)
        values (v_user, v_item.capability_slug, v_type, 'self_declared', coalesce(v_item.metadata, '{}'::jsonb), now())
      on conflict (user_id, capability_slug, identity_type) where identity_type is not null do update set metadata = case
        when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb then excluded.metadata
        else public.provider_capabilities.metadata end;
    end if;
  end loop;
  return query select * from public.provider_capabilities where user_id = v_user;
end;
$$;
revoke all on function public.save_provider_capabilities(jsonb, text, text[]) from public, anon;
grant execute on function public.save_provider_capabilities(jsonb, text, text[]) to authenticated;

-- The existing Company flow saves a company profile and its selected service
-- rows atomically. Route Financial Services through the identity-aware save
-- RPC so these rows do not collide with the same capability under Individual.
create or replace function private.save_financial_company_category_internal(
  p_category_slug text,
  p_services text[],
  p_roles text[],
  p_profile jsonb,
  p_evidence jsonb
) returns void language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_type text;
  v_enabled text;
  v_profile jsonb := coalesce(p_profile, '{}'::jsonb);
  v_services text[] := coalesce(p_services, array[]::text[]);
  v_roles text[] := coalesce(p_roles, array[]::text[]);
  v_areas text[] := array[]::text[];
  v_old_profile jsonb;
  v_items jsonb;
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if p_category_slug <> 'financial_services' or jsonb_typeof(v_profile) <> 'object'
     or jsonb_typeof(coalesce(p_evidence, '[]'::jsonb)) <> 'array'
     or jsonb_array_length(coalesce(p_evidence, '[]'::jsonb)) <> 0
     or cardinality(v_roles) <> 0
     or cardinality(v_services) = 0
     or cardinality(v_services) <> cardinality(array(select distinct x from unnest(v_services) x)) then
    raise exception 'Financial company profile or service selection is invalid.' using errcode = 'P0201';
  end if;
  select provider_type into v_type from public.provider_category_profiles
    where user_id = v_user and category_slug = p_category_slug;
  if v_type is distinct from 'company' then
    raise exception 'Choose Company / Organization for Financial Services first.' using errcode = 'P0202';
  end if;
  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled' and is_public
      and (country is null or country = (select country from public.profiles where id = v_user))
    order by (country = (select country from public.profiles where id = v_user)) desc nulls last limit 1;
  if lower(coalesce(v_enabled, 'false')) not in ('true', '1') then
    raise exception 'Provider capability profiles are disabled.' using errcode = 'P0202';
  end if;
  if not exists (select 1 from public.need_categories
      where slug = p_category_slug and is_active) then
    raise exception 'Financial Services is not available.' using errcode = 'P0202';
  end if;
  if length(coalesce(v_profile->>'company_name', '')) not between 1 and 80
     or length(coalesce(v_profile->>'registration_number', '')) > 40
     or (v_profile ? 'team_size' and v_profile->>'team_size' not in ('1-5','6-20','21-50','50+'))
     or (v_profile ? 'years_in_business' and v_profile->>'years_in_business' not in ('<1','1-2','3-5','6-10','10+'))
     or (v_profile ? 'service_areas' and jsonb_typeof(v_profile->'service_areas') <> 'array') then
    raise exception 'Company profile details are invalid.' using errcode = 'P0204';
  end if;
  if exists (select 1 from unnest(v_services) selected(slug)
      where not exists (select 1 from public.need_capabilities nc
        where nc.slug = selected.slug and nc.category_slug = p_category_slug
          and nc.is_active and nc.capability_type = 'service')) then
    raise exception 'A selected financial service is invalid.' using errcode = 'P0203';
  end if;
  select coalesce(array_agg(distinct btrim(value)), array[]::text[]) into v_areas
    from jsonb_array_elements_text(coalesce(v_profile->'service_areas', '[]'::jsonb)) x(value)
    where btrim(value) <> '';
  if exists (select 1 from unnest(v_areas) area where length(area) > 80) then
    raise exception 'Service areas must be district or city names.' using errcode = 'P0204';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
      'capability_slug', slug, 'metadata', '{}'::jsonb)), '[]'::jsonb)
    into v_items from unnest(v_services) selected(slug);
  perform public.save_provider_capabilities(v_items, p_category_slug, array[]::text[]);

  select to_jsonb(cp) into v_old_profile from public.provider_company_profiles cp
    where cp.user_id = v_user and cp.category_slug = p_category_slug;
  insert into public.provider_company_profiles(
    user_id, category_slug, company_name, registration_number, team_size,
    years_in_business, service_areas
  ) values (
    v_user, p_category_slug, nullif(btrim(v_profile->>'company_name'), ''),
    nullif(btrim(v_profile->>'registration_number'), ''),
    nullif(v_profile->>'team_size', ''), nullif(v_profile->>'years_in_business', ''), v_areas
  ) on conflict (user_id, category_slug) do update set
    company_name = excluded.company_name,
    registration_number = excluded.registration_number,
    team_size = excluded.team_size,
    years_in_business = excluded.years_in_business,
    service_areas = excluded.service_areas,
    updated_at = now();
  insert into public.audit_logs(user_id, event_type, entity_type, action, old_values, new_values)
    values (v_user, 'admin_action', 'provider_company_profile', 'save_financial_company_category',
      v_old_profile, jsonb_build_object('category_slug', p_category_slug,
        'services', to_jsonb(v_services), 'service_count', cardinality(v_services)));
end;
$$;
revoke all on function private.save_financial_company_category_internal(text, text[], text[], jsonb, jsonb)
  from public, anon;
grant execute on function private.save_financial_company_category_internal(text, text[], text[], jsonb, jsonb)
  to authenticated;

create or replace function public.save_company_category(
  p_category_slug text,
  p_services text[],
  p_roles text[],
  p_profile jsonb,
  p_evidence jsonb,
  p_presentation jsonb
) returns void language plpgsql security invoker
set search_path = public, private, pg_temp as $$
declare
  v_name text := btrim(coalesce(p_profile->>'company_name', ''));
  v_mode text := coalesce(p_presentation->>'display_mode', 'company');
  v_rep text := btrim(coalesce(p_presentation->>'representative_name', ''));
  v_authorized boolean := coalesce(
    (p_presentation->>'representative_authorized')::boolean, false);
  v_presentation jsonb;
begin
  if v_name = '' then
    raise exception 'Company name is required.' using errcode = 'P0217';
  end if;
  if char_length(v_name) > 80 then
    raise exception 'Company name must be 80 characters or fewer.' using errcode = 'P0218';
  end if;
  if v_mode not in ('company', 'company_with_representative') then
    raise exception 'Invalid company display mode.' using errcode = 'P0216';
  end if;
  if v_mode = 'company_with_representative'
     and (v_rep = '' or not v_authorized) then
    raise exception 'Representative name and authorization are required.' using errcode = 'P0219';
  end if;

  perform private.set_provider_category_type_internal(p_category_slug, 'company');
  if p_category_slug = 'financial_services' then
    perform private.save_financial_company_category_internal(
      p_category_slug, p_services, p_roles, p_profile, p_evidence);
  else
    perform private.save_company_category_internal(
      p_category_slug, p_services, p_roles, p_profile, p_evidence);
  end if;

  v_presentation := coalesce(p_presentation, '{}'::jsonb) || jsonb_build_object(
    'display_mode', v_mode,
    'display_name', v_name,
    'representative_name', case when v_mode = 'company_with_representative'
      then v_rep else null end,
    'representative_authorized', case when v_mode = 'company_with_representative'
      then v_authorized else false end);
  perform private.save_provider_identity_presentation_internal(
    p_category_slug, 'company', v_presentation);
end;
$$;
revoke all on function public.save_company_category(text, text[], text[], jsonb, jsonb, jsonb)
  from public, anon;
grant execute on function public.save_company_category(text, text[], text[], jsonb, jsonb, jsonb)
  to authenticated;

-- Reuse the existing Company document review. For Financial Services only,
-- reviewed registration/authorization documents satisfy the matching
-- capability evidence keys; no separate company-proof store is introduced.
create or replace function private.sync_financial_company_document_evidence()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_key text;
  v_evidence_status text;
begin
  if new.category_slug <> 'financial_services' then return new; end if;
  v_key := case new.document_type
    when 'business_registration' then 'business_registration'
    when 'business_licence' then 'financial_authorization'
    when 'certificate' then 'financial_authorization'
    else null end;
  if v_key is null then return new; end if;

  if tg_op = 'UPDATE' and old.file_path is distinct from new.file_path then
    update public.provider_capability_evidence e
      set status = 'expired', updated_at = now()
      from public.provider_capabilities pc
      join public.need_capabilities nc on nc.slug = pc.capability_slug
      where e.provider_capability_id = pc.id and pc.user_id = new.user_id
        and pc.identity_type = 'company' and nc.category_slug = 'financial_services'
        and e.file_url = old.file_path and e.requirement_key = v_key
        and e.provider_type = 'company' and e.status = 'approved';
    update public.provider_capabilities pc
      set verification_level = 'self_declared', verified_by = null, verified_at = null,
          is_active = false
      from public.need_capabilities nc
      where nc.slug = pc.capability_slug and nc.category_slug = 'financial_services'
        and pc.user_id = new.user_id and pc.identity_type = 'company'
        and pc.verification_level = 'provider_verified';
  end if;

  v_evidence_status := case new.status
    when 'approved' then 'approved'
    when 'rejected' then 'rejected'
    else 'pending' end;
  update public.provider_capability_evidence e
    set status = v_evidence_status,
        reject_reason = case when v_evidence_status = 'rejected' then new.reject_reason else null end,
        reviewed_by = new.reviewed_by, reviewed_at = new.reviewed_at, updated_at = now()
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where e.provider_capability_id = pc.id and pc.user_id = new.user_id
      and pc.identity_type = 'company' and nc.category_slug = 'financial_services'
      and e.requirement_key = v_key and e.file_url = new.file_path
      and e.provider_type = 'company';
  insert into public.provider_capability_evidence(
    provider_capability_id, requirement_key, file_url, status, reject_reason,
    reviewed_by, reviewed_at, provider_type
  )
  select pc.id, v_key, new.file_path, v_evidence_status,
         case when v_evidence_status = 'rejected' then new.reject_reason else null end,
         new.reviewed_by, new.reviewed_at, 'company'
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  where pc.user_id = new.user_id and pc.identity_type = 'company'
    and nc.category_slug = 'financial_services'
    and not exists (select 1 from public.provider_capability_evidence e
      where e.provider_capability_id = pc.id and e.requirement_key = v_key
        and e.file_url = new.file_path);

  if v_evidence_status = 'approved' then
    update public.provider_capabilities pc
      set verification_level = 'provider_verified',
          verified_by = new.reviewed_by, verified_at = coalesce(new.reviewed_at, now())
      from public.need_capabilities nc
      where nc.slug = pc.capability_slug and nc.category_slug = 'financial_services'
        and pc.user_id = new.user_id and pc.identity_type = 'company'
        and exists (select 1 from public.verification_requirements vr
          where vr.scope_type = 'capability' and vr.scope_id = pc.capability_slug
            and vr.provider_type = 'company' and vr.is_active
            and cardinality(vr.required_evidence) > 0
            and not exists (
              select 1 from unnest(vr.required_evidence) required(key)
              where not exists (select 1 from public.provider_capability_evidence e
                where e.provider_capability_id = pc.id and e.provider_type = 'company'
                  and e.requirement_key = required.key and e.status = 'approved'
                  and (e.expires_at is null or e.expires_at > now()))
            ));
  end if;
  return new;
end;
$$;
drop trigger if exists trg_sync_financial_company_document_evidence
  on public.provider_company_verification_submissions;
create trigger trg_sync_financial_company_document_evidence
  after insert or update of status, file_path, document_type
  on public.provider_company_verification_submissions
  for each row execute function private.sync_financial_company_document_evidence();

update public.provider_company_verification_submissions
set status = status
where category_slug = 'financial_services';

commit;

notify pgrst, 'reload schema';

-- ============================================================================
-- END MERGED SECTION (31/52): patch_financial_services_provider_capabilities.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (32/52): patch_loan_classification.sql
-- ============================================================================

-- Add structured classifications while retaining the existing free-text purpose.
-- Safe to re-run; existing requests remain available.

begin;

alter table public.loan_requests
  add column if not exists loan_category text,
  add column if not exists loan_purpose text;

-- Backfill only rows with recognizable legacy titles. Unrecognized records stay
-- available with null structured fields for later review.
update public.loan_requests
set loan_category = case
  when lower(title) ~ 'school|university|tuition|certification|education' then 'Education Loans'
  when lower(title) ~ 'medical|clinic|surgery|health' then 'Personal Loans'
  when lower(title) ~ 'boda|motorcycle|vehicle|van|car|commercial van' then 'Asset Financing'
  when lower(title) ~ 'farm|irrigation|crop|tractor|agri' then 'Agricultural Loans'
  when lower(title) ~ 'land|home|property|mortgage|renovation' then 'Property Loans'
  when lower(title) ~ 'inventory|stock|working capital|working|business|bakery|shop|tailor|equipment upgrade|startup|expansion|agribusiness|phone repair' then 'Business Loans'
  else 'Personal Loans' end,
    loan_purpose = case
  when lower(title) ~ 'school|university|tuition|certification|education' then case
      when lower(title) ~ 'certification|professional' then 'Professional Courses'
      when lower(title) ~ 'university|tuition' then 'University Tuition'
      else 'School Fees' end
  when lower(title) ~ 'medical|clinic|surgery|health' then 'Medical Expenses'
  when lower(title) ~ 'boda|motorcycle|vehicle|van|car|commercial van' then case
      when lower(title) ~ 'boda' then 'Boda Boda Financing'
      when lower(title) ~ 'motorcycle' then 'Motorcycle Financing'
      else 'Car Financing' end
  when lower(title) ~ 'farm|irrigation|crop|tractor|agri' then case
      when lower(title) ~ 'irrigation|equipment' then 'Agricultural Equipment'
      else 'Crop Production' end
  when lower(title) ~ 'land|home|property|mortgage|renovation' then case
      when lower(title) ~ 'renovation|improvement' then 'Home Improvement'
      when lower(title) ~ 'construction' then 'Home Construction'
      else 'Other Property Needs' end
  when lower(title) ~ 'inventory|stock|working capital|working|business|bakery|shop|tailor|equipment upgrade|startup|expansion|agribusiness|phone repair' then case
      when lower(title) ~ 'inventory|stock|restock' then 'Inventory / Stock Purchase'
      when lower(title) ~ 'working capital' then 'Working Capital'
      when lower(title) ~ 'equipment|machine|tailor|phone repair' then 'Equipment for Business'
      when lower(title) ~ 'expansion|boost' then 'Business Expansion'
      else 'Other Business Needs' end
  else 'Other Personal Needs' end
where loan_category is null or loan_purpose is null;

create index if not exists idx_loan_requests_category_purpose
  on public.loan_requests (loan_category, loan_purpose);

commit;

notify pgrst, 'reload schema';

-- ============================================================================
-- END MERGED SECTION (32/52): patch_loan_classification.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (33/52): patch_loan_products.sql
-- ============================================================================

-- Provider loan products (Part B).
-- Apply after provider identities, capability verification policies, and the
-- Financial Services provider patch. This adds a separate lender product
-- catalogue; borrower loan_requests and loan_offers are not modified.

begin;

create table if not exists public.loan_product_categories (
  slug text primary key,
  name text not null,
  sort_order integer not null,
  is_active boolean not null default true
);

create table if not exists public.loan_product_purposes (
  category_slug text not null references public.loan_product_categories(slug),
  slug text not null,
  name text not null,
  sort_order integer not null,
  is_active boolean not null default true,
  primary key(category_slug, slug)
);

create table if not exists public.loan_product_interest_methods (
  slug text primary key,
  name text not null,
  sort_order integer not null,
  is_active boolean not null default true
);

create table if not exists public.loan_product_repayment_frequencies (
  slug text primary key,
  name text not null,
  sort_order integer not null,
  is_active boolean not null default true
);

insert into public.loan_product_categories(slug,name,sort_order) values
 ('personal','Personal',10),('business','Business',20),
 ('asset_financing','Asset Financing',30),('agricultural','Agricultural',40),
 ('property','Property',50),('education','Education',60),('lifestyle','Lifestyle',70)
on conflict(slug) do update set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

insert into public.loan_product_purposes(category_slug,slug,name,sort_order) values
 ('personal','general_personal_expenses','General Personal Expenses',10),
 ('personal','salary_advance','Salary Advance',20),
 ('personal','medical_expenses','Medical Expenses',30),
 ('personal','debt_consolidation','Debt Consolidation',40),
 ('personal','family_support','Family Support',50),
 ('personal','other_personal_needs','Other Personal Needs',60),
 ('business','business_startup','Business Startup',10),
 ('business','business_expansion','Business Expansion',20),
 ('business','working_capital','Working Capital',30),
 ('business','inventory_stock_purchase','Inventory / Stock Purchase',40),
 ('business','equipment_for_business','Equipment for Business',50),
 ('business','contract_financing','Contract Financing',60),
 ('business','invoice_financing','Invoice Financing',70),
 ('business','other_business_needs','Other Business Needs',80),
 ('asset_financing','boda_boda','Boda Boda',10),
 ('asset_financing','car','Car',20),
 ('asset_financing','tuk_tuk','Tuk-tuk',30),
 ('asset_financing','motorcycle','Motorcycle',40),
 ('asset_financing','smartphone','Smartphone',50),
 ('asset_financing','laptop','Laptop',60),
 ('asset_financing','heavy_machinery','Heavy Machinery',70),
 ('asset_financing','agricultural_equipment','Agricultural Equipment',80),
 ('asset_financing','other_asset_financing','Other Asset Financing',90),
 ('agricultural','crop_production','Crop Production',10),
 ('agricultural','greenhouse_farming','Greenhouse Farming',20),
 ('agricultural','livestock','Livestock',30),
 ('agricultural','poultry_farming','Poultry Farming',40),
 ('agricultural','farm_inputs','Farm Inputs',50),
 ('agricultural','irrigation','Irrigation',60),
 ('agricultural','tractor_financing','Tractor Financing',70),
 ('agricultural','agricultural_equipment','Agricultural Equipment',80),
 ('agricultural','other_agricultural_needs','Other Agricultural Needs',90),
 ('property','land_purchase','Land Purchase',10),
 ('property','home_construction','Home Construction',20),
 ('property','home_improvement','Home Improvement',30),
 ('property','mortgage_financing','Mortgage Financing',40),
 ('property','property_development','Property Development',50),
 ('property','commercial_property','Commercial Property',60),
 ('property','other_property_needs','Other Property Needs',70),
 ('education','school_fees','School Fees',10),
 ('education','university_tuition','University Tuition',20),
 ('education','vocational_training','Vocational Training',30),
 ('education','professional_courses','Professional Courses',40),
 ('education','study_abroad','Study Abroad',50),
 ('education','educational_equipment','Educational Equipment',60),
 ('education','other_education_needs','Other Education Needs',70),
 ('lifestyle','wedding_expenses','Wedding Expenses',10),
 ('lifestyle','travel_holiday','Travel / Holiday',20),
 ('lifestyle','events_celebrations','Events and Celebrations',30),
 ('lifestyle','family_events','Family Events',40),
 ('lifestyle','relocation_expenses','Relocation Expenses',50),
 ('lifestyle','other_lifestyle_needs','Other Lifestyle Needs',60)
on conflict(category_slug,slug) do update set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

insert into public.loan_product_interest_methods(slug,name,sort_order) values
 ('flat_rate','Flat rate',10),('reducing_balance','Reducing balance',20),
 ('compound_interest','Compound interest',30),('simple_interest','Simple interest',40),
 ('custom','Custom / explain in terms',50)
on conflict(slug) do update set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

insert into public.loan_product_repayment_frequencies(slug,name,sort_order) values
 ('daily','Daily',10),('weekly','Weekly',20),('biweekly','Biweekly',30),
 ('monthly','Monthly',40),('custom','Custom',50)
on conflict(slug) do update set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

create table if not exists public.loan_products (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.profiles(id) on delete cascade,
  identity_type text not null check(identity_type in ('individual','company')),
  provider_capability_id uuid not null references public.provider_capabilities(id) on delete restrict,
  category_slug text not null references public.loan_product_categories(slug),
  purpose_slug text,
  product_title text not null check(char_length(product_title) between 3 and 100),
  short_description text not null default '' check(char_length(short_description) <= 1000),
  minimum_amount bigint,
  maximum_amount bigint,
  currency_code text references public.currencies(code),
  terms jsonb not null default '{}'::jsonb check(jsonb_typeof(terms)='object'),
  status text not null default 'draft'
    check(status in ('draft','active','paused','unavailable','archived')),
  is_featured boolean not null default false,
  views_count bigint not null default 0 check(views_count >= 0),
  enquiries_count bigint not null default 0 check(enquiries_count >= 0),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key(category_slug,purpose_slug)
    references public.loan_product_purposes(category_slug,slug),
  check(minimum_amount is null or minimum_amount > 0),
  check(maximum_amount is null or maximum_amount > 0),
  check(minimum_amount is null or maximum_amount is null or minimum_amount <= maximum_amount)
);

create index if not exists idx_loan_products_owner_status
  on public.loan_products(provider_id,status,updated_at desc);
create index if not exists idx_loan_products_category_purpose
  on public.loan_products(category_slug,purpose_slug,status);
create index if not exists idx_loan_products_capability
  on public.loan_products(provider_capability_id,status);

alter table public.loan_products enable row level security;
revoke all on public.loan_products from public,anon,authenticated;
grant select on public.loan_products to authenticated;
drop policy if exists loan_products_owner_read on public.loan_products;
create policy loan_products_owner_read on public.loan_products
  for select to authenticated using(provider_id=auth.uid());

grant select on public.loan_product_categories,public.loan_product_purposes,
  public.loan_product_interest_methods,public.loan_product_repayment_frequencies
  to anon,authenticated;

insert into public.system_settings(setting_key,country,setting_value,setting_type,category,description,is_public)
values
 ('loan_products_max_active_free',null,'1','number','provider','Maximum active loan products for Free provider plan',true),
 ('loan_products_max_active_lender',null,'3','number','provider','Maximum active loan products for Lender provider plan',true),
 ('loan_products_max_active_pro',null,'10','number','provider','Maximum active loan products for Pro provider plan',true),
 ('loan_products_max_featured_free',null,'0','number','provider','Maximum featured loan products for Free provider plan',true),
 ('loan_products_max_featured_lender',null,'1','number','provider','Maximum featured loan products for Lender provider plan',true),
 ('loan_products_max_featured_pro',null,'3','number','provider','Maximum featured loan products for Pro provider plan',true)
on conflict(setting_key,coalesce(country,'__global__')) do nothing;

create or replace function private.loan_products_feature_enabled(p_user_id uuid default auth.uid())
returns boolean language sql stable security definer
set search_path=public,pg_temp as $$
  select coalesce((
    select lower(s.setting_value) in ('true','1')
    from public.system_settings s
    join public.profiles p on p.id=p_user_id
    where s.setting_key='capability_profiles_enabled' and s.is_public
      and (s.country=p.country or s.country is null)
    order by (s.country=p.country) desc nulls last limit 1
  ),false)
$$;

revoke all on function private.loan_products_feature_enabled(uuid) from public,anon;
grant execute on function private.loan_products_feature_enabled(uuid) to authenticated;
drop policy if exists loan_products_active_market_read on public.loan_products;
create policy loan_products_active_market_read on public.loan_products
  for select to authenticated using(
    status='active' and private.loan_products_feature_enabled()
    and (
      identity_type='individual'
      or private.provider_capability_is_eligible(provider_capability_id)
    )
  );

create or replace function public.save_loan_product_draft(
  p_product_id uuid,
  p_payload jsonb
) returns uuid language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare
  v_user uuid:=auth.uid(); v_id uuid; v_identity text; v_capability uuid;
  v_category text; v_purpose text; v_title text; v_description text;
  v_min bigint; v_max bigint; v_currency text; v_terms jsonb;
begin
  if v_user is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(v_user) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  if jsonb_typeof(p_payload)<>'object' then raise exception 'Invalid product draft.' using errcode='22023'; end if;
  v_identity:=p_payload->>'identity_type'; v_capability:=(p_payload->>'provider_capability_id')::uuid;
  v_category:=p_payload->>'category_slug'; v_purpose:=nullif(p_payload->>'purpose_slug','');
  v_title:=coalesce(nullif(btrim(p_payload->>'product_title'),''),'Untitled loan product');
  v_description:=coalesce(p_payload->>'short_description','');
  v_min:=nullif(p_payload->>'minimum_amount','')::bigint;
  v_max:=nullif(p_payload->>'maximum_amount','')::bigint;
  v_currency:=nullif(p_payload->>'currency_code','');
  v_terms:=coalesce(p_payload->'terms','{}'::jsonb);
  if v_identity not in ('individual','company') or v_capability is null
     or not exists(select 1 from public.provider_category_profiles pcp
       where pcp.user_id=v_user and pcp.category_slug='financial_services'
         and pcp.provider_type=v_identity) then
    raise exception 'Choose the matching Individual or Company financial identity first.' using errcode='P0216';
  end if;
  if not exists(select 1 from public.provider_capabilities pc
       join public.need_capabilities nc on nc.slug=pc.capability_slug
       where pc.id=v_capability and pc.user_id=v_user
         and pc.identity_type=v_identity and nc.category_slug='financial_services') then
    raise exception 'Choose a Financial Services capability saved under this identity.' using errcode='P0216';
  end if;
  if not exists(select 1 from public.loan_product_categories c where c.slug=v_category and c.is_active) then
    raise exception 'Choose an available product category.' using errcode='22023'; end if;
  if v_purpose is not null and not exists(select 1 from public.loan_product_purposes p
      where p.category_slug=v_category and p.slug=v_purpose and p.is_active) then
    raise exception 'Choose a purpose from this category.' using errcode='22023'; end if;
  if v_min is not null and v_min<=0 or v_max is not null and v_max<=0
     or v_min is not null and v_max is not null and v_min>v_max then
    raise exception 'Enter a valid minimum and maximum amount.' using errcode='22023'; end if;
  if v_currency is not null and not exists(select 1 from public.currencies c where c.code=v_currency) then
    raise exception 'Choose an available currency.' using errcode='22023'; end if;
  if jsonb_typeof(v_terms)<>'object' then raise exception 'Invalid product terms.' using errcode='22023'; end if;
  if p_product_id is null then
    insert into public.loan_products(provider_id,identity_type,provider_capability_id,category_slug,
      purpose_slug,product_title,short_description,minimum_amount,maximum_amount,currency_code,terms,is_featured)
    values(v_user,v_identity,v_capability,v_category,v_purpose,v_title,v_description,
      v_min,v_max,v_currency,v_terms,coalesce((v_terms->>'featured')::boolean,false)) returning id into v_id;
  else
    update public.loan_products set identity_type=v_identity,provider_capability_id=v_capability,
      category_slug=v_category,purpose_slug=v_purpose,product_title=v_title,
      short_description=v_description,minimum_amount=v_min,maximum_amount=v_max,
      currency_code=v_currency,terms=v_terms,
      is_featured=coalesce((v_terms->>'featured')::boolean,false),
      status=case when status='archived' then status else 'draft' end,
      updated_at=now()
    where id=p_product_id and provider_id=v_user and status<>'archived'
    returning id into v_id;
    if v_id is null then raise exception 'Product not found or archived.' using errcode='P0212'; end if;
  end if;
  return v_id;
end;
$$;
revoke all on function public.save_loan_product_draft(uuid,jsonb) from public,anon;
grant execute on function public.save_loan_product_draft(uuid,jsonb) to authenticated;

create or replace function public.publish_loan_product(p_product_id uuid)
returns jsonb language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare v_user uuid:=auth.uid(); v_product public.loan_products%rowtype;
  v_plan text; v_country text; v_max int; v_featured_max int; v_active int; v_featured int;
  v_setting text; v_required text[]:=array['interest_method','repayment_frequency','minimum_period',
    'maximum_period','secured','guarantor_required','minimum_age','eligible_locations'];
  v_key text;
begin
  if v_user is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text||':loan_products',0));
  if not private.loan_products_feature_enabled(v_user) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  select * into v_product from public.loan_products where id=p_product_id and provider_id=v_user for update;
  if not found then raise exception 'Product not found.' using errcode='P0212'; end if;
  if v_product.status='archived' then raise exception 'Archived products cannot be published.' using errcode='22023'; end if;
  if v_product.purpose_slug is null or v_product.minimum_amount is null or v_product.maximum_amount is null
     or v_product.currency_code is null or v_product.product_title='Untitled loan product'
     or length(btrim(v_product.short_description))<10 then
    raise exception 'Complete category, purpose, title, description, amount range, and currency.' using errcode='22023'; end if;
  if v_product.minimum_amount>v_product.maximum_amount then
    raise exception 'Minimum amount cannot exceed maximum amount.' using errcode='22023'; end if;
  for v_key in select unnest(v_required) loop
    if not (v_product.terms ? v_key) or v_product.terms->v_key is null then
      raise exception 'Complete all required loan terms before publishing.' using errcode='22023'; end if;
  end loop;
  if not exists(select 1 from public.provider_category_profiles pcp
       where pcp.user_id=v_user and pcp.category_slug='financial_services'
         and pcp.provider_type=v_product.identity_type) then
    raise exception 'This provider identity is no longer selected.' using errcode='P0216'; end if;
  if not exists(select 1 from public.provider_capabilities pc
       where pc.id=v_product.provider_capability_id and pc.user_id=v_user
         and pc.identity_type=v_product.identity_type and pc.is_active
         and (v_product.identity_type='individual'
              or (pc.verification_level='provider_verified'
                  and private.provider_capability_is_eligible(pc.id)))) then
    raise exception 'An eligible Financial Services capability under this identity is required to publish.' using errcode='P0216'; end if;
  if not exists(select 1 from public.profiles p join public.kyc_verifications k on k.user_id=p.id
       where p.id=v_user and p.account_status='active' and p.phone_verified_at is not null
         and k.status='approved' and (k.expires_at is null or k.expires_at>now())) then
    raise exception 'Complete the existing account and identity verification checks to publish.' using errcode='P0216'; end if;
  select coalesce(s.plan::text,'free'),p.country into v_plan,v_country
    from public.profiles p left join lateral (select plan from public.subscriptions
      where user_id=p.id and status='active' order by created_at desc limit 1) s on true
    where p.id=v_user;
  select setting_value::int into v_max from public.system_settings
    where setting_key='loan_products_max_active_'||v_plan and (country=v_country or country is null)
    order by (country=v_country) desc nulls last limit 1;
  select setting_value::int into v_featured_max from public.system_settings
    where setting_key='loan_products_max_featured_'||v_plan and (country=v_country or country is null)
    order by (country=v_country) desc nulls last limit 1;
  if v_max is null or v_featured_max is null then raise exception 'Loan product limits are not configured.' using errcode='P0206'; end if;
  select count(*) into v_active from public.loan_products where provider_id=v_user and status='active' and id<>p_product_id;
  select count(*) into v_featured from public.loan_products where provider_id=v_user and status='active' and is_featured and id<>p_product_id;
  if v_active>=v_max then raise exception 'LOAN_PRODUCT_LIMIT: You have reached the active product limit for your plan.' using errcode='P0206'; end if;
  if v_product.is_featured and v_featured>=v_featured_max then raise exception 'LOAN_PRODUCT_FEATURED_LIMIT: Your plan has no featured placements available.' using errcode='P0206'; end if;
  update public.loan_products set status='active',published_at=coalesce(published_at,now()),updated_at=now()
    where id=p_product_id;
  return jsonb_build_object('id',p_product_id,'status','active','active_count',v_active+1,'active_limit',v_max);
end;
$$;
revoke all on function public.publish_loan_product(uuid) from public,anon;
grant execute on function public.publish_loan_product(uuid) to authenticated;

create or replace function public.set_loan_product_status(p_product_id uuid,p_status text)
returns boolean language plpgsql security definer
set search_path=public,private,pg_temp as $$
begin
  if auth.uid() is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if p_status not in ('paused','unavailable','archived') then raise exception 'Invalid product status.' using errcode='22023'; end if;
  update public.loan_products set status=p_status,updated_at=now()
    where id=p_product_id and provider_id=auth.uid() and status<>'archived';
  if not found then raise exception 'Product not found.' using errcode='P0212'; end if;
  return true;
end;
$$;
revoke all on function public.set_loan_product_status(uuid,text) from public,anon;
grant execute on function public.set_loan_product_status(uuid,text) to authenticated;

create or replace function public.get_my_loan_product_quota()
returns jsonb language plpgsql security definer stable
set search_path=public,private,pg_temp as $$
declare v_plan text;v_country text;v_limit int;v_count int;v_featured_limit int;v_featured int;
begin
  if auth.uid() is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(auth.uid()) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  select coalesce(s.plan::text,'free'),p.country into v_plan,v_country from public.profiles p
   left join lateral(select plan from public.subscriptions where user_id=p.id and status='active'
   order by created_at desc limit 1)s on true where p.id=auth.uid();
  select setting_value::int into v_limit from public.system_settings where setting_key='loan_products_max_active_'||v_plan
   and(country=v_country or country is null) order by(country=v_country) desc nulls last limit 1;
  select setting_value::int into v_featured_limit from public.system_settings where setting_key='loan_products_max_featured_'||v_plan
   and(country=v_country or country is null) order by(country=v_country) desc nulls last limit 1;
  select count(*) into v_count from public.loan_products where provider_id=auth.uid() and status='active';
  select count(*) into v_featured from public.loan_products where provider_id=auth.uid() and status='active' and is_featured;
  return jsonb_build_object('plan',v_plan,'active_count',v_count,'active_limit',v_limit,
    'featured_count',v_featured,'featured_limit',v_featured_limit);
end;
$$;
revoke all on function public.get_my_loan_product_quota() from public,anon;
grant execute on function public.get_my_loan_product_quota() to authenticated;

create or replace view public.v_active_loan_products
with (security_barrier=true) as
select lp.id,lp.identity_type,lp.category_slug,lc.name as category_name,
  lp.purpose_slug,pu.name as purpose_name,lp.product_title,lp.short_description,
  lp.minimum_amount,lp.maximum_amount,lp.currency_code,lp.terms,lp.is_featured,
  lp.published_at,lp.views_count,lp.enquiries_count,
  case when lp.identity_type='company' then cp.company_name
       else coalesce(ip.display_name,pr.full_name,'Individual provider') end as provider_name,
  null::text as provider_logo_url,
  pc.verification_level='provider_verified' as provider_verified
from public.loan_products lp
join public.loan_product_categories lc on lc.slug=lp.category_slug
join public.loan_product_purposes pu on pu.category_slug=lp.category_slug and pu.slug=lp.purpose_slug
join public.provider_capabilities pc on pc.id=lp.provider_capability_id
left join public.provider_category_profiles pcp on pcp.user_id=lp.provider_id and pcp.category_slug='financial_services'
left join public.provider_company_profiles cp on cp.user_id=lp.provider_id and cp.category_slug='financial_services'
left join public.provider_identity_presentations ip on ip.user_id=lp.provider_id and ip.category_slug='financial_services' and ip.identity_type='individual'
left join public.profiles pr on pr.id=lp.provider_id
where lp.status='active' and private.loan_products_feature_enabled(lp.provider_id)
  and pcp.provider_type=lp.identity_type and pc.identity_type=lp.identity_type
  and pc.is_active
  and (lp.identity_type='individual'
       or (pc.verification_level='provider_verified'
           and private.provider_capability_is_eligible(pc.id)));
grant select on public.v_active_loan_products to anon,authenticated;

commit;
notify pgrst,'reload schema';

-- ============================================================================
-- END MERGED SECTION (33/52): patch_loan_products.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (34/52): patch_individual_loan_services_no_proof.sql
-- ============================================================================

-- Individual Financial Services are active without service evidence.
-- Company Financial Services keep the existing proof and review requirements.
-- Apply in Supabase SQL Editor after patch_financial_services_provider_capabilities.sql.
-- Safe to re-run.

begin;

do $$
begin
  if to_regclass('public.provider_capabilities') is null
     or to_regclass('public.need_capabilities') is null then
    raise exception 'Provider capability tables are missing. Apply the Financial Services provider patch first.';
  end if;
end;
$$;

create or replace function private.activate_individual_financial_service_without_proof()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if new.identity_type = 'individual' and exists (
    select 1
    from public.need_capabilities nc
    where nc.slug = new.capability_slug
      and nc.category_slug = 'financial_services'
      and nc.capability_type = 'service'
      and nc.is_active
  ) then
    new.is_active := true;
  end if;
  return new;
end;
$$;

drop trigger if exists zz_activate_individual_financial_service_without_proof
  on public.provider_capabilities;
create trigger zz_activate_individual_financial_service_without_proof
  before insert or update of is_active, verification_level, identity_type, capability_slug
  on public.provider_capabilities
  for each row
  execute function private.activate_individual_financial_service_without_proof();

-- Re-evaluate existing Individual service rows through the policy triggers.
update public.provider_capabilities pc
set is_active = true
from public.need_capabilities nc
where nc.slug = pc.capability_slug
  and nc.category_slug = 'financial_services'
  and nc.capability_type = 'service'
  and pc.identity_type = 'individual';

commit;

-- ============================================================================
-- END MERGED SECTION (34/52): patch_individual_loan_services_no_proof.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (35/52): patch_loan_products_part_b_hardening.sql
-- ============================================================================

-- Part B follow-up: require approved financial capability proof for Companies
-- (Individuals do not require capability proof) and expose Company logos.
-- Apply after patch_loan_products.sql and the Financial Services provider
-- identity / verification / company-logo patches.

begin;

create or replace function private.guard_loan_product_activation()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  if new.status <> 'active' then
    return new;
  end if;

  if not private.loan_products_feature_enabled(new.provider_id) then
    raise exception 'Provider loan products are disabled.' using errcode = 'P0216';
  end if;

  if not exists (
    select 1
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    join public.provider_category_profiles pcp
      on pcp.user_id = pc.user_id
     and pcp.category_slug = nc.category_slug
    where pc.id = new.provider_capability_id
      and pc.user_id = new.provider_id
      and pc.identity_type = new.identity_type
      and pcp.provider_type = new.identity_type
      and nc.category_slug = 'financial_services'
      and pc.is_active
      and (
        new.identity_type = 'individual'
        or (
          pc.verification_level = 'provider_verified'
          and private.provider_capability_is_eligible(pc.id)
        )
      )
  ) then
    raise exception 'Choose a Financial Services capability under this identity; Company capabilities must have approved proof.'
      using errcode = 'P0216';
  end if;

  return new;
end;
$$;

revoke all on function private.guard_loan_product_activation() from public, anon, authenticated;
drop trigger if exists trg_guard_loan_product_activation on public.loan_products;
create trigger trg_guard_loan_product_activation
  before insert or update of status, provider_capability_id, identity_type
  on public.loan_products
  for each row execute function private.guard_loan_product_activation();

create or replace function private.loan_product_logo_is_public(p_object_name text)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1
    from public.provider_company_profiles cp
    join public.provider_category_profiles pcp
      on pcp.user_id = cp.user_id and pcp.category_slug = cp.category_slug
    join public.loan_products lp
      on lp.provider_id = cp.user_id and lp.identity_type = 'company'
    join public.provider_capabilities pc
      on pc.id = lp.provider_capability_id
    where cp.category_slug = 'financial_services'
      and cp.logo_path = p_object_name
      and pcp.provider_type = 'company'
      and lp.status = 'active'
      and private.loan_products_feature_enabled(lp.provider_id)
      and pc.is_active
      and pc.verification_level = 'provider_verified'
      and private.provider_capability_is_eligible(pc.id)
  );
$$;

revoke all on function private.loan_product_logo_is_public(text) from public;
grant execute on function private.loan_product_logo_is_public(text) to anon, authenticated;
drop policy if exists financial_loan_product_logo_marketplace_read on storage.objects;
create policy financial_loan_product_logo_marketplace_read
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'provider-evidence'
    and private.loan_product_logo_is_public(name)
  );

create or replace view public.v_active_loan_products
with (security_barrier = true) as
select lp.id, lp.identity_type, lp.category_slug, lc.name as category_name,
  lp.purpose_slug, pu.name as purpose_name, lp.product_title,
  lp.short_description, lp.minimum_amount, lp.maximum_amount,
  lp.currency_code, lp.terms, lp.is_featured, lp.published_at,
  lp.views_count, lp.enquiries_count,
  case when lp.identity_type = 'company' then cp.company_name
       else coalesce(ip.display_name, pr.full_name, 'Individual provider')
  end as provider_name,
  case when lp.identity_type = 'company' then cp.logo_path else null end
    as provider_logo_url,
  pc.verification_level = 'provider_verified' as provider_verified
from public.loan_products lp
join public.loan_product_categories lc on lc.slug = lp.category_slug
join public.loan_product_purposes pu
  on pu.category_slug = lp.category_slug and pu.slug = lp.purpose_slug
join public.provider_capabilities pc on pc.id = lp.provider_capability_id
left join public.provider_category_profiles pcp
  on pcp.user_id = lp.provider_id and pcp.category_slug = 'financial_services'
left join public.provider_company_profiles cp
  on cp.user_id = lp.provider_id and cp.category_slug = 'financial_services'
left join public.provider_identity_presentations ip
  on ip.user_id = lp.provider_id
 and ip.category_slug = 'financial_services'
 and ip.identity_type = 'individual'
left join public.profiles pr on pr.id = lp.provider_id
where lp.status = 'active'
  and private.loan_products_feature_enabled(lp.provider_id)
  and pcp.provider_type = lp.identity_type
  and pc.identity_type = lp.identity_type
  and pc.is_active
  and (
    lp.identity_type = 'individual'
    or (
      pc.verification_level = 'provider_verified'
      and private.provider_capability_is_eligible(pc.id)
    )
  );

grant select on public.v_active_loan_products to anon, authenticated;

commit;
notify pgrst, 'reload schema';

-- ============================================================================
-- END MERGED SECTION (35/52): patch_loan_products_part_b_hardening.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (36/52): patch_loan_products_part_c_matching.sql
-- ============================================================================

-- Part C: capability coverage, request matching, provider notifications and
-- product enquiries. Apply after Part B and the Financial Services patches.

begin;

create table if not exists public.financial_capability_loan_product_coverage (
  capability_slug text not null references public.need_capabilities(slug) on delete cascade,
  category_slug text not null,
  purpose_slug text not null,
  primary key(capability_slug,category_slug,purpose_slug),
  foreign key(category_slug,purpose_slug)
    references public.loan_product_purposes(category_slug,slug) on delete cascade
);
alter table public.financial_capability_loan_product_coverage enable row level security;
revoke all on public.financial_capability_loan_product_coverage from public,anon,authenticated;
grant select on public.financial_capability_loan_product_coverage to authenticated;
drop policy if exists financial_loan_coverage_read on public.financial_capability_loan_product_coverage;
create policy financial_loan_coverage_read on public.financial_capability_loan_product_coverage
  for select to authenticated using(private.loan_products_feature_enabled());
grant insert,update,delete on public.financial_capability_loan_product_coverage to authenticated;
drop policy if exists financial_loan_coverage_admin_write on public.financial_capability_loan_product_coverage;
create policy financial_loan_coverage_admin_write on public.financial_capability_loan_product_coverage
  for all to authenticated using(private.is_admin()) with check(private.is_admin());

insert into public.financial_capability_loan_product_coverage values
 ('personal_loan_services','personal','general_personal_expenses'),
 ('personal_loan_services','personal','family_support'),
 ('personal_loan_services','personal','debt_consolidation'),
 ('personal_loan_services','personal','other_personal_needs'),
 ('emergency_loan_services','personal','general_personal_expenses'),
 ('emergency_loan_services','personal','medical_expenses'),
 ('salary_loan_services','personal','salary_advance'),
 ('medical_financing','personal','medical_expenses'),
 ('business_startup_financing','business','business_startup'),
 ('working_capital_financing','business','working_capital'),
 ('working_capital_financing','business','inventory_stock_purchase'),
 ('business_expansion_financing','business','business_expansion'),
 ('sme_financing','business','business_startup'),
 ('sme_financing','business','business_expansion'),
 ('sme_financing','business','working_capital'),
 ('sme_financing','business','inventory_stock_purchase'),
 ('sme_financing','business','equipment_for_business'),
 ('sme_financing','business','contract_financing'),
 ('sme_financing','business','invoice_financing'),
 ('sme_financing','business','other_business_needs'),
 ('boda_boda_financing','asset_financing','boda_boda'),
 ('car_financing','asset_financing','car'),
 ('tuk_tuk_financing','asset_financing','tuk_tuk'),
 ('motorcycle_financing','asset_financing','motorcycle'),
 ('smartphone_financing','asset_financing','smartphone'),
 ('laptop_financing','asset_financing','laptop'),
 ('heavy_machinery_financing','asset_financing','heavy_machinery'),
 ('equipment_financing','business','equipment_for_business'),
 ('equipment_financing','asset_financing','other_asset_financing'),
 ('agricultural_loan_services','agricultural','crop_production'),
 ('agricultural_loan_services','agricultural','greenhouse_farming'),
 ('agricultural_loan_services','agricultural','livestock'),
 ('agricultural_loan_services','agricultural','poultry_farming'),
 ('agricultural_loan_services','agricultural','farm_inputs'),
 ('agricultural_loan_services','agricultural','irrigation'),
 ('agricultural_loan_services','agricultural','tractor_financing'),
 ('agricultural_loan_services','agricultural','agricultural_equipment'),
 ('agricultural_loan_services','agricultural','other_agricultural_needs'),
 ('livestock_financing','agricultural','livestock'),
 ('livestock_financing','agricultural','poultry_farming'),
 ('crop_financing','agricultural','crop_production'),
 ('crop_financing','agricultural','farm_inputs'),
 ('crop_financing','agricultural','greenhouse_farming'),
 ('crop_financing','agricultural','irrigation'),
 ('farm_equipment_financing','agricultural','tractor_financing'),
 ('farm_equipment_financing','agricultural','agricultural_equipment'),
 ('farm_equipment_financing','asset_financing','agricultural_equipment'),
 ('mortgage_financing','property','mortgage_financing'),
 ('mortgage_financing','property','home_construction'),
 ('mortgage_financing','property','home_improvement'),
 ('land_financing','property','land_purchase'),
 ('property_development_financing','property','property_development'),
 ('property_development_financing','property','commercial_property'),
 ('school_fees_financing','education','school_fees'),
 ('university_financing','education','university_tuition'),
 ('education_loan_services','education','school_fees'),
 ('education_loan_services','education','university_tuition'),
 ('education_loan_services','education','vocational_training'),
 ('education_loan_services','education','professional_courses'),
 ('education_loan_services','education','study_abroad'),
 ('education_loan_services','education','educational_equipment'),
 ('education_loan_services','education','other_education_needs'),
 ('travel_financing','lifestyle','travel_holiday'),
 ('wedding_financing','lifestyle','wedding_expenses'),
 ('other_lifestyle_financing','lifestyle','events_celebrations'),
 ('other_lifestyle_financing','lifestyle','family_events'),
 ('other_lifestyle_financing','lifestyle','relocation_expenses'),
 ('other_lifestyle_financing','lifestyle','other_lifestyle_needs')
on conflict do nothing;

-- Only products whose linked capability covers their exact purpose are
-- publicly browseable. Individual products need no capability proof;
-- Company products still require approved proof.
create or replace view public.v_active_loan_products with(security_barrier=true) as
select lp.id,lp.identity_type,lp.category_slug,lc.name as category_name,
  lp.purpose_slug,pu.name as purpose_name,lp.product_title,lp.short_description,
  lp.minimum_amount,lp.maximum_amount,lp.currency_code,lp.terms,lp.is_featured,
  lp.published_at,lp.views_count,lp.enquiries_count,
  case when lp.identity_type='company' then cp.company_name
       else coalesce(ip.display_name,pr.full_name,'Individual provider') end as provider_name,
  case when lp.identity_type='company' then cp.logo_path else null end as provider_logo_url,
  pc.verification_level='provider_verified' as provider_verified
from public.loan_products lp
join public.loan_product_categories lc on lc.slug=lp.category_slug
join public.loan_product_purposes pu on pu.category_slug=lp.category_slug and pu.slug=lp.purpose_slug
join public.provider_capabilities pc on pc.id=lp.provider_capability_id
join public.provider_category_profiles pcp on pcp.user_id=lp.provider_id
  and pcp.category_slug='financial_services' and pcp.provider_type=lp.identity_type
left join public.provider_company_profiles cp on cp.user_id=lp.provider_id
  and cp.category_slug='financial_services'
left join public.provider_identity_presentations ip on ip.user_id=lp.provider_id
  and ip.category_slug='financial_services' and ip.identity_type='individual'
left join public.profiles pr on pr.id=lp.provider_id
where lp.status='active' and private.loan_products_feature_enabled(lp.provider_id)
  and pc.user_id=lp.provider_id and pc.identity_type=lp.identity_type and pc.is_active
  and exists(select 1 from public.financial_capability_loan_product_coverage cov
    where cov.capability_slug=pc.capability_slug and cov.category_slug=lp.category_slug
      and cov.purpose_slug=lp.purpose_slug)
  and (lp.identity_type='individual' or
    (pc.verification_level='provider_verified' and private.provider_capability_is_eligible(pc.id)));
grant select on public.v_active_loan_products to anon,authenticated;

create or replace function private.guard_loan_product_coverage()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
begin
  if new.status <> 'active' then return new; end if;
  if not exists (
    select 1 from public.provider_capabilities pc
    join public.financial_capability_loan_product_coverage cov
      on cov.capability_slug=pc.capability_slug
    where pc.id=new.provider_capability_id and pc.user_id=new.provider_id
      and pc.identity_type=new.identity_type
      and cov.category_slug=new.category_slug and cov.purpose_slug=new.purpose_slug
  ) then
    raise exception 'This Financial Services capability does not cover the selected loan purpose.'
      using errcode='P0216';
  end if;
  return new;
end;
$$;
revoke all on function private.guard_loan_product_coverage() from public,anon,authenticated;
drop trigger if exists trg_guard_loan_product_coverage on public.loan_products;
create trigger trg_guard_loan_product_coverage
  before insert or update of status,provider_capability_id,category_slug,purpose_slug
  on public.loan_products for each row execute function private.guard_loan_product_coverage();

alter table public.loan_requests
  add column if not exists loan_category text,
  add column if not exists loan_purpose text;
create index if not exists idx_loan_requests_product_pair
  on public.loan_requests(loan_category,loan_purpose,status);

create or replace function private.loan_product_term_number(p_terms jsonb,p_key text)
returns numeric language plpgsql immutable
set search_path=pg_catalog as $$
begin
  if coalesce(p_terms->>p_key,'') !~ '^-?[0-9]+([.][0-9]+)?$' then return null; end if;
  return (p_terms->>p_key)::numeric;
exception when others then return null;
end;
$$;
revoke all on function private.loan_product_term_number(jsonb,text) from public,anon,authenticated;

create or replace function private.guard_structured_loan_request_classification()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
begin
  if new.status::text='active' and private.loan_products_feature_enabled(new.borrower_id) then
    if new.loan_category is null or new.loan_purpose is null then
      raise exception 'Choose a loan category and purpose so providers can match suitable products.'
        using errcode='22023';
    end if;
    if not exists(select 1 from public.loan_product_purposes p
      join public.loan_product_categories c on c.slug=p.category_slug
      where p.category_slug=new.loan_category and p.slug=new.loan_purpose
        and p.is_active and c.is_active) then
      raise exception 'Choose an active loan purpose from the selected category.'
        using errcode='22023';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function private.guard_structured_loan_request_classification() from public,anon,authenticated;
drop trigger if exists trg_guard_structured_loan_request_classification on public.loan_requests;
create trigger trg_guard_structured_loan_request_classification
  before insert or update of status,loan_category,loan_purpose on public.loan_requests
  for each row execute function private.guard_structured_loan_request_classification();

create table if not exists public.loan_product_match_notifications (
  provider_id uuid not null references public.profiles(id) on delete cascade,
  request_id uuid not null references public.loan_requests(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(provider_id,request_id)
);
alter table public.loan_product_match_notifications enable row level security;
revoke all on public.loan_product_match_notifications from public,anon,authenticated;

create or replace function private.loan_product_matches_request(
  p_product public.loan_products,p_request public.loan_requests
) returns boolean language sql stable security definer
set search_path=public,private,pg_temp as $$
  select p_product.status='active' and p_request.status='active'
    and p_request.borrower_id<>p_product.provider_id
    and p_request.loan_category=p_product.category_slug
    and p_request.loan_purpose=p_product.purpose_slug
    and p_request.requested_amount between p_product.minimum_amount and p_product.maximum_amount
    and p_product.currency_code=(select c.currency_code from public.countries c where c.code=p_request.country)
    and coalesce(p_product.terms->>'repayment_frequency','') in
      (p_request.preferred_repayment_plan,'custom')
    and case coalesce(p_product.terms->>'period_unit','month')
      when 'day' then p_request.duration_months*30 between
        coalesce(private.loan_product_term_number(p_product.terms,'minimum_period'),0)
        and coalesce(private.loan_product_term_number(p_product.terms,'maximum_period'),2147483647)
      when 'week' then p_request.duration_months*4.35 between
        coalesce(private.loan_product_term_number(p_product.terms,'minimum_period'),0)
        and coalesce(private.loan_product_term_number(p_product.terms,'maximum_period'),2147483647)
      when 'year' then p_request.duration_months/12.0 between
        coalesce(private.loan_product_term_number(p_product.terms,'minimum_period'),0)
        and coalesce(private.loan_product_term_number(p_product.terms,'maximum_period'),2147483647)
      else p_request.duration_months between
        coalesce(private.loan_product_term_number(p_product.terms,'minimum_period'),0)
        and coalesce(private.loan_product_term_number(p_product.terms,'maximum_period'),2147483647)
    end
    and (coalesce(p_product.terms->>'secured','false')<>'true' or p_request.has_collateral)
    and (
      coalesce(private.loan_product_term_number(p_product.terms,'minimum_income'),0)=0
      or exists (
        select 1 from public.borrower_information bi
        where bi.user_id=p_request.borrower_id
          and bi.income_currency=p_product.currency_code
          and case bi.monthly_income_range
            when 'no_regular_income' then 0
            when 'under_500k' then 0
            when '500k_1m' then 500000
            when '1m_2m' then 1000000
            when '2m_3m' then 2000000
            when 'over_3m' then 3000000
          end >= private.loan_product_term_number(p_product.terms,'minimum_income')
      )
    )
    and (
      coalesce(nullif(btrim(p_product.terms->>'employment_requirement'),''),'any') in ('any','Any','all','All')
      or exists (
        select 1 from public.borrower_information bi
        where bi.user_id=p_request.borrower_id
          and (lower(p_product.terms->>'employment_requirement') like '%' ||
            replace(bi.employment_status,'_',' ') || '%'
            or lower(p_product.terms->>'employment_requirement') like '%' ||
              replace(bi.employment_status,'_','%') || '%')
      )
    )
    and (coalesce(jsonb_array_length(p_product.terms->'eligible_locations'),0)=0
      or (jsonb_typeof(p_product.terms->'eligible_locations')='array'
        and exists(select 1 from jsonb_array_elements_text(p_product.terms->'eligible_locations') loc
          where lower(loc) in (lower(p_request.district),lower(p_request.country)))))
    and not private.is_blocked_from_future_request(p_request.borrower_id,p_product.provider_id,p_request.listed_at)
    and not exists(select 1 from public.loan_offers lo
      where lo.request_id=p_request.id and lo.lender_id=p_product.provider_id
        and lo.status in ('pending','accepted'))
    and exists(select 1 from public.provider_capabilities pc
      join public.financial_capability_loan_product_coverage cov on cov.capability_slug=pc.capability_slug
      join public.provider_category_profiles pcp on pcp.user_id=pc.user_id
        and pcp.category_slug='financial_services' and pcp.provider_type=pc.identity_type
      where pc.id=p_product.provider_capability_id and pc.user_id=p_product.provider_id and pc.is_active
        and private.loan_products_feature_enabled(pc.user_id)
        and exists(select 1 from public.provider_category_profiles pcp
          where pcp.user_id=pc.user_id and pcp.category_slug='financial_services'
            and pcp.provider_type=pc.identity_type)
        and cov.category_slug=p_request.loan_category and cov.purpose_slug=p_request.loan_purpose
        and (pc.identity_type='individual' or
          (pc.verification_level='provider_verified' and private.provider_capability_is_eligible(pc.id))))
$$;
revoke all on function private.loan_product_matches_request(public.loan_products,public.loan_requests)
  from public,anon,authenticated;

create or replace function public.get_my_loan_product_matches(p_product_id uuid default null)
returns table(product_id uuid,product_title text,request_id uuid,request_title text,
  category_slug text,purpose_slug text,country text,currency_code text,district text,
  requested_amount bigint,preferred_repayment_plan text,duration_months integer,
  has_collateral boolean,listed_at timestamp)
language plpgsql security definer set search_path=public,private,pg_temp as $$
begin
  if auth.uid() is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(auth.uid()) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  return query select lp.id,lp.product_title,lr.id,lr.title,lr.loan_category,lr.loan_purpose,
    lr.country,c.currency_code,lr.district,lr.requested_amount,lr.preferred_repayment_plan,
    lr.duration_months,lr.has_collateral,lr.listed_at
  from public.loan_products lp
  join public.loan_requests lr on private.loan_product_matches_request(lp,lr)
  join public.countries c on c.code=lr.country
  where lp.provider_id=auth.uid() and lp.status='active'
    and (p_product_id is null or lp.id=p_product_id)
  order by lr.listed_at desc;
end;
$$;
revoke all on function public.get_my_loan_product_matches(uuid) from public,anon;
grant execute on function public.get_my_loan_product_matches(uuid) to authenticated;

create or replace function public.get_matching_products_for_request(p_request_id uuid)
returns table(product_id uuid,identity_type text,provider_name text,product_title text,
  category_name text,purpose_name text,minimum_amount bigint,maximum_amount bigint,
  currency_code text,terms jsonb,provider_verified boolean)
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_request public.loan_requests%rowtype;
begin
  if auth.uid() is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(auth.uid()) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  select * into v_request from public.loan_requests
    where id=p_request_id and borrower_id=auth.uid() and status='active';
  if not found then raise exception 'Active request not found.' using errcode='P0212'; end if;
  return query
  select lp.id,lp.identity_type,
    case when lp.identity_type='company' then cp.company_name
      else coalesce(ip.display_name,pr.full_name,'Individual provider') end,
    lp.product_title,lc.name,pu.name,lp.minimum_amount,lp.maximum_amount,
    lp.currency_code,lp.terms,pc.verification_level='provider_verified'
  from public.loan_products lp
  join public.loan_product_categories lc on lc.slug=lp.category_slug
  join public.loan_product_purposes pu on pu.category_slug=lp.category_slug and pu.slug=lp.purpose_slug
  join public.provider_capabilities pc on pc.id=lp.provider_capability_id
  join public.provider_category_profiles pcp on pcp.user_id=lp.provider_id
    and pcp.category_slug='financial_services' and pcp.provider_type=lp.identity_type
  left join public.provider_company_profiles cp on cp.user_id=lp.provider_id
    and cp.category_slug='financial_services'
  left join public.provider_identity_presentations ip on ip.user_id=lp.provider_id
    and ip.category_slug='financial_services' and ip.identity_type='individual'
  left join public.profiles pr on pr.id=lp.provider_id
  where private.loan_product_matches_request(lp,v_request)
  order by lp.is_featured desc,lp.published_at desc;
end;
$$;
revoke all on function public.get_matching_products_for_request(uuid) from public,anon;
grant execute on function public.get_matching_products_for_request(uuid) to authenticated;

create or replace function private.notify_matching_loan_products()
returns trigger language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_owner uuid;
begin
  if new.status<>'active' or new.loan_category is null or new.loan_purpose is null then return new; end if;
  for v_owner in select distinct lp.provider_id from public.loan_products lp
    where private.loan_product_matches_request(lp,new)
  loop
    insert into public.loan_product_match_notifications(provider_id,request_id)
      values(v_owner,new.id) on conflict do nothing;
    if found then
      insert into public.notifications(user_id,type,title,body,request_id,data)
      values(v_owner,'system','A loan request matches your product',
        'A new borrower request matches one of your active loan products.',new.id,
        jsonb_build_object('kind','loan_product_match','request_id',new.id));
    end if;
  end loop;
  return new;
end;
$$;
revoke all on function private.notify_matching_loan_products() from public,anon,authenticated;
drop trigger if exists trg_notify_matching_loan_products on public.loan_requests;
create trigger trg_notify_matching_loan_products
  after insert or update of status,loan_category,loan_purpose,requested_amount,
    preferred_repayment_plan,country,district,has_collateral
  on public.loan_requests for each row execute function private.notify_matching_loan_products();

create table if not exists public.loan_product_enquiries (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.loan_products(id) on delete cascade,
  borrower_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check(char_length(btrim(message)) between 5 and 2000),
  created_at timestamptz not null default now(),
  unique(product_id,borrower_id)
);
alter table public.loan_product_enquiries enable row level security;
revoke all on public.loan_product_enquiries from public,anon,authenticated;
drop policy if exists loan_product_enquiries_borrower_read on public.loan_product_enquiries;
create policy loan_product_enquiries_borrower_read on public.loan_product_enquiries
  for select to authenticated using(borrower_id=auth.uid());
drop policy if exists loan_product_enquiries_provider_read on public.loan_product_enquiries;
create policy loan_product_enquiries_provider_read on public.loan_product_enquiries
  for select to authenticated using(exists(
    select 1 from public.loan_products lp where lp.id=product_id and lp.provider_id=auth.uid()));

create or replace function public.enquire_loan_product(p_product_id uuid,p_message text)
returns uuid language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_user uuid:=auth.uid();v_owner uuid;v_id uuid;v_is_new boolean;
begin
  if v_user is null then raise exception 'Not authenticated.' using errcode='42501'; end if;
  if not private.loan_products_feature_enabled(v_user) then
    raise exception 'Provider loan products are disabled.' using errcode='P0216'; end if;
  if p_message is null or char_length(btrim(p_message)) not between 5 and 2000 then
    raise exception 'Enter an enquiry between 5 and 2000 characters.' using errcode='22023'; end if;
  select lp.provider_id into v_owner from public.loan_products lp
    where lp.id=p_product_id and lp.status='active'
      and exists(select 1 from public.v_active_loan_products v where v.id=lp.id)
    for update;
  if v_owner is null then raise exception 'Product is no longer available.' using errcode='P0212'; end if;
  if v_owner=v_user then raise exception 'You cannot enquire about your own product.' using errcode='22023'; end if;
  select not exists(select 1 from public.loan_product_enquiries e
    where e.product_id=p_product_id and e.borrower_id=v_user) into v_is_new;
  insert into public.loan_product_enquiries(product_id,borrower_id,message)
    values(p_product_id,v_user,btrim(p_message))
    on conflict(product_id,borrower_id) do update set message=excluded.message,created_at=now()
    returning id into v_id;
  if v_is_new then
    update public.loan_products set enquiries_count=enquiries_count+1,updated_at=now()
      where id=p_product_id;
  end if;
  insert into public.notifications(user_id,type,title,body,data)
    values(v_owner,'system','New loan product enquiry',
      'Someone sent an enquiry about one of your loan products.',
      jsonb_build_object('kind','loan_product_enquiry','product_id',p_product_id,'enquiry_id',v_id));
  return v_id;
end;
$$;
revoke all on function public.enquire_loan_product(uuid,text) from public,anon;
grant execute on function public.enquire_loan_product(uuid,text) to authenticated;

create or replace view public.v_my_loan_product_enquiries with(security_barrier=true) as
select e.id,e.product_id,lp.product_title,e.message,e.created_at
from public.loan_product_enquiries e join public.loan_products lp on lp.id=e.product_id
where lp.provider_id=auth.uid();
grant select on public.v_my_loan_product_enquiries to authenticated;

commit;
notify pgrst,'reload schema';

-- ============================================================================
-- END MERGED SECTION (36/52): patch_loan_products_part_c_matching.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (37/52): patch_loan_request_purpose_picker_catalog.sql
-- ============================================================================

-- Add the single-purpose-picker display labels and legacy property purposes.
-- Apply after patch_loan_products_part_c_matching.sql.

begin;

alter table public.loan_product_categories
  add column if not exists request_picker_name text;

-- The borrower app reads these public lookup tables with the Supabase anon
-- key. Explicit read policies are needed when the project has RLS enabled.
alter table public.loan_product_categories enable row level security;
alter table public.loan_product_purposes enable row level security;

grant select on public.loan_product_categories, public.loan_product_purposes
  to anon, authenticated;

drop policy if exists loan_product_categories_picker_read
  on public.loan_product_categories;
create policy loan_product_categories_picker_read
  on public.loan_product_categories
  for select to anon, authenticated
  using (true);

drop policy if exists loan_product_purposes_picker_read
  on public.loan_product_purposes;
create policy loan_product_purposes_picker_read
  on public.loan_product_purposes
  for select to anon, authenticated
  using (true);

update public.loan_product_categories
set request_picker_name = case slug
  when 'personal' then 'Personal Loans'
  when 'business' then 'Business Loans'
  when 'asset_financing' then 'Asset Financing'
  when 'agricultural' then 'Agricultural Loans'
  when 'property' then 'Property Loans'
  when 'education' then 'Education Loans'
  when 'lifestyle' then 'Lifestyle Loans'
  else name
end
where request_picker_name is null;

insert into public.loan_product_purposes(category_slug,slug,name,sort_order,is_active)
values
  ('property','solar_energy','Solar / Energy',80,true),
  ('property','water_sanitation','Water & Sanitation',90,true)
on conflict(category_slug,slug) do update
set name=excluded.name,sort_order=excluded.sort_order,is_active=true;

insert into public.financial_capability_loan_product_coverage(
  capability_slug,category_slug,purpose_slug
) values
  ('mortgage_financing','property','solar_energy'),
  ('mortgage_financing','property','water_sanitation')
on conflict do nothing;

commit;
notify pgrst,'reload schema';

-- ============================================================================
-- END MERGED SECTION (37/52): patch_loan_request_purpose_picker_catalog.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (38/52): patch_provider_catalog_one_word_hierarchy.sql
-- ============================================================================

-- Align the Supabase catalog to provider_catalog_one_word_categories.md.
-- Apply after the v2 catalog, work-profile, catalog expansion, provider type,
-- company path, identity switch, financial-service, and verification patches.
-- Existing service slugs are retained. Business & Investment is folded into Finance.
begin;

alter table public.need_capabilities add column if not exists verification_policy text not null default 'open';
alter table public.need_capabilities drop constraint if exists need_capabilities_verification_policy_check;
alter table public.need_capabilities add constraint need_capabilities_verification_policy_check check (verification_policy in ('open', 'optional_proof', 'required_proof'));

update public.need_categories as c set name = v.name, sort_order = v.sort_order, is_active = true from (values
  ('technology_digital', 'Technology', 1),
  ('marketing_promotion', 'Marketing', 2),
  ('professional_services', 'Business', 3),
  ('education_training', 'Education', 4),
  ('events_production', 'Events', 5),
  ('photo_video_music_talent', 'Media', 6),
  ('beauty_fashion_styling', 'Beauty', 7),
  ('construction_building', 'Construction', 8),
  ('energy_utilities', 'Energy', 9),
  ('transport_logistics', 'Transport', 10),
  ('machinery_equipment', 'Machinery', 11),
  ('agriculture_agribusiness', 'Agriculture', 12),
  ('specialized_products', 'Sourcing', 13),
  ('travel_international', 'Travel', 14),
  ('domestic_household', 'Domestic', 15),
  ('health_medical', 'Health', 16),
  ('traditional_cultural', 'Cultural', 17),
  ('financial_services', 'Finance', 18)
) as v(slug, name, sort_order) where c.slug = v.slug;

-- Retain the old slug for existing references, but remove its duplicate picker entry.
update public.need_categories set is_active = false where slug = 'business_investment';

-- Preserve legacy identity and company details when merging the category into Finance.
insert into public.provider_category_profiles (user_id, category_slug, provider_type)
select old_profile.user_id, 'financial_services', old_profile.provider_type
from public.provider_category_profiles as old_profile
where old_profile.category_slug = 'business_investment'
  and not exists (
    select 1 from public.provider_category_profiles as finance_profile
    where finance_profile.user_id = old_profile.user_id
      and finance_profile.category_slug = 'financial_services'
  );
delete from public.provider_category_profiles where category_slug = 'business_investment';

update public.provider_company_profiles as finance_profile
set company_name = coalesce(finance_profile.company_name, old_profile.company_name),
    registration_number = coalesce(finance_profile.registration_number, old_profile.registration_number),
    team_size = coalesce(finance_profile.team_size, old_profile.team_size),
    years_in_business = coalesce(finance_profile.years_in_business, old_profile.years_in_business),
    service_areas = case when cardinality(finance_profile.service_areas) = 0
      then old_profile.service_areas else finance_profile.service_areas end,
    updated_at = greatest(finance_profile.updated_at, old_profile.updated_at)
from public.provider_company_profiles as old_profile
where finance_profile.user_id = old_profile.user_id
  and finance_profile.category_slug = 'financial_services'
  and old_profile.category_slug = 'business_investment';

insert into public.provider_company_profiles (
  user_id, category_slug, company_name, registration_number, team_size,
  years_in_business, service_areas, created_at, updated_at
)
select old_profile.user_id, 'financial_services', old_profile.company_name,
       old_profile.registration_number, old_profile.team_size,
       old_profile.years_in_business, old_profile.service_areas,
       old_profile.created_at, old_profile.updated_at
from public.provider_company_profiles as old_profile
where old_profile.category_slug = 'business_investment'
  and not exists (
    select 1 from public.provider_company_profiles as finance_profile
    where finance_profile.user_id = old_profile.user_id
      and finance_profile.category_slug = 'financial_services'
  );
delete from public.provider_company_profiles where category_slug = 'business_investment';

insert into public.provider_identity_presentations (
  user_id, category_slug, identity_type, display_mode, display_name,
  representative_name, representative_authorized, created_at, updated_at
)
select old_presentation.user_id, 'financial_services', old_presentation.identity_type,
       old_presentation.display_mode, old_presentation.display_name,
       old_presentation.representative_name, old_presentation.representative_authorized,
       old_presentation.created_at, old_presentation.updated_at
from public.provider_identity_presentations as old_presentation
where old_presentation.category_slug = 'business_investment'
  and not exists (
    select 1 from public.provider_identity_presentations as finance_presentation
    where finance_presentation.user_id = old_presentation.user_id
      and finance_presentation.category_slug = 'financial_services'
      and finance_presentation.identity_type = old_presentation.identity_type
  );
delete from public.provider_identity_presentations where category_slug = 'business_investment';

insert into public.provider_company_verification_submissions (
  user_id, category_slug, document_type, file_path, status, reject_reason,
  reviewed_by, reviewed_at, created_at, updated_at
)
select old_submission.user_id, 'financial_services', old_submission.document_type,
       old_submission.file_path, old_submission.status, old_submission.reject_reason,
       old_submission.reviewed_by, old_submission.reviewed_at,
       old_submission.created_at, old_submission.updated_at
from public.provider_company_verification_submissions as old_submission
where old_submission.category_slug = 'business_investment'
  and not exists (
    select 1 from public.provider_company_verification_submissions as finance_submission
    where finance_submission.user_id = old_submission.user_id
      and finance_submission.category_slug = 'financial_services'
      and finance_submission.document_type = old_submission.document_type
  );
delete from public.provider_company_verification_submissions where category_slug = 'business_investment';

-- The guide has no Other services. Deactivate only service rows that are not in its active list.
update public.need_capabilities set is_active = false where capability_type = 'service' and category_slug in ('technology_digital', 'marketing_promotion', 'professional_services', 'education_training', 'events_production', 'photo_video_music_talent', 'beauty_fashion_styling', 'construction_building', 'energy_utilities', 'transport_logistics', 'machinery_equipment', 'agriculture_agribusiness', 'specialized_products', 'travel_international', 'domestic_household', 'health_medical', 'traditional_cultural', 'financial_services', 'business_investment') and slug not in (
  'software_development', 'website_development', 'mobile_app_development', 'automation_services', 'it_support', 'networking_services', 'cybersecurity_services', 'digital_marketing',
  'social_media_marketing', 'advertising_campaigns', 'brand_promotion', 'event_promotion', 'affiliate_marketing', 'content_creation', 'influencer_marketing', 'product_reviews',
  'i_have_an_audience', 'accounting_tax', 'legal_services', 'company_registration', 'business_consulting', 'hr_services', 'private_tutoring', 'online_classes',
  'exam_preparation', 'language_training', 'computer_training', 'professional_training', 'vocational_training', 'academic_consulting', 'university_admissions', 'study_abroad_guidance',
  'internship_placement', 'health_nursing_placements', 'final_year_project_support', 'research_dissertation_guidance', 'data_analysis_help', 'proofreading_editing', 'coursework_tutoring', 'event_planning',
  'event_decoration', 'celebration_cakes', 'celebration_catering', 'tent_hire', 'event_equipment', 'sound_systems', 'lighting_hire', 'celebration_mc_dj',
  'event_transport', 'photography_services', 'videography_services', 'video_editors', 'recording_studios', 'music_producers', 'mixing_mastering', 'songwriters',
  'singers_vocalists', 'actors_actresses', 'dancers', 'background_extras', 'music_video_models', 'art_illustration', 'graphic_design', 'celebration_makeup',
  'hair_styling', 'salon_barber_services', 'nails_skincare_services', 'bridal_styling', 'music_video_stylists', 'dresses_bridesmaid_outfits', 'massage_therapy', 'spa_services',
  'sauna_steam_services', 'building_contractors', 'roofing_services', 'excavation_works', 'concrete_works', 'plumbing_services', 'electrical_works', 'construction_materials',
  'surveying_services', 'architecture_services', 'engineering_consulting', 'solar_systems', 'battery_supply', 'backup_power', 'generator_supply', 'electrical_installation',
  'borehole_drilling', 'water_systems', 'energy_consulting', 'cargo_transport', 'bulk_delivery', 'heavy_haulage', 'agricultural_transport', 'cold_chain_transport',
  'courier_delivery', 'moving_services', 'truck_hire', 'vehicle_transport', 'chauffeur_services', 'personal_driver_hire', 'boda_taxi_services', 'driving_school_driver_training',
  'excavator_hire', 'loader_hire', 'grader_hire', 'crane_hire', 'generator_hire', 'tractor_hire', 'industrial_equipment', 'farm_services',
  'irrigation_services', 'seeds_inputs', 'livestock_sourcing', 'produce_buyers', 'bulk_procurement', 'equipment_sourcing', 'imported_products', 'hard_to_find_products',
  'electronics_procurement', 'industrial_parts', 'spare_parts', 'medical_lab_supplies', 'flight_tickets', 'accommodation', 'airport_transfers', 'tour_packages',
  'visa_assistance', 'travel_documentation', 'travel_insurance', 'hajj_umrah', 'international_relocation', 'travel_consultation', 'house_help_services', 'housekeeping_services',
  'laundry_services', 'gardening_services', 'childcare_nanny_services', 'home_cooking_services', 'elderly_home_care', 'clinic_services', 'hospital_services', 'eye_clinic_optical',
  'dental_clinic', 'diagnostic_lab', 'pharmacy_services', 'physiotherapy_clinic', 'orthopaedic_care', 'home_nursing_agency', 'medical_staffing_agency', 'mobile_health_outreach',
  'maternity_care_services', 'family_planning_services', 'hiv_testing_services', 'circumcision_services', 'duwah_services', 'traditional_ceremony_services', 'traditional_dance_drumming', 'traditional_attire_crafts',
  'traditional_healing_herbal', 'personal_loan_services', 'emergency_loan_services', 'salary_loan_services', 'medical_financing', 'business_startup_financing', 'working_capital_financing', 'business_expansion_financing',
  'sme_financing', 'boda_boda_financing', 'car_financing', 'tuk_tuk_financing', 'motorcycle_financing', 'smartphone_financing', 'laptop_financing', 'heavy_machinery_financing',
  'equipment_financing', 'agricultural_loan_services', 'livestock_financing', 'crop_financing', 'farm_equipment_financing', 'mortgage_financing', 'land_financing', 'property_development_financing',
  'school_fees_financing', 'university_financing', 'education_loan_services', 'travel_financing', 'wedding_financing', 'forex_currency_exchange', 'forex_trading_training', 'forex_trading_brokerage', 'money_transfer',
  'investment_stocks_shares', 'investment_bonds_treasury_bills', 'investment_precious_metals', 'investment_brokerage', 'investment_advisory',
  'sacco_services', 'vsla_groups', 'cooperative_societies', 'group_savings_chamas', 'angel_investor_network', 'startup_advisory', 'investor_introductions', 'incubator_accelerator'
);

-- Put all documented services under the category and subcategory in the guide.
update public.need_capabilities as nc set category_slug = v.category_slug, ui_group_slug = v.category_slug, service_group_slug = v.group_slug, service_group_name = v.group_name, sort_order = v.sort_order, service_sort_order = v.service_sort_order, name = v.name, is_active = true from (values
  ('software_development', 'technology_digital', 'development', 'Development', 1101, 1, 'Software Development', 'open'),
  ('website_development', 'technology_digital', 'development', 'Development', 1102, 2, 'Website Development', 'open'),
  ('mobile_app_development', 'technology_digital', 'development', 'Development', 1103, 3, 'Mobile App Development', 'open'),
  ('automation_services', 'technology_digital', 'development', 'Development', 1104, 4, 'Automation', 'open'),
  ('it_support', 'technology_digital', 'support_networks', 'Support & Networks', 1201, 1, 'IT Support', 'open'),
  ('networking_services', 'technology_digital', 'support_networks', 'Support & Networks', 1202, 2, 'Networking', 'open'),
  ('cybersecurity_services', 'technology_digital', 'security', 'Security', 1301, 1, 'Cybersecurity', 'open'),
  ('digital_marketing', 'marketing_promotion', 'campaigns', 'Campaigns', 2101, 1, 'Digital Marketing', 'open'),
  ('social_media_marketing', 'marketing_promotion', 'campaigns', 'Campaigns', 2102, 2, 'Social Media Marketing', 'open'),
  ('advertising_campaigns', 'marketing_promotion', 'campaigns', 'Campaigns', 2103, 3, 'Advertising Campaigns', 'open'),
  ('brand_promotion', 'marketing_promotion', 'campaigns', 'Campaigns', 2104, 4, 'Brand Promotion', 'open'),
  ('event_promotion', 'marketing_promotion', 'campaigns', 'Campaigns', 2105, 5, 'Event Promotion', 'open'),
  ('affiliate_marketing', 'marketing_promotion', 'campaigns', 'Campaigns', 2106, 6, 'Affiliate Marketing', 'open'),
  ('content_creation', 'marketing_promotion', 'content_reach', 'Content & Reach', 2201, 1, 'Content Creation', 'open'),
  ('influencer_marketing', 'marketing_promotion', 'content_reach', 'Content & Reach', 2202, 2, 'Influencer Marketing', 'open'),
  ('product_reviews', 'marketing_promotion', 'content_reach', 'Content & Reach', 2203, 3, 'Product Reviews', 'open'),
  ('i_have_an_audience', 'marketing_promotion', 'content_reach', 'Content & Reach', 2204, 4, 'I Have an Audience', 'open'),
  ('accounting_tax', 'professional_services', 'accounting_legal', 'Accounting & Legal', 3101, 1, 'Accounting & Tax', 'open'),
  ('legal_services', 'professional_services', 'accounting_legal', 'Accounting & Legal', 3102, 2, 'Legal Services', 'open'),
  ('company_registration', 'professional_services', 'accounting_legal', 'Accounting & Legal', 3103, 3, 'Company Registration', 'open'),
  ('business_consulting', 'professional_services', 'advisory', 'Advisory', 3201, 1, 'Business Consulting', 'open'),
  ('hr_services', 'professional_services', 'advisory', 'Advisory', 3202, 2, 'HR Services', 'open'),
  ('private_tutoring', 'education_training', 'learning', 'Learning', 4101, 1, 'Private Tutoring', 'open'),
  ('online_classes', 'education_training', 'learning', 'Learning', 4102, 2, 'Online Classes', 'open'),
  ('exam_preparation', 'education_training', 'learning', 'Learning', 4103, 3, 'Exam Preparation', 'open'),
  ('language_training', 'education_training', 'learning', 'Learning', 4104, 4, 'Language Training', 'open'),
  ('computer_training', 'education_training', 'learning', 'Learning', 4105, 5, 'Computer Training', 'open'),
  ('professional_training', 'education_training', 'learning', 'Learning', 4106, 6, 'Professional Training', 'open'),
  ('vocational_training', 'education_training', 'learning', 'Learning', 4107, 7, 'Vocational Training', 'open'),
  ('academic_consulting', 'education_training', 'learning', 'Learning', 4108, 8, 'Academic Consulting', 'open'),
  ('university_admissions', 'education_training', 'admissions_placements', 'Admissions & Placements', 4201, 1, 'University Admissions', 'open'),
  ('study_abroad_guidance', 'education_training', 'admissions_placements', 'Admissions & Placements', 4202, 2, 'Study Abroad Guidance', 'open'),
  ('internship_placement', 'education_training', 'admissions_placements', 'Admissions & Placements', 4203, 3, 'Internship Placement', 'open'),
  ('health_nursing_placements', 'education_training', 'admissions_placements', 'Admissions & Placements', 4204, 4, 'Health / Nursing Placements', 'open'),
  ('final_year_project_support', 'education_training', 'coursework_projects', 'Coursework & Projects', 4301, 1, 'Final Year Project Support', 'optional_proof'),
  ('research_dissertation_guidance', 'education_training', 'coursework_projects', 'Coursework & Projects', 4302, 2, 'Research Proposal & Dissertation Guidance', 'optional_proof'),
  ('data_analysis_help', 'education_training', 'coursework_projects', 'Coursework & Projects', 4303, 3, 'Data Analysis & Statistics Help', 'open'),
  ('proofreading_editing', 'education_training', 'coursework_projects', 'Coursework & Projects', 4304, 4, 'Proofreading & Editing', 'open'),
  ('coursework_tutoring', 'education_training', 'coursework_projects', 'Coursework & Projects', 4305, 5, 'Coursework Tutoring', 'open'),
  ('event_planning', 'events_production', 'planning_styling', 'Planning & Styling', 5101, 1, 'Event Planning', 'open'),
  ('event_decoration', 'events_production', 'planning_styling', 'Planning & Styling', 5102, 2, 'Decoration', 'open'),
  ('celebration_cakes', 'events_production', 'planning_styling', 'Planning & Styling', 5103, 3, 'Cakes', 'open'),
  ('celebration_catering', 'events_production', 'planning_styling', 'Planning & Styling', 5104, 4, 'Catering', 'open'),
  ('tent_hire', 'events_production', 'equipment_venue', 'Equipment & Venue', 5201, 1, 'Tents', 'open'),
  ('event_equipment', 'events_production', 'equipment_venue', 'Equipment & Venue', 5202, 2, 'Event Equipment', 'open'),
  ('sound_systems', 'events_production', 'equipment_venue', 'Equipment & Venue', 5203, 3, 'Sound Systems', 'open'),
  ('lighting_hire', 'events_production', 'equipment_venue', 'Equipment & Venue', 5204, 4, 'Lighting', 'open'),
  ('celebration_mc_dj', 'events_production', 'entertainment_transport', 'Entertainment & Transport', 5301, 1, 'DJs / MCs', 'open'),
  ('event_transport', 'events_production', 'entertainment_transport', 'Entertainment & Transport', 5302, 2, 'Event Transport', 'open'),
  ('photography_services', 'photo_video_music_talent', 'photo_video', 'Photo & Video', 6101, 1, 'Photography', 'open'),
  ('videography_services', 'photo_video_music_talent', 'photo_video', 'Photo & Video', 6102, 2, 'Videography', 'open'),
  ('video_editors', 'photo_video_music_talent', 'photo_video', 'Photo & Video', 6103, 3, 'Video Editors', 'open'),
  ('recording_studios', 'photo_video_music_talent', 'music', 'Music', 6201, 1, 'Recording Studios', 'open'),
  ('music_producers', 'photo_video_music_talent', 'music', 'Music', 6202, 2, 'Music Producers', 'open'),
  ('mixing_mastering', 'photo_video_music_talent', 'music', 'Music', 6203, 3, 'Mixing & Mastering', 'open'),
  ('songwriters', 'photo_video_music_talent', 'music', 'Music', 6204, 4, 'Songwriters', 'open'),
  ('singers_vocalists', 'photo_video_music_talent', 'music', 'Music', 6205, 5, 'Singers / Vocalists', 'open'),
  ('actors_actresses', 'photo_video_music_talent', 'performers', 'Performers', 6301, 1, 'Actors / Actresses', 'open'),
  ('dancers', 'photo_video_music_talent', 'performers', 'Performers', 6302, 2, 'Dancers', 'open'),
  ('background_extras', 'photo_video_music_talent', 'performers', 'Performers', 6303, 3, 'Background Extras', 'open'),
  ('music_video_models', 'photo_video_music_talent', 'performers', 'Performers', 6304, 4, 'Music Video Models', 'open'),
  ('art_illustration', 'photo_video_music_talent', 'art_design', 'Art & Design', 6401, 1, 'Art & Illustration', 'open'),
  ('graphic_design', 'photo_video_music_talent', 'art_design', 'Art & Design', 6402, 2, 'Graphic Design', 'open'),
  ('celebration_makeup', 'beauty_fashion_styling', 'beauty', 'Beauty', 7101, 1, 'Makeup Artists', 'open'),
  ('hair_styling', 'beauty_fashion_styling', 'beauty', 'Beauty', 7102, 2, 'Hair Stylists', 'open'),
  ('salon_barber_services', 'beauty_fashion_styling', 'beauty', 'Beauty', 7103, 3, 'Salons & Barber Shops', 'optional_proof'),
  ('nails_skincare_services', 'beauty_fashion_styling', 'beauty', 'Beauty', 7104, 4, 'Nails & Skincare', 'optional_proof'),
  ('bridal_styling', 'beauty_fashion_styling', 'fashion', 'Fashion', 7201, 1, 'Bridal Styling', 'open'),
  ('music_video_stylists', 'beauty_fashion_styling', 'fashion', 'Fashion', 7202, 2, 'Stylists', 'open'),
  ('dresses_bridesmaid_outfits', 'beauty_fashion_styling', 'fashion', 'Fashion', 7203, 3, 'Wedding Dresses / Bridesmaid Outfits', 'open'),
  ('massage_therapy', 'beauty_fashion_styling', 'wellness_spa', 'Wellness & Spa', 7301, 1, 'Massage Therapy', 'optional_proof'),
  ('spa_services', 'beauty_fashion_styling', 'wellness_spa', 'Wellness & Spa', 7302, 2, 'Spa Services', 'optional_proof'),
  ('sauna_steam_services', 'beauty_fashion_styling', 'wellness_spa', 'Wellness & Spa', 7303, 3, 'Sauna & Steam', 'optional_proof'),
  ('building_contractors', 'construction_building', 'contracting', 'Contracting', 8101, 1, 'Building Contractors', 'open'),
  ('roofing_services', 'construction_building', 'contracting', 'Contracting', 8102, 2, 'Roofing', 'open'),
  ('excavation_works', 'construction_building', 'contracting', 'Contracting', 8103, 3, 'Excavation', 'open'),
  ('concrete_works', 'construction_building', 'contracting', 'Contracting', 8104, 4, 'Concrete', 'open'),
  ('plumbing_services', 'construction_building', 'trades', 'Trades', 8201, 1, 'Plumbing', 'open'),
  ('electrical_works', 'construction_building', 'trades', 'Trades', 8202, 2, 'Electrical Works', 'open'),
  ('construction_materials', 'construction_building', 'materials_survey', 'Materials & Survey', 8301, 1, 'Construction Materials', 'open'),
  ('surveying_services', 'construction_building', 'materials_survey', 'Materials & Survey', 8302, 2, 'Surveying', 'open'),
  ('architecture_services', 'construction_building', 'design_engineering', 'Design & Engineering', 8401, 1, 'Architecture', 'open'),
  ('engineering_consulting', 'construction_building', 'design_engineering', 'Design & Engineering', 8402, 2, 'Engineering', 'open'),
  ('solar_systems', 'energy_utilities', 'power', 'Power', 9101, 1, 'Solar Systems', 'open'),
  ('battery_supply', 'energy_utilities', 'power', 'Power', 9102, 2, 'Batteries', 'open'),
  ('backup_power', 'energy_utilities', 'power', 'Power', 9103, 3, 'Backup Power', 'open'),
  ('generator_supply', 'energy_utilities', 'power', 'Power', 9104, 4, 'Generators', 'open'),
  ('electrical_installation', 'energy_utilities', 'power', 'Power', 9105, 5, 'Electrical Installation', 'open'),
  ('borehole_drilling', 'energy_utilities', 'water', 'Water', 9201, 1, 'Boreholes', 'open'),
  ('water_systems', 'energy_utilities', 'water', 'Water', 9202, 2, 'Water Systems', 'open'),
  ('energy_consulting', 'energy_utilities', 'advisory', 'Advisory', 9301, 1, 'Energy Consulting', 'open'),
  ('cargo_transport', 'transport_logistics', 'freight', 'Freight', 10101, 1, 'Cargo Transport', 'open'),
  ('bulk_delivery', 'transport_logistics', 'freight', 'Freight', 10102, 2, 'Bulk Delivery', 'open'),
  ('heavy_haulage', 'transport_logistics', 'freight', 'Freight', 10103, 3, 'Heavy Haulage', 'open'),
  ('agricultural_transport', 'transport_logistics', 'freight', 'Freight', 10104, 4, 'Agricultural Transport', 'open'),
  ('cold_chain_transport', 'transport_logistics', 'freight', 'Freight', 10105, 5, 'Cold Chain & Refrigerated', 'open'),
  ('courier_delivery', 'transport_logistics', 'delivery_moving', 'Delivery & Moving', 10201, 1, 'Courier', 'open'),
  ('moving_services', 'transport_logistics', 'delivery_moving', 'Delivery & Moving', 10202, 2, 'Moving Services', 'open'),
  ('truck_hire', 'transport_logistics', 'vehicles', 'Vehicles', 10301, 1, 'Truck Hire', 'open'),
  ('vehicle_transport', 'transport_logistics', 'vehicles', 'Vehicles', 10302, 2, 'Vehicle Transport', 'open'),
  ('chauffeur_services', 'transport_logistics', 'passenger', 'Passenger', 10401, 1, 'Chauffeur Services', 'optional_proof'),
  ('personal_driver_hire', 'transport_logistics', 'passenger', 'Passenger', 10402, 2, 'Personal Driver Hire', 'optional_proof'),
  ('boda_taxi_services', 'transport_logistics', 'passenger', 'Passenger', 10403, 3, 'Boda Boda / Motorcycle Taxi', 'optional_proof'),
  ('driving_school_driver_training', 'transport_logistics', 'training', 'Training', 10501, 1, 'Driving School / Driver Training', 'required_proof'),
  ('excavator_hire', 'machinery_equipment', 'earthmoving', 'Earthmoving', 11101, 1, 'Excavator Hire', 'open'),
  ('loader_hire', 'machinery_equipment', 'earthmoving', 'Earthmoving', 11102, 2, 'Loader Hire', 'open'),
  ('grader_hire', 'machinery_equipment', 'earthmoving', 'Earthmoving', 11103, 3, 'Grader Hire', 'open'),
  ('crane_hire', 'machinery_equipment', 'lifting_power', 'Lifting & Power', 11201, 1, 'Crane Hire', 'open'),
  ('generator_hire', 'machinery_equipment', 'lifting_power', 'Lifting & Power', 11202, 2, 'Generator Hire', 'open'),
  ('tractor_hire', 'machinery_equipment', 'farm_industrial', 'Farm & Industrial', 11301, 1, 'Tractor Hire', 'open'),
  ('industrial_equipment', 'machinery_equipment', 'farm_industrial', 'Farm & Industrial', 11302, 2, 'Industrial Equipment', 'open'),
  ('farm_services', 'agriculture_agribusiness', 'farm_operations', 'Farm Operations', 12101, 1, 'Farm Services', 'open'),
  ('irrigation_services', 'agriculture_agribusiness', 'farm_operations', 'Farm Operations', 12102, 2, 'Irrigation', 'open'),
  ('seeds_inputs', 'agriculture_agribusiness', 'inputs_livestock', 'Inputs & Livestock', 12201, 1, 'Seeds & Inputs', 'open'),
  ('livestock_sourcing', 'agriculture_agribusiness', 'inputs_livestock', 'Inputs & Livestock', 12202, 2, 'Livestock Sourcing', 'open'),
  ('produce_buyers', 'agriculture_agribusiness', 'market', 'Market', 12301, 1, 'Produce Buyers', 'open'),
  ('bulk_procurement', 'specialized_products', 'sourcing', 'Sourcing', 13101, 1, 'Bulk Procurement', 'open'),
  ('equipment_sourcing', 'specialized_products', 'sourcing', 'Sourcing', 13102, 2, 'Equipment Sourcing', 'open'),
  ('imported_products', 'specialized_products', 'sourcing', 'Sourcing', 13103, 3, 'Imported Products', 'open'),
  ('hard_to_find_products', 'specialized_products', 'sourcing', 'Sourcing', 13104, 4, 'Hard-to-Find Products', 'open'),
  ('electronics_procurement', 'specialized_products', 'parts_supplies', 'Parts & Supplies', 13201, 1, 'Electronics Procurement', 'open'),
  ('industrial_parts', 'specialized_products', 'parts_supplies', 'Parts & Supplies', 13202, 2, 'Industrial Parts', 'open'),
  ('spare_parts', 'specialized_products', 'parts_supplies', 'Parts & Supplies', 13203, 3, 'Spare Parts', 'open'),
  ('medical_lab_supplies', 'specialized_products', 'parts_supplies', 'Parts & Supplies', 13204, 4, 'Medical & Lab Supplies', 'open'),
  ('flight_tickets', 'travel_international', 'bookings', 'Bookings', 14101, 1, 'Flight Tickets & Bookings', 'open'),
  ('accommodation', 'travel_international', 'bookings', 'Bookings', 14102, 2, 'Accommodation', 'open'),
  ('airport_transfers', 'travel_international', 'bookings', 'Bookings', 14103, 3, 'Airport Transfers', 'open'),
  ('tour_packages', 'travel_international', 'bookings', 'Bookings', 14104, 4, 'Tour Packages', 'open'),
  ('visa_assistance', 'travel_international', 'documents_cover', 'Documents & Cover', 14201, 1, 'Visa Assistance', 'open'),
  ('travel_documentation', 'travel_international', 'documents_cover', 'Documents & Cover', 14202, 2, 'Travel Documentation', 'open'),
  ('travel_insurance', 'travel_international', 'documents_cover', 'Documents & Cover', 14203, 3, 'Travel Insurance', 'open'),
  ('hajj_umrah', 'travel_international', 'specialised', 'Specialised', 14301, 1, 'Hajj & Umrah', 'open'),
  ('international_relocation', 'travel_international', 'specialised', 'Specialised', 14302, 2, 'International Relocation', 'open'),
  ('travel_consultation', 'travel_international', 'specialised', 'Specialised', 14303, 3, 'Travel Consultation', 'open'),
  ('house_help_services', 'domestic_household', 'home_help', 'Home Help', 15101, 1, 'Maids & House Help', 'optional_proof'),
  ('housekeeping_services', 'domestic_household', 'home_help', 'Home Help', 15102, 2, 'Housekeeping & Cleaning', 'optional_proof'),
  ('laundry_services', 'domestic_household', 'home_help', 'Home Help', 15103, 3, 'Laundry & Ironing', 'open'),
  ('gardening_services', 'domestic_household', 'home_help', 'Home Help', 15104, 4, 'Gardening & Compound Care', 'open'),
  ('childcare_nanny_services', 'domestic_household', 'family', 'Family', 15201, 1, 'Nannies & Childcare', 'optional_proof'),
  ('home_cooking_services', 'domestic_household', 'family', 'Family', 15202, 2, 'Home Cooks', 'optional_proof'),
  ('elderly_home_care', 'domestic_household', 'family', 'Family', 15203, 3, 'Elderly Home Care', 'optional_proof'),
  ('clinic_services', 'health_medical', 'facilities', 'Facilities', 16101, 1, 'Clinics & Health Centres', 'required_proof'),
  ('hospital_services', 'health_medical', 'facilities', 'Facilities', 16102, 2, 'Hospitals', 'required_proof'),
  ('eye_clinic_optical', 'health_medical', 'facilities', 'Facilities', 16103, 3, 'Eye Clinics & Opticals', 'required_proof'),
  ('dental_clinic', 'health_medical', 'facilities', 'Facilities', 16104, 4, 'Dental Clinics', 'required_proof'),
  ('diagnostic_lab', 'health_medical', 'facilities', 'Facilities', 16105, 5, 'Diagnostic Labs & Imaging', 'required_proof'),
  ('pharmacy_services', 'health_medical', 'facilities', 'Facilities', 16106, 6, 'Pharmacies', 'required_proof'),
  ('physiotherapy_clinic', 'health_medical', 'facilities', 'Facilities', 16107, 7, 'Physiotherapy Clinics', 'required_proof'),
  ('orthopaedic_care', 'health_medical', 'facilities', 'Facilities', 16108, 8, 'Orthopaedic & Bone Care', 'required_proof'),
  ('home_nursing_agency', 'health_medical', 'home_outreach', 'Home & Outreach', 16201, 1, 'Home Nursing Agencies', 'required_proof'),
  ('medical_staffing_agency', 'health_medical', 'home_outreach', 'Home & Outreach', 16202, 2, 'Medical Staffing Agencies', 'required_proof'),
  ('mobile_health_outreach', 'health_medical', 'home_outreach', 'Home & Outreach', 16203, 3, 'Mobile Health Outreach', 'required_proof'),
  ('maternity_care_services', 'health_medical', 'reproductive_health', 'Reproductive Health', 16301, 1, 'Antenatal & Maternity Care', 'required_proof'),
  ('family_planning_services', 'health_medical', 'reproductive_health', 'Reproductive Health', 16302, 2, 'Family Planning & Reproductive Health', 'required_proof'),
  ('hiv_testing_services', 'health_medical', 'reproductive_health', 'Reproductive Health', 16303, 3, 'HIV Testing & Counselling', 'required_proof'),
  ('circumcision_services', 'health_medical', 'procedures', 'Procedures', 16401, 1, 'Circumcision Services', 'required_proof'),
  ('duwah_services', 'traditional_cultural', 'culture', 'Culture', 17101, 1, 'Duwah Services', 'optional_proof'),
  ('traditional_ceremony_services', 'traditional_cultural', 'culture', 'Culture', 17102, 2, 'Traditional Ceremonies', 'optional_proof'),
  ('traditional_dance_drumming', 'traditional_cultural', 'culture', 'Culture', 17103, 3, 'Traditional Dance & Drumming', 'open'),
  ('traditional_attire_crafts', 'traditional_cultural', 'culture', 'Culture', 17104, 4, 'Traditional Attire & Crafts', 'open'),
  ('traditional_healing_herbal', 'traditional_cultural', 'healing', 'Healing', 17201, 1, 'Herbal & Traditional Healing', 'required_proof'),
  ('personal_loan_services', 'financial_services', 'loans', 'Loans', 18101, 1, 'Personal Loan Services', 'required_proof'),
  ('emergency_loan_services', 'financial_services', 'loans', 'Loans', 18102, 2, 'Emergency Loan Services', 'required_proof'),
  ('salary_loan_services', 'financial_services', 'loans', 'Loans', 18103, 3, 'Salary Loan Services', 'required_proof'),
  ('medical_financing', 'financial_services', 'loans', 'Loans', 18104, 4, 'Medical Financing', 'required_proof'),
  ('business_startup_financing', 'financial_services', 'loans', 'Loans', 18105, 5, 'Business Startup Financing', 'required_proof'),
  ('working_capital_financing', 'financial_services', 'loans', 'Loans', 18106, 6, 'Working Capital Financing', 'required_proof'),
  ('business_expansion_financing', 'financial_services', 'loans', 'Loans', 18107, 7, 'Business Expansion Financing', 'required_proof'),
  ('sme_financing', 'financial_services', 'loans', 'Loans', 18108, 8, 'SME Financing', 'required_proof'),
  ('boda_boda_financing', 'financial_services', 'loans', 'Loans', 18109, 9, 'Boda Boda Financing', 'required_proof'),
  ('car_financing', 'financial_services', 'loans', 'Loans', 18110, 10, 'Car Financing', 'required_proof'),
  ('tuk_tuk_financing', 'financial_services', 'loans', 'Loans', 18111, 11, 'Tuk-tuk Financing', 'required_proof'),
  ('motorcycle_financing', 'financial_services', 'loans', 'Loans', 18112, 12, 'Motorcycle Financing', 'required_proof'),
  ('smartphone_financing', 'financial_services', 'loans', 'Loans', 18113, 13, 'Smartphone Financing', 'required_proof'),
  ('laptop_financing', 'financial_services', 'loans', 'Loans', 18114, 14, 'Laptop Financing', 'required_proof'),
  ('heavy_machinery_financing', 'financial_services', 'loans', 'Loans', 18115, 15, 'Heavy Machinery Financing', 'required_proof'),
  ('equipment_financing', 'financial_services', 'loans', 'Loans', 18116, 16, 'Equipment Financing', 'required_proof'),
  ('agricultural_loan_services', 'financial_services', 'loans', 'Loans', 18117, 17, 'Agricultural Loans', 'required_proof'),
  ('livestock_financing', 'financial_services', 'loans', 'Loans', 18118, 18, 'Livestock Financing', 'required_proof'),
  ('crop_financing', 'financial_services', 'loans', 'Loans', 18119, 19, 'Crop Financing', 'required_proof'),
  ('farm_equipment_financing', 'financial_services', 'loans', 'Loans', 18120, 20, 'Farm Equipment Financing', 'required_proof'),
  ('mortgage_financing', 'financial_services', 'loans', 'Loans', 18121, 21, 'Mortgage Financing', 'required_proof'),
  ('land_financing', 'financial_services', 'loans', 'Loans', 18122, 22, 'Land Financing', 'required_proof'),
  ('property_development_financing', 'financial_services', 'loans', 'Loans', 18123, 23, 'Property Development Financing', 'required_proof'),
  ('school_fees_financing', 'financial_services', 'loans', 'Loans', 18124, 24, 'School Fees Financing', 'required_proof'),
  ('university_financing', 'financial_services', 'loans', 'Loans', 18125, 25, 'University Financing', 'required_proof'),
  ('education_loan_services', 'financial_services', 'loans', 'Loans', 18126, 26, 'Education Loans', 'required_proof'),
  ('travel_financing', 'financial_services', 'loans', 'Loans', 18127, 27, 'Travel Financing', 'required_proof'),
  ('wedding_financing', 'financial_services', 'loans', 'Loans', 18128, 28, 'Wedding Financing', 'required_proof'),
  ('forex_currency_exchange', 'financial_services', 'forex', 'Forex', 18201, 1, 'Currency Exchange / Forex Bureau', 'required_proof'),
  ('forex_trading_training', 'financial_services', 'forex', 'Forex', 18202, 2, 'Forex Trading Training', 'required_proof'),
  ('forex_trading_brokerage', 'financial_services', 'forex', 'Forex', 18203, 3, 'Forex Trading Brokerage', 'required_proof'),
  ('money_transfer', 'financial_services', 'forex', 'Forex', 18204, 4, 'Money Transfer', 'required_proof'),
  ('sacco_services', 'financial_services', 'saccos_cooperatives', 'SACCOs & Cooperatives', 18301, 1, 'SACCOs', 'required_proof'),
  ('vsla_groups', 'financial_services', 'saccos_cooperatives', 'SACCOs & Cooperatives', 18302, 2, 'Village Savings Groups (VSLA)', 'required_proof'),
  ('cooperative_societies', 'financial_services', 'saccos_cooperatives', 'SACCOs & Cooperatives', 18303, 3, 'Cooperative Societies', 'required_proof'),
  ('group_savings_chamas', 'financial_services', 'saccos_cooperatives', 'SACCOs & Cooperatives', 18304, 4, 'Group Savings & Chamas', 'required_proof'),
  ('investment_stocks_shares', 'financial_services', 'investment_services', 'Investment Services', 18411, 1, 'Stocks & Shares', 'required_proof'),
  ('investment_bonds_treasury_bills', 'financial_services', 'investment_services', 'Investment Services', 18412, 2, 'Bonds & Treasury Bills', 'required_proof'),
  ('investment_precious_metals', 'financial_services', 'investment_services', 'Investment Services', 18413, 3, 'Gold & Precious Metals', 'required_proof'),
  ('investment_brokerage', 'financial_services', 'investment_services', 'Investment Services', 18414, 4, 'Investment Brokerage', 'required_proof'),
  ('investment_advisory', 'financial_services', 'investment_services', 'Investment Services', 18415, 5, 'Investment Advisory', 'required_proof'),
  ('angel_investor_network', 'financial_services', 'investment_opportunities', 'Investment Opportunities', 18401, 1, 'Angel Investor Networks', 'required_proof'),
  ('startup_advisory', 'financial_services', 'investment_opportunities', 'Investment Opportunities', 18402, 2, 'Startup Advisory', 'optional_proof'),
  ('investor_introductions', 'financial_services', 'investment_opportunities', 'Investment Opportunities', 18403, 3, 'Investor Introductions', 'required_proof'),
  ('incubator_accelerator', 'financial_services', 'investment_opportunities', 'Investment Opportunities', 18404, 4, 'Incubators & Accelerators', 'required_proof')
) as v(slug, category_slug, group_slug, group_name, sort_order, service_sort_order, name, verification_policy) where nc.slug = v.slug;

-- Add the new catalog services; Forex reuses its existing database slug.
update public.need_capabilities as nc
set category_slug = v.category_slug,
    name = v.name,
    is_active = true,
    ui_group_slug = v.ui_group_slug,
    sort_order = v.sort_order,
    service_group_slug = v.service_group_slug,
    service_group_name = v.service_group_name,
    service_sort_order = v.service_sort_order,
    capability_type = v.capability_type,
    policy = v.policy,
    verification_policy = v.verification_policy
from (values
  ('art_illustration', 'photo_video_music_talent', 'Art & Illustration', 'photo_video_music_talent', 6401, 'art_design', 'Art & Design', 1, 'service', 'open', 'open'),
  ('graphic_design', 'photo_video_music_talent', 'Graphic Design', 'photo_video_music_talent', 6402, 'art_design', 'Art & Design', 2, 'service', 'open', 'open'),
  ('forex_currency_exchange', 'financial_services', 'Currency Exchange / Forex Bureau', 'financial_services', 18201, 'forex', 'Forex', 1, 'service', 'required_proof', 'required_proof'),
  ('forex_trading_training', 'financial_services', 'Forex Trading Training', 'financial_services', 18202, 'forex', 'Forex', 2, 'service', 'required_proof', 'required_proof'),
  ('forex_trading_brokerage', 'financial_services', 'Forex Trading Brokerage', 'financial_services', 18203, 'forex', 'Forex', 3, 'service', 'required_proof', 'required_proof'),
  ('money_transfer', 'financial_services', 'Money Transfer', 'financial_services', 18204, 'forex', 'Forex', 4, 'service', 'required_proof', 'required_proof'),
  ('investment_stocks_shares', 'financial_services', 'Stocks & Shares', 'financial_services', 18411, 'investment_services', 'Investment Services', 1, 'service', 'required_proof', 'required_proof'),
  ('investment_bonds_treasury_bills', 'financial_services', 'Bonds & Treasury Bills', 'financial_services', 18412, 'investment_services', 'Investment Services', 2, 'service', 'required_proof', 'required_proof'),
  ('investment_precious_metals', 'financial_services', 'Gold & Precious Metals', 'financial_services', 18413, 'investment_services', 'Investment Services', 3, 'service', 'required_proof', 'required_proof'),
  ('investment_brokerage', 'financial_services', 'Investment Brokerage', 'financial_services', 18414, 'investment_services', 'Investment Services', 4, 'service', 'required_proof', 'required_proof'),
  ('investment_advisory', 'financial_services', 'Investment Advisory', 'financial_services', 18415, 'investment_services', 'Investment Services', 5, 'service', 'required_proof', 'required_proof'),
  ('sacco_services', 'financial_services', 'SACCOs', 'financial_services', 18301, 'saccos_cooperatives', 'SACCOs & Cooperatives', 1, 'service', 'required_proof', 'required_proof'),
  ('vsla_groups', 'financial_services', 'Village Savings Groups (VSLA)', 'financial_services', 18302, 'saccos_cooperatives', 'SACCOs & Cooperatives', 2, 'service', 'required_proof', 'required_proof'),
  ('cooperative_societies', 'financial_services', 'Cooperative Societies', 'financial_services', 18303, 'saccos_cooperatives', 'SACCOs & Cooperatives', 3, 'service', 'required_proof', 'required_proof'),
  ('group_savings_chamas', 'financial_services', 'Group Savings & Chamas', 'financial_services', 18304, 'saccos_cooperatives', 'SACCOs & Cooperatives', 4, 'service', 'required_proof', 'required_proof')
) as v(slug, category_slug, name, ui_group_slug, sort_order, service_group_slug, service_group_name, service_sort_order, capability_type, policy, verification_policy)
where nc.slug = v.slug;

insert into public.need_capabilities (
  slug, category_slug, name, is_active, ui_group_slug, sort_order,
  service_group_slug, service_group_name, service_sort_order,
  capability_type, policy, verification_policy
)
select v.slug, v.category_slug, v.name, true, v.ui_group_slug, v.sort_order,
       v.service_group_slug, v.service_group_name, v.service_sort_order,
       v.capability_type, v.policy, v.verification_policy
from (values
  ('art_illustration', 'photo_video_music_talent', 'Art & Illustration', 'photo_video_music_talent', 6401, 'art_design', 'Art & Design', 1, 'service', 'open', 'open'),
  ('graphic_design', 'photo_video_music_talent', 'Graphic Design', 'photo_video_music_talent', 6402, 'art_design', 'Art & Design', 2, 'service', 'open', 'open'),
  ('forex_currency_exchange', 'financial_services', 'Currency Exchange / Forex Bureau', 'financial_services', 18201, 'forex', 'Forex', 1, 'service', 'required_proof', 'required_proof'),
  ('forex_trading_training', 'financial_services', 'Forex Trading Training', 'financial_services', 18202, 'forex', 'Forex', 2, 'service', 'required_proof', 'required_proof'),
  ('forex_trading_brokerage', 'financial_services', 'Forex Trading Brokerage', 'financial_services', 18203, 'forex', 'Forex', 3, 'service', 'required_proof', 'required_proof'),
  ('money_transfer', 'financial_services', 'Money Transfer', 'financial_services', 18204, 'forex', 'Forex', 4, 'service', 'required_proof', 'required_proof'),
  ('investment_stocks_shares', 'financial_services', 'Stocks & Shares', 'financial_services', 18411, 'investment_services', 'Investment Services', 1, 'service', 'required_proof', 'required_proof'),
  ('investment_bonds_treasury_bills', 'financial_services', 'Bonds & Treasury Bills', 'financial_services', 18412, 'investment_services', 'Investment Services', 2, 'service', 'required_proof', 'required_proof'),
  ('investment_precious_metals', 'financial_services', 'Gold & Precious Metals', 'financial_services', 18413, 'investment_services', 'Investment Services', 3, 'service', 'required_proof', 'required_proof'),
  ('investment_brokerage', 'financial_services', 'Investment Brokerage', 'financial_services', 18414, 'investment_services', 'Investment Services', 4, 'service', 'required_proof', 'required_proof'),
  ('investment_advisory', 'financial_services', 'Investment Advisory', 'financial_services', 18415, 'investment_services', 'Investment Services', 5, 'service', 'required_proof', 'required_proof'),
  ('sacco_services', 'financial_services', 'SACCOs', 'financial_services', 18301, 'saccos_cooperatives', 'SACCOs & Cooperatives', 1, 'service', 'required_proof', 'required_proof'),
  ('vsla_groups', 'financial_services', 'Village Savings Groups (VSLA)', 'financial_services', 18302, 'saccos_cooperatives', 'SACCOs & Cooperatives', 2, 'service', 'required_proof', 'required_proof'),
  ('cooperative_societies', 'financial_services', 'Cooperative Societies', 'financial_services', 18303, 'saccos_cooperatives', 'SACCOs & Cooperatives', 3, 'service', 'required_proof', 'required_proof'),
  ('group_savings_chamas', 'financial_services', 'Group Savings & Chamas', 'financial_services', 18304, 'saccos_cooperatives', 'SACCOs & Cooperatives', 4, 'service', 'required_proof', 'required_proof')
) as v(slug, category_slug, name, ui_group_slug, sort_order, service_group_slug, service_group_name, service_sort_order, capability_type, policy, verification_policy)
where not exists (
  select 1 from public.need_capabilities as existing
  where existing.slug = v.slug
);

-- Supply the standard authorization evidence rule for new Finance services.
update public.verification_requirements as vr
set identity_required = true,
    phone_required = false,
    provider_verification_required = true,
    evidence_requirements = jsonb_build_array(vr.scope_id || '_authorization'),
    required_evidence = array[vr.scope_id || '_authorization'],
    expires_after_days = 365,
    is_active = true
where vr.scope_type = 'capability'
  and vr.provider_type = 'both'
  and vr.scope_id in (
    'forex_currency_exchange', 'forex_trading_training', 'forex_trading_brokerage', 'money_transfer',
    'sacco_services', 'vsla_groups', 'cooperative_societies', 'group_savings_chamas',
    'investment_stocks_shares', 'investment_bonds_treasury_bills', 'investment_precious_metals', 'investment_brokerage', 'investment_advisory'
  );

insert into public.verification_requirements (
  scope_type, scope_id, provider_type, identity_required, phone_required,
  provider_verification_required, evidence_requirements, required_evidence,
  expires_after_days, is_active
)
select 'capability', nc.slug, 'both', true, false, true,
       jsonb_build_array(nc.slug || '_authorization'),
       array[nc.slug || '_authorization'], 365, true
from public.need_capabilities nc
where nc.slug in (
  'forex_currency_exchange', 'forex_trading_training', 'forex_trading_brokerage', 'money_transfer',
  'sacco_services', 'vsla_groups', 'cooperative_societies', 'group_savings_chamas',
  'investment_stocks_shares', 'investment_bonds_treasury_bills', 'investment_precious_metals', 'investment_brokerage', 'investment_advisory'
)
  and not exists (
    select 1 from public.verification_requirements vr
    where vr.scope_type = 'capability'
      and vr.scope_id = nc.slug
      and vr.provider_type = 'both'
  );

-- Enable work-role rows because the guide has no category rollout gates.
update public.need_capabilities set is_active = true where capability_type = 'work' and category_slug in ('technology_digital', 'marketing_promotion', 'professional_services', 'education_training', 'events_production', 'photo_video_music_talent', 'beauty_fashion_styling', 'construction_building', 'energy_utilities', 'transport_logistics', 'machinery_equipment', 'agriculture_agribusiness', 'specialized_products', 'travel_international', 'domestic_household', 'health_medical', 'traditional_cultural', 'financial_services', 'business_investment');
update public.capability_roles set is_active = true where category_slug in ('technology_digital', 'marketing_promotion', 'professional_services', 'education_training', 'events_production', 'photo_video_music_talent', 'beauty_fashion_styling', 'construction_building', 'energy_utilities', 'transport_logistics', 'machinery_equipment', 'agriculture_agribusiness', 'specialized_products', 'travel_international', 'domestic_household', 'health_medical', 'traditional_cultural', 'financial_services', 'business_investment');
update public.need_capabilities set category_slug = 'financial_services', ui_group_slug = 'financial_services', is_active = true where slug in ('work_angel_investor', 'work_business_mentor');
update public.capability_roles set category_slug = 'financial_services', is_active = true where slug in ('work_angel_investor', 'work_business_mentor');

-- Enable every guide category and the Individual work-profile flow.
update public.system_settings
set setting_value = 'true', is_public = true, updated_at = now()
where country is null and setting_key in (
  'capability_profiles_enabled',
  'capability_profiles_enabled_domestic_household',
  'capability_profiles_enabled_health_medical',
  'capability_profiles_enabled_traditional_cultural',
  'work_profiles_enabled'
);

insert into public.system_settings (
  setting_key, country, setting_value, setting_type, category, description, is_public
)
select v.setting_key, null, 'true', 'boolean', 'providers', v.description, true
from (values
  ('capability_profiles_enabled', 'Enables category-scoped Individual and Company provider identities.'),
  ('capability_profiles_enabled_domestic_household', 'domestic_household provider catalog enabled'),
  ('capability_profiles_enabled_health_medical', 'health_medical provider catalog enabled'),
  ('capability_profiles_enabled_traditional_cultural', 'traditional_cultural provider catalog enabled'),
  ('work_profiles_enabled', 'Enables individual work-role profiles across Provider Services.')
) as v(setting_key, description)
where not exists (
  select 1 from public.system_settings ss
  where ss.setting_key = v.setting_key and ss.country is null
);

commit;

-- ============================================================================
-- END MERGED SECTION (38/52): patch_provider_catalog_one_word_hierarchy.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (39/52): patch_provider_category_full_names.sql
-- ============================================================================

-- Align backend category names with the full Provider Services display labels.
-- Apply after patch_provider_services_v2_catalog.sql.
-- Category slugs and saved provider selections remain unchanged.

begin;

do $$
begin
  if to_regclass('public.need_categories') is null then
    raise exception 'Provider category catalog is missing. Apply the base schema first.';
  end if;
end;
$$;

update public.need_categories as categories
set name = labels.name
from (values
  ('technology_digital', 'Technology & Digital'),
  ('marketing_promotion', 'Marketing & Promotion'),
  ('professional_services', 'Business & Professional Services'),
  ('education_training', 'Education & Training'),
  ('events_production', 'Events & Celebrations'),
  ('events_celebrations', 'Events & Celebrations'),
  ('weddings_celebrations', 'Events & Celebrations'),
  ('photo_video_music_talent', 'Photo, Video, Music & Talent'),
  ('photo_video_talent', 'Photo, Video & Talent'),
  ('music_video', 'Music & Video'),
  ('beauty_fashion_styling', 'Beauty, Fashion, Styling & Wellness'),
  ('construction_building', 'Construction & Building'),
  ('energy_utilities', 'Energy & Utilities'),
  ('transport_logistics', 'Transport & Logistics'),
  ('machinery_equipment', 'Machinery & Equipment'),
  ('agriculture_agribusiness', 'Agriculture & Agribusiness'),
  ('specialized_products', 'Specialized Products & Procurement'),
  ('travel_international', 'Travel & International'),
  ('domestic_household', 'Domestic & Household'),
  ('health_medical', 'Health & Medical'),
  ('business_investment', 'Business & Investment'),
  ('financial_services', 'Finance & Investments'),
  ('traditional_cultural', 'Traditional & Cultural Services')
) as labels(slug, name)
where categories.slug = labels.slug;

commit;

-- ============================================================================
-- END MERGED SECTION (39/52): patch_provider_category_full_names.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (40/52): patch_travel_tourism_services.sql
-- ============================================================================

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

-- ============================================================================
-- END MERGED SECTION (40/52): patch_travel_tourism_services.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (41/52): patch_chef_food_specialties.sql
-- ============================================================================

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

-- ============================================================================
-- END MERGED SECTION (41/52): patch_chef_food_specialties.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (42/52): patch_property_real_estate_services.sql
-- ============================================================================

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

-- ============================================================================
-- END MERGED SECTION (42/52): patch_property_real_estate_services.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (43/52): patch_identity_verification_helper.sql
-- ============================================================================

-- Compatibility fix for projects where KYC is stored only in
-- public.kyc_verifications and profiles has no kyc_status column.
-- This preserves strict identity verification: only approved, unexpired KYC
-- rows satisfy the check. It does not approve users or bypass KYC.

CREATE OR REPLACE FUNCTION private.is_identity_verified(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT COALESCE(
    EXISTS (
      SELECT 1
      FROM public.kyc_verifications kv
      WHERE kv.user_id = p_user_id
        AND kv.status = 'approved'
        AND (kv.expires_at IS NULL OR kv.expires_at > now())
    ),
    false
  );
$$;

COMMENT ON FUNCTION private.is_identity_verified(uuid) IS
  'Returns true only for users with approved, unexpired KYC in public.kyc_verifications.';

-- ============================================================================
-- END MERGED SECTION (43/52): patch_identity_verification_helper.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (44/52): patch_notification_type_new_opportunity.sql
-- ============================================================================

-- Add the notification kind used by the Needs provider-opportunity trigger.
-- Run this as a standalone statement and let it commit before retrying the
-- Needs seed so PostgreSQL can use the new enum value in trigger inserts.

ALTER TYPE public.notification_type_enum
  ADD VALUE IF NOT EXISTS 'new_opportunity';

-- ============================================================================
-- END MERGED SECTION (44/52): patch_notification_type_new_opportunity.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (45/52): patch_need_provider_notification_trigger.sql
-- ============================================================================

-- Fix the Needs opportunity trigger to match the current schema:
-- provider_capabilities uses user_id, and needs_requests uses request_id.
-- Notification matching and recipient behavior are otherwise unchanged.

CREATE OR REPLACE FUNCTION private.trg_notify_matching_providers_on_need_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
  v_capability_slug text := NEW.capability_slug;
  v_category_slug text := NEW.category_slug;
  v_title text := COALESCE(NEW.title, 'New opportunity');
  v_provider_id uuid;
BEGIN
  FOR v_provider_id IN
    SELECT DISTINCT pc.user_id
    FROM public.provider_capabilities pc
    JOIN public.need_capabilities nc ON nc.slug = pc.capability_slug
    WHERE (
      (v_capability_slug IS NOT NULL AND pc.capability_slug = v_capability_slug)
      OR
      (v_capability_slug IS NULL AND nc.category_slug = v_category_slug)
    )
      AND pc.user_id <> NEW.requester_id
  LOOP
    INSERT INTO public.notifications (
      user_id, type, title, body, data, is_read, created_at
    ) VALUES (
      v_provider_id,
      'new_opportunity',
      'New Opportunity',
      v_title,
      jsonb_build_object(
        'need_id', NEW.request_id,
        'category_slug', v_category_slug,
        'capability_slug', v_capability_slug
      ),
      false,
      now()
    );
  END LOOP;

  RETURN NEW;
END;
$$;

-- ============================================================================
-- END MERGED SECTION (45/52): patch_need_provider_notification_trigger.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (46/52): patch_save_company_category_presentation.sql
-- ============================================================================

-- Keep the company category save RPC aligned with the Flutter client. Apply
-- after patch_financial_services_provider_capabilities.sql and
-- patch_provider_identity_switch.sql. The app passes six named RPC arguments
-- and saves the company profile, service selection, and identity presentation
-- in one transaction.
begin;

create or replace function public.save_company_category(
  p_category_slug text,
  p_services text[],
  p_roles text[],
  p_profile jsonb,
  p_evidence jsonb,
  p_presentation jsonb
) returns void
language plpgsql security invoker
set search_path = public, private, pg_temp
as $$
declare
  v_name text := btrim(coalesce(p_profile->>'company_name', ''));
  v_mode text := coalesce(p_presentation->>'display_mode', 'company');
  v_rep text := btrim(coalesce(p_presentation->>'representative_name', ''));
  v_authorized boolean := coalesce(
    (p_presentation->>'representative_authorized')::boolean, false);
  v_presentation jsonb;
begin
  if v_name = '' then
    raise exception 'Company name is required.' using errcode = 'P0217';
  end if;
  if char_length(v_name) > 80 then
    raise exception 'Company name must be 80 characters or fewer.' using errcode = 'P0218';
  end if;
  if v_mode not in ('company', 'company_with_representative') then
    raise exception 'Invalid company display mode.' using errcode = 'P0216';
  end if;
  if v_mode = 'company_with_representative'
     and (v_rep = '' or not v_authorized) then
    raise exception 'Representative name and authorization are required.'
      using errcode = 'P0219';
  end if;

  perform private.set_provider_category_type_internal(p_category_slug, 'company');
  if p_category_slug = 'financial_services' then
    perform private.save_financial_company_category_internal(
      p_category_slug, p_services, p_roles, p_profile, p_evidence);
  else
    perform private.save_company_category_internal(
      p_category_slug, p_services, p_roles, p_profile, p_evidence);
  end if;

  v_presentation := coalesce(p_presentation, '{}'::jsonb) || jsonb_build_object(
    'display_mode', v_mode,
    'display_name', v_name,
    'representative_name', case when v_mode = 'company_with_representative'
      then v_rep else null end,
    'representative_authorized', case when v_mode = 'company_with_representative'
      then v_authorized else false end);
  perform private.save_provider_identity_presentation_internal(
    p_category_slug, 'company', v_presentation);
end;
$$;

revoke all on function public.save_company_category(text,text[],text[],jsonb,jsonb,jsonb)
  from public, anon;
grant execute on function public.save_company_category(text,text[],text[],jsonb,jsonb,jsonb)
  to authenticated;

commit;

-- ============================================================================
-- END MERGED SECTION (46/52): patch_save_company_category_presentation.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (47/52): patch_finance_provider_top_level_categories.sql
-- ============================================================================

-- Split the former Finance & Investments provider category into independent
-- top-level provider categories while keeping the financial_services slug for
-- Loans & Financing so existing loan product checks and matching remain valid.
-- Apply after patch_provider_catalog_one_word_hierarchy.sql,
-- patch_financial_services_provider_capabilities.sql, and the provider
-- identity / verification patches. This patch has not been run.

begin;

insert into public.need_categories
  (slug, name, icon, description, sort_order, is_active, provider_verification_required)
values
  ('investment_services', 'Investment Services', '📈',
   'Investment brokerage, investment guidance and related services.', 20, true, false),
  ('investment_opportunities', 'Investment Opportunities', '🤝',
   'Investor networks, introductions and startup support services.', 21, true, false),
  ('forex_money_services', 'Forex & Money Services', '💱',
   'Currency exchange, forex services and money transfer.', 22, true, false),
  ('savings_cooperatives', 'Savings & Cooperatives', '🏦',
   'SACCOs, savings groups, VSLAs and cooperatives.', 23, true, false)
on conflict (slug) do update set
  name = excluded.name,
  icon = excluded.icon,
  description = excluded.description,
  sort_order = excluded.sort_order,
  is_active = true;

update public.need_categories
set name = 'Loans & Financing', icon = '💰',
    description = 'Personal, business, asset and other loan financing services.',
   sort_order = 18, is_active = true
where slug = 'financial_services';

-- Move catalog rows by their stable capability slugs. Provider capability rows
-- reference these slugs, so their verification history and IDs remain intact.
WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
update public.need_capabilities nc
set category_slug = m.target_category_slug,
    ui_group_slug = m.target_category_slug
from finance_category_moves m
where nc.slug = m.capability_slug
  and nc.category_slug = 'financial_services';

-- Startup advisory is a business mentor work role in older catalogs. Keep the
-- capability in the Investment Opportunities category if that legacy slug is
-- still present there.
update public.need_capabilities
set category_slug = 'investment_opportunities', ui_group_slug = 'investment_opportunities'
where slug = 'work_business_mentor' and category_slug = 'financial_services';
update public.need_capabilities
set service_group_name = case category_slug
  when 'investment_services' then 'Brokerage & Advisory'
  when 'investment_opportunities' then 'Investor Networks & Startup Support'
  when 'forex_money_services' then 'Currency Exchange & Transfers'
  when 'savings_cooperatives' then 'Savings Groups & Cooperatives'
end
where category_slug in ('investment_services', 'investment_opportunities',
  'forex_money_services', 'savings_cooperatives');
update public.capability_roles
set category_slug = 'investment_opportunities'
where slug in ('work_angel_investor', 'work_business_mentor')
  and category_slug = 'financial_services';

-- Give Individual Forex providers role choices like Education providers have.
alter table public.role_qualifications
  add column if not exists is_required_proof boolean not null default false;

insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order,
   capability_type, policy, aliases)
values
  ('work_forex_bureau_operator', 'forex_money_services', 'Currency Exchange / Forex Bureau Operator', true, 'forex_money_services', 22300, 'work_roles', 'Work roles', 10, 'work', 'required_proof', array['forex bureau','currency exchange']),
  ('work_forex_trainer', 'forex_money_services', 'Forex Trading Trainer', true, 'forex_money_services', 22310, 'work_roles', 'Work roles', 20, 'work', 'optional_proof', array['forex instructor']),
  ('work_forex_broker', 'forex_money_services', 'Forex Broker / Dealer', true, 'forex_money_services', 22320, 'work_roles', 'Work roles', 30, 'work', 'required_proof', array['forex dealer']),
  ('work_money_transfer_agent', 'forex_money_services', 'Money Transfer Agent', true, 'forex_money_services', 22330, 'work_roles', 'Work roles', 40, 'work', 'required_proof', array['remittance agent','transfer agent'])
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = excluded.is_active,
  ui_group_slug = excluded.ui_group_slug,
  service_group_slug = excluded.service_group_slug,
  service_group_name = excluded.service_group_name,
  service_sort_order = excluded.service_sort_order,
  capability_type = excluded.capability_type,
  policy = excluded.policy,
  aliases = excluded.aliases;

insert into public.capability_roles
  (slug, category_slug, capability_slug, name, kind_question, is_active, aliases)
values
  ('forex_bureau_operator', 'forex_money_services', 'work_forex_bureau_operator', 'Currency Exchange / Forex Bureau Operator', 'Which currency services do you provide?', true, array['forex bureau','currency exchange']),
  ('forex_trainer', 'forex_money_services', 'work_forex_trainer', 'Forex Trading Trainer', 'What do you teach?', true, array['forex instructor']),
  ('forex_broker', 'forex_money_services', 'work_forex_broker', 'Forex Broker / Dealer', 'Which brokerage services do you provide?', true, array['forex dealer']),
  ('money_transfer_agent', 'forex_money_services', 'work_money_transfer_agent', 'Money Transfer Agent', 'Which transfer services do you handle?', true, array['remittance agent','transfer agent'])
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  capability_slug = excluded.capability_slug,
  name = excluded.name,
  kind_question = excluded.kind_question,
  is_active = excluded.is_active,
  aliases = excluded.aliases;

insert into public.role_kinds (role_slug, slug, name, sort_order) values
  ('forex_bureau_operator', 'cash_exchange', 'Cash currency exchange', 10),
  ('forex_bureau_operator', 'business_exchange', 'Business currency exchange', 20),
  ('forex_bureau_operator', 'rate_quotations', 'Rate quotations', 30),
  ('forex_trainer', 'forex_basics', 'Forex basics', 10),
  ('forex_trainer', 'technical_analysis', 'Technical analysis', 20),
  ('forex_trainer', 'risk_management', 'Risk management', 30),
  ('forex_broker', 'trade_execution', 'Trade execution', 10),
  ('forex_broker', 'client_onboarding', 'Client onboarding', 20),
  ('forex_broker', 'account_support', 'Account support', 30),
  ('money_transfer_agent', 'domestic_transfers', 'Domestic transfers', 10),
  ('money_transfer_agent', 'international_transfers', 'International transfers', 20),
  ('money_transfer_agent', 'mobile_money_transfers', 'Mobile money transfers', 30)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  sort_order = excluded.sort_order;

insert into public.role_qualifications
  (role_slug, slug, name, is_evidence, sort_order, is_required_proof) values
  ('forex_bureau_operator', 'exchange_authorisation', 'Forex bureau or dealer authorisation', true, 10, true),
  ('forex_bureau_operator', 'aml_training', 'AML / financial crime training', true, 20, false),
  ('forex_bureau_operator', 'cash_handling_experience', 'Cash handling experience', false, 30, false),
  ('forex_trainer', 'forex_training_experience', 'Forex teaching experience', false, 10, false),
  ('forex_trainer', 'training_materials', 'Training materials or course outline', false, 20, false),
  ('forex_trainer', 'trading_track_record', 'Trading track record', false, 30, false),
  ('forex_broker', 'broker_authorisation', 'Broker or dealer authorisation', true, 10, true),
  ('forex_broker', 'aml_training', 'AML / financial crime training', true, 20, false),
  ('forex_broker', 'brokerage_experience', 'Brokerage experience', false, 30, false),
  ('money_transfer_agent', 'agent_authorisation', 'Money transfer agent authorisation', true, 10, true),
  ('money_transfer_agent', 'aml_training', 'AML / financial crime training', true, 20, false),
  ('money_transfer_agent', 'customer_service_experience', 'Customer service experience', false, 30, false)
on conflict (role_slug, slug) do update set
  name = excluded.name,
  is_evidence = excluded.is_evidence,
  sort_order = excluded.sort_order,
  is_required_proof = excluded.is_required_proof;

-- Carry each selected category's identity, company details and presentation
-- into the new category rows. The old profile remains for Loans & Financing.
WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
insert into public.provider_category_profiles (user_id, category_slug, provider_type)
select distinct pc.user_id, m.target_category_slug,
       coalesce(pc.identity_type, pcp.provider_type, 'company')
from public.provider_capabilities pc
join finance_category_moves m on m.capability_slug = pc.capability_slug
left join public.provider_category_profiles pcp
  on pcp.user_id = pc.user_id and pcp.category_slug = 'financial_services'
where pc.identity_type is not null or pcp.provider_type is not null
on conflict (user_id, category_slug) do nothing;

WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
insert into public.provider_company_profiles (
  user_id, category_slug, company_name, registration_number, team_size,
  years_in_business, service_areas, created_at, updated_at
)
select distinct cp.user_id, m.target_category_slug, cp.company_name,
       cp.registration_number, cp.team_size, cp.years_in_business,
       cp.service_areas, cp.created_at, cp.updated_at
from public.provider_company_profiles cp
join public.provider_capabilities pc on pc.user_id = cp.user_id
join finance_category_moves m on m.capability_slug = pc.capability_slug
where cp.category_slug = 'financial_services'
  and coalesce(pc.identity_type, 'company') = 'company'
on conflict (user_id, category_slug) do nothing;

WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
insert into public.provider_identity_presentations (
  user_id, category_slug, identity_type, display_mode, display_name,
  representative_name, representative_authorized, created_at, updated_at
)
select distinct ip.user_id, m.target_category_slug, ip.identity_type,
       ip.display_mode, ip.display_name, ip.representative_name,
       ip.representative_authorized, ip.created_at, ip.updated_at
from public.provider_identity_presentations ip
join public.provider_capabilities pc on pc.user_id = ip.user_id
join finance_category_moves m on m.capability_slug = pc.capability_slug
where ip.category_slug = 'financial_services'
  and ip.identity_type = coalesce(pc.identity_type, 'company')
on conflict (user_id, category_slug, identity_type) do nothing;

WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
insert into public.provider_company_verification_submissions (
  user_id, category_slug, document_type, file_path, status, reject_reason,
  reviewed_by, reviewed_at, created_at, updated_at
)
select distinct submission.user_id, moves.target_category_slug,
       submission.document_type, submission.file_path, submission.status,
       submission.reject_reason, submission.reviewed_by, submission.reviewed_at,
       submission.created_at, submission.updated_at
from public.provider_company_verification_submissions submission
join public.provider_capabilities pc on pc.user_id = submission.user_id
join finance_category_moves moves on moves.capability_slug = pc.capability_slug
where submission.category_slug = 'financial_services'
  and coalesce(pc.identity_type, 'company') = 'company'
  and not exists (
    select 1 from public.provider_company_verification_submissions existing
    where existing.user_id = submission.user_id
      and existing.category_slug = moves.target_category_slug
      and existing.document_type = submission.document_type
  );

-- Keep the capability-save RPC's category ownership checks and limits while
-- extending Individual service support to the four new finance categories.
create or replace function public.save_provider_capabilities(
  p_items jsonb default '[]'::jsonb,
  p_category_slug text default null,
  p_remove_slugs text[] default array[]::text[]
) returns setof public.provider_capabilities
language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare
  v_user uuid := auth.uid(); v_type text; v_max int := 30; v_count int;
  v_item record; v_kind text; v_category text;
  v_incoming text[] := array[]::text[];
begin
  if v_user is null then raise exception 'Not authenticated' using errcode = '42501'; end if;
  if jsonb_typeof(coalesce(p_items, '[]'::jsonb)) <> 'array' then
    raise exception 'Invalid capability selection.' using errcode = 'P0215';
  end if;
  if p_category_slug is not null then
    select provider_type into v_type from public.provider_category_profiles
    where user_id = v_user and category_slug = p_category_slug;
    if v_type is null then raise exception 'Choose a provider identity first.' using errcode = 'P0216'; end if;
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb))
    as x(capability_slug text, metadata jsonb)
  loop
    select nc.category_slug, nc.capability_type into v_category, v_kind
    from public.need_capabilities nc
    where nc.slug = v_item.capability_slug and nc.is_active;
    if not found or (p_category_slug is not null and v_category <> p_category_slug) then
      raise exception 'Invalid capability for category.' using errcode = 'P0215';
    end if;
    if v_kind = 'service' and coalesce(v_type, 'company') = 'individual'
       and v_category not in ('financial_services', 'investment_services',
         'investment_opportunities', 'forex_money_services', 'savings_cooperatives') then
      raise exception 'Individual providers cannot save company services.' using errcode = 'P0215';
    end if;
    v_incoming := array_append(v_incoming, v_item.capability_slug);
  end loop;
  select coalesce(nullif(setting_value, '')::int, 30) into v_max
  from public.system_settings where setting_key = 'max_provider_capabilities'
    and (country is null or country = '__global__') limit 1;
  select count(*) into v_count from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  where pc.user_id = v_user
    and (p_category_slug is null or nc.category_slug <> p_category_slug
      or pc.identity_type = v_type or nc.capability_type = 'work')
    and (p_category_slug is not null
      or not (pc.capability_slug = any(coalesce(p_remove_slugs, array[]::text[]))));
  if v_count + cardinality(v_incoming) > coalesce(v_max, 30) then
    raise exception 'Maximum limit of % provider capabilities reached.', coalesce(v_max, 30)
      using errcode = 'P0206';
  end if;
  if coalesce(cardinality(p_remove_slugs), 0) > 0 then
    delete from public.provider_capabilities pc
    where pc.user_id = v_user and pc.capability_slug = any(p_remove_slugs)
      and (p_category_slug is null or pc.identity_type = v_type or pc.identity_type is null);
  end if;
  if p_category_slug is not null then
    delete from public.provider_capabilities pc using public.need_capabilities nc
    where pc.capability_slug = nc.slug and pc.user_id = v_user
      and nc.category_slug = p_category_slug
      and not (pc.capability_slug = any(v_incoming))
      and (nc.capability_type = 'work' or pc.identity_type = v_type);
  end if;
  for v_item in select * from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb))
    as x(capability_slug text, metadata jsonb)
  loop
    select capability_type into v_kind from public.need_capabilities
    where slug = v_item.capability_slug;
    if v_kind = 'work' then
      insert into public.provider_capabilities(user_id, capability_slug, verification_level, metadata, created_at)
      values (v_user, v_item.capability_slug, 'self_declared', coalesce(v_item.metadata, '{}'::jsonb), now())
      on conflict (user_id, capability_slug) where identity_type is null do update set
        metadata = case when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb
          then excluded.metadata else public.provider_capabilities.metadata end;
    else
      insert into public.provider_capabilities(user_id, capability_slug, identity_type, verification_level, metadata, created_at)
      values (v_user, v_item.capability_slug, v_type, 'self_declared', coalesce(v_item.metadata, '{}'::jsonb), now())
      on conflict (user_id, capability_slug, identity_type) where identity_type is not null do update set
        metadata = case when excluded.metadata is not null and excluded.metadata <> '{}'::jsonb
          then excluded.metadata else public.provider_capabilities.metadata end;
    end if;
  end loop;
  return query select * from public.provider_capabilities where user_id = v_user;
end;
$$;
revoke all on function public.save_provider_capabilities(jsonb, text, text[]) from public, anon;
grant execute on function public.save_provider_capabilities(jsonb, text, text[]) to authenticated;

-- Financial capabilities can be offered under either provider identity. The
-- legacy rule allowed individual identities only under financial_services;
-- extend that rule to the new finance category slugs.
create or replace function private.enforce_provider_identity_capability()
returns trigger language plpgsql security definer
set search_path = public, private, pg_temp as $$
declare v_category text; v_kind text; v_current text;
begin
  select category_slug, capability_type into v_category, v_kind
  from public.need_capabilities where slug = new.capability_slug;
  if v_kind = 'service' then
    if tg_op = 'UPDATE' and old.identity_type is not null
       and new.identity_type is distinct from old.identity_type
       and not private.is_admin() then
      raise exception 'A service identity cannot be changed directly.' using errcode = 'P0216';
    end if;
    select provider_type into v_current from public.provider_category_profiles
    where user_id = new.user_id and category_slug = v_category;
    if new.identity_type is null then new.identity_type := coalesce(v_current, 'company'); end if;
    if new.identity_type not in ('individual', 'company') then
      raise exception 'Invalid capability identity.' using errcode = 'P0216';
    end if;
    if new.is_active and new.identity_type is distinct from coalesce(v_current, 'company') then
      new.is_active := false;
    elsif new.is_active
       and v_category not in ('financial_services', 'investment_services',
         'investment_opportunities', 'forex_money_services', 'savings_cooperatives')
       and coalesce(v_current, 'company') = 'individual' then
      new.is_active := false;
    end if;
  else
    new.identity_type := null;
  end if;
  return new;
end;
$$;

-- Re-run the existing per-capability proof gate under each category's identity
-- and verification policy. This hides moved services that lack approved proof.
WITH finance_category_moves(capability_slug, target_category_slug) AS (VALUES
  ('forex_currency_exchange', 'forex_money_services'),
  ('forex_trading_training', 'forex_money_services'),
  ('forex_trading_brokerage', 'forex_money_services'),
  ('money_transfer', 'forex_money_services'),
  ('sacco_services', 'savings_cooperatives'),
  ('vsla_groups', 'savings_cooperatives'),
  ('cooperative_societies', 'savings_cooperatives'),
  ('group_savings_chamas', 'savings_cooperatives'),
  ('sacco_microfinance', 'savings_cooperatives'),
  ('investment_stocks_shares', 'investment_services'),
  ('investment_bonds_treasury_bills', 'investment_services'),
  ('investment_precious_metals', 'investment_services'),
  ('investment_brokerage', 'investment_services'),
  ('investment_advisory', 'investment_services'),
  ('financial_advisory', 'investment_services'),
  ('angel_investor_network', 'investment_opportunities'),
  ('startup_advisory', 'investment_opportunities'),
  ('investor_introductions', 'investment_opportunities'),
  ('incubator_accelerator', 'investment_opportunities'),
  ('work_angel_investor', 'investment_opportunities'),
  ('work_business_mentor', 'investment_opportunities')
)
update public.provider_capabilities pc
set is_active = pc.is_active
from public.need_capabilities nc
join finance_category_moves moves on moves.capability_slug = nc.slug
where pc.capability_slug = nc.slug
  and moves.target_category_slug <> 'financial_services';

-- Keep the new provider-only categories out of borrower Needs even though
-- their catalog rows remain active for Provider Services.
create or replace function public.reject_financial_needs_category()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.category_slug in (
    'financial_services', 'investment_services', 'investment_opportunities',
    'forex_money_services', 'savings_cooperatives'
  ) then
    raise exception 'Financial service categories belong in Provider Services, Loans or Forex, not Needs.'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

commit;

notify pgrst, 'reload schema';

-- ============================================================================
-- END MERGED SECTION (47/52): patch_finance_provider_top_level_categories.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (48/52): patch_save_company_category_identity_conflict.sql
-- ============================================================================

-- Fix 42P10 in private.save_company_category_internal after
-- patch_financial_services_provider_capabilities.sql replaced
-- provider_capabilities_user_id_capability_slug_key with the partial
-- identity-scoped unique indexes:
--   provider_capabilities_service_identity_uidx (user_id, capability_slug, identity_type) where identity_type is not null
--   provider_capabilities_work_identity_uidx    (user_id, capability_slug) where identity_type is null
-- Apply after patch_company_provider_path.sql and
-- patch_financial_services_provider_capabilities.sql.
begin;

create or replace function private.save_company_category_internal(
  p_category_slug text,
  p_services text[],
  p_roles text[],
  p_profile jsonb,
  p_evidence jsonb
) returns void
language plpgsql security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_country text;
  v_type text;
  v_enabled text;
  v_limit integer := 30;
  v_count integer;
  v_services text[] := coalesce(p_services, array[]::text[]);
  v_roles text[] := coalesce(p_roles, array[]::text[]);
  v_service text;
  v_item jsonb;
  v_key text;
  v_path text;
  v_size bigint;
  v_mime text;
  v_recent_uploads integer := 0;
  v_profile jsonb := coalesce(p_profile, '{}'::jsonb);
  v_areas text[] := array[]::text[];
  v_old_profile jsonb;
begin
  if v_user is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  if p_category_slug is null or btrim(p_category_slug) = '' then
    raise exception 'A provider category is required.' using errcode = 'P0201';
  end if;
  if jsonb_typeof(v_profile) <> 'object'
     or jsonb_typeof(coalesce(p_evidence, '[]'::jsonb)) <> 'array' then
    raise exception 'Company profile or evidence payload is invalid.' using errcode = 'P0201';
  end if;
  if cardinality(v_services) <> cardinality(array(select distinct x from unnest(v_services) x))
     or cardinality(v_roles) <> cardinality(array(select distinct x from unnest(v_roles) x))
     or v_services && v_roles then
    raise exception 'Duplicate or conflicting provider selections.' using errcode = 'P0201';
  end if;
  if cardinality(v_roles) > 0 then
    raise exception 'Company providers can select services only.' using errcode = 'P0201';
  end if;
  if cardinality(v_services) = 0 then
    raise exception 'Select at least one service.' using errcode = 'P0201';
  end if;
  if not exists (select 1 from public.need_categories c
    where c.slug = p_category_slug and c.is_active) then
    raise exception 'This provider category is not active.' using errcode = 'P0201';
  end if;
  select country into v_country from public.profiles where id = v_user;
  if not found then raise exception 'Provider profile is unavailable.' using errcode = 'P0201'; end if;
  select provider_type into v_type from public.provider_category_profiles
    where user_id = v_user and category_slug = p_category_slug;
  if v_type is distinct from 'company' then
    raise exception 'Choose Company / Organization for this category first.' using errcode = 'P0202';
  end if;

  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled' and is_public
      and (country = v_country or country is null)
    order by (country = v_country) desc nulls last limit 1;
  if lower(coalesce(v_enabled, 'false')) not in ('true', '1') then
    raise exception 'Provider services are not enabled in your market.' using errcode = 'P0202';
  end if;
  select setting_value into v_enabled from public.system_settings
    where setting_key = 'capability_profiles_enabled_' || p_category_slug and is_public
      and (country = v_country or country is null)
    order by (country = v_country) desc nulls last limit 1;
  if lower(coalesce(v_enabled, 'true')) in ('false', '0') then
    raise exception 'This provider category is not enabled in your market.' using errcode = 'P0202';
  end if;

  foreach v_service in array v_services loop
    if not exists (select 1 from public.need_capabilities nc
      where nc.slug = v_service and nc.category_slug = p_category_slug
        and nc.is_active and nc.capability_type = 'service') then
      raise exception 'A selected service is invalid for this category.' using errcode = 'P0203';
    end if;
  end loop;
  if length(coalesce(v_profile->>'company_name', '')) > 80
     or length(coalesce(v_profile->>'registration_number', '')) > 40
     or (v_profile ? 'team_size' and v_profile->>'team_size' not in ('1-5','6-20','21-50','50+'))
     or (v_profile ? 'years_in_business' and v_profile->>'years_in_business' not in ('<1','1-2','3-5','6-10','10+'))
     or (v_profile ? 'service_areas' and jsonb_typeof(v_profile->'service_areas') <> 'array') then
    raise exception 'Company profile details are invalid.' using errcode = 'P0204';
  end if;
  select coalesce(array_agg(distinct btrim(value)), array[]::text[]) into v_areas
    from jsonb_array_elements_text(coalesce(v_profile->'service_areas', '[]'::jsonb)) x(value)
    where btrim(value) <> '';
  if exists (select 1 from unnest(v_areas) area where length(area) > 80) then
    raise exception 'Service areas must be district or city names.' using errcode = 'P0204';
  end if;

  select coalesce(nullif(setting_value, '')::integer, 30) into v_limit
    from public.system_settings
    where setting_key = 'max_provider_capabilities'
      and (country = v_country or country is null)
    order by (country = v_country) desc nulls last limit 1;
  v_limit := coalesce(v_limit, 30);
  select count(*) into v_count
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    where pc.user_id = v_user
      and (nc.category_slug <> p_category_slug or nc.capability_type = 'work');
  if v_count + cardinality(v_services) > v_limit then
    raise exception 'Maximum limit of % provider capabilities reached.', v_limit using errcode = 'P0206';
  end if;

  if jsonb_array_length(coalesce(p_evidence, '[]'::jsonb)) > 0 then
    select count(distinct e.file_url) into v_recent_uploads
      from public.provider_capability_evidence e
      join public.provider_capabilities pc on pc.id = e.provider_capability_id
      where pc.user_id = v_user and e.created_at > now() - interval '1 hour';
    if v_recent_uploads >= 20 then
      raise exception 'Evidence upload limit reached. Try again later.' using errcode = 'P0213';
    end if;
  end if;

  -- The Company path edits company services only. Existing personal work
  -- profiles and individual services remain untouched.
  delete from public.provider_capabilities pc using public.need_capabilities nc
    where pc.capability_slug = nc.slug and pc.user_id = v_user
      and nc.category_slug = p_category_slug and nc.capability_type = 'service'
      and (pc.identity_type = 'company' or pc.identity_type is null)
      and not (pc.capability_slug = any(v_services));

  foreach v_service in array v_services loop
    insert into public.provider_capabilities(
      user_id, capability_slug, identity_type, verification_level, metadata, created_at
    )
      values (v_user, v_service, 'company', 'self_declared', '{}'::jsonb, now())
    on conflict (user_id, capability_slug, identity_type)
      where identity_type is not null
    do update
      set verification_level = case when provider_capabilities.verification_level = 'provider_verified'
        then provider_capabilities.verification_level else 'self_declared' end;
  end loop;
  select to_jsonb(cp) into v_old_profile from public.provider_company_profiles cp
    where cp.user_id = v_user and cp.category_slug = p_category_slug;
  insert into public.provider_company_profiles(
    user_id, category_slug, company_name, registration_number, team_size,
    years_in_business, service_areas
  ) values (
    v_user, p_category_slug, nullif(btrim(v_profile->>'company_name'), ''),
    nullif(btrim(v_profile->>'registration_number'), ''),
    nullif(v_profile->>'team_size', ''), nullif(v_profile->>'years_in_business', ''), v_areas
  ) on conflict(user_id, category_slug) do update set
    company_name = excluded.company_name,
    registration_number = excluded.registration_number,
    team_size = excluded.team_size,
    years_in_business = excluded.years_in_business,
    service_areas = excluded.service_areas,
    updated_at = now();

  for v_item in select value from jsonb_array_elements(coalesce(p_evidence, '[]'::jsonb))
  loop
    v_key := btrim(coalesce(v_item->>'requirement_key', ''));
    v_path := btrim(coalesce(v_item->>'file_path', ''));
    if v_key = '' or v_path = '' or
       v_path not like 'evidence/' || v_user::text || '/' || p_category_slug || '/%' then
      raise exception 'Company evidence path or requirement is invalid.' using errcode = 'P0205';
    end if;
    if not exists (
      select 1 from public.verification_requirements r
      where r.is_active and (
        r.provider_type = 'company' or (r.provider_type = 'both' and not exists (
          select 1 from public.verification_requirements specific
          where specific.scope_type = r.scope_type and specific.scope_id = r.scope_id
            and specific.provider_type = 'company' and specific.is_active
        ))
      ) and (
        (r.scope_type = 'category' and r.scope_id = p_category_slug)
        or (r.scope_type = 'capability' and r.scope_id = any(v_services))
      ) and (
        v_key = any(coalesce(r.required_evidence, array[]::text[]))
        or exists (select 1 from jsonb_array_elements_text(
              case when jsonb_typeof(r.evidence_requirements) = 'array'
                then r.evidence_requirements else '[]'::jsonb end
            ) ev(value)
              where ev.value = v_key))
      ) then
      raise exception 'Evidence type is not required for selected company services.' using errcode = 'P0205';
    end if;
    select (o.metadata->>'size')::bigint, lower(coalesce(o.metadata->>'mimetype', ''))
      into v_size, v_mime from storage.objects o
      where o.bucket_id = 'provider-evidence' and o.name = v_path and o.owner_id = v_user::text;
    if not found then
      raise exception 'Uploaded evidence file is not owned by this provider.' using errcode = 'P0205';
    end if;
    if v_size is null or v_size > 5242880 or v_mime not in ('image/jpeg', 'image/png', 'application/pdf') then
      raise exception 'Evidence must be JPG, PNG, or PDF and no larger than 5 MB.' using errcode = 'P0205';
    end if;
    for v_service in select unnest(v_services) loop
      if exists (
        select 1 from public.verification_requirements r
        where r.is_active and (
          r.provider_type = 'company' or (r.provider_type = 'both' and not exists (
            select 1 from public.verification_requirements specific
            where specific.scope_type = r.scope_type and specific.scope_id = r.scope_id
              and specific.provider_type = 'company' and specific.is_active
          ))
        ) and (
          (r.scope_type = 'category' and r.scope_id = p_category_slug)
          or (r.scope_type = 'capability' and r.scope_id = v_service)
        ) and (
          v_key = any(coalesce(r.required_evidence, array[]::text[]))
          or exists (select 1 from jsonb_array_elements_text(
                case when jsonb_typeof(r.evidence_requirements) = 'array'
                  then r.evidence_requirements else '[]'::jsonb end
              ) ev(value)
                where ev.value = v_key))
        ) then
        insert into public.provider_capability_evidence(
          provider_capability_id, requirement_key, file_url, status, provider_type
        )
        select pc.id, v_key, v_path, 'pending', 'company'
          from public.provider_capabilities pc
          where pc.user_id = v_user and pc.capability_slug = v_service
            and pc.identity_type = 'company'
            and not exists (select 1 from public.provider_capability_evidence e
              where e.provider_capability_id = pc.id and e.requirement_key = v_key
                and e.file_url = v_path);
      end if;
    end loop;
  end loop;

  insert into public.audit_logs(user_id, event_type, entity_type, action, old_values, new_values)
  values (v_user, 'admin_action', 'provider_company_profile', 'save_company_category',
    v_old_profile,
    jsonb_build_object('category_slug', p_category_slug,
      'services', to_jsonb(v_services), 'roles', to_jsonb(v_roles),
      'service_count', cardinality(v_services), 'role_count', cardinality(v_roles)));
end;
$$;

revoke all on function private.save_company_category_internal(text, text[], text[], jsonb, jsonb)
  from public, anon;
grant execute on function private.save_company_category_internal(text, text[], text[], jsonb, jsonb)
  to authenticated;

commit;

-- ============================================================================
-- END MERGED SECTION (48/52): patch_save_company_category_identity_conflict.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (49/52): patch_provider_approval_notifications_and_all_required.sql
-- ============================================================================

-- Require ALL required evidence items to be approved before activating a
-- required-proof provider capability, and send instant in-app notifications
-- when capability evidence, company verification documents, or role
-- qualifications are approved.
-- Apply after patch_financial_services_provider_capabilities.sql,
-- patch_provider_capability_evidence_security.sql,
-- patch_provider_profile_documents.sql, and patch_catalog_expansion_v3.sql.
begin;

-- 0. Helper: a Company is verified once BOTH its business registration and
--    business licence/authorization documents have been approved.
create or replace function private.has_approved_company_verification(p_user_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public, private, pg_temp
as $$
  select exists (
    select 1 from public.provider_company_verification_submissions s
    where s.user_id = p_user_id
      and s.document_type = 'business_registration'
      and s.status = 'approved'
  ) and exists (
    select 1 from public.provider_company_verification_submissions s
    where s.user_id = p_user_id
      and s.document_type = 'business_licence'
      and s.status = 'approved'
  );
$$;
revoke all on function private.has_approved_company_verification(uuid) from public, anon;
grant execute on function private.has_approved_company_verification(uuid) to authenticated;

-- 1. Enforce all-required-evidence activation in the capability policy trigger.
--    For Company providers, once both Business Registration and Business Licence
--    are approved, all Company capabilities/offers activate automatically.
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
  v_company_verified boolean := false;
begin
  select category_slug, verification_policy, capability_type
    into v_category, v_policy, v_type
    from public.need_capabilities where slug = new.capability_slug;
  if not found then
    raise exception 'Provider capability is unavailable.' using errcode = 'P0203';
  end if;

  select coalesce(new.identity_type, pcp.provider_type, 'both') into v_type
  from (select 1) seed
  left join public.provider_category_profiles pcp
    on pcp.user_id = new.user_id and pcp.category_slug = v_category;

  v_company_verified := (v_type = 'company')
    and private.has_approved_company_verification(new.user_id);

  if v_company_verified then
    new.verification_level := 'provider_verified';
    new.verified_at := coalesce(new.verified_at, now());
    new.is_active := true;
    return new;
  end if;

  if v_category = 'financial_services' and v_policy = 'required_proof' then
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

-- 1b. Update provider_capability_is_eligible so v_my_capability_policy_status
--     also treats approved Companies as eligible across all selected services.
create or replace function private.provider_capability_is_eligible(p_capability_id uuid)
returns boolean language plpgsql security definer stable
set search_path = public, private, pg_catalog as $$
declare
  v_user uuid;
  v_slug text;
  v_policy text;
  v_type text := 'both';
  v_rule_type text := 'both';
  v_active boolean;
  v_role_active boolean;
  v_has_requirements boolean := false;
  v_key text;
begin
  select pc.user_id, pc.capability_slug, nc.verification_policy, pc.is_active,
         coalesce(pc.metadata->>'is_role_active' <> 'false', true),
         coalesce(pc.identity_type, pcp.provider_type, 'both')
    into v_user, v_slug, v_policy, v_active, v_role_active, v_type
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  left join public.provider_category_profiles pcp
    on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
  where pc.id = p_capability_id;
  if not found or not v_active or not v_role_active then return false; end if;
  if v_policy <> 'required_proof' then return true; end if;
  if v_type = 'company' and private.has_approved_company_verification(v_user) then
    return true;
  end if;

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
         pc.identity_type as capability_identity_type,
         nc.category_slug, nc.name as capability_name,
         pcp.provider_type as category_provider_type
    into v_evidence
    from public.provider_capability_evidence e
    join public.provider_capabilities pc on pc.id = e.provider_capability_id
    join public.need_capabilities nc on nc.slug = pc.capability_slug
    left join public.provider_category_profiles pcp
      on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
    where e.id = p_evidence_id for update of e;
  if not found then
    raise exception 'Provider capability evidence not found.' using errcode = 'P0212';
  end if;

  v_provider_type := coalesce(
    nullif(v_evidence.provider_type, 'both'),
    v_evidence.capability_identity_type,
    v_evidence.category_provider_type,
    'both'
  );
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
  elsif p_action = 'reject' then
    insert into public.notifications(user_id, type, title, body, data)
    values (
      v_evidence.provider_user_id,
      'system',
      'Verification document rejected',
      'A document for ' || v_cap_name || ' was rejected' ||
        case when nullif(btrim(p_reject_reason), '') is not null
          then ': ' || left(btrim(p_reject_reason), 180)
          else '.' end,
      jsonb_build_object(
        'kind', 'provider_capability_rejected',
        'capability_slug', v_evidence.capability_slug,
        'category_slug', v_evidence.category_slug,
        'requirement_key', v_evidence.requirement_key,
        'reject_reason', p_reject_reason
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

  v_doc_label := case v_row.document_type
    when 'business_registration' then 'Business registration certificate'
    when 'business_licence' then 'Licences or authorization documents'
    else 'Company verification document'
  end;

  if p_action = 'approve' then
    v_all_approved := private.has_approved_company_verification(v_row.user_id);
    if v_all_approved then
      update public.provider_capabilities pc
        set verification_level = 'provider_verified',
            verified_by = v_admin,
            verified_at = coalesce(pc.verified_at, now()),
            is_active = true
        where pc.user_id = v_row.user_id
          and pc.identity_type = 'company';
    end if;
    insert into public.notifications(user_id, type, title, body, data)
    values (
      v_row.user_id,
      'system',
      case when v_all_approved then 'Company verification approved'
           else 'Company document approved' end,
      case when v_all_approved then
        v_doc_label || ' approved. All your company services are now active.'
      else
        v_doc_label || ' was approved. Approve both registration and licence to activate all company services.'
      end,
      jsonb_build_object(
        'kind', 'provider_company_document_approved',
        'category_slug', v_row.category_slug,
        'document_type', v_row.document_type,
        'submission_id', v_row.id,
        'all_approved', v_all_approved
      )
    );
  elsif p_action = 'reject' then
    if not private.has_approved_company_verification(v_row.user_id) then
      update public.provider_capabilities pc
        set verification_level = 'self_declared',
            verified_by = null,
            verified_at = null
        from public.need_capabilities nc
        where nc.slug = pc.capability_slug
          and nc.verification_policy = 'required_proof'
          and pc.user_id = v_row.user_id
          and pc.identity_type = 'company';
    end if;
    insert into public.notifications(user_id, type, title, body, data)
    values (
      v_row.user_id,
      'system',
      'Company document rejected',
      v_doc_label || ' was rejected' ||
        case when nullif(btrim(v_row.reject_reason), '') is not null
          then ': ' || left(btrim(v_row.reject_reason), 180)
          else '.' end,
      jsonb_build_object(
        'kind', 'provider_company_document_rejected',
        'category_slug', v_row.category_slug,
        'document_type', v_row.document_type,
        'submission_id', v_row.id,
        'reject_reason', v_row.reject_reason
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
  elsif p_action = 'reject' then
    insert into public.notifications(user_id, type, title, body, data)
    values (
      v_claim.user_id,
      'system',
      'Role qualification rejected',
      'Your qualification for ' || coalesce(nullif(btrim(v_claim.capability_name), ''), v_claim.capability_slug) || ' was rejected' ||
        case when nullif(btrim(p_reject_reason), '') is not null
          then ': ' || left(btrim(p_reject_reason), 180)
          else '.' end,
      jsonb_build_object(
        'kind', 'provider_role_qualification_rejected',
        'capability_slug', v_claim.capability_slug,
        'role_slug', v_claim.role_slug,
        'qualification_slug', v_claim.qualification_slug,
        'claim_id', p_claim_id,
        'reject_reason', p_reject_reason
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

do $$
begin
  alter publication supabase_realtime add table public.provider_capabilities;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.provider_company_verification_submissions;
exception
  when duplicate_object or undefined_object then null;
end $$;

-- Re-evaluate existing required_proof capabilities that already have all
-- required evidence approved (or belong to an approved Company) so they
-- activate immediately.
update public.provider_capabilities pc
set verification_level = 'provider_verified',
    verified_at = coalesce(pc.verified_at, now())
from public.need_capabilities nc
where nc.slug = pc.capability_slug
  and nc.verification_policy = 'required_proof'
  and pc.verification_level <> 'provider_verified'
  and (
    (pc.identity_type = 'company' and private.has_approved_company_verification(pc.user_id))
    or exists (
      select 1 from public.provider_capability_evidence e
      where e.provider_capability_id = pc.id
        and e.status = 'approved'
        and (e.expires_at is null or e.expires_at > now())
    )
  );

update public.provider_capabilities pc
set is_active = pc.is_active
from public.need_capabilities nc
where nc.slug = pc.capability_slug
  and nc.verification_policy = 'required_proof';

commit;

-- ============================================================================
-- END MERGED SECTION (49/52): patch_provider_approval_notifications_and_all_required.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (50/52): patch_company_capability_activation_fix.sql
-- ============================================================================

-- Fix company provider capability activation.
--
-- Root causes fixed by this patch:
--  1. provider_capability_is_eligible() returned false immediately when
--     is_active=false, so company-verified rows were never re-evaluated.
--  2. The backfill in the previous patch set is_active = pc.is_active (no-op)
--     instead of is_active = true for company-verified rows.
--  3. admin_review_provider_company_document() correctly sets is_active=true on
--     approval, but existing rows approved before the patch were never updated.
--
-- Apply AFTER patch_provider_approval_notifications_and_all_required.sql.
-- Safe to re-apply (idempotent via create or replace + explicit updates).

begin;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Fix provider_capability_is_eligible so it evaluates company verification
--    BEFORE checking is_active.  A company whose docs are both approved should
--    always be considered eligible regardless of the stored is_active flag.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function private.provider_capability_is_eligible(p_capability_id uuid)
returns boolean language plpgsql security definer stable
set search_path = public, private, pg_catalog as $$
declare
  v_user         uuid;
  v_slug         text;
  v_policy       text;
  v_type         text := 'both';
  v_rule_type    text := 'both';
  v_active       boolean;
  v_role_active  boolean;
  v_has_req      boolean := false;
  v_key          text;
begin
  select pc.user_id, pc.capability_slug, nc.verification_policy, pc.is_active,
         coalesce(pc.metadata->>'is_role_active' <> 'false', true),
         coalesce(pc.identity_type, pcp.provider_type, 'both')
    into v_user, v_slug, v_policy, v_active, v_role_active, v_type
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug = pc.capability_slug
  left join public.provider_category_profiles pcp
    on pcp.user_id = pc.user_id and pcp.category_slug = nc.category_slug
  where pc.id = p_capability_id;

  if not found then return false; end if;

  -- Company providers with both docs approved are always eligible —
  -- check this BEFORE the is_active gate so stale flags don't block them.
  if v_type = 'company' and private.has_approved_company_verification(v_user) then
    return true;
  end if;

  -- For all other cases, respect the stored active flag.
  if not v_active or not v_role_active then return false; end if;
  if v_policy <> 'required_proof' then return true; end if;

  -- Capability-scoped requirements
  if exists (
    select 1 from public.verification_requirements r
    where r.scope_type = 'capability' and r.scope_id = v_slug
      and r.provider_type = v_type and r.is_active
  ) then
    v_rule_type := v_type;
  end if;

  for v_key in
    select distinct keys.value from (
      select unnest(coalesce(r.required_evidence, array[]::text[])) as value
      from public.verification_requirements r
      where r.scope_type = 'capability' and r.scope_id = v_slug
        and r.provider_type = v_rule_type and r.is_active
      union
      select jsonb_array_elements_text(
        case when jsonb_typeof(r.evidence_requirements) = 'array'
             then r.evidence_requirements else '[]'::jsonb end)
      from public.verification_requirements r
      where r.scope_type = 'capability' and r.scope_id = v_slug
        and r.provider_type = v_rule_type and r.is_active
    ) keys
  loop
    v_has_req := true;
    if not exists (
      select 1 from public.provider_capability_evidence e
      where e.provider_capability_id = p_capability_id
        and e.requirement_key = v_key and e.status = 'approved'
        and (e.expires_at is null or e.expires_at > now())
    ) then
      return false;
    end if;
  end loop;

  return v_has_req and exists (
    select 1 from public.provider_capabilities pc
    where pc.id = p_capability_id and pc.verification_level = 'provider_verified'
  );
end;
$$;
revoke all on function private.provider_capability_is_eligible(uuid) from public;
grant execute on function private.provider_capability_is_eligible(uuid)
  to authenticated, anon;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Backfill: activate ALL company provider_capabilities for every user whose
--    has_approved_company_verification() returns true.
--    This fixes rows that were created before the approval patch ran.
-- ─────────────────────────────────────────────────────────────────────────────
update public.provider_capabilities pc
set verification_level = 'provider_verified',
    verified_at        = coalesce(pc.verified_at, now()),
    is_active          = true
where pc.identity_type = 'company'
  and private.has_approved_company_verification(pc.user_id)
  and (pc.is_active = false or pc.verification_level <> 'provider_verified');

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Diagnostic: show the rows just updated (runs inside the transaction so
--    you can verify before commit — the result is visible in the SQL editor).
-- ─────────────────────────────────────────────────────────────────────────────
select
  pc.id,
  p.full_name,
  pc.capability_slug,
  pc.identity_type,
  pc.verification_level,
  pc.is_active,
  private.has_approved_company_verification(pc.user_id) as company_verified
from public.provider_capabilities pc
join public.profiles p on p.id = pc.user_id
where pc.identity_type = 'company'
  and private.has_approved_company_verification(pc.user_id)
order by p.full_name, pc.capability_slug;

commit;

-- ============================================================================
-- END MERGED SECTION (50/52): patch_company_capability_activation_fix.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (51/52): patch_financial_provider_service_groups.sql
-- ============================================================================

-- Align Loans & Financing provider selection with the four supported
-- top-level services. Capability slugs and provider records remain unchanged.
BEGIN;

UPDATE public.need_capabilities
SET service_group_slug = 'personal_financing',
    service_group_name = 'Personal Loans',
    service_sort_order = CASE
      WHEN slug IN ('personal_loan_services', 'emergency_loan_services',
                    'salary_loan_services', 'medical_financing') THEN service_sort_order
      ELSE 50 + service_sort_order
    END
WHERE category_slug = 'financial_services'
  AND service_group_slug IN (
    'personal_financing',
    'agricultural_financing',
    'education_financing',
    'lifestyle_financing'
  );

UPDATE public.need_capabilities
SET service_group_name = 'Business Financing'
WHERE category_slug = 'financial_services'
  AND service_group_slug = 'business_financing';

UPDATE public.need_capabilities
SET service_group_name = 'Asset Financing'
WHERE category_slug = 'financial_services'
  AND service_group_slug = 'asset_financing';

UPDATE public.need_capabilities
SET service_group_name = 'Property Financing'
WHERE category_slug = 'financial_services'
  AND service_group_slug = 'property_financing';

COMMIT;

-- ============================================================================
-- END MERGED SECTION (51/52): patch_financial_provider_service_groups.sql
-- ============================================================================


-- ============================================================================
-- BEGIN MERGED SECTION (52/52): patch_pets_animal_services.sql
-- ============================================================================

-- Pets & Animal Services provider category and role catalogue.
-- Apply after provider service/work-profile catalogue patches. Safe to rerun.
-- Existing Veterinary / Livestock Officer role and capability slugs are kept;
-- moving their catalogue category preserves provider capability rows and offers.
begin;

do $$
begin
  if to_regclass('public.need_categories') is null
     or to_regclass('public.need_capabilities') is null
     or to_regclass('public.capability_roles') is null
     or to_regclass('public.role_kinds') is null
     or to_regclass('public.role_qualifications') is null then
    raise exception 'Apply provider services and work-profile catalogue patches first.';
  end if;
end;
$$;

alter table public.role_qualifications
  add column if not exists is_required_proof boolean not null default false;
alter table public.need_categories
  add column if not exists description text;
alter table public.need_capabilities
  add column if not exists capability_type text not null default 'service',
  add column if not exists ui_group_slug text,
  add column if not exists sort_order integer not null default 1000,
  add column if not exists service_group_slug text,
  add column if not exists service_group_name text,
  add column if not exists service_sort_order integer not null default 1000,
  add column if not exists verification_policy text not null default 'open';

insert into public.need_categories
  (slug, name, icon, sort_order, description, is_active)
values
  ('pets_animal_services', 'Pets & Animal Services', '🐾', 24,
   'Veterinary care, pet training, grooming, boarding and animal care.', true)
on conflict (slug) do update set
  name = excluded.name, icon = excluded.icon,
  description = excluded.description, is_active = true;

insert into public.need_capabilities
  (slug, category_slug, name, is_active, ui_group_slug, sort_order,
   service_group_slug, service_group_name, service_sort_order,
   capability_type, verification_policy)
values
  ('animal_veterinary_care','pets_animal_services','Veterinary care',true,'pets_animal_services',1,'clinical_care','Clinical care',10,'service','open'),
  ('animal_herd_health','pets_animal_services','Livestock herd health and vaccination',true,'pets_animal_services',2,'clinical_care','Clinical care',20,'service','open'),
  ('pet_training_behaviour','pets_animal_services','Pet training and behaviour support',true,'pets_animal_services',3,'pet_care','Pet care',10,'service','open'),
  ('pet_grooming','pets_animal_services','Pet grooming',true,'pets_animal_services',4,'pet_care','Pet care',20,'service','open'),
  ('pet_sitting','pets_animal_services','In-home pet sitting and visits',true,'pets_animal_services',5,'pet_care','Pet care',30,'service','open'),
  ('pet_boarding','pets_animal_services','Pet boarding',true,'pets_animal_services',6,'pet_care','Pet care',40,'service','open'),
  ('dog_walking','pets_animal_services','Dog walking',true,'pets_animal_services',7,'pet_care','Pet care',50,'service','open'),
  ('animal_transport','pets_animal_services','Animal transport',true,'pets_animal_services',8,'animal_services','Animal services',10,'service','open'),
  ('animal_breeding','pets_animal_services','Responsible animal breeding',true,'pets_animal_services',9,'animal_services','Animal services',20,'service','open'),
  ('animal_nutrition_advice','pets_animal_services','Animal nutrition advice',true,'pets_animal_services',10,'animal_services','Animal services',30,'service','open'),
  ('work_veterinarian','pets_animal_services','Veterinarian (clinical care)',true,'pets_animal_services',10,'work_roles','Work Roles',10,'work','required_proof'),
  ('work_veterinary_assistant','pets_animal_services','Veterinary Assistant',true,'pets_animal_services',20,'work_roles','Work Roles',20,'work','optional_proof'),
  ('work_pet_trainer_behaviour_specialist','pets_animal_services','Pet Trainer / Behaviour Specialist',true,'pets_animal_services',30,'work_roles','Work Roles',30,'work','optional_proof'),
  ('work_pet_groomer','pets_animal_services','Pet Groomer',true,'pets_animal_services',50,'work_roles','Work Roles',50,'work','open'),
  ('work_pet_sitter','pets_animal_services','Pet Sitter',true,'pets_animal_services',60,'work_roles','Work Roles',60,'work','open'),
  ('work_pet_boarding_provider','pets_animal_services','Pet Boarding Provider',true,'pets_animal_services',70,'work_roles','Work Roles',70,'work','optional_proof'),
  ('work_dog_walker','pets_animal_services','Dog Walker',true,'pets_animal_services',80,'work_roles','Work Roles',80,'work','open'),
  ('work_animal_transport_provider','pets_animal_services','Animal Transport Provider',true,'pets_animal_services',90,'work_roles','Work Roles',90,'work','open'),
  ('work_animal_breeder','pets_animal_services','Animal Breeder',true,'pets_animal_services',100,'work_roles','Work Roles',100,'work','optional_proof'),
  ('work_animal_nutritionist','pets_animal_services','Animal Nutritionist',true,'pets_animal_services',110,'work_roles','Work Roles',110,'work','optional_proof')
on conflict (slug) do update set
  category_slug=excluded.category_slug, name=excluded.name, is_active=true,
  ui_group_slug=excluded.ui_group_slug, sort_order=excluded.sort_order,
  service_group_slug=excluded.service_group_slug,
  service_group_name=excluded.service_group_name,
  service_sort_order=excluded.service_sort_order,
  capability_type=excluded.capability_type,
  verification_policy=excluded.verification_policy;

-- Preserve old provider_capabilities and saved role metadata under the same
-- identifiers, while exposing the legacy role only in the new category.
update public.need_capabilities
set category_slug='pets_animal_services', ui_group_slug='pets_animal_services',
    sort_order=15, service_group_slug='work_roles',
    service_group_name='Work Roles', service_sort_order=15, is_active=true
where slug='work_veterinary_livestock_officer';

-- Dog training is already covered by Pet Trainer / Behaviour Specialist,
-- whose animal-kind selector includes dogs. Retire the duplicate catalog
-- entry without deleting its capability or any providers' saved records.
update public.need_capabilities
set is_active=false
where slug='work_dog_trainer';

insert into public.capability_roles
  (slug, category_slug, capability_slug, name, kind_question, is_active)
values
  ('veterinarian','pets_animal_services','work_veterinarian','Veterinarian (clinical care)','What animals do you treat?',true),
  ('veterinary_assistant','pets_animal_services','work_veterinary_assistant','Veterinary Assistant','Which animals can you assist with?',true),
  ('pet_trainer_behaviour_specialist','pets_animal_services','work_pet_trainer_behaviour_specialist','Pet Trainer / Behaviour Specialist','Which animals do you train?',true),
  ('pet_groomer','pets_animal_services','work_pet_groomer','Pet Groomer','Which animals do you groom?',true),
  ('pet_sitter','pets_animal_services','work_pet_sitter','Pet Sitter','Which animals do you care for?',true),
  ('pet_boarding_provider','pets_animal_services','work_pet_boarding_provider','Pet Boarding Provider','Which animals can you accommodate?',true),
  ('dog_walker','pets_animal_services','work_dog_walker','Dog Walker','Which dogs do you walk?',true),
  ('animal_transport_provider','pets_animal_services','work_animal_transport_provider','Animal Transport Provider','What animals can you transport?',true),
  ('animal_breeder','pets_animal_services','work_animal_breeder','Animal Breeder','Which animals do you breed?',true),
  ('animal_nutritionist','pets_animal_services','work_animal_nutritionist','Animal Nutritionist','Which animals do you advise on?',true)
on conflict (slug) do update set
  category_slug=excluded.category_slug, capability_slug=excluded.capability_slug,
  name=excluded.name, kind_question=excluded.kind_question, is_active=true;

update public.capability_roles
set is_active=false
where slug='dog_trainer';

update public.capability_roles
set category_slug='pets_animal_services',
    name='Livestock Officer (herd health)',
    kind_question='Which livestock do you support with herd health and vaccination?', is_active=true
where slug='veterinary_livestock_officer';

insert into public.role_kinds (role_slug, slug, name, sort_order)
select roles.slug, kinds.slug, kinds.name, kinds.sort_order
from (values
  ('veterinarian'),('veterinary_assistant'),('pet_trainer_behaviour_specialist'),
  ('pet_groomer'),('pet_sitter'),('pet_boarding_provider'),
  ('dog_walker'),('animal_transport_provider'),('animal_breeder'),('animal_nutritionist'),
  ('veterinary_livestock_officer')
) roles(slug)
cross join (values
  ('dogs','Dogs',10),('cats','Cats',20),('cattle','Cattle',30),
  ('poultry','Poultry',40),('goats','Goats',50),('sheep','Sheep',60),
  ('rabbits','Rabbits',70),('horses','Horses',80),('other_animals','Other animals',90)
) kinds(slug,name,sort_order)
where (roles.slug in ('veterinarian','veterinary_assistant','animal_breeder','animal_nutritionist')
       or (roles.slug='veterinary_livestock_officer' and kinds.slug in ('cattle','poultry','goats','sheep','rabbits','horses','other_animals'))
       or (roles.slug in ('pet_trainer_behaviour_specialist','pet_groomer') and kinds.slug in ('dogs','cats','other_animals'))
       or (roles.slug in ('pet_sitter','pet_boarding_provider') and kinds.slug in ('dogs','cats','rabbits','other_animals'))
       or (roles.slug='dog_trainer' and kinds.slug='dogs')
       or (roles.slug='dog_walker' and kinds.slug='dogs')
       or (roles.slug='animal_transport_provider' and kinds.slug in ('dogs','cats','cattle','poultry','goats','sheep','horses','other_animals')))
on conflict (role_slug,slug) do update set
  name=excluded.name, sort_order=excluded.sort_order;

delete from public.role_kinds
where role_slug='veterinary_livestock_officer'
  and slug in ('dogs','cats');

insert into public.role_qualifications
  (role_slug,slug,name,is_evidence,is_required_proof,sort_order)
values
  ('veterinarian','veterinary_licence','Veterinary professional registration and authorization',true,true,10),
  ('veterinary_assistant','animal_care_qualification','Animal care qualification',true,false,10),
  ('veterinary_assistant','animal_care_experience','Animal care experience',false,false,20),
  ('pet_trainer_behaviour_specialist','training_qualification','Training qualification',true,false,10),
  ('pet_trainer_behaviour_specialist','training_references','Client references',true,false,20),
  ('pet_trainer_behaviour_specialist','training_experience','Training experience',false,false,30),
  ('dog_trainer','training_qualification','Training qualification',true,false,10),
  ('dog_trainer','training_references','Client references',true,false,20),
  ('dog_trainer','training_experience','Training experience',false,false,30),
  ('pet_boarding_provider','boarding_facility','Boarding facility information',true,false,10),
  ('pet_boarding_provider','animal_welfare_practices','Animal welfare practices',true,false,20),
  ('animal_breeder','breeding_welfare_practices','Breeding and animal welfare practices',true,false,10),
  ('animal_breeder','breeding_authorization','Applicable breeder authorization',true,false,20)
on conflict (role_slug,slug) do update set
  name=excluded.name, is_evidence=excluded.is_evidence,
  is_required_proof=excluded.is_required_proof, sort_order=excluded.sort_order;

-- Retain and extend legacy evidence choices; veterinarian's licence remains a
-- required proof. Optional evidence supports role-specific review in the
-- existing admin verification workflow.
update public.role_qualifications
set is_evidence=true, is_required_proof=false
where role_slug='veterinary_livestock_officer'
  and slug in ('veterinary_licence','vaccination_certification');
update public.role_qualifications
set is_required_proof=true, is_evidence=true
where role_slug='veterinarian' and slug='veterinary_licence';

insert into public.system_settings
  (setting_key,country,setting_value,setting_type,category,description,is_public)
values
  ('work_profiles_enabled_pets_animal_services',null,'true','boolean','provider',
   'Enables role registration for Pets & Animal Services when work profiles are enabled.',true)
on conflict (setting_key,coalesce(country,'__global__')) do update set
  setting_value=excluded.setting_value, setting_type=excluded.setting_type,
  category=excluded.category, description=excluded.description,
  is_public=excluded.is_public, updated_at=now();

-- Match animal requests to the selected work role and declared animal kinds.
-- The existing needs/offer pipeline remains in place; this narrows opportunity
-- notifications and validates offers when an animal_type is supplied.
create or replace function private.pet_animal_kind_slug(p_value text)
returns text
language sql
immutable
as $$
  select case when nullif(btrim(coalesce(p_value,'')),'') is null then null else
    case lower(regexp_replace(btrim(p_value), '\s+', '_', 'g'))
      when 'dog' then 'dogs' when 'dogs' then 'dogs'
      when 'cat' then 'cats' when 'cats' then 'cats'
      when 'cow' then 'cattle' when 'cattle' then 'cattle'
      when 'chicken' then 'poultry' when 'poultry' then 'poultry'
      when 'goat' then 'goats' when 'goats' then 'goats'
      when 'sheep' then 'sheep' when 'rabbit' then 'rabbits'
      when 'rabbits' then 'rabbits' when 'horse' then 'horses'
      when 'horses' then 'horses' when 'other_animals' then 'other_animals'
      else 'other_animals'
    end
  end;
$$;

create or replace function private.trg_notify_matching_providers_on_need_request()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_provider_id uuid;
  v_animal_kind text := private.pet_animal_kind_slug(new.details->>'animal_type');
begin
  for v_provider_id in
    select distinct pc.user_id
    from public.provider_capabilities pc
    join public.need_capabilities nc on nc.slug=pc.capability_slug
    where (
      (new.capability_slug is not null and pc.capability_slug=new.capability_slug)
      or (new.capability_slug is null and nc.category_slug=new.category_slug)
    )
    and pc.user_id <> new.requester_id
    and (
      new.category_slug <> 'pets_animal_services'
      or v_animal_kind is null
      or private.jsonb_text_array(pc.metadata->'kind_ids') @> array[v_animal_kind]
      or (v_animal_kind in ('goats','sheep') and
          private.jsonb_text_array(pc.metadata->'kind_ids') @> array['small_ruminants'])
      or exists (
        select 1
        from jsonb_array_elements(
          case when jsonb_typeof(pc.metadata->'roles')='array'
            then pc.metadata->'roles' else '[]'::jsonb end
        ) role_data
        where private.jsonb_text_array(role_data->'kind_ids') @> array[v_animal_kind]
           or (v_animal_kind in ('goats','sheep') and
               private.jsonb_text_array(role_data->'kind_ids') @> array['small_ruminants'])
      )
    )
  loop
    insert into public.notifications
      (user_id,type,title,body,data,is_read,created_at)
    values
      (v_provider_id,'new_opportunity','New Opportunity',
       coalesce(new.title,'New opportunity'),
       jsonb_build_object('need_id',new.request_id,'category_slug',new.category_slug,
                          'capability_slug',new.capability_slug),false,now());
  end loop;
  return new;
end;
$$;

create or replace function private.capability_match_score(
  p_need_details jsonb,
  p_provider_metadata jsonb
)
returns integer
language plpgsql
immutable
as $$
declare
  v_role_id text := nullif(btrim(coalesce(p_need_details->>'role_id','')), '');
  v_need_kinds text[] := private.jsonb_text_array(p_need_details->'kind_ids');
  v_animal_kind text := private.pet_animal_kind_slug(p_need_details->>'animal_type');
  v_required_quals text[] := private.jsonb_text_array(p_need_details->'required_qualification_ids');
  v_role jsonb;
  v_role_kinds text[];
  v_role_quals text[];
  v_matched_quals integer := 0;
  v_total_quals integer := coalesce(array_length(v_required_quals,1),0);
begin
  if coalesce(p_need_details->>'engagement','') <> 'hire_person'
     and v_animal_kind is null then return 100; end if;
  -- Work capability saves store one role directly in metadata; support the
  -- nested roles representation used by older profiles as well.
  if p_provider_metadata ? 'role_id' then
    v_role_kinds := private.jsonb_text_array(p_provider_metadata->'kind_ids');
    v_role_quals := private.jsonb_text_array(p_provider_metadata->'qualification_ids');
    if (v_role_id is null or p_provider_metadata->>'role_id'=v_role_id)
       and (v_animal_kind is null or v_animal_kind=any(v_role_kinds)
         or (v_animal_kind in ('goats','sheep') and 'small_ruminants'=any(v_role_kinds)))
       and (coalesce(array_length(v_need_kinds,1),0)=0 or v_need_kinds && v_role_kinds) then
      if v_total_quals=0 then return 100; end if;
      select count(*)::integer into v_matched_quals from unnest(v_required_quals) q where q=any(v_role_quals);
      return round((v_matched_quals::numeric/v_total_quals::numeric)*100)::integer;
    end if;
  end if;
  for v_role in
    select jsonb_array_elements(case when jsonb_typeof(p_provider_metadata->'roles')='array'
      then p_provider_metadata->'roles' else '[]'::jsonb end)
  loop
    if v_role_id is not null and v_role->>'role_id' <> v_role_id then continue; end if;
    v_role_kinds := private.jsonb_text_array(v_role->'kind_ids');
    v_role_quals := private.jsonb_text_array(v_role->'qualification_ids');
    if v_animal_kind is not null
       and not (v_animal_kind = any(v_role_kinds)
         or (v_animal_kind in ('goats','sheep') and 'small_ruminants'=any(v_role_kinds))) then continue; end if;
    if coalesce(array_length(v_need_kinds,1),0)>0 and not (v_need_kinds && v_role_kinds) then continue; end if;
    if v_total_quals=0 then return 100; end if;
    select count(*)::integer into v_matched_quals from unnest(v_required_quals) q where q=any(v_role_quals);
    return round((v_matched_quals::numeric/v_total_quals::numeric)*100)::integer;
  end loop;
  return 0;
end;
$$;

create or replace function private.validate_pet_animal_need_offer()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_need public.needs_requests%rowtype;
  v_capability public.provider_capabilities%rowtype;
begin
  select * into v_need from public.needs_requests where request_id=new.need_id;
  if not found or v_need.category_slug <> 'pets_animal_services'
     or private.pet_animal_kind_slug(v_need.details->>'animal_type') is null then
    return new;
  end if;
  select pc.* into v_capability
  from public.provider_capabilities pc
  join public.need_capabilities nc on nc.slug=pc.capability_slug
  where pc.user_id=new.offer_maker_id
    and nc.category_slug='pets_animal_services'
    and (v_need.capability_slug is null or pc.capability_slug=v_need.capability_slug)
    and private.capability_match_score(v_need.details,coalesce(pc.metadata,'{}'::jsonb))>0
  limit 1;
  if not found then
    raise exception 'Your declared animal specialization does not match this request.'
      using errcode='P0203';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_pet_animal_need_offer on public.need_offers;
create trigger trg_validate_pet_animal_need_offer
  before insert on public.need_offers
  for each row execute function private.validate_pet_animal_need_offer();

commit;

-- ============================================================================
-- END MERGED SECTION (52/52): patch_pets_animal_services.sql
-- ============================================================================


NOTIFY pgrst, 'reload schema';
