// Haven Edge Function: research-item-alternative
// Lightweight single-item replacement: user says "find me something more modern"
// and we return 2-3 alternatives with real prices.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

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

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "ANTHROPIC_API_KEY not set" }),
        { status: 500, headers }
      );
    }

    const body = await req.json();
    const {
      item_name,
      item_category,
      project_context,
      style_preferences,
      user_request,
      property_location,
    } = body;

    if (!item_name || !user_request) {
      return new Response(
        JSON.stringify({ error: "item_name and user_request are required" }),
        { status: 400, headers }
      );
    }

    const locationContext = property_location
      ? `Prices should reflect ${property_location} area retail.`
      : "Use national average US pricing.";

    const styleContext = style_preferences
      ? `The user's style preference is: ${style_preferences}. Match alternatives to this aesthetic.`
      : "";

    console.log(`[item-alternative] Finding alternatives for "${item_name}" — request: "${user_request}"`);

    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 2048,
        system: `You are a product sourcing assistant for home improvement projects. Return ONLY valid JSON — no markdown, no code fences. Start with { and end with }.`,
        messages: [
          {
            role: "user",
            content: `The user has this item in their project: "${item_name}" (category: ${item_category || "materials"}).
${project_context ? `Project context: ${project_context}` : ""}
${styleContext}
${locationContext}

They want alternatives: "${user_request}"

Return 3 alternative products with real 2025-2026 retail pricing. Use specific brand names, model numbers, and real prices from retailers like Crate & Barrel, Pottery Barn, West Elm, Restoration Hardware, Arhaus, Wayfair, CB2, Article, Rejuvenation, Lumens, or specialty retailers. For tools/construction items, use Home Depot or Lowe's.

Return this JSON:
{
  "alternatives": [
    {
      "name": "Specific product name with brand and model",
      "price": 29.99,
      "unit": "each|sq ft|linear ft|etc",
      "store": "Store name",
      "reason": "Why this matches their request (1 sentence)",
      "category": "${item_category || "materials"}"
    }
  ],
  "note": "Brief note about the alternatives (e.g., 'These options prioritize the matte black finish you requested while staying in a similar price range')"
}`,
          },
        ],
      }),
    });

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      console.error(`[item-alternative] Claude error: ${claudeResponse.status} ${errText.substring(0, 200)}`);
      return new Response(
        JSON.stringify({ error: "AI lookup failed" }),
        { status: 502, headers }
      );
    }

    const claudeData = await claudeResponse.json();
    const aiText = claudeData?.content?.[0]?.text ?? '{"error": "No response"}';

    let result: Record<string, unknown>;
    try {
      let cleaned = aiText.trim();
      if (cleaned.startsWith("```json")) cleaned = cleaned.slice(7);
      else if (cleaned.startsWith("```")) cleaned = cleaned.slice(3);
      if (cleaned.endsWith("```")) cleaned = cleaned.slice(0, -3);
      result = JSON.parse(cleaned.trim());
    } catch {
      const jsonMatch = aiText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          result = JSON.parse(jsonMatch[0]);
        } catch {
          result = { error: "Could not parse alternatives", raw: aiText.substring(0, 300) };
        }
      } else {
        result = { error: "Could not parse alternatives" };
      }
    }

    // --- ENRICH ALTERNATIVES WITH PRODUCT IMAGES via Serper (best-effort, parallel) ---
    const serperKey = Deno.env.get("SERPER_API_KEY");
    const alts = (result.alternatives as Array<Record<string, unknown>>) ?? [];

    if (serperKey && alts.length > 0) {
      await Promise.allSettled(
        alts.map(async (alt) => {
          try {
            const res = await fetch("https://google.serper.dev/images", {
              method: "POST",
              headers: {
                "X-API-KEY": serperKey,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({ q: `${alt.name} ${alt.store || ""}`, num: 1 }),
            });
            if (!res.ok) return;
            const data = await res.json();
            const first = (data as any)?.images?.[0];
            if (first) {
              alt.imageUrl = first.imageUrl;
              alt.productUrl = first.link ?? null;
            }
          } catch { /* non-blocking */ }
        })
      );
      console.log(`[item-alternative] Enriched ${alts.filter(a => a.imageUrl).length}/${alts.length} with images`);
    }

    console.log(`[item-alternative] Found ${alts.length} alternatives`);

    return new Response(
      JSON.stringify({ success: true, ...result }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[item-alternative] Error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers }
    );
  }
});
