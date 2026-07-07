// views/ops.js — how the desk is running (Phase D). Response times,
// effort per case, SLA hit rate, automation rate, and cost coordinated,
// over the last 30 and 7 days, plus a weekly trend and the playbook
// funnel. Backed by fetch_ops_metrics (the Phase 100 views).

import { callConcierge, ApiError } from "../api.js";
import { zone, unzone, invalidate, esc } from "../render.js";
import { bindActions } from "../actions.js";
import { toast } from "../components/toast.js";
import { fmtMoneyCents } from "../lib/format.js";

let data = null;
let loadError = false;
let disposeActions = null;

export function enter() {
  const root = document.getElementById("svc-view");
  root.innerHTML = `<div class="svc-ops" data-ops-zone></div>`;
  zone("ops", root.querySelector("[data-ops-zone]"), render);
  disposeActions = bindActions(root, { "retry": () => { data = null; load(); } });
  invalidate("ops");
  load();
}

async function load() {
  try {
    data = await callConcierge("fetch_ops_metrics");
    loadError = false;
  } catch (err) {
    loadError = true;
    if (err instanceof ApiError && err.status === 403) toast("Admin access required", "error");
  }
  invalidate("ops");
}

function fmtMinutes(m) {
  if (m == null) return "—";
  const n = Number(m);
  if (n < 60) return `${Math.round(n)}m`;
  return `${(n / 60).toFixed(1)}h`;
}
function fmtHours(h) { return h == null ? "—" : `${Number(h).toFixed(1)}h`; }
function fmtPct(r) { return r == null ? "—" : `${Math.round(Number(r) * 100)}%`; }

function metricGrid(label, m) {
  if (!m) return "";
  const cell = (v, l) => `<div class="svc-metric"><div class="svc-metric__val">${v}</div><div class="svc-metric__lbl">${l}</div></div>`;
  return `
    <section class="svc-ops-block">
      <h2 class="svc-agenda-day__label">${esc(label)}</h2>
      <div class="svc-metric-row">
        ${cell(m.opened ?? 0, "Opened")}
        ${cell(m.resolved ?? 0, "Resolved")}
        ${cell(fmtMinutes(m.median_first_response_minutes), "Median first response")}
        ${cell(fmtHours(m.median_resolution_hours), "Median resolution")}
        ${cell(fmtPct(m.sla_hit_rate), "SLA hit rate")}
        ${cell(m.avg_touches ?? "—", "Touches / case")}
        ${cell(fmtPct(m.automation_rate), "Automation rate")}
        ${cell(fmtMinutes(m.median_effort_minutes), "Median effort")}
        ${cell(m.total_final_cost_cents ? fmtMoneyCents(m.total_final_cost_cents) : "$0", "Coordinated cost")}
      </div>
    </section>
  `;
}

function render() {
  if (loadError) return `<div class="svc-empty">Couldn't load ops metrics. <button class="svc-link" data-action="retry">Try again</button></div>`;
  if (!data) return `<div class="svc-loading">Loading ops metrics...</div>`;

  const funnel = Array.isArray(data.playbook_funnel) ? data.playbook_funnel : [];
  const funnelBlock = funnel.length ? `
    <section class="svc-ops-block">
      <h2 class="svc-agenda-day__label">Playbook funnel</h2>
      <div class="svc-sec"><div class="svc-sec__rows">
        ${funnel.map((f) => `<div class="svc-sec__row">${esc(f.playbook_mode || f.mode || "playbook")} <span class="svc-dim">${f.count ?? f.total ?? 0} case${(f.count ?? f.total ?? 0) === 1 ? "" : "s"}</span></div>`).join("")}
      </div></div>
    </section>` : "";

  return `
    <header class="svc-view-head">
      <h1 class="svc-view-title">Ops</h1>
      <p class="svc-view-sub">How the desk is running</p>
    </header>
    ${metricGrid("Last 30 days", data.last_30_days)}
    ${metricGrid("Last 7 days", data.last_7_days)}
    ${funnelBlock}
  `;
}

export function leave() {
  unzone("ops");
  disposeActions?.();
  disposeActions = null;
  const root = document.getElementById("svc-view");
  if (root) root.innerHTML = "";
}
