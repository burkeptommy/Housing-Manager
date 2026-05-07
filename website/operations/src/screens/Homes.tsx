import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, formatRelativeTime } from "../lib/api";
import type { HomeRow } from "../lib/types";

export default function HomesScreen() {
  const { dashboard } = useWorkspace();
  const navigate = useNavigate();
  const [filter, setFilter] = useState<"all" | "active" | "new">("all");
  const [search, setSearch] = useState("");
  const [selectedHomeId, setSelectedHomeId] = useState<string | null>(null);

  const homes = useMemo(() => dashboard?.homes ?? [], [dashboard]);

  const filtered = useMemo(() => {
    return homes.filter((h) => {
      if (filter === "active" && h.openRequests === 0) return false;
      if (filter === "new") {
        // "New" heuristic: no completed visits yet
        if (h.lastCompletedVisit) return false;
      }
      if (search && !`${h.name} ${h.address}`.toLowerCase().includes(search.toLowerCase())) return false;
      return true;
    });
  }, [homes, filter, search]);

  const selectedHome = useMemo(() => {
    if (selectedHomeId) return homes.find((h) => h.propertyId === selectedHomeId) ?? null;
    return filtered[0] ?? null;
  }, [selectedHomeId, homes, filtered]);

  const historyForHome = useMemo(() => {
    if (!dashboard || !selectedHome) return [];
    return dashboard.visits
      .filter((v) => v.property?.id === selectedHome.propertyId)
      .sort((a, b) => String(b.updatedAt).localeCompare(String(a.updatedAt)));
  }, [dashboard, selectedHome]);

  if (!dashboard) return null;

  if (homes.length === 0) {
    return (
      <EmptyState
        icon="home"
        title="No homes on your books yet"
        body="When a homeowner requests a visit from you, their home shows up here. Share your Chez Contractor handle so customers can find you."
      />
    );
  }

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
              {f === "all" ? `All · ${homes.length}` : f === "active" ? "Active" : "New"}
            </button>
          ))}
        </div>
      </div>

      <div className="ops-grid-3col" style={{ marginBottom: 24 }}>
        {filtered.map((home) => (
          <Card
            key={home.propertyId}
            padding="default"
            hoverable
            onClick={() => navigate(`/homes/${home.propertyId}`)}
            style={selectedHome?.propertyId === home.propertyId ? { borderColor: "var(--indigo-400)", boxShadow: "0 6px 20px rgba(42,34,82,0.12)" } : {}}
          >
            <HomeArtwork isNew={!home.lastCompletedVisit} />
            <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600, color: "var(--text)" }}>{home.name}</div>
            <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 12 }}>{home.address || "—"}</div>

            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 8, marginBottom: 14 }}>
              <Stat label="Systems" value={String(home.systemCount)} />
              <Stat label="Open" value={String(home.openRequests)} accent={home.openRequests > 0} />
              <Stat label="Visits" value={String(historyCount(dashboard.visits, home.propertyId))} />
            </div>

            <div style={{ display: "flex", gap: 8 }}>
              <button
                className="ops-button ops-button--ghost"
                style={{ flex: 1, fontSize: 12 }}
                onClick={(e) => { e.stopPropagation(); setSelectedHomeId(home.propertyId); }}
              >
                Quick history
              </button>
              <button
                className="ops-button ops-button--indigo"
                style={{ flex: 1, fontSize: 12 }}
                onClick={(e) => { e.stopPropagation(); navigate(`/homes/${home.propertyId}`); }}
              >
                Open profile →
              </button>
            </div>
          </Card>
        ))}
      </div>

      {selectedHome && (
        <Card padding="default">
          <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
            <div className="ops-section-label">Service history · {selectedHome.name}</div>
          </div>
          {historyForHome.length === 0 ? (
            <div style={{ padding: "16px 0", fontSize: 13, color: "var(--text-muted)" }}>
              No visits logged yet for this home.
            </div>
          ) : (
            <div>
              {historyForHome.map((row) => (
                <div key={row.requestId} className="ops-row" style={{ padding: "12px 0" }}>
                  <div style={{ width: 80, fontSize: 12, color: "var(--text-soft)", fontWeight: 600 }}>
                    {row.routeDate ? new Date(row.routeDate).toLocaleDateString(undefined, { month: "short", day: "numeric" }) : "—"}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{row.title}</div>
                    <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{row.statusLabel}</div>
                  </div>
                  {row.assignment && (
                    <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                      <Avatar initials={initialsFor(row.assignment.memberName)} size={26} fontSize={10} />
                      <span style={{ fontSize: 12, color: "var(--text)" }}>{row.assignment.memberName.split(" ")[0]}</span>
                    </div>
                  )}
                  <Pill tone={row.status === "completed" ? "success" : "indigo"}>{row.statusLabel}</Pill>
                  {row.quote && (
                    <div style={{ fontFamily: "var(--serif)", fontSize: 14, fontWeight: 600, color: "var(--indigo)", width: 80, textAlign: "right" }}>
                      {formatCurrency(row.quote.total)}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </Card>
      )}
    </>
  );
}

function HomeArtwork({ isNew }: { isNew: boolean }) {
  return (
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
      {isNew && (
        <span style={{ position: "absolute", top: 10, right: 10, background: "var(--salmon)", color: "#fff", fontSize: 10, fontWeight: 700, letterSpacing: "0.08em", padding: "3px 8px", borderRadius: 6 }}>
          NEW
        </span>
      )}
    </div>
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

function historyCount(visits: { property: { id: string } | null }[], propertyId: string): number {
  return visits.filter((v) => v.property?.id === propertyId).length;
}
