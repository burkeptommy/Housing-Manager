-- Phase 95 — telemetry table for ai-cost-discipline.
--
-- Every Claude call that goes through `callClaudeWithDiscipline` writes one
-- row here so daily spend can be summed and the budget cap can refuse new
-- calls when the per-day cap is exhausted. Powers the
-- _shared/ai-cost-discipline.ts:loadTodaysSpendUsd helper.

BEGIN;

CREATE TABLE IF NOT EXISTS chez_ai_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Short identifier for the call site (e.g. "expand_catalog",
    -- "analyze_request", "research_project_pro"). Lets us slice spend
    -- by feature in the analytics dashboard.
    tag TEXT NOT NULL,
    -- The exact model that was billed (haiku-4-5 vs sonnet-4-6, etc.).
    -- Determines the per-1M-token rate when computing daily spend.
    model TEXT NOT NULL,
    -- Token usage from the Anthropic API response.
    input_tokens INT NOT NULL DEFAULT 0,
    output_tokens INT NOT NULL DEFAULT 0,
    cache_read_tokens INT NOT NULL DEFAULT 0,
    cache_creation_tokens INT NOT NULL DEFAULT 0,
    -- The max_tokens cap the caller passed. Useful for tuning prompts
    -- (high cap + low actual output = wasted budget headroom).
    max_tokens INT,
    -- Optional context for analytics drill-down.
    request_id TEXT,
    household_id UUID REFERENCES households(id) ON DELETE SET NULL,
    user_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Hot path: daily-spend lookup filters by created_at and reads small
-- numeric columns. A B-tree on created_at is sufficient since the helper
-- caches the total in-memory for 60s.
CREATE INDEX IF NOT EXISTS idx_chez_ai_usage_created_at
    ON chez_ai_usage(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chez_ai_usage_tag_created
    ON chez_ai_usage(tag, created_at DESC);

ALTER TABLE chez_ai_usage ENABLE ROW LEVEL SECURITY;

-- Service-role only. Edge Functions write via service_role; admin portal
-- reads via service_role as well. No user-facing surface needs RLS.
DROP POLICY IF EXISTS "Service role manages ai usage" ON chez_ai_usage;
CREATE POLICY "Service role manages ai usage"
    ON chez_ai_usage FOR ALL
    USING (false);

COMMENT ON TABLE chez_ai_usage IS
  'Phase 95 — every callClaudeWithDiscipline call writes one row. Powers the per-day spend cap (loadTodaysSpendUsd) + cost analytics. Service-role-only access.';

COMMIT;
