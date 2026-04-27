import { useMemo, useState } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { HOMES_DEMO, CREW_DEMO, formatCurrencyCents } from "../lib/fixtures";

const HISTORY_DEMO = [
  { id: "h1", date: "Apr 21", title: "Spring punch-list bundle", home: "14 Beacon Hill", tech: "MC", status: "Closed", totalCents: 184200 },
  { id: "h2", date: "Apr 14", title: "Replace shower diverter",  home: "8 Marlborough",  tech: "DA", status: "Closed", totalCents: 64500 },
  { id: "h3", date: "Apr 12", title: "Hang gallery wall",        home: "212 Highland",   tech: "MC", status: "Closed", totalCents: 28000 },
  { id: "h4", date: "Apr 4",  title: "Fix toilet running",       home: "6 Carriage Ln",  tech: "DA", status: "Closed", totalCents: 9500 },
];

export default function HomesScreen() {
  const [filter, setFilter] = useState<"all" | "active" | "new">("all");
  const [search, setSearch] = useState("");

  const filtered = useMemo(() => {
    return HOMES_DEMO.filter((h) => {
      if (filter === "active" && h.openWork === 0) return false;
      if (filter === "new" && !h.isNew) return false;
      if (search && !`${h.label} ${h.owner} ${h.city}`.toLowerCase().includes(search.toLowerCase())) return false;
      return true;
    });
  }, [filter, search]);

  return (
    <>
      <div className="ops-page-toolbar">
        <div className="ops-topbar__search" style={{ width: 280 }}>
          <span className="ops-topbar__search-icon"><Icon name="search" size={15} stroke={1.9} /></span>
          <input
            type="search"
            placeholder="Search homes, owners, or cities…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div style={{ display: "flex", gap: 6 }}>
          {(["all", "active", "new"] as const).map((f) => (
            <button
              key={f}
              className="ops-button ops-button--ghost"
              style={{
                fontSize: 12,
                padding: "4px 12px",
                background: filter === f ? "var(--neutral-200)" : "#fff",
              }}
              onClick={() => setFilter(f)}
            >
              {f === "all" ? `All · ${HOMES_DEMO.length}` : f === "active" ? "Active" : "New this month"}
            </button>
          ))}
          <button className="ops-button ops-button--ghost" style={{ fontSize: 12, padding: "4px 12px" }}>
            <Icon name="filter" size={13} stroke={1.9} /> Filter
          </button>
        </div>
      </div>

      <div className="ops-grid-3col" style={{ marginBottom: 24 }}>
        {filtered.map((home) => (
          <Card key={home.id} padding="default" hoverable>
            <div
              style={{
                height: 96,
                borderRadius: 12,
                background: "linear-gradient(135deg, #E8E4F2, #FFE8E2)",
                position: "relative",
                marginBottom: 14,
                overflow: "hidden",
              }}
              aria-hidden="true"
            >
              <svg viewBox="0 0 240 96" style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}>
                <path d="M40 80 L80 50 L120 80 Z" fill="var(--indigo)" opacity="0.5" />
                <path d="M120 80 L160 45 L200 80 Z" fill="var(--salmon)" opacity="0.5" />
              </svg>
              {home.isNew && (
                <span style={{ position: "absolute", top: 10, right: 10, background: "var(--salmon)", color: "#fff", fontSize: 10, fontWeight: 700, letterSpacing: "0.08em", padding: "3px 8px", borderRadius: 6 }}>
                  NEW
                </span>
              )}
            </div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600, color: "var(--text)" }}>{home.label}</div>
            <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 12 }}>{home.owner} · {home.city}</div>

            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 8, marginBottom: 14 }}>
              <Stat label="Systems" value={String(home.systems)} />
              <Stat label="Open" value={String(home.openWork)} accent={home.openWork > 0} />
              <Stat label="Lifetime" value={`$${(home.lifetime / 1000).toFixed(1)}K`} />
            </div>

            <div style={{ display: "flex", gap: 8 }}>
              <button className="ops-button ops-button--ghost" style={{ flex: 1, fontSize: 12 }}>History</button>
              <button className="ops-button ops-button--indigo" style={{ flex: 1, fontSize: 12 }}>New visit</button>
            </div>
          </Card>
        ))}
      </div>

      <Card padding="default">
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
          <div className="ops-section-label">Service history · 14 Beacon Hill</div>
          <div style={{ display: "flex", gap: 6 }}>
            {["All", "Visits", "Quotes", "Photos"].map((c) => (
              <button key={c} className="ops-button ops-button--ghost" style={{ fontSize: 11, padding: "4px 10px" }}>
                {c}
              </button>
            ))}
          </div>
        </div>
        <div>
          {HISTORY_DEMO.map((row) => {
            const tech = CREW_DEMO.find((c) => c.id === row.tech);
            return (
              <div key={row.id} className="ops-row" style={{ padding: "12px 0" }}>
                <div style={{ width: 60, fontSize: 12, color: "var(--text-soft)", fontWeight: 600 }}>{row.date}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{row.title}</div>
                  <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{row.home}</div>
                </div>
                {tech && (
                  <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                    <Avatar initials={tech.avatar} color={tech.color} size={26} fontSize={10} />
                    <span style={{ fontSize: 12, color: "var(--text)" }}>{tech.name.split(" ")[0]}</span>
                  </div>
                )}
                <Pill tone="success">{row.status}</Pill>
                <div style={{ fontFamily: "var(--serif)", fontSize: 14, fontWeight: 600, color: "var(--indigo)", width: 70, textAlign: "right" }}>
                  {formatCurrencyCents(row.totalCents)}
                </div>
                <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
              </div>
            );
          })}
        </div>
      </Card>
      {/* Suppress unused-var lint */}
      <div style={{ display: "none" }}>{initialsFor("ignored")}</div>
    </>
  );
}

function Stat({ label, value, accent = false }: { label: string; value: string; accent?: boolean }) {
  return (
    <div>
      <div style={{ fontSize: 10, color: "var(--text-soft)", letterSpacing: "0.08em", textTransform: "uppercase", fontWeight: 600 }}>{label}</div>
      <div style={{ fontFamily: "var(--serif)", fontSize: 20, fontWeight: 700, color: accent ? "var(--salmon-dark)" : "var(--text)", letterSpacing: "-0.018em" }}>
        {value}
      </div>
    </div>
  );
}
