-- Add the notification kind used by the Needs provider-opportunity trigger.
-- Run this as a standalone statement and let it commit before retrying the
-- Needs seed so PostgreSQL can use the new enum value in trigger inserts.

ALTER TYPE public.notification_type_enum
  ADD VALUE IF NOT EXISTS 'new_opportunity';
