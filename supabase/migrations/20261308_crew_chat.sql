-- Wave M7 — Crew chat (intra-workspace messaging)
--
-- Tech-to-tech / tech-to-dispatch coordination distinct from the
-- customer-visible thread on `handyman_request_messages`. A workspace
-- member can post "Bob just called in sick, anyone available to take
-- 4pm at the Smiths?" without it ever surfacing on the homeowner's
-- iOS app.
--
-- Authoring: any active workspace member can read + write threads and
-- messages for their workspace. Auth is enforced by the edge function
-- via assertWorkspaceAccess(), AND by RLS via the helper
-- public.get_my_provider_workspace_ids() so PostgREST direct reads
-- (Operations Desk SPA + iOS realtime channel filter) work without
-- routing every fetch through the function.

CREATE TABLE IF NOT EXISTS public.crew_chat_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.provider_workspaces(id) ON DELETE CASCADE,
  name TEXT,
  kind TEXT NOT NULL DEFAULT 'general' CHECK (kind IN ('general', 'route_day', 'tech_pair')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.crew_chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES public.crew_chat_threads(id) ON DELETE CASCADE,
  workspace_id UUID NOT NULL,
  sender_member_id UUID NOT NULL REFERENCES public.provider_workspace_members(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  read_by JSONB NOT NULL DEFAULT '[]'::jsonb,  -- array of member_ids who've read
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS crew_chat_threads_workspace_idx
  ON public.crew_chat_threads(workspace_id);

CREATE INDEX IF NOT EXISTS crew_chat_messages_thread_idx
  ON public.crew_chat_messages(thread_id);

CREATE INDEX IF NOT EXISTS crew_chat_messages_workspace_idx
  ON public.crew_chat_messages(workspace_id);

CREATE INDEX IF NOT EXISTS crew_chat_messages_thread_created_idx
  ON public.crew_chat_messages(thread_id, created_at DESC);

ALTER TABLE public.crew_chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_chat_messages ENABLE ROW LEVEL SECURITY;

-- Mirrors the workspace-RW pattern from
-- `provider_visit_tech_notes` / `provider_visit_pauses`. A member sees
-- a thread when their workspace shows up in
-- public.get_my_provider_workspace_ids() and writes are gated the same
-- way. The edge function double-gates via assertWorkspaceAccess so
-- direct PostgREST writes (which we don't ship today) would still
-- carry the workspace check.
CREATE POLICY "workspace_members_can_rw_threads"
  ON public.crew_chat_threads
  FOR ALL
  USING (workspace_id IN (SELECT public.get_my_provider_workspace_ids()))
  WITH CHECK (workspace_id IN (SELECT public.get_my_provider_workspace_ids()));

CREATE POLICY "workspace_members_can_rw_messages"
  ON public.crew_chat_messages
  FOR ALL
  USING (workspace_id IN (SELECT public.get_my_provider_workspace_ids()))
  WITH CHECK (workspace_id IN (SELECT public.get_my_provider_workspace_ids()));
