import { useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { MESSAGE_THREAD_DEMO } from "../lib/fixtures";

export default function MessagesScreen() {
  const [draft, setDraft] = useState(
    "Glad to hear Mara crushed it. Yes, easy add — I'll route the trim touch-up + the detector swap into next Tuesday's visit. Want me to add a quote line so it's all on one approval?"
  );

  return (
    <div className="ops-grid-messages">
      {/* Inbox */}
      <Card padding="default">
        <div style={{ display: "flex", gap: 6, marginBottom: 12 }}>
          {["All · 5", "Unread · 3", "Mine"].map((c, i) => (
            <button key={c} className="ops-button ops-button--ghost" style={{ fontSize: 11, padding: "4px 10px", background: i === 0 ? "var(--neutral-200)" : "#fff" }}>
              {c}
            </button>
          ))}
        </div>
        <div>
          {MESSAGE_THREAD_DEMO.inbox.map((t) => (
            <button
              key={t.id}
              style={{
                display: "flex",
                gap: 10,
                padding: "12px 10px",
                width: "100%",
                background: t.selected ? "var(--salmon-50)" : "none",
                border: "none",
                borderRadius: 10,
                borderLeft: t.selected ? "3px solid var(--salmon)" : "3px solid transparent",
                cursor: "pointer",
                textAlign: "left",
                alignItems: "flex-start",
              }}
            >
              <Avatar initials={initialsFor(t.from)} size={32} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 6 }}>
                  <div style={{ fontSize: 13, fontWeight: t.unread ? 700 : 500, color: "var(--text)" }}>{t.from}</div>
                  <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{t.timestamp}</div>
                </div>
                <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{t.home}</div>
                <div style={{ fontSize: 12, marginTop: 2, color: t.unread ? "var(--text)" : "var(--text-muted)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                  {t.preview}
                </div>
              </div>
              {t.unread > 0 && <Pill tone="salmon">{t.unread} new</Pill>}
            </button>
          ))}
        </div>
      </Card>

      {/* Thread pane */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "center", gap: 12, paddingBottom: 14, borderBottom: "1px solid var(--neutral-200)" }}>
          <Avatar initials="SW" color="#453A70" size={36} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 600 }}>Sarah Whitfield</div>
            <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>14 Beacon Hill · Brookline</div>
          </div>
          <Pill tone="success" withDot>Active customer</Pill>
          <button className="ops-button ops-button--ghost" style={{ fontSize: 12 }}>Open home →</button>
        </div>

        <div style={{ padding: "16px 0", display: "flex", flexDirection: "column", gap: 12 }}>
          {MESSAGE_THREAD_DEMO.thread.map((m) => {
            if (m.who === "system") {
              return (
                <div key={m.id} style={{ alignSelf: "center" }}>
                  <Pill tone="success">{m.body}</Pill>
                </div>
              );
            }
            const isUs = m.who === "us";
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
                <div style={{ marginTop: 6, fontSize: 10.5, color: isUs ? "rgba(255,255,255,0.7)" : "var(--text-soft)" }}>{m.timestamp}</div>
              </div>
            );
          })}
        </div>

        {/* Composer */}
        <div style={{ borderTop: "1px solid var(--neutral-200)", paddingTop: 14 }}>
          <div style={{ display: "flex", gap: 6, marginBottom: 10, flexWrap: "wrap" }}>
            <SuggestionChip icon="sparkles">Suggest reply</SuggestionChip>
            <SuggestionChip>Confirm window</SuggestionChip>
            <SuggestionChip>Add to scope</SuggestionChip>
            <SuggestionChip>We're on the way</SuggestionChip>
          </div>
          <Card padding="tight">
            <textarea
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
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
              <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>Sending as <strong>Burke Handymen</strong></div>
              <button className="ops-button ops-button--salmon" style={{ marginLeft: "auto" }}>
                Send update <Icon name="send" size={13} stroke={1.9} />
              </button>
            </div>
          </Card>
        </div>
      </Card>

      {/* Right rail */}
      <Card padding="default">
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-soft)" }}>Selected client</div>
        <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600 }}>14 Beacon Hill</div>
        <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 14 }}>Sarah Whitfield · Brookline</div>

        <div style={{ background: "var(--salmon-50)", border: "1px solid var(--salmon-pale)", borderRadius: 12, padding: 12, marginBottom: 14 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>Spring punch-list bundle</div>
          <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginBottom: 6 }}>Mara on site Tuesday 8:30 – 9:30</div>
          <Pill tone="success" withDot>Approved</Pill>
        </div>

        <div className="ops-section-label" style={{ marginBottom: 8 }}>Recent visits</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 0, marginBottom: 14 }}>
          <div className="ops-row" style={{ padding: "8px 0" }}>
            <div style={{ flex: 1, fontSize: 12.5 }}>Hang gallery wall</div>
            <div style={{ fontSize: 11, color: "var(--text-soft)" }}>Apr 12</div>
          </div>
          <div className="ops-row" style={{ padding: "8px 0" }}>
            <div style={{ flex: 1, fontSize: 12.5 }}>Replace shower diverter</div>
            <div style={{ fontSize: 11, color: "var(--text-soft)" }}>Mar 28</div>
          </div>
        </div>

        <div style={{ background: "var(--indigo)", color: "#fff", borderRadius: 12, padding: 14 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--salmon-light)", marginBottom: 6 }}>
            Alfred suggests
          </div>
          <div style={{ fontFamily: "var(--serif)", fontSize: 14.5, lineHeight: 1.4, color: "#fff" }}>
            {MESSAGE_THREAD_DEMO.alfredSuggestion}
          </div>
        </div>
      </Card>
    </div>
  );
}

function SuggestionChip({ icon, children }: { icon?: string; children: React.ReactNode }) {
  return (
    <button
      style={{
        background: "var(--indigo-50)",
        color: "var(--indigo)",
        border: "1px solid var(--indigo-100)",
        borderRadius: 9,
        padding: "5px 10px",
        fontSize: 11.5,
        fontWeight: 600,
        cursor: "pointer",
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
      }}
    >
      {icon && <Icon name={icon} size={12} stroke={1.9} />}
      {children}
    </button>
  );
}
