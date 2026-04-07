// Haven Edge Function: vehicle-lookup
// Decodes a VIN (typed or photographed) via NHTSA APIs, fetches recall data,
// and generates a vehicle-specific maintenance schedule using Claude.
//
// Usage:
//   POST /functions/v1/vehicle-lookup
//   Body: { "vin": "1HGBH41JXMN109186" }
//   Body: { "image_base64": "..." }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// NHTSA variable IDs we care about
const NHTSA_VARIABLE_MAP: Record<number, string> = {
  29: "model_year",
  26: "make",
  28: "model",
  109: "trim",
  5: "body_class",
  15: "drive_type",
  9: "engine_cylinders",
  11: "displacement_l",
  24: "fuel_type",
  37: "transmission",
  75: "plant_country",
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
    let vin: string | null = (body.vin ?? "").trim().toUpperCase() || null;
    const imageBase64: string | null = body.image_base64 ?? null;

    // -------------------------------------------------------------------
    // Step 1: If image provided, extract VIN via Claude Vision
    // -------------------------------------------------------------------
    if (!vin && imageBase64) {
      console.log("[vehicle-lookup] Extracting VIN from image via Claude Vision");

      const visionResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": anthropicApiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 512,
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
                  text: `You are analyzing a photo of a vehicle VIN sticker, VIN plate, registration document, or any document/label containing a Vehicle Identification Number (VIN).

Extract the 17-character VIN from this image. A VIN is exactly 17 characters long, containing uppercase letters (except I, O, Q) and digits.

Respond with ONLY valid JSON:
{
  "found": true,
  "vin": "THE17CHARVIN12345",
  "confidence": "high" or "medium" or "low",
  "source": "where on the image you found it"
}

If no VIN is visible or readable, respond:
{
  "found": false,
  "vin": null,
  "confidence": null,
  "source": null
}`,
                },
              ],
            },
          ],
        }),
      });

      if (!visionResponse.ok) {
        const errText = await visionResponse.text();
        console.error("[vehicle-lookup] Claude Vision error:", errText);
        return new Response(
          JSON.stringify({ error: "Failed to analyze image for VIN" }),
          { status: 502, headers }
        );
      }

      const visionResult = await visionResponse.json();
      const rawText = visionResult.content?.[0]?.text ?? "";

      let visionData;
      try {
        visionData = JSON.parse(rawText);
      } catch {
        const jsonMatch = rawText.match(/```(?:json)?\s*([\s\S]*?)```/);
        if (jsonMatch) {
          visionData = JSON.parse(jsonMatch[1].trim());
        } else {
          console.error("[vehicle-lookup] Failed to parse vision response:", rawText.substring(0, 500));
          return new Response(
            JSON.stringify({ error: "Could not extract VIN from image" }),
            { status: 422, headers }
          );
        }
      }

      if (!visionData.found || !visionData.vin) {
        return new Response(
          JSON.stringify({ error: "No VIN found in the provided image" }),
          { status: 422, headers }
        );
      }

      vin = visionData.vin.toUpperCase();
      console.log(`[vehicle-lookup] Extracted VIN from image: ${vin} (confidence: ${visionData.confidence})`);
    }

    // Validate we have a VIN at this point
    if (!vin) {
      return new Response(
        JSON.stringify({ error: "Either vin or image_base64 is required" }),
        { status: 400, headers }
      );
    }

    // Basic VIN format validation
    if (!/^[A-HJ-NPR-Z0-9]{17}$/.test(vin)) {
      return new Response(
        JSON.stringify({ error: "Invalid VIN format. Must be 17 characters (letters A-H, J-N, P-R, S-Z and digits)." }),
        { status: 400, headers }
      );
    }

    console.log(`[vehicle-lookup] Decoding VIN: ${vin}`);

    // -------------------------------------------------------------------
    // Step 2: Call NHTSA APIs in parallel (VIN Decoder + Recalls)
    // -------------------------------------------------------------------
    // Use allSettled so a recalls DNS failure doesn't kill VIN decode
    const [decodeResult, recallsResult] = await Promise.allSettled([
      fetch(`https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/${vin}?format=json`),
      fetch(`https://api.nhtsa.dot.gov/recalls/recallsByVin?vin=${vin}`)
        .catch(() => fetch(`https://vpic.nhtsa.dot.gov/api/vehicles/GetRecalls/vin/${vin}?format=json`))
        .catch(() => null),
    ]);

    // Parse VIN decode results
    if (decodeResult.status !== "fulfilled" || !decodeResult.value.ok) {
      const reason = decodeResult.status === "rejected" ? String(decodeResult.reason) : `HTTP ${(decodeResult as any).value?.status}`;
      console.error("[vehicle-lookup] NHTSA VIN decode failed:", reason);
      return new Response(
        JSON.stringify({ error: "NHTSA VIN decode service unavailable" }),
        { status: 502, headers }
      );
    }

    const decodeData = await decodeResult.value.json();
    const results = decodeData.Results ?? [];

    // Save the recalls response for later (may be null/rejected)
    const recallsResponse = recallsResult.status === "fulfilled" ? recallsResult.value : null;

    // Extract the fields we care about
    const vehicle: Record<string, string | null> = { vin };
    for (const result of results) {
      const variableId = result.VariableId;
      const fieldName = NHTSA_VARIABLE_MAP[variableId];
      if (fieldName && result.Value && result.Value.trim() !== "") {
        vehicle[fieldName] = result.Value.trim();
      }
    }

    // Check if we got meaningful data
    if (!vehicle.make && !vehicle.model) {
      return new Response(
        JSON.stringify({
          error: "VIN not found in NHTSA database. The VIN may be invalid or for a non-US market vehicle.",
          vin,
        }),
        { status: 404, headers }
      );
    }

    // Parse recalls
    let recalls: Array<Record<string, string>> = [];
    let recallCount = 0;
    try {
      if (recallsResponse && recallsResponse.ok) {
        const recallsData = await recallsResponse.json();
        const rawRecalls = recallsData.results ?? [];
        recalls = rawRecalls.map((r: Record<string, string>) => ({
          nhtsa_campaign_number: r.NHTSACampaignNumber ?? null,
          report_date: r.ReportReceivedDate ?? null,
          component: r.Component ?? null,
          summary: r.Summary ?? null,
          consequence: r.Consequence ?? null,
          remedy: r.Remedy ?? null,
          manufacturer: r.Manufacturer ?? null,
        }));
        recallCount = recalls.length;
      }
    } catch (e) {
      console.error("[vehicle-lookup] Recalls API parse error:", e);
      // Non-fatal: continue without recalls
    }

    console.log(`[vehicle-lookup] Decoded: ${vehicle.model_year} ${vehicle.make} ${vehicle.model} | ${recallCount} recalls`);

    // -------------------------------------------------------------------
    // Step 3: Generate maintenance schedule via Claude
    // -------------------------------------------------------------------
    const vehicleDescription = [
      vehicle.model_year,
      vehicle.make,
      vehicle.model,
      vehicle.trim,
      vehicle.engine_cylinders ? `${vehicle.engine_cylinders}-cylinder` : null,
      vehicle.displacement_l ? `${(parseFloat(vehicle.displacement_l) / 1000).toFixed(1)}L` : null,
      vehicle.fuel_type,
      vehicle.drive_type,
      vehicle.transmission,
    ]
      .filter(Boolean)
      .join(" ");

    const maintenanceResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 4096,
        system: `You are an expert automotive technician. Generate a comprehensive maintenance schedule specific to this exact vehicle. Use manufacturer-recommended intervals where known, and industry standards otherwise. Be specific to the vehicle's engine type, drivetrain, and fuel type.

Return ONLY valid JSON -- no markdown fences, no backticks, no commentary.`,
        messages: [
          {
            role: "user",
            content: `Generate a maintenance schedule for this vehicle: ${vehicleDescription}

Return a JSON array of maintenance items. Each item must have these exact fields:
- "type": one of: oil_change, tire_rotation, brake_inspection, air_filter, cabin_filter, transmission_fluid, coolant_flush, spark_plugs, battery_check, wheel_alignment, wiper_blades, serpentine_belt, timing_belt, differential_fluid
- "interval_miles": number (miles between service)
- "interval_months": number (months between service)
- "estimated_cost": number (USD estimate for a typical shop)
- "description": string (1-2 sentences specific to this vehicle, including any model-specific notes)

Include all 14 types. If a type does not apply to this vehicle (e.g., timing_belt on a chain-driven engine, or differential_fluid on a FWD car), set interval_miles and interval_months to null, estimated_cost to 0, and description should explain why it does not apply.

Return ONLY the JSON array.`,
          },
        ],
      }),
    });

    let maintenanceSchedule: Array<Record<string, unknown>> = [];

    if (maintenanceResponse.ok) {
      const maintenanceResult = await maintenanceResponse.json();
      const maintenanceText = maintenanceResult.content?.[0]?.text ?? "";

      try {
        maintenanceSchedule = JSON.parse(maintenanceText);
      } catch {
        const jsonMatch = maintenanceText.match(/```(?:json)?\s*([\s\S]*?)```/);
        if (jsonMatch) {
          maintenanceSchedule = JSON.parse(jsonMatch[1].trim());
        } else {
          console.error("[vehicle-lookup] Failed to parse maintenance schedule:", maintenanceText.substring(0, 500));
        }
      }
    } else {
      console.error("[vehicle-lookup] Claude maintenance schedule error:", maintenanceResponse.status);
    }

    // -------------------------------------------------------------------
    // Step 4: Return combined results
    // -------------------------------------------------------------------
    const response = {
      vehicle,
      recalls,
      recall_count: recallCount,
      maintenance_schedule: maintenanceSchedule,
      vin_decoded: true,
    };

    console.log(`[vehicle-lookup] Success for VIN ${vin}`);

    return new Response(JSON.stringify(response), { status: 200, headers });
  } catch (error) {
    console.error("[vehicle-lookup] Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers }
    );
  }
});
