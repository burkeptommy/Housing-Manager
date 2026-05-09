// Wave M7 — Crew chat (intra-workspace messaging)
//
// Tech-to-tech / tech-to-dispatch coordination. Distinct from the
// customer-visible thread on `handyman_request_messages` so workspace
// members can post "Bob just called in sick — anyone available to take
// 4pm at the Smiths?" without it surfacing on the homeowner's iOS app.
//
// Action discriminator pattern matches `handyman-provider`. Auth via
// Supabase session JWT in the Authorization header. Workspace
// membership is verified via `assertWorkspaceAccess` so a malicious
// caller can't read or write another workspace's threads.
//
// Four actions:
//   - `list_threads`   — workspace's threads with last-message previews + unread counts
//   - `send`           — insert a `crew_chat_messages` row
//   - `mark_read`      — append the caller's member_id into every message's `read_by` array
//   - `create_thread`  — create a new thread (general / route_day / tech_pair)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function compactString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function isoNow(): string {
  return new Date().toISOString();
}

type ServiceClient = ReturnType<typeof createClient>;

async function getAuthenticatedUser(service: ServiceClient, req: Request) {
  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice("Bearer ".length) : "";
  if (!token) return null;
  const { data, error } = await service.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}

const MEMBER_SELECT =
  "id, workspace_id, role, full_name, email, phone, status, user_id, provider_workspaces(id)";

/**
 * Resolve the caller's active workspace membership. Mirrors the
 * `getWorkspaceMembership` helper in `handyman-provider` but trimmed
 * to the columns this function needs. We accept an optional
 * preferredWorkspaceId so multi-workspace users can scope reads.
 */
async function getWorkspaceMembership(
  service: ServiceClient,
  userId: string,
  authEmail: string | undefined,
  preferredWorkspaceId: string,
) {
  // Primary: caller pinned to a workspace they belong to.
  if (preferredWorkspaceId) {
    const preferred = await service
      .from("provider_workspace_members")
      .select(MEMBER_SELECT)
      .eq("user_id", userId)
      .eq("workspace_id", preferredWorkspaceId)
      .eq("status", "active")
      .limit(1)
      .maybeSingle();
    if (preferred.error) throw preferred.error;
    if (preferred.data) return preferred.data as Record<string, unknown>;
  }

  // Fall through: first active membership for this user.
  const direct = await service
    .from("provider_workspace_members")
    .select(MEMBER_SELECT)
    .eq("user_id", userId)
    .eq("status", "active")
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
  if (direct.error) throw direct.error;
  if (direct.data) return direct.data as Record<string, unknown>;

  // Final fallback: invited row addressed to the verified auth email.
  // Auto-claim it on first sign-in, mirrors handyman-provider behavior.
  const trimmedEmail = authEmail?.trim().toLowerCase();
  if (!trimmedEmail) return null;

  const invitedByEmail = await service
    .from("provider_workspace_members")
    .select(MEMBER_SELECT)
    .ilike("email", trimmedEmail)
    .eq("status", "invited")
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();
  if (invitedByEmail.error) throw invitedByEmail.error;
  if (invitedByEmail.data) {
    const row = invitedByEmail.data as Record<string, unknown>;
    const memberId = compactString(row.id);
    if (memberId) {
      await service
        .from("provider_workspace_members")
        .update({
          user_id: userId,
          status: "active",
          invite_token: null,
          last_seen_at: isoNow(),
          updated_at: isoNow(),
        })
        .eq("id", memberId);
    }
    return { ...row, user_id: userId, status: "active" };
  }

  return null;
}

/**
 * Verify the caller belongs to the requested workspace. Returns the
 * full membership row so the caller can use member_id, role, etc.
 */
async function assertWorkspaceAccess(
  service: ServiceClient,
  user: { id: string; email?: string },
  workspaceId: string,
) {
  if (!workspaceId) throw new Error("workspaceId is required");
  const membership = await getWorkspaceMembership(
    service,
    compactString(user.id),
    user.email,
    workspaceId,
  );
  if (!membership) throw new Error("No provider workspace found");
  const activeWorkspaceId = compactString(
    (membership.provider_workspaces as Record<string, unknown> | undefined)?.id,
  );
  if (activeWorkspaceId !== workspaceId) {
    throw new Error("Workspace access denied");
  }
  return membership;
}

/**
 * `list_threads` — return every thread for the workspace with the most
 * recent message preview and an unread count. Unread = messages where
 * the caller's member_id is NOT in the `read_by` JSONB array.
 *
 * Compute unread counts client-side after the join because PostgREST
 * doesn't have a clean way to count "json array doesn't contain X"
 * across joined rows in a single query without a custom RPC.
 */
async function listThreads(
  service: ServiceClient,
  user: { id: string; email?: string },
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const membership = await assertWorkspaceAccess(service, user, workspaceId);
  const memberId = compactString(membership.id);

  const { data: threads, error: threadsError } = await service
    .from("crew_chat_threads")
    .select("id, workspace_id, name, kind, created_at")
    .eq("workspace_id", workspaceId)
    .order("created_at", { ascending: false });

  if (threadsError) throw threadsError;

  const threadIds = (threads ?? []).map((row) => compactString(row.id));
  if (threadIds.length === 0) {
    return { threads: [] };
  }

  // Pull every message for these threads in one query — at this scale
  // (a workspace has at most a few dozen threads × ~hundreds of
  // messages) it's cheaper than N round-trips per thread. Order
  // ascending so the last entry per thread is the most recent.
  const { data: messages, error: messagesError } = await service
    .from("crew_chat_messages")
    .select("id, thread_id, sender_member_id, body, attachments, read_by, created_at")
    .in("thread_id", threadIds)
    .order("created_at", { ascending: true });

  if (messagesError) throw messagesError;

  const senderIds = Array.from(
    new Set(
      (messages ?? [])
        .map((row: Record<string, unknown>) => compactString(row.sender_member_id))
        .filter(Boolean),
    ),
  );

  const senderById = new Map<string, Record<string, unknown>>();
  if (senderIds.length > 0) {
    const { data: senders } = await service
      .from("provider_workspace_members")
      .select("id, full_name, email")
      .in("id", senderIds);
    for (const sender of (senders ?? []) as Record<string, unknown>[]) {
      senderById.set(compactString(sender.id), sender);
    }
  }

  const lastMessageByThread = new Map<string, Record<string, unknown>>();
  const unreadCountByThread = new Map<string, number>();
  for (const row of (messages ?? []) as Record<string, unknown>[]) {
    const threadId = compactString(row.thread_id);
    if (!threadId) continue;

    // Last message wins because messages are sorted ascending.
    lastMessageByThread.set(threadId, row);

    const readBy = Array.isArray(row.read_by) ? row.read_by : [];
    const senderMemberId = compactString(row.sender_member_id);
    // The sender has implicitly read their own message — don't ask
    // them to mark it.
    if (senderMemberId === memberId) continue;
    if (!readBy.includes(memberId)) {
      unreadCountByThread.set(threadId, (unreadCountByThread.get(threadId) ?? 0) + 1);
    }
  }

  return {
    threads: (threads ?? []).map((thread) => {
      const threadId = compactString(thread.id);
      const lastMessage = lastMessageByThread.get(threadId);
      const sender = lastMessage
        ? senderById.get(compactString(lastMessage.sender_member_id))
        : undefined;

      return {
        id: threadId,
        workspaceId: compactString(thread.workspace_id),
        name: compactString(thread.name) || null,
        kind: compactString(thread.kind) || "general",
        createdAt: thread.created_at,
        lastMessage: lastMessage
          ? {
              id: compactString(lastMessage.id),
              body: compactString(lastMessage.body),
              senderMemberId: compactString(lastMessage.sender_member_id),
              senderName:
                compactString(sender?.full_name) ||
                compactString(sender?.email) ||
                "Workspace member",
              createdAt: lastMessage.created_at,
            }
          : null,
        unreadCount: unreadCountByThread.get(threadId) ?? 0,
      };
    }),
  };
}

/**
 * `send` — insert a single `crew_chat_messages` row. The sender's
 * member_id is auto-stamped (we never trust client-supplied
 * sender_member_id). Attachments are an opaque JSONB array — caller
 * is responsible for shape; we just round-trip what they send.
 */
async function sendMessage(
  service: ServiceClient,
  user: { id: string; email?: string },
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const membership = await assertWorkspaceAccess(service, user, workspaceId);
  const memberId = compactString(membership.id);

  const threadId = compactString(body.threadId);
  if (!threadId) throw new Error("threadId is required");

  const text = compactString(body.body);
  if (!text) throw new Error("body is required");
  if (text.length > 4000) throw new Error("Message is too long (max 4000 chars)");

  // Verify the thread belongs to this workspace before insert. RLS
  // would catch this too via the policy USING clause, but failing
  // fast with a clear error beats a generic RLS denial.
  const { data: thread, error: threadError } = await service
    .from("crew_chat_threads")
    .select("id, workspace_id")
    .eq("id", threadId)
    .eq("workspace_id", workspaceId)
    .limit(1)
    .maybeSingle();
  if (threadError) throw threadError;
  if (!thread) throw new Error("Thread not found in this workspace");

  // Attachments: accept whatever the client sent, default to empty
  // array. Same opaque-shape policy as the punch-item attachments
  // pattern from M2.
  const attachments = Array.isArray(body.attachments) ? body.attachments : [];

  // Sender pre-reads their own message so it doesn't count toward
  // their own unread badge.
  const readBy = [memberId];

  const { data: inserted, error: insertError } = await service
    .from("crew_chat_messages")
    .insert({
      thread_id: threadId,
      workspace_id: workspaceId,
      sender_member_id: memberId,
      body: text,
      attachments,
      read_by: readBy,
    })
    .select()
    .single();

  if (insertError || !inserted) throw insertError ?? new Error("Failed to send message");

  const senderName =
    compactString(membership.full_name) ||
    compactString(membership.email) ||
    "Workspace member";

  return {
    message: {
      id: compactString(inserted.id),
      threadId: compactString(inserted.thread_id),
      workspaceId: compactString(inserted.workspace_id),
      senderMemberId: compactString(inserted.sender_member_id),
      senderName,
      body: compactString(inserted.body),
      attachments: Array.isArray(inserted.attachments) ? inserted.attachments : [],
      readBy: Array.isArray(inserted.read_by) ? inserted.read_by : [memberId],
      createdAt: inserted.created_at,
    },
  };
}

/**
 * `mark_read` — append the caller's member_id to `read_by` on every
 * message in the thread. Idempotent: if the member is already in the
 * array, the row is skipped (no-op).
 *
 * We can't use a single UPDATE with array-append-on-conflict-skip in
 * vanilla PostgREST without a custom RPC, so we fetch the messages
 * with their current read_by, compute the new arrays in memory, and
 * batch-update only the rows that changed.
 */
async function markThreadRead(
  service: ServiceClient,
  user: { id: string; email?: string },
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  const membership = await assertWorkspaceAccess(service, user, workspaceId);
  const memberId = compactString(membership.id);

  const threadId = compactString(body.threadId);
  if (!threadId) throw new Error("threadId is required");

  // Pull only the rows that DON'T already contain memberId. Using
  // PostgREST's `not` + `cs` (contains) operator with a JSONB array
  // is fiddly and version-dependent, so we fetch all and filter in
  // memory — at our scale (≤ a few hundred messages per thread) this
  // is fine.
  const { data: messages, error: fetchError } = await service
    .from("crew_chat_messages")
    .select("id, read_by")
    .eq("thread_id", threadId)
    .eq("workspace_id", workspaceId);
  if (fetchError) throw fetchError;

  const updates: Array<{ id: string; read_by: string[] }> = [];
  for (const row of (messages ?? []) as Record<string, unknown>[]) {
    const id = compactString(row.id);
    const readBy = Array.isArray(row.read_by) ? (row.read_by as string[]) : [];
    if (readBy.includes(memberId)) continue;
    updates.push({ id, read_by: [...readBy, memberId] });
  }

  // Update in serial — `crew_chat_messages` updates per thread are
  // small and we'd rather not race ourselves with concurrent writes
  // to the same row.
  let updated = 0;
  for (const update of updates) {
    const { error: updateError } = await service
      .from("crew_chat_messages")
      .update({ read_by: update.read_by })
      .eq("id", update.id);
    if (updateError) throw updateError;
    updated += 1;
  }

  return { ok: true, markedCount: updated };
}

/**
 * `create_thread` — insert a new thread row. Used for ad-hoc
 * tech-pair conversations ("just you and Maria"), route-day threads
 * ("Tuesday route, May 12"), and ad-hoc generals. memberIds is
 * preserved on the JSONB attachments roadmap for future participant
 * scoping but ignored today — every thread is workspace-wide because
 * every active member can see every thread by RLS policy.
 */
async function createThread(
  service: ServiceClient,
  user: { id: string; email?: string },
  body: Record<string, unknown>,
) {
  const workspaceId = compactString(body.workspaceId);
  await assertWorkspaceAccess(service, user, workspaceId);

  const rawKind = compactString(body.kind) || "general";
  if (!["general", "route_day", "tech_pair"].includes(rawKind)) {
    throw new Error("kind must be one of: general, route_day, tech_pair");
  }

  const name = compactString(body.name) || null;

  // memberIds isn't persisted today (no participants table), but we
  // accept it so the iOS UI for ad-hoc tech-pair threads can ship a
  // stable shape. Future migration can fold this into a join table.
  // Validate the array shape so we'd catch callers passing the wrong
  // type early.
  if (body.memberIds != null && !Array.isArray(body.memberIds)) {
    throw new Error("memberIds must be an array of UUID strings");
  }

  const { data: inserted, error: insertError } = await service
    .from("crew_chat_threads")
    .insert({
      workspace_id: workspaceId,
      name,
      kind: rawKind,
    })
    .select()
    .single();

  if (insertError || !inserted) throw insertError ?? new Error("Failed to create thread");

  return {
    thread: {
      id: compactString(inserted.id),
      workspaceId: compactString(inserted.workspace_id),
      name: compactString(inserted.name) || null,
      kind: compactString(inserted.kind) || "general",
      createdAt: inserted.created_at,
      lastMessage: null,
      unreadCount: 0,
    },
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "Missing Supabase configuration" }, 500);
    }

    const service = createClient(supabaseUrl, serviceRoleKey);

    if (req.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const user = await getAuthenticatedUser(service, req);
    if (!user) return json({ error: "Unauthorized" }, 401);

    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
    const action = compactString(body.action);

    const ctx = { id: compactString(user.id), email: user.email };

    if (action === "list_threads") {
      const result = await listThreads(service, ctx, body);
      return json(result);
    }

    if (action === "send") {
      const result = await sendMessage(service, ctx, body);
      return json(result);
    }

    if (action === "mark_read") {
      const result = await markThreadRead(service, ctx, body);
      return json(result);
    }

    if (action === "create_thread") {
      const result = await createThread(service, ctx, body);
      return json(result);
    }

    return json({ error: `Unknown action: ${action}` }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Internal error";
    console.error("[crew-chat] Error:", message);
    // Workspace-access errors and validation errors map to 400 so the
    // iOS UI can render a friendly inline message. Everything else is
    // treated as a server failure.
    const isClientError =
      message.toLowerCase().includes("workspace") ||
      message.toLowerCase().includes("required") ||
      message.toLowerCase().includes("must be") ||
      message.toLowerCase().includes("not found") ||
      message.toLowerCase().includes("too long") ||
      message.toLowerCase().includes("unknown action");
    return json({ error: message }, isClientError ? 400 : 500);
  }
});
