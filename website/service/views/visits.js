// views/visits.js — the visit agenda across every home. Phase C: a
// read-first calendar sourced from fetch_upcoming's visit-flavored
// entries (vendor visits + routine visits), grouped by day, each row
// offering an .ics download and a jump into its case. Completion and
// no-show tracking happen inside the case cockpit; this is the operator's
// cross-home "what's coming" surface.

import { callConcierge, ApiError } from "../api.js";
import { zone, unzone, invalidate, esc } from "../render.js";
import { bindActions } from "../actions.js";
import { navigate } from "../router.js";
import { toast } from "../components/toast.js";
import { buildVisitICS, downloadICS } from "../lib/ics.js";

let items = null;
let loadError = false;
let disposeActions = null;

const VISIT_TYPES = new Set(["chez_visit", "routine_visit"]);

export function enter() {
  const root = document.getElementById("svc-view");
  root.innerHTML = `<div class="svc-visits" data-visits-zone></div>`;
  zone("visits", root.querySelector("[data-visits-zone]"), render);
  disposeActions = bindActions(root, {
    "ics": (elm) => downloadForRow(elm.dataset.id),
    "open-case": (elm) => { if (elm.dataset.caseId) navigate(`#/case/${encodeURIComponent(elm.dataset.caseId)}`); },
    "retry": () => { items = null; load(); },
  });
  invalidate("visits");
  load();
}

async function load() {
  try {
    const res = await callConcierge("fetch_upcoming", { window_days: 14 });
    const all = Array.isArray(res.items) ? res.items : [];
    items = all.filter((i) => VISIT_TYPES.has(i.type) && i.due_at);
    loadError = false;
  } catch (err) {
    loadError = true;
    if (err instanceof ApiError && err.status === 403) toast("Admin access required", "error");
  }
  invalidate("visits");
}

function dayKey(iso) {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? "unknown" : d.toISOString().slice(0, 10);
}

function dayLabel(key) {
  const d = new Date(key + "T12:00:00");
  const today = new Date().toISOString().slice(0, 10);
  const tomorrow = new Date(Date.now() + 86400000).toISOString().slice(0, 10);
  if (key === today) return "Today";
  if (key === tomorrow) return "Tomorrow";
  return d.toLocaleDateString("en-US", { weekday: "long", month: "short", day: "numeric" });
}

function timeLabel(iso) {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? "" : d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
}

function render() {
  if (loadError) {
    return `<div class="svc-empty">Couldn't load the visit agenda. <button class="svc-link" data-action="retry">Try again</button></div>`;
  }
  if (!items) return `<div class="svc-loading">Loading visits...</div>`;

  const rows = [...items].sort((a, b) => String(a.due_at).localeCompare(String(b.due_at)));
  if (rows.length === 0) {
    return `
      <header class="svc-view-head">
        <h1 class="svc-view-title">Visits</h1>
        <p class="svc-view-sub">Next 14 days</p>
      </header>
      <div class="svc-empty">Nothing on the calendar in the next 14 days.</div>
    `;
  }

  // Group by day.
  const groups = new Map();
  for (const r of rows) {
    const k = dayKey(r.due_at);
    if (!groups.has(k)) groups.set(k, []);
    groups.get(k).push(r);
  }

  const groupHtml = [...groups.entries()].map(([key, dayRows]) => `
    <section class="svc-agenda-day">
      <h2 class="svc-agenda-day__label">${esc(dayLabel(key))}</h2>
      <div class="svc-agenda-day__rows">
        ${dayRows.map(rowHtml).join("")}
      </div>
    </section>
  `).join("");

  return `
    <header class="svc-view-head">
      <h1 class="svc-view-title">Visits</h1>
      <p class="svc-view-sub">${rows.length} visit${rows.length === 1 ? "" : "s"} · next 14 days</p>
    </header>
    ${groupHtml}
  `;
}

function rowHtml(r) {
  const isVendor = r.type === "chez_visit";
  const caseId = r.request_id || "";
  return `
    <div class="svc-agenda-row">
      <div class="svc-agenda-row__time">${esc(timeLabel(r.due_at))}</div>
      <div class="svc-agenda-row__main">
        <div class="svc-agenda-row__title">${esc(r.title || "Visit")}</div>
        <div class="svc-agenda-row__sub">${esc(r.household_name || "")}${isVendor ? "" : " · routine"}</div>
      </div>
      <div class="svc-agenda-row__actions">
        <button class="svc-btn svc-btn--ghost" data-action="ics" data-id="${esc(r.id)}">Add to calendar</button>
        ${caseId ? `<button class="svc-btn svc-btn--ghost" data-action="open-case" data-case-id="${esc(caseId)}">Open case</button>` : ""}
      </div>
    </div>
  `;
}

function downloadForRow(id) {
  const r = (items || []).find((x) => String(x.id) === String(id));
  if (!r) return;
  const ics = buildVisitICS({
    uid: r.id,
    start: r.due_at,
    durationMinutes: 60,
    summary: `${r.title || "Chez visit"} — ${r.household_name || ""}`.trim(),
    location: r.household_name || "",
    description: "Scheduled through the Chez service portal.",
  });
  if (!ics) { toast("This visit has no scheduled time yet.", "error"); return; }
  downloadICS(`chez-visit-${dayKey(r.due_at)}`, ics);
  toast("Calendar file downloaded", "success");
}

export function leave() {
  unzone("visits");
  disposeActions?.();
  disposeActions = null;
  const root = document.getElementById("svc-view");
  if (root) root.innerHTML = "";
}
