import { useMemo } from "react";
import { Card } from "../components/chrome/Card";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatTime12h, isToday } from "../lib/api";
import type { VisitRow } from "../lib/types";

export default function RoutesScreen() {
  const { dashboard, mode } = useWorkspace();

  const today = new Date().toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" });

  // Group today's assigned visits by tech (member)
  const routes = useMemo(() => {
    if (!dashboard) return [];
    const grouped = new Map<string, { memberId: string; memberName: string; visits: VisitRow[] }>();
    dashboard.visits
      .filter((v) => isToday(v.routeDate) && v.assignment)
      .sort((a, b) => (a.assignment?.stopOrder ?? 99) - (b.assignment?.stopOrder ?? 99))
      .forEach((v) => {
        const memberId = v.assignment!.memberId;
        if (!grouped.has(memberId)) {
          grouped.set(memberId, {
            memberId,
            memberName: v.assignment!.memberName,
            visits: [],
          });
        }
        grouped.get(memberId)!.visits.push(v);
      });
    return Array.from(grouped.values());
  }, [dashboard]);

  if (!dashboard) return null;

  return (
    <>
      <div className="ops-page-toolbar">
        <button className="ops-button ops-button--ghost" style={{ height: 32 }}>
          <Icon name="chevron" size={14} stroke={2} style={{ transform: "rotate(180deg)" }} />
        </button>
        <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600 }}>Today · {today}</div>
        <button className="ops-button ops-button--ghost" style={{ height: 32 }}>
          <Icon name="chevron" size={14} stroke={2} />
        </button>
        {routes.length > 1 && (
          <div style={{ marginLeft: "auto" }}>
            <button className="ops-button ops-button--indigo">
              <Icon name="sparkles" size={14} stroke={1.9} />
              Optimize all routes
            </button>
          </div>
        )}
      </div>

      {routes.length === 0 ? (
        <EmptyState
          icon="route"
          title={mode === "sole" ? "No stops on your route today" : "Nothing routed today"}
          body={mode === "sole" ? "Assign yourself a visit from Dispatch and your route will build itself here." : "Once your team has visits scheduled for today, their routes show up as a side-by-side board."}
        />
      ) : (
        <div className="ops-grid-3col">
          {routes.map((route) => {
            const totalDriveMin = route.visits.length * 12; // crude estimate
            const totalMin = route.visits.reduce((sum, v) => {
              const start = v.assignment?.windowStartTime;
              const end = v.assignment?.windowEndTime;
              if (!start || !end) return sum + 60;
              return sum + (timeMin(end) - timeMin(start));
            }, 0);
            return (
              <Card key={route.memberId} padding="default">
                <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
                  <Avatar initials={initialsFor(route.memberName)} size={36} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 14, fontWeight: 600 }}>{route.memberName}</div>
                    <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>
                      {route.visits.length} stop{route.visits.length === 1 ? "" : "s"} · {Math.round(totalMin / 60)}h {totalMin % 60}m on site · ~{totalDriveMin}m drive
                    </div>
                  </div>
                </div>

                {/* Mini map preview — schematic, not from a real routing engine */}
                <div
                  style={{
                    height: 130,
                    borderRadius: 12,
                    background: "linear-gradient(135deg, #E8E4F2, #F2EFF8 50%, #FFE8E2)",
                    position: "relative",
                    marginBottom: 14,
                    overflow: "hidden",
                  }}
                  aria-hidden="true"
                >
                  <svg viewBox="0 0 240 130" style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}>
                    <path d="M30 30 Q 80 10 120 60 T 210 100" stroke="var(--indigo)" strokeWidth="1.5" fill="none" strokeDasharray="4 4" />
                    {route.visits.slice(0, 4).map((_, i) => {
                      const positions = [
                        { x: 30, y: 30 },
                        { x: 110, y: 50 },
                        { x: 170, y: 75 },
                        { x: 210, y: 100 },
                      ];
                      const p = positions[i] ?? { x: 50, y: 60 };
                      return (
                        <g key={i}>
                          <circle cx={p.x} cy={p.y} r="9" fill="var(--salmon)" />
                          <text x={p.x} y={p.y + 3} textAnchor="middle" fill="#fff" fontSize="10" fontWeight="700">{i + 1}</text>
                        </g>
                      );
                    })}
                  </svg>
                </div>

                <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
                  {route.visits.map((stop, i) => (
                    <div key={stop.requestId} style={{ display: "flex", gap: 12, padding: "10px 0", borderBottom: i < route.visits.length - 1 ? "1px solid var(--neutral-200)" : "none" }}>
                      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", flex: "none" }}>
                        <div style={{ width: 22, height: 22, borderRadius: "50%", background: "var(--salmon-pale)", color: "var(--salmon-dark)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 700 }}>
                          {i + 1}
                        </div>
                        {i < route.visits.length - 1 && <div style={{ width: 1.5, flex: 1, background: "var(--neutral-300)", marginTop: 4, minHeight: 28 }} />}
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{stop.title}</div>
                        <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginBottom: 4 }}>
                          {stop.property?.name || "—"}{stop.property?.address ? ` · ${stop.property.address.split(",")[1]?.trim() ?? ""}` : ""}
                        </div>
                        <div style={{ display: "flex", gap: 12, fontSize: 11, color: "var(--text-soft)" }}>
                          {stop.assignment?.windowStartTime && (
                            <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
                              <Icon name="clock" size={12} stroke={1.9} />
                              {formatTime12h(stop.assignment.windowStartTime)} – {formatTime12h(stop.assignment.windowEndTime)}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </>
  );
}

function timeMin(s: string): number {
  const [h, m] = s.split(":").map(Number);
  return (h ?? 0) * 60 + (m ?? 0);
}
