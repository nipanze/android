-- Seed up to 50 clearly labeled, active Needs listings for UI/chip testing.
-- Run in the Supabase SQL editor for the intended test project.
-- Adds capabilities to up to two existing identity-verified profiles. They
-- remain self-declared; this script does not grant provider approval or KYC.
-- Needs are distributed across identity-verified profiles with active-request
-- quota remaining. If capacity is below 100, fewer posts are seeded evenly
-- across the categories.
-- Re-running this script adds up to the currently available quota again.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE private.is_identity_verified(p.id)
  ) THEN
    RAISE EXCEPTION 'Seed needs require an existing identity-verified test profile; no KYC checks were bypassed.';
  END IF;
END;
$$;

-- Verified accounts are used as providers when available. Self-declared
-- capabilities are valid without provider approval. Capability slugs are
-- limited to entries in the catalog.
WITH eligible_providers AS (
  SELECT p.id, row_number() OVER (ORDER BY p.created_at, p.id) AS provider_no
  FROM public.profiles p
  WHERE private.is_identity_verified(p.id)
  ORDER BY p.created_at, p.id
  LIMIT 2
), capability_seed AS (
  SELECT * FROM (VALUES
    (1, 'excavator_hire'), (1, 'tractor_hire'), (1, 'generator_hire'),
    (1, 'heavy_haulage'), (1, 'courier_delivery'),
    (1, 'company_registration'), (1, 'accounting_tax'),
    (1, 'engineering_consulting'),
    (2, 'bulk_procurement'), (2, 'medical_supplies'),
    (2, 'electronic_hardware'), (2, 'visa_assistance'),
    (2, 'flight_tickets'), (2, 'hajj_umrah')
  ) AS rows(provider_no, slug)
)
INSERT INTO public.provider_capabilities (user_id, capability_slug, verification_level)
SELECT eligible_providers.id, capability_seed.slug, 'self_declared'
FROM eligible_providers
JOIN capability_seed USING (provider_no)
JOIN public.need_capabilities nc
  ON nc.slug = capability_seed.slug AND nc.is_active
WHERE NOT EXISTS (
  SELECT 1
  FROM public.provider_capabilities existing
  WHERE existing.user_id = eligible_providers.id
    AND existing.capability_slug = capability_seed.slug
);

WITH test_needs AS (
  SELECT * FROM (VALUES
    ('machinery_equipment', 'Excavator hire for drainage work', 'Need a 20-ton excavator with operator for a small drainage project.', 850000, 'Wakiso', 'Urgent', '{"equipment_type":"Excavator","duration_days":7,"operator_needed":true}'::jsonb),
    ('machinery_equipment', 'Tractor hire for maize field', 'Looking for a tractor and plough to prepare about five acres.', 420000, 'Mityana', 'Within 30 days', '{"equipment_type":"Tractor","duration_days":3,"operator_needed":true}'::jsonb),
    ('machinery_equipment', 'Backup generator for shop', 'Need a quiet generator suitable for a retail shop and freezer.', 1800000, 'Kampala', 'This month', '{"equipment_type":"Generator","duration_days":30}'::jsonb),
    ('machinery_equipment', 'Concrete mixer for house build', 'Seeking a concrete mixer for a residential construction site.', 250000, 'Mukono', 'Within 30 days', '{"equipment_type":"Concrete mixer","duration_days":10}'::jsonb),
    ('machinery_equipment', 'Forklift rental for warehouse', 'Need a 3-ton forklift for unloading stock during a warehouse move.', 600000, 'Kampala', 'This month', '{"equipment_type":"Forklift","duration_days":4}'::jsonb),
    ('machinery_equipment', 'Water pump for irrigation', 'Looking for a diesel water pump for a vegetable farm.', 320000, 'Luweero', 'Flexible', '{"equipment_type":"Water pump","duration_days":14}'::jsonb),
    ('machinery_equipment', 'Backhoe loader for trenching', 'Need a backhoe loader to dig utility trenches on a building site.', 950000, 'Entebbe', 'Within 30 days', '{"equipment_type":"Backhoe loader","duration_days":5}'::jsonb),
    ('machinery_equipment', 'Thresher for rice harvest', 'Seeking a rice thresher for a small cooperative harvest.', 500000, 'Bugiri', 'Urgent', '{"equipment_type":"Rice thresher","duration_days":6}'::jsonb),
    ('machinery_equipment', 'Scaffolding set for painting', 'Need safe scaffolding for exterior painting of a two-storey building.', 280000, 'Jinja', 'This month', '{"equipment_type":"Scaffolding","duration_days":12}'::jsonb),
    ('machinery_equipment', 'Cold room equipment rental', 'Looking for temporary cold storage equipment for a produce collection point.', 1200000, 'Mbale', 'Within 30 days', '{"equipment_type":"Cold room","duration_days":14}'::jsonb),
    ('transport_logistics', 'Truck to move cement bags', 'Need a covered truck to move cement from Kampala to a construction site.', 380000, 'Kampala', 'Urgent', '{"load_type":"Building materials","distance_km":45}'::jsonb),
    ('transport_logistics', 'Refrigerated delivery for produce', 'Seeking cold-chain transport for fresh vegetables to local shops.', 450000, 'Mbarara', 'Within 30 days', '{"load_type":"Fresh produce","distance_km":30}'::jsonb),
    ('transport_logistics', 'Courier delivery for online shop', 'Need reliable same-day parcel delivery within Kampala.', 150000, 'Kampala', 'This month', '{"load_type":"Parcels","distance_km":20}'::jsonb),
    ('transport_logistics', 'Furniture moving van', 'Looking for a van and helpers to move household furniture.', 220000, 'Mukono', 'Flexible', '{"load_type":"Furniture","distance_km":25}'::jsonb),
    ('transport_logistics', 'Bulk sand haulage', 'Need several trips of clean sand delivered to a building site.', 700000, 'Wakiso', 'Within 30 days', '{"load_type":"Sand","distance_km":35}'::jsonb),
    ('transport_logistics', 'School event bus hire', 'Seeking a 30-seater bus for a supervised school outing.', 500000, 'Kampala', 'This month', '{"load_type":"Passengers","distance_km":80}'::jsonb),
    ('transport_logistics', 'Motorcycle courier for documents', 'Need a boda courier for urgent document deliveries around town.', 60000, 'Gulu', 'Urgent', '{"load_type":"Documents","distance_km":15}'::jsonb),
    ('transport_logistics', 'Livestock transport to market', 'Looking for suitable livestock transport with careful handling.', 350000, 'Soroti', 'Within 30 days', '{"load_type":"Livestock","distance_km":60}'::jsonb),
    ('transport_logistics', 'Pickup truck for farm supplies', 'Need a pickup to collect seed and fertilizer from town.', 180000, 'Masaka', 'Flexible', '{"load_type":"Farm supplies","distance_km":40}'::jsonb),
    ('transport_logistics', 'Water tank delivery', 'Seeking transport for a 5,000 litre water tank to a rural home.', 260000, 'Luwero', 'This month', '{"load_type":"Water tank","distance_km":55}'::jsonb),
    ('professional_services', 'Bookkeeping support for small business', 'Need monthly bookkeeping and a simple income and expense report.', 300000, 'Kampala', 'Within 30 days', '{"service_needed":"Bookkeeping","duration":"Monthly"}'::jsonb),
    ('professional_services', 'Company registration guidance', 'Looking for help preparing and submitting a small company registration.', 250000, 'Kampala', 'This month', '{"service_needed":"Company registration"}'::jsonb),
    ('professional_services', 'Tax return preparation', 'Need an accountant to prepare a small business tax return.', 400000, 'Mbarara', 'Urgent', '{"service_needed":"Tax advisory"}'::jsonb),
    ('professional_services', 'Architectural plan review', 'Seeking a qualified architect to review house plans before construction.', 500000, 'Jinja', 'Within 30 days', '{"service_needed":"Architecture"}'::jsonb),
    ('professional_services', 'Website setup for local cafe', 'Need a simple mobile-friendly website with menu and contact details.', 900000, 'Kampala', 'Flexible', '{"service_needed":"Web development"}'::jsonb),
    ('professional_services', 'Employment contract review', 'Looking for a legal professional to review a draft employment contract.', 350000, 'Entebbe', 'This month', '{"service_needed":"Legal review"}'::jsonb),
    ('professional_services', 'Electrical inspection for rental units', 'Need an electrician to inspect wiring and provide a safety report.', 450000, 'Mukono', 'Within 30 days', '{"service_needed":"Electrical inspection"}'::jsonb),
    ('professional_services', 'Business logo and brand guide', 'Seeking a designer for a logo and a short brand usage guide.', 500000, 'Kampala', 'Flexible', '{"service_needed":"Graphic design"}'::jsonb),
    ('professional_services', 'Bookkeeping cleanup', 'Need help organizing six months of receipts and sales records.', 280000, 'Fort Portal', 'This month', '{"service_needed":"Bookkeeping cleanup"}'::jsonb),
    ('professional_services', 'Land survey for family plot', 'Looking for a licensed surveyor to mark plot boundaries.', 650000, 'Hoima', 'Within 30 days', '{"service_needed":"Land survey"}'::jsonb),
    ('specialized_products', 'Laptop batteries for repair shop', 'Need a batch of replacement laptop batteries for common models.', 750000, 'Kampala', 'Within 30 days', '{"item_needed":"Laptop batteries","quantity":10}'::jsonb),
    ('specialized_products', 'Laboratory glassware set', 'Seeking basic lab glassware for a secondary school science lab.', 480000, 'Iganga', 'This month', '{"item_needed":"Lab glassware","quantity":20}'::jsonb),
    ('specialized_products', 'Solar charge controllers', 'Need reliable charge controllers compatible with a small solar installation.', 600000, 'Lira', 'Flexible', '{"item_needed":"Solar controllers","quantity":5}'::jsonb),
    ('specialized_products', 'Food-grade packaging pouches', 'Looking for resealable pouches for a small roasted coffee business.', 320000, 'Kampala', 'Within 30 days', '{"item_needed":"Packaging pouches","quantity":500}'::jsonb),
    ('specialized_products', 'Water quality testing kit', 'Need a field kit for checking drinking water quality at community wells.', 900000, 'Arua', 'Urgent', '{"item_needed":"Water testing kit","quantity":2}'::jsonb),
    ('specialized_products', 'Industrial sewing machine parts', 'Seeking replacement parts for a commercial sewing machine.', 240000, 'Mbale', 'This month', '{"item_needed":"Sewing machine parts"}'::jsonb),
    ('specialized_products', 'Protective work gloves', 'Need durable gloves for a small construction crew.', 180000, 'Wakiso', 'Within 30 days', '{"item_needed":"Work gloves","quantity":30}'::jsonb),
    ('specialized_products', 'Point of sale barcode scanner', 'Looking for a USB barcode scanner compatible with a laptop POS.', 210000, 'Kampala', 'Flexible', '{"item_needed":"Barcode scanner","quantity":2}'::jsonb),
    ('specialized_products', 'Medical examination gloves', 'Need disposable examination gloves for a community clinic.', 260000, 'Mbarara', 'Urgent', '{"item_needed":"Examination gloves","quantity":20}'::jsonb),
    ('specialized_products', 'Bee keeping starter equipment', 'Seeking protective suits, smokers and hive tools for a new apiary.', 550000, 'Kiboga', 'This month', '{"item_needed":"Beekeeping equipment"}'::jsonb),
    ('travel_international', 'Visitor visa application guidance', 'Need help understanding visitor visa documents and appointment steps.', 300000, 'Kampala', 'Within 30 days', '{"travel_purpose":"Visit","destination":"United Kingdom"}'::jsonb),
    ('travel_international', 'Flight booking to Nairobi', 'Looking for flight options and booking assistance for a return trip.', 1500000, 'Entebbe', 'This month', '{"travel_purpose":"Business","destination":"Kenya"}'::jsonb),
    ('travel_international', 'Umrah group travel planning', 'Seeking a registered travel operator to explain group Umrah packages.', 2500000, 'Kampala', 'Flexible', '{"travel_purpose":"Umrah","destination":"Saudi Arabia"}'::jsonb),
    ('travel_international', 'Student travel checklist support', 'Need guidance organizing travel documents for an overseas study program.', 350000, 'Kampala', 'Within 30 days', '{"travel_purpose":"Study","destination":"Canada"}'::jsonb),
    ('travel_international', 'Regional bus and hotel booking', 'Looking for help arranging a short trip with transport and accommodation.', 800000, 'Jinja', 'This month', '{"travel_purpose":"Leisure","destination":"Rwanda"}'::jsonb),
    ('travel_international', 'Passport appointment guidance', 'Need information on the passport application process and appointment booking.', 120000, 'Gulu', 'Urgent', '{"travel_purpose":"Passport assistance"}'::jsonb),
    ('travel_international', 'Family holiday itinerary', 'Seeking a practical family itinerary and hotel suggestions for a week away.', 400000, 'Kampala', 'Flexible', '{"travel_purpose":"Holiday","destination":"Tanzania"}'::jsonb),
    ('travel_international', 'Airport transfer for visiting team', 'Need a van transfer for a small visiting group and their luggage.', 300000, 'Entebbe', 'Within 30 days', '{"travel_purpose":"Airport transfer"}'::jsonb),
    ('travel_international', 'Conference travel coordination', 'Looking for assistance comparing flights and accommodation for a conference.', 600000, 'Kampala', 'This month', '{"travel_purpose":"Conference","destination":"South Africa"}'::jsonb),
    ('travel_international', 'Travel insurance options', 'Need help comparing travel insurance options for a two-week trip.', 180000, 'Mbarara', 'Flexible', '{"travel_purpose":"Insurance","destination":"Kenya"}'::jsonb),
    ('agriculture_agribusiness', 'Hybrid maize seed for planting', 'Need certified hybrid maize seed for the coming planting season.', 400000, 'Iganga', 'Within 30 days', '{"agri_item":"Maize seed","volume_or_acres":"5 acres"}'::jsonb),
    ('agriculture_agribusiness', 'Drip irrigation kit for tomatoes', 'Seeking a drip kit suitable for a quarter-acre tomato garden.', 850000, 'Wakiso', 'This month', '{"agri_item":"Drip irrigation","volume_or_acres":"0.25 acre"}'::jsonb),
    ('agriculture_agribusiness', 'Poultry feed for layers', 'Need quality layer feed for a small poultry unit.', 500000, 'Mukono', 'Urgent', '{"agri_item":"Poultry feed","volume_or_acres":"20 bags"}'::jsonb),
    ('agriculture_agribusiness', 'Coffee seedlings for farm', 'Looking for healthy coffee seedlings from a reliable nursery.', 350000, 'Mbale', 'Flexible', '{"agri_item":"Coffee seedlings","volume_or_acres":"300 seedlings"}'::jsonb),
    ('agriculture_agribusiness', 'Soil testing for vegetable plot', 'Need soil testing and practical recommendations before planting.', 220000, 'Masaka', 'Within 30 days', '{"agri_item":"Soil testing","volume_or_acres":"2 acres"}'::jsonb),
    ('agriculture_agribusiness', 'Beehives for honey project', 'Seeking modern beehives and basic installation advice.', 700000, 'Kiboga', 'This month', '{"agri_item":"Beehives","volume_or_acres":"10 hives"}'::jsonb),
    ('agriculture_agribusiness', 'Cassava cuttings for planting', 'Need disease-resistant cassava cuttings for a community farm.', 280000, 'Luwero', 'Within 30 days', '{"agri_item":"Cassava cuttings","volume_or_acres":"3 acres"}'::jsonb),
    ('agriculture_agribusiness', 'Farm sprayer for orchard', 'Looking for a knapsack sprayer for a young fruit orchard.', 180000, 'Fort Portal', 'Flexible', '{"agri_item":"Farm sprayer","volume_or_acres":"2 units"}'::jsonb),
    ('agriculture_agribusiness', 'Fish pond aerator', 'Need an aerator and setup advice for a small fish pond.', 650000, 'Kampala', 'This month', '{"agri_item":"Pond aerator","volume_or_acres":"1 pond"}'::jsonb),
    ('agriculture_agribusiness', 'Maize shelling service', 'Seeking a mobile maize sheller for a village harvest.', 300000, 'Soroti', 'Urgent', '{"agri_item":"Maize shelling","volume_or_acres":"3 tonnes"}'::jsonb),
    ('technology_digital', 'Point of sale software setup', 'Need help configuring inventory and sales tracking for a small shop.', 450000, 'Kampala', 'Within 30 days', '{"system_type":"Point of sale","schedule":"One-time setup"}'::jsonb),
    ('technology_digital', 'Small office Wi-Fi installation', 'Looking for secure Wi-Fi coverage across a three-room office.', 280000, 'Entebbe', 'This month', '{"system_type":"Networking","schedule":"One-time setup"}'::jsonb),
    ('technology_digital', 'Data recovery from laptop', 'Need help recovering work files from a laptop that will not start.', 220000, 'Jinja', 'Urgent', '{"system_type":"Data recovery"}'::jsonb),
    ('technology_digital', 'Cloud backup for design studio', 'Seeking a simple cloud backup plan and setup for a small team.', 350000, 'Kampala', 'Flexible', '{"system_type":"Cloud backup"}'::jsonb),
    ('technology_digital', 'Mobile app maintenance', 'Need bug fixes and routine updates for an existing Android app.', 900000, 'Kampala', 'Within 30 days', '{"system_type":"Mobile application","schedule":"Monthly"}'::jsonb),
    ('technology_digital', 'CCTV system configuration', 'Looking for installation and secure remote viewing setup for a shop.', 600000, 'Mbarara', 'This month', '{"system_type":"CCTV","schedule":"One-time setup"}'::jsonb),
    ('technology_digital', 'Website domain and email setup', 'Need a business domain and professional email accounts configured.', 250000, 'Gulu', 'Flexible', '{"system_type":"Domain and email"}'::jsonb),
    ('technology_digital', 'Computer lab maintenance', 'Seeking a technician to service and update ten school computers.', 500000, 'Lira', 'This month', '{"system_type":"Computer maintenance","schedule":"One-time"}'::jsonb),
    ('technology_digital', 'Spreadsheet automation', 'Need a simple automated spreadsheet for stock and supplier records.', 300000, 'Kampala', 'Within 30 days', '{"system_type":"Business automation"}'::jsonb),
    ('technology_digital', 'Printer network troubleshooting', 'Looking for help connecting an office printer to the local network.', 120000, 'Mukono', 'Urgent', '{"system_type":"Printer support"}'::jsonb),
    ('education_training', 'Computer basics lessons for staff', 'Need beginner computer training for five small business employees.', 400000, 'Masaka', 'Within 30 days', '{"subject_or_skill":"Computer basics","training_level":"Beginner","preferred_format":"In person"}'::jsonb),
    ('education_training', 'Mathematics tutor for senior student', 'Seeking regular mathematics tutoring to prepare for final examinations.', 300000, 'Kampala', 'This month', '{"subject_or_skill":"Mathematics","training_level":"Advanced","preferred_format":"In person"}'::jsonb),
    ('education_training', 'First aid training for team', 'Need practical first aid training for a community organization team.', 650000, 'Jinja', 'Flexible', '{"subject_or_skill":"First aid","training_level":"Beginner","preferred_format":"In person"}'::jsonb),
    ('education_training', 'Spoken English practice sessions', 'Looking for a friendly English conversation tutor for an adult learner.', 180000, 'Mbale', 'Within 30 days', '{"subject_or_skill":"English","training_level":"Intermediate","preferred_format":"Online"}'::jsonb),
    ('education_training', 'Bookkeeping course for entrepreneur', 'Need short practical bookkeeping lessons using simple examples.', 350000, 'Kampala', 'This month', '{"subject_or_skill":"Bookkeeping","training_level":"Beginner","preferred_format":"Hybrid"}'::jsonb),
    ('education_training', 'Driving lessons for new learner', 'Seeking a patient driving instructor with a training vehicle.', 500000, 'Wakiso', 'Flexible', '{"subject_or_skill":"Driving","training_level":"Beginner","preferred_format":"In person"}'::jsonb),
    ('education_training', 'Tailoring lessons for youth group', 'Need a trainer to teach basic machine sewing to a youth group.', 800000, 'Arua', 'Within 30 days', '{"subject_or_skill":"Tailoring","training_level":"Beginner","preferred_format":"In person"}'::jsonb),
    ('education_training', 'Excel training for office assistant', 'Looking for practical spreadsheet lessons covering formulas and tables.', 250000, 'Entebbe', 'This month', '{"subject_or_skill":"Excel","training_level":"Intermediate","preferred_format":"Online"}'::jsonb),
    ('education_training', 'Agribusiness planning workshop', 'Seeking a facilitator for a half-day farm business planning workshop.', 550000, 'Mbarara', 'Flexible', '{"subject_or_skill":"Agribusiness","training_level":"Intermediate","preferred_format":"In person"}'::jsonb),
    ('education_training', 'Photography lessons for beginner', 'Need a few beginner sessions covering camera basics and composition.', 300000, 'Kampala', 'Within 30 days', '{"subject_or_skill":"Photography","training_level":"Beginner","preferred_format":"Hybrid"}'::jsonb),
    ('events_celebrations', 'Sound system for community meeting', 'Need a sound system with a technician for a daytime community event.', 250000, 'Kampala', 'Within 30 days', '{"event_type":"Community meeting","guest_count":120}'::jsonb),
    ('events_celebrations', 'Wedding photographer for reception', 'Seeking a photographer for ceremony and reception coverage.', 900000, 'Mbarara', 'This month', '{"event_type":"Wedding","guest_count":180}'::jsonb),
    ('events_celebrations', 'Chairs and tents for graduation', 'Need chairs and two tents for a family graduation celebration.', 650000, 'Mukono', 'Flexible', '{"event_type":"Graduation","guest_count":100}'::jsonb),
    ('events_celebrations', 'Birthday cake for children party', 'Looking for a decorated cake for a child-friendly birthday party.', 180000, 'Entebbe', 'Within 30 days', '{"event_type":"Birthday","guest_count":35}'::jsonb),
    ('events_celebrations', 'Traditional introduction ceremony decor', 'Seeking tasteful decor and setup for a family introduction ceremony.', 750000, 'Wakiso', 'This month', '{"event_type":"Introduction ceremony","guest_count":150}'::jsonb),
    ('events_celebrations', 'MC for company team day', 'Need an engaging master of ceremonies for a staff event.', 300000, 'Kampala', 'Flexible', '{"event_type":"Company event","guest_count":80}'::jsonb),
    ('events_celebrations', 'Small PA system for church function', 'Looking for a PA system and operator for a church function.', 220000, 'Gulu', 'Within 30 days', '{"event_type":"Church function","guest_count":200}'::jsonb),
    ('events_celebrations', 'Catering for workshop lunch', 'Need a local caterer to provide lunch and refreshments for a workshop.', 600000, 'Jinja', 'This month', '{"event_type":"Workshop","guest_count":50}'::jsonb),
    ('events_celebrations', 'Live music for wedding dinner', 'Seeking a small acoustic band for a wedding dinner reception.', 850000, 'Kampala', 'Flexible', '{"event_type":"Wedding","guest_count":120}'::jsonb),
    ('events_celebrations', 'Event video recording', 'Need clear video coverage of a school awards ceremony.', 500000, 'Lira', 'Within 30 days', '{"event_type":"School awards","guest_count":250}'::jsonb),
    ('construction_building', 'Mason for boundary wall', 'Looking for an experienced mason to build a short boundary wall.', 1000000, 'Wakiso', 'Within 30 days', '{"project_type":"Boundary wall","project_size":"Small"}'::jsonb),
    ('construction_building', 'Roof repair before rainy season', 'Need a fundi to inspect and repair leaks on an iron sheet roof.', 450000, 'Kampala', 'Urgent', '{"project_type":"Roof repair","project_size":"Medium"}'::jsonb),
    ('construction_building', 'House painting and finishing', 'Seeking painters for interior finishing of a three-bedroom house.', 900000, 'Mukono', 'This month', '{"project_type":"Painting","project_size":"Medium"}'::jsonb),
    ('construction_building', 'Plumber to install water tanks', 'Need plumbing work to connect two household water tanks.', 300000, 'Entebbe', 'Flexible', '{"project_type":"Plumbing","project_size":"Small"}'::jsonb),
    ('construction_building', 'Floor tiling for shop', 'Looking for a tiler to finish the floor of a small retail shop.', 650000, 'Jinja', 'Within 30 days', '{"project_type":"Tiling","project_size":"Small"}'::jsonb),
    ('construction_building', 'Solar water heater installation', 'Need a qualified installer for a domestic solar water heater.', 500000, 'Kampala', 'This month', '{"project_type":"Solar installation","project_size":"Small"}'::jsonb),
    ('construction_building', 'Carpenter for kitchen cabinets', 'Seeking custom kitchen cabinets and installation for a family home.', 1800000, 'Mbarara', 'Flexible', '{"project_type":"Cabinetry","project_size":"Medium"}'::jsonb),
    ('construction_building', 'House foundation inspection', 'Need an independent engineer to inspect foundation work and advise.', 550000, 'Hoima', 'Within 30 days', '{"project_type":"Engineering inspection","project_size":"Small"}'::jsonb),
    ('construction_building', 'Install rain gutters on home', 'Looking for supply and fitting of gutters on a modest family house.', 420000, 'Masaka', 'This month', '{"project_type":"Gutters","project_size":"Small"}'::jsonb),
    ('construction_building', 'Repair compound drainage channel', 'Need a builder to repair a blocked and damaged compound drain.', 350000, 'Fort Portal', 'Urgent', '{"project_type":"Drainage","project_size":"Small"}'::jsonb)
  ) AS rows(category_slug, title, specification, budget, location, urgency, details)
  WHERE category_slug IN (
    'machinery_equipment', 'professional_services',
    'transport_logistics', 'specialized_products', 'travel_international'
  )
), ranked_needs AS (
  SELECT row_number() OVER (
    PARTITION BY category_slug ORDER BY title
  ) AS category_rank, *
  FROM test_needs
), numbered AS (
  SELECT row_number() OVER (
    ORDER BY category_rank, category_slug
  ) AS n, *
  FROM ranked_needs
), available_accounts AS (
  SELECT p.id, p.country,
    COALESCE(s.plan, 'free'::public.subscription_plan_enum) AS plan
  FROM public.profiles p
  LEFT JOIN LATERAL (
    SELECT sub.plan
    FROM public.subscriptions sub
    WHERE sub.user_id = p.id
      AND sub.status = 'active'
      AND (sub.expires_at IS NULL OR sub.expires_at > now())
    ORDER BY sub.created_at DESC NULLS LAST
    LIMIT 1
  ) s ON true
  WHERE private.is_identity_verified(p.id)
), available_limits AS (
  SELECT a.id, COALESCE(
    (SELECT setting_value::integer
     FROM public.system_settings ss
     WHERE ss.setting_key = 'max_active_requests_' || a.plan::text
       AND (ss.country = 'UG' OR ss.country IS NULL)
     ORDER BY ss.country NULLS LAST
     LIMIT 1),
    CASE a.plan WHEN 'free' THEN 3 WHEN 'lender' THEN 8 WHEN 'pro' THEN 20 END
  ) AS request_limit
  FROM available_accounts a
), available_slots AS (
  SELECT l.id, greatest(l.request_limit -
    (SELECT count(*) FROM public.loan_requests lr
     WHERE lr.borrower_id = l.id AND lr.status::text = 'active')
    -
    (SELECT count(*) FROM public.needs_requests nr
     WHERE nr.requester_id = l.id AND nr.status::text = 'active'), 0
  )::int AS slots
  FROM available_limits l
), requesters AS (
  SELECT slots.id, row_number() OVER (ORDER BY slots.id, slot_no) AS n
  FROM available_slots slots
  CROSS JOIN LATERAL generate_series(1, slots.slots) AS slot_no
)
INSERT INTO public.needs_requests (
  requester_id, title, specification, category, category_slug, capability_slug, details,
  budget, currency, location, country, urgency, status, listed_at, expires_at,
  trust_is_verified, number_of_offers
)
SELECT
  requesters.id,
  '[TEST ' || lpad(n::text, 3, '0') || '] ' || title,
  specification || ' Sample listing for testing Needs categories and chips.',
  COALESCE((SELECT name FROM public.need_categories WHERE slug = numbered.category_slug),
           initcap(replace(numbered.category_slug, '_', ' '))),
  numbered.category_slug,
  CASE numbered.category_slug
    WHEN 'machinery_equipment' THEN 'excavator_hire'
    WHEN 'transport_logistics' THEN 'heavy_haulage'
    WHEN 'professional_services' THEN 'company_registration'
    WHEN 'specialized_products' THEN 'bulk_procurement'
    WHEN 'travel_international' THEN 'visa_assistance'
    ELSE NULL
  END,
  details,
  budget,
  'UGX',
  location,
  'UG',
  urgency,
  'active',
  now() - ((n % 100) || ' minutes')::interval,
  now() + interval '30 days',
  false,
  0
FROM numbered
JOIN requesters USING (n);
