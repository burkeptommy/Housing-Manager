// Haven Edge Function: expand-catalog
// Phase 3 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
//
// Rewritten from the original brand-narrow logic to a (brand, category)-pair
// portfolio expander. The Phase 2 expand-brand-categories function populates
// equipment_brand_categories with rows like (LG, hvac-mini-split, confidence
// 99). This function takes ONE such row and asks Claude for the top 50-80
// most popular models in that brand's product line for that category,
// ordered by popularity. Sibling-aware via parent_brand_family.
//
// Usage:
//   POST /functions/v1/expand-catalog
//   Body: {
//     "manufacturer_slug": "ao-smith",
//     "category_slug": "water-heater-heat-pump",
//     "include_discontinued": true,           // optional, default true
//     "popularity_offset": 0                  // optional, for second-pass continuation
//   }
//
//   Body: {
//     "batch": true,
//     "limit": 5,                              // process the next N un-expanded pairs
//     "tier": "premium"                        // optional filter: only this tier of brand
//   }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Cap on how many models we ask Claude for in a single first-pass call.
// Each model JSON row averages 250-400 tokens depending on field density.
// 40 × 400 ≈ 16K — fits inside max_tokens with headroom for the wrapper
// object + more_available flag. Brands with > 40 models trigger a second
// call via popularity_offset.
const MAX_MODELS_PER_CALL = 40;

// Confidence threshold below which we skip a (brand, category) pair in
// batch mode. Phase 2 sweeps assign 0-100; 70+ means Claude is confident the
// brand makes products in that category.
const MIN_CONFIDENCE = 70;

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
      // Find the next N (brand, category) pairs that haven't been expanded yet.
      // "Hasn't been expanded" = no equipment_catalog rows exist with verification_status =
      // 'claude_generated' AND created within the last 30 days for this (brand, category).
      // Simpler heuristic: pick the pair if equipment_catalog has fewer than 30 rows
      // for this (manufacturer_id, category_id) combination.
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
  // Pull (brand, category) pairs from equipment_brand_categories, joined to
  // existing equipment_catalog counts. Pick those with < 30 catalog rows.
  let q = supabase
    .from("equipment_brand_categories")
    .select(`
      confidence,
      manufacturer:equipment_manufacturers!inner(id, slug, name, tier),
      category:equipment_categories!inner(id, slug, name)
    `)
    .gte("confidence", MIN_CONFIDENCE)
    .order("confidence", { ascending: false })
    .limit(limit * 5); // over-fetch since we'll filter

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
  // Resolve manufacturer + sibling brands
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

  // Sibling brands in the same family — Phase 3 prompt warns Claude to avoid
  // duplicating the same SKU under multiple sibling brands.
  let siblings: { name: string; slug: string }[] = [];
  if (mfg.parent_brand_family) {
    const { data: sibs } = await supabase
      .from("equipment_manufacturers")
      .select("name, slug")
      .eq("parent_brand_family", mfg.parent_brand_family)
      .neq("id", mfg.id);
    siblings = (sibs as any[]) ?? [];
  }

  // Existing catalog rows for this (brand, category) — dedup by model_number
  const { data: existing } = await supabase
    .from("equipment_catalog")
    .select("model_number")
    .eq("manufacturer_id", mfg.id)
    .eq("category_id", cat.id);
  const existingModels = new Set((existing || []).map((e: any) => (e.model_number || "").toUpperCase()));

  // Brand-categories metadata: market_status + notes for prompt context
  const { data: brandCat } = await supabase
    .from("equipment_brand_categories")
    .select("market_status, notes, confidence")
    .eq("manufacturer_id", mfg.id)
    .eq("category_id", cat.id)
    .maybeSingle();

  // Build the popularity-ordered portfolio prompt
  const prompt = buildPortfolioPrompt({
    mfg, cat, siblings,
    existingModels: [...existingModels],
    includeDiscontinued,
    popularityOffset,
    brandCatNotes: brandCat?.notes ?? null,
  });

  const resp = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": anthropicKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-6",
      // 16K headroom: 80 rows × ~200 tokens each = 16K. Anthropic charges
      // actual output tokens, not max_tokens, so the boutique-brand short
      // responses don't get billed for unused capacity.
      max_tokens: 16384,
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    console.error(`[expand-catalog] Claude error for ${manufacturerSlug}/${categorySlug}:`, errText);
    return { brand: mfg.name, category: cat.name, status: "claude_error", http_status: resp.status };
  }

  const data = await resp.json();
  const text = data.content?.[0]?.text ?? "";

  // Tolerant parse cascade:
  //   1. Direct JSON (the happy path — prompt asks for raw JSON)
  //   2. Markdown-fenced JSON (Claude sometimes adds ```json despite the directive)
  //   3. Object-bounded extraction with truncation recovery: if Claude was
  //      cut off mid-object, find the last complete object in the models
  //      array and reassemble.
  let parsed: any = null;
  try {
    parsed = JSON.parse(text);
  } catch {
    const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (fenced) {
      try { parsed = JSON.parse(fenced[1].trim()); } catch { /* fall through */ }
    }
    if (!parsed) {
      // Strip leading ```json / trailing ``` if present, then try
      let stripped = text.trim();
      if (stripped.startsWith("```")) {
        stripped = stripped.replace(/^```(?:json)?\s*/, "").replace(/\s*```\s*$/, "");
      }
      try { parsed = JSON.parse(stripped); } catch { /* fall through */ }
    }
    if (!parsed) {
      // Truncation-recovery: extract everything up to the last complete
      // object inside "models": [ ... ] and synthesize a closing array.
      parsed = recoverTruncatedModels(text);
    }
  }

  if (!parsed || !Array.isArray(parsed.models)) {
    console.error(`[expand-catalog] Parse error ${manufacturerSlug}/${categorySlug}. Sample:`, text.substring(0, 400));
    return { brand: mfg.name, category: cat.name, status: "parse_error", raw_sample: text.substring(0, 400) };
  }

  const models: any[] = parsed.models;
  const moreAvailable: boolean = !!parsed.more_available;

  // Insert new rows
  let inserted = 0;
  let skippedDup = 0;
  let skippedInvalid = 0;
  const insertedModels: string[] = [];

  for (let i = 0; i < models.length; i++) {
    const m = models[i];
    const modelNumber = String(m?.model_number ?? "").trim();
    if (!modelNumber || modelNumber.length < 2) { skippedInvalid++; continue; }
    if (existingModels.has(modelNumber.toUpperCase())) { skippedDup++; continue; }

    // Parse capacity if present — same logic as the legacy expand-catalog
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

    // Build the row from whichever fields Claude actually returned. Phase 3
    // intentionally narrows the prompt to a tight subset — width/height/
    // depth/year_introduced/energy_star/wifi_enabled/expected_lifespan are
    // dropped from the prompt to keep response size in check, and default
    // safely on insert. They can be backfilled later via enrich-catalog.
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
      // The model_number+manufacturer_id unique constraint may catch a dup
      // not in our existingModels set (race or case mismatch). Treat as dup.
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
    ? `\nWe already have these model numbers — do NOT return them: ${existingModels.slice(0, 100).join(", ")}${existingModels.length > 100 ? `, +${existingModels.length - 100} more` : ""}.`
    : "";

  const contextNote = brandCatNotes
    ? `\nContext from earlier research: ${brandCatNotes}`
    : "";

  const headerSentence = isContinuation
    ? `Continuing the popularity-ordered list of ${mfg.name} ${cat.name} models. Return positions ${minRow}-${maxRow}.`
    : `Build a popularity-ordered list of ${mfg.name} ${cat.name} models. Return the most popular ${MAX_MODELS_PER_CALL} models, ordered most-popular first.`;

  return buildPortfolioPromptInner({ mfg, cat, siblingNote, contextNote, dedupNote, headerSentence, includeDiscontinued, maxRow });
}

function buildPortfolioPromptInner(args: any): string {
  const { mfg, cat, siblingNote, contextNote, dedupNote, headerSentence, includeDiscontinued, maxRow } = args;
  return `You are an expert on ${mfg.name}'s ${cat.name} product line${mfg.parent_company ? ` (owned by ${mfg.parent_company})` : ""}.${siblingNote}${contextNote}${dedupNote}

${headerSentence} Order by popularity / sales volume / prevalence in HNW homes today — bestsellers first, then mid-tier popular models${includeDiscontinued ? ", then common discontinued models from the last 10-15 years still operating in homes" : ""}.

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

CRITICAL: Return ONLY raw JSON. NO markdown fences. NO \`\`\`json wrapper. NO commentary. Start your response with { and end with }:
{"models":[{...}],"more_available":false}`;
}

// Recover models from a Claude response that was truncated mid-output.
// Strips any leading markdown fence, finds the start of the models array,
// and walks forward collecting complete top-level objects. Stops at the
// last complete object — partial trailing objects are dropped. Sets
// more_available=true so the caller knows to issue a continuation call.
//
// Returns null if the response can't be salvaged.
function recoverTruncatedModels(text: string): { models: any[]; more_available: boolean } | null {
  let s = text.trim();
  // Strip leading markdown fence
  if (s.startsWith("```")) {
    s = s.replace(/^```(?:json)?\s*/, "");
  }
  // Find the start of the models array
  const arrayStart = s.indexOf('"models"');
  if (arrayStart < 0) return null;
  const bracketStart = s.indexOf("[", arrayStart);
  if (bracketStart < 0) return null;

  const models: any[] = [];
  let i = bracketStart + 1;
  while (i < s.length) {
    // Skip whitespace + commas
    while (i < s.length && /[\s,]/.test(s[i])) i++;
    if (i >= s.length || s[i] === "]") break;
    if (s[i] !== "{") break;

    // Walk forward through balanced braces, tracking string state
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
    if (objEnd < 0) break; // truncated mid-object — stop here

    try {
      const obj = JSON.parse(s.substring(objStart, objEnd));
      models.push(obj);
    } catch {
      // Skip this malformed object and continue scanning
    }
  }

  if (models.length === 0) return null;
  return { models, more_available: true };
}
