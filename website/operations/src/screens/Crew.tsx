import { useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatRelativeTime, isToday, postProviderAction } from "../lib/api";

export default function CrewScreen() {
  const { dashboard, mode, refresh } = useWorkspace();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [busyMemberId, setBusyMemberId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

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
          <button className="ops-button ops-button--salmon">+ Invite teammate</button>
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
              When you add a second person, the workspace flips into crew mode — Dispatch lanes split by tech, the Calendar gets per-tech filters, and Routes shows side-by-side boards.
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
                <Detail icon="mail"      label="Email"  value={selected.email || "—"} />
                <Detail icon="phone"     label="Phone"  value={selected.phone || "—"} />
                <Detail icon="briefcase" label="Role"   value={selected.role} />
                <Detail icon="shield"    label="Last seen" value={selected.lastSeenAt ? formatRelativeTime(selected.lastSeenAt) : "—"} />
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
                        <span className="ops-pill__dot" style={{ background: "#4A7C59", width: 8, height: 8, borderRadius: "50%" }} />
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
  );
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
