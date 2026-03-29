// Haven Edge Function: project-feasibility
// Lightweight ROI analysis for project suggestions on the dashboard.
// Returns cost estimate + ROI data without the full 30-item line breakdown.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface FeasibilityRequest {
  project_type: string;
  property_location?: string;
  year_built?: number;
  square_footage?: number;
  property_value?: number;
}

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

    const body: FeasibilityRequest = await req.json();
    const { project_type, property_location, year_built, square_footage, property_value } = body;

    if (!project_type) {
      return new Response(
        JSON.stringify({ error: "Missing project_type" }),
        { status: 400, headers }
      );
    }

    const locationContext = property_location
      ? `Property location: ${property_location}.`
      : "Use national US averages.";

    const propertyContext = [
      year_built ? `Built in ${year_built}` : null,
      square_footage ? `${square_footage} sq ft` : null,
      property_value ? `Estimated value: $${property_value.toLocaleString()}` : null,
    ].filter(Boolean).join(". ");

    const prompt = `You are a real estate and home improvement ROI analyst. Provide a quick feasibility assessment for this project.

PROJECT: ${project_type}
${locationContext}
${propertyContext ? `PROPERTY: ${propertyContext}` : ""}

Return ONLY valid JSON:
{
  "projectName": "Clean project name",
  "estimatedCostRange": {
    "low": 0,
    "high": 0
  },
  "estimatedDiyCostRange": {
    "low": 0,
    "high": 0
  },
  "estimatedMaterialsCost": {
    "low": 0,
    "high": 0
  },
  "complexity": "Easy" | "Moderate" | "Complex" | "Professional Recommended",
  "complexityNote": "1 sentence explaining why this complexity level",
  "estimatedTimeframe": "e.g. '2-3 weekends' or '1-2 days'",
  "roi": {
    "score": 0,
    "label": "High ROI" | "Moderate ROI" | "Low ROI" | "Lifestyle Only",
    "typicalReturn": "60-80%",
    "explanation": "1-2 sentences on why this ROI level"
  },
  "valueIncrease": {
    "estimatedDollarIncrease": 0,
    "percentageIncrease": "2-4%",
    "timeToRecoup": "Immediate at resale" | "3-5 years" | "May not recoup"
  },
  "marketDemand": "High" | "Moderate" | "Low",
  "marketDemandNote": "Brief note on buyer demand for this feature",
  "quickTip": "One practical tip for maximizing ROI on this project"
}

estimatedMaterialsCost = materials only (no labor, no tools). For DIY homeowners budgeting a trip to the store.
complexity = how hard this is for a competent DIYer. "Professional Recommended" means code/safety/specialty work.

Base the ROI on real estate industry data. Be specific to the location and property details if provided.`;

    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 1024,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      console.error(`[project-feasibility] Claude error: ${errText}`);
      return new Response(
        JSON.stringify({ error: "AI analysis failed" }),
        { status: 502, headers }
      );
    }

    const claudeData = await claudeResponse.json();
    const aiText = claudeData?.content?.[0]?.text ?? "{}";

    let feasibility: Record<string, unknown>;
    try {
      feasibility = JSON.parse(aiText);
    } catch {
      const match = aiText.match(/\{[\s\S]*\}/);
      feasibility = match ? JSON.parse(match[0]) : { error: "Failed to parse" };
    }

    console.log(`[project-feasibility] Success for: ${project_type}`);

    return new Response(
      JSON.stringify({ success: true, feasibility }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error("[project-feasibility] Error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", detail: String(err) }),
      { status: 500, headers }
    );
  }
});
