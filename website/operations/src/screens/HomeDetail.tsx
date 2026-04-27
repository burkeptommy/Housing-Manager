import { useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrency, formatRelativeTime, postProviderAction } from "../lib/api";
import type { HomeSystem, RequestStatus } from "../lib/types";

export default function HomeDetailScreen() {
  const { propertyId } = useParams<{ propertyId: string }>();
  const { dashboard, refresh } = useWorkspace();
  const navigate = useNavigate();
  const [showSuggest, setShowSuggest] = useState(false);
  const [suggestTitle, setSuggestTitle] = useState("");
  const [suggestDetails, setSuggestDetails] = useState("");
  const [suggestType, setSuggestType] = useState("standard_visit");
  const [suggestSubmitting, setSuggestSubmitting] = useState(false);

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
            <div style={{ fontSize: 13, color: "var(--text-muted)" }}>{home.address || "—"}</div>
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
          <Stat label="Last visit" value={home.lastCompletedVisit ? formatRelativeTime(home.lastCompletedVisit) : "—"} />
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
              <div style={{ display: "flex", flexDirection: "column" }}>
                {home.systems.map((s) => (
                  <SystemRow key={s.id} system={s} />
                ))}
              </div>
            )}
          </Card>

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

function SystemRow({ system }: { system: HomeSystem }) {
  const headline = system.manufacturer || system.modelNumber
    ? `${system.manufacturer ?? ""} ${system.modelNumber ?? ""}`.trim()
    : "Manufacturer unknown";
  return (
    <div className="ops-row" style={{ padding: "12px 0" }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: "var(--indigo-50)", color: "var(--indigo)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
        <Icon name="briefcase" size={16} stroke={1.9} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{system.name}</div>
        <div style={{ fontSize: 11.5, color: "var(--text-muted)" }}>
          {system.category}{system.category && headline !== "Manufacturer unknown" ? " · " : ""}{headline !== "Manufacturer unknown" ? headline : ""}
        </div>
      </div>
      {!system.manufacturer && (
        <Pill tone="warning">Update on next visit</Pill>
      )}
    </div>
  );
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
  switch (status) {
    case "submitted":
    case "sent_to_handyman":
    case "alternate_dates_proposed":
    case "awaiting_homeowner":
      return "salmon";
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
