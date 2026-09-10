-- Standalone Supabase Cloud patch: split forex settlement into method + detail.
-- Keeps legacy settlement_preference values readable while allowing richer bank/
-- mobile-money / in-person provider details.

BEGIN;

ALTER TABLE public.forex_requests
  ADD COLUMN IF NOT EXISTS settlement_method TEXT,
  ADD COLUMN IF NOT EXISTS settlement_details TEXT;

UPDATE public.forex_requests fr
SET
  settlement_method = CASE
    WHEN fr.settlement_method IS NOT NULL AND trim(fr.settlement_method) <> '' THEN trim(fr.settlement_method)
    WHEN lower(fr.settlement_preference) LIKE '%bank%' THEN 'bank'
    WHEN lower(fr.settlement_preference) LIKE '%m-pesa%' OR lower(fr.settlement_preference) LIKE '%mpesa%' OR lower(fr.settlement_preference) LIKE '%mobile%' OR lower(fr.settlement_preference) LIKE '%money%' THEN 'mobile_money'
    WHEN lower(fr.settlement_preference) LIKE '%person%' OR lower(fr.settlement_preference) LIKE '%cash%' OR lower(fr.settlement_preference) LIKE '%pickup%' THEN 'in_person'
    ELSE 'other'
  END,
  settlement_details = CASE
    WHEN fr.settlement_details IS NOT NULL AND trim(fr.settlement_details) <> '' THEN trim(fr.settlement_details)
    WHEN fr.settlement_preference IS NULL OR trim(fr.settlement_preference) = '' THEN NULL
    WHEN lower(fr.settlement_preference) LIKE '%bank%' THEN NULLIF(
      trim(regexp_replace(fr.settlement_preference, '(?i)\b(bank transfer|bank|transfer)\b', '', 'g')),
      ''
    )
    WHEN lower(fr.settlement_preference) LIKE '%m-pesa%' OR lower(fr.settlement_preference) LIKE '%mpesa%' OR lower(fr.settlement_preference) LIKE '%mobile%' OR lower(fr.settlement_preference) LIKE '%money%' THEN NULLIF(
      trim(regexp_replace(fr.settlement_preference, '(?i)\b(mobile money|mobile|money)\b', '', 'g')),
      ''
    )
    WHEN lower(fr.settlement_preference) LIKE '%person%' OR lower(fr.settlement_preference) LIKE '%cash%' OR lower(fr.settlement_preference) LIKE '%pickup%' THEN NULLIF(
      trim(regexp_replace(fr.settlement_preference, '(?i)\b(in person|cash|pickup)\b', '', 'g')),
      ''
    )
    ELSE NULLIF(trim(fr.settlement_preference), '')
  END
WHERE fr.settlement_method IS NULL OR fr.settlement_details IS NULL;

ALTER TABLE public.forex_requests
  ALTER COLUMN settlement_method SET DEFAULT 'other';

DROP VIEW IF EXISTS public.v_forex_listings;

CREATE VIEW public.v_forex_listings AS
SELECT
    fr.id                                                                     AS request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount,
    fr.country,
    fr.district,
    CASE
        WHEN fr.settlement_details IS NOT NULL AND trim(fr.settlement_details) <> '' THEN
            CASE fr.settlement_method
                WHEN 'bank' THEN 'Bank transfer — ' || fr.settlement_details
                WHEN 'mobile_money' THEN 'Mobile money — ' || fr.settlement_details
                WHEN 'in_person' THEN 'In person — ' || fr.settlement_details
                ELSE 'Other — ' || fr.settlement_details
            END
        WHEN fr.settlement_preference IS NOT NULL AND trim(fr.settlement_preference) <> '' THEN fr.settlement_preference
        WHEN fr.settlement_method = 'bank' THEN 'Bank transfer'
        WHEN fr.settlement_method = 'mobile_money' THEN 'Mobile money'
        WHEN fr.settlement_method = 'in_person' THEN 'In person'
        ELSE 'Other'
    END                                                                     AS settlement_preference,
    fr.settlement_method,
    fr.settlement_details,
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
