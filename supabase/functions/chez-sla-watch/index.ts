// chez-sla-watch — Phase 100 part F.
//
// Cron-invoked (pg_cron every 15 minutes, see migration
// 20270108_chez_crons.sql). Watches open chez_requests against their
// business-hours SLA (chez_business_hours_due computed sla_due_at at
// submit time) and notifies the operator twice per open cycle:
//
//   WARN   — case is open, due within the at-risk window (4h), not yet
//            warned. Skipped on weekends: the SLA clock itself skips
//            weekends, so a Saturday warning would be noise.
//   BREACH — case is open, past due, not yet notified.
//
// Concurrency-safe idempotency: each bucket stamps its column FIRST
// with an .is(column, null) guard, then notifies only the rows the
// stamp actually claimed. A second cron tick (or an overlapping run)
// matches zero rows. handleTransition in chez-concierge clears both
// stamps whenever a case re-enters "open" so reopened cases get fresh
// attention.
//
// Every user-facing string says "Chez" — this function only talks to
// the operator (push + SendGrid backstop), never the homeowner.
//
// Deploy: supabase functions deploy chez-sla-watch --no-verify-jwt

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

type ServiceClient = SupabaseClient;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const FROM_EMAIL = "alfred@getchez.com";
const FROM_NAME = "Chez";
const AT_RISK_WINDOW_MS = 4 * 60 * 60 * 1000;
const BUCKET_CAP = 20;

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function adminEmails(): string[] {
  return (Deno.env.get("CHEZ_ADMIN_EMAILS") ?? "tom@getchez.com")
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
}

function adminUserIds(): string[] {
  return (Deno.env.get("CHEZ_ADMIN_USER_IDS") ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

function operatorPortalUrl(requestId: string): string {
  const explicit = Deno.env.get("OPERATOR_PORTAL_URL");
  if (explicit) {
    return `${explicit.replace(/\/+$/, "")}/?case=${requestId}`;
  }
  return `https://getchez.com/service.html?case=${requestId}`;
}

async function sendPush(
  serviceUrl: string,
  serviceRoleKey: string,
  recipientUserIds: string[],
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  if (recipientUserIds.length === 0) return;
  try {
    const resp = await fetch(`${serviceUrl}/functions/v1/send-push-notification`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ recipient_user_ids: recipientUserIds, title, body, data }),
    });
    if (!resp.ok) {
      console.error("[chez-sla-watch] push failed:", resp.status, await resp.text());
    }
  } catch (error) {
    console.error("[chez-sla-watch] push error:", error);
  }
}

async function sendAdminEmail(subject: string, bodyText: string): Promise<void> {
  const apiKey = Deno.env.get("SENDGRID_API_KEY");
  const to = adminEmails();
  if (!apiKey || to.length === 0) {
    console.warn("[chez-sla-watch] sendgrid not configured or no recipients");
    return;
  }
  try {
    const resp = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        personalizations: [{ to: to.map((email) => ({ email })) }],
        from: { email: FROM_EMAIL, name: FROM_NAME },
        subject,
        content: [{ type: "text/plain", value: bodyText }],
      }),
    });
    if (!resp.ok) {
      console.error("[chez-sla-watch] sendgrid failed:", resp.status, await resp.text());
    }
  } catch (error) {
    console.error("[chez-sla-watch] sendgrid error:", error);
  }
}

interface SlaCaseRow {
  id: string;
  household_id: string;
  summary: string | null;
  category: string | null;
  sla_due_at: string;
}

/// Stamp-first claim: update the idempotency column on rows matching the
/// bucket criteria and return only the rows this run actually claimed.
async function claimBucket(
  service: ServiceClient,
  mode: "warn" | "breach",
  nowIso: string,
  riskHorizonIso: string
): Promise<SlaCaseRow[]> {
  const stampColumn = mode === "warn" ? "sla_warned_at" : "sla_breach_notified_at";
  // Find candidates first (cheap, indexed by idx_chez_requests_sla_watch).
  const base = service
    .from("chez_requests")
    .select("id, household_id, summary, category, sla_due_at")
    .eq("status", "open")
    .is(stampColumn, null)
    .not("sla_due_at", "is", null)
    .order("sla_due_at", { ascending: true })
    .limit(BUCKET_CAP);
  const query = mode === "warn"
    ? base.gte("sla_due_at", nowIso).lte("sla_due_at", riskHorizonIso)
    : base.lt("sla_due_at", nowIso);
  const { data: candidates, error } = await query;
  if (error) {
    console.error(`[chez-sla-watch] ${stampColumn} candidate query failed:`, error.message);
    return [];
  }
  const rows = (candidates ?? []) as SlaCaseRow[];
  if (rows.length === 0) return [];

  // Claim each row individually with the .is() guard so a concurrent run
  // can never double-send for the same case.
  const claimed: SlaCaseRow[] = [];
  for (const row of rows) {
    const { data: updated, error: updateErr } = await service
      .from("chez_requests")
      .update({ [stampColumn]: nowIso })
      .eq("id", row.id)
      .eq("status", "open")
      .is(stampColumn, null)
      .select("id");
    if (updateErr) {
      console.warn(`[chez-sla-watch] stamp failed for ${row.id}:`, updateErr.message);
      continue;
    }
    if ((updated ?? []).length > 0) claimed.push(row);
  }
  return claimed;
}

function shortSummary(row: SlaCaseRow): string {
  const s = (row.summary ?? "").trim() || (row.category ?? "request");
  return s.length > 90 ? `${s.slice(0, 87)}...` : s;
}

function minutesUntil(iso: string, now: number): number {
  return Math.round((new Date(iso).getTime() - now) / 60000);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const serviceUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const service = createClient(serviceUrl, serviceRoleKey, {
    auth: { persistSession: false },
  }) as ServiceClient;

  const now = Date.now();
  const nowIso = new Date(now).toISOString();
  const riskHorizonIso = new Date(now + AT_RISK_WINDOW_MS).toISOString();

  // Weekend guard for the WARN bucket only (Eastern). The SLA clock skips
  // weekends, so warning on a Saturday about a Monday-due case is noise.
  // Breaches still notify any day: a breached case is late, full stop.
  const easternDay = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/New_York",
    weekday: "short",
  }).format(new Date(now));
  const isWeekend = easternDay === "Sat" || easternDay === "Sun";

  let warned: SlaCaseRow[] = [];
  if (!isWeekend) {
    warned = await claimBucket(service, "warn", nowIso, riskHorizonIso);
  }

  const breached = await claimBucket(service, "breach", nowIso, riskHorizonIso);

  const adminIds = adminUserIds();
  for (const row of warned) {
    const mins = minutesUntil(row.sla_due_at, now);
    const title = "SLA at risk";
    const body = `${shortSummary(row)} is due in about ${mins} min.`;
    await sendPush(serviceUrl, serviceRoleKey, adminIds, title, body, {
      type: "chez_admin_request",
      request_id: row.id,
    });
    await sendAdminEmail(
      `[Chez] SLA at risk: ${shortSummary(row)}`,
      `This case is due in about ${mins} minutes.\n\nOpen it: ${operatorPortalUrl(row.id)}`
    );
  }

  for (const row of breached) {
    const title = "SLA breached";
    const body = `${shortSummary(row)} is past its response window.`;
    await sendPush(serviceUrl, serviceRoleKey, adminIds, title, body, {
      type: "chez_admin_request",
      request_id: row.id,
    });
    await sendAdminEmail(
      `[Chez] SLA breached: ${shortSummary(row)}`,
      `This case is past its response window.\n\nOpen it: ${operatorPortalUrl(row.id)}`
    );
  }

  console.log(`[chez-sla-watch] warned=${warned.length} breached=${breached.length} weekend=${isWeekend}`);
  return json({ ok: true, warned: warned.length, breached: breached.length, weekend: isWeekend });
});
