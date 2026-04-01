// Haven Edge Function: enrich-catalog
// Uses Claude to fill in missing series names, features, and specs
// for catalog entries that are missing details.
//
// Usage:
//   POST /functions/v1/enrich-catalog
//   Body: { "manufacturer_slug": "bosch", "limit": 20 }
//   Body: { "batch": true, "limit": 50 }

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
    const limit: number = Math.min(body.limit ?? 20, 50);

    // Find entries missing series OR key_features
    let query = supabase
      .from("equipment_catalog")
      .select("id, model_number, model_name, series, key_features, equipment_manufacturers!inner(name, slug), equipment_categories!inner(name)")
      .or("series.is.null,key_features.eq.{}");

    if (slug) {
      query = query.eq("equipment_manufacturers.slug", slug);
    }

    const { data: entries } = await query.limit(limit);
    if (!entries || entries.length === 0) {
      return new Response(JSON.stringify({ enriched: 0, message: "No entries need enrichment" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // Batch entries by manufacturer for efficient Claude calls (up to 10 per call)
    const batches: any[][] = [];
    for (let i = 0; i < entries.length; i += 10) {
      batches.push(entries.slice(i, i + 10));
    }

    let enriched = 0;
    for (const batch of batches) {
      const modelsText = batch.map((e: any) =>
        `- ${e.model_number} (${(e as any).equipment_manufacturers.name}, ${(e as any).equipment_categories.name})${e.model_name ? ` — currently: "${e.model_name}"` : ""}`
      ).join("\n");

      const prompt = `You are an appliance expert. For each model below, provide the series name, a descriptive model name, and 3-5 key features. Use your knowledge of these real products.

Models to enrich:
${modelsText}

For each model, return:
- series: The product line/series name (e.g., "800 Series", "Profile", "Benchmark", "Bespoke", "Signature", etc.). null if unknown.
- model_name: A descriptive name like "800 Series 36\" French Door Refrigerator - Panel Ready" or "XR16 3-Ton Central Air Conditioner"
- key_features: Array of 3-5 notable features (e.g., ["Panel-ready", "VitaFresh Pro", "Home Connect Wi-Fi"])
- installation_type: freestanding/built-in/slide-in/wall-mount/under-counter if not already set
- expected_lifespan_years: typical lifespan in years

Return ONLY valid JSON array (no markdown):
[
  {
    "model_number": "...",
    "series": "...",
    "model_name": "...",
    "key_features": ["...", "..."],
    "installation_type": "...",
    "expected_lifespan_years": 12
  }
]`;

      try {
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

        if (!resp.ok) continue;
        const data = await resp.json();
        const text = data.content?.[0]?.text ?? "";
        const jsonMatch = text.match(/\[[\s\S]*\]/);
        if (!jsonMatch) continue;

        const enrichments = JSON.parse(jsonMatch[0]);

        for (const enrich of enrichments) {
          const entry = batch.find((e: any) => e.model_number === enrich.model_number);
          if (!entry) continue;

          const updates: Record<string, any> = {};
          if (enrich.series && !entry.series) updates.series = enrich.series;
          if (enrich.model_name) updates.model_name = enrich.model_name;
          if (enrich.key_features?.length > 0 && (!entry.key_features || entry.key_features.length === 0)) {
            updates.key_features = enrich.key_features;
          }
          if (enrich.installation_type) updates.installation_type = enrich.installation_type;
          if (enrich.expected_lifespan_years) updates.expected_lifespan_years = enrich.expected_lifespan_years;

          if (Object.keys(updates).length > 0) {
            await supabase.from("equipment_catalog").update(updates).eq("id", entry.id);
            enriched++;
          }
        }
      } catch { continue; }
    }

    return new Response(JSON.stringify({ enriched, total_checked: entries.length }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (err) {
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
