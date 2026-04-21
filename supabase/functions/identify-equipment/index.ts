// Haven Edge Function: identify-equipment
// Accepts a photo (base64) of an appliance model/serial plate, uses Claude Vision
// to extract manufacturer, model number, and serial number, then matches against
// the equipment catalog.
//
// Usage:
//   POST /functions/v1/identify-equipment
//   Body: { "image_base64": "...", "category": "hvac" }

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
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!anthropicApiKey) {
      throw new Error("ANTHROPIC_API_KEY is not configured");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const body = await req.json();
    const imageBase64: string = body.image_base64;
    const category: string | null = body.category ?? null;

    if (!imageBase64) {
      return new Response(
        JSON.stringify({ error: "image_base64 is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 1: Send to Claude Vision to extract equipment info from the photo
    const visionResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: "image/jpeg",
                  data: imageBase64,
                },
              },
              {
                type: "text",
                text: `You are analyzing a photo of a home appliance, HVAC system, or home equipment label/plate. Extract the following information:

1. **Manufacturer/Brand** — the company that made this equipment
2. **Model Number** — the exact model number (alphanumeric code)
3. **Serial Number** — the serial number if visible
4. **Product Type** — what kind of equipment this is (e.g., "refrigerator", "furnace", "dishwasher", "water heater")
5. **Any other visible specs** — voltage, BTU, capacity, etc.

If the image is not of an equipment label or is too blurry to read, say so.

Respond with ONLY valid JSON in this exact format:
{
  "identified": true/false,
  "manufacturer": "Brand Name" or null,
  "model_number": "EXACT-MODEL-123" or null,
  "serial_number": "SN12345" or null,
  "product_type": "refrigerator" or null,
  "additional_specs": "any visible specs" or null,
  "confidence": "high" / "medium" / "low",
  "raw_text": "all readable text from the label"
}`,
              },
            ],
          },
        ],
      }),
    });

    if (!visionResponse.ok) {
      const errText = await visionResponse.text();
      throw new Error(`Claude Vision API error: ${visionResponse.status} - ${errText}`);
    }

    const visionData = await visionResponse.json();
    const visionText = visionData.content?.[0]?.text ?? "";

    // Parse the JSON response from Claude
    let extracted: {
      identified: boolean;
      manufacturer: string | null;
      model_number: string | null;
      serial_number: string | null;
      product_type: string | null;
      confidence: string;
      raw_text: string;
    };

    try {
      // Extract JSON from the response (Claude might wrap it in markdown)
      const jsonMatch = visionText.match(/\{[\s\S]*\}/);
      extracted = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(visionText);
    } catch {
      return new Response(
        JSON.stringify({
          identified: false,
          error: "Could not parse equipment information from photo",
          raw_text: visionText,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!extracted.identified || !extracted.model_number) {
      return new Response(
        JSON.stringify({
          identified: false,
          manufacturer: extracted.manufacturer,
          model_number: extracted.model_number,
          serial_number: extracted.serial_number,
          confidence: extracted.confidence,
          raw_text: extracted.raw_text,
          catalog_match: null,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 2: Search the catalog for a match
    let catalogMatch = null;

    const catalogSelect = `
      id, model_number, model_name, series, fuel_type,
      installation_type, capacity_value, capacity_unit,
      msrp_usd, expected_lifespan_years, key_features,
      is_current_model, width_inches, specs,
      equipment_manufacturers!inner (id, name, slug, tier),
      equipment_categories!inner (id, name, slug, room)
    `;

    // Clean model number: strip suffix like "/28", "/01" (Bosch variant codes)
    const rawModel = extracted.model_number ?? "";
    const cleanModel = rawModel.replace(/\/\d+$/, "").trim();

    // Strategy 1: Exact substring match on full model number
    // Prefer matching within the detected manufacturer first
    let exactMatch: any = null;
    const detectedMfg = extracted.manufacturer ?? "";

    if (detectedMfg) {
      // Try to find manufacturer ID first
      const mfgTerms = [detectedMfg];
      if (detectedMfg.toUpperCase() === "BSH") mfgTerms.push("Bosch");
      if (detectedMfg.toLowerCase().includes("bsh")) mfgTerms.push("Bosch");

      for (const term of mfgTerms) {
        const { data: mfgs } = await supabase
          .from("equipment_manufacturers")
          .select("id")
          .ilike("name", `%${term}%`);
        if (mfgs && mfgs.length > 0) {
          const { data: match } = await supabase
            .from("equipment_catalog")
            .select(catalogSelect)
            .ilike("model_number", `%${cleanModel}%`)
            .in("manufacturer_id", mfgs.map((m: any) => m.id))
            .limit(1)
            .single();
          if (match) { exactMatch = match; break; }
        }
      }
    }

    // Fallback: search all brands (only if no manufacturer detected)
    if (!exactMatch && !detectedMfg) {
      const { data: match } = await supabase
        .from("equipment_catalog")
        .select(catalogSelect)
        .ilike("model_number", `%${cleanModel}%`)
        .limit(1)
        .single();
      exactMatch = match;
    }

    // Strategy 2: Fuzzy match — MUST respect manufacturer to avoid cross-brand matches
    // Try multiple core positions since OCR errors can shift characters
    if (!exactMatch && cleanModel.length >= 6) {
      // Try cores from different positions to handle OCR misreads
      const corePositions = [
        cleanModel.substring(3, 7),  // Standard: skip type prefix
        cleanModel.substring(2, 6),  // Shifted left
        cleanModel.substring(1, 5),  // More shifted
      ].filter(c => c.length >= 3);

      const modelCore = corePositions[0]; // Use first for the search
      if (modelCore.length >= 3) {
        const mfgName = extracted.manufacturer ?? "";

        // Resolve manufacturer — try multiple name variations
        // "BSH" → "Bosch", handle parent company names
        const mfgSearchTerms = [mfgName];
        if (mfgName.toUpperCase() === "BSH") mfgSearchTerms.push("Bosch"); // BSH = Bosch parent
        if (mfgName.toLowerCase().includes("bsh")) mfgSearchTerms.push("Bosch");

        let matchedMfgIds: string[] = [];
        for (const term of mfgSearchTerms) {
          if (!term) continue;
          const { data: mfgs } = await supabase
            .from("equipment_manufacturers")
            .select("id")
            .ilike("name", `%${term}%`);
          if (mfgs && mfgs.length > 0) {
            matchedMfgIds = mfgs.map((m: any) => m.id);
            break;
          }
        }

        // ONLY fuzzy match within the SAME manufacturer — never cross-brand
        // Try each core position until we find a match
        if (matchedMfgIds.length > 0) {
          for (const core of corePositions) {
            const { data: fuzzyResults } = await supabase
              .from("equipment_catalog")
              .select(catalogSelect)
              .ilike("model_number", `%${core}%`)
              .in("manufacturer_id", matchedMfgIds)
              .limit(5);

            if (fuzzyResults && fuzzyResults.length > 0) {
              const prefix = cleanModel.substring(0, 3).toLowerCase();
              exactMatch = fuzzyResults.find((r: any) =>
                r.model_number.toLowerCase().startsWith(prefix)
              ) || fuzzyResults[0];
              break;
            }
          }
        }
        // If no manufacturer match found, don't fuzzy match at all —
        // let auto-catalog create the correct entry below
      }
    }

    if (exactMatch) {
      const mfg = (exactMatch as any).equipment_manufacturers;
      const cat = (exactMatch as any).equipment_categories;
      catalogMatch = {
        id: exactMatch.id,
        model_number: exactMatch.model_number,
        model_name: exactMatch.model_name,
        display_name: `${mfg.name} ${exactMatch.model_name || exactMatch.model_number}`,
        subtitle: [
          exactMatch.series ? `${exactMatch.series} Series` : null,
          cat.name,
          exactMatch.fuel_type,
          exactMatch.width_inches ? `${exactMatch.width_inches}"` : null,
        ].filter(Boolean).join(" · "),
        manufacturer: { id: mfg.id, name: mfg.name, slug: mfg.slug, tier: mfg.tier },
        category: { id: cat.id, name: cat.name, slug: cat.slug, room: cat.room },
        specs: {
          series: exactMatch.series,
          fuel_type: exactMatch.fuel_type,
          installation_type: exactMatch.installation_type,
          width_inches: exactMatch.width_inches,
          capacity: exactMatch.capacity_value && exactMatch.capacity_unit
            ? `${exactMatch.capacity_value} ${exactMatch.capacity_unit}` : null,
          msrp: exactMatch.msrp_usd,
          expected_lifespan_years: exactMatch.expected_lifespan_years,
          is_current_model: exactMatch.is_current_model,
          key_features: exactMatch.key_features,
          details: exactMatch.specs,
        },
      };
    }

    // Auto-catalog: if no match found and we have brand + model with HIGH confidence,
    // create a catalog entry so this model is never "missing" again.
    // Only auto-create when confidence is high AND model number looks valid (has both letters and digits, 5+ chars)
    const modelForAutoCreate = cleanModel || rawModel;
    const isValidModel = modelForAutoCreate.length >= 5
      && /[A-Z]/i.test(modelForAutoCreate)
      && /\d/.test(modelForAutoCreate)
      && extracted.confidence === "high";

    if (!catalogMatch && extracted.manufacturer && extracted.model_number && isValidModel) {
      try {
        // Find or create manufacturer
        let { data: mfgRow } = await supabase
          .from("equipment_manufacturers")
          .select("id, name, slug")
          .ilike("name", `%${extracted.manufacturer}%`)
          .limit(1)
          .single();

        if (mfgRow) {
          // Determine category from product_type or default to "Appliance"
          const productType = (extracted.product_type || "appliance").toLowerCase();
          let categorySlug = "appliance"; // default
          if (productType.includes("dishwasher")) categorySlug = "dishwasher";
          else if (productType.includes("refrigerator") || productType.includes("fridge")) categorySlug = "refrigerator";
          else if (productType.includes("washer")) categorySlug = "washer";
          else if (productType.includes("dryer")) categorySlug = "dryer";
          else if (productType.includes("range") || productType.includes("oven") || productType.includes("stove")) categorySlug = "range";
          else if (productType.includes("microwave")) categorySlug = "microwave";
          else if (productType.includes("cooktop")) categorySlug = "cooktop-gas";
          else if (productType.includes("furnace") || productType.includes("hvac")) categorySlug = "hvac-furnace";
          else if (productType.includes("air conditioner") || productType.includes("ac")) categorySlug = "hvac-central-ac";
          else if (productType.includes("water heater")) categorySlug = "water-heater";
          else if (productType.includes("generator")) categorySlug = "generator";

          const { data: catRow } = await supabase
            .from("equipment_categories")
            .select("id, name, slug, room")
            .ilike("slug", `%${categorySlug}%`)
            .limit(1)
            .single();

          if (catRow) {
            const modelNum = cleanModel || rawModel;
            // Insert catalog entry
            const { data: newEntry } = await supabase
              .from("equipment_catalog")
              .insert({
                manufacturer_id: mfgRow.id,
                category_id: catRow.id,
                model_number: modelNum,
                model_name: `${extracted.manufacturer} ${modelNum}`,
                is_current_model: true,
                key_features: [],
                specs: {},
              })
              .select("id")
              .single();

            if (newEntry) {
              // Create the catalog match response from the new entry
              catalogMatch = {
                id: newEntry.id,
                model_number: modelNum,
                model_name: `${extracted.manufacturer} ${modelNum}`,
                display_name: `${mfgRow.name} ${modelNum}`,
                subtitle: catRow.name,
                manufacturer: { id: mfgRow.id, name: mfgRow.name, slug: mfgRow.slug, tier: "" },
                category: { id: catRow.id, name: catRow.name, slug: catRow.slug, room: catRow.room },
                specs: {},
              };

              // Add manual links using manufacturer support URL
              const supportUrls: Record<string, string> = {
                "bosch": "https://www.bosch-home.com/us/en/productservice/{MODEL}-01",
                "samsung": "https://www.samsung.com/us/support/model/{MODEL}/",
                "lg": "https://www.lg.com/us/support/products/{MODEL}.html",
                "whirlpool": "https://www.whirlpool.com/support/product-help.html?model={MODEL}",
                "kitchenaid": "https://www.kitchenaid.com/support/product-help.html?model={MODEL}",
                "miele": "https://www.mieleusa.com/e/support-7594.htm?q={MODEL}",
              };
              const pattern = supportUrls[mfgRow.slug];
              if (pattern) {
                const url = pattern.replace("{MODEL}", modelNum);
                for (const mt of ["owners_manual", "spec_sheet"]) {
                  await supabase.from("equipment_manuals").insert({
                    catalog_entry_id: newEntry.id,
                    manual_type: mt,
                    title: mt.replace(/_/g, " ").replace(/\b\w/g, (l: string) => l.toUpperCase()),
                    source_url: url,
                    language: "en",
                  }).catch(() => {});
                }
              }
            }
          }
        }
      } catch (autoErr) {
        // Auto-catalog is best-effort — don't fail the response
        console.error("[identify-equipment] Auto-catalog error:", autoErr);
      }
    }

    return new Response(
      JSON.stringify({
        identified: true,
        manufacturer: extracted.manufacturer,
        model_number: extracted.model_number,
        serial_number: extracted.serial_number,
        // Build 94: Forward the extracted product_type so no-catalog-match
        // cases still hand iOS a subtype hint ("Refrigerator" / "Wall
        // Oven"). When a catalog match exists, iOS still prefers
        // `catalog_match.category.name` because it's been through the
        // normalized equipment_categories table — this is the fallback
        // for photo-identified items that don't hit the catalog.
        product_type: extracted.product_type ?? null,
        confidence: extracted.confidence,
        raw_text: extracted.raw_text,
        catalog_match: catalogMatch,
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
