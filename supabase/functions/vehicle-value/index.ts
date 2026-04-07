// Haven Edge Function: vehicle-value
// Returns a current estimated market value for a vehicle, computed by Claude
// from year/make/model/trim/mileage. Free fallback for KBB until a paid
// provider (VinAudit, MarketCheck, Black Book) is wired in.
//
// Usage:
//   POST /functions/v1/vehicle-value
//   Body: { year, make, model, trim?, mileage?, condition? }
//   Returns: { low, mid, high, currency, confidence, notes, source }

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
      throw new Error("ANTHROPIC_API_KEY is not configured");
    }

    const body = await req.json();
    const year = body.year;
    const make = (body.make ?? "").toString().trim();
    const model = (body.model ?? "").toString().trim();
    const trim = (body.trim ?? "").toString().trim();
    const mileage = body.mileage;
    const condition = (body.condition ?? "average").toString().trim();

    if (!year || !make || !model) {
      return new Response(
        JSON.stringify({ error: "year, make, and model are required" }),
        { status: 400, headers }
      );
    }

    const descriptor = [year, make, model, trim].filter(Boolean).join(" ");
    const mileageLine = mileage
      ? `Odometer reading: approximately ${mileage} miles.`
      : `Odometer reading: unknown — assume typical mileage for the vehicle's age.`;

    const prompt = `You are a US used-car market expert with access to recent private-party and dealer retail pricing data.

Vehicle: ${descriptor}
${mileageLine}
Condition: ${condition}.

Estimate the CURRENT private-party resale value in US dollars. Consider depreciation, model-year demand, current market trends, and typical mileage adjustments.

Reply with JSON ONLY (no prose, no markdown, no code fences) in this exact shape:
{"low": <integer dollars>, "mid": <integer dollars>, "high": <integer dollars>, "currency": "USD", "confidence": <0.0-1.0>, "notes": "<one-sentence rationale>"}`;

    console.log(`[vehicle-value] Estimating ${descriptor} (${mileage ?? "?"} mi)`);

    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 400,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text();
      console.error("[vehicle-value] Claude error:", errText);
      throw new Error(`Claude API error: ${claudeResponse.status}`);
    }

    const claudeJson = await claudeResponse.json();
    const text: string = claudeJson?.content?.[0]?.text ?? "";

    // Extract JSON object even if Claude wrapped it
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) {
      throw new Error("Claude did not return JSON");
    }
    const parsed = JSON.parse(match[0]);

    const result = {
      low: Math.round(Number(parsed.low) || 0),
      mid: Math.round(Number(parsed.mid) || 0),
      high: Math.round(Number(parsed.high) || 0),
      currency: parsed.currency || "USD",
      confidence: Math.max(0, Math.min(1, Number(parsed.confidence) || 0)),
      notes: parsed.notes || "",
      source: "claude-ai",
    };

    return new Response(JSON.stringify(result), { headers });
  } catch (err) {
    console.error("[vehicle-value] error:", err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers }
    );
  }
});
