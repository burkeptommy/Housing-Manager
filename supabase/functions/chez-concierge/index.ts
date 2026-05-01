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
      ? `Tom needs your answer: ${request.summary}`
      : `Tom replied: ${request.summary}`;
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
          ? "Tom marked this resolved."
          : newStatus === "waiting_customer"
          ? "Tom is waiting on your answer."
          : "Tom reopened this request.";
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
      ackRequired ? "Tom needs your answer" : "Tom replied",
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
  note?: string;  // optional system message body ("Tom marked this resolved with a note")
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

  // System message in the thread for the audit trail.
  const actorLabel = isAdmin ? "Tom" : "Homeowner";
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
        summary: payload.note || "Tom marked this concierge request resolved.",
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
      default:
        return json({ error: `unknown action: ${action}` }, 400);
    }
  } catch (error) {
    console.error("[chez-concierge] uncaught:", error);
    return json({ error: String(error) }, 500);
  }
});
