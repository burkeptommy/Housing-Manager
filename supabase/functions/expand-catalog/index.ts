// Haven Edge Function: expand-catalog
// Uses Claude to generate missing equipment catalog entries for a brand.
// Identifies which product categories a brand should have (based on what they make)
// but doesn't have in our catalog, then generates accurate model entries.
//
// Usage:
//   POST /functions/v1/expand-catalog
//   Body: { "manufacturer_slug": "bosch" }             // Expand one brand
//   Body: { "batch": true, "limit": 5 }                // Expand top 5 brands with gaps

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json().catch(() => ({}));
    const slug: string | null = body.manufacturer_slug ?? null;
    const batch: boolean = body.batch ?? false;
    const batchLimit: number = Math.min(body.limit ?? 5, 20);

    const results: any[] = [];

    if (slug) {
      const r = await expandBrand(supabase, anthropicKey, slug);
      results.push(r);
    } else if (batch) {
      // Find brands that are likely missing major product lines
      const { data: allMfgs } = await supabase
        .from("equipment_manufacturers")
        .select("slug, name")
        .order("name")
        .limit(300);

      // Check each for low catalog count
      for (const mfg of (allMfgs || []).slice(0, batchLimit)) {
        const r = await expandBrand(supabase, anthropicKey, mfg.slug);
        results.push(r);
      }
    }

    return new Response(JSON.stringify({ results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

async function expandBrand(supabase: any, anthropicKey: string, slug: string) {
  // Get manufacturer
  const { data: mfg } = await supabase
    .from("equipment_manufacturers")
    .select("id, name, slug, tier, parent_company, website_url")
    .eq("slug", slug)
    .single();
  if (!mfg) return { brand: slug, status: "not_found" };

  // Get existing catalog entries
  const { data: existing } = await supabase
    .from("equipment_catalog")
    .select("model_number, model_name, equipment_categories!inner(name, slug)")
    .eq("manufacturer_id", mfg.id);

  const existingCategories = [...new Set((existing || []).map((e: any) => e.equipment_categories.slug))];
  const existingModels = new Set((existing || []).map((e: any) => e.model_number));

  // Get all available categories
  const { data: allCategories } = await supabase
    .from("equipment_categories")
    .select("id, name, slug, room, typical_lifespan_years");

  // Ask Claude what products this brand makes and which are missing
  const prompt = `You are an appliance and home equipment expert. The brand "${mfg.name}" (${mfg.tier || "unknown"} tier${mfg.parent_company ? `, part of ${mfg.parent_company}` : ""}) currently has these products in our catalog:

${existingCategories.length > 0 ? existingCategories.map((c: string) => `- ${c}`).join("\n") : "- No products yet"}

Existing model numbers: ${[...existingModels].slice(0, 20).join(", ")}${existingModels.size > 20 ? "..." : ""}

What major product categories is ${mfg.name} known for that we're MISSING? Generate the top 10-15 most popular current models for each missing category. For example, if we have Bosch dishwashers but not Bosch refrigerators, generate their 800 Series, 500 Series, and Benchmark refrigerators.

For each model, provide:
- model_number (exact, real model number like "B36CL81ENS")
- model_name (descriptive, like "800 Series 36\" French Door Refrigerator")
- series (like "800 Series", "500 Series", "Benchmark")
- category_slug (from this list: ${(allCategories || []).map((c: any) => c.slug).join(", ")})
- fuel_type (gas/electric/dual-fuel/induction or null)
- installation_type (freestanding/built-in/slide-in/wall-mount/under-counter)
- width_inches (number or null)
- capacity (like "20.5 cu ft" or "44 dBA" or null)
- msrp_usd (estimated current retail price, number or null)
- expected_lifespan_years (number)
- is_current_model (true if currently sold, false if discontinued)
- key_features (array of 3-5 features)

IMPORTANT: Only include REAL model numbers that ${mfg.name} actually makes or made. Do not invent fake model numbers.

Return ONLY valid JSON array (no markdown):
[
  {
    "model_number": "...",
    "model_name": "...",
    "series": "...",
    "category_slug": "...",
    "fuel_type": null,
    "installation_type": "...",
    "width_inches": null,
    "capacity": null,
    "msrp_usd": null,
    "expected_lifespan_years": 12,
    "is_current_model": true,
    "key_features": ["...", "...", "..."]
  }
]`;

  const resp = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": anthropicKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-20250514",
      max_tokens: 4096,
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!resp.ok) throw new Error(`Claude API: ${resp.status}`);
  const data = await resp.json();
  const text = data.content?.[0]?.text ?? "";
  const jsonMatch = text.match(/\[[\s\S]*\]/);
  if (!jsonMatch) return { brand: mfg.name, status: "no_models_generated" };

  const models = JSON.parse(jsonMatch[0]);

  // Build category slug → id map
  const catMap: Record<string, string> = {};
  for (const c of allCategories || []) catMap[c.slug] = c.id;

  // Insert new models (skip duplicates)
  let inserted = 0;
  let skipped = 0;
  for (const model of models) {
    if (existingModels.has(model.model_number)) { skipped++; continue; }
    const categoryId = catMap[model.category_slug];
    if (!categoryId) { skipped++; continue; }

    // Parse capacity
    let capacityValue: number | null = null;
    let capacityUnit: string | null = null;
    if (model.capacity) {
      const capMatch = model.capacity.match(/([\d.]+)\s*(cu\s*ft|dba|btu|gallons?|watts?)/i);
      if (capMatch) {
        capacityValue = parseFloat(capMatch[1]);
        capacityUnit = capMatch[2].toLowerCase().replace(/\s+/g, "_").replace("gallons", "gal");
      }
    }

    const { error } = await supabase.from("equipment_catalog").insert({
      manufacturer_id: mfg.id,
      category_id: categoryId,
      model_number: model.model_number,
      model_name: model.model_name,
      series: model.series || null,
      fuel_type: model.fuel_type || null,
      installation_type: model.installation_type || null,
      width_inches: model.width_inches || null,
      capacity_value: capacityValue,
      capacity_unit: capacityUnit,
      msrp_usd: model.msrp_usd || null,
      expected_lifespan_years: model.expected_lifespan_years || null,
      is_current_model: model.is_current_model ?? true,
      key_features: model.key_features || [],
      specs: {},
    });

    if (!error) {
      inserted++;
      existingModels.add(model.model_number);
    } else {
      skipped++;
    }
  }

  // Also generate manual entries for new models using manufacturer support URL
  const supportUrlPatterns: Record<string, string> = {
    "bosch": "https://www.bosch-home.com/us/en/productservice/{MODEL}-01",
    "samsung": "https://www.samsung.com/us/support/model/{MODEL}/",
    "lg": "https://www.lg.com/us/support/products/{MODEL}.html",
    "whirlpool": "https://www.whirlpool.com/support/product-help.html?model={MODEL}",
    "kitchenaid": "https://www.kitchenaid.com/support/product-help.html?model={MODEL}",
    "ge-appliances": "https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}",
    "ge-profile": "https://www.geappliances.com/ge/service-and-support/manuals-and-downloads.htm?smartNumber={MODEL}",
    "frigidaire": "https://www.frigidaire.com/support/product-support/?modelNumber={MODEL}",
    "miele": "https://www.mieleusa.com/e/support-7594.htm?q={MODEL}",
    "thermador": "https://www.thermador.com/us/support/product-support/{MODEL}",
  };

  const pattern = supportUrlPatterns[slug];
  if (pattern) {
    for (const model of models) {
      if (!model.model_number) continue;
      const catId = catMap[model.category_slug];
      if (!catId) continue;

      // Find the catalog entry we just inserted
      const { data: entry } = await supabase
        .from("equipment_catalog")
        .select("id")
        .eq("model_number", model.model_number)
        .eq("manufacturer_id", mfg.id)
        .limit(1)
        .single();

      if (entry) {
        const url = pattern.replace("{MODEL}", model.model_number);
        for (const manualType of ["owners_manual", "installation_guide", "spec_sheet"]) {
          await supabase.from("equipment_manuals").insert({
            catalog_entry_id: entry.id,
            manual_type: manualType,
            title: `${manualType.replace(/_/g, " ").replace(/\b\w/g, l => l.toUpperCase())}`,
            source_url: url,
            language: "en",
          }).catch(() => {});
        }
      }
    }
  }

  return {
    brand: mfg.name,
    status: "expanded",
    existing_categories: existingCategories,
    models_generated: models.length,
    inserted,
    skipped,
  };
}
