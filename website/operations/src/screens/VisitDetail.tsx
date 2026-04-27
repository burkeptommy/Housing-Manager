import { useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, formatRelativeTime, formatTime12h, postProviderAction } from "../lib/api";
import type { RequestStatus } from "../lib/types";

export default function VisitDetailScreen() {
  const { requestId } = useParams<{ requestId: string }>();
  const { dashboard, refresh } = useWorkspace();
  const navigate = useNavigate();
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const [busy, setBusy] = useState(false);

  const visit = useMemo(() => {
    if (!dashboard || !requestId) return null;
    return dashboard.visits.find((v) => v.requestId === requestId) ?? null;
  }, [dashboard, requestId]);

  const home = useMemo(() => {
    if (!dashboard || !visit?.property) return null;
    return dashboard.homes.find((h) => h.propertyId === visit.property!.id) ?? null;
  }, [dashboard, visit]);

  const thread = useMemo(() => {
    if (!dashboard || !requestId) return null;
    return dashboard.messages.find((m) => m.requestId === requestId) ?? null;
  }, [dashboard, requestId]);

  const upsells = useMemo(() => {
    if (!home || !home.systems) return [];
    return suggestUpsells(home.systems, dashboard?.visits ?? []);
  }, [home, dashboard]);

  const aiTimeEstimate = useMemo(() => estimateVisitTime(visit), [visit]);

  if (!dashboard) return null;
  if (!visit) {
    return (
      <Card padding="default">
        <div style={{ padding: 32, textAlign: "center" }}>
          <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600, marginBottom: 8 }}>
            Visit not found
          </div>
          <div style={{ fontSize: 13, color: "var(--text-muted)", marginBottom: 16 }}>
            It may have been cancelled or deleted.
          </div>
          <button className="ops-button ops-button--ghost" onClick={() => navigate("/visits")}>
            ← Back to Visits
          </button>
        </div>
      </Card>
    );
  }

  async function handleSend() {
    if (!draft.trim() || !visit || !dashboard) return;
    setSending(true);
    try {
      await postProviderAction("send_message", {
        workspaceId: dashboard.workspace.id,
        requestId: visit.requestId,
        body: draft,
      });
      setDraft("");
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't send.");
    } finally {
      setSending(false);
    }
  }

  async function handleAssignToMe() {
    if (!visit || !dashboard || !dashboard.currentUser.memberId) return;
    setBusy(true);
    try {
      await postProviderAction("assign_visit", {
        workspaceId: dashboard.workspace.id,
        requestId: visit.requestId,
        assignedMemberId: dashboard.currentUser.memberId,
        routeDate: visit.routeDate || new Date().toISOString().slice(0, 10),
        windowStartTime: "09:00",
        windowEndTime: "11:00",
      });
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't assign.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <div style={{ marginBottom: 16, display: "flex", gap: 8, alignItems: "center", fontSize: 13 }}>
        <Link to="/visits" style={{ color: "var(--text-soft)", textDecoration: "none" }}>← Visits</Link>
        <span style={{ color: "var(--text-soft)" }}>·</span>
        <span style={{ color: "var(--text-muted)" }}>{visit.requestId.slice(0, 8)}</span>
      </div>

      {/* Header card */}
      <Card padding="default" style={{ marginBottom: 16 }}>
        <div style={{ display: "flex", gap: 6, marginBottom: 8, alignItems: "center" }}>
          <Pill tone={requestStatusTone(visit.status)}>{visit.statusLabel}</Pill>
          {visit.assignment ? (
            <Pill tone="indigo">Assigned to {visit.assignment.memberName.split(" ")[0]}</Pill>
          ) : (
            <Pill tone="warning">Not assigned</Pill>
          )}
          <span style={{ marginLeft: "auto", fontSize: 11, color: "var(--text-soft)" }}>
            Updated {formatRelativeTime(visit.updatedAt)}
          </span>
        </div>
        <div style={{ fontFamily: "var(--serif)", fontSize: 26, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em", marginBottom: 6 }}>
          {visit.title}
        </div>
        {visit.property && (
          <Link to={`/homes/${visit.property.id}`} style={{ display: "inline-flex", alignItems: "center", gap: 6, fontSize: 13, color: "var(--indigo-500)", textDecoration: "none", marginBottom: 12 }}>
            <Icon name="home" size={14} stroke={1.9} />
            {visit.property.name}{visit.property.address ? ` · ${visit.property.address}` : ""}
          </Link>
        )}

        <div style={{ display: "flex", gap: 8, marginTop: 12, flexWrap: "wrap" }}>
          {!visit.assignment && (
            <button className="ops-button ops-button--salmon" disabled={busy} onClick={handleAssignToMe}>
              {busy ? "Assigning…" : "Assign to me"}
            </button>
          )}
          {visit.assignment && visit.fieldWorkspace && (
            <a className="ops-button ops-button--indigo" href={visit.fieldWorkspace.url} target="_blank" rel="noopener">
              Open in Chez Field →
            </a>
          )}
          <button className="ops-button ops-button--ghost">Propose new time</button>
          <button className="ops-button ops-button--ghost">Build a quote</button>
          <button className="ops-button ops-button--ghost" style={{ marginLeft: "auto" }}>Mark complete</button>
        </div>
      </Card>

      <div style={{ display: "grid", gridTemplateColumns: "1.4fr 1fr", gap: 24, alignItems: "start" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          {/* Tasks the homeowner asked for */}
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>What the homeowner is asking for</div>
            <div style={{ fontSize: 13.5, lineHeight: 1.55, color: "var(--text)", whiteSpace: "pre-wrap" }}>
              {visit.title}
            </div>
            {visit.preferredTiming && (
              <div style={{ marginTop: 10, padding: 10, background: "var(--indigo-50)", borderRadius: 8, fontSize: 12.5, color: "var(--text-muted)" }}>
                <strong style={{ color: "var(--indigo)" }}>Preferred timing:</strong> {visit.preferredTiming}
              </div>
            )}
          </Card>

          {/* AI time estimate */}
          <Card padding="default">
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 12 }}>
              <div className="ops-section-label" style={{ marginBottom: 0 }}>Time estimate</div>
              <Pill tone="indigo">AI-suggested</Pill>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12 }}>
              <Estimate label="Site time" value={`${aiTimeEstimate.siteMinutes} min`} />
              <Estimate label="Drive both ways" value={`${aiTimeEstimate.driveMinutes} min`} />
              <Estimate label="Total block" value={`${Math.round(aiTimeEstimate.totalMinutes / 60 * 10) / 10} hrs`} accent />
            </div>
            <div style={{ marginTop: 10, fontSize: 12, color: "var(--text-muted)", lineHeight: 1.5 }}>
              {aiTimeEstimate.reasoning}
            </div>
            {aiTimeEstimate.suggestSplit && (
              <div style={{ marginTop: 12, padding: 12, background: "var(--salmon-50)", border: "1px solid var(--salmon-pale)", borderRadius: 8, fontSize: 12.5, color: "var(--text)", lineHeight: 1.5 }}>
                <strong style={{ color: "var(--salmon-dark)" }}>Heads-up:</strong> This looks like more work than fits a single window. Consider splitting into 2 visits — one for diagnosis, one for the fix.
              </div>
            )}
          </Card>

          {/* Upsell suggestions */}
          {home && (
            <Card padding="default">
              <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 12 }}>
                <div className="ops-section-label" style={{ marginBottom: 0 }}>While you're there</div>
                <Pill tone="warning">Upsell</Pill>
              </div>
              {upsells.length === 0 ? (
                <div style={{ fontSize: 13, color: "var(--text-muted)" }}>
                  No upsells suggested for this home yet. Once we have system age + last-service data, we'll surface specific recommendations here.
                </div>
              ) : (
                <div style={{ display: "flex", flexDirection: "column" }}>
                  {upsells.map((u, i) => (
                    <div key={i} className="ops-row" style={{ padding: "10px 0" }}>
                      <div style={{ width: 32, height: 32, borderRadius: 8, background: "var(--salmon-pale)", color: "var(--salmon-dark)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
                        <Icon name="lightbulb" size={16} stroke={1.9} />
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{u.title}</div>
                        <div style={{ fontSize: 12, color: "var(--text-muted)" }}>{u.reason}</div>
                      </div>
                      {u.estimate && (
                        <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, color: "var(--indigo)", width: 70, textAlign: "right" }}>
                          {u.estimate}
                        </div>
                      )}
                      <button className="ops-button ops-button--ghost" style={{ fontSize: 11, padding: "4px 8px" }}>Add to quote</button>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          )}

          {/* Inline messaging */}
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>Conversation</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 12, maxHeight: 280, overflowY: "auto" }}>
              {(thread?.recentMessages ?? []).length === 0 ? (
                <div style={{ padding: 12, fontSize: 13, color: "var(--text-muted)" }}>
                  No messages yet. Send one below to kick things off.
                </div>
              ) : (
                thread!.recentMessages.slice().reverse().map((m) => {
                  const isUs = m.senderRole === "vendor" || m.senderRole === "haven";
                  return (
                    <div
                      key={m.id}
                      style={{
                        alignSelf: isUs ? "flex-end" : "flex-start",
                        maxWidth: "80%",
                        background: isUs ? "var(--indigo)" : "#fff",
                        color: isUs ? "#fff" : "var(--text)",
                        padding: "10px 12px",
                        borderRadius: 12,
                        border: isUs ? "none" : "1px solid var(--neutral-200)",
                        fontSize: 13,
                      }}
                    >
                      {m.body}
                      <div style={{ fontSize: 10.5, marginTop: 4, color: isUs ? "rgba(255,255,255,0.7)" : "var(--text-soft)" }}>
                        {formatRelativeTime(m.createdAt)}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
            <div style={{ marginTop: 12, padding: 10, border: "1px solid var(--neutral-200)", borderRadius: 10, background: "#fff" }}>
              <textarea
                value={draft}
                onChange={(e) => setDraft(e.target.value)}
                placeholder="Reply to the homeowner…"
                style={{ width: "100%", border: "none", outline: "none", resize: "vertical", fontFamily: "var(--sans)", fontSize: 13, color: "var(--text)", minHeight: 60, background: "transparent" }}
              />
              <div style={{ display: "flex", alignItems: "center", marginTop: 6 }}>
                <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
                  Sending as <strong>{dashboard.workspace.companyName}</strong>
                </div>
                <button
                  className="ops-button ops-button--salmon"
                  style={{ marginLeft: "auto" }}
                  disabled={sending || !draft.trim()}
                  onClick={handleSend}
                >
                  {sending ? "Sending…" : "Send"} <Icon name="send" size={13} stroke={1.9} />
                </button>
              </div>
            </div>
          </Card>
        </div>

        {/* Right rail */}
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>Schedule</div>
            <SidebarRow label="Date" value={visit.routeDate ? new Date(visit.routeDate).toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" }) : "Not booked"} />
            <SidebarRow label="Window" value={visit.assignment?.windowStartTime ? `${formatTime12h(visit.assignment.windowStartTime)} – ${formatTime12h(visit.assignment.windowEndTime)}` : "—"} />
            <SidebarRow label="Tech" value={visit.assignment?.memberName || "Unassigned"} />
            <SidebarRow label="Stop #" value={visit.assignment?.stopOrder ? String(visit.assignment.stopOrder) : "—"} />
          </Card>

          {visit.quote && (
            <Card padding="default">
              <div className="ops-section-label" style={{ marginBottom: 12 }}>Quote</div>
              <div style={{ fontFamily: "var(--serif)", fontSize: 24, fontWeight: 700, color: "var(--indigo)", marginBottom: 4 }}>
                {formatCurrency(visit.quote.total)}
              </div>
              <Pill tone={visit.quote.status === "approved" ? "success" : "indigo"}>{visit.quote.statusLabel}</Pill>
              {visit.quote.publicShareUrl && (
                <a href={visit.quote.publicShareUrl} target="_blank" rel="noopener" style={{ display: "block", marginTop: 12, fontSize: 12, color: "var(--indigo-500)" }}>
                  Open homeowner view →
                </a>
              )}
            </Card>
          )}

          {home && (
            <Card padding="default">
              <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 12 }}>
                <Avatar initials={initialsFor(home.name)} size={32} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{home.name}</div>
                  <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{home.address}</div>
                </div>
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 0, marginTop: 6 }}>
                <SidebarRow label="Systems" value={String(home.systemCount)} />
                <SidebarRow label="Open requests" value={String(home.openRequests)} />
                <SidebarRow label="Last visit" value={home.lastCompletedVisit ? formatRelativeTime(home.lastCompletedVisit) : "—"} />
              </div>
              <Link to={`/homes/${home.propertyId}`} className="ops-button ops-button--ghost" style={{ marginTop: 12, width: "100%", textAlign: "center", justifyContent: "center" }}>
                Open home profile →
              </Link>
            </Card>
          )}
        </div>
      </div>
    </>
  );
}

function SidebarRow({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", padding: "6px 0", borderBottom: "1px solid var(--neutral-200)" }}>
      <span style={{ fontSize: 11.5, color: "var(--text-soft)", letterSpacing: "0.04em", textTransform: "uppercase", fontWeight: 600 }}>{label}</span>
      <span style={{ fontSize: 13, color: "var(--text)" }}>{value}</span>
    </div>
  );
}

function Estimate({ label, value, accent = false }: { label: string; value: string; accent?: boolean }) {
  return (
    <div>
      <div style={{ fontSize: 10.5, color: "var(--text-soft)", letterSpacing: "0.08em", textTransform: "uppercase", fontWeight: 600 }}>{label}</div>
      <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 700, color: accent ? "var(--indigo)" : "var(--text)", letterSpacing: "-0.018em" }}>
        {value}
      </div>
    </div>
  );
}

// ─── AI heuristics (replace with Claude edge fn later) ───

function estimateVisitTime(visit: ReturnType<typeof useMemo<any>> extends infer T ? T : never): {
  siteMinutes: number;
  driveMinutes: number;
  totalMinutes: number;
  reasoning: string;
  suggestSplit: boolean;
} {
  // Title-based heuristic. Ships now; Claude-driven version comes next.
  const title = (visit?.title ?? "").toLowerCase();
  let siteMinutes = 60;
  let suggestSplit = false;
  let reasoning = "Standard handyman visit window.";
  if (title.includes("install") || title.includes("replace")) {
    siteMinutes = 120;
    reasoning = "Installs and replacements typically run 90–150 min on site.";
  } else if (title.includes("inspect") || title.includes("diagnose")) {
    siteMinutes = 45;
    reasoning = "Inspection-only visit — diagnose, document, return with quote.";
  } else if (title.includes("repair") || title.includes("fix")) {
    siteMinutes = 90;
    reasoning = "Repairs vary; budget 60–120 min on site.";
  } else if (title.includes("punch") || title.includes("bundle") || title.includes("multiple")) {
    siteMinutes = 180;
    suggestSplit = true;
    reasoning = "Bundled punch-list visits can run long. Consider scoping into discrete blocks.";
  }
  const driveMinutes = 25;
  return { siteMinutes, driveMinutes, totalMinutes: siteMinutes + driveMinutes, reasoning, suggestSplit };
}

function suggestUpsells(systems: { name: string; category: string; manufacturer?: string; modelNumber?: string }[], _visits: unknown[]): { title: string; reason: string; estimate?: string }[] {
  const out: { title: string; reason: string; estimate?: string }[] = [];
  const cats = systems.map((s) => (s.category || "").toLowerCase());
  const names = systems.map((s) => (s.name || "").toLowerCase());

  if (cats.some((c) => c.includes("hvac")) || names.some((n) => n.includes("furnace") || n.includes("ac"))) {
    out.push({
      title: "Replace HVAC filter while you're here",
      reason: "Standard HVAC system on file — easy 5-minute add-on.",
      estimate: "$25",
    });
  }
  if (cats.some((c) => c.includes("plumb")) || names.some((n) => n.includes("water heater"))) {
    out.push({
      title: "Test water heater anode",
      reason: "Anode rod typically lasts 5 years. Quick check, big lifetime impact.",
      estimate: "$35",
    });
  }
  if (cats.some((c) => c.includes("smoke") || c.includes("safety")) || systems.length > 5) {
    out.push({
      title: "Smoke + CO detector battery swap",
      reason: "Safety check most homes haven't done this year.",
      estimate: "$45",
    });
  }
  if (systems.some((s) => (s.category || "").toLowerCase().includes("dryer"))) {
    out.push({
      title: "Clean dryer vent duct",
      reason: "Fire prevention. Owner has a dryer on file but no recent vent service.",
      estimate: "$85",
    });
  }
  // Generic "while you're there" suggestions for any home
  if (out.length < 2) {
    out.push({
      title: "Caulk + grout walk-through",
      reason: "Most homes have something needing 15 min of caulk attention.",
      estimate: "$60",
    });
  }
  return out.slice(0, 4);
}

function requestStatusTone(status: RequestStatus): PillTone {
  switch (status) {
    case "submitted":
    case "sent_to_handyman":
    case "alternate_dates_proposed":
    case "awaiting_homeowner":
      return "salmon";
    case "scheduled":
    case "confirmed":
      return "indigo";
    case "on_my_way":
    case "checked_in":
    case "in_progress":
      return "info";
    case "completed":
      return "success";
    case "quoted":
      return "warning";
    default:
      return "neutral";
  }
}
