import { useMemo, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatRelativeTime, formatTime12h, isToday, postProviderAction } from "../lib/api";
import type { VisitRow, RequestStatus } from "../lib/types";

export default function DispatchScreen() {
  const { dashboard, mode, refresh } = useWorkspace();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  // Phase 84.5 — added "assessment" filter to surface free home-assessment
  // visits separately from standard handyman work.
  const [filterChip, setFilterChip] = useState<"all" | "urgent" | "older" | "assessment">("all");
  const [assigning, setAssigning] = useState(false);
  const [routeDate, setRouteDate] = useState<string>(() => new Date().toISOString().slice(0, 10));
  const [windowSlot, setWindowSlot] = useState<string>("9-11");

  const unassigned = useMemo(() => {
    if (!dashboard) return [];
    return dashboard.visits.filter((v) =>
      !v.assignment && !["completed", "cancelled", "declined"].includes(v.status)
    );
  }, [dashboard]);

  const filteredQueue = useMemo(() => {
    return unassigned.filter((u) => {
      if (filterChip === "urgent") {
        return ["submitted", "sent_to_handyman"].includes(u.status);
      }
      if (filterChip === "older") {
        const created = new Date(u.updatedAt).getTime();
        return Date.now() - created > 24 * 60 * 60 * 1000;
      }
      // Phase 84.5 — show only free home-assessment visits when this
      // chip is active.
      if (filterChip === "assessment") {
        return u.visitType === "home_assessment";
      }
      return true;
    });
  }, [unassigned, filterChip]);

  const todayBoard = useMemo(() => {
    if (!dashboard) return [];
    return dashboard.visits.filter((v) => isToday(v.routeDate) && v.assignment);
  }, [dashboard]);

  const selected = useMemo(() => {
    if (!selectedId || !dashboard) return null;
    return dashboard.visits.find((v) => v.requestId === selectedId) ?? null;
  }, [selectedId, dashboard]);

  const techs = useMemo(() => {
    if (!dashboard) return [];
    return dashboard.teamMembers.filter((m) => m.status === "active");
  }, [dashboard]);

  if (!dashboard) return null;

  async function handleAssign(memberId: string) {
    if (!selected || !dashboard) return;
    setAssigning(true);
    try {
      // Server locks the date to confirmed_visit_at when one exists,
      // so what we send here gets ignored in that case. Only matters
      // for unconfirmed visits where the dispatcher is booking from
      // scratch.
      const [start, end] = parseWindow(windowSlot);
      await postProviderAction("assign_visit", {
        workspaceId: dashboard.workspace.id,
        requestId: selected.requestId,
        assignedMemberId: memberId,
        routeDate,
        windowStartTime: start,
        windowEndTime: end,
      });
      await refresh();
      setSelectedId(null);
    } catch (e) {
      console.error("[Dispatch] assign_visit failed", e);
      alert(e instanceof Error ? e.message : "Couldn't assign the visit.");
    } finally {
      setAssigning(false);
    }
  }

  // All visits filtered for the all-list section. Excludes completed
  // unless filter explicitly asks for it.
  const allVisitsList = useMemo(() => {
    if (!dashboard) return [];
    return dashboard.visits
      .filter((v) => !["completed", "cancelled", "declined"].includes(v.status))
      .sort((a, b) => {
        const aDate = a.routeDate || "9999-12-31";
        const bDate = b.routeDate || "9999-12-31";
        return aDate.localeCompare(bDate);
      });
  }, [dashboard]);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
      {/* All open visits — full-width list, every row clickable */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
          <div className="ops-section-label">All open visits · {allVisitsList.length}</div>
          <span style={{ fontSize: 11, color: "var(--text-soft)" }}>Tap any row to manage the visit</span>
        </div>
        {allVisitsList.length === 0 ? (
          <div style={{ padding: 20, fontSize: 13, color: "var(--text-muted)" }}>
            No open visits right now. New visit requests from homeowners land here.
          </div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column" }}>
            {allVisitsList.map((v) => (
              <Link
                key={v.requestId}
                to={`/visits/${v.requestId}`}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  padding: "12px 0",
                  borderBottom: "1px solid var(--neutral-200)",
                  textDecoration: "none",
                  color: "inherit",
                }}
              >
                <div style={{ width: 80, fontSize: 12, color: "var(--text-soft)", fontWeight: 600 }}>
                  {v.routeDate
                    ? new Date(v.routeDate).toLocaleDateString(undefined, { month: "short", day: "numeric" })
                    : "TBD"}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13.5, fontWeight: 600, color: "var(--text)" }}>{v.title}</div>
                  <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
                    {v.property?.name || "Not set"}
                  </div>
                </div>
                {v.assignment && (
                  <div style={{ fontSize: 11, color: "var(--text-soft)" }}>
                    {v.assignment.memberName.split(" ")[0]}
                  </div>
                )}
                <Pill tone={requestStatusTone(v.status)}>{v.statusLabel}</Pill>
                {v.suggestedByRequestId && (
                  /* Wave M8 — visit was scheduled from a field tech's
                     end-of-visit wizard. The pill tells the operator
                     this row didn't come from the homeowner queue or
                     from the admin route — it's a tech's recommendation. */
                  <Pill tone="indigo">Suggested by visit</Pill>
                )}
                {v.quote && (
                  <Pill tone={v.quote.status === "approved" ? "success" : "indigo"}>
                    Quote · {v.quote.statusLabel}
                  </Pill>
                )}
                <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
              </Link>
            ))}
          </div>
        )}
      </Card>

      <div className="ops-grid-dispatch">
      {/* Unassigned column */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
          <div className="ops-section-label">Unassigned · {filteredQueue.length}</div>
        </div>
        <div style={{ display: "flex", gap: 6, marginBottom: 12, flexWrap: "wrap" }}>
          {(["all", "urgent", "older", "assessment"] as const).map((c) => (
            <button
              key={c}
              className="ops-button ops-button--ghost"
              style={{
                fontSize: 11,
                padding: "4px 10px",
                background: filterChip === c ? "var(--neutral-200)" : "#fff",
              }}
              onClick={() => setFilterChip(c)}
            >
              {c === "all" ? "All" : c === "urgent" ? "Need response" : c === "older" ? "24h+" : "Home assessments"}
            </button>
          ))}
        </div>

        {filteredQueue.length === 0 ? (
          <EmptyState
            icon="check"
            title={unassigned.length === 0 ? "Everything's assigned" : "No matches"}
            body={unassigned.length === 0 ? "When a homeowner books a visit it lands here for routing." : "Nothing in the queue matches that filter."}
          />
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {filteredQueue.map((job) => (
              <UnassignedCard
                key={job.requestId}
                visit={job}
                isSelected={selectedId === job.requestId}
                onClick={() => setSelectedId(job.requestId)}
              />
            ))}
          </div>
        )}
      </Card>

      {/* Today's lanes */}
      <Card padding="default">
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 14 }}>
          <div>
            <div className="ops-section-label">Today's board</div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600, color: "var(--text)" }}>
              {new Date().toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" })}
            </div>
          </div>
        </div>

        {todayBoard.length === 0 ? (
          <EmptyState
            icon="calendar"
            title="Nothing on the board today"
            body={mode === "sole" ? "Pick a visit from the unassigned queue and route it to yourself." : "Assign visits from the unassigned queue and they'll fill in here."}
          />
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {techs.map((tech) => {
              const techVisits = todayBoard.filter((v) => v.assignment?.memberId === tech.id);
              if (techVisits.length === 0 && mode === "sole" && tech.role !== "owner") return null;
              return (
                <div key={tech.id} style={{ display: "grid", gridTemplateColumns: "120px 1fr", gap: 12, alignItems: "center", padding: "10px 0", borderBottom: "1px solid var(--neutral-200)" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <Avatar initials={initialsFor(tech.fullName || tech.email)} size={28} />
                    <span style={{ fontSize: 12, fontWeight: 600 }}>{(tech.fullName || tech.email).split(" ")[0]}</span>
                  </div>
                  {techVisits.length === 0 ? (
                    <span style={{ fontSize: 12, color: "var(--text-soft)" }}>No stops today</span>
                  ) : (
                    <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
                      {techVisits.map((v) => (
                        <Link
                          key={v.requestId}
                          to={`/visits/${v.requestId}`}
                          style={{
                            background: "var(--indigo)",
                            color: "#fff",
                            borderRadius: 6,
                            padding: "6px 10px",
                            fontSize: 12,
                            fontWeight: 500,
                            textDecoration: "none",
                            display: "block",
                          }}
                        >
                          {formatTime12h(v.assignment?.windowStartTime || "")} {v.title} <span style={{ opacity: 0.7 }}>· {v.property?.name}</span>
                        </Link>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </Card>

      {/* Assign panel */}
      <Card padding="default">
        {selected ? (
          <>
            <div style={{ display: "flex", gap: 6, marginBottom: 8 }}>
              <Pill tone={requestStatusTone(selected.status)}>{selected.statusLabel}</Pill>
            </div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 19, fontWeight: 600, color: "var(--text)", marginBottom: 4 }}>
              {selected.title}
            </div>
            <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 4 }}>
              {selected.property?.name || selected.property?.address || "No address on file"}{selected.property?.name && selected.property?.address ? ` · ${selected.property.address}` : ""}
            </div>
            {selected.preferredTiming && (
              <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 12 }}>
                Preferred: {selected.preferredTiming}
              </div>
            )}

            <div className="ops-section-label" style={{ marginBottom: 10 }}>{techs.length === 1 ? "Assign to yourself" : "Pick a technician"}</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8, marginBottom: 16 }}>
              {techs.map((tech) => {
                const isMe = tech.userId === dashboard.currentUser.id;
                return (
                  <button
                    key={tech.id}
                    onClick={() => handleAssign(tech.id)}
                    disabled={assigning}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 10,
                      padding: 10,
                      border: isMe ? "1px solid var(--salmon)" : "1px solid var(--neutral-200)",
                      background: isMe ? "var(--salmon-50)" : "#fff",
                      borderRadius: 10,
                      cursor: assigning ? "not-allowed" : "pointer",
                      opacity: assigning ? 0.5 : 1,
                      width: "100%",
                      textAlign: "left",
                    }}
                  >
                    <Avatar initials={initialsFor(tech.fullName || tech.email)} size={32} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{tech.fullName || tech.email}</div>
                      <div style={{ fontSize: 11, color: "var(--text-soft)" }}>
                        {tech.title || tech.role}
                      </div>
                    </div>
                    {isMe ? <Pill tone="success" withDot>You</Pill> : <Pill tone="neutral">Available</Pill>}
                  </button>
                );
              })}
            </div>

            <div className="ops-section-label" style={{ marginBottom: 8 }}>When</div>
            {selected.confirmedVisitAt ? (
              <div style={{
                marginBottom: 16,
                padding: 12,
                borderRadius: 10,
                background: "var(--cream)",
                border: "1px solid var(--neutral-200)",
                display: "flex",
                alignItems: "center",
                gap: 10,
              }}>
                <Icon name="lock" size={14} stroke={2} color="var(--text-muted)" />
                <div style={{ flex: 1, fontSize: 12.5, color: "var(--text)", lineHeight: 1.4 }}>
                  <strong style={{ color: "var(--indigo)" }}>
                    {new Date(selected.confirmedVisitAt).toLocaleString(undefined, {
                      weekday: "short",
                      month: "short",
                      day: "numeric",
                      hour: "numeric",
                      minute: "2-digit",
                    })}
                  </strong>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>
                    Locked to homeowner's accepted time. Use Propose new time to change it.
                  </div>
                </div>
              </div>
            ) : (
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 16 }}>
                <input type="date" value={routeDate} onChange={(e) => setRouteDate(e.target.value)} style={selectInputStyle} />
                <select value={windowSlot} onChange={(e) => setWindowSlot(e.target.value)} style={selectInputStyle}>
                  <option value="9-11">9 AM – 11 AM</option>
                  <option value="11-13">11 AM – 1 PM</option>
                  <option value="13-15">1 PM – 3 PM</option>
                  <option value="15-17">3 PM – 5 PM</option>
                </select>
              </div>
            )}
          </>
        ) : (
          <EmptyState
            icon="dispatch"
            title={unassigned.length === 0 ? "Nothing to dispatch" : "Pick a job"}
            body={unassigned.length === 0 ? "When a new visit lands in the unassigned queue, you can route it from here." : "Tap an unassigned visit on the left to route it to a technician."}
          />
        )}
      </Card>
      </div>
    </div>
  );
}

function UnassignedCard({ visit, isSelected, onClick }: { visit: VisitRow; isSelected: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="ops-card is-padded-tight is-hoverable"
      style={{
        textAlign: "left",
        background: isSelected ? "var(--salmon-50)" : "#fff",
        borderLeft: isSelected ? "3px solid var(--salmon)" : "1px solid var(--neutral-200)",
        cursor: "pointer",
      }}
    >
      <div style={{ display: "flex", gap: 6, marginBottom: 6, alignItems: "center", flexWrap: "wrap" }}>
        <Pill tone={requestStatusTone(visit.status)}>{visit.statusLabel}</Pill>
        <span style={{ marginLeft: "auto", fontSize: 11, color: "var(--text-soft)" }}>{formatRelativeTime(visit.updatedAt)}</span>
      </div>
      <div style={{ fontSize: 13.5, fontWeight: 600, color: "var(--text)", marginBottom: 4 }}>{visit.title}</div>
      <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
        {visit.property?.name || "Not set"}
      </div>
    </button>
  );
}

const selectInputStyle: React.CSSProperties = {
  height: 36,
  padding: "0 10px",
  border: "1px solid var(--neutral-200)",
  borderRadius: 10,
  background: "#fff",
  fontSize: 13,
  color: "var(--text)",
  fontFamily: "var(--sans)",
};

function parseWindow(slot: string): [string, string] {
  const [s, e] = slot.split("-").map(Number);
  return [`${String(s).padStart(2, "0")}:00`, `${String(e).padStart(2, "0")}:00`];
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
