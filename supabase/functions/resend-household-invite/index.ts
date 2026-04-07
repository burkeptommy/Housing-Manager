// Haven Edge Function: resend-household-invite
//
// Re-sends an existing pending invitation. Called by the settings pending
// invitations row when the user taps "Resend" and by the daily reminder cron
// (via send-reminder-batch) at 24h, 3d, 7d after the original send.
//
// The function looks up the invitation by id with the service role, refuses
// to resend revoked/accepted/expired ones, and rebuilds the same SendGrid
// payload that send-household-invite uses.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface ResendRequest {
  invitation_id: string;
}

const FROM_EMAIL = "hello@havenhome.dev";
const FROM_NAME = "Haven";
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

interface EmailContext {
  to: string;
  inviteCode: string;
  inviteUrl: string;
  inviterName: string;
  householdName: string | null;
  householdAddress: string | null;
  systemCount: number;
  taskCount: number;
  memberCount: number;
  personalMessage: string | null;
  inviteeFirstName: string | null;
}

function buildHtml(ctx: EmailContext): string {
  const inviteeName = ctx.inviteeFirstName?.trim() || "there";
  const inviterName = ctx.inviterName.trim();
  const householdName = ctx.householdName?.trim();
  const address = ctx.householdAddress?.trim();
  const personalMessage = ctx.personalMessage?.trim();
  const code = formatCode(ctx.inviteCode);

  const counts: string[] = [];
  if (ctx.systemCount > 0) counts.push(`${ctx.systemCount} home system${ctx.systemCount === 1 ? "" : "s"}`);
  if (ctx.taskCount > 0) counts.push(`${ctx.taskCount} maintenance task${ctx.taskCount === 1 ? "" : "s"}`);
  if (ctx.memberCount > 0) counts.push(`${ctx.memberCount} household member${ctx.memberCount === 1 ? "" : "s"}`);
  const countsLine = counts.length
    ? `${escapeHtml(inviterName)} has set up ${escapeHtml(counts.join(", "))} so far.`
    : "";
  const personalBlock = personalMessage
    ? `<tr><td style="padding-top:24px;font-family:Georgia,serif;font-style:italic;font-size:15px;color:#1B2A4A;">"${escapeHtml(personalMessage)}"</td></tr>`
    : "";

  return `<!doctype html>
<html>
  <body style="margin:0;padding:0;background:#F2EEE5;font-family:Georgia,serif;color:#1B2A4A;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F2EEE5;">
      <tr>
        <td align="center" style="padding:48px 16px;">
          <table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px;background:#F8F6F1;border-radius:16px;border:1px solid #F0EBE1;">
            <tr><td style="padding:32px 32px 8px 32px;text-align:center;"><div style="font-family:Georgia,serif;font-size:28px;font-weight:bold;color:#1B2A4A;letter-spacing:0.5px;">Haven</div></td></tr>
            <tr><td style="padding:24px 32px 0 32px;font-family:Georgia,serif;font-size:18px;color:#1B2A4A;">Hi ${escapeHtml(inviteeName)},</td></tr>
            <tr><td style="padding:16px 32px 0 32px;font-family:Georgia,serif;font-size:15px;line-height:1.55;color:#1B2A4A;">A quick reminder: ${escapeHtml(inviterName)} invited you to join ${householdName ? `<strong>${escapeHtml(householdName)}</strong>` : "their household"} on Haven. Your invite is still active and we wanted to make sure it didn't get lost in your inbox.</td></tr>
            ${address ? `<tr><td style="padding:24px 32px 0 32px;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FAF7F2;border:1px solid #E3D9C6;border-radius:12px;"><tr><td style="padding:16px 20px;font-family:Georgia,serif;font-size:14px;color:#1B2A4A;">${escapeHtml(address)}</td></tr></table></td></tr>` : ""}
            ${countsLine ? `<tr><td style="padding:16px 32px 0 32px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:13px;color:#1B2A4A;opacity:0.8;">${countsLine}</td></tr>` : ""}
            ${personalBlock ? `<tr><td style="padding:0 32px;">${personalBlock}</td></tr>` : ""}
            <tr><td style="padding:32px 32px 0 32px;text-align:center;"><a href="${escapeHtml(ctx.inviteUrl)}" style="display:inline-block;padding:14px 28px;background:#1B2A4A;color:#F8F6F1;text-decoration:none;border-radius:14px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:15px;font-weight:600;">Open in Haven</a></td></tr>
            <tr><td style="padding:24px 32px 0 32px;text-align:center;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:13px;color:#1B2A4A;opacity:0.7;">Or enter this code in the app:</td></tr>
            <tr><td style="padding:8px 32px 0 32px;text-align:center;font-family:'SF Mono',Menlo,Monaco,monospace;font-size:24px;font-weight:bold;letter-spacing:4px;color:#1B2A4A;">${escapeHtml(code)}</td></tr>
            <tr><td style="padding:32px 32px 0 32px;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:12px;line-height:1.6;color:#1B2A4A;opacity:0.6;text-align:center;">This invite expires in 30 days. If you don't want to join, just ignore this email.</td></tr>
            <tr><td style="padding:24px 32px 32px 32px;text-align:center;font-family:'SF Pro',-apple-system,Helvetica,Arial,sans-serif;font-size:11px;color:#1B2A4A;opacity:0.5;">Haven Home, havenhome.dev</td></tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

function buildText(ctx: EmailContext): string {
  const inviteeName = ctx.inviteeFirstName?.trim() || "there";
  const inviterName = ctx.inviterName.trim();
  const householdName = ctx.householdName?.trim() || "their household";
  const address = ctx.householdAddress?.trim();
  const personalMessage = ctx.personalMessage?.trim();
  const code = formatCode(ctx.inviteCode);

  const lines = [
    `Hi ${inviteeName},`,
    "",
    `A quick reminder: ${inviterName} invited you to join ${householdName} on Haven.`,
  ];
  if (address) {
    lines.push("");
    lines.push(address);
  }
  if (personalMessage) {
    lines.push("");
    lines.push(`"${personalMessage}"`);
  }
  lines.push("");
  lines.push(`Open in Haven: ${ctx.inviteUrl}`);
  lines.push("");
  lines.push(`Or enter code: ${code}`);
  lines.push("");
  lines.push("This invite expires in 30 days. If you don't want to join, just ignore this email.");
  lines.push("");
  lines.push("Haven Home, havenhome.dev");
  return lines.join("\n");
}

async function loadInvitationContext(supabase: any, invitationId: string): Promise<EmailContext | { error: string; status: number }> {
  const { data: invitation, error } = await supabase
    .from("household_invitations")
    .select("id, household_id, invited_by, invited_email, invite_code, status, expires_at, personal_message, family_member_id")
    .eq("id", invitationId)
    .maybeSingle();
  if (error) {
    console.error("[resend-household-invite] Lookup error:", error);
    return { error: "Failed to look up invitation", status: 500 };
  }
  if (!invitation) {
    return { error: "Invitation not found", status: 404 };
  }
  if (invitation.status !== "pending") {
    return { error: `Cannot resend invitation in status ${invitation.status}`, status: 409 };
  }
  if (invitation.expires_at && new Date(invitation.expires_at).getTime() < Date.now()) {
    return { error: "Invitation has expired", status: 410 };
  }

  const [{ data: inviter }, { data: household }, { data: properties }, { data: systems }, { data: tasks }, { data: members }, { data: familyMember }] = await Promise.all([
    supabase.from("users").select("id, full_name").eq("id", invitation.invited_by).maybeSingle(),
    supabase.from("households").select("id, name").eq("id", invitation.household_id).maybeSingle(),
    supabase.from("properties").select("id, street, city, state").eq("household_id", invitation.household_id),
    supabase.from("home_systems").select("id").eq("household_id", invitation.household_id),
    supabase.from("maintenance_tasks").select("id").eq("household_id", invitation.household_id),
    supabase.from("family_members").select("id").eq("household_id", invitation.household_id),
    invitation.family_member_id
      ? supabase.from("family_members").select("first_name").eq("id", invitation.family_member_id).maybeSingle()
      : Promise.resolve({ data: null }),
  ]);

  const primaryProperty =
    (properties || []).find((p: { street?: string | null }) => (p.street || "").length > 0) ||
    (properties || [])[0] ||
    null;
  const householdAddress = primaryProperty
    ? [primaryProperty.street, primaryProperty.city, primaryProperty.state]
        .filter((part: unknown) => typeof part === "string" && (part as string).length > 0)
        .join(", ")
    : null;

  return {
    to: invitation.invited_email,
    inviteCode: invitation.invite_code,
    inviteUrl: `https://havenhome.dev/join/${invitation.invite_code}`,
    inviterName: inviter?.full_name ?? "Someone on Haven",
    householdName: household?.name ?? null,
    householdAddress: householdAddress,
    systemCount: (systems || []).length,
    taskCount: (tasks || []).length,
    memberCount: (members || []).length,
    personalMessage: invitation.personal_message ?? null,
    inviteeFirstName: familyMember?.first_name ?? null,
  };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const headers = { ...corsHeaders, "Content-Type": "application/json" };

  try {
    const sendgridKey = Deno.env.get("SENDGRID_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!sendgridKey || !supabaseUrl || !serviceRoleKey) {
      console.error("[resend-household-invite] Required env not configured");
      return new Response(JSON.stringify({ error: "Server misconfigured" }), { status: 503, headers });
    }

    const body = (await req.json()) as ResendRequest;
    if (!body?.invitation_id) {
      return new Response(JSON.stringify({ error: "Missing invitation_id" }), { status: 400, headers });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const ctxOrError = await loadInvitationContext(supabase, body.invitation_id);
    if ("error" in ctxOrError) {
      return new Response(JSON.stringify({ error: ctxOrError.error }), { status: ctxOrError.status, headers });
    }
    const ctx = ctxOrError;

    const subject = `${ctx.inviterName.split(/\s+/)[0]} is still waiting on Haven`;

    const sendgridBody = {
      personalizations: [
        {
          to: [{ email: ctx.to, name: ctx.inviteeFirstName || undefined }],
          subject,
        },
      ],
      from: { email: FROM_EMAIL, name: FROM_NAME },
      reply_to: { email: REPLY_TO_EMAIL, name: "Tom Burke" },
      content: [
        { type: "text/plain", value: buildText(ctx) },
        { type: "text/html", value: buildHtml(ctx) },
      ],
      categories: ["household_invite", "household_invite_resend"],
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
      console.error(`[resend-household-invite] SendGrid ${sendgridResponse.status}: ${errText}`);
      return new Response(
        JSON.stringify({ error: "SendGrid rejected the request", detail: errText.slice(0, 500) }),
        { status: 502, headers }
      );
    }

    // Stamp the row so the cron and the iOS cooldown can both observe it.
    await supabase
      .from("household_invitations")
      .update({
        reminder_sent_at: new Date().toISOString(),
        reminder_count: 0, // manual resends reset the cron's automatic counter
      })
      .eq("id", body.invitation_id);

    return new Response(
      JSON.stringify({ sent: true, invitation_id: body.invitation_id }),
      { status: 200, headers }
    );
  } catch (error) {
    console.error("[resend-household-invite] Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers }
    );
  }
});
