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
  'school_fees_financing', 'university_financing', 'education_loan_services', 'travel_financing', 'wedding_financing', 'forex_currency_exchange', 'forex_trading_training', 'money_transfer',
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
  ('money_transfer', 'financial_services', 'forex', 'Forex', 18203, 3, 'Money Transfer', 'required_proof'),
  ('sacco_services', 'financial_services', 'saccos_cooperatives', 'SACCOs & Cooperatives', 18301, 1, 'SACCOs', 'required_proof'),
  ('vsla_groups', 'financial_services', 'saccos_cooperatives', 'SACCOs & Cooperatives', 18302, 2, 'Village Savings Groups (VSLA)', 'required_proof'),
  ('cooperative_societies', 'financial_services', 'saccos_cooperatives', 'SACCOs & Cooperatives', 18303, 3, 'Cooperative Societies', 'required_proof'),
  ('group_savings_chamas', 'financial_services', 'saccos_cooperatives', 'SACCOs & Cooperatives', 18304, 4, 'Group Savings & Chamas', 'required_proof'),
  ('angel_investor_network', 'financial_services', 'investment_opportunities', 'Investment Opportunities', 18401, 1, 'Angel Investor Networks', 'required_proof'),
  ('startup_advisory', 'financial_services', 'investment_opportunities', 'Investment Opportunities', 18402, 2, 'Startup Advisory', 'optional_proof'),
  ('investor_introductions', 'financial_services', 'investment_opportunities', 'Investment Opportunities', 18403, 3, 'Investor Introductions', 'required_proof'),
  ('incubator_accelerator', 'financial_services', 'investment_opportunities', 'Investment Opportunities', 18404, 4, 'Incubators & Accelerators', 'required_proof')
) as v(slug, category_slug, group_slug, group_name, sort_order, service_sort_order, name, verification_policy) where nc.slug = v.slug;

-- Add the nine services marked new; Forex reuses its existing database slug.
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
  ('money_transfer', 'financial_services', 'Money Transfer', 'financial_services', 18203, 'forex', 'Forex', 3, 'service', 'required_proof', 'required_proof'),
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
  ('money_transfer', 'financial_services', 'Money Transfer', 'financial_services', 18203, 'forex', 'Forex', 3, 'service', 'required_proof', 'required_proof'),
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
    'forex_currency_exchange', 'forex_trading_training', 'money_transfer',
    'sacco_services', 'vsla_groups', 'cooperative_societies', 'group_savings_chamas'
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
  'forex_currency_exchange', 'forex_trading_training', 'money_transfer',
  'sacco_services', 'vsla_groups', 'cooperative_societies', 'group_savings_chamas'
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
