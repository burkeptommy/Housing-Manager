import type React from "react";
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatTime12h, isToday, postProviderAction } from "../lib/api";
import type { PartRequest, PartRequestStatus, VisitRow } from "../lib/types";

export default function RoutesScreen() {
  const { dashboard, mode } = useWorkspace();

  const today = new Date().toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" });

  // Wave M12 — open part requests for this workspace. Loaded on mount
  // and re-fetched on operator actions (mark ordered / mark fulfilled
  // / dispatch). Rendered as a sub-section above the route cards.
  const [partRequests, setPartRequests] = useState<PartRequest[]>([]);
  const [partRequestsLoading, setPartRequestsLoading] = useState(true);
  const [partRequestActionInFlight, setPartRequestActionInFlight] = useState<string | null>(null);

  useEffect(() => {
    if (!dashboard?.workspace?.id) return;
    let cancelled = false;
    (async () => {
      try {
        setPartRequestsLoading(true);
        const res = await postProviderAction<{ partRequests: PartRequest[]; openCount: number }>(
          "list_open_part_requests",
          { workspaceId: dashboard.workspace.id, status: "open" }
        );
        if (!cancelled) {
          setPartRequests(res.partRequests ?? []);
        }
      } catch (err) {
        console.warn("[Routes] failed to load part requests", err);
      } finally {
        if (!cancelled) setPartRequestsLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [dashboard?.workspace?.id]);

  async function updatePartStatus(req: PartRequest, status: PartRequestStatus, supplier?: string, supplierEta?: string) {
    if (!dashboard?.workspace?.id) return;
    setPartRequestActionInFlight(req.id);
    try {
      const res = await postProviderAction<{ partRequest: PartRequest }>("update_part_status", {
        workspaceId: dashboard.workspace.id,
        partRequestId: req.id,
        status,
        ...(supplier ? { supplier } : {}),
        ...(supplierEta ? { supplierEta } : {}),
      });
      // Drop fulfilled / cancelled rows from the open list, otherwise
      // replace in place.
      if (res.partRequest.status === "fulfilled" || res.partRequest.status === "cancelled") {
        setPartRequests((prev) => prev.filter((p) => p.id !== req.id));
      } else {
        setPartRequests((prev) => prev.map((p) => (p.id === req.id ? res.partRequest : p)));
      }
    } catch (err) {
      console.warn("[Routes] update_part_status failed", err);
      alert(err instanceof Error ? err.message : "Failed to update part request");
    } finally {
      setPartRequestActionInFlight(null);
    }
  }

  async function markOrdered(req: PartRequest) {
    const supplier = window.prompt("Supplier (optional):", req.supplier ?? "") ?? "";
    const etaInput = window.prompt("Supplier ETA (YYYY-MM-DD HH:MM, optional, e.g. 2026-05-10 09:00):", "");
    let etaIso: string | undefined;
    if (etaInput) {
      const parsed = new Date(etaInput.replace(" ", "T"));
      if (!isNaN(parsed.getTime())) etaIso = parsed.toISOString();
    }
    await updatePartStatus(req, "ordered", supplier || undefined, etaIso);
  }

  async function markFulfilled(req: PartRequest) {
    if (!window.confirm("Mark this part request as fulfilled?")) return;
    await updatePartStatus(req, "fulfilled");
  }

  async function markCancelled(req: PartRequest) {
    if (!window.confirm("Cancel this part request?")) return;
    await updatePartStatus(req, "cancelled");
  }

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
        <div style={{ fontFamily: "var(--serif)", fontSize: 18, fontWeight: 600 }}>Today · {today}</div>
        {routes.length > 0 && (
          <div style={{ marginLeft: "auto", fontSize: 12, color: "var(--text-soft)" }}>
            {routes.length} {routes.length === 1 ? "tech" : "techs"} routed · {routes.reduce((sum, r) => sum + r.visits.length, 0)} stops
          </div>
        )}
      </div>

      {/* Wave M12 — open part requests sub-section. Renders above the
          route cards so the dispatcher sees the active queue first. */}
      {(partRequestsLoading || partRequests.length > 0) && (
        <div style={{ marginBottom: 24 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <Icon name="wrench" size={16} stroke={1.9} color="var(--text)" />
            <div style={{ fontFamily: "var(--serif)", fontSize: 16, fontWeight: 600 }}>
              Part requests
            </div>
            {!partRequestsLoading && partRequests.length > 0 && (
              <span
                style={{
                  fontSize: 11,
                  color: "var(--text-soft)",
                  background: "var(--neutral-100)",
                  padding: "2px 8px",
                  borderRadius: 999,
                }}
              >
                {partRequests.length} open
              </span>
            )}
          </div>
          {partRequestsLoading ? (
            <Card padding="default">
              <div style={{ height: 16, width: 220, background: "var(--neutral-100)", borderRadius: 4, marginBottom: 8 }} />
              <div style={{ height: 12, width: 160, background: "var(--neutral-100)", borderRadius: 4 }} />
            </Card>
          ) : (
            <div style={{ display: "grid", gap: 10 }}>
              {partRequests.map((req) => (
                <PartRequestRow
                  key={req.id}
                  request={req}
                  inFlight={partRequestActionInFlight === req.id}
                  onMarkOrdered={() => markOrdered(req)}
                  onMarkFulfilled={() => markFulfilled(req)}
                  onMarkCancelled={() => markCancelled(req)}
                />
              ))}
            </div>
          )}
        </div>
      )}

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
                    <Link
                      key={stop.requestId}
                      to={`/visits/${stop.requestId}`}
                      style={{ display: "flex", gap: 12, padding: "10px 0", borderBottom: i < route.visits.length - 1 ? "1px solid var(--neutral-200)" : "none", textDecoration: "none", color: "inherit" }}
                    >
                      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", flex: "none" }}>
                        <div style={{ width: 22, height: 22, borderRadius: "50%", background: "var(--salmon-pale)", color: "var(--salmon-dark)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 700 }}>
                          {i + 1}
                        </div>
                        {i < route.visits.length - 1 && <div style={{ width: 1.5, flex: 1, background: "var(--neutral-300)", marginTop: 4, minHeight: 28 }} />}
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{stop.title}</div>
                        <div style={{ fontSize: 11.5, color: "var(--text-muted)", marginBottom: 4 }}>
                          {stop.property?.name || stop.property?.address || "No address on file"}{stop.property?.name && stop.property?.address ? ` · ${stop.property.address.split(",")[1]?.trim() ?? ""}` : ""}
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
                      <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
                    </Link>
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

// Wave M12 — single row in the Part Requests sub-section. Description
// + urgency pill + status pill + supplier ETA + action buttons.
function PartRequestRow(props: {
  request: PartRequest;
  inFlight: boolean;
  onMarkOrdered: () => void;
  onMarkFulfilled: () => void;
  onMarkCancelled: () => void;
}) {
  const { request, inFlight, onMarkOrdered, onMarkFulfilled, onMarkCancelled } = props;
  const urgencyMeta = urgencyDisplay(request.urgency);
  const statusMeta = statusDisplay(request.status);
  const etaLabel = request.supplierEta
    ? new Date(request.supplierEta).toLocaleString(undefined, {
        month: "short",
        day: "numeric",
        hour: "numeric",
        minute: "2-digit",
      })
    : null;

  return (
    <Card padding="tight">
      <div style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 14, fontWeight: 600, color: "var(--text)", marginBottom: 6 }}>
            {request.description}
          </div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 6, alignItems: "center" }}>
            <span
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 4,
                fontSize: 11,
                fontWeight: 600,
                padding: "3px 8px",
                borderRadius: 999,
                background: urgencyMeta.bg,
                color: urgencyMeta.fg,
              }}
            >
              <span
                style={{
                  width: 6,
                  height: 6,
                  borderRadius: "50%",
                  background: urgencyMeta.fg,
                  display: "inline-block",
                }}
              />
              {urgencyMeta.label}
            </span>
            <span
              style={{
                fontSize: 11,
                fontWeight: 600,
                padding: "3px 8px",
                borderRadius: 999,
                background: statusMeta.bg,
                color: statusMeta.fg,
              }}
            >
              {statusMeta.label}
            </span>
            {request.supplier && (
              <span style={{ fontSize: 11, color: "var(--text-muted)" }}>
                {request.supplier}
                {etaLabel ? ` · ETA ${etaLabel}` : ""}
              </span>
            )}
            {request.requestId && (
              <Link
                to={`/visits/${request.requestId}`}
                style={{ fontSize: 11, color: "var(--indigo)", textDecoration: "none" }}
              >
                View visit →
              </Link>
            )}
          </div>
          {request.photos.length > 0 && (
            <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
              {request.photos.slice(0, 4).map((photo) =>
                photo.signedUrl ? (
                  <a
                    key={photo.path}
                    href={photo.signedUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      width: 56,
                      height: 56,
                      borderRadius: 8,
                      overflow: "hidden",
                      background: "var(--neutral-100)",
                      display: "block",
                    }}
                  >
                    <img
                      src={photo.signedUrl}
                      alt="Part"
                      style={{ width: "100%", height: "100%", objectFit: "cover" }}
                    />
                  </a>
                ) : null
              )}
            </div>
          )}
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 6, flex: "none" }}>
          {request.status === "open" && (
            <button
              type="button"
              disabled={inFlight}
              onClick={onMarkOrdered}
              style={actionButtonStyle("primary", inFlight)}
            >
              {inFlight ? "Working" : "Mark ordered"}
            </button>
          )}
          {(request.status === "open" || request.status === "ordered" || request.status === "in_truck") && (
            <button
              type="button"
              disabled={inFlight}
              onClick={onMarkFulfilled}
              style={actionButtonStyle("secondary", inFlight)}
            >
              Fulfilled
            </button>
          )}
          <button
            type="button"
            disabled={inFlight}
            onClick={onMarkCancelled}
            style={actionButtonStyle("ghost", inFlight)}
          >
            Cancel
          </button>
        </div>
      </div>
    </Card>
  );
}

function urgencyDisplay(urgency: PartRequest["urgency"]) {
  switch (urgency) {
    case "blocking_now":
      return { label: "Blocking now", bg: "rgba(220, 53, 69, 0.10)", fg: "#DC3545" };
    case "next_visit":
      return { label: "Next visit", bg: "rgba(245, 158, 11, 0.10)", fg: "#B45309" };
    default:
      return { label: "Order for stock", bg: "var(--neutral-100)", fg: "var(--text-muted)" };
  }
}

function statusDisplay(status: PartRequest["status"]) {
  switch (status) {
    case "open":
      return { label: "Open", bg: "rgba(255, 105, 85, 0.10)", fg: "var(--salmon-dark)" };
    case "ordered":
      return { label: "Ordered", bg: "rgba(99, 102, 241, 0.10)", fg: "#4338CA" };
    case "in_truck":
      return { label: "In truck", bg: "rgba(59, 130, 246, 0.10)", fg: "#1D4ED8" };
    case "fulfilled":
      return { label: "Fulfilled", bg: "rgba(34, 197, 94, 0.10)", fg: "#15803D" };
    default:
      return { label: status, bg: "var(--neutral-100)", fg: "var(--text-muted)" };
  }
}

function actionButtonStyle(variant: "primary" | "secondary" | "ghost", disabled: boolean): React.CSSProperties {
  const base: React.CSSProperties = {
    fontSize: 12,
    fontWeight: 600,
    padding: "6px 12px",
    borderRadius: 8,
    border: "1px solid transparent",
    cursor: disabled ? "not-allowed" : "pointer",
    opacity: disabled ? 0.5 : 1,
    minHeight: 28,
    whiteSpace: "nowrap",
  };
  if (variant === "primary") {
    return { ...base, background: "var(--salmon)", color: "#fff" };
  }
  if (variant === "secondary") {
    return { ...base, background: "var(--surface)", color: "var(--text)", borderColor: "var(--neutral-300)" };
  }
  return { ...base, background: "transparent", color: "var(--text-muted)" };
}
