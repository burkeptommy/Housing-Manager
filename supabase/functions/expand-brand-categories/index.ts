// Haven Edge Function: expand-brand-categories
// Phase 2 of the equipment catalog expansion.
// Phase 95 — re-enabled with cost discipline (haiku-4-5, max_tokens 4096,
// daily budget cap, kill-switch via CHEZ_AI_ENABLED env var).
//
// Asks Claude what every category a brand makes products in. Inserts
// (manufacturer, category) pairs into equipment_brand_categories with
// confidence scores. Phase 3's expand-catalog driver iterates the rows
// where confidence >= 70 to know which (brand, category) pairs to expand.
//
// Usage:
//   POST /functions/v1/expand-brand-categories
//   Body: { "manufacturer_slug": "lg" }                  // Sweep one brand
//   Body: { "batch": true, "limit": 10 }                 // Sweep next N brands
//   Body: { "manufacturer_slug": "lg", "force": true }   // Re-sweep even if rows exist

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callClaudeWithDiscipline } from "../_shared/ai-cost-discipline.ts";
import { requireAdminOrInternal } from "../_shared/require-household.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Phase 95 — haiku is enough reasoning depth for category mapping. 4096 fits
// the largest multi-category brands (LG = 77 categories, Bosch = 69) at the
// concise output format below (~50 tokens/row).
const HAIKU_MAX_TOKENS = 4096;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  // July 2026 security sweep (audit S9): these batch/admin utilities were
  // fully unauthenticated in prod (arbitrary uploads, batch-job triggers,
  // Claude spend). Admin JWT (CHEZ_ADMIN_EMAILS), the internal secret, or
  // the service-role bearer are now required.
  if (!(await requireAdminOrInternal(req))) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY") ?? "";

    if (!anthropicKey) {
      return new Response(JSON.stringify({ error: "ANTHROPIC_API_KEY missing" }), { status: 500, headers });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json().catch(() => ({}));
    const slug: string | null = body.manufacturer_slug ?? null;
    const batch: boolean = body.batch ?? false;
    const batchLimit: number = Math.min(body.limit ?? 5, 20);
    const force: boolean = body.force ?? false;

    const { data: allCategories } = await supabase
      .from("equipment_categories")
      .select("id, slug, name, room")
      .order("slug");

    if (!allCategories || allCategories.length === 0) {
      return new Response(JSON.stringify({ error: "No categories in equipment_categories" }), { status: 500, headers });
    }

    const catBySlug: Record<string, { id: string; slug: string; name: string; room: string }> = {};
    for (const c of allCategories) catBySlug[c.slug] = c;

    const results: any[] = [];

    if (slug) {
      const r = await sweepBrand(supabase, anthropicKey, slug, allCategories, catBySlug, force);
      results.push(r);
    } else if (batch) {
      const { data: allMfgs } = await supabase
        .from("equipment_manufacturers")
        .select("id, slug, name")
        .order("name")
        .limit(1000);

      const { data: existing } = await supabase
        .from("equipment_brand_categories")
        .select("manufacturer_id");

      const haveSweep = new Set((existing || []).map((r: any) => r.manufacturer_id));
      const brands = (allMfgs || [])
        .filter((m: any) => !haveSweep.has(m.id))
        .slice(0, batchLimit)
        .map((m: any) => ({ slug: m.slug, name: m.name }));

      for (const b of brands) {
        const r = await sweepBrand(supabase, anthropicKey, b.slug, allCategories, catBySlug, force);
        results.push(r);
      }
    } else {
      return new Response(
        JSON.stringify({ error: "Provide either { manufacturer_slug } or { batch: true, limit }" }),
        { status: 400, headers }
      );
    }

    return new Response(JSON.stringify({ results }), { headers });
  } catch (err) {
    console.error("[expand-brand-categories] Error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

async function sweepBrand(
  supabase: any,
  anthropicKey: string,
  slug: string,
  allCategories: { id: string; slug: string; name: string; room: string }[],
  catBySlug: Record<string, { id: string; slug: string; name: string; room: string }>,
  force: boolean
) {
  const { data: mfg } = await supabase
    .from("equipment_manufacturers")
    .select("id, name, slug, tier, parent_company, country_of_origin, parent_brand_family")
    .eq("slug", slug)
    .single();

  if (!mfg) return { brand: slug, status: "not_found" };

  if (!force) {
    const { count } = await supabase
      .from("equipment_brand_categories")
      .select("id", { count: "exact", head: true })
      .eq("manufacturer_id", mfg.id);
    if ((count ?? 0) > 0) {
      return { brand: mfg.name, status: "already_swept", existing_rows: count };
    }
  }

  const grouped: Record<string, string[]> = {};
  for (const c of allCategories) {
    const room = c.room || "other";
    if (!grouped[room]) grouped[room] = [];
    grouped[room].push(c.slug);
  }
  const categoryList = Object.entries(grouped)
    .map(([room, slugs]) => `${room}: ${slugs.join(", ")}`)
    .join("\n");

  const prompt = `Brand: ${mfg.name} (${mfg.tier || "unknown"} tier${mfg.parent_company ? `, owned by ${mfg.parent_company}` : ""}${mfg.country_of_origin ? `, ${mfg.country_of_origin}` : ""})${mfg.parent_brand_family ? `\nBrand family: ${mfg.parent_brand_family} — only list categories THIS brand owns directly, not sibling brands' categories` : ""}

List every category ${mfg.name} makes or has made residential / light-commercial products in over the last 15 years, in any market. Map each to one of these slugs (do NOT invent new ones):

${categoryList}

Be comprehensive about multi-category brands. For boutique brands the answer may be 1-3 categories — don't pad.

For each category return JSON: category_slug (exact match), marketing_name (≤ 50 chars), confidence (0-100), market_status ("current"/"discontinued"/"regional"/"historical"), notes (≤ 80 chars).

Return ONLY a valid JSON array. No markdown, no commentary:
[{"category_slug":"...","marketing_name":"...","confidence":95,"market_status":"current","notes":"..."}]`;

  // Phase 95 — route through cost-discipline helper.
  const ai = await callClaudeWithDiscipline({
    supabase,
    apiKey: anthropicKey,
    tag: "expand_brand_categories",
    max_tokens: HAIKU_MAX_TOKENS,
    messages: [{ role: "user", content: prompt }],
  });

  if (!ai) {
    return { brand: mfg.name, status: "ai_disabled_or_capped" };
  }

  const text = ai.text;

  let parsed: any[] | null = null;
  try {
    parsed = JSON.parse(text);
  } catch {
    const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (fenced) {
      try { parsed = JSON.parse(fenced[1].trim()); } catch { /* fall through */ }
    }
    if (!parsed) {
      const arrayMatch = text.match(/\[[\s\S]*\]/);
      if (arrayMatch) {
        try { parsed = JSON.parse(arrayMatch[0]); } catch { /* fall through */ }
      }
    }
  }

  if (!Array.isArray(parsed)) {
    console.error(`[expand-brand-categories] Parse error for ${slug}. Sample:`, text.substring(0, 300));
    return { brand: mfg.name, status: "parse_error", raw_sample: text.substring(0, 300), model_used: ai.model_used };
  }

  let inserted = 0;
  let skipped = 0;
  const skippedReasons: Record<string, number> = {};

  for (const row of parsed) {
    const targetSlug = row?.category_slug;
    const cat = targetSlug ? catBySlug[targetSlug] : null;
    if (!cat) {
      skipped++;
      skippedReasons[targetSlug || "missing_slug"] = (skippedReasons[targetSlug || "missing_slug"] || 0) + 1;
      continue;
    }
    const confidence = Math.max(0, Math.min(100, Number(row.confidence ?? 0)));
    const marketStatus = ["current", "discontinued", "regional", "historical"].includes(row.market_status)
      ? row.market_status
      : "current";

    const { error } = await supabase
      .from("equipment_brand_categories")
      .upsert({
        manufacturer_id: mfg.id,
        category_id: cat.id,
        confidence,
        market_status: marketStatus,
        notes: row.notes ?? null,
        sourced_at: new Date().toISOString(),
      }, { onConflict: "manufacturer_id,category_id" });

    if (error) {
      skipped++;
      skippedReasons["upsert_error"] = (skippedReasons["upsert_error"] || 0) + 1;
      console.error(`[expand-brand-categories] Upsert error for ${mfg.slug}/${cat.slug}:`, error);
    } else {
      inserted++;
    }
  }

  return {
    brand: mfg.name,
    slug: mfg.slug,
    status: "swept",
    categories_returned: parsed.length,
    inserted,
    skipped,
    skipped_reasons: skippedReasons,
    model_used: ai.model_used,
    input_tokens: ai.input_tokens,
    output_tokens: ai.output_tokens,
  };
}
