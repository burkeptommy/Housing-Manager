// views/homes.js — the operator's reference view over every household
// Chez manages. Phase C: a read-only workbench. List of homes (with
// standing-engagement + open-case counts) → per-home detail with the
// full entity picture (systems, vendors, routines, tasks, utilities,
// projects, documents) and links into the open cases.

import { callConcierge, ApiError } from "../api.js";
import { zone, unzone, invalidate, esc } from "../render.js";
import { bindActions } from "../actions.js";
import { navigate } from "../router.js";
import { toast } from "../components/toast.js";
import { fmtAgo, fmtDate, fmtMoneyCents } from "../lib/format.js";

// Per-view state (cleared on leave). Cached workbench keyed by household.
let listData = null;
let listError = false;
let search = "";
let detailId = null;
let detailData = null;
let detailError = false;
const expanded = new Set(["systems", "vendors", "routines"]); // default-open sections
let disposeActions = null;

// ── List route ──────────────────────────────────────────────────────

export function enterList() {
  detailId = null; detailData = null;
  const root = document.getElementById("svc-view");
  root.innerHTML = `<div class="svc-homes" data-homes-zone></div>`;
  zone("homes", root.querySelector("[data-homes-zone]"), renderList);
  bindListActions(root);
  invalidate("homes");
  loadList();
}

async function loadList() {
  if (listData) { invalidate("homes"); return; }
  try {
    const res = await callConcierge("fetch_households_list");
    listData = Array.isArray(res.households) ? res.households : [];
    listError = false;
  } catch (err) {
    listError = true;
    if (err instanceof ApiError && err.status === 403) toast("Admin access required", "error");
  }
  invalidate("homes");
}

function filteredHomes() {
  const q = search.trim().toLowerCase();
  const rows = listData || [];
  if (!q) return rows;
  return rows.filter((h) => String(h.name || "").toLowerCase().includes(q));
}

function renderList() {
  if (listError) {
    return `<div class="svc-empty">Couldn't load homes. <button class="svc-link" data-action="retry-list">Try again</button></div>`;
  }
  if (!listData) return `<div class="svc-loading">Loading homes...</div>`;
  const rows = filteredHomes();
  const cards = rows.map((h) => `
    <button class="svc-home-card" data-action="open-home" data-id="${esc(h.id)}">
      <div class="svc-home-card__name">${esc(h.name || "Household")}</div>
      <div class="svc-home-card__meta">
        ${h.owned_count ? `<span class="svc-chip">${h.owned_count} Chez-owned</span>` : ""}
        ${h.open_cases ? `<span class="svc-chip svc-chip--accent">${h.open_cases} open case${h.open_cases === 1 ? "" : "s"}</span>` : ""}
        ${h.last_activity_at ? `<span class="svc-home-card__ago">${esc(fmtAgo(h.last_activity_at))}</span>` : ""}
      </div>
    </button>
  `).join("");
  return `
    <header class="svc-view-head">
      <h1 class="svc-view-title">Homes</h1>
      <p class="svc-view-sub">${(listData || []).length} household${(listData || []).length === 1 ? "" : "s"} under management</p>
    </header>
    <div class="svc-toolbar">
      <input class="svc-search" type="search" placeholder="Search homes" value="${esc(search)}" data-homes-search aria-label="Search homes" />
    </div>
    <div class="svc-home-grid">
      ${cards || `<div class="svc-empty">No homes match.</div>`}
    </div>
  `;
}

function bindListActions(root) {
  disposeActions?.();
  disposeActions = bindActions(root, {
    "open-home": (elm) => { if (elm.dataset.id) navigate(`#/homes/${encodeURIComponent(elm.dataset.id)}`); },
    "retry-list": () => { listData = null; loadList(); },
  });
  root.addEventListener("input", (e) => {
    if (e.target.matches("[data-homes-search]")) { search = e.target.value; invalidate("homes"); }
  });
}

// ── Detail route ────────────────────────────────────────────────────

export function enterDetail(id) {
  detailId = id; detailData = null; detailError = false;
  const root = document.getElementById("svc-view");
  root.innerHTML = `<div class="svc-homes" data-homes-zone></div>`;
  zone("homes", root.querySelector("[data-homes-zone]"), renderDetail);
  bindDetailActions(root);
  invalidate("homes");
  loadDetail(id);
}

async function loadDetail(id) {
  try {
    detailData = await callConcierge("fetch_household_workbench", { household_id: id });
    detailError = false;
  } catch (err) {
    detailError = true;
    if (err instanceof ApiError && err.status === 403) toast("Admin access required", "error");
  }
  invalidate("homes");
}

function propertyLine(props) {
  const p = (props || [])[0];
  if (!p) return "";
  return [p.street, p.city, p.state, p.zip_code].filter(Boolean).join(", ");
}

function profileSummary(household) {
  const prof = household?.chez_profile;
  if (!prof || typeof prof !== "object") return "";
  const bits = [];
  const tiers = prof.spending_tiers;
  if (tiers && (tiers.auto_approve_under || tiers.explicit_above)) {
    const auto = tiers.auto_approve_under ? `auto-approve under $${tiers.auto_approve_under}` : null;
    const explicit = tiers.explicit_above ? `always ask above $${tiers.explicit_above}` : null;
    bits.push([auto, explicit].filter(Boolean).join(", "));
  }
  const log = prof.logistics;
  if (log?.entry_instructions) bits.push(`Access: ${log.entry_instructions}`);
  if (log?.has_pets && log?.pet_notes) bits.push(log.pet_notes);
  return bits.map((b) => `<div class="svc-profile-line">${esc(b)}</div>`).join("");
}

const SECTIONS = [
  { key: "systems", label: "Systems", src: "home_systems", row: (s) => `${esc(s.name || s.category || "System")} <span class="svc-dim">${esc(s.category || "")}</span>` },
  { key: "vendors", label: "Vendors", src: "contractors", row: (c) => `${esc(c.company_name || "Vendor")} <span class="svc-dim">${esc(c.category || "")}${c.phone ? " · " + esc(c.phone) : ""}</span>` },
  { key: "routines", label: "Routines", src: "routines", row: (r) => `${esc(r.label || r.routine_kind || "Routine")} <span class="svc-dim">${esc(r.cadence_type || "")}</span>` },
  { key: "tasks", label: "Tasks", src: "tasks", row: (t) => `${esc(t.title || "Task")} <span class="svc-dim">${t.next_due_date ? "due " + esc(fmtDate(t.next_due_date)) : ""}</span>` },
  { key: "utilities", label: "Utilities", src: "utility_accounts", row: (u) => `${esc(u.provider_name || "Provider")} <span class="svc-dim">${esc(u.provider_type || "")}${u.monthly_cost ? " · $" + u.monthly_cost + "/mo" : ""}</span>` },
  { key: "projects", label: "Projects", src: "projects", row: (p) => `${esc(p.name || "Project")} <span class="svc-dim">${esc(p.status || "")}${p.estimated_budget ? " · $" + Number(p.estimated_budget).toLocaleString() : ""}</span>` },
  { key: "documents", label: "Documents", src: "documents", row: (d) => `${esc(d.title || d.filename || "Document")} <span class="svc-dim">${esc(d.category || "")}${d.expiration_date ? " · expires " + esc(fmtDate(d.expiration_date)) : ""}</span>` },
  { key: "vehicles", label: "Vehicles", src: "vehicles", row: (v) => `${esc([v.year, v.make, v.model].filter(Boolean).join(" ") || v.name || "Vehicle")}` },
];

function renderDetail() {
  if (detailError) {
    return `<div class="svc-empty"><button class="svc-link" data-action="back-to-homes">← Homes</button><p>Couldn't load this home.</p></div>`;
  }
  if (!detailData) return `<div class="svc-loading"><button class="svc-link" data-action="back-to-homes">← Homes</button><p>Loading home...</p></div>`;
  const d = detailData;
  const name = d.household?.name || "Household";
  const openCases = Array.isArray(d.open_cases) ? d.open_cases : [];

  const sections = SECTIONS.map((sec) => {
    const rows = Array.isArray(d[sec.src]) ? d[sec.src] : [];
    const open = expanded.has(sec.key);
    const body = open
      ? (rows.length
        ? `<div class="svc-sec__rows">${rows.map((r) => `<div class="svc-sec__row">${sec.row(r)}</div>`).join("")}</div>`
        : `<div class="svc-sec__empty">None on file.</div>`)
      : "";
    return `
      <div class="svc-sec">
        <button class="svc-sec__head" data-action="toggle-sec" data-key="${sec.key}">
          <span class="svc-sec__chev">${open ? "▾" : "▸"}</span>
          <span class="svc-sec__label">${sec.label}</span>
          <span class="svc-sec__count">${rows.length}</span>
        </button>
        ${body}
      </div>
    `;
  }).join("");

  const casesBlock = openCases.length ? `
    <div class="svc-sec">
      <div class="svc-sec__head svc-sec__head--static">
        <span class="svc-sec__label">Open cases</span>
        <span class="svc-sec__count">${openCases.length}</span>
      </div>
      <div class="svc-sec__rows">
        ${openCases.map((c) => `
          <button class="svc-sec__row svc-sec__row--link" data-action="open-case" data-id="${esc(c.id)}">
            ${esc(c.summary || "Request")} <span class="svc-dim">${esc(c.status || "")}</span>
          </button>
        `).join("")}
      </div>
    </div>
  ` : "";

  return `
    <div class="svc-home-detail">
      <button class="svc-link" data-action="back-to-homes">← Homes</button>
      <header class="svc-home-detail__head">
        <h1 class="svc-view-title">${esc(name)}</h1>
        <p class="svc-view-sub">${esc(propertyLine(d.properties))}</p>
        ${(d.family_members || []).length ? `<div class="svc-chip-row">${(d.family_members || []).map((m) => `<span class="svc-chip">${esc([m.first_name, m.last_name].filter(Boolean).join(" ") || "Member")}${m.member_type && m.member_type !== "family" ? " · " + esc(m.member_type) : ""}</span>`).join("")}</div>` : ""}
        <div class="svc-profile">${profileSummary(d.household) || `<div class="svc-profile-line svc-dim">No standing instructions on file.</div>`}</div>
      </header>
      ${casesBlock}
      ${sections}
    </div>
  `;
}

function bindDetailActions(root) {
  disposeActions?.();
  disposeActions = bindActions(root, {
    "back-to-homes": () => navigate("#/homes"),
    "toggle-sec": (elm) => {
      const k = elm.dataset.key;
      if (expanded.has(k)) expanded.delete(k); else expanded.add(k);
      invalidate("homes");
    },
    "open-case": (elm) => { if (elm.dataset.id) navigate(`#/case/${encodeURIComponent(elm.dataset.id)}`); },
  });
}

export function leave() {
  unzone("homes");
  disposeActions?.();
  disposeActions = null;
  const root = document.getElementById("svc-view");
  if (root) root.innerHTML = "";
}
