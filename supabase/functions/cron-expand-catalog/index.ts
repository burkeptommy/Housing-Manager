// Haven Edge Function: cron-expand-catalog
//
// Phase 6 of the equipment catalog expansion.
// Phase 95 — re-enabled with cost discipline:
//   - Pre-flight check: if today's spend already > CHEZ_AI_DAILY_BUDGET_USD,
//     skip claiming new pairs entirely. Saves the wasted DB cycles when
//     pg_cron fires after the budget is exhausted.
//   - The downstream expand-catalog call also routes through
//     callClaudeWithDiscipline, so every Claude call has independent
//     cost protection. This function is the orchestrator-level brake.
//
// Paced, priority-driven nightly catalog expansion. Each invocation:
//   1. Claims the next N priority pairs via claim_next_priority_pairs(N)
//   2. Calls expand-catalog for each pair in parallel
//   3. Marks each pair complete (regardless of success/failure)
//   4. Returns summary
//
// Usage:
//   POST /functions/v1/cron-expand-catalog
//   Body: { "max_pairs": 5, "parallelism": 2 }   // optional, defaults shown
//   Body: { "dry_run": true }                    // see what would be claimed without firing

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DEFAULT_MAX_PAIRS = 5;
const DEFAULT_PARALLELISM = 2;

// Approx USD prices for the spend pre-check (matches ai-cost-discipline.ts).
const PRICE_PER_1M_INPUT_USD: Record<string, number> = {
  "claude-haiku-4-5": 1.0,
  "claude-haiku-4-5-20251001": 1.0,
  "claude-sonnet-4-6": 3.0,
};
const PRICE_PER_1M_OUTPUT_USD: Record<string, number> = {
  "claude-haiku-4-5": 5.0,
  "claude-haiku-4-5-20251001": 5.0,
  "claude-sonnet-4-6": 15.0,
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json().catch(() => ({}));
    const maxPairs: number = Math.min(Math.max(1, body.max_pairs ?? DEFAULT_MAX_PAIRS), 20);
    const parallelism: number = Math.min(Math.max(1, body.parallelism ?? DEFAULT_PARALLELISM), 5);
    const dryRun: boolean = body.dry_run ?? false;

    // Phase 95 — kill-switch check. If CHEZ_AI_ENABLED is off, skip the
    // claim entirely and report the disabled status. Cron will keep firing
    // but each fire is a fast no-op.
    const enabled = (Deno.env.get("CHEZ_AI_ENABLED") ?? "true").toLowerCase();
    if (enabled === "false" || enabled === "0" || enabled === "off") {
      return new Response(
        JSON.stringify({
          status: "ai_disabled",
          message: "CHEZ_AI_ENABLED=false — kill-switch is on. Set to true to resume catalog expansion.",
          pairs_claimed: 0,
        }),
        { headers }
      );
    }

    // Phase 95 — daily-budget pre-check. If today's spend has already
    // exceeded the per-day cap, skip claiming pairs. The downstream
    // expand-catalog calls would each refuse to fire anyway (the helper
    // does the same check), but that wastes DB cycles + claims pairs
    // that get marked complete with no progress. Better to stop here.
    const budgetStr = Deno.env.get("CHEZ_AI_DAILY_BUDGET_USD");
    const budget = budgetStr ? Number(budgetStr) : 50;
    if (budget > 0) {
      const spent = await loadTodaysSpendUsd(supabase);
      if (spent >= budget) {
        return new Response(
          JSON.stringify({
            status: "budget_exhausted",
            message: `Today's spend $${spent.toFixed(2)} >= cap $${budget}. Resume after midnight UTC or raise CHEZ_AI_DAILY_BUDGET_USD.`,
            spent_today_usd: Number(spent.toFixed(4)),
            daily_budget_usd: budget,
            pairs_claimed: 0,
          }),
          { headers }
        );
      }
    }

    // Step 1: Claim next N priority pairs atomically.
    const { data: rawClaimed, error: claimErr } = await supabase
      .rpc("claim_next_priority_pairs", { p_limit: maxPairs });

    if (claimErr) {
      console.error("[cron-expand-catalog] claim failed:", claimErr);
      return new Response(JSON.stringify({ error: claimErr.message }), { status: 500, headers });
    }

    const claimed = (rawClaimed ?? []).map((r: any) => ({
      manufacturer_id: r.out_manufacturer_id,
      category_id: r.out_category_id,
      manufacturer_slug: r.out_manufacturer_slug,
      category_slug: r.out_category_slug,
      priority_bucket: r.out_priority_bucket,
      current_count: r.out_current_count,
    }));

    if (claimed.length === 0) {
      return new Response(
        JSON.stringify({
          status: "no_gaps",
          message: "Catalog is fully saturated. Nothing to expand.",
          pairs_claimed: 0,
        }),
        { headers }
      );
    }

    if (dryRun) {
      return new Response(
        JSON.stringify({
          status: "dry_run",
          would_claim: claimed,
          count: claimed.length,
        }),
        { headers }
      );
    }

    // Step 2: Process pairs in parallel via fetch into expand-catalog.
    // expand-catalog itself routes through callClaudeWithDiscipline so each
    // pair has independent cost protection.
    const expandUrl = `${supabaseUrl}/functions/v1/expand-catalog`;
    const results: any[] = [];

    for (let i = 0; i < claimed.length; i += parallelism) {
      const chunk = claimed.slice(i, i + parallelism);
      const chunkResults = await Promise.all(
        chunk.map(async (pair: any) => {
          const startedAt = Date.now();
          try {
            const resp = await fetch(expandUrl, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${supabaseAnonKey}`,
                // expand-catalog is admin/internal-gated post-sweep.
                "x-internal-secret": Deno.env.get("INTERNAL_FN_SECRET") ?? "",
              },
              body: JSON.stringify({
                manufacturer_slug: pair.manufacturer_slug,
                category_slug: pair.category_slug,
                include_discontinued: true,
              }),
            });
            const data = await resp.json();
            const result = data?.results?.[0] ?? data;
            const elapsedMs = Date.now() - startedAt;

            await supabase.rpc("mark_priority_pair_complete", {
              p_manufacturer_id: pair.manufacturer_id,
              p_category_id: pair.category_id,
            });

            return {
              manufacturer_slug: pair.manufacturer_slug,
              category_slug: pair.category_slug,
              priority_bucket: pair.priority_bucket,
              status: result?.status ?? "unknown",
              inserted: result?.inserted ?? 0,
              skipped_duplicate: result?.skipped_duplicate ?? 0,
              skipped_invalid: result?.skipped_invalid ?? 0,
              model_used: result?.model_used ?? null,
              elapsed_ms: elapsedMs,
            };
          } catch (err) {
            await supabase.rpc("mark_priority_pair_complete", {
              p_manufacturer_id: pair.manufacturer_id,
              p_category_id: pair.category_id,
            });

            return {
              manufacturer_slug: pair.manufacturer_slug,
              category_slug: pair.category_slug,
              priority_bucket: pair.priority_bucket,
              status: "fetch_error",
              error: err instanceof Error ? err.message : String(err),
              elapsed_ms: Date.now() - startedAt,
            };
          }
        })
      );
      results.push(...chunkResults);
    }

    const totalInserted = results.reduce((sum, r) => sum + (r.inserted ?? 0), 0);
    const errors = results.filter((r) => r.status !== "expanded").length;

    return new Response(
      JSON.stringify({
        status: "ok",
        pairs_processed: results.length,
        total_inserted: totalInserted,
        errors,
        results,
      }),
      { headers }
    );
  } catch (err) {
    console.error("[cron-expand-catalog] Error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// Read today's spend from chez_ai_usage. Used for the pre-flight budget
// check. Mirrors the logic in _shared/ai-cost-discipline.ts:loadTodaysSpendUsd
// but inlined here to avoid importing the helper just for this one read
// (the helper's cache is process-local and we want a fresh value at the
// start of each cron run).
async function loadTodaysSpendUsd(supabase: any): Promise<number> {
  try {
    const startOfDay = new Date();
    startOfDay.setUTCHours(0, 0, 0, 0);
    const { data, error } = await supabase
      .from("chez_ai_usage")
      .select("model, input_tokens, output_tokens, cache_read_tokens")
      .gte("created_at", startOfDay.toISOString())
      .limit(5000);
    if (error || !data) return 0;
    let total = 0;
    for (const row of data as Array<{ model: string; input_tokens: number; output_tokens: number; cache_read_tokens: number }>) {
      const inRate = PRICE_PER_1M_INPUT_USD[row.model] ?? 3.0;
      const outRate = PRICE_PER_1M_OUTPUT_USD[row.model] ?? 15.0;
      const billedInput = Math.max(0, (row.input_tokens ?? 0) - (row.cache_read_tokens ?? 0)) +
        (row.cache_read_tokens ?? 0) * 0.1;
      total += (billedInput / 1_000_000) * inRate;
      total += ((row.output_tokens ?? 0) / 1_000_000) * outRate;
    }
    return total;
  } catch (e) {
    console.warn("[cron-expand-catalog] daily spend lookup failed:", e);
    return 0;
  }
}
