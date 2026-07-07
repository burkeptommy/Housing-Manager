// views/today.js — the operator's start-of-day surface.
//
// Hero greeting + count chips (boot.today.stats), then severity sections:
// Overdue / Due soon / Unread replies / Today's visits / Upcoming. Rows show
// household + summary + slaPill + snapshotChips; clicking a row opens
// #/case/:id. Keyboard: j/k move the selection, Enter opens it (bound while
// this view is mounted, suppressed automatically while typing).
//
// One zone ("today") renders the whole column; the scroll container lives
// OUTSIDE the zone so repaints (j/k selection) never reset scroll position.

import { state, refreshQueue } from "../state.js";
import { zone, unzone, invalidate, esc } from "../render.js";
import { bindActions, bindShortcuts } from "../actions.js";
import { navigate } from "../router.js";
import { toast } from "../components/toast.js";
import { slaPill, categoryGlyph, snapshotChips } from "../components/pills.js";
import { fmtAgo, fmtDate, truncate } from "../lib/format.js";

let disposeActions = null;
let disposeKeys = null;
let selIndex = -1;
let refreshing = false;

export function enter() {
  const root = document.getElementById("svc-view");
  if (!root) return;
  selIndex = -1;
  refreshing = false;
  root.innerHTML = `
    <div class="svc-today">
      <div class="svc-today__col" data-today-zone></div>
    </div>
  `;
  zone("today", root.querySelector("[data-today-zone]"), renderToday);
  disposeActions = bindActions(root, {
    "open-case": (el) => {
      if (el.dataset.id) navigate(`#/case/${encodeURIComponent(el.dataset.id)}`);
    },
    "refresh": () => doRefresh(),
    "jump": (el) => {
      document.getElementById(el.dataset.target)?.scrollIntoView({ behavior: "smooth", block: "start" });
    },
  });
  disposeKeys = bindShortcuts({
    j: () => moveSelection(1),
    k: () => moveSelection(-1),
    Enter: () => openSelection(),
  });
}

export function leave() {
  unzone("today");
  disposeActions?.();
  disposeKeys?.();
  disposeActions = null;
  disposeKeys = null;
  const root = document.getElementById("svc-view");
  if (root) root.innerHTML = "";
}

// ── Data shaping ────────────────────────────────────────────────────────────

function brief() {
  return state.boot?.today || {};
}

function overdueRows() {
  return (brief().urgent_cases || []).filter((r) => r.severity === "overdue");
}

function dueSoonRows() {
  return (brief().urgent_cases || []).filter((r) => r.severity === "due_soon");
}

// Unread replies: the 48h message excerpts, plus any unread-severity cases
// the excerpt window missed. Deduped by request id.
function unreadRows() {
  const t = brief();
  const rows = [];
  const seen = new Set();
  for (const m of t.recent_unread || []) {
    if (seen.has(m.request_id)) continue;
    seen.add(m.request_id);
    rows.push({
      id: m.request_id,
      household_id: m.household_id,
      household_name: m.household_name,
      household_address: m.household_address,
      category: m.category,
      summary: m.summary,
      excerpt: m.excerpt,
      sent_at: m.sent_at,
    });
  }
  for (const r of (t.urgent_cases || []).filter((c) => c.severity === "unread")) {
    if (seen.has(r.id)) continue;
    seen.add(r.id);
    rows.push({
      id: r.id,
      household_id: r.household_id,
      household_name: r.household_name,
      household_address: r.household_address,
      category: r.category,
      summary: r.summary,
      excerpt: null,
      sent_at: r.last_message_at,
    });
  }
  return rows;
}

function todaysVisits() {
  return brief().todays_visits || [];
}

function upcomingVisits() {
  return brief().upcoming_visits || [];
}

// Keyboard-selectable rows, in exact render order. Visits without a linked
// case aren't selectable (nothing to open).
function selectables() {
  const rows = [];
  for (const r of overdueRows()) rows.push(r.id);
  for (const r of dueSoonRows()) rows.push(r.id);
  for (const r of unreadRows()) rows.push(r.id);
  for (const v of todaysVisits()) if (v.request_id) rows.push(v.request_id);
  for (const v of upcomingVisits()) if (v.request_id) rows.push(v.request_id);
  return rows;
}

function moveSelection(delta) {
  const list = selectables();
  if (!list.length) return;
  selIndex = Math.min(Math.max(selIndex + delta, 0), list.length - 1);
  invalidate("today");
  queueMicrotask(() => {
    document.querySelector(".svc-row.is-selected")?.scrollIntoView({ block: "nearest" });
  });
}

function openSelection() {
  const list = selectables();
  if (selIndex < 0 || selIndex >= list.length) return;
  navigate(`#/case/${encodeURIComponent(list[selIndex])}`);
}

async function doRefresh() {
  if (refreshing) return;
  refreshing = true;
  invalidate("today");
  try {
    await refreshQueue();
    selIndex = -1;
  } catch (err) {
    console.warn("[today] refresh failed", err);
    toast("Couldn't refresh the brief. Try again in a moment.", "error");
  } finally {
    refreshing = false;
    invalidate("today");
  }
}

// ── Rendering ───────────────────────────────────────────────────────────────

function renderToday() {
  if (!state.boot) {
    return '<div class="svc-empty">Loading the brief…</div>';
  }
  // Visits without a linked case aren't selectable; keep the keyboard index
  // aligned with selectables() by only advancing it for linked rows.
  let visitSel = 0;
  const visitRows = todaysVisits().map((v) =>
    visitRow(v, v.request_id ? selKeyFor("visits", visitSel++) : -1, true)
  );
  const sections = [
    section("sec-overdue", "Overdue", overdueRows().map((r, i) => caseRow(r, selKeyFor("overdue", i)))),
    section("sec-due-soon", "Due within 6 hours", dueSoonRows().map((r, i) => caseRow(r, selKeyFor("due_soon", i)))),
    section("sec-unread", "Unread replies", unreadRows().map((r, i) => unreadRow(r, selKeyFor("unread", i)))),
    section("sec-visits", "Today's visits", visitRows),
    upcomingSection(),
  ].filter(Boolean);

  return `
    ${hero()}
    ${sections.length ? sections.join("") : allClear()}
    <p class="svc-keyhint">j / k move &middot; Enter opens &middot; &#8984;K search</p>
  `;
}

// Absolute selection index for a row, matching selectables() order.
function selKeyFor(group, indexInGroup) {
  const counts = {
    overdue: 0,
    due_soon: overdueRows().length,
  };
  counts.unread = counts.due_soon + dueSoonRows().length;
  counts.visits = counts.unread + unreadRows().length;
  counts.upcoming = counts.visits + todaysVisits().filter((v) => v.request_id).length;
  return counts[group] + indexInGroup;
}

function hero() {
  const now = new Date();
  const hour = now.getHours();
  let greeting;
  if (hour < 5) greeting = "Late shift";
  else if (hour < 12) greeting = "Good morning";
  else if (hour < 17) greeting = "Good afternoon";
  else greeting = "Good evening";

  const dateStr = now.toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" });
  const s = brief().stats || {};

  let headline;
  if ((s.sla_overdue || 0) > 0) {
    headline = `${s.sla_overdue} ${s.sla_overdue === 1 ? "case is" : "cases are"} past SLA.`;
  } else if ((s.sla_due_soon || 0) > 0) {
    headline = `${s.sla_due_soon} ${s.sla_due_soon === 1 ? "case is" : "cases are"} due within 6 hours.`;
  } else if ((s.visits_today || 0) > 0) {
    headline = `${s.visits_today} vendor ${s.visits_today === 1 ? "visit is" : "visits are"} scheduled today.`;
  } else if ((s.open_cases || 0) > 0) {
    headline = `All caught up on SLAs. ${s.open_cases} ${s.open_cases === 1 ? "case" : "cases"} open.`;
  } else {
    headline = "All clear. No open cases.";
  }

  const fetchedAt = brief().fetched_at || null;
  const updated = fetchedAt ? `Updated ${fmtAgo(fetchedAt)}` : "";

  return `
    <header class="svc-hero">
      <div class="svc-hero__row">
        <div class="svc-hero__text">
          <p class="svc-eyebrow">${esc(dateStr)} &middot; Start of day</p>
          <h1 class="svc-hero__title">${greeting}.</h1>
          <p class="svc-hero__sub">${esc(headline)}</p>
        </div>
        <div class="svc-hero__side">
          <button type="button" class="svc-btn svc-btn--ghost svc-btn--small" data-action="refresh"${refreshing ? " disabled" : ""}>${refreshing ? "Refreshing…" : "Refresh"}</button>
          ${updated ? `<span class="svc-hero__updated">${esc(updated)}</span>` : ""}
        </div>
      </div>
      <div class="svc-hero__chips">
        ${statChip(s.sla_overdue, "past SLA", { alert: true, target: "sec-overdue" })}
        ${statChip(s.sla_due_soon, "due soon", { target: "sec-due-soon" })}
        ${statChip(s.visits_today, "visits today", { target: "sec-visits" })}
        ${statChip(s.open_cases, "open")}
        ${statChip(s.homes_under_management, "homes")}
      </div>
    </header>
  `;
}

function statChip(value, label, { alert = false, target = null } = {}) {
  const n = value ?? 0;
  const cls = [
    "svc-statchip",
    alert && n > 0 ? "svc-statchip--alert" : "",
    n === 0 ? "svc-statchip--zero" : "",
  ].filter(Boolean).join(" ");
  const inner = `<strong>${n}</strong> ${esc(label)}`;
  if (target && n > 0) {
    return `<button type="button" class="${cls}" data-action="jump" data-target="${target}">${inner}</button>`;
  }
  return `<span class="${cls}">${inner}</span>`;
}

function section(id, label, rows) {
  if (!rows.length) return "";
  return `
    <section class="svc-section" id="${id}">
      <div class="svc-section__head">
        <h2 class="svc-section-label">${label}</h2>
        <span class="svc-section__count">${rows.length}</span>
      </div>
      <div class="svc-rowlist">${rows.join("")}</div>
    </section>
  `;
}

function upcomingSection() {
  const visits = upcomingVisits();
  if (!visits.length) return "";
  // Group by day, preserving order (payload arrives sorted by scheduled_for).
  const groups = [];
  const byDay = new Map();
  let selectableIndex = 0;
  for (const v of visits) {
    const day = dayLabel(v.scheduled_for);
    if (!byDay.has(day)) {
      byDay.set(day, []);
      groups.push(day);
    }
    const idx = v.request_id ? selKeyFor("upcoming", selectableIndex++) : -1;
    byDay.get(day).push(visitRow(v, idx, false));
  }
  const body = groups
    .map((day) => `<div class="svc-dayhead">${esc(day)}</div>${byDay.get(day).join("")}`)
    .join("");
  return `
    <section class="svc-section" id="sec-upcoming">
      <div class="svc-section__head">
        <h2 class="svc-section-label">Upcoming &middot; next 7 days</h2>
        <span class="svc-section__count">${visits.length}</span>
      </div>
      <div class="svc-rowlist">${body}</div>
    </section>
  `;
}

function dayLabel(iso) {
  if (!iso) return "Unscheduled";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "Unscheduled";
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(today.getDate() + 1);
  const sameDay = (a, b) =>
    a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  if (sameDay(d, today)) return "Today";
  if (sameDay(d, tomorrow)) return "Tomorrow";
  return `${d.toLocaleDateString(undefined, { weekday: "short" })}, ${fmtDate(d)}`;
}

// Case rows join the boot queue by id so server-derived snapshot chips
// (budget, timing, work-order readiness) show on the brief too.
function chipsFor(row) {
  const queueRow = state.queue.find((q) => q.id === row.id);
  return snapshotChips(queueRow || row);
}

function rowShell(inner, { selectable, selected, caseId }) {
  const cls = ["svc-row", selected ? "is-selected" : "", selectable ? "" : "svc-row--static"]
    .filter(Boolean)
    .join(" ");
  if (!selectable) return `<div class="${cls}">${inner}</div>`;
  return `<div class="${cls}" role="button" tabindex="0" data-action="open-case" data-id="${esc(caseId)}">${inner}</div>`;
}

function household(row) {
  const name = row.household_name || "Household";
  const addr = row.household_address && row.household_address !== row.household_name ? row.household_address : "";
  return `
    <span class="svc-row__who">${esc(name)}</span>
    ${addr ? `<span class="svc-row__where">${esc(addr)}</span>` : ""}
  `;
}

function caseRow(row, absIndex) {
  const inner = `
    <div class="svc-row__top">
      ${household(row)}
      <span class="svc-row__spacer"></span>
      ${row.pending_proposal_count > 0 ? '<span class="svc-chip svc-chip--ready">Proposal out</span>' : ""}
      ${slaPill(row)}
    </div>
    <div class="svc-row__sub">
      ${categoryGlyph(row.category)}
      <span class="svc-row__summary">${esc(truncate(row.summary, 110))}</span>
    </div>
    ${chipsFor(row)}
  `;
  return rowShell(inner, { selectable: true, selected: absIndex === selIndex, caseId: row.id });
}

function unreadRow(row, absIndex) {
  const inner = `
    <div class="svc-row__top">
      ${household(row)}
      <span class="svc-row__spacer"></span>
      ${row.sent_at ? `<span class="svc-row__ago">${esc(fmtAgo(row.sent_at))}</span>` : ""}
      <span class="svc-pill svc-pill--unread">Unread</span>
    </div>
    <div class="svc-row__sub">
      ${categoryGlyph(row.category)}
      <span class="svc-row__summary">${esc(truncate(row.summary, 110))}</span>
    </div>
    ${row.excerpt ? `<p class="svc-row__excerpt">${esc(truncate(row.excerpt, 160))}</p>` : ""}
    ${chipsFor(row)}
  `;
  return rowShell(inner, { selectable: true, selected: absIndex === selIndex, caseId: row.id });
}

function visitRow(visit, absIndex, showTime) {
  const time = visit.scheduled_window
    ? visit.scheduled_window
    : visit.scheduled_for
      ? new Date(visit.scheduled_for).toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" })
      : "";
  const stateLabel = visit.state === "awaiting_date" ? "Awaiting date" : visit.state === "in_progress" ? "In progress" : "";
  const inner = `
    <div class="svc-row__top">
      ${showTime && time ? `<span class="svc-row__time">${esc(time)}</span>` : ""}
      <span class="svc-row__who">${esc(visit.vendor_name || "Vendor")}</span>
      <span class="svc-row__where">${esc(visit.household_name || visit.household_address || "")}</span>
      <span class="svc-row__spacer"></span>
      ${stateLabel ? `<span class="svc-pill svc-pill--muted">${esc(stateLabel)}</span>` : ""}
      ${!showTime && time ? `<span class="svc-row__ago">${esc(time)}</span>` : ""}
    </div>
    ${visit.notes ? `<div class="svc-row__sub"><span class="svc-row__summary">${esc(truncate(visit.notes, 110))}</span></div>` : ""}
    ${visit.request_id ? "" : '<div class="svc-row__sub"><span class="svc-row__nolink">No linked case</span></div>'}
  `;
  return rowShell(inner, {
    selectable: !!visit.request_id,
    selected: absIndex === selIndex && absIndex >= 0,
    caseId: visit.request_id || "",
  });
}

function allClear() {
  return `
    <div class="svc-allclear">
      <div class="svc-allclear__mark" aria-hidden="true">&#10003;</div>
      <h2 class="svc-allclear__title">All clear.</h2>
      <p class="svc-allclear__sub">No overdue cases, no unread replies, and no visits on the books. Enjoy the quiet.</p>
    </div>
  `;
}
