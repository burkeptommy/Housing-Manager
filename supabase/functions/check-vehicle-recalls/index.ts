import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { authFailure, requireHousehold, requireInternal } from "../_shared/require-household.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface CollectedRecall {
  vehicleId: string;
  vehicleName: string;
  component: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json();
    let { household_id } = body;

    // --- AUTH (July 2026 security sweep, audit S1) ---
    // Previously read AND WROTE any household's vehicles/recalls from a
    // body-supplied household_id. User callers now derive household from
    // their JWT; internal callers (future scheduled scans) use the secret.
    if (!requireInternal(req)) {
      const auth = await requireHousehold(req);
      if ("failure" in auth) return authFailure(auth, headers);
      household_id = auth.householdId;
    }

    if (!household_id) {
      return new Response(JSON.stringify({ error: "Missing household_id" }), { status: 400, headers });
    }

    // Get all vehicles with VINs
    const { data: vehicles } = await supabase
      .from("vehicles")
      .select("id, vin, name")
      .eq("household_id", household_id)
      .not("vin", "is", null);

    if (!vehicles || vehicles.length === 0) {
      return new Response(JSON.stringify({ checked: 0, new_recalls: 0 }), { status: 200, headers });
    }

    let totalNewRecalls = 0;
    const collected: CollectedRecall[] = [];

    for (const vehicle of vehicles) {
      if (!vehicle.vin || vehicle.vin.length !== 17) continue;

      try {
        // Fetch recalls from NHTSA
        const recallRes = await fetch(`https://api.nhtsa.dot.gov/recalls/recallsByVin?vin=${vehicle.vin}`);
        if (!recallRes.ok) continue;

        const recallData = await recallRes.json();
        const nhtsaRecalls = recallData.results ?? [];

        // Get existing recalls for this vehicle
        const { data: existingRecalls } = await supabase
          .from("vehicle_recalls")
          .select("nhtsa_campaign_number")
          .eq("vehicle_id", vehicle.id);

        const existingCampaigns = new Set(
          (existingRecalls ?? []).map((r: any) => r.nhtsa_campaign_number).filter(Boolean)
        );

        // Insert only new recalls
        for (const recall of nhtsaRecalls) {
          const campaignNum = recall.NHTSACampaignNumber;
          if (!campaignNum || existingCampaigns.has(campaignNum)) continue;

          await supabase.from("vehicle_recalls").insert({
            vehicle_id: vehicle.id,
            household_id,
            nhtsa_campaign_number: campaignNum,
            component: recall.Component,
            summary: recall.Summary,
            consequence: recall.Consequence,
            remedy: recall.Remedy,
            recall_date: recall.ReportReceivedDate,
          });
          totalNewRecalls++;

          // Track for push notification — Phase 95 audit gap #85.
          // Without this, a user-initiated recall refresh silently
          // inserts safety recalls without paging the household. The
          // cron path (proactive-scan) already pushes; this closes the
          // user-tapped path.
          collected.push({
            vehicleId: vehicle.id,
            vehicleName: vehicle.name,
            component: recall.Component ?? "Unknown component",
          });
        }

        console.log(`[check-recalls] ${vehicle.name}: ${nhtsaRecalls.length} NHTSA, ${totalNewRecalls} new`);
      } catch (err) {
        console.warn(`[check-recalls] Failed for ${vehicle.name}: ${err}`);
      }
    }

    // Send push notifications for any new recalls. Mirrors the
    // proactive-scan pattern — one push per recall per device token,
    // tagged with `vehicle_recall` so the iOS push handler routes the
    // tap to VehicleDetailView. Failures are warned and swallowed; the
    // row was already inserted, so the user will still see the recall
    // the next time they open the app.
    if (collected.length > 0) {
      try {
        const { data: hhUsers } = await supabase
          .from("users")
          .select("id")
          .eq("household_id", household_id);
        const userIds = (hhUsers ?? []).map((u: any) => u.id);

        if (userIds.length > 0) {
          const { data: tokens } = await supabase
            .from("device_tokens")
            .select("token")
            .in("user_id", userIds);

          if (tokens && tokens.length > 0) {
            for (const recall of collected) {
              for (const { token } of tokens) {
                try {
                  await supabase.functions.invoke("send-push-notification", {
                    body: {
                      token,
                      title: `New Recall: ${recall.vehicleName}`,
                      body: `${recall.component} - Contact your dealer for details`,
                      data: {
                        type: "vehicle_recall",
                        vehicle_id: recall.vehicleId,
                      },
                    },
                  });
                } catch (pushErr) {
                  console.warn(`[check-recalls] Push failed for token: ${pushErr}`);
                }
              }
            }
          }
        }
      } catch (err) {
        console.warn(`[check-recalls] Push notification error: ${err}`);
      }
    }

    return new Response(
      JSON.stringify({ checked: vehicles.length, new_recalls: totalNewRecalls }),
      { status: 200, headers }
    );
  } catch (error) {
    console.error("[check-recalls] Error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Internal error" }),
      { status: 500, headers }
    );
  }
});
