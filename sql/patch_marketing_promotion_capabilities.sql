-- Provider Services: expand the existing Marketing capability.
-- Existing provider rows keep the marketing_services slug, so current users
-- remain mapped to Marketing & Promotion without changing their capabilities.

insert into public.need_capabilities (slug, category_slug, name, is_active)
values
  ('marketing_services', 'professional_services', 'Marketing & Promotion', true),
  ('social_media_marketing', 'professional_services', 'Social Media Marketing', true),
  ('tiktok_promotion', 'professional_services', 'TikTok Promotion', true),
  ('instagram_promotion', 'professional_services', 'Instagram Promotion', true),
  ('youtube_promotion', 'professional_services', 'YouTube Promotion', true),
  ('facebook_promotion', 'professional_services', 'Facebook Promotion', true),
  ('influencer_marketing', 'professional_services', 'Influencer Marketing', true),
  ('content_creation', 'professional_services', 'Content Creation', true),
  ('product_reviews', 'professional_services', 'Product Reviews', true),
  ('event_promotion', 'professional_services', 'Event Promotion', true),
  ('whatsapp_community_promotion', 'professional_services', 'WhatsApp / Community Promotion', true),
  ('affiliate_marketing', 'professional_services', 'Affiliate Marketing', true),
  ('advertising_campaigns', 'professional_services', 'Advertising Campaigns', true),
  ('brand_promotion', 'professional_services', 'Brand Promotion', true),
  ('other_marketing_services', 'professional_services', 'Other Marketing Services', true),
  ('i_have_an_audience', 'professional_services', 'I Have an Audience', true)
on conflict (slug) do update set
  category_slug = excluded.category_slug,
  name = excluded.name,
  is_active = excluded.is_active;

-- Audience declarations are stored in provider_capabilities.metadata for the
-- i_have_an_audience row; verification remains governed by the existing
-- provider-capability verification trigger and is never changed by this patch.
