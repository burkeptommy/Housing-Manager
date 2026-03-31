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
      "heat pump": ["hvac-heat-pump", "dryer-heat-pump"],
      toilet: ["toilet"],
      faucet: ["bathroom-faucet"],
      shower: ["shower-system"],
      tub: ["bathtub"],
      "water heater": ["water-heater", "water-heater-tank-gas", "water-heater-tank-electric", "water-heater-tankless-gas"],
      tankless: ["water-heater-tankless-gas", "water-heater-tankless-electric"],
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

    // Detect if any word is a category alias
    let detectedCategorySlugs: string[] = [];
    let brandWords: string[] = [];
    let otherWords: string[] = [];

    for (const word of words) {
      // Check single words and two-word combos
      const twoWord = words.slice(words.indexOf(word), words.indexOf(word) + 2).join(" ");

      if (categoryAliases[twoWord]) {
        detectedCategorySlugs.push(...categoryAliases[twoWord]);
      } else if (categoryAliases[word]) {
        detectedCategorySlugs.push(...categoryAliases[word]);
      } else {
        // Check prefix match — "induc" should match "induction"
        const prefixMatch = Object.keys(categoryAliases).find(alias => alias.startsWith(word) && word.length >= 3);
        if (prefixMatch) {
          detectedCategorySlugs.push(...categoryAliases[prefixMatch]);
        } else if (/\d/.test(word)) {
          otherWords.push(word); // Model number, series number, or spec (e.g., "800", "RF29DB")
        } else {
          brandWords.push(word); // Likely brand name (e.g., "bosch", "samsung")
        }
      }
    }

    // Build the search results using multiple strategies

    let results: any[] = [];

    // First, resolve brand words to manufacturer IDs
    let matchedManufacturerIds: string[] = [];
    if (brandWords.length > 0) {
      const brandPattern = `%${brandWords.join("%")}%`;
      const { data: mfgs } = await supabase
        .from("equipment_manufacturers")
        .select("id")
        .ilike("name", brandPattern);
      if (mfgs && mfgs.length > 0) {
        matchedManufacturerIds = mfgs.map((m: any) => m.id);
      }
    }

    const selectFields = `
      id, model_number, model_name, series, fuel_type,
      installation_type, capacity_value, capacity_unit,
      msrp_usd, expected_lifespan_years, key_features,
      is_current_model, width_inches, specs,
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
    if (matchedCategoryIds.length > 0 && matchedManufacturerIds.length > 0) {
      const { data } = await supabase
        .from("equipment_catalog")
        .select(selectFields)
        .in("manufacturer_id", matchedManufacturerIds)
        .in("category_id", matchedCategoryIds)
        .order("is_current_model", { ascending: false })
        .limit(100); // Fetch more, then filter client-side for leftover words

      if (data && data.length > 0) {
        // If there are leftover words (e.g., "800"), narrow results by matching
        // them anywhere in series, model_name, or model_number
        if (unmatchedWords.length > 0) {
          const filtered = data.filter((r: any) => {
            const haystack = [r.series, r.model_name, r.model_number]
              .filter(Boolean).join(" ").toLowerCase();
            return unmatchedWords.every(w => haystack.includes(w.toLowerCase()));
          });
          results = filtered.length > 0 ? filtered.slice(0, limit) : data.slice(0, limit);
        } else {
          results = data.slice(0, limit);
        }
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
