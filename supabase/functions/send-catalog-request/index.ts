// Haven Edge Function: send-catalog-request
//
// Phase 4 of the equipment catalog expansion (plan: i-tried-to-add-reactive-boole.md).
//
// Dual-writes a homeowner request for a missing catalog entry: inserts into
// equipment_catalog_requests so the admin portal can surface it, AND sends an
// email backstop to tom@getchez.com so it doesn't sit unseen.
//
// Two trigger surfaces:
//   1. Photo-ID partial match — iOS captures the label photo, Claude Vision
//      extracts brand/model/serial, but our catalog doesn't have that exact
//      SKU. iOS POSTs source: "photo_label" with the extracted fields and
//      optionally an image_path (already uploaded to equipment-label-photos
//      bucket).
//   2. Text-search escape hatch — user submits "Don't see your system?" form
//      from EquipmentSearchSheet. iOS POSTs source: "text_search" with brand
//      + systemType + optional model.
//
// Backward compatibility: the original API of this function (brand,
// systemType, modelNumber, notes, userId, householdId) keeps working —
// existing iOS callers don't need to change.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const sendgridApiKey = Deno.env.get("SENDGRID_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json();

    // Accept both legacy and new payload shapes. Legacy: brand, systemType,
    // modelNumber, notes. New: brand, systemType (or productType), model
    // (alias modelNumber), serial, source, imagePath, homeSystemId.
    const brand: string | undefined = body.brand;
    const systemType: string | undefined = body.systemType ?? body.productType;
    const modelNumber: string | undefined = body.modelNumber ?? body.model;
    const serial: string | undefined = body.serialNumber ?? body.serial;
    const notes: string | undefined = body.notes;
    const userId: string | undefined = body.userId;
    const householdId: string | undefined = body.householdId;
    const homeSystemId: string | undefined = body.homeSystemId;
    const imagePath: string | undefined = body.imagePath;
    const source: string =
      body.source ??
      (imagePath ? "photo_label" : (modelNumber || serial ? "text_search" : "unknown"));

    if (!brand && !modelNumber) {
      return new Response(
        JSON.stringify({ error: "Provide at least { brand } or { modelNumber }" }),
        { status: 400, headers }
      );
    }

    // ------------------------------------------------------------------
    // 1. Insert into equipment_catalog_requests (admin queue)
    // ------------------------------------------------------------------
    let requestId: string | null = null;
    if (householdId) {
      const insertPayload: Record<string, unknown> = {
        household_id: householdId,
        user_id: userId ?? null,
        home_system_id: homeSystemId ?? null,
        submitted_brand: brand ?? null,
        submitted_model_number: modelNumber ?? null,
        submitted_serial: serial ?? null,
        submitted_product_type: systemType ?? null,
        image_path: imagePath ?? null,
        notes: notes ?? null,
        status: "pending",
        source: ["photo_label", "text_search", "manual", "unknown"].includes(source)
          ? source
          : "unknown",
      };
      const { data: inserted, error: insertErr } = await supabase
        .from("equipment_catalog_requests")
        .insert(insertPayload)
        .select("id")
        .single();
      if (insertErr) {
        console.error("[send-catalog-request] DB insert failed:", insertErr);
        // Don't fail the whole request — fall through to email. Surface in response.
      } else {
        requestId = inserted?.id ?? null;
      }
    } else {
      console.warn("[send-catalog-request] Missing householdId — skipping DB insert, email only.");
    }

    // ------------------------------------------------------------------
    // 2. Look up customer details for email body
    // ------------------------------------------------------------------
    let userEmail = "Unknown";
    let userName = "A Chez user";
    let householdName = "";
    if (userId) {
      const { data: user } = await supabase
        .from("users")
        .select("email, full_name")
        .eq("id", userId)
        .single();
      if (user) {
        userEmail = user.email || "Unknown";
        userName = user.full_name || userEmail;
      }
      if (householdId) {
        const { data: household } = await supabase
          .from("households")
          .select("name")
          .eq("id", householdId)
          .single();
        householdName = household?.name || "";
      }
    }

    // July 2026 (audit F14): the email used to link to
    // admin.getchez.com/system-requests/{id} — a host + route that have
    // NEVER existed (no admin queue reads equipment_catalog_requests), and
    // promised a 4-hour SLA against that dead surface. Email IS the surface:
    // the request row (id below) is the record; act on it by hand, then
    // UPDATE its status to 'added'. No fabricated SLA, no dead link.
    const requestRef = requestId
      ? `\nRequest id: ${requestId} (update equipment_catalog_requests.status = 'added' when done)\n`
      : "";

    const emailBody = `
A Chez customer needs an equipment added to the catalog.

Source: ${source}
Brand: ${brand ?? "(not provided)"}
${systemType ? `Type: ${systemType}` : ""}
${modelNumber ? `Model: ${modelNumber}` : ""}
${serial ? `Serial: ${serial}` : ""}
${imagePath ? `Label photo: ${supabaseUrl}/storage/v1/object/public/equipment-label-photos/${imagePath}` : ""}
${notes ? `Notes: ${notes}` : ""}

Customer: ${userName} (${userEmail})
${householdName ? `Household: ${householdName}` : ""}
${requestRef}
To fulfill: add the model to equipment_catalog, then set this request's
status to 'added' — the customer gets a push when it lands.
    `.trim();

    if (sendgridApiKey) {
      const sgResponse = await fetch("https://api.sendgrid.com/v3/mail/send", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${sendgridApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          personalizations: [{ to: [{ email: "tom@getchez.com" }] }],
          from: { email: "alfred@getchez.com", name: "Chez Catalog Requests" },
          subject: `Catalog request: ${brand ?? "?"}${modelNumber ? ` ${modelNumber}` : ""}${systemType ? ` (${systemType})` : ""}`,
          content: [{ type: "text/plain", value: emailBody }],
        }),
      });

      if (!sgResponse.ok) {
        const errText = await sgResponse.text().catch(() => "unknown");
        console.error(`[send-catalog-request] SendGrid error: ${sgResponse.status} ${errText}`);
      } else {
        console.log(`[send-catalog-request] Email sent: ${brand} ${modelNumber ?? ""}`);
      }
    } else {
      console.log(`[send-catalog-request] No SENDGRID_API_KEY — logging only.`);
      console.log(emailBody);
    }

    return new Response(
      JSON.stringify({
        success: true,
        request_id: requestId,
      }),
      { status: 200, headers }
    );
  } catch (err) {
    console.error(`[send-catalog-request] Error: ${err}`);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers }
    );
  }
});
