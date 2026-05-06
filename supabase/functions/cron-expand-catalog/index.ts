// Phase 95 — DISABLED.
//
// cron-expand-catalog was running continuously and burning Anthropic
// credit on claude-sonnet-4-6 calls (4-9K output tokens per call,
// 4-5 calls/min sustained per Tom's logs on 2026-05-06). The
// function used to be called nightly at 3am for a 1-hour window,
// but something was firing it on a much tighter schedule.
//
// This file is intentionally short-circuited. The original is
// preserved in `index.ts.disabled-bak` for reference. Re-enabling
// requires:
//   1. Confirming the pg_cron schedule is the intended cadence
//      (SELECT * FROM cron.job WHERE jobname LIKE '%expand%')
//   2. Routing the underlying expand-catalog call through the
//      Phase 95 _shared/ai-cost-discipline.ts helper so the daily
//      budget cap + kill-switch protect against runaways
//   3. Switching the model from claude-sonnet-4-6 to claude-haiku-4-5
//      (catalog row generation does not need sonnet's reasoning depth)
//
// Until then this returns 200 with a status payload so any caller
// (cron job or otherwise) doesn't error-loop.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  console.log("[cron-expand-catalog] Disabled by Phase 95 cost-discipline patch. No-op.");
  return new Response(
    JSON.stringify({
      status: "disabled",
      reason: "phase_95_cost_discipline",
      message: "cron-expand-catalog is paused. See index.ts.disabled-bak for original. Re-enable after migrating to ai-cost-discipline helper + switching model to haiku.",
      pairs_claimed: 0,
    }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
