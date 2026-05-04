// Phase 80 — Chez Concierge Edge Function.
//
// Single function with `action` discriminator (mirrors process-inbox-item):
//   submit              — homeowner creates a new request
//   reply               — homeowner OR admin replies on the thread
//   mark_read           — clear unread flag for caller's side
//   transition_status   — update status (open / waiting_customer / resolved)
//
// Authorization:
//   - Homeowner actions require a JWT whose auth.uid() owns the request.
//   - Admin actions require a JWT whose verified email is in CHEZ_ADMIN_EMAILS.
//
// Side effects:
//   - submit              → push + email to admin (Tom). SendGrid is the
//                           backstop because Tom doesn't have the iOS app
//                           installed, so push alone is not enough.
//   - admin reply         → creates an inbox_items row in the homeowner's
//                           household (type chez_reply_action_needed when
//                           acknowledgement_required, else chez_reply_informational)
//                           + push to homeowner.
//   - homeowner reply     → push + email to admin.
//   - transition_status   → push to other party + (resolved) inbox_items row
//                           informing the homeowner it's done.
//
// Required Supabase secrets:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY  (standard)
//   CHEZ_ADMIN_EMAILS       — comma-separated list (e.g. "tom@getchez.com")
//   CHEZ_ADMIN_USER_IDS     — comma-separated UUIDs (recipients for iOS push)
//   SENDGRID_API_KEY        — for emailing Tom on new requests / replies
//   ADMIN_PORTAL_URL        — defaults to https://admin.getchez.com

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

function adminPortalUrl(requestId: string): string {
  const base = (Deno.env.get("ADMIN_PORTAL_URL") || "https://admin.getchez.com")
    .replace(/\/+$/, "");
  return `${base}/admin.html?view=chez&request=${requestId}`;
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
  <body style="margin:0;padding:24px;background:#F8F9FA;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#453A70;">
    <span style="display:none;">${escapeHtml(args.preview)}</span>
    <div style="max-width:560px;margin:0 auto;background:#FFFFFF;border-radius:14px;padding:28px;">
      <h1 style="font-family:Georgia,serif;font-size:22px;margin:0 0 8px;">${escapeHtml(args.heading)}</h1>
      <p style="font-size:14px;line-height:1.5;margin:0 0 16px;">${escapeHtml(args.intro)}</p>
      <pre style="background:#F8F9FA;border:1px solid #EDEEF0;border-radius:10px;padding:12px;font-family:-apple-system,sans-serif;white-space:pre-wrap;font-size:13px;color:#524580;">${escapeHtml(args.bodyText)}</pre>
      <p style="margin:18px 0 0;">
        <a href="${escapeHtml(args.ctaUrl)}" style="background:#ED6955;color:#fff;padding:10px 18px;border-radius:10px;text-decoration:none;font-weight:600;font-size:14px;">${escapeHtml(args.ctaLabel)}</a>
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

  // Notify admins (push + email).
  const requestId = (request as ConciergeRequestRow).id;
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
      `${emailIntro}\n\nRequest body:\n${description}\n\nOpen the portal:\n${portalUrl}`,
      emailBody({
        preview: `New Chez request: ${summary}`,
        heading: "New Chez request",
        intro: emailIntro,
        bodyText: description,
        ctaLabel: "Open in admin portal",
        ctaUrl: portalUrl,
      })
    ),
  ]);

  return json({ ok: true, request });
}

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
  await service
    .from("chez_requests")
    .update({
      status: toStatus,
      resolved_at: toStatus === "resolved" ? now : null,
      last_message_at: now,
      unread_for_user: isAdmin ? true : request.unread_for_user,
      unread_for_admin: isAdmin ? request.unread_for_admin : true,
    })
    .eq("id", request.id);

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
  const householdId = await householdIdForUser(service, user.id);
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
      // System message in the new thread.
      await service.from("concierge_messages").insert({
        household_id: householdId,
        user_id: user.id,
        request_id: r.id,
        role: "system",
        content: `Customer delegated this routine to Chez. From now on, schedule visits without prompting them.${payload.notes ? `\n\nNotes from customer:\n${payload.notes}` : ""}`,
        attachments: [],
      });
      await sendPush(
        serviceUrl,
        serviceRoleKey,
        adminUserIds(),
        "Customer delegated a routine to Chez",
        summary,
        { type: "chez_admin_request", request_id: r.id }
      );
      await sendAdminEmail(
        adminEmails(),
        `[Chez] New standing engagement: ${(routine as { label: string }).label}`,
        `Customer delegated this routine to Chez. From now on, schedule visits without prompting them.\n\n${payload.notes ?? ""}\n\n${adminPortalUrl(r.id)}`,
        emailBody({
          preview: "Customer handed off a recurring routine to Chez.",
          heading: "New standing engagement",
          intro: `The customer wants Chez to own scheduling for "${(routine as { label: string }).label}" from now on.`,
          bodyText: payload.notes ?? "(no additional notes)",
          ctaLabel: "Open in admin portal",
          ctaUrl: adminPortalUrl(r.id),
        })
      );
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
  const householdId = await householdIdForUser(service, user.id);
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
      await service.from("concierge_messages").insert({
        household_id: householdId,
        user_id: user.id,
        request_id: r.id,
        role: "system",
        content: `Customer set Chez as point of contact for ${c.company_name}. From now on, you handle scheduling and follow-ups directly with this vendor.${payload.notes ? `\n\nNotes from customer:\n${payload.notes}` : ""}`,
        attachments: [],
      });
      await sendPush(
        serviceUrl,
        serviceRoleKey,
        adminUserIds(),
        "Customer made Chez point of contact for a vendor",
        summary,
        { type: "chez_admin_request", request_id: r.id }
      );
      await sendAdminEmail(
        adminEmails(),
        `[Chez] New standing engagement: ${c.company_name}`,
        `Customer set Chez as point of contact for ${c.company_name}.\n\n${payload.notes ?? ""}\n\n${adminPortalUrl(r.id)}`,
        emailBody({
          preview: `Customer made Chez point of contact for ${c.company_name}.`,
          heading: "New standing engagement",
          intro: `The customer wants Chez to be point of contact for ${c.company_name} from now on.`,
          bodyText: payload.notes ?? "(no additional notes)",
          ctaLabel: "Open in admin portal",
          ctaUrl: adminPortalUrl(r.id),
        })
      );
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
  const householdId = await householdIdForUser(service, user.id);
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

  // System message: explicit + actionable so Chez knows the routing.
  const description = task.description?.trim() ?? "";
  const customerNotes = payload.notes?.trim() ?? "";
  let systemBody: string;
  if (hasVendor) {
    const vendorName = vendorRow?.company_name ?? "their vendor";
    systemBody = `Customer delegated this task to Chez. Coordinate with ${vendorName} to schedule and follow up — they don't want to chase the appointment themselves.\n\nTask: ${task.title}`;
  } else {
    systemBody = `Customer asked Chez to source a vendor for this task and own coordination end-to-end. Find a vetted local pro, propose them, and handle scheduling once approved.\n\nTask: ${task.title}`;
  }
  if (description) systemBody += `\n\nWhat the task involves:\n${description}`;
  if (customerNotes) systemBody += `\n\nCustomer notes:\n${customerNotes}`;

  await service.from("concierge_messages").insert({
    household_id: householdId,
    user_id: user.id,
    request_id: r.id,
    role: "system",
    content: systemBody,
    attachments: [],
  });

  // Push + email to admin.
  await sendPush(
    serviceUrl,
    serviceRoleKey,
    adminUserIds(),
    hasVendor
      ? "Customer asked Chez to handle a task"
      : "Customer asked Chez to source a vendor",
    summary,
    { type: "chez_admin_request", request_id: r.id }
  );
  await sendAdminEmail(
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
      bodyText: customerNotes || description || "(no additional notes)",
      ctaLabel: "Open in admin portal",
      ctaUrl: adminPortalUrl(r.id),
    })
  );

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
      content: content || `Chez sent you a proposal — tap to review.`,
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
            await service
              .from("contractors")
              .update({
                chez_request_id: request.id,
                chez_recommended_at: now,
                // Keep their original source ("manual"/"quiz"/etc.). We
                // don't overwrite — provenance is captured in the new
                // chez_request_id field.
              })
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

  try {
    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 200,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });
    if (!resp.ok) {
      const text = await resp.text();
      console.warn("[suggest_vendor_framing] Claude error:", resp.status, text.slice(0, 300));
      return json({ framing: "" });
    }
    const data = await resp.json() as { content?: Array<{ text?: string }> };
    const framing = data.content?.[0]?.text?.trim() ?? "";
    return json({ framing });
  } catch (e) {
    console.warn("[suggest_vendor_framing] exception:", e);
    return json({ framing: "" });
  }
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

  // 1. Fetch the request + household scope.
  const { data: requestRow, error: reqErr } = await service
    .from("chez_requests")
    .select("*")
    .eq("id", requestId)
    .maybeSingle();
  if (reqErr || !requestRow) return json({ error: "request not found" }, 404);
  const request = requestRow as ConciergeRequestRow;

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
    const userPrompt = `You're the Chez Concierge research assistant. A customer just submitted a request — analyze it so Tom (the admin) can act on it in 2 minutes instead of 20.

## Request
Category: ${request.category}
Summary: ${request.summary}
Context payload: ${JSON.stringify(request.context ?? {}, null, 2)}

## Property
${propertyContext}

## Customer profile
${profileBlob}

## Existing vendors on file
${contractors.length === 0 ? "(none)" : contractors.map((c) => `- ${c.company_name} (${c.category ?? "unknown trade"})`).join("\n")}

## Output format — STRICT JSON, no markdown fences
{
  "inferred_category": "Single-word/short trade name to use as Google Places category. Examples: 'roofing', 'plumbing', 'crawl space encapsulation', 'tree removal', 'handyman'. This drives the local-vendor search.",
  "summary": "1-sentence rephrase in Tom's voice — what does the customer actually want?",
  "key_considerations": "2-3 sentences naming the SPECIFIC factors that matter for THIS homeowner — e.g. age of home, pet/access notes, vendor preferences, budget orientation. Reference real fields, not fluff.",
  "questions_to_ask": ["3-5 short questions Tom should ask each vendor on the phone. Be specific to this home + situation."],
  "call_script": "A 3-4 sentence call opener Tom can read on the phone. First-person ('Hi, I'm calling on behalf of a homeowner in [town]…'). Ends with the first question. ~80 words.",
  "recommended_approach": "1-2 sentence playbook for Tom: how many quotes to gather, what to focus on, anything quirky about this specific homeowner."
}

Return ONLY the JSON. No preamble.`;

    try {
      const resp = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 1500,
          messages: [{ role: "user", content: userPrompt }],
        }),
      });
      if (resp.ok) {
        const data = await resp.json() as { content?: Array<{ text?: string }> };
        const text = data.content?.[0]?.text?.trim() ?? "";
        try {
          // Claude sometimes wraps JSON in fences despite instructions.
          const cleaned = text.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/i, "");
          analysis = { ...analysis, ...JSON.parse(cleaned) };
        } catch (parseErr) {
          console.warn("[analyze] JSON parse failed; raw:", text.slice(0, 400));
        }
      } else {
        console.warn("[analyze] Claude error:", resp.status, await resp.text());
      }
    } catch (e) {
      console.warn("[analyze] exception:", e);
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
  let placesCandidates: Array<Record<string, unknown>> = [];
  if (inferredCat && property.city && property.state) {
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

  return json({
    analysis,
    existing_vendors: existingMatches,
    places_candidates: placesCandidates,
    property_location: { city: property.city ?? "", state: property.state ?? "" },
  });
}

interface AnalysisResult {
  inferred_category: string;
  summary: string;
  key_considerations: string;
  questions_to_ask: string[];
  call_script: string;
  recommended_approach: string;
}

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

  const systemPrompt = `You are Alfred, the case-scoped AI co-pilot for Chez Concierge agents. You have full context on a homeowner case and answer the agent's questions directly. You're talking to a human operator (an experienced agent), not the homeowner.

Voice rules:
- Concise, professional, no fluff. 1-3 sentences when the question is direct; up to 5-6 when the question needs reasoning.
- Reference SPECIFIC facts from the case context when they're relevant (year of home, vendor names, past cases, profile preferences). Don't invent.
- If the agent asks about cost, vendor selection, or precedent, look at PAST CASES + EXISTING VENDORS first before generalizing.
- Never give legal / regulatory advice — defer to "verify with a licensed pro" when the question touches code, permits, or insurance.
- If the answer requires data you don't have, say so plainly + suggest where the agent could find it (the homeowner profile, the past-case archive, etc.).

The agent's question is below. Return ONLY the answer text — no preamble, no markdown headers, no quotes.`;

  const userPrompt = `# CASE CONTEXT

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

## Recent thread (most recent ${Math.min(messages.length, 12)} messages)
${threadLines || "(no messages yet)"}

## Past Chez cases for this homeowner
${pastRequestLines || "(none)"}

# AGENT QUESTION
${question}`;

  try {
    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 600,
        system: systemPrompt,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });
    if (!resp.ok) {
      const text = await resp.text();
      console.warn("[ask_alfred] Claude error:", resp.status, text.slice(0, 300));
      return json({ answer: "Alfred had trouble reaching the model. Try once more in a moment." });
    }
    const data = await resp.json() as { content?: Array<{ text?: string }> };
    const answer = data.content?.[0]?.text?.trim() ?? "(empty response)";
    return json({ answer });
  } catch (e) {
    console.warn("[ask_alfred] exception:", e);
    return json({ answer: "I couldn't reach the model. The case context is loaded; try once more." });
  }
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
  const householdId = await householdIdForUser(service, user.id);
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
      await service.from("concierge_messages").insert({
        household_id: householdId,
        user_id: user.id,
        request_id: r.id,
        role: "system",
        content: `${instruction}${payload.notes ? `\n\nNotes from customer:\n${payload.notes}` : ""}`,
        attachments: [],
      });
      await sendPush(
        serviceUrl,
        serviceRoleKey,
        adminUserIds(),
        `Customer delegated a ${ENTITY_FRIENDLY_LABEL[entityType] ?? "entity"} to Chez`,
        summary,
        { type: "chez_admin_request", request_id: r.id }
      );
      await sendAdminEmail(
        adminEmails(),
        `[Chez] New standing engagement: ${labelForThread}`,
        `${instruction}\n\n${payload.notes ?? ""}\n\n${adminPortalUrl(r.id)}`,
        emailBody({
          preview: `Customer handed off a ${ENTITY_FRIENDLY_LABEL[entityType] ?? "entity"} to Chez.`,
          heading: "New standing engagement",
          intro: `The customer wants Chez to own management of "${labelForThread}" from now on.`,
          bodyText: payload.notes ?? "(no additional notes)",
          ctaLabel: "Open in admin portal",
          ctaUrl: adminPortalUrl(r.id),
        })
      );
    }
  }

  return json({ ok: true });
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
  const householdId = await householdIdForUser(service, user.id);
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
      await service.from("concierge_messages").insert({
        household_id: householdId,
        user_id: user.id,
        request_id: r.id,
        role: "system",
        content: `Customer asked Chez to take over ${friendly[group] ?? group} (${backfillCount} item${backfillCount === 1 ? "" : "s"} now owned). New entries in this category will auto-delegate going forward.${payload.notes ? `\n\nNotes:\n${payload.notes}` : ""}`,
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
        `Customer flipped on ${friendly[group] ?? group}. ${backfillCount} existing items now owned by Chez.\n\n${adminPortalUrl(r.id)}`,
        emailBody({
          preview: `${backfillCount} ${friendly[group] ?? group} now Chez-owned.`,
          heading: "New group delegation",
          intro: `The customer wants Chez to own ${friendly[group] ?? group} from now on.`,
          bodyText: `${backfillCount} existing items stamped owned. ${payload.notes ?? ""}`,
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
  return json({ ok: true, action: auditRow ?? null, side_effect: sideEffectResult });
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
      // Stamp last_completed_date and clear scheduled_date. We don't
      // recompute next_due_date server-side here — the iOS reconciler
      // recomputes it on the next reconcile pass via interval-aware
      // logic that lives in MaintenanceTaskReconciler. For tasks
      // without a frequency (one-shots), next_due_date stays null,
      // which surfaces them as resolved.
      const { error } = await service
        .from("maintenance_tasks")
        .update({
          last_completed_date: completedAt,
          scheduled_date: null,
        })
        .eq("id", entityId);
      if (error) throw new Error(`maintenance_tasks update failed: ${error.message}`);
      return { completed_at: completedAt };
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
      // No DB write today — Claude draft will be wired in PR 7. For
      // now we just record the intent in the audit trail.
      return { drafted: false, reason: "claude_draft_not_yet_wired" };
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

async function handleFetchHouseholdsList(
  service: ServiceClient,
  user: { id: string; email?: string | null } | null
) {
  if (!user || !isAdminUser(user)) return json({ error: "admin only" }, 403);

  const safe = async <T,>(p: PromiseLike<T>, label: string): Promise<T | null> => {
    try { return await p; } catch (e) { console.warn(`[households_list] ${label} failed:`, e); return null; }
  };

  const [householdsRes, requestsRes, routinesRes, contractorsRes, tasksRes, systemsRes, projectsRes] = await Promise.all([
    safe(service.from("households").select("id, name, created_at, chez_ownership_groups").order("created_at", { ascending: false }), "households"),
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
    casesRes, workbenchActionsRes, remindersRes,
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
    safe(service.from("documents").select("id, household_id, filename, category, mime_type, expiration_date, chez_owned, chez_owned_at").eq("household_id", householdId).limit(200), "documents"),
    safe(service.from("utility_accounts").select("*").eq("household_id", householdId), "utilities"),
    safe(service.from("vehicles").select("*").eq("household_id", householdId), "vehicles"),
    safe(service.from("chez_requests").select("*").eq("household_id", householdId).neq("status", "resolved").order("last_message_at", { ascending: false }), "open_cases"),
    safe(service.from("chez_workbench_actions").select("*").eq("household_id", householdId).order("created_at", { ascending: false }).limit(20), "workbench_actions"),
    safe(service.from("chez_reminders").select("*").eq("household_id", householdId).is("completed_at", null).order("due_at", { ascending: true }).limit(20), "reminders"),
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

  await sendPush(serviceUrl, serviceRoleKey, adminUserIds(),
    "Home assessment cancelled",
    `Customer cancelled their assessment (${payload.reason ?? "homeowner_self_serve"}).`,
    { type: "chez_admin_request", assessment_id: assessmentId });
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

  await service.from("home_assessments")
    .update({
      reschedule_requested_at: new Date().toISOString(),
      reschedule_request_notes: payload.notes ?? null,
    })
    .eq("id", assessmentId);

  const preferredText = (payload.preferred_dates ?? []).join(", ");
  await sendPush(serviceUrl, serviceRoleKey, adminUserIds(),
    "Reschedule requested",
    `Customer asked to reschedule their assessment.${preferredText ? ` Preferred: ${preferredText}` : ""}`,
    { type: "chez_admin_request", assessment_id: assessmentId });
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

      default:
        return json({ error: `unknown action: ${action}` }, 400);
    }
  } catch (error) {
    console.error("[chez-concierge] uncaught:", error);
    return json({ error: String(error) }, 500);
  }
});
