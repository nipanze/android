-- Fix the Needs opportunity trigger to match the current schema:
-- provider_capabilities uses user_id, and needs_requests uses request_id.
-- Notification matching and recipient behavior are otherwise unchanged.

CREATE OR REPLACE FUNCTION private.trg_notify_matching_providers_on_need_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
  v_capability_slug text := NEW.capability_slug;
  v_category_slug text := NEW.category_slug;
  v_title text := COALESCE(NEW.title, 'New opportunity');
  v_provider_id uuid;
BEGIN
  FOR v_provider_id IN
    SELECT DISTINCT pc.user_id
    FROM public.provider_capabilities pc
    JOIN public.need_capabilities nc ON nc.slug = pc.capability_slug
    WHERE (
      (v_capability_slug IS NOT NULL AND pc.capability_slug = v_capability_slug)
      OR
      (v_capability_slug IS NULL AND nc.category_slug = v_category_slug)
    )
      AND pc.user_id <> NEW.requester_id
  LOOP
    INSERT INTO public.notifications (
      user_id, type, title, body, data, is_read, created_at
    ) VALUES (
      v_provider_id,
      'new_opportunity',
      'New Opportunity',
      v_title,
      jsonb_build_object(
        'need_id', NEW.request_id,
        'category_slug', v_category_slug,
        'capability_slug', v_capability_slug
      ),
      false,
      now()
    );
  END LOOP;

  RETURN NEW;
END;
$$;
