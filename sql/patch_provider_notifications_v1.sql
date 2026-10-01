-- =============================================================
-- Patch: Provider Opportunity Notifications
-- File:  sql/patch_provider_notifications_v1.sql
-- Desc:  When a new need/request is created, notify every
--        provider whose declared capabilities match the
--        request's category or specific capability slug.
-- =============================================================

-- 1. Trigger function ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.trg_notify_matching_providers_on_need_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
  v_capability_slug  TEXT;
  v_category_slug    TEXT;
  v_title            TEXT;
  v_provider_id      UUID;
BEGIN
  -- Pull relevant fields from the inserted row
  v_capability_slug := NEW.capability_slug;   -- may be NULL
  v_category_slug   := NEW.category_slug;     -- always present
  v_title           := COALESCE(NEW.title, 'New opportunity');

  -- Loop over every provider who has at least one matching capability
  FOR v_provider_id IN
    SELECT DISTINCT pc.provider_id
    FROM   public.provider_capabilities pc
    JOIN   public.need_capabilities     nc ON nc.slug = pc.capability_slug
    WHERE
      -- Match on the specific capability if given, otherwise match by category
      (
        (v_capability_slug IS NOT NULL AND pc.capability_slug = v_capability_slug)
        OR
        (v_capability_slug IS NULL     AND nc.category_slug   = v_category_slug)
      )
      -- Don't notify the requester themselves (if they're also a provider)
      AND pc.provider_id <> NEW.requester_id
  LOOP
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      body,
      data,
      is_read,
      created_at
    ) VALUES (
      v_provider_id,
      'new_opportunity',
      'New Opportunity',
      v_title,
      jsonb_build_object(
        'need_id',         NEW.id,
        'category_slug',   v_category_slug,
        'capability_slug', v_capability_slug
      ),
      false,
      NOW()
    );
  END LOOP;

  RETURN NEW;
END;
$$;

-- 2. Attach trigger to needs_requests ─────────────────────────

DROP TRIGGER IF EXISTS trg_notify_matching_providers ON public.needs_requests;

CREATE TRIGGER trg_notify_matching_providers
  AFTER INSERT ON public.needs_requests
  FOR EACH ROW
  EXECUTE FUNCTION private.trg_notify_matching_providers_on_need_request();

-- 3. Grant execute to the authenticated role ──────────────────
-- (the function runs as SECURITY DEFINER so the caller only
--  needs INSERT on needs_requests, which is already granted)

COMMENT ON FUNCTION private.trg_notify_matching_providers_on_need_request()
  IS 'Notifies providers whose declared capabilities match a newly posted need request.';
