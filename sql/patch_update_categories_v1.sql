-- =============================================================================
-- patch_update_categories_v1.sql
-- =============================================================================
-- Adjusts Needs categories to the final 14-category list:
--   1.  Technology & Digital
--   2.  Marketing & Promotion          ← NEW top-level category
--   3.  Business & Professional        ← was "Professional & Business Services"
--   4.  Education & Training
--   5.  Events & Celebrations          ← was "Events & Production"
--   6.  Photo, Video, Music & Talent   ← NEW top-level category
--   7.  Beauty, Fashion & Styling      ← NEW top-level category
--   8.  Construction & Building
--   9.  Energy & Water                 ← was "Energy & Utilities"
--  10.  Transport & Logistics
--  11.  Machinery & Equipment
--  12.  Agriculture                    ← was "Agriculture & Agribusiness"
--  13.  Procurement & Sourcing         ← was "Specialized Products & Procurement"
--  14.  Travel & International
--
-- Safe to re-run: all upserts use ON CONFLICT DO UPDATE.
-- Never modifies patch.sql / schema.sql / merged.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Rename existing categories & fix sort orders
-- ---------------------------------------------------------------------------
UPDATE public.need_categories
SET name = 'Technology & Digital',  sort_order = 1
WHERE slug = 'technology_digital';

UPDATE public.need_categories
SET name = 'Business & Professional', sort_order = 3
WHERE slug = 'professional_services';

UPDATE public.need_categories
SET name = 'Education & Training',   sort_order = 4
WHERE slug = 'education_training';

UPDATE public.need_categories
SET name = 'Events & Celebrations',  sort_order = 5
WHERE slug = 'events_production';

UPDATE public.need_categories
SET name = 'Construction & Building', sort_order = 8
WHERE slug = 'construction_building';

UPDATE public.need_categories
SET name = 'Energy & Water',          sort_order = 9
WHERE slug = 'energy_utilities';

UPDATE public.need_categories
SET name = 'Transport & Logistics',   sort_order = 10
WHERE slug = 'transport_logistics';

UPDATE public.need_categories
SET name = 'Machinery & Equipment',   sort_order = 11
WHERE slug = 'machinery_equipment';

UPDATE public.need_categories
SET name = 'Agriculture',             sort_order = 12
WHERE slug = 'agriculture_agribusiness';

UPDATE public.need_categories
SET name = 'Procurement & Sourcing',  sort_order = 13
WHERE slug = 'specialized_products';

UPDATE public.need_categories
SET name = 'Travel & International',  sort_order = 14
WHERE slug = 'travel_international';

-- ---------------------------------------------------------------------------
-- 2. Insert the 3 new top-level categories (idempotent)
-- ---------------------------------------------------------------------------
INSERT INTO public.need_categories (slug, name, icon, sort_order, description, is_active)
VALUES
  ('marketing_promotion',
   'Marketing & Promotion', '📣', 2,
   'Digital marketing, social media, advertising, influencer marketing, and brand promotion services.',
   true),
  ('photo_video_music_talent',
   'Photo, Video, Music & Talent', '🎬', 6,
   'Photography, videography, music production, DJs, performers, and creative talent.',
   true),
  ('beauty_fashion_styling',
   'Beauty, Fashion & Styling', '💄', 7,
   'Hair styling, makeup, tailoring, fashion design, and personal styling services.',
   true)
ON CONFLICT (slug) DO UPDATE SET
  name        = EXCLUDED.name,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order,
  description = EXCLUDED.description,
  is_active   = EXCLUDED.is_active;

-- ---------------------------------------------------------------------------
-- 3. Migrate marketing capabilities from professional_services
--    to marketing_promotion (idempotent – only moves rows that still point
--    to the old slug)
-- ---------------------------------------------------------------------------
UPDATE public.need_capabilities
SET category_slug = 'marketing_promotion'
WHERE category_slug = 'professional_services'
  AND slug IN (
    'social_media_marketing',
    'influencer_marketing',
    'content_creation',
    'product_reviews',
    'event_promotion',
    'affiliate_marketing',
    'advertising_campaigns',
    'brand_promotion',
    'tiktok_promotion',
    'other_marketing_services',
    'i_have_an_audience',
    'marketing_services'
  );

-- ---------------------------------------------------------------------------
-- 4. Migrate music/video capabilities to photo_video_music_talent
--    (these live under music_video in patch.sql)
-- ---------------------------------------------------------------------------
UPDATE public.need_capabilities
SET category_slug = 'photo_video_music_talent'
WHERE category_slug = 'music_video';

-- ---------------------------------------------------------------------------
-- 5. Migrate beauty/fashion capabilities to beauty_fashion_styling
--    (some live under weddings_celebrations in patch.sql)
-- ---------------------------------------------------------------------------
UPDATE public.need_capabilities
SET category_slug = 'beauty_fashion_styling'
WHERE category_slug = 'weddings_celebrations'
  AND slug IN (
    'celebration_makeup',
    'hair_styling',
    'bridal_styling',
    'dresses_bridesmaid_outfits'
  );

-- ---------------------------------------------------------------------------
-- 6. Migrate events capabilities that were under weddings_celebrations
--    to events_production (the renamed Events & Celebrations category)
-- ---------------------------------------------------------------------------
UPDATE public.need_capabilities
SET category_slug = 'events_production'
WHERE category_slug = 'weddings_celebrations'
  AND slug IN (
    'graduation_photography',
    'graduation_videography',
    'wedding_photography',
    'wedding_videography',
    'event_decoration',
    'celebration_catering'
  );

-- ---------------------------------------------------------------------------
-- 7. Fix capability_roles category_slug mismatches introduced by
--    patch_job_seeking_profiles.sql
-- ---------------------------------------------------------------------------

-- Marketing roles → marketing_promotion
UPDATE public.capability_roles
SET category_slug = 'marketing_promotion'
WHERE category_slug IN ('professional_services', 'marketing_promotion')
  AND slug IN (
    'marketer_specialist',
    'content_creator',
    'digital_marketer',
    'social_media_manager',
    'graphic_designer',
    'marketing_officer'
  );

-- Events roles → events_production (Events & Celebrations)
UPDATE public.capability_roles
SET category_slug = 'events_production'
WHERE category_slug IN ('weddings_celebrations', 'events_production')
  AND slug IN (
    'event_manager_planner',
    'mc_dj',
    'event_decorator',
    'event_caterer',
    'sound_technician',
    'event_coordinator'
  );

-- Photo / Video / Music roles → photo_video_music_talent
UPDATE public.capability_roles
SET category_slug = 'photo_video_music_talent'
WHERE category_slug IN ('music_video', 'photo_video_music_talent')
  AND slug IN (
    'photographer_videographer',
    'performer_talent'
  );

-- Beauty / Fashion roles → beauty_fashion_styling
UPDATE public.capability_roles
SET category_slug = 'beauty_fashion_styling'
WHERE category_slug IN ('weddings_celebrations', 'beauty_fashion_styling')
  AND slug IN (
    'hair_stylist',
    'makeup_artist',
    'tailor_fashion_designer',
    'fashion_designer',
    'wardrobe_stylist'
  );

-- ---------------------------------------------------------------------------
-- 8. Deactivate legacy categories that are no longer top-level
--    (music_video, weddings_celebrations).  They remain in the DB for FK
--    integrity but won't appear in the active category list.
-- ---------------------------------------------------------------------------
UPDATE public.need_categories
SET is_active = false
WHERE slug IN ('music_video', 'weddings_celebrations');

-- ---------------------------------------------------------------------------
-- 9. Final de-duplication and safety checks for active category inners.
--    Slugs are already unique, but this keeps legacy placeholder rows from
--    rendering as repeated inner categories in clients that fetch all active
--    capabilities.
-- ---------------------------------------------------------------------------
UPDATE public.need_capabilities
SET is_active = false
WHERE slug = 'marketing_services';

UPDATE public.need_capabilities
SET category_slug = 'marketing_promotion'
WHERE slug IN (
  'social_media_marketing',
  'influencer_marketing',
  'content_creation',
  'product_reviews',
  'event_promotion',
  'affiliate_marketing',
  'advertising_campaigns',
  'brand_promotion',
  'tiktok_promotion',
  'other_marketing_services',
  'i_have_an_audience'
);

UPDATE public.need_categories
SET provider_verification_required = true
WHERE slug IN (
  'technology_digital',
  'marketing_promotion',
  'professional_services',
  'education_training',
  'events_production',
  'photo_video_music_talent',
  'beauty_fashion_styling',
  'construction_building',
  'energy_utilities',
  'transport_logistics',
  'machinery_equipment',
  'agriculture_agribusiness',
  'specialized_products',
  'travel_international'
);

