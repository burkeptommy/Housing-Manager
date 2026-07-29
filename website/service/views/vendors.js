// views/vendors.js — the cross-household vendor registry (Phase D). The
// first UI where the Phase 100 registry becomes an operator asset: who
// answers, who quotes fairly, who wins jobs, who no-shows. List →
// per-vendor drilldown (every call, outreach, and visit across homes).

import { callConcierge, ApiError } from "../api.js";
import { zone, unzone, invalidate, esc } from "../render.js";
import { bindActions } from "../actions.js";
import { navigate } from "../router.js";
import { toast } from "../components/toast.js";
import { fmtDate, fmtMoneyCents } from "../lib/format.js";

let listData = null;
let listError = false;
let search = "";
let detailKey = null;
let detailData = null;
let detailError = false;
let disposeActions = null;

function pct(v) { return v == null ? "—" : `${Math.round(Number(v) * 100)}%`; }

// ── List ────────────────────────────────────────────────────────────

export function enterList() {
  detailKey = null; detailData = null;
  const root = document.getElementById("svc-view");
  root.innerHTML = `<div class="svc-vendors" data-vendors-zone></div>`;
  zone("vendors", root.querySelector("[data-vendors-zone]"), renderList);
  bindListActions(root);
  invalidate("vendors");
  loadList();
}

async function loadList() {
  try {
    const res = await callConcierge("fetch_vendor_registry", { limit: 100 });
    listData = Array.isArray(res.vendors) ? res.vendors : [];
    listError = false;
  } catch (err) {
    listError = true;
    if (err instanceof ApiError && err.status === 403) toast("Admin access required", "error");
  }
  invalidate("vendors");
}

function filtered() {
  const q = search.trim().toLowerCase();
  const rows = listData || [];
  if (!q) return rows;
  return rows.filter((v) =>
    String(v.display_name || "").toLowerCase().includes(q) ||
    (Array.isArray(v.categories) && v.categories.some((c) => String(c).toLowerCase().includes(q))));
}

function renderList() {
  if (listError) return `<div class="svc-empty">Couldn't load the vendor registry. <button class="svc-link" data-action="retry">Try again</button></div>`;
  if (!listData) return `<div class="svc-loading">Loading vendors...</div>`;
  const rows = filtered();
  const cards = rows.map((v) => `
    <button class="svc-vendor-row" data-action="open-vendor" data-key="${esc(v.vendor_key)}">
      <div class="svc-vendor-row__main">
        <div class="svc-vendor-row__name">${esc(v.display_name || "Vendor")}
          ${v.chez_sourced ? `<span class="svc-chip svc-chip--accent">Chez network</span>` : ""}
        </div>
        <div class="svc-vendor-row__cats">${esc((v.categories || []).slice(0, 3).join(", "))}${(v.towns || []).length ? ` · ${esc((v.towns || [])[0])}` : ""}</div>
      </div>
      <div class="svc-vendor-row__stats">
        <span title="Times called / answer rate">${v.times_called || 0} calls · ${pct(v.answer_rate)}</span>
        <span title="Jobs won">${v.jobs_won || 0} won</span>
        ${v.no_shows ? `<span class="svc-stat-warn" title="No-shows">${v.no_shows} no-show${v.no_shows === 1 ? "" : "s"}</span>` : ""}
        ${v.avg_quoted_cost_cents ? `<span title="Average quote">${fmtMoneyCents(v.avg_quoted_cost_cents)} avg</span>` : ""}
      </div>
    </button>
  `).join("");
  return `
    <header class="svc-view-head">
      <h1 class="svc-view-title">Vendors</h1>
      <p class="svc-view-sub">${(listData || []).length} vendor${(listData || []).length === 1 ? "" : "s"} across every home Chez manages</p>
    </header>
    <div class="svc-toolbar">
      <input class="svc-search" type="search" placeholder="Search by name or trade" value="${esc(search)}" data-vendors-search aria-label="Search vendors" />
    </div>
    <div class="svc-vendor-list">${cards || `<div class="svc-empty">No vendors match.</div>`}</div>
  `;
}

function bindListActions(root) {
  disposeActions?.();
  disposeActions = bindActions(root, {
    "open-vendor": (elm) => { if (elm.dataset.key) navigate(`#/vendors/${encodeURIComponent(elm.dataset.key)}`); },
    "retry": () => { listData = null; loadList(); },
    "back-to-vendors": () => navigate("#/vendors"),
  });
  root.addEventListener("input", (e) => {
    if (e.target.matches("[data-vendors-search]")) { search = e.target.value; invalidate("vendors"); }
  });
}

// ── Detail ──────────────────────────────────────────────────────────

export function enterDetail(key) {
  detailKey = key; detailData = null; detailError = false;
  const root = document.getElementById("svc-view");
  root.innerHTML = `<div class="svc-vendors" data-vendors-zone></div>`;
  zone("vendors", root.querySelector("[data-vendors-zone]"), renderDetail);
  bindListActions(root);
  invalidate("vendors");
  loadDetail(key);
}

async function loadDetail(key) {
  try {
    detailData = await callConcierge("fetch_vendor_detail", { vendor_key: key });
    detailError = false;
  } catch (err) {
    detailError = true;
    if (err instanceof ApiError && err.status === 403) toast("Admin access required", "error");
  }
  invalidate("vendors");
}

function renderDetail() {
  if (detailError) return `<div class="svc-empty"><button class="svc-link" data-action="back-to-vendors">← Vendors</button><p>Couldn't load this vendor.</p></div>`;
  if (!detailData) return `<div class="svc-loading"><button class="svc-link" data-action="back-to-vendors">← Vendors</button><p>Loading vendor...</p></div>`;
  const d = detailData;
  const reg = d.registry || {};
  const calls = Array.isArray(d.calls) ? d.calls : [];
  const visits = Array.isArray(d.visits) ? d.visits : [];
  const outreach = Array.isArray(d.outreach) ? d.outreach : [];
  const name = reg.display_name || d.matched_by?.name || "Vendor";

  const stat = (label, val) => `<div class="svc-metric"><div class="svc-metric__val">${val}</div><div class="svc-metric__lbl">${label}</div></div>`;

  const callRows = calls.map((c) => `
    <div class="svc-sec__row">
      ${esc(c.outcome || "logged")} <span class="svc-dim">${c.quoted_cost_cents ? fmtMoneyCents(c.quoted_cost_cents) : ""}${c.town ? " · " + esc(c.town) : ""}${c.last_called_at ? " · " + esc(fmtDate(c.last_called_at)) : ""}</span>
      ${c.recommended ? `<span class="svc-chip svc-chip--accent">recommended</span>` : ""}
    </div>`).join("");
  const visitRows = visits.map((v) => `
    <div class="svc-sec__row">
      ${esc(v.state || "visit")} <span class="svc-dim">${v.scheduled_for ? esc(fmtDate(v.scheduled_for)) : ""}${v.final_cost_cents ? " · " + fmtMoneyCents(v.final_cost_cents) : ""}</span>
      ${v.no_show ? `<span class="svc-stat-warn">no-show</span>` : ""}
    </div>`).join("");

  return `
    <div class="svc-vendor-detail">
      <button class="svc-link" data-action="back-to-vendors">← Vendors</button>
      <header class="svc-home-detail__head">
        <h1 class="svc-view-title">${esc(name)}${reg.chez_sourced ? ` <span class="svc-chip svc-chip--accent">Chez network</span>` : ""}</h1>
        <p class="svc-view-sub">${esc((reg.categories || []).join(", "))}${reg.phone ? " · " + esc(reg.phone) : ""}${(reg.towns || []).length ? " · " + esc((reg.towns || []).join(", ")) : ""}</p>
      </header>
      <div class="svc-metric-row">
        ${stat("Times called", reg.times_called || 0)}
        ${stat("Answer rate", pct(reg.answer_rate))}
        ${stat("Jobs won", reg.jobs_won || 0)}
        ${stat("Visits done", reg.visits_completed || 0)}
        ${stat("No-shows", reg.no_shows || 0)}
        ${stat("Avg quote", reg.avg_quoted_cost_cents ? fmtMoneyCents(reg.avg_quoted_cost_cents) : "—")}
        ${stat("Homes", reg.households_touched || 0)}
      </div>
      <div class="svc-sec">
        <div class="svc-sec__head svc-sec__head--static"><span class="svc-sec__label">Call history</span><span class="svc-sec__count">${calls.length}</span></div>
        <div class="svc-sec__rows">${callRows || `<div class="svc-sec__empty">No calls logged.</div>`}</div>
      </div>
      <div class="svc-sec">
        <div class="svc-sec__head svc-sec__head--static"><span class="svc-sec__label">Visits</span><span class="svc-sec__count">${visits.length}</span></div>
        <div class="svc-sec__rows">${visitRows || `<div class="svc-sec__empty">No visits on file.</div>`}</div>
      </div>
      ${outreach.length ? `<div class="svc-sec"><div class="svc-sec__head svc-sec__head--static"><span class="svc-sec__label">Email outreach</span><span class="svc-sec__count">${outreach.length}</span></div><div class="svc-sec__rows">${outreach.map((o) => `<div class="svc-sec__row">${esc(o.direction || "email")} <span class="svc-dim">${o.created_at ? esc(fmtDate(o.created_at)) : ""}</span></div>`).join("")}</div></div>` : ""}
    </div>
  `;
}

export function leave() {
  unzone("vendors");
  disposeActions?.();
  disposeActions = null;
  const root = document.getElementById("svc-view");
  if (root) root.innerHTML = "";
}
