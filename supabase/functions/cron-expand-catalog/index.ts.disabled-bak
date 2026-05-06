// Haven Edge Function: cron-expand-catalog
//
// Phase 6 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
//
// Paced, priority-driven nightly catalog expansion. Each invocation:
//   1. Claims the next N priority pairs via claim_next_priority_pairs(N)
//   2. Calls expand-catalog for each pair in parallel (capped to stay under rate limits)
//   3. Marks each pair complete
//   4. Returns summary
//
// Designed to be called every 2 minutes by pg_cron during a nightly window.
// Default 5 pairs per invocation × 20 invocations = 100 pairs/night ≈ 4,000 rows.
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

// Conservative defaults — 5 pairs at parallelism 2 finishes in ~75s
// (within Supabase's HTTP timeout). Bump max_pairs if you're on a higher
// Anthropic tier and want to clear faster.
const DEFAULT_MAX_PAIRS = 5;
const DEFAULT_PARALLELISM = 2;

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

    // Step 1: Claim next N priority pairs atomically.
    // The RPC returns columns prefixed `out_*` to disambiguate from the
    // catalog_expansion_priority view's column names (PL/pgSQL OUT-param
    // shadowing). We map back to natural names here.
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
      // No more gaps — catalog is complete (within saturation threshold).
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

    // Step 2: Process pairs in parallel (capped by parallelism).
    // Each pair fires expand-catalog via fetch. We don't refactor expand-catalog
    // to share its core function — fetch keeps the boundary clean and lets us
    // re-run individual pairs from the dashboard if needed.
    const expandUrl = `${supabaseUrl}/functions/v1/expand-catalog`;
    const results: any[] = [];

    // Simple parallelism via chunked Promise.all
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

            // Mark complete regardless — we don't want failed pairs to block
            // the queue forever. They'll re-surface on next priority recompute
            // since current_count won't have grown.
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
              elapsed_ms: elapsedMs,
            };
          } catch (err) {
            // Mark complete so the pair doesn't lock for 10 min — it'll
            // re-enter the queue at the next priority recompute and retry.
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
