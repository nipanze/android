-- =============================================================================
-- Patch v2: ensure authenticated users can delete their own provider_capabilities
-- rows directly via RLS (no RPC needed). Safe to re-run.
-- =============================================================================

begin;

-- Ensure the delete RLS policy exists on provider_capabilities
drop policy if exists "Users delete own provider capabilities" on public.provider_capabilities;
create policy "Users delete own provider capabilities" on public.provider_capabilities
  for delete to authenticated using (user_id = auth.uid());

commit;

