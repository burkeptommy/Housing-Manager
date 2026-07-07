// Chez Concierge Edge Function (Phase 80 → 100).
//
// Single function with an `action` discriminator. The dispatcher switch in
// the server entry at the bottom of this file is the canonical action
// inventory (48+ actions) — do not trust any hand-maintained list here.
// Major groups:
//   - Thread lifecycle: submit / reply / mark_read / transition_status
//     (transition_status accepts an optional structured `outcome` payload
//     on resolve — Phase 100)
//   - Profile + delegation: fetch/update_profile, delegate_routine /
//     _contractor / _task / _entity, set_ownership_group, propose /
//     decide_proposal / propose_ownership
//   - Operator cockpit: fetch_dossier, analyze_request (playbook-shared
//     core with per-category modes), suggest_vendor_framing, ask_alfred,
//     fetch_visits / update_visit, workbench_action, fetch_today_brief,
//     fetch_households_list / fetch_household_workbench, fetch_upcoming,
//     admin_submit, snippets / tags / assign / merge / link
//   - Home assessments: request / cancel / reschedule / review /
//     corrections / pre-visit / fetch / assign_handyman
//   - Phase 100 intelligence foundation: save_vendor_calls /
//     fetch_vendor_calls (persisted call ledger), record_outcome,
//     fetch_vendor_registry (cross-household vendor intelligence),
//     fetch_ops_metrics, log_operator_event
//
// Authorization:
//   - Homeowner actions require a JWT whose auth.uid() owns the request.
//   - Admin actions require a JWT whose verified email is in CHEZ_ADMIN_EMAILS.
//
// Side effects (the load-bearing ones):
//   - submit              → push + email to admin (Tom). SendGrid is the
//                           backstop because Tom doesn't have the iOS app
//                           installed, so push alone is not enough. Also
//                           fires the category playbook (pre-warmed
//                           analysis brief for every category — Phase 100).
//   - admin reply         → creates an inbox_items row in the homeowner's
//                           household (type chez_reply_action_needed when
//                           acknowledgement_required, else chez_reply_informational)
//                           + push to homeowner.
//   - homeowner reply     → push + email to admin.
//   - transition_status   → push to other party + (resolved) inbox_items row
//                           informing the homeowner it's done. Reopening
//                           clears the SLA watcher stamps (chez-sla-watch).
//
// Required Supabase secrets:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY  (standard)
//   CHEZ_ADMIN_EMAILS       — comma-separated list (e.g. "tom@getchez.com")
//   CHEZ_ADMIN_USER_IDS     — comma-separated UUIDs (recipients for iOS push)
//   SENDGRID_API_KEY        — for emailing Tom on new requests / replies
//   OPERATOR_PORTAL_URL     — defaults to https://service.getchez.com
//                             (operator workspace for handling live homeowner
//                             requests; admin.getchez.com is back-of-house
//                             content/templates only.) `ADMIN_PORTAL_URL` is
//                             still read as a fallback so existing deployments
//                             keep working until the Vercel env var is renamed.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { callClaudeWithDiscipline } from "../_shared/ai-cost-discipline.ts";
import {
  attachSnapshotToRequest,
  buildDelegationSnapshot,
  inferSnapshotKindFromContext,
  isSnapshotKind,
  SnapshotAuthError,
  snapshotDigest,
  snapshotReadiness,
  suggestedBudgetFor,
  type DelegationSnapshot,
  type SnapshotKind,
} from "./snapshot.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const FROM_EMAIL = "hello@getchez.com";
const FROM_NAME = "Chez Concierge";

type ServiceClient = ReturnType<typeof createClient>;

interface ConciergeRequestRow {
  id: string;
  household_id: string;
  user_id: string;
  category: string;
  summary: string;
  context: Record<string, unknown>;
  status: "open" | "waiting_customer" | "resolved";
  sla_due_at: string;
  last_message_at: string;
  unread_for_user: boolean;
  unread_for_admin: boolean;
  resolved_at: string | null;
  created_at: string;
  updated_at: string;
  /// Phase 80.1 — denormalized counter of proposals still awaiting the
  /// homeowner's decision. Maintained by `propose` / `decide_proposal`.
  pending_proposal_count?: number;
}

interface AttachmentMeta {
  path: string;
  filename: string;
  mime_type: string;
  size_bytes: number;
  uploaded_at: string;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function compactString(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function escapeHtml(value: unknown) {
  return compactString(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
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

async function getAuthenticatedUser(service: ServiceClient, req: Request) {
  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice("Bearer ".length) : "";
  if (!token) return null;
  const { data, error } = await service.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}

function isAdminUser(user: { email?: string | null } | null): boolean {
  if (!user?.email) return false;
  return adminEmails().includes(user.email.toLowerCase());
}

async function householdIdForUser(
  service: ServiceClient,
  userId: string
): Promise<string | null> {
  const { data, error } = await service
    .from("users")
    .select("household_id")
    .eq("id", userId)
    .maybeSingle();
  if (error || !data) return null;
  return (data as { household_id: string | null }).household_id ?? null;
}

// Phase 85.5: admin operators don't have a household_id on their user row
// — they delegate / update entities on behalf of a homeowner via the admin
// workbench. This helper returns the explicit `household_id` from the
// payload when the caller is an admin, otherwise falls back to the user's
// own household_id. Homeowners cannot override via payload (so they can't
// touch a household that isn't theirs).
async function resolveHouseholdId(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payloadHouseholdId: unknown
): Promise<string | null> {
  if (!user) return null;
  if (isAdminUser(user)) {
    const explicit = compactString((payloadHouseholdId as string | undefined) || "");
    if (explicit) return explicit;
  }
  return householdIdForUser(service, user.id);
}

// ============================================================================
// Push + email helpers
// ============================================================================

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
      body: JSON.stringify({
        recipient_user_ids: recipientUserIds,
        title,
        body,
        data,
      }),
    });
    if (!resp.ok) {
      console.error("[chez-concierge] push failed:", resp.status, await resp.text());
    }
  } catch (error) {
    console.error("[chez-concierge] push error:", error);
  }
}

async function sendAdminEmail(
  to: string[],
  subject: string,
  bodyText: string,
  bodyHtml: string
): Promise<void> {
  const apiKey = Deno.env.get("SENDGRID_API_KEY");
  if (!apiKey || to.length === 0) {
    console.warn("[chez-concierge] sendgrid not configured or no recipients");
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
        content: [
          { type: "text/plain", value: bodyText },
          { type: "text/html", value: bodyHtml },
        ],
      }),
    });
    if (!resp.ok) {
      console.error("[chez-concierge] sendgrid failed:", resp.status, await resp.text());
    }
  } catch (error) {
    console.error("[chez-concierge] sendgrid error:", error);
  }
}

/// Returns the operator-portal deep-link for a chez_requests row.
/// Phase X (May 2026) — every admin push payload + every SendGrid
/// email backstop now lands on the operator workspace focused on
/// serving home requests. admin.getchez.com stays for back-of-house
/// content/templates (Quiz Builder, Task Templates, Routines,
/// Systems). The legacy `adminPortalUrl` name is preserved here so
/// the 19+ callers don't need to be touched in the same diff.
///
/// URL resolution precedence:
///   1. OPERATOR_PORTAL_URL secret (set once DNS for
///      service.getchez.com is configured; format
///      "https://service.getchez.com" → produces "/?case={id}")
///   2. Default → `https://getchez.com/service.html?case={id}` so
///      links work today, on the existing getchez.com domain, the
///      moment the website redeploys with service.html in place.
///
/// We intentionally DO NOT fall back to ADMIN_PORTAL_URL anymore.
/// Old deployments may still have it set pointing at
/// `https://admin.getchez.com`, which would produce a broken URL
/// under the new `/?case={id}` path (admin's root serves admin.html,
/// not a case query handler). Default-to-getchez-interim is safer.
function adminPortalUrl(requestId: string): string {
  const explicit = Deno.env.get("OPERATOR_PORTAL_URL");
  if (explicit) {
    return `${explicit.replace(/\/+$/, "")}/?case=${requestId}`;
  }
  return `https://getchez.com/service.html?case=${requestId}`;
}

function emailBody(args: {
  preview: string;
  heading: string;
  intro: string;
  bodyText: string;
  ctaLabel: string;
  ctaUrl: string;
}): string {
  return `
<!doctype html>
<html lang="en">
  <body style="margin:0;padding:24px;background:#FAFAFC;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#0A0A0A;">
    <span style="display:none;">${escapeHtml(args.preview)}</span>
    <div style="max-width:560px;margin:0 auto;background:#FFFFFF;border-radius:14px;padding:28px;border:1px solid #EDEEF0;">
      <div style="text-align:center;margin:0 0 20px;">
        <img src="https://getchez.com/chez-icon-on-purple-180.png" alt="Chez" width="56" height="56" style="display:inline-block;border-radius:13px;" />
      </div>
      <h1 style="font-family:Georgia,'New York',serif;font-size:22px;margin:0 0 8px;color:#0A0A0A;font-weight:600;">${escapeHtml(args.heading)}</h1>
      <p style="font-size:14px;line-height:1.5;margin:0 0 16px;color:#0A0A0A;">${escapeHtml(args.intro)}</p>
      <pre style="background:#FAFAFC;border:1px solid #EDEEF0;border-radius:10px;padding:12px;font-family:-apple-system,sans-serif;white-space:pre-wrap;font-size:13px;color:#6B6B7B;margin:0;">${escapeHtml(args.bodyText)}</pre>
      <p style="margin:18px 0 0;">
        <a href="${escapeHtml(args.ctaUrl)}" style="background:#6938EF;color:#fff;padding:10px 18px;border-radius:10px;text-decoration:none;font-weight:600;font-size:14px;">${escapeHtml(args.ctaLabel)}</a>
      </p>
    </div>
  </body>
</html>`;
}

// ============================================================================
// Action: submit
// ============================================================================

interface SubmitPayload {
  category: string;
  summary: string;
  description: string;
  context?: Record<string, unknown>;
  attachments?: AttachmentMeta[];
}

async function handleSubmit(
  service: ServiceClient,
  user: { id: string; email?: string | null },
  payload: SubmitPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "No household for user" }, 400);

  const summary = compactString(payload.summary);
  const description = compactString(payload.description);
  const category = compactString(payload.category) || "general";
  if (!summary || !description) {
    return json({ error: "summary and description required" }, 400);
  }

  // Compute SLA via the SQL helper.
  const { data: slaRow, error: slaErr } = await service
    .rpc("chez_business_hours_due", { start_at: new Date().toISOString() });
  if (slaErr) {
    console.error("[chez-concierge] sla rpc failed:", slaErr);
  }
  const sla_due_at =
    typeof slaRow === "string"
      ? slaRow
      : new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  // Insert request.
  const { data: request, error: reqErr } = await service
    .from("chez_requests")
    .insert({
      household_id: householdId,
      user_id: user.id,
      category,
      summary,
      context: payload.context || {},
      status: "open",
      sla_due_at,
      last_message_at: new Date().toISOString(),
      unread_for_user: false,
      unread_for_admin: true,
    })
    .select("*")
    .single();
  if (reqErr || !request) {
    console.error("[chez-concierge] submit insert failed:", reqErr);
    return json({ error: "Failed to create request" }, 500);
  }

  // Insert first message (the homeowner's description).
  const { error: msgErr } = await service.from("concierge_messages").insert({
    household_id: householdId,
    user_id: user.id,
    request_id: (request as ConciergeRequestRow).id,
    role: "user",
    content: description,
    attachments: payload.attachments || [],
  });
  if (msgErr) {
    console.error("[chez-concierge] submit message failed:", msgErr);
  }

  // Wave 1 — server-assembled delegation snapshot. iOS entry points pass
  // entity ids in `context`; the server assembles the full household
  // truth (system details, warranties, service history, cost references)
  // so the operator and the AI brief act without follow-up questions.
  // Best-effort: a snapshot failure never sinks the submit. Runs BEFORE
  // the playbook so runAnalysisCore sees the attached snapshot.
  const requestId = (request as ConciergeRequestRow).id;
  let submitDigest = "";
  try {
    const inferred = inferSnapshotKindFromContext(
      (payload.context ?? {}) as Record<string, unknown>
    );
    const snapshot = await buildDelegationSnapshot(service, {
      kind: inferred?.kind ?? "general",
      entityId: inferred?.entityId,
      householdId,
      propertyId: inferred?.propertyId,
    });
    if (snapshot) {
      await attachSnapshotToRequest(service, requestId, snapshot);
      submitDigest = snapshotDigest(snapshot);
    }
  } catch (e) {
    console.warn("[snapshot] submit build failed:", e);
  }

  // Phase 86D — kick off the category playbook. Each playbook drops a
  // first-touch system message in the thread ("Chez is on it…") and
  // optionally fires server-side work (AI research, follow-up reminders).
  // Best-effort: failure here doesn't sink the submit. Runs in parallel
  // with the admin notification fan-out below.
  const playbookPromise = runChezPlaybookForRequest({
    service,
    user,
    requestId,
    householdId,
    category,
    summary,
    description,
  }).catch((e) => console.warn("[playbook] runner failed:", e));

  // Notify admins (push + email).
  const portalUrl = adminPortalUrl(requestId);
  const emailIntro = `${user.email || "A homeowner"} just submitted a Chez request.\nCategory: ${category}\nSummary: ${summary}`;
  await Promise.all([
    sendPush(
      serviceUrl,
      serviceRoleKey,
      adminUserIds(),
      "New Chez request",
      summary,
      { type: "chez_admin_request", request_id: requestId }
    ),
    sendAdminEmail(
      adminEmails(),
      `[Chez] New ${category}: ${summary.slice(0, 60)}`,
      `${emailIntro}\n\nRequest body:\n${description}${submitDigest ? `\n\n${submitDigest}` : ""}\n\nOpen the portal:\n${portalUrl}`,
      emailBody({
        preview: `New Chez request: ${summary}`,
        heading: "New Chez request",
        intro: emailIntro,
        bodyText: submitDigest ? `${description}\n\n${submitDigest}` : description,
        ctaLabel: "Open in admin portal",
        ctaUrl: portalUrl,
      })
    ),
    playbookPromise,
  ]);

  return json({ ok: true, request });
}

// ============================================================================
// Phase 86D — Category playbooks
// ============================================================================
// When a homeowner submits a Chez request OR delegates an entity ("Have
// Chez handle this"), the category determines a small server-side
// playbook of automation:
//
//   find_vendor       → first-touch + auto analyze_request (Claude
//                       inference + Google Places candidates pre-cached
//                       so the operator opens the cockpit with the
//                       vendor brief already populated)
//   coordinate_task   → first-touch + flag the linked contractor for
//                       follow-up so Tom knows to call them
//   schedule_visit    → first-touch + propose-date hint
//   get_quote         → first-touch + suggest comparable-rate research
//   find_handyman     → first-touch + (home assessment flow runs
//                       elsewhere; this just acknowledges)
//   general           → simple first-touch
//
// The point: when the homeowner taps "Have Chez handle this", they see
// Chez acknowledge + start working IMMEDIATELY, not a 24-hour SLA-wait
// silence. The operator then opens the cockpit to find the case
// already partly worked.
// ============================================================================

interface PlaybookContext {
  service: ServiceClient;
  user: { id: string; email?: string | null };
  requestId: string;
  householdId: string;
  category: string;
  summary: string;
  description: string;
}

async function runChezPlaybookForRequest(ctx: PlaybookContext): Promise<void> {
  const { service, requestId, category } = ctx;

  // First-touch system message — always fires, regardless of category.
  // Operator can override later by replying with a more specific reply;
  // this is just so the homeowner doesn't sit in silence for 24h.
  const acknowledgement = firstTouchMessageForCategory(category, ctx.summary);
  try {
    await service.from("concierge_messages").insert({
      request_id: requestId,
      role: "system",
      content: acknowledgement,
    });
  } catch (e) {
    console.warn("[playbook] first-touch insert failed:", e);
  }

  // Category-specific playbooks.
  switch (category) {
    case "find_vendor":
      await playbookFindVendor(ctx);
      break;
    case "coordinate_task":
      await playbookCoordinateTask(ctx);
      break;
    case "schedule_visit":
      await playbookScheduleVisit(ctx);
      break;
    case "get_quote":
      await playbookGetQuote(ctx);
      break;
    // find_handyman + general: first-touch message is enough; no extra
    // automation. Home assessment flow runs in its own path when
    // category=coordinate_task with context._kind=home_assessment_request.
  }

  // Create a follow-up reminder for the operator regardless of category.
  // 4 business hours out so the operator has time to do real work
  // before the system nudges them.
  try {
    const dueAt = new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString();
    await service.from("chez_reminders").insert({
      household_id: ctx.householdId,
      request_id: requestId,
      title: `Check progress on: ${ctx.summary.slice(0, 80)}`,
      due_at: dueAt,
    });
  } catch (e) {
    // chez_reminders may not exist on every deployment yet; non-fatal.
    console.warn("[playbook] reminder insert (non-fatal):", e);
  }
}

function firstTouchMessageForCategory(category: string, summary: string): string {
  // First-person Chez voice. Always brand-neutral ("we"), never names
  // an individual operator. Reflects the homeowner's specific ask so
  // the message doesn't read as a generic auto-reply.
  const trimSummary = summary.length > 80 ? summary.slice(0, 77) + "…" : summary;
  switch (category) {
    case "find_vendor":
      return `Chez is on it. We're sourcing options for "${trimSummary}" and will have a shortlist of vetted candidates within 24 business hours.`;
    case "get_quote":
      return `Chez is on it. We'll line up a quote for "${trimSummary}" and surface a clear cost breakdown for you to approve.`;
    case "schedule_visit":
      return `Chez is on it. We'll coordinate scheduling for "${trimSummary}" and propose times that work for your week.`;
    case "coordinate_task":
      return `Chez is on it. We're coordinating "${trimSummary}" and will keep you in the loop without taking your time.`;
    case "find_handyman":
      return `Chez is on it. We'll match you with a vetted handyman for "${trimSummary}" and arrange a free assessment.`;
    case "general":
    default:
      return `Chez is on it. We're working on "${trimSummary}" and will be back to you within 24 business hours.`;
  }
}

async function playbookFindVendor(ctx: PlaybookContext): Promise<void> {
  // Phase 86E.4 — fire the real analyze pipeline (Claude inference +
  // existing-vendor match + Places lookup + cache write) so when the
  // operator opens the cockpit the brief panel is already populated.
  // The whole pipeline is await-ed here because the parent caller
  // awaits the playbook inside a Promise.all alongside the admin push
  // + email; the submit response goes out as soon as all three
  // resolve. analyze takes 3-6s end-to-end so this adds modest latency
  // to the submit; the value is worth it (operator opens to a
  // pre-warmed brief, not a "loading…" state).
  //
  // serviceUrl falls back to the Supabase URL env var so the
  // find-local-vendors fetch can resolve.
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return; // no key → skip silently; sentinel from prior code path keeps the cache stub
  const serviceUrl = Deno.env.get("SUPABASE_URL") ?? "";
  try {
    await runAnalysisCore(ctx.service, ctx.requestId, false, serviceUrl, ctx.user.id);
  } catch (e) {
    console.warn("[playbook:find_vendor] analyze failed:", e);
  }
}

async function playbookCoordinateTask(ctx: PlaybookContext): Promise<void> {
  // Phase 100 — same pre-warmed brief as find_vendor, with the prompt
  // reframed around coordinating the homeowner's EXISTING vendor/task
  // instead of cold-sourcing. Places lookup is skipped when a matching
  // household vendor exists (runAnalysisCore handles that per-mode).
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return;
  const serviceUrl = Deno.env.get("SUPABASE_URL") ?? "";
  try {
    await runAnalysisCore(ctx.service, ctx.requestId, false, serviceUrl, ctx.user.id, "coordinate_task");
  } catch (e) {
    console.warn("[playbook:coordinate_task] analyze failed:", e);
  }
}

async function playbookScheduleVisit(ctx: PlaybookContext): Promise<void> {
  // Phase 100 — pre-warmed brief asking Claude to additionally extract
  // preferred_time_hints from the homeowner's description ("next
  // Tuesday afternoon") so the proposal builder can prefill date slots.
  // No Places lookup: scheduling implies the vendor is already known.
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return;
  const serviceUrl = Deno.env.get("SUPABASE_URL") ?? "";
  try {
    await runAnalysisCore(ctx.service, ctx.requestId, false, serviceUrl, ctx.user.id, "schedule_visit");
  } catch (e) {
    console.warn("[playbook:schedule_visit] analyze failed:", e);
  }
}

async function playbookGetQuote(ctx: PlaybookContext): Promise<void> {
  // Phase 100 — pre-warmed brief with a cost-references block (this
  // household's completed-visit costs + cross-household registry
  // averages for nearby vendors) so the operator opens the cockpit
  // with comparables and a negotiation angle already drafted.
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return;
  const serviceUrl = Deno.env.get("SUPABASE_URL") ?? "";
  try {
    await runAnalysisCore(ctx.service, ctx.requestId, false, serviceUrl, ctx.user.id, "get_quote");
  } catch (e) {
    console.warn("[playbook:get_quote] analyze failed:", e);
  }
}

// Phase 86E.4 — runChezAnalysisForRequest sentinel removed. The
// find_vendor playbook now calls runAnalysisCore directly so the cockpit
// opens with a real cached brief (Claude + Places + matched vendors),
// not a placeholder. See playbookFindVendor + handleAnalyzeRequest.

// ============================================================================
// Action: reply
// ============================================================================

interface ReplyPayload {
  request_id: string;
  content: string;
  attachments?: AttachmentMeta[];
  acknowledgement_required?: boolean;  // admin-only
  /// Phase 80 — admin-only convenience: send reply + transition status
  /// in one call. The admin portal exposes a status select directly on
  /// the reply form so Tom can mark a request "waiting on customer" or
  /// "resolved" the same instant he sends his message. Ignored for
  /// homeowner-side replies (use the dedicated `transition_status`
  /// action). Validated against the same enum as `transition_status`.
  to_status?: "open" | "waiting_customer" | "resolved";
}

async function handleReply(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: ReplyPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  const requestId = compactString(payload.request_id);
  const content = compactString(payload.content);
  if (!requestId || !content) {
    return json({ error: "request_id and content required" }, 400);
  }
  const { data: requestData, error: lookupErr } = await service
    .from("chez_requests")
    .select("*")
    .eq("id", requestId)
    .maybeSingle();
  if (lookupErr || !requestData) {
    return json({ error: "request not found" }, 404);
  }
  const request = requestData as ConciergeRequestRow;

  const isAdmin = isAdminUser(user);
  const isOwner = !!user && user.id === request.user_id;
  if (!isAdmin && !isOwner) {
    return json({ error: "not authorized" }, 403);
  }

  const role: "concierge" | "user" = isAdmin ? "concierge" : "user";
  const now = new Date().toISOString();

  const { data: message, error: msgErr } = await service
    .from("concierge_messages")
    .insert({
      household_id: request.household_id,
      user_id: isAdmin ? request.user_id : user!.id,  // anchor to homeowner for RLS
      request_id: request.id,
      role,
      content,
      attachments: payload.attachments || [],
    })
    .select("*")
    .single();
  if (msgErr || !message) {
    console.error("[chez-concierge] reply insert failed:", msgErr);
    return json({ error: "failed to insert message" }, 500);
  }

  // Update parent request flags + status side effects.
  // - Homeowner reply on a 'waiting_customer' request → bump back to 'open'
  //   so Tom sees it again (the ball is back in his court).
  // - Homeowner reply on a 'resolved' request → reopen to 'open'.
  // - Admin reply with `to_status` → honor it (one-click reply+transition
  //   from the admin portal's reply form).
  // - Admin reply without `to_status` → leave status as-is.
  let newStatus = request.status;
  if (!isAdmin && (request.status === "waiting_customer" || request.status === "resolved")) {
    newStatus = "open";
  }
  if (isAdmin && payload.to_status &&
      ["open", "waiting_customer", "resolved"].includes(payload.to_status)) {
    newStatus = payload.to_status;
  }
  // resolved_at is "now" when transitioning into resolved, preserved
  // when the request was already resolved + we're not changing it,
  // and cleared otherwise.
  const resolvedAt = newStatus === "resolved"
    ? (request.status === "resolved" ? request.resolved_at : now)
    : null;
  await service
    .from("chez_requests")
    .update({
      last_message_at: now,
      unread_for_user: isAdmin ? true : request.unread_for_user,
      unread_for_admin: isAdmin ? request.unread_for_admin : true,
      status: newStatus,
      resolved_at: resolvedAt,
    })
    .eq("id", request.id);

  // Side effects:
  if (isAdmin) {
    // 1. Create an inbox_items row so the homeowner sees the reply land in
    //    their normal Needs Action / Unread sorting.
    const ackRequired = !!payload.acknowledgement_required;
    const inboxType = ackRequired
      ? "chez_reply_action_needed"
      : "chez_reply_informational";
    const inboxTitle = ackRequired
      ? `Chez needs your answer: ${request.summary}`
      : `Chez replied: ${request.summary}`;
    await service.from("inbox_items").insert({
      household_id: request.household_id,
      type: inboxType,
      title: inboxTitle,
      summary: content.slice(0, 280),
      seen: false,
      needs_action: ackRequired,
      action_type: ackRequired ? "chez_reply_action_needed" : null,
      action_completed: false,
      metadata: {
        chez_request_id: request.id,
        message_id: (message as { id: string }).id,
        category: request.category,
      },
      related_chez_request_id: request.id,
    });

    // 2. If the admin used reply-with-status (one-click "send + mark
    //    resolved" / "send + mark waiting"), insert the same system
    //    message that `transition_status` would have. Keeps the
    //    in-thread audit trail consistent regardless of which path
    //    drove the change.
    if (newStatus !== request.status) {
      const systemBody =
        newStatus === "resolved"
          ? "Chez marked this resolved."
          : newStatus === "waiting_customer"
          ? "Chez is waiting on your answer."
          : "Chez reopened this request.";
      await service.from("concierge_messages").insert({
        household_id: request.household_id,
        user_id: request.user_id,  // anchor for RLS
        request_id: request.id,
        role: "system",
        content: systemBody,
        attachments: [],
      });
    }

    // 3. Push to homeowner.
    await sendPush(
      serviceUrl,
      serviceRoleKey,
      [request.user_id],
      ackRequired ? "Chez needs your answer" : "Chez replied",
      content.slice(0, 140),
      { type: "chez_request_reply", request_id: request.id }
    );
  } else {
    // Homeowner replied → notify admin (push + email).
    const portalUrl = adminPortalUrl(request.id);
    const homeownerLabel = user?.email || "Homeowner";
    await Promise.all([
      sendPush(
        serviceUrl,
        serviceRoleKey,
        adminUserIds(),
        "Homeowner replied on Chez request",
        `${homeownerLabel}: ${content.slice(0, 100)}`,
        { type: "chez_admin_request", request_id: request.id }
      ),
      sendAdminEmail(
        adminEmails(),
        `[Chez] Reply on: ${request.summary.slice(0, 60)}`,
        `${homeownerLabel} replied:\n\n${content}\n\nOpen the portal:\n${portalUrl}`,
        emailBody({
          preview: `Homeowner replied: ${content.slice(0, 100)}`,
          heading: "Homeowner replied",
          intro: `${homeownerLabel} replied on a Chez request.`,
          bodyText: content,
          ctaLabel: "Open in admin portal",
          ctaUrl: portalUrl,
        })
      ),
    ]);
  }

  return json({ ok: true, message });
}

// ============================================================================
// Action: mark_read
// ============================================================================

async function handleMarkRead(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { request_id: string }
) {
  const requestId = compactString(payload.request_id);
  if (!requestId) return json({ error: "request_id required" }, 400);

  const { data: request, error: lookupErr } = await service
    .from("chez_requests")
    .select("id, household_id, user_id")
    .eq("id", requestId)
    .maybeSingle();
  if (lookupErr || !request) return json({ error: "not found" }, 404);

  const isAdmin = isAdminUser(user);
  const isOwner = !!user && user.id === (request as { user_id: string }).user_id;
  if (!isAdmin && !isOwner) return json({ error: "not authorized" }, 403);

  const update: Record<string, unknown> = {};
  if (isAdmin) update.unread_for_admin = false;
  else update.unread_for_user = false;

  await service.from("chez_requests").update(update).eq("id", requestId);

  // Stamp read_at on unread messages from the OTHER party.
  if (isAdmin) {
    await service
      .from("concierge_messages")
      .update({ read_at: new Date().toISOString() })
      .eq("request_id", requestId)
      .eq("role", "user")
      .is("read_at", null);
  } else {
    await service
      .from("concierge_messages")
      .update({ read_at: new Date().toISOString() })
      .eq("request_id", requestId)
      .eq("role", "concierge")
      .is("read_at", null);
  }
  return json({ ok: true });
}

// ============================================================================
// Action: transition_status
// ============================================================================

interface TransitionPayload {
  request_id: string;
  to_status: "open" | "waiting_customer" | "resolved";
  note?: string;  // optional system message body ("Chez marked this resolved with a note")
  // Phase 100 — structured outcome captured by the cockpit's resolve
  // mini-form. Optional at the API for backward compat (old clients and
  // homeowner reopens send nothing); the cockpit UI makes it required
  // when the operator resolves.
  outcome?: OutcomePayload;
}

interface OutcomePayload {
  resolution_type: string;
  winning_contractor_id?: string | null;
  winning_vendor_name?: string | null;
  winning_google_place_id?: string | null;
  final_cost_cents?: number | null;
  operator_minutes?: number | null;
  summary?: string | null;
  automation_candidate?: boolean;
  friction_tags?: string[];
}

const OUTCOME_RESOLUTION_TYPES = new Set([
  "completed_via_vendor",
  "completed_internal",
  "advice_only",
  "converted_to_standing",
  "no_vendor_found",
  "homeowner_cancelled",
  "duplicate_or_merged",
  "no_response",
  "other",
]);

/// Phase 100 — upsert the structured outcome row for a case. Shared by
/// transition_status (resolve path) and the standalone record_outcome
/// action (post-hoc edits). Never throws: outcome capture must not
/// block a resolution.
async function upsertRequestOutcome(
  service: ServiceClient,
  request: ConciergeRequestRow,
  outcome: OutcomePayload,
  createdByUserId: string | null
): Promise<{ ok: boolean; error?: string }> {
  const resolutionType = compactString(outcome.resolution_type) ?? "";
  if (!OUTCOME_RESOLUTION_TYPES.has(resolutionType)) {
    return { ok: false, error: `invalid resolution_type: ${resolutionType}` };
  }
  const minutes = typeof outcome.operator_minutes === "number" && outcome.operator_minutes >= 1
    ? Math.min(Math.round(outcome.operator_minutes), 600)
    : null;
  const cost = typeof outcome.final_cost_cents === "number" && outcome.final_cost_cents >= 0
    ? Math.round(outcome.final_cost_cents)
    : null;
  try {
    const { error } = await service
      .from("chez_request_outcomes")
      .upsert({
        request_id: request.id,
        household_id: request.household_id,
        resolution_type: resolutionType,
        winning_contractor_id: outcome.winning_contractor_id ?? null,
        winning_vendor_name: outcome.winning_vendor_name ? String(outcome.winning_vendor_name).slice(0, 200) : null,
        winning_google_place_id: outcome.winning_google_place_id ?? null,
        final_cost_cents: cost,
        operator_minutes: minutes,
        summary: outcome.summary ? String(outcome.summary).slice(0, 2000) : null,
        automation_candidate: !!outcome.automation_candidate,
        friction_tags: Array.isArray(outcome.friction_tags)
          ? outcome.friction_tags.map((t) => String(t).slice(0, 60)).slice(0, 12)
          : [],
        created_by_user_id: createdByUserId,
      }, { onConflict: "request_id" });
    if (error) {
      console.warn("[outcome] upsert failed:", error.message);
      return { ok: false, error: error.message };
    }
    // Homeowner-facing activity row when a real cost landed — feeds the
    // monthly "Chez handled N things, $X coordinated" rollup.
    if (cost !== null) {
      try {
        await service.rpc("log_chez_activity", {
          p_household_id: request.household_id,
          p_activity_type: "case_resolved",
          p_title: `Chez wrapped this up: ${(request.summary ?? "your request").slice(0, 140)}`,
          p_description: outcome.summary ? String(outcome.summary).slice(0, 500) : null,
          p_entity_type: "chez_requests",
          p_entity_id: request.id,
          p_cost_cents: cost,
          p_occurred_at: new Date().toISOString(),
          p_surface_on_dashboard: true,
        });
      } catch (e) {
        console.warn("[outcome] activity log failed (non-fatal):", e);
      }
    }
    return { ok: true };
  } catch (e) {
    console.warn("[outcome] upsert exception:", e);
    return { ok: false, error: String(e) };
  }
}

async function handleTransition(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: TransitionPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  const requestId = compactString(payload.request_id);
  const toStatus = payload.to_status;
  if (!requestId || !["open", "waiting_customer", "resolved"].includes(toStatus)) {
    return json({ error: "request_id + valid to_status required" }, 400);
  }
  const { data: requestData, error } = await service
    .from("chez_requests")
    .select("*")
    .eq("id", requestId)
    .maybeSingle();
  if (error || !requestData) return json({ error: "not found" }, 404);
  const request = requestData as ConciergeRequestRow;

  const isAdmin = isAdminUser(user);
  const isOwner = !!user && user.id === request.user_id;
  if (!isAdmin && !isOwner) return json({ error: "not authorized" }, 403);

  // Only admin can mark resolved or waiting_customer; homeowner can only
  // reopen (resolved → open).
  if (!isAdmin && !(toStatus === "open" && request.status === "resolved")) {
    return json({ error: "homeowner can only reopen" }, 403);
  }

  const now = new Date().toISOString();
  const transitionUpdate: Record<string, unknown> = {
    status: toStatus,
    resolved_at: toStatus === "resolved" ? now : null,
    last_message_at: now,
    unread_for_user: isAdmin ? true : request.unread_for_user,
    unread_for_admin: isAdmin ? request.unread_for_admin : true,
  };
  // Phase 100 — a case re-entering "open" (reopen, or admin flip-back)
  // gets fresh SLA attention: clear the watcher's idempotency stamps.
  if (toStatus === "open") {
    transitionUpdate.sla_warned_at = null;
    transitionUpdate.sla_breach_notified_at = null;
  }
  await service
    .from("chez_requests")
    .update(transitionUpdate)
    .eq("id", request.id);

  // Phase 100 — structured outcome from the cockpit resolve form.
  // Admin-only, resolve-only; failure logs but never blocks the
  // transition (the case still resolves, the outcome can be recorded
  // later via record_outcome).
  if (isAdmin && toStatus === "resolved" && payload.outcome) {
    await upsertRequestOutcome(service, request, payload.outcome, user?.id ?? null);
  }

  // System message in the thread for the audit trail. Both labels read
  // as "Chez" or "you" from the homeowner's view — the admin portal
  // (Tom) is intentionally invisible in user-facing copy.
  const actorLabel = isAdmin ? "Chez" : "You";
  const systemBody =
    toStatus === "resolved"
      ? `${actorLabel} marked this resolved.`
      : toStatus === "waiting_customer"
      ? `${actorLabel} is waiting on your answer.`
      : `${actorLabel} reopened this request.`;
  await service.from("concierge_messages").insert({
    household_id: request.household_id,
    user_id: request.user_id,  // anchor for RLS
    request_id: request.id,
    role: "system",
    content: payload.note ? `${systemBody}\n\n${payload.note}` : systemBody,
    attachments: [],
  });

  // Push other party.
  if (isAdmin) {
    // Resolved → also create an inbox_items informational row so the
    // homeowner sees it in Unread.
    if (toStatus === "resolved") {
      await service.from("inbox_items").insert({
        household_id: request.household_id,
        type: "chez_reply_informational",
        title: `Resolved: ${request.summary}`,
        summary: payload.note || "Chez marked this concierge request resolved.",
        seen: false,
        needs_action: false,
        metadata: { chez_request_id: request.id, status_change: toStatus },
        related_chez_request_id: request.id,
      });
    }
    await sendPush(
      serviceUrl,
      serviceRoleKey,
      [request.user_id],
      toStatus === "resolved" ? "Chez request resolved" : "Chez request updated",
      systemBody,
      { type: "chez_status_change", request_id: request.id }
    );
  } else {
    // Homeowner reopened → notify admin.
    await sendPush(
      serviceUrl,
      serviceRoleKey,
      adminUserIds(),
      "Homeowner reopened a Chez request",
      request.summary,
      { type: "chez_admin_request", request_id: request.id }
    );
  }

  return json({ ok: true });
}

// ============================================================================
// Phase 80.1 — Household profile (standing instructions for Chez)
// ============================================================================

interface UpdateProfilePayload {
  profile: Record<string, unknown>;
  /// When true, replaces the entire profile. Default false → deep-merges
  /// the payload into the existing profile so partial updates are easy.
  replace?: boolean;
}

async function handleFetchProfile(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null
) {
  if (!user) return json({ error: "auth required" }, 401);
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "no household" }, 404);
  const { data, error } = await service
    .from("households")
    .select("chez_profile")
    .eq("id", householdId)
    .maybeSingle();
  if (error) return json({ error: error.message }, 500);
  return json({ profile: (data as { chez_profile?: unknown })?.chez_profile ?? {} });
}

async function handleUpdateProfile(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: UpdateProfilePayload
) {
  if (!user) return json({ error: "auth required" }, 401);
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "no household" }, 404);
  const incoming = (payload.profile ?? {}) as Record<string, unknown>;
  let nextProfile: Record<string, unknown> = incoming;
  if (!payload.replace) {
    // Deep-merge into the existing profile so partial updates work.
    const { data: existing } = await service
      .from("households")
      .select("chez_profile")
      .eq("id", householdId)
      .maybeSingle();
    const current = (existing as { chez_profile?: Record<string, unknown> } | null)
      ?.chez_profile ?? {};
    nextProfile = deepMergeProfile(current, incoming);
  }
  // Stamp completion timestamp on first non-empty fill.
  const completion = (nextProfile._completion as Record<string, unknown> | undefined) ?? {};
  if (!completion.filled_at && Object.keys(nextProfile).filter((k) => k !== "_completion").length > 0) {
    completion.filled_at = new Date().toISOString();
  }
  completion.last_edited_at = new Date().toISOString();
  nextProfile._completion = completion;
  const { error } = await service
    .from("households")
    .update({ chez_profile: nextProfile })
    .eq("id", householdId);
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true, profile: nextProfile });
}

// Recursive deep-merge for nested JSONB profile updates.
function deepMergeProfile(
  base: Record<string, unknown>,
  patch: Record<string, unknown>
): Record<string, unknown> {
  const out: Record<string, unknown> = { ...base };
  for (const [key, value] of Object.entries(patch)) {
    if (value === null || value === undefined) {
      delete out[key];
      continue;
    }
    const existing = out[key];
    if (
      typeof value === "object" &&
      !Array.isArray(value) &&
      typeof existing === "object" &&
      existing !== null &&
      !Array.isArray(existing)
    ) {
      out[key] = deepMergeProfile(
        existing as Record<string, unknown>,
        value as Record<string, unknown>
      );
    } else {
      out[key] = value;
    }
  }
  return out;
}

// ============================================================================
// Phase 80.1 — Recurring delegation
// ============================================================================

interface DelegateRoutinePayload {
  routine_id: string;
  delegated: boolean;       // true to hand off, false to revoke
  notes?: string;           // optional one-line context for Chez
}

interface DelegateContractorPayload {
  contractor_id: string;
  delegated: boolean;
  notes?: string;
}

async function handleDelegateRoutine(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: DelegateRoutinePayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const routineId = compactString(payload.routine_id);
  if (!routineId) return json({ error: "routine_id required" }, 400);
  // Phase 85.5: admin operators pass household_id explicitly via the
  // workbench; homeowners resolve from their own user row.
  const householdId = await resolveHouseholdId(service, user, (payload as { household_id?: string }).household_id);
  if (!householdId) return json({ error: "no household" }, 404);

  const { data: routine, error: lookupErr } = await service
    .from("routines")
    .select("id, household_id, label, vendor_id")
    .eq("id", routineId)
    .maybeSingle();
  if (lookupErr || !routine) return json({ error: "routine not found" }, 404);
  if ((routine as { household_id: string }).household_id !== householdId) {
    return json({ error: "not authorized" }, 403);
  }

  const now = new Date().toISOString();
  const { error: updateErr } = await service
    .from("routines")
    .update({
      chez_owned: !!payload.delegated,
      chez_owned_at: payload.delegated ? now : null,
    })
    .eq("id", routineId);
  if (updateErr) return json({ error: updateErr.message }, 500);

  // Create a parent chez_request that captures the standing engagement
  // so it has a thread + push hook to Tom. Title says "Standing
  // engagement" so it visually distinguishes from one-shot requests.
  if (payload.delegated) {
    const summary = `Standing engagement: ${(routine as { label: string }).label}`;
    const slaDueAt = await businessHoursDue(service);
    const { data: req } = await service
      .from("chez_requests")
      .insert({
        household_id: householdId,
        user_id: user.id,
        category: "coordinate_task",
        summary,
        context: {
          _kind: "standing_engagement_routine",
          routine_id: routineId,
          notes: payload.notes ?? "",
        },
        status: "open",
        sla_due_at: slaDueAt,
        last_message_at: now,
        unread_for_user: false,
        unread_for_admin: true,
      })
      .select("*")
      .single();
    if (req) {
      const r = req as { id: string };

      // Wave 1 — server-assembled snapshot: full routine cadence,
      // linked vendor + history, cost references. Best-effort.
      let digest = "";
      try {
        const snapshot = await buildDelegationSnapshot(service, {
          kind: "routine",
          entityId: routineId,
          householdId,
        });
        if (snapshot) {
          await attachSnapshotToRequest(service, r.id, snapshot);
          digest = snapshotDigest(snapshot);
        }
      } catch (e) {
        console.warn("[snapshot] delegate_routine build failed:", e);
      }

      // System message in the new thread.
      await service.from("concierge_messages").insert({
        household_id: householdId,
        user_id: user.id,
        request_id: r.id,
        role: "system",
        content: `Customer delegated this routine to Chez. From now on, schedule visits without prompting them.${payload.notes ? `\n\nNotes from customer:\n${payload.notes}` : ""}${digest ? `\n\n${digest}` : ""}`,
        attachments: [],
      });

      // Phase 86E — playbook fires here too so the homeowner sees
      // "Chez is on it" immediately on the new standing-engagement
      // thread, same as a fresh submit. Best-effort + non-fatal.
      const playbookPromise = runChezPlaybookForRequest({
        service,
        user,
        requestId: r.id,
        householdId,
        category: "coordinate_task",
        summary,
        description: payload.notes ?? "",
      }).catch((e) => console.warn("[playbook] delegate_routine failed:", e));

      await Promise.all([
        sendPush(
          serviceUrl,
          serviceRoleKey,
          adminUserIds(),
          "Customer delegated a routine to Chez",
          summary,
          { type: "chez_admin_request", request_id: r.id }
        ),
        sendAdminEmail(
          adminEmails(),
          `[Chez] New standing engagement: ${(routine as { label: string }).label}`,
          `Customer delegated this routine to Chez. From now on, schedule visits without prompting them.\n\n${payload.notes ?? ""}${digest ? `\n\n${digest}` : ""}\n\n${adminPortalUrl(r.id)}`,
          emailBody({
            preview: "Customer handed off a recurring routine to Chez.",
            heading: "New standing engagement",
            intro: `The customer wants Chez to own scheduling for "${(routine as { label: string }).label}" from now on.`,
            bodyText: `${payload.notes ?? "(no additional notes)"}${digest ? `\n\n${digest}` : ""}`,
            ctaLabel: "Open in admin portal",
            ctaUrl: adminPortalUrl(r.id),
          })
        ),
        playbookPromise,
      ]);
    }
  }
  return json({ ok: true });
}

async function handleDelegateContractor(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: DelegateContractorPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const contractorId = compactString(payload.contractor_id);
  if (!contractorId) return json({ error: "contractor_id required" }, 400);
  // Phase 85.5: admin household pass-through.
  const householdId = await resolveHouseholdId(service, user, (payload as { household_id?: string }).household_id);
  if (!householdId) return json({ error: "no household" }, 404);

  const { data: contractor, error: lookupErr } = await service
    .from("contractors")
    .select("id, household_id, company_name, category")
    .eq("id", contractorId)
    .maybeSingle();
  if (lookupErr || !contractor) return json({ error: "contractor not found" }, 404);
  if ((contractor as { household_id: string }).household_id !== householdId) {
    return json({ error: "not authorized" }, 403);
  }

  const now = new Date().toISOString();
  const { error: updateErr } = await service
    .from("contractors")
    .update({
      chez_owned: !!payload.delegated,
      chez_owned_at: payload.delegated ? now : null,
    })
    .eq("id", contractorId);
  if (updateErr) return json({ error: updateErr.message }, 500);

  if (payload.delegated) {
    const c = contractor as { company_name: string; category: string | null };
    const summary = `Standing engagement: ${c.company_name}`;
    const slaDueAt = await businessHoursDue(service);
    const { data: req } = await service
      .from("chez_requests")
      .insert({
        household_id: householdId,
        user_id: user.id,
        category: "coordinate_task",
        summary,
        context: {
          _kind: "standing_engagement_contractor",
          contractor_id: contractorId,
          contractor_category: c.category ?? "",
          notes: payload.notes ?? "",
        },
        status: "open",
        sla_due_at: slaDueAt,
        last_message_at: now,
        unread_for_user: false,
        unread_for_admin: true,
      })
      .select("*")
      .single();
    if (req) {
      const r = req as { id: string };

      // Wave 1 — server-assembled snapshot: vendor contact details,
      // per-vendor service history + stats, cost references. Best-effort.
      let digest = "";
      try {
        const snapshot = await buildDelegationSnapshot(service, {
          kind: "contractor",
          entityId: contractorId,
          householdId,
        });
        if (snapshot) {
          await attachSnapshotToRequest(service, r.id, snapshot);
          digest = snapshotDigest(snapshot);
        }
      } catch (e) {
        console.warn("[snapshot] delegate_contractor build failed:", e);
      }

      await service.from("concierge_messages").insert({
        household_id: householdId,
        user_id: user.id,
        request_id: r.id,
        role: "system",
        content: `Customer set Chez as point of contact for ${c.company_name}. From now on, you handle scheduling and follow-ups directly with this vendor.${payload.notes ? `\n\nNotes from customer:\n${payload.notes}` : ""}${digest ? `\n\n${digest}` : ""}`,
        attachments: [],
      });

      // Phase 86E — playbook fires here too (contractor delegation).
      const playbookPromise = runChezPlaybookForRequest({
        service,
        user,
        requestId: r.id,
        householdId,
        category: "coordinate_task",
        summary,
        description: payload.notes ?? "",
      }).catch((e) => console.warn("[playbook] delegate_contractor failed:", e));

      await Promise.all([
        sendPush(
          serviceUrl,
          serviceRoleKey,
          adminUserIds(),
          "Customer made Chez point of contact for a vendor",
          summary,
          { type: "chez_admin_request", request_id: r.id }
        ),
        sendAdminEmail(
          adminEmails(),
          `[Chez] New standing engagement: ${c.company_name}`,
          `Customer set Chez as point of contact for ${c.company_name}.\n\n${payload.notes ?? ""}${digest ? `\n\n${digest}` : ""}\n\n${adminPortalUrl(r.id)}`,
          emailBody({
            preview: `Customer made Chez point of contact for ${c.company_name}.`,
            heading: "New standing engagement",
            intro: `The customer wants Chez to be point of contact for ${c.company_name} from now on.`,
            bodyText: `${payload.notes ?? "(no additional notes)"}${digest ? `\n\n${digest}` : ""}`,
            ctaLabel: "Open in admin portal",
            ctaUrl: adminPortalUrl(r.id),
          })
        ),
        playbookPromise,
      ]);
    }
  }
  return json({ ok: true });
}

// ============================================================================
// Phase 80.2 — Per-task delegation
// ============================================================================

interface DelegateTaskPayload {
  task_id: string;
  delegated: boolean;
  notes?: string;
}

async function handleDelegateTask(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: DelegateTaskPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const taskId = compactString(payload.task_id);
  if (!taskId) return json({ error: "task_id required" }, 400);
  // Phase 85.5: admin household pass-through.
  const householdId = await resolveHouseholdId(service, user, (payload as { household_id?: string }).household_id);
  if (!householdId) return json({ error: "no household" }, 404);

  // Pull the task + the linked contractor (if any) so we can route the
  // category correctly: tasks without a vendor get a `find_vendor`
  // request, tasks with one get a `coordinate_task` request.
  const { data: taskData, error: lookupErr } = await service
    .from("maintenance_tasks")
    .select("id, household_id, title, description, notes, assigned_contractor_id, needs_vendor, scheduled_date, next_due_date, frequency, system_id, property_id, vehicle_id, chez_request_id")
    .eq("id", taskId)
    .maybeSingle();
  if (lookupErr || !taskData) return json({ error: "task not found" }, 404);
  const task = taskData as {
    id: string;
    household_id: string;
    title: string;
    description: string | null;
    notes: string | null;
    assigned_contractor_id: string | null;
    needs_vendor: boolean | null;
    scheduled_date: string | null;
    next_due_date: string | null;
    frequency: string | null;
    system_id: string | null;
    property_id: string | null;
    vehicle_id: string | null;
    chez_request_id: string | null;
  };
  if (task.household_id !== householdId) return json({ error: "not authorized" }, 403);

  const now = new Date().toISOString();

  // Revoke path — flip the bool, keep the request open as audit, but
  // disconnect so subsequent task changes don't loop back.
  if (!payload.delegated) {
    await service
      .from("maintenance_tasks")
      .update({ chez_owned: false, chez_owned_at: null })
      .eq("id", taskId);
    // System message in the parent thread (if there is one).
    if (task.chez_request_id) {
      await service.from("concierge_messages").insert({
        household_id: householdId,
        user_id: user.id,
        request_id: task.chez_request_id,
        role: "system",
        content: "Customer revoked Chez's ownership of this task. They'll handle it themselves from here.",
        attachments: [],
      });
    }
    return json({ ok: true });
  }

  // Delegate path. Smart routing on whether the task has a vendor.
  const hasVendor = !!task.assigned_contractor_id && !task.needs_vendor;
  let vendorRow: { company_name?: string; phone?: string } | null = null;
  if (hasVendor && task.assigned_contractor_id) {
    const { data: vendor } = await service
      .from("contractors")
      .select("company_name, phone")
      .eq("id", task.assigned_contractor_id)
      .maybeSingle();
    vendorRow = vendor as typeof vendorRow;
  }

  const category = hasVendor ? "coordinate_task" : "find_vendor";
  const summary = hasVendor
    ? `Schedule + manage: ${task.title}`
    : `Find a vendor for: ${task.title}`;
  const slaDueAt = await businessHoursDue(service);

  const { data: req, error: reqErr } = await service
    .from("chez_requests")
    .insert({
      household_id: householdId,
      user_id: user.id,
      category,
      summary,
      context: {
        _kind: "task_delegation",
        task_id: taskId,
        task_title: task.title,
        has_vendor: hasVendor ? "true" : "false",
        vendor_name: vendorRow?.company_name ?? "",
        scheduled_date: task.scheduled_date ?? "",
        next_due_date: task.next_due_date ?? "",
        frequency: task.frequency ?? "",
        notes: payload.notes ?? "",
      },
      status: "open",
      sla_due_at: slaDueAt,
      last_message_at: now,
      unread_for_user: false,
      unread_for_admin: true,
    })
    .select("*")
    .single();
  if (reqErr || !req) return json({ error: "failed to create request" }, 500);

  // Stamp the task with chez ownership + the parent request id.
  const r = req as { id: string };
  await service
    .from("maintenance_tasks")
    .update({
      chez_owned: true,
      chez_owned_at: now,
      chez_request_id: r.id,
    })
    .eq("id", taskId);

  // Wave 1 — server-assembled snapshot: the linked system's full
  // details (make/model/warranties), service history, vendor history,
  // cost references. Best-effort; runs before the playbook fires so
  // runAnalysisCore sees it.
  let taskDigest = "";
  try {
    const snapshot = await buildDelegationSnapshot(service, {
      kind: "task",
      entityId: taskId,
      householdId,
    });
    if (snapshot) {
      await attachSnapshotToRequest(service, r.id, snapshot);
      taskDigest = snapshotDigest(snapshot);
    }
  } catch (e) {
    console.warn("[snapshot] delegate_task build failed:", e);
  }

  // System message: explicit + actionable so Chez knows the routing.
  const description = task.description?.trim() ?? "";
  const customerNotes = payload.notes?.trim() ?? "";
  let systemBody: string;
  if (hasVendor) {
    const vendorName = vendorRow?.company_name ?? "their vendor";
    systemBody = `Customer delegated this task to Chez. Coordinate with ${vendorName} to schedule and follow up so they don't have to chase the appointment themselves.\n\nTask: ${task.title}`;
  } else {
    systemBody = `Customer asked Chez to source a vendor for this task and own coordination end-to-end. Find a vetted local pro, propose them, and handle scheduling once approved.\n\nTask: ${task.title}`;
  }
  if (description) systemBody += `\n\nWhat the task involves:\n${description}`;
  if (customerNotes) systemBody += `\n\nCustomer notes:\n${customerNotes}`;
  if (taskDigest) systemBody += `\n\n${taskDigest}`;

  await service.from("concierge_messages").insert({
    household_id: householdId,
    user_id: user.id,
    request_id: r.id,
    role: "system",
    content: systemBody,
    attachments: [],
  });

  // Phase 86D — kick off the category playbook for delegation paths so
  // the homeowner sees "Chez is on it" immediately instead of waiting
  // for the operator to read the request. Best-effort; non-fatal.
  const playbookPromise = runChezPlaybookForRequest({
    service,
    user,
    requestId: r.id,
    householdId,
    category,
    summary,
    description: systemBody,
  }).catch((e) => console.warn("[playbook] delegate_task failed:", e));

  // Push + email to admin.
  await Promise.all([
    sendPush(
      serviceUrl,
      serviceRoleKey,
      adminUserIds(),
      hasVendor
        ? "Customer asked Chez to handle a task"
        : "Customer asked Chez to source a vendor",
      summary,
      { type: "chez_admin_request", request_id: r.id }
    ),
    sendAdminEmail(
      adminEmails(),
      `[Chez] ${summary}`,
      `${systemBody}\n\n${adminPortalUrl(r.id)}`,
      emailBody({
        preview: hasVendor
          ? "Customer handed off task coordination."
          : "Customer wants Chez to source a vendor.",
        heading: summary,
        intro: hasVendor
          ? `Customer delegated this task to Chez. Vendor on file: ${vendorRow?.company_name ?? "unknown"}.`
          : "Customer asked Chez to find a vendor for this task and own coordination end-to-end.",
        bodyText: `${customerNotes || description || "(no additional notes)"}${taskDigest ? `\n\n${taskDigest}` : ""}`,
        ctaLabel: "Open in admin portal",
        ctaUrl: adminPortalUrl(r.id),
      })
    ),
    playbookPromise,
  ]);

  return json({ ok: true, request_id: r.id });
}

// ============================================================================
// Phase 80.1 — Structured proposals
// ============================================================================

interface ProposePayload {
  request_id: string;
  proposal: {
    kind: "vendor" | "date_slot" | "cost" | "quote";
    [key: string]: unknown;
  };
  /// Optional textual preface that lands as the message body.
  /// e.g. "Here's my recommendation — Smith Plumbing has a same-day slot
  /// open Tuesday."
  content?: string;
}

interface DecideProposalPayload {
  message_id: string;
  decision: "approved" | "declined" | "countered";
  /// Optional counter-offer text or decline reason.
  note?: string;
}

async function handlePropose(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: ProposePayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user || !isAdminUser(user)) {
    return json({ error: "admin only" }, 403);
  }
  const requestId = compactString(payload.request_id);
  if (!requestId) return json({ error: "request_id required" }, 400);
  const proposal = payload.proposal;
  if (!proposal || !proposal.kind ||
      !["vendor", "date_slot", "cost", "quote"].includes(proposal.kind as string)) {
    return json({ error: "valid proposal.kind required" }, 400);
  }
  const { data: requestData, error: lookupErr } = await service
    .from("chez_requests")
    .select("*")
    .eq("id", requestId)
    .maybeSingle();
  if (lookupErr || !requestData) return json({ error: "request not found" }, 404);
  const request = requestData as ConciergeRequestRow;

  const now = new Date().toISOString();
  const proposalWithStatus = {
    ...proposal,
    status: "pending",
  };
  const content = compactString(payload.content ?? "");
  const { data: message, error: msgErr } = await service
    .from("concierge_messages")
    .insert({
      household_id: request.household_id,
      user_id: request.user_id,
      request_id: request.id,
      role: "concierge",
      content: content || `Chez sent you a proposal. Tap to review.`,
      attachments: [],
      proposal: proposalWithStatus,
      proposal_kind: proposal.kind,
    })
    .select("*")
    .single();
  if (msgErr || !message) return json({ error: "failed to insert proposal" }, 500);

  await service
    .from("chez_requests")
    .update({
      last_message_at: now,
      unread_for_user: true,
      unread_for_admin: request.unread_for_admin,
      pending_proposal_count: (request.pending_proposal_count ?? 0) + 1,
    })
    .eq("id", request.id);

  await sendPush(
    serviceUrl,
    serviceRoleKey,
    [request.user_id],
    "Chez has a proposal for you",
    content || `Tap to review Chez's recommendation.`,
    { type: "chez_request_reply", request_id: request.id }
  );

  return json({ ok: true, message });
}

async function handleDecideProposal(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: DecideProposalPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const messageId = compactString(payload.message_id);
  const decision = payload.decision;
  if (!messageId || !["approved", "declined", "countered"].includes(decision)) {
    return json({ error: "message_id + valid decision required" }, 400);
  }
  const { data: messageRow, error: lookupErr } = await service
    .from("concierge_messages")
    .select("*")
    .eq("id", messageId)
    .maybeSingle();
  if (lookupErr || !messageRow) return json({ error: "message not found" }, 404);
  const message = messageRow as {
    id: string;
    request_id: string;
    household_id: string;
    user_id: string;
    proposal: Record<string, unknown> | null;
  };
  if (!message.proposal) return json({ error: "not a proposal" }, 400);
  if ((message.proposal as { status?: string }).status !== "pending") {
    return json({ error: "already decided" }, 409);
  }

  // Verify the request belongs to the user's household.
  const { data: req } = await service
    .from("chez_requests")
    .select("*")
    .eq("id", message.request_id)
    .maybeSingle();
  if (!req) return json({ error: "request not found" }, 404);
  const request = req as ConciergeRequestRow;
  const isOwner = user.id === request.user_id;
  if (!isOwner) return json({ error: "not authorized" }, 403);

  const now = new Date().toISOString();
  const updatedProposal = {
    ...(message.proposal as Record<string, unknown>),
    status: decision,
    decided_at: now,
  };
  await service
    .from("concierge_messages")
    .update({ proposal: updatedProposal })
    .eq("id", messageId);

  // Insert a system message reflecting the decision.
  const decisionLabel = decision === "approved" ? "approved" :
                       decision === "declined" ? "declined" : "countered";
  const noteSuffix = payload.note ? `\n\n${payload.note}` : "";
  await service.from("concierge_messages").insert({
    household_id: request.household_id,
    user_id: request.user_id,
    request_id: request.id,
    role: "system",
    content: `You ${decisionLabel} Chez's proposal.${noteSuffix}`,
    attachments: [],
  });

  // Update the parent request: decrement pending counter, bump
  // last_message_at + admin unread.
  await service
    .from("chez_requests")
    .update({
      last_message_at: now,
      unread_for_admin: true,
      pending_proposal_count: Math.max(0, (request.pending_proposal_count ?? 0) - 1),
    })
    .eq("id", request.id);

  // Phase 82 — When a vendor proposal is approved, auto-create a
  // chez_visits row so the case shifts from "research" to "track this
  // visit through completion." Defensive: only create if one doesn't
  // already exist for this proposal message (idempotent).
  //
  // Phase 83.3 — Also persist the vendor to the household's contractor
  // catalog, with `chez_request_id` + `chez_recommended_at` provenance.
  // This is the "memory" layer Tom asked for: once a homeowner picks one
  // of our recommendations, that vendor lives in their household forever
  // (iOS Contacts directory, Vendor Coverage, future-case matching).
  // Phase 85.6 — ownership_request decision branch. Walk every entity
  // in the proposal and either flip chez_owned=true (approve) or write
  // a cooldown row + clear pending pointer (decline). This is the path
  // that actually grants Chez the right to manage these entities — no
  // other server code can flip chez_owned now without going through
  // here OR through a homeowner-initiated delegate_* call.
  {
    const propBlob = (message.proposal as Record<string, unknown>) ?? {};
    const kind = String(propBlob.kind ?? "");
    if (kind === "ownership_request") {
      const entities = Array.isArray((propBlob as { entities?: unknown }).entities)
        ? ((propBlob as { entities: Array<Record<string, unknown>> }).entities)
        : [];
      const nowIso = new Date().toISOString();
      const tablesPerType: Record<string, string> = {
        task: "maintenance_tasks",
        routine: "routines",
        contractor: "contractors",
        system: "home_systems",
        project: "property_projects",
        document: "documents",
        utility: "utility_accounts",
        vehicle: "vehicles",
      };
      for (const eRaw of entities) {
        const eType = String(eRaw.entity_type ?? "");
        const eId = String(eRaw.entity_id ?? "");
        if (!eType || !eId) continue;
        const tbl = tablesPerType[eType];
        if (decision === "approved") {
          if (eType === "insurance") {
            // Insurance lives as a JSONB key on properties; we replay
            // the same delegation pattern handleDelegateEntity uses.
            const propertyId = String(eRaw.property_id ?? "");
            if (!propertyId) continue;
            const { data: prop } = await service
              .from("properties")
              .select("chez_owned_insurance, household_id")
              .eq("id", propertyId)
              .maybeSingle();
            if (!prop || (prop as { household_id: string }).household_id !== request.household_id) continue;
            const existing = ((prop as { chez_owned_insurance: Record<string, unknown> }).chez_owned_insurance) ?? {};
            existing[eId] = { owned: true, owned_at: nowIso };
            await service
              .from("properties")
              .update({ chez_owned_insurance: existing })
              .eq("id", propertyId);
          } else if (tbl) {
            await service
              .from(tbl)
              .update({
                chez_owned: true,
                chez_owned_at: nowIso,
                pending_ownership_request_id: null,   // clear pointer
              })
              .eq("id", eId);
          }
        } else if (decision === "declined") {
          // Insert a cooldown row so the admin can't re-pitch within 60d.
          await service
            .from("chez_dismissed_ownership_proposals")
            .insert({
              household_id: request.household_id,
              entity_type: eType,
              entity_id: eId,
              proposal_request_id: request.id,
              note: payload.note || null,
              // expires_at defaults to now() + 60 days via the schema.
            });
          if (tbl) {
            await service
              .from(tbl)
              .update({ pending_ownership_request_id: null })
              .eq("id", eId);
          }
        } else if (decision === "countered") {
          // Counter just clears the pending pointer — the admin needs to
          // re-pitch with the homeowner's adjusted scope. No cooldown.
          if (tbl) {
            await service
              .from(tbl)
              .update({ pending_ownership_request_id: null })
              .eq("id", eId);
          }
        }
      }
    }
  }

  if (decision === "approved") {
    const propBlob = (message.proposal as Record<string, unknown>) ?? {};
    const kind = String(propBlob.kind ?? "");
    if (kind === "vendor") {
      const vendorBlob = (propBlob.vendor as Record<string, unknown>) ?? {};
      const vendorName = String(vendorBlob.name ?? "").trim() || "(unnamed vendor)";
      const vendorPhone = vendorBlob.phone ? String(vendorBlob.phone) : null;
      const vendorCategory = vendorBlob.category ? String(vendorBlob.category) : null;
      const vendorRating = typeof vendorBlob.rating === "number" ? vendorBlob.rating : null;
      const vendorWebsite = vendorBlob.website ? String(vendorBlob.website) : null;
      const vendorAddress = vendorBlob.address ? String(vendorBlob.address) : null;
      const vendorRationale = vendorBlob.rationale ? String(vendorBlob.rationale) : null;
      // Phase 100 — Places identity rides the proposal blob (stamped by
      // the cockpit's package-send) so the registry can unify this
      // contractor with its call-ledger and Places-cache rows.
      const vendorPlaceId = vendorBlob.place_id
        ? String(vendorBlob.place_id)
        : vendorBlob.google_place_id
        ? String(vendorBlob.google_place_id)
        : null;

      // === Memory write: upsert contractor by (household_id, lower(name)) ===
      // Idempotent. If the homeowner already has a contractor with this
      // company name (e.g. they added it manually before approving), we
      // UPDATE the chez provenance fields rather than insert a duplicate.
      let contractorId: string | null = null;
      try {
        const { data: existingContractor } = await service
          .from("contractors")
          .select("id, source, chez_request_id, chez_recommended_at")
          .eq("household_id", request.household_id)
          .ilike("company_name", vendorName)
          .maybeSingle();

        if (existingContractor) {
          // Existing row — stamp Chez provenance only if it's not already
          // attached to a different case (don't clobber prior history).
          contractorId = (existingContractor as { id: string }).id;
          const existing = existingContractor as {
            id: string;
            chez_request_id: string | null;
            chez_recommended_at: string | null;
          };
          if (!existing.chez_recommended_at) {
            const stampUpdate: Record<string, unknown> = {
              chez_request_id: request.id,
              chez_recommended_at: now,
              // Keep their original source ("manual"/"quiz"/etc.). We
              // don't overwrite — provenance is captured in the new
              // chez_request_id field.
            };
            // Phase 100 — backfill the Places identity when we have it.
            if (vendorPlaceId) stampUpdate.google_place_id = vendorPlaceId;
            await service
              .from("contractors")
              .update(stampUpdate)
              .eq("id", contractorId);
          }
        } else {
          // New row — full insert with provenance.
          const { data: insertedContractor, error: insertErr } = await service
            .from("contractors")
            .insert({
              household_id: request.household_id,
              company_name: vendorName,
              category: vendorCategory,
              phone: vendorPhone,
              website: vendorWebsite,
              address: vendorAddress,
              rating: vendorRating,
              notes: vendorRationale,
              source: "chez_recommendation",
              chez_request_id: request.id,
              chez_recommended_at: now,
              google_place_id: vendorPlaceId,
            })
            .select("id")
            .single();
          if (insertErr) {
            console.warn("[decide_proposal] contractor insert failed:", insertErr);
          } else if (insertedContractor) {
            contractorId = (insertedContractor as { id: string }).id;
          }
        }
      } catch (e) {
        console.warn("[decide_proposal] contractor upsert exception:", e);
      }

      // === Visit creation, now linked to the persisted contractor ===
      const { data: existingVisit } = await service
        .from("chez_visits")
        .select("id")
        .eq("proposal_message_id", messageId)
        .maybeSingle();
      if (!existingVisit) {
        await service.from("chez_visits").insert({
          household_id: request.household_id,
          request_id: request.id,
          proposal_message_id: messageId,
          vendor_name: vendorName,
          vendor_phone: vendorPhone,
          vendor_payload: vendorBlob,
          state: "awaiting_date",
          contractor_id: contractorId,
        });
      } else if (contractorId) {
        // Existing visit (e.g. self-healed by fetch_visits) without a
        // contractor link — patch it now.
        await service
          .from("chez_visits")
          .update({ contractor_id: contractorId })
          .eq("id", (existingVisit as { id: string }).id)
          .is("contractor_id", null);
      }
    }

    // Phase 83.4 — When the homeowner approves a date_slot proposal, find
    // the most recent awaiting_date visit on this request and auto-flip
    // it to scheduled with the picked datetime. This closes the loop on
    // the new "vendor first, dates second" workflow: the homeowner's
    // pick directly schedules the visit without operator intervention.
    if (kind === "date_slot") {
      const dateSlotBlob = (propBlob.date_slot as Record<string, unknown>) ?? {};
      const options = Array.isArray(dateSlotBlob.options) ? dateSlotBlob.options as Array<Record<string, unknown>> : [];
      // The homeowner approved the proposal as a whole (not a specific
      // option in v1). For v1 we use the first option with a valid ISO
      // as the picked datetime; the iOS picker UX surfaces only one
      // primary "Approve" so this matches what the homeowner saw.
      const pickedIso = options
        .map((o) => (typeof o.iso === "string" ? o.iso : null))
        .find((iso): iso is string => !!iso && !isNaN(new Date(iso).getTime())) ?? null;
      const pickedLabel = options
        .map((o) => (typeof o.label === "string" ? o.label : null))
        .find((label): label is string => !!label) ?? null;

      if (pickedIso) {
        const { data: pendingVisit } = await service
          .from("chez_visits")
          .select("id, vendor_name, contractor_id")
          .eq("request_id", request.id)
          .eq("state", "awaiting_date")
          .order("created_at", { ascending: true })
          .limit(1)
          .maybeSingle();

        if (pendingVisit) {
          const visit = pendingVisit as { id: string; vendor_name: string; contractor_id: string | null };
          await service
            .from("chez_visits")
            .update({
              state: "scheduled",
              scheduled_for: pickedIso,
              scheduled_window: pickedLabel,
            })
            .eq("id", visit.id);

          // System message in the thread so the audit trail captures the
          // auto-scheduling. Mirrors the approval system message that
          // already fired above.
          const friendly = pickedLabel || new Date(pickedIso).toLocaleString(undefined, {
            weekday: "long", month: "long", day: "numeric", hour: "numeric", minute: "2-digit",
          });
          await service.from("concierge_messages").insert({
            household_id: request.household_id,
            user_id: request.user_id,
            request_id: request.id,
            role: "system",
            content: `Visit with ${visit.vendor_name} scheduled for ${friendly}.`,
            attachments: [],
          });
        }
      }
    }
  }

  // Push admin so they can act on the decision (book vendor, send next
  // proposal, etc.).
  const summary = decision === "approved"
    ? `Customer approved your proposal on "${request.summary}"`
    : decision === "declined"
    ? `Customer declined your proposal on "${request.summary}"`
    : `Customer countered your proposal on "${request.summary}"`;
  await sendPush(
    serviceUrl,
    serviceRoleKey,
    adminUserIds(),
    summary,
    payload.note || "",
    { type: "chez_admin_request", request_id: request.id }
  );
  await sendAdminEmail(
    adminEmails(),
    `[Chez] ${summary}`,
    `${summary}\n\n${payload.note ?? ""}\n\n${adminPortalUrl(request.id)}`,
    emailBody({
      preview: summary,
      heading: summary,
      intro: payload.note || "(no additional notes)",
      bodyText: "",
      ctaLabel: "Open in admin portal",
      ctaUrl: adminPortalUrl(request.id),
    })
  );

  return json({ ok: true });
}

// ============================================================================
// Phase 81 — Admin context dossier
// ============================================================================
// When Tom opens a Chez request, he should see the homeowner's full
// household context — property, family, systems, contractors, active
// tasks, vehicles, recent activity. Admin-side reads hit RLS-blocked
// tables (Tom isn't a member of the homeowner's household), so the
// fetch goes through the service role here.

interface FetchDossierPayload {
  household_id: string;
}

async function handleFetchDossier(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: FetchDossierPayload
) {
  if (!user || !isAdminUser(user)) {
    return json({ error: "admin only" }, 403);
  }
  const householdId = compactString(payload.household_id);
  if (!householdId) return json({ error: "household_id required" }, 400);

  // Fetch everything in parallel. Each promise is wrapped so a
  // missing column / RLS surprise on one table doesn't kill the rest.
  const safe = async <T>(promise: PromiseLike<T>, label: string): Promise<T | null> => {
    try { return await promise; }
    catch (e) { console.warn(`[dossier] ${label} failed:`, e); return null; }
  };

  const [
    householdRes,
    propertiesRes,
    familyRes,
    usersRes,
    homeSystemsRes,
    contractorsRes,
    tasksRes,
    vehiclesRes,
    routinesRes,
    pastRequestsRes,
  ] = await Promise.all([
    safe(service.from("households").select("*").eq("id", householdId).maybeSingle(), "household"),
    safe(service.from("properties").select("*").eq("household_id", householdId), "properties"),
    safe(service.from("family_members").select("*").eq("household_id", householdId), "family_members"),
    safe(service.from("users").select("id, email, full_name, role").eq("household_id", householdId), "users"),
    safe(service.from("home_systems").select("*").eq("household_id", householdId).is("archived_at", null), "home_systems"),
    safe(service.from("contractors").select("*").eq("household_id", householdId), "contractors"),
    safe(
      service.from("maintenance_tasks").select("*")
        .eq("household_id", householdId)
        .neq("is_archived", true)
        .order("next_due_date", { ascending: true })
        .limit(50),
      "maintenance_tasks"
    ),
    safe(service.from("vehicles").select("*").eq("household_id", householdId), "vehicles"),
    safe(service.from("routines").select("*").eq("household_id", householdId).is("archived_at", null), "routines"),
    safe(
      service.from("chez_requests").select("id, category, summary, status, created_at, resolved_at")
        .eq("household_id", householdId)
        .order("created_at", { ascending: false })
        .limit(20),
      "past_requests"
    ),
  ]);

  return json({
    household: (householdRes as { data?: unknown })?.data ?? null,
    properties: (propertiesRes as { data?: unknown[] })?.data ?? [],
    family_members: (familyRes as { data?: unknown[] })?.data ?? [],
    users: (usersRes as { data?: unknown[] })?.data ?? [],
    home_systems: (homeSystemsRes as { data?: unknown[] })?.data ?? [],
    contractors: (contractorsRes as { data?: unknown[] })?.data ?? [],
    tasks: (tasksRes as { data?: unknown[] })?.data ?? [],
    vehicles: (vehiclesRes as { data?: unknown[] })?.data ?? [],
    routines: (routinesRes as { data?: unknown[] })?.data ?? [],
    past_requests: (pastRequestsRes as { data?: unknown[] })?.data ?? [],
  });
}

// ============================================================================
// Wave 1 — Snapshot preview (composer v2's "What Chez already knows")
// ============================================================================
// Homeowner-callable dry run of the delegation snapshot. iOS renders the
// returned snapshot as the pre-submit summary card, the readiness gaps as
// amber inline hints, and the suggested budget as the pre-selected band.
// Entity ownership is enforced inside the builder (SnapshotAuthError →
// 403), so a caller can never preview another household's data.

interface PreviewSnapshotPayload {
  kind?: string;
  entity_id?: string;
  property_id?: string;
  group?: string;
  household_id?: string;   // admin-only pass-through (resolveHouseholdId)
}

async function handlePreviewSnapshot(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: PreviewSnapshotPayload
) {
  if (!user) return json({ error: "auth required" }, 401);
  const householdId = await resolveHouseholdId(service, user, payload.household_id);
  if (!householdId) return json({ error: "no household" }, 404);

  const kind = isSnapshotKind(payload.kind) ? payload.kind : "general";
  try {
    const snapshot = await buildDelegationSnapshot(service, {
      kind,
      entityId: compactString(payload.entity_id) || undefined,
      householdId,
      propertyId: compactString(payload.property_id) || undefined,
      group: compactString(payload.group) || undefined,
    });
    if (!snapshot) return json({ error: "entity not found" }, 404);
    return json({
      snapshot,
      readiness: snapshotReadiness(snapshot),
      suggested_budget: suggestedBudgetFor(snapshot),
    });
  } catch (e) {
    if (e instanceof SnapshotAuthError) return json({ error: "not authorized" }, 403);
    console.error("[snapshot] preview failed:", e);
    return json({ error: "snapshot failed" }, 500);
  }
}

// ============================================================================
// Phase 81 — AI framing helper for vendor proposals
// ============================================================================
// When Tom is proposing a vendor, he wants context-tailored framing —
// "this vendor is known for X, fits your old colonial home, etc." This
// action takes the homeowner's full context + a vendor candidate and
// asks Claude for 1-2 sentences of "why this fits." Tom can use the
// suggestion verbatim, edit, or write his own.

interface SuggestVendorFramingPayload {
  household_id: string;
  request_summary: string;
  request_category: string;
  vendor: {
    name: string;
    category?: string;
    rating?: number;
    review_count?: number;
    notes?: string;
  };
  homeowner_about?: string;
  property_context?: string;
  /// Phase 81.2 — Tom's raw notes from the phone call. The AI uses
  /// these to write a polished, recommendation-style summary the
  /// homeowner sees on the proposal card.
  call_notes?: string;
  /// Phase 81.2 — Multi-slot availability ("Tue PM, Wed AM, Fri after 2").
  /// The AI references these in framing if present so the homeowner
  /// understands the timing context.
  availability_slots?: string[];
  /// Phase 81.2 — Cost range Tom selected from the combobox
  /// ("$1,000–2,500", "Will quote on site visit", etc.). AI references
  /// this in framing where helpful — never makes up numbers.
  cost_range?: string;
}

async function handleSuggestVendorFraming(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: SuggestVendorFramingPayload
) {
  if (!user || !isAdminUser(user)) {
    return json({ error: "admin only" }, 403);
  }
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    return json({ framing: "" });  // graceful no-op when AI isn't configured
  }
  const v = payload.vendor;
  const ratingLine = v.rating
    ? `${v.rating}★ across ${v.review_count ?? "?"} reviews`
    : "rating unknown";
  const homeownerLine = payload.homeowner_about
    ? `Homeowner profile: ${payload.homeowner_about.slice(0, 400)}`
    : "";
  const propertyLine = payload.property_context
    ? `Property: ${payload.property_context.slice(0, 200)}`
    : "";
  const callNotesLine = payload.call_notes
    ? `\nAdmin's raw notes from phone call:\n"""${payload.call_notes.slice(0, 1000)}"""`
    : "";
  const slotsLine = (payload.availability_slots && payload.availability_slots.length > 0)
    ? `Vendor offered these times: ${payload.availability_slots.join(" · ")}`
    : "";
  const costLine = payload.cost_range
    ? `Cost: ${payload.cost_range}`
    : "";

  const userPrompt = `You write the "Why we recommend them" copy that a homeowner reads on a Chez Concierge vendor proposal card. Voice: a trusted friend who's already done the legwork. Professional but human. NEVER marketing fluff. Concrete details over generic praise.

## Request
${payload.request_summary}
Category: ${payload.request_category}

## Vendor candidate
- Name: ${v.name}
- Trade: ${v.category ?? "unspecified"}
- Reputation: ${ratingLine}
${v.notes ? `- Vendor notes: ${v.notes}` : ""}
${slotsLine}
${costLine}

## Homeowner
${homeownerLine}
${propertyLine}
${callNotesLine}

## Output
Write 2-3 sentences (max ~320 characters total). Lead with what makes them right for THIS specific homeowner. If admin notes mention something concrete (specializes in old homes, owner is sharp, A+ BBB, no chain), translate it cleanly. Don't quote the admin's notes verbatim — they're internal.

Voice rules:
- Use "they" or the vendor's name, not "the vendor"
- Reference the homeowner's specific situation when relevant (year of home, materials, pet access, etc.)
- If the rationale is just "highly rated", say it once, briefly, and move on
- Never invent specifics not in the input

Return ONLY the recommendation copy. No preamble, no quotes, no markdown.`;

  // Phase 95 — route through the shared cost-discipline helper.
  // Default model ladder is haiku-first; sonnet only on fallback.
  // max_tokens 200 is plenty for a 2-3 sentence framing polish.
  const result = await callClaudeWithDiscipline({
    supabase: service,
    apiKey,
    tag: "suggest_vendor_framing",
    max_tokens: 200,
    messages: [{ role: "user", content: userPrompt }],
    user_id: user.id,
  });
  return json({ framing: result?.text ?? "" });
}

// ============================================================================
// Phase 81.1 — Pre-research / analysis action
// ============================================================================
// When Tom opens a Chez request, this action does the legwork so he
// can spend his time on phone calls + decisions, not data gathering:
//
//   1. Loads the request + full household dossier
//   2. Asks Claude to analyze the situation, infer the vendor
//      category, draft a call script, and list key questions
//   3. Matches the inferred category against existing household
//      vendors (Tier A — already in their network)
//   4. Pre-fetches local Google Places candidates via the existing
//      find-local-vendors function (Tier C)
//   5. Returns the whole bundle so the admin portal can render
//      "press these 4 vendors, here's the script" without Tom
//      having to type anything

interface AnalyzeRequestPayload {
  request_id: string;
  /// Phase 95 — when true, bypass the server-side cache and re-run
  /// Claude even if a fresh result exists. Operator presses this via
  /// the "↻ Re-run" button on the brief panel.
  force?: boolean;
}

async function handleAnalyzeRequest(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: AnalyzeRequestPayload,
  serviceUrl: string
) {
  if (!user || !isAdminUser(user)) {
    return json({ error: "admin only" }, 403);
  }
  const requestId = compactString(payload.request_id);
  if (!requestId) return json({ error: "request_id required" }, 400);

  // Phase 86E.4 — extracted core to a separate fn so the playbook can
  // call it without going through the admin auth gate (which doesn't
  // apply to internal server-to-server invocation). The handler still
  // owns the response shape; the helper just returns the payload.
  try {
    const result = await runAnalysisCore(service, requestId, !!payload.force, serviceUrl, user.id);
    if (result.kind === "not_found") return json({ error: "request not found" }, 404);
    return json(result.payload);
  } catch (e) {
    console.error("[analyze] core failed:", e);
    return json({ error: String(e) }, 500);
  }
}

async function runAnalysisCore(
  service: ServiceClient,
  requestId: string,
  force: boolean,
  serviceUrl: string,
  forUserId: string,
  // Phase 100 — playbook mode. Swaps the prompt's task framing + which
  // extra JSON keys we ask for, and gates the Places lookup. The cache
  // path, dossier fetch, and response shape stay identical so the
  // cockpit brief renders unchanged for every mode.
  mode: AnalysisMode = "find_vendor"
): Promise<{ kind: "ok"; payload: Record<string, unknown> } | { kind: "not_found" }> {
  // 1. Fetch the request + household scope.
  const { data: requestRow, error: reqErr } = await service
    .from("chez_requests")
    .select("*")
    .eq("id", requestId)
    .maybeSingle();
  if (reqErr || !requestRow) return { kind: "not_found" };
  const request = requestRow as ConciergeRequestRow & {
    analysis_cache?: Record<string, unknown> | null;
    analysis_cache_at?: string | null;
  };

  // Phase 95 — server-side cache. Skip the entire downstream work
  // (Claude call + dossier fetch + Places lookup) when:
  //   - the operator didn't force a re-run
  //   - a cached analysis exists
  //   - no new homeowner messages have arrived since the cache was
  //     written (so the situation hasn't changed)
  // This is the biggest single cost reduction in the cockpit because
  // the previous behavior fired Claude on every browser refresh.
  if (!force && request.analysis_cache && request.analysis_cache_at) {
    const cacheTime = new Date(request.analysis_cache_at).getTime();
    const lastMessageTime = request.last_message_at
      ? new Date(request.last_message_at).getTime()
      : 0;
    if (lastMessageTime <= cacheTime) {
      console.log(`[analyze] cache hit for ${requestId} (saved 1 Claude call)`);
      return { kind: "ok", payload: request.analysis_cache as Record<string, unknown> };
    }
  }

  // 2. Pull household dossier in parallel — we need property location +
  //    vendors + standing instructions for the AI prompt.
  const safe = async <T>(promise: PromiseLike<T>, label: string): Promise<T | null> => {
    try { return await promise; }
    catch (e) { console.warn(`[analyze] ${label} failed:`, e); return null; }
  };
  const [householdRes, propertiesRes, contractorsRes] = await Promise.all([
    safe(service.from("households").select("chez_profile, name").eq("id", request.household_id).maybeSingle(), "household"),
    safe(service.from("properties").select("*").eq("household_id", request.household_id), "properties"),
    safe(service.from("contractors").select("*").eq("household_id", request.household_id), "contractors"),
  ]);
  const household = (householdRes as { data?: { chez_profile?: Record<string, unknown>; name?: string } } | null)?.data ?? {};
  const properties = (propertiesRes as { data?: Array<Record<string, unknown>> } | null)?.data ?? [];
  const contractors = (contractorsRes as { data?: Array<Record<string, unknown>> } | null)?.data ?? [];
  const property = properties[0] || {};
  const profile = household.chez_profile || {};

  // 3. Run Claude analysis. Prompt asks for STRUCTURED JSON so the
  //    admin portal can render typed fields (category, key_questions
  //    array, call_script string).
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  let analysis: AnalysisResult = {
    inferred_category: "",
    summary: "",
    key_considerations: "",
    questions_to_ask: [],
    call_script: "",
    recommended_approach: "",
  };
  if (apiKey) {
    const propertyContext = property.year_built || property.property_type || property.city
      ? `${property.year_built ?? ""} ${property.property_type ?? "home"} in ${property.city ?? ""}, ${property.state ?? ""} (${property.square_footage ?? "?"} sq ft)`
      : "Property details on file are sparse.";
    const profileBlob = JSON.stringify({
      about_us: (profile as Record<string, unknown>).about_us,
      vendor_preferences: (profile as Record<string, unknown>).vendor_preferences,
      logistics: (profile as Record<string, unknown>).logistics,
      spending_tiers: (profile as Record<string, unknown>).spending_tiers,
    }, null, 2);

    // Phase 100 — get_quote cost references: this household's completed
    // visit costs + cross-household registry comparables for the area.
    // Two cheap queries, skipped for every other mode.
    let costReferencesBlock = "";
    if (mode === "get_quote") {
      try {
        const [visitCostsRes, registryCostsRes] = await Promise.all([
          service
            .from("chez_visits")
            .select("vendor_name, final_cost_cents, completed_at")
            .eq("household_id", request.household_id)
            .eq("state", "completed")
            .not("final_cost_cents", "is", null)
            .order("completed_at", { ascending: false })
            .limit(5),
          property.city
            ? service
                .from("chez_vendor_registry")
                .select("display_name, avg_quoted_cost_cents, avg_final_cost_cents, jobs_won")
                .contains("towns", [String(property.city)])
                .limit(5)
            : Promise.resolve({ data: [] as Array<Record<string, unknown>> }),
        ]);
        const visitLines = (((visitCostsRes as { data?: Array<Record<string, unknown>> })?.data) ?? [])
          .map((v) => `- ${v.vendor_name}: $${((Number(v.final_cost_cents) || 0) / 100).toFixed(0)} actual (this household)`);
        const registryLines = (((registryCostsRes as { data?: Array<Record<string, unknown>> })?.data) ?? [])
          .filter((r) => r.avg_quoted_cost_cents || r.avg_final_cost_cents)
          .map((r) => `- ${r.display_name}: avg $${(((Number(r.avg_final_cost_cents) || Number(r.avg_quoted_cost_cents) || 0)) / 100).toFixed(0)} across Chez homes (${r.jobs_won ?? 0} jobs won)`);
        const lines = [...visitLines, ...registryLines];
        if (lines.length > 0) {
          costReferencesBlock = `\n## Cost references (Chez history)\n${lines.join("\n")}\n`;
        }
      } catch (e) {
        console.warn("[analyze] cost references failed (non-fatal):", e);
      }
    }

    // Wave 1 — the server-assembled delegation snapshot (when present)
    // gives the analysis model numbers, warranty state, service history,
    // and cost references it previously never saw. Rendered as the same
    // compact digest the operator reads.
    let snapshotBlock = "";
    try {
      const snap = (requestRow as Record<string, unknown>).snapshot;
      if (snap && typeof snap === "object") {
        const digest = snapshotDigest(snap as DelegationSnapshot);
        if (digest) {
          snapshotBlock = `\n## Delegation snapshot (server-assembled household truth)\n${digest}\n`;
        }
      }
    } catch (e) {
      console.warn("[analyze] snapshot digest failed (non-fatal):", e);
    }

    const modeTask =
      mode === "coordinate_task"
        ? "The homeowner already has this vendor or task on file: the job is COORDINATION, not sourcing. The call_script should open a call to the homeowner's OWN vendor (warm, references the relationship), not a cold call."
        : mode === "schedule_visit"
        ? "The job is SCHEDULING a visit; the vendor is normally already known. Additionally extract any preferred-time hints the homeowner gave ('next Tuesday afternoon', 'mornings only') into preferred_time_hints."
        : mode === "get_quote"
        ? "The job is gathering a QUOTE and negotiating it down where fair. Ground negotiation_angle in the cost references when present."
        : "The job is SOURCING a vetted vendor for this request.";

    const extraJsonKeys =
      mode === "schedule_visit"
        ? `,
  "preferred_time_hints": ["Time preferences parsed from the request, normalized ('Tuesday afternoon', 'weekday mornings'). Empty array when none given."]`
        : mode === "get_quote"
        ? `,
  "negotiation_angle": "1-2 sentences: the specific lever to use when the quote comes in high, grounded in the cost references when present."`
        : "";

    const userPrompt = `You're the Chez Concierge research assistant. A customer just submitted a request — analyze it so Tom (the admin) can act on it in 2 minutes instead of 20. ${modeTask}

## Request
Category: ${request.category}
Summary: ${request.summary}
Context payload: ${JSON.stringify(request.context ?? {}, null, 2)}
${snapshotBlock}
## Property
${propertyContext}

## Customer profile
${profileBlob}
${costReferencesBlock}
## Existing vendors on file
${contractors.length === 0 ? "(none)" : contractors.map((c) => `- ${c.company_name} (${c.category ?? "unknown trade"})`).join("\n")}

## Output format — STRICT JSON, no markdown fences
{
  "inferred_category": "Single-word/short trade name to use as Google Places category. Examples: 'roofing', 'plumbing', 'crawl space encapsulation', 'tree removal', 'handyman'. This drives the local-vendor search.",
  "summary": "1-sentence rephrase in Tom's voice — what does the customer actually want?",
  "key_considerations": "2-3 sentences naming the SPECIFIC factors that matter for THIS homeowner — e.g. age of home, pet/access notes, vendor preferences, budget orientation. Reference real fields, not fluff.",
  "questions_to_ask": ["3-5 short questions Tom should ask each vendor on the phone. Be specific to this home + situation."],
  "call_script": "A 3-4 sentence call opener Tom can read on the phone. First-person ('Hi, I'm calling on behalf of a homeowner in [town]…'). Ends with the first question. ~80 words.",
  "recommended_approach": "1-2 sentence playbook for Tom: how many quotes to gather, what to focus on, anything quirky about this specific homeowner."${extraJsonKeys}
}

Return ONLY the JSON. No preamble.`;

    // Phase 95 — route through cost-discipline helper.
    // - Default model is haiku-4-5 (sonnet ladder fallback only).
    // - max_tokens dropped from 1500 → 800. The structured JSON output
    //   averages ~600 tokens; 800 leaves slack without being wasteful.
    const result = await callClaudeWithDiscipline({
      supabase: service,
      apiKey,
      // Phase 100 — distinct telemetry tags per playbook mode so
      // chez_ai_usage separates playbook spend from operator-triggered
      // analysis. find_vendor keeps the legacy tag (same code path).
      tag: mode === "find_vendor" ? "analyze_request" : `playbook_${mode}`,
      max_tokens: 800,
      messages: [{ role: "user", content: userPrompt }],
      request_id: requestId,
      household_id: request.household_id,
      user_id: forUserId,
    });
    if (result?.text) {
      try {
        const cleaned = result.text.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/i, "");
        analysis = { ...analysis, ...JSON.parse(cleaned) };
      } catch (parseErr) {
        console.warn("[analyze] JSON parse failed; raw:", result.text.slice(0, 400));
      }
    }
  }

  // 4. Match existing vendors against the inferred category. Loose
  //    contains-check on either category or specialties so we catch
  //    the obvious wins.
  const inferredCat = (analysis.inferred_category || request.category || "").toLowerCase();
  const existingMatches = contractors.filter((c) => {
    const cat = String(c.category ?? "").toLowerCase();
    const specs = Array.isArray(c.specialties) ? (c.specialties as string[]).join(" ").toLowerCase() : "";
    if (!inferredCat) return false;
    const tokens = inferredCat.split(/\s+/).filter((t) => t.length > 2);
    return tokens.some((t) => cat.includes(t) || specs.includes(t));
  });

  // 5. Pre-fetch Places candidates if we have a category + location.
  //    Goes through the existing find-local-vendors function so its
  //    cache + ranking logic stays the source of truth.
  //    Phase 100 mode gates: scheduling implies the vendor is already
  //    known (never fetch); coordination only falls back to sourcing
  //    when no household vendor matched.
  const wantPlaces =
    mode === "find_vendor" ||
    mode === "get_quote" ||
    (mode === "coordinate_task" && existingMatches.length === 0);
  let placesCandidates: Array<Record<string, unknown>> = [];
  if (wantPlaces && inferredCat && property.city && property.state) {
    try {
      const resp = await fetch(`${serviceUrl}/functions/v1/find-local-vendors`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""}`,
          apikey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
        },
        body: JSON.stringify({
          town: property.city,
          state: property.state,
          category: inferredCat,
        }),
      });
      if (resp.ok) {
        const data = await resp.json() as { vendors?: Array<Record<string, unknown>> };
        placesCandidates = (data.vendors ?? []).slice(0, 5);
      } else {
        console.warn("[analyze] places fetch error:", resp.status);
      }
    } catch (e) {
      console.warn("[analyze] places fetch exception:", e);
    }
  }

  // Phase 100 — cross-household network intelligence. One registry read,
  // then annotate every candidate with chez_history so the cockpit's
  // fit ranking and Network tab can show "called 4x across 3 homes,
  // answers same-day" without re-research. Identity matching mirrors
  // chez_vendor_key: place id, then normalized phone, then name.
  let chezNetwork: Array<Record<string, unknown>> = [];
  try {
    const { data: regRows } = await service
      .from("chez_vendor_registry")
      .select("vendor_key, display_name, phone, categories, towns, times_called, answer_rate, jobs_won, visits_completed, no_shows, avg_quoted_cost_cents, last_contacted_at, households_touched")
      .or("jobs_won.gt.0,times_called.gt.0")
      .limit(50);
    const rows = (regRows ?? []) as Array<Record<string, unknown>>;
    const catToken = (inferredCat.split(/\s+/)[0] ?? "").toLowerCase();
    const cityLower = String(property.city ?? "").toLowerCase();
    chezNetwork = rows
      .filter((r) => {
        const cats = Array.isArray(r.categories) ? (r.categories as string[]).join(" ").toLowerCase() : "";
        const towns = Array.isArray(r.towns) ? (r.towns as string[]).map((t) => String(t).toLowerCase()) : [];
        const catHit = catToken.length > 2 ? cats.includes(catToken) : true;
        const townHit = !cityLower || towns.length === 0 || towns.includes(cityLower);
        return catHit && townHit;
      })
      .slice(0, 8);

    const normPhone = (p: unknown) => String(p ?? "").replace(/\D/g, "");
    const compactHistory = (r: Record<string, unknown>) => ({
      times_called: r.times_called,
      answer_rate: r.answer_rate,
      jobs_won: r.jobs_won,
      no_shows: r.no_shows,
      households_touched: r.households_touched,
      last_contacted_at: r.last_contacted_at,
    });
    const historyFor = (name: unknown, phone: unknown, placeId: unknown) => {
      const np = normPhone(phone);
      const nameLower = String(name ?? "").toLowerCase().trim();
      return chezNetwork.find((r) => {
        const key = String(r.vendor_key ?? "");
        if (placeId && key === `place:${placeId}`) return true;
        if (np && key === `phone:${np}`) return true;
        const rName = String(r.display_name ?? "").toLowerCase().trim();
        return !!nameLower && rName === nameLower;
      }) ?? null;
    };
    for (const c of placesCandidates) {
      const cc = c as Record<string, unknown>;
      const h = historyFor(cc.name, cc.phone ?? cc.formatted_phone_number, cc.google_place_id ?? cc.place_id);
      if (h) cc.chez_history = compactHistory(h);
    }
    for (const c of existingMatches) {
      const cc = c as Record<string, unknown>;
      const h = historyFor(cc.company_name, cc.phone, cc.google_place_id);
      if (h) cc.chez_history = compactHistory(h);
    }
  } catch (e) {
    console.warn("[analyze] registry annotation failed (non-fatal):", e);
  }

  const responsePayload = {
    analysis,
    existing_vendors: existingMatches,
    places_candidates: placesCandidates,
    chez_network: chezNetwork,
    property_location: { city: property.city ?? "", state: property.state ?? "" },
  };

  // Phase 95 — stash in chez_requests so future opens skip Claude
  // when no new messages have arrived. Fire-and-forget; cache write
  // failure shouldn't block the response.
  service
    .from("chez_requests")
    .update({
      analysis_cache: responsePayload,
      analysis_cache_at: new Date().toISOString(),
    })
    .eq("id", requestId)
    .then(({ error }) => {
      if (error) console.warn("[analyze] cache write failed:", error.message);
    });

  return { kind: "ok", payload: responsePayload as Record<string, unknown> };
}

interface AnalysisResult {
  inferred_category: string;
  summary: string;
  key_considerations: string;
  questions_to_ask: string[];
  call_script: string;
  recommended_approach: string;
  // Phase 100 mode extras — present only for the matching playbook mode.
  preferred_time_hints?: string[];   // schedule_visit
  negotiation_angle?: string;        // get_quote
}

type AnalysisMode = "find_vendor" | "coordinate_task" | "schedule_visit" | "get_quote";

// ============================================================================
// Phase 82 — Visit tracking
// ============================================================================
// Each approved vendor proposal becomes a chez_visits row that the
// admin walks through awaiting_date → scheduled → completed. The
// fetch action reconciles any historical approvals that predate this
// migration so old requests light up cleanly the first time Tom opens
// them after the deploy.

interface FetchVisitsPayload {
  request_id: string;
}

interface UpdateVisitPayload {
  visit_id: string;
  state?: "awaiting_date" | "scheduled" | "completed" | "cancelled";
  scheduled_for?: string | null;
  scheduled_window?: string | null;
  notes?: string | null;
  outcome?: string | null;
  // Phase 100 — structured completion facts (free-text outcome stays
  // for operator color; these feed the vendor registry).
  completed_on_time?: boolean | null;
  no_show?: boolean;
  final_cost_cents?: number | null;
  /// Optional reply text that lands as a normal homeowner message in
  /// the parent thread alongside the state change. Lets Tom say
  /// "Booked Smith Plumbing for Tue 2pm — see you then" without
  /// switching to the reply composer.
  send_reply?: string;
  acknowledgement_required?: boolean;
}

async function handleFetchVisits(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: FetchVisitsPayload
) {
  if (!user) return json({ error: "auth required" }, 401);
  const requestId = compactString(payload.request_id);
  if (!requestId) return json({ error: "request_id required" }, 400);

  const { data: req, error: reqErr } = await service
    .from("chez_requests")
    .select("id, household_id, user_id")
    .eq("id", requestId)
    .maybeSingle();
  if (reqErr || !req) return json({ error: "request not found" }, 404);
  const isAdmin = isAdminUser(user);
  const isOwner = user.id === (req as { user_id: string }).user_id;
  if (!isAdmin && !isOwner) return json({ error: "not authorized" }, 403);

  // Self-healing reconciliation: any approved vendor proposal in this
  // thread that doesn't yet have a corresponding chez_visits row gets
  // one created. Idempotent — won't duplicate if visits already exist.
  // Catches approvals that happened before the 20261204 migration.
  const { data: approvedProposals } = await service
    .from("concierge_messages")
    .select("id, proposal")
    .eq("request_id", requestId)
    .eq("proposal_kind", "vendor");
  const proposals = (approvedProposals ?? []) as Array<{
    id: string;
    proposal: Record<string, unknown> | null;
  }>;
  const approvedVendorMessages = proposals.filter((m) => {
    const p = m.proposal as Record<string, unknown> | null;
    return p && p.status === "approved" && p.kind === "vendor";
  });
  if (approvedVendorMessages.length > 0) {
    const { data: existingVisits } = await service
      .from("chez_visits")
      .select("proposal_message_id")
      .eq("request_id", requestId);
    const existingIds = new Set(
      ((existingVisits ?? []) as Array<{ proposal_message_id: string | null }>)
        .map((v) => v.proposal_message_id)
        .filter((id): id is string => !!id)
    );
    const toCreate = approvedVendorMessages.filter((m) => !existingIds.has(m.id));
    for (const m of toCreate) {
      const vendorBlob = (m.proposal as Record<string, unknown>).vendor as Record<string, unknown> ?? {};
      const vendorName = String(vendorBlob.name ?? "").trim() || "(unnamed vendor)";
      const vendorPhone = vendorBlob.phone ? String(vendorBlob.phone) : null;
      const householdId = (req as { household_id: string }).household_id;

      // Phase 83.3 — Self-healing memory write. For approvals that
      // happened before the contractor-upsert path landed, also persist
      // the vendor here so the household catalog catches up. Idempotent
      // by (household_id, lower(name)).
      let contractorId: string | null = null;
      try {
        const { data: existingContractor } = await service
          .from("contractors")
          .select("id, chez_recommended_at")
          .eq("household_id", householdId)
          .ilike("company_name", vendorName)
          .maybeSingle();
        if (existingContractor) {
          contractorId = (existingContractor as { id: string }).id;
          const stamp = (existingContractor as { chez_recommended_at: string | null }).chez_recommended_at;
          if (!stamp) {
            await service
              .from("contractors")
              .update({ chez_request_id: requestId, chez_recommended_at: new Date().toISOString() })
              .eq("id", contractorId);
          }
        } else {
          const { data: insertedContractor } = await service
            .from("contractors")
            .insert({
              household_id: householdId,
              company_name: vendorName,
              category: vendorBlob.category ? String(vendorBlob.category) : null,
              phone: vendorPhone,
              website: vendorBlob.website ? String(vendorBlob.website) : null,
              address: vendorBlob.address ? String(vendorBlob.address) : null,
              rating: typeof vendorBlob.rating === "number" ? vendorBlob.rating : null,
              notes: vendorBlob.rationale ? String(vendorBlob.rationale) : null,
              source: "chez_recommendation",
              chez_request_id: requestId,
              chez_recommended_at: new Date().toISOString(),
            })
            .select("id")
            .single();
          if (insertedContractor) {
            contractorId = (insertedContractor as { id: string }).id;
          }
        }
      } catch (e) {
        console.warn("[fetch_visits] contractor backfill failed:", e);
      }

      await service.from("chez_visits").insert({
        household_id: householdId,
        request_id: requestId,
        proposal_message_id: m.id,
        vendor_name: vendorName,
        vendor_phone: vendorPhone,
        vendor_payload: vendorBlob,
        state: "awaiting_date",
        contractor_id: contractorId,
      });
    }
  }

  const { data: visits, error: visitsErr } = await service
    .from("chez_visits")
    .select("*")
    .eq("request_id", requestId)
    .order("created_at", { ascending: true });
  if (visitsErr) return json({ error: visitsErr.message }, 500);

  return json({ visits: visits ?? [] });
}

async function handleUpdateVisit(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: UpdateVisitPayload
) {
  if (!user || !isAdminUser(user)) {
    return json({ error: "admin only" }, 403);
  }
  const visitId = compactString(payload.visit_id);
  if (!visitId) return json({ error: "visit_id required" }, 400);

  const { data: visitRow, error: lookupErr } = await service
    .from("chez_visits")
    .select("*")
    .eq("id", visitId)
    .maybeSingle();
  if (lookupErr || !visitRow) return json({ error: "visit not found" }, 404);
  const visit = visitRow as {
    id: string;
    request_id: string;
    household_id: string;
    state: string;
    vendor_name: string;
  };

  const update: Record<string, unknown> = {};
  if (payload.state) update.state = payload.state;
  if (payload.scheduled_for !== undefined) update.scheduled_for = payload.scheduled_for;
  if (payload.scheduled_window !== undefined) update.scheduled_window = payload.scheduled_window;
  if (payload.notes !== undefined) update.notes = payload.notes;
  if (payload.outcome !== undefined) update.outcome = payload.outcome;
  if (payload.completed_on_time !== undefined) update.completed_on_time = payload.completed_on_time;
  if (payload.no_show !== undefined) update.no_show = !!payload.no_show;
  if (payload.final_cost_cents !== undefined) {
    update.final_cost_cents =
      typeof payload.final_cost_cents === "number" && payload.final_cost_cents >= 0
        ? Math.round(payload.final_cost_cents)
        : null;
  }
  if (payload.state === "completed") update.completed_at = new Date().toISOString();

  if (Object.keys(update).length > 0) {
    const { error: updateErr } = await service
      .from("chez_visits")
      .update(update)
      .eq("id", visitId);
    if (updateErr) return json({ error: updateErr.message }, 500);
  }

  // Fetch the parent request once — both the optional reply and the
  // state-change system message need request.user_id as the
  // concierge_messages.user_id anchor (visits don't carry user_id
  // themselves; that lives on the request).
  const stateChanged = !!payload.state && payload.state !== visit.state;
  const willSendReply = !!(payload.send_reply && payload.send_reply.trim().length > 0);
  if (stateChanged || willSendReply) {
    const { data: requestRow } = await service
      .from("chez_requests")
      .select("*")
      .eq("id", visit.request_id)
      .maybeSingle();
    if (requestRow) {
      const request = requestRow as ConciergeRequestRow;
      const now = new Date().toISOString();

      if (willSendReply) {
        const ackRequired = !!payload.acknowledgement_required;
        const content = payload.send_reply!.trim();
        await service.from("concierge_messages").insert({
          household_id: request.household_id,
          user_id: request.user_id,
          request_id: request.id,
          role: "concierge",
          content,
          attachments: [],
        });
        await service
          .from("chez_requests")
          .update({
            last_message_at: now,
            unread_for_user: true,
          })
          .eq("id", request.id);
        const inboxType = ackRequired ? "chez_reply_action_needed" : "chez_reply_informational";
        const inboxTitle = ackRequired
          ? `Chez needs your answer: ${request.summary}`
          : `Chez replied: ${request.summary}`;
        await service.from("inbox_items").insert({
          household_id: request.household_id,
          type: inboxType,
          title: inboxTitle,
          summary: content.slice(0, 280),
          seen: false,
          needs_action: ackRequired,
          action_type: ackRequired ? "chez_reply_action_needed" : null,
          action_completed: false,
          metadata: { chez_request_id: request.id, category: request.category },
          related_chez_request_id: request.id,
        });
      }

      if (stateChanged) {
        let body = "";
        if (payload.state === "scheduled") body = `Visit with ${visit.vendor_name} is on the calendar.`;
        else if (payload.state === "completed") body = `Visit with ${visit.vendor_name} completed.`;
        else if (payload.state === "cancelled") body = `Visit with ${visit.vendor_name} was cancelled.`;
        if (body) {
          await service.from("concierge_messages").insert({
            household_id: request.household_id,
            user_id: request.user_id,
            request_id: request.id,
            role: "system",
            content: body,
            attachments: [],
          });
        }
      }
    }
  }

  return json({ ok: true });
}

// ============================================================================
// Phase 83 — Ask Alfred: case-scoped chat for the cockpit copilot
// ============================================================================
// The cockpit's right sidebar lets the operator have a free-form
// conversation with Alfred about the active case. This action loads
// case context (request + dossier + thread + cached analysis) and
// asks Claude to answer. Single-shot for now; multi-turn comes once
// the operator has been using the surface long enough to know the
// shape of useful follow-ups.
interface AskAlfredPayload {
  request_id: string;
  question: string;
}

async function handleAskAlfred(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: AskAlfredPayload
) {
  if (!user || !isAdminUser(user)) {
    return json({ error: "admin only" }, 403);
  }
  const requestId = compactString(payload.request_id);
  const question = compactString(payload.question || "");
  if (!requestId || !question) {
    return json({ error: "request_id + question required" }, 400);
  }

  // 1. Load the case + everything Alfred can use for context.
  const { data: requestRow, error: reqErr } = await service
    .from("chez_requests")
    .select("*")
    .eq("id", requestId)
    .maybeSingle();
  if (reqErr || !requestRow) return json({ error: "request not found" }, 404);
  const request = requestRow as ConciergeRequestRow;

  const safe = async <T>(promise: PromiseLike<T>, label: string): Promise<T | null> => {
    try { return await promise; }
    catch (e) { console.warn(`[ask_alfred] ${label} failed:`, e); return null; }
  };
  const [householdRes, propertiesRes, contractorsRes, systemsRes, routinesRes, messagesRes, pastReqRes] = await Promise.all([
    safe(service.from("households").select("chez_profile, name").eq("id", request.household_id).maybeSingle(), "household"),
    safe(service.from("properties").select("*").eq("household_id", request.household_id), "properties"),
    safe(service.from("contractors").select("id, company_name, category, rating").eq("household_id", request.household_id), "contractors"),
    safe(service.from("home_systems").select("id, name, category, manufacturer, install_date, last_service_date").eq("household_id", request.household_id), "systems"),
    safe(service.from("routines").select("id, label, routine_kind, cadence_type, vendor_id").eq("household_id", request.household_id).is("archived_at", null), "routines"),
    safe(service.from("concierge_messages").select("role, content, proposal, created_at").eq("request_id", requestId).order("created_at", { ascending: true }), "messages"),
    safe(service.from("chez_requests").select("id, summary, category, status, created_at, resolved_at").eq("household_id", request.household_id).neq("id", requestId).order("created_at", { ascending: false }).limit(8), "past_requests"),
  ]);
  const household = (householdRes as { data?: { chez_profile?: Record<string, unknown>; name?: string } } | null)?.data ?? {};
  const properties = (propertiesRes as { data?: Array<Record<string, unknown>> } | null)?.data ?? [];
  const contractors = (contractorsRes as { data?: Array<Record<string, unknown>> } | null)?.data ?? [];
  const systems = (systemsRes as { data?: Array<Record<string, unknown>> } | null)?.data ?? [];
  const routines = (routinesRes as { data?: Array<Record<string, unknown>> } | null)?.data ?? [];
  const messages = (messagesRes as { data?: Array<Record<string, unknown>> } | null)?.data ?? [];
  const pastRequests = (pastReqRes as { data?: Array<Record<string, unknown>> } | null)?.data ?? [];

  const property = properties[0] || {};
  const profile = household.chez_profile || {};

  // 2. Build a compact context block. Caps each section so the prompt
  //    stays under ~6k tokens; Alfred is a single-shot responder.
  const propertyLine = property.year_built || property.city
    ? `${property.year_built ?? "?"} ${property.property_type ?? "home"} in ${property.city ?? ""}, ${property.state ?? ""} (${property.square_footage ?? "?"} sq ft)`
    : "Property details on file are sparse.";

  const profileBlob = JSON.stringify({
    about_us: (profile as Record<string, unknown>).about_us,
    vendor_preferences: (profile as Record<string, unknown>).vendor_preferences,
    logistics: (profile as Record<string, unknown>).logistics,
    spending_tiers: (profile as Record<string, unknown>).spending_tiers,
    communication: (profile as Record<string, unknown>).communication,
  }, null, 2);

  const systemsLines = systems.slice(0, 14).map((s) => `- ${s.name || s.category} (${s.category || "—"}${s.manufacturer ? `, ${s.manufacturer}` : ""}${s.last_service_date ? `, last ${s.last_service_date}` : ""})`).join("\n");
  const contractorsLines = contractors.slice(0, 14).map((c) => `- ${c.company_name} (${c.category || "—"}${c.rating ? `, ★ ${c.rating}` : ""})`).join("\n");
  const routinesLines = routines.slice(0, 8).map((r) => `- ${r.label || r.routine_kind} (${r.cadence_type || "—"})`).join("\n");

  const threadLines = messages.slice(-12).map((m) => {
    const who = m.role === "concierge" ? "Chez" : m.role === "user" ? "Homeowner" : "system";
    const text = (typeof m.content === "string" ? m.content : "") || (m.proposal ? `[${(m.proposal as Record<string, unknown>).kind ?? "proposal"} proposal]` : "");
    return `[${who}] ${String(text).slice(0, 280)}`;
  }).join("\n");

  const pastRequestLines = pastRequests.slice(0, 6).map((r) => `- ${r.id} (${r.category}, ${r.status}): ${r.summary}`).join("\n");

  // Optional: if there's a cached AI brief for this case in the runtime
  // memory of the Edge Function, we'd include it. We don't persist it
  // server-side, so we ask the question with whatever's on the row.
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return json({ answer: "Alfred is offline (no API key configured). Try again in a moment." });

  // Phase 95 — Combine the static voice rules + case dossier into one
  // cached system prompt. Cached blocks live in Anthropic's prompt
  // cache for 5 minutes; subsequent turns within that window only
  // re-bill the (small) user message + thread, not the (large) dossier.
  // Cache-eligible content must be ≥1024 tokens; the dossier almost
  // always clears that threshold once any household has data.
  //
  // The thread + question stay in the user message because they change
  // every turn. The dossier stays stable across turns of the same case.
  const systemPrompt = `You are Alfred, the case-scoped AI co-pilot for Chez Concierge agents. You answer the agent's questions directly. You're talking to a human operator, not the homeowner.

Voice rules:
- Concise, professional, no fluff. 1-3 sentences when direct; up to 5-6 when reasoning is needed.
- Reference SPECIFIC facts from the case context when they're relevant (year of home, vendor names, past cases, profile preferences). Don't invent.
- For cost / vendor / precedent questions, check PAST CASES + EXISTING VENDORS first before generalizing.
- Never give legal / regulatory advice — defer to "verify with a licensed pro" for code, permits, insurance.
- If the answer requires data you don't have, say so + point at where to find it.

Return ONLY the answer text — no preamble, no markdown headers, no quotes.

# CASE CONTEXT (static across this conversation)

## Active request
ID: ${request.id}
Category: ${request.category}
Status: ${request.status}
Summary: ${request.summary}
Opened: ${request.created_at}

## Property
${propertyLine}

## Customer profile
${profileBlob}

## Existing systems (${systems.length})
${systemsLines || "(none)"}

## Existing vendors (${contractors.length})
${contractorsLines || "(none)"}

## Active routines (${routines.length})
${routinesLines || "(none)"}

## Past Chez cases for this homeowner
${pastRequestLines || "(none)"}`;

  // The thread + question go in the user message because they change
  // turn-by-turn. Don't pollute the cached system block with these.
  const userPrompt = `# Recent thread (most recent ${Math.min(messages.length, 12)} messages)
${threadLines || "(no messages yet)"}

# AGENT QUESTION
${question}`;

  const result = await callClaudeWithDiscipline({
    supabase: service,
    apiKey,
    tag: "ask_alfred",
    max_tokens: 400,           // dropped from 600. answers are 1-6 sentences.
    system: systemPrompt,
    cache_system: true,        // 5-min ephemeral cache. ~90% input savings on multi-turn.
    messages: [{ role: "user", content: userPrompt }],
    request_id: request.id,
    household_id: request.household_id,
    user_id: user.id,
  });
  if (!result?.text) {
    return json({ answer: "Alfred is unavailable right now. Try again in a moment." });
  }
  return json({ answer: result.text });
}

// ============================================================================
// Phase 84 — Universal entity-level delegation
// ============================================================================
//
// `delegate_routine` / `delegate_contractor` / `delegate_task` already
// exist (Phase 80.1 / 80.2). This phase adds a generic
// `handleDelegateEntity` covering the remaining entity types — system,
// project, document, utility, insurance, vehicle. The shape mirrors
// `handleDelegateRoutine`: flip the chez_owned flag, create a parent
// chez_request when delegating (so Tom has a thread + push), system-
// message + admin email + push.

interface DelegateEntityPayload {
  entity_type: "system" | "project" | "document" | "utility" | "insurance" | "vehicle";
  entity_id: string;                          // for insurance: the policy key (e.g., "homeowners" or "auto_<vehicle_id>")
  delegated: boolean;
  notes?: string;
  property_id?: string;                       // required for "insurance" since insurance lives on properties
  household_id?: string;                      // admin-only — workbench operators pass this explicitly since they aren't tied to any household. task / routine / contractor have their own delegate_* actions.
}

const ENTITY_TABLES: Record<string, { table: string; idCol: string; labelCol?: string; categoryCol?: string }> = {
  system: { table: "home_systems", idCol: "id", labelCol: "name", categoryCol: "category" },
  project: { table: "property_projects", idCol: "id", labelCol: "name" },
  document: { table: "documents", idCol: "id", labelCol: "filename" },
  utility: { table: "utility_accounts", idCol: "id", labelCol: "provider_name" },
  vehicle: { table: "vehicles", idCol: "id" /* label built from year/make/model below */ },
};

const ENTITY_FRIENDLY_LABEL: Record<string, string> = {
  system: "home system",
  project: "project",
  document: "document",
  utility: "utility account",
  insurance: "insurance policy",
  vehicle: "vehicle",
};

const ENTITY_INSTRUCTION: Record<string, string> = {
  system: "Customer asked Chez to manage this home system end-to-end. Schedule routine maintenance, log service, track warranty, order parts when needed.",
  project: "Customer delegated this project to Chez. Source vendors, run quotes, negotiate pricing, manage the timeline + budget.",
  document: "Customer asked Chez to manage this document. File, organize, share with vendors when relevant, scan for gaps.",
  utility: "Customer asked Chez to manage this utility account. Audit bills for errors, negotiate rates, switch providers if a better deal appears.",
  insurance: "Customer asked Chez to manage this insurance policy. File claims, audit coverage against property value, shop renewals.",
  vehicle: "Customer asked Chez to manage this vehicle end-to-end. Service scheduling, recalls, registration renewal, insurance claims.",
};

async function handleDelegateEntity(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: DelegateEntityPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const entityType = payload.entity_type;
  const entityId = compactString(payload.entity_id);
  if (!entityType || !entityId) return json({ error: "entity_type + entity_id required" }, 400);
  // Phase 85.5: admin operators delegate on behalf of a homeowner via the
  // workbench. resolveHouseholdId accepts an explicit `household_id`
  // payload field for admin callers only — homeowners resolve from their
  // own user row.
  const householdId = await resolveHouseholdId(service, user, payload.household_id);
  if (!householdId) return json({ error: "no household" }, 404);

  const now = new Date().toISOString();
  let labelForThread = ENTITY_FRIENDLY_LABEL[entityType] ?? "entity";

  // Branch on entity_type — most types follow the same pattern but
  // insurance lives as a JSONB key on properties, so it has its own path.
  if (entityType === "insurance") {
    const propertyId = compactString(payload.property_id || "");
    if (!propertyId) return json({ error: "property_id required for insurance" }, 400);

    const { data: property, error: lookupErr } = await service
      .from("properties")
      .select("id, household_id, street, chez_owned_insurance")
      .eq("id", propertyId)
      .maybeSingle();
    if (lookupErr || !property) return json({ error: "property not found" }, 404);
    if ((property as { household_id: string }).household_id !== householdId) {
      return json({ error: "not authorized" }, 403);
    }

    const existing = ((property as { chez_owned_insurance: Record<string, unknown> }).chez_owned_insurance) ?? {};
    existing[entityId] = payload.delegated
      ? { owned: true, owned_at: now }
      : { owned: false, owned_at: null };

    const { error: updateErr } = await service
      .from("properties")
      .update({ chez_owned_insurance: existing })
      .eq("id", propertyId);
    if (updateErr) return json({ error: updateErr.message }, 500);

    labelForThread = `${entityId} insurance`;
  } else {
    const cfg = ENTITY_TABLES[entityType];
    if (!cfg) return json({ error: "unknown entity_type" }, 400);

    const selectCols = ["id", "household_id", cfg.labelCol, cfg.categoryCol]
      .filter((s): s is string => !!s)
      .concat(entityType === "vehicle" ? ["year", "make", "model"] : [])
      .join(", ");

    const { data: row, error: lookupErr } = await service
      .from(cfg.table)
      .select(selectCols)
      .eq("id", entityId)
      .maybeSingle();
    if (lookupErr || !row) return json({ error: `${entityType} not found` }, 404);
    if ((row as { household_id: string }).household_id !== householdId) {
      return json({ error: "not authorized" }, 403);
    }

    const { error: updateErr } = await service
      .from(cfg.table)
      .update({
        chez_owned: !!payload.delegated,
        chez_owned_at: payload.delegated ? now : null,
      })
      .eq("id", entityId);
    if (updateErr) return json({ error: updateErr.message }, 500);

    if (entityType === "vehicle") {
      const v = row as { year: number | null; make: string | null; model: string | null };
      labelForThread = [v.year, v.make, v.model].filter(Boolean).join(" ").trim() || "vehicle";
    } else if (cfg.labelCol) {
      const lbl = (row as Record<string, unknown>)[cfg.labelCol];
      if (typeof lbl === "string" && lbl.trim()) labelForThread = lbl.trim();
    }
  }

  // Create a parent chez_request only when delegating ON. Revoking
  // doesn't spawn a thread — it just flips the flag.
  if (payload.delegated) {
    const summary = `Standing engagement: ${labelForThread}`;
    const slaDueAt = await businessHoursDue(service);
    const { data: req } = await service
      .from("chez_requests")
      .insert({
        household_id: householdId,
        user_id: user.id,
        category: "coordinate_task",
        summary,
        context: {
          _kind: `standing_engagement_${entityType}`,
          entity_type: entityType,
          entity_id: entityId,
          property_id: payload.property_id ?? null,
          notes: payload.notes ?? "",
        },
        status: "open",
        sla_due_at: slaDueAt,
        last_message_at: now,
        unread_for_user: false,
        unread_for_admin: true,
      })
      .select("*")
      .single();
    if (req) {
      const r = req as { id: string };
      const instruction = ENTITY_INSTRUCTION[entityType] ?? "Customer delegated this entity to Chez.";

      // Wave 1 — server-assembled snapshot. Before this, delegate_entity
      // sent an EMPTY context and the operator had to dig for everything.
      // The entity_type maps 1:1 onto a snapshot kind; insurance gets the
      // common household + property sections only (the policy lives as a
      // JSONB key, not a row).
      let digest = "";
      try {
        const snapshot = await buildDelegationSnapshot(service, {
          kind: entityType as SnapshotKind,
          entityId: entityType === "insurance" ? undefined : entityId,
          householdId,
          propertyId: compactString(payload.property_id || "") || undefined,
        });
        if (snapshot) {
          await attachSnapshotToRequest(service, r.id, snapshot);
          digest = snapshotDigest(snapshot);
        }
      } catch (e) {
        console.warn(`[snapshot] delegate_entity (${entityType}) build failed:`, e);
      }

      await service.from("concierge_messages").insert({
        household_id: householdId,
        user_id: user.id,
        request_id: r.id,
        role: "system",
        content: `${instruction}${payload.notes ? `\n\nNotes from customer:\n${payload.notes}` : ""}${digest ? `\n\n${digest}` : ""}`,
        attachments: [],
      });

      // Phase 86E — playbook fires here too for delegate_entity. Same
      // category mapping as the other delegation paths so the operator
      // gets a consistent thread experience. project entities map to
      // get_quote (vendors + bids); everything else maps to
      // coordinate_task.
      const playbookCategory = entityType === "project" ? "get_quote" : "coordinate_task";
      const playbookPromise = runChezPlaybookForRequest({
        service,
        user,
        requestId: r.id,
        householdId,
        category: playbookCategory,
        summary,
        description: payload.notes ?? instruction,
      }).catch((e) => console.warn(`[playbook] delegate_entity (${entityType}) failed:`, e));

      await Promise.all([
        sendPush(
          serviceUrl,
          serviceRoleKey,
          adminUserIds(),
          `Customer delegated a ${ENTITY_FRIENDLY_LABEL[entityType] ?? "entity"} to Chez`,
          summary,
          { type: "chez_admin_request", request_id: r.id }
        ),
        sendAdminEmail(
          adminEmails(),
          `[Chez] New standing engagement: ${labelForThread}`,
          `${instruction}\n\n${payload.notes ?? ""}${digest ? `\n\n${digest}` : ""}\n\n${adminPortalUrl(r.id)}`,
          emailBody({
            preview: `Customer handed off a ${ENTITY_FRIENDLY_LABEL[entityType] ?? "entity"} to Chez.`,
            heading: "New standing engagement",
            intro: `The customer wants Chez to own management of "${labelForThread}" from now on.`,
            bodyText: `${payload.notes ?? "(no additional notes)"}${digest ? `\n\n${digest}` : ""}`,
            ctaLabel: "Open in admin portal",
            ctaUrl: adminPortalUrl(r.id),
          })
        ),
        playbookPromise,
      ]);
    }
  }

  return json({ ok: true });
}

// ============================================================================
// Phase 85.6 — Ownership consent flow (propose / approve / decline)
// ============================================================================
//
// Replaces the direct `delegate_entity` admin path with a consent loop:
//   1. Admin clicks "Propose Chez ownership" → server creates a chez_request
//      with category=ownership_request + a structured proposal message
//      listing the entities the operator wants to take over.
//   2. Homeowner sees an Approve/Decline card in iOS inbox.
//   3. On approve, decide_proposal handler walks the listed entities and
//      runs the existing delegate_* flow on each.
//   4. On decline, the 60-day cooldown table (chez_dismissed_ownership_proposals)
//      gets a row per entity so the admin can't re-pitch the same week.
//
// The proposal is single OR batched. Batched is critical for group toggles
// ("Chez handles all my systems") — without batching, a homeowner with 18
// systems would get 18 separate Approve/Decline cards.

interface ProposeOwnershipEntity {
  entity_type: "task" | "routine" | "contractor" | "system" | "project" | "document" | "utility" | "vehicle" | "insurance";
  entity_id: string;
  label?: string;          // Optional pre-resolved human label. If absent, server resolves from the entity table.
  property_id?: string;    // Required for insurance (which lives as a JSONB key on properties).
}

interface ProposeOwnershipPayload {
  household_id?: string;   // Admin-only override; homeowner callers resolve from their user row.
  entities: ProposeOwnershipEntity[];
  // Optional message preface ("Margaret, I noticed you've been asking
  // about boiler care — can Chez take this over?")
  preface?: string;
  // Optional "Standing engagement" parent request to append to. If not
  // provided, a new ownership_request thread is created.
  request_id?: string;
}

async function handleProposeOwnership(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: ProposeOwnershipPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const householdId = await resolveHouseholdId(service, user, payload.household_id);
  if (!householdId) return json({ error: "no household" }, 404);
  const entities = Array.isArray(payload.entities) ? payload.entities : [];
  if (entities.length === 0) return json({ error: "entities required" }, 400);
  if (entities.length > 50) return json({ error: "too many entities in one proposal (max 50)" }, 400);

  // Resolve the homeowner user_id for the household (proposals are routed
  // to the primary user; future: route to whichever user delegated last).
  const { data: userRows } = await service
    .from("users")
    .select("id, full_name, role")
    .eq("household_id", householdId)
    .limit(1);
  const homeownerUserId = (userRows && userRows[0]?.id) || null;
  if (!homeownerUserId) return json({ error: "no user on household" }, 404);

  // Resolve labels for any entity that didn't ship one. We look up the
  // table per entity_type from ENTITY_TABLES; for task/routine/contractor
  // (which have their own delegate handlers and aren't in ENTITY_TABLES)
  // we have to hardcode the table + label column.
  const labelTable: Record<string, { table: string; col: string }> = {
    task:       { table: "maintenance_tasks", col: "title" },
    routine:    { table: "routines",          col: "label" },
    contractor: { table: "contractors",       col: "company_name" },
    system:     { table: "home_systems",      col: "name" },
    project:    { table: "property_projects", col: "name" },
    document:   { table: "documents",         col: "filename" },
    utility:    { table: "utility_accounts",  col: "provider_name" },
    vehicle:    { table: "vehicles",          col: "make" },     // synthesized below
  };

  const resolved: Array<ProposeOwnershipEntity & { label: string }> = [];
  for (const e of entities) {
    const t = e.entity_type;
    if (!t) continue;
    let label = compactString(e.label || "");
    if (!label && labelTable[t]) {
      const cfg = labelTable[t];
      const cols = t === "vehicle" ? "year, make, model" : cfg.col;
      const { data: row } = await service
        .from(cfg.table)
        .select(cols)
        .eq("id", e.entity_id)
        .eq("household_id", householdId)
        .maybeSingle();
      if (row) {
        if (t === "vehicle") {
          const v = row as { year: number | null; make: string | null; model: string | null };
          label = [v.year, v.make, v.model].filter(Boolean).join(" ").trim();
        } else {
          label = String((row as Record<string, unknown>)[cfg.col] || "");
        }
      }
    }
    if (!label) label = `${t} ${e.entity_id.slice(0, 8)}`;
    resolved.push({ ...e, label });
  }

  // Filter out entities that are still on cooldown from a prior decline.
  // The cooldown query is one round-trip; we drop any entity that matches
  // a still-active row and report it in the response so the admin sees
  // "these 3 were excluded — homeowner declined within the last 60 days."
  const nowIso = new Date().toISOString();
  const { data: cooldownRows } = await service
    .from("chez_dismissed_ownership_proposals")
    .select("entity_type, entity_id, expires_at, note")
    .eq("household_id", householdId)
    .gt("expires_at", nowIso);
  const cooldownSet = new Set(
    ((cooldownRows ?? []) as Array<{ entity_type: string; entity_id: string }>)
      .map((r) => `${r.entity_type}:${r.entity_id}`)
  );
  const proposable = resolved.filter((e) => !cooldownSet.has(`${e.entity_type}:${e.entity_id}`));
  const skipped = resolved.filter((e) => cooldownSet.has(`${e.entity_type}:${e.entity_id}`));
  if (proposable.length === 0) {
    return json({
      error: "all entities are on cooldown from prior declines",
      skipped,
    }, 409);
  }

  // Find or create the parent chez_request.
  const now = new Date().toISOString();
  let requestId = compactString(payload.request_id || "");
  if (!requestId) {
    const summary = proposable.length === 1
      ? `Chez wants to handle: ${proposable[0].label}`
      : `Chez wants to handle ${proposable.length} ${proposable[0].entity_type}s`;
    const slaDueAt = await businessHoursDue(service);
    const { data: req, error: createErr } = await service
      .from("chez_requests")
      .insert({
        household_id: householdId,
        user_id: homeownerUserId,
        category: "ownership_request",
        summary,
        context: {
          entity_types: Array.from(new Set(proposable.map((e) => e.entity_type))),
          entity_count: proposable.length,
        },
        status: "open",
        sla_due_at: slaDueAt,
        last_message_at: now,
        unread_for_user: true,
        unread_for_admin: false,
        pending_proposal_count: 1,
      })
      .select("id")
      .single();
    if (createErr || !req) return json({ error: createErr?.message || "failed to create request" }, 500);
    requestId = (req as { id: string }).id;
  }

  // Insert the proposal message. The `kind: ownership_request` variant
  // carries the full entity list so the iOS card can render one row per
  // entity with Approve-all / Decline-all (and eventually a custom split).
  const prefaceText = compactString(payload.preface || "");
  const preview = proposable.slice(0, 3).map((e) => e.label).join(", ");
  const extras = proposable.length > 3 ? ` and ${proposable.length - 3} more` : "";
  const proposalContent = prefaceText
    || (proposable.length === 1
        ? `Hey — can Chez take over ${proposable[0].label}? We'll handle scheduling and follow-up so you don't have to think about it.`
        : `Hey — can Chez take over ${proposable.length} items for you? (${preview}${extras}). We'll handle scheduling and follow-up so you don't have to think about it.`);

  const { data: message, error: msgErr } = await service
    .from("concierge_messages")
    .insert({
      household_id: householdId,
      user_id: homeownerUserId,
      request_id: requestId,
      role: "concierge",
      content: proposalContent,
      attachments: [],
      proposal: {
        kind: "ownership_request",
        status: "pending",
        entities: proposable.map((e) => ({
          entity_type: e.entity_type,
          entity_id: e.entity_id,
          label: e.label,
          property_id: e.property_id,
        })),
      },
      proposal_kind: "ownership_request",
    })
    .select("*")
    .single();
  if (msgErr || !message) {
    return json({ error: msgErr?.message || "failed to insert proposal" }, 500);
  }

  // Stamp pending_ownership_request_id on each entity so the admin
  // portal can resolve "is this entity already proposed?" without
  // scanning concierge_messages. We do per-type updates because each
  // entity table has its own column.
  const tablesPerType: Record<string, string> = {
    task: "maintenance_tasks",
    routine: "routines",
    contractor: "contractors",
    system: "home_systems",
    project: "property_projects",
    document: "documents",
    utility: "utility_accounts",
    vehicle: "vehicles",
  };
  for (const e of proposable) {
    const table = tablesPerType[e.entity_type];
    if (!table) continue;        // insurance has no per-row pointer
    await service
      .from(table)
      .update({ pending_ownership_request_id: requestId })
      .eq("id", e.entity_id);
  }

  // Bump last_message_at + unread_for_user on the parent request.
  await service
    .from("chez_requests")
    .update({
      last_message_at: now,
      unread_for_user: true,
    })
    .eq("id", requestId);

  // Push to the homeowner.
  await sendPush(
    serviceUrl,
    serviceRoleKey,
    [homeownerUserId],
    "Chez wants to help",
    proposable.length === 1
      ? `Approve Chez to take over ${proposable[0].label}?`
      : `Approve Chez to take over ${proposable.length} items?`,
    { type: "chez_request_reply", request_id: requestId }
  );

  return json({
    ok: true,
    request_id: requestId,
    message_id: (message as { id: string }).id,
    proposed: proposable.length,
    skipped_for_cooldown: skipped,
  });
}

// ============================================================================
// Phase 84 — Group-level ownership ("Chez handles all my X")
// ============================================================================

const OWNERSHIP_GROUPS: Record<string, { table: string }> = {
  all_routines: { table: "routines" },
  all_systems: { table: "home_systems" },
  all_vendors: { table: "contractors" },
  all_projects: { table: "property_projects" },
  all_bills: { table: "utility_accounts" },
  all_documents: { table: "documents" },
  all_vehicles: { table: "vehicles" },
  // all_insurance is special-cased — see below.
};

interface SetOwnershipGroupPayload {
  group: string;        // one of the keys above OR "all_insurance"
  on: boolean;
  notes?: string;
}

async function handleSetOwnershipGroup(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: SetOwnershipGroupPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const group = compactString(payload.group);
  if (!group) return json({ error: "group required" }, 400);
  // Phase 85.5: admin household pass-through.
  const householdId = await resolveHouseholdId(service, user, (payload as { household_id?: string }).household_id);
  if (!householdId) return json({ error: "no household" }, 404);

  const now = new Date().toISOString();

  // 1. Update the ownership-groups JSONB on the household.
  const { data: householdRow } = await service
    .from("households")
    .select("id, chez_ownership_groups")
    .eq("id", householdId)
    .maybeSingle();
  const groups = ((householdRow as { chez_ownership_groups?: Record<string, unknown> } | null)?.chez_ownership_groups) ?? {};
  groups[group] = payload.on
    ? { on: true, set_at: now }
    : { on: false, set_at: now };
  await service
    .from("households")
    .update({ chez_ownership_groups: groups })
    .eq("id", householdId);

  // 2. Backfill: stamp every existing entity in the category as
  //    owned/unowned. Single SQL update per group keeps this fast even
  //    for households with hundreds of entities.
  let backfillCount = 0;
  if (group === "all_insurance") {
    // Insurance lives as JSONB on properties — load each property,
    // mark every key in chez_owned_insurance as on/off.
    const { data: props } = await service
      .from("properties")
      .select("id, chez_owned_insurance")
      .eq("household_id", householdId);
    for (const p of (props ?? []) as Array<{ id: string; chez_owned_insurance: Record<string, unknown> }>) {
      const existing = p.chez_owned_insurance ?? {};
      // For first-time turn-on, seed a default "homeowners" key. Subsequent
      // policies the homeowner adds will inherit via the new-entity hook.
      if (Object.keys(existing).length === 0 && payload.on) {
        existing["homeowners"] = { owned: true, owned_at: now };
      } else {
        for (const k of Object.keys(existing)) {
          existing[k] = payload.on
            ? { owned: true, owned_at: now }
            : { owned: false, owned_at: null };
        }
      }
      await service.from("properties").update({ chez_owned_insurance: existing }).eq("id", p.id);
      backfillCount += Object.keys(existing).length;
    }
  } else {
    const cfg = OWNERSHIP_GROUPS[group];
    if (!cfg) return json({ error: "unknown group" }, 400);
    const { data: rows, error: countErr } = await service
      .from(cfg.table)
      .update({
        chez_owned: payload.on,
        chez_owned_at: payload.on ? now : null,
      })
      .eq("household_id", householdId)
      .select("id");
    if (countErr) return json({ error: countErr.message }, 500);
    backfillCount = (rows ?? []).length;
  }

  // 3. Single summary chez_request — not one per entity.
  if (payload.on) {
    const friendly: Record<string, string> = {
      all_routines: "all routines",
      all_systems: "all home systems",
      all_vendors: "all vendor relationships",
      all_projects: "all projects",
      all_bills: "all utility accounts",
      all_documents: "all documents",
      all_vehicles: "all vehicles",
      all_insurance: "all insurance policies",
    };
    const summary = `Standing engagement: ${friendly[group] ?? group}`;
    const slaDueAt = await businessHoursDue(service);
    const { data: req } = await service
      .from("chez_requests")
      .insert({
        household_id: householdId,
        user_id: user.id,
        category: "coordinate_task",
        summary,
        context: {
          _kind: "standing_engagement_group",
          group,
          backfill_count: backfillCount,
          notes: payload.notes ?? "",
        },
        status: "open",
        sla_due_at: slaDueAt,
        last_message_at: now,
        unread_for_user: false,
        unread_for_admin: true,
      })
      .select("*")
      .single();
    if (req) {
      const r = req as { id: string };

      // Wave 1 — grouped snapshot: enumerates every entity in the
      // category (labels, cadences, vendors, est monthly spend) so the
      // operator sees exactly what was handed off, not just a count.
      let digest = "";
      try {
        const snapshot = await buildDelegationSnapshot(service, {
          kind: "group",
          householdId,
          group,
        });
        if (snapshot) {
          await attachSnapshotToRequest(service, r.id, snapshot);
          digest = snapshotDigest(snapshot);
        }
      } catch (e) {
        console.warn("[snapshot] set_ownership_group build failed:", e);
      }

      await service.from("concierge_messages").insert({
        household_id: householdId,
        user_id: user.id,
        request_id: r.id,
        role: "system",
        content: `Customer asked Chez to take over ${friendly[group] ?? group} (${backfillCount} item${backfillCount === 1 ? "" : "s"} now owned). New entries in this category will auto-delegate going forward.${payload.notes ? `\n\nNotes:\n${payload.notes}` : ""}${digest ? `\n\n${digest}` : ""}`,
        attachments: [],
      });
      await sendPush(
        serviceUrl,
        serviceRoleKey,
        adminUserIds(),
        "Customer delegated a category to Chez",
        summary,
        { type: "chez_admin_request", request_id: r.id }
      );
      await sendAdminEmail(
        adminEmails(),
        `[Chez] New group delegation: ${friendly[group] ?? group}`,
        `Customer flipped on ${friendly[group] ?? group}. ${backfillCount} existing items now owned by Chez.${digest ? `\n\n${digest}` : ""}\n\n${adminPortalUrl(r.id)}`,
        emailBody({
          preview: `${backfillCount} ${friendly[group] ?? group} now Chez-owned.`,
          heading: "New group delegation",
          intro: `The customer wants Chez to own ${friendly[group] ?? group} from now on.`,
          bodyText: `${backfillCount} existing items stamped owned. ${payload.notes ?? ""}${digest ? `\n\n${digest}` : ""}`,
          ctaLabel: "Open in admin portal",
          ctaUrl: adminPortalUrl(r.id),
        })
      );
    }
  }

  return json({ ok: true, backfill_count: backfillCount });
}

// ============================================================================
// Phase 84 — Workbench actions (admin-side ops audit trail)
// ============================================================================

interface WorkbenchActionPayload {
  household_id: string;
  entity_type: "system" | "routine" | "contractor" | "task" | "project" | "document" | "utility" | "insurance" | "vehicle";
  entity_id: string;
  action_type: string;                  // "schedule_visit" / "log_service" / "audit_bill" / etc.
  payload?: Record<string, unknown>;
  request_id?: string;                  // optional link to a case
}

async function handleWorkbenchAction(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: WorkbenchActionPayload
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const householdId = compactString(payload.household_id);
  const entityType = payload.entity_type;
  const entityId = compactString(payload.entity_id);
  const actionType = compactString(payload.action_type);
  if (!householdId || !entityType || !entityId || !actionType) {
    return json({ error: "household_id + entity_type + entity_id + action_type required" }, 400);
  }

  // Phase 85 PR 5E — every workbench button does real work, not just an
  // audit row. Dispatch on action_type before the audit insert so the
  // audit row can capture the resulting record id where one is created.
  // Errors at the side-effect layer surface to the operator with a clear
  // message — the audit row is rolled back by virtue of not being
  // inserted (we only insert it after a successful side-effect).
  const sidePayload = (payload.payload ?? {}) as Record<string, unknown>;
  let sideEffectResult: Record<string, unknown> | null = null;
  let sideEffectError: string | null = null;

  try {
    sideEffectResult = await runWorkbenchSideEffect({
      service,
      user,
      entityType,
      entityId,
      actionType,
      payload: sidePayload,
      householdId,
    });
  } catch (e) {
    console.error("[chez-concierge] workbench side-effect failed:", e);
    sideEffectError = (e as Error).message ?? String(e);
  }

  if (sideEffectError) {
    return json({ error: sideEffectError, action_type: actionType }, 500);
  }

  // Audit row goes in last so it carries any new entity ids from the
  // side-effect result. Failure to insert the audit row is logged but
  // doesn't fail the request — the side-effect already landed.
  const auditPayload = { ...sidePayload, ...(sideEffectResult ?? {}) };
  const { data: auditRow, error: auditErr } = await service
    .from("chez_workbench_actions")
    .insert({
      household_id: householdId,
      entity_type: entityType,
      entity_id: entityId,
      action_type: actionType,
      payload: auditPayload,
      performed_by_user_id: user.id,
      request_id: payload.request_id ?? null,
    })
    .select("*")
    .single();
  if (auditErr) {
    console.warn("[chez-concierge] audit insert failed (side-effect already landed):", auditErr);
  }

  // Phase 86B — auto-post a system message on the linked case thread for
  // high-signal workbench actions. The homeowner sees the operator's
  // work reflected in-thread instead of having to discover it by
  // noticing a task changed state. Only fires when the workbench action
  // came from inside a case (payload.request_id set).
  const requestId = payload.request_id;
  if (requestId && shouldPostSystemMessageForAction(actionType)) {
    const verb = workbenchVerbForCustomer(actionType);
    const entityLabel = extractEntityLabel(auditPayload);
    const msg = entityLabel ? `Chez ${verb}: ${entityLabel}.` : `Chez ${verb}.`;
    try {
      await service.from("concierge_messages").insert({
        request_id: requestId,
        role: "system",
        content: msg,
      });
      // Bump unread_for_user so the case rises in the homeowner's inbox.
      await service
        .from("chez_requests")
        .update({ unread_for_user: true, last_message_at: new Date().toISOString() })
        .eq("id", requestId);
    } catch (e) {
      console.warn("[workbench-action] auto-system-message failed:", e);
    }
  }

  // Phase 86B — also write to chez_activity_log so the iOS Dashboard's
  // existing "This week with Chez" tally card (Phase 85 PR 5c) picks
  // up workbench actions in the rollup. The fn() is SECURITY DEFINER
  // so it works through the service role without RLS friction.
  if (shouldPostSystemMessageForAction(actionType)) {
    const verb = workbenchVerbForCustomer(actionType);
    const entityLabel = extractEntityLabel(auditPayload);
    const title = entityLabel ? `${capitalizeFirst(verb)}: ${entityLabel}` : capitalizeFirst(verb);
    try {
      await service.rpc("log_chez_activity", {
        p_household_id: householdId,
        p_activity_type: actionType,
        p_title: title,
        p_description: null,
        p_entity_type: entityType,
        p_entity_id: entityId,
        p_cost_cents: typeof auditPayload.cost_cents === "number" ? auditPayload.cost_cents : null,
        p_occurred_at: new Date().toISOString(),
        p_surface_on_dashboard: true,
      });
    } catch (e) {
      console.warn("[workbench-action] chez_activity_log write failed:", e);
    }
  }

  return json({ ok: true, action: auditRow ?? null, side_effect: sideEffectResult });
}

function capitalizeFirst(s: string): string {
  if (!s) return s;
  return s[0].toUpperCase() + s.slice(1);
}

// ----------------------------------------------------------------------------
// Phase 86B — auto-message helpers.
//
// `shouldPostSystemMessageForAction` is the allowlist of action_types that
// the homeowner cares about seeing. Internal-only actions (admin notes,
// snooze, etc.) stay silent so the thread isn't noisy. The verb table is
// customer-facing copy — different from the operator-facing
// WORKBENCH_ACTION_LABELS in admin.js because the audience is different.
// ----------------------------------------------------------------------------
function shouldPostSystemMessageForAction(actionType: string): boolean {
  return new Set([
    "schedule_visit",
    "schedule_maintenance",
    "schedule",
    "schedule_service",
    "log_visit",
    "log_service",
    "complete_on_behalf",
    "audit_bill",
    "share_with_vendor",
    "handle_recall",
  ]).has(actionType);
}

function workbenchVerbForCustomer(actionType: string): string {
  switch (actionType) {
    case "schedule_visit": return "scheduled a vendor visit";
    case "schedule_maintenance": return "scheduled maintenance";
    case "schedule": return "scheduled a task";
    case "schedule_service": return "scheduled a service appointment";
    case "log_visit": return "logged a vendor visit";
    case "log_service": return "logged service";
    case "complete_on_behalf": return "completed this for you";
    case "audit_bill": return "audited a bill on your behalf";
    case "share_with_vendor": return "shared a document with the vendor";
    case "handle_recall": return "resolved a vehicle recall";
    default: return "took action";
  }
}

function extractEntityLabel(payload: Record<string, unknown>): string | null {
  const candidates: Array<string | undefined> = [
    typeof payload.entity_label === "string" ? payload.entity_label as string : undefined,
    typeof payload.title === "string" ? payload.title as string : undefined,
    typeof payload.vendor_name === "string" ? payload.vendor_name as string : undefined,
    typeof payload.system_name === "string" ? payload.system_name as string : undefined,
    typeof payload.task_title === "string" ? payload.task_title as string : undefined,
  ];
  return candidates.find((c) => typeof c === "string" && c.trim().length > 0) ?? null;
}

// ----------------------------------------------------------------------------
// Phase 85 PR 5E — workbench side-effect dispatcher.
//
// Each action_type maps to a real DB write. We keep the dispatcher in one
// function so the audit-row insert above stays generic and we can extend
// the action set without touching the wrapper. Returns a partial object
// merged into the audit payload (e.g. `{ visit_id: "..." }` so we can
// trace the audit row back to the side-effect).
// ----------------------------------------------------------------------------

async function runWorkbenchSideEffect(args: {
  service: ServiceClient;
  user: { id: string; email?: string | null };
  entityType: string;
  entityId: string;
  actionType: string;
  payload: Record<string, unknown>;
  householdId: string;
}): Promise<Record<string, unknown> | null> {
  const { service, user, entityType, entityId, actionType, payload, householdId } = args;

  const asString = (v: unknown): string | null =>
    typeof v === "string" && v.trim().length > 0 ? v.trim() : null;
  const asNumber = (v: unknown): number | null =>
    typeof v === "number" && Number.isFinite(v) ? v : null;
  const asIso = (v: unknown): string | null => {
    const s = asString(v);
    if (!s) return null;
    const d = new Date(s);
    return Number.isNaN(d.getTime()) ? null : d.toISOString();
  };

  switch (actionType) {
    // ----- Routines -----
    // routine_visits columns (Phase 55 + Phase 66 extensions):
    //   routine_id (FK), scheduled_date DATE NOT NULL, status TEXT,
    //   visit_state TEXT, target_window_start/end DATE,
    //   confirmed_at, confirmed_by, actual_cost_cents, notes.
    // Note: NO household_id — inherits via routine_id.
    case "schedule_visit": {
      const targetDate = asString(payload.scheduled_date) ?? asString(payload.target_window_start);
      if (!targetDate) throw new Error("scheduled_date required for schedule_visit (YYYY-MM-DD)");
      const dateOnly = targetDate.length >= 10 ? targetDate.slice(0, 10) : targetDate;
      const notes = asString(payload.notes);
      const { data, error } = await service
        .from("routine_visits")
        .insert({
          routine_id: entityId,
          scheduled_date: dateOnly,
          status: "upcoming",
          visit_state: "scheduled",
          target_window_start: dateOnly,
          confirmed_by: user.id,
          notes,
        })
        .select("id")
        .single();
      if (error) throw new Error(`routine_visits insert failed: ${error.message}`);

      // Phase 3.3: when the schedule lands on a chez_owned routine,
      // push the homeowner so the household sees "Chez scheduled
      // <vendor> for <date>" in their Notification Center. Admin-only
      // since handleWorkbenchAction is gated on isAdminUser. Wrapped
      // in try/catch so push failure never fails the schedule itself.
      try {
        const { data: routine } = await service
          .from("routines")
          .select("id, household_id, vendor_id, chez_owned, label")
          .eq("id", entityId)
          .maybeSingle();
        if (routine && routine.chez_owned === true) {
          let vendorName: string | null = null;
          if (routine.vendor_id) {
            const { data: vendor } = await service
              .from("contractors")
              .select("company_name")
              .eq("id", routine.vendor_id)
              .maybeSingle();
            vendorName = (vendor?.company_name as string | undefined) ?? null;
          }
          const { data: users } = await service
            .from("users")
            .select("id")
            .eq("household_id", routine.household_id);
          const recipientIds = (users ?? [])
            .map((u: { id: string }) => u.id)
            .filter((id: string | null | undefined): id is string => !!id);
          if (recipientIds.length > 0) {
            const serviceUrl = Deno.env.get("SUPABASE_URL") ?? "";
            const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
            const label = (routine.label as string | undefined)?.trim();
            const vendorPart = vendorName?.trim() && vendorName.trim().length > 0 ? vendorName.trim() : (label && label.length > 0 ? label : "Your vendor");
            const body = `${vendorPart} is booked for ${dateOnly}`;
            await sendPush(
              serviceUrl,
              serviceRoleKey,
              recipientIds,
              "Chez scheduled a visit",
              body,
              {
                type: "chez_routine_visit_scheduled",
                routine_id: entityId,
                visit_id: String(data.id),
                scheduled_date: dateOnly,
              }
            );
          }
        }
      } catch (pushError) {
        console.error("[chez-concierge] chez_owned routine push failed:", pushError);
      }

      return { visit_id: data.id, scheduled_date: dateOnly };
    }
    case "log_visit": {
      const occurredRaw = asString(payload.occurred_at) ?? new Date().toISOString();
      const dateOnly = occurredRaw.slice(0, 10);
      const cost = asNumber(payload.actual_cost_cents);
      const notes = asString(payload.notes);
      const { data, error } = await service
        .from("routine_visits")
        .insert({
          routine_id: entityId,
          scheduled_date: dateOnly,
          status: "confirmed",
          visit_state: "completed",
          confirmed_at: new Date().toISOString(),
          confirmed_by: user.id,
          actual_cost_cents: cost,
          notes,
        })
        .select("id")
        .single();
      if (error) throw new Error(`routine_visits insert failed: ${error.message}`);
      return { visit_id: data.id, occurred_at: dateOnly };
    }

    // ----- Systems -----
    // service_records columns: system_id, property_id (NOT NULL),
    // household_id, contractor_id, service_date (DATE NOT NULL),
    // service_type (NOT NULL), description (NOT NULL), cost (DECIMAL),
    // invoice_document_id, notes.
    case "log_service": {
      const occurredRaw = asString(payload.occurred_at) ?? new Date().toISOString();
      const serviceDate = occurredRaw.slice(0, 10);
      const cost = asNumber(payload.cost_cents);
      const costDecimal = cost !== null ? cost / 100 : null;
      const vendorId = asString(payload.contractor_id);
      const description = asString(payload.description) ?? asString(payload.notes) ?? "Service logged by Chez";
      const serviceType = asString(payload.service_type) ?? "maintenance";

      // Look up property_id from the home_systems row — service_records
      // requires it as NOT NULL.
      const { data: sys, error: sysErr } = await service
        .from("home_systems")
        .select("property_id")
        .eq("id", entityId)
        .maybeSingle();
      if (sysErr || !sys?.property_id) {
        throw new Error(`home_systems lookup failed: ${sysErr?.message ?? "missing property_id"}`);
      }

      const { data, error } = await service
        .from("service_records")
        .insert({
          system_id: entityId,
          property_id: sys.property_id,
          household_id: householdId,
          contractor_id: vendorId,
          service_date: serviceDate,
          service_type: serviceType,
          description,
          cost: costDecimal,
          notes: asString(payload.notes),
        })
        .select("id")
        .single();
      if (error) throw new Error(`service_records insert failed: ${error.message}`);

      const { error: stampErr } = await service
        .from("home_systems")
        .update({ last_service_date: serviceDate })
        .eq("id", entityId);
      if (stampErr) {
        console.warn("[workbench] home_systems.last_service_date stamp failed:", stampErr);
      }
      return { service_record_id: data.id, service_date: serviceDate };
    }
    case "schedule_maintenance": {
      const rawDate = asString(payload.scheduled_date) ?? asString(payload.next_due_date);
      if (!rawDate) throw new Error("scheduled_date required for schedule_maintenance (YYYY-MM-DD)");
      const dueDate = rawDate.slice(0, 10);
      const title = asString(payload.title) ?? "Scheduled by Chez";
      const description = asString(payload.notes) ?? "";
      const frequency = asString(payload.frequency) ?? "once";
      // Look up property_id from the system row.
      const { data: sys, error: sysErr } = await service
        .from("home_systems")
        .select("property_id")
        .eq("id", entityId)
        .maybeSingle();
      if (sysErr || !sys?.property_id) {
        throw new Error(`home_systems lookup failed: ${sysErr?.message ?? "missing property_id"}`);
      }
      const { data, error } = await service
        .from("maintenance_tasks")
        .insert({
          household_id: householdId,
          property_id: sys.property_id,
          system_id: entityId,
          title,
          description,
          frequency,
          scheduled_date: dueDate,
          next_due_date: dueDate,
          assignment_type: "vendor",
          chez_owned: true,
          chez_owned_at: new Date().toISOString(),
        })
        .select("id")
        .single();
      if (error) throw new Error(`maintenance_tasks insert failed: ${error.message}`);
      return { task_id: data.id, scheduled_date: dueDate };
    }

    // ----- Tasks -----
    case "schedule": {
      const rawDate = asString(payload.scheduled_date);
      if (!rawDate) throw new Error("scheduled_date required for schedule (YYYY-MM-DD)");
      const scheduled = rawDate.slice(0, 10);
      const { error } = await service
        .from("maintenance_tasks")
        .update({ scheduled_date: scheduled })
        .eq("id", entityId);
      if (error) throw new Error(`maintenance_tasks update failed: ${error.message}`);
      return { scheduled_date: scheduled };
    }
    case "complete_on_behalf": {
      const completedRaw = asString(payload.completed_at) ?? new Date().toISOString();
      const completedAt = completedRaw.slice(0, 10);
      const cost = asNumber(payload.cost_cents);
      const notes = asString(payload.notes);
      // Stamp last_completed_date and clear scheduled_date. We don't
      // recompute next_due_date server-side here — the iOS reconciler
      // recomputes it on the next reconcile pass via interval-aware
      // logic that lives in MaintenanceTaskReconciler. For tasks
      // without a frequency (one-shots), next_due_date stays null,
      // which surfaces them as resolved.
      const { data: taskRow, error: readErr } = await service
        .from("maintenance_tasks")
        .select("system_id, property_id, household_id, title, assigned_contractor_id")
        .eq("id", entityId)
        .maybeSingle();
      if (readErr) throw new Error(`task lookup failed: ${readErr.message}`);
      const { error } = await service
        .from("maintenance_tasks")
        .update({
          last_completed_date: completedAt,
          scheduled_date: null,
        })
        .eq("id", entityId);
      if (error) throw new Error(`maintenance_tasks update failed: ${error.message}`);
      // Phase 85 PR 5.1 — when the task is system-scoped and the
      // operator captured a cost, also write a service_records row so
      // it lands on the system's service history (matches the
      // homeowner's mental model: "what happened on this system,
      // when, and what did it cost?"). Cost-less notes-less
      // completions don't warrant the row.
      let serviceRecordId: string | null = null;
      if (taskRow?.system_id && taskRow.property_id && (cost !== null || notes)) {
        const { data: srv, error: srvErr } = await service
          .from("service_records")
          .insert({
            system_id: taskRow.system_id,
            property_id: taskRow.property_id,
            household_id: taskRow.household_id,
            contractor_id: taskRow.assigned_contractor_id,
            service_date: completedAt,
            service_type: "scheduled_maintenance",
            description: taskRow.title ?? "Task completed by Chez",
            cost: cost !== null ? cost / 100 : null,
            notes,
          })
          .select("id")
          .single();
        if (srvErr) {
          console.warn("[workbench] service_records insert failed:", srvErr);
        } else {
          serviceRecordId = (srv as { id: string }).id;
          if (taskRow.system_id) {
            await service
              .from("home_systems")
              .update({ last_service_date: completedAt })
              .eq("id", taskRow.system_id);
          }
        }
      }
      return { completed_at: completedAt, cost_cents: cost, service_record_id: serviceRecordId };
    }
    case "snooze": {
      // Push next_due_date out N days (default 7).
      const days = asNumber(payload.days) ?? 7;
      const { data: row, error: readErr } = await service
        .from("maintenance_tasks")
        .select("next_due_date")
        .eq("id", entityId)
        .maybeSingle();
      if (readErr || !row) throw new Error(`task not found: ${readErr?.message ?? "missing"}`);
      const base = row.next_due_date ? new Date(row.next_due_date) : new Date();
      base.setDate(base.getDate() + days);
      const newDue = base.toISOString().slice(0, 10);
      const { error } = await service
        .from("maintenance_tasks")
        .update({ next_due_date: newDue })
        .eq("id", entityId);
      if (error) throw new Error(`maintenance_tasks update failed: ${error.message}`);
      return { snoozed_until: newDue, days };
    }

    // ----- Vendors -----
    case "log_call": {
      const channel = asString(payload.channel) ?? "call";
      const direction = asString(payload.direction) ?? "outbound";
      const subject = asString(payload.subject);
      const notes = asString(payload.notes);
      const duration = asNumber(payload.duration_seconds);
      const { data, error } = await service
        .from("contractor_engagement_log")
        .insert({
          contractor_id: entityId,
          household_id: householdId,
          channel,
          direction,
          subject,
          notes,
          duration_seconds: duration,
          performed_by_user_id: user.id,
        })
        .select("id")
        .single();
      if (error) throw new Error(`engagement insert failed: ${error.message}`);
      return { engagement_id: data.id };
    }
    case "send_message": {
      // The composer lives client-side; server records the act.
      const { data, error } = await service
        .from("contractor_engagement_log")
        .insert({
          contractor_id: entityId,
          household_id: householdId,
          channel: asString(payload.channel) ?? "email",
          direction: "outbound",
          subject: asString(payload.subject),
          notes: asString(payload.notes) ?? asString(payload.body),
          performed_by_user_id: user.id,
        })
        .select("id")
        .single();
      if (error) throw new Error(`engagement insert failed: ${error.message}`);
      return { engagement_id: data.id };
    }

    // ----- Documents -----
    case "mark_filed": {
      const now = new Date().toISOString();
      const { error: updErr } = await service
        .from("documents")
        .update({ chez_filed_at: now, chez_filed_by_user_id: user.id })
        .eq("id", entityId);
      if (updErr) throw new Error(`documents update failed: ${updErr.message}`);
      const { data, error } = await service
        .from("document_share_log")
        .insert({
          document_id: entityId,
          household_id: householdId,
          action: "filed",
          notes: asString(payload.notes),
          performed_by_user_id: user.id,
        })
        .select("id")
        .single();
      if (error) console.warn("[workbench] document_share_log insert failed:", error);
      return { filed_at: now, log_id: data?.id ?? null };
    }
    case "share_with_vendor": {
      const contractorId = asString(payload.contractor_id);
      const email = asString(payload.email);
      const expiresAt = asIso(payload.expires_at);
      const shareUrl = asString(payload.share_url); // operator can paste a generated link in v1
      const { data, error } = await service
        .from("document_share_log")
        .insert({
          document_id: entityId,
          household_id: householdId,
          shared_with_contractor_id: contractorId,
          shared_with_email: email,
          share_url: shareUrl,
          expires_at: expiresAt,
          action: "shared",
          notes: asString(payload.notes),
          performed_by_user_id: user.id,
        })
        .select("id")
        .single();
      if (error) throw new Error(`document_share_log insert failed: ${error.message}`);
      return { share_log_id: data.id };
    }

    // ----- Utility (bills) -----
    case "audit_bill": {
      const billAmount = asNumber(payload.bill_amount_cents);
      if (billAmount == null) throw new Error("bill_amount_cents required for audit_bill");
      const priorAmount = asNumber(payload.prior_amount_cents);
      const variance = asNumber(payload.variance_cents) ??
        (priorAmount !== null ? billAmount - priorAmount : null);
      const { data, error } = await service
        .from("utility_bill_audits")
        .insert({
          utility_account_id: entityId,
          household_id: householdId,
          bill_period_start: asString(payload.bill_period_start),
          bill_period_end: asString(payload.bill_period_end),
          bill_amount_cents: billAmount,
          prior_amount_cents: priorAmount,
          variance_cents: variance,
          finding: asString(payload.finding),
          notes: asString(payload.notes),
          performed_by_user_id: user.id,
        })
        .select("id")
        .single();
      if (error) throw new Error(`utility_bill_audits insert failed: ${error.message}`);
      return { audit_id: data.id, variance_cents: variance };
    }
    case "draft_negotiation": {
      // Phase 86C — wired. Generates a counter-offer email body via
      // Claude sonnet-4-6 using the homeowner's standing instructions +
      // the utility bill context. Always-review for v1 per Tom's
      // approval: returns the draft, doesn't auto-send.
      //
      // Input payload shape (admin-supplied from the cockpit):
      //   {
      //     vendor_name?, vendor_email?, current_amount_cents,
      //     target_amount_cents?, target_reduction_pct?,
      //     scope?, operator_notes?
      //   }
      //
      // Returns { draft: { subject, body, suggested_target_cents, rationale } }.
      const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
      if (!apiKey) {
        return { drafted: false, reason: "anthropic_key_missing" };
      }
      // Pull the homeowner's chez_profile for standing instructions
      // (budget orientation, vendor prefs, communication tone). This is
      // the linchpin: the same Claude prompt produces different output
      // for a "premium prefers local" homeowner vs. a "budget avoid
      // chains" one.
      const { data: hh } = await service
        .from("households")
        .select("chez_profile, name")
        .eq("id", householdId)
        .maybeSingle();
      const profile = (hh?.chez_profile as Record<string, unknown> | null) ?? {};
      // Vendor + bill context.
      const utility: Record<string, unknown> = (payload.utility ?? {}) as Record<string, unknown>;
      const vendorName = asString(payload.vendor_name) ?? asString(utility.provider_name) ?? "the vendor";
      const currentCents = asNumber(payload.current_amount_cents) ?? asNumber(payload.current_cents) ?? null;
      const targetCents = asNumber(payload.target_amount_cents) ?? null;
      const targetPct = asNumber(payload.target_reduction_pct) ?? null;
      const scope = asString(payload.scope) ?? asString(utility.service_type) ?? "the service";
      const operatorNotes = asString(payload.operator_notes) ?? "";

      const moneyStr = (cents: number | null) =>
        cents == null ? "(unspecified)" : `$${(cents / 100).toFixed(2)}`;

      const systemPrompt = `You are Chez, a concierge service negotiating service-vendor pricing on behalf of a HNW homeowner. Write a counter-offer email body (no subject, no signature — those go elsewhere).

The email goes from Chez to the vendor. Brand voice: professional, warm but firm, direct about the ask, no em dashes, no overstated apologies. Two to four short paragraphs.

Goals:
1. Acknowledge the relationship + quoted price specifically
2. State the target price or target reduction clearly
3. Give a real-feeling reason for the counter (market comp, longer-term relationship, scope tradeoff)
4. Leave the door open with a soft close

DO NOT:
- Include "Dear" / "Sincerely" / closing signature lines (those are appended outside)
- Use em dashes (—) at all
- Invent specifics about the home or homeowner not provided
- Threaten to walk away

Output JSON only with this exact shape:
{
  "subject": "<email subject — short, no Re:>",
  "body": "<the email body, plain text with \\n line breaks>",
  "suggested_target_cents": <integer cents or null>,
  "rationale": "<1-sentence internal note explaining why this counter-offer is reasonable>"
}`;

      const userPrompt = `Vendor: ${vendorName}
Service / scope: ${scope}
Current quoted amount: ${moneyStr(currentCents)}
Target amount (if operator-specified): ${moneyStr(targetCents)}
Target reduction percent (if operator-specified): ${targetPct == null ? "(unspecified)" : `${targetPct}%`}

Homeowner standing instructions:
- About: ${JSON.stringify(profile.about_us || "(none)")}
- Vendor preferences: ${JSON.stringify(profile.vendor_preferences || {})}
- Spending tiers: ${JSON.stringify(profile.spending_tiers || {})}
- Communication tone: ${JSON.stringify(profile.communication || {})}

Operator notes on the negotiation strategy:
${operatorNotes || "(none — pick a reasonable counter based on market comp and the homeowner's budget orientation)"}

Generate the counter-offer JSON now.`;

      try {
        const result = await callClaudeWithDiscipline({
          supabase: service,
          apiKey,
          tag: "draft_negotiation",
          model: "claude-sonnet-4-6",
          max_tokens: 900,
          system: systemPrompt,
          messages: [{ role: "user", content: userPrompt }],
          user_id: user.id,
        });
        const text = result?.text ?? "";
        // Robust JSON parse — Claude usually returns clean JSON but
        // occasionally wraps it in ```json fences.
        const cleaned = text.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/i, "").trim();
        let parsed: Record<string, unknown> = {};
        try {
          parsed = JSON.parse(cleaned);
        } catch (_e) {
          // Fallback: return the raw text as body, no subject parse.
          return {
            drafted: true,
            draft: {
              subject: `Following up on the quote for ${scope}`,
              body: cleaned,
              suggested_target_cents: targetCents,
              rationale: "(model returned non-JSON; using as plaintext body)",
            },
          };
        }
        return {
          drafted: true,
          draft: {
            subject: typeof parsed.subject === "string" ? parsed.subject : `Following up on the quote for ${scope}`,
            body: typeof parsed.body === "string" ? parsed.body : "",
            suggested_target_cents: typeof parsed.suggested_target_cents === "number" ? parsed.suggested_target_cents : targetCents,
            rationale: typeof parsed.rationale === "string" ? parsed.rationale : "",
          },
        };
      } catch (e) {
        console.error("[draft_negotiation] Claude call failed:", e);
        return { drafted: false, reason: "claude_call_failed", error: String(e) };
      }
    }

    // ----- Vehicles -----
    case "schedule_service": {
      const rawDate = asString(payload.scheduled_date);
      if (!rawDate) throw new Error("scheduled_date required for schedule_service (YYYY-MM-DD)");
      const dueDate = rawDate.slice(0, 10);
      const title = asString(payload.title) ?? "Vehicle service (Chez-scheduled)";
      const description = asString(payload.notes) ?? "";
      const cost = asNumber(payload.cost_cents);
      const frequency = asString(payload.frequency) ?? "once";
      const { data, error } = await service
        .from("maintenance_tasks")
        .insert({
          household_id: householdId,
          vehicle_id: entityId,
          title,
          description,
          frequency,
          scheduled_date: dueDate,
          next_due_date: dueDate,
          assignment_type: "vendor",
          chez_owned: true,
          chez_owned_at: new Date().toISOString(),
          estimated_cost: cost !== null ? cost / 100 : null,
        })
        .select("id")
        .single();
      if (error) throw new Error(`maintenance_tasks insert failed: ${error.message}`);
      return { task_id: data.id, scheduled_date: dueDate, cost_cents: cost };
    }
    case "handle_recall": {
      // Tom passes the specific recall id in payload.recall_id; the
      // entityId is the vehicle. If recall_id is missing, mark every
      // open recall on the vehicle as resolved (rare, but supported).
      // vehicle_recalls uses { is_resolved BOOLEAN, resolved_date DATE }.
      const recallId = asString(payload.recall_id);
      const today = new Date().toISOString().slice(0, 10);
      const update = { is_resolved: true, resolved_date: today };
      const query = service.from("vehicle_recalls").update(update);
      const final = recallId
        ? query.eq("id", recallId)
        : query.eq("vehicle_id", entityId).eq("is_resolved", false);
      const { error } = await final;
      if (error) throw new Error(`vehicle_recalls update failed: ${error.message}`);
      return { resolved_date: today, recall_id: recallId };
    }

    default:
      // Unknown action — record audit only, no side-effect. Avoids
      // breaking the workbench when a new button gets shipped before
      // its server handler.
      return { dispatched: false, reason: "unhandled_action_type" };
  }
}

// ============================================================================
// Phase 84 — Reminders + Upcoming feed
// ============================================================================

interface CreateReminderPayload {
  household_id: string;
  due_at: string;             // ISO
  title: string;
  notes?: string;
  request_id?: string;
  entity_type?: string;
  entity_id?: string;
}

async function handleCreateReminder(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: CreateReminderPayload
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const householdId = compactString(payload.household_id);
  const dueAt = compactString(payload.due_at);
  const title = compactString(payload.title);
  if (!householdId || !dueAt || !title) {
    return json({ error: "household_id + due_at + title required" }, 400);
  }
  const { data, error } = await service
    .from("chez_reminders")
    .insert({
      household_id: householdId,
      due_at: dueAt,
      title,
      notes: payload.notes ?? null,
      request_id: payload.request_id ?? null,
      entity_type: payload.entity_type ?? null,
      entity_id: payload.entity_id ?? null,
      created_by_user_id: user.id,
    })
    .select("*")
    .single();
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true, reminder: data });
}

async function handleCompleteReminder(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { reminder_id: string }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const reminderId = compactString(payload.reminder_id);
  if (!reminderId) return json({ error: "reminder_id required" }, 400);
  const { error } = await service
    .from("chez_reminders")
    .update({ completed_at: new Date().toISOString() })
    .eq("id", reminderId);
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true });
}

interface FetchUpcomingPayload {
  window_days?: number;       // default 14
}

async function handleFetchUpcoming(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: FetchUpcomingPayload
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const windowDays = Math.max(1, Math.min(60, payload.window_days ?? 14));
  const now = new Date();
  const horizon = new Date(now.getTime() + windowDays * 24 * 60 * 60 * 1000);
  const horizonIso = horizon.toISOString();

  // Pull each source in parallel. Each row is normalized to the same
  // shape so the admin SPA can render them uniformly.
  const safe = async <T,>(p: PromiseLike<T>, label: string): Promise<T | null> => {
    try { return await p; }
    catch (e) { console.warn(`[upcoming] ${label} failed:`, e); return null; }
  };

  // Phase 84.1 — added maintenance_tasks + handyman_punch_items + routines
  // (for chez_owned enrichment of routine_visits). Without these sources
  // the Upcoming feed collapsed to whatever cases/visits existed, so
  // every click opened the cockpit and the surface was useless for
  // looking at the actual home-management backlog Tom has to work
  // through.
  const horizonDate = horizonIso.slice(0, 10);
  const overdueFloor = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);

  const [
    routineVisitsRes,
    chezVisitsRes,
    casesRes,
    remindersRes,
    documentsRes,
    vehiclesRes,
    householdsRes,
    routinesRes,
    maintenanceTasksRes,
    handymanPunchRes,
  ] = await Promise.all([
    safe(service.from("routine_visits").select("id, routine_id, household_id, target_window_start, visit_state").gte("target_window_start", now.toISOString()).lte("target_window_start", horizonIso).neq("visit_state", "completed").neq("visit_state", "cancelled").limit(200), "routine_visits"),
    safe(service.from("chez_visits").select("id, household_id, request_id, vendor_name, scheduled_for, state").gte("scheduled_for", now.toISOString()).lte("scheduled_for", horizonIso).neq("state", "completed").neq("state", "cancelled").limit(200), "chez_visits"),
    safe(service.from("chez_requests").select("id, household_id, summary, sla_due_at, status").eq("status", "open").lte("sla_due_at", horizonIso).limit(200), "cases"),
    safe(service.from("chez_reminders").select("id, household_id, due_at, title, notes, request_id, entity_type, entity_id").is("completed_at", null).lte("due_at", horizonIso).limit(200), "reminders"),
    safe(service.from("documents").select("id, household_id, filename, expiration_date").not("expiration_date", "is", null).lte("expiration_date", horizonIso).limit(100), "documents"),
    safe(service.from("vehicles").select("id, household_id, year, make, model, registration_expiry, insurance_expiry").or(`registration_expiry.lte.${horizonIso},insurance_expiry.lte.${horizonIso}`).limit(100), "vehicles"),
    safe(service.from("households").select("id, name").limit(500), "households"),
    safe(service.from("routines").select("id, label, chez_owned, vendor_id").is("archived_at", null).limit(2000), "routines"),
    safe(service.from("maintenance_tasks").select("id, household_id, title, scheduled_date, next_due_date, last_completed_date, chez_owned, assignment_type, needs_vendor, priority").is("archived_at", null).or(`scheduled_date.lte.${horizonDate},next_due_date.lte.${horizonDate}`).gte("next_due_date", overdueFloor).limit(300), "maintenance_tasks"),
    safe(service.from("handyman_punch_items").select("id, household_id, title, created_at, source").is("archived_at", null).is("completed_at", null).limit(500), "handyman_punch_items"),
  ]);

  const householdName = new Map<string, string>();
  for (const h of ((householdsRes as { data?: Array<{ id: string; name: string }> })?.data ?? [])) {
    householdName.set(h.id, h.name);
  }
  const hh = (id: string) => householdName.get(id) ?? "Unknown household";

  type Row = {
    id: string;
    type: string;
    household_id: string;
    household_name: string;
    due_at: string;
    title: string;
    sub: string | null;
    priority: string;     // 'overdue' | 'today' | 'this_week' | 'next_14_days'
    entity_type: string | null;
    entity_id: string | null;
    deep_link: string | null;
    // Phase 84.1 — when true, the entity behind this row is already
    // delegated to Chez (chez_owned on the underlying routine / task /
    // contractor). Drives the "Chez owns" badge in the admin UI and
    // floats these items to the top of the queue since they are
    // explicit operator commitments.
    chez_owned: boolean;
    // Phase 84.1 — surface what the operator should do. Mostly cosmetic
    // for now; future Phase 2 will turn this into a one-click action.
    suggested_action: "schedule" | "delegate" | "verify" | "complete" | null;
  };

  // Phase 84.1 — routines lookup so we can enrich routine_visits with
  // their chez_owned + display label. Map id → row.
  type RoutineRow = { id: string; label: string | null; chez_owned: boolean | null; vendor_id: string | null };
  const routinesById = new Map<string, RoutineRow>();
  for (const r of (((routinesRes as { data?: RoutineRow[] })?.data) ?? [])) {
    routinesById.set(r.id, r);
  }

  const items: Row[] = [];
  const priorityFor = (dueIso: string) => {
    const due = new Date(dueIso).getTime();
    const ms = due - now.getTime();
    if (ms < 0) return "overdue";
    const oneDay = 24 * 60 * 60 * 1000;
    if (ms < oneDay) return "today";
    if (ms < 7 * oneDay) return "this_week";
    return "next_14_days";
  };

  for (const r of (((routineVisitsRes as { data?: Array<{ id: string; routine_id: string; household_id: string; target_window_start: string }> })?.data) ?? [])) {
    const routine = routinesById.get(r.routine_id);
    const chezOwned = !!routine?.chez_owned;
    items.push({
      id: `rv:${r.id}`,
      type: "routine_visit",
      household_id: r.household_id,
      household_name: hh(r.household_id),
      due_at: r.target_window_start,
      title: routine?.label ? `${routine.label} visit` : "Routine visit",
      sub: chezOwned ? "Chez owns scheduling" : null,
      priority: priorityFor(r.target_window_start),
      entity_type: "routine",
      entity_id: r.routine_id,
      deep_link: null,
      chez_owned: chezOwned,
      suggested_action: chezOwned ? "schedule" : "delegate",
    });
  }
  for (const v of (((chezVisitsRes as { data?: Array<{ id: string; household_id: string; request_id: string; vendor_name: string; scheduled_for: string }> })?.data) ?? [])) {
    items.push({
      id: `cv:${v.id}`,
      type: "chez_visit",
      household_id: v.household_id,
      household_name: hh(v.household_id),
      due_at: v.scheduled_for,
      title: `Visit · ${v.vendor_name}`,
      sub: null,
      priority: priorityFor(v.scheduled_for),
      entity_type: null,
      entity_id: null,
      deep_link: `/admin#concierge?case=${v.request_id}`,
      chez_owned: true, // every chez_visit is by definition Chez-coordinated
      suggested_action: "verify",
    });
  }
  for (const c of (((casesRes as { data?: Array<{ id: string; household_id: string; summary: string; sla_due_at: string }> })?.data) ?? [])) {
    items.push({
      id: `case:${c.id}`,
      type: "case_sla",
      household_id: c.household_id,
      household_name: hh(c.household_id),
      due_at: c.sla_due_at,
      title: c.summary,
      sub: "SLA",
      priority: priorityFor(c.sla_due_at),
      entity_type: null,
      entity_id: null,
      deep_link: `/admin#concierge?case=${c.id}`,
      chez_owned: true,
      suggested_action: "verify",
    });
  }
  for (const r of (((remindersRes as { data?: Array<{ id: string; household_id: string; due_at: string; title: string; notes: string | null; request_id: string | null; entity_type: string | null; entity_id: string | null }> })?.data) ?? [])) {
    items.push({
      id: `rm:${r.id}`,
      type: "reminder",
      household_id: r.household_id,
      household_name: hh(r.household_id),
      due_at: r.due_at,
      title: r.title,
      sub: r.notes,
      priority: priorityFor(r.due_at),
      entity_type: r.entity_type,
      entity_id: r.entity_id,
      deep_link: r.request_id ? `/admin#concierge?case=${r.request_id}` : null,
      chez_owned: true,
      suggested_action: "complete",
    });
  }
  // Phase 84.1 — maintenance tasks coming due across all households.
  // Tagged with chez_owned so already-delegated tasks float up; non-
  // chez-owned tasks are delegation opportunities.
  for (const t of (((maintenanceTasksRes as { data?: Array<{ id: string; household_id: string; title: string; scheduled_date: string | null; next_due_date: string | null; chez_owned: boolean | null; assignment_type: string | null; needs_vendor: boolean | null; priority: string | null }> })?.data) ?? [])) {
    const due = t.scheduled_date ?? t.next_due_date;
    if (!due) continue;
    const dueIso = new Date(due + "T12:00:00Z").toISOString();
    const chezOwned = !!t.chez_owned;
    let sub: string | null = null;
    if (chezOwned) sub = "Chez owns this task";
    else if (t.needs_vendor) sub = "Needs a vendor";
    else if (t.assignment_type === "vendor") sub = "Vendor-managed";
    items.push({
      id: `mt:${t.id}`,
      type: "maintenance_task",
      household_id: t.household_id,
      household_name: hh(t.household_id),
      due_at: dueIso,
      title: t.title,
      sub,
      priority: priorityFor(dueIso),
      entity_type: "maintenance_task",
      entity_id: t.id,
      deep_link: null,
      chez_owned: chezOwned,
      suggested_action: chezOwned ? "schedule" : (t.needs_vendor ? "delegate" : "schedule"),
    });
  }
  // Phase 84.1 — open handyman punch items, summarized one-row-per-
  // household. Punch items have no inherent due date — they accumulate
  // until the next handyman visit — so the row's due_at uses the oldest
  // item's created_at as a "stale since" anchor.
  type PunchRow = { id: string; household_id: string; title: string; created_at: string; source: string | null };
  const punchByHousehold = new Map<string, PunchRow[]>();
  for (const p of (((handymanPunchRes as { data?: PunchRow[] })?.data) ?? [])) {
    const arr = punchByHousehold.get(p.household_id) ?? [];
    arr.push(p);
    punchByHousehold.set(p.household_id, arr);
  }
  for (const [householdId, list] of punchByHousehold.entries()) {
    if (list.length === 0) continue;
    list.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
    const oldest = list[0].created_at;
    const examples = list.slice(0, 3).map((p) => p.title).join(", ");
    items.push({
      id: `hp:${householdId}`,
      type: "handyman_punch",
      household_id: householdId,
      household_name: hh(householdId),
      due_at: oldest,
      title: `Handyman punch list · ${list.length} ${list.length === 1 ? "item" : "items"}`,
      sub: examples.length > 0 ? `e.g. ${examples}` : null,
      priority: priorityFor(oldest),
      entity_type: "handyman_punch",
      entity_id: householdId,
      deep_link: null,
      chez_owned: false,
      suggested_action: "schedule",
    });
  }
  for (const d of (((documentsRes as { data?: Array<{ id: string; household_id: string; filename: string; expiration_date: string }> })?.data) ?? [])) {
    items.push({
      id: `doc:${d.id}`,
      type: "document_expiring",
      household_id: d.household_id,
      household_name: hh(d.household_id),
      due_at: d.expiration_date,
      title: `Expiring: ${d.filename}`,
      sub: null,
      priority: priorityFor(d.expiration_date),
      entity_type: "document",
      entity_id: d.id,
      deep_link: null,
      chez_owned: false,
      suggested_action: "verify",
    });
  }
  for (const v of (((vehiclesRes as { data?: Array<{ id: string; household_id: string; year: number | null; make: string | null; model: string | null; registration_expiry: string | null; insurance_expiry: string | null }> })?.data) ?? [])) {
    const label = [v.year, v.make, v.model].filter(Boolean).join(" ").trim() || "Vehicle";
    if (v.registration_expiry && new Date(v.registration_expiry) <= horizon) {
      items.push({
        id: `vreg:${v.id}`,
        type: "vehicle_registration",
        household_id: v.household_id,
        household_name: hh(v.household_id),
        due_at: v.registration_expiry,
        title: `Registration expires: ${label}`,
        sub: null,
        priority: priorityFor(v.registration_expiry),
        entity_type: "vehicle",
        entity_id: v.id,
        deep_link: null,
        chez_owned: false,
        suggested_action: "verify",
      });
    }
    if (v.insurance_expiry && new Date(v.insurance_expiry) <= horizon) {
      items.push({
        id: `vins:${v.id}`,
        type: "vehicle_insurance",
        household_id: v.household_id,
        household_name: hh(v.household_id),
        due_at: v.insurance_expiry,
        title: `Insurance expires: ${label}`,
        sub: null,
        priority: priorityFor(v.insurance_expiry),
        entity_type: "vehicle",
        entity_id: v.id,
        deep_link: null,
        chez_owned: false,
        suggested_action: "verify",
      });
    }
  }

  // Sort: overdue first; within each priority band, chez_owned floats to
  // the top (operator commitments), then by due_at ascending.
  items.sort((a, b) => {
    const aOverdue = a.priority === "overdue" ? 0 : 1;
    const bOverdue = b.priority === "overdue" ? 0 : 1;
    if (aOverdue !== bOverdue) return aOverdue - bOverdue;
    const aChez = a.chez_owned ? 0 : 1;
    const bChez = b.chez_owned ? 0 : 1;
    if (aChez !== bChez) return aChez - bChez;
    return new Date(a.due_at).getTime() - new Date(b.due_at).getTime();
  });

  return json({ items, fetched_at: now.toISOString(), window_days: windowDays });
}

// ============================================================================
// Phase 84 — Operator-initiated case creation ("+ New case" in cockpit)
// ============================================================================
//
// Today every chez_request comes from the homeowner. This action lets
// Tom spawn a case from the admin side — useful when he gets a phone
// call, sees a vendor email, or wants to track work he's about to do
// proactively.

interface AdminSubmitPayload {
  household_id: string;
  category: "find_vendor" | "get_quote" | "schedule_visit" | "coordinate_task" | "find_handyman" | "general";
  summary: string;
  context?: Record<string, unknown>;
  initial_message?: string;
}

async function handleAdminSubmit(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: AdminSubmitPayload
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const householdId = compactString(payload.household_id);
  const summary = compactString(payload.summary);
  if (!householdId || !summary) return json({ error: "household_id + summary required" }, 400);

  // Resolve a primary user_id for the household. Cases attribute to the
  // homeowner's user_id (so iOS RLS reads work) but flag admin_initiated
  // so the iOS thread can show "Chez started this case for you."
  const { data: ownerRow } = await service
    .from("users")
    .select("id")
    .eq("household_id", householdId)
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
  const ownerId = (ownerRow as { id: string } | null)?.id;
  if (!ownerId) return json({ error: "household has no users" }, 400);

  const now = new Date().toISOString();
  const slaDueAt = await businessHoursDue(service);
  const { data: req, error: insertErr } = await service
    .from("chez_requests")
    .insert({
      household_id: householdId,
      user_id: ownerId,
      category: payload.category,
      summary,
      context: payload.context ?? {},
      status: "open",
      sla_due_at: slaDueAt,
      last_message_at: now,
      unread_for_user: false,
      unread_for_admin: true,
      admin_initiated: true,
    })
    .select("*")
    .single();
  if (insertErr || !req) return json({ error: insertErr?.message ?? "insert failed" }, 500);

  const r = req as { id: string };
  // System message in the new thread so the homeowner sees how this case
  // started.
  await service.from("concierge_messages").insert({
    household_id: householdId,
    user_id: ownerId,
    request_id: r.id,
    role: "system",
    content: `Chez started this case on your behalf.${payload.initial_message ? `\n\n${payload.initial_message}` : ""}`,
    attachments: [],
  });
  // Optional initial message from the operator.
  if (payload.initial_message && payload.initial_message.trim()) {
    await service.from("concierge_messages").insert({
      household_id: householdId,
      user_id: ownerId,
      request_id: r.id,
      role: "concierge",
      content: payload.initial_message.trim(),
      attachments: [],
    });
  }

  return json({ ok: true, request: req });
}

// ============================================================================
// Phase 84 — Households workbench data
// ============================================================================
//
// `fetch_households_list` returns one row per household with stats
// suitable for the admin Households tab list view. `fetch_household_workbench`
// returns the deep per-household data needed to render the workbench
// (every owned entity grouped by type + open cases + recent workbench
// actions). One round-trip for the whole panel.

// ============================================================================
// Phase 86A — handleFetchTodayBrief
// ============================================================================
// Cross-home triage payload powering the admin "Today" command center.
// Mirrors the shape of fetch_households_list: admin-only, parallel reads,
// graceful per-query failure via `safe()`.
//
// Returns four buckets the operator needs at the start of a shift:
//   - urgent_cases — chez_requests where SLA is overdue OR due within
//       6 hours OR there's an unread homeowner message waiting for admin.
//   - todays_visits — chez_visits with scheduled_for between now and
//       EOD (UTC; the iOS app handles local-time display per household tz).
//   - upcoming_visits — chez_visits scheduled +1d through +7d.
//   - recent_unread — concierge_messages from the last 48h where the
//       homeowner sent the message and the admin hasn't replied yet
//       (request.unread_for_admin = true). Already covered partially by
//       urgent_cases, but surfaced separately for "needs a quick reply"
//       triage.
//
// Each item is enriched with the household name + primary property address
// so the Today list renders as "[address] — [case summary]" without a
// second lookup. Households with no name fall back to the primary user's
// email; properties with no address fall back to the household name.
// ============================================================================

async function handleFetchTodayBrief(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);

  const safe = async <T,>(p: PromiseLike<T>, label: string): Promise<T | null> => {
    try { return await p; } catch (e) { console.warn(`[today_brief] ${label} failed:`, e); return null; }
  };

  const now = new Date();
  const sixHoursOut = new Date(now.getTime() + 6 * 60 * 60 * 1000).toISOString();
  const endOfDayUtc = new Date(now);
  endOfDayUtc.setUTCHours(23, 59, 59, 999);
  const endOfDayIso = endOfDayUtc.toISOString();
  const oneWeekOut = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString();
  const fortyEightHoursAgo = new Date(now.getTime() - 48 * 60 * 60 * 1000).toISOString();
  const nowIso = now.toISOString();

  // Parallel reads. Each is best-effort — a failure on one bucket doesn't
  // sink the whole brief.
  const [
    householdsRes,
    propertiesRes,
    requestsRes,
    visitsRes,
    recentMsgsRes,
  ] = await Promise.all([
    safe(service.from("households").select("id, name"), "households"),
    safe(service.from("properties").select("id, household_id, street, city, state, zip"), "properties"),
    safe(service.from("chez_requests")
      .select("id, household_id, category, summary, status, sla_due_at, last_message_at, unread_for_admin, pending_proposal_count, created_at")
      .in("status", ["open", "waiting_customer"])
      .order("sla_due_at", { ascending: true })
      .limit(200), "requests"),
    safe(service.from("chez_visits")
      .select("id, household_id, request_id, vendor_name, vendor_phone, state, scheduled_for, scheduled_window, notes")
      .in("state", ["awaiting_date", "scheduled", "in_progress"])
      .gte("scheduled_for", nowIso)
      .lte("scheduled_for", oneWeekOut)
      .order("scheduled_for", { ascending: true })
      .limit(100), "visits"),
    safe(service.from("concierge_messages")
      .select("id, request_id, role, content, created_at")
      .eq("role", "user")
      .gte("created_at", fortyEightHoursAgo)
      .order("created_at", { ascending: false })
      .limit(40), "recent_msgs"),
  ]);

  type HH = { id: string; name: string | null };
  type Prop = { id: string; household_id: string; street: string | null; city: string | null; state: string | null; zip: string | null };
  type Req = { id: string; household_id: string; category: string; summary: string; status: string; sla_due_at: string | null; last_message_at: string | null; unread_for_admin: boolean | null; pending_proposal_count: number | null; created_at: string };
  type Visit = { id: string; household_id: string; request_id: string | null; vendor_name: string | null; vendor_phone: string | null; state: string; scheduled_for: string | null; scheduled_window: string | null; notes: string | null };
  type Msg = { id: string; request_id: string; role: string; content: string; created_at: string };

  const households = ((householdsRes as { data?: HH[] })?.data ?? []) as HH[];
  const properties = ((propertiesRes as { data?: Prop[] })?.data ?? []) as Prop[];
  const requests = ((requestsRes as { data?: Req[] })?.data ?? []) as Req[];
  const visits = ((visitsRes as { data?: Visit[] })?.data ?? []) as Visit[];
  const recentMsgs = ((recentMsgsRes as { data?: Msg[] })?.data ?? []) as Msg[];

  // Lookup maps for enrichment. First property wins as "primary address".
  const householdName = new Map<string, string>();
  for (const h of households) householdName.set(h.id, h.name || "Household");
  const householdAddress = new Map<string, string>();
  for (const p of properties) {
    if (householdAddress.has(p.household_id)) continue; // first wins
    const street = (p.street || "").trim();
    const city = (p.city || "").trim();
    const stateCode = (p.state || "").trim();
    const pieces = [street, [city, stateCode].filter(Boolean).join(", ")].filter(Boolean);
    if (pieces.length > 0) householdAddress.set(p.household_id, pieces.join(" · "));
  }
  const addressOrName = (hid: string) =>
    householdAddress.get(hid) || householdName.get(hid) || "Unknown home";

  // ---------- urgent_cases ----------
  // Rules (any one qualifies):
  //   1. SLA is overdue (sla_due_at < now AND status = open)
  //   2. SLA is due within 6 hours
  //   3. unread_for_admin = true (homeowner sent something we haven't read)
  // Severity ranking: overdue > unread > due_soon. Caps at 30 rows so the
  // Today view doesn't degenerate into the full case list.
  const urgentCases = requests
    .map((r) => {
      const slaTime = r.sla_due_at ? new Date(r.sla_due_at).getTime() : null;
      const nowT = now.getTime();
      const isOverdue = r.status === "open" && slaTime !== null && slaTime < nowT;
      const isDueSoon = r.status === "open" && slaTime !== null && slaTime >= nowT && slaTime <= nowT + 6 * 60 * 60 * 1000;
      const isUnread = r.unread_for_admin === true;
      let severity: "overdue" | "unread" | "due_soon" | null = null;
      if (isOverdue) severity = "overdue";
      else if (isUnread) severity = "unread";
      else if (isDueSoon) severity = "due_soon";
      if (!severity) return null;
      return {
        id: r.id,
        household_id: r.household_id,
        household_address: addressOrName(r.household_id),
        // Phase 9d — surface the household NAME alongside the address so
        // the redesigned Today row can render "Burke · find vendor · 14
        // Bay Rd" (family name as the strong anchor, address as muted
        // suffix). The prior payload only emitted addressOrName which
        // collapsed the two — the new UI needs them separable.
        household_name: householdName.get(r.household_id) || null,
        category: r.category,
        summary: r.summary,
        status: r.status,
        sla_due_at: r.sla_due_at,
        last_message_at: r.last_message_at,
        unread_for_admin: r.unread_for_admin === true,
        pending_proposal_count: r.pending_proposal_count ?? 0,
        severity,
      };
    })
    .filter((x): x is NonNullable<typeof x> => x !== null);

  // Sort severity → SLA time. Overdue first (most past-due at top), then
  // unread, then due-soon (closest-due at top).
  const sevRank = { overdue: 0, unread: 1, due_soon: 2 } as const;
  urgentCases.sort((a, b) => {
    if (sevRank[a.severity] !== sevRank[b.severity]) return sevRank[a.severity] - sevRank[b.severity];
    const aT = a.sla_due_at ? new Date(a.sla_due_at).getTime() : 0;
    const bT = b.sla_due_at ? new Date(b.sla_due_at).getTime() : 0;
    return aT - bT;
  });
  urgentCases.splice(30);

  // ---------- todays_visits ----------
  const todaysVisits = visits
    .filter((v) => v.scheduled_for && v.scheduled_for <= endOfDayIso)
    .map((v) => ({
      id: v.id,
      household_id: v.household_id,
      household_address: addressOrName(v.household_id),
      household_name: householdName.get(v.household_id) || null,
      request_id: v.request_id,
      vendor_name: v.vendor_name,
      vendor_phone: v.vendor_phone,
      state: v.state,
      scheduled_for: v.scheduled_for,
      scheduled_window: v.scheduled_window,
    }));

  // ---------- upcoming_visits (tomorrow → +7d) ----------
  const upcomingVisits = visits
    .filter((v) => v.scheduled_for && v.scheduled_for > endOfDayIso)
    .map((v) => ({
      id: v.id,
      household_id: v.household_id,
      household_address: addressOrName(v.household_id),
      household_name: householdName.get(v.household_id) || null,
      request_id: v.request_id,
      vendor_name: v.vendor_name,
      vendor_phone: v.vendor_phone,
      state: v.state,
      scheduled_for: v.scheduled_for,
      scheduled_window: v.scheduled_window,
    }));

  // ---------- recent_unread ----------
  // Match concierge_messages to requests where admin still owes a reply.
  const requestById = new Map(requests.map((r) => [r.id, r]));
  const seen = new Set<string>(); // dedup by request_id (only show most-recent message per case)
  const recentUnread = recentMsgs
    .filter((m) => {
      if (seen.has(m.request_id)) return false;
      const req = requestById.get(m.request_id);
      if (!req || !req.unread_for_admin) return false;
      seen.add(m.request_id);
      return true;
    })
    .map((m) => {
      const req = requestById.get(m.request_id)!;
      return {
        message_id: m.id,
        request_id: m.request_id,
        household_id: req.household_id,
        household_address: addressOrName(req.household_id),
        household_name: householdName.get(req.household_id) || null,
        category: req.category,
        summary: req.summary,
        excerpt: m.content.length > 160 ? m.content.slice(0, 160) + "…" : m.content,
        sent_at: m.created_at,
      };
    });
  recentUnread.splice(15);

  // ---------- stats ----------
  const openCases = requests.filter((r) => r.status === "open" || r.status === "waiting_customer").length;
  const slaOverdue = urgentCases.filter((u) => u.severity === "overdue").length;
  const slaDueSoon = urgentCases.filter((u) => u.severity === "due_soon").length;
  const homesUnderManagement = new Set([...requests.map((r) => r.household_id), ...visits.map((v) => v.household_id)]).size;

  return json({
    urgent_cases: urgentCases,
    todays_visits: todaysVisits,
    upcoming_visits: upcomingVisits,
    recent_unread: recentUnread,
    stats: {
      open_cases: openCases,
      sla_overdue: slaOverdue,
      sla_due_soon: slaDueSoon,
      visits_today: todaysVisits.length,
      visits_this_week: todaysVisits.length + upcomingVisits.length,
      homes_under_management: homesUnderManagement,
    },
    fetched_at: now.toISOString(),
  });
}

async function handleFetchHouseholdsList(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);

  const safe = async <T,>(p: PromiseLike<T>, label: string): Promise<T | null> => {
    try { return await p; } catch (e) { console.warn(`[households_list] ${label} failed:`, e); return null; }
  };

  const [householdsRes, requestsRes, routinesRes, contractorsRes, tasksRes, systemsRes, projectsRes] = await Promise.all([
    // Phase 85.8: filter out soft-archived households (240 fully-empty
    // test rows from the 5/18 sweep). archived_at IS NULL keeps the
    // active set tight + the queue rail clean.
    safe(service.from("households").select("id, name, created_at, chez_ownership_groups").is("archived_at", null).order("created_at", { ascending: false }), "households"),
    safe(service.from("chez_requests").select("id, household_id, status, last_message_at, sla_due_at"), "requests"),
    safe(service.from("routines").select("id, household_id, chez_owned").eq("chez_owned", true), "routines"),
    safe(service.from("contractors").select("id, household_id, chez_owned").eq("chez_owned", true), "contractors"),
    safe(service.from("maintenance_tasks").select("id, household_id, chez_owned").eq("chez_owned", true), "tasks"),
    safe(service.from("home_systems").select("id, household_id, chez_owned").eq("chez_owned", true), "systems"),
    safe(service.from("property_projects").select("id, household_id, chez_owned").eq("chez_owned", true), "projects"),
  ]);

  type HH = { id: string; name: string; created_at: string; chez_ownership_groups: Record<string, { on?: boolean }> };
  const households = ((householdsRes as { data?: HH[] })?.data ?? []) as HH[];
  const requests = (((requestsRes as { data?: Array<{ id: string; household_id: string; status: string; last_message_at: string; sla_due_at: string }> })?.data) ?? []);
  const ownedRoutines = (((routinesRes as { data?: Array<{ household_id: string }> })?.data) ?? []);
  const ownedContractors = (((contractorsRes as { data?: Array<{ household_id: string }> })?.data) ?? []);
  const ownedTasks = (((tasksRes as { data?: Array<{ household_id: string }> })?.data) ?? []);
  const ownedSystems = (((systemsRes as { data?: Array<{ household_id: string }> })?.data) ?? []);
  const ownedProjects = (((projectsRes as { data?: Array<{ household_id: string }> })?.data) ?? []);

  // Bucket per household.
  const byHousehold = new Map<string, { open_cases: number; owned_count: number; group_count: number; last_activity_at: string | null }>();
  for (const h of households) {
    const groupCount = Object.values(h.chez_ownership_groups ?? {}).filter((g) => (g as { on?: boolean }).on === true).length;
    byHousehold.set(h.id, { open_cases: 0, owned_count: 0, group_count: groupCount, last_activity_at: null });
  }
  for (const r of requests) {
    const stat = byHousehold.get(r.household_id);
    if (!stat) continue;
    if (r.status === "open" || r.status === "waiting_customer") stat.open_cases += 1;
    if (r.last_message_at && (!stat.last_activity_at || new Date(r.last_message_at) > new Date(stat.last_activity_at))) {
      stat.last_activity_at = r.last_message_at;
    }
  }
  const inc = (id: string) => { const s = byHousehold.get(id); if (s) s.owned_count += 1; };
  for (const r of ownedRoutines) inc(r.household_id);
  for (const r of ownedContractors) inc(r.household_id);
  for (const r of ownedTasks) inc(r.household_id);
  for (const r of ownedSystems) inc(r.household_id);
  for (const r of ownedProjects) inc(r.household_id);

  const items = households.map((h) => ({
    id: h.id,
    name: h.name,
    created_at: h.created_at,
    open_cases: byHousehold.get(h.id)?.open_cases ?? 0,
    owned_count: byHousehold.get(h.id)?.owned_count ?? 0,
    group_count: byHousehold.get(h.id)?.group_count ?? 0,
    last_activity_at: byHousehold.get(h.id)?.last_activity_at ?? null,
    chez_ownership_groups: h.chez_ownership_groups ?? {},
  }));

  // Sort: most-recent-activity first (households with no activity sink to bottom).
  items.sort((a, b) => {
    const aT = a.last_activity_at ? new Date(a.last_activity_at).getTime() : 0;
    const bT = b.last_activity_at ? new Date(b.last_activity_at).getTime() : 0;
    return bT - aT;
  });

  return json({ households: items });
}

interface FetchHouseholdWorkbenchPayload {
  household_id: string;
}

async function handleFetchHouseholdWorkbench(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: FetchHouseholdWorkbenchPayload
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const householdId = compactString(payload.household_id);
  if (!householdId) return json({ error: "household_id required" }, 400);

  const safe = async <T,>(p: PromiseLike<T>, label: string): Promise<T | null> => {
    try { return await p; } catch (e) { console.warn(`[workbench] ${label} failed:`, e); return null; }
  };

  const [
    householdRes, propertiesRes, usersRes, familyRes,
    routinesRes, systemsRes, contractorsRes, tasksRes, projectsRes,
    documentsRes, utilitiesRes, vehiclesRes,
    casesRes, workbenchActionsRes, remindersRes, punchItemsRes,
    vehicleServiceRes, vehicleRecallsRes, bundleCustomSubitemsRes,
    utilityBillAuditsRes,
  ] = await Promise.all([
    safe(service.from("households").select("*").eq("id", householdId).maybeSingle(), "household"),
    safe(service.from("properties").select("*").eq("household_id", householdId), "properties"),
    safe(service.from("users").select("id, full_name, email, role").eq("household_id", householdId), "users"),
    safe(service.from("family_members").select("*").eq("household_id", householdId), "family"),
    safe(service.from("routines").select("*").eq("household_id", householdId).is("archived_at", null), "routines"),
    safe(service.from("home_systems").select("*").eq("household_id", householdId), "systems"),
    safe(service.from("contractors").select("*").eq("household_id", householdId), "contractors"),
    safe(service.from("maintenance_tasks").select("*").eq("household_id", householdId).eq("is_archived", false), "tasks"),
    safe(service.from("property_projects").select("*").eq("household_id", householdId), "projects"),
    safe(service.from("documents").select("id, household_id, filename, category, mime_type, expiration_date, chez_owned, chez_owned_at, vehicle_id, project_id, chez_filed_at, created_at, notes, pending_ownership_request_id").eq("household_id", householdId).limit(200), "documents"),
    safe(service.from("utility_accounts").select("*").eq("household_id", householdId), "utilities"),
    safe(service.from("vehicles").select("*").eq("household_id", householdId), "vehicles"),
    safe(service.from("chez_requests").select("*").eq("household_id", householdId).neq("status", "resolved").order("last_message_at", { ascending: false }), "open_cases"),
    safe(service.from("chez_workbench_actions").select("*").eq("household_id", householdId).order("created_at", { ascending: false }).limit(20), "workbench_actions"),
    safe(service.from("chez_reminders").select("*").eq("household_id", householdId).is("completed_at", null).order("due_at", { ascending: true }).limit(20), "reminders"),
    // Phase 85.5: include the household's pending handyman punch list so
    // the admin workbench can render the Handyman tab + the Upcoming
    // "Handyman punch list" row click has somewhere to drill into.
    safe(service.from("handyman_punch_items").select("id, household_id, title, notes, created_at, source").is("archived_at", null).is("completed_at", null).order("created_at", { ascending: true }), "punch_items"),
    // Phase 85.6 Phase C: vehicle service history. Needed by the rebuilt
    // Vehicle focused panel which mirrors the iOS VehicleDetailView's
    // service-history section. Loaded once per workbench fetch; the
    // panel filters to the focused vehicle client-side.
    safe(service.from("vehicle_service_records").select("*").eq("household_id", householdId).order("service_date", { ascending: false }).limit(100), "vehicle_service"),
    // Phase 85.6 Phase C: vehicle recalls (open + resolved) so the
    // panel can show the full recall history, not just the open ones
    // already loaded into focused-entity relations.
    safe(service.from("vehicle_recalls").select("*").eq("household_id", householdId), "vehicle_recalls"),
    // Phase 85.6 Phase C: bundle custom subitems. iOS Task detail
    // renders these as "Custom additions" under a bundle parent task.
    // Filtered to active rows (archived_at NULL, used_at NULL).
    safe(service.from("bundle_custom_subitems").select("*").eq("household_id", householdId).is("archived_at", null).is("used_at", null), "bundle_custom_subitems"),
    // Phase 85.7: utility bill audit history. Powers the rebuilt Bill
    // focused panel's "Chez audit timeline" section. One row per audit.
    safe(service.from("utility_bill_audits").select("*").eq("household_id", householdId).order("created_at", { ascending: false }).limit(50), "utility_bill_audits"),
  ]);

  return json({
    household: (householdRes as { data?: unknown } | null)?.data ?? null,
    properties: ((propertiesRes as { data?: unknown[] })?.data) ?? [],
    users: ((usersRes as { data?: unknown[] })?.data) ?? [],
    family_members: ((familyRes as { data?: unknown[] })?.data) ?? [],
    routines: ((routinesRes as { data?: unknown[] })?.data) ?? [],
    home_systems: ((systemsRes as { data?: unknown[] })?.data) ?? [],
    contractors: ((contractorsRes as { data?: unknown[] })?.data) ?? [],
    tasks: ((tasksRes as { data?: unknown[] })?.data) ?? [],
    projects: ((projectsRes as { data?: unknown[] })?.data) ?? [],
    documents: ((documentsRes as { data?: unknown[] })?.data) ?? [],
    utility_accounts: ((utilitiesRes as { data?: unknown[] })?.data) ?? [],
    vehicles: ((vehiclesRes as { data?: unknown[] })?.data) ?? [],
    open_cases: ((casesRes as { data?: unknown[] })?.data) ?? [],
    workbench_actions: ((workbenchActionsRes as { data?: unknown[] })?.data) ?? [],
    reminders: ((remindersRes as { data?: unknown[] })?.data) ?? [],
    handyman_punch_items: ((punchItemsRes as { data?: unknown[] })?.data) ?? [],
    vehicle_service_records: ((vehicleServiceRes as { data?: unknown[] })?.data) ?? [],
    vehicle_recalls: ((vehicleRecallsRes as { data?: unknown[] })?.data) ?? [],
    bundle_custom_subitems: ((bundleCustomSubitemsRes as { data?: unknown[] })?.data) ?? [],
    utility_bill_audits: ((utilityBillAuditsRes as { data?: unknown[] })?.data) ?? [],
  });
}

// ============================================================================
// Phase 84 PR 4 — Project negotiation tracking
// ============================================================================

interface AddProjectNegotiationTurnPayload {
  quote_id?: string;
  // The two sides of a negotiation. "chez" is the operator messaging the
  // vendor on behalf of the homeowner; "vendor" is the response coming
  // back. We don't track "homeowner" here — when the homeowner approves
  // a final number, we close the loop via the existing proposal flow.
  from?: "chez" | "vendor";
  message?: string;
  price_cents?: number;
  // Optional terms metadata so future shapes (payment schedule,
  // exclusions, scope deltas) can ride alongside without a column add.
  terms?: Record<string, unknown>;
}

interface NegotiationTurn {
  from: "chez" | "vendor";
  message: string;
  price_cents?: number;
  terms?: Record<string, unknown>;
  sent_at: string;
  performed_by_user_id?: string;
}

/// Operator-only — appends one row to `project_quotes.negotiation_history`.
/// The history is ordered chronologically; UI renders newest first by
/// reversing on read so we don't have to deal with prepend semantics
/// in JSONB. Service role write because we don't expose project_quotes
/// mutations to the homeowner via RLS today.
async function handleAddProjectNegotiationTurn(
  service: ServiceClient,
  user: { id: string; email: string },
  payload: AddProjectNegotiationTurnPayload
): Promise<Response> {
  if (!isAdminUser(user)) {
    return json({ error: "admin only" }, 403);
  }
  const quoteId = payload.quote_id?.trim();
  const from = payload.from;
  const message = payload.message?.trim() ?? "";
  if (!quoteId || !from || !message) {
    return json(
      { error: "quote_id, from, and message are required" },
      400
    );
  }
  if (from !== "chez" && from !== "vendor") {
    return json({ error: "from must be 'chez' or 'vendor'" }, 400);
  }

  // Fetch existing history so we can append. Postgres array_append on
  // JSONB is awkward through PostgREST; round-tripping the array is
  // simplest and the array is bounded in practice (a real negotiation
  // is < 50 turns).
  const { data: row, error: fetchErr } = await service
    .from("project_quotes")
    .select("id, project_id, negotiation_history")
    .eq("id", quoteId)
    .maybeSingle();
  if (fetchErr) {
    console.error("[chez-concierge] negotiation fetch failed:", fetchErr);
    return json({ error: fetchErr.message }, 500);
  }
  if (!row) {
    return json({ error: "quote not found" }, 404);
  }

  const existing: NegotiationTurn[] = Array.isArray(
    (row as { negotiation_history?: unknown }).negotiation_history
  )
    ? ((row as { negotiation_history: NegotiationTurn[] }).negotiation_history)
    : [];

  const turn: NegotiationTurn = {
    from,
    message,
    price_cents: typeof payload.price_cents === "number" ? payload.price_cents : undefined,
    terms: payload.terms && typeof payload.terms === "object" ? payload.terms : undefined,
    sent_at: new Date().toISOString(),
    performed_by_user_id: user.id,
  };
  const next = [...existing, turn];

  const { error: updateErr } = await service
    .from("project_quotes")
    .update({
      negotiation_history: next,
      updated_at: new Date().toISOString(),
    })
    .eq("id", quoteId);
  if (updateErr) {
    console.error("[chez-concierge] negotiation update failed:", updateErr);
    return json({ error: updateErr.message }, 500);
  }

  return json({
    ok: true,
    quote_id: quoteId,
    project_id: (row as { project_id?: string }).project_id,
    turn_count: next.length,
    turn,
  });
}

// ============================================================================
// Helpers
// ============================================================================

// Note: `householdIdForUser` is defined once above near the auth helpers.
// Deno rejects duplicate function declarations at parse time, which would
// boot-error the entire function — don't add a second copy here.

async function businessHoursDue(service: ServiceClient): Promise<string> {
  // Reuse the public.chez_business_hours_due() Postgres function defined
  // in the 20261201 migration. Same call shape as `handleSubmit` —
  // takes a start_at arg. Falls back to naive +24h on any failure.
  const { data, error } = await service.rpc(
    "chez_business_hours_due",
    { start_at: new Date().toISOString() }
  );
  if (error || !data) {
    const fallback = new Date(Date.now() + 24 * 60 * 60 * 1000);
    return fallback.toISOString();
  }
  return data as string;
}

// ============================================================================
// Phase 84.5 — Home Assessment (Free Handyman Assessment + 3-mode onboarding)
// ============================================================================
//
// Homeowner-facing actions. Field-side actions (handyman-side capture +
// ingestion) live in handyman-provider/index.ts. Shared workspace table:
// public.home_assessments (migration 20261210).

interface RequestHomeAssessmentPayload {
  property_id: string;
  notes?: string;
  pre_visit_notes?: string;
  pre_visit_photos?: string[];
}
interface CancelHomeAssessmentPayload {
  assessment_id: string;
  reason?: string;
}
interface RequestAssessmentReschedulePayload {
  assessment_id: string;
  notes?: string;
  preferred_dates?: string[];
}
interface SubmitAssessmentReviewPayload {
  assessment_id: string;
}
interface RequestAssessmentCorrectionsPayload {
  assessment_id: string;
  items: Array<{
    section: "system" | "contractor" | "routine" | "document" | "attribute";
    entity_id?: string;
    note: string;
  }>;
}
interface UpdatePreVisitDataPayload {
  assessment_id: string;
  pre_visit_notes?: string;
  pre_visit_photos?: string[];
  captured_attributes?: Record<string, unknown>;
}
interface FetchHomeAssessmentPayload {
  assessment_id?: string;
  property_id?: string;
}

async function handleRequestHomeAssessment(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: RequestHomeAssessmentPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const propertyId = compactString(payload.property_id);
  if (!propertyId) return json({ error: "property_id required" }, 400);
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "no household" }, 404);

  const { data: property, error: propErr } = await service
    .from("properties")
    .select("id, household_id, attributes, address_line_1, city, state, zip_code")
    .eq("id", propertyId)
    .maybeSingle();
  if (propErr || !property) return json({ error: "property not found" }, 404);
  if ((property as { household_id: string }).household_id !== householdId) {
    return json({ error: "not authorized" }, 403);
  }

  const { data: assessment, error: rpcErr } = await service.rpc(
    "find_or_create_home_assessment",
    { p_property_id: propertyId, p_household_id: householdId }
  );
  if (rpcErr || !assessment) return json({ error: rpcErr?.message ?? "create failed" }, 500);
  const a = (Array.isArray(assessment) ? assessment[0] : assessment) as {
    id: string;
    status: string;
    pre_visit_notes: string | null;
  };

  const attrs = ((property as { attributes: Record<string, unknown> | null }).attributes) ?? {};
  attrs["assessment_mode"] = "handyman";
  await service.from("properties").update({ attributes: attrs }).eq("id", propertyId);

  if (payload.pre_visit_notes || payload.pre_visit_photos) {
    await service.from("home_assessments")
      .update({
        pre_visit_notes: payload.pre_visit_notes ?? a.pre_visit_notes,
        pre_visit_photos: payload.pre_visit_photos ?? [],
      })
      .eq("id", a.id);
  }

  const propAddr = property as { address_line_1: string | null; city: string | null; state: string | null; zip_code: string | null };
  const addrSummary = [propAddr.address_line_1, propAddr.city, propAddr.state].filter(Boolean).join(", ");
  const summary = `Home assessment requested${addrSummary ? ` (${addrSummary})` : ""}`;
  const slaDueAt = await businessHoursDue(service);
  // Phase 96 — read the booking-time preferences off home_assessments
  // (handyman-provider's request_home_assessment writes them when the
  // homeowner picks a window) so the chez_request context surfaces them
  // on the admin cockpit's case panel from day one. Soft-fail to nulls
  // if the read errors out; the home_assessments row is the source of
  // truth either way.
  let preferredWindowStart: string | null = null;
  let preferredTimeOfDay: string | null = null;
  try {
    const { data: prefs } = await service
      .from("home_assessments")
      .select("preferred_window_start, preferred_time_of_day")
      .eq("id", a.id)
      .maybeSingle();
    const p = prefs as { preferred_window_start: string | null; preferred_time_of_day: string | null } | null;
    preferredWindowStart = p?.preferred_window_start ?? null;
    preferredTimeOfDay = p?.preferred_time_of_day ?? null;
  } catch (e) {
    console.warn("[chez-concierge] read assessment prefs failed", e);
  }
  const { data: req } = await service
    .from("chez_requests")
    .insert({
      household_id: householdId,
      user_id: user.id,
      category: "coordinate_task",
      summary,
      context: {
        _kind: "home_assessment_request",
        assessment_id: a.id,
        property_id: propertyId,
        notes: payload.notes ?? "",
        // Phase 96 — booking-time scheduling preferences (the admin
        // cockpit surfaces these on the case panel via
        // renderAssessmentPreferencesBanner).
        preferred_window_start: preferredWindowStart,
        preferred_time_of_day: preferredTimeOfDay,
      },
      status: "open",
      sla_due_at: slaDueAt,
      last_message_at: new Date().toISOString(),
      unread_for_user: false,
      unread_for_admin: true,
    })
    .select("*")
    .single();

  if (req) {
    const r = req as { id: string };
    await service.from("concierge_messages").insert({
      household_id: householdId,
      user_id: user.id,
      request_id: r.id,
      role: "system",
      content: `Customer picked "Have Chez handle it" at signup. Dispatch a handyman to ${addrSummary || "their home"} for a free home assessment.${payload.notes ? `\n\nCustomer notes:\n${payload.notes}` : ""}`,
      attachments: [],
    });
    await sendPush(serviceUrl, serviceRoleKey, adminUserIds(),
      "New free home assessment request", summary,
      { type: "chez_admin_request", request_id: r.id });
    await sendAdminEmail(adminEmails(),
      `[Chez] Free home assessment: ${addrSummary}`,
      `New free assessment requested by the homeowner.\n\nCustomer notes: ${payload.notes ?? "(none)"}\n\n${adminPortalUrl(r.id)}`,
      emailBody({
        preview: `Free assessment for ${addrSummary}.`,
        heading: "New home assessment request",
        intro: `Customer picked "Have Chez handle it" at signup. Dispatch a handyman to capture their systems, vendors, routines, and documents.`,
        bodyText: payload.notes ?? "(no additional notes)",
        ctaLabel: "Open in admin portal",
        ctaUrl: adminPortalUrl(r.id),
      }));
  }

  return json({ ok: true, assessment_id: a.id, status: a.status });
}

async function handleCancelHomeAssessment(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: CancelHomeAssessmentPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const assessmentId = compactString(payload.assessment_id);
  if (!assessmentId) return json({ error: "assessment_id required" }, 400);
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "no household" }, 404);

  const { data: assessment } = await service
    .from("home_assessments")
    .select("id, household_id, property_id, status")
    .eq("id", assessmentId)
    .maybeSingle();
  if (!assessment) return json({ error: "assessment not found" }, 404);
  if ((assessment as { household_id: string }).household_id !== householdId) {
    return json({ error: "not authorized" }, 403);
  }
  const a = assessment as { property_id: string; status: string };
  if (a.status === "completed" || a.status === "cancelled") {
    return json({ ok: true, status: a.status });
  }

  await service.from("home_assessments")
    .update({
      status: "cancelled",
      cancelled_at: new Date().toISOString(),
      cancellation_reason: payload.reason ?? "homeowner_self_serve",
    })
    .eq("id", assessmentId);

  const { data: prop } = await service
    .from("properties").select("attributes").eq("id", a.property_id).maybeSingle();
  const attrs = ((prop as { attributes: Record<string, unknown> | null } | null)?.attributes) ?? {};
  if (attrs["assessment_mode"] === "handyman") {
    delete attrs["assessment_mode"];
    await service.from("properties").update({ attributes: attrs }).eq("id", a.property_id);
  }

  // Phase X (May 2026) — also send admin email + include the operator
  // portal URL in the push payload so cancel notifications deep-link
  // directly to the right case on service.getchez.com. Cases linked
  // to this assessment carry `context.assessment_id` in their JSONB.
  const { data: matchedRequests } = await service
    .from("chez_requests")
    .select("id")
    .filter("context->>_kind", "eq", "home_assessment_request")
    .filter("context->>assessment_id", "eq", assessmentId)
    .limit(1);
  const linkedRequestId =
    (matchedRequests as Array<{ id: string }> | null)?.[0]?.id ?? null;
  const portalUrl = linkedRequestId ? adminPortalUrl(linkedRequestId) : null;

  await sendPush(serviceUrl, serviceRoleKey, adminUserIds(),
    "Home assessment cancelled",
    `Customer cancelled their assessment (${payload.reason ?? "homeowner_self_serve"}).`,
    {
      type: "chez_admin_request",
      assessment_id: assessmentId,
      ...(linkedRequestId ? { request_id: linkedRequestId } : {}),
    });
  if (portalUrl) {
    await sendAdminEmail(
      adminEmails(),
      "[Chez] Home assessment cancelled",
      `Customer cancelled their assessment.\nReason: ${payload.reason ?? "homeowner_self_serve"}\n\n${portalUrl}`,
      emailBody({
        preview: "Home assessment cancelled",
        heading: "Home assessment cancelled",
        intro: "The homeowner cancelled their scheduled assessment.",
        bodyText: `Reason: ${payload.reason ?? "homeowner_self_serve"}`,
        ctaLabel: "Open case",
        ctaUrl: portalUrl,
      })
    );
  }
  return json({ ok: true, status: "cancelled" });
}

async function handleRequestAssessmentReschedule(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: RequestAssessmentReschedulePayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const assessmentId = compactString(payload.assessment_id);
  if (!assessmentId) return json({ error: "assessment_id required" }, 400);
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "no household" }, 404);

  const { data: assessment } = await service
    .from("home_assessments").select("id, household_id, status").eq("id", assessmentId).maybeSingle();
  if (!assessment) return json({ error: "assessment not found" }, 404);
  if ((assessment as { household_id: string }).household_id !== householdId) {
    return json({ error: "not authorized" }, 403);
  }

  // Phase 96 — clean + persist preferred_dates alongside the timestamp
  // and notes. Previously this array was used only to populate the
  // push notification body and then discarded, so the operator had no
  // way to see the homeowner's preferences once the push was dismissed.
  const cleanedPreferredDates: string[] = (payload.preferred_dates ?? [])
    .map((d) => (typeof d === "string" ? d.trim() : ""))
    .filter((d) => d.length > 0);

  await service.from("home_assessments")
    .update({
      reschedule_requested_at: new Date().toISOString(),
      reschedule_request_notes: payload.notes ?? null,
      preferred_dates: cleanedPreferredDates.length > 0
        ? cleanedPreferredDates
        : null,
    })
    .eq("id", assessmentId);

  // Phase 96 — also patch the matching chez_request context so the
  // admin Operations Desk sees the preferences inline on the case
  // panel without an extra fetch. The request was created with
  // `context._kind === "home_assessment_request"` and a populated
  // `context.assessment_id` when the homeowner first booked; we
  // merge preferred_dates + reschedule_request_notes +
  // reschedule_requested_at into that blob in place. Idempotent on
  // re-submits (overwrites the same keys).
  try {
    const { data: matchedRequests } = await service
      .from("chez_requests")
      .select("id, context")
      .filter("context->>_kind", "eq", "home_assessment_request")
      .filter("context->>assessment_id", "eq", assessmentId);
    for (const row of (matchedRequests ?? []) as Array<{ id: string; context: Record<string, unknown> | null }>) {
      const merged = {
        ...(row.context ?? {}),
        preferred_dates: cleanedPreferredDates.length > 0 ? cleanedPreferredDates : null,
        reschedule_request_notes: payload.notes ?? null,
        reschedule_requested_at: new Date().toISOString(),
      };
      await service
        .from("chez_requests")
        .update({ context: merged })
        .eq("id", row.id);
    }
  } catch (e) {
    // Soft-fail: the home_assessments update above is the source of
    // truth. Context patching is purely a convenience for the admin
    // panel surface; if it fails we still have the row data + push.
    console.warn("[chez-concierge] context patch on reschedule failed", e);
  }

  const preferredText = cleanedPreferredDates.join(", ");

  // Phase X (May 2026) — fold the linked chez_request_id into the
  // push payload + send a SendGrid email backstop so the operator
  // can land directly on the right case on service.getchez.com.
  // The matchedRequests query above already loaded those rows; reuse
  // the first id for the deep-link URL.
  const firstRequestId =
    (matchedRequests as Array<{ id: string; context: Record<string, unknown> | null }> | null)?.[0]?.id ?? null;
  const portalUrl = firstRequestId ? adminPortalUrl(firstRequestId) : null;

  await sendPush(serviceUrl, serviceRoleKey, adminUserIds(),
    "Reschedule requested",
    `Customer asked to reschedule their assessment.${preferredText ? ` Preferred: ${preferredText}` : ""}`,
    {
      type: "chez_admin_request",
      assessment_id: assessmentId,
      ...(firstRequestId ? { request_id: firstRequestId } : {}),
    });
  if (portalUrl) {
    await sendAdminEmail(
      adminEmails(),
      "[Chez] Reschedule requested",
      `Customer asked to reschedule their assessment.\n${preferredText ? `Preferred: ${preferredText}\n` : ""}${payload.notes ? `Notes: ${payload.notes}\n` : ""}\n${portalUrl}`,
      emailBody({
        preview: "Reschedule requested",
        heading: "Reschedule requested",
        intro: "The homeowner wants to reschedule their assessment.",
        bodyText: `${preferredText ? `Preferred: ${preferredText}\n` : ""}${payload.notes ? `Notes: ${payload.notes}` : ""}`.trim() || "No additional notes.",
        ctaLabel: "Open case",
        ctaUrl: portalUrl,
      })
    );
  }
  return json({ ok: true });
}

async function handleSubmitAssessmentReview(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: SubmitAssessmentReviewPayload
) {
  if (!user) return json({ error: "auth required" }, 401);
  const assessmentId = compactString(payload.assessment_id);
  if (!assessmentId) return json({ error: "assessment_id required" }, 400);
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "no household" }, 404);

  const { data: assessment } = await service
    .from("home_assessments").select("id, household_id, status").eq("id", assessmentId).maybeSingle();
  if (!assessment) return json({ error: "assessment not found" }, 404);
  if ((assessment as { household_id: string }).household_id !== householdId) {
    return json({ error: "not authorized" }, 403);
  }
  const a = assessment as { status: string };
  if (a.status !== "awaiting_review") {
    return json({ error: `cannot review from status ${a.status}` }, 400);
  }

  const now = new Date().toISOString();
  await service.from("home_assessments")
    .update({ status: "completed", reviewed_at: now, completed_at: now })
    .eq("id", assessmentId);
  return json({ ok: true, status: "completed" });
}

async function handleRequestAssessmentCorrections(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: RequestAssessmentCorrectionsPayload,
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user) return json({ error: "auth required" }, 401);
  const assessmentId = compactString(payload.assessment_id);
  if (!assessmentId) return json({ error: "assessment_id required" }, 400);
  if (!Array.isArray(payload.items) || payload.items.length === 0) {
    return json({ error: "items required" }, 400);
  }
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "no household" }, 404);

  const { data: assessment } = await service
    .from("home_assessments").select("id, household_id").eq("id", assessmentId).maybeSingle();
  if (!assessment) return json({ error: "assessment not found" }, 404);
  if ((assessment as { household_id: string }).household_id !== householdId) {
    return json({ error: "not authorized" }, 403);
  }

  await service.from("home_assessments")
    .update({ status: "corrections_requested" })
    .eq("id", assessmentId);

  const summary = `Assessment corrections (${payload.items.length} item${payload.items.length === 1 ? "" : "s"})`;
  const slaDueAt = await businessHoursDue(service);
  const { data: req } = await service
    .from("chez_requests")
    .insert({
      household_id: householdId, user_id: user.id, category: "coordinate_task",
      summary,
      context: {
        _kind: "assessment_corrections",
        assessment_id: assessmentId,
        items: payload.items,
      },
      status: "open", sla_due_at: slaDueAt,
      last_message_at: new Date().toISOString(),
      unread_for_user: false, unread_for_admin: true,
    })
    .select("*")
    .single();

  if (req) {
    const r = req as { id: string };
    const itemList = payload.items
      .map((i, idx) => `${idx + 1}. [${i.section}] ${i.note}${i.entity_id ? ` (entity: ${i.entity_id})` : ""}`)
      .join("\n");
    await service.from("concierge_messages").insert({
      household_id: householdId, user_id: user.id, request_id: r.id,
      role: "user",
      content: `My handyman missed or got these things wrong:\n\n${itemList}`,
      attachments: [],
    });
    await sendPush(serviceUrl, serviceRoleKey, adminUserIds(),
      "Assessment corrections requested",
      `Customer flagged ${payload.items.length} item${payload.items.length === 1 ? "" : "s"} on their assessment.`,
      { type: "chez_admin_request", request_id: r.id });
  }

  return json({ ok: true, status: "corrections_requested" });
}

async function handleUpdatePreVisitData(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: UpdatePreVisitDataPayload
) {
  if (!user) return json({ error: "auth required" }, 401);
  const assessmentId = compactString(payload.assessment_id);
  if (!assessmentId) return json({ error: "assessment_id required" }, 400);
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "no household" }, 404);

  const { data: assessment } = await service
    .from("home_assessments")
    .select("id, household_id, captured_attributes, pre_visit_photos")
    .eq("id", assessmentId)
    .maybeSingle();
  if (!assessment) return json({ error: "assessment not found" }, 404);
  if ((assessment as { household_id: string }).household_id !== householdId) {
    return json({ error: "not authorized" }, 403);
  }

  const updates: Record<string, unknown> = {};
  if (typeof payload.pre_visit_notes === "string") {
    updates.pre_visit_notes = payload.pre_visit_notes;
  }
  if (Array.isArray(payload.pre_visit_photos)) {
    updates.pre_visit_photos = payload.pre_visit_photos;
  }
  if (payload.captured_attributes && typeof payload.captured_attributes === "object") {
    const existing = ((assessment as { captured_attributes: Record<string, unknown> | null }).captured_attributes) ?? {};
    updates.captured_attributes = { ...existing, ...payload.captured_attributes };
  }
  if (Object.keys(updates).length === 0) return json({ ok: true, no_op: true });

  await service.from("home_assessments").update(updates).eq("id", assessmentId);
  return json({ ok: true });
}

async function handleFetchHomeAssessment(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: FetchHomeAssessmentPayload
) {
  if (!user) return json({ error: "auth required" }, 401);
  const householdId = await householdIdForUser(service, user.id);
  if (!householdId) return json({ error: "no household" }, 404);

  let q = service.from("home_assessments").select("*").eq("household_id", householdId);
  const assessmentId = compactString(payload.assessment_id);
  const propertyId = compactString(payload.property_id);
  if (assessmentId) {
    q = q.eq("id", assessmentId);
  } else if (propertyId) {
    q = q.eq("property_id", propertyId).order("created_at", { ascending: false }).limit(1);
  } else {
    q = q.not("status", "in", "(completed,cancelled)").order("created_at", { ascending: false }).limit(1);
  }

  const { data, error } = await q.maybeSingle();
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true, assessment: data });
}

/// Admin-only — list every active home_assessments row (drives the
/// cockpit's Pending Assessments queue).
async function handleFetchPendingAssessments(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const { data, error } = await service
    .from("chez_pending_assessments_v")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true, assessments: data ?? [] });
}

/// Admin-only — fetch one assessment with full captured payload + property
/// + household context for the Captured Data review modal.
async function handleAdminFetchAssessment(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { assessment_id?: string }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const assessmentId = compactString(payload.assessment_id);
  if (!assessmentId) return json({ error: "assessment_id required" }, 400);

  const { data: assessment } = await service
    .from("home_assessments").select("*").eq("id", assessmentId).maybeSingle();
  if (!assessment) return json({ error: "not found" }, 404);

  const a = assessment as { household_id: string; property_id: string };
  const { data: property } = await service
    .from("properties")
    .select("id, address_line_1, city, state, zip_code, year_built, square_footage")
    .eq("id", a.property_id).maybeSingle();
  const { data: household } = await service
    .from("households").select("id, name").eq("id", a.household_id).maybeSingle();

  return json({ ok: true, assessment, property, household });
}

/// Phase 85 dispatch — admin lists workspaces eligible for an assessment
/// dispatch. State-aware: workspaces serving the property's state float
/// to the top, with the workspace's default assignee surfaced so the
/// admin can confirm in-place. Returns ALL active workspaces; the
/// admin picks. Workspaces without any active member are excluded
/// (they'd have no one to assign to).
async function handleListEligibleWorkspaces(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { property_state?: string }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const propertyState = compactString(payload.property_state).toUpperCase().slice(0, 2) || null;

  const { data: workspaces, error: wsErr } = await service
    .from("provider_workspaces")
    .select("id, company_name, primary_email, primary_phone, service_state, service_city, categories")
    .order("company_name", { ascending: true });
  if (wsErr) return json({ error: wsErr.message }, 500);
  const wsRows = (workspaces ?? []) as Record<string, unknown>[];

  const wsIds = wsRows.map((w) => compactString(w.id)).filter(Boolean);
  if (wsIds.length === 0) return json({ ok: true, workspaces: [] });

  const { data: members } = await service
    .from("provider_workspace_members")
    .select("id, workspace_id, full_name, email, role, status, is_default_assignee")
    .in("workspace_id", wsIds);
  const memberRows = (members ?? []) as Record<string, unknown>[];

  const enriched = wsRows
    .map((w) => {
      const wsId = compactString(w.id);
      const wsMembers = memberRows.filter((m) => compactString(m.workspace_id) === wsId);
      const activeMembers = wsMembers.filter((m) => compactString(m.status) === "active");
      const defaultMember = wsMembers.find((m) => m.is_default_assignee === true) ?? null;
      const wsState = compactString(w.service_state).toUpperCase() || null;
      const stateMatch = !!(propertyState && wsState && wsState === propertyState);
      return {
        id: wsId,
        companyName: compactString(w.company_name),
        primaryEmail: compactString(w.primary_email),
        primaryPhone: compactString(w.primary_phone),
        serviceState: wsState,
        serviceCity: compactString(w.service_city) || null,
        categories: Array.isArray(w.categories) ? (w.categories as string[]) : [],
        activeMemberCount: activeMembers.length,
        defaultMember: defaultMember ? {
          id: compactString(defaultMember.id),
          fullName: compactString(defaultMember.full_name) || compactString(defaultMember.email) || "Team member",
          email: compactString(defaultMember.email),
          role: compactString(defaultMember.role),
        } : null,
        stateMatch,
      };
    })
    .filter((w) => w.activeMemberCount > 0 || w.defaultMember !== null);

  // Sort: state match first, then by name.
  enriched.sort((a, b) => {
    if (a.stateMatch !== b.stateMatch) return a.stateMatch ? -1 : 1;
    return a.companyName.localeCompare(b.companyName);
  });

  return json({ ok: true, workspaces: enriched });
}

/// Phase 85 dispatch — admin assigns a workspace + handyman to an
/// assessment. Reuses the dispatchHomeAssessment logic in
/// handyman-provider but skips its assertWorkspaceAccess gate (admin
/// dispatches across any workspace, not their own). The flow:
///
///   1. Stub a `handyman_requests` row tagged `request_kind="home_assessment"`.
///   2. Insert the `provider_visit_assignments` row scoping the
///      handyman's RLS access to the assessment's JSONB.
///   3. Update `home_assessments.{visit_assignment_id, handyman_member_id, status, scheduled_at}`.
///   4. Post a system message to the related chez_request thread so
///      the homeowner sees "Chez assigned a handyman" in the audit
///      trail.
///   5. Notify the assigned member by push + email so they see the
///      visit in their operations SPA queue.
async function handleAssignHandymanToAssessment(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: {
    assessment_id?: string;
    workspace_id?: string;
    member_id?: string | null;
    request_id?: string | null;
    route_date?: string | null;
    window_start_time?: string | null;
    window_end_time?: string | null;
  },
  serviceUrl: string,
  serviceRoleKey: string
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const assessmentId = compactString(payload.assessment_id);
  const workspaceId = compactString(payload.workspace_id);
  if (!assessmentId || !workspaceId) {
    return json({ error: "assessment_id + workspace_id required" }, 400);
  }
  const requestedMemberId = compactString(payload.member_id) || null;
  const chezRequestId = compactString(payload.request_id) || null;
  const routeDate = compactString(payload.route_date) || null;
  const windowStart = compactString(payload.window_start_time) || null;
  const windowEnd = compactString(payload.window_end_time) || null;

  const { data: assessmentRow } = await service
    .from("home_assessments")
    .select("id, household_id, property_id, status")
    .eq("id", assessmentId)
    .maybeSingle();
  if (!assessmentRow) return json({ error: "assessment not found" }, 404);
  const assessment = assessmentRow as { id: string; household_id: string; property_id: string; status: string };

  // If the caller didn't pass an explicit member, fall back to the
  // workspace's default assignee. Sole-prop is the common case so the
  // admin doesn't have to think about it.
  let memberId = requestedMemberId;
  if (!memberId) {
    const { data: defaultMemberRow } = await service
      .from("provider_workspace_members")
      .select("id")
      .eq("workspace_id", workspaceId)
      .eq("is_default_assignee", true)
      .maybeSingle();
    memberId = defaultMemberRow ? compactString((defaultMemberRow as { id: string }).id) || null : null;
  }

  const { data: memberRow } = memberId
    ? await service
        .from("provider_workspace_members")
        .select("id, full_name, email, user_id, workspace_id")
        .eq("id", memberId)
        .eq("workspace_id", workspaceId)
        .maybeSingle()
    : { data: null };

  // 1. Stub handyman_request row.
  let stubRequestId: string | null = null;
  const { data: stubRequest, error: reqErr } = await service
    .from("handyman_requests")
    .insert({
      household_id: assessment.household_id,
      property_id: assessment.property_id,
      title: "Home assessment (Chez free)",
      summary: "Capture systems, vendors, routines, documents during the free Chez home assessment.",
      status: "scheduled",
      request_kind: "home_assessment",
    })
    .select("id")
    .single();
  if (stubRequest && !reqErr) {
    stubRequestId = (stubRequest as { id: string }).id;
  } else {
    // Older schemas may not have request_kind — retry without it.
    const { data: retry } = await service
      .from("handyman_requests")
      .insert({
        household_id: assessment.household_id,
        property_id: assessment.property_id,
        title: "Home assessment (Chez free)",
        summary: "Capture systems, vendors, routines, documents during the free Chez home assessment.",
        status: "scheduled",
      })
      .select("id")
      .single();
    if (!retry) return json({ error: `failed to create stub request: ${reqErr?.message ?? "unknown"}` }, 500);
    stubRequestId = (retry as { id: string }).id;
  }

  // 2. Visit assignment.
  const { data: visit, error: visitErr } = await service
    .from("provider_visit_assignments")
    .insert({
      workspace_id: workspaceId,
      request_id: stubRequestId,
      assigned_member_id: memberId,
      assigned_by_user_id: user.id,
      route_date: routeDate,
      window_start_time: windowStart,
      window_end_time: windowEnd,
      visit_type: "home_assessment",
    })
    .select("id")
    .single();
  if (visitErr || !visit) {
    return json({ error: `failed to create visit: ${visitErr?.message ?? "unknown"}` }, 500);
  }
  const visitId = (visit as { id: string }).id;

  // 3. Flip assessment row.
  const nowIso = new Date().toISOString();
  await service
    .from("home_assessments")
    .update({
      visit_assignment_id: visitId,
      handyman_member_id: memberId,
      status: "scheduled",
      scheduled_at: nowIso,
    })
    .eq("id", assessmentId);

  // 4. Audit-trail message on the chez_request (if linked).
  const member = memberRow as { full_name?: string; email?: string; user_id?: string; workspace_id?: string } | null;
  const memberLabel = member
    ? compactString(member.full_name) || compactString(member.email) || "a handyman"
    : "a handyman";
  if (chezRequestId) {
    await service.from("concierge_messages").insert({
      household_id: assessment.household_id,
      user_id: user.id,
      request_id: chezRequestId,
      role: "system",
      content: `Chez assigned ${memberLabel} for the home assessment visit.${routeDate ? ` Scheduled for ${routeDate}.` : ""}`,
      attachments: [],
    });
  }

  // 5. Notify the assigned member (push + email).
  // Note: as of May 2026 the handyman Operations Desk is decommissioned —
  // visit confirmation now happens via direct reply to this email. The
  // dispatch flow itself is dormant until the new offline visit surface
  // ships; this branch only fires if an admin manually assigns a member.
  const memberUserId = compactString(member?.user_id) || null;
  if (memberUserId) {
    await sendPush(
      serviceUrl, serviceRoleKey, [memberUserId],
      "New home assessment assigned",
      "You've been assigned a Chez free home assessment visit. Tom will be in touch to confirm.",
      { type: "home_assessment_assigned", assessment_id: assessmentId, visit_assignment_id: visitId }
    );
  }
  const memberEmail = compactString(member?.email);
  if (memberEmail) {
    await sendAdminEmail(
      [memberEmail],
      "New Chez home assessment assigned to you",
      `You've been assigned a Chez free home assessment visit.${routeDate ? `\n\nScheduled for: ${routeDate}.` : ""}\n\nReply to this email to confirm or reschedule.\n\nChez`,
      emailBody({
        preview: "You've been assigned a new Chez home assessment visit.",
        heading: "New home assessment assigned",
        intro: "Chez has dispatched a free home assessment to your workspace. Reply to this email to confirm or reschedule the visit.",
        bodyText: `Visit type: free home assessment.${routeDate ? `\nScheduled for: ${routeDate}.` : ""}`,
      })
    );
  }

  return json({
    ok: true,
    visit_assignment_id: visitId,
    handyman_request_id: stubRequestId,
    handyman_member_id: memberId,
    assigned_member_label: memberLabel,
  });
}

// ============================================================================
// Phase 100 — Intelligence foundation actions
// ============================================================================
// save_vendor_calls / fetch_vendor_calls — persist the cockpit's
//   per-candidate call ledger (state.chezVendorCallsByRequest) so it
//   survives refresh and feeds the cross-household vendor registry.
// record_outcome — post-hoc edits to a case's structured outcome (the
//   resolve-time path rides transition_status.outcome).
// fetch_vendor_registry — operator-side network intelligence reads.
// fetch_ops_metrics — Insights strip rollups.
// log_operator_event — effort telemetry (case_opened etc.).

interface SaveVendorCallsPayload {
  request_id: string;
  calls: Array<{
    candidate_key: string;
    source?: "existing" | "places" | "manual";
    contractor_id?: string | null;
    google_place_id?: string | null;
    vendor_name?: string | null;
    vendor_phone?: string | null;
    vendor_email?: string | null;
    category?: string | null;
    town?: string | null;
    state?: string | null;
    outcome?: string | null;
    notes?: string | null;
    rationale?: string | null;
    recommended?: boolean;
    availability_slots?: string[];
    cost_range?: string | null;
    cost_custom?: string | null;
  }>;
}

/// Best-effort dollars→cents parser for the call form's free-text cost
/// fields ("$1,200 firm", "400-600", "1.2k"). Returns the midpoint of a
/// range. Null when no number is recoverable — never guesses.
function parseQuotedCostCents(costCustom: string | null | undefined, costRange: string | null | undefined): number | null {
  const text = `${costCustom ?? ""} ${costRange ?? ""}`.toLowerCase();
  if (!text.trim()) return null;
  const matches = text.match(/\$?\s*(\d{1,3}(?:,\d{3})+|\d+(?:\.\d+)?)\s*(k)?/g);
  if (!matches) return null;
  const values: number[] = [];
  for (const m of matches) {
    const k = /k\s*$/.test(m.trim());
    const num = parseFloat(m.replace(/[$,k\s]/g, ""));
    if (!Number.isFinite(num) || num <= 0) continue;
    values.push(k ? num * 1000 : num);
  }
  if (values.length === 0) return null;
  // Single number → itself; multiple → midpoint of min/max (ranges).
  const lo = Math.min(...values);
  const hi = Math.max(...values);
  const dollars = (lo + hi) / 2;
  // Ignore implausible parses (under $5 reads like a slot time, not a cost).
  if (dollars < 5) return null;
  return Math.round(dollars * 100);
}

async function handleSaveVendorCalls(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: SaveVendorCallsPayload
) {
  if (!isAdminUser(user)) return json({ error: "admin only" }, 403);
  const requestId = compactString(payload.request_id);
  if (!requestId || !Array.isArray(payload.calls) || payload.calls.length === 0) {
    return json({ error: "request_id + calls required" }, 400);
  }
  const { data: requestRow, error: reqErr } = await service
    .from("chez_requests")
    .select("id, household_id")
    .eq("id", requestId)
    .maybeSingle();
  if (reqErr || !requestRow) return json({ error: "request not found" }, 404);
  const householdId = (requestRow as { household_id: string }).household_id;

  const nowIso = new Date().toISOString();
  const rows = payload.calls
    .filter((c) => compactString(c.candidate_key))
    .slice(0, 40)
    .map((c) => {
      const hasOutcome = !!compactString(c.outcome ?? undefined);
      return {
        request_id: requestId,
        household_id: householdId,
        candidate_key: String(c.candidate_key).slice(0, 300),
        source: c.source === "existing" || c.source === "manual" ? c.source : "places",
        contractor_id: c.contractor_id ?? null,
        google_place_id: c.google_place_id ?? null,
        vendor_name: c.vendor_name ? String(c.vendor_name).slice(0, 200) : null,
        vendor_phone: c.vendor_phone ? String(c.vendor_phone).slice(0, 40) : null,
        vendor_email: c.vendor_email ? String(c.vendor_email).slice(0, 200) : null,
        category: c.category ? String(c.category).slice(0, 100) : null,
        town: c.town ? String(c.town).slice(0, 100) : null,
        state: c.state ? String(c.state).slice(0, 10) : null,
        outcome: hasOutcome ? String(c.outcome) : null,
        notes: c.notes ? String(c.notes).slice(0, 4000) : null,
        rationale: c.rationale ? String(c.rationale).slice(0, 4000) : null,
        recommended: !!c.recommended,
        availability_slots: Array.isArray(c.availability_slots)
          ? c.availability_slots.map((s) => String(s).slice(0, 200)).slice(0, 12)
          : [],
        cost_range: c.cost_range ? String(c.cost_range).slice(0, 100) : null,
        cost_custom: c.cost_custom ? String(c.cost_custom).slice(0, 300) : null,
        quoted_cost_cents: parseQuotedCostCents(c.cost_custom, c.cost_range),
        last_called_at: hasOutcome ? nowIso : null,
      };
    });
  if (rows.length === 0) return json({ error: "no valid calls" }, 400);

  const { error: upsertErr } = await service
    .from("chez_vendor_calls")
    .upsert(rows, { onConflict: "request_id,candidate_key" });
  if (upsertErr) return json({ error: upsertErr.message }, 500);

  // first_called_at: stamp once for rows that now have an outcome but no
  // first_called_at yet. Separate cheap update keeps the upsert simple.
  try {
    await service
      .from("chez_vendor_calls")
      .update({ first_called_at: nowIso })
      .eq("request_id", requestId)
      .is("first_called_at", null)
      .not("outcome", "is", null);
  } catch (e) {
    console.warn("[vendor-calls] first_called_at stamp failed:", e);
  }

  return json({ ok: true, saved: rows.length });
}

async function handleFetchVendorCalls(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { request_id?: string }
) {
  if (!isAdminUser(user)) return json({ error: "admin only" }, 403);
  const requestId = compactString(payload.request_id);
  if (!requestId) return json({ error: "request_id required" }, 400);
  const { data, error } = await service
    .from("chez_vendor_calls")
    .select("*")
    .eq("request_id", requestId)
    .order("created_at", { ascending: true });
  if (error) return json({ error: error.message }, 500);
  return json({ calls: data ?? [] });
}

async function handleRecordOutcome(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { request_id?: string; outcome?: OutcomePayload }
) {
  if (!isAdminUser(user)) return json({ error: "admin only" }, 403);
  const requestId = compactString(payload.request_id);
  if (!requestId || !payload.outcome) return json({ error: "request_id + outcome required" }, 400);
  const { data: requestRow, error: reqErr } = await service
    .from("chez_requests")
    .select("*")
    .eq("id", requestId)
    .maybeSingle();
  if (reqErr || !requestRow) return json({ error: "request not found" }, 404);
  const result = await upsertRequestOutcome(
    service,
    requestRow as ConciergeRequestRow,
    payload.outcome,
    user?.id ?? null
  );
  if (!result.ok) return json({ error: result.error ?? "outcome upsert failed" }, 400);
  return json({ ok: true });
}

async function handleFetchVendorRegistry(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { category?: string; town?: string; search?: string; limit?: number }
) {
  if (!isAdminUser(user)) return json({ error: "admin only" }, 403);
  const limit = Math.min(Math.max(Number(payload.limit) || 50, 1), 200);
  let query = service
    .from("chez_vendor_registry")
    .select("*")
    .order("jobs_won", { ascending: false })
    .order("times_called", { ascending: false })
    .limit(limit);
  const category = compactString(payload.category)?.toLowerCase();
  if (category) query = query.contains("categories", [category]);
  const town = compactString(payload.town);
  if (town) query = query.contains("towns", [town]);
  const search = compactString(payload.search);
  if (search) query = query.ilike("display_name", `%${search}%`);
  const { data, error } = await query;
  if (error) return json({ error: error.message }, 500);
  return json({ vendors: data ?? [] });
}

async function handleFetchOpsMetrics(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null
) {
  if (!isAdminUser(user)) return json({ error: "admin only" }, 403);
  const since30 = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const since7 = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const safe = async <T>(promise: PromiseLike<T>, label: string): Promise<T | null> => {
    try { return await promise; }
    catch (e) { console.warn(`[ops-metrics] ${label} failed:`, e); return null; }
  };
  const [cases30Res, weeklyRes, funnelRes, effortRes] = await Promise.all([
    safe(service.from("chez_case_metrics").select("*").gte("created_at", since30), "cases30"),
    safe(service.from("chez_weekly_ops").select("*").order("week", { ascending: false }).limit(16), "weekly"),
    safe(service.from("chez_playbook_funnel").select("*"), "funnel"),
    safe(service.from("chez_case_effort").select("*"), "effort"),
  ]);
  const cases30 = ((cases30Res as { data?: Array<Record<string, unknown>> } | null)?.data ?? []) as Array<Record<string, unknown>>;
  const effortRows = ((effortRes as { data?: Array<Record<string, unknown>> } | null)?.data ?? []) as Array<Record<string, unknown>>;
  const effortById = new Map(effortRows.map((r) => [String(r.request_id), Number(r.effort_minutes) || 0]));

  const median = (values: number[]): number | null => {
    if (values.length === 0) return null;
    const sorted = [...values].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
  };
  const rate = (hits: number, total: number): number | null =>
    total > 0 ? Math.round((hits / total) * 100) / 100 : null;

  const summarize = (rows: Array<Record<string, unknown>>) => {
    const resolved = rows.filter((r) => r.status === "resolved");
    const slaEligible = rows.filter((r) => r.sla_due_at);
    return {
      opened: rows.length,
      resolved: resolved.length,
      median_first_response_minutes: median(rows.map((r) => Number(r.first_response_minutes)).filter((n) => Number.isFinite(n))),
      median_resolution_hours: median(resolved.map((r) => Number(r.resolution_hours)).filter((n) => Number.isFinite(n))),
      sla_hit_rate: rate(slaEligible.filter((r) => r.sla_hit === true).length, slaEligible.length),
      avg_touches: rows.length > 0
        ? Math.round((rows.reduce((sum, r) => sum + (Number(r.operator_touches) || 0), 0) / rows.length) * 10) / 10
        : null,
      automation_rate: rate(rows.filter((r) => r.automation_proxy === true).length, rows.length),
      median_effort_minutes: median(rows.map((r) => effortById.get(String(r.id)) ?? NaN).filter((n) => Number.isFinite(n) && n > 0)),
      total_final_cost_cents: rows.reduce((sum, r) => sum + (Number(r.final_cost_cents) || 0), 0),
    };
  };

  return json({
    last_30_days: summarize(cases30),
    last_7_days: summarize(cases30.filter((r) => String(r.created_at) >= since7)),
    weekly: (weeklyRes as { data?: unknown[] } | null)?.data ?? [],
    playbook_funnel: (funnelRes as { data?: unknown[] } | null)?.data ?? [],
  });
}

async function handleLogOperatorEvent(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { events?: Array<{ request_id?: string; event_type?: string; client_session_id?: string }> }
) {
  if (!isAdminUser(user)) return json({ error: "admin only" }, 403);
  const allowed = new Set(["case_opened", "case_closed", "reply_sent", "call_logged"]);
  const events = (payload.events ?? [])
    .filter((e) => compactString(e.request_id) && allowed.has(String(e.event_type)))
    .slice(0, 50);
  if (events.length === 0) return json({ ok: true, logged: 0 });

  // household_id is denormalized for per-household queries; resolve in
  // one batched read.
  const requestIds = [...new Set(events.map((e) => String(e.request_id)))];
  const { data: requestRows } = await service
    .from("chez_requests")
    .select("id, household_id")
    .in("id", requestIds);
  const householdByRequest = new Map(
    ((requestRows ?? []) as Array<{ id: string; household_id: string }>).map((r) => [r.id, r.household_id])
  );

  const rows = events
    .filter((e) => householdByRequest.has(String(e.request_id)))
    .map((e) => ({
      request_id: String(e.request_id),
      household_id: householdByRequest.get(String(e.request_id)) ?? null,
      event_type: String(e.event_type),
      operator_user_id: user?.id ?? null,
      client_session_id: e.client_session_id ? String(e.client_session_id).slice(0, 100) : null,
    }));
  if (rows.length === 0) return json({ ok: true, logged: 0 });
  const { error } = await service.from("chez_operator_events").insert(rows);
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true, logged: rows.length });
}

// ============================================================================
// Server entry
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "server not configured" }, 500);
    }
    const service = createClient(supabaseUrl, serviceRoleKey);

    const body = (await req.json().catch(() => ({}))) as {
      action?: string;
    } & Record<string, unknown>;
    const action = compactString(body.action);

    const user = await getAuthenticatedUser(service, req);

    switch (action) {
      case "submit": {
        if (!user) return json({ error: "auth required" }, 401);
        return handleSubmit(
          service,
          user,
          body as unknown as SubmitPayload,
          supabaseUrl,
          serviceRoleKey
        );
      }
      case "reply":
        return handleReply(
          service,
          user,
          body as unknown as ReplyPayload,
          supabaseUrl,
          serviceRoleKey
        );
      case "mark_read":
        return handleMarkRead(service, user, body as { request_id: string });
      case "transition_status":
        return handleTransition(
          service,
          user,
          body as unknown as TransitionPayload,
          supabaseUrl,
          serviceRoleKey
        );

      // Phase 80.1 — household profile (standing instructions for Chez)
      case "fetch_profile":
        return handleFetchProfile(service, user);
      case "update_profile":
        return handleUpdateProfile(
          service,
          user,
          body as unknown as UpdateProfilePayload
        );

      // Phase 80.1 — recurring delegation (Chez owns a routine / vendor)
      case "delegate_routine":
        return handleDelegateRoutine(
          service,
          user,
          body as unknown as DelegateRoutinePayload,
          supabaseUrl,
          serviceRoleKey
        );
      case "delegate_contractor":
        return handleDelegateContractor(
          service,
          user,
          body as unknown as DelegateContractorPayload,
          supabaseUrl,
          serviceRoleKey
        );
      case "delegate_task":
        return handleDelegateTask(
          service,
          user,
          body as unknown as DelegateTaskPayload,
          supabaseUrl,
          serviceRoleKey
        );

      // Wave 1 — homeowner dry run of the delegation snapshot (composer
      // v2 renders "What Chez already knows" + readiness + budget hint)
      case "preview_snapshot":
        return handlePreviewSnapshot(
          service,
          user,
          body as unknown as PreviewSnapshotPayload
        );

      // Phase 80.1 — structured proposals (Chez proposes vendor / date /
      // cost / quote, homeowner approves / declines / counters)
      case "propose":
        return handlePropose(
          service,
          user,
          body as unknown as ProposePayload,
          supabaseUrl,
          serviceRoleKey
        );
      case "decide_proposal":
        return handleDecideProposal(
          service,
          user,
          body as unknown as DecideProposalPayload,
          supabaseUrl,
          serviceRoleKey
        );

      // Phase 81 — admin context dossier + AI framing helper
      case "fetch_dossier":
        return handleFetchDossier(
          service,
          user,
          body as unknown as FetchDossierPayload
        );
      case "suggest_vendor_framing":
        return handleSuggestVendorFraming(
          service,
          user,
          body as unknown as SuggestVendorFramingPayload
        );

      // Phase 81.1 — pre-research action that does ALL the AI heavy
      // lifting on request open: analyzes the homeowner's situation,
      // matches existing household vendors, pre-fetches local Places
      // candidates, drafts a call script. Tom just makes the calls.
      case "analyze_request":
        return handleAnalyzeRequest(
          service,
          user,
          body as unknown as AnalyzeRequestPayload,
          supabaseUrl
        );

      // Phase 82 — visit tracking. Once a vendor proposal is approved,
      // the case shifts to coordinating that visit through completion.
      case "fetch_visits":
        return handleFetchVisits(
          service,
          user,
          body as unknown as FetchVisitsPayload
        );
      case "update_visit":
        return handleUpdateVisit(
          service,
          user,
          body as unknown as UpdateVisitPayload
        );

      // Phase 100 — intelligence foundation: call ledger persistence,
      // structured outcomes, vendor registry, ops metrics, operator
      // effort telemetry. All admin-gated inside the handlers.
      case "save_vendor_calls":
        return handleSaveVendorCalls(
          service,
          user,
          body as unknown as SaveVendorCallsPayload
        );
      case "fetch_vendor_calls":
        return handleFetchVendorCalls(
          service,
          user,
          body as { request_id?: string }
        );
      case "record_outcome":
        return handleRecordOutcome(
          service,
          user,
          body as { request_id?: string; outcome?: OutcomePayload }
        );
      case "fetch_vendor_registry":
        return handleFetchVendorRegistry(
          service,
          user,
          body as { category?: string; town?: string; search?: string; limit?: number }
        );
      case "fetch_ops_metrics":
        return handleFetchOpsMetrics(service, user);
      case "log_operator_event":
        return handleLogOperatorEvent(
          service,
          user,
          body as { events?: Array<{ request_id?: string; event_type?: string; client_session_id?: string }> }
        );

      // Phase 83 — Cockpit Alfred chat. Single-shot, case-scoped Q&A.
      case "ask_alfred":
        return handleAskAlfred(
          service,
          user,
          body as unknown as AskAlfredPayload
        );

      // Phase 84 — Universal entity-level delegation (covers system,
      // project, document, utility, insurance, vehicle in one generic
      // handler).
      case "delegate_entity":
        return handleDelegateEntity(
          service,
          user,
          body as unknown as DelegateEntityPayload,
          supabaseUrl,
          serviceRoleKey
        );

      // Phase 85.6 — Ownership consent flow. Admin proposes; homeowner
      // approves via the existing decide_proposal action, which now
      // dispatches on `ownership_request` to flip chez_owned.
      case "propose_ownership":
        return handleProposeOwnership(
          service,
          user,
          body as unknown as ProposeOwnershipPayload,
          supabaseUrl,
          serviceRoleKey
        );

      // Phase 84 — Group-level delegation ("Chez handles all my X").
      case "set_ownership_group":
        return handleSetOwnershipGroup(
          service,
          user,
          body as unknown as SetOwnershipGroupPayload,
          supabaseUrl,
          serviceRoleKey
        );

      // Phase 84 — Workbench audit + reminders + Upcoming feed.
      case "workbench_action":
        return handleWorkbenchAction(
          service,
          user,
          body as unknown as WorkbenchActionPayload
        );
      case "create_reminder":
        return handleCreateReminder(
          service,
          user,
          body as unknown as CreateReminderPayload
        );
      case "complete_reminder":
        return handleCompleteReminder(
          service,
          user,
          body as { reminder_id: string }
        );
      case "fetch_upcoming":
        return handleFetchUpcoming(
          service,
          user,
          body as unknown as FetchUpcomingPayload
        );

      // Phase 84 — Operator-initiated case ("+ New case" in cockpit).
      case "admin_submit":
        return handleAdminSubmit(
          service,
          user,
          body as unknown as AdminSubmitPayload
        );

      // Phase 84 — Households workbench data.
      case "fetch_households_list":
        return handleFetchHouseholdsList(service, user);
      case "fetch_household_workbench":
        return handleFetchHouseholdWorkbench(
          service,
          user,
          body as unknown as FetchHouseholdWorkbenchPayload
        );

      // Phase 86A — Today command center brief. Admin-only. Returns a
      // cross-home triage payload: SLA-due cases, today's visits,
      // upcoming visits (+1d through +7d), recent unread homeowner
      // replies, plus aggregate stats. Replaces the catalog-tool default
      // landing with a customer-service surface.
      case "fetch_today_brief":
        return handleFetchTodayBrief(service, user);

      // Phase 84 PR 4 — project negotiation tracking. Each call appends
      // one turn to project_quotes.negotiation_history. Admin-only;
      // mutation goes through service role since the operator may not
      // have homeowner-side RLS access to write project_quotes.
      case "add_project_negotiation_turn":
        return handleAddProjectNegotiationTurn(
          service,
          user,
          body as unknown as AddProjectNegotiationTurnPayload
        );

      // Phase 84.5 — Free Handyman Assessment + 3-Mode Onboarding.
      // Homeowner-facing actions (handyman-side actions live in
      // handyman-provider/index.ts).
      case "request_home_assessment":
        return handleRequestHomeAssessment(
          service, user, body as unknown as RequestHomeAssessmentPayload,
          supabaseUrl, serviceRoleKey
        );
      case "cancel_home_assessment":
        return handleCancelHomeAssessment(
          service, user, body as unknown as CancelHomeAssessmentPayload,
          supabaseUrl, serviceRoleKey
        );
      case "request_assessment_reschedule":
        return handleRequestAssessmentReschedule(
          service, user, body as unknown as RequestAssessmentReschedulePayload,
          supabaseUrl, serviceRoleKey
        );
      case "submit_assessment_review":
        return handleSubmitAssessmentReview(
          service, user, body as unknown as SubmitAssessmentReviewPayload
        );
      case "request_assessment_corrections":
        return handleRequestAssessmentCorrections(
          service, user, body as unknown as RequestAssessmentCorrectionsPayload,
          supabaseUrl, serviceRoleKey
        );
      case "update_pre_visit_data":
        return handleUpdatePreVisitData(
          service, user, body as unknown as UpdatePreVisitDataPayload
        );
      case "fetch_home_assessment":
        return handleFetchHomeAssessment(
          service, user, body as unknown as FetchHomeAssessmentPayload
        );
      // Phase 84.5 — Admin-only assessment data
      case "fetch_pending_assessments":
        return handleFetchPendingAssessments(service, user);
      case "admin_fetch_assessment":
        return handleAdminFetchAssessment(
          service, user, body as { assessment_id?: string }
        );

      // Phase 85 dispatch — admin-only.
      case "list_eligible_workspaces":
        return handleListEligibleWorkspaces(
          service, user, body as { property_state?: string }
        );
      case "assign_handyman_to_assessment":
        return handleAssignHandymanToAssessment(
          service, user,
          body as Parameters<typeof handleAssignHandymanToAssessment>[2],
          supabaseUrl, serviceRoleKey
        );

      // ====================================================================
      // Phase 86B — CRM hygiene actions
      // ====================================================================
      case "list_snippets":
        return handleListSnippets(service, user);
      case "save_snippet":
        return handleSaveSnippet(service, user, body as SaveSnippetPayload);
      case "delete_snippet":
        return handleDeleteSnippet(service, user, body as { snippet_id?: string });
      case "record_snippet_use":
        return handleRecordSnippetUse(service, user, body as { snippet_id?: string });

      case "list_tag_definitions":
        return handleListTagDefinitions(service, user);
      case "apply_tag":
        return handleApplyTag(service, user, body as { request_id?: string; tag_slug?: string });
      case "remove_tag":
        return handleRemoveTag(service, user, body as { request_id?: string; tag_slug?: string });

      case "assign_case":
        return handleAssignCase(service, user, body as { request_id?: string; assignee_user_id?: string | null });
      case "merge_cases":
        return handleMergeCases(service, user, body as { source_id?: string; target_id?: string });
      case "link_case":
        return handleLinkCase(service, user, body as { request_id?: string; related_id?: string; unlink?: boolean });

      case "fetch_activity_feed":
        return handleFetchActivityFeed(service, user, body as { household_id?: string; limit?: number });

      default:
        return json({ error: `unknown action: ${action}` }, 400);
    }
  } catch (error) {
    console.error("[chez-concierge] uncaught:", error);
    return json({ error: String(error) }, 500);
  }
});

// ============================================================================
// Phase 86B — CRM hygiene handlers
// ============================================================================
// Operator-personal snippets + shared org library. The org-shared seed
// rows are returned in every list response so a freshly-onboarded operator
// has a starter set before they save their own. `record_snippet_use`
// bumps a counter that the picker sorts by so frequently-used snippets
// float to the top of the list. Personal snippets always sort above
// shared ones at equal use counts.
// ============================================================================

interface SaveSnippetPayload {
  id?: string | null;       // null/undefined → create
  slug?: string;
  label?: string;
  body?: string;
  category?: string | null;
  shared_with_org?: boolean;
}

async function handleListSnippets(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  // RLS already filters by ownership but we also want the org-shared
  // seed rows (owner_user_id IS NULL). Use service role + an OR query.
  const { data, error } = await service
    .from("chez_snippets")
    .select("*")
    .or(`owner_user_id.eq.${user.id},shared_with_org.eq.true,owner_user_id.is.null`)
    .order("use_count", { ascending: false })
    .order("label", { ascending: true });
  if (error) {
    console.warn("[snippets:list]", error);
    return json({ error: error.message }, 500);
  }
  return json({ snippets: data ?? [] });
}

async function handleSaveSnippet(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: SaveSnippetPayload
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const slug = payload.slug?.trim().toLowerCase();
  const label = payload.label?.trim();
  const body = payload.body?.trim();
  if (!slug || !label || !body) {
    return json({ error: "slug, label, and body are required" }, 400);
  }
  // Slug sanity: lowercase hyphenated, 2-40 chars.
  if (!/^[a-z0-9][a-z0-9-]{1,39}$/.test(slug)) {
    return json({ error: "slug must be lowercase, hyphenated, 2-40 chars" }, 400);
  }

  const row = {
    owner_user_id: user.id,
    slug,
    label,
    body,
    category: payload.category ?? null,
    shared_with_org: !!payload.shared_with_org,
  };

  if (payload.id) {
    // Update existing (must be operator's own — DB policy enforces, but we
    // also surface a clear 404 if the id doesn't belong to them).
    const { data, error } = await service
      .from("chez_snippets")
      .update(row)
      .eq("id", payload.id)
      .eq("owner_user_id", user.id)
      .select("*")
      .maybeSingle();
    if (error) return json({ error: error.message }, 500);
    if (!data) return json({ error: "snippet not found or not yours" }, 404);
    return json({ snippet: data });
  }

  // Insert. UNIQUE (owner_user_id, slug) catches collisions.
  const { data, error } = await service
    .from("chez_snippets")
    .insert(row)
    .select("*")
    .single();
  if (error) {
    if (error.code === "23505") {
      return json({ error: `you already have a snippet with slug "${slug}"` }, 409);
    }
    return json({ error: error.message }, 500);
  }
  return json({ snippet: data });
}

async function handleDeleteSnippet(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { snippet_id?: string }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  if (!payload.snippet_id) return json({ error: "snippet_id required" }, 400);
  const { error } = await service
    .from("chez_snippets")
    .delete()
    .eq("id", payload.snippet_id)
    .eq("owner_user_id", user.id);
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true });
}

async function handleRecordSnippetUse(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { snippet_id?: string }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  if (!payload.snippet_id) return json({ error: "snippet_id required" }, 400);
  // Bump counter + stamp last_used_at. Fire-and-forget — non-fatal if it
  // misses (the snippet was still inserted in the composer).
  // Read-modify-write because PostgREST doesn't support column arithmetic
  // and we don't want to load a stored-procedure migration just for this.
  const { data: row } = await service
    .from("chez_snippets")
    .select("use_count")
    .eq("id", payload.snippet_id)
    .maybeSingle();
  if (!row) return json({ ok: true });
  await service
    .from("chez_snippets")
    .update({
      use_count: (row.use_count ?? 0) + 1,
      last_used_at: new Date().toISOString(),
    })
    .eq("id", payload.snippet_id);
  return json({ ok: true });
}

// ----------------------------------------------------------------------------
// Tags
// ----------------------------------------------------------------------------
async function handleListTagDefinitions(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const { data, error } = await service
    .from("chez_tag_definitions")
    .select("*")
    .is("archived_at", null)
    .order("label", { ascending: true });
  if (error) return json({ error: error.message }, 500);
  return json({ tags: data ?? [] });
}

async function handleApplyTag(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { request_id?: string; tag_slug?: string }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  if (!payload.request_id || !payload.tag_slug) {
    return json({ error: "request_id and tag_slug required" }, 400);
  }
  // Resolve slug → tag_definition_id.
  const { data: tagDef, error: tagErr } = await service
    .from("chez_tag_definitions")
    .select("id")
    .eq("slug", payload.tag_slug)
    .is("archived_at", null)
    .maybeSingle();
  if (tagErr) return json({ error: tagErr.message }, 500);
  if (!tagDef) return json({ error: `tag "${payload.tag_slug}" not found` }, 404);

  // Upsert. PK is (request_id, tag_definition_id) so re-applying is a no-op.
  const { error } = await service
    .from("chez_request_tags")
    .upsert({
      request_id: payload.request_id,
      tag_definition_id: tagDef.id,
      applied_by_user_id: user.id,
    }, { onConflict: "request_id,tag_definition_id" });
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true });
}

async function handleRemoveTag(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { request_id?: string; tag_slug?: string }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  if (!payload.request_id || !payload.tag_slug) {
    return json({ error: "request_id and tag_slug required" }, 400);
  }
  const { data: tagDef } = await service
    .from("chez_tag_definitions")
    .select("id")
    .eq("slug", payload.tag_slug)
    .maybeSingle();
  if (!tagDef) return json({ ok: true }); // tag doesn't exist; nothing to remove
  await service
    .from("chez_request_tags")
    .delete()
    .eq("request_id", payload.request_id)
    .eq("tag_definition_id", tagDef.id);
  return json({ ok: true });
}

// ----------------------------------------------------------------------------
// Assign + merge + link
// ----------------------------------------------------------------------------
async function handleAssignCase(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { request_id?: string; assignee_user_id?: string | null }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  if (!payload.request_id) return json({ error: "request_id required" }, 400);
  // assignee_user_id: explicit null = unassign. Otherwise must be admin
  // (we don't surface a UI to assign to non-admin users today; gate the
  // value to admins via env allowlist lookup is overkill for v1 — solo
  // operator means assignee = user.id 100% of the time).
  const { error } = await service
    .from("chez_requests")
    .update({ assigned_to_user_id: payload.assignee_user_id ?? null })
    .eq("id", payload.request_id);
  if (error) return json({ error: error.message }, 500);

  // Drop a system-role message in the thread for audit clarity.
  const note = payload.assignee_user_id
    ? "Chez took ownership of this case."
    : "Chez released ownership of this case (back to the queue).";
  await service.from("concierge_messages").insert({
    request_id: payload.request_id,
    role: "system",
    content: note,
  });
  return json({ ok: true });
}

async function handleMergeCases(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { source_id?: string; target_id?: string }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  const sourceId = payload.source_id?.trim();
  const targetId = payload.target_id?.trim();
  if (!sourceId || !targetId) {
    return json({ error: "source_id and target_id required" }, 400);
  }
  if (sourceId === targetId) {
    return json({ error: "cannot merge a case into itself" }, 400);
  }

  // Both cases must exist and live in the same household. Cross-household
  // merge is a footgun — refuse it.
  const { data: rows, error: fetchErr } = await service
    .from("chez_requests")
    .select("id, household_id, summary")
    .in("id", [sourceId, targetId]);
  if (fetchErr) return json({ error: fetchErr.message }, 500);
  if (!rows || rows.length !== 2) return json({ error: "source or target not found" }, 404);
  const source = rows.find((r) => r.id === sourceId);
  const target = rows.find((r) => r.id === targetId);
  if (!source || !target) return json({ error: "source or target not found" }, 404);
  if (source.household_id !== target.household_id) {
    return json({ error: "cannot merge across households" }, 400);
  }

  // Move source messages onto target so the thread reads continuously.
  // The original ordering is preserved (we don't touch created_at).
  const { error: msgErr } = await service
    .from("concierge_messages")
    .update({ request_id: targetId })
    .eq("request_id", sourceId);
  if (msgErr) return json({ error: msgErr.message }, 500);

  // Move chez_visits + chez_workbench_actions onto the target (best-effort).
  await service.from("chez_visits").update({ request_id: targetId }).eq("request_id", sourceId);
  await service.from("chez_workbench_actions").update({ request_id: targetId }).eq("request_id", sourceId);

  // Soft-archive the source. The trigger forces status → resolved when
  // merged_into_request_id is set, so we don't need to send it explicitly.
  const { error: updErr } = await service
    .from("chez_requests")
    .update({
      merged_into_request_id: targetId,
      unread_for_user: false,
      unread_for_admin: false,
    })
    .eq("id", sourceId);
  if (updErr) return json({ error: updErr.message }, 500);

  // Audit-trail message on the surviving case.
  await service.from("concierge_messages").insert({
    request_id: targetId,
    role: "system",
    content: `Chez merged a related conversation into this one ("${source.summary || "Untitled"}").`,
  });

  return json({ ok: true, merged_into: targetId });
}

async function handleLinkCase(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { request_id?: string; related_id?: string; unlink?: boolean }
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);
  if (!payload.request_id || !payload.related_id) {
    return json({ error: "request_id and related_id required" }, 400);
  }
  if (payload.request_id === payload.related_id) {
    return json({ error: "cannot link a case to itself" }, 400);
  }

  // Two-sided link: update both rows' arrays so either case shows the
  // relationship. Read-modify-write since postgres doesn't have a
  // single-statement array union via PostgREST.
  for (const [a, b] of [
    [payload.request_id, payload.related_id],
    [payload.related_id, payload.request_id],
  ]) {
    const { data: row } = await service
      .from("chez_requests")
      .select("related_case_ids")
      .eq("id", a)
      .maybeSingle();
    if (!row) continue;
    const existing: string[] = row.related_case_ids ?? [];
    let next: string[];
    if (payload.unlink) {
      next = existing.filter((x) => x !== b);
    } else {
      next = existing.includes(b) ? existing : [...existing, b];
    }
    await service
      .from("chez_requests")
      .update({ related_case_ids: next })
      .eq("id", a);
  }
  return json({ ok: true });
}

// ----------------------------------------------------------------------------
// Activity feed — Phase 86B iOS reader for chez_workbench_actions.
// ----------------------------------------------------------------------------
// Homeowner-facing. Returns the last N workbench actions for the
// requesting user's household so iOS can render the "Recent Chez activity"
// card on the Dashboard. Each row is denormalized with a friendly verb +
// optional entity label so the iOS side doesn't have to do its own
// translation table.
//
// Verb mapping mirrors WORKBENCH_ACTION_LABELS in admin.js so admin +
// homeowner see the same copy.
// ----------------------------------------------------------------------------
async function handleFetchActivityFeed(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null,
  payload: { household_id?: string; limit?: number }
) {
  if (!user) return json({ error: "auth required" }, 401);
  // Admin can override household_id to spot-check any home; non-admin
  // gets only their own household (looked up from their `users` row).
  let householdId = payload.household_id?.trim() || null;
  if (!isAdminUser(user)) {
    const { data: u } = await service
      .from("users")
      .select("household_id")
      .eq("id", user.id)
      .maybeSingle();
    if (!u?.household_id) return json({ error: "no household" }, 404);
    householdId = u.household_id as string;
  }
  if (!householdId) return json({ error: "household_id required" }, 400);

  const limit = Math.min(Math.max(payload.limit ?? 25, 1), 100);

  const { data, error } = await service
    .from("chez_workbench_actions")
    .select("id, action_type, entity_type, entity_id, payload, request_id, created_at")
    .eq("household_id", householdId)
    .order("created_at", { ascending: false })
    .limit(limit);
  if (error) return json({ error: error.message }, 500);

  // Friendly verb mapping. Keep aligned with admin.js WORKBENCH_ACTION_LABELS.
  const VERB: Record<string, string> = {
    schedule_visit: "Scheduled a vendor visit",
    log_visit: "Logged a vendor visit",
    log_service: "Logged service",
    schedule_maintenance: "Scheduled maintenance",
    schedule: "Scheduled a task",
    complete_on_behalf: "Marked a task complete",
    snooze: "Snoozed a task",
    log_call: "Logged a vendor call",
    send_message: "Recorded a vendor message",
    mark_filed: "Filed a document",
    share_with_vendor: "Shared a document with a vendor",
    audit_bill: "Audited a bill",
    draft_negotiation: "Drafted a negotiation",
    schedule_service: "Scheduled service",
    handle_recall: "Resolved a recall",
    admin_note: "Added a note",
  };

  const items = (data ?? []).map((row) => {
    const p = (row.payload ?? {}) as Record<string, unknown>;
    // Extract a human-readable entity label from the payload when present.
    const entityLabel =
      (typeof p.entity_label === "string" && p.entity_label) ||
      (typeof p.title === "string" && p.title) ||
      (typeof p.vendor_name === "string" && p.vendor_name) ||
      (typeof p.system_name === "string" && p.system_name) ||
      null;
    return {
      id: row.id,
      verb: VERB[row.action_type] || row.action_type.replace(/_/g, " "),
      entity_type: row.entity_type,
      entity_id: row.entity_id,
      entity_label: entityLabel,
      request_id: row.request_id,
      occurred_at: row.created_at,
    };
  });
  return json({ items });
}
