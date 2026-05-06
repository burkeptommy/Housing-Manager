-- Phase 95 — Chez AI usage telemetry.
--
-- Every successful Claude call from chez-concierge writes one row here.
-- The model fallback ladder + kill-switch live in the Edge Function;
-- this is just the audit trail so Tom can see where his Anthropic
-- spend is actually going day-to-day.
--
-- Read pattern: dashboards filter by created_at + tag + model. Indexes
-- support both. Service role writes (the Edge Function uses service
-- role context); admin reads via is_tom_admin().

CREATE TABLE IF NOT EXISTS public.chez_ai_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Call site identifier. Matches `tag` field on ClaudeCallOptions.
  -- e.g. "analyze_request", "ask_alfred", "suggest_vendor_framing".
  tag TEXT NOT NULL,
  -- Model name we actually billed against (after the fallback ladder
  -- picked one). Lets us see haiku vs sonnet split.
  model TEXT NOT NULL,
  -- Token counts straight from the Anthropic response. cache_read +
  -- cache_creation only fire when prompt caching is on (ask_alfred).
  input_tokens INT NOT NULL DEFAULT 0,
  output_tokens INT NOT NULL DEFAULT 0,
  cache_read_tokens INT NOT NULL DEFAULT 0,
  cache_creation_tokens INT NOT NULL DEFAULT 0,
  -- max_tokens we capped at. Helps see whether we're under-sizing
  -- (responses bumping the cap) or wastefully generous.
  max_tokens INT,
  -- Optional context for joining: which case / household / operator.
  request_id UUID REFERENCES public.chez_requests(id) ON DELETE SET NULL,
  household_id UUID REFERENCES public.households(id) ON DELETE SET NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Daily-spend roll-up index (group by day + model + tag).
CREATE INDEX IF NOT EXISTS idx_chez_ai_usage_created_at
  ON public.chez_ai_usage(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chez_ai_usage_tag
  ON public.chez_ai_usage(tag, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chez_ai_usage_model
  ON public.chez_ai_usage(model, created_at DESC);

ALTER TABLE public.chez_ai_usage ENABLE ROW LEVEL SECURITY;

-- Admin-only reads. No homeowner-side surface.
CREATE POLICY "Admin reads ai usage"
  ON public.chez_ai_usage FOR SELECT
  USING (public.is_tom_admin());

-- Service role writes (the Edge Function bypasses RLS via service role).
-- No explicit policy needed — service role bypasses RLS by default.

-- Phase 95 — server-side cache for analyze_request.
-- handleAnalyzeRequest used to call Claude on every case open (the
-- client-side memory cache reset on every browser refresh). Now we
-- stash the analysis result on the request itself + a timestamp so
-- subsequent opens return cached when no new messages have arrived.
ALTER TABLE public.chez_requests
  ADD COLUMN IF NOT EXISTS analysis_cache JSONB,
  ADD COLUMN IF NOT EXISTS analysis_cache_at TIMESTAMPTZ;
