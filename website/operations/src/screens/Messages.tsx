import { useMemo, useRef, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { ProposeVisitSheet } from "../components/ProposeVisitSheet";
import { useWorkspace } from "../lib/workspace-context";
import {
  formatCurrency,
  formatRelativeTime,
  postProviderAction,
  resizeImageForMessageUpload,
} from "../lib/api";

// Wave T: quick-reply chips above the composer. Tom's audience
// (homeowners) loves the iMessage-style suggestions. Click fills the
// textarea so the user can review and edit before send. No auto-send.
const SUGGESTION_CHIPS: string[] = [
  "On my way",
  "Running 15 min late",
  "Be there in 10",
  "Wrapping up",
  "All done. Thanks.",
];

interface AttachmentRef {
  path: string;
  contentType: string;
  signedUrl: string;
}

interface VisitSlot {
  start: string;
  end: string | null;
  note: string | null;
}

export default function MessagesScreen() {
  const { dashboard, refresh } = useWorkspace();
  const [filter, setFilter] = useState<"all" | "unread">("all");
  const [selectedRequestId, setSelectedRequestId] = useState<string | null>(null);
  const [draft, setDraft] = useState("");
  const [pendingAttachments, setPendingAttachments] = useState<AttachmentRef[]>([]);
  const [sending, setSending] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [showVisitSheet, setShowVisitSheet] = useState(false);
  const [lightboxUrl, setLightboxUrl] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

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

  // ─── Send handlers ─────────────────────────────────────────

  async function handleSend() {
    if (!selected || !dashboard) return;
    if (!draft.trim() && pendingAttachments.length === 0) return;
    setSending(true);
    try {
      // If there are pending attachments but no body, stamp a default
      // body so the homeowner sees something readable in the inbox
      // preview row even before the photo loads.
      const messageBody = draft.trim() ||
        (pendingAttachments.length === 1 ? "Sent a photo." : `Sent ${pendingAttachments.length} photos.`);
      const metadata: Record<string, unknown> = {};
      if (pendingAttachments.length > 0) {
        metadata.attachments = pendingAttachments.map((a) => ({
          path: a.path,
          contentType: a.contentType,
          signedUrl: a.signedUrl,
        }));
      }
      await postProviderAction("send_message", {
        workspaceId: dashboard.workspace.id,
        requestId: selected.requestId,
        body: messageBody,
        ...(Object.keys(metadata).length > 0 ? { metadata } : {}),
      });
      setDraft("");
      setPendingAttachments([]);
      await refresh();
    } catch (e) {
      console.error("[Messages] send failed", e);
      alert(e instanceof Error ? e.message : "Couldn't send. Try again.");
    } finally {
      setSending(false);
    }
  }

  // ─── Photo upload (Matrix 10.5) ────────────────────────────

  async function handlePhotoSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? []);
    e.target.value = ""; // allow re-selecting the same file
    if (files.length === 0 || !selected || !dashboard) return;

    setUploading(true);
    try {
      const uploadedAttachments: AttachmentRef[] = [];
      for (const file of files) {
        if (file.size > 10 * 1024 * 1024) {
          alert(`${file.name} is over 10MB. Pick a smaller image.`);
          continue;
        }
        const { dataBase64, contentType } = await resizeImageForMessageUpload(file);
        const result = await postProviderAction<{
          path: string;
          contentType: string;
          signedUrl: string;
        }>("upload_message_attachment", {
          workspaceId: dashboard.workspace.id,
          requestId: selected.requestId,
          dataBase64,
          contentType,
        });
        uploadedAttachments.push({
          path: result.path,
          contentType: result.contentType,
          signedUrl: result.signedUrl,
        });
      }
      setPendingAttachments((prev) => [...prev, ...uploadedAttachments]);
    } catch (err) {
      console.error("[Messages] photo upload failed", err);
      alert(err instanceof Error ? err.message : "Photo upload failed.");
    } finally {
      setUploading(false);
    }
  }

  function removePendingAttachment(idx: number) {
    setPendingAttachments((prev) => prev.filter((_, i) => i !== idx));
  }

  // ─── +Quote handler (Matrix 10.6) ──────────────────────────

  function openNewQuote() {
    if (!selected) return;
    const detail = {
      propertyId: selected.propertyId,
      requestId: selected.requestId,
      title: selected.propertyName
        ? `Quote for ${selected.propertyName}`
        : "Quote",
    };
    window.dispatchEvent(new CustomEvent("ops:open-new-quote", { detail }));
  }

  // ─── +Visit handler (Matrix 10.7) ──────────────────────────

  function openVisitSheet() {
    if (!selected) return;
    setShowVisitSheet(true);
  }

  // ─── Suggestion chip handler (Matrix 10.13) ────────────────

  function applyChip(text: string) {
    setDraft((prev) => (prev.trim() ? `${prev.trim()} ${text}` : text));
  }

  // ─── Render ────────────────────────────────────────────────

  return (
    <div className="ops-grid-messages">
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple
        onChange={handlePhotoSelect}
        style={{ display: "none" }}
      />

      {/* Inbox */}
      <Card padding="default">
        <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
          {(["all", "unread"] as const).map((c) => (
            <button
              key={c}
              className="ops-button ops-button--ghost"
              style={{ fontSize: 11, padding: "8px 12px", background: filter === c ? "var(--neutral-200)" : "#fff", minHeight: 32 }}
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
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap" }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{selected.propertyName || selected.title}</div>
                  {/* Section 19c — surface emergency + Chez routing on the
                      thread header so the dispatcher sees both at a glance. */}
                  {selectedVisit?.urgency === "urgent" && <Pill tone="critical">Emergency</Pill>}
                  {selectedVisit?.source === "haven" && <Pill tone="indigo">Routed by Chez</Pill>}
                </div>
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
                // Server returns messages newest-first; chat UX expects oldest-first
                // (newest at bottom near composer), so reverse before rendering.
                [...selected.recentMessages].reverse().map((m) => {
                  const role = m.senderRole;
                  const isUs = role === "vendor";
                  // Chez admin messages (haven / chez sender_role) render as a distinct
                  // 3rd identity, center-aligned, never as "us" or "homeowner". Brand
                  // voice rule: always shown as "Chez", never an operator name.
                  const isChez = role === "haven" || role === "chez";
                  const meta = (m.metadata ?? {}) as Record<string, unknown>;
                  const kind = typeof meta.kind === "string" ? meta.kind : null;
                  const attachments = Array.isArray(meta.attachments)
                    ? (meta.attachments as Array<Record<string, unknown>>)
                    : [];
                  const slots = Array.isArray(meta.slots)
                    ? (meta.slots as Array<Record<string, unknown>>)
                    : [];

                  if (isChez) {
                    return (
                      <div
                        key={m.id}
                        style={{
                          alignSelf: "center",
                          maxWidth: "80%",
                          background: "var(--salmon-50)",
                          color: "var(--text)",
                          padding: "10px 14px",
                          borderRadius: 12,
                          border: "1px solid var(--salmon-pale)",
                          fontSize: 13,
                          lineHeight: 1.5,
                          textAlign: "center",
                        }}
                      >
                        <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--salmon)", marginBottom: 4 }}>Chez</div>
                        {m.body}
                        <div style={{ marginTop: 6, fontSize: 10.5, color: "var(--text-soft)" }}>{formatRelativeTime(m.createdAt)}</div>
                      </div>
                    );
                  }

                  // Quote-sent card (mirrored by mirrorQuoteMessageToRequestThread).
                  if (kind === "quote_sent") {
                    const quoteTitle = typeof meta.title === "string" ? meta.title : "Quote";
                    const quoteTotal = typeof meta.total === "number" ? meta.total : null;
                    const quoteShareUrl = typeof meta.shareUrl === "string" ? meta.shareUrl : null;
                    return (
                      <div
                        key={m.id}
                        style={{
                          alignSelf: isUs ? "flex-end" : "flex-start",
                          maxWidth: "85%",
                          background: isUs ? "var(--indigo)" : "#fff",
                          color: isUs ? "#fff" : "var(--text)",
                          padding: "14px 16px",
                          borderRadius: 14,
                          borderTopLeftRadius: isUs ? 14 : 4,
                          borderTopRightRadius: isUs ? 4 : 14,
                          border: isUs ? "none" : "1px solid var(--neutral-200)",
                          fontSize: 13.5,
                          lineHeight: 1.55,
                        }}
                      >
                        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: isUs ? "rgba(255,255,255,0.85)" : "var(--text-soft)", marginBottom: 6 }}>
                          <Icon name="quote" size={11} stroke={2} /> Quote sent
                        </div>
                        <div style={{ fontWeight: 600, marginBottom: 4 }}>{quoteTitle}</div>
                        {quoteTotal !== null && (
                          <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, marginBottom: 8 }}>
                            {formatCurrency(quoteTotal)}
                          </div>
                        )}
                        {m.body && m.body !== quoteTitle && (
                          <div style={{ fontSize: 13, marginBottom: 8 }}>{m.body}</div>
                        )}
                        {quoteShareUrl && (
                          <a
                            href={quoteShareUrl}
                            target="_blank"
                            rel="noreferrer"
                            style={{
                              fontSize: 12.5,
                              fontWeight: 600,
                              color: isUs ? "#fff" : "var(--salmon)",
                              textDecoration: "underline",
                            }}
                          >
                            View quote details
                          </a>
                        )}
                        <div style={{ marginTop: 8, fontSize: 10.5, color: isUs ? "rgba(255,255,255,0.7)" : "var(--text-soft)" }}>{formatRelativeTime(m.createdAt)}</div>
                      </div>
                    );
                  }

                  // Visit-proposed slot card.
                  if (kind === "visit_proposed" && slots.length > 0) {
                    return (
                      <div
                        key={m.id}
                        style={{
                          alignSelf: isUs ? "flex-end" : "flex-start",
                          maxWidth: "85%",
                          background: "#fff",
                          color: "var(--text)",
                          padding: "14px 16px",
                          borderRadius: 14,
                          borderTopLeftRadius: isUs ? 14 : 4,
                          borderTopRightRadius: isUs ? 4 : 14,
                          border: "1px solid var(--neutral-200)",
                          fontSize: 13.5,
                          lineHeight: 1.55,
                        }}
                      >
                        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)", marginBottom: 8 }}>
                          <Icon name="calendar" size={11} stroke={2} /> Visit times suggested
                        </div>
                        {m.body && (
                          <div style={{ fontSize: 13, marginBottom: 10, color: "var(--text-muted)" }}>{m.body}</div>
                        )}
                        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
                          {(slots as Array<Record<string, unknown>>).map((slot, idx) => {
                            const start = typeof slot.start === "string" ? slot.start : null;
                            const end = typeof slot.end === "string" ? slot.end : null;
                            const note = typeof slot.note === "string" ? slot.note : null;
                            return (
                              <div
                                key={idx}
                                style={{
                                  border: "1px solid var(--neutral-200)",
                                  borderRadius: 10,
                                  padding: "10px 12px",
                                  background: "#FAFBFC",
                                  fontSize: 13,
                                }}
                              >
                                <div style={{ fontWeight: 600 }}>
                                  Option {idx + 1}: {start ? new Date(start).toLocaleString(undefined, {
                                    weekday: "short",
                                    month: "short",
                                    day: "numeric",
                                    hour: "numeric",
                                    minute: "2-digit",
                                  }) : "(no time)"}
                                </div>
                                {end && (
                                  <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>
                                    Until {new Date(end).toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" })}
                                  </div>
                                )}
                                {note && <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginTop: 2 }}>{note}</div>}
                              </div>
                            );
                          })}
                        </div>
                        <div style={{ fontSize: 10.5, color: "var(--text-soft)", marginTop: 10 }}>
                          Homeowner picks one in the Haven app. {formatRelativeTime(m.createdAt)}
                        </div>
                      </div>
                    );
                  }

                  // Default text bubble, with optional inline thumbnails when
                  // the message carries metadata.attachments.
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
                      {attachments.length > 0 && (
                        <div style={{
                          display: "grid",
                          gap: 6,
                          gridTemplateColumns: attachments.length === 1 ? "1fr" : "repeat(2, 1fr)",
                          marginBottom: m.body ? 8 : 0,
                        }}>
                          {attachments.map((att, idx) => {
                            const url = typeof att.signedUrl === "string"
                              ? att.signedUrl
                              : typeof att.url === "string" ? att.url : null;
                            if (!url) return null;
                            return (
                              <button
                                key={idx}
                                type="button"
                                onClick={() => setLightboxUrl(url)}
                                style={{
                                  border: "none",
                                  padding: 0,
                                  cursor: "pointer",
                                  background: "transparent",
                                  borderRadius: 10,
                                  overflow: "hidden",
                                }}
                              >
                                <img
                                  src={url}
                                  alt="Photo attachment"
                                  style={{
                                    display: "block",
                                    width: "100%",
                                    maxHeight: 200,
                                    objectFit: "cover",
                                    borderRadius: 10,
                                    background: "rgba(255,255,255,0.05)",
                                  }}
                                />
                              </button>
                            );
                          })}
                        </div>
                      )}
                      {m.body}
                      <div style={{ marginTop: 6, fontSize: 10.5, color: isUs ? "rgba(255,255,255,0.7)" : "var(--text-soft)" }}>{formatRelativeTime(m.createdAt)}</div>
                    </div>
                  );
                })
              )}
            </div>

            <div style={{ borderTop: "1px solid var(--neutral-200)", paddingTop: 14 }}>
              {/* Suggestion chips above the composer */}
              <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 }}>
                {SUGGESTION_CHIPS.map((chip) => (
                  <button
                    key={chip}
                    onClick={() => applyChip(chip)}
                    className="ops-button ops-button--ghost"
                    style={{
                      fontSize: 11.5,
                      padding: "6px 10px",
                      minHeight: 28,
                      borderRadius: 14,
                      background: "var(--neutral-100, #F4F5F7)",
                      border: "1px solid var(--neutral-200)",
                    }}
                  >
                    {chip}
                  </button>
                ))}
              </div>

              <Card padding="tight">
                <textarea
                  value={draft}
                  onChange={(e) => setDraft(e.target.value)}
                  placeholder={selectedVisit?.source === "haven" ? "Reply to Chez. They'll relay to the homeowner." : "Type your reply."}
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

                {/* Pending photo attachments preview */}
                {pendingAttachments.length > 0 && (
                  <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginTop: 6 }}>
                    {pendingAttachments.map((att, idx) => (
                      <div
                        key={att.path}
                        style={{
                          position: "relative",
                          width: 64,
                          height: 64,
                          borderRadius: 8,
                          overflow: "hidden",
                          border: "1px solid var(--neutral-200)",
                        }}
                      >
                        <img
                          src={att.signedUrl}
                          alt=""
                          style={{ width: "100%", height: "100%", objectFit: "cover" }}
                        />
                        <button
                          type="button"
                          onClick={() => removePendingAttachment(idx)}
                          aria-label="Remove photo"
                          style={{
                            position: "absolute",
                            top: 2,
                            right: 2,
                            background: "rgba(20,16,50,0.75)",
                            color: "#fff",
                            border: "none",
                            borderRadius: 999,
                            width: 18,
                            height: 18,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            cursor: "pointer",
                            fontSize: 12,
                          }}
                        >
                          ×
                        </button>
                      </div>
                    ))}
                  </div>
                )}

                <div style={{ display: "flex", alignItems: "center", marginTop: 10, gap: 8, flexWrap: "wrap" }}>
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    className="ops-button ops-button--ghost"
                    disabled={uploading}
                    aria-label="Attach photo"
                    style={{ minHeight: 32, padding: "6px 10px", fontSize: 12 }}
                  >
                    <Icon name="paperclip" size={13} stroke={1.9} />
                    {uploading ? " Uploading..." : ""}
                  </button>
                  <button
                    type="button"
                    onClick={openNewQuote}
                    className="ops-button ops-button--ghost"
                    style={{ minHeight: 32, padding: "6px 10px", fontSize: 12 }}
                  >
                    <Icon name="plus" size={11} stroke={2} /> Quote
                  </button>
                  <button
                    type="button"
                    onClick={openVisitSheet}
                    className="ops-button ops-button--ghost"
                    style={{ minHeight: 32, padding: "6px 10px", fontSize: 12 }}
                  >
                    <Icon name="plus" size={11} stroke={2} /> Visit
                  </button>
                  <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginLeft: "auto" }}>
                    Sending as <strong>{dashboard.workspace.companyName}</strong>
                  </div>
                  <button
                    className="ops-button ops-button--salmon"
                    disabled={sending || (!draft.trim() && pendingAttachments.length === 0)}
                    onClick={handleSend}
                  >
                    {sending ? "Sending..." : "Send update"} <Icon name="send" size={13} stroke={1.9} />
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

      {/* +Visit modal */}
      {selected && (
        <ProposeVisitSheet
          open={showVisitSheet}
          workspaceId={dashboard.workspace.id}
          requestId={selected.requestId}
          propertyName={selected.propertyName || ""}
          onClose={() => setShowVisitSheet(false)}
          onSent={() => refresh()}
        />
      )}

      {/* Lightbox */}
      {lightboxUrl && (
        <div
          onClick={() => setLightboxUrl(null)}
          style={{
            position: "fixed",
            inset: 0,
            background: "rgba(20,16,50,0.85)",
            zIndex: 2000,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: 30,
            cursor: "zoom-out",
          }}
        >
          <img
            src={lightboxUrl}
            alt="Photo"
            style={{ maxWidth: "100%", maxHeight: "100%", borderRadius: 8, boxShadow: "0 25px 60px rgba(0,0,0,0.6)" }}
          />
        </div>
      )}
    </div>
  );
}

// Avoid unused-import for VisitSlot helper type. Wave T currently uses it
// in ProposeVisitSheet only; the type is exported here as a convenience for
// future tooling that needs the same shape (e.g. test fixtures).
export type { VisitSlot };
