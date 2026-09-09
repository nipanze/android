-- Standalone Supabase Cloud patch: add district/location to forex_requests
-- and expose it through the public forex listings view.

BEGIN;

ALTER TABLE public.forex_requests
  ADD COLUMN IF NOT EXISTS district TEXT;

UPDATE public.forex_requests
SET district = 'Other'
WHERE district IS NULL;

ALTER TABLE public.forex_requests
  ALTER COLUMN district SET NOT NULL;

DROP VIEW IF EXISTS public.v_forex_listings;

CREATE VIEW public.v_forex_listings AS
SELECT
    fr.id                                                                     AS request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount,
    fr.country,
    fr.district,
    fr.settlement_preference,
    fr.is_urgent,
    fr.preferred_rate,
    fr.terms_locked_at,
    fr.status,
    fr.number_of_offers,
    CASE
        WHEN fr.number_of_offers = 0 THEN 'low'
        WHEN fr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS rate_coverage_tier,
    fr.listed_at,
    fr.expires_at,
    k.status                                                                  AS kyc_status,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                  AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                         AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    GREATEST(fr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (fr.expires_at < NOW() + INTERVAL '24 hours')                             AS closing_soon_24h,
    (fr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h
FROM public.forex_requests fr
JOIN public.profiles p ON p.id = fr.requester_id
LEFT JOIN public.kyc_verifications k ON k.user_id = fr.requester_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = fr.requester_id
WHERE fr.status = 'active'
  AND (
    auth.uid() IS NULL OR fr.requester_id <> auth.uid()
  )
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.forex_offers fo
      WHERE fo.request_id = fr.id
        AND fo.offer_maker_id = auth.uid()
        AND fo.status IN ('pending', 'accepted')
    )
  );

GRANT SELECT ON public.v_forex_listings TO authenticated, anon;

COMMIT;
