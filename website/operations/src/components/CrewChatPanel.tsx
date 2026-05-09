import { useEffect, useMemo, useRef, useState } from "react";
import { Card } from "./chrome/Card";
import { Pill } from "./chrome/Pill";
import { Avatar, initialsFor } from "./chrome/Avatar";
import { Icon } from "./chrome/Icon";
import { EmptyState } from "./chrome/EmptyState";
import { postCrewChatAction, formatRelativeTime } from "../lib/api";
import type {
  CrewChatThread,
  CrewChatMessage,
  CrewChatThreadKind,
  TeamMember,
} from "../lib/types";
import { supabase } from "../lib/supabase";

// Wave M7 — Operations Desk parity with the iOS Crew tab. Renders as
// a sub-tab under Crew (next to Roster). Mirrors the iOS shape:
// thread list, per-thread bubbles, composer at the bottom of the
// open thread, "+ New thread" affordance.

interface CrewChatPanelProps {
  workspaceId: string;
  members: TeamMember[];
  /** Caller's own member id, sourced from the workspace dashboard.
   * When provided, our own messages render right-aligned in salmon. */
  selfMemberId?: string | null;
}

interface ListThreadsResponse {
  threads: CrewChatThread[];
}

interface SendMessageResponse {
  message: CrewChatMessage;
}

interface CreateThreadResponse {
  thread: CrewChatThread;
}

/**
 * Wave M7 — supabase-js direct fetch of `crew_chat_messages` for a
 * thread. RLS gates access via `get_my_provider_workspace_ids()`, so
 * the caller's session JWT is the only auth boundary needed.
 */
async function fetchMessagesForThread(
  threadId: string,
  workspaceId: string,
): Promise<CrewChatMessage[]> {
  const { data, error } = await supabase
    .from("crew_chat_messages")
    .select(
      "id,thread_id,workspace_id,sender_member_id,body,attachments,read_by,created_at",
    )
    .eq("thread_id", threadId)
    .eq("workspace_id", workspaceId)
    .order("created_at", { ascending: true });
  if (error) throw error;
  return (data ?? []).map((row) => ({
    id: String(row.id),
    threadId: String(row.thread_id),
    workspaceId: row.workspace_id ? String(row.workspace_id) : null,
    senderMemberId: String(row.sender_member_id),
    senderName: "Workspace member",
    body: String(row.body ?? ""),
    attachments: Array.isArray(row.attachments) ? row.attachments : [],
    readBy: Array.isArray(row.read_by) ? row.read_by : [],
    createdAt: row.created_at,
  }));
}

export function CrewChatPanel({ workspaceId, members, selfMemberId }: CrewChatPanelProps) {
  const [threads, setThreads] = useState<CrewChatThread[]>([]);
  const [selectedThreadId, setSelectedThreadId] = useState<string | null>(null);
  const [messages, setMessages] = useState<CrewChatMessage[]>([]);
  const [isLoadingThreads, setIsLoadingThreads] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [composerBody, setComposerBody] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [showNewThread, setShowNewThread] = useState(false);

  // Member name lookup by id. Preferred over the row's senderName so
  // the row reflects current roster shape rather than what the server
  // happened to return when the message was inserted.
  const memberNameById = useMemo(() => {
    const map = new Map<string, string>();
    for (const m of members) {
      map.set(m.id, m.fullName || m.email || "Workspace member");
    }
    return map;
  }, [members]);

  const sortedThreads = useMemo(() => {
    return [...threads].sort((a, b) => {
      const aKey = a.lastMessage?.createdAt || a.createdAt || "";
      const bKey = b.lastMessage?.createdAt || b.createdAt || "";
      return aKey > bKey ? -1 : aKey < bKey ? 1 : 0;
    });
  }, [threads]);

  const selectedThread = useMemo(
    () => sortedThreads.find((t) => t.id === selectedThreadId) ?? null,
    [sortedThreads, selectedThreadId],
  );

  async function loadThreads() {
    setIsLoadingThreads(true);
    setError(null);
    try {
      const result = await postCrewChatAction<ListThreadsResponse>("list_threads", {
        workspaceId,
      });
      setThreads(result.threads ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Couldn't load crew chat");
    } finally {
      setIsLoadingThreads(false);
    }
  }

  async function loadMessages(threadId: string) {
    try {
      const fetched = await fetchMessagesForThread(threadId, workspaceId);
      setMessages(fetched);
    } catch (e) {
      console.error("[CrewChatPanel] load messages failed:", e);
    }
  }

  async function markRead(threadId: string) {
    try {
      await postCrewChatAction("mark_read", { workspaceId, threadId });
      await loadThreads();
    } catch (e) {
      // Non-fatal — badge will clear on next refresh.
      console.error("[CrewChatPanel] mark_read failed:", e);
    }
  }

  async function send() {
    const trimmed = composerBody.trim();
    if (!trimmed || !selectedThreadId || isSending) return;
    setIsSending(true);
    try {
      const result = await postCrewChatAction<SendMessageResponse>("send", {
        workspaceId,
        threadId: selectedThreadId,
        body: trimmed,
      });
      setMessages((prev) => {
        // Dedup against the realtime echo.
        if (prev.some((m) => m.id === result.message.id)) return prev;
        return [...prev, result.message];
      });
      setComposerBody("");
      await loadThreads();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Couldn't send message");
    } finally {
      setIsSending(false);
    }
  }

  // Initial load + workspace-scoped realtime subscription.
  useEffect(() => {
    if (!workspaceId) return;
    let cancelled = false;
    void loadThreads();

    const channel = supabase
      .channel(`crew-chat-${workspaceId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "crew_chat_messages",
          filter: `workspace_id=eq.${workspaceId}`,
        },
        () => {
          if (cancelled) return;
          void loadThreads();
          // If a thread is open, refresh its messages too.
          if (selectedThreadId) {
            void loadMessages(selectedThreadId);
          }
        },
      )
      .subscribe();

    return () => {
      cancelled = true;
      void supabase.removeChannel(channel);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [workspaceId]);

  // When the selected thread changes, fetch its messages + mark read.
  useEffect(() => {
    if (!selectedThreadId) {
      setMessages([]);
      return;
    }
    void loadMessages(selectedThreadId);
    void markRead(selectedThreadId);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedThreadId]);

  function handleCreated(thread: CrewChatThread) {
    setShowNewThread(false);
    setThreads((prev) => {
      if (prev.some((t) => t.id === thread.id)) return prev;
      return [thread, ...prev];
    });
    setSelectedThreadId(thread.id);
  }

  return (
    <div style={{ display: "grid", gridTemplateColumns: "320px 1fr", gap: 16 }}>
      {/* Left rail — thread list */}
      <Card padding="default" style={{ padding: 0, overflow: "hidden" }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "14px 16px",
            borderBottom: "1px solid var(--border, #E6E5EE)",
          }}
        >
          <div>
            <div className="ops-section-label">Threads</div>
            <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
              {sortedThreads.length === 0
                ? "Nothing yet"
                : `${sortedThreads.length} thread${sortedThreads.length === 1 ? "" : "s"}`}
            </div>
          </div>
          <button
            className="ops-button ops-button--salmon"
            onClick={() => setShowNewThread(true)}
            style={{ padding: "6px 12px", fontSize: 12 }}
          >
            + New
          </button>
        </div>
        <div style={{ maxHeight: 520, overflowY: "auto" }}>
          {isLoadingThreads && sortedThreads.length === 0 ? (
            <div style={{ padding: 16, fontSize: 12, color: "var(--text-muted)" }}>
              Loading…
            </div>
          ) : sortedThreads.length === 0 ? (
            <EmptyState
              icon="message"
              title="No threads"
              body="Start one with the + New button above."
            />
          ) : (
            sortedThreads.map((thread) => (
              <button
                key={thread.id}
                onClick={() => setSelectedThreadId(thread.id)}
                style={threadRowStyle(thread.id === selectedThreadId)}
              >
                <div
                  style={{
                    width: 32,
                    height: 32,
                    borderRadius: "50%",
                    background: "var(--indigo-50)",
                    color: "var(--indigo)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    flex: "none",
                  }}
                >
                  <Icon
                    name={iconNameForKind(thread.kind)}
                    size={14}
                    stroke={2}
                  />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div
                    style={{
                      display: "flex",
                      alignItems: "baseline",
                      gap: 6,
                    }}
                  >
                    <span
                      style={{
                        fontSize: 13,
                        fontWeight: 600,
                        color: "var(--text)",
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {displayNameForThread(thread)}
                    </span>
                    {thread.lastMessage?.createdAt && (
                      <span style={{ fontSize: 11, color: "var(--text-soft)" }}>
                        {formatRelativeTime(thread.lastMessage.createdAt)}
                      </span>
                    )}
                  </div>
                  <div
                    style={{
                      fontSize: 11.5,
                      color: "var(--text-muted)",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap",
                    }}
                  >
                    {thread.lastMessage
                      ? `${thread.lastMessage.senderName}: ${thread.lastMessage.body}`
                      : "No messages yet."}
                  </div>
                </div>
                {thread.unreadCount > 0 && (
                  <Pill tone="salmon">{thread.unreadCount}</Pill>
                )}
              </button>
            ))
          )}
        </div>
      </Card>

      {/* Right pane — open thread */}
      {selectedThread ? (
        <Card padding="default" style={{ padding: 0, display: "flex", flexDirection: "column" }}>
          <div
            style={{
              padding: "14px 18px",
              borderBottom: "1px solid var(--border, #E6E5EE)",
              display: "flex",
              alignItems: "center",
              gap: 10,
            }}
          >
            <Icon name={iconNameForKind(selectedThread.kind)} size={16} stroke={2} />
            <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>
              {displayNameForThread(selectedThread)}
            </div>
            <Pill tone="indigo">{kindLabel(selectedThread.kind)}</Pill>
          </div>
          <div style={{ flex: 1, padding: 16, maxHeight: 460, overflowY: "auto" }}>
            <ThreadMessages
              messages={messages}
              memberNameById={memberNameById}
              selfMemberId={selfMemberId ?? null}
            />
          </div>
          <div
            style={{
              padding: 12,
              borderTop: "1px solid var(--border, #E6E5EE)",
              display: "flex",
              gap: 8,
            }}
          >
            <input
              value={composerBody}
              onChange={(e) => setComposerBody(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  void send();
                }
              }}
              placeholder="Message the workspace…"
              style={{
                flex: 1,
                padding: "10px 12px",
                fontSize: 13,
                borderRadius: 12,
                border: "1px solid var(--border, #E6E5EE)",
                background: "var(--pearl, #F8F9FA)",
                outline: "none",
              }}
            />
            <button
              className="ops-button ops-button--salmon"
              disabled={!composerBody.trim() || isSending}
              onClick={() => void send()}
              style={{ minWidth: 72, opacity: !composerBody.trim() || isSending ? 0.6 : 1 }}
            >
              {isSending ? "…" : "Send"}
            </button>
          </div>
        </Card>
      ) : (
        <Card padding="default">
          <EmptyState
            icon="message"
            title="Pick a thread"
            body="Tap a row on the left to open the conversation."
          />
        </Card>
      )}

      {error && (
        <div
          style={{
            position: "fixed",
            bottom: 24,
            right: 24,
            background: "var(--surface, #FFFFFF)",
            border: "1px solid var(--critical, #B91C1C)",
            padding: "10px 14px",
            borderRadius: 12,
            fontSize: 12.5,
            color: "var(--critical, #B91C1C)",
            zIndex: 200,
          }}
        >
          {error}
          <button
            onClick={() => setError(null)}
            style={{ marginLeft: 12, color: "var(--text-muted)", background: "transparent", border: "none", cursor: "pointer" }}
          >
            ×
          </button>
        </div>
      )}

      {showNewThread && (
        <NewThreadModal
          workspaceId={workspaceId}
          members={members}
          onClose={() => setShowNewThread(false)}
          onCreated={handleCreated}
        />
      )}
    </div>
  );
}

function ThreadMessages({
  messages,
  memberNameById,
  selfMemberId,
}: {
  messages: CrewChatMessage[];
  memberNameById: Map<string, string>;
  selfMemberId: string | null;
}) {
  const scrollRef = useRef<HTMLDivElement | null>(null);
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages.length]);

  if (messages.length === 0) {
    return (
      <div style={{ padding: "32px 16px", textAlign: "center", color: "var(--text-muted)", fontSize: 13 }}>
        No messages yet. Send the first one to start the thread.
      </div>
    );
  }

  return (
    <div ref={scrollRef} style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      {messages.map((m) => {
        const isMine = selfMemberId != null && m.senderMemberId === selfMemberId;
        const senderName =
          memberNameById.get(m.senderMemberId) ?? m.senderName ?? "Workspace member";
        return (
          <div
            key={m.id}
            style={{
              display: "flex",
              flexDirection: isMine ? "row-reverse" : "row",
              gap: 8,
            }}
          >
            <Avatar initials={initialsFor(senderName)} size={28} />
            <div
              style={{
                maxWidth: "70%",
                display: "flex",
                flexDirection: "column",
                alignItems: isMine ? "flex-end" : "flex-start",
                gap: 2,
              }}
            >
              <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{senderName}</div>
              <div
                style={{
                  padding: "8px 12px",
                  background: isMine ? "var(--salmon)" : "var(--surface, #FFFFFF)",
                  color: isMine ? "#FFFFFF" : "var(--text)",
                  border: isMine ? "none" : "1px solid var(--border, #E6E5EE)",
                  borderRadius: 14,
                  fontSize: 13,
                  lineHeight: 1.4,
                }}
              >
                {m.body}
              </div>
              {m.createdAt && (
                <div style={{ fontSize: 10, color: "var(--text-soft)" }}>
                  {formatRelativeTime(m.createdAt)}
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

function NewThreadModal({
  workspaceId,
  members,
  onClose,
  onCreated,
}: {
  workspaceId: string;
  members: TeamMember[];
  onClose: () => void;
  onCreated: (thread: CrewChatThread) => void;
}) {
  const [name, setName] = useState("");
  const [kind, setKind] = useState<CrewChatThreadKind>("general");
  const [selectedMemberIds, setSelectedMemberIds] = useState<Set<string>>(new Set());
  const [isCreating, setIsCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const activeMembers = members.filter((m) => m.status === "active");

  function toggleMember(id: string) {
    setSelectedMemberIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  async function create() {
    setIsCreating(true);
    setError(null);
    try {
      const trimmed = name.trim();
      const result = await postCrewChatAction<CreateThreadResponse>("create_thread", {
        workspaceId,
        name: trimmed || null,
        kind,
        memberIds: Array.from(selectedMemberIds),
      });
      onCreated(result.thread);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Couldn't create thread");
    } finally {
      setIsCreating(false);
    }
  }

  return (
    <div
      onClick={onClose}
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(20, 18, 50, 0.45)",
        zIndex: 100,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 24,
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: "var(--surface, #FFFFFF)",
          padding: 24,
          borderRadius: 16,
          width: "100%",
          maxWidth: 480,
          maxHeight: "85vh",
          display: "flex",
          flexDirection: "column",
          gap: 16,
        }}
      >
        <div>
          <div className="ops-section-label">New thread</div>
          <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600 }}>
            Start a workspace conversation
          </div>
        </div>

        <div>
          <label style={labelStyle}>Type</label>
          <div style={{ display: "flex", gap: 8 }}>
            {(["general", "tech_pair", "route_day"] as CrewChatThreadKind[]).map((k) => (
              <button
                key={k}
                onClick={() => setKind(k)}
                style={kindChipStyle(kind === k)}
              >
                {kindLabel(k)}
              </button>
            ))}
          </div>
        </div>

        <div>
          <label style={labelStyle}>Title (optional)</label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g. Tuesday route"
            style={inputStyle}
          />
        </div>

        <div style={{ flex: 1, overflowY: "auto", maxHeight: 220 }}>
          <label style={labelStyle}>Participants (optional)</label>
          {activeMembers.length === 0 ? (
            <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
              No active workspace members yet.
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
              {activeMembers.map((m) => (
                <button
                  key={m.id}
                  onClick={() => toggleMember(m.id)}
                  style={memberRowStyle(selectedMemberIds.has(m.id))}
                >
                  <Avatar initials={initialsFor(m.fullName || m.email)} size={28} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>
                      {m.fullName || m.email}
                    </div>
                    <div style={{ fontSize: 11, color: "var(--text-muted)" }}>
                      {m.title || m.role}
                    </div>
                  </div>
                  {selectedMemberIds.has(m.id) ? (
                    <Icon name="check" size={16} color="var(--salmon)" stroke={2.2} />
                  ) : null}
                </button>
              ))}
            </div>
          )}
        </div>

        {error && (
          <div style={{ color: "var(--critical, #B91C1C)", fontSize: 12 }}>{error}</div>
        )}

        <div style={{ display: "flex", justifyContent: "flex-end", gap: 8 }}>
          <button
            onClick={onClose}
            style={{
              padding: "8px 14px",
              border: "1px solid var(--border, #E6E5EE)",
              background: "transparent",
              borderRadius: 12,
              fontSize: 13,
              cursor: "pointer",
            }}
          >
            Cancel
          </button>
          <button
            className="ops-button ops-button--salmon"
            disabled={isCreating}
            onClick={() => void create()}
            style={{ opacity: isCreating ? 0.6 : 1 }}
          >
            {isCreating ? "Creating…" : "Create"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Helpers ────────────────────────────────────────────────────

function displayNameForThread(thread: CrewChatThread): string {
  if (thread.name && thread.name.trim().length > 0) return thread.name.trim();
  switch (thread.kind) {
    case "route_day":
      return "Route day";
    case "tech_pair":
      return "Direct chat";
    default:
      return "Crew chat";
  }
}

function iconNameForKind(kind: CrewChatThreadKind): string {
  switch (kind) {
    case "route_day":
      return "calendar";
    case "tech_pair":
      return "user";
    default:
      return "message";
  }
}

function kindLabel(kind: CrewChatThreadKind): string {
  switch (kind) {
    case "route_day":
      return "Route day";
    case "tech_pair":
      return "Direct";
    default:
      return "General";
  }
}

function threadRowStyle(isSelected: boolean): React.CSSProperties {
  return {
    display: "flex",
    alignItems: "center",
    gap: 10,
    width: "100%",
    padding: "10px 14px",
    border: "none",
    background: isSelected ? "var(--salmon-50, #FDEDEA)" : "transparent",
    borderLeft: isSelected
      ? "3px solid var(--salmon)"
      : "3px solid transparent",
    cursor: "pointer",
    textAlign: "left",
  };
}

const labelStyle: React.CSSProperties = {
  display: "block",
  fontSize: 11,
  fontWeight: 600,
  textTransform: "uppercase",
  letterSpacing: "0.06em",
  color: "var(--text-muted)",
  marginBottom: 6,
};

const inputStyle: React.CSSProperties = {
  width: "100%",
  padding: "10px 12px",
  border: "1px solid var(--border, #E6E5EE)",
  background: "var(--pearl, #F8F9FA)",
  borderRadius: 12,
  fontSize: 13,
};

function kindChipStyle(isActive: boolean): React.CSSProperties {
  return {
    padding: "8px 12px",
    border: isActive ? "1px solid var(--salmon)" : "1px solid var(--border, #E6E5EE)",
    background: isActive ? "var(--salmon-50, #FDEDEA)" : "transparent",
    color: isActive ? "var(--salmon)" : "var(--text)",
    borderRadius: 10,
    fontSize: 12,
    fontWeight: isActive ? 600 : 500,
    cursor: "pointer",
  };
}

function memberRowStyle(isSelected: boolean): React.CSSProperties {
  return {
    display: "flex",
    alignItems: "center",
    gap: 10,
    padding: "8px 10px",
    border: "1px solid var(--border, #E6E5EE)",
    background: isSelected ? "var(--salmon-50, #FDEDEA)" : "transparent",
    borderRadius: 10,
    cursor: "pointer",
    width: "100%",
    textAlign: "left",
  };
}
