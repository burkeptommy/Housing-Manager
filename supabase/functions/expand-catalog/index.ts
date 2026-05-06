// Phase 95 — DISABLED.
//
// expand-catalog used claude-sonnet-4-6 with max_tokens 16384 — the
// most expensive model at the highest cap. Combined with a runaway
// cron firing it 4-5×/minute it generated >11M output tokens in a
// single day on 2026-05-06.
//
// Original implementation preserved in index.ts.disabled-bak. To
// re-enable, route the Claude call through the Phase 95
// _shared/ai-cost-discipline.ts helper, switch the default model to
// claude-haiku-4-5, drop max_tokens to 4096, and set a sensible
// per-day cap via CHEZ_AI_DAILY_BUDGET_USD. THEN re-enable the cron.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  console.log("[expand-catalog] Disabled by Phase 95 cost-discipline patch. No-op.");
  return new Response(
    JSON.stringify({
      status: "disabled",
      reason: "phase_95_cost_discipline",
      message: "expand-catalog is paused. See index.ts.disabled-bak for original.",
      models_added: 0,
    }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
