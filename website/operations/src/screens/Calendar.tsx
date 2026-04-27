import { useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Avatar } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { CREW_DEMO, VISITS_DEMO } from "../lib/fixtures";

type View = "Day" | "Week" | "Month";

export default function CalendarScreen() {
  const [view, setView] = useState<View>("Month");
  const today = new Date();

  const cells = useMemo(() => buildMonthGrid(today), [today]);

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
        <button className="ops-button ops-button--ghost" style={{ height: 32, padding: "4px 10px" }} aria-label="Previous">
          <Icon name="chevron" size={14} stroke={2} style={{ transform: "rotate(180deg)" }} />
        </button>
        <button className="ops-button ops-button--ghost" style={{ height: 32, padding: "4px 12px" }}>Today</button>
        <button className="ops-button ops-button--ghost" style={{ height: 32, padding: "4px 10px" }} aria-label="Next">
          <Icon name="chevron" size={14} stroke={2} />
        </button>
        <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", marginLeft: 8 }}>
          {today.toLocaleDateString(undefined, { month: "long", year: "numeric" })}
        </div>
        <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 6 }}>
          {CREW_DEMO.filter((c) => !c.desk).map((tech) => (
            <button
              key={tech.id}
              className="ops-button ops-button--ghost"
              style={{ height: 28, padding: "2px 10px 2px 4px", fontSize: 11, gap: 4 }}
            >
              <Avatar initials={tech.avatar} color={tech.color} size={22} fontSize={9} />
              {tech.name.split(" ")[0]}
            </button>
          ))}
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(7, 1fr)", gap: 1, background: "var(--neutral-200)", borderRadius: 12, overflow: "hidden" }}>
        {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((d) => (
          <div key={d} style={{ padding: "8px 12px", background: "#fff", fontSize: 11, fontWeight: 600, letterSpacing: "0.08em", color: "var(--text-soft)", textTransform: "uppercase" }}>
            {d}
          </div>
        ))}
        {cells.map((cell, i) => {
          const isToday = cell.iso === isoDate(today);
          return (
            <div
              key={i}
              style={{
                background: isToday ? "var(--salmon-50)" : "#fff",
                minHeight: 92,
                padding: 8,
                position: "relative",
                opacity: cell.isCurrentMonth ? 1 : 0.4,
              }}
            >
              <div style={{ position: "absolute", top: 6, left: 6 }}>
                {isToday ? (
                  <span style={{ background: "var(--salmon)", color: "#fff", padding: "2px 7px", borderRadius: 8, fontWeight: 700, fontSize: 11 }}>
                    {cell.day}
                  </span>
                ) : (
                  <span style={{ fontSize: 11, fontWeight: 600, color: "var(--text)" }}>{cell.day}</span>
                )}
              </div>
              {isToday && (
                <div style={{ marginTop: 24, display: "flex", flexDirection: "column", gap: 3 }}>
                  {VISITS_DEMO.slice(0, 3).map((v) => (
                    <div
                      key={v.id}
                      style={{
                        background: v.priority === "high" ? "var(--salmon-pale)" : "var(--indigo-50)",
                        color: v.priority === "high" ? "var(--salmon-dark)" : "var(--indigo)",
                        fontSize: 10.5,
                        fontWeight: 600,
                        padding: "2px 6px",
                        borderRadius: 4,
                        whiteSpace: "nowrap",
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                      }}
                    >
                      {v.time.split(" ")[0]} {v.title}
                    </div>
                  ))}
                  {VISITS_DEMO.length > 3 && (
                    <div style={{ position: "absolute", top: 6, right: 6, fontSize: 10, color: "var(--text-soft)", fontWeight: 600 }}>
                      +{VISITS_DEMO.length - 3}
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </Card>
  );
}

function buildMonthGrid(today: Date): { day: number; iso: string; isCurrentMonth: boolean }[] {
  const year = today.getFullYear();
  const month = today.getMonth();
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
