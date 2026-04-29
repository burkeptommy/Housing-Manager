// Haven Edge Function: send-household-invite
//
// Sends a Haven household invitation email through SendGrid. Called by the
// HouseholdInviteCoordinator on iOS when someone is added to a household with
// an email and the user has chosen to send an invite. Also reused by
// `resend-household-invite` and the daily reminder cron.
//
// Required Supabase secrets:
//   SENDGRID_API_KEY -- API key with mail.send scope
//
// Authentication:
//   The function is deployed with --no-verify-jwt because we want the iOS
//   client to call it with the user's session token. The function does not
//   look up the caller; the caller is responsible for telling the function
//   which household, inviter, and recipient the email is for.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface SendInviteRequest {
  to: string;
  invite_code: string;
  invite_url: string;
  inviter_name: string;
  inviter_avatar_url?: string | null;
  household_name?: string | null;
  household_address?: string | null;
  system_count?: number | null;
  task_count?: number | null;
  member_count?: number | null;
  personal_message?: string | null;
  invitee_first_name?: string | null;
}

const FROM_EMAIL = "hello@havenhome.dev";
const FROM_NAME = "Chez";
const REPLY_TO_EMAIL = "tom@havenhome.dev";

function escapeHtml(input: string): string {
  return input
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function formatCode(code: string): string {
  const cleaned = code.toUpperCase().replace(/-/g, "");
  if (cleaned.length !== 6) return cleaned;
  return `${cleaned.slice(0, 3)}-${cleaned.slice(3)}`;
}

function buildHtml(payload: SendInviteRequest): string {
  const inviteeName = payload.invitee_first_name?.trim() || "there";
  const inviterName = payload.inviter_name?.trim() || "Someone";
  const householdName = payload.household_name?.trim();
  const address = payload.household_address?.trim();
  const personalMessage = payload.personal_message?.trim();
  const code = formatCode(payload.invite_code);

  const counts: string[] = [];
  if (typeof payload.system_count === "number" && payload.system_count > 0) {
    counts.push(`${payload.system_count} home system${payload.system_count === 1 ? "" : "s"}`);
  }
  if (typeof payload.task_count === "number" && payload.task_count > 0) {
    counts.push(`${payload.task_count} maintenance task${payload.task_count === 1 ? "" : "s"}`);
  }
  if (typeof payload.member_count === "number" && payload.member_count > 0) {
    counts.push(`${payload.member_count} household member${payload.member_count === 1 ? "" : "s"}`);
  }
  const countsLine = counts.length
    ? `${escapeHtml(inviterName)} has set up ${escapeHtml(counts.join(", "))} so far.`
    : "";

  const personalBlock = personalMessage
    ? `<tr><td style="padding-top:24px;font-family:Georgia,serif;font-style:italic;font-size:15px;color:#1B2A4A;">"${escapeHtml(personalMessage)}"</td></tr>`
    : "";

  return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>You're invited to Chez</title>
  </head>
  <body style="margin:0;padding:0;background:#F2EEE5;font-family:Georgia,serif;color:#1B2A4A;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F2EEE5;">
      <tr>
        <td align="center" style="padding:48px 16px;">
          <table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px;background:#F8F6F1;border-radius:16px;border:1px solid #F0EBE1;">
            <tr>
              <td style="padding:32px 32px 8px 32px;text-align:center;">
                <div style="font-family:Georgia,serif;font-size:28px;font-weight:bold;color:#1B2A4A;letter-spacing:0.5px;">Chez</div>
              </td>
            </tr>
            <tr>
              <td style="padding:24px 32px 0 32px;font-family:Georgia,serif;font-size:18px;color:#1B2A4A;">
                Hi ${escapeHtml(inviteeName)},
              </td>
            </tr>
            <tr>
              <td style="padding:16px 32px 0 32px;font-family:Georgia,serif;font-size:15px;line-height:1.55;color:#1B2A4A;">
                ${escapeHtml(inviterName)} invited you to join ${householdName ? `<strong>${escapeHtml(householdName)}</strong>` : "their household"} on Chez, the app that helps families protect their home and everything in it.
              </td>
            </tr>
            ${address ? `<tr><td style="padding:24px 32px 0 32px;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FAF7F2;border:1px solid #E3D9C6;border-radius:12px;"><tr><td style="padding:16px 20px;font-family:Georgia,serif;font-size:14px;color:#1B2A4A;">${escapeHtml(address)}</td></tr></table></td></tr>` : ""}
            ${countsLine ? `<tr><td style="padding:16px 32px 0 32px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:13px;color:#1B2A4A;opacity:0.8;">${countsLine}</td></tr>` : ""}
            ${personalBlock ? `<tr><td style="padding:0 32px;">${personalBlock}</td></tr>` : ""}
            <tr>
              <td style="padding:32px 32px 0 32px;text-align:center;">
                <a href="${escapeHtml(payload.invite_url)}" style="display:inline-block;padding:14px 28px;background:#1B2A4A;color:#F8F6F1;text-decoration:none;border-radius:14px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:15px;font-weight:600;">Open in Chez</a>
              </td>
            </tr>
            <tr>
              <td style="padding:24px 32px 0 32px;text-align:center;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:13px;color:#1B2A4A;opacity:0.7;">
                Or enter this code in the app:
              </td>
            </tr>
            <tr>
              <td style="padding:8px 32px 0 32px;text-align:center;font-family:'SF Mono',Menlo,Monaco,monospace;font-size:24px;font-weight:bold;letter-spacing:4px;color:#1B2A4A;">
                ${escapeHtml(code)}
              </td>
            </tr>
            <tr>
              <td style="padding:32px 32px 0 32px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:12px;line-height:1.6;color:#1B2A4A;opacity:0.6;text-align:center;">
                This invite expires in 30 days. If you don't want to join, just ignore this email.<br />
                Need help? Reply to this message and Tom will get it.
              </td>
            </tr>
            <tr>
              <td style="padding:24px 32px 32px 32px;text-align:center;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:11px;color:#1B2A4A;opacity:0.5;">
                Chez, havenhome.dev
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

function buildText(payload: SendInviteRequest): string {
  const inviteeName = payload.invitee_first_name?.trim() || "there";
  const inviterName = payload.inviter_name?.trim() || "Someone";
  const householdName = payload.household_name?.trim() || "their household";
  const address = payload.household_address?.trim();
  const personalMessage = payload.personal_message?.trim();
  const code = formatCode(payload.invite_code);

  const lines: string[] = [];
  lines.push(`Hi ${inviteeName},`);
  lines.push("");
  lines.push(`${inviterName} invited you to join ${householdName} on Chez, the app that helps families protect their home and everything in it.`);
  if (address) {
    lines.push("");
    lines.push(address);
  }
  if (personalMessage) {
    lines.push("");
    lines.push(`"${personalMessage}"`);
  }
  lines.push("");
  lines.push(`Open in Chez: ${payload.invite_url}`);
  lines.push("");
  lines.push(`Or enter code: ${code}`);
  lines.push("");
  lines.push("This invite expires in 30 days. If you don't want to join, just ignore this email.");
  lines.push("");
  lines.push("Chez, havenhome.dev");
  return lines.join("\n");
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const sendgridKey = Deno.env.get("SENDGRID_API_KEY");
    if (!sendgridKey) {
      console.error("[send-household-invite] SENDGRID_API_KEY not configured");
      return new Response(JSON.stringify({ error: "Email service not configured" }), { status: 503, headers });
    }

    const payload = (await req.json()) as SendInviteRequest;

    if (!payload?.to || !payload.invite_code || !payload.invite_url || !payload.inviter_name) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: to, invite_code, invite_url, inviter_name" }),
        { status: 400, headers }
      );
    }

    const subject = `${payload.inviter_name.split(/\s+/)[0]} invited you to Chez`;
    const previewText = payload.household_name
      ? `Join ${payload.household_name} to keep your home protected together.`
      : "Join their household to keep your home protected together.";

    const sendgridBody = {
      personalizations: [
        {
          to: [
            {
              email: payload.to,
              name: payload.invitee_first_name || undefined,
            },
          ],
          subject,
        },
      ],
      from: { email: FROM_EMAIL, name: FROM_NAME },
      reply_to: { email: REPLY_TO_EMAIL, name: "Tom Burke" },
      content: [
        { type: "text/plain", value: buildText(payload) },
        { type: "text/html", value: buildHtml(payload) },
      ],
      // Include the preview text as a custom header so SendGrid templates can
      // pick it up if we ever migrate to dynamic templates. Email clients show
      // it through the first line of the HTML otherwise.
      headers: {
        "X-Preview-Text": previewText,
      },
      categories: ["household_invite"],
    };

    const sendgridResponse = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${sendgridKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(sendgridBody),
    });

    if (!sendgridResponse.ok) {
      const errText = await sendgridResponse.text();
      console.error(`[send-household-invite] SendGrid ${sendgridResponse.status}: ${errText}`);
      return new Response(
        JSON.stringify({
          error: "SendGrid rejected the request",
          status: sendgridResponse.status,
          detail: errText.slice(0, 500),
        }),
        { status: 502, headers }
      );
    }

    console.log(
      `[send-household-invite] Sent to ${payload.to} for code ${payload.invite_code}`
    );

    return new Response(
      JSON.stringify({
        sent: true,
        to: payload.to,
        invite_code: payload.invite_code,
      }),
      { status: 200, headers }
    );
  } catch (error) {
    console.error("[send-household-invite] Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers }
    );
  }
});
