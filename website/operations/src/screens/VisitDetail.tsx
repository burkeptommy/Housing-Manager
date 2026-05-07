import { useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { categorizePunchList, formatCurrency, formatRelativeTime, formatTime12h, parsePunchList, postProviderAction, type PunchListItem } from "../lib/api";
import type { RequestStatus, VisitRow } from "../lib/types";

export default function VisitDetailScreen() {
  const { requestId } = useParams<{ requestId: string }>();
  const { dashboard, refresh } = useWorkspace();
  const navigate = useNavigate();
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const [busy, setBusy] = useState(false);
  const [showReschedule, setShowReschedule] = useState(false);
  const [showSplit, setShowSplit] = useState(false);

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

  // Punch list parsed from the linked maintenance_task's notes.
  const punchList = useMemo(() => parsePunchList(visit?.visit?.notes), [visit?.visit?.notes]);
  // Grouped by physical work zone so the handyman can do all the
  // exterior in one pass, all the safety checks in one pass, etc.
  const categorizedPunch = useMemo(() => categorizePunchList(punchList), [punchList]);
  // Long visits are easier to manage as two — surface the split CTA
  // by default at 8+ items.
  const punchIsLong = punchList.length >= 8;

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
      // Server locks date/time to confirmed_visit_at when present, so
      // we don't override here. For unconfirmed visits we send the
      // existing routeDate so the assignment lands on the same day
      // the homeowner originally requested instead of jumping to today.
      await postProviderAction("assign_visit", {
        workspaceId: dashboard.workspace.id,
        requestId: visit.requestId,
        assignedMemberId: dashboard.currentUser.memberId,
        routeDate: visit.routeDate || new Date().toISOString().slice(0, 10),
        windowStartTime: visit.assignment?.windowStartTime || "09:00",
        windowEndTime: visit.assignment?.windowEndTime || "11:00",
      });
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't assign.");
    } finally {
      setBusy(false);
    }
  }

  function openQuoteForVisit() {
    if (!visit || !visit.property) return;
    // Pre-populate line items from the visit's punch list so the
    // handyman doesn't have to re-type each item — they can adjust
    // quantities/prices and send.
    const itemSuggestions = punchList.map((item) => ({
      name: item.title,
      description: "",
      unit: "ea" as const,
      quantity: 1,
      // $75/item is a reasonable "starter" handyman line. Easy to adjust.
      unitPrice: 75,
    }));
    window.dispatchEvent(new CustomEvent("ops:open-new-quote", {
      detail: {
        propertyId: visit.property.id,
        requestId: visit.requestId,
        title: visit.quote ? `Revised quote · ${visit.title}` : `Quote for ${visit.title}`,
        suggestions: itemSuggestions,
      },
    }));
  }

  async function handleMarkComplete() {
    if (!visit || !dashboard) return;
    const next = visit.status === "completed" ? "in_progress" : "completed";
    const verb = next === "completed" ? "Mark this visit complete?" : "Reopen this visit?";
    if (!window.confirm(verb)) return;
    setBusy(true);
    try {
      await postProviderAction("update_request_status", {
        workspaceId: dashboard.workspace.id,
        requestId: visit.requestId,
        status: next,
      });
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't update status. The action may not be wired on the server yet.");
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

      {/* Pending homeowner counter-proposal — Accept/Counter inline so
          the dispatcher doesn't have to hunt through the chat thread to
          act on the homeowner's response. Only renders when the most
          recent proposal came from the homeowner and isn't yet
          confirmed. */}
      {visit.proposedVisitAt
        && visit.proposedByRole === "homeowner"
        && !visit.confirmedVisitAt && (
        <PendingHomeownerProposalCard
          visit={visit}
          workspaceId={dashboard.workspace.id}
          onResolved={async () => {
            await refresh();
          }}
        />
      )}

      {/* Header card */}
      <Card padding="default" style={{ marginBottom: 16 }}>
        <div style={{ display: "flex", gap: 6, marginBottom: 8, alignItems: "center", flexWrap: "wrap" }}>
          <Pill tone={requestStatusTone(visit.status)}>{visit.statusLabel}</Pill>
          {visit.assignment ? (
            <Pill tone="indigo">Assigned to {visit.assignment.memberName.split(" ")[0]}</Pill>
          ) : (
            <Pill tone="warning">Not assigned</Pill>
          )}
          {/* Section 19a — surface Chez routing + urgency on the header
              so the dispatcher sees the reply path and pace at a glance. */}
          {visit.urgency === "urgent" && <Pill tone="critical">Emergency</Pill>}
          {visit.source === "haven" && <Pill tone="indigo">Routed by Chez</Pill>}
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
          <button className="ops-button ops-button--ghost" onClick={() => setShowReschedule(true)}>
            Propose new time
          </button>
          <button className="ops-button ops-button--ghost" onClick={openQuoteForVisit}>
            {visit.quote ? "Edit quote" : "Build a quote"}
          </button>
          <button
            className="ops-button ops-button--ghost"
            style={{ marginLeft: "auto" }}
            onClick={handleMarkComplete}
            disabled={busy}
          >
            {visit.status === "completed" ? "Reopen visit" : "Mark complete"}
          </button>
        </div>
      </Card>

      {showReschedule && (
        <RescheduleModal
          visit={visit}
          onClose={() => setShowReschedule(false)}
          onConfirmed={async () => {
            setShowReschedule(false);
            await refresh();
          }}
        />
      )}

      <div style={{ display: "grid", gridTemplateColumns: "1.4fr 1fr", gap: 24, alignItems: "start" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          {/* Tasks the homeowner (or Chez admin) asked for. Section 19a:
              when source='haven' the request was routed by the Chez admin
              on the homeowner's behalf, so the framing reads as a Chez
              brief instead of a direct homeowner ask. */}
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>
              {visit.source === "haven" ? "What Chez is asking for" : "What the homeowner is asking for"}
            </div>
            <div style={{ fontSize: 13.5, lineHeight: 1.55, color: "var(--text)", whiteSpace: "pre-wrap" }}>
              {visit.title}
            </div>
            {visit.source === "haven" && (
              <div style={{ marginTop: 10, padding: 10, background: "var(--indigo-50)", borderRadius: 8, fontSize: 12.5, color: "var(--text-muted)" }}>
                <strong style={{ color: "var(--indigo)" }}>Routed by Chez.</strong> Replies on this thread go to the Chez admin, who relays back to the homeowner.
              </div>
            )}
            {visit.preferredTiming && (
              <div style={{ marginTop: 10, padding: 10, background: "var(--indigo-50)", borderRadius: 8, fontSize: 12.5, color: "var(--text-muted)" }}>
                <strong style={{ color: "var(--indigo)" }}>Preferred timing:</strong> {visit.preferredTiming}
              </div>
            )}
          </Card>

          {/* Punch list — grouped by work zone so the tech doesn't double back. */}
          {punchList.length > 0 && (
            <Card padding="default">
              <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 4, gap: 12, flexWrap: "wrap" }}>
                <div className="ops-section-label">
                  Punch list ({punchList.length}) · grouped by zone
                </div>
                <div style={{ display: "flex", gap: 14, flexWrap: "wrap" }}>
                  <button
                    onClick={() => setShowSplit(true)}
                    style={{
                      background: "none", border: "none",
                      color: punchIsLong ? "var(--salmon-dark)" : "var(--indigo)",
                      fontSize: 12, fontWeight: 600, cursor: "pointer",
                    }}
                  >
                    {punchIsLong ? "↗ Long list. Split into two visits?" : "Split into two visits"}
                  </button>
                  <button
                    onClick={openQuoteForVisit}
                    style={{ background: "none", border: "none", color: "var(--salmon-dark)", fontSize: 12, fontWeight: 600, cursor: "pointer" }}
                  >
                    + Pre-fill quote from these
                  </button>
                </div>
              </div>

              <div style={{ display: "flex", flexDirection: "column", gap: 18, marginTop: 14 }}>
                {categorizedPunch.map((group) => (
                  <div key={group.category.id}>
                    <div style={{
                      display: "flex", alignItems: "center", justifyContent: "space-between",
                      paddingBottom: 6, marginBottom: 6,
                      borderBottom: "1px solid var(--neutral-200)",
                    }}>
                      <div style={{
                        fontSize: 11, fontWeight: 700, letterSpacing: "0.12em",
                        textTransform: "uppercase", color: "var(--indigo)",
                      }}>
                        {group.category.label} · {group.items.length}
                      </div>
                      {group.totalMinutes > 0 && (
                        <div style={{ fontSize: 11, color: "var(--text-soft)", fontWeight: 500 }}>
                          ~{group.totalMinutes} min total
                        </div>
                      )}
                    </div>
                    <div style={{ display: "flex", flexDirection: "column" }}>
                      {group.items.map((item, i) => (
                        <div
                          key={item.id}
                          style={{
                            display: "flex",
                            alignItems: "center",
                            gap: 12,
                            padding: "8px 0",
                            borderBottom: i < group.items.length - 1 ? "1px solid var(--neutral-200)" : "none",
                          }}
                        >
                          <div
                            style={{
                              width: 22, height: 22, borderRadius: "50%",
                              border: "1.7px solid var(--neutral-300)", flex: "none",
                            }}
                          />
                          <div style={{ flex: 1, fontSize: 13.5, color: "var(--text)" }}>{item.title}</div>
                          {item.estimatedMinutes != null && (
                            <span style={{ fontSize: 11.5, color: "var(--text-soft)", fontWeight: 500 }}>
                              ~{item.estimatedMinutes} min
                            </span>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>

              <div style={{ marginTop: 14, fontSize: 11.5, color: "var(--text-muted)" }}>
                Items grouped by work zone so you can knock out everything in one area before moving on.
                Check them off in Chez Field on the day of the visit.
              </div>
            </Card>
          )}

          {/* Split-visit modal */}
          {showSplit && visit && (
            <SplitVisitModal
              originalRequestId={visit.requestId}
              originalTitle={visit.title}
              workspaceId={dashboard.workspace.id}
              items={punchList}
              onClose={() => setShowSplit(false)}
              onSplit={async () => {
                setShowSplit(false);
                await refresh();
              }}
            />
          )}

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
                <strong style={{ color: "var(--salmon-dark)" }}>Heads-up:</strong> This looks like more work than fits a single window. Consider splitting into 2 visits: one for diagnosis, one for the fix.
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
                      <div style={{ width: 32, height: 32, borderRadius: 8, background: "var(--neutral-200)", color: "var(--text-soft)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
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
                placeholder={visit.source === "haven" ? "Reply to Chez. They'll relay to the homeowner." : "Reply to the homeowner."}
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
            <SidebarRow label="Window" value={visit.assignment?.windowStartTime ? `${formatTime12h(visit.assignment.windowStartTime)} to ${formatTime12h(visit.assignment.windowEndTime)}` : "Not scheduled"} />
            <SidebarRow label="Tech" value={visit.assignment?.memberName || "Unassigned"} />
            <SidebarRow label="Stop #" value={visit.assignment?.stopOrder ? String(visit.assignment.stopOrder) : "Not assigned"} />
          </Card>

          {visit.quote ? (
            <Card padding="default">
              <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 8 }}>
                <div className="ops-section-label">Quote</div>
                <Pill tone={visit.quote.status === "approved" ? "success" : visit.quote.status === "declined" ? "critical" : visit.quote.status === "viewed" ? "indigo" : "info"}>
                  {visit.quote.statusLabel}
                </Pill>
              </div>
              <div style={{ fontFamily: "var(--serif)", fontSize: 28, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.018em", marginBottom: 8 }}>
                {formatCurrency(visit.quote.total)}
              </div>
              <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginBottom: 12 }}>
                {visit.quote.lineItems.length} line item{visit.quote.lineItems.length === 1 ? "" : "s"} · updated {formatRelativeTime(visit.quote.updatedAt)}
              </div>
              <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                <button className="ops-button ops-button--ghost" style={{ fontSize: 12 }} onClick={openQuoteForVisit}>
                  Edit
                </button>
                {visit.quote.publicShareUrl && (
                  <a className="ops-button ops-button--ghost" style={{ fontSize: 12 }} href={visit.quote.publicShareUrl} target="_blank" rel="noopener">
                    Homeowner view →
                  </a>
                )}
              </div>
            </Card>
          ) : (
            <Card padding="default">
              <div className="ops-section-label" style={{ marginBottom: 8 }}>Quote</div>
              <div style={{ fontSize: 13, color: "var(--text-muted)", lineHeight: 1.5, marginBottom: 12 }}>
                No quote on this visit yet. Build one from the home's systems and send it for the homeowner to approve.
              </div>
              <button className="ops-button ops-button--salmon" style={{ width: "100%", justifyContent: "center" }} onClick={openQuoteForVisit}>
                + Build a quote
              </button>
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
                <SidebarRow label="Last visit" value={home.lastCompletedVisit ? formatRelativeTime(home.lastCompletedVisit) : "Never"} />
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
  let reasoning = "Standard contractor visit window.";
  if (title.includes("install") || title.includes("replace")) {
    siteMinutes = 120;
    reasoning = "Installs and replacements typically run 90 to 150 min on site.";
  } else if (title.includes("inspect") || title.includes("diagnose")) {
    siteMinutes = 45;
    reasoning = "Inspection-only visit. Diagnose, document, return with quote.";
  } else if (title.includes("repair") || title.includes("fix")) {
    siteMinutes = 90;
    reasoning = "Repairs vary; budget 60 to 120 min on site.";
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
      reason: "Standard HVAC system on file. Easy 5-minute add-on.",
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
  // Salmon discipline (CLAUDE.md): salmon is reserved for SLA-critical /
  // counter-offered states only — never for routine status decoration.
  switch (status) {
    case "alternate_dates_proposed":
      return "salmon";
    case "submitted":
    case "sent_to_handyman":
      return "indigo";
    case "awaiting_homeowner":
      return "warning";
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

// ─── Reschedule modal — propose a new time to the homeowner ───

function RescheduleModal({
  visit,
  onClose,
  onConfirmed,
}: {
  visit: VisitRow;
  onClose: () => void;
  onConfirmed: () => Promise<void>;
}) {
  const { dashboard } = useWorkspace();
  const initialDate = visit.routeDate || new Date().toISOString().slice(0, 10);
  const [date, setDate] = useState(initialDate);
  const [hour, setHour] = useState("09");
  const [minute, setMinute] = useState("00");
  const [note, setNote] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function submit() {
    if (!dashboard) return;
    setSubmitting(true);
    try {
      // Build an ISO timestamp from the local date + hour:minute
      const proposedAt = new Date(`${date}T${hour}:${minute}:00`).toISOString();
      await postProviderAction("propose_visit_time", {
        workspaceId: dashboard.workspace.id,
        requestId: visit.requestId,
        proposedAt,
        note: note.trim() || undefined,
      });
      await onConfirmed();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't propose new time.");
    } finally {
      setSubmitting(false);
    }
  }

  const hours = Array.from({ length: 12 }, (_, i) => String(i + 7).padStart(2, "0")); // 7am-6pm
  const minutes = ["00", "15", "30", "45"];

  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 50,
        background: "rgba(42,34,82,0.4)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: 24,
      }}
      onClick={() => !submitting && onClose()}
    >
      <div
        style={{ background: "#fff", borderRadius: 16, padding: 24, width: "min(440px, 90vw)", boxShadow: "0 24px 60px rgba(42,34,82,0.4)" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
          <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600 }}>Propose a new time</div>
          <button onClick={onClose} style={{ background: "none", border: "none", color: "var(--text-soft)", cursor: "pointer", padding: 4 }} aria-label="Close">
            <Icon name="remove" size={16} stroke={2} />
          </button>
        </div>
        <div style={{ fontSize: 13, color: "var(--text-muted)", lineHeight: 1.5, marginBottom: 16 }}>
          The homeowner gets a notification with this proposal. If they accept, the visit shifts to the new time; if they counter, you'll see their proposal here.
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <label style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>New date</span>
            <input
              type="date"
              value={date}
              min={new Date().toISOString().slice(0, 10)}
              onChange={(e) => setDate(e.target.value)}
              style={{ width: "100%", padding: "10px 12px", border: "1px solid var(--neutral-200)", borderRadius: 10, fontSize: 13, fontFamily: "var(--sans)" }}
            />
          </label>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
            <label style={{ display: "flex", flexDirection: "column", gap: 4 }}>
              <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>Hour</span>
              <select value={hour} onChange={(e) => setHour(e.target.value)} style={{ width: "100%", padding: "10px 12px", border: "1px solid var(--neutral-200)", borderRadius: 10, fontSize: 13, fontFamily: "var(--sans)" }}>
                {hours.map((h) => (
                  <option key={h} value={h}>{Number(h) > 12 ? `${Number(h) - 12} PM` : Number(h) === 12 ? "12 PM" : `${Number(h)} AM`}</option>
                ))}
              </select>
            </label>
            <label style={{ display: "flex", flexDirection: "column", gap: 4 }}>
              <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>Minutes</span>
              <select value={minute} onChange={(e) => setMinute(e.target.value)} style={{ width: "100%", padding: "10px 12px", border: "1px solid var(--neutral-200)", borderRadius: 10, fontSize: 13, fontFamily: "var(--sans)" }}>
                {minutes.map((m) => (
                  <option key={m} value={m}>:{m}</option>
                ))}
              </select>
            </label>
          </div>

          <label style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>Note (optional)</span>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Quick context for the homeowner: e.g. 'Pushed back because of a delivery delay'."
              style={{ width: "100%", padding: "10px 12px", border: "1px solid var(--neutral-200)", borderRadius: 10, fontSize: 13, fontFamily: "var(--sans)", minHeight: 80, resize: "vertical" }}
            />
          </label>

          <div style={{ display: "flex", gap: 8, justifyContent: "flex-end", marginTop: 8 }}>
            <button className="ops-button ops-button--ghost" onClick={onClose} disabled={submitting}>Cancel</button>
            <button className="ops-button ops-button--salmon" onClick={submit} disabled={submitting}>
              {submitting ? "Sending…" : "Send proposal"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Split visit modal ──────────────────────────────────────────
//
// Lets the handyman peel items off the current visit into a brand-new
// follow-up visit. Default selection is empty — the handyman ticks
// the items they want to push to the second visit, picks a target
// date, and we POST split_visit_punch_list. The edge function
// creates a new handyman_request + maintenance_task and rewrites
// the original task's notes to drop the moved items.

function SplitVisitModal({
  originalRequestId,
  originalTitle,
  workspaceId,
  items,
  onClose,
  onSplit,
}: {
  originalRequestId: string;
  originalTitle: string;
  workspaceId: string;
  items: PunchListItem[];
  onClose: () => void;
  onSplit: () => void | Promise<void>;
}) {
  const [moved, setMoved] = useState<Set<string>>(new Set());
  const [followUpDate, setFollowUpDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() + 14);
    return d.toISOString().slice(0, 10);
  });
  const [followUpTitle, setFollowUpTitle] = useState(`${originalTitle} — follow-up`);
  const [submitting, setSubmitting] = useState(false);

  // Group the items so the handyman picks by zone, not by random order
  const grouped = useMemo(() => categorizePunchList(items), [items]);

  function toggle(id: string) {
    setMoved((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function moveAllInGroup(groupItems: PunchListItem[]) {
    setMoved((prev) => {
      const next = new Set(prev);
      const allMoved = groupItems.every((i) => next.has(i.id));
      for (const item of groupItems) {
        if (allMoved) next.delete(item.id);
        else next.add(item.id);
      }
      return next;
    });
  }

  async function submit() {
    if (moved.size === 0) {
      alert("Pick at least one item to move to the follow-up visit.");
      return;
    }
    setSubmitting(true);
    try {
      const titles = items.filter((i) => moved.has(i.id)).map((i) => i.title);
      await postProviderAction("split_visit_punch_list", {
        workspaceId,
        requestId: originalRequestId,
        movedTitles: titles,
        followUpTitle: followUpTitle.trim() || `${originalTitle} — follow-up`,
        followUpDate: followUpDate || undefined,
      });
      await onSplit();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't split the visit.");
    } finally {
      setSubmitting(false);
    }
  }

  const movedCount = moved.size;
  const remainingCount = items.length - movedCount;

  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 60,
        background: "rgba(42, 34, 82, 0.45)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: 24,
      }}
      onClick={() => !submitting && onClose()}
    >
      <div
        style={{
          background: "#fff", borderRadius: 18, width: "min(640px, 95vw)",
          maxHeight: "88vh", overflowY: "auto",
          boxShadow: "0 24px 60px rgba(42, 34, 82, 0.4)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ padding: 24, borderBottom: "1px solid var(--neutral-200)" }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase", color: "var(--text-soft)", marginBottom: 6 }}>
            Split visit
          </div>
          <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em" }}>
            Move some items to a follow-up visit
          </div>
          <div style={{ fontSize: 13, color: "var(--text-muted)", marginTop: 6, lineHeight: 1.5 }}>
            Tick anything that won't fit in this visit. We'll create a second visit on the date you pick and message the homeowner.
          </div>
        </div>

        <div style={{ padding: "16px 24px", display: "flex", flexDirection: "column", gap: 16 }}>
          {grouped.map((group) => {
            const allMoved = group.items.every((i) => moved.has(i.id));
            return (
              <div key={group.category.id}>
                <div style={{
                  display: "flex", alignItems: "center", justifyContent: "space-between",
                  paddingBottom: 6, marginBottom: 6,
                  borderBottom: "1px solid var(--neutral-200)",
                }}>
                  <div style={{
                    fontSize: 11, fontWeight: 700, letterSpacing: "0.12em",
                    textTransform: "uppercase", color: "var(--indigo)",
                  }}>
                    {group.category.label} · {group.items.length}
                  </div>
                  <button
                    type="button"
                    onClick={() => moveAllInGroup(group.items)}
                    style={{
                      background: "none", border: "none",
                      color: "var(--salmon-dark)", fontSize: 11.5, fontWeight: 600,
                      cursor: "pointer",
                    }}
                  >
                    {allMoved ? "Keep all in this visit" : "Move all to follow-up"}
                  </button>
                </div>
                {group.items.map((item) => {
                  const isMoved = moved.has(item.id);
                  return (
                    <label
                      key={item.id}
                      style={{
                        display: "flex", alignItems: "center", gap: 12,
                        padding: "8px 0",
                        cursor: "pointer",
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={isMoved}
                        onChange={() => toggle(item.id)}
                        style={{ width: 18, height: 18, accentColor: "var(--salmon)", flexShrink: 0 }}
                      />
                      <span style={{
                        flex: 1, fontSize: 13.5,
                        color: isMoved ? "var(--text-muted)" : "var(--text)",
                        textDecoration: isMoved ? "line-through" : "none",
                      }}>
                        {item.title}
                      </span>
                      {item.estimatedMinutes != null && (
                        <span style={{ fontSize: 11.5, color: "var(--text-soft)", fontWeight: 500 }}>
                          ~{item.estimatedMinutes} min
                        </span>
                      )}
                    </label>
                  );
                })}
              </div>
            );
          })}
        </div>

        <div style={{ padding: "16px 24px", borderTop: "1px solid var(--neutral-200)", background: "var(--cream)" }}>
          <div style={{ display: "flex", gap: 12, marginBottom: 12 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)", marginBottom: 4 }}>
                Follow-up title
              </div>
              <input
                type="text"
                value={followUpTitle}
                onChange={(e) => setFollowUpTitle(e.target.value)}
                style={{
                  width: "100%", padding: "10px 12px",
                  border: "1px solid var(--neutral-200)", borderRadius: 10,
                  background: "#fff", fontSize: 13, fontFamily: "var(--sans)",
                  color: "var(--text)",
                }}
              />
            </div>
            <div>
              <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)", marginBottom: 4 }}>
                Target date
              </div>
              <input
                type="date"
                value={followUpDate}
                min={new Date().toISOString().slice(0, 10)}
                onChange={(e) => setFollowUpDate(e.target.value)}
                style={{
                  padding: "10px 12px",
                  border: "1px solid var(--neutral-200)", borderRadius: 10,
                  background: "#fff", fontSize: 13, fontFamily: "var(--sans)",
                  color: "var(--text)",
                }}
              />
            </div>
          </div>

          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12, flexWrap: "wrap" }}>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)" }}>
              <strong style={{ color: "var(--text)" }}>{remainingCount}</strong> stay in this visit ·{" "}
              <strong style={{ color: "var(--salmon-dark)" }}>{movedCount}</strong> move to follow-up
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <button className="ops-button ops-button--ghost" onClick={onClose} disabled={submitting}>Cancel</button>
              <button
                className="ops-button ops-button--salmon"
                onClick={submit}
                disabled={submitting || movedCount === 0}
              >
                {submitting ? "Splitting…" : `Schedule follow-up visit (${movedCount})`}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Pending homeowner counter-proposal callout ─────────────────
//
// The most prominent visual element on the page when the homeowner
// has counter-proposed a time. Big proposed time in serif, two
// inline buttons (Accept locks it in, Counter opens the existing
// reschedule modal). Without this the only signal of a pending
// proposal was a row buried in the chat thread.

function PendingHomeownerProposalCard({
  visit,
  workspaceId,
  onResolved,
}: {
  visit: VisitRow;
  workspaceId: string;
  onResolved: () => Promise<void>;
}) {
  const [busy, setBusy] = useState<"accept" | "counter" | null>(null);
  const [showReschedule, setShowReschedule] = useState(false);

  const proposedDate = visit.proposedVisitAt ? new Date(visit.proposedVisitAt) : null;
  const dateLabel = proposedDate
    ? proposedDate.toLocaleString(undefined, {
        weekday: "long",
        month: "long",
        day: "numeric",
        hour: "numeric",
        minute: "2-digit",
      })
    : "A new time";

  async function accept() {
    setBusy("accept");
    try {
      await postProviderAction("accept_visit_time", {
        workspaceId,
        requestId: visit.requestId,
      });
      await onResolved();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't accept the time.");
    } finally {
      setBusy(null);
    }
  }

  return (
    <>
      <div
        style={{
          marginBottom: 16,
          padding: 20,
          borderRadius: 16,
          background: "linear-gradient(155deg, #FFF5F2 0%, #FFE8E2 100%)",
          border: "1px solid rgba(237, 105, 85, 0.35)",
          boxShadow: "0 6px 20px rgba(237, 105, 85, 0.12)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 8 }}>
          <Icon name="clock" size={14} stroke={2} color="var(--salmon-dark)" />
          <div style={{
            fontSize: 11, fontWeight: 700, letterSpacing: "0.16em",
            textTransform: "uppercase", color: "var(--salmon-dark)",
          }}>
            Homeowner proposed a new time
          </div>
        </div>
        <div style={{
          fontFamily: "var(--serif)", fontSize: 24, fontWeight: 600,
          color: "var(--text)", letterSpacing: "-0.018em", marginBottom: 4,
        }}>
          {dateLabel}
        </div>
        <div style={{ fontSize: 13, color: "var(--text-muted)", marginBottom: 16 }}>
          Accept to lock it in, or counter with another time. The homeowner gets a push either way.
        </div>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <button
            className="ops-button ops-button--salmon"
            disabled={busy !== null}
            onClick={accept}
          >
            {busy === "accept" ? "Accepting…" : "✓ Accept this time"}
          </button>
          <button
            className="ops-button ops-button--ghost"
            disabled={busy !== null}
            onClick={() => setShowReschedule(true)}
          >
            Counter with another time
          </button>
        </div>
      </div>

      {showReschedule && (
        <RescheduleModal
          visit={visit}
          onClose={() => setShowReschedule(false)}
          onConfirmed={async () => {
            setShowReschedule(false);
            await onResolved();
          }}
        />
      )}
    </>
  );
}
