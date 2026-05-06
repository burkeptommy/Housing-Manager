// Haven Edge Function: search-equipment
// Fast fuzzy search across the equipment catalog for autocomplete.
// Supports natural language queries like "bosch stove", "carrier ac",
// "dishwasher", "48 inch range", or exact model numbers.
//
// Usage:
//   POST /functions/v1/search-equipment
//   Body: { "query": "bosch stove" }
//   Body: { "query": "bosch stove", "limit": 20 }
//   Body: { "query": "RF29DB", "exact": true }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json().catch(() => ({}));
    const query: string = (body.query ?? "").trim();
    const limit: number = Math.min(body.limit ?? 15, 50);
    const categoryFilter: string | null = body.category ?? null;

    if (!query || query.length < 2) {
      return new Response(
        JSON.stringify({ results: [], query, message: "Query too short" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse the query into components
    const words = query.toLowerCase().split(/\s+/).filter(w => w.length > 1);

    // Phase 5 — spec-signal extraction. Pulls capacity, fuel, finish, and
    // installation hints out of the query so we can rank results that align
    // with what the user actually typed. Used only by Strategy 1 (brand +
    // category) where multiple matches need a tiebreaker; other strategies
    // are already narrow enough.
    const querySignals = extractQuerySignals(query.toLowerCase());

    // Common category aliases people might type
    const categoryAliases: Record<string, string[]> = {
      stove: ["range", "cooktop", "range-gas", "range-electric", "range-dual-fuel", "range-induction", "range-pro", "cooktop-gas", "cooktop-electric", "cooktop-induction"],
      oven: ["wall-oven", "wall-oven-single", "wall-oven-double", "wall-oven-combo", "range"],
      fridge: ["refrigerator", "refrigerator-french-door", "refrigerator-side-by-side", "refrigerator-top-freezer", "refrigerator-bottom-freezer", "refrigerator-column", "refrigerator-built-in"],
      refrigerator: ["refrigerator", "refrigerator-french-door", "refrigerator-side-by-side", "refrigerator-top-freezer"],
      washer: ["washer", "washer-front-load", "washer-top-load-agitator", "washer-top-load-impeller", "washer-compact"],
      dryer: ["dryer", "dryer-electric", "dryer-gas", "dryer-heat-pump", "dryer-compact"],
      ac: ["hvac", "hvac-central-ac", "hvac-heat-pump", "hvac-mini-split"],
      "air conditioner": ["hvac-central-ac", "hvac-heat-pump"],
      furnace: ["hvac-furnace"],
      boiler: ["hvac-boiler"],
      "mini split": ["hvac-mini-split"],
      induction: ["range-induction", "cooktop-induction"],
      // Note: "heat pump" maps to multiple categories. Phase 5 ranking uses
      // brand context — when query contains a water-heater brand (AO Smith,
      // Rheem, Bradford White) + "hybrid"/"gallon", water-heater-heat-pump
      // wins via the disambiguation in resolveCategoryByBrandContext below.
      "heat pump": ["hvac-heat-pump", "dryer-heat-pump", "water-heater-heat-pump"],
      toilet: ["toilet"],
      faucet: ["bathroom-faucet"],
      shower: ["shower-system"],
      tub: ["bathtub"],
      "water heater": ["water-heater", "water-heater-tank-gas", "water-heater-tank-electric", "water-heater-tankless-gas", "water-heater-heat-pump"],
      tankless: ["water-heater-tankless-gas", "water-heater-tankless-electric"],
      hybrid: ["water-heater-heat-pump"],
      "hybrid water heater": ["water-heater-heat-pump"],
      "heat pump water heater": ["water-heater-heat-pump"],
      "hpwh": ["water-heater-heat-pump"],
      "sump pump": ["sump-pump", "sump-pump-submersible"],
      generator: ["generator", "generator-portable", "generator-inverter", "generator-standby-gas"],
      pool: ["pool-pump", "pool-filter", "pool-heater", "salt-chlorine-generator", "pool-cleaner"],
      dishwasher: ["dishwasher"],
      microwave: ["microwave", "microwave-otr", "microwave-built-in", "microwave-drawer"],
      "range hood": ["range-hood", "range-hood-wall", "range-hood-island", "range-hood-under-cabinet"],
      sprinkler: ["irrigation-controller", "sprinkler-head"],
      softener: ["water-treatment-softener"],
      freezer: ["freezer-upright", "freezer-chest"],
      garbage: ["garbage-disposal"],
      disposal: ["garbage-disposal"],
      wine: ["wine-cooler", "wine-cellar-cooling"],
    };

    // Phase 5 — words that describe specs/units, never brands. Catches
    // "gallon"/"hybrid"/"electric" leaking into the brand-pattern when the
    // query has both a brand and spec descriptors ("AO Smith 80 gallon
    // hybrid heat pump"). Without this, brand matching tries to find a
    // brand named "ao smith gallon hybrid" and fails.
    const SPEC_STOPWORDS = new Set([
      "gallon", "gallons", "gal", "liter", "liters", "ltr",
      "ton", "tons",
      "cu", "ft", "cubic", "feet", "foot",
      "btu", "btus", "kbtu",
      "dba", "decibel",
      "watt", "watts", "kw", "amp", "amps", "volt", "volts", "voltage",
      "gpm",
      "inch", "inches",
      "hybrid", "dual", "fuel",
      "electric", "gas", "propane", "natural", "ng", "lp", "oil",
      "induction", "convection", "radiant", "solar",
      "year", "years",
      "current", "model", "discontinued",
      "size", "capacity",
      "wifi", "smart", "connected",
      "energy", "star",
    ]);

    // Detect if any word is a category alias
    let detectedCategorySlugs: string[] = [];
    let brandWords: string[] = [];
    let otherWords: string[] = [];
    const consumedIndices = new Set<number>();

    for (let i = 0; i < words.length; i++) {
      if (consumedIndices.has(i)) continue;
      const word = words[i];

      // Check two-word combos first (e.g., "heat pump", "water heater", "mini split")
      if (i + 1 < words.length) {
        const twoWord = `${word} ${words[i + 1]}`;
        if (categoryAliases[twoWord]) {
          detectedCategorySlugs.push(...categoryAliases[twoWord]);
          consumedIndices.add(i);
          consumedIndices.add(i + 1);
          continue;
        }
      }

      // Single-word category match
      if (categoryAliases[word]) {
        detectedCategorySlugs.push(...categoryAliases[word]);
        consumedIndices.add(i);
      } else {
        // Check prefix match — "induc" should match "induction"
        const prefixMatch = Object.keys(categoryAliases).find(alias => alias.startsWith(word) && word.length >= 3);
        if (prefixMatch) {
          detectedCategorySlugs.push(...categoryAliases[prefixMatch]);
          consumedIndices.add(i);
        } else if (/\d/.test(word)) {
          otherWords.push(word); // Model number, series number, or spec (e.g., "800", "RF29DB")
        } else if (SPEC_STOPWORDS.has(word)) {
          // Phase 5 — spec descriptor. Don't poison the brand pool.
          consumedIndices.add(i);
        } else {
          brandWords.push(word); // Likely brand name (e.g., "bosch", "samsung")
        }
      }
    }

    // Build the search results using multiple strategies

    let results: any[] = [];

    // First, resolve brand words to manufacturer IDs.
    // Phase 5 — match against normalized name (strip ., -, _, spaces) so
    // queries like "AO Smith" match stored "A.O. Smith". Fetches all 456
    // brands once per request (small, cheap) and filters in JS.
    let matchedManufacturerIds: string[] = [];
    if (brandWords.length > 0) {
      const queryBrandToken = brandWords.join("").replace(/[\s\.\-_]/g, "").toLowerCase();
      const { data: allMfgs } = await supabase
        .from("equipment_manufacturers")
        .select("id, name, slug");
      if (allMfgs && allMfgs.length > 0) {
        const matches = allMfgs.filter((m: any) => {
          const normName = String(m.name).replace(/[\s\.\-_&]/g, "").toLowerCase();
          const normSlug = String(m.slug).replace(/[\s\.\-_]/g, "").toLowerCase();
          return normName.includes(queryBrandToken) || normSlug.includes(queryBrandToken);
        });
        matchedManufacturerIds = matches.map((m: any) => m.id);
      }
    }

    const selectFields = `
      id, model_number, model_name, series, fuel_type,
      installation_type, capacity_value, capacity_unit,
      msrp_usd, expected_lifespan_years, key_features,
      is_current_model, width_inches, specs,
      popularity_rank, verification_status,
      equipment_manufacturers!inner (id, name, slug, tier, reliability_score, score_summary),
      equipment_categories!inner (id, name, slug, room)
    `;

    // Resolve category slugs to IDs
    let matchedCategoryIds: string[] = [];
    if (detectedCategorySlugs.length > 0) {
      const { data: cats } = await supabase
        .from("equipment_categories")
        .select("id")
        .in("slug", detectedCategorySlugs);
      if (cats) matchedCategoryIds = cats.map((c: any) => c.id);
    }

    // Collect unmatched words (not brand, not category) — these might be series names,
    // model fragments, or specs like "800", "pro", "profile", etc.
    const unmatchedWords = otherWords.concat(
      brandWords.filter(() => matchedManufacturerIds.length === 0) // only if brand didn't match
    );

    // Strategy 1: Brand + category (e.g., "bosch stove", "bosch 800 induction")
    // Phase 5 — once results return, score each by how many spec signals
    // from the query (capacity / fuel / installation) align with the row.
    // Sort by signal_match DESC, then popularity_rank ASC NULLS LAST, then
    // is_current_model DESC so the best-aligned + most-popular + still-sold
    // model surfaces first.
    if (matchedCategoryIds.length > 0 && matchedManufacturerIds.length > 0) {
      const { data } = await supabase
        .from("equipment_catalog")
        .select(selectFields)
        .in("manufacturer_id", matchedManufacturerIds)
        .in("category_id", matchedCategoryIds)
        // Don't pre-order on SQL side — JS sort below combines signal score
        // + popularity_rank and SQL doesn't have the signal score.
        .limit(200); // Fetch wider pool so signal-ranking can find the best fit

      if (data && data.length > 0) {
        // Apply unmatched-word filter first (e.g. "800" series narrowing)
        let candidates = data;
        if (unmatchedWords.length > 0) {
          const filtered = data.filter((r: any) => {
            const haystack = [r.series, r.model_name, r.model_number]
              .filter(Boolean).join(" ").toLowerCase();
            return unmatchedWords.every(w => haystack.includes(w.toLowerCase()));
          });
          if (filtered.length > 0) candidates = filtered;
        }

        // Phase 5 — rank by spec-signal alignment + popularity + currency
        candidates = candidates
          .map((r: any) => ({ row: r, score: scoreRowAgainstSignals(r, querySignals) }))
          .sort((a, b) => {
            // 1. Higher signal score wins
            if (a.score !== b.score) return b.score - a.score;
            // 2. Lower popularity_rank wins (NULL last)
            const pa = a.row.popularity_rank ?? 9999;
            const pb = b.row.popularity_rank ?? 9999;
            if (pa !== pb) return pa - pb;
            // 3. Current models above discontinued
            const ca = a.row.is_current_model ? 1 : 0;
            const cb = b.row.is_current_model ? 1 : 0;
            return cb - ca;
          })
          .map((x) => ({ ...x.row, _match_score: x.score, _signal_count: querySignals.signalCount }));

        results = candidates.slice(0, limit);
      }
    }

    // Strategy 2: Brand only (e.g., "bosch")
    if (results.length === 0 && matchedManufacturerIds.length > 0 && detectedCategorySlugs.length === 0) {
      const { data } = await supabase
        .from("equipment_catalog")
        .select(selectFields)
        .in("manufacturer_id", matchedManufacturerIds)
        .order("is_current_model", { ascending: false })
        .limit(limit);

      if (data) results = data;
    }

    // Strategy 3: Model number search (exact or prefix match)
    if (results.length === 0) {
      const { data } = await supabase
        .from("equipment_catalog")
        .select(`
          id, model_number, model_name, series, fuel_type,
          installation_type, capacity_value, capacity_unit,
          msrp_usd, expected_lifespan_years, key_features,
          is_current_model, width_inches, specs,
          equipment_manufacturers!inner (id, name, slug, tier),
          equipment_categories!inner (id, name, slug, room)
        `)
        .ilike("model_number", `%${query}%`)
        .order("is_current_model", { ascending: false })
        .limit(limit);

      if (data) results = data;
    }

    // Strategy 3b: Delimiter-normalized model number search
    // Handles user input like "BOVA60HDN1M20G" matching "BOVA-60HDN1-M20G"
    // Uses SQL replace() to strip delimiters server-side for efficient matching
    if (results.length === 0) {
      const normalizedQuery = query.replace(/[-_.\s]/g, "").toLowerCase();
      if (normalizedQuery.length >= 4) {
        const { data } = await supabase.rpc("search_model_normalized", {
          search_query: normalizedQuery,
          result_limit: limit,
        });

        if (data && data.length > 0) {
          // Re-fetch full records with joins for the matched IDs
          const matchedIds = data.map((r: any) => r.id);
          const { data: fullResults } = await supabase
            .from("equipment_catalog")
            .select(selectFields)
            .in("id", matchedIds)
            .limit(limit);

          if (fullResults) results = fullResults;
        }
      }
    }

    // Strategy 4: Full-text search on model_name
    if (results.length === 0) {
      const { data } = await supabase
        .from("equipment_catalog")
        .select(`
          id, model_number, model_name, series, fuel_type,
          installation_type, capacity_value, capacity_unit,
          msrp_usd, expected_lifespan_years, key_features,
          is_current_model, width_inches, specs,
          equipment_manufacturers!inner (id, name, slug, tier),
          equipment_categories!inner (id, name, slug, room)
        `)
        .ilike("model_name", `%${query}%`)
        .order("is_current_model", { ascending: false })
        .limit(limit);

      if (data) results = data;
    }

    // Strategy 5: Category-only search (e.g., just "dishwasher")
    if (results.length === 0 && matchedCategoryIds.length > 0) {
      const { data } = await supabase
        .from("equipment_catalog")
        .select(selectFields)
        .in("category_id", matchedCategoryIds)
        .order("is_current_model", { ascending: false })
        .limit(limit);

      if (data) results = data;
    }

    // Apply category filter if provided
    if (categoryFilter && results.length > 0) {
      results = results.filter((r: any) =>
        r.equipment_categories?.slug?.includes(categoryFilter) ||
        r.equipment_categories?.name?.toLowerCase().includes(categoryFilter.toLowerCase())
      );
    }

    // Format results for the mobile app
    const formatted = results.map((r: any) => {
      const mfg = r.equipment_manufacturers;
      const cat = r.equipment_categories;

      return {
        id: r.id,
        model_number: r.model_number,
        model_name: r.model_name,
        display_name: `${mfg.name} ${r.model_name || r.model_number}`,
        subtitle: [
          r.series ? `${r.series} Series` : null,
          cat.name,
          r.fuel_type ? r.fuel_type.replace(/-/g, " ") : null,
          r.width_inches ? `${r.width_inches}"` : null,
        ].filter(Boolean).join(" · "),
        // Phase 5 — match score + flag for "Best match" pill in iOS
        match_score: r._match_score ?? null,
        is_best_match: (r._match_score ?? 0) >= 3 && (r._signal_count ?? 0) >= 3,
        popularity_rank: r.popularity_rank ?? null,
        verification_status: r.verification_status ?? null,
        manufacturer: {
          id: mfg.id,
          name: mfg.name,
          slug: mfg.slug,
          tier: mfg.tier,
        },
        category: {
          id: cat.id,
          name: cat.name,
          slug: cat.slug,
          room: cat.room,
        },
        specs: {
          series: r.series,
          fuel_type: r.fuel_type,
          installation_type: r.installation_type,
          width_inches: r.width_inches,
          capacity: r.capacity_value && r.capacity_unit
            ? `${r.capacity_value} ${r.capacity_unit}`
            : null,
          msrp: r.msrp_usd,
          expected_lifespan_years: r.expected_lifespan_years,
          is_current_model: r.is_current_model,
          key_features: r.key_features,
          details: r.specs,
        },
        scores: mfg.reliability_score ? {
          reliability: mfg.reliability_score,
          summary: mfg.score_summary,
          source: "brand",
        } : null,
      };
    });

    return new Response(
      JSON.stringify({
        query,
        count: formatted.length,
        // Phase 5 — surface what we extracted so iOS can show "Showing
        // matches for 80 gal · electric · heat pump"
        signals: querySignals.signalCount > 0 ? {
          capacity_value: querySignals.capacityValue,
          capacity_unit: querySignals.capacityUnit,
          fuel_type: querySignals.fuelType,
          installation_type: querySignals.installationType,
          signal_count: querySignals.signalCount,
        } : null,
        results: formatted,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// Phase 5 — extract spec signals from a free-text query so we can rank
// catalog results by alignment. Returns a tiny struct with capacity, fuel,
// and installation hints. Only what we extract counts toward signal_count.
//
// Examples:
//   "AO Smith 80 gallon hybrid heat pump"
//     → { capacityValue: 80, capacityUnit: "gal", fuelType: "electric",
//         installationType: "freestanding", signalCount: 4 }
//   "Bosch 800 series 36 inch french door"
//     → { widthInches: 36, signalCount: 1 }
//   "Trane 3 ton heat pump"
//     → { capacityValue: 3, capacityUnit: "tons", fuelType: "electric",
//         installationType: "ducted", signalCount: 4 }
function extractQuerySignals(q: string): {
  capacityValue: number | null;
  capacityUnit: string | null;
  fuelType: string | null;
  installationType: string | null;
  widthInches: number | null;
  signalCount: number;
} {
  let capacityValue: number | null = null;
  let capacityUnit: string | null = null;
  let fuelType: string | null = null;
  let installationType: string | null = null;
  let widthInches: number | null = null;

  // Capacity — "80 gallon", "44 dBA", "5.0 cu ft", "24000 btu", "3 ton"
  const gallonMatch = q.match(/(\d+)\s*(gallon|gal\b)/);
  if (gallonMatch) { capacityValue = parseInt(gallonMatch[1]); capacityUnit = "gal"; }

  const cuFtMatch = q.match(/(\d+(?:\.\d+)?)\s*(cu\s*\.?\s*ft|cubic\s*feet?)/);
  if (cuFtMatch) { capacityValue = parseFloat(cuFtMatch[1]); capacityUnit = "cu_ft"; }

  const btuMatch = q.match(/(\d{4,6})\s*btu/);
  if (btuMatch) { capacityValue = parseInt(btuMatch[1]); capacityUnit = "btu"; }

  const tonMatch = q.match(/(\d+(?:\.\d+)?)\s*ton/);
  if (tonMatch) { capacityValue = parseFloat(tonMatch[1]); capacityUnit = "tons"; }

  const dbaMatch = q.match(/(\d{2,3})\s*dba/);
  if (dbaMatch) { capacityValue = parseInt(dbaMatch[1]); capacityUnit = "dba"; }

  // Width — "36 inch", "30\""
  const widthMatch = q.match(/(\d{2,3})\s*(?:inch|inches|"|in\b)/);
  if (widthMatch) widthInches = parseInt(widthMatch[1]);

  // Fuel — explicit type wins, then implied
  if (/\b(natural\s*gas|\bng\b|propane|\blp\b|gas)\b/.test(q)) fuelType = "gas";
  else if (/\belectric|hybrid|heat\s*pump|induction\b/.test(q)) fuelType = "electric";
  else if (/\boil\b|fuel\s*oil/.test(q)) fuelType = "oil";
  else if (/\bdual[-\s]?fuel\b/.test(q)) fuelType = "dual-fuel";

  // Installation type — heat pump implies ducted, mini-split called out, built-in vs freestanding
  if (/mini[-\s]?split|ductless/.test(q)) installationType = "mini-split";
  else if (/heat\s*pump\b/.test(q) && installationType === null) installationType = "freestanding";
  else if (/built[-\s]?in\b/.test(q)) installationType = "built-in";
  else if (/free[-\s]?standing|countertop|portable/.test(q)) installationType = "freestanding";
  else if (/under[-\s]?counter\b/.test(q)) installationType = "under-counter";
  else if (/wall[-\s]?mount/.test(q)) installationType = "wall-mount";

  let signalCount = 0;
  if (capacityValue !== null) signalCount++;
  if (fuelType !== null) signalCount++;
  if (installationType !== null) signalCount++;
  if (widthInches !== null) signalCount++;

  return { capacityValue, capacityUnit, fuelType, installationType, widthInches, signalCount };
}

// Phase 5 — score a catalog row against extracted query signals. Each
// matching signal contributes +1 to the score. Capacity match is fuzzy
// (within 5% for numeric capacities), fuel/installation are exact-match.
function scoreRowAgainstSignals(
  row: any,
  s: ReturnType<typeof extractQuerySignals>
): number {
  let score = 0;

  // Capacity alignment — within 5% counts as a match (handles 80 gal vs
  // 80 gallons stored as 80.0)
  if (s.capacityValue !== null && row.capacity_value !== null && row.capacity_value !== undefined) {
    const sUnit = (s.capacityUnit ?? "").toLowerCase();
    const rUnit = (row.capacity_unit ?? "").toLowerCase();
    if (!sUnit || !rUnit || sUnit === rUnit) {
      const diff = Math.abs(Number(row.capacity_value) - s.capacityValue);
      const tolerance = Math.max(s.capacityValue * 0.05, 0.5);
      if (diff <= tolerance) score++;
    }
  }

  // Width — within 1 inch
  if (s.widthInches !== null && row.width_inches !== null && row.width_inches !== undefined) {
    if (Math.abs(Number(row.width_inches) - s.widthInches) <= 1) score++;
  }

  // Fuel — exact match (and "electric" matches "induction" since induction is electric)
  if (s.fuelType && row.fuel_type) {
    const a = String(row.fuel_type).toLowerCase();
    const b = s.fuelType.toLowerCase();
    if (a === b) score++;
    else if (b === "electric" && a === "induction") score++;
    else if (b === "gas" && a.includes("gas")) score++;
  }

  // Installation type — exact match
  if (s.installationType && row.installation_type) {
    if (String(row.installation_type).toLowerCase() === s.installationType.toLowerCase()) {
      score++;
    }
  }

  return score;
}
