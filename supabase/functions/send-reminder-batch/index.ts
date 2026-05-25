// Haven Edge Function: send-reminder-batch
//
// Daily cron-driven reminder batch for pending household invitations. Fires
// reminder emails on the 24h, 3-day, and 7-day marks (relative to the
// invitation's created_at timestamp), and marks invitations expired once
// they pass their expires_at deadline.
//
// Triggered by pg_cron at 10:00 UTC daily (see migration
// 20260419_invite_reminder_cron.sql).
//
// The function is idempotent — running it multiple times in a window will
// not double-send because each row has a `reminder_count` and we use the
// monotonically increasing milestone index to decide whether the next
// reminder is due.
//
// Required Supabase secrets:
//   SENDGRID_API_KEY -- API key with mail.send scope
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY -- standard

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const FROM_EMAIL = "hello@getchez.com";
const FROM_NAME = "Chez";
const REPLY_TO_EMAIL = "tom@getchez.com";

// Reminder thresholds: 24h, 3 days, 7 days (in milliseconds).
const REMINDER_INTERVALS_MS = [
  24 * 60 * 60 * 1000,
  3 * 24 * 60 * 60 * 1000,
  7 * 24 * 60 * 60 * 1000,
];

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

interface ReminderContext {
  invitationId: string;
  to: string;
  inviteCode: string;
  inviteUrl: string;
  inviterName: string;
  householdName: string | null;
  householdAddress: string | null;
  personalMessage: string | null;
  inviteeFirstName: string | null;
  reminderIndex: number; // 0 = 24h, 1 = 3d, 2 = 7d
}

function reminderCopy(index: number): { subjectSuffix: string; intro: string } {
  switch (index) {
    case 0:
      return {
        subjectSuffix: "is still waiting on Chez",
        intro: "A quick reminder: your invitation is still active.",
      };
    case 1:
      return {
        subjectSuffix: "your Chez invite is still open",
        intro: "Just a friendly nudge — your invitation is still waiting.",
      };
    default:
      return {
        subjectSuffix: "last chance to join Chez",
        intro: "This is the last reminder we'll send. Your invitation is still open.",
      };
  }
}

function buildHtml(ctx: ReminderContext, intro: string): string {
  const inviteeName = ctx.inviteeFirstName?.trim() || "there";
  const householdName = ctx.householdName?.trim() || "their household";
  const code = formatCode(ctx.inviteCode);
  const personalBlock = ctx.personalMessage
    ? `<tr><td style="padding-top:24px;font-family:Georgia,serif;font-style:italic;font-size:15px;color:#0A0A0A;">"${escapeHtml(ctx.personalMessage)}"</td></tr>`
    : "";

  return `<!doctype html>
<html>
  <body style="margin:0;padding:0;background:#FAF7F1;font-family:Georgia,serif;color:#0A0A0A;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FAF7F1;">
      <tr>
        <td align="center" style="padding:48px 16px;">
          <table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px;background:#FFFFFF;border-radius:16px;border:1px solid #EDEEF0;">
            <tr><td style="padding:32px 32px 8px 32px;text-align:center;"><img src="https://getchez.com/chez-icon-on-purple-180.png" alt="" width="56" height="56" style="display:inline-block;border-radius:13px;margin-bottom:10px;" /><div style="font-family:Georgia,'New York',serif;font-size:28px;font-weight:bold;color:#6938EF;letter-spacing:0.5px;">Chez</div></td></tr>
            <tr><td style="padding:24px 32px 0 32px;font-family:Georgia,serif;font-size:18px;color:#0A0A0A;">Hi ${escapeHtml(inviteeName)},</td></tr>
            <tr><td style="padding:16px 32px 0 32px;font-family:Georgia,serif;font-size:15px;line-height:1.55;color:#0A0A0A;">${escapeHtml(intro)} ${escapeHtml(ctx.inviterName)} invited you to join <strong>${escapeHtml(householdName)}</strong> on Chez.</td></tr>
            ${ctx.householdAddress ? `<tr><td style="padding:24px 32px 0 32px;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F4F0FE;border:1px solid #EFEAFE;border-radius:12px;"><tr><td style="padding:16px 20px;font-family:Georgia,serif;font-size:14px;color:#0A0A0A;">${escapeHtml(ctx.householdAddress)}</td></tr></table></td></tr>` : ""}
            ${personalBlock ? `<tr><td style="padding:0 32px;">${personalBlock}</td></tr>` : ""}
            <tr><td style="padding:32px 32px 0 32px;text-align:center;"><a href="${escapeHtml(ctx.inviteUrl)}" style="display:inline-block;padding:14px 28px;background:#6938EF;color:#FFFFFF;text-decoration:none;border-radius:14px;font-family:-apple-system,BlinkMacSystemFont,'SF Pro',Helvetica,Arial,sans-serif;font-size:15px;font-weight:600;">Open in Chez</a></td></tr>
            <tr><td style="padding:24px 32px 0 32px;text-align:center;font-family:-apple-system,BlinkMacSystemFont,'SF Pro',Helvetica,Arial,sans-serif;font-size:13px;color:#6B6B7B;">Or enter this code in the app:</td></tr>
            <tr><td style="padding:8px 32px 0 32px;text-align:center;font-family:'SF Mono',Menlo,Monaco,monospace;font-size:24px;font-weight:bold;letter-spacing:4px;color:#6938EF;">${escapeHtml(code)}</td></tr>
            <tr><td style="padding:32px 32px 0 32px;font-family:-apple-system,BlinkMacSystemFont,'SF Pro',Helvetica,Arial,sans-serif;font-size:12px;line-height:1.6;color:#6B6B7B;text-align:center;">If you don't want to join, just ignore this email.</td></tr>
            <tr><td style="padding:24px 32px 32px 32px;text-align:center;font-family:-apple-system,BlinkMacSystemFont,'SF Pro',Helvetica,Arial,sans-serif;font-size:11px;color:#A1A1AC;">Chez · getchez.com</td></tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

function buildText(ctx: ReminderContext, intro: string): string {
  const inviteeName = ctx.inviteeFirstName?.trim() || "there";
  const householdName = ctx.householdName?.trim() || "their household";
  const code = formatCode(ctx.inviteCode);
  const lines = [
    `Hi ${inviteeName},`,
    "",
    `${intro} ${ctx.inviterName} invited you to join ${householdName} on Chez.`,
  ];
  if (ctx.householdAddress) {
    lines.push("");
    lines.push(ctx.householdAddress);
  }
  if (ctx.personalMessage) {
    lines.push("");
    lines.push(`"${ctx.personalMessage}"`);
  }
  lines.push("");
  lines.push(`Open in Chez: ${ctx.inviteUrl}`);
  lines.push("");
  lines.push(`Or enter code: ${code}`);
  lines.push("");
  lines.push("Chez, getchez.com");
  return lines.join("\n");
}

async function sendReminder(
  sendgridKey: string,
  ctx: ReminderContext,
): Promise<{ ok: boolean; status?: number; error?: string }> {
  const { subjectSuffix, intro } = reminderCopy(ctx.reminderIndex);
  const subject = `${ctx.inviterName.split(/\s+/)[0]} ${subjectSuffix}`;
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
      { type: "text/plain", value: buildText(ctx, intro) },
      { type: "text/html", value: buildHtml(ctx, intro) },
    ],
    categories: ["household_invite", "household_invite_reminder"],
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
    return { ok: false, status: sendgridResponse.status, error: errText.slice(0, 500) };
  }
  return { ok: true };
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
      console.error("[send-reminder-batch] Required env not configured");
      return new Response(JSON.stringify({ error: "Server misconfigured" }), { status: 503, headers });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Step 1 — expire any pending invitations whose expires_at has passed.
    const { data: expired, error: expireError } = await supabase
      .from("household_invitations")
      .update({ status: "expired" })
      .eq("status", "pending")
      .lt("expires_at", new Date().toISOString())
      .select("id");
    if (expireError) {
      console.error("[send-reminder-batch] Expire pass error:", expireError);
    }
    const expiredCount = expired?.length ?? 0;

    // Step 2 — find pending invitations whose age has crossed the next reminder
    // milestone they have not yet hit.
    const now = Date.now();
    const { data: pending, error: pendingError } = await supabase
      .from("household_invitations")
      .select("id, household_id, invited_by, invited_email, invite_code, status, expires_at, personal_message, family_member_id, created_at, reminder_count")
      .eq("status", "pending");
    if (pendingError) {
      console.error("[send-reminder-batch] Pending fetch error:", pendingError);
      return new Response(JSON.stringify({ error: "Failed to load pending invitations" }), { status: 500, headers });
    }

    const candidates = (pending || []).filter((row: any) => {
      const created = row.created_at ? new Date(row.created_at).getTime() : null;
      if (!created) return false;
      const age = now - created;
      const reminderCount = row.reminder_count ?? 0;
      if (reminderCount >= REMINDER_INTERVALS_MS.length) return false;
      const nextThreshold = REMINDER_INTERVALS_MS[reminderCount];
      return age >= nextThreshold;
    });

    if (candidates.length === 0) {
      return new Response(
        JSON.stringify({
          ok: true,
          expired: expiredCount,
          considered: pending?.length ?? 0,
          sent: 0,
          message: "No reminders due",
        }),
        { status: 200, headers },
      );
    }

    let sentCount = 0;
    let failedCount = 0;
    const failures: Array<{ id: string; error: string }> = [];

    for (const row of candidates) {
      // Hydrate the email payload from the household + inviter + counts.
      const [{ data: inviter }, { data: household }, { data: properties }, { data: familyMember }] = await Promise.all([
        supabase.from("users").select("id, full_name").eq("id", row.invited_by).maybeSingle(),
        supabase.from("households").select("id, name").eq("id", row.household_id).maybeSingle(),
        supabase.from("properties").select("street, city, state").eq("household_id", row.household_id),
        row.family_member_id
          ? supabase.from("family_members").select("first_name").eq("id", row.family_member_id).maybeSingle()
          : Promise.resolve({ data: null }),
      ]);

      const primaryProperty =
        (properties || []).find((p: any) => (p.street || "").length > 0) || (properties || [])[0] || null;
      const householdAddress = primaryProperty
        ? [primaryProperty.street, primaryProperty.city, primaryProperty.state]
            .filter((part: unknown) => typeof part === "string" && (part as string).length > 0)
            .join(", ")
        : null;

      const ctx: ReminderContext = {
        invitationId: row.id,
        to: row.invited_email,
        inviteCode: row.invite_code,
        inviteUrl: `https://getchez.com/join/${row.invite_code}`,
        inviterName: inviter?.full_name ?? "Someone on Chez",
        householdName: household?.name ?? null,
        householdAddress,
        personalMessage: row.personal_message ?? null,
        inviteeFirstName: familyMember?.first_name ?? null,
        reminderIndex: row.reminder_count ?? 0,
      };

      const result = await sendReminder(sendgridKey, ctx);
      if (result.ok) {
        sentCount++;
        await supabase
          .from("household_invitations")
          .update({
            reminder_sent_at: new Date().toISOString(),
            reminder_count: (row.reminder_count ?? 0) + 1,
          })
          .eq("id", row.id);
      } else {
        failedCount++;
        failures.push({ id: row.id, error: result.error ?? "unknown" });
        console.error(`[send-reminder-batch] Send failed for ${row.id}: ${result.error}`);
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        expired: expiredCount,
        considered: pending?.length ?? 0,
        candidates: candidates.length,
        sent: sentCount,
        failed: failedCount,
        failures: failures.length > 0 ? failures : undefined,
      }),
      { status: 200, headers },
    );
  } catch (error) {
    console.error("[send-reminder-batch] Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers },
    );
  }
});
