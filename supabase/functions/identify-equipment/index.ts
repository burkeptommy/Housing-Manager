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

    // Try exact model number match
    const { data: exactMatch } = await supabase
      .from("equipment_catalog")
      .select(`
        id, model_number, model_name, series, fuel_type,
        installation_type, capacity_value, capacity_unit,
        msrp_usd, expected_lifespan_years, key_features,
        is_current_model, width_inches, specs,
        equipment_manufacturers!inner (id, name, slug, tier),
        equipment_categories!inner (id, name, slug, room)
      `)
      .ilike("model_number", `%${extracted.model_number}%`)
      .limit(1)
      .single();

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

    return new Response(
      JSON.stringify({
        identified: true,
        manufacturer: extracted.manufacturer,
        model_number: extracted.model_number,
        serial_number: extracted.serial_number,
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
