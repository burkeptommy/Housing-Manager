// Phase 95 (audit gaps #29 / #68) — email fallback when the handyman
// doesn't open the field PWA.
//
// The homeowner sends an in-app message; the iOS app calls this
// function fire-and-forget right after the message insert succeeds.
// If the handyman has opened the portal recently OR a fallback email
// already went out within the last 24 hours for this request, we
// short-circuit. Otherwise we send a SendGrid email containing the
// most recent message so the handyman can read and reply via reply-
// to-thread (handled by the receive-email pipeline) or by opening
// the portal link.
//
// In-app remains the primary channel — this is a backstop. We
// intentionally don't fire SMS yet (Tom's call: in-app + email only
// for now).
//
// Env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SENDGRID_API_KEY.
//
// Deploy: `supabase functions deploy notify-handyman-message-fallback --no-verify-jwt`

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const FROM_EMAIL = "hello@getchez.com";
const FROM_NAME = "Chez Field";

// 24h cooldowns. Tunable here; deploy required to take effect.
const PORTAL_INACTIVITY_HOURS = 24;
const FALLBACK_RATE_LIMIT_HOURS = 24;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const sendgridKey = Deno.env.get("SENDGRID_API_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ error: "Supabase not configured" }), { status: 500, headers });
    }
    if (!sendgridKey) {
      // Without SendGrid this function can't do its job. Return 200
      // so the iOS fire-and-forget call doesn't error-toast the user
      // — the in-app message already landed; this was a backstop.
      console.warn("[notify-handyman-fallback] SENDGRID_API_KEY missing; skipping email");
      return new Response(JSON.stringify({ skipped: "no_sendgrid_key" }), { status: 200, headers });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const body = await req.json();
    const requestId = (body.request_id ?? "").trim();
    if (!requestId) {
      return new Response(JSON.stringify({ error: "Missing request_id" }), { status: 400, headers });
    }

    // 1. Load the request + linked contractor (the handyman receiving
    //    the email) + the household name (used in the From / subject
    //    line). We do this in parallel so the function stays under
    //    300ms in the happy path.
    const [requestRes, msgsRes] = await Promise.all([
      supabase
        .from("handyman_requests")
        .select("id, household_id, contractor_id, title, status, last_email_fallback_sent_at")
        .eq("id", requestId)
        .limit(1)
        .maybeSingle(),
      supabase
        .from("handyman_request_messages")
        .select("id, sender_role, body, created_at")
        .eq("request_id", requestId)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle(),
    ]);

    if (requestRes.error || !requestRes.data) {
      return new Response(JSON.stringify({ error: "Request not found" }), { status: 404, headers });
    }
    const request = requestRes.data;
    const latestMessage = msgsRes.data;

    if (!latestMessage || latestMessage.sender_role !== "homeowner") {
      // Latest message wasn't from the homeowner (or there is none).
      // Nothing to fall back from — handyman / system messages
      // shouldn't email the handyman.
      return new Response(JSON.stringify({ skipped: "no_homeowner_message" }), { status: 200, headers });
    }

    // Rate-limit per-request to once per day. Same-day repeat messages
    // collapse into one digest email so the handyman doesn't get
    // hammered if the homeowner sends a flurry.
    if (request.last_email_fallback_sent_at) {
      const sentAt = new Date(request.last_email_fallback_sent_at);
      const ageHours = (Date.now() - sentAt.getTime()) / 3600_000;
      if (ageHours < FALLBACK_RATE_LIMIT_HOURS) {
        return new Response(JSON.stringify({ skipped: "rate_limited" }), { status: 200, headers });
      }
    }

    // 2. Has the handyman opened the portal recently? If yes, in-app
    //    is sufficient; skip the email.
    if (request.contractor_id) {
      const { data: session } = await supabase
        .from("handyman_portal_sessions")
        .select("last_opened_at")
        .eq("contractor_id", request.contractor_id)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (session?.last_opened_at) {
        const openedAt = new Date(session.last_opened_at as string);
        const ageHours = (Date.now() - openedAt.getTime()) / 3600_000;
        if (ageHours < PORTAL_INACTIVITY_HOURS) {
          return new Response(JSON.stringify({ skipped: "handyman_active" }), { status: 200, headers });
        }
      }
    }

    // 3. Resolve the handyman's email from the linked contractor row.
    //    No email = nothing we can do. Return 200 so the caller
    //    treats it as "best effort done."
    if (!request.contractor_id) {
      return new Response(JSON.stringify({ skipped: "no_contractor" }), { status: 200, headers });
    }
    const { data: contractor } = await supabase
      .from("contractors")
      .select("email, contact_name, company_name")
      .eq("id", request.contractor_id)
      .limit(1)
      .maybeSingle();
    const handymanEmail = (contractor?.email ?? "").trim();
    if (!handymanEmail) {
      return new Response(JSON.stringify({ skipped: "no_handyman_email" }), { status: 200, headers });
    }

    // 4. Pull the household name for the subject line. Best-effort.
    const { data: household } = await supabase
      .from("households")
      .select("name")
      .eq("id", request.household_id)
      .limit(1)
      .maybeSingle();
    const householdName = (household?.name ?? "").trim() || "your client";

    // 5. Compose + send the email.
    const subject = `${householdName} sent a message`;
    const messageBody = String(latestMessage.body ?? "").trim() || "(no message body)";
    const requestTitle = String(request.title ?? "").trim();
    const handymanName = String(contractor?.contact_name ?? contractor?.company_name ?? "").trim();

    const text = [
      handymanName ? `Hi ${handymanName.split(" ")[0]},` : "Hi,",
      "",
      `${householdName} sent you a message in Chez:`,
      "",
      messageBody,
      "",
      requestTitle ? `Request: ${requestTitle}` : null,
      "",
      "Reply to this email or open the Chez Field portal to respond.",
    ]
      .filter((line) => line !== null)
      .join("\n");

    const html = `
      <p>${handymanName ? `Hi ${escapeHtml(handymanName.split(" ")[0])},` : "Hi,"}</p>
      <p><strong>${escapeHtml(householdName)}</strong> sent you a message in Chez:</p>
      <blockquote style="border-left:3px solid #ED6955;padding-left:12px;color:#453A70;">
        ${escapeHtml(messageBody).replace(/\n/g, "<br/>")}
      </blockquote>
      ${requestTitle ? `<p style="color:#71717A;">Request: ${escapeHtml(requestTitle)}</p>` : ""}
      <p style="color:#71717A;">Reply to this email or open the Chez Field portal to respond.</p>
    `.trim();

    const sendgridResponse = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${sendgridKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        personalizations: [
          {
            to: [{ email: handymanEmail, name: handymanName || undefined }],
            subject,
          },
        ],
        from: { email: FROM_EMAIL, name: FROM_NAME },
        content: [
          { type: "text/plain", value: text },
          { type: "text/html", value: html },
        ],
        categories: ["handyman_message_fallback"],
      }),
    });

    if (!sendgridResponse.ok) {
      const detail = await sendgridResponse.text().catch(() => "");
      console.error("[notify-handyman-fallback] SendGrid error:", sendgridResponse.status, detail.slice(0, 240));
      return new Response(
        JSON.stringify({ error: "SendGrid send failed" }),
        { status: 502, headers }
      );
    }

    // 6. Stamp the rate-limit timestamp so subsequent calls inside
    //    the 24h window short-circuit.
    await supabase
      .from("handyman_requests")
      .update({ last_email_fallback_sent_at: new Date().toISOString() })
      .eq("id", requestId);

    return new Response(JSON.stringify({ sent: true }), { status: 200, headers });
  } catch (error) {
    console.error("[notify-handyman-fallback] Error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message ?? "Internal error" }),
      { status: 500, headers }
    );
  }
});

function escapeHtml(input: string): string {
  return input
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}
