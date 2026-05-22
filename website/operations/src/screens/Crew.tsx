import { useEffect, useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatRelativeTime, isToday, postProviderAction } from "../lib/api";
import type { TodaySummary } from "../lib/types";
// Wave M7 — Crew chat sub-tab. Lives in its own component so the
// roster surface stays unchanged when the operator stays on the
// default Roster view.
import { CrewChatPanel } from "../components/CrewChatPanel";

type CrewSubTab = "roster" | "chat";

export default function CrewScreen() {
  const { dashboard, mode, refresh } = useWorkspace();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [busyMemberId, setBusyMemberId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  // Wave M7 — sub-tab toggle. Roster (default) vs Chat. Persist to
  // localStorage so an operator who flips to Chat doesn't lose their
  // place on tab switches. Mirrors the iOS Crew tab → workspace
  // messaging pattern.
  const [subTab, setSubTab] = useState<CrewSubTab>(() => {
    if (typeof window === "undefined") return "roster";
    return (window.localStorage.getItem("ops:crewSubTab") as CrewSubTab | null) ?? "roster";
  });
  useEffect(() => {
    if (typeof window === "undefined") return;
    window.localStorage.setItem("ops:crewSubTab", subTab);
  }, [subTab]);

  const members = useMemo(() => dashboard?.teamMembers ?? [], [dashboard]);

  async function setDefaultAssignee(memberId: string) {
    if (!dashboard) return;
    if (busyMemberId) return;
    setError(null);
    setBusyMemberId(memberId);
    try {
      await postProviderAction("update_team_member", {
        workspaceId: dashboard.workspace.id,
        memberId,
        isDefaultAssignee: true,
      });
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to update default assignee");
    } finally {
      setBusyMemberId(null);
    }
  }
  const selected = useMemo(() => {
    if (!members.length) return null;
    return members.find((m) => m.id === selectedId) ?? members[0];
  }, [selectedId, members]);

  if (!dashboard) return null;

  const isSole = mode === "sole" || members.length === 1;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
      {/* Wave M7 — sub-tab switcher. Roster (existing surface) vs
          Chat (intra-workspace messaging). Lives above the workload
          strip so it's the first thing the operator sees. */}
      <div style={{ display: "flex", gap: 4, padding: 4, background: "var(--pearl, #FAFAFC)", borderRadius: 12, alignSelf: "flex-start", border: "1px solid var(--border, #E6E5EE)" }}>
        <button
          onClick={() => setSubTab("roster")}
          style={crewSubTabStyle(subTab === "roster")}
        >
          Roster
        </button>
        <button
          onClick={() => setSubTab("chat")}
          style={crewSubTabStyle(subTab === "chat")}
        >
          Chat
        </button>
      </div>

      {subTab === "chat" ? (
        <CrewChatPanel
          workspaceId={dashboard.workspace.id}
          members={members}
          selfMemberId={dashboard.currentUser?.memberId ?? null}
        />
      ) : (
        <>
      {/* Wave M11 — today's progress strip. Loads via today_summary so
          the dispatcher sees the same numbers the field tech sees on iOS
          before drilling into the roster. */}
      <WorkloadStrip workspaceId={dashboard.workspace.id} />

      <div style={{ display: "grid", gridTemplateColumns: "1.1fr 0.9fr", gap: 24 }}>
      {/* Roster */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 16 }}>
          <div>
            <div className="ops-section-label">Roster</div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)" }}>
              {isSole ? "Just you for now" : `${members.length} teammate${members.length === 1 ? "" : "s"} · ${dashboard.workspace.invitedMemberCount} pending`}
            </div>
          </div>
          <button
            className="ops-button ops-button--salmon"
            onClick={() => window.dispatchEvent(new CustomEvent("ops:open-invite-teammate"))}
          >
            + Invite teammate
          </button>
        </div>

        {isSole && members.length === 1 ? (
          <>
            <button
              onClick={() => setSelectedId(members[0].id)}
              style={selectedRosterRowStyle(true)}
            >
              <Avatar initials={initialsFor(members[0].fullName || members[0].email)} size={36} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{members[0].fullName || members[0].email}</div>
                <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>{members[0].title || members[0].role}</div>
              </div>
              {members[0].isDefaultAssignee && <Pill tone="success">Default</Pill>}
              <Pill tone="indigo">{members[0].role === "owner" ? "Owner" : members[0].role}</Pill>
              <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
            </button>
            <div style={{ marginTop: 14, padding: 14, background: "var(--indigo-50)", borderRadius: 10, fontSize: 12.5, color: "var(--text-muted)", lineHeight: 1.5 }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)", marginBottom: 4 }}>
                Bring on a teammate?
              </div>
              When you add a second person, the workspace flips into crew mode. Dispatch lanes split by tech, the Calendar gets per-tech filters, and Routes shows side-by-side boards.
            </div>
          </>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            {members.map((m) => {
              const isSelected = selected?.id === m.id;
              const myVisits = dashboard.visits.filter((v) => v.assignment?.memberId === m.id && !["completed", "cancelled", "declined"].includes(v.status));
              const today = myVisits.filter((v) => isToday(v.routeDate)).length;
              return (
                <button
                  key={m.id}
                  onClick={() => setSelectedId(m.id)}
                  style={selectedRosterRowStyle(isSelected)}
                >
                  <Avatar initials={initialsFor(m.fullName || m.email)} size={36} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 600, display: "flex", alignItems: "center", gap: 6 }}>
                      <span style={{ overflow: "hidden", textOverflow: "ellipsis" }}>{m.fullName || m.email}</span>
                      {m.isDefaultAssignee && <Pill tone="success">Default</Pill>}
                    </div>
                    <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>{m.title || m.role}</div>
                  </div>
                  <Pill tone={m.status === "invited" ? "warning" : "indigo"}>
                    {m.status === "invited" ? "Invite sent" : m.role === "owner" ? "Owner" : m.role}
                  </Pill>
                  <div style={{ width: 64, fontSize: 11, color: "var(--text-soft)", textAlign: "right" }}>
                    {today} today · {myVisits.length} open
                  </div>
                  <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
                </button>
              );
            })}
          </div>
        )}
      </Card>

      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {selected ? (
          <>
            <Card padding="default" style={{ padding: 0, overflow: "hidden" }}>
              <div style={{ background: "linear-gradient(135deg, var(--indigo), var(--indigo-600))", padding: "20px 24px", display: "flex", alignItems: "center", gap: 12 }}>
                <Avatar initials={initialsFor(selected.fullName || selected.email)} size={48} />
                <div style={{ flex: 1, color: "#fff" }}>
                  <div style={{ fontFamily: "var(--serif)", fontSize: 20, fontWeight: 600 }}>{selected.fullName || selected.email}</div>
                  <div style={{ fontSize: 12.5, color: "rgba(255,255,255,0.7)" }}>{selected.title || selected.role}</div>
                </div>
                <Pill tone={selected.status === "active" ? "success" : "warning"} withDot>
                  {selected.status === "active" ? "Active" : selected.status === "invited" ? "Invited" : "Disabled"}
                </Pill>
              </div>
              <div style={{ padding: 18, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
                <Detail icon="mail"      label="Email"  value={selected.email || "Not set"} />
                <Detail icon="phone"     label="Phone"  value={selected.phone || "Not set"} />
                <Detail icon="briefcase" label="Role"   value={selected.role} />
                <Detail icon="shield"    label="Last seen" value={selected.lastSeenAt ? formatRelativeTime(selected.lastSeenAt) : "Never"} />
              </div>
            </Card>

            {/* T5.8 (post-overnight) — per-tech revenue + utilization
                metrics. Server-side surfaces lifetimeRevenueCents,
                thisMonthRevenueCents, and utilizationRate on every
                team member row. HomeDetail.tsx already surfaced
                home-level lifetime spend; this is the per-tech mirror
                so Tom can see who's most productive at a glance. */}
            <Card padding="default">
              <div className="ops-section-label" style={{ marginBottom: 8 }}>Performance</div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 12 }}>
                <Detail
                  icon="dollar-sign"
                  label="Lifetime"
                  value={formatCents(selected.lifetimeRevenueCents ?? 0)}
                />
                <Detail
                  icon="trending-up"
                  label="Last 30 days"
                  value={formatCents(selected.thisMonthRevenueCents ?? 0)}
                />
                <Detail
                  icon="check-circle"
                  label="Completed"
                  value={String(selected.completedCount ?? 0)}
                />
                <Detail
                  icon="activity"
                  label="On-time rate"
                  value={
                    selected.utilizationRate != null
                      ? `${Math.round((selected.utilizationRate ?? 0) * 100)}%`
                      : "—"
                  }
                />
              </div>
            </Card>

            <Card padding="default">
              <div className="ops-section-label" style={{ marginBottom: 8 }}>Dispatch</div>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: selected.isDefaultAssignee ? "var(--salmon-50)" : "var(--indigo-50)", color: selected.isDefaultAssignee ? "var(--salmon)" : "var(--indigo)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
                  <Icon name="check" size={16} stroke={2.2} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>
                    Default assignee for new home assessments
                  </div>
                  <div style={{ fontSize: 12, color: "var(--text-muted)", lineHeight: 1.45 }}>
                    {selected.isDefaultAssignee
                      ? "Chez auto-suggests this teammate when dispatching new assessment visits to your workspace."
                      : "Mark this teammate as the default and Chez will auto-suggest them when dispatching new visits."}
                  </div>
                </div>
                {selected.isDefaultAssignee ? (
                  <Pill tone="success" withDot>Default</Pill>
                ) : (
                  <button
                    className="ops-button ops-button--salmon"
                    style={{ opacity: busyMemberId === selected.id ? 0.6 : 1 }}
                    disabled={busyMemberId === selected.id || selected.status !== "active"}
                    onClick={() => setDefaultAssignee(selected.id)}
                  >
                    {busyMemberId === selected.id ? "Saving…" : "Make default"}
                  </button>
                )}
              </div>
              {selected.status !== "active" && !selected.isDefaultAssignee && (
                <div style={{ marginTop: 10, fontSize: 11.5, color: "var(--text-soft)", fontStyle: "italic" }}>
                  Only active teammates can be set as the default.
                </div>
              )}
              {error && (
                <div style={{ marginTop: 10, fontSize: 12, color: "var(--critical, #B91C1C)" }}>
                  {error}
                </div>
              )}
            </Card>

            <Card padding="default">
              <div className="ops-section-label" style={{ marginBottom: 8 }}>Recent activity</div>
              {(() => {
                const myWork = dashboard.recentWork.filter((v) => v.assignment?.memberId === selected.id).slice(0, 6);
                if (myWork.length === 0) {
                  return (
                    <div style={{ padding: "20px 0", fontSize: 13, color: "var(--text-muted)" }}>
                      No completed visits yet.
                    </div>
                  );
                }
                return (
                  <div style={{ display: "flex", flexDirection: "column" }}>
                    {myWork.map((v) => (
                      <div key={v.requestId} className="ops-row" style={{ padding: "10px 0" }}>
                        <span className="ops-pill__dot" style={{ background: "#0A0A0A", width: 8, height: 8, borderRadius: "50%" }} />
                        <div style={{ flex: 1, fontSize: 13, color: "var(--text)" }}>{v.title}</div>
                        <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>
                          {v.fieldWorkspace?.completedAt ? formatRelativeTime(v.fieldWorkspace.completedAt) : formatRelativeTime(v.updatedAt)}
                        </div>
                      </div>
                    ))}
                  </div>
                );
              })()}
            </Card>
          </>
        ) : (
          <EmptyState
            icon="user"
            title="No teammates selected"
            body="Tap a row in the roster to see profile and recent activity."
          />
        )}
      </div>
      </div>
        </>
      )}
    </div>
  );
}

// Wave M7 — sub-tab pill style. Matches existing ops-button rounded
// chip pattern but smaller. Active = salmon-50 wash + salmon text.
function crewSubTabStyle(isActive: boolean): React.CSSProperties {
  return {
    padding: "6px 14px",
    border: "none",
    background: isActive ? "var(--salmon-50, #FDEDEA)" : "transparent",
    color: isActive ? "var(--salmon)" : "var(--text-muted)",
    borderRadius: 8,
    fontSize: 13,
    fontWeight: isActive ? 600 : 500,
    cursor: "pointer",
  };
}

// ─── Wave M11 — Today's progress strip ────────────────────────────────
//
// Compact summary of today's stops + clock totals + revenue invoiced
// for the workspace, with a small tomorrow preview line. Mirrors the
// hero card the field tech sees on iOS so the dispatcher and the tech
// see the same numbers. Renders inline above the roster grid; loads
// on mount via the today_summary action and silently degrades to a
// muted "0 stops scheduled today" line on read failure.

function WorkloadStrip({ workspaceId }: { workspaceId: string }) {
  const [summary, setSummary] = useState<TodaySummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    postProviderAction<TodaySummary>("today_summary", { workspaceId })
      .then((result) => {
        if (cancelled) return;
        setSummary(result);
      })
      .catch((e) => {
        if (cancelled) return;
        setError(e instanceof Error ? e.message : "Failed to load today's summary");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [workspaceId]);

  if (loading) {
    return (
      <Card padding="default">
        <div style={{ fontSize: 13, color: "var(--text-soft)" }}>Loading today's progress…</div>
      </Card>
    );
  }
  if (error || !summary) {
    return (
      <Card padding="default">
        <div style={{ fontSize: 13, color: "var(--text-soft)" }}>
          Today's progress unavailable.
        </div>
      </Card>
    );
  }
  const { today, tomorrow } = summary;
  return (
    <Card padding="default">
      <div style={{ display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
        <div style={{ display: "flex", flexDirection: "column", flex: "1 1 0", minWidth: 200 }}>
          <div className="ops-section-label">Today's progress</div>
          <div style={{ fontSize: 18, fontWeight: 700, color: "var(--text)", fontFamily: "var(--serif)" }}>
            {today.stopsCompleted} of {today.stopsCompleted + today.stopsRemaining} {today.stopsCompleted + today.stopsRemaining === 1 ? "stop" : "stops"} done
          </div>
        </div>
        <WorkloadStat label="Clock" value={formatClockMinutes(today.totalClockMinutes)} />
        <WorkloadStat label="Materials" value={formatCents(today.materialsCostCents)} />
        <WorkloadStat label="Invoiced" value={formatCents(today.revenueInvoicedCents)} />
      </div>
      <div style={{ marginTop: 12, paddingTop: 12, borderTop: "1px solid var(--neutral-200)", fontSize: 12.5, color: "var(--text-muted)" }}>
        {tomorrow.stopsCount === 0 ? (
          <span>No stops on the calendar for tomorrow.</span>
        ) : (
          <span>
            Tomorrow: {tomorrow.stopsCount} {tomorrow.stopsCount === 1 ? "stop" : "stops"} scheduled
            {tomorrow.firstAt ? ` · first at ${tomorrow.firstAt.slice(0, 5)}` : ""}
            {tomorrow.firstCustomer ? ` with ${tomorrow.firstCustomer}` : ""}
          </span>
        )}
      </div>
    </Card>
  );
}

function WorkloadStat({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", minWidth: 80 }}>
      <div style={{ fontSize: 11, color: "var(--text-soft)", letterSpacing: "0.04em", textTransform: "uppercase", fontWeight: 600 }}>
        {label}
      </div>
      <div style={{ fontSize: 16, fontWeight: 600, color: "var(--text)" }}>{value}</div>
    </div>
  );
}

function formatClockMinutes(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h > 0 && m > 0) return `${h}h ${m}m`;
  if (h > 0) return `${h}h`;
  return `${m}m`;
}

function formatCents(cents: number): string {
  if (!cents || cents <= 0) return "$0";
  const dollars = cents / 100;
  if (dollars >= 1000) return `$${(dollars / 1000).toFixed(1)}K`;
  return `$${Math.round(dollars).toLocaleString()}`;
}

function selectedRosterRowStyle(isSelected: boolean): React.CSSProperties {
  return {
    display: "flex",
    alignItems: "center",
    gap: 12,
    padding: "10px 12px",
    border: "1px solid var(--neutral-200)",
    borderRadius: 10,
    background: isSelected ? "var(--salmon-50)" : "#fff",
    cursor: "pointer",
    textAlign: "left",
    width: "100%",
  };
}

function Detail({ icon, label, value }: { icon: string; label: string; value: string }) {
  return (
    <div style={{ display: "flex", gap: 8 }}>
      <div style={{ width: 30, height: 30, borderRadius: 8, background: "var(--indigo-50)", color: "var(--indigo)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
        <Icon name={icon} size={14} stroke={1.9} />
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 11, color: "var(--text-soft)", letterSpacing: "0.04em", textTransform: "uppercase", fontWeight: 600 }}>{label}</div>
        <div style={{ fontSize: 13, color: "var(--text)", overflow: "hidden", textOverflow: "ellipsis" }}>{value}</div>
      </div>
    </div>
  );
}
