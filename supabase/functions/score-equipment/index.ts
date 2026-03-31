// Haven Edge Function: score-equipment
// AI-powered reliability scoring for equipment brands and models.
// Uses Claude to analyze our catalog data + its training knowledge
// (Consumer Reports, r/BuyItForLife, r/Appliances, repair tech forums)
// to generate 1-100 scores with pros/cons.
//
// Usage:
//   POST /functions/v1/score-equipment
//   Body: { "manufacturer_slug": "bosch" }           // Score brand across all categories
//   Body: { "catalog_entry_id": "uuid" }              // Score a specific model
//   Body: { "batch": true, "limit": 50 }              // Score next 50 unscored brands

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ScoreResult {
  overall_score: number;
  reliability_score: number;
  value_score: number;
  repairability_score: number;
  longevity_score: number;
  summary: string;
  pros: string[];
  cons: string[];
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    if (!anthropicKey) {
      throw new Error("ANTHROPIC_API_KEY not configured");
    }

    const body = await req.json().catch(() => ({}));
    const manufacturerSlug: string | null = body.manufacturer_slug ?? null;
    const catalogEntryId: string | null = body.catalog_entry_id ?? null;
    const batch: boolean = body.batch ?? false;
    const batchLimit: number = Math.min(body.limit ?? 20, 100);

    const results: any[] = [];

    if (catalogEntryId) {
      // Score a specific model
      const score = await scoreModel(supabase, anthropicKey, catalogEntryId);
      results.push(score);
    } else if (manufacturerSlug) {
      // Score a brand across categories
      const score = await scoreBrand(supabase, anthropicKey, manufacturerSlug);
      results.push(score);
    } else if (batch) {
      // Score unscored brands in batch
      const scored = await scoreBatch(supabase, anthropicKey, batchLimit);
      results.push(...scored);
    } else {
      throw new Error("Provide manufacturer_slug, catalog_entry_id, or batch: true");
    }

    return new Response(
      JSON.stringify({ scored: results.length, results }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// ── Score a single model ───────────────────────────────────────────────────

async function scoreModel(
  supabase: any,
  anthropicKey: string,
  catalogEntryId: string
) {
  // Check for existing non-expired score
  const { data: existing } = await supabase
    .from("equipment_scores")
    .select("*")
    .eq("catalog_entry_id", catalogEntryId)
    .gt("expires_at", new Date().toISOString())
    .limit(1);

  if (existing && existing.length > 0) {
    return { status: "cached", ...existing[0] };
  }

  // Fetch model data
  const { data: model } = await supabase
    .from("equipment_catalog")
    .select(`
      *,
      equipment_manufacturers!inner (id, name, slug, tier, parent_company),
      equipment_categories!inner (id, name, slug)
    `)
    .eq("id", catalogEntryId)
    .single();

  if (!model) throw new Error(`Model ${catalogEntryId} not found`);

  // Fetch common issues for this model/category/manufacturer
  const { data: issues } = await supabase
    .from("equipment_common_issues")
    .select("issue_title, description, diy_difficulty, estimated_repair_cost_low, estimated_repair_cost_high, typical_occurrence_years")
    .or(`catalog_entry_id.eq.${catalogEntryId},category_id.eq.${model.category_id},manufacturer_id.eq.${model.manufacturer_id}`)
    .limit(10);

  // Fetch maintenance schedule
  const { data: schedules } = await supabase
    .from("equipment_service_schedules")
    .select("task_name, frequency_months, estimated_cost, professional_recommended")
    .or(`catalog_entry_id.eq.${catalogEntryId},category_id.eq.${model.category_id}`)
    .limit(10);

  const mfg = model.equipment_manufacturers;
  const cat = model.equipment_categories;

  const prompt = buildModelPrompt(model, mfg, cat, issues || [], schedules || []);
  const scores = await callClaude(anthropicKey, prompt);

  // Delete existing model score, then insert fresh
  await supabase
    .from("equipment_scores")
    .delete()
    .eq("catalog_entry_id", catalogEntryId);

  await supabase
    .from("equipment_scores")
    .insert({
      catalog_entry_id: catalogEntryId,
      manufacturer_id: mfg.id,
      category_id: cat.id,
      ...scores,
      data_sources: ["catalog_data", "common_issues", "ai_knowledge"],
      generated_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
    });

  return { status: "scored", model: `${mfg.name} ${model.model_number}`, ...scores };
}

// ── Score a brand across categories ────────────────────────────────────────

async function scoreBrand(
  supabase: any,
  anthropicKey: string,
  manufacturerSlug: string
) {
  const { data: mfg } = await supabase
    .from("equipment_manufacturers")
    .select("*")
    .eq("slug", manufacturerSlug)
    .single();

  if (!mfg) throw new Error(`Manufacturer ${manufacturerSlug} not found`);

  // Check for existing non-expired brand score
  const { data: existing } = await supabase
    .from("equipment_scores")
    .select("*")
    .eq("manufacturer_id", mfg.id)
    .is("catalog_entry_id", null)
    .is("category_id", null)
    .gt("expires_at", new Date().toISOString())
    .limit(1);

  if (existing && existing.length > 0) {
    return { status: "cached", ...existing[0] };
  }

  // Fetch brand's catalog stats
  const { data: models, count } = await supabase
    .from("equipment_catalog")
    .select("model_number, model_name, series, expected_lifespan_years, msrp_usd, typical_repair_cost_low, typical_repair_cost_high, equipment_categories!inner(name)", { count: "exact" })
    .eq("manufacturer_id", mfg.id)
    .limit(50);

  // Fetch brand-level common issues
  const { data: issues } = await supabase
    .from("equipment_common_issues")
    .select("issue_title, description, diy_difficulty, estimated_repair_cost_low, typical_occurrence_years")
    .eq("manufacturer_id", mfg.id)
    .limit(15);

  const prompt = buildBrandPrompt(mfg, models || [], issues || [], count || 0);
  const scores = await callClaude(anthropicKey, prompt);

  // Delete existing brand score, then insert fresh
  await supabase
    .from("equipment_scores")
    .delete()
    .eq("manufacturer_id", mfg.id)
    .is("catalog_entry_id", null)
    .is("category_id", null);

  await supabase
    .from("equipment_scores")
    .insert({
      manufacturer_id: mfg.id,
      catalog_entry_id: null,
      category_id: null,
      ...scores,
      data_sources: ["catalog_data", "common_issues", "ai_knowledge"],
      generated_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
    });

  // Also update the manufacturers table for quick lookups
  await supabase
    .from("equipment_manufacturers")
    .update({
      reliability_score: scores.reliability_score,
      score_summary: scores.summary,
    })
    .eq("id", mfg.id);

  return { status: "scored", brand: mfg.name, ...scores };
}

// ── Batch score unscored brands ────────────────────────────────────────────

async function scoreBatch(
  supabase: any,
  anthropicKey: string,
  limit: number
) {
  // Find manufacturers without a score or with expired scores
  const { data: allMfgs } = await supabase
    .from("equipment_manufacturers")
    .select("slug")
    .is("reliability_score", null)
    .order("name")
    .limit(limit);

  if (!allMfgs || allMfgs.length === 0) {
    return [{ status: "done", message: "All brands have been scored" }];
  }

  const results = [];
  for (const mfg of allMfgs) {
    try {
      const result = await scoreBrand(supabase, anthropicKey, mfg.slug);
      results.push(result);
    } catch (err) {
      results.push({ status: "error", brand: mfg.slug, error: (err as Error).message });
    }
  }

  return results;
}

// ── Claude API ─────────────────────────────────────────────────────────────

async function callClaude(apiKey: string, prompt: string): Promise<ScoreResult> {
  const resp = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      messages: [{
        role: "user",
        content: prompt,
      }],
    }),
  });

  if (!resp.ok) {
    const err = await resp.text();
    throw new Error(`Claude API error: ${resp.status} ${err}`);
  }

  const data = await resp.json();
  const text = data.content?.[0]?.text ?? "";

  // Extract JSON from response (may be wrapped in markdown code blocks)
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error("Claude did not return valid JSON");

  const parsed = JSON.parse(jsonMatch[0]);

  return {
    overall_score: clamp(parsed.overall_score, 1, 100),
    reliability_score: clamp(parsed.reliability_score, 1, 100),
    value_score: clamp(parsed.value_score, 1, 100),
    repairability_score: clamp(parsed.repairability_score, 1, 100),
    longevity_score: clamp(parsed.longevity_score, 1, 100),
    summary: parsed.summary || "",
    pros: (parsed.pros || []).slice(0, 5),
    cons: (parsed.cons || []).slice(0, 5),
  };
}

function clamp(val: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, Math.round(val) || min));
}

// ── Prompt builders ────────────────────────────────────────────────────────

function buildModelPrompt(
  model: any, mfg: any, cat: any,
  issues: any[], schedules: any[]
): string {
  const issuesSummary = issues.length > 0
    ? issues.map(i => `- ${i.issue_title} (${i.diy_difficulty}, ~$${i.estimated_repair_cost_low}-${i.estimated_repair_cost_high}, occurs ~${i.typical_occurrence_years} years)`).join("\n")
    : "No documented issues in our database.";

  const scheduleSummary = schedules.length > 0
    ? schedules.map(s => `- ${s.task_name} every ${s.frequency_months} months (~$${s.estimated_cost}${s.professional_recommended ? ", professional recommended" : ""})`).join("\n")
    : "No specific maintenance schedule documented.";

  return `You are an appliance reliability analyst for a home management app. Score this equipment based on our catalog data AND your knowledge from industry sources (Consumer Reports, repair technician communities, owner forums, r/BuyItForLife, r/Appliances, professional reviews).

Equipment Details:
- Model: ${model.model_number} ${model.model_name ? `(${model.model_name})` : ""}
- Brand: ${mfg.name} (${mfg.tier || "unknown"} tier${mfg.parent_company ? `, part of ${mfg.parent_company}` : ""})
- Category: ${cat.name}
- Series: ${model.series || "N/A"}
- MSRP: ${model.msrp_usd ? `$${model.msrp_usd}` : "Unknown"}
- Expected Lifespan: ${model.expected_lifespan_years || "Unknown"} years
- Fuel Type: ${model.fuel_type || "N/A"}
- Key Features: ${(model.key_features || []).join(", ") || "None listed"}
- Typical Repair Cost: ${model.typical_repair_cost_low && model.typical_repair_cost_high ? `$${model.typical_repair_cost_low}-$${model.typical_repair_cost_high}` : "Unknown"}

Known Issues:
${issuesSummary}

Maintenance Schedule:
${scheduleSummary}

Rate this specific model 1-100 on each dimension. Be honest — if a brand or model has known reliability problems, score accordingly. If it's exceptional, score high.

Return ONLY valid JSON (no markdown, no explanation outside the JSON):
{
  "overall_score": <1-100>,
  "reliability_score": <1-100>,
  "value_score": <1-100>,
  "repairability_score": <1-100>,
  "longevity_score": <1-100>,
  "summary": "<2-3 sentence assessment>",
  "pros": ["<strength 1>", "<strength 2>", "<strength 3>"],
  "cons": ["<weakness 1>", "<weakness 2>", "<weakness 3>"]
}`;
}

function buildBrandPrompt(
  mfg: any, models: any[],
  issues: any[], totalModels: number
): string {
  // Summarize the brand's product range
  const categories = [...new Set(models.map((m: any) => m.equipment_categories?.name).filter(Boolean))];
  const avgLifespan = models.reduce((sum: number, m: any) => sum + (m.expected_lifespan_years || 0), 0) / (models.filter((m: any) => m.expected_lifespan_years).length || 1);
  const priceRange = models.filter((m: any) => m.msrp_usd);
  const minPrice = priceRange.length > 0 ? Math.min(...priceRange.map((m: any) => m.msrp_usd)) : null;
  const maxPrice = priceRange.length > 0 ? Math.max(...priceRange.map((m: any) => m.msrp_usd)) : null;

  const issuesSummary = issues.length > 0
    ? issues.map(i => `- ${i.issue_title}: ${i.description?.substring(0, 100) || ""}`).join("\n")
    : "No brand-specific issues documented.";

  return `You are an appliance reliability analyst for a home management app. Score this BRAND overall based on our catalog data AND your knowledge from industry sources (Consumer Reports, repair technician communities, owner forums, r/BuyItForLife, r/Appliances, professional reviews).

Brand: ${mfg.name}
Tier: ${mfg.tier || "unknown"}
${mfg.parent_company ? `Parent Company: ${mfg.parent_company}` : ""}
Country: ${mfg.country_of_origin || "Unknown"}
Products in Catalog: ${totalModels} models
Categories: ${categories.join(", ") || "Various"}
Average Expected Lifespan: ${avgLifespan ? `${Math.round(avgLifespan)} years` : "Unknown"}
Price Range: ${minPrice && maxPrice ? `$${minPrice} - $${maxPrice}` : "Unknown"}

Known Brand Issues:
${issuesSummary}

Score this brand OVERALL (across all their product lines) 1-100. Be honest and opinionated. Consumers rely on this to make purchase decisions.

Return ONLY valid JSON (no markdown, no explanation outside the JSON):
{
  "overall_score": <1-100>,
  "reliability_score": <1-100>,
  "value_score": <1-100>,
  "repairability_score": <1-100>,
  "longevity_score": <1-100>,
  "summary": "<2-3 sentence brand assessment>",
  "pros": ["<strength 1>", "<strength 2>", "<strength 3>"],
  "cons": ["<weakness 1>", "<weakness 2>", "<weakness 3>"]
}`;
}
