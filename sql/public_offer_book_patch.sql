-- ============================================================
-- NIPANZE -- Public anonymized offer book
-- Run this in the Supabase SQL Editor for the cloud project.
-- Safe to run multiple times.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_public_listing_offers(p_request_id UUID)
RETURNS TABLE (
    id UUID,
    request_id UUID,
    lender_id TEXT,
    offer_amount BIGINT,
    proposed_expectations TEXT,
    status TEXT,
    offered_at TIMESTAMP,
    accepted_at TIMESTAMP
)
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT
        lo.id,
        lo.request_id,
        ('public-offer-' || ROW_NUMBER() OVER (ORDER BY lo.offered_at ASC))::TEXT AS lender_id,
        lo.offer_amount,
        lo.proposed_expectations,
        lo.status::TEXT,
        lo.offered_at,
        lo.accepted_at
    FROM loan_offers lo
    JOIN loan_requests lr ON lr.id = lo.request_id
    WHERE lo.request_id = p_request_id
      AND lo.status = 'pending'
      AND lr.status = 'active'
    ORDER BY lo.offered_at DESC;
$$;

COMMENT ON FUNCTION public.get_public_listing_offers(UUID) IS
'Public anonymized offer book for active listings. Does not expose lender_id or borrower details.';

GRANT EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) TO anon, authenticated;

-- Keep the denormalized offer count aligned with pending offers, which is
-- what the marketplace UI shows as current offer activity.
CREATE OR REPLACE FUNCTION public.trg_fn_sync_offer_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_request_id UUID;
BEGIN
    v_request_id := COALESCE(NEW.request_id, OLD.request_id);

    UPDATE loan_requests lr
       SET number_of_offers = (
           SELECT COUNT(*)::INT
             FROM loan_offers lo
            WHERE lo.request_id = v_request_id
              AND lo.status = 'pending'
       )
     WHERE lr.id = v_request_id;

    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_increment_offer_count ON loan_offers;
DROP TRIGGER IF EXISTS trg_sync_offer_count ON loan_offers;

CREATE TRIGGER trg_sync_offer_count
    AFTER INSERT OR UPDATE OR DELETE ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION public.trg_fn_sync_offer_count();

-- Repair existing cloud/seed data after installing the trigger.
UPDATE loan_requests lr
   SET number_of_offers = counts.pending_count
  FROM (
      SELECT request_id, COUNT(*)::INT AS pending_count
        FROM loan_offers
       WHERE status = 'pending'
       GROUP BY request_id
  ) counts
 WHERE lr.id = counts.request_id;

UPDATE loan_requests lr
   SET number_of_offers = 0
 WHERE NOT EXISTS (
     SELECT 1
       FROM loan_offers lo
      WHERE lo.request_id = lr.id
        AND lo.status = 'pending'
 );
