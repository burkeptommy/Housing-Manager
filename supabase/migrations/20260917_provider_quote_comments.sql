-- Phase 75h: per-line-item Q&A on provider quotes.
--
-- Lets the homeowner tap any line item on the review sheet, attach a
-- question or comment, and batch-send. The provider sees those
-- comments inline on their quote builder and can reply per-line +
-- adjust the quote as needed.

CREATE TABLE IF NOT EXISTS public.provider_quote_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID NOT NULL REFERENCES public.provider_quotes(id) ON DELETE CASCADE,
    -- Nullable: a NULL line_item_id is a quote-level comment (general
    -- question rather than tied to a specific item).
    line_item_id TEXT,
    parent_comment_id UUID REFERENCES public.provider_quote_comments(id) ON DELETE CASCADE,
    author_role TEXT NOT NULL CHECK (author_role IN ('homeowner', 'provider')),
    author_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    body TEXT NOT NULL,
    -- "open" while waiting for a response; "answered" once the other
    -- side has replied or marked it resolved. Provider reply fires the
    -- transition automatically.
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'answered')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pqc_quote ON public.provider_quote_comments (quote_id, created_at);
CREATE INDEX IF NOT EXISTS idx_pqc_line_item ON public.provider_quote_comments (quote_id, line_item_id) WHERE line_item_id IS NOT NULL;

ALTER TABLE public.provider_quote_comments ENABLE ROW LEVEL SECURITY;

-- Homeowners see comments on quotes for their household.
DROP POLICY IF EXISTS "pqc_homeowner_select" ON public.provider_quote_comments;
CREATE POLICY "pqc_homeowner_select" ON public.provider_quote_comments
  FOR SELECT
  USING (
    quote_id IN (
      SELECT id FROM public.provider_quotes pq
       WHERE pq.household_id IN (SELECT household_id FROM public.users WHERE id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "pqc_homeowner_insert" ON public.provider_quote_comments;
CREATE POLICY "pqc_homeowner_insert" ON public.provider_quote_comments
  FOR INSERT
  WITH CHECK (
    author_role = 'homeowner'
    AND quote_id IN (
      SELECT id FROM public.provider_quotes pq
       WHERE pq.household_id IN (SELECT household_id FROM public.users WHERE id = auth.uid())
    )
  );

-- Providers see/insert comments on quotes their workspace owns.
DROP POLICY IF EXISTS "pqc_provider_select" ON public.provider_quote_comments;
CREATE POLICY "pqc_provider_select" ON public.provider_quote_comments
  FOR SELECT
  USING (
    quote_id IN (
      SELECT pq.id FROM public.provider_quotes pq
        JOIN public.provider_workspace_members pwm
          ON pwm.workspace_id = pq.workspace_id
       WHERE pwm.user_id = auth.uid() AND pwm.status = 'active'
    )
  );

-- Note: provider INSERT is gated server-side via the handyman-provider
-- edge function (which uses the service role) so we don't add a
-- direct INSERT policy here.

-- Add to the realtime publication so both sides see new comments
-- without manual refresh.
ALTER PUBLICATION supabase_realtime ADD TABLE public.provider_quote_comments;
