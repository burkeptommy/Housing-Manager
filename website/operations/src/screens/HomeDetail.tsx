import { useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, formatRelativeTime, postProviderAction } from "../lib/api";
import type { HomeSystem, HomeSystemPhoto, RequestStatus } from "../lib/types";

export default function HomeDetailScreen() {
  const { propertyId } = useParams<{ propertyId: string }>();
  const { dashboard, refresh } = useWorkspace();
  const navigate = useNavigate();
  const [showSuggest, setShowSuggest] = useState(false);
  const [suggestTitle, setSuggestTitle] = useState("");
  const [suggestDetails, setSuggestDetails] = useState("");
  const [suggestType, setSuggestType] = useState("standard_visit");
  const [suggestSubmitting, setSuggestSubmitting] = useState(false);
  const [editingSystem, setEditingSystem] = useState<HomeSystem | null>(null);

  const home = useMemo(() => {
    if (!dashboard || !propertyId) return null;
    return dashboard.homes.find((h) => h.propertyId === propertyId) ?? null;
  }, [dashboard, propertyId]);

  const visits = useMemo(() => {
    if (!dashboard || !home) return [];
    return dashboard.visits.filter((v) => v.property?.id === home.propertyId);
  }, [dashboard, home]);

  const openVisits = visits.filter((v) => !["completed", "cancelled", "declined"].includes(v.status));
  const completedVisits = visits.filter((v) => v.status === "completed");
  const lifetime = visits.reduce((sum, v) => sum + (v.quote?.total ?? 0), 0);
  const recentSuggestions = visits.filter((v) => v.requestType !== "standard_visit");

  const aiSuggestions = useMemo(() => generateAISuggestions(home, visits), [home, visits]);

  if (!dashboard) return null;
  if (!home) {
    return (
      <Card padding="default">
        <div style={{ padding: 32, textAlign: "center" }}>
          <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600, marginBottom: 8 }}>
            Home not found
          </div>
          <button className="ops-button ops-button--ghost" onClick={() => navigate("/homes")}>
            ← Back to Homes
          </button>
        </div>
      </Card>
    );
  }

  async function handleSuggestSubmit() {
    if (!suggestTitle.trim() || !home) return;
    setSuggestSubmitting(true);
    try {
      await postProviderAction("create_ad_hoc_visit", {
        workspaceId: dashboard!.workspace.id,
        propertyId: home.propertyId,
        title: suggestTitle.trim(),
        details: suggestDetails.trim(),
        requestType: suggestType,
        scheduledDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
        priority: "Medium",
      });
      setSuggestTitle("");
      setSuggestDetails("");
      setShowSuggest(false);
      await refresh();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't suggest task.");
    } finally {
      setSuggestSubmitting(false);
    }
  }

  return (
    <>
      <div style={{ marginBottom: 16, display: "flex", gap: 8, alignItems: "center", fontSize: 13 }}>
        <Link to="/homes" style={{ color: "var(--text-soft)", textDecoration: "none" }}>← Homes</Link>
      </div>

      {/* Header */}
      <Card padding="default" style={{ marginBottom: 24 }}>
        <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
          <Avatar initials={initialsFor(home.name)} size={56} fontSize={20} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: "var(--serif)", fontSize: 26, fontWeight: 600, color: "var(--text)", letterSpacing: "-0.018em" }}>
              {home.name}
            </div>
            <div style={{ fontSize: 13, color: "var(--text-muted)" }}>{home.address || "No address on file"}</div>
          </div>
          <button className="ops-button ops-button--salmon" onClick={() => setShowSuggest(true)}>
            <Icon name="sparkles" size={14} stroke={1.9} />
            Suggest a task
          </button>
          <button className="ops-button ops-button--ghost">+ New quote</button>
          <button className="ops-button ops-button--ghost">Message</button>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12, marginTop: 18 }}>
          <Stat label="Systems" value={String(home.systemCount)} />
          <Stat label="Open requests" value={String(home.openRequests)} accent={home.openRequests > 0} />
          <Stat label="Lifetime" value={formatCurrency(lifetime)} />
          <Stat label="Last visit" value={home.lastCompletedVisit ? formatRelativeTime(home.lastCompletedVisit) : "Never"} />
        </div>
      </Card>

      <div style={{ display: "grid", gridTemplateColumns: "1.4fr 1fr", gap: 24, alignItems: "start" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          {/* Systems */}
          <Card padding="default">
            <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
              <div className="ops-section-label">Systems on file ({home.systems?.length ?? 0})</div>
              <span style={{ fontSize: 11, color: "var(--text-soft)" }}>From the homeowner's profile</span>
            </div>
            {!home.systems || home.systems.length === 0 ? (
              <div style={{ padding: 16, fontSize: 13, color: "var(--text-muted)", lineHeight: 1.5 }}>
                No systems registered yet for this home. On your first visit, build the home profile in Chez Field — manufacturer + model + serial syncs back to the homeowner's app automatically.
              </div>
            ) : (
              <CategorizedSystems systems={home.systems} onEditSystem={setEditingSystem} />
            )}
          </Card>

          {editingSystem && (
            <SystemEditSheet
              system={editingSystem}
              onClose={() => setEditingSystem(null)}
              onSaved={async () => {
                setEditingSystem(null);
                await refresh();
              }}
            />
          )}

          {/* AI suggestions */}
          <Card padding="default">
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 12 }}>
              <div className="ops-section-label" style={{ marginBottom: 0 }}>What this home likely needs</div>
              <Pill tone="indigo">Smart suggestions</Pill>
            </div>
            <div style={{ fontSize: 12, color: "var(--text-muted)", marginBottom: 12 }}>
              Generated from the systems you have on file. Tap to suggest as a task.
            </div>
            <div style={{ display: "flex", flexDirection: "column" }}>
              {aiSuggestions.map((s, i) => (
                <button
                  key={i}
                  className="ops-row"
                  style={{ background: "none", border: "none", borderBottom: "1px solid var(--neutral-200)", padding: "10px 0", textAlign: "left", cursor: "pointer", width: "100%" }}
                  onClick={() => {
                    setSuggestTitle(s.title);
                    setSuggestDetails(s.reason);
                    setSuggestType(s.requestType);
                    setShowSuggest(true);
                  }}
                >
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: "var(--salmon-pale)", color: "var(--salmon-dark)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
                    <Icon name={s.icon} size={16} stroke={1.9} />
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{s.title}</div>
                    <div style={{ fontSize: 12, color: "var(--text-muted)" }}>{s.reason}</div>
                  </div>
                  <Pill tone="warning">{s.priority}</Pill>
                  <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
                </button>
              ))}
            </div>
          </Card>

          {/* Visit history */}
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>Visit history ({visits.length})</div>
            {visits.length === 0 ? (
              <div style={{ padding: 12, fontSize: 13, color: "var(--text-muted)" }}>
                No visits to this home yet.
              </div>
            ) : (
              <div style={{ display: "flex", flexDirection: "column" }}>
                {visits.slice(0, 12).map((v) => (
                  <Link
                    key={v.requestId}
                    to={`/visits/${v.requestId}`}
                    className="ops-row"
                    style={{ padding: "12px 0", textDecoration: "none" }}
                  >
                    <div style={{ width: 80, fontSize: 12, color: "var(--text-soft)", fontWeight: 600 }}>
                      {v.routeDate ? new Date(v.routeDate).toLocaleDateString(undefined, { month: "short", day: "numeric" }) : "TBD"}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{v.title}</div>
                      <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
                        {v.assignment?.memberName ?? "Unassigned"}
                      </div>
                    </div>
                    <Pill tone={requestStatusTone(v.status)}>{v.statusLabel}</Pill>
                    {v.quote && (
                      <div style={{ fontFamily: "var(--serif)", fontSize: 13, fontWeight: 600, color: "var(--indigo)", width: 70, textAlign: "right" }}>
                        {formatCurrency(v.quote.total)}
                      </div>
                    )}
                    <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
                  </Link>
                ))}
              </div>
            )}
          </Card>
        </div>

        {/* Right rail */}
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          {/* Follow-ups on past suggestions */}
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>Follow-ups</div>
            {recentSuggestions.length === 0 ? (
              <div style={{ padding: 12, fontSize: 13, color: "var(--text-muted)" }}>
                Tasks you suggest will show here so you can track whether the homeowner accepted.
              </div>
            ) : (
              <div style={{ display: "flex", flexDirection: "column" }}>
                {recentSuggestions.slice(0, 5).map((v) => (
                  <Link key={v.requestId} to={`/visits/${v.requestId}`} className="ops-row" style={{ padding: "10px 0", textDecoration: "none" }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{v.title}</div>
                      <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
                        Suggested {formatRelativeTime(v.updatedAt)}
                      </div>
                    </div>
                    <Pill tone={requestStatusTone(v.status)}>{v.statusLabel}</Pill>
                  </Link>
                ))}
              </div>
            )}
          </Card>

          {/* Open work */}
          {openVisits.length > 0 && (
            <Card padding="default">
              <div className="ops-section-label" style={{ marginBottom: 12 }}>Open work</div>
              <div style={{ display: "flex", flexDirection: "column" }}>
                {openVisits.map((v) => (
                  <Link key={v.requestId} to={`/visits/${v.requestId}`} className="ops-row" style={{ padding: "10px 0", textDecoration: "none" }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{v.title}</div>
                      <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{v.statusLabel}</div>
                    </div>
                    <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
                  </Link>
                ))}
              </div>
            </Card>
          )}

          {/* Snapshot */}
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>Snapshot</div>
            <SidebarStat label="Visits completed" value={String(completedVisits.length)} />
            <SidebarStat label="Open requests" value={String(home.openRequests)} />
            <SidebarStat label="Systems known" value={String(home.systemCount)} />
            <SidebarStat label="Lifetime spend" value={formatCurrency(lifetime)} />
          </Card>
        </div>
      </div>

      {/* Suggest a task modal */}
      {showSuggest && (
        <ModalShell onClose={() => setShowSuggest(false)} title={`Suggest a task for ${home.name}`}>
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <Field label="Title">
              <input
                type="text"
                placeholder="e.g. Replace water heater anode rod"
                value={suggestTitle}
                onChange={(e) => setSuggestTitle(e.target.value)}
                style={inputStyle}
                autoFocus
              />
            </Field>
            <Field label="Why you're suggesting this">
              <textarea
                placeholder="What you noticed, the upside, urgency, expected scope…"
                value={suggestDetails}
                onChange={(e) => setSuggestDetails(e.target.value)}
                style={{ ...inputStyle, minHeight: 90, resize: "vertical" }}
              />
            </Field>
            <Field label="Type">
              <select value={suggestType} onChange={(e) => setSuggestType(e.target.value)} style={inputStyle}>
                <option value="standard_visit">Visit</option>
                <option value="repair">Repair</option>
                <option value="install">Install</option>
                <option value="quote">Quote only</option>
                <option value="question">Just a question</option>
              </select>
            </Field>
            <div style={{ display: "flex", gap: 8, justifyContent: "flex-end", marginTop: 8 }}>
              <button className="ops-button ops-button--ghost" onClick={() => setShowSuggest(false)}>Cancel</button>
              <button
                className="ops-button ops-button--salmon"
                disabled={suggestSubmitting || !suggestTitle.trim()}
                onClick={handleSuggestSubmit}
              >
                {suggestSubmitting ? "Suggesting…" : "Send to homeowner"}
              </button>
            </div>
            <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginTop: 4, lineHeight: 1.4 }}>
              The homeowner gets the suggestion in their Chez app and can approve, decline, or counter with a different time.
            </div>
          </div>
        </ModalShell>
      )}
    </>
  );
}

// ─── Subcomponents ───

function SystemRow({ system, onClick }: { system: HomeSystem; onClick: () => void }) {
  const headline = system.manufacturer || system.modelNumber
    ? `${system.manufacturer ?? ""} ${system.modelNumber ?? ""}`.trim()
    : "Manufacturer unknown";
  return (
    <button
      onClick={onClick}
      className="ops-row"
      style={{
        padding: "10px 0",
        background: "none",
        border: "none",
        cursor: "pointer",
        textAlign: "left",
        width: "100%",
      }}
    >
      <div style={{ width: 32, height: 32, borderRadius: 8, background: "var(--indigo-50)", color: "var(--indigo)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
        <Icon name={iconForCategory(system.category)} size={14} stroke={1.9} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{system.name}</div>
        {headline !== "Manufacturer unknown" && (
          <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>{headline}</div>
        )}
      </div>
      {!system.manufacturer && (
        <Pill tone="warning">Update on next visit</Pill>
      )}
      <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
    </button>
  );
}

// ─── Categorized systems group ────────────────────────────────

// editing-system-id state lives in the parent so the modal can open
// regardless of which group the row belongs to.

/**
 * Groups a flat systems list into 6 collapsible buckets so a 27-system
 * home is scannable at a glance:
 *
 *   • Mechanicals          — HVAC, water heater, plumbing, electrical, generator
 *   • Outdoor & water      — pool/spa, hot tub, irrigation, septic, well, sump pump
 *   • Building envelope    — roofing, crawl space, garage door, driveway, hardscape
 *   • Recurring services   — trash, cleaning, pet waste, snow, mosquito, pest, lawn, window/pressure wash, tree
 *   • Appliances           — washer/dryer/refrigerator/dishwasher
 *   • Safety & security    — security system, smoke/CO, radon
 *   • Other                — anything that didn't bucket
 *
 * Default expansion: groups with ≤4 items expanded; the larger ones
 * collapsed so the section opens scannable, not overwhelming.
 */
function CategorizedSystems({ systems, onEditSystem }: { systems: HomeSystem[]; onEditSystem: (s: HomeSystem) => void }) {
  const groups = useMemo(() => groupSystems(systems), [systems]);
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      {groups.map((group) => (
        <SystemGroup key={group.label} group={group} onEditSystem={onEditSystem} />
      ))}
    </div>
  );
}

interface SystemGroupData {
  label: string;
  count: number;
  defaultExpanded: boolean;
  items: HomeSystem[];
}

function SystemGroup({ group, onEditSystem }: { group: SystemGroupData; onEditSystem: (s: HomeSystem) => void }) {
  const [open, setOpen] = useState(group.defaultExpanded);
  return (
    <div style={{ border: "1px solid var(--neutral-200)", borderRadius: 12, overflow: "hidden" }}>
      <button
        onClick={() => setOpen((v) => !v)}
        style={{
          display: "flex",
          alignItems: "center",
          gap: 10,
          width: "100%",
          padding: "10px 14px",
          background: open ? "var(--pearl)" : "#fff",
          border: "none",
          borderBottom: open ? "1px solid var(--neutral-200)" : "none",
          cursor: "pointer",
          textAlign: "left",
        }}
      >
        <span
          style={{
            fontSize: 10,
            fontWeight: 700,
            letterSpacing: "0.14em",
            textTransform: "uppercase",
            color: "var(--text-soft)",
          }}
        >
          {group.label}
        </span>
        <span style={{ fontSize: 11, fontWeight: 600, color: "var(--text-soft)" }}>· {group.count}</span>
        <span style={{ marginLeft: "auto" }}>
          <Icon
            name="chevronDown"
            size={14}
            color="var(--text-soft)"
            stroke={2}
            style={{ transform: open ? "rotate(0deg)" : "rotate(-90deg)", transition: "transform 150ms" }}
          />
        </span>
      </button>
      {open && (
        <div style={{ padding: "0 14px" }}>
          {group.items.map((s, i) => (
            <div
              key={s.id}
              style={{ borderBottom: i < group.items.length - 1 ? "1px solid var(--neutral-200)" : "none" }}
            >
              <SystemRow system={s} onClick={() => onEditSystem(s)} />
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ─── Categorization rules ────────────────────────────────────

/**
 * Map a HomeSystem.category string (the value the homeowner-side iOS
 * stamps when creating a system) to one of our top-level groups.
 */
function bucketForCategory(category: string): SystemGroupKey {
  const c = (category ?? "").toLowerCase().trim();
  if (!c) return "other";

  // Recurring services first — Tom's explicit callout. These aren't
  // "systems" in the traditional sense; they're vendor relationships
  // that recur on a schedule.
  if (
    c.includes("trash") || c.includes("recycling") || c.includes("garbage") ||
    c.includes("cleaning service") || c.includes("housekeeping") ||
    c.includes("pet waste") ||
    c.includes("snow removal") || c.includes("snow") ||
    c.includes("mosquito") || c.includes("tick") ||
    c.includes("pest") || c.includes("exterminat") ||
    c.includes("lawn care") || c.includes("landscap") ||
    c.includes("window cleaning") || c.includes("pressure washing") || c.includes("power washing") ||
    c.includes("tree service") || c.includes("tree care") ||
    c.includes("gutter cleaning") || c.includes("gutter clean")
  ) return "recurring";

  // Mechanicals
  if (
    c.includes("hvac") || c === "heating" || c === "cooling" || c === "ac" ||
    c.includes("water heater") || c.includes("plumb") ||
    c.includes("electrical") || c === "panel" ||
    c.includes("generator")
  ) return "mechanicals";

  // Outdoor systems + water
  if (
    c.includes("pool") || c.includes("spa") || c.includes("hot tub") ||
    c.includes("irrigation") || c.includes("sprinkler") ||
    c.includes("septic") ||
    c.includes("well") ||
    c.includes("sump")
  ) return "outdoor";

  // Building envelope
  if (
    c.includes("roof") || c.includes("siding") || c.includes("foundation") ||
    c.includes("crawl") || c.includes("attic") || c.includes("insulation") ||
    c.includes("garage door") ||
    c.includes("driveway") || c.includes("hardscape") || c.includes("paver")
  ) return "building";

  // Appliances
  if (
    c === "appliance" || c.includes("appliances") ||
    c.includes("dishwasher") || c.includes("refriger") ||
    c.includes("washer") || c.includes("dryer") || c.includes("oven") ||
    c.includes("range") || c.includes("microwave")
  ) return "appliances";

  // Safety & security
  if (
    c.includes("security") || c.includes("alarm") ||
    c.includes("smoke") || c.includes("carbon monoxide") || c === "co" ||
    c.includes("radon") || c.includes("fire")
  ) return "safety";

  // Handyman as its own light catch-all
  if (c.includes("handyman")) return "other";

  return "other";
}

type SystemGroupKey =
  | "mechanicals"
  | "outdoor"
  | "building"
  | "appliances"
  | "safety"
  | "recurring"
  | "other";

const GROUP_LABEL: Record<SystemGroupKey, string> = {
  mechanicals: "Mechanicals",
  outdoor:     "Outdoor & water",
  building:    "Building envelope",
  appliances:  "Appliances",
  safety:      "Safety & security",
  recurring:   "Recurring services",
  other:       "Other",
};

const GROUP_ORDER: SystemGroupKey[] = [
  "mechanicals",
  "outdoor",
  "building",
  "appliances",
  "safety",
  "recurring",
  "other",
];

function groupSystems(systems: HomeSystem[]): SystemGroupData[] {
  const buckets = new Map<SystemGroupKey, HomeSystem[]>();
  systems.forEach((s) => {
    const key = bucketForCategory(s.category);
    const arr = buckets.get(key) ?? [];
    arr.push(s);
    buckets.set(key, arr);
  });
  return GROUP_ORDER
    .filter((k) => buckets.has(k))
    .map((k) => {
      const items = (buckets.get(k) ?? []).sort((a, b) => a.name.localeCompare(b.name));
      return {
        label: GROUP_LABEL[k],
        count: items.length,
        // Open ≤4-item groups by default; collapse the chunky ones so
        // the page isn't a wall of rows on first paint.
        defaultExpanded: items.length <= 4,
        items,
      };
    });
}

function iconForCategory(category: string): string {
  const c = (category ?? "").toLowerCase();
  if (c.includes("hvac") || c.includes("heating") || c.includes("cooling")) return "lightbulb";
  if (c.includes("water heater") || c.includes("plumb")) return "drag";
  if (c.includes("electrical") || c.includes("generator")) return "lightbulb";
  if (c.includes("pool") || c.includes("spa") || c.includes("irrigation") || c.includes("sump") || c.includes("well") || c.includes("septic")) return "drag";
  if (c.includes("roof") || c.includes("siding") || c.includes("foundation") || c.includes("crawl") || c.includes("garage")) return "home";
  if (c.includes("appliance") || c.includes("dishwasher") || c.includes("refriger") || c.includes("washer") || c.includes("dryer")) return "briefcase";
  if (c.includes("security") || c.includes("smoke") || c.includes("alarm") || c.includes("radon")) return "shield";
  if (c.includes("trash") || c.includes("recycling") || c.includes("cleaning service")) return "history";
  if (c.includes("pet waste") || c.includes("mosquito") || c.includes("tick") || c.includes("pest") || c.includes("snow") || c.includes("lawn") || c.includes("landscap") || c.includes("window") || c.includes("tree") || c.includes("gutter")) return "history";
  return "briefcase";
}

function Stat({ label, value, accent = false }: { label: string; value: string; accent?: boolean }) {
  return (
    <div>
      <div style={{ fontSize: 10, color: "var(--text-soft)", letterSpacing: "0.08em", textTransform: "uppercase", fontWeight: 600 }}>{label}</div>
      <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 700, color: accent ? "var(--salmon-dark)" : "var(--text)", letterSpacing: "-0.018em" }}>
        {value}
      </div>
    </div>
  );
}

function SidebarStat({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", padding: "6px 0", borderBottom: "1px solid var(--neutral-200)" }}>
      <span style={{ fontSize: 11.5, color: "var(--text-soft)", letterSpacing: "0.04em", textTransform: "uppercase", fontWeight: 600 }}>{label}</span>
      <span style={{ fontSize: 13, color: "var(--text)", fontWeight: 600 }}>{value}</span>
    </div>
  );
}

function ModalShell({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 50,
        background: "rgba(42,34,82,0.4)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: 24,
      }}
      onClick={onClose}
    >
      <div
        style={{
          background: "#fff",
          borderRadius: 16,
          padding: 24,
          maxWidth: 520,
          width: "100%",
          boxShadow: "0 24px 60px rgba(42,34,82,0.4)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
          <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600 }}>{title}</div>
          <button onClick={onClose} style={{ background: "none", border: "none", color: "var(--text-soft)", cursor: "pointer", padding: 4 }} aria-label="Close">
            <Icon name="remove" size={16} stroke={2} />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label style={{ display: "flex", flexDirection: "column", gap: 4 }}>
      <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--text-soft)" }}>{label}</span>
      {children}
    </label>
  );
}

const inputStyle: React.CSSProperties = {
  width: "100%",
  padding: "10px 12px",
  border: "1px solid var(--neutral-200)",
  borderRadius: 10,
  background: "#fff",
  fontSize: 13,
  fontFamily: "var(--sans)",
  color: "var(--text)",
};

// ─── AI heuristics ───

function generateAISuggestions(home: { name: string; systems?: HomeSystem[] } | null, visits: { title: string; status: string; routeDate: string; quote: { total: number } | null }[]) {
  if (!home) return [];
  const systems = home.systems ?? [];
  const out: { title: string; reason: string; icon: string; priority: string; requestType: string }[] = [];
  const cats = systems.map((s) => (s.category || "").toLowerCase());

  const lastVisit = visits.find((v) => v.status === "completed");
  const lastVisitDate = lastVisit ? new Date(lastVisit.routeDate || 0) : null;
  const monthsSinceLast = lastVisitDate ? Math.round((Date.now() - lastVisitDate.getTime()) / (30 * 24 * 60 * 60 * 1000)) : null;

  if (cats.some((c) => c.includes("hvac"))) {
    out.push({
      title: "Annual HVAC tune-up",
      reason: "HVAC system on file. Yearly tune-up keeps efficiency up and warranty intact.",
      icon: "lightbulb",
      priority: "Annual",
      requestType: "standard_visit",
    });
  }
  if (cats.some((c) => c.includes("water heater")) || systems.some((s) => (s.name || "").toLowerCase().includes("water heater"))) {
    out.push({
      title: "Test water heater pressure relief valve",
      reason: "Quick safety check on water heater. Often skipped, easy to add to any visit.",
      icon: "shield",
      priority: "Yearly",
      requestType: "standard_visit",
    });
  }
  if (systems.some((s) => !s.manufacturer)) {
    out.push({
      title: "Build out home profile (manufacturer + model)",
      reason: "Some systems have no make/model on file. Capturing on next visit unlocks better recommendations.",
      icon: "briefcase",
      priority: "First visit",
      requestType: "setup",
    });
  }
  if (monthsSinceLast === null || monthsSinceLast > 12) {
    out.push({
      title: "Annual home walk-through",
      reason: lastVisitDate ? `Last visit was ${monthsSinceLast} months ago.` : "No completed visits on file yet — a walk-through builds the profile and finds easy wins.",
      icon: "home",
      priority: "Soon",
      requestType: "standard_visit",
    });
  }
  if (out.length < 3) {
    out.push({
      title: "Smoke + CO detector battery sweep",
      reason: "Universal yearly safety check, ~30 min for a typical home.",
      icon: "shield",
      priority: "Yearly",
      requestType: "standard_visit",
    });
  }
  return out.slice(0, 4);
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

// ─── System edit sheet ─────────────────────────────────────

/**
 * Lets the handyman update the make/model/notes/install date on a
 * system from desktop, e.g. after a visit when they're back at the
 * desk and don't want to fumble with their phone. Posts the new
 * `update_home_system` action which the edge function gates by
 * "this workspace has worked with this property" before writing.
 */
function SystemEditSheet({
  system,
  onClose,
  onSaved,
}: {
  system: HomeSystem;
  onClose: () => void;
  onSaved: () => void | Promise<void>;
}) {
  const { dashboard, refresh } = useWorkspace();
  const [name, setName] = useState(system.name);
  const [manufacturer, setManufacturer] = useState(system.manufacturer ?? "");
  const [modelNumber, setModelNumber] = useState(system.modelNumber ?? "");
  const [serialNumber, setSerialNumber] = useState(system.serialNumber ?? "");
  const [notes, setNotes] = useState(system.notes ?? "");
  const [installDate, setInstallDate] = useState(system.installDate ?? "");
  const [submitting, setSubmitting] = useState(false);
  const [photos, setPhotos] = useState(system.photos ?? []);
  const [photoBusy, setPhotoBusy] = useState(false);
  const [photoError, setPhotoError] = useState<string | null>(null);

  async function save() {
    if (!dashboard) return;
    setSubmitting(true);
    try {
      await postProviderAction("update_home_system", {
        workspaceId: dashboard.workspace.id,
        systemId: system.id,
        name,
        manufacturer,
        modelNumber,
        serialNumber,
        notes,
        installDate: installDate || undefined,
      });
      await onSaved();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Couldn't save system.");
    } finally {
      setSubmitting(false);
    }
  }

  async function handlePhotoFiles(files: FileList | null) {
    if (!files || files.length === 0 || !dashboard) return;
    setPhotoBusy(true);
    setPhotoError(null);
    try {
      for (const file of Array.from(files)) {
        if (!file.type.startsWith("image/")) continue;
        const compressed = await compressImageFile(file);
        const result = await postProviderAction<{ photo: HomeSystemPhoto }>(
          "upload_home_system_photo",
          {
            workspaceId: dashboard.workspace.id,
            systemId: system.id,
            filename: file.name,
            contentType: compressed.contentType,
            fileBase64: compressed.base64,
          },
        );
        if (result.photo) {
          setPhotos((prev) => [...prev, result.photo]);
        }
      }
      // Refresh dashboard so the parent screen sees the new photo too
      await refresh();
    } catch (e) {
      setPhotoError(e instanceof Error ? e.message : "Couldn't upload photo.");
    } finally {
      setPhotoBusy(false);
    }
  }

  async function deletePhoto(path: string) {
    if (!dashboard) return;
    const before = photos;
    setPhotos((prev) => prev.filter((p) => p.path !== path));
    try {
      await postProviderAction("delete_home_system_photo", {
        workspaceId: dashboard.workspace.id,
        systemId: system.id,
        path,
      });
      await refresh();
    } catch (e) {
      // Revert optimistic removal on failure
      setPhotos(before);
      setPhotoError(e instanceof Error ? e.message : "Couldn't remove photo.");
    }
  }

  return (
    <div
      style={{
        position: "fixed", inset: 0, zIndex: 50,
        background: "rgba(42,34,82,0.4)",
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: 24,
      }}
      onClick={() => !submitting && onClose()}
    >
      <div
        style={{
          background: "#fff", borderRadius: 16, padding: 24,
          width: "min(520px, 95vw)", maxHeight: "90vh", overflowY: "auto",
          boxShadow: "0 24px 60px rgba(42,34,82,0.4)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 6 }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--text-soft)" }}>
              {system.category || "Home system"}
            </div>
            <div style={{ fontFamily: "var(--serif)", fontSize: 22, fontWeight: 600, color: "var(--text)", marginTop: 4 }}>
              {system.name}
            </div>
          </div>
          <button onClick={onClose} style={{ background: "none", border: "none", color: "var(--text-soft)", cursor: "pointer", padding: 4 }} aria-label="Close">
            <Icon name="remove" size={18} stroke={2} />
          </button>
        </div>

        <div style={{ fontSize: 12.5, color: "var(--text-muted)", marginBottom: 18, lineHeight: 1.5 }}>
          Anything you capture here syncs back to the homeowner's app so future visits get smarter recommendations.
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <Field label="Display name">
            <input type="text" value={name} onChange={(e) => setName(e.target.value)} style={inputStyle2} />
          </Field>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
            <Field label="Manufacturer">
              <input
                type="text"
                placeholder="Bosch"
                value={manufacturer}
                onChange={(e) => setManufacturer(e.target.value)}
                style={inputStyle2}
              />
            </Field>
            <Field label="Model #">
              <input
                type="text"
                placeholder="800 Series"
                value={modelNumber}
                onChange={(e) => setModelNumber(e.target.value)}
                style={inputStyle2}
              />
            </Field>
          </div>
          <Field label="Serial #">
            <input
              type="text"
              placeholder="(if you can find it)"
              value={serialNumber}
              onChange={(e) => setSerialNumber(e.target.value)}
              style={inputStyle2}
            />
          </Field>
          <Field label="Install date (rough is fine)">
            <input type="date" value={installDate} onChange={(e) => setInstallDate(e.target.value)} style={inputStyle2} />
          </Field>
          <Field label="Notes">
            <textarea
              placeholder="Anything you noticed — corrosion, last service date, recommended replacements…"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              style={{ ...inputStyle2, minHeight: 100, resize: "vertical" }}
            />
          </Field>
        </div>

        {/* Photos — capture rating-plate / nameplate / install context */}
        <div style={{ marginTop: 22 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 10 }}>
            <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--text-soft)" }}>
              Photos
            </div>
            <label
              style={{
                display: "inline-flex", alignItems: "center", gap: 6,
                padding: "6px 12px", borderRadius: 999,
                background: "var(--indigo-50)", color: "var(--indigo)",
                fontSize: 12, fontWeight: 600, cursor: photoBusy ? "wait" : "pointer",
                opacity: photoBusy ? 0.6 : 1,
              }}
            >
              <Icon name="plus" size={14} stroke={2} />
              {photoBusy ? "Uploading…" : "Add photos"}
              <input
                type="file"
                accept="image/*"
                multiple
                style={{ display: "none" }}
                disabled={photoBusy}
                onChange={(e) => {
                  void handlePhotoFiles(e.target.files);
                  e.target.value = ""; // reset so re-selecting same file fires
                }}
              />
            </label>
          </div>

          {photos.length > 0 ? (
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(96px, 1fr))", gap: 8 }}>
              {photos.map((photo) => (
                <div
                  key={photo.path}
                  style={{
                    position: "relative", aspectRatio: "1 / 1",
                    borderRadius: 10, overflow: "hidden",
                    background: "var(--cream)", border: "1px solid var(--neutral-200)",
                  }}
                >
                  {photo.signedUrl ? (
                    <img
                      src={photo.signedUrl}
                      alt={photo.caption || "System photo"}
                      style={{ width: "100%", height: "100%", objectFit: "cover" }}
                    />
                  ) : (
                    <div style={{
                      display: "flex", alignItems: "center", justifyContent: "center",
                      height: "100%", color: "var(--text-soft)", fontSize: 11,
                    }}>
                      Loading
                    </div>
                  )}
                  <button
                    onClick={() => void deletePhoto(photo.path)}
                    aria-label="Remove photo"
                    style={{
                      position: "absolute", top: 4, right: 4,
                      background: "rgba(42, 34, 82, 0.78)", color: "#fff",
                      border: "none", borderRadius: "50%",
                      width: 22, height: 22, fontSize: 13, lineHeight: 1,
                      cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
                    }}
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <div style={{
              padding: "16px 14px", borderRadius: 10,
              background: "var(--cream)", border: "1px dashed var(--neutral-300)",
              color: "var(--text-muted)", fontSize: 12.5, lineHeight: 1.5, textAlign: "center",
            }}>
              Snap the rating plate, model sticker, or anything that helps the next visit. Future you will thank you.
            </div>
          )}

          {photoError && (
            <div style={{ marginTop: 8, fontSize: 12, color: "var(--salmon-dark)" }}>{photoError}</div>
          )}
        </div>

        <div style={{ display: "flex", gap: 8, justifyContent: "flex-end", marginTop: 18 }}>
          <button className="ops-button ops-button--ghost" onClick={onClose} disabled={submitting}>Cancel</button>
          <button className="ops-button ops-button--salmon" onClick={save} disabled={submitting}>
            {submitting ? "Saving…" : "Save changes"}
          </button>
        </div>
      </div>
    </div>
  );
}

/**
 * Client-side image compression — resize to max 1600px on the long
 * edge and re-encode as JPEG q=0.82 to keep upload payloads under
 * ~500KB. Returns base64 (no data: prefix) so the edge function can
 * decode straight to bytes.
 */
async function compressImageFile(file: File): Promise<{ base64: string; contentType: string }> {
  const dataUrl = await new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(new Error("Failed to read file"));
    reader.readAsDataURL(file);
  });

  const img = await new Promise<HTMLImageElement>((resolve, reject) => {
    const el = new Image();
    el.onload = () => resolve(el);
    el.onerror = () => reject(new Error("Failed to decode image"));
    el.src = dataUrl;
  });

  const maxEdge = 1600;
  const scale = Math.min(1, maxEdge / Math.max(img.width, img.height));
  const targetW = Math.round(img.width * scale);
  const targetH = Math.round(img.height * scale);

  const canvas = document.createElement("canvas");
  canvas.width = targetW;
  canvas.height = targetH;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas unavailable");
  ctx.drawImage(img, 0, 0, targetW, targetH);

  const blob = await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob((b) => (b ? resolve(b) : reject(new Error("Encode failed"))), "image/jpeg", 0.82);
  });

  const base64 = await new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = String(reader.result);
      resolve(result.includes(",") ? result.split(",", 2)[1] : result);
    };
    reader.onerror = () => reject(new Error("Failed to encode"));
    reader.readAsDataURL(blob);
  });

  return { base64, contentType: "image/jpeg" };
}

const inputStyle2: React.CSSProperties = {
  width: "100%",
  padding: "10px 12px",
  border: "1px solid var(--neutral-200)",
  borderRadius: 10,
  background: "#fff",
  fontSize: 13,
  fontFamily: "var(--sans)",
  color: "var(--text)",
};
