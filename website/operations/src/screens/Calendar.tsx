import { useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatTime12h } from "../lib/api";
import type { VisitRow } from "../lib/types";

type View = "Day" | "Week" | "Month";

export default function CalendarScreen() {
  const { dashboard } = useWorkspace();
  const [view, setView] = useState<View>("Month");
  const [cursor, setCursor] = useState(() => new Date());

  const cells = useMemo(() => buildMonthGrid(cursor), [cursor]);

  if (!dashboard) return null;

  // Group visits by ISO date (yyyy-MM-dd) so the cell render is O(1)
  const visitsByDate = useMemo(() => {
    const map = new Map<string, VisitRow[]>();
    dashboard.visits.forEach((v) => {
      const day = (v.routeDate || v.visit?.scheduledDate || "").slice(0, 10);
      if (!day) return;
      const arr = map.get(day) ?? [];
      arr.push(v);
      map.set(day, arr);
    });
    return map;
  }, [dashboard]);

  const totalVisits = dashboard.visits.filter((v) =>
    !["cancelled", "declined"].includes(v.status)
  ).length;

  return (
    <Card padding="default">
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
        <div style={{ display: "flex", gap: 4, background: "var(--neutral-200)", padding: 3, borderRadius: 9 }}>
          {(["Day", "Week", "Month"] as const).map((v) => (
            <button
              key={v}
              className="ops-page-toolbar__seg-button"
              style={{
                background: view === v ? "var(--indigo)" : "transparent",
                color: view === v ? "#fff" : "var(--text-muted)",
              }}
              onClick={() => setView(v)}
            >
              {v}
            </button>
          ))}
        </div>
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
        <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 6 }}>
          {dashboard.teamMembers.filter((m) => m.status === "active").map((tech) => (
            <button
              key={tech.id}
              className="ops-button ops-button--ghost"
              style={{ height: 28, padding: "2px 10px 2px 4px", fontSize: 11, gap: 4 }}
            >
              <Avatar initials={initialsFor(tech.fullName || tech.email)} size={22} fontSize={9} />
              {(tech.fullName || tech.email).split(" ")[0]}
            </button>
          ))}
        </div>
      </div>

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
            return (
              <div
                key={i}
                style={{
                  background: isCellToday ? "var(--salmon-50)" : "#fff",
                  minHeight: 92,
                  padding: 8,
                  position: "relative",
                  opacity: cell.isCurrentMonth ? 1 : 0.4,
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
                    {dayVisits.slice(0, 3).map((v) => (
                      <div
                        key={v.requestId}
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
                        }}
                        title={`${v.title} · ${v.property?.name ?? ""}`}
                      >
                        {formatTime12h(v.assignment?.windowStartTime || "")} {v.title}
                      </div>
                    ))}
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
