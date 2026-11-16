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
