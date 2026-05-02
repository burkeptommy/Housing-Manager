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

  const userPrompt = `You are helping a Chez Concierge admin draft a 1-2 sentence "why this vendor fits" line for a homeowner. Be specific to the homeowner's context. No marketing fluff. Concise + concrete.

Request: ${payload.request_summary}
Category: ${payload.request_category}

Vendor candidate:
- Name: ${v.name}
- Category: ${v.category ?? "unspecified"}
- Reputation: ${ratingLine}
${v.notes ? `- Notes: ${v.notes}` : ""}

${homeownerLine}
${propertyLine}

Write 1-2 sentences (max ~250 characters total) the admin can paste into a proposal card. Reference the homeowner's specific situation when possible. No preamble. Plain text only.`;

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

      default:
        return json({ error: `unknown action: ${action}` }, 400);
    }
  } catch (error) {
    console.error("[chez-concierge] uncaught:", error);
    return json({ error: String(error) }, 500);
  }
});
