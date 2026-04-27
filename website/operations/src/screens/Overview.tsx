import { useMemo } from "react";
import { Card } from "../components/chrome/Card";
import { Pill } from "../components/chrome/Pill";
import { StatTile } from "../components/chrome/StatTile";
import { Avatar, initialsFor } from "../components/chrome/Avatar";
import { Icon } from "../components/chrome/Icon";
import { useWorkspace } from "../lib/workspace-context";
import {
  CREW_DEMO,
  KPIS_DEMO,
  PIPELINE_DEMO,
  RECENT_THREADS_DEMO,
  REQUESTS_DECISIONS_DEMO,
  VISITS_DEMO,
  formatCurrencyCents,
  isDemoMode,
} from "../lib/fixtures";

export default function OverviewScreen() {
  const { mode, member, workspace } = useWorkspace();
  const _demo = isDemoMode();
  // v1: data is fixture-backed regardless of `_demo` because the live
  // schema's aggregation views aren't wired yet. Once the dispatch
  // table is loaded for real, swap the fixtures for the live `api.ts`
  // queries — every render path below is structured to receive either.
  void _demo;

  const heroSnapshot = useMemo(() => {
    const total = VISITS_DEMO.length;
    const done = VISITS_DEMO.filter((v) => v.status === "on-the-way").length;
    const togo = total - done;
    return { total, done, ontheway: 0, togo };
  }, []);

  const personHero = mode === "sole";
  const greetName = member?.full_name?.split(" ")[0] ?? "Tom";
  const orgLabel = workspace?.company_name ?? "Burke Handymen";

  return (
    <>
      <Hero
        eyebrow={
          personHero
            ? `${greetName.toUpperCase()} · ${formattedDate()}`
            : `OPERATIONS · ${formattedDate()}`
        }
        headline={
          personHero
            ? "Four stops today, finished by "
            : "Own the queue, route the field "
        }
        emphasis={personHero ? "3:30." : "team."}
        primaryCta={{ label: "Open my day →" }}
        secondaryCta={{ label: "New quote" }}
        tertiaryCta={{ label: "Auto-route the day", icon: "sparkles" }}
        snapshot={{
          label: "Today snapshot",
          value: heroSnapshot.total,
          done: heroSnapshot.done,
          ontheway: heroSnapshot.ontheway,
          togo: heroSnapshot.togo,
        }}
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
              <Pill tone="neutral">All techs</Pill>
              <Pill tone="salmon">Unassigned · 4</Pill>
              <button className="ops-button ops-button--ghost" style={{ height: 28, padding: "4px 10px", fontSize: 12 }}>
                <Icon name="filter" size={13} stroke={1.9} /> Filter
              </button>
            </div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            {VISITS_DEMO.map((v) => (
              <FieldBoardRow key={v.id} visit={v} />
            ))}
          </div>
        </Card>

        {/* RIGHT — Decision queue + Pipeline + Threads */}
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>Needs your decision</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
              {REQUESTS_DECISIONS_DEMO.map((d) => (
                <button key={d.id} className="ops-row" style={{ background: "none", border: "none", borderBottom: "1px solid var(--neutral-200)", padding: "12px 0", textAlign: "left", cursor: "pointer", width: "100%" }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: "var(--salmon-pale)", color: "var(--salmon-dark)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
                    <Icon name={d.icon} size={18} stroke={1.9} />
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13.5, color: "var(--text)", fontWeight: 600, marginBottom: 2 }}>{d.title}</div>
                    <div style={{ fontSize: 12, color: "var(--text-muted)" }}>{d.sub}</div>
                  </div>
                  <Icon name="chevron" size={14} color="var(--text-soft)" stroke={2} />
                </button>
              ))}
            </div>
          </Card>

          <Card padding="default">
            <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 12 }}>
              <div>
                <div className="ops-section-label">Quote pipeline</div>
                <div style={{ fontFamily: "var(--serif)", fontSize: 28, fontWeight: 700, color: "var(--indigo)", letterSpacing: "-0.018em", lineHeight: 1.05 }}>
                  {formatCurrencyCents(PIPELINE_DEMO.totalCents)}
                </div>
              </div>
              <Pill tone="indigo">5 quotes</Pill>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 8 }}>
              {PIPELINE_DEMO.buckets.map((b) => (
                <div key={b.label}>
                  <div style={{ height: 3, borderRadius: 2, background: toneColor(b.tone), marginBottom: 6 }} />
                  <div style={{ fontSize: 11, color: "var(--text-soft)", letterSpacing: "0.06em", textTransform: "uppercase", fontWeight: 600 }}>{b.label}</div>
                  <div style={{ fontFamily: "var(--serif)", fontSize: 18, color: "var(--text)", fontWeight: 700 }}>{b.count}</div>
                </div>
              ))}
            </div>
          </Card>

          <Card padding="default">
            <div className="ops-section-label" style={{ marginBottom: 12 }}>Recent threads</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
              {RECENT_THREADS_DEMO.map((t) => (
                <button key={t.id} className="ops-row" style={{ background: "none", border: "none", borderBottom: "1px solid var(--neutral-200)", padding: "10px 0", textAlign: "left", cursor: "pointer", width: "100%" }}>
                  <Avatar initials={initialsFor(t.from)} size={32} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 6 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{t.from}</div>
                      <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{t.timestamp}</div>
                    </div>
                    <div style={{ fontSize: 12, color: "var(--text-muted)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{t.preview}</div>
                  </div>
                  {t.unread > 0 && <Pill tone="salmon">{t.unread} new</Pill>}
                </button>
              ))}
            </div>
          </Card>
        </div>
      </div>

      {mode === "crew" && (
        <div style={{ marginTop: 24 }}>
          <div className="ops-section-label" style={{ marginBottom: 10 }}>Crew workload</div>
          <div className="ops-grid-3col">
            {CREW_DEMO.filter((c) => c.role !== "Owner").map((c) => (
              <CrewWorkloadCard key={c.id} member={c} />
            ))}
          </div>
        </div>
      )}

      <div style={{ height: 60 }} />
      <div style={{ fontSize: 11, color: "var(--text-soft)", textAlign: "center" }}>
        {orgLabel} · {personHero ? "Sole proprietor" : `${CREW_DEMO.length} teammates`}
      </div>
    </>
  );
}

// ─── Hero ────────────────────────────────────────────────────────

function Hero(props: {
  eyebrow: string;
  headline: string;
  emphasis: string;
  primaryCta: { label: string };
  secondaryCta: { label: string };
  tertiaryCta?: { label: string; icon: string };
  snapshot: { label: string; value: number; done: number; ontheway: number; togo: number };
}) {
  const total = Math.max(props.snapshot.value, 1);
  const donePct = (props.snapshot.done / total) * 100;
  const ontheWayPct = (props.snapshot.ontheway / total) * 100;
  const togoPct = (props.snapshot.togo / total) * 100;
  return (
    <div className="ops-hero">
      <div>
        <div className="ops-hero__eyebrow">{props.eyebrow}</div>
        <h1 className="ops-hero__headline">
          {props.headline}<em>{props.emphasis}</em>
        </h1>
        <div className="ops-hero__cta-row">
          <button className="ops-button ops-button--salmon">{props.primaryCta.label}</button>
          <button className="ops-button ops-button--ghost">{props.secondaryCta.label}</button>
          {props.tertiaryCta && (
            <button className="ops-button ops-button--ghost">
              <Icon name={props.tertiaryCta.icon} size={14} stroke={1.9} /> {props.tertiaryCta.label}
            </button>
          )}
        </div>
      </div>
      <div className="ops-hero__snapshot">
        <div className="ops-hero__snapshot-label">{props.snapshot.label}</div>
        <div className="ops-hero__snapshot-value">{props.snapshot.value}</div>
        <div className="ops-hero__snapshot-bar">
          <div className="ops-hero__snapshot-bar-segment ops-hero__snapshot-bar-segment--done" style={{ width: `${donePct}%` }} />
          <div className="ops-hero__snapshot-bar-segment ops-hero__snapshot-bar-segment--ontheway" style={{ width: `${ontheWayPct}%` }} />
          <div className="ops-hero__snapshot-bar-segment ops-hero__snapshot-bar-segment--togo" style={{ width: `${togoPct}%` }} />
        </div>
        <div className="ops-hero__snapshot-legend">
          <span>{props.snapshot.done} done</span>
          <span>{props.snapshot.ontheway} on the way</span>
          <span>{props.snapshot.togo} to go</span>
        </div>
      </div>
    </div>
  );
}

// ─── KPI strip ──────────────────────────────────────────────────

function KpiStrip() {
  return (
    <div className="ops-grid-kpis">
      {KPIS_DEMO.map((k) => (
        <StatTile key={k.label} label={k.label} value={k.value} sub={k.sub} accent={k.accent} />
      ))}
    </div>
  );
}

// ─── Field board row ───────────────────────────────────────────

function FieldBoardRow({ visit }: { visit: typeof VISITS_DEMO[number] }) {
  const tech = CREW_DEMO.find((c) => c.id === visit.tech);
  return (
    <div className="ops-row" style={{ padding: "10px 0" }}>
      <div style={{ width: 70, flex: "none", display: "flex", flexDirection: "column" }}>
        <span style={{ fontFamily: "var(--serif)", fontSize: 14, color: "var(--text)", fontWeight: 600 }}>{visit.time}</span>
        <span style={{ fontSize: 11, color: "var(--text-soft)" }}>{visit.duration} min</span>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 2 }}>
          <span style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{visit.title}</span>
          {visit.bundle && <Pill tone="indigo">Bundle</Pill>}
          {visit.priority === "high" && <Pill tone="critical">High</Pill>}
        </div>
        <div style={{ fontSize: 12, color: "var(--text-muted)" }}>{visit.home}</div>
      </div>
      {tech && (
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <Avatar initials={tech.avatar} color={tech.color} size={28} />
          <span style={{ fontSize: 12, color: "var(--text)", fontWeight: 500 }}>{tech.name.split(" ")[0]}</span>
        </div>
      )}
      <Pill tone={visit.status === "on-the-way" ? "salmon" : "indigo"} withDot>
        {visit.status === "on-the-way" ? "On the way" : "Scheduled"}
      </Pill>
      <button style={{ background: "none", border: "none", color: "var(--text-soft)", cursor: "pointer", padding: 4 }} aria-label="More">
        <Icon name="more" size={16} stroke={1.9} />
      </button>
    </div>
  );
}

// ─── Crew workload ─────────────────────────────────────────────

function CrewWorkloadCard({ member }: { member: typeof CREW_DEMO[number] }) {
  const today = Math.floor(Math.random() * 4) + 2;
  const open = Math.floor(Math.random() * 6) + 2;
  const cap = Math.min(100, today * 15 + open * 4);
  return (
    <Card padding="tight">
      <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
        <Avatar initials={member.avatar} color={member.color} size={32} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text)" }}>{member.name}</div>
          <div style={{ fontSize: 11, color: "var(--text-soft)" }}>{member.title}</div>
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
}

// ─── Helpers ───────────────────────────────────────────────────

function formattedDate(): string {
  return new Date().toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" }).toUpperCase();
}

function formattedFullDate(): string {
  return new Date().toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" });
}

function toneColor(tone: "neutral" | "indigo" | "salmon" | "success" | "warning" | "critical" | "info"): string {
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
