begin;

-- Ensure every category referenced by the templates exists before inserting
-- templates because need_category_slug has a foreign key to this catalog.
insert into public.need_categories (slug, name, icon, sort_order, is_active)
values
  ('machinery_equipment', 'Machinery & Equipment', '🚜', 1, true),
  ('transport_logistics', 'Transport & Logistics', '🚚', 2, true),
  ('specialized_products', 'Specialized Products & Procurement', '🔎', 3, true),
  ('construction_building', 'Construction & Building', '🏗️', 4, true),
  ('professional_services', 'Business & Professional Services', '🧑‍💼', 5, true),
  ('travel_international', 'Travel & International', '✈️', 6, true),
  ('agriculture_agribusiness', 'Agriculture & Agribusiness', '🌾', 7, true),
  ('pets_animal_services', 'Pets & Animal Services', '🐾', 8, true),
  ('energy_utilities', 'Energy & Water', '⚡', 9, true),
  ('technology_digital', 'Technology & Digital', '💻', 10, true),
  ('marketing_promotion', 'Marketing & Promotion', '📢', 11, true),
  ('education_training', 'Education & Training', '🎓', 12, true),
  ('events_celebrations', 'Events & Celebrations', '🎉', 13, true),
  ('photo_video_music_talent', 'Photo, Video, Music & Talent', '🎬', 14, true),
  ('beauty_fashion_styling', 'Beauty, Fashion & Styling', '💄', 15, true),
  ('domestic_household', 'Domestic & Household', '🏠', 16, true),
  ('health_medical', 'Health & Medical', '⚕️', 17, true),
  ('traditional_cultural', 'Traditional & Cultural Services', '🪘', 18, true),
  ('financial_services', 'Finance & Investments', '💰', 19, true),
  ('property_real_estate', 'Property & Real Estate', '🏡', 20, true),
  ('investment_services', 'Investment Services', '📈', 21, true),
  ('investment_opportunities', 'Investment Opportunities', '🤝', 22, true),
  ('forex_money_services', 'Forex & Money Services', '💱', 23, true),
  ('savings_cooperatives', 'Savings & Cooperatives', '🏦', 24, true)
on conflict (slug) do nothing;

-- Replace the four broad starter questions with one guided prompt per need
-- category. Existing interaction history is retained for the old templates.
update public.discovery_question_templates
set is_active = false, updated_at = now()
where slug in (
  'travel_planning_basic',
  'internship_interest_basic',
  'business_equipment_basic',
  'financial_interest_basic'
);

insert into public.discovery_question_templates (
  slug, title, question, category, need_category_slug, plan_type,
  answer_type, options, follow_up_rules, country_codes, priority,
  cta_label, deep_link, is_active
)
select
  'category_intro_' || source.slug,
  source.title,
  source.question,
  source.category,
  source.slug,
  source.plan_type,
  'single_select',
  '[{"value":"yes","label":"Yes","save_plan":true},{"value":"later","label":"Maybe later"},{"value":"no","label":"No"}]'::jsonb,
  '{}'::jsonb,
  null,
  source.priority,
  source.cta_label,
  '/marketplace',
  true
from (values
  ('machinery_equipment', 'Request equipment for your work', 'Need a tractor, generator, or other equipment for a job? Post a request and compare offers from equipment providers.', 'business', 'business', 10, 'Browse equipment requests'),
  ('transport_logistics', 'Request a delivery or transport', 'Moving goods or need a delivery? Post the route and load, then compare offers from transport providers.', 'business', 'business', 20, 'Browse transport requests'),
  ('specialized_products', 'Request a hard-to-find product', 'Looking for a hard-to-find product? Describe what you need and compare sourcing offers from suppliers.', 'business', 'business', 30, 'Browse product requests'),
  ('construction_building', 'Request help for a building project', 'Planning a build or repair? Describe the work and compare offers from contractors and tradespeople.', 'business', 'business', 40, 'Browse construction requests'),
  ('professional_services', 'Request professional business support', 'Need legal work, accounting, HR, or consulting? Describe the support you need and compare professional offers.', 'business', 'business', 50, 'Browse professional requests'),
  ('travel_international', 'Plan a trip with Nipanze', 'Planning a trip or relocation? Post a travel request, then compare help and offers from providers who can assist.', 'travel', 'travel', 60, 'Browse travel requests'),
  ('agriculture_agribusiness', 'Request farm services or inputs', 'Need farm inputs, field services, or a buyer for produce? Post what you need and compare responses from providers.', 'business', 'business', 70, 'Browse agriculture requests'),
  ('pets_animal_services', 'Request care for your animal', 'Need a vet, grooming, training, or boarding? Post what your animal needs and compare provider offers.', 'general', 'general', 80, 'Browse animal care requests'),
  ('energy_utilities', 'Request an energy or water solution', 'Looking for solar power, backup electricity, a borehole, or water equipment? Describe the project and compare offers.', 'business', 'business', 90, 'Browse energy and water requests'),
  ('technology_digital', 'Request digital or IT expertise', 'Need a website, app, IT support, or better security? Post your project and compare offers from specialists.', 'business', 'business', 100, 'Browse technology requests'),
  ('marketing_promotion', 'Request help reaching customers', 'Want more people to discover your business? Describe the campaign and compare offers for advertising, content, or promotion.', 'business', 'business', 110, 'Browse marketing requests'),
  ('education_training', 'Request learning or career support', 'Looking for a course, tutor, internship, or professional training? Post what you are looking for and compare responses.', 'education', 'education_career', 120, 'Browse education requests'),
  ('events_celebrations', 'Request services for an event', 'Planning a wedding, party, or other event? List what you need and compare offers from event providers.', 'business', 'business', 130, 'Browse event requests'),
  ('photo_video_music_talent', 'Request creative talent', 'Need a photographer, videographer, musician, or performer? Describe your project and compare offers from creatives.', 'business', 'business', 140, 'Browse creative requests'),
  ('beauty_fashion_styling', 'Request beauty and wellness services', 'Thinking about a massage, makeup, hair, or styling appointment? Post what you need and compare provider offers and prices.', 'general', 'general', 150, 'Browse beauty requests'),
  ('domestic_household', 'Request help around the home', 'Need help at home, childcare, cooking, or household care? Describe the support you need and compare provider offers.', 'general', 'general', 160, 'Browse household requests'),
  ('health_medical', 'Request health or medical support', 'Looking for a clinic, medical provider, or specialist service? Describe the service you need and review provider responses.', 'general', 'general', 170, 'Browse health requests'),
  ('traditional_cultural', 'Request traditional or cultural services', 'Need help with a cultural ceremony or traditional service? Describe what you need and review provider responses.', 'general', 'general', 180, 'Browse cultural requests'),
  ('financial_services', 'Explore loan and finance options', 'Exploring a loan or financing option? Browse available offers and compare the terms providers list.', 'financial', 'financial', 190, 'Browse loan offers'),
  ('property_real_estate', 'Request a property or agent', 'Looking to rent, buy, lease, or find an agent? Describe what you are looking for and compare responses.', 'general', 'general', 200, 'Browse property requests'),
  ('investment_services', 'Find investment support', 'Looking for investment support? Find listed investment services and review each provider''s details.', 'financial', 'financial', 210, 'Browse investment services'),
  ('investment_opportunities', 'Explore investor connections', 'Building a startup or looking for investor connections? Find listed introductions and startup support.', 'financial', 'financial', 220, 'Browse investment opportunities'),
  ('forex_money_services', 'Compare currency and money services', 'Need to exchange currency or send money? Find listed providers and compare their stated rates and fees.', 'financial', 'financial', 230, 'Browse Forex services'),
  ('savings_cooperatives', 'Find a savings group or cooperative', 'Interested in a SACCO, savings group, or cooperative? Find groups and review their membership information.', 'financial', 'financial', 240, 'Browse savings groups')
) as source(slug, title, question, category, plan_type, priority, cta_label)
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
  is_active = excluded.is_active,
  updated_at = now();

commit;
