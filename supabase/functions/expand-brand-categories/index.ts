// Haven Edge Function: expand-brand-categories
// Phase 2 of the equipment catalog expansion.
//
// Asks Claude what every category a brand makes products in (current,
// discontinued, regional). Inserts the resulting (manufacturer, category)
// pairs into equipment_brand_categories with confidence scores. Phase 3's
// expand-catalog driver iterates the rows where confidence >= 70 to know
// which (brand, category) pairs to generate full portfolios for.
//
// Usage:
//   POST /functions/v1/expand-brand-categories
//   Body: { "manufacturer_slug": "lg" }                  // Sweep one brand
//   Body: { "batch": true, "limit": 10 }                 // Sweep next N brands
//   Body: { "manufacturer_slug": "lg", "force": true }   // Re-sweep even if rows exist

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
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

    // Pull the full list of categories ONCE — same set passes into every
    // brand prompt so Claude maps to a known slug rather than inventing one.
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
      // Find brands with no rows in equipment_brand_categories yet
      const { data: needsSweep } = await supabase.rpc("brands_without_brand_categories", {
        p_limit: batchLimit,
      }).maybeSingle()
        // RPC is optional; if it doesn't exist, fall back to the fetch-all-then-filter pattern below.
        .catch(() => ({ data: null }));

      let brands: { slug: string; name: string }[] = [];

      if (needsSweep && Array.isArray(needsSweep)) {
        brands = needsSweep as any;
      } else {
        // Fallback: list manufacturers, filter to those with no brand_categories rows
        const { data: allMfgs } = await supabase
          .from("equipment_manufacturers")
          .select("id, slug, name")
          .order("name")
          .limit(1000);

        const { data: existing } = await supabase
          .from("equipment_brand_categories")
          .select("manufacturer_id");

        const haveSweep = new Set((existing || []).map((r: any) => r.manufacturer_id));
        brands = (allMfgs || [])
          .filter((m: any) => !haveSweep.has(m.id))
          .slice(0, batchLimit)
          .map((m: any) => ({ slug: m.slug, name: m.name }));
      }

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

  // Skip if already swept (unless force)
  if (!force) {
    const { count } = await supabase
      .from("equipment_brand_categories")
      .select("id", { count: "exact", head: true })
      .eq("manufacturer_id", mfg.id);
    if ((count ?? 0) > 0) {
      return { brand: mfg.name, status: "already_swept", existing_rows: count };
    }
  }

  // Compact slug-only list grouped by room. Keeps the input prompt small so
  // the entire response budget can be spent on the JSON output (LG, Samsung,
  // GE, Whirlpool, Bosch can each surface 15-20 categories — that's a lot of
  // output tokens at ~150 each).
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

Be comprehensive about multi-category brands — LG also makes mini-splits / heat pumps / solar / air purifiers; Samsung also makes HVAC + air purifiers; Honeywell makes thermostats + humidifiers + detectors + air purifiers + cameras; Whirlpool also makes water heaters + dehumidifiers; Bosch also makes heat pumps + tankless water heaters; Generac also makes battery storage + EV chargers. For boutique brands the answer may be 1-3 categories — don't pad.

For each category return JSON: category_slug (exact match), marketing_name (≤ 60 chars, what ${mfg.name} calls the line), confidence (0-100), market_status ("current"/"discontinued"/"regional"/"historical"), notes (≤ 100 chars, sub-brand or market specifics).

Return ONLY a valid JSON array. No markdown fences, no commentary, no trailing text:
[{"category_slug":"...","marketing_name":"...","confidence":95,"market_status":"current","notes":"..."}]`;

  const resp = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": anthropicKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-6",
      // Multi-category brands like LG / Samsung / GE / Whirlpool / Bosch /
      // Honeywell can return 15-25 rows × ~200 tokens each. 8192 keeps headroom
      // without paying for a much-larger response on small specialist brands.
      max_tokens: 8192,
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    console.error(`[expand-brand-categories] Claude API error for ${slug}:`, errText);
    return { brand: mfg.name, status: "claude_error", http_status: resp.status };
  }

  const data = await resp.json();
  const text = data.content?.[0]?.text ?? "";

  // Tolerant parse: try direct JSON, then markdown-fenced JSON, then array regex
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
    console.error(`[expand-brand-categories] Could not parse response for ${slug}. Sample:`, text.substring(0, 300));
    return { brand: mfg.name, status: "parse_error", raw_sample: text.substring(0, 300) };
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
  };
}
