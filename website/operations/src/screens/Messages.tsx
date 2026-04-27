import { useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatRelativeTime, postProviderAction } from "../lib/api";

export default function MessagesScreen() {
  const { dashboard, refresh } = useWorkspace();
  const [filter, setFilter] = useState<"all" | "unread">("all");
  const [selectedRequestId, setSelectedRequestId] = useState<string | null>(null);
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);

  const threads = useMemo(() => dashboard?.messages ?? [], [dashboard]);

  const filteredThreads = useMemo(() => {
    return threads.filter((t) => {
      if (filter === "unread") return t.senderRole === "homeowner";
      return true;
    });
  }, [threads, filter]);

  const selected = useMemo(() => {
    if (!filteredThreads.length) return null;
    if (selectedRequestId) {
      return threads.find((t) => t.requestId === selectedRequestId) ?? filteredThreads[0];
    }
    return filteredThreads[0];
  }, [filteredThreads, selectedRequestId, threads]);

  const selectedVisit = useMemo(() => {
    if (!dashboard || !selected) return null;
    return dashboard.visits.find((v) => v.requestId === selected.requestId) ?? null;
  }, [dashboard, selected]);

  if (!dashboard) return null;

  if (threads.length === 0) {
    return (
      <EmptyState
        icon="message"
        title="No homeowner messages yet"
        body="Threads kick off when a homeowner books a visit or replies to a quote. They'll show up here organized by home."
      />
    );
  }

  async function handleSend() {
    if (!selected || !draft.trim() || !dashboard) return;
    setSending(true);
    try {
      await postProviderAction("send_message", {
        workspaceId: dashboard.workspace.id,
        requestId: selected.requestId,
        body: draft,
      });
      setDraft("");
      await refresh();
    } catch (e) {
      console.error("[Messages] send failed", e);
      alert(e instanceof Error ? e.message : "Couldn't send. Try again.");
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="ops-grid-messages">
      {/* Inbox */}
      <Card padding="default">
        <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
          {(["all", "unread"] as const).map((c) => (
            <button
              key={c}
              className="ops-button ops-button--ghost"
              style={{ fontSize: 11, padding: "4px 10px", background: filter === c ? "var(--neutral-200)" : "#fff" }}
              onClick={() => setFilter(c)}
            >
              {c === "all" ? `All · ${threads.length}` : `Awaiting · ${threads.filter((t) => t.senderRole === "homeowner").length}`}
            </button>
          ))}
        </div>
        <div>
          {filteredThreads.map((t) => (
            <button
              key={t.requestId}
              onClick={() => setSelectedRequestId(t.requestId)}
              style={{
                display: "flex",
                gap: 10,
                padding: "12px 10px",
                width: "100%",
                background: selected?.requestId === t.requestId ? "var(--salmon-50)" : "none",
                border: "none",
                borderRadius: 10,
                borderLeft: selected?.requestId === t.requestId ? "3px solid var(--salmon)" : "3px solid transparent",
                cursor: "pointer",
                textAlign: "left",
                alignItems: "flex-start",
              }}
            >
              <Avatar initials={initialsFor(t.propertyName || t.title)} size={32} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 6 }}>
                  <div style={{ fontSize: 13, fontWeight: t.senderRole === "homeowner" ? 700 : 500, color: "var(--text)" }}>
                    {t.propertyName || t.title}
                  </div>
                  <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{formatRelativeTime(t.latestMessageAt)}</div>
                </div>
                <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{t.title}</div>
                <div style={{ fontSize: 12, marginTop: 2, color: t.senderRole === "homeowner" ? "var(--text)" : "var(--text-muted)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                  {t.latestMessage}
                </div>
              </div>
              {t.senderRole === "homeowner" && <Pill tone="salmon">Reply</Pill>}
            </button>
          ))}
        </div>
      </Card>

      {/* Thread pane */}
      <Card padding="default">
        {selected ? (
          <>
            <div style={{ display: "flex", alignItems: "center", gap: 12, paddingBottom: 14, borderBottom: "1px solid var(--neutral-200)" }}>
              <Avatar initials={initialsFor(selected.propertyName)} size={36} />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{selected.propertyName || selected.title}</div>
                <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>{selected.title}{selected.propertyAddress ? ` · ${selected.propertyAddress}` : ""}</div>
              </div>
              {selectedVisit && (
                <Pill tone="indigo">{selectedVisit.statusLabel}</Pill>
              )}
            </div>

            <div style={{ padding: "16px 0", display: "flex", flexDirection: "column", gap: 12 }}>
              {(selected.recentMessages ?? []).length === 0 ? (
                <div style={{ padding: 16, fontSize: 13, color: "var(--text-muted)", textAlign: "center" }}>
                  No replies yet on this thread.
                </div>
              ) : (
                selected.recentMessages.map((m) => {
                  const isUs = m.senderRole === "vendor" || m.senderRole === "haven";
                  return (
                    <div
                      key={m.id}
                      style={{
                        alignSelf: isUs ? "flex-end" : "flex-start",
                        maxWidth: "70%",
                        background: isUs ? "var(--indigo)" : "#fff",
                        color: isUs ? "#fff" : "var(--text)",
                        padding: "12px 14px",
                        borderRadius: 14,
                        borderTopLeftRadius: isUs ? 14 : 4,
                        borderTopRightRadius: isUs ? 4 : 14,
                        border: isUs ? "none" : "1px solid var(--neutral-200)",
                        fontSize: 13.5,
                        lineHeight: 1.55,
                      }}
                    >
                      {m.body}
                      <div style={{ marginTop: 6, fontSize: 10.5, color: isUs ? "rgba(255,255,255,0.7)" : "var(--text-soft)" }}>{formatRelativeTime(m.createdAt)}</div>
                    </div>
                  );
                })
              )}
            </div>

            <div style={{ borderTop: "1px solid var(--neutral-200)", paddingTop: 14 }}>
              <Card padding="tight">
                <textarea
                  value={draft}
                  onChange={(e) => setDraft(e.target.value)}
                  placeholder="Type your reply…"
                  style={{
                    width: "100%",
                    border: "none",
                    outline: "none",
                    resize: "vertical",
                    fontFamily: "var(--sans)",
                    fontSize: 13.5,
                    color: "var(--text)",
                    minHeight: 80,
                    background: "transparent",
                  }}
                />
                <div style={{ display: "flex", alignItems: "center", marginTop: 10 }}>
                  <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
                    Sending as <strong>{dashboard.workspace.companyName}</strong>
                  </div>
                  <button
                    className="ops-button ops-button--salmon"
                    style={{ marginLeft: "auto" }}
                    disabled={sending || !draft.trim()}
                    onClick={handleSend}
                  >
                    {sending ? "Sending…" : "Send update"} <Icon name="send" size={13} stroke={1.9} />
                  </button>
                </div>
              </Card>
            </div>
          </>
        ) : (
          <EmptyState
            icon="message"
            title="No thread selected"
            body="Pick a conversation from the inbox on the left."
          />
        )}
      </Card>

      {/* Right rail */}
      <Card padding="default">
        {selectedVisit ? (
          <>
            <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-soft)" }}>Selected request</div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600 }}>{selectedVisit.property?.name || selectedVisit.title}</div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 14 }}>{selectedVisit.property?.address || ""}</div>

            <div style={{ background: "var(--salmon-50)", border: "1px solid var(--salmon-pale)", borderRadius: 12, padding: 12, marginBottom: 14 }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{selectedVisit.title}</div>
              <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginBottom: 6 }}>
                {selectedVisit.preferredTiming || formatRelativeTime(selectedVisit.updatedAt)}
              </div>
              <Pill tone={selectedVisit.status === "completed" ? "success" : "indigo"} withDot>
                {selectedVisit.statusLabel}
              </Pill>
            </div>

            {selectedVisit.quote && (
              <div style={{ marginBottom: 14 }}>
                <div className="ops-section-label" style={{ marginBottom: 6 }}>Quote</div>
                <div style={{ fontSize: 13, color: "var(--text)" }}>
                  {selectedVisit.quote.statusLabel} · ${selectedVisit.quote.total.toLocaleString()}
                </div>
              </div>
            )}
          </>
        ) : (
          <div style={{ fontSize: 13, color: "var(--text-muted)" }}>
            No request selected.
          </div>
        )}
      </Card>
    </div>
  );
}
