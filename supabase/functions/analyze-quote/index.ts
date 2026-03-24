// Haven Edge Function: analyze-quote
// Takes a contractor quote (image or text), extracts line items and vendor info,
// then compares each item to fair market pricing.

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

    const systemPrompt = `You are an expert home improvement cost analyst. You analyze contractor quotes and compare them to fair market pricing.

Your job:
1. Extract the vendor/contractor information from the quote
2. Extract every line item with quantities, unit prices, and totals
3. Compare each line item to the MEDIAN fair market price for that item/service in 2025-2026
4. Rate each line item as "good_deal", "fair", or "overpriced" with explanation
5. Give an overall assessment of the quote

IMPORTANT RULES:
- Compare to MEDIAN market prices, not cheapest available
- For labor, compare to typical contractor rates for the region
- Factor in that contractors buy materials at wholesale (10-20% below retail)
- A "fair" rating means within 15% of median market price
- "good_deal" means more than 15% below median
- "overpriced" means more than 15% above median
- Be specific about WHY something is overpriced — cite what the typical price should be
- ${locationContext}
- ${projectContext}

You MUST respond with valid JSON only. No markdown, no backticks.`;

    const userPrompt = `Analyze this contractor quote and compare every line item to fair market pricing.

Return this exact JSON structure:
{
  "vendor": {
    "name": "Company name from quote",
    "phone": "Phone if visible",
    "email": "Email if visible",
    "address": "Address if visible",
    "license": "License number if visible"
  },
  "projectType": "Inferred project category (e.g., Electrical, Plumbing, Kitchen Renovation)",
  "quoteDate": "Date on quote if visible, or null",
  "quoteTotal": 0.00,
  "lineItems": [
    {
      "description": "Exact description from quote",
      "category": "materials|labor|permits|disposal|other",
      "quantity": 1,
      "unit": "each|sq ft|linear ft|hour|flat fee",
      "unitPrice": 0.00,
      "totalPrice": 0.00,
      "marketMedianPrice": 0.00,
      "rating": "good_deal|fair|overpriced",
      "ratingReason": "Brief explanation comparing to market price"
    }
  ],
  "overallAssessment": {
    "rating": "good_deal|fair|overpriced",
    "summary": "2-3 sentence overall assessment of the quote",
    "totalQuoted": 0.00,
    "estimatedFairTotal": 0.00,
    "potentialSavings": 0.00,
    "negotiationTips": [
      "Specific, actionable tip for negotiating this quote"
    ]
  },
  "suggestedDiyAlternative": {
    "feasible": true,
    "estimatedDiyCost": 0.00,
    "notes": "Brief note about DIY feasibility for this project"
  }
}

Be thorough — extract EVERY line item from the quote, even small ones. The user needs to see exactly what they're paying for.`;

    // Build Claude messages — support both image and text
    const messages: Array<{ role: string; content: unknown }> = [];

    if (image_base64) {
      // Detect media type from base64 header or default to jpeg
      let mediaType = "image/jpeg";
      if (image_base64.startsWith("/9j/")) mediaType = "image/jpeg";
      else if (image_base64.startsWith("iVBOR")) mediaType = "image/png";
      else if (image_base64.startsWith("JVBER")) mediaType = "application/pdf";

      messages.push({
        role: "user",
        content: [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: mediaType,
              data: image_base64,
            },
          },
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

    console.log(`[analyze-quote] Calling Claude for quote analysis`);

    const claudeResponse = await fetch(
      "https://api.anthropic.com/v1/messages",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": anthropicApiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 4096,
          system: systemPrompt,
          messages,
        }),
      }
    );

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      console.error(
        `[analyze-quote] Claude error (${claudeResponse.status}): ${errText}`
      );
      return new Response(
        JSON.stringify({
          error: "AI analysis failed",
          detail: errText.substring(0, 500),
        }),
        { status: 502, headers }
      );
    }

    const claudeData = await claudeResponse.json();
    const aiText =
      claudeData?.content?.[0]?.text ?? '{"error": "No response"}';

    let analysis: Record<string, unknown>;
    try {
      analysis = JSON.parse(aiText);
    } catch {
      const jsonMatch = aiText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          analysis = JSON.parse(jsonMatch[0]);
        } catch {
          analysis = { error: "Failed to parse AI response", raw: aiText.substring(0, 500) };
        }
      } else {
        analysis = { error: "Failed to parse AI response", raw: aiText.substring(0, 500) };
      }
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
