-- =============================================================================
-- Standalone SQL Patch: patch_creative_events_capabilities.sql
-- Purpose: Expand the existing Needs catalog with Music & Video and
--          Weddings & Celebrations capabilities. No marketplace/provider
--          tables or offer flows are introduced.
-- Safe to re-run: catalog rows are upserted by their existing slugs.
-- =============================================================================

-- Optional ISO country-code keyed label overrides. Each value may contain
-- {"name": "...", "description": "..."}; clients fall back to the base
-- name/description when there is no country-specific override.
alter table public.need_categories
  add column if not exists country_labels jsonb not null default '{}'::jsonb;

alter table public.need_capabilities
  add column if not exists country_labels jsonb not null default '{}'::jsonb;

-- These groups use the same Need -> Offer -> Accept -> Contact Reveal flow.
insert into public.need_categories
  (slug, name, icon, sort_order, description, country_labels, is_active)
values
  ('music_video', 'Music & Video', '🎬', 11,
   'Performers and production professionals for music, film, and video projects.', '{}'::jsonb, true),
  ('weddings_celebrations', 'Weddings & Celebrations', '🎉', 12,
   'Creative and event services for graduations, weddings, and social celebrations.', '{}'::jsonb, true)
on conflict (slug) do update set
  name = excluded.name,
  icon = excluded.icon,
  sort_order = excluded.sort_order,
  description = excluded.description;

insert into public.need_capabilities
  (slug, category_slug, name, country_labels, is_active)
values
  ('music_video_models', 'music_video', 'Music Video Models / Video Vixens', '{}'::jsonb, true),
  ('dancers', 'music_video', 'Dancers', '{}'::jsonb, true),
  ('actors_actresses', 'music_video', 'Actors / Actresses', '{}'::jsonb, true),
  ('background_extras', 'music_video', 'Background Extras', '{}'::jsonb, true),
  ('singers_vocalists', 'music_video', 'Singers / Vocalists', '{}'::jsonb, true),
  ('songwriters', 'music_video', 'Songwriters', '{}'::jsonb, true),
  ('music_producers', 'music_video', 'Music Producers', '{}'::jsonb, true),
  ('recording_studios', 'music_video', 'Recording Studios', '{}'::jsonb, true),
  ('mixing_mastering', 'music_video', 'Mixing & Mastering', '{}'::jsonb, true),
  ('videographers', 'music_video', 'Videographers', '{}'::jsonb, true),
  ('video_editors', 'music_video', 'Video Editors', '{}'::jsonb, true),
  ('photographers', 'music_video', 'Photographers', '{}'::jsonb, true),
  ('music_video_makeup', 'music_video', 'Makeup Artists', '{}'::jsonb, true),
  ('music_video_stylists', 'music_video', 'Stylists', '{}'::jsonb, true),
  ('graduation_photography', 'weddings_celebrations', 'Graduation Photography', '{}'::jsonb, true),
  ('graduation_videography', 'weddings_celebrations', 'Graduation Videography', '{}'::jsonb, true),
  ('wedding_photography', 'weddings_celebrations', 'Wedding Photography', '{}'::jsonb, true),
  ('wedding_videography', 'weddings_celebrations', 'Wedding Videography', '{}'::jsonb, true),
  ('celebration_makeup', 'weddings_celebrations', 'Makeup Artists', '{}'::jsonb, true),
  ('hair_styling', 'weddings_celebrations', 'Hair Stylists', '{}'::jsonb, true),
  ('bridal_styling', 'weddings_celebrations', 'Bridal Styling', '{}'::jsonb, true),
  ('dresses_bridesmaid_outfits', 'weddings_celebrations', 'Wedding Dresses / Bridesmaid Outfits', '{}'::jsonb, true),
  ('event_decoration', 'weddings_celebrations', 'Decoration', '{}'::jsonb, true),
  ('celebration_catering', 'weddings_celebrations', 'Catering', '{}'::jsonb, true),
  ('celebration_cakes', 'weddings_celebrations', 'Cakes', '{}'::jsonb, true),
  ('celebration_mc_dj', 'weddings_celebrations', 'DJs / MCs', '{}'::jsonb, true),
  ('celebration_singers_dancers', 'weddings_celebrations', 'Singers / Dancers', '{}'::jsonb, true),
  ('wedding_event_planning', 'weddings_celebrations', 'Event Planning', '{}'::jsonb, true),
  ('event_transport', 'weddings_celebrations', 'Event Transport', '{}'::jsonb, true),
  ('engagement_planning', 'weddings_celebrations', 'Engagements', '{}'::jsonb, true),
  ('bridal_shower_planning', 'weddings_celebrations', 'Bridal Showers', '{}'::jsonb, true),
  ('baby_shower_planning', 'weddings_celebrations', 'Baby Showers', '{}'::jsonb, true),
  ('birthday_celebrations', 'weddings_celebrations', 'Birthdays', '{}'::jsonb, true),
  ('anniversary_celebrations', 'weddings_celebrations', 'Anniversaries', '{}'::jsonb, true),
  ('other_social_celebrations', 'weddings_celebrations', 'Other Social Celebrations', '{}'::jsonb, true)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name;

-- Example country-specific category terminology:
-- update public.need_categories
-- set country_labels = jsonb_set(country_labels, '{KE}',
--   '{"name":"Celebrations & Events"}'::jsonb, true)
-- where slug = 'weddings_celebrations';

grant select on public.need_categories to anon, authenticated;
grant select on public.need_capabilities to anon, authenticated;
