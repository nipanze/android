-- =============================================================================
-- Fix: ensure authenticated users can delete their own provider_capabilities rows.
-- Covers: missing table-level DELETE grant, missing/dropped RLS delete policy.
-- Safe to re-run.
-- =============================================================================

begin;

-- 1. Ensure table-level DELETE privilege is granted to authenticated role
grant delete on public.provider_capabilities to authenticated;

-- 2. Re-create the RLS delete policy (idempotent)
drop policy if exists "Users delete own provider capabilities" on public.provider_capabilities;
create policy "Users delete own provider capabilities"
  on public.provider_capabilities
  for delete to authenticated
  using (user_id = auth.uid());

commit;

