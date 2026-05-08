import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatTime12h, postProviderAction } from "../lib/api";
import type { VisitRow } from "../lib/types";

export default function CalendarScreen() {
  const { dashboard, refresh } = useWorkspace();
  const [cursor, setCursor] = useState(() => new Date());
  const [techFilter, setTechFilter] = useState<Set<string>>(new Set());
  // Wave Z.1 — drag-to-reschedule state. Holds the requestId of the
  // visit currently being dragged so we can update it on drop. Also
  // tracks the cell currently under the cursor so we can paint a
  // soft target highlight.
  const [draggingRequestId, setDraggingRequestId] = useState<string | null>(null);
  const [dropTargetIso, setDropTargetIso] = useState<string | null>(null);
  // Optimistic-overrides map: requestId → newIso. Keeps the chip on the
  // dropped day instantly while the network round-trip resolves; on
  // error we delete the override and revert to the real data.
  const [optimisticDates, setOptimisticDates] = useState<Map<string, string>>(new Map());
  const [rescheduleError, setRescheduleError] = useState<string | null>(null);

  const cells = useMemo(() => buildMonthGrid(cursor), [cursor]);

  // Group filtered visits by ISO date (yyyy-MM-dd) so the cell render is O(1).
  // Wave Z.1 layers an optimistic-overrides map on top so the chip
  // appears on the dropped day immediately before the network resolves.
  const visitsByDate = useMemo(() => {
    const map = new Map<string, VisitRow[]>();
    if (!dashboard) return map;
    const filterActive = techFilter.size > 0;
    dashboard.visits.forEach((v) => {
      if (filterActive) {
        const memberId = v.assignment?.memberId;
        if (!memberId || !techFilter.has(memberId)) return;
      }
      const overrideDay = optimisticDates.get(v.requestId);
      const day =
        overrideDay ?? (v.routeDate || v.visit?.scheduledDate || "").slice(0, 10);
      if (!day) return;
      const arr = map.get(day) ?? [];
      arr.push(v);
      map.set(day, arr);
    });
    return map;
  }, [dashboard, techFilter, optimisticDates]);

  if (!dashboard) return null;

  const totalVisits = dashboard.visits.filter((v) =>
    !["cancelled", "declined"].includes(v.status)
  ).length;

  const toggleTech = (memberId: string) => {
    setTechFilter((prev) => {
      const next = new Set(prev);
      if (next.has(memberId)) next.delete(memberId);
      else next.add(memberId);
      return next;
    });
  };

  // Wave Z.1 — drop handler. Confirmed visits get a confirm dialog
  // (per the brief: only confirm if the visit is already confirmed,
  // not for unconfirmed/draft). The optimistic update lands first so
  // the chip is on the new day instantly; we revert + alert on error.
  async function handleDrop(visit: VisitRow, targetIso: string) {
    setDropTargetIso(null);
    setDraggingRequestId(null);
    if (!dashboard) return;

    const currentIso = (visit.routeDate || visit.visit?.scheduledDate || "").slice(0, 10);
    if (currentIso === targetIso) return; // no-op

    const isConfirmed = Boolean(visit.confirmedVisitAt);
    if (isConfirmed) {
      const targetLabel = new Date(`${targetIso}T12:00:00`).toLocaleDateString(undefined, {
        weekday: "short",
        month: "short",
        day: "numeric",
      });
      if (!confirm(`Move ${visit.title} to ${targetLabel}? The homeowner will be notified.`)) {
        return;
      }
    }

    // Optimistic local override.
    setOptimisticDates((prev) => {
      const next = new Map(prev);
      next.set(visit.requestId, targetIso);
      return next;
    });

    try {
      await postProviderAction("reschedule_visit", {
        workspaceId: dashboard.workspace.id,
        requestId: visit.requestId,
        newRouteDate: targetIso,
      });
      await refresh();
      // Clear the override now that the dashboard has the new truth.
      setOptimisticDates((prev) => {
        const next = new Map(prev);
        next.delete(visit.requestId);
        return next;
      });
    } catch (e) {
      // Revert.
      setOptimisticDates((prev) => {
        const next = new Map(prev);
        next.delete(visit.requestId);
        return next;
      });
      setRescheduleError(e instanceof Error ? e.message : "Couldn't reschedule the visit.");
      // Auto-clear the banner.
      setTimeout(() => setRescheduleError(null), 4500);
    }
  }

  return (
    <Card padding="default">
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16, flexWrap: "wrap" }}>
        <button className="ops-button ops-button--ghost" style={{ height: 32, padding: "4px 10px" }} aria-label="Previous"
          onClick={() => setCursor((d) => addMonths(d, -1))}>
          <Icon name="chevron" size={14} stroke={2} style={{ transform: "rotate(180deg)" }} />
        </button>
        <button className="ops-button ops-button--ghost" style={{ height: 32, padding: "4px 12px" }} onClick={() => setCursor(new Date())}>
          Today
        </button>
        <button className="ops-button ops-button--ghost" style={{ height: 32, padding: "4px 10px" }} aria-label="Next"
          onClick={() => setCursor((d) => addMonths(d, 1))}>
          <Icon name="chevron" size={14} stroke={2} />
        </button>
        <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", marginLeft: 8 }}>
          {cursor.toLocaleDateString(undefined, { month: "long", year: "numeric" })}
        </div>
        <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap" }}>
          {techFilter.size > 0 && (
            <button
              className="ops-button ops-button--ghost"
              style={{ height: 28, padding: "2px 10px", fontSize: 11, color: "var(--text-soft)" }}
              onClick={() => setTechFilter(new Set())}
            >
              Clear filter
            </button>
          )}
          {dashboard.teamMembers.filter((m) => m.status === "active").map((tech) => {
            const isActive = techFilter.has(tech.id);
            const filterEmpty = techFilter.size === 0;
            return (
              <button
                key={tech.id}
                className="ops-button ops-button--ghost"
                aria-pressed={isActive}
                style={{
                  height: 28,
                  padding: "2px 10px 2px 4px",
                  fontSize: 11,
                  gap: 4,
                  background: isActive ? "var(--indigo)" : "transparent",
                  color: isActive ? "#fff" : "var(--text-muted)",
                  opacity: filterEmpty || isActive ? 1 : 0.55,
                }}
                onClick={() => toggleTech(tech.id)}
              >
                <Avatar initials={initialsFor(tech.fullName || tech.email)} size={22} fontSize={9} />
                {(tech.fullName || tech.email).split(" ")[0]}
              </button>
            );
          })}
        </div>
      </div>

      {rescheduleError && (
        <div
          role="alert"
          style={{
            background: "var(--critical-50, #FEF2F2)",
            border: "1px solid var(--critical, #DC2626)",
            color: "var(--critical, #DC2626)",
            borderRadius: 8,
            padding: "8px 12px",
            marginBottom: 12,
            fontSize: 13,
          }}
        >
          {rescheduleError}
        </div>
      )}

      {totalVisits === 0 ? (
        <EmptyState
          icon="calendar"
          title="No visits booked yet"
          body="When you assign visits from Dispatch they'll show up on the calendar here."
        />
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(7, 1fr)", gap: 1, background: "var(--neutral-200)", borderRadius: 12, overflow: "hidden" }}>
          {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((d) => (
            <div key={d} style={{ padding: "8px 12px", background: "#fff", fontSize: 11, fontWeight: 600, letterSpacing: "0.08em", color: "var(--text-soft)", textTransform: "uppercase" }}>
              {d}
            </div>
          ))}
          {cells.map((cell, i) => {
            const isCellToday = cell.iso === isoDate(new Date());
            const dayVisits = visitsByDate.get(cell.iso) ?? [];
            const isDropTarget = dropTargetIso === cell.iso && draggingRequestId !== null;
            const draggingVisit = draggingRequestId
              ? dashboard.visits.find((v) => v.requestId === draggingRequestId)
              : null;
            // The drop target gets a soft salmon outline only when the
            // chip would actually move (different day from current).
            const draggingCurrentIso = draggingVisit
              ? optimisticDates.get(draggingVisit.requestId) ??
                (draggingVisit.routeDate || draggingVisit.visit?.scheduledDate || "").slice(0, 10)
              : null;
            const isValidDropTarget = isDropTarget && draggingCurrentIso !== cell.iso;
            return (
              <div
                key={i}
                onDragOver={(e) => {
                  if (draggingRequestId) {
                    e.preventDefault();
                    setDropTargetIso(cell.iso);
                  }
                }}
                onDragLeave={() => {
                  if (dropTargetIso === cell.iso) setDropTargetIso(null);
                }}
                onDrop={(e) => {
                  e.preventDefault();
                  const reqId = e.dataTransfer.getData("text/plain");
                  if (!reqId) return;
                  const visit = dashboard.visits.find((v) => v.requestId === reqId);
                  if (visit) void handleDrop(visit, cell.iso);
                }}
                style={{
                  background: isValidDropTarget
                    ? "var(--salmon-50)"
                    : isCellToday
                      ? "var(--salmon-50)"
                      : "#fff",
                  outline: isValidDropTarget ? "2px solid var(--salmon)" : "none",
                  outlineOffset: -2,
                  minHeight: 92,
                  padding: 8,
                  position: "relative",
                  opacity: cell.isCurrentMonth ? 1 : 0.4,
                  transition: "outline 0.12s ease",
                }}
              >
                <div style={{ position: "absolute", top: 6, left: 6 }}>
                  {isCellToday ? (
                    <span style={{ background: "var(--salmon)", color: "#fff", padding: "2px 7px", borderRadius: 8, fontWeight: 700, fontSize: 11 }}>
                      {cell.day}
                    </span>
                  ) : (
                    <span style={{ fontSize: 11, fontWeight: 600, color: "var(--text)" }}>{cell.day}</span>
                  )}
                </div>
                {dayVisits.length > 0 && (
                  <div style={{ marginTop: 24, display: "flex", flexDirection: "column", gap: 3 }}>
                    {dayVisits.slice(0, 3).map((v) => {
                      const isBeingDragged = draggingRequestId === v.requestId;
                      return (
                        <Link
                          key={v.requestId}
                          to={`/visits/${v.requestId}`}
                          draggable={true}
                          onDragStart={(e) => {
                            e.dataTransfer.setData("text/plain", v.requestId);
                            e.dataTransfer.effectAllowed = "move";
                            setDraggingRequestId(v.requestId);
                          }}
                          onDragEnd={() => {
                            setDraggingRequestId(null);
                            setDropTargetIso(null);
                          }}
                          style={{
                            background: "var(--indigo-50)",
                            color: "var(--indigo)",
                            fontSize: 10.5,
                            fontWeight: 600,
                            padding: "2px 6px",
                            borderRadius: 4,
                            whiteSpace: "nowrap",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            textDecoration: "none",
                            cursor: isBeingDragged ? "grabbing" : "grab",
                            display: "block",
                            opacity: isBeingDragged ? 0.4 : 1,
                          }}
                          title={`${v.title} · ${v.property?.name ?? ""} (drag to move)`}
                        >
                          {formatTime12h(v.assignment?.windowStartTime || "")} {v.title}
                        </Link>
                      );
                    })}
                    {dayVisits.length > 3 && (
                      <div style={{ position: "absolute", top: 6, right: 6, fontSize: 10, color: "var(--text-soft)", fontWeight: 600 }}>
                        +{dayVisits.length - 3}
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </Card>
  );
}

function buildMonthGrid(cursor: Date): { day: number; iso: string; isCurrentMonth: boolean }[] {
  const year = cursor.getFullYear();
  const month = cursor.getMonth();
  const firstOfMonth = new Date(year, month, 1);
  const startWeekday = firstOfMonth.getDay();
  const start = new Date(year, month, 1 - startWeekday);
  const cells = [];
  for (let i = 0; i < 42; i++) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    cells.push({
      day: d.getDate(),
      iso: isoDate(d),
      isCurrentMonth: d.getMonth() === month,
    });
  }
  return cells;
}

function isoDate(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function addMonths(d: Date, n: number): Date {
  const r = new Date(d);
  r.setMonth(r.getMonth() + n);
  return r;
}
