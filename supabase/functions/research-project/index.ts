// Haven Edge Function: research-project
// Receives a home improvement project description, calls Claude to research
// realistic costs, materials, and tips, and optionally updates the property_projects record.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ResearchRequest {
  project_name: string;
  category: string;
  description?: string;
  property_location?: string;
  project_id?: string;
  user_toolkit?: string[];
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    // --- ENV CHECK ---
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "ANTHROPIC_API_KEY not set" }),
        { status: 500, headers }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // --- PARSE REQUEST ---
    const body: ResearchRequest = await req.json();
    const { project_name, category, description, property_location, project_id, user_toolkit } = body;

    if (!project_name) {
      return new Response(
        JSON.stringify({ error: "Missing project_name" }),
        { status: 400, headers }
      );
    }

    if (!category) {
      return new Response(
        JSON.stringify({ error: "Missing category" }),
        { status: 400, headers }
      );
    }

    console.log(
      `[research-project] Researching: "${project_name}" (${category})${project_id ? ` project_id=${project_id}` : ""}`
    );

    // --- BUILD LOCATION CONTEXT ---
    const locationContext = property_location
      ? `The property is located in ${property_location}. Factor in regional pricing, local permit requirements, and any climate or code considerations specific to this area.`
      : "No specific property location was provided. Use national average pricing for the United States.";

    // --- BUILD TOOLKIT CONTEXT ---
    const toolkitContext = user_toolkit && user_toolkit.length > 0
      ? `\n\nIMPORTANT: The user already owns these tools: ${user_toolkit.join(", ")}. Do NOT include any of these in typicalItems. The user does not need to buy them again.`
      : "";

    // --- BUILD PROMPTS ---
    const systemPrompt = `You are a home improvement cost estimator and project research assistant for Haven, a home management app. You MUST return ONLY valid JSON — no markdown code fences, no backticks, no explanation outside the JSON object. Start your response with { and end with }.

Your job is to provide realistic, detailed cost estimates for home improvement projects. Follow these rules:

1. Use real 2025-2026 retail pricing from major retailers (Home Depot, Lowe's, Menards, etc.) and typical contractor rates.
2. Always include a waste factor (usually 10-15% for materials) in your estimates.
3. Include commonly forgotten items — underlayment, fasteners, adhesives, primers, drop cloths, disposal fees, permit fees, tool rentals, etc. Homeowners consistently underestimate because they forget these things.
4. Be honest about difficulty. If a project looks simple but has gotchas (e.g., asbestos abatement, load-bearing walls, plumbing rough-in), call them out clearly.
5. Pro costs should reflect real contractor pricing including labor, overhead, markup, and profit margin — not just labor + materials.
6. DIY costs should include tool rentals or purchases that a typical homeowner wouldn't already own.
7. For the items list, use specific product names and real unit prices where possible rather than vague categories.
8. Timeframes should reflect realistic DIY pace (weekends only) vs. professional pace.${toolkitContext}`;

    const userPrompt = `Research the following home improvement project and provide a detailed cost estimate.

PROJECT: ${project_name}
CATEGORY: ${category}
${description ? `DESCRIPTION: ${description}` : ""}

LOCATION: ${locationContext}

Return JSON with this EXACT structure:
{
  "projectSummary": "2-3 sentence overview of what this project involves, scope, and key considerations",
  "typicalItems": [
    {
      "name": "Specific product/material name",
      "category": "materials" | "tools" | "hardware" | "rental" | "permits" | "disposal" | "safety",
      "necessity": "required" | "optional" | "likely_owned",
      "multiProjectUseful": false,
      "quantity": 1,
      "unit": "each" | "sq ft" | "linear ft" | "gallon" | "bag" | "box" | "bundle" | "day" | "flat fee",
      "price": 29.99,
      "store": "Home Depot" | "Lowe's" | "Specialty" | "Online" | "Municipal" | "Rental Center"
    }
  ],
  "estimatedDiyCost": {
    "low": 500,
    "high": 1200,
    "breakdown": [
      {"category": "Materials", "amount": "$400-$800"},
      {"category": "Tools & Rentals", "amount": "$50-$150"},
      {"category": "Permits & Fees", "amount": "$50-$250"}
    ]
  },
  "estimatedProCost": {
    "low": 1500,
    "high": 3500,
    "breakdown": [
      {"category": "Labor", "amount": "$800-$1800"},
      {"category": "Materials (contractor pricing)", "amount": "$500-$1000"},
      {"category": "Overhead & Profit", "amount": "$200-$700"}
    ]
  },
  "tipsAndWarnings": [
    "Practical tip or important warning — be specific and actionable"
  ],
  "suggestedVideoTopics": [
    "YouTube search query that would help a DIYer with this specific project"
  ],
  "permitNotes": "Whether permits are typically required, what type, approximate cost and timeline, and consequences of skipping them",
  "difficultyLevel": "beginner" | "intermediate" | "advanced" | "professional-recommended",
  "estimatedTimeframe": {
    "diy": "e.g., 2-3 weekends",
    "professional": "e.g., 2-4 days"
  },
  "dealRating": "good_value" | "fair" | "premium",
  "dealRatingReason": "Brief explanation of whether typical costs for this project represent good value for what you get",
  "homeValueImpact": {
    "score": 72,
    "label": "High ROI" | "Moderate ROI" | "Low ROI" | "Lifestyle Only",
    "typicalRoi": "70-80%",
    "explanation": "Brief explanation of how this project typically affects home resale value and marketability"
  }
}

IMPORTANT:
- The typicalItems list should be comprehensive — include EVERYTHING someone would need to buy, rent, or pay for. 10-25 items is typical.
- Prices in typicalItems should be per-unit prices. The quantity field handles multiples.
- The low/high cost ranges should reflect the realistic spread for a typical-sized version of this project (e.g., average room size, average home size).
- Include at least 3-5 tips/warnings that are specific to THIS project, not generic advice.
- For necessity: "required" = must buy for the project to succeed. "optional" = improves outcome but not essential (e.g., nicer tape, knee pads, premium finishes). "likely_owned" = common household tools the user probably already has (screwdriver, tape measure, utility knife, drill, level, etc.).
- For multiProjectUseful: set to true for tools and items that are broadly useful beyond this specific project (e.g., a stud finder, cordless drill, or oscillating multi-tool). Set to false for project-specific materials and consumables.
- For homeValueImpact score (0-100): Kitchen/bathroom remodels score 70-85, curb appeal 60-75, maintenance/repair 40-60, purely cosmetic/lifestyle 10-30. Base this on real estate industry data about typical ROI at resale.
- dealRating should assess whether the MEDIAN cost of this project is good value for what you get (not comparing to a user budget).
- Include 2-4 video topic suggestions that would actually help someone doing this project.`;

    // --- CALL CLAUDE ---
    console.log(`[research-project] Calling Claude for: "${project_name}"`);

    let claudeResponse: Response;
    try {
      claudeResponse = await fetch(
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
            messages: [
              {
                role: "user",
                content: userPrompt,
              },
            ],
          }),
        }
      );
    } catch (fetchErr) {
      console.error(`[research-project] Fetch to Claude failed:`, fetchErr);
      return new Response(
        JSON.stringify({
          error: "Failed to connect to AI service",
          detail: String(fetchErr),
        }),
        { status: 502, headers }
      );
    }

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      console.error(
        `[research-project] Claude API error (${claudeResponse.status}): ${errText}`
      );

      // Parse specific error types for better client messaging
      let errorMessage = "AI service error";
      let errorCode = "ai_error";
      try {
        const errJson = JSON.parse(errText);
        const errType = errJson?.error?.type ?? "";
        const errMsg = errJson?.error?.message ?? "";

        if (claudeResponse.status === 401) {
          errorMessage = "AI service authentication failed";
          errorCode = "auth_error";
        } else if (claudeResponse.status === 429) {
          errorMessage = "AI service is rate limited. Please wait a moment and try again.";
          errorCode = "rate_limited";
        } else if (errType === "not_found_error" || errMsg.includes("model")) {
          errorMessage = "AI model configuration error";
          errorCode = "model_error";
          console.error(`[research-project] Model error — check model ID is valid`);
        } else if (claudeResponse.status === 400) {
          errorMessage = "AI request was invalid";
          errorCode = "bad_request";
        } else if (claudeResponse.status >= 500) {
          errorMessage = "AI service is temporarily unavailable";
          errorCode = "ai_unavailable";
        }
        console.error(`[research-project] Parsed error type: ${errType}, message: ${errMsg}`);
      } catch {
        // errText was not JSON
      }

      return new Response(
        JSON.stringify({
          error: errorMessage,
          error_code: errorCode,
          detail: errText.substring(0, 500),
        }),
        { status: 502, headers }
      );
    }

    const claudeData = await claudeResponse.json();
    const aiText =
      claudeData?.content?.[0]?.text ?? '{"error": "No response from AI"}';

    // Extract JSON from response
    let research: Record<string, unknown>;
    try {
      // Try direct parse first
      research = JSON.parse(aiText);
    } catch {
      // Try extracting JSON from markdown code block or surrounding text
      const jsonMatch = aiText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          research = JSON.parse(jsonMatch[0]);
        } catch {
          console.error("[research-project] Failed to parse extracted JSON");
          research = {
            projectSummary: aiText.substring(0, 500),
            typicalItems: [],
            estimatedDiyCost: { low: 0, high: 0, breakdown: [] },
            estimatedProCost: { low: 0, high: 0, breakdown: [] },
            tipsAndWarnings: [],
            suggestedVideoTopics: [],
            permitNotes: "Unable to parse AI response",
            difficultyLevel: "unknown",
            estimatedTimeframe: { diy: "unknown", professional: "unknown" },
          };
        }
      } else {
        research = {
          projectSummary: aiText.substring(0, 500),
          typicalItems: [],
          estimatedDiyCost: { low: 0, high: 0, breakdown: [] },
          estimatedProCost: { low: 0, high: 0, breakdown: [] },
          tipsAndWarnings: [],
          suggestedVideoTopics: [],
          permitNotes: "Unable to parse AI response",
          difficultyLevel: "unknown",
          estimatedTimeframe: { diy: "unknown", professional: "unknown" },
        };
      }
    }

    // --- OPTIONALLY UPDATE property_projects RECORD ---
    if (project_id) {
      try {
        const supabase = createClient(supabaseUrl, serviceRoleKey);

        const diyCost = research.estimatedDiyCost as Record<string, unknown> | undefined;
        const proCost = research.estimatedProCost as Record<string, unknown> | undefined;

        const diyAvg =
          diyCost && typeof diyCost.low === "number" && typeof diyCost.high === "number"
            ? Math.round((diyCost.low + diyCost.high) / 2)
            : null;
        const proAvg =
          proCost && typeof proCost.low === "number" && typeof proCost.high === "number"
            ? Math.round((proCost.low + proCost.high) / 2)
            : null;

        const updatePayload: Record<string, unknown> = {
          ai_research: research,
          ai_research_updated_at: new Date().toISOString(),
        };

        if (diyAvg !== null) {
          updatePayload.estimated_diy_cost = diyAvg;
        }
        if (proAvg !== null) {
          updatePayload.estimated_pro_cost = proAvg;
        }

        const { error: updateError } = await supabase
          .from("property_projects")
          .update(updatePayload)
          .eq("id", project_id);

        if (updateError) {
          console.error(
            `[research-project] Failed to update property_projects: ${updateError.message}`
          );
          // Don't fail the whole request — still return the research
        } else {
          console.log(
            `[research-project] Updated property_projects ${project_id} with research data`
          );
        }
      } catch (dbErr) {
        console.error(`[research-project] DB update error:`, dbErr);
      }
    }

    console.log(`[research-project] Success for: "${project_name}"`);

    return new Response(
      JSON.stringify({ success: true, research }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[research-project] Error:", err);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        detail: String(err),
      }),
      { status: 500, headers }
    );
  }
});
