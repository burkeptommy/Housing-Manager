import { useMemo } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Card } from "../components/chrome/Card";
import { Pill, type PillTone } from "../components/chrome/Pill";
import { StatTile } from "../components/chrome/StatTile";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { EmptyState } from "../components/chrome/EmptyState";
import { useWorkspace } from "../lib/workspace-context";
import { formatCurrencyCompact, formatRelativeTime, formatTime12h, isToday } from "../lib/api";
import type { VisitRow, RequestStatus, MessageThread } from "../lib/types";

export default function OverviewScreen() {
  const { dashboard, mode, isLoading } = useWorkspace();

  // Today's visits (for the field board) — sole prop sees all workspace
  // visits today since they're the only person; crew sees the entire board.
  const todaysVisits = useMemo(() => {
    if (!dashboard) return [];
    return dashboard.visits.filter((v) => isToday(v.routeDate) && !["completed", "cancelled", "declined"].includes(v.status));
  }, [dashboard]);

  // The decision queue: requests that need attention from the workspace
  // owner. Order: emergency first (urgency='urgent'), then Chez-routed
  // requests (need an explicit ack), then routine. Limit 4 to keep the
  // panel scannable. Section 19a fix.
  const decisions = useMemo(() => {
    if (!dashboard) return [];
    return dashboard.visits
      .filter((v) =>
        ["submitted", "sent_to_handyman", "alternate_dates_proposed", "awaiting_homeowner", "quoted"].includes(v.status)
      )
      .sort((a, b) => {
        const aPriority = a.urgency === "urgent" ? 0 : a.source === "haven" ? 1 : 2;
        const bPriority = b.urgency === "urgent" ? 0 : b.source === "haven" ? 1 : 2;
        return aPriority - bPriority;
      })
      .slice(0, 4);
  }, [dashboard]);

  if (isLoading) return <LoadingShell />;
  if (!dashboard) return null;

  const greetName = dashboard.currentUser.fullName?.split(" ")[0] ?? "";
  const personHero = mode === "sole";
  const todayDoneCount = dashboard.visits.filter((v) => isToday(v.routeDate) && v.status === "completed").length;
  const todayInProgress = dashboard.visits.filter((v) => isToday(v.routeDate) && ["on_my_way", "in_progress", "checked_in"].includes(v.status)).length;
  // todaysVisits already filters out completed/cancelled/declined and so
  // includes both in-progress and to-go visits. The hero count is the
  // total (all today's visits including done), and remaining = the slice
  // not yet started.
  const todayCount = todaysVisits.length + todayDoneCount;
  const todayRemaining = Math.max(todaysVisits.length - todayInProgress, 0);

  return (
    <>
      <Hero
        eyebrow={`OPERATIONS · ${formattedDate()}`}
        personHero={personHero}
        firstName={greetName}
        todayCount={todayCount}
        todayDone={todayDoneCount}
        todayInProgress={todayInProgress}
        todayRemaining={todayRemaining}
      />

      <KpiStrip />

      <div className="ops-grid-2col">
        {/* LEFT — Today field board */}
        <Card padding="default">
          <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
            <div>
              <div className="ops-section-label">Today · Field board</div>
              <div style={{ fontFamily: "var(--serif)", fontSize: 18, color: "var(--text)", fontWeight: 600 }}>
                {formattedFullDate()}
              </div>
            </div>
            <div style={{ display: "flex", gap: 6 }}>
              <Pill tone="neutral">{personHero ? "You" : "All techs"}</Pill>
              {dashboard.stats.unassignedVisits > 0 && (
                <Pill tone="salmon">Unassigned · {dashboard.stats.unassignedVisits}</Pill>
              )}
            </div>
          </div>

          {todaysVisits.length === 0 ? (
            <EmptyFieldBoard hasAnyVisits={dashboard.visits.length > 0} />
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
              {todaysVisits.map((v) => (
                <FieldBoardRow key={v.requestId} visit={v} />
              ))}
            </div>
          )}
        </Card>

        {/* RIGHT — Decision queue + Pipeline + Threads */}
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>Needs your attention</div>
            {decisions.length === 0 ? (
              <SmallEmpty
                icon="check"
                title="Inbox zero"
                body="No requests waiting on you. New homeowner work shows up here first."
              />
            ) : (
              <div style={{ display: "flex", flexDirection: "column" }}>
                {decisions.map((v) => (
                  <DecisionRow key={v.requestId} visit={v} />
                ))}
              </div>
            )}
          </Card>

          <Card padding="default">
            <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
              <div>
                <div className="ops-section-label">Quote pipeline</div>
                <div style={{ fontFamily: "var(--serif)", fontSize: 28, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.018em", lineHeight: 1.05 }}>
                  {formatCurrencyCompact(pipelineTotal(dashboard.quotes))}
                </div>
              </div>
              <Pill tone="indigo">{dashboard.quotes.length} quote{dashboard.quotes.length === 1 ? "" : "s"}</Pill>
            </div>
            {dashboard.quotes.length === 0 ? (
              <SmallEmpty
                icon="quote"
                title="No quotes yet"
                body="When you draft a quote it lands here so you can track it through the pipeline."
              />
            ) : (
              <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 8 }}>
                {(["draft", "sent", "viewed", "approved", "declined"] as const).map((status) => {
                  const count = dashboard.quotes.filter((q) => q.status === status).length;
                  const tone = quoteStatusTone(status);
                  return (
                    <div key={status}>
                      <div style={{ height: 3, borderRadius: 2, background: toneCss(tone), marginBottom: 6 }} />
                      <div style={{ fontSize: 11, color: "var(--text-soft)", letterSpacing: "0.06em", textTransform: "uppercase", fontWeight: 600 }}>{status}</div>
                      <div style={{ fontFamily: "var(--serif)", fontSize: 18, color: "var(--text)", fontWeight: 700 }}>{count}</div>
                    </div>
                  );
                })}
              </div>
            )}
          </Card>

          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>Recent threads</div>
            {dashboard.messages.length === 0 ? (
              <SmallEmpty
                icon="message"
                title="No homeowner messages yet"
                body="When a homeowner messages you about a visit, threads show up here."
              />
            ) : (
              <div style={{ display: "flex", flexDirection: "column" }}>
                {dashboard.messages.slice(0, 4).map((t) => (
                  <ThreadPreviewRow key={t.requestId} thread={t} />
                ))}
              </div>
            )}
          </Card>
        </div>
      </div>

      {mode === "crew" && dashboard.teamMembers.length > 1 && (
        <div style={{ marginTop: 24 }}>
          <div className="ops-section-label" style={{ marginBottom: 10 }}>Crew workload</div>
          <div className="ops-grid-3col">
            {dashboard.teamMembers
              .filter((m) => m.role !== "owner")
              .map((m) => {
                const today = dashboard.visits.filter((v) => v.assignment?.memberId === m.id && isToday(v.routeDate)).length;
                const open = dashboard.visits.filter((v) => v.assignment?.memberId === m.id && !["completed", "cancelled", "declined"].includes(v.status)).length;
                const cap = Math.min(100, today * 18 + open * 5);
                return (
                  <Card key={m.id} padding="tight">
                    <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
                      <Avatar initials={initialsFor(m.fullName || m.email)} size={32} />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{m.fullName || m.email}</div>
                        <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{m.title || m.role}</div>
                      </div>
                      <Pill tone={cap > 90 ? "critical" : "indigo"}>
                        {cap > 90 ? "At capacity" : "Available"}
                      </Pill>
                    </div>
                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: 11, color: "var(--text-soft)", marginBottom: 4 }}>
                      <span>{today} today</span>
                      <span>{open} open</span>
                    </div>
                    <div style={{ height: 6, background: "var(--neutral-200)", borderRadius: 4, overflow: "hidden" }}>
                      <div style={{ width: `${cap}%`, height: "100%", background: cap > 90 ? "var(--salmon)" : "var(--indigo)" }} />
                    </div>
                  </Card>
                );
              })}
          </div>
        </div>
      )}

      <div style={{ height: 40 }} />
    </>
  );
}

// ─── Hero ────────────────────────────────────────────────────────

function Hero(props: {
  eyebrow: string;
  personHero: boolean;
  firstName: string;
  todayCount: number;
  todayDone: number;
  todayInProgress: number;
  todayRemaining: number;
}) {
  const total = Math.max(props.todayCount, 1);
  const donePct = (props.todayDone / total) * 100;
  const ontheWayPct = (props.todayInProgress / total) * 100;
  const togoPct = (props.todayRemaining / total) * 100;

  const headline = props.personHero
    ? props.todayCount === 0
      ? { lead: `Welcome back${props.firstName ? `, ${props.firstName}` : ""}.`, emphasis: " A clean slate." }
      : props.todayRemaining === 0
        ? { lead: "All ", emphasis: `${props.todayCount} visit${props.todayCount === 1 ? "" : "s"} done.` }
        : { lead: `${props.todayRemaining} stop${props.todayRemaining === 1 ? "" : "s"} `, emphasis: "to go today." }
    : props.todayCount === 0
      ? { lead: "Quiet morning. ", emphasis: "Time to fill the board." }
      : { lead: "Own the queue, ", emphasis: "route the field team." };

  return (
    <div className="ops-hero">
      <div>
        <div className="ops-hero__eyebrow">{props.eyebrow}</div>
        <h1 className="ops-hero__headline">
          {headline.lead}<em>{headline.emphasis}</em>
        </h1>
        <div className="ops-hero__cta-row">
          <button className="ops-button ops-button--salmon">Open my day →</button>
          <button className="ops-button ops-button--ghost">New quote</button>
        </div>
      </div>
      <div className="ops-hero__snapshot">
        <div className="ops-hero__snapshot-label">Today snapshot</div>
        <div className="ops-hero__snapshot-value">{props.todayCount}</div>
        <div className="ops-hero__snapshot-bar">
          <div className="ops-hero__snapshot-bar-segment ops-hero__snapshot-bar-segment--done" style={{ width: `${donePct}%` }} />
          <div className="ops-hero__snapshot-bar-segment ops-hero__snapshot-bar-segment--ontheway" style={{ width: `${ontheWayPct}%` }} />
          <div className="ops-hero__snapshot-bar-segment ops-hero__snapshot-bar-segment--togo" style={{ width: `${togoPct}%` }} />
        </div>
        <div className="ops-hero__snapshot-legend">
          <span>{props.todayDone} done</span>
          <span>{props.todayInProgress} on the way</span>
          <span>{props.todayRemaining} to go</span>
        </div>
      </div>
    </div>
  );
}

// ─── KPI strip ──────────────────────────────────────────────────

function KpiStrip() {
  const { dashboard, mode } = useWorkspace();
  const navigate = useNavigate();
  if (!dashboard) return null;
  const s = dashboard.stats;
  const todayLabel = mode === "sole" ? "Today (you)" : "Today";

  const tiles: { label: string; value: string | number; sub: string; to: string; accent?: boolean }[] = [
    { label: "Requested",   value: s.requestedVisits,   sub: "Open requests",        to: "/visits?filter=requested" },
    { label: "Unassigned",  value: s.unassignedVisits,  sub: "Awaiting dispatch",    to: "/visits" },
    { label: todayLabel,    value: s.todayStops,        sub: "Stops on the board",   to: "/visits?filter=today" },
    { label: "Homes",       value: s.homesServiced,     sub: "On your books",        to: "/homes" },
    { label: "Pipeline",    value: formatCurrencyCompact(pipelineTotal(dashboard.quotes)), sub: `Across ${dashboard.quotes.length} quote${dashboard.quotes.length === 1 ? "" : "s"}`, to: "/quotes", accent: true },
    { label: "This week",   value: s.upcomingVisits,    sub: "Visits booked",        to: "/visits?filter=week" },
  ];

  return (
    <div className="ops-grid-kpis">
      {tiles.map((t) => (
        <button
          key={t.label}
          onClick={() => navigate(t.to)}
          style={{ background: "none", border: "none", padding: 0, cursor: "pointer", textAlign: "left" }}
          aria-label={`${t.label}: ${t.value} — open ${t.to}`}
        >
          <StatTile label={t.label} value={t.value} sub={t.sub} accent={t.accent} />
        </button>
      ))}
    </div>
  );
}

// ─── Field board row ───────────────────────────────────────────

function FieldBoardRow({ visit }: { visit: VisitRow }) {
  const time = formatTime12h(visit.assignment?.windowStartTime ?? visit.visit?.scheduledDate);
  return (
    <Link to={`/visits/${visit.requestId}`} className="ops-row" style={{ padding: "10px 0", textDecoration: "none", color: "inherit" }}>
      <div style={{ width: 86, flex: "none", display: "flex", flexDirection: "column" }}>
        <span style={{ fontFamily: "var(--serif)", fontSize: 14, color: "var(--text)", fontWeight: 600 }}>
          {time || "TBD"}
        </span>
        {visit.assignment?.windowEndTime && (
          <span style={{ fontSize: 11, color: "var(--text-soft)" }}>to {formatTime12h(visit.assignment.windowEndTime)}</span>
        )}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 2 }}>
          <span style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{visit.title}</span>
          <Pill tone={requestStatusTone(visit.status)}>{visit.statusLabel}</Pill>
        </div>
        <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
          {visit.property?.name || visit.property?.address || "No address on file"}
        </div>
      </div>
      {visit.assignment && (
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <Avatar initials={initialsFor(visit.assignment.memberName)} size={28} />
          <span style={{ fontSize: 12, color: "var(--text)", fontWeight: 500 }}>
            {visit.assignment.memberName.split(" ")[0]}
          </span>
        </div>
      )}
      <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
    </Link>
  );
}

// ─── Decision row ───────────────────────────────────────────────

function DecisionRow({ visit }: { visit: VisitRow }) {
  const sub = visit.preferredTiming || visit.property?.address || formatRelativeTime(visit.updatedAt);
  // Section 19a — Chez-routed (source='haven') and emergency-urgency
  // requests get a small marker so the dispatcher knows the reply path
  // and how fast to act before they click in.
  const routedByChez = visit.source === "haven";
  const isEmergency = visit.urgency === "urgent";
  return (
    <Link to={`/visits/${visit.requestId}`} className="ops-row" style={{ borderBottom: "1px solid var(--neutral-200)", padding: "12px 0", textDecoration: "none", color: "inherit" }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: "var(--salmon-pale)", color: "var(--salmon-dark)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
        <Icon name={iconForRequest(visit.requestType)} size={18} stroke={1.9} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 2, flexWrap: "wrap" }}>
          <div style={{ fontSize: 13.5, color: "var(--text)", fontWeight: 600 }}>{visit.title}</div>
          {isEmergency && <Pill tone="critical">Emergency</Pill>}
          {routedByChez && <Pill tone="indigo">Routed by Chez</Pill>}
        </div>
        <div style={{ fontSize: 12, color: "var(--text-muted)" }}>
          {visit.property?.name ? `${visit.property.name} · ` : ""}{sub}
        </div>
      </div>
      <Pill tone={requestStatusTone(visit.status)}>{visit.statusLabel}</Pill>
      <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
    </Link>
  );
}

// ─── Recent thread row ──────────────────────────────────────────

function ThreadPreviewRow({ thread }: { thread: MessageThread }) {
  return (
    <Link to={`/messages?request=${thread.requestId}`} className="ops-row" style={{ borderBottom: "1px solid var(--neutral-200)", padding: "10px 0", textDecoration: "none", color: "inherit" }}>
      <Avatar initials={initialsFor(thread.propertyName || thread.title)} size={32} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 6 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{thread.propertyName || thread.title}</div>
          <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{formatRelativeTime(thread.latestMessageAt)}</div>
        </div>
        <div style={{ fontSize: 12, color: "var(--text-muted)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{thread.latestMessage}</div>
      </div>
    </Link>
  );
}

// ─── Empty states ───────────────────────────────────────────────

function EmptyFieldBoard({ hasAnyVisits }: { hasAnyVisits: boolean }) {
  return (
    <EmptyState
      icon="calendar"
      title={hasAnyVisits ? "Nothing on the board today" : "No visits scheduled yet"}
      body={hasAnyVisits ? "Today's a clean slate. Tomorrow's stops are still on the calendar." : "When a homeowner books a visit with you it shows up here. The Visit Hub on Chez is the easiest way to get started."}
    />
  );
}

function SmallEmpty({ icon, title, body }: { icon: string; title: string; body: string }) {
  return (
    <div style={{ padding: "16px 4px", display: "flex", gap: 10, alignItems: "flex-start" }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: "var(--neutral-200)", color: "var(--text-soft)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
        <Icon name={icon} size={16} stroke={1.9} />
      </div>
      <div>
        <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)", marginBottom: 2 }}>{title}</div>
        <div style={{ fontSize: 12, color: "var(--text-muted)", lineHeight: 1.5 }}>{body}</div>
      </div>
    </div>
  );
}

function LoadingShell() {
  return (
    <div style={{ padding: 48, fontSize: 14, color: "var(--text-muted)" }}>
      Loading your workspace…
    </div>
  );
}

// ─── Helpers ───────────────────────────────────────────────────

function formattedDate(): string {
  return new Date().toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" }).toUpperCase();
}

function formattedFullDate(): string {
  return new Date().toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" });
}

function pipelineTotal(quotes: { status: string; total: number }[]): number {
  return quotes
    .filter((q) => q.status === "sent" || q.status === "viewed")
    .reduce((sum, q) => sum + (q.total || 0), 0);
}

function requestStatusTone(status: RequestStatus): PillTone {
  // Salmon discipline (CLAUDE.md): salmon is reserved for SLA-critical /
  // counter-offered states only — never for routine status decoration.
  switch (status) {
    case "alternate_dates_proposed":
      // Truly counter-offered: needs your response to unblock.
      return "salmon";
    case "submitted":
    case "sent_to_handyman":
      // Routine inbound. Indigo says "in flight, no action yet."
      return "indigo";
    case "awaiting_homeowner":
      // Gentle attention: ball is in their court.
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
    case "cancelled":
    case "declined":
      return "neutral";
    case "quoted":
      return "warning";
    default:
      return "neutral";
  }
}

function quoteStatusTone(status: string): PillTone {
  switch (status) {
    case "draft": return "neutral";
    case "sent": return "info";
    case "viewed": return "indigo";
    case "approved": return "success";
    case "declined": return "critical";
    default: return "neutral";
  }
}

function toneCss(tone: PillTone): string {
  switch (tone) {
    case "indigo":   return "var(--indigo)";
    case "salmon":   return "var(--salmon)";
    case "success":  return "#4A7C59";
    case "warning":  return "#C77E2E";
    case "critical": return "#C25A5E";
    case "info":     return "#5A8DB5";
    default:         return "var(--neutral-300)";
  }
}

function iconForRequest(requestType: string): string {
  switch (requestType) {
    case "quote": return "quote";
    case "repair": return "truck";
    case "install":
    case "assembly": return "briefcase";
    case "question": return "message";
    case "setup": return "lightbulb";
    case "standard_visit":
    default: return "calendar";
  }
}
