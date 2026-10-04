-- Run this patch in the Supabase SQL Editor after needs_requests exists.
-- Extends watchlist support to Marketplace Needs listings.

BEGIN;

ALTER TABLE public.watchlist
  ADD COLUMN IF NOT EXISTS needs_request_id UUID
  REFERENCES public.needs_requests(request_id) ON DELETE CASCADE;

ALTER TABLE public.watchlist
  DROP CONSTRAINT IF EXISTS chk_wl_one_target;

ALTER TABLE public.watchlist
  ADD CONSTRAINT chk_wl_one_target CHECK (
    (request_id IS NOT NULL AND forex_request_id IS NULL AND needs_request_id IS NULL) OR
    (request_id IS NULL AND forex_request_id IS NOT NULL AND needs_request_id IS NULL) OR
    (request_id IS NULL AND forex_request_id IS NULL AND needs_request_id IS NOT NULL)
  );

-- Full unique indexes allow PostgREST upsert conflict targets to be inferred.
CREATE UNIQUE INDEX IF NOT EXISTS uidx_wl_user_forex_request_full
  ON public.watchlist (user_id, forex_request_id);

CREATE UNIQUE INDEX IF NOT EXISTS uidx_wl_user_needs_request
  ON public.watchlist (user_id, needs_request_id);

COMMIT;
