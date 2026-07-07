// Haven Edge Function: expand-catalog
// Phase 3 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
// Phase 95 — re-enabled with cost discipline (haiku-4-5 default, max_tokens 4096,
// daily budget cap, kill-switch via CHEZ_AI_ENABLED env var).
//
// Takes ONE (brand, category) pair and asks Claude for the most popular models
// in that brand's product line for that category, ordered by popularity.
// Sibling-aware via parent_brand_family.
//
// Usage:
//   POST /functions/v1/expand-catalog
//   Body: {
//     "manufacturer_slug": "ao-smith",
//     "category_slug": "water-heater-heat-pump",
//     "include_discontinued": true,           // optional, default true
//     "popularity_offset": 0                  // optional, for second-pass continuation
//   }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callClaudeWithDiscipline } from "../_shared/ai-cost-discipline.ts";
import { requireAdminOrInternal } from "../_shared/require-household.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Phase 95 — dropped from 40 to 25 to fit in 4096-token max_tokens cap on
// haiku. Each model JSON row ≈ 130-180 tokens; 25 × 160 = 4000 tokens leaves
// headroom for the wrapper { "models": [...], "more_available": ... }.
// Brands with > 25 models trigger a second call via popularity_offset
// (more_available: true → caller fires a continuation call).
const MAX_MODELS_PER_CALL = 25;

// Phase 95 — haiku is enough reasoning depth for catalog enumeration.
// max_tokens kept tight to prevent the model from rambling. The helper
// allows fallback to sonnet on rate limits / overloads automatically.
const HAIKU_MAX_TOKENS = 4096;

const MIN_CONFIDENCE = 70;

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

    const manufacturerSlug: string | null = body.manufacturer_slug ?? null;
    const categorySlug: string | null = body.category_slug ?? null;
    const includeDiscontinued: boolean = body.include_discontinued ?? true;
    const popularityOffset: number = Math.max(0, Number(body.popularity_offset ?? 0));
    const batch: boolean = body.batch ?? false;
    const batchLimit: number = Math.min(body.limit ?? 5, 20);
    const tierFilter: string | null = body.tier ?? null;

    const results: any[] = [];

    if (manufacturerSlug && categorySlug) {
      const r = await expandPair(
        supabase, anthropicKey,
        manufacturerSlug, categorySlug,
        includeDiscontinued, popularityOffset
      );
      results.push(r);
    } else if (batch) {
      const pairs = await findUnexpandedPairs(supabase, batchLimit, tierFilter);
      for (const p of pairs) {
        const r = await expandPair(
          supabase, anthropicKey,
          p.manufacturer_slug, p.category_slug,
          includeDiscontinued, 0
        );
        results.push(r);
      }
    } else {
      return new Response(
        JSON.stringify({ error: "Provide either { manufacturer_slug + category_slug } or { batch: true, limit }" }),
        { status: 400, headers }
      );
    }

    return new Response(JSON.stringify({ results }), { headers });
  } catch (err) {
    console.error("[expand-catalog] Error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

async function findUnexpandedPairs(
  supabase: any,
  limit: number,
  tierFilter: string | null
): Promise<{ manufacturer_slug: string; category_slug: string; manufacturer_name: string; category_name: string }[]> {
  let q = supabase
    .from("equipment_brand_categories")
    .select(`
      confidence,
      manufacturer:equipment_manufacturers!inner(id, slug, name, tier),
      category:equipment_categories!inner(id, slug, name)
    `)
    .gte("confidence", MIN_CONFIDENCE)
    .order("confidence", { ascending: false })
    .limit(limit * 5);

  if (tierFilter) {
    q = q.eq("manufacturer.tier", tierFilter);
  }

  const { data: candidates } = await q;
  if (!candidates) return [];

  const pairs: { manufacturer_slug: string; category_slug: string; manufacturer_name: string; category_name: string }[] = [];
  for (const row of candidates as any[]) {
    if (pairs.length >= limit) break;
    const mfgId = row.manufacturer.id;
    const catId = row.category.id;
    const { count } = await supabase
      .from("equipment_catalog")
      .select("id", { count: "exact", head: true })
      .eq("manufacturer_id", mfgId)
      .eq("category_id", catId);
    if ((count ?? 0) < 30) {
      pairs.push({
        manufacturer_slug: row.manufacturer.slug,
        category_slug: row.category.slug,
        manufacturer_name: row.manufacturer.name,
        category_name: row.category.name,
      });
    }
  }
  return pairs;
}

async function expandPair(
  supabase: any,
  anthropicKey: string,
  manufacturerSlug: string,
  categorySlug: string,
  includeDiscontinued: boolean,
  popularityOffset: number
) {
  const { data: mfg } = await supabase
    .from("equipment_manufacturers")
    .select("id, name, slug, tier, parent_company, country_of_origin, parent_brand_family")
    .eq("slug", manufacturerSlug)
    .single();
  if (!mfg) return { brand: manufacturerSlug, category: categorySlug, status: "manufacturer_not_found" };

  const { data: cat } = await supabase
    .from("equipment_categories")
    .select("id, slug, name, room, parent_category_id, typical_lifespan_years")
    .eq("slug", categorySlug)
    .single();
  if (!cat) return { brand: manufacturerSlug, category: categorySlug, status: "category_not_found" };

  let siblings: { name: string; slug: string }[] = [];
  if (mfg.parent_brand_family) {
    const { data: sibs } = await supabase
      .from("equipment_manufacturers")
      .select("name, slug")
      .eq("parent_brand_family", mfg.parent_brand_family)
      .neq("id", mfg.id);
    siblings = (sibs as any[]) ?? [];
  }

  const { data: existing } = await supabase
    .from("equipment_catalog")
    .select("model_number")
    .eq("manufacturer_id", mfg.id)
    .eq("category_id", cat.id);
  const existingModels = new Set((existing || []).map((e: any) => (e.model_number || "").toUpperCase()));

  const { data: brandCat } = await supabase
    .from("equipment_brand_categories")
    .select("market_status, notes, confidence")
    .eq("manufacturer_id", mfg.id)
    .eq("category_id", cat.id)
    .maybeSingle();

  const prompt = buildPortfolioPrompt({
    mfg, cat, siblings,
    existingModels: [...existingModels],
    includeDiscontinued,
    popularityOffset,
    brandCatNotes: brandCat?.notes ?? null,
  });

  // Phase 95 — route through cost-discipline helper. Returns null if the
  // kill-switch is on (CHEZ_AI_ENABLED=false), the daily budget cap is
  // exhausted, or every model in the ladder errored. The function caller
  // should treat null as a hard stop and surface degraded UX upstream.
  const ai = await callClaudeWithDiscipline({
    supabase,
    apiKey: anthropicKey,
    tag: "expand_catalog",
    max_tokens: HAIKU_MAX_TOKENS,
    messages: [{ role: "user", content: prompt }],
    // models default to [haiku-4-5, haiku-4-5, sonnet-4-6] — cheapest first
  });

  if (!ai) {
    return {
      brand: mfg.name,
      category: cat.name,
      status: "ai_disabled_or_capped",
      message: "AI call skipped — kill-switch on, daily budget exhausted, or all models failed.",
    };
  }

  const text = ai.text;

  // Tolerant parse cascade — same logic as before, defensive against haiku's
  // formatting variance (it sometimes adds commentary or markdown fences).
  let parsed: any = null;
  try {
    parsed = JSON.parse(text);
  } catch {
    const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (fenced) {
      try { parsed = JSON.parse(fenced[1].trim()); } catch { /* fall through */ }
    }
    if (!parsed) {
      let stripped = text.trim();
      if (stripped.startsWith("```")) {
        stripped = stripped.replace(/^```(?:json)?\s*/, "").replace(/\s*```\s*$/, "");
      }
      try { parsed = JSON.parse(stripped); } catch { /* fall through */ }
    }
    if (!parsed) {
      parsed = recoverTruncatedModels(text);
    }
  }

  if (!parsed || !Array.isArray(parsed.models)) {
    console.error(`[expand-catalog] Parse error ${manufacturerSlug}/${categorySlug}. Sample:`, text.substring(0, 400));
    return { brand: mfg.name, category: cat.name, status: "parse_error", raw_sample: text.substring(0, 400), model_used: ai.model_used };
  }

  const models: any[] = parsed.models;
  const moreAvailable: boolean = !!parsed.more_available;

  let inserted = 0;
  let skippedDup = 0;
  let skippedInvalid = 0;
  const insertedModels: string[] = [];

  for (let i = 0; i < models.length; i++) {
    const m = models[i];
    const modelNumber = String(m?.model_number ?? "").trim();
    if (!modelNumber || modelNumber.length < 2) { skippedInvalid++; continue; }
    if (existingModels.has(modelNumber.toUpperCase())) { skippedDup++; continue; }

    let capacityValue: number | null = null;
    let capacityUnit: string | null = null;
    if (m.capacity) {
      const capMatch = String(m.capacity).match(/([\d.]+)\s*(cu\s*ft|dba|btu|gallons?|gpm|tons?|kw|watts?|amps?)/i);
      if (capMatch) {
        capacityValue = parseFloat(capMatch[1]);
        capacityUnit = capMatch[2].toLowerCase().replace(/\s+/g, "_").replace("gallons", "gal");
      }
    }
    if (capacityValue === null && typeof m.capacity_value === "number") {
      capacityValue = m.capacity_value;
      capacityUnit = m.capacity_unit ?? null;
    }

    const popularityRank = popularityOffset + i + 1;

    const row = {
      manufacturer_id: mfg.id,
      category_id: cat.id,
      model_number: modelNumber,
      model_name: m.model_name ?? null,
      series: m.series ?? null,
      fuel_type: m.fuel_type ?? null,
      installation_type: m.installation_type ?? null,
      capacity: m.capacity ?? null,
      capacity_value: capacityValue,
      capacity_unit: capacityUnit,
      msrp_usd: typeof m.msrp_usd === "number" ? m.msrp_usd : null,
      year_discontinued: typeof m.year_discontinued === "number" ? m.year_discontinued : null,
      is_current_model: m.is_current_model ?? true,
      expected_lifespan_years: cat.typical_lifespan_years ?? null,
      key_features: Array.isArray(m.key_features) ? m.key_features.slice(0, 4) : [],
      specs: m.specs ?? {},
      verification_status: "claude_generated",
      popularity_rank: popularityRank,
      last_verified_at: null,
    };

    const { error } = await supabase.from("equipment_catalog").insert(row);
    if (error) {
      if (String(error.message || "").includes("duplicate")) {
        skippedDup++;
      } else {
        skippedInvalid++;
        console.error(`[expand-catalog] Insert error ${manufacturerSlug}/${categorySlug}/${modelNumber}:`, error.message);
      }
    } else {
      inserted++;
      existingModels.add(modelNumber.toUpperCase());
      insertedModels.push(modelNumber);
    }
  }

  return {
    brand: mfg.name,
    brand_slug: mfg.slug,
    category: cat.name,
    category_slug: cat.slug,
    status: "expanded",
    models_returned: models.length,
    inserted,
    skipped_duplicate: skippedDup,
    skipped_invalid: skippedInvalid,
    more_available: moreAvailable,
    popularity_offset_used: popularityOffset,
    sample_inserted: insertedModels.slice(0, 5),
    model_used: ai.model_used,
    input_tokens: ai.input_tokens,
    output_tokens: ai.output_tokens,
  };
}

function buildPortfolioPrompt(opts: {
  mfg: { name: string; tier: string | null; parent_company: string | null; country_of_origin: string | null; parent_brand_family: string | null };
  cat: { name: string; slug: string; room: string | null; typical_lifespan_years: number | null };
  siblings: { name: string; slug: string }[];
  existingModels: string[];
  includeDiscontinued: boolean;
  popularityOffset: number;
  brandCatNotes: string | null;
}): string {
  const { mfg, cat, siblings, existingModels, includeDiscontinued, popularityOffset, brandCatNotes } = opts;

  const isContinuation = popularityOffset > 0;
  const minRow = popularityOffset + 1;
  const maxRow = popularityOffset + MAX_MODELS_PER_CALL;

  const siblingNote = siblings.length
    ? `\nSibling brands in the ${mfg.parent_brand_family} family (DO NOT duplicate the same SKU under these names — only return models sold under the "${mfg.name}" brand specifically): ${siblings.map(s => s.name).join(", ")}.`
    : "";

  const dedupNote = existingModels.length
    ? `\nWe already have these model numbers — do NOT return them: ${existingModels.slice(0, 80).join(", ")}${existingModels.length > 80 ? `, +${existingModels.length - 80} more` : ""}.`
    : "";

  const contextNote = brandCatNotes
    ? `\nContext: ${brandCatNotes}`
    : "";

  const headerSentence = isContinuation
    ? `Continuing the popularity-ordered list of ${mfg.name} ${cat.name} models. Return positions ${minRow}-${maxRow}.`
    : `Build a popularity-ordered list of ${mfg.name} ${cat.name} models. Return up to ${MAX_MODELS_PER_CALL} models, ordered most-popular first.`;

  return `You are an expert on ${mfg.name}'s ${cat.name} product line${mfg.parent_company ? ` (owned by ${mfg.parent_company})` : ""}.${siblingNote}${contextNote}${dedupNote}

${headerSentence} Order by popularity / sales volume / prevalence in HNW homes today — bestsellers first${includeDiscontinued ? ", then common discontinued models from the last 10-15 years still operating in homes" : ""}.

Cover all series, capacity/size/fuel/finish variants. For boutique brands with only 5-20 SKUs, return all of them. Do NOT invent fake model numbers — only real ones.

Per model return these fields (concise — omit fields that are null/unknown):
- model_number: REAL exact (e.g. "HPTU-80N", "B36CL81ENS")
- model_name: ≤ 60 chars
- series: e.g. "Voltex", "800 Series" (null if none)
- fuel_type: "gas"/"electric"/"dual-fuel"/"induction"/"propane"/"oil" (null if N/A)
- installation_type: "freestanding"/"built-in"/"slide-in"/"wall-mount"/"under-counter"/"ducted"/"mini-split" (null if N/A)
- capacity: e.g. "80 gallons", "5.0 cu ft", "44 dBA" (null if N/A)
- capacity_value: numeric only (e.g. 80)
- capacity_unit: "gal"/"cu_ft"/"btu"/"dba"/"tons"/"kw"/"watts"/"amps"/"gpm"
- msrp_usd: estimate, number or null
- year_discontinued: year if discontinued, null if current
- is_current_model: true/false
- key_features: array of 2-4 SHORT feature strings (≤ 30 chars each)
- specs: tiny JSON for category-specific specs (e.g. {"uef":3.45} or {"btu":24000,"seer":18}); {} if none

Set "more_available": true if there are more popular models beyond position ${maxRow}; false if this is the full portfolio or close to it.

CRITICAL: Return ONLY raw JSON. NO markdown fences. NO \`\`\`json wrapper. NO commentary. Start with { and end with }:
{"models":[{...}],"more_available":false}`;
}

function recoverTruncatedModels(text: string): { models: any[]; more_available: boolean } | null {
  let s = text.trim();
  if (s.startsWith("```")) {
    s = s.replace(/^```(?:json)?\s*/, "");
  }
  const arrayStart = s.indexOf('"models"');
  if (arrayStart < 0) return null;
  const bracketStart = s.indexOf("[", arrayStart);
  if (bracketStart < 0) return null;

  const models: any[] = [];
  let i = bracketStart + 1;
  while (i < s.length) {
    while (i < s.length && /[\s,]/.test(s[i])) i++;
    if (i >= s.length || s[i] === "]") break;
    if (s[i] !== "{") break;

    let depth = 0;
    let inString = false;
    let escape = false;
    const objStart = i;
    let objEnd = -1;
    for (; i < s.length; i++) {
      const ch = s[i];
      if (escape) { escape = false; continue; }
      if (ch === "\\") { escape = true; continue; }
      if (ch === '"') { inString = !inString; continue; }
      if (inString) continue;
      if (ch === "{") depth++;
      else if (ch === "}") {
        depth--;
        if (depth === 0) { objEnd = i + 1; i++; break; }
      }
    }
    if (objEnd < 0) break;

    try {
      const obj = JSON.parse(s.substring(objStart, objEnd));
      models.push(obj);
    } catch {
      // skip malformed
    }
  }

  if (models.length === 0) return null;
  return { models, more_available: true };
}
