import { Card } from "../components/chrome/Card";
import { Avatar } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { CREW_DEMO, ROUTES_DEMO } from "../lib/fixtures";

export default function RoutesScreen() {
  const today = new Date().toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" });

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
        <div style={{ marginLeft: "auto" }}>
          <button className="ops-button ops-button--indigo">
            <Icon name="sparkles" size={14} stroke={1.9} />
            Optimize all routes
          </button>
        </div>
      </div>

      <div className="ops-grid-3col">
        {ROUTES_DEMO.map((route) => {
          const tech = CREW_DEMO.find((c) => c.id === route.techId);
          return (
            <Card key={route.techId} padding="default">
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
                {tech && <Avatar initials={tech.avatar} color={tech.color} size={36} />}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{route.name}</div>
                  <div style={{ fontSize: 11.5, color: "var(--text-soft)" }}>{route.summary}</div>
                </div>
                <button style={{ background: "none", border: "none", cursor: "pointer", color: "var(--text-soft)" }} aria-label="More">
                  <Icon name="more" size={16} />
                </button>
              </div>

              {/* Mini map preview */}
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
                  {route.stops.map((s, i) => {
                    const positions = [
                      { x: 30, y: 30 },
                      { x: 110, y: 50 },
                      { x: 170, y: 75 },
                      { x: 210, y: 100 },
                    ];
                    const p = positions[i] ?? { x: 50, y: 60 };
                    return (
                      <g key={s.idx}>
                        <circle cx={p.x} cy={p.y} r="9" fill="var(--salmon)" />
                        <text x={p.x} y={p.y + 3} textAnchor="middle" fill="#fff" fontSize="10" fontWeight="700">{s.idx}</text>
                      </g>
                    );
                  })}
                </svg>
              </div>

              <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
                {route.stops.map((stop, i) => (
                  <div key={stop.idx} style={{ display: "flex", gap: 12, padding: "10px 0", borderBottom: i < route.stops.length - 1 ? "1px solid var(--neutral-200)" : "none" }}>
                    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", flex: "none" }}>
                      <div style={{ width: 22, height: 22, borderRadius: "50%", background: "var(--salmon-pale)", color: "var(--salmon-dark)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 700 }}>
                        {stop.idx}
                      </div>
                      {i < route.stops.length - 1 && <div style={{ width: 1.5, flex: 1, background: "var(--neutral-300)", marginTop: 4, minHeight: 28 }} />}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{stop.title}</div>
                      <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginBottom: 4 }}>{stop.home} · {stop.city}</div>
                      <div style={{ display: "flex", gap: 12, fontSize: 11, color: "var(--text-soft)" }}>
                        <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
                          <Icon name="clock" size={12} stroke={1.9} /> {stop.window}
                        </span>
                        <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
                          <Icon name="truck" size={12} stroke={1.9} /> {stop.drive}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          );
        })}
      </div>
    </>
  );
}
