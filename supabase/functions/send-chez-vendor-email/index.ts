// Phase 86C — Chez vendor outbound email.
//
// The cockpit operator can email a vendor AS Chez (on behalf of a homeowner)
// without leaving the case thread. Reply-to is a sub-addressed
// `vendor+<token>@alfred.getchez.com` so the vendor's response gets routed
// by `receive-email` back into the case thread as an inbound vendor
// message — full round-trip, no operator copy-paste.
//
// Auth: admin only via the CHEZ_ADMIN_EMAILS allowlist (mirrors the
// pattern in chez-concierge/isAdminUser). Service role required for the
// chez_vendor_outreach insert + the case-thread system message.
//
// Body schema:
//   {
//     "request_id": "uuid",
//     "contractor_id": "uuid?" (nullable for cold outreach),
//     "vendor_email": "string",
//     "vendor_name": "string?",
//     "subject": "string",
//     "body": "string",
//     "negotiation_payload": { ... }?       // when this is a counter-offer
//   }
//
// Side effects on success:
//   1. SendGrid mail send
//   2. chez_vendor_outreach row inserted (direction=outbound, status=sent)
//   3. concierge_messages system row on the case thread
//      ("📧 To Petro Heating: …") so the homeowner can see Chez is
//      working without exposing the vendor's email verbatim.
//   4. chez_requests.last_message_at refreshed.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const ADMIN_ALLOWLIST = (Deno.env.get("CHEZ_ADMIN_EMAILS") ?? "tom@getchez.com")
  .split(",")
  .map((e) => e.trim().toLowerCase())
  .filter(Boolean);

// Reply-to domain — same as the homeowner forwarding-inbox domain.
// SendGrid Inbound Parse routes `vendor+<token>@alfred.getchez.com`
// through `receive-email`, which (Phase 86C) recognizes the `vendor+`
// prefix and threads the reply into the case.
const REPLY_DOMAIN = Deno.env.get("CHEZ_VENDOR_REPLY_DOMAIN") ?? "alfred.getchez.com";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const sendgridKey = Deno.env.get("SENDGRID_API_KEY") ?? "";
    if (!sendgridKey) {
      return new Response(JSON.stringify({ error: "SendGrid not configured" }), { status: 500, headers });
    }

    const auth = req.headers.get("Authorization") || "";
    const token = auth.replace(/^Bearer\s+/i, "");
    const adminClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const service = createClient(supabaseUrl, serviceRoleKey);

    const { data: userRes } = await adminClient.auth.getUser();
    const userEmail = (userRes?.user?.email ?? "").toLowerCase();
    if (!userEmail || !ADMIN_ALLOWLIST.includes(userEmail)) {
      return new Response(JSON.stringify({ error: "admin only" }), { status: 403, headers });
    }
    const userId = userRes?.user?.id;

    const body = await req.json();
    const requestId = (body?.request_id ?? "").toString().trim();
    const vendorEmail = (body?.vendor_email ?? "").toString().trim();
    const subject = (body?.subject ?? "").toString().trim();
    const messageBody = (body?.body ?? "").toString().trim();
    const vendorName = (body?.vendor_name ?? "").toString().trim() || null;
    const contractorId = (body?.contractor_id ?? null) || null;
    const negotiationPayload = body?.negotiation_payload ?? null;

    if (!requestId || !vendorEmail || !subject || !messageBody) {
      return new Response(
        JSON.stringify({ error: "request_id, vendor_email, subject, body required" }),
        { status: 400, headers }
      );
    }
    if (!isValidEmail(vendorEmail)) {
      return new Response(JSON.stringify({ error: "invalid vendor_email" }), { status: 400, headers });
    }

    // Pull the case for household_id + scope check.
    const { data: req_, error: caseErr } = await service
      .from("chez_requests")
      .select("id, household_id, summary")
      .eq("id", requestId)
      .maybeSingle();
    if (caseErr || !req_) {
      return new Response(JSON.stringify({ error: "case not found" }), { status: 404, headers });
    }

    // Generate a reply token. Crypto.random hex; collision risk vanishing
    // for the foreseeable future. UNIQUE index on the column will catch
    // the astronomical collision case at insert-time.
    const replyToken = generateReplyToken();
    const replyTo = `vendor+${replyToken}@${REPLY_DOMAIN}`;

    // Insert the outreach row FIRST so we have an id to reference if the
    // SendGrid call fails (we mark it failed instead of leaving a phantom).
    const { data: outreachRow, error: insertErr } = await service
      .from("chez_vendor_outreach")
      .insert({
        request_id: requestId,
        household_id: req_.household_id,
        contractor_id: contractorId,
        direction: "outbound",
        channel: "email",
        vendor_name: vendorName,
        vendor_email: vendorEmail,
        subject,
        body: messageBody,
        reply_token: replyToken,
        status: "queued",
        sent_by_user_id: userId,
        negotiation_payload: negotiationPayload,
      })
      .select("*")
      .single();
    if (insertErr || !outreachRow) {
      console.error("[send-chez-vendor-email] outreach insert failed:", insertErr);
      return new Response(JSON.stringify({ error: insertErr?.message ?? "insert failed" }), { status: 500, headers });
    }

    // Build email payload.
    const greeting = vendorName ? `Hi ${vendorName.split(/\s+/)[0]},` : "Hello,";
    const text = `${greeting}\n\n${messageBody}\n\n—\nChez · home-management concierge\nReply to this email and we'll take it from there.`;
    const html = `
      <p>${escapeHtml(greeting)}</p>
      <p style="white-space: pre-wrap;">${escapeHtml(messageBody)}</p>
      <hr style="border:none;border-top:1px solid #EDEEF0;margin:24px 0;" />
      <p style="color:#6F6A88;font-size:13px;">
        <strong>Chez</strong> · home-management concierge<br/>
        Reply to this email and we'll take it from there.
      </p>
    `;

    const sgPayload = {
      personalizations: [{
        to: [{ email: vendorEmail, name: vendorName || undefined }],
      }],
      from: { email: "hello@getchez.com", name: "Chez Concierge" },
      reply_to: { email: replyTo, name: "Chez" },
      subject,
      content: [
        { type: "text/plain", value: text },
        { type: "text/html", value: html },
      ],
    };

    const sgResp = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${sendgridKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(sgPayload),
    });

    if (!sgResp.ok) {
      const errText = await sgResp.text();
      console.error("[send-chez-vendor-email] SendGrid error:", errText);
      await service
        .from("chez_vendor_outreach")
        .update({ status: "failed" })
        .eq("id", outreachRow.id);
      return new Response(
        JSON.stringify({ error: "SendGrid send failed", details: errText.slice(0, 500) }),
        { status: 502, headers }
      );
    }

    // Mark sent.
    await service
      .from("chez_vendor_outreach")
      .update({ status: "sent", sent_at: new Date().toISOString() })
      .eq("id", outreachRow.id);

    // Drop a system message on the case thread so the homeowner sees
    // that Chez is reaching out. NOTE: we don't expose the raw email
    // body to the homeowner — they get a polished line, not the
    // operational mechanics.
    const vendorLabel = vendorName || vendorEmail;
    const summary = summarizeOutreachForHomeowner(subject, messageBody);
    const sysMsg = `Chez reached out to ${vendorLabel} about ${summary}.`;
    await postSystemMessage(service, requestId, sysMsg);
    await service
      .from("chez_requests")
      .update({ last_message_at: new Date().toISOString() })
      .eq("id", requestId);

    return new Response(JSON.stringify({
      ok: true,
      outreach_id: outreachRow.id,
      reply_token: replyToken,
      status: "sent",
    }), { headers });
  } catch (error) {
    console.error("[send-chez-vendor-email]:", error);
    return new Response(JSON.stringify({ error: String(error) }), { status: 500, headers });
  }
});

// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------

function generateReplyToken(): string {
  // 16 hex chars = 64 bits of entropy. Way more than enough for the
  // outreach volume we'll ever see.
  const buf = new Uint8Array(8);
  crypto.getRandomValues(buf);
  return Array.from(buf).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function isValidEmail(s: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s);
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Polishes the outbound subject/body into a customer-facing sentence
// fragment for the case thread. Falls back to the subject if the body is
// already short. Trimmed to ~80 chars to keep the system message clean.
function summarizeOutreachForHomeowner(subject: string, body: string): string {
  const cleanSubject = (subject || "").replace(/^Re:\s*/i, "").trim();
  if (cleanSubject.length > 8) {
    return cleanSubject.length > 80 ? cleanSubject.slice(0, 77) + "…" : cleanSubject;
  }
  const firstLine = (body || "").split(/\n/)[0].trim();
  return firstLine.length > 80 ? firstLine.slice(0, 77) + "…" : firstLine;
}

async function postSystemMessage(service: SupabaseClient, requestId: string, content: string) {
  try {
    await service.from("concierge_messages").insert({
      request_id: requestId,
      role: "system",
      content,
    });
  } catch (e) {
    console.warn("[send-chez-vendor-email] system message insert failed:", e);
  }
}
