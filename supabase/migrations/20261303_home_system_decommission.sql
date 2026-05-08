-- Wave M3 — System inventory authoring
--
-- The most-used UX during a Chez assessment visit. The field tech walks
-- the home, captures every system in <30 seconds via camera-first sweep,
-- and the homeowner's iOS app reflects everything when the visit closes.
--
-- This migration adds the columns the field workflow needs that aren't
-- already on home_systems:
--
--   • marked_for_followup_at + followup_reason — tech couldn't access
--     this system this visit (tenant out, attic locked, breaker panel
--     buried). Surfaces on the next visit's prep checklist + on the
--     homeowner's dashboard if the gap is material.
--   • voice_note_path — voice memo recorded next to a system row, for
--     "this thing's making a weird hum, listen" context the photos can't
--     capture. Stored in the home-system-attachments bucket, mp4/m4a.
--
-- The decommissioning columns (decommissioned_at, decommissioned_reason,
-- is_active) were added in 20261211_chez_home_assessment_extensions.sql
-- and are already present on the table. We don't redefine them here so
-- the existing decommission_system action and the homeowner Haven app's
-- reconciler keep using the established names.

ALTER TABLE public.home_systems
  ADD COLUMN IF NOT EXISTS marked_for_followup_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS followup_reason TEXT,
  ADD COLUMN IF NOT EXISTS voice_note_path TEXT;

COMMENT ON COLUMN public.home_systems.marked_for_followup_at IS
  'M3 — set when a Chez field tech couldn''t access the system on the current visit. Surfaces on the next visit''s prep checklist + the homeowner dashboard.';

COMMENT ON COLUMN public.home_systems.followup_reason IS
  'M3 — short human note explaining why the tech couldn''t complete this system on the visit (e.g. "tenant unavailable", "attic locked").';

COMMENT ON COLUMN public.home_systems.voice_note_path IS
  'M3 — storage path inside home-system-attachments bucket pointing at the operator''s voice memo for this system. NULL when no memo recorded.';

-- Storage bucket for voice memos + any other system-level captures the
-- field workflow accumulates. Photos still live in home-system-photos
-- (created in earlier migration) — this bucket is for non-image artifacts.
INSERT INTO storage.buckets (id, name, public)
  VALUES ('home-system-attachments', 'home-system-attachments', false)
  ON CONFLICT (id) DO NOTHING;

-- Workspace-member RLS: a member of a provider workspace that has at
-- least one handyman_request linking the system's property's household
-- to one of the workspace's linked contractors can read + write voice
-- memos for that system. Mirrors the existing photo bucket pattern in
-- handyman-provider's loadSystemForProviderWrite() helper — the actual
-- writes go through the service role key in the edge function so we
-- don't need a permissive bucket policy here. We only allow SELECT for
-- linked workspace members (signed URL handout) + the original
-- household members.

DROP POLICY IF EXISTS "home_system_attachments_workspace_select" ON storage.objects;
CREATE POLICY "home_system_attachments_workspace_select"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'home-system-attachments'
    AND (
      -- Path is "{household_id}/{system_id}/voice.m4a" — the household
      -- members own everything in their folder.
      (split_part(name, '/', 1))::uuid IN (
        SELECT household_id FROM public.users WHERE id = auth.uid()
        UNION
        SELECT household_id FROM public.family_members WHERE linked_user_id = auth.uid()
      )
      OR
      -- A provider workspace member can read iff their workspace has at
      -- least one handyman_request whose household_id matches the
      -- folder's leading segment.
      (split_part(name, '/', 1))::uuid IN (
        SELECT hr.household_id
        FROM public.handyman_requests hr
        JOIN public.provider_contractor_links pcl
          ON pcl.contractor_id = hr.contractor_id
        WHERE pcl.workspace_id IN (SELECT public.get_my_provider_workspace_ids())
      )
    )
  );

-- Same scope for INSERT — but in practice the edge function uses the
-- service role key, so this is belt-and-braces.
DROP POLICY IF EXISTS "home_system_attachments_workspace_insert" ON storage.objects;
CREATE POLICY "home_system_attachments_workspace_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'home-system-attachments'
    AND (
      (split_part(name, '/', 1))::uuid IN (
        SELECT household_id FROM public.users WHERE id = auth.uid()
      )
      OR
      (split_part(name, '/', 1))::uuid IN (
        SELECT hr.household_id
        FROM public.handyman_requests hr
        JOIN public.provider_contractor_links pcl
          ON pcl.contractor_id = hr.contractor_id
        WHERE pcl.workspace_id IN (SELECT public.get_my_provider_workspace_ids())
      )
    )
  );

DROP POLICY IF EXISTS "home_system_attachments_workspace_delete" ON storage.objects;
CREATE POLICY "home_system_attachments_workspace_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'home-system-attachments'
    AND (
      (split_part(name, '/', 1))::uuid IN (
        SELECT household_id FROM public.users WHERE id = auth.uid()
      )
      OR
      (split_part(name, '/', 1))::uuid IN (
        SELECT hr.household_id
        FROM public.handyman_requests hr
        JOIN public.provider_contractor_links pcl
          ON pcl.contractor_id = hr.contractor_id
        WHERE pcl.workspace_id IN (SELECT public.get_my_provider_workspace_ids())
      )
    )
  );
