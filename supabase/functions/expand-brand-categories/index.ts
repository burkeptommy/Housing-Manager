// Phase 95 — DISABLED.
//
// expand-brand-categories used claude-sonnet-4-6 with max_tokens 8192
// in a batch loop. Combined with cron-expand-catalog firing
// continuously this contributed to the runaway spend on 2026-05-06.
//
// Original implementation preserved in index.ts.disabled-bak. Re-enable
// after migrating the Claude call to the _shared/ai-cost-discipline.ts
// helper + switching the default model to claude-haiku-4-5.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  console.log("[expand-brand-categories] Disabled by Phase 95 cost-discipline patch. No-op.");
  return new Response(
    JSON.stringify({
      status: "disabled",
      reason: "phase_95_cost_discipline",
      message: "expand-brand-categories is paused. See index.ts.disabled-bak for original.",
      results: [],
    }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
