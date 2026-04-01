// Haven Edge Function: score-property
// Uses Claude to estimate current property value based on address, property details,
// purchase history, and completed improvement projects. Stores the estimate
// in properties.current_estimated_value for display on the property card.
//
// Usage:
//   POST /functions/v1/score-property
//   Body: { "property_id": "uuid" }

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
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    if (!anthropicKey) throw new Error("ANTHROPIC_API_KEY not configured");

    const body = await req.json().catch(() => ({}));
    const propertyId: string | null = body.property_id ?? null;
    if (!propertyId) throw new Error("property_id is required");

    // Fetch property details
    const { data: property, error: propError } = await supabase
      .from("properties")
      .select("*")
      .eq("id", propertyId)
      .single();

    if (propError || !property) throw new Error(`Property not found: ${propError?.message}`);

    // Fetch home systems for this property
    const { data: systems } = await supabase
      .from("home_systems")
      .select("name, category, manufacturer, model_number, install_date, status")
      .eq("property_id", propertyId);

    // Fetch completed projects
    const { data: projects } = await supabase
      .from("projects")
      .select("title, description, status, budget, actual_cost, completed_at")
      .eq("property_id", propertyId)
      .in("status", ["completed", "in_progress"]);

    // Fetch total maintenance spend
    const { data: serviceRecords } = await supabase
      .from("service_records")
      .select("cost, service_date, description")
      .eq("property_id", propertyId)
      .not("cost", "is", null);

    const totalMaintenanceSpend = (serviceRecords || []).reduce(
      (sum: number, r: any) => sum + (r.cost || 0), 0
    );

    const totalProjectSpend = (projects || [])
      .filter((p: any) => p.status === "completed")
      .reduce((sum: number, p: any) => sum + (p.actual_cost || p.budget || 0), 0);

    // Build the prompt
    const address = [property.street, property.unit, property.city, property.state, property.zip_code]
      .filter(Boolean).join(", ");

    const purchaseInfo = property.purchase_price
      ? `Purchased for $${property.purchase_price.toLocaleString()}${property.purchase_date ? ` on ${property.purchase_date}` : ""}`
      : "Purchase price not provided";

    const systemsSummary = (systems || []).length > 0
      ? (systems || []).map((s: any) => {
          const parts = [s.name, s.manufacturer, s.model_number, s.install_date ? `installed ${s.install_date}` : null, s.status].filter(Boolean);
          return `  - ${parts.join(", ")}`;
        }).join("\n")
      : "  No systems tracked yet";

    const projectsSummary = (projects || []).length > 0
      ? (projects || []).map((p: any) => {
          const cost = p.actual_cost || p.budget;
          return `  - ${p.title}${cost ? ` ($${cost.toLocaleString()})` : ""}${p.status === "completed" ? " [completed]" : " [in progress]"}`;
        }).join("\n")
      : "  No improvement projects";

    const prompt = `You are a real estate valuation analyst for a home management app. Estimate the current market value of this property as of early 2026.

IMPORTANT CONTEXT: The US housing market experienced massive appreciation from 2020-2025, especially in the Northeast (CT, NY, NJ, MA). Many markets saw 30-50%+ gains. Factor this into your estimate. Your estimate should reflect CURRENT 2026 market values, not historical ones.

Property Details:
- Address: ${address}
- Type: ${property.property_type || "Single Family Home"}
- Year Built: ${property.year_built || "Unknown"}
- Square Footage: ${property.square_footage ? `${property.square_footage} sq ft` : "Unknown"}
- ${purchaseInfo}

Home Systems/Equipment:
${systemsSummary}

Improvement Projects:
${projectsSummary}

Total Maintenance Investment: $${totalMaintenanceSpend.toLocaleString()}
Total Project Investment: $${totalProjectSpend.toLocaleString()}

Instructions:
1. Estimate based on current 2026 market values for ${property.city || "this area"}, ${property.state || ""} ${property.zip_code || ""}
2. Well-maintained homes with modern systems (HVAC, appliances, etc.) sell for MORE than average comps
3. ${property.purchase_price ? `The purchase price was $${property.purchase_price.toLocaleString()} — your estimate MUST be higher than this (homes appreciate, they don't depreciate in this market)` : "If no purchase price is given, estimate based on the area median and property characteristics"}
4. Be optimistic — this homeowner actively maintains their property, which adds real value
5. Factor in any tracked improvement projects as direct value-adds

Return ONLY valid JSON (no markdown):
{
  "estimated_value": <number>,
  "confidence": "<low|medium|high>",
  "value_range_low": <number>,
  "value_range_high": <number>,
  "summary": "<2-3 sentence explanation>",
  "improvement_value_added": <number>,
  "market_trend": "<appreciating|stable|declining>",
  "comparable_note": "<brief note about comparable properties>"
}`;

    // Call Claude
    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 1024,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!resp.ok) {
      const err = await resp.text();
      throw new Error(`Claude API error: ${resp.status} ${err}`);
    }

    const claudeData = await resp.json();
    const text = claudeData.content?.[0]?.text ?? "";
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error("Claude did not return valid JSON");

    const estimate = JSON.parse(jsonMatch[0]);

    // Store the estimate on the property
    await supabase
      .from("properties")
      .update({ current_estimated_value: estimate.estimated_value })
      .eq("id", propertyId);

    return new Response(
      JSON.stringify({
        property_id: propertyId,
        address,
        ...estimate,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
