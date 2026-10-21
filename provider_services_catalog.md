# Nipanze Provider Services Catalog

> Current repository catalog reference. Generated from [`provider_services_v2.json`](./provider_services_v2.json); rollout state comes from the SQL seed. A deployed database may differ if patches or flags have not been applied.

> **Provider identity rule:** Individual profiles select work roles. Company / Organization profiles select services only; the Company setup screen has no roles section.

**Catalog size:** 18 categories · 178 services · 90 Individual roles.

Policies: `open` = a provider profile can be active without proof; `optional_proof` = the profile can be active while proof may be reviewed for a badge; `required_proof` = the provider profile remains inactive until required proof is approved. The catalog entry itself may still be available for selection. “Configured by verification rules” identifies existing capabilities whose policy is supplied separately.

## Categories at a glance

| # | Category | Status | Services | Individual roles |
|---:|---|---|---:|---:|
| 1 | [Technology & Digital](#1-technology-and-digital) | Available | 8 | 5 |
| 2 | [Marketing & Promotion](#2-marketing-and-promotion) | Available | 11 | 4 |
| 3 | [Business & Professional Services](#3-business-and-professional-services) | Available | 9 | 8 |
| 4 | [Education & Training](#4-education-and-training) | Available | 17 | 5 |
| 5 | [Events & Celebrations](#5-events-and-celebrations) | Available | 11 | 5 |
| 6 | [Photo, Video, Music & Talent](#6-photo-video-music-and-talent) | Available | 12 | 4 |
| 7 | [Beauty, Fashion, Styling & Wellness](#7-beauty-fashion-styling-and-wellness) | Available | 10 | 7 |
| 8 | [Construction & Building](#8-construction-and-building) | Available | 9 | 5 |
| 9 | [Energy & Water](#9-energy-and-water) | Available | 9 | 4 |
| 10 | [Transport & Logistics](#10-transport-and-logistics) | Available | 13 | 5 |
| 11 | [Machinery & Equipment](#11-machinery-and-equipment) | Available | 8 | 4 |
| 12 | [Agriculture & Agribusiness](#12-agriculture-and-agribusiness) | Available | 6 | 4 |
| 13 | [Procurement & Sourcing](#13-procurement-and-sourcing) | Available | 9 | 3 |
| 14 | [Travel & International](#14-travel-and-international) | Available | 11 | 4 |
| 15 | [Domestic & Household](#15-domestic-and-household) | Inactive (rollout gated) | 8 | 5 |
| 16 | [Health & Medical](#16-health-and-medical) | Inactive (rollout gated) | 16 | 12 |
| 17 | [Business & Investment](#17-business-and-investment) | Inactive (rollout gated) | 5 | 2 |
| 18 | [Traditional & Cultural Services](#18-traditional-and-cultural-services) | Inactive (rollout gated) | 6 | 4 |

## Full catalog

## 1. 💻 Technology & Digital

**Status:** Available
**Database slug:** `technology_digital`
**Description:** Software, websites, IT support and security

### Services

#### Build

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Software Development | `software_development` | `software_development` | Available | `Configured by verification rules` |
| Website Development | `website_development` | `website_development` | Available | `Configured by verification rules` |
| Mobile App Development | `mobile_app_development` | `mobile_app_development` | Available | `Configured by verification rules` |
| Automation | `automation_services` | `automation` | Available | `Configured by verification rules` |

#### Support & Infrastructure

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| IT Support | `it_support` | `it_support` | Available | `Configured by verification rules` |
| Networking | `networking_services` | `networking` | Available | `Configured by verification rules` |
| Cybersecurity | `cybersecurity_services` | `cybersecurity` | Available | `Configured by verification rules` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Technology | `other_technology` | `other_technology` | Available | `Configured by verification rules` |

### Individual roles

#### Developer

**Database slug:** `work_developer`
**Status:** Available
**Question:** What do you build?
**Kinds:** Frontend · Backend · Full-stack · Mobile · QA / Tester · DevOps

| Qualification | Evidence required |
|---|---|
| Degree / Diploma in IT or CS | No |
| Portfolio or GitHub link | No |
| Cloud certification (AWS/Azure/GCP) | No |
| 3+ years experience | No |

#### IT Technician

**Database slug:** `work_it_technician`
**Status:** Available
**Question:** What do you do?
**Kinds:** Helpdesk · Hardware repair · Network installation · CCTV & access control

| Qualification | Evidence required |
|---|---|
| CompTIA A+ / N+ | No |
| CCNA | No |
| Own toolkit | No |
| 2+ years experience | No |

#### Security Specialist

**Database slug:** `work_security_specialist`
**Status:** Available
**Question:** Which area?
**Kinds:** Network security · Penetration testing · Security audits

| Qualification | Evidence required |
|---|---|
| CEH | No |
| CISSP / CISM | No |
| ISO 27001 | No |
| Police clearance | No |

#### Project Manager

**Database slug:** `work_project_manager`
**Status:** Available
**Question:** What kind of projects?
**Kinds:** Software · IT infrastructure · Digital transformation

| Qualification | Evidence required |
|---|---|
| PMP / PRINCE2 | No |
| Agile / Scrum certified | No |
| Led 3+ projects | No |
| Degree | No |

#### Team Lead / Manager

**Database slug:** `work_team_lead_manager`
**Status:** Available
**Question:** What do you lead?
**Kinds:** Dev team · IT / support team · Product

| Qualification | Evidence required |
|---|---|
| Managed 5+ people | No |
| Degree | No |
| 3+ years leadership | No |

## 2. 📣 Marketing & Promotion

**Status:** Available
**Database slug:** `marketing_promotion`
**Description:** Advertising, content and influencer work

### Services

#### Campaigns

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Digital Marketing | `digital_marketing` | `digital_marketing` | Available | `Configured by verification rules` |
| Social Media Marketing | `social_media_marketing` | `social_media_marketing` | Available | `Configured by verification rules` |
| Advertising Campaigns | `advertising_campaigns` | `advertising_campaigns` | Available | `Configured by verification rules` |
| Brand Promotion | `brand_promotion` | `brand_promotion` | Available | `Configured by verification rules` |
| Event Promotion | `event_promotion` | `event_promotion` | Available | `Configured by verification rules` |
| Affiliate Marketing | `affiliate_marketing` | `affiliate_marketing` | Available | `Configured by verification rules` |

#### Content & Reach

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Content Creation | `content_creation` | `content_creation` | Available | `Configured by verification rules` |
| Influencer Marketing | `influencer_marketing` | `influencer_marketing` | Available | `Configured by verification rules` |
| Product Reviews | `product_reviews` | `product_reviews` | Available | `Configured by verification rules` |
| I Have an Audience | `i_have_an_audience` | `i_have_an_audience` | Available | `Configured by verification rules` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Marketing Services | `other_marketing_services` | `other_marketing_services` | Available | `Configured by verification rules` |

### Individual roles

#### Marketer / Specialist

**Database slug:** `work_marketer_specialist`
**Status:** Available
**Question:** Which channel?
**Kinds:** Social media · SEO / SEM · Email · Brand · Community management

| Qualification | Evidence required |
|---|---|
| Marketing diploma / degree | No |
| Google Ads / Meta certified | No |
| Case studies or portfolio | No |
| 2+ years experience | No |

#### Content Creator

**Database slug:** `work_content_creator`
**Status:** Available
**Question:** What do you produce?
**Kinds:** Video · Photo · Writing · Design · Podcast

| Qualification | Evidence required |
|---|---|
| Portfolio | No |
| Own equipment | No |
| Audience size proof | No |

#### Marketing Manager

**Database slug:** `work_marketing_manager`
**Status:** Available
**Question:** What scope?
**Kinds:** Brand · Digital · Events & promotions

| Qualification | Evidence required |
|---|---|
| Degree | No |
| Managed budgets | No |
| Managed 3+ people | No |

#### Campaign Project Manager

**Database slug:** `work_campaign_project_manager`
**Status:** Available
**Question:** Campaign type?
**Kinds:** Digital · Field / activation · Event

| Qualification | Evidence required |
|---|---|
| PMP / PRINCE2 | No |
| Led 3+ campaigns | No |

## 3. 💼 Business & Professional Services

**Status:** Available
**Database slug:** `professional_services`
**Description:** Consulting, legal, accounting, HR and design

### Services

#### Finance & Legal

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Accounting & Tax | `accounting_tax` | `accounting_tax` | Available | `Configured by verification rules` |
| Legal Services | `legal_services` | `legal_services` | Available | `Configured by verification rules` |
| Company Registration | `company_registration` | `company_registration` | Available | `Configured by verification rules` |

#### Advisory

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Business Consulting | `business_consulting` | `business_consulting` | Available | `Configured by verification rules` |
| HR Services | `hr_services` | `hr_services` | Available | `Configured by verification rules` |

#### Design & Engineering

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Architecture | `architecture_services` | `architecture` | Available | `Configured by verification rules` |
| Engineering | `engineering_consulting` | `engineering` | Available | `Configured by verification rules` |
| Driving School / Driver Training | `driving_school_driver_training` | `driving_school_driver_training` | Available | `required_proof` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Professional Services | `other_professional` | `other_professional_services` | Available | `Configured by verification rules` |

### Individual roles

#### Accountant / Finance Officer

**Database slug:** `work_accountant_finance_officer`
**Status:** Available
**Question:** What area?
**Kinds:** Bookkeeping · Tax · Audit · Payroll

| Qualification | Evidence required |
|---|---|
| CPA / ACCA / CPA-U | No |
| Degree | No |
| Practising certificate | No |
| 3+ years experience | No |

#### Lawyer / Legal Officer

**Database slug:** `work_lawyer_legal_officer`
**Status:** Available
**Question:** What area?
**Kinds:** Corporate · Property · Contracts · Compliance

| Qualification | Evidence required |
|---|---|
| Bar admission / practising certificate | No |
| LLB | No |
| 3+ years experience | No |

#### Engineer

**Database slug:** `work_engineer`
**Status:** Available
**Question:** Which discipline?
**Kinds:** Civil · Electrical · Mechanical · Mining

| Qualification | Evidence required |
|---|---|
| Degree in engineering | No |
| Registered with engineers board | No |
| Site experience | No |

#### Architect / Designer

**Database slug:** `work_architect_designer`
**Status:** Available
**Question:** What do you design?
**Kinds:** Buildings · Interiors · Landscape

| Qualification | Evidence required |
|---|---|
| Registered architect | No |
| Portfolio | No |
| CAD/BIM skills | No |

#### HR Officer / Manager

**Database slug:** `work_hr_officer_manager`
**Status:** Available
**Question:** What area?
**Kinds:** Recruitment · Payroll & benefits · Training & compliance

| Qualification | Evidence required |
|---|---|
| HR diploma / degree | No |
| IHRM / CIPD | No |
| 3+ years experience | No |

#### Business Administrator / Office Manager

**Database slug:** `work_business_administrator_office_manager`
**Status:** Available
**Question:** What kind of admin work?
**Kinds:** Office administration · Operations support · Executive assistant · Records & documentation

| Qualification | Evidence required |
|---|---|
| Diploma / degree in business administration | No |
| Office software skills (documents, spreadsheets, email) | No |
| 2+ years experience | No |
| References | No |

#### Consultant

**Database slug:** `work_consultant`
**Status:** Available
**Question:** Advisory area?
**Kinds:** Strategy · Operations · Finance · Compliance

| Qualification | Evidence required |
|---|---|
| Degree | No |
| Case studies | No |
| 5+ years experience | No |

#### Project Manager

**Database slug:** `work_professional_services_project_manager`
**Status:** Available
**Question:** What kind of projects?
**Kinds:** Business · Compliance · Operations

| Qualification | Evidence required |
|---|---|
| PMP / PRINCE2 | No |
| Led 3+ projects | No |

## 4. 🎓 Education & Training

**Status:** Available
**Database slug:** `education_training`
**Description:** Learning, admissions and placements

### Services

#### Learning

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Private Tutoring | `private_tutoring` | `private_tutoring` | Available | `Configured by verification rules` |
| Online Classes | `online_classes` | `online_classes` | Available | `Configured by verification rules` |
| Exam Preparation | `exam_preparation` | `exam_preparation` | Available | `Configured by verification rules` |
| Language Training | `language_training` | `language_training` | Available | `Configured by verification rules` |
| Computer Training | `computer_training` | `computer_training` | Available | `Configured by verification rules` |
| Professional Training | `professional_training` | `professional_training` | Available | `Configured by verification rules` |
| Vocational Training | `vocational_training` | `vocational_training` | Available | `Configured by verification rules` |
| Academic Consulting | `academic_consulting` | `academic_consulting` | Available | `Configured by verification rules` |

#### Admissions & Placements

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| University Admissions | `university_admissions` | `university_admissions` | Available | `Configured by verification rules` |
| Study Abroad Guidance | `study_abroad_guidance` | `study_abroad_guidance` | Available | `Configured by verification rules` |
| Internship Placement | `internship_placement` | `internship_placement` | Available | `Configured by verification rules` |
| Health / Nursing Placements | `health_nursing_placements` | `health_nursing_placements` | Available | `Configured by verification rules` |

#### Coursework & projects

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Final Year Project Support | `final_year_project_support` | `final_year_project_support`; aliases: FYP, capstone, project defence | Available | `optional_proof` |
| Research Proposal & Dissertation Guidance | `research_dissertation_guidance` | `research_dissertation_guidance`; aliases: thesis, research paper, proposal | Available | `optional_proof` |
| Data Analysis & Statistics Help | `data_analysis_help` | `data_analysis_help`; aliases: SPSS, statistics, STATA | Available | `open` |
| Proofreading & Editing | `proofreading_editing` | `proofreading_editing`; aliases: editing | Available | `open` |
| Coursework Tutoring | `coursework_tutoring` | `coursework_tutoring`; aliases: course work, coursework, assignment help, homework | Available | `open` |

### Individual roles

#### Teacher / Tutor

**Database slug:** `work_teacher_tutor`
**Status:** Available
**Question:** What do you teach?
**Kinds:** Primary · Secondary · University · Languages · Exam prep

| Qualification | Evidence required |
|---|---|
| Teaching certificate / degree | No |
| Registered with teaching board | No |
| 2+ years teaching | No |
| Subject specialisation | No |

#### Trainer / Instructor

**Database slug:** `work_trainer_instructor`
**Status:** Available
**Question:** Training field?
**Kinds:** Computer / IT · Vocational / technical · Professional / corporate · Driving

| Qualification | Evidence required |
|---|---|
| Trade certificate | No |
| Trainer-of-trainers (ToT) | No |
| Industry experience 3+ years | No |

#### Placement Coordinator

**Database slug:** `work_placement_coordinator`
**Status:** Available
**Question:** What placements?
**Kinds:** Internships · Nursing / health · Study abroad · University

| Qualification | Evidence required |
|---|---|
| Education or HR background | No |
| Partner network | No |
| Counselling certificate | No |

#### Programme Manager

**Database slug:** `work_programme_manager`
**Status:** Available
**Question:** What programmes?
**Kinds:** Training programmes · Placement programmes

| Qualification | Evidence required |
|---|---|
| Degree | No |
| Managed 3+ programmes | No |

#### Project / Research Mentor

**Database slug:** `work_research_mentor`
**Status:** Available
**Question:** What do you help with?
**Verification policy:** `optional_proof`
**Aliases:** FYP, capstone, thesis, research paper, proposal
**Kinds:** Final year project · Dissertation or thesis · Research proposal · Data analysis (SPSS, R, Excel, Stata) · Proofreading & editing · Presentation & defence coaching · Software/IT project guidance

| Qualification | Evidence required |
|---|---|
| Degree in the field | Yes |
| Master’s or PhD | Yes |
| Published work or portfolio | No |
| Subject specialisation | No |
| References | No |

## 5. 🎉 Events & Celebrations

**Status:** Available
**Database slug:** `events_production`
**Description:** Weddings, parties, corporate events and the services behind them

### Services

#### Planning & Styling

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Event Planning | `event_planning` | `event_planning` | Available | `Configured by verification rules` |
| Decoration | `event_decoration` | `decoration` | Available | `Configured by verification rules` |
| Cakes | `celebration_cakes` | `cakes` | Available | `Configured by verification rules` |
| Catering | `celebration_catering` | `catering` | Available | `Configured by verification rules` |

#### Equipment & Venue Setup

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Tents | `tent_hire` | `tents` | Available | `Configured by verification rules` |
| Event Equipment | `event_equipment` | `event_equipment` | Available | `Configured by verification rules` |
| Sound Systems | `sound_systems` | `sound_systems` | Available | `Configured by verification rules` |
| Lighting | `lighting_hire` | `lighting` | Available | `Configured by verification rules` |

#### Entertainment & Hosting

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| DJs / MCs | `celebration_mc_dj` | `djs_mcs` | Available | `Configured by verification rules` |
| Event Transport | `event_transport` | `event_transport` | Available | `Configured by verification rules` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Events | `other_events` | `other_events` | Available | `Configured by verification rules` |

### Individual roles

#### Event Manager / Planner

**Database slug:** `work_event_manager_planner`
**Status:** Available
**Question:** What events?
**Kinds:** Weddings · Corporate · Birthdays & parties · Graduations · Funerals & memorials

| Qualification | Evidence required |
|---|---|
| Event planning certificate | No |
| Portfolio of 5+ events | No |
| Insurance / permit | No |
| Team of 3+ staff | No |

#### MC / DJ

**Database slug:** `work_mc_dj`
**Status:** Available
**Question:** Which role?
**Kinds:** MC · DJ · Both

| Qualification | Evidence required |
|---|---|
| Own equipment | No |
| Sample mix / video | No |
| References | No |

#### Event Crew / Technician

**Database slug:** `work_event_crew_technician`
**Status:** Available
**Question:** What do you operate?
**Kinds:** Sound · Lighting · Tents & setup · Stage

| Qualification | Evidence required |
|---|---|
| Technical training | No |
| Own tools | No |
| Event experience 1+ year | No |

#### Caterer / Chef

**Database slug:** `work_caterer_chef`
**Status:** Available
**Question:** What kind?
**Kinds:** Event catering · Cakes & baking · Buffet / plated

| Qualification | Evidence required |
|---|---|
| Food handler certificate | No |
| Health permit | No |
| Culinary diploma | No |

#### Event Supervisor

**Database slug:** `work_event_supervisor`
**Status:** Available
**Question:** What scope?
**Kinds:** Venue · Logistics · Guest management

| Qualification | Evidence required |
|---|---|
| Managed 5+ events | No |
| Team leadership | No |

## 6. 🎬 Photo, Video, Music & Talent

**Status:** Available
**Database slug:** `photo_video_music_talent`
**Description:** Creative production and performers for any occasion

### Services

#### Photo & Video

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Photography | `photography_services` | `photography` | Available | `Configured by verification rules` |
| Videography | `videography_services` | `videography` | Available | `Configured by verification rules` |
| Video Editors | `video_editors` | `video_editors` | Available | `Configured by verification rules` |

#### Music Production

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Recording Studios | `recording_studios` | `recording_studios` | Available | `Configured by verification rules` |
| Music Producers | `music_producers` | `music_producers` | Available | `Configured by verification rules` |
| Mixing & Mastering | `mixing_mastering` | `mixing_mastering` | Available | `Configured by verification rules` |
| Songwriters | `songwriters` | `songwriters` | Available | `Configured by verification rules` |
| Singers / Vocalists | `singers_vocalists` | `singers_vocalists` | Available | `Configured by verification rules` |

#### On-screen & Performers

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Actors / Actresses | `actors_actresses` | `actors_actresses` | Available | `Configured by verification rules` |
| Dancers | `dancers` | `dancers` | Available | `Configured by verification rules` |
| Background Extras | `background_extras` | `background_extras` | Available | `Configured by verification rules` |
| Music Video Models | `music_video_models` | `music_video_models` | Available | `Configured by verification rules` |

### Individual roles

#### Photographer / Videographer

**Database slug:** `work_photographer_videographer`
**Status:** Available
**Question:** What do you shoot?
**Kinds:** Weddings · Corporate · Fashion & portraits · Music videos · Real estate · Graduations

| Qualification | Evidence required |
|---|---|
| Portfolio link | No |
| Own camera / drone kit | No |
| Drone licence | No |
| Editing skills | No |

#### Audio Engineer / Producer

**Database slug:** `work_audio_engineer_producer`
**Status:** Available
**Question:** What do you do?
**Kinds:** Recording · Mixing & mastering · Beat production · Live sound

| Qualification | Evidence required |
|---|---|
| Own studio / DAW | No |
| Portfolio | No |
| Audio engineering diploma | No |

#### Performer / Talent

**Database slug:** `work_performer_talent`
**Status:** Available
**Question:** What kind?
**Kinds:** Singer · Dancer · Actor · Model · Extra

| Qualification | Evidence required |
|---|---|
| Showreel / audition clip | No |
| Agency representation | No |
| Performance experience | No |

#### Production Manager

**Database slug:** `work_production_manager`
**Status:** Available
**Question:** What productions?
**Kinds:** Video / film · Music · Live events

| Qualification | Evidence required |
|---|---|
| Managed 3+ productions | No |
| Budget handling | No |
| Crew network | No |

## 7. 💄 Beauty, Fashion, Styling & Wellness

**Status:** Available
**Database slug:** `beauty_fashion_styling`
**Description:** Makeup, hair, styling, clothing, massage, spa, and wellness services

### Services

#### Beauty

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Makeup Artists | `celebration_makeup` | `makeup_artists` | Available | `Configured by verification rules` |
| Hair Stylists | `hair_styling` | `hair_stylists` | Available | `Configured by verification rules` |

#### Fashion

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Bridal Styling | `bridal_styling` | `bridal_styling` | Available | `Configured by verification rules` |
| Stylists | `music_video_stylists` | `stylists` | Available | `Configured by verification rules` |
| Wedding Dresses / Bridesmaid Outfits | `dresses_bridesmaid_outfits` | `wedding_dresses_bridesmaid_outfits` | Available | `Configured by verification rules` |

#### Wellness & Spa

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Massage Therapy | `massage_therapy` | `massage_therapy`; aliases: massage, masseuse, masseur, therapeutic body rub | Available | `optional_proof` |
| Spa Services | `spa_services` | `spa_services`; aliases: wellness, sauna, steam | Available | `optional_proof` |
| Salons & Barber Shops | `salon_barber_services` | `salon_barber_services`; aliases: salon, barber, barbershop | Available | `optional_proof` |
| Nails & Skincare | `nails_skincare_services` | `nails_skincare_services`; aliases: manicure, pedicure, skincare | Available | `optional_proof` |
| Sauna & Steam | `sauna_steam_services` | `sauna_steam_services`; aliases: sauna, steam room | Available | `optional_proof` |

### Individual roles

#### Makeup Artist

**Database slug:** `work_makeup_artist`
**Status:** Available
**Question:** Specialty?
**Kinds:** Bridal · Fashion / editorial · Film / stage · Everyday

| Qualification | Evidence required |
|---|---|
| Cosmetology certificate | No |
| Portfolio | No |
| Own kit | No |
| Hygiene certification | No |

#### Hair Stylist

**Database slug:** `work_hair_stylist`
**Status:** Available
**Question:** Specialty?
**Kinds:** Braiding · Salon styling · Bridal hair · Barbering

| Qualification | Evidence required |
|---|---|
| Cosmetology certificate | No |
| Portfolio | No |
| Salon licence | No |

#### Stylist / Designer

**Database slug:** `work_stylist_designer`
**Status:** Available
**Question:** Specialty?
**Kinds:** Wardrobe styling · Tailoring · Bridal wear

| Qualification | Evidence required |
|---|---|
| Fashion diploma | No |
| Portfolio | No |
| Own workshop | No |

#### Salon / Studio Manager

**Database slug:** `work_salon_studio_manager`
**Status:** Available
**Question:** What scope?
**Kinds:** Salon · Fashion studio

| Qualification | Evidence required |
|---|---|
| Managed 3+ staff | No |
| Business licence | No |

#### Massage Therapist

**Database slug:** `work_massage_therapist`
**Status:** Available
**Question:** Which massage?
**Verification policy:** `optional_proof`
**Aliases:** masseuse, masseur
**Kinds:** Relaxation · Deep tissue · Sports · Prenatal · Mobile / at-home

| Qualification | Evidence required |
|---|---|
| Massage therapy certificate | Yes |
| Hygiene certification | Yes |
| Own equipment | No |
| Experience 1+ year | No |

#### Spa Therapist

**Database slug:** `work_spa_therapist`
**Status:** Available
**Question:** What treatments?
**Verification policy:** `optional_proof`
**Kinds:** Facials · Body treatments · Nails · Waxing

| Qualification | Evidence required |
|---|---|
| Cosmetology or spa certificate | Yes |
| Hygiene certification | Yes |
| Portfolio | No |

#### Spa / Wellness Manager

**Database slug:** `work_spa_manager`
**Status:** Available
**Question:** What do you manage?
**Verification policy:** `optional_proof`
**Kinds:** Spa · Salon · Wellness centre

| Qualification | Evidence required |
|---|---|
| Business licence | Yes |
| Managed 3+ staff | No |

## 8. 🏗️ Construction & Building

**Status:** Available
**Database slug:** `construction_building`
**Description:** Contractors, trades and surveying

### Services

#### Contracting

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Building Contractors | `building_contractors` | `building_contractors` | Available | `Configured by verification rules` |
| Roofing | `roofing_services` | `roofing` | Available | `Configured by verification rules` |
| Excavation | `excavation_works` | `excavation` | Available | `Configured by verification rules` |
| Concrete | `concrete_works` | `concrete` | Available | `Configured by verification rules` |

#### Trades

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Plumbing | `plumbing_services` | `plumbing` | Available | `Configured by verification rules` |
| Electrical Works | `electrical_works` | `electrical_works` | Available | `Configured by verification rules` |

#### Materials & Survey

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Construction Materials | `construction_materials` | `construction_materials` | Available | `Configured by verification rules` |
| Surveying | `surveying_services` | `surveying` | Available | `Configured by verification rules` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Construction | `other_construction` | `other_construction` | Available | `Configured by verification rules` |

### Individual roles

#### Site Manager

**Database slug:** `work_site_manager`
**Status:** Available
**Question:** What type of sites?
**Kinds:** Residential · Commercial · Infrastructure

| Qualification | Evidence required |
|---|---|
| Civil/Construction diploma or degree | No |
| Registered with engineers/contractors board | No |
| 5+ years on site | No |
| Safety certification (OSHA) | No |

#### Project Manager

**Database slug:** `work_construction_building_project_manager`
**Status:** Available
**Question:** What kind of projects?
**Kinds:** Residential · Commercial · Roads & civil

| Qualification | Evidence required |
|---|---|
| PMP / PRINCE2 | No |
| Degree | No |
| Delivered 3+ projects | Not specified in JSON |

#### Foreman / Supervisor

**Database slug:** `work_foreman_supervisor`
**Status:** Available
**Question:** Which trade?
**Kinds:** Masonry · Roofing · Concrete · Finishing

| Qualification | Evidence required |
|---|---|
| Trade test certificate | No |
| Managed 10+ workers | No |
| Safety training | No |

#### Skilled Tradesperson

**Database slug:** `work_skilled_tradesperson`
**Status:** Available
**Question:** Which trade?
**Kinds:** Mason · Plumber · Electrician · Carpenter · Welder · Painter · Roofer

| Qualification | Evidence required |
|---|---|
| Trade test (Grade I/II/III) | No |
| Licence (electrical/plumbing) | No |
| Own tools | No |
| 2+ years experience | No |

#### Surveyor

**Database slug:** `work_surveyor`
**Status:** Available
**Question:** What type?
**Kinds:** Land · Quantity · Topographic

| Qualification | Evidence required |
|---|---|
| Registered surveyor | No |
| Degree / diploma | No |
| Own instruments | No |

## 9. ⚡ Energy & Water

**Status:** Available
**Database slug:** `energy_utilities`
**Description:** Solar, power backup, boreholes and water systems

### Services

#### Power

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Solar Systems | `solar_systems` | `solar_systems` | Available | `Configured by verification rules` |
| Batteries | `battery_supply` | `batteries` | Available | `Configured by verification rules` |
| Backup Power | `backup_power` | `backup_power` | Available | `Configured by verification rules` |
| Generators | `generator_supply` | `generators` | Available | `Configured by verification rules` |
| Electrical Installation | `electrical_installation` | `electrical_installation` | Available | `Configured by verification rules` |

#### Water

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Boreholes | `borehole_drilling` | `boreholes` | Available | `Configured by verification rules` |
| Water Systems | `water_systems` | `water_systems` | Available | `Configured by verification rules` |

#### Advisory

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Energy Consulting | `energy_consulting` | `energy_consulting` | Available | `Configured by verification rules` |
| Other Energy Services | `other_energy_services` | `other_energy_services` | Available | `Configured by verification rules` |

### Individual roles

#### Solar / Electrical Technician

**Database slug:** `work_solar_electrical_technician`
**Status:** Available
**Question:** What do you install?
**Kinds:** Solar PV · Batteries & inverters · Generators · Wiring

| Qualification | Evidence required |
|---|---|
| Electrical licence | No |
| Solar installer certificate | No |
| Safety training | No |
| Own tools | No |

#### Borehole / Water Technician

**Database slug:** `work_borehole_water_technician`
**Status:** Available
**Question:** What do you do?
**Kinds:** Drilling · Pump installation · Plumbing & tanks · Water treatment

| Qualification | Evidence required |
|---|---|
| Water technician certificate | No |
| Drilling permit | No |
| Own equipment | No |

#### Energy Engineer

**Database slug:** `work_energy_engineer`
**Status:** Available
**Question:** Which area?
**Kinds:** Solar design · Energy audits · Grid / mini-grid

| Qualification | Evidence required |
|---|---|
| Engineering degree | No |
| Registered engineer | No |
| Design software skills | No |

#### Project Manager

**Database slug:** `work_energy_utilities_project_manager`
**Status:** Available
**Question:** What kind of projects?
**Kinds:** Solar · Water · Electrification

| Qualification | Evidence required |
|---|---|
| PMP / PRINCE2 | No |
| Delivered 3+ projects | Not specified in JSON |

## 10. 🚚 Transport & Logistics

**Status:** Available
**Database slug:** `transport_logistics`
**Description:** Moving, hauling, delivery and cold chain

### Services

#### Freight

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Cargo Transport | `cargo_transport` | `cargo_transport` | Available | `Configured by verification rules` |
| Bulk Delivery | `bulk_delivery` | `bulk_delivery` | Available | `Configured by verification rules` |
| Heavy Haulage | `heavy_haulage` | `heavy_haulage` | Available | `Configured by verification rules` |
| Agricultural Transport | `agricultural_transport` | `agricultural_transport` | Available | `Configured by verification rules` |
| Cold Chain & Refrigerated | `cold_chain_transport` | `cold_chain_refrigerated` | Available | `Configured by verification rules` |

#### Delivery & Moving

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Courier | `courier_delivery` | `courier` | Available | `Configured by verification rules` |
| Moving Services | `moving_services` | `moving_services` | Available | `Configured by verification rules` |

#### Vehicles

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Truck Hire | `truck_hire` | `truck_hire` | Available | `Configured by verification rules` |
| Vehicle Transport | `vehicle_transport` | `vehicle_transport` | Available | `Configured by verification rules` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Logistics | `other_logistics` | `other_logistics` | Available | `Configured by verification rules` |

#### Passenger transport

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Chauffeur Services | `chauffeur_services` | `chauffeur_services`; aliases: chauffeur, executive driver | Available | `optional_proof` |
| Personal Driver Hire | `personal_driver_hire` | `personal_driver_hire`; aliases: personal driver, private driver | Available | `optional_proof` |
| Boda Boda / Motorcycle Taxi | `boda_taxi_services` | `boda_taxi_services`; aliases: boda, boda boda, motorcycle taxi | Available | `optional_proof` |

### Individual roles

#### Driver

**Database slug:** `work_driver`
**Status:** Available
**Question:** What do you drive?
**Kinds:** Truck / heavy · Pickup / van · Bus / minibus · Motorcycle courier · Tanker · Personal driver · Chauffeur (executive) · Boda rider · Airport / school runs

| Qualification | Evidence required |
|---|---|
| Valid driving licence (class) | No |
| PSV badge | No |
| Clean driving record | No |
| Defensive driving certificate | No |
| Own vehicle | No |
| Chauffeur or executive driving experience | No |
| Certificate of good conduct | Yes |

#### Fleet / Operations Manager

**Database slug:** `work_fleet_operations_manager`
**Status:** Available
**Question:** What fleet?
**Kinds:** Trucks · Vans & couriers · Mixed

| Qualification | Evidence required |
|---|---|
| Logistics diploma / degree | No |
| Managed 10+ vehicles | No |
| Transport licence | No |

#### Dispatcher / Coordinator

**Database slug:** `work_dispatcher_coordinator`
**Status:** Available
**Question:** What area?
**Kinds:** Route planning · Customs & clearing · Warehouse

| Qualification | Evidence required |
|---|---|
| Logistics experience | No |
| Customs clearing licence | No |

#### Loader / Mover

**Database slug:** `work_loader_mover`
**Status:** Available
**Question:** What work?
**Kinds:** Moving · Warehouse · Loading

| Qualification | Evidence required |
|---|---|
| Physical fitness | No |
| Experience 1+ year | No |

#### Driving Instructor

**Database slug:** `work_driving_instructor`
**Status:** Available
**Question:** What do you teach?
**Verification policy:** `required_proof`
**Aliases:** driving lessons, instructor
**Kinds:** Cars · Motorcycles · Trucks · Defensive driving

| Qualification | Evidence required |
|---|---|
| Instructor licence | Yes |
| Valid driving licence | Yes |
| 2+ years teaching | No |

## 11. 🚜 Machinery & Equipment

**Status:** Available
**Database slug:** `machinery_equipment`
**Description:** Heavy machinery and equipment hire, with or without an operator

### Services

#### Earthmoving

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Excavator Hire | `excavator_hire` | `excavator_hire` | Available | `Configured by verification rules` |
| Loader Hire | `loader_hire` | `loader_hire` | Available | `Configured by verification rules` |
| Grader Hire | `grader_hire` | `grader_hire` | Available | `Configured by verification rules` |

#### Lifting & Power

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Crane Hire | `crane_hire` | `crane_hire` | Available | `Configured by verification rules` |
| Generator Hire | `generator_hire` | `generator_hire` | Available | `Configured by verification rules` |

#### Farm & Industrial

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Tractor Hire | `tractor_hire` | `tractor_hire` | Available | `Configured by verification rules` |
| Industrial Equipment | `industrial_equipment` | `industrial_equipment` | Available | `Configured by verification rules` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Machinery | `other_machinery` | `other_machinery` | Available | `Configured by verification rules` |

### Individual roles

#### Machine Operator

**Database slug:** `work_machine_operator`
**Status:** Available
**Question:** Which machine do you operate?
**Kinds:** Excavator · Loader · Grader · Crane · Tractor · Roller · Forklift · Bulldozer · Concrete mixer / pump

| Qualification | Evidence required |
|---|---|
| Operator licence / certificate | No |
| Safety / OSHA certificate | No |
| 3+ years experience | No |
| Medical fitness | No |
| Can work away from home | No |

#### Equipment Mechanic

**Database slug:** `work_equipment_mechanic`
**Status:** Available
**Question:** What do you service?
**Kinds:** Heavy plant · Generators · Hydraulics · Electrical systems

| Qualification | Evidence required |
|---|---|
| Mechanic trade certificate | No |
| Own tools | No |
| Field repair experience | No |

#### Fleet / Equipment Manager

**Database slug:** `work_fleet_equipment_manager`
**Status:** Available
**Question:** What fleet?
**Kinds:** Construction plant · Farm machinery · Industrial equipment

| Qualification | Evidence required |
|---|---|
| Managed fleet of 5+ machines | No |
| Diploma / degree | No |
| Maintenance scheduling | No |

#### Site Supervisor

**Database slug:** `work_site_supervisor`
**Status:** Available
**Question:** Which sites?
**Kinds:** Earthworks · Quarry / mining · Farm

| Qualification | Evidence required |
|---|---|
| Plant experience | No |
| Team leadership | No |
| Safety certification | No |

## 12. 🌾 Agriculture & Agribusiness

**Status:** Available
**Database slug:** `agriculture_agribusiness`
**Description:** Farm services, inputs and produce

### Services

#### Farm Operations

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Farm Services | `farm_services` | `farm_services` | Available | `Configured by verification rules` |
| Irrigation | `irrigation_services` | `irrigation` | Available | `Configured by verification rules` |

#### Inputs & Livestock

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Seeds & Inputs | `seeds_inputs` | `seeds_inputs` | Available | `Configured by verification rules` |
| Livestock Sourcing | `livestock_sourcing` | `livestock_sourcing` | Available | `Configured by verification rules` |

#### Market

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Produce Buyers | `produce_buyers` | `produce_buyers` | Available | `Configured by verification rules` |
| Other Agriculture | `other_agriculture` | `other_agriculture` | Available | `Configured by verification rules` |

### Individual roles

#### Farm Manager

**Database slug:** `work_farm_manager`
**Status:** Available
**Question:** What farm?
**Kinds:** Crops · Dairy · Poultry · Mixed

| Qualification | Evidence required |
|---|---|
| Agriculture diploma / degree | No |
| Managed 5+ workers | No |
| 5+ years farming experience | No |

#### Agronomist / Extension Officer

**Database slug:** `work_agronomist_extension_officer`
**Status:** Available
**Question:** What focus?
**Kinds:** Crops · Soil & irrigation · Pest management

| Qualification | Evidence required |
|---|---|
| Degree / diploma in agronomy | No |
| Field experience | No |

#### Veterinary / Livestock Officer

**Database slug:** `work_veterinary_livestock_officer`
**Status:** Available
**Question:** What animals?
**Kinds:** Cattle · Poultry · Small ruminants

| Qualification | Evidence required |
|---|---|
| Veterinary licence | No |
| Diploma / degree | No |
| Vaccination certification | No |

#### Farm Worker / Operator

**Database slug:** `work_farm_worker_operator`
**Status:** Available
**Question:** What work?
**Kinds:** Tractor operation · Irrigation · Harvesting · Spraying

| Qualification | Evidence required |
|---|---|
| Tractor licence | No |
| Pesticide handling certificate | No |
| Experience 1+ year | No |

## 13. 🔎 Procurement & Sourcing

**Status:** Available
**Database slug:** `specialized_products`
**Description:** Buying, importing and finding hard-to-get products

### Services

#### Sourcing

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Bulk Procurement | `bulk_procurement` | `bulk_procurement` | Available | `Configured by verification rules` |
| Equipment Sourcing | `equipment_sourcing` | `equipment_sourcing` | Available | `Configured by verification rules` |
| Imported Products | `imported_products` | `imported_products` | Available | `Configured by verification rules` |
| Hard-to-Find Products | `hard_to_find_products` | `hard_to_find_products` | Available | `Configured by verification rules` |

#### Parts & Supplies

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Electronics Procurement | `electronics_procurement` | `electronics_procurement` | Available | `Configured by verification rules` |
| Industrial Parts | `industrial_parts` | `industrial_parts` | Available | `Configured by verification rules` |
| Spare Parts | `spare_parts` | `spare_parts` | Available | `Configured by verification rules` |
| Medical & Lab Supplies | `medical_lab_supplies` | `medical_lab_supplies` | Available | `Configured by verification rules` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Procurement | `other_procurement` | `other_procurement` | Available | `Configured by verification rules` |

### Individual roles

#### Procurement Officer / Manager

**Database slug:** `work_procurement_officer_manager`
**Status:** Available
**Question:** What do you buy?
**Kinds:** Industrial · Electronics · Medical & lab · General supplies

| Qualification | Evidence required |
|---|---|
| Procurement diploma (CIPS or similar) | No |
| Supplier network | No |
| 3+ years experience | No |

#### Sourcing Agent

**Database slug:** `work_sourcing_agent`
**Status:** Available
**Question:** Where do you source?
**Kinds:** Local · China · Dubai · India · Europe / USA

| Qualification | Evidence required |
|---|---|
| Import/export experience | No |
| Language skills | No |
| Supplier contacts | No |

#### Clearing & Customs Agent

**Database slug:** `work_clearing_customs_agent`
**Status:** Available
**Question:** What do you handle?
**Kinds:** Imports · Exports · Freight forwarding

| Qualification | Evidence required |
|---|---|
| Customs clearing licence | No |
| Logistics experience | No |

## 14. ✈️ Travel & International

**Status:** Available
**Database slug:** `travel_international`
**Description:** Bookings, visas, tours and relocation

### Services

#### Bookings

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Flight Tickets & Bookings | `flight_tickets` | `flight_tickets_bookings` | Available | `Configured by verification rules` |
| Accommodation | `accommodation` | `accommodation` | Available | `Configured by verification rules` |
| Airport Transfers | `airport_transfers` | `airport_transfers` | Available | `Configured by verification rules` |
| Tour Packages | `tour_packages` | `tour_packages` | Available | `Configured by verification rules` |

#### Documents & Cover

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Visa Assistance | `visa_assistance` | `visa_assistance` | Available | `Configured by verification rules` |
| Travel Documentation | `travel_documentation` | `travel_documentation` | Available | `Configured by verification rules` |
| Travel Insurance | `travel_insurance` | `travel_insurance` | Available | `Configured by verification rules` |

#### Specialised

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Hajj & Umrah | `hajj_umrah` | `hajj_umrah` | Available | `Configured by verification rules` |
| International Relocation | `international_relocation` | `international_relocation` | Available | `Configured by verification rules` |
| Travel Consultation | `travel_consultation` | `travel_consultation` | Available | `Configured by verification rules` |
| Other Travel Services | `other_travel_services` | `other_travel_services` | Available | `Configured by verification rules` |

### Individual roles

#### Travel Agent / Consultant

**Database slug:** `work_travel_agent_consultant`
**Status:** Available
**Question:** What do you handle?
**Kinds:** Flights · Tours & packages · Visas · Hajj & Umrah · Relocation

| Qualification | Evidence required |
|---|---|
| IATA certification | No |
| Travel agency licence | No |
| 2+ years experience | No |

#### Tour Guide

**Database slug:** `work_tour_guide`
**Status:** Available
**Question:** What tours?
**Kinds:** Wildlife safari · Cultural · City tours · Adventure

| Qualification | Evidence required |
|---|---|
| Tourism board guide licence | No |
| First aid certificate | No |
| Languages spoken | No |

#### Driver-Guide

**Database slug:** `work_driver_guide`
**Status:** Available
**Question:** What vehicle?
**Kinds:** Safari vehicle · Minibus · Airport transfers

| Qualification | Evidence required |
|---|---|
| Valid driving licence (class) | No |
| Tourism licence | No |
| Clean driving record | No |

#### Operations Manager

**Database slug:** `work_operations_manager`
**Status:** Available
**Question:** What scope?
**Kinds:** Tours · Visa & documentation · Travel desk

| Qualification | Evidence required |
|---|---|
| Tourism diploma / degree | No |
| Managed 3+ staff | No |

## 15. 🏠 Domestic & Household

**Status:** Inactive (rollout gated)
**Database slug:** `domestic_household`
**Description:** House help, childcare, home cooking and care at home

### Services

#### Home help

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Maids & House Help | `house_help_services` | `house_help_services`; aliases: maid, house help, housegirl, dada, domestic worker | Inactive (rollout gated) | `optional_proof` |
| Housekeeping & Cleaning | `housekeeping_services` | `housekeeping_services`; aliases: cleaner, house cleaner | Inactive (rollout gated) | `optional_proof` |
| Laundry & Ironing | `laundry_services` | `laundry_services`; aliases: laundry, ironing | Inactive (rollout gated) | `open` |
| Gardening & Compound Care | `gardening_services` | `gardening_services`; aliases: gardener, compound care | Inactive (rollout gated) | `open` |

#### Family

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Nannies & Childcare | `childcare_nanny_services` | `childcare_nanny_services`; aliases: nanny, babysitter, childcare | Inactive (rollout gated) | `optional_proof` |
| Home Cooks | `home_cooking_services` | `home_cooking_services`; aliases: home cook, private cook | Inactive (rollout gated) | `optional_proof` |
| Elderly Home Care | `elderly_home_care` | `elderly_home_care`; aliases: home carer, elder care | Inactive (rollout gated) | `optional_proof` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Domestic | `other_domestic` | `other_domestic` | Inactive (rollout gated) | `open` |

### Individual roles

#### House Help / Maid

**Database slug:** `work_house_help`
**Status:** Inactive (rollout gated)
**Question:** What kind of help?
**Verification policy:** `optional_proof`
**Aliases:** maid, housegirl, dada, domestic worker
**Kinds:** Live-in · Live-out · Day work · Part-time · Cleaning only

| Qualification | Evidence required |
|---|---|
| National ID | Yes |
| References | No |
| Experience 1+ year | No |
| Languages | No |

#### Nanny / Childcare

**Database slug:** `work_nanny`
**Status:** Inactive (rollout gated)
**Question:** Which ages?
**Verification policy:** `required_proof`
**Aliases:** nanny, babysitter
**Kinds:** Newborn · Toddler · School age · Special needs

| Qualification | Evidence required |
|---|---|
| National ID | Yes |
| Police clearance | Yes |
| First aid | Yes |
| Childcare certificate | No |
| References | No |

#### Home Cook

**Database slug:** `work_home_cook`
**Status:** Inactive (rollout gated)
**Question:** What do you cook?
**Verification policy:** `optional_proof`
**Aliases:** cook
**Kinds:** Family meals · Special diets · Event cooking · Baking

| Qualification | Evidence required |
|---|---|
| Food handler certificate | Yes |
| References | No |
| Experience 2+ years | No |

#### Gardener / Groundskeeper

**Database slug:** `work_gardener`
**Status:** Inactive (rollout gated)
**Question:** What work?
**Verification policy:** `open`
**Aliases:** gardener
**Kinds:** Lawn & garden · Landscaping · Compound upkeep

| Qualification | Evidence required |
|---|---|
| Experience | No |
| References | No |
| Own tools | No |

#### Home Carer

**Database slug:** `work_home_carer`
**Status:** Inactive (rollout gated)
**Question:** Whom do you care for?
**Verification policy:** `optional_proof`
**Aliases:** caregiver, home care
**Kinds:** Elderly · Disabled · Post-surgery

| Qualification | Evidence required |
|---|---|
| Caregiving certificate | Yes |
| First aid | Yes |
| National ID | Yes |
| References | No |

## 16. ⚕️ Health & Medical

**Status:** Inactive (rollout gated)
**Database slug:** `health_medical`
**Description:** Nurses, doctors, specialists, clinics and care

### Services

#### Facilities

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Clinics & Health Centres | `clinic_services` | `clinic_services`; aliases: clinic, health centre, dispensary | Inactive (rollout gated) | `required_proof` |
| Hospitals | `hospital_services` | `hospital_services`; aliases: hospital | Inactive (rollout gated) | `required_proof` |
| Eye Clinics & Opticals | `eye_clinic_optical` | `eye_clinic_optical`; aliases: optician, optometrist, eye doctor, glasses | Inactive (rollout gated) | `required_proof` |
| Dental Clinics | `dental_clinic` | `dental_clinic`; aliases: dentist | Inactive (rollout gated) | `required_proof` |
| Diagnostic Labs & Imaging | `diagnostic_lab` | `diagnostic_lab`; aliases: lab, x-ray, imaging | Inactive (rollout gated) | `required_proof` |
| Pharmacies | `pharmacy_services` | `pharmacy_services`; aliases: chemist, drug shop | Inactive (rollout gated) | `required_proof` |
| Physiotherapy Clinics | `physiotherapy_clinic` | `physiotherapy_clinic`; aliases: physio | Inactive (rollout gated) | `required_proof` |
| Orthopaedic & Bone Care | `orthopaedic_care` | `orthopaedic_care`; aliases: bone doctor, fracture, broken bone, back pain, joint pain, knee, arthritis, x-ray, physio | Inactive (rollout gated) | `required_proof` |

#### Staffing & home care

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Home Nursing Agencies | `home_nursing_agency` | `home_nursing_agency`; aliases: home nurse | Inactive (rollout gated) | `required_proof` |
| Medical Staffing Agencies | `medical_staffing_agency` | `medical_staffing_agency` | Inactive (rollout gated) | `required_proof` |
| Mobile Health Outreach | `mobile_health_outreach` | `mobile_health_outreach`; aliases: home visit | Inactive (rollout gated) | `required_proof` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Health Services | `other_health` | `other_health` | Inactive (rollout gated) | `required_proof` |

#### Procedures

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Circumcision Services | `circumcision_services` | `circumcision_services`; aliases: male circumcision, VMMC, mobile circumcision | Inactive (rollout gated) | `required_proof` |

#### Reproductive health

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Antenatal & Maternity Care | `maternity_care_services` | `maternity_care_services`; aliases: pregnancy, antenatal, ANC, maternity, midwife, prenatal, delivery, post-abortion care | Inactive (rollout gated) | `required_proof` |
| Family Planning & Reproductive Health | `family_planning_services` | `family_planning_services`; aliases: contraception, family planning | Inactive (rollout gated) | `required_proof` |
| HIV Testing & Counselling | `hiv_testing_services` | `hiv_testing_services`; aliases: HIV test, HCT, VCT, PrEP, PEP, STI test, sexual health | Inactive (rollout gated) | `required_proof` |

### Individual roles

#### Nurse / Midwife

**Database slug:** `work_nurse`
**Status:** Inactive (rollout gated)
**Question:** What nursing?
**Verification policy:** `required_proof`
**Aliases:** sister, RN, enrolled nurse
**Kinds:** General · Theatre · Paediatric · ICU / critical care · Midwifery · Community health · Antenatal & postnatal care · Family planning · HIV testing & counselling

| Qualification | Evidence required |
|---|---|
| Nursing council registration | Yes |
| Diploma / degree | Yes |
| Current practising certificate | Yes |
| 2+ years | No |

#### Doctor

**Database slug:** `work_doctor`
**Status:** Inactive (rollout gated)
**Question:** What do you practise?
**Verification policy:** `required_proof`
**Aliases:** physician, MD, medical officer
**Kinds:** General practitioner · Surgeon · Emergency · Locum · Circumcision (adult and infant)

| Qualification | Evidence required |
|---|---|
| Medical council registration | Yes |
| MBChB / MD | Yes |
| Practising certificate | Yes |
| Internship completed | No |

#### Clinical Officer / Clinician

**Database slug:** `work_clinician`
**Status:** Inactive (rollout gated)
**Question:** What area?
**Verification policy:** `required_proof`
**Kinds:** General clinical · Anaesthesia · Orthopaedic · Ophthalmic · Community · Circumcision (adult and infant)

| Qualification | Evidence required |
|---|---|
| Clinical officers council registration | Yes |
| Diploma | Yes |
| Practising licence | Yes |

#### Medical Specialist

**Database slug:** `work_medical_specialist`
**Status:** Inactive (rollout gated)
**Question:** Which specialty?
**Verification policy:** `required_proof`
**Aliases:** oncologist, cancer specialist
**Kinds:** Oncologist · Cardiologist · Paediatrician · Gynaecologist · Dermatologist · ENT · Neurologist · Orthopaedic surgeon · Urologist · Psychiatrist · Radiologist · Other specialist

| Qualification | Evidence required |
|---|---|
| Specialist registration | Yes |
| Postgraduate degree or fellowship | Yes |
| Medical council registration | Yes |
| Years in specialty | No |

#### Optician / Optometrist

**Database slug:** `work_optometrist`
**Status:** Inactive (rollout gated)
**Question:** What do you do?
**Verification policy:** `required_proof`
**Aliases:** optician, eye doctor, glasses
**Kinds:** Eye tests · Contact lenses · Dispensing optician · Low vision

| Qualification | Evidence required |
|---|---|
| Optometry registration | Yes |
| Diploma / degree | Yes |
| Practising certificate | Yes |

#### Dentist

**Database slug:** `work_dentist`
**Status:** Inactive (rollout gated)
**Question:** What dentistry?
**Verification policy:** `required_proof`
**Kinds:** General · Orthodontics · Oral surgery · Paediatric

| Qualification | Evidence required |
|---|---|
| Dental council registration | Yes |
| BDS | Yes |
| Practising certificate | Yes |

#### Pharmacist

**Database slug:** `work_pharmacist`
**Status:** Inactive (rollout gated)
**Question:** Where do you work?
**Verification policy:** `required_proof`
**Kinds:** Retail · Hospital · Dispensing · Locum

| Qualification | Evidence required |
|---|---|
| Pharmacy board registration | Yes |
| Degree | Yes |
| Practising certificate | Yes |

#### Lab Technician

**Database slug:** `work_lab_technician`
**Status:** Inactive (rollout gated)
**Question:** What lab work?
**Verification policy:** `required_proof`
**Kinds:** Medical lab · Radiography · Ultrasound

| Qualification | Evidence required |
|---|---|
| Lab council registration | Yes |
| Diploma | Yes |

#### Physiotherapist

**Database slug:** `work_physiotherapist`
**Status:** Inactive (rollout gated)
**Question:** What therapy?
**Verification policy:** `required_proof`
**Kinds:** Sports · Neuro · Paediatric · Geriatric · Home visits

| Qualification | Evidence required |
|---|---|
| Physiotherapy registration | Yes |
| Degree | Yes |
| Practising certificate | Yes |

#### Counsellor / Psychologist

**Database slug:** `work_counsellor`
**Status:** Inactive (rollout gated)
**Question:** What support?
**Verification policy:** `required_proof`
**Kinds:** Individual · Couples & family · Trauma · Child & adolescent

| Qualification | Evidence required |
|---|---|
| Counselling or psychology registration | Yes |
| Degree | Yes |
| Supervised hours | No |

#### Nursing Assistant / Caregiver

**Database slug:** `work_nursing_assistant`
**Status:** Inactive (rollout gated)
**Question:** What care?
**Verification policy:** `required_proof`
**Kinds:** Bedside · Home care · Elderly · Post-surgery

| Qualification | Evidence required |
|---|---|
| Nursing assistant certificate | Yes |
| First aid | Yes |
| National ID | Yes |

#### HIV Counsellor / Testing Officer

**Database slug:** `work_hiv_counsellor`
**Status:** Inactive (rollout gated)
**Question:** What do you do?
**Verification policy:** `required_proof`
**Aliases:** HIV testing counsellor, HCT
**Kinds:** Testing & counselling · Peer educator · Community outreach

| Qualification | Evidence required |
|---|---|
| Counselling certificate | Yes |
| HIV testing and counselling training | Yes |
| Ministry of Health or facility authorisation | Yes |
| National ID | Yes |

## 17. 💼 Business & Investment

**Status:** Inactive (rollout gated)
**Database slug:** `business_investment`
**Description:** Angel investors, mentors and startup support

### Services

#### Investor support

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Angel Investor Networks | `angel_investor_network` | `angel_investor_network`; aliases: angel investor, investor, seed funding, startup funding | Inactive (rollout gated) | `required_proof` |
| Startup Advisory | `startup_advisory` | `startup_advisory`; aliases: startup mentor | Inactive (rollout gated) | `optional_proof` |
| Investor Introductions | `investor_introductions` | `investor_introductions`; aliases: investor introduction | Inactive (rollout gated) | `required_proof` |
| Incubators & Accelerators | `incubator_accelerator` | `incubator_accelerator`; aliases: startup incubator, accelerator | Inactive (rollout gated) | `required_proof` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Investment Support | `other_investment` | `other_investment` | Inactive (rollout gated) | `open` |

### Individual roles

#### Angel Investor

**Database slug:** `work_angel_investor`
**Status:** Inactive (rollout gated)
**Question:** Which sectors?
**Verification policy:** `required_proof`
**Aliases:** investor, seed funding
**Kinds:** Technology · Agriculture · Retail & trade · Health · Energy · Real estate · Creative · General

| Qualification | Evidence required |
|---|---|
| Identity verification | Yes |
| Proof of investment track record or portfolio | Yes |
| Ticket size range | No |
| Stage focus | No |

#### Business Mentor

**Database slug:** `work_business_mentor`
**Status:** Inactive (rollout gated)
**Question:** What do you help with?
**Verification policy:** `optional_proof`
**Aliases:** startup mentor
**Kinds:** Startup · SME growth · Export · Agribusiness

| Qualification | Evidence required |
|---|---|
| Experience 5+ years | No |
| Case studies | No |
| Referees | No |

## 18. 🪘 Traditional & Cultural Services

**Status:** Inactive (rollout gated)
**Database slug:** `traditional_cultural`
**Description:** Traditional ceremonies, prayers, healing and culture

### Services

#### Culture

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Duwah Services | `duwah_services` | `duwah_services`; aliases: duwa, duwah | Inactive (rollout gated) | `optional_proof` |
| Traditional Ceremonies | `traditional_ceremony_services` | `traditional_ceremony_services` | Inactive (rollout gated) | `optional_proof` |
| Traditional Dance & Drumming | `traditional_dance_drumming` | `traditional_dance_drumming` | Inactive (rollout gated) | `open` |
| Traditional Attire & Crafts | `traditional_attire_crafts` | `traditional_attire_crafts` | Inactive (rollout gated) | `open` |

#### Healing

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Herbal & Traditional Healing | `traditional_healing_herbal` | `traditional_healing_herbal`; aliases: traditional healer, herbalist | Inactive (rollout gated) | `required_proof` |

#### Other

| Service | Database slug | Catalog ID | Status | Verification policy |
|---|---|---|---|---|
| Other Traditional | `other_traditional` | `other_traditional` | Inactive (rollout gated) | `open` |

### Individual roles

#### Duwah Practitioner

**Database slug:** `work_duwah_practitioner`
**Status:** Inactive (rollout gated)
**Question:** What is your practice?
**Verification policy:** `optional_proof`
**Aliases:** duwa, duwah
**Kinds:** Pending definition / not configured

| Qualification | Evidence required |
|---|---|
| Community or religious endorsement letter | Yes |
| References | No |
| Experience years | No |

#### Ceremony Officiant / Elder

**Database slug:** `work_ceremony_officiant`
**Status:** Inactive (rollout gated)
**Question:** Which ceremonies?
**Verification policy:** `optional_proof`
**Kinds:** Introduction & marriage · Naming · Funeral & memorial · Cultural rites

| Qualification | Evidence required |
|---|---|
| Endorsement | Yes |
| References | No |

#### Traditional Performer

**Database slug:** `work_traditional_performer`
**Status:** Inactive (rollout gated)
**Question:** What do you perform?
**Verification policy:** `open`
**Kinds:** Dancer · Drummer · Singer · Storyteller

| Qualification | Evidence required |
|---|---|
| Showreel | No |
| Group membership | No |

#### Traditional Healer / Herbalist

**Database slug:** `work_traditional_healer`
**Status:** Inactive (rollout gated)
**Question:** What is your practice?
**Verification policy:** `required_proof`
**Aliases:** traditional healer, herbalist
**Kinds:** Herbalist · Bone setter · Birth attendant

| Qualification | Evidence required |
|---|---|
| Registration with relevant association or local authority | Yes |
| Referees | No |

## Safety and rollout notes

- **Beauty, Fashion, Styling & Wellness:** Massage and spa listings are therapeutic and wellness services only; sexual services are prohibited.
- **Domestic & Household:** Inactive pending rollout. Never expose exact home addresses; an ID-checked badge requires admin approval.
- **Health & Medical:** Inactive pending legal and country licensing review. Do not collect or store HIV results; sensitive Needs must remain private.
- **Business & Investment:** Inactive pending legal review. Nipanze does not hold funds, provide investment advice, or guarantee returns.
- **Traditional & Cultural Services:** Inactive pending regulation review. Listings must not claim to cure illness or guarantee outcomes.
- **Education & Training:** Academic services are guidance, tutoring, mentoring, editing, and analysis only; ghost-writing/submitting work as a student is prohibited.

## Source and implementation notes

- The JSON is the versioned catalog reference. [`sql/patch_catalog_expansion_v3.sql`](./sql/patch_catalog_expansion_v3.sql) seeds the expansion and rollout flags.
- Legacy catalog IDs are retained; `database_slug` maps every entry to its current canonical database slug.
- Domestic & Household, Health & Medical, Business & Investment, and Traditional & Cultural Services remain represented but inactive pending rollout/review.
- This documents repository seed state, not confirmation that a live Supabase database has applied every migration.
