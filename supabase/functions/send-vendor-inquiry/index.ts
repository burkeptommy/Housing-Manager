// Phase 95 (audit gap #47) — Service-vendor outreach delivery.
//
// Service vendors (HVAC, plumber, electrician, roofer, etc.) don't have
// an app, so the only inbound channel they have is email. This Edge
// Function takes a `service_vendor_inquiries` row id, renders a
// homeowner-styled email via SendGrid, and stamps the row's
// delivery_status when done. Reply-to is set to the household's
// alfred.getchez.com forwarding address so any reply lands in
// `receive-email` and surfaces in the homeowner's Inbox.
//
// Per Tom's audit feedback: "in-app first + email fallback only (NO
// SMS) for handyman messaging." This is the same model — the iOS sheet
// is the homeowner's in-app surface; SendGrid is the fallback that
// actually reaches the vendor since they have nothing else.

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
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const sendgridKey = Deno.env.get("SENDGRID_API_KEY") ?? "";
    if (!sendgridKey) {
      return new Response(JSON.stringify({ error: "SendGrid not configured" }), { status: 500, headers });
    }
    const service = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json();
    const inquiryId = (body?.inquiry_id ?? "").toString().trim();
    if (!inquiryId) {
      return new Response(JSON.stringify({ error: "inquiry_id required" }), { status: 400, headers });
    }

    // Pull the inquiry, the contractor's contact info, and the
    // homeowner's display name + forwarding email in one round-trip
    // each. RLS bypass via service role is OK because we trust the
    // caller's JWT (verify-jwt enforced at the iOS layer).
    const { data: inquiry, error: inquiryErr } = await service
      .from("service_vendor_inquiries")
      .select("*")
      .eq("id", inquiryId)
      .maybeSingle();
    if (inquiryErr || !inquiry) {
      return new Response(JSON.stringify({ error: "inquiry not found" }), { status: 404, headers });
    }

    const { data: contractor } = await service
      .from("contractors")
      .select("id, company_name, contact_name, email, phone")
      .eq("id", inquiry.contractor_id)
      .maybeSingle();

    const { data: sender } = await service
      .from("users")
      .select("id, full_name, email")
      .eq("id", inquiry.sender_user_id)
      .maybeSingle();

    const { data: forwarding } = await service
      .from("household_email_addresses")
      .select("local_part")
      .eq("household_id", inquiry.household_id)
      .order("created_at", { ascending: true })
      .limit(1)
      .maybeSingle();

    const replyTo = forwarding?.local_part
      ? `${forwarding.local_part}@alfred.getchez.com`
      : "hello@getchez.com";

    if (!contractor?.email) {
      // Service vendor has no email on file → record the no_email
      // status and bail. The iOS layer surfaces the resulting state
      // via the row's delivery_status field.
      await service
        .from("service_vendor_inquiries")
        .update({ delivery_status: "no_email" })
        .eq("id", inquiryId);
      return new Response(JSON.stringify({ ok: true, delivery_status: "no_email" }), { headers });
    }

    const senderName = sender?.full_name?.trim() || "A Chez homeowner";
    const subject = inquiry.subject?.trim() || `Inquiry from ${senderName}`;

    const text = `Hi ${contractor.contact_name?.trim() || contractor.company_name?.trim() || "there"},

${senderName} is reaching out via the Chez home-management app. They've asked us to pass along the message below.

—

${inquiry.body}

—

Reply directly to this email and ${senderName} will see your response in their Chez Inbox. There's nothing to install.

Thanks,
The Chez team`;

    const html = `<p>Hi ${escapeHtml(contractor.contact_name?.trim() || contractor.company_name?.trim() || "there")},</p>
<p>${escapeHtml(senderName)} is reaching out via the Chez home-management app. They've asked us to pass along the message below.</p>
<hr/>
<p style="white-space: pre-wrap;">${escapeHtml(inquiry.body)}</p>
<hr/>
<p>Reply directly to this email and ${escapeHtml(senderName)} will see your response in their Chez Inbox. There's nothing to install.</p>
<p>Thanks,<br/>The Chez team</p>`;

    const sgPayload = {
      personalizations: [
        {
          to: [
            {
              email: contractor.email,
              name: contractor.company_name?.trim() || undefined,
            },
          ],
        },
      ],
      from: { email: "hello@getchez.com", name: "Chez" },
      reply_to: { email: replyTo, name: senderName },
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
      console.error("[send-vendor-inquiry] SendGrid error:", errText);
      await service
        .from("service_vendor_inquiries")
        .update({
          delivery_status: "failed",
          delivery_error: errText.substring(0, 500),
        })
        .eq("id", inquiryId);
      return new Response(JSON.stringify({ ok: false, delivery_status: "failed" }), { status: 502, headers });
    }

    await service
      .from("service_vendor_inquiries")
      .update({
        delivery_status: "sent",
        sent_at: new Date().toISOString(),
      })
      .eq("id", inquiryId);

    return new Response(JSON.stringify({ ok: true, delivery_status: "sent" }), { headers });
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error);
    console.error("[send-vendor-inquiry] Error:", errMsg);
    return new Response(JSON.stringify({ error: errMsg }), { status: 500, headers });
  }
});

function escapeHtml(input: string): string {
  return input
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
