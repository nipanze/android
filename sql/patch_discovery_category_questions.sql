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
  '[]'::jsonb,
  '{}'::jsonb,
  null,
  source.priority,
  source.cta_label,
  '/marketplace',
  true
from (values
  ('machinery_equipment', 'Need equipment?', 'Post what you need and compare offers from equipment providers.', 'business', 'business', 10, 'Browse equipment requests'),
  ('transport_logistics', 'Moving something?', 'Post the route and load, then compare offers from transport providers.', 'business', 'business', 20, 'Browse transport requests'),
  ('specialized_products', 'Looking for a specific product?', 'Describe the product and compare sourcing offers from suppliers.', 'business', 'business', 30, 'Browse product requests'),
  ('construction_building', 'Planning construction or repairs?', 'Describe the work and compare offers from contractors and tradespeople.', 'business', 'business', 40, 'Browse construction requests'),
  ('professional_services', 'Need business support?', 'Describe the help you need and compare offers from professionals.', 'business', 'business', 50, 'Browse professional requests'),
  ('travel_international', 'Planning a trip?', 'Post a travel request, then compare offers from providers who can assist.', 'travel', 'travel', 60, 'Browse travel requests'),
  ('agriculture_agribusiness', 'Need farm support?', 'Post what you need and compare responses from agricultural providers.', 'business', 'business', 70, 'Browse agriculture requests'),
  ('pets_animal_services', 'Need care for your animal?', 'Describe the care you need and compare offers from animal service providers.', 'general', 'general', 80, 'Browse animal care requests'),
  ('energy_utilities', 'Looking for energy or water help?', 'Describe the project and compare offers from energy and water providers.', 'business', 'business', 90, 'Browse energy and water requests'),
  ('technology_digital', 'Need tech support?', 'Post your project and compare offers from digital and IT specialists.', 'business', 'business', 100, 'Browse technology requests'),
  ('marketing_promotion', 'Need marketing help?', 'Describe your campaign and compare offers for content, advertising, or promotion.', 'business', 'business', 110, 'Browse marketing requests'),
  ('education_training', 'Looking for training or an internship?', 'Post what you are looking for and compare responses from education providers.', 'education', 'education_career', 120, 'Browse education requests'),
  ('events_celebrations', 'Planning an event?', 'List what you need and compare offers from event providers.', 'business', 'business', 130, 'Browse event requests'),
  ('photo_video_music_talent', 'Need creative talent?', 'Describe your project and compare offers from photographers, videographers, musicians, or performers.', 'business', 'business', 140, 'Browse creative requests'),
  ('beauty_fashion_styling', 'Thinking about a massage or beauty appointment?', 'Post what you need and compare service offers and prices from providers.', 'general', 'general', 150, 'Browse beauty requests'),
  ('domestic_household', 'Need help at home?', 'Describe the support you need and compare offers from household providers.', 'general', 'general', 160, 'Browse household requests'),
  ('health_medical', 'Looking for health services?', 'Describe the service you need and review responses from health providers.', 'general', 'general', 170, 'Browse health requests'),
  ('traditional_cultural', 'Planning a cultural event?', 'Describe what you need and review responses from cultural service providers.', 'general', 'general', 180, 'Browse cultural requests'),
  ('financial_services', 'Exploring a loan?', 'Browse loan offers or post a request for financing.', 'financial', 'financial', 190, 'Browse loan offers'),
  ('property_real_estate', 'Looking for property?', 'Describe what you are looking for and review responses from property providers.', 'general', 'general', 200, 'Browse property requests'),
  ('investment_services', 'Need investment support?', 'Review listed services or post a request to compare provider responses.', 'financial', 'financial', 210, 'Browse investment services'),
  ('investment_opportunities', 'Looking for investor connections?', 'Post what your startup needs and review responses; funding is not guaranteed.', 'financial', 'financial', 220, 'Browse investment opportunities'),
  ('forex_money_services', 'Exchanging currency or sending money?', 'Browse listed services and compare the rates and fees providers show.', 'financial', 'financial', 230, 'Browse Forex services'),
  ('savings_cooperatives', 'Interested in a SACCO or savings group?', 'Review group information or post a question to find a suitable cooperative.', 'financial', 'financial', 240, 'Browse savings groups')
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
