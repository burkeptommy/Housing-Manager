// Haven Edge Function: analyze-quote
// Takes a contractor quote (image or text), extracts line items and vendor info,
// then compares each item to fair market pricing.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callClaudeWithDiscipline } from "../_shared/ai-cost-discipline.ts";

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
      image_base64,
      text,
      project_name,
      project_category,
      property_location,
    } = body;

    if (!image_base64 && !text) {
      return new Response(
        JSON.stringify({
          error: "Send image_base64 (photo of quote) or text (OCR/pasted)",
        }),
        { status: 400, headers }
      );
    }

    const locationContext = property_location
      ? `The property is in ${property_location}. Use regional pricing for comparison.`
      : "Use national average US pricing for comparison.";

    const projectContext =
      project_name && project_category
        ? `This quote is for a "${project_name}" project in the "${project_category}" category.`
        : "The project type is unknown — infer it from the quote contents.";

    const systemPrompt = `You are an expert home improvement cost analyst and estimator. You analyze contractor quotes by researching fair market pricing for the SPECIFIC location provided.

Your job:
1. Extract vendor/contractor information from the quote
2. Identify the BUNDLED SYSTEMS or SCOPE ITEMS — NOT individual line items in isolation
3. For each bundled system, research the TOTAL INSTALLED COST (equipment + labor + accessories + permits + disposal) as a single package price for the specific area
4. Compare each bundled system price against your all-in installed estimate
5. Rate each system and give an overall assessment

CRITICAL — TWO-LEVEL ANALYSIS (System + Component):
Contractors quote work as systems/packages even when they list individual components. You MUST analyze at BOTH levels:

LEVEL 1 — SYSTEM/BUNDLE RATING (the primary "is this fair?" answer):
- Group related line items into their parent system/scope (e.g., "Furnace System" = equipment + labor + accessories + disposal + permits)
- Research the TOTAL ALL-IN INSTALLED COST for that system in the specific county
- The system subtotal's rating is the ONE THAT MATTERS for fair/overpriced — this is what the homeowner uses to decide
- If the quote has subtotal lines, use those as system totals
- If no subtotals, group logically and create a virtual system summary

LEVEL 2 — COMPONENT BREAKDOWN (context for negotiation):
- For EACH individual line item (equipment, labor, accessories, permits), still provide:
  - What that component typically costs in the area (estimatedMaterialsCost, estimatedLaborCost, marketMedianPrice)
  - A localPriceRange for what contractors in the county charge for that specific component
  - A rating for that component relative to typical pricing for that component type
  - A ratingReason explaining what the component typically costs so the homeowner can have an informed discussion
- This gives the homeowner ammo: "I see your furnace unit is $3,200 — that's fair, but your labor at $8,400 is on the high end for this area where it typically runs $5,500–$7,500"
- Component ratings should reflect component-level fairness, but make clear in ratingReason how it fits into the system total

PRICING RULES:
- ${locationContext}
- ${projectContext}
- ALWAYS price for the specific county/town — costs vary significantly even within the same state (e.g., Fairfield County CT is 20-40% higher than rural CT)
- Use MEDIAN contractor rates for the region, not cheapest or most expensive
- Research TOTAL INSTALLED COST — what a homeowner should expect to pay all-in for the complete job from a reputable licensed contractor
- Factor in contractor wholesale pricing on materials (10-20% below retail)
- A "fair" rating means within 15% of the typical all-in installed price for the area
- "good_deal" means more than 15% below typical installed price
- "overpriced" means more than 15% above typical installed price
- Be specific — cite the full installed price range a homeowner should expect in that county

HANDLING QUOTES WITHOUT PER-ITEM PRICES:
Many contractor quotes list scope items without individual prices, showing only a lump sum total. When this happens:
- Set "quotedPrice" to null for each line item
- STILL provide your full research on what each system/scope should cost all-in
- Sum all your estimates to get "estimatedFairTotal"
- Compare the contractor's lump sum total against your estimatedFairTotal
- Set "priceSource" to "estimated" (vs "quoted" when the contractor provided the price)

You MUST respond with valid JSON only. No markdown, no backticks, no code fences.`;

    const userPrompt = `Analyze this contractor quote. Research fair market pricing for EVERY line item based on the specific location provided.

Return this exact JSON structure:
{
  "vendor": {
    "name": "Company name from quote",
    "phone": "Phone if visible",
    "email": "Email if visible",
    "address": "Address if visible",
    "license": "License number if visible",
    "trade": "The contractor's primary trade/specialty (e.g., Electrical, Plumbing, HVAC, General Contractor, Roofing, Painting, Flooring, Carpentry, Masonry, Landscaping, Insulation, Drywall, Demolition, Windows & Doors, Solar, Fire Protection, Septic, Well, Pool/Spa)"
  },
  "projectType": "Inferred project category (e.g., Kitchen Renovation, Bathroom Remodel, Roofing)",
  "quoteDate": "Date on quote if visible, or null",
  "quoteTotal": 154500.00,
  "hasItemizedPricing": false,
  "lineItems": [
    {
      "description": "Exact description from quote",
      "category": "materials|labor|permits|disposal|other",
      "quantity": 1,
      "unit": "each|sq ft|linear ft|hour|flat fee",
      "quotedPrice": null,
      "estimatedMaterialsCost": 2500.00,
      "estimatedLaborCost": 1500.00,
      "marketMedianPrice": 4000.00,
      "localPriceRange": {
        "low": 3200.00,
        "high": 5500.00,
        "countyName": "Fairfield County",
        "costIndex": "high"
      },
      "priceSource": "estimated|quoted",
      "rating": "good_deal|fair|overpriced|unknown",
      "ratingReason": "Detailed explanation with specific dollar amounts for this area. E.g., 'Cabinet installation in Fairfield County CT typically runs $3,000-5,000 for materials and $2,000-3,500 for labor based on a standard 10x12 kitchen.'"
    }
  ],
  "overallAssessment": {
    "rating": "good_deal|fair|overpriced",
    "summary": "2-3 sentence assessment. When no per-item prices exist, explain how the lump sum total compares to your item-by-item research.",
    "totalQuoted": 154500.00,
    "estimatedFairTotal": 0.00,
    "estimatedMaterials": 0.00,
    "estimatedLabor": 0.00,
    "potentialSavings": 0.00,
    "negotiationTips": [
      "Specific, actionable tip referencing actual line items and dollar amounts"
    ]
  },
  "suggestedDiyAlternative": {
    "feasible": true,
    "estimatedDiyCost": 0.00,
    "notes": "Brief note about DIY feasibility — which items a handy homeowner could do vs must hire out"
  }
}

IMPORTANT — TWO-LEVEL ANALYSIS:
- Extract EVERY line item from the quote including subtotals, components, warranties, and credits
- Include BOTH system subtotals AND individual components as separate lineItems entries
- For SYSTEM SUBTOTALS: research the all-in installed cost for the complete system. The rating here is the definitive answer on value. localPriceRange should reflect total installed cost range for the system in that county.
- For INDIVIDUAL COMPONENTS (equipment, labor, accessories, permits): research what that specific component typically costs. Give it its own rating and localPriceRange. The ratingReason should say things like "Oil furnace equipment at contractor wholesale typically runs $2,600-$3,800 in Fairfield County" or "Furnace replacement labor including removal, ductwork, and startup typically runs $5,500-$7,500 in this market"
- This gives homeowners specific talking points: "Your labor seems high — the typical range here is X to Y"
- The estimatedFairTotal in overallAssessment should reflect the all-in installed cost for ALL systems combined
- For items like warranties, rebates, or $0 items: rate as "fair" and note they're standard/expected
- Sum your system-level estimates to verify consistency with estimatedFairTotal

LOCAL PRICE RANGE (localPriceRange) — REQUIRED for every line item:
- "low": the low end of what contractors in this SPECIFIC county charge for this work (10th-25th percentile)
- "high": the high end for this county (75th-90th percentile). In high-cost counties like Fairfield County CT, Westchester NY, or the Bay Area, the high end should reflect premium contractor rates for that market
- "countyName": the county name (e.g., "Fairfield County", "Los Angeles County")
- "costIndex": rate the county's cost of living for home improvement — "low", "average", "high", or "very_high"
- The range should reflect the FULL spread a homeowner might see from different contractors in that county — budget contractors to premium firms
- For high-cost counties, labor rates are significantly higher (often 30-60% above national average). Adjust accordingly.
- For low-cost counties, labor rates can be 15-30% below national average. Adjust accordingly.
- Materials costs vary less by region (10-15%) but labor is the big swing factor`;

    // Build Claude messages — support both image and text
    const messages: Array<{ role: string; content: unknown }> = [];

    if (image_base64) {
      // Detect media type from base64 header or default to jpeg
      let mediaType = "image/jpeg";
      if (image_base64.startsWith("/9j/")) mediaType = "image/jpeg";
      else if (image_base64.startsWith("iVBOR")) mediaType = "image/png";
      else if (image_base64.startsWith("JVBER")) mediaType = "application/pdf";

      const isPdf = mediaType === "application/pdf";

      // Claude uses "document" type for PDFs, "image" type for images
      const contentBlock = isPdf
        ? {
            type: "document" as const,
            source: {
              type: "base64" as const,
              media_type: mediaType,
              data: image_base64,
            },
          }
        : {
            type: "image" as const,
            source: {
              type: "base64" as const,
              media_type: mediaType,
              data: image_base64,
            },
          };

      messages.push({
        role: "user",
        content: [
          contentBlock,
          {
            type: "text",
            text: userPrompt,
          },
        ],
      });
    } else {
      messages.push({
        role: "user",
        content: `Here is the text of the contractor quote:\n\n${text}\n\n${userPrompt}`,
      });
    }

    // Phase 95 — route through cost-discipline helper, but keep opus
    // as the default model for quote analysis. Tom's call: this is
    // the single highest-value AI feature in the app (catching
    // overpriced line items can save the homeowner thousands per
    // quote), so reasoning quality matters more than per-call cost.
    // We still get the kill-switch + daily budget cap + telemetry +
    // automatic fallback to sonnet/haiku if opus is rate-limited or
    // overloaded.
    //
    // max_tokens stays at 8K (down from 16K). Real outputs typically
    // run 3-5K; 8K gives slack for line-item-heavy quotes without
    // being wastefully open-ended.
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabaseClient = supabaseUrl && serviceRoleKey
      ? createClient(supabaseUrl, serviceRoleKey)
      : null;
    const aiResult = await callClaudeWithDiscipline({
      supabase: supabaseClient,
      apiKey: anthropicApiKey,
      tag: "analyze_quote",
      max_tokens: 8192,
      // Opus first — Tom's instruction: quote analysis is the biggest
      // value-add and accuracy matters. Sonnet fallback for opus rate
      // limits / overload. Haiku as last resort so we never fail to
      // return something rather than silently dropping the analysis.
      models: ["claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-5"],
      system: systemPrompt,
      messages: messages as Array<{ role: "user" | "assistant"; content: unknown }>,
    });
    if (!aiResult) {
      return new Response(
        JSON.stringify({ error: "AI analysis failed", detail: "Disabled by kill-switch, daily budget exhausted, or all model fallbacks failed." }),
        { status: 502, headers }
      );
    }
    const aiText = aiResult.text || '{"error": "No response from AI"}';
    const stopReason = "end_turn"; // legacy logging — helper doesn't surface this

    console.log(`[analyze-quote] Claude response: ${aiText.length} chars, stop_reason=${stopReason}`);

    // If response was truncated, log a warning
    if (stopReason === "max_tokens") {
      console.warn(`[analyze-quote] Response was truncated (hit max_tokens). Response may have incomplete JSON.`);
    }

    // --- PARSE JSON RESPONSE ---
    let analysis: Record<string, unknown>;
    try {
      // Strip markdown code fences if present (Claude sometimes wraps JSON in ```json ... ```)
      let cleaned = aiText.trim();
      if (cleaned.startsWith("```json")) cleaned = cleaned.slice(7);
      else if (cleaned.startsWith("```")) cleaned = cleaned.slice(3);
      if (cleaned.endsWith("```")) cleaned = cleaned.slice(0, -3);
      cleaned = cleaned.trim();

      analysis = JSON.parse(cleaned);
    } catch {
      // Fallback: try to extract JSON object from the response
      const jsonMatch = aiText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          analysis = JSON.parse(jsonMatch[0]);
        } catch {
          console.error(`[analyze-quote] JSON parse failed. Raw (first 500): ${aiText.substring(0, 500)}`);
          analysis = { error: "Could not parse AI response. Try a clearer photo or PDF.", raw: aiText.substring(0, 500) };
        }
      } else {
        console.error(`[analyze-quote] No JSON found in response. Raw (first 500): ${aiText.substring(0, 500)}`);
        analysis = { error: "Could not parse AI response. Try a clearer photo or PDF.", raw: aiText.substring(0, 500) };
      }
    }

    // If analysis contains an error, return 422 so client gets a useful message
    if (analysis.error) {
      console.error(`[analyze-quote] Parse failed: ${analysis.error}`);
      return new Response(
        JSON.stringify({ success: false, error: analysis.error, detail: (analysis.raw as string)?.substring(0, 200) }),
        { status: 422, headers }
      );
    }

    console.log(`[analyze-quote] Success — ${(analysis.lineItems as unknown[])?.length ?? 0} items extracted`);

    return new Response(
      JSON.stringify({ success: true, analysis }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[analyze-quote] Error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers }
    );
  }
});
