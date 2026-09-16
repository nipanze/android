-- Sample Needs marketplace requests: 10 each for every country listed below.
-- Safe to paste into the Supabase SQL editor.
-- Existing needs_requests tables and v_needs_listings views are not replaced.

create table if not exists public.needs_requests (
  request_id uuid primary key default gen_random_uuid(),
  title text not null,
  specification text not null default '',
  category text not null default 'Other',
  budget integer not null default 0 check (budget >= 0),
  currency text not null default 'UGX',
  location text not null default '',
  country text not null default 'UG',
  urgency text not null default 'Flexible',
  status text not null default 'active',
  listed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  trust_is_verified boolean not null default false
);

-- Create the read model used by the Flutter marketplace when it is absent.
do $$
begin
  if not exists (
    select 1
    from pg_views
    where schemaname = 'public'
      and viewname = 'v_needs_listings'
  ) then
    execute $view$
      create view public.v_needs_listings as
      select
        request_id,
        title,
        specification,
        category,
        budget,
        currency,
        location,
        country,
        urgency,
        status,
        listed_at,
        created_at,
        trust_is_verified
      from public.needs_requests
      where status = 'active'
    $view$;
  end if;
end
$$;

insert into public.needs_requests (
  request_id, title, specification, category, budget, currency,
  location, country, urgency, status, listed_at, trust_is_verified
)
values
  ('d1000000-0000-0000-0000-000000000001',
   'Solar Home System',
   'Need a 200W solar panel, battery, controller, and installation for a two-room home.',
   'Home & Energy', 1850000, 'UGX', 'Gulu', 'UG', 'This month', 'active', now() - interval '2 hours', true),
  ('d1000000-0000-0000-0000-000000000002',
   'Commercial Fridge',
   'Display fridge for a small yoghurt and fresh juice shop near the main taxi stage.',
   'Business Equipment', 3200000, 'UGX', 'Mbarara', 'UG', 'Within 30 days', 'active', now() - interval '5 hours', false),
  ('d1000000-0000-0000-0000-000000000003',
   'School Desks',
   'Thirty-five durable desks and chairs for a growing primary school in Wakiso.',
   'Education', 4200000, 'UGX', 'Wakiso', 'UG', 'Urgent', 'active', now() - interval '1 day', true),
  ('d1000000-0000-0000-0000-000000000004',
   'Water Storage Tank',
   'A 10,000 litre tank and raised stand for a community water point serving nearby homes.',
   'Community', 2900000, 'UGX', 'Lira', 'UG', 'Within 30 days', 'active', now() - interval '1 day 4 hours', true),
  ('d1000000-0000-0000-0000-000000000005',
   'Restaurant Kitchen Equipment',
   'Two-burner cooker, stainless work table, pots, and serving equipment for a new cafe.',
   'Business Equipment', 5600000, 'UGX', 'Kampala Central', 'UG', 'This month', 'active', now() - interval '2 days', false),
  ('d1000000-0000-0000-0000-000000000006',
   'Motorcycle Spare Parts',
   'Bulk brake pads, chains, cables, and tyres to restock a motorcycle parts shop.',
   'Inventory', 950000, 'KES', 'Nairobi', 'KE', 'Within 30 days', 'active', now() - interval '2 days 6 hours', false),
  ('d1000000-0000-0000-0000-000000000007',
   'Irrigation Pump',
   'Petrol irrigation pump and hose for a vegetable plot supplying local markets.',
   'Agriculture', 780000, 'TZS', 'Arusha', 'TZ', 'Before next planting season', 'active', now() - interval '3 days', true),
  ('d1000000-0000-0000-0000-000000000008',
   'Laptop for Graphic Design',
   'Reliable laptop with at least 16GB RAM for freelance design and video editing work.',
   'Technology', 1450000, 'RWF', 'Kigali', 'RW', 'Within 30 days', 'active', now() - interval '3 days 5 hours', false)
  ,('d1000000-0000-0000-0000-000000000009',
   'Borehole Repair',
   'Replace the damaged pump and restore clean water access for a village health centre.',
   'Community', 2300000, 'UGX', 'Hoima', 'UG', 'Urgent', 'active', now() - interval '4 days', true)
  ,('d1000000-0000-0000-0000-000000000010',
   'Tailoring Machine',
   'Industrial sewing machine for a small tailoring workshop employing three young people.',
   'Business Equipment', 1750000, 'UGX', 'Jinja', 'UG', 'Within 30 days', 'active', now() - interval '4 days 6 hours', false)
  ,('d1000000-0000-0000-0000-000000000011',
   'Motorcycle for Farm Deliveries',
   'Reliable motorcycle to transport produce from a family farm to the local market.',
   'Agriculture', 6800000, 'UGX', 'Mbale', 'UG', 'This month', 'active', now() - interval '5 days', true)
  ,('d1000000-0000-0000-0000-000000000012',
   'Maternity Ward Supplies',
   'Delivery kits, sterilisation supplies, and washable sheets for a rural maternity ward.',
   'Health', 1600000, 'UGX', 'Fort Portal', 'UG', 'Urgent', 'active', now() - interval '5 days 5 hours', true)
  ,('d1000000-0000-0000-0000-000000000013',
   'Beehives and Protective Gear',
   'Ten modern hives, smoker, veil, and protective suits for a new beekeeping group.',
   'Agriculture', 1250000, 'UGX', 'Arua', 'UG', 'Before next season', 'active', now() - interval '6 days', false)
  ,('d1000000-0000-0000-0000-000000000014',
   'Shop Shelving',
   'Metal shelving and a counter for a neighbourhood household goods shop.',
   'Business Equipment', 980000, 'KES', 'Kisumu', 'KE', 'Within 30 days', 'active', now() - interval '4 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000015',
   'School Computer Lab',
   'Ten refurbished desktop computers, network equipment, and setup for a secondary school.',
   'Education', 850000, 'KES', 'Nakuru', 'KE', 'This term', 'active', now() - interval '4 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000016',
   'Greenhouse Materials',
   'Polythene, irrigation lines, and seed trays for a small commercial vegetable greenhouse.',
   'Agriculture', 420000, 'KES', 'Eldoret', 'KE', 'Before next planting season', 'active', now() - interval '5 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000017',
   'Clinic Solar Backup',
   'Battery and inverter backup to keep vaccine refrigeration running during outages.',
   'Health', 690000, 'KES', 'Mombasa', 'KE', 'Urgent', 'active', now() - interval '6 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000018',
   'Mobile Food Cart',
   'Food cart, gas burner, and insulated containers for a breakfast business.',
   'Business Equipment', 280000, 'KES', 'Thika', 'KE', 'Within 30 days', 'active', now() - interval '6 days 10 hours', false)
  ,('d1000000-0000-0000-0000-000000000019',
   'Fishing Nets and Cooler',
   'Legal fishing nets and a solar cooler for a lakeside fishing cooperative.',
   'Livelihoods', 1650000, 'TZS', 'Mwanza', 'TZ', 'This month', 'active', now() - interval '4 days 9 hours', true)
  ,('d1000000-0000-0000-0000-000000000020',
   'School Water Filter',
   'Large-capacity filtration system and storage containers for a rural primary school.',
   'Education', 1100000, 'TZS', 'Dodoma', 'TZ', 'Urgent', 'active', now() - interval '4 days 14 hours', true)
  ,('d1000000-0000-0000-0000-000000000021',
   'Poultry House Materials',
   'Timber, wire mesh, feeders, and drinkers for a 500-bird poultry project.',
   'Agriculture', 2400000, 'TZS', 'Morogoro', 'TZ', 'Within 30 days', 'active', now() - interval '5 days 2 hours', false)
  ,('d1000000-0000-0000-0000-000000000022',
   'Phone Repair Tools',
   'Professional microscope, heat station, and precision tools for a phone repair kiosk.',
   'Technology', 1350000, 'TZS', 'Dar es Salaam', 'TZ', 'This month', 'active', now() - interval '5 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000023',
   'Community Library Books',
   'Age-appropriate textbooks, story books, and shelves for a community reading room.',
   'Education', 1750000, 'TZS', 'Mbeya', 'TZ', 'Flexible', 'active', now() - interval '6 days 2 hours', true)
  ,('d1000000-0000-0000-0000-000000000024',
   'Bakery Oven',
   'Electric deck oven to increase daily bread production for a growing bakery.',
   'Business Equipment', 480000, 'RWF', 'Huye', 'RW', 'This month', 'active', now() - interval '4 days 10 hours', false)
  ,('d1000000-0000-0000-0000-000000000025',
   'Rainwater Harvesting Tanks',
   'Two tanks and guttering for a community centre that hosts youth programmes.',
   'Community', 920000, 'RWF', 'Musanze', 'RW', 'Before rainy season', 'active', now() - interval '4 days 16 hours', true)
  ,('d1000000-0000-0000-0000-000000000026',
   'Motorcycle Delivery Box',
   'Insulated delivery box and safety gear for a small food delivery service.',
   'Business Equipment', 260000, 'RWF', 'Kigali', 'RW', 'Within 30 days', 'active', now() - interval '5 days 4 hours', false)
  ,('d1000000-0000-0000-0000-000000000027',
   'Piglet Starter Stock',
   'Healthy piglets, pen materials, and initial feed for a family farming project.',
   'Agriculture', 1150000, 'RWF', 'Rubavu', 'RW', 'This month', 'active', now() - interval '5 days 18 hours', true)
  ,('d1000000-0000-0000-0000-000000000028',
   'Community First Aid Kit',
   'First aid supplies, stretcher, and basic protective equipment for a village response team.',
   'Health', 390000, 'RWF', 'Nyagatare', 'RW', 'Urgent', 'active', now() - interval '6 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000029',
   'Fresh Produce Stall',
   'Lockable market stall, crates, and weighing scale for a fresh produce business.',
   'Business Equipment', 315000, 'KES', 'Nairobi', 'KE', 'This month', 'active', now() - interval '7 days', true)
  ,('d1000000-0000-0000-0000-000000000030',
   'Rainwater Tank',
   '5,000 litre tank and gutters for a household in a water-scarce neighbourhood.',
   'Home & Energy', 185000, 'KES', 'Machakos', 'KE', 'Before rainy season', 'active', now() - interval '7 days 6 hours', false)
  ,('d1000000-0000-0000-0000-000000000031',
   'Motorcycle Safety Gear',
   'Helmets, reflective jackets, and rain gear for a small delivery team.',
   'Transport', 125000, 'KES', 'Kakamega', 'KE', 'Within 30 days', 'active', now() - interval '8 days', false)
  ,('d1000000-0000-0000-0000-000000000032',
   'Dairy Feed and Chiller',
   'Three months of dairy feed and a small milk chiller for a cooperative.',
   'Agriculture', 610000, 'KES', 'Nyeri', 'KE', 'Urgent', 'active', now() - interval '8 days 5 hours', true)
  ,('d1000000-0000-0000-0000-000000000033',
   'Solar Street Light',
   'Solar street light and pole to improve safety near a market entrance.',
   'Community', 850000, 'TZS', 'Tanga', 'TZ', 'This month', 'active', now() - interval '7 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000034',
   'Tailoring Fabric Stock',
   'Cotton fabric, thread, zips, and buttons for school uniform orders.',
   'Inventory', 1650000, 'TZS', 'Zanzibar', 'TZ', 'Within 30 days', 'active', now() - interval '7 days 10 hours', false)
  ,('d1000000-0000-0000-0000-000000000035',
   'Poultry Vaccination Supplies',
   'Vaccines, feeders, and drinkers for a small poultry farmers association.',
   'Agriculture', 980000, 'TZS', 'Shinyanga', 'TZ', 'Urgent', 'active', now() - interval '8 days 3 hours', true)
  ,('d1000000-0000-0000-0000-000000000036',
   'Solar Study Lamps',
   'Rechargeable study lamps for students in an off-grid village school.',
   'Education', 730000, 'TZS', 'Kigoma', 'TZ', 'This term', 'active', now() - interval '8 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000037',
   'Milk Collection Canisters',
   'Food-grade milk cans and a weighing scale for a cooperative collection point.',
   'Agriculture', 610000, 'RWF', 'Gicumbi', 'RW', 'This month', 'active', now() - interval '7 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000038',
   'Classroom Desks',
   'Twenty-five desks and chairs for a growing lower secondary school.',
   'Education', 1750000, 'RWF', 'Rwamagana', 'RW', 'Urgent', 'active', now() - interval '7 days 14 hours', false)
  ,('d1000000-0000-0000-0000-000000000039',
   'Phone Charging Kiosk',
   'Solar charging kiosk, cables, and secure counter for a rural trading centre.',
   'Business Equipment', 890000, 'RWF', 'Kayonza', 'RW', 'Within 30 days', 'active', now() - interval '8 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000040',
   'Vegetable Seed Starter Pack',
   'Seeds, trays, compost, and watering cans for a youth farming group.',
   'Agriculture', 290000, 'RWF', 'Nyanza', 'RW', 'Before next planting season', 'active', now() - interval '8 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000041',
   'Cassava Processing Machine',
   'Small motorised cassava grater and press for a women-led farming cooperative.',
   'Agriculture', 6800000, 'BIF', 'Gitega', 'BI', 'This month', 'active', now() - interval '9 days', true)
  ,('d1000000-0000-0000-0000-000000000042',
   'Classroom Roofing Sheets',
   'Corrugated roofing sheets and timber to repair two classrooms before the rains.',
   'Education', 4200000, 'BIF', 'Ngozi', 'BI', 'Urgent', 'active', now() - interval '9 days 5 hours', false)
  ,('d1000000-0000-0000-0000-000000000043',
   'Market Stall Materials',
   'Timber, iron sheets, and a lockable counter for a small produce stall.',
   'Business Equipment', 2100000, 'BIF', 'Bujumbura', 'BI', 'Within 30 days', 'active', now() - interval '10 days', true)
  ,('d1000000-0000-0000-0000-000000000044',
   'Village Water Tank',
   'Large storage tank and stand for a village water collection point.',
   'Community', 5500000, 'BIF', 'Muyinga', 'BI', 'Urgent', 'active', now() - interval '10 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000045',
   'Solar Charging Station',
   'Solar panel, battery, and charging cabinet for a rural trading centre.',
   'Home & Energy', 3600000, 'BIF', 'Makamba', 'BI', 'This month', 'active', now() - interval '11 days', false)
  ,('d1000000-0000-0000-0000-000000000046',
   'Fishing Boat Repair',
   'Timber, paint, and engine service for a cooperative fishing boat.',
   'Livelihoods', 7800000, 'CDF', 'Goma', 'CD', 'Urgent', 'active', now() - interval '9 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000047',
   'Pharmacy Shelving',
   'Lockable shelving, counter, and storage bins for a community pharmacy.',
   'Health', 4200000, 'CDF', 'Bukavu', 'CD', 'Within 30 days', 'active', now() - interval '9 days 14 hours', false)
  ,('d1000000-0000-0000-0000-000000000048',
   'School Solar Kit',
   'Solar panels, batteries, and lights for a primary school with no grid connection.',
   'Education', 9500000, 'CDF', 'Lubumbashi', 'CD', 'This term', 'active', now() - interval '10 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000049',
   'Water Pump',
   'Solar water pump and pipes for a small community garden.',
   'Agriculture', 6400000, 'CDF', 'Kisangani', 'CD', 'Before next planting season', 'active', now() - interval '10 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000050',
   'Tailoring Workshop Tools',
   'Three sewing machines, cutting table, and starter fabric for a youth workshop.',
   'Business Equipment', 5800000, 'CDF', 'Kinshasa', 'CD', 'This month', 'active', now() - interval '11 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000051',
   'Fishing Nets',
   'Durable legal fishing nets and insulated storage boxes for coastal fishers.',
   'Livelihoods', 185000, 'SOS', 'Mogadishu', 'SO', 'This month', 'active', now() - interval '9 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000052',
   'Clinic Medical Refrigerator',
   'Solar vaccine refrigerator and temperature monitor for a rural clinic.',
   'Health', 420000, 'SOS', 'Hargeisa', 'SO', 'Urgent', 'active', now() - interval '9 days 16 hours', false)
  ,('d1000000-0000-0000-0000-000000000053',
   'Water Truck Storage Tank',
   'Poly tanks and distribution hoses for a drought-response water point.',
   'Community', 310000, 'SOS', 'Baidoa', 'SO', 'Urgent', 'active', now() - interval '10 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000054',
   'Solar Lights for School',
   'Rechargeable solar lights for classrooms and evening study sessions.',
   'Education', 165000, 'SOS', 'Kismayo', 'SO', 'This term', 'active', now() - interval '10 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000055',
   'Small Grocery Stock',
   'Rice, flour, cooking oil, and shelves to open a neighbourhood grocery shop.',
   'Inventory', 280000, 'SOS', 'Garowe', 'SO', 'Within 30 days', 'active', now() - interval '11 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000056',
   'Maize Milling Machine',
   'Small diesel maize mill to serve farming communities near a market centre.',
   'Agriculture', 1850000, 'SSP', 'Juba', 'SS', 'This month', 'active', now() - interval '9 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000057',
   'Borehole Pump Repair',
   'Replacement pump and fittings to restore water access for a settlement.',
   'Community', 1250000, 'SSP', 'Wau', 'SS', 'Urgent', 'active', now() - interval '9 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000058',
   'School Desks and Boards',
   'Desks, benches, and writing boards for two temporary classrooms.',
   'Education', 980000, 'SSP', 'Malakal', 'SS', 'This term', 'active', now() - interval '10 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000059',
   'Solar Clinic Backup',
   'Solar battery system to keep essential lights and medical equipment running.',
   'Health', 2400000, 'SSP', 'Yei', 'SS', 'Urgent', 'active', now() - interval '10 days 20 hours', false)
  ,('d1000000-0000-0000-0000-000000000060',
   'Goat Farming Starter Group',
   'Starter goats, shelter materials, and veterinary supplies for a women’s group.',
   'Agriculture', 1450000, 'SSP', 'Aweil', 'SS', 'Within 30 days', 'active', now() - interval '11 days 18 hours', true)
  ,('d1000000-0000-0000-0000-000000000061',
   'Rice Huller',
   'Small rice huller and spare belts for a farming cooperative.',
   'Agriculture', 7200000, 'BIF', 'Kirundo', 'BI', 'This month', 'active', now() - interval '12 days', false)
  ,('d1000000-0000-0000-0000-000000000062',
   'Maternity Supplies',
   'Reusable delivery kits, steriliser, and basic supplies for a rural health post.',
   'Health', 2900000, 'BIF', 'Cibitoke', 'BI', 'Urgent', 'active', now() - interval '12 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000063',
   'Motorcycle Delivery Box',
   'Secure delivery box and rain gear for a pharmacy delivery rider.',
   'Transport', 1100000, 'BIF', 'Rumonge', 'BI', 'Within 30 days', 'active', now() - interval '13 days', false)
  ,('d1000000-0000-0000-0000-000000000064',
   'Community Library Books',
   'Children’s readers, textbooks, and shelves for a community reading room.',
   'Education', 2500000, 'BIF', 'Kayanza', 'BI', 'Flexible', 'active', now() - interval '13 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000065',
   'Market Cold Box',
   'Solar-powered cold box for preserving fish and fresh produce at the market.',
   'Business Equipment', 6100000, 'CDF', 'Matadi', 'CD', 'This month', 'active', now() - interval '12 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000066',
   'Community Grain Store',
   'Metal sheets, timber, and pallets to build a dry grain storage room.',
   'Community', 8700000, 'CDF', 'Mbuji-Mayi', 'CD', 'Before harvest', 'active', now() - interval '12 days 14 hours', true)
  ,('d1000000-0000-0000-0000-000000000067',
   'Computer Training Lab',
   'Six refurbished laptops and a small solar backup for digital skills training.',
   'Technology', 11200000, 'CDF', 'Beni', 'CD', 'This term', 'active', now() - interval '13 days 4 hours', false)
  ,('d1000000-0000-0000-0000-000000000068',
   'Beekeeping Equipment',
   'Modern hives, smoker, protective suits, and starter colonies for a cooperative.',
   'Agriculture', 4900000, 'CDF', 'Uvira', 'CD', 'Before next season', 'active', now() - interval '13 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000069',
   'Fish Market Stall',
   'Lockable stall, scales, and insulated containers for a fish vendor.',
   'Business Equipment', 240000, 'SOS', 'Berbera', 'SO', 'Within 30 days', 'active', now() - interval '12 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000070',
   'Community Water Filters',
   'Household water filters and safe storage containers for a displaced community.',
   'Community', 195000, 'SOS', 'Doolow', 'SO', 'Urgent', 'active', now() - interval '12 days 18 hours', true)
  ,('d1000000-0000-0000-0000-000000000071',
   'Solar Phone Charging Kiosk',
   'Solar charging station and secure kiosk for a busy transport stop.',
   'Business Equipment', 335000, 'SOS', 'Bosaso', 'SO', 'This month', 'active', now() - interval '13 days 6 hours', false)
  ,('d1000000-0000-0000-0000-000000000072',
   'School Learning Materials',
   'Exercise books, pens, chalk, and basic teaching materials for a primary school.',
   'Education', 155000, 'SOS', 'Beledweyne', 'SO', 'This term', 'active', now() - interval '13 days 16 hours', true)
  ,('d1000000-0000-0000-0000-000000000073',
   'Vegetable Garden Irrigation',
   'Drip lines, water tank, and hand tools for an urban vegetable garden.',
   'Agriculture', 1180000, 'SSP', 'Torit', 'SS', 'Before next planting season', 'active', now() - interval '12 days 16 hours', false)
  ,('d1000000-0000-0000-0000-000000000074',
   'Community Pharmacy Shelves',
   'Lockable shelves and medicine storage bins for a community pharmacy.',
   'Health', 980000, 'SSP', 'Rumbek', 'SS', 'Within 30 days', 'active', now() - interval '12 days 22 hours', true)
  ,('d1000000-0000-0000-0000-000000000075',
   'Market Stall Construction',
   'Iron sheets, timber, and a lock for a small dry goods stall.',
   'Business Equipment', 720000, 'SSP', 'Bor', 'SS', 'This month', 'active', now() - interval '13 days 10 hours', false)
  ,('d1000000-0000-0000-0000-000000000076',
   'Handwashing Stations',
   'Water tanks, stands, and soap dispensers for a school and nearby market.',
   'Community', 560000, 'SSP', 'Bentiu', 'SS', 'Urgent', 'active', now() - interval '13 days 20 hours', true)
  ,('d1000000-0000-0000-0000-000000000077',
   'Groundnut Sheller',
   'Manual sheller and storage sacks for a small farmers’ association.',
   'Agriculture', 840000, 'BIF', 'Bubanza', 'BI', 'Before harvest', 'active', now() - interval '14 days', true)
  ,('d1000000-0000-0000-0000-000000000078',
   'Solar Sewing Workshop',
   'Two sewing machines and solar backup for a women’s tailoring workshop.',
    'Business Equipment', 530000, 'SOS', 'Hargeisa', 'SO', 'This month', 'active', now() - interval '14 days 6 hours', false)
  ,('d1000000-0000-0000-0000-000000000079',
   'Classroom Water Filter',
   'Water filter and storage containers for a rural primary school.',
   'Education', 1450000, 'CDF', 'Kikwit', 'CD', 'Urgent', 'active', now() - interval '14 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000080',
   'Livestock Vaccination Kit',
   'Cold box, syringes, and veterinary supplies for a pastoralist community.',
   'Agriculture', 630000, 'SSP', 'Yambio', 'SS', 'Before next season', 'active', now() - interval '14 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000081',
   'Solar Power Kit',
   'Solar panels, battery, and inverter for a small household and home office.',
   'Home & Energy', 850000, 'NGN', 'Abuja', 'NG', 'This month', 'active', now() - interval '15 days', true)
  ,('d1000000-0000-0000-0000-000000000082',
   'Poultry Feed Stock',
   'Starter feed and drinkers for a 300-bird poultry business.',
   'Agriculture', 420000, 'NGN', 'Ibadan', 'NG', 'Within 30 days', 'active', now() - interval '15 days 5 hours', false)
  ,('d1000000-0000-0000-0000-000000000083',
   'School Projector',
   'Reliable projector and screen for lessons at a community secondary school.',
   'Education', 680000, 'NGN', 'Lagos', 'NG', 'This term', 'active', now() - interval '16 days', true)
  ,('d1000000-0000-0000-0000-000000000084',
   'Water Borehole Pump',
   'Submersible pump and pipes to restore water access for a farming settlement.',
   'Community', 1250000, 'NGN', 'Kaduna', 'NG', 'Urgent', 'active', now() - interval '16 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000085',
   'Tailoring Equipment',
   'Two sewing machines, cutting table, and fabric for a women’s tailoring group.',
   'Business Equipment', 950000, 'NGN', 'Enugu', 'NG', 'This month', 'active', now() - interval '17 days', false)
  ,('d1000000-0000-0000-0000-000000000086',
   'Clinic Examination Bed',
   'Examination bed, privacy screen, and basic diagnostic equipment for a clinic.',
   'Health', 56000, 'EGP', 'Cairo', 'EG', 'Within 30 days', 'active', now() - interval '15 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000087',
   'Bakery Mixer',
   'Commercial dough mixer and trays for a neighbourhood bakery.',
   'Business Equipment', 74000, 'EGP', 'Alexandria', 'EG', 'This month', 'active', now() - interval '15 days 14 hours', false)
  ,('d1000000-0000-0000-0000-000000000088',
   'Irrigation Drip Lines',
   'Drip irrigation lines and water tank for a vegetable farm outside the city.',
   'Agriculture', 48000, 'EGP', 'Giza', 'EG', 'Before next planting season', 'active', now() - interval '16 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000089',
   'School Desks',
   'Forty desks and chairs for a public school with growing enrolment.',
   'Education', 92000, 'EGP', 'Aswan', 'EG', 'Urgent', 'active', now() - interval '16 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000090',
   'Cold Storage Chest',
   'Energy-efficient chest freezer for a small fish and frozen food business.',
   'Business Equipment', 63000, 'EGP', 'Port Said', 'EG', 'Within 30 days', 'active', now() - interval '17 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000091',
   'Community Garden Tools',
   'Wheelbarrows, hand tools, compost, and seedlings for a shared food garden.',
   'Community', 18500, 'ZAR', 'Johannesburg', 'ZA', 'This month', 'active', now() - interval '15 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000092',
   'Mobile Food Trailer',
   'Compact food trailer, gas burner, and serving equipment for a new vendor.',
   'Business Equipment', 78000, 'ZAR', 'Cape Town', 'ZA', 'Within 30 days', 'active', now() - interval '15 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000093',
   'Solar Water Pump',
   'Solar pump and storage tank for a small vegetable farm.',
   'Agriculture', 46500, 'ZAR', 'Polokwane', 'ZA', 'Before next planting season', 'active', now() - interval '16 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000094',
   'Computer Lab Upgrade',
   'Refurbished computers and network equipment for a township learning centre.',
   'Technology', 92000, 'ZAR', 'Durban', 'ZA', 'This term', 'active', now() - interval '16 days 16 hours', false)
  ,('d1000000-0000-0000-0000-000000000095',
   'Clinic Backup Battery',
   'Battery and inverter backup for vaccine refrigeration and emergency lighting.',
   'Health', 38500, 'ZAR', 'Mthatha', 'ZA', 'Urgent', 'active', now() - interval '17 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000096',
   'Farming Tunnel Materials',
   'Plastic tunnel, irrigation fittings, and seedlings for a community farm.',
   'Agriculture', 52000, 'ZAR', 'Mbombela', 'ZA', 'This month', 'active', now() - interval '18 days', false)
  ,('d1000000-0000-0000-0000-000000000097',
   'School Library Shelves',
   'Shelving and age-appropriate books for a rural primary school library.',
   'Education', 27500, 'ZAR', 'Kimberley', 'ZA', 'This term', 'active', now() - interval '18 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000098',
   'Hair Salon Equipment',
   'Salon chair, hair dryer, mirrors, and starter products for a new business.',
   'Business Equipment', 34000, 'ZAR', 'Soweto', 'ZA', 'Within 30 days', 'active', now() - interval '18 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000099',
   'Rainwater Harvesting System',
   'Gutters, tanks, and filtration for a community centre.',
   'Home & Energy', 61500, 'ZAR', 'Gqeberha', 'ZA', 'Before rainy season', 'active', now() - interval '19 days', true)
  ,('d1000000-0000-0000-0000-000000000100',
   'Small Delivery Vehicle',
   'Used compact vehicle for delivering groceries and farm produce locally.',
   'Transport', 145000, 'ZAR', 'Pretoria', 'ZA', 'This month', 'active', now() - interval '19 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000101',
   'Market Cold Cabinet',
   'Glass-door refrigerator for a small dairy and fresh juice shop.',
   'Business Equipment', 690000, 'NGN', 'Benin City', 'NG', 'Within 30 days', 'active', now() - interval '16 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000102',
   'Borehole Storage Tank',
   'Water tank and stand for a school and surrounding households.',
   'Community', 530000, 'NGN', 'Jos', 'NG', 'Urgent', 'active', now() - interval '16 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000103',
   'Farm Produce Crates',
   'Reusable crates and weighing scale for transporting vegetables to market.',
   'Agriculture', 275000, 'NGN', 'Abeokuta', 'NG', 'This month', 'active', now() - interval '17 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000104',
   'Community First Aid Supplies',
   'First aid kits, stretcher, and protective supplies for a volunteer response team.',
   'Health', 410000, 'NGN', 'Maiduguri', 'NG', 'Urgent', 'active', now() - interval '18 days 4 hours', false)
  ,('d1000000-0000-0000-0000-000000000105',
   'Learning Tablets',
   'Ten durable tablets and charging case for an after-school learning programme.',
   'Technology', 980000, 'NGN', 'Kano', 'NG', 'This term', 'active', now() - interval '19 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000106',
   'Solar Irrigation Controller',
   'Controller, panels, and pipes for a small farm irrigation system.',
   'Agriculture', 38500, 'EGP', 'Luxor', 'EG', 'Before next planting season', 'active', now() - interval '17 days 14 hours', false)
  ,('d1000000-0000-0000-0000-000000000107',
   'Vocational Training Tools',
   'Basic carpentry tools and workbenches for a youth skills programme.',
   'Education', 47000, 'EGP', 'Sohag', 'EG', 'This month', 'active', now() - interval '18 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000108',
   'Small Grocery Shelves',
   'Metal shelving, counter, and storage bins for a family grocery shop.',
   'Business Equipment', 32500, 'EGP', 'Mansoura', 'EG', 'Within 30 days', 'active', now() - interval '18 days 16 hours', false)
  ,('d1000000-0000-0000-0000-000000000109',
   'Water Filtration Unit',
   'Commercial filter and safe storage tank for a community water point.',
   'Community', 54000, 'EGP', 'Faiyum', 'EG', 'Urgent', 'active', now() - interval '19 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000110',
   'Medical Transport Motorbike',
   'Motorbike and secure case for delivering medicines to remote villages.',
    'Health', 118000, 'EGP', 'Minya', 'EG', 'This month', 'active', now() - interval '20 days', false)
on conflict (request_id) do update set
  title = excluded.title,
  specification = excluded.specification,
  category = excluded.category,
  budget = excluded.budget,
  currency = excluded.currency,
  location = excluded.location,
  country = excluded.country,
  urgency = excluded.urgency,
  status = excluded.status,
  listed_at = excluded.listed_at,
  trust_is_verified = excluded.trust_is_verified;

select country, count(*) as request_count
from public.needs_requests
where request_id::text like 'd1000000-%'
group by country
order by country; 

 