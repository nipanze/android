# ADDENDUM v2: Catalog expansion, active-first ordering, global search, upload fix

Supersedes `CATALOG_EXPANSION_PROMPT.md`. Built against the real catalog in `provider_services_catalog.md` (14 categories, 129 capabilities, 61 roles). Extends Stages 4.14 to 4.16.

Read first: `.agents/AGENTS.md`, `BUILD_PLAN.md`, `PROVIDER_FLOW_BUILD_ORDER.md`, `VERIFICATION_SPEC.md`, `PROVIDER_TYPE_STEP_PROMPT.md`, `provider_services_catalog.md`. All earlier rules apply: Home and the Marketplace feed are protected; everything behind `capability_profiles_enabled`; SQL only as standalone, re-runnable patches (never edit `sql/patch.sql` or `sql/merged.sql`); RLS on new tables, no anon grants; **no existing slug is ever renamed or deleted**; per-capability verification never transfers; non-custodial; staging first; tracker updated in the same commit. Inspect and report first, then wait for my OK.

## 1. What already exists (do NOT add again)
| Request | Already in the catalog | Action |
|---|---|---|
| Foreman | Construction role "Foreman / Supervisor" (kinds Masonry, Roofing, Concrete, Finishing; trade test certificate needs evidence) | No new role. Fix proof upload and use it as test case 1. Add alias "foreman", "supervisor", "ganger" |
| Driver | Transport role "Driver" (Truck/heavy, Pickup/van, Bus/minibus, Motorcycle courier, Tanker; licence needs evidence); Travel role "Driver-Guide" | Add kinds only (section 4.2) |
| Driving school | `driving_school` ("Driving School / Driver Training") under Business & Professional; Education role "Trainer / Instructor" has kind "Driving" | Keep slug and category. Add `ui_group_slug` so it also appears under Transport & Logistics and Education & Training, plus aliases. Do NOT move or rename |
| Barber, hair, makeup | Beauty, Fashion & Styling: `hair_styling`, `celebration_makeup`, roles Hair Stylist (kind Barbering), Makeup Artist | Add massage and spa here (section 4.3) |

## 2. Bugs first (block everything else)
1. **Proof upload is broken in the Individual path (screen F) and the Company path (CompanyDetailsStep, "Add proof" and company verification uploads).** Reproduce both, capture the exact error, report the root cause before fixing. Check in order: private bucket exists; storage RLS lets the owner insert under their own path; `provider_capability_evidence` insert policy or RPC; picker permissions (Android manifest, iOS Info.plist); JPG, PNG, PDF up to 5 MB; object key format; upload-then-record ordering and rollback; signed URL generation; swallowed errors; button disabled or missing `onPressed`. Both paths use ONE shared upload component with progress, success, and Retry. Tests: success, oversize, wrong type, offline, another user cannot read.
2. **Foreman proof upload** works end to end after the fix (Trade test certificate). This is the acceptance case.

## 3. Category list behaviour (screen B, Choose Category only; Home untouched)
1. **Active first.** Order: categories where the user has at least one capability or a saved identity (most recently updated first), then all others in catalog `sort_order`. Keep the green "N selected" badge. Record this as an approved change to B's ordering in the decisions log.
2. **Global search**, always visible at the top of B. It searches categories, capabilities, roles, kinds and aliases, in en, sw, fr, rw, ar, plus local terms. Results are grouped (Category, Service, Role, Kind) and each shows its parent category. Tapping a result opens B2 (or C/D if an identity exists) with that item pre-ticked. Add `aliases text[]` to the catalog tables (or a `v_catalog_search` view, additive). Debounce 250 ms. Empty state: "No match. Request a service", writing to `catalog_requests` (owner insert, admin read, no anon).
3. Starter aliases (extend as needed): foreman=supervisor,ganger; maid=house help,housegirl,dada,domestic worker; chauffeur=personal driver,executive driver; driving school=driving lessons,learn to drive,instructor; massage=masseuse,masseur,body rub (therapeutic only); spa=wellness,sauna,steam; nurse=sister,RN,enrolled nurse; doctor=physician,MD,medical officer; optician=optometrist,eye doctor,glasses; oncologist=cancer specialist; clinic=health centre,dispensary; angel investor=investor,seed funding,startup funding; duwa/duwah=(see 4.6, pending).

## 4. New catalog content (`sql/patch_catalog_expansion_v3.sql`, additive seeds, re-runnable)
Conventions: capabilities (`capability_type='service'`) are offered by Companies; roles (`'work'`, slug `work_<role>`) are personal profiles by Individuals (and optional for Companies). This follows the current identity rule: Individuals save roles only, Companies save services and roles. Each new item gets: slug, `ui_group_slug`, `sort_order`, `policy` (open / optional_proof / required_proof), aliases, l10n keys (en complete; sw, fr, rw, ar fall back and missing keys are listed). Each role gets kinds, a question, and qualifications with `required_evidence` flags and `expires_after_days` where noted.

### 4.1 New category 15: Domestic & Household (`domestic_household`)
Tagline: "House help, childcare, home cooking and care at home"
**Capabilities (Company / agency):**
| Group | Capability | Slug | Policy |
|---|---|---|---|
| Home help | Maids & House Help | `house_help_services` | optional_proof |
| Home help | Housekeeping & Cleaning | `housekeeping_services` | optional_proof |
| Home help | Laundry & Ironing | `laundry_services` | open |
| Home help | Gardening & Compound Care | `gardening_services` | open |
| Family | Nannies & Childcare | `childcare_nanny_services` | optional_proof |
| Family | Home Cooks | `home_cooking_services` | optional_proof |
| Family | Elderly Home Care | `elderly_home_care` | optional_proof |
| Other | Other Domestic | `other_domestic` | open |
**Roles (Individual):**
| Role (slug) | Question | Kinds | Qualifications (E = evidence) |
|---|---|---|---|
| House Help / Maid (`work_house_help`) | "What kind of help?" | Live-in · Live-out · Day work · Part-time · Cleaning only | National ID (E) · References · Experience 1+ year · Languages |
| Nanny / Childcare (`work_nanny`) | "Which ages?" | Newborn · Toddler · School age · Special needs | National ID (E) · Police clearance (E) · First aid (E) · Childcare certificate · References |
| Home Cook (`work_home_cook`) | "What do you cook?" | Family meals · Special diets · Event cooking · Baking | Food handler certificate (E) · References · Experience 2+ years |
| Gardener / Groundskeeper (`work_gardener`) | "What work?" | Lawn & garden · Landscaping · Compound security-free upkeep | Experience · References · Own tools |
| Home Carer (`work_home_carer`) | "Whom do you care for?" | Elderly · Disabled · Post-surgery | Caregiving certificate (E) · First aid (E) · National ID (E) · References |
Safety: show an "ID checked" badge only after admin approval; never show exact home addresses in any public view; nanny and home carer profiles default to `optional_proof` but the badge is the main trust signal (open decision O-3).

### 4.2 Transport & Logistics additions (existing category)
- New capabilities: Chauffeur Services `chauffeur_services` (optional_proof); Personal Driver Hire `personal_driver_hire` (optional_proof); Boda Boda / Motorcycle Taxi `boda_taxi_services` (optional_proof).
- Extend role **Driver** with new kinds (existing kinds untouched): Personal driver · Chauffeur (executive) · Boda rider · Airport / school runs. Add qualification "Chauffeur or executive driving experience" (no evidence) and "Certificate of good conduct" (E, optional).
- `driving_school` stays in Business & Professional; set its policy to `required_proof` (school licence, E, `expires_after_days` 365). Add role **Driving Instructor** (`work_driving_instructor`; kinds Cars · Motorcycles · Trucks · Defensive driving; qualifications Instructor licence (E), Valid driving licence (E), 2+ years teaching). Show it under Transport & Logistics, Education & Training and Business & Professional through `ui_group_slug`.

### 4.3 Beauty, Fashion & Styling additions (display label becomes "Beauty, Fashion, Styling & Wellness"; slug unchanged)
- Capabilities (new group "Wellness & Spa"): Massage Therapy `massage_therapy`; Spa Services `spa_services`; Salons & Barber Shops `salon_barber_services`; Nails & Skincare `nails_skincare_services`; Sauna & Steam `sauna_steam_services`. Policy: optional_proof; `spa_services` and `salon_barber_services` need business licence (E) for the verified badge.
- Roles: **Massage Therapist** (`work_massage_therapist`; "Which massage?"; kinds Relaxation · Deep tissue · Sports · Prenatal · Mobile / at-home; qualifications Massage therapy certificate (E), Hygiene certification (E), Own equipment, Experience 1+ year). **Spa Therapist** (`work_spa_therapist`; kinds Facials · Body treatments · Nails · Waxing; qualifications Cosmetology or spa certificate (E), Hygiene certification (E), Portfolio). **Spa / Wellness Manager** (`work_spa_manager`; kinds Spa · Salon · Wellness centre; qualifications Business licence (E), Managed 3+ staff).
- Content rule (non-negotiable): massage and spa listings are therapeutic and wellness services only. Listings, titles, photos or messages that offer or imply sexual services are rejected by moderation and can lead to removal. Show a one-line notice on the Massage and Spa sheets. Add a report action.

### 4.4 New category 16: Health & Medical (`health_medical`)
Tagline: "Nurses, doctors, specialists, clinics and care"
All items `required_proof`: inactive and invisible until the licence is admin-approved. Council registrations need `expires_after_days` 365.
**Capabilities (Company):**
| Group | Capability | Slug |
|---|---|---|
| Facilities | Clinics & Health Centres | `clinic_services` |
| Facilities | Hospitals | `hospital_services` |
| Facilities | Eye Clinics & Opticals | `eye_clinic_optical` |
| Facilities | Dental Clinics | `dental_clinic` |
| Facilities | Diagnostic Labs & Imaging | `diagnostic_lab` |
| Facilities | Pharmacies | `pharmacy_services` |
| Facilities | Physiotherapy Clinics | `physiotherapy_clinic` |
| Staffing & home care | Home Nursing Agencies | `home_nursing_agency` |
| Staffing & home care | Medical Staffing Agencies | `medical_staffing_agency` |
| Other | Other Health Services | `other_health` |
**Roles (Individual):**
| Role (slug) | Question | Kinds | Qualifications (E = evidence) |
|---|---|---|---|
| Nurse / Midwife (`work_nurse`) | "What nursing?" | General · Theatre · Paediatric · ICU / critical care · Midwifery · Community health | Nursing council registration (E, expires) · Diploma / degree (E) · Current practising certificate (E, expires) · 2+ years |
| Doctor (`work_doctor`) | "What do you practise?" | General practitioner · Surgeon · Emergency · Locum | Medical council registration (E, expires) · MBChB / MD (E) · Practising certificate (E, expires) · Internship completed |
| Clinical Officer / Clinician (`work_clinician`) | "What area?" | General clinical · Anaesthesia · Orthopaedic · Ophthalmic · Community | Clinical officers council registration (E, expires) · Diploma (E) · Practising licence (E, expires) |
| Medical Specialist (`work_medical_specialist`) | "Which specialty?" | Oncologist · Cardiologist · Paediatrician · Gynaecologist · Dermatologist · ENT · Neurologist · Orthopaedic surgeon · Urologist · Psychiatrist · Radiologist · Other specialist | Specialist registration (E, expires) · Postgraduate degree or fellowship (E) · Medical council registration (E, expires) · Years in specialty |
| Optician / Optometrist (`work_optometrist`) | "What do you do?" | Eye tests · Contact lenses · Dispensing optician · Low vision | Optometry registration (E, expires) · Diploma / degree (E) · Practising certificate (E, expires) |
| Dentist (`work_dentist`) | "What dentistry?" | General · Orthodontics · Oral surgery · Paediatric | Dental council registration (E, expires) · BDS (E) · Practising certificate (E, expires) |
| Pharmacist (`work_pharmacist`) | "Where do you work?" | Retail · Hospital · Dispensing · Locum | Pharmacy board registration (E, expires) · Degree (E) · Practising certificate (E, expires) |
| Lab Technician (`work_lab_technician`) | "What lab work?" | Medical lab · Radiography · Ultrasound | Lab council registration (E, expires) · Diploma (E) |
| Physiotherapist (`work_physiotherapist`) | "What therapy?" | Sports · Neuro · Paediatric · Geriatric · Home visits | Physiotherapy registration (E, expires) · Degree (E) · Practising certificate (E, expires) |
| Counsellor / Psychologist (`work_counsellor`) | "What support?" | Individual · Couples & family · Trauma · Child & adolescent | Counselling or psychology registration (E, expires) · Degree (E) · Supervised hours |
| Nursing Assistant / Caregiver (`work_nursing_assistant`) | "What care?" | Bedside · Home care · Elderly · Post-surgery | Nursing assistant certificate (E) · First aid (E) · National ID (E) |
Rules: nothing here is advertised until approved; Nipanze connects people only, gives no medical advice and takes no payment for care (non-custodial). Show a short neutral notice on the category sheet and in Need detail ("Nipanze does not provide medical advice or guarantee care"). A company registration never activates a medical service. Hire-person Needs for nurses and doctors reuse the existing hire-person Need with no new Home layout. Specialists and clinics are found by users through Needs, offers and the global search; a public directory is an open decision (O-6). Medical staffing needs country-specific council names: keep council names in l10n and country config, not in slugs. Needs legal and country review before launch (O-4).

### 4.5 New category 17: Business & Investment (`business_investment`)
Tagline: "Angel investors, mentors and startup support"
**Capabilities (Company / fund / syndicate):** Angel Investor Networks `angel_investor_network` (required_proof); Startup Advisory `startup_advisory` (optional_proof); Investor Introductions `investor_introductions` (required_proof); Incubators & Accelerators `incubator_accelerator` (required_proof); Other Investment Support `other_investment`.
**Roles (Individual):** **Angel Investor** (`work_angel_investor`; "Which sectors?"; kinds Technology · Agriculture · Retail & trade · Health · Energy · Real estate · Creative · General; qualifications Identity verification (E), Proof of investment track record or portfolio (E), Ticket size range, Stage focus (Idea · Seed · Early growth)). **Business Mentor** (`work_business_mentor`; kinds Startup · SME growth · Export · Agribusiness; qualifications Experience 5+ years, Case studies, Referees).
Rules: Nipanze only introduces people. It never holds, moves or pools money, gives investment advice, or promises returns. `financial_services` stays retired. Notice on the sheet and Need detail: "Nipanze does not hold funds, give investment advice or guarantee returns." Do not ship this category until legal review is done (O-4). Matching for a startup's Need ("Looking for an angel investor") uses sector and stage kinds, and the investor's ticket size is private until an offer is accepted.

### 4.6 New category 18: Traditional & Cultural Services (`traditional_cultural`)
Tagline: "Traditional ceremonies, prayers, healing and culture"
**Capabilities (Company / group):** Duwah Services `duwah_services` (optional_proof; wording and scope pending, O-1); Traditional Ceremonies `traditional_ceremony_services` (optional_proof); Traditional Dance & Drumming `traditional_dance_drumming` (open); Herbal & Traditional Healing `traditional_healing_herbal` (required_proof); Traditional Attire & Crafts `traditional_attire_crafts` (open); Other Traditional `other_traditional` (open).
**Roles (Individual):** **Duwah Practitioner** (`work_duwah_practitioner`; kinds to be confirmed in O-1; qualifications Community or religious endorsement letter (E, optional), References, Experience years). **Ceremony Officiant / Elder** (`work_ceremony_officiant`; kinds Introduction & marriage · Naming · Funeral & memorial · Cultural rites; qualifications Endorsement (E, optional), References). **Traditional Performer** (`work_traditional_performer`; kinds Dancer · Drummer · Singer · Storyteller; qualifications Showreel, Group membership). **Traditional Healer / Herbalist** (`work_traditional_healer`; `required_proof`; kinds Herbalist · Bone setter · Birth attendant; qualifications Registration with the relevant healers association or local authority (E, expires), Referees).
Rules: no claims of curing illness, no guarantees of outcomes, and listings that promise miracles or request payment for unverifiable claims are rejected by moderation. Show a short neutral notice on the healer sheet. Confirm local regulation (O-5).

### 4.7 Existing capabilities: policy proposals (do not change behaviour without my OK)
Inspect current verification requirements first and seed `policy` to match today's behaviour. Then propose, for my approval, `required_proof` for: `visa_assistance`, `travel_insurance`, `hajj_umrah`, `legal_services`, `medical_supplies`, `driving_school`, the Veterinary / Livestock Officer role; `optional_proof` for most others; `open` for simple hire and "Other" entries. Present as a table in the plan.

### 4.8 Totals after expansion
18 categories; about 62 new capabilities and 25 new roles, plus 3 capabilities and 1 role in existing categories, new kinds on Driver. Update the Summary table in `provider_services_catalog.md` and the legend: replace "✗ = Self-declared" with "No proof required" and "✅ = Evidence upload required".

### 4.9 Additions (round 2): circumcision, pregnancy care, HIV testing, bone and joint, coursework and projects

**Health & Medical (`health_medical`) additions, all `required_proof`:**
- Capabilities (Company): Circumcision Services (clinic and mobile) `circumcision_services`; Antenatal & Maternity Care `maternity_care_services`; Family Planning & Reproductive Health `family_planning_services`; HIV Testing & Counselling `hiv_testing_services`; Mobile Health Outreach (home visits) `mobile_health_outreach`; Orthopaedic & Bone Care `orthopaedic_care`.
- Role kinds added to existing roles (existing kinds untouched): Doctor and Clinical Officer get **Circumcision (adult and infant)**; Nurse / Midwife gets **Antenatal & postnatal care**, **Family planning** and **HIV testing & counselling**; Clinical Officer already has Orthopaedic. New role **HIV Counsellor / Testing Officer** (`work_hiv_counsellor`; "What do you do?"; kinds Testing & counselling · Peer educator · Community outreach; qualifications Counselling certificate (E), HIV testing and counselling training (E), Ministry of Health or facility authorisation (E, expires), National ID (E)).
- **Mobile / at-home services:** add `service_mode` to the profile metadata (values `at_facility`, `at_home`, `both`) and a "Comes to you" chip on offers. At-home circumcision and testing are allowed only for approved, licensed providers, with these extra proofs: facility or practising licence (E, expires), sterile equipment and infection-control declaration, emergency referral facility name. Show a notice: "Procedures need a licensed provider, consent, and a referral hospital for emergencies."
- **Circumcision rules:** medical circumcision only through licensed doctors, clinical officers or nurses/midwives authorised for it. Listings from unlicensed people are not activated. Infant and minor procedures require guardian consent; the listing shows this notice. Traditional or ritual circumcision is NOT listed in Health; if wanted, it goes under Traditional & Cultural as ceremony support with no procedure listed (confirm in O-9).
- **Pregnancy care rules:** the category supports licensed antenatal care, midwives, maternity clinics, pregnancy counselling, family planning, and **post-abortion and miscarriage care** (life-saving, lawful follow-up). Nipanze does **not** list or match abortion procedures, pills or "pregnancy termination" providers; moderation rejects such listings and Needs and shows a safe-care message instead ("Unsafe abortion can be life-threatening. Please see a licensed clinic or hospital."). Warning-signs notice on this category: heavy bleeding, severe pain, fever or fainting means go to a hospital at once. Youth-friendly: allow providers to mark "youth-friendly", never show a Need's details publicly, and contact is revealed only after accept.
- **HIV testing rules:** testing and counselling only from authorised providers; results are never handled, stored or sent through Nipanze. Needs and offers for testing are private by default: no public listing text that names the condition, contact reveal only after accept, and no health detail in notifications or any public view. Also allow listings for PrEP and PEP referral as "referral" only.
- **Bone and joint:** `orthopaedic_care` (Company); aliases for search: bone doctor, fracture, broken bone, back pain, joint pain, knee, arthritis, X-ray, physio. Medical Specialist kind **Orthopaedic surgeon** and the Physiotherapist role already cover individuals.
- **Search aliases (add):** circumcision=male circumcision,VMMC,cut,mobile circumcision; pregnancy=antenatal,ANC,maternity,midwife,expecting,prenatal,delivery,family planning,contraception,post-abortion care; HIV=HIV test,HCT,VCT,PrEP,PEP,STI test,sexual health; bone=orthopaedic,fracture,joint.

**Education & Training (`education_training`) additions for coursework and final year projects (Company or Individual via roles):**
- Capabilities (Company): Final Year Project Support `final_year_project_support` (optional_proof); Research Proposal & Dissertation Guidance `research_dissertation_guidance` (optional_proof); Data Analysis & Statistics Help `data_analysis_help` (open); Proofreading & Editing `proofreading_editing` (open); Coursework Tutoring `coursework_tutoring` (open). Existing `academic_consulting` and `private_tutoring` stay.
- New role **Project / Research Mentor** (`work_research_mentor`; "What do you help with?"; kinds Final year project · Dissertation or thesis · Research proposal · Data analysis (SPSS, R, Excel, Stata) · Proofreading & editing · Presentation & defence coaching · Software/IT project guidance; qualifications Degree in the field (E, optional), Master's or PhD (E, optional), Published work or portfolio, Subject specialisation, References).
- **Academic integrity rule (non-negotiable):** the service is guidance, tutoring, mentoring, editing and analysis help. Listings or Needs that offer to write, sell or submit work as the student's own (ghost-writing, "we do your assignment/exam/thesis") are rejected by moderation. Show a notice on the sheet: "Get guidance and feedback. Submitting someone else's work as your own can get you expelled." Add a report action.
- **Search aliases (add):** course work=coursework,assignment help,homework; final year project=FYP,capstone,project defence; dissertation=thesis,research paper,proposal; data analysis=SPSS,statistics,STATA.

**Updated totals:** 6 new health capabilities and 1 role, plus kinds; 5 new education capabilities and 1 role. Recompute the Summary table in `provider_services_catalog.md` after seeding.

## 5. Process
Inspect and report first (no code): upload bug root cause on both paths; the live DB catalog vs `provider_services_catalog.md` (slug diff); alias and `ui_group_slug` plan; counts of rows affected (should be zero for existing users); file-by-file plan; risks; open questions. Wait for OK. Then phases, each a small PR with `flutter analyze`, `flutter test`, SQL checks, Home baseline diff, "how to try it", tracker update:
P1 upload fix (shared component, both paths, Foreman acceptance) | P2 catalog patch, aliases, ui groups, policy column, l10n | P3 active-first ordering | P4 global search + catalog_requests | P5 sensitive-category rules, notices, moderation hooks (Health, Investment, Traditional, Massage/Spa, Domestic) | P6 localization, a11y, RTL, dark mode, 360px, tests, BUILD_PLAN and catalog doc update.

## 6. Tests (add to the tracker)
| Area | Case |
|---|---|
| Upload | Individual (screen F) and Company (CompanyDetailsStep): success, progress, retry, oversize, wrong type, offline; other user cannot read; Foreman trade test certificate end to end |
| Catalog | Every new slug present; no existing slug renamed or removed; re-run changes nothing; existing users' capabilities untouched |
| Ordering | Categories with capabilities sort first (recent first), others keep catalog order; badge unchanged |
| Search | "foreman", "duwa", "maid", "chauffeur", "driving school", "massage", "spa", "nurse", "optician", "oncologist", "angel investor" each find the right item from any category and open B2/C/D with it ticked; kinds and aliases searchable; sw/fr/ar labels searchable |
| Identity | Individual can save new roles, not new services; Company can save both; atomic bulk save; soft cap 30 |
| Policy | required_proof items (all Health, driving_school, angel investor network, healers) are inactive and receive no offers until approved; open and optional items active at once; no "Self-declared" label anywhere |
| Expiry | Council registration expires after 365 days and deactivates only that capability |
| Safety | Massage and spa listings with sexual content are rejected; medical, investment and healer notices shown; no exact home address, ticket size or evidence in public views |
| Needs | Hire-person Needs for nurse, doctor, maid, driver, massage therapist, angel investor create and match through the existing Need, Offer, Accept, Contact flow |
| Localization | 5 locales (missing keys listed), RTL, dark, 360px, 200% text |
| Home protection | Snapshots (4 tabs, light/dark, 360px), view and RPC columns, feed results identical to baseline; no Home file in the diff |
| Regression | Loans, Forex, Needs, offers, accept, contact reveal, trust, watchlist, discovery plans, expiry unchanged |

## 7. Open questions (recommend, then wait)
- O-1 What exactly is Duwah, and which kinds and qualifications belong under it? (Needed before seeding its role kinds.)
- O-2 Chauffeur and driver: keep inside Transport (this plan) or add a separate "Drivers & Chauffeurs" category for discoverability? (Recommended: keep inside, rely on search and aliases.)
- O-3 Nanny and home carer: `optional_proof` with an ID-checked badge (this plan) or `required_proof` police clearance? (Recommended: required for nanny, optional for the rest.)
- O-4 Legal review: medical licensing by country, and angel investor introductions. Block launch of those two categories until done.
- O-5 Traditional healing regulation by country.
- O-6 Public directory pages for specialists and clinics, or discovery only through Needs, offers and search? (Recommended: discovery only for now.)
- O-7 Angel investor is usually an individual: this plan models it as a personal role plus a Company network service. Alternatively allow Individuals to list services in this one category. (Recommended: personal role.)
- O-9 Traditional (ritual) circumcision: leave out entirely, or allow only as ceremony support under Traditional & Cultural with no procedure? (Recommended: leave out of launch.)
- O-10 Pregnancy and abortion: confirm that Nipanze lists only licensed antenatal, counselling, family planning and post-abortion care, and rejects any abortion provider listing. Needs local legal review. (Recommended: yes.)
- O-11 HIV testing Needs: private by default with no public text, contact reveal only after accept. Confirm. (Recommended: yes.)
- O-12 Mobile at-home medical services: allow at launch for licensed providers only, or facility-only first? (Recommended: facility-only first, mobile in a second release.)
- O-13 Academic help: confirm the guidance-only rule and moderation of "we do your assignment" listings. (Recommended: yes.)
- O-8 Show the 4 new categories at launch or behind per-category flags `work_profiles_enabled_<slug>` and a catalog flag so they can be released one at a time? (Recommended: per-category flags.)
