// Service portal v2 - case view controller (Wave 3 Phase A).
//
// Router coupling surface (wired by main.js): export `async function
// enter(requestId)` and `function leave()`. A null requestId is legal
// (the #/cases route with an empty queue): the queue rail renders with an
// empty workspace.
//
// Layout composes the foundation's service.css scaffolding: .svc-case grid
// (queue rail 300px | workspace | Alfred rail 340px, `is-alfred-closed`
// collapses the rail), .svc-topbar, .svc-scroll, .svc-queue-*, .svc-msg,
// .svc-composer. This module injects one scoped style block for the
// case-only pieces service.css does not know about (work order, snippet
// popover, Alfred internals, resolve form chips).
//
// Zone discipline: every paint goes through render.js zones; renderFns are
// pure reads of `state`; typing never invalidates the zone that holds the
// input (queue search only invalidates the list zone, composer drafts go
// to the scratchpad).
//
// Telemetry (verified against chez-concierge handleLogOperatorEvent):
//   { action: "log_operator_event",
//     events: [{ request_id, event_type, client_session_id }] }
// with event_type in case_opened / case_closed / reply_sent.

import { zone, unzone, invalidate, esc } from "../../render.js";
import { state, setState } from "../../state.js";
import { callConcierge, ApiError } from "../../api.js";
import { uiSet } from "../../storage.js";
import { navigate } from "../../router.js";
import { bindActions, bindShortcuts } from "../../actions.js";
import { toast } from "../../components/toast.js";
import { slaPill, statusPill, categoryGlyph, snapshotChips } from "../../components/pills.js";
import { fmtAgo, truncate } from "../../lib/format.js";

import { renderWorkOrderZone } from "./workorder.js";
import { renderThreadZone } from "./thread.js";
import {
  renderComposerZone, handleComposerInput, handleComposerKeydown,
  sendReply, flushDraft, resetComposerFor, pickSnippet, toggleWaiting, reopenFromComposer,
} from "./composer.js";
import { openResolveModal, markWaiting, reopenCase } from "./resolve.js";
import {
  renderAlfredZone, handleAlfredInput, handleAlfredKeydown,
  sendFromInput, askAlfred, clearAlfredChat, resetAlfredFor, scrollAlfredToBottom,
} from "./alfred.js";
import {
  renderVendorsZone, syncVendorsFromBundle, resetVendorsFor,
  handleVendorsInput, handleVendorsFocusout, flushVendorDrafts,
  toggleCandidateForm, setOutcome, toggleRecommended, runAnalysis,
  copyCallScript, openManualForm, cancelManualForm, saveManualCandidate,
  askForBudgetAndTiming, sendableRecommendedKeys,
} from "./vendors.js";
import {
  renderProposeZone, resetProposeFor, openProposeFor, closePropose,
  activateChip, removeChip, polishFraming, sendProposals, handleProposeInput,
} from "./propose.js";

const ZONES = [
  "case-queue-head", "case-queue-list", "case-topbar",
  "case-workorder", "case-vendors", "case-propose",
  "case-thread", "case-composer", "case-alfred",
];

const QUEUE_FILTERS = [
  { key: "all", label: "All" },
  { key: "unread", label: "Unread" },
  { key: "overdue", label: "Overdue" },
  { key: "waiting", label: "Waiting" },
];

let currentId = null;
let mounted = false;
let shellEl = null;
let disposeActions = null;
let disposeKeys = null;
let cleanupFns = [];
let bundleSeq = 0;
let searchTimer = null;
let bootPollTimer = null;
let queueCursor = null;

// ---------------------------------------------------------------------------
// Operator telemetry (ported from admin.js queueOperatorEvent /
// trackOperatorCaseFocus: 2s debounced batch flush, 5 minute dedupe on
// repeat case_opened for the same case).
// ---------------------------------------------------------------------------

const SESSION_ID = `svc-${Math.random().toString(36).slice(2, 10)}-${Date.now().toString(36)}`;
let eventBuffer = [];
let eventTimer = null;
let lastFocusedCaseId = null;
const caseOpenedAt = {};

export function queueCaseEvent(requestId, eventType) {
  if (!requestId || !eventType) return;
  eventBuffer.push({ request_id: requestId, event_type: eventType, client_session_id: SESSION_ID });
  if (eventTimer) clearTimeout(eventTimer);
  eventTimer = setTimeout(flushCaseEvents, 2000);
}

async function flushCaseEvents() {
  if (eventTimer) {
    clearTimeout(eventTimer);
    eventTimer = null;
  }
  if (eventBuffer.length === 0) return;
  const events = eventBuffer.splice(0, 50);
  try {
    await callConcierge("log_operator_event", { events });
  } catch (err) {
    // Telemetry never blocks the operator; dropped batches are acceptable.
    console.warn("[svc-case] log_operator_event failed (dropped)", err);
  }
}

function trackCaseFocus(nextId) {
  if (lastFocusedCaseId === nextId) return;
  const prev = lastFocusedCaseId;
  lastFocusedCaseId = nextId;
  if (prev) queueCaseEvent(prev, "case_closed");
  if (nextId) {
    const last = caseOpenedAt[nextId] || 0;
    if (Date.now() - last > 5 * 60 * 1000) {
      caseOpenedAt[nextId] = Date.now();
      queueCaseEvent(nextId, "case_opened");
    }
  }
}

// ---------------------------------------------------------------------------
// Queue rail
// ---------------------------------------------------------------------------

function queueRows() {
  return Array.isArray(state.queue) ? state.queue.filter((r) => r && r.id) : [];
}

function isOverdueRow(row) {
  if (!row || row.status !== "open" || !row.sla_due_at) return false;
  const due = Date.parse(row.sla_due_at);
  return Number.isFinite(due) && due < Date.now();
}

function filteredQueue() {
  const filter = state.ui.queueFilter || "all";
  const query = String(state.ui.search || "").trim().toLowerCase();
  let rows = queueRows();
  if (filter === "unread") rows = rows.filter((r) => !!r.unread_for_admin);
  else if (filter === "overdue") rows = rows.filter(isOverdueRow);
  else if (filter === "waiting") rows = rows.filter((r) => r.status === "waiting_customer");
  if (query) {
    rows = rows.filter((r) => {
      const haystack = `${r.summary || ""} ${r.household_name || ""} ${r.category || ""}`.toLowerCase();
      return haystack.includes(query);
    });
  }
  return rows;
}

function renderQueueHeadZone() {
  const rows = queueRows();
  const counts = {
    all: rows.length,
    unread: rows.filter((r) => !!r.unread_for_admin).length,
    overdue: rows.filter(isOverdueRow).length,
    waiting: rows.filter((r) => r.status === "waiting_customer").length,
  };
  const active = state.ui.queueFilter || "all";
  return `
    <div class="svc-queue-search">
      <input
        type="search"
        class="svc-input"
        data-queue-search
        placeholder="Search this queue"
        value="${esc(state.ui.search || "")}"
      />
    </div>
    <div class="svc-filterchips">
      ${QUEUE_FILTERS.map((f) => `
        <button type="button" class="svc-filterchip ${active === f.key ? "is-active" : ""}" data-action="queue-filter" data-filter="${f.key}">
          ${esc(f.label)}${counts[f.key] ? ` <span class="svc-filterchip__count">${counts[f.key]}</span>` : ""}
        </button>
      `).join("")}
    </div>
  `;
}

function renderQueueListZone() {
  if (!state.boot && queueRows().length === 0) {
    return `<div class="svc-queue-empty">Loading the queue...</div>`;
  }
  const rows = filteredQueue();
  if (rows.length === 0) {
    return `<div class="svc-queue-empty">No cases match this view.</div>`;
  }
  return rows.map((row) => {
    const isActive = row.id === state.activeCaseId && !!currentId;
    const isCursor = row.id === queueCursor && !isActive;
    return `
      <div class="svc-queue-item ${isActive ? "is-active" : ""} ${isCursor ? "is-cursor" : ""} ${row.unread_for_admin ? "is-unread" : ""}"
           data-action="open-case" data-id="${esc(row.id)}" role="button" tabindex="0">
        <div class="svc-qrow__top">
          <span class="svc-qrow__home">${esc(row.household_name || "Household")}</span>
          ${slaPill(row) || ""}
        </div>
        <div class="svc-qrow__sum">${esc(truncate(row.summary || "Concierge request", 90))}</div>
        <div class="svc-qrow__meta">
          ${categoryGlyph(row.category)}
          ${statusPill(row.status)}
          ${snapshotChips(row) || ""}
        </div>
      </div>
    `;
  }).join("");
}

function moveQueueCursor(delta) {
  const rows = filteredQueue();
  if (rows.length === 0) return;
  const ids = rows.map((r) => r.id);
  const from = queueCursor && ids.includes(queueCursor) ? ids.indexOf(queueCursor)
    : (state.activeCaseId && ids.includes(state.activeCaseId) ? ids.indexOf(state.activeCaseId) : -1);
  const next = Math.min(Math.max(from + delta, 0), ids.length - 1);
  queueCursor = ids[next];
  invalidate("case-queue-list");
  requestAnimationFrame(() => {
    const el = shellEl && shellEl.querySelector(".svc-queue-item.is-cursor, .svc-queue-item.is-active");
    if (el) el.scrollIntoView({ block: "nearest" });
  });
}

function openCaseById(id) {
  if (!id || id === currentId) return;
  queueCursor = id;
  navigate(`#/case/${encodeURIComponent(id)}`);
}

// ---------------------------------------------------------------------------
// Topbar
// ---------------------------------------------------------------------------

function activeRequest() {
  if (!currentId) return null;
  const bundle = state.cases[currentId];
  if (bundle && bundle.request) return bundle.request;
  return queueRows().find((r) => r.id === currentId) || null;
}

function renderTopbarZone() {
  if (!currentId) {
    return `
      <div class="svc-casebar">
        <div class="svc-casebar__info"><span class="svc-dim">No case open. Pick one from the queue.</span></div>
      </div>
    `;
  }
  const request = activeRequest();
  if (!request) {
    return `<div class="svc-casebar"><div class="svc-casebar__info"><span class="svc-dim">Opening case...</span></div></div>`;
  }
  const status = request.status;
  const buttons = [];
  if (status === "resolved") {
    buttons.push(`<button type="button" class="svc-btn svc-btn--small" data-action="topbar-reopen">Reopen</button>`);
  } else {
    if (status === "waiting_customer") {
      buttons.push(`<button type="button" class="svc-btn svc-btn--ghost svc-btn--small" data-action="topbar-open">Mark open</button>`);
    } else {
      buttons.push(`<button type="button" class="svc-btn svc-btn--ghost svc-btn--small" data-action="topbar-waiting">Waiting on homeowner</button>`);
    }
    buttons.push(`<button type="button" class="svc-btn svc-btn--primary svc-btn--small" data-action="topbar-resolve" title="Resolve (e)">Resolve</button>`);
  }
  buttons.push(`
    <button type="button" class="svc-btn svc-btn--ghost svc-btn--small ${state.ui.alfredOpen ? "is-on" : ""}"
            data-action="toggle-alfred" title="${state.ui.alfredOpen ? "Hide the Alfred rail" : "Show the Alfred rail"}">
      Alfred
    </button>
  `);

  // Household name links into its Homes workbench — the case ↔ home
  // drill-down that keeps the surfaces seamless. The raw chez_requests
  // row carries no household_name, so resolve it through the bundle's
  // dossier or the queue row.
  const bundle = state.cases[currentId];
  const householdName = request.household_name
    || (bundle && bundle.dossier_lite && bundle.dossier_lite.household && bundle.dossier_lite.household.name)
    || (queueRows().find((r) => r.id === currentId) || {}).household_name
    || "";
  const homeLink = householdName
    ? (request.household_id
      ? `<a class="svc-casebar__home" href="#/homes/${encodeURIComponent(request.household_id)}" title="Open this home">${esc(householdName)}</a>`
      : esc(householdName))
    : "";
  const meta = [
    homeLink,
    request.created_at ? `Opened ${esc(fmtAgo(request.created_at))}` : "",
  ].filter(Boolean).join(" · ");

  return `
    <div class="svc-casebar">
      <div class="svc-casebar__info">
        <div class="svc-casebar__title">${categoryGlyph(request.category)} <span>${esc(truncate(request.summary || "Concierge request", 90))}</span></div>
        <div class="svc-casebar__meta">${statusPill(request.status)} ${slaPill(request) || ""} ${meta ? `<span class="svc-dim">${meta}</span>` : ""}</div>
      </div>
      <div class="svc-casebar__actions">${buttons.join("")}</div>
    </div>
  `;
}

// ---------------------------------------------------------------------------
// Bundle load
// ---------------------------------------------------------------------------

async function loadBundle(requestId, { showErrors = true } = {}) {
  const seq = ++bundleSeq;
  try {
    const bundle = await callConcierge("fetch_case_bundle", { request_id: requestId });
    if (seq !== bundleSeq || currentId !== requestId) return;

    if (bundle && bundle.request) bundle.request.unread_for_admin = false;
    setState({ cases: { ...state.cases, [requestId]: bundle } });
    // Vendor engine: hydrate the call-ledger form model from the bundle's
    // vendor_calls rows (drafts included; local unsaved edits win).
    syncVendorsFromBundle(requestId, bundle);

    const row = queueRows().find((r) => r.id === requestId);
    if (row && row.unread_for_admin) row.unread_for_admin = false;
    callConcierge("mark_read", { request_id: requestId }).catch(() => {});

    invalidate(...ZONES);
    // Land at the TOP on open: the work order is the whole point of the
    // snapshot work — burying it below a full thread means the operator
    // digs on every case. Scroll-to-bottom stays on send / propose /
    // resolve, where the operator's attention IS the thread.
    requestAnimationFrame(scrollWorkspaceToTop);
  } catch (err) {
    if (seq !== bundleSeq || currentId !== requestId) return;
    const message = err instanceof ApiError && err.status === 404
      ? "That case does not exist anymore."
      : (err && err.message ? err.message : String(err));
    // Keep a previously loaded bundle on screen; only park an error entry
    // when there is nothing cached to show.
    if (!state.cases[requestId] || state.cases[requestId]._error) {
      setState({ cases: { ...state.cases, [requestId]: { _error: message } } });
    }
    invalidate("case-workorder", "case-topbar", "case-thread", "case-composer");
    if (showErrors) toast(`Could not load the case: ${message}`, "error");
  }
}

// ---------------------------------------------------------------------------
// Actions table (bindActions delegation: click + Enter/Space)
// ---------------------------------------------------------------------------

const ACTIONS = {
  "open-case": (el) => openCaseById(el.dataset.id),
  "queue-filter": (el) => {
    const filter = el.dataset.filter || "all";
    setState({ ui: { ...state.ui, queueFilter: filter } });
    invalidate("case-queue-head", "case-queue-list");
  },
  "retry-bundle": () => {
    if (!currentId) return;
    const cases = { ...state.cases };
    delete cases[currentId];
    setState({ cases });
    invalidate("case-workorder", "case-thread", "case-composer");
    loadBundle(currentId);
  },
  "topbar-resolve": () => { if (currentId) openResolveModal(currentId); },
  "topbar-waiting": () => { if (currentId) markWaiting(currentId); },
  "topbar-open": () => { if (currentId) reopenCase(currentId, { fromWaiting: true }); },
  "topbar-reopen": () => { if (currentId) reopenCase(currentId); },
  "toggle-alfred": () => {
    const next = !state.ui.alfredOpen;
    setState({ ui: { ...state.ui, alfredOpen: next } });
    uiSet({ alfredOpen: next });
    if (shellEl) shellEl.classList.toggle("is-alfred-closed", !next);
    invalidate("case-alfred", "case-topbar");
    if (next) requestAnimationFrame(scrollAlfredToBottom);
  },
  "composer-send": () => { sendReply(); },
  "composer-toggle-waiting": () => { toggleWaiting(); },
  "composer-reopen": () => { reopenFromComposer(); },
  "snip-pick": (el) => { pickSnippet(el.dataset.snipId); },
  "alfred-send": () => { sendFromInput(); },
  "alfred-suggest": (el) => { askAlfred(el.dataset.q || ""); },
  "alfred-clear": () => { clearAlfredChat(); },

  // Vendor engine (Phase B). Candidate-scoped actions resolve their key
  // from the enclosing [data-ve-key] card.
  "ve-run-analysis": () => { runAnalysis(); },
  "ve-refresh-analysis": () => { runAnalysis({ force: true }); },
  "ve-copy-script": (el) => { copyCallScript(el); },
  "ve-toggle-form": (el) => { toggleCandidateForm(veKey(el)); },
  "ve-outcome": (el) => { setOutcome(veKey(el), el.dataset.outcome); },
  "ve-recommend": (el) => { toggleRecommended(veKey(el)); },
  "ve-propose": (el) => {
    const key = veKey(el);
    if (currentId && key) openProposeFor(currentId, [key]);
  },
  "ve-send-recommended": () => {
    if (!currentId) return;
    const keys = sendableRecommendedKeys(currentId);
    if (keys.length > 0) openProposeFor(currentId, keys);
  },
  "ve-add-manual": () => { openManualForm(); },
  "ve-manual-save": () => { saveManualCandidate(); },
  "ve-manual-cancel": () => { cancelManualForm(); },
  "ve-thin-ask": () => { askForBudgetAndTiming(); },

  // Docked proposal builder.
  "propose-chip": (el) => { activateChip(el.dataset.key); },
  "propose-chip-remove": (el) => { removeChip(el.dataset.key); },
  "propose-polish": () => { polishFraming(); },
  "propose-send": () => { sendProposals(); },
  "propose-close": () => { closePropose(); },
};

function veKey(el) {
  const card = el.closest("[data-ve-key]");
  return card ? card.getAttribute("data-ve-key") : null;
}

// ---------------------------------------------------------------------------
// Delegated input / keydown wiring (attached to the shell, which is
// recreated per enter, so listeners never stack)
// ---------------------------------------------------------------------------

function onShellInput(e) {
  const target = e.target;
  if (!(target instanceof Element)) return;
  if (target.matches("[data-queue-search]")) {
    const value = target.value;
    if (searchTimer) clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      searchTimer = null;
      setState({ ui: { ...state.ui, search: value } });
      queueCursor = null;
      invalidate("case-queue-list");
    }, 150);
    return;
  }
  handleComposerInput(target);
  handleAlfredInput(target);
  handleVendorsInput(target);
  handleProposeInput(target);
}

/// Vendor call-ledger rows persist on blur (draft: true, single-row batch).
function onShellFocusout(e) {
  const target = e.target;
  if (!(target instanceof Element)) return;
  handleVendorsFocusout(target);
}

function onShellKeydown(e) {
  const target = e.target;
  if (!(target instanceof Element)) return;
  if (target.matches("[data-queue-search]")) {
    if (e.key === "Enter") {
      e.preventDefault();
      const first = filteredQueue()[0];
      if (first) openCaseById(first.id);
    } else if (e.key === "Escape") {
      target.value = "";
      setState({ ui: { ...state.ui, search: "" } });
      invalidate("case-queue-list");
    }
    return;
  }
  handleComposerKeydown(e, target);
  handleAlfredKeydown(e, target);
}

/// View shortcuts ride the shared bindShortcuts registry (same lifecycle
/// today.js uses): auto-suppressed while typing or while a modal is open,
/// disposed on leave. Cmd+K stays with main.js's queue palette.
function shortcutMap() {
  return {
    j: () => moveQueueCursor(1),
    k: () => moveQueueCursor(-1),
    Enter: () => {
      // A focused queue row already opens through bindActions' Enter path;
      // double-driving it from here would fight that dispatch.
      const focused = document.activeElement;
      if (focused instanceof Element && focused.closest("[data-action]")) return;
      if (queueCursor && queueCursor !== currentId) openCaseById(queueCursor);
    },
    r: () => {
      const input = shellEl && shellEl.querySelector("[data-composer-input]");
      if (input && !input.disabled) {
        input.focus();
        input.setSelectionRange(input.value.length, input.value.length);
      }
    },
    e: () => {
      const bundle = currentId ? state.cases[currentId] : null;
      if (bundle && bundle.request && bundle.request.status !== "resolved") {
        openResolveModal(currentId);
      }
    },
  };
}

function onVisibilityChange() {
  if (document.visibilityState === "hidden") {
    flushVendorDrafts();
    flushCaseEvents();
  }
}

// ---------------------------------------------------------------------------
// Scaffold + mount
// ---------------------------------------------------------------------------

function findViewRoot() {
  const root = document.getElementById("svc-view")
    || document.querySelector("[data-svc-view]")
    || document.querySelector("main");
  if (root) return root;
  // Last resort: never wipe <body>; park the view in a dedicated container.
  let fallback = document.getElementById("svc-case-fallback-root");
  if (!fallback) {
    fallback = document.createElement("div");
    fallback.id = "svc-case-fallback-root";
    document.body.appendChild(fallback);
  }
  return fallback;
}

function scaffoldHtml() {
  return `
    <aside class="svc-case__queue">
      <div data-zone="case-queue-head"></div>
      <div class="svc-queue-list" data-zone="case-queue-list"></div>
    </aside>
    <section class="svc-case__work">
      <div data-zone="case-topbar"></div>
      <div class="svc-scroll svc-case-scroll" data-svc-thread-scroll>
        <div data-zone="case-workorder"></div>
        <div data-zone="case-vendors"></div>
        <div data-zone="case-propose"></div>
        <div data-zone="case-thread"></div>
      </div>
      <div data-zone="case-composer"></div>
    </section>
    <aside class="svc-case__alfred" data-zone="case-alfred"></aside>
  `;
}

function registerZones() {
  const byName = (name) => shellEl.querySelector(`[data-zone="${name}"]`);
  zone("case-queue-head", byName("case-queue-head"), renderQueueHeadZone);
  zone("case-queue-list", byName("case-queue-list"), renderQueueListZone);
  zone("case-topbar", byName("case-topbar"), renderTopbarZone);
  zone("case-workorder", byName("case-workorder"), renderWorkOrderZone);
  zone("case-vendors", byName("case-vendors"), renderVendorsZone);
  zone("case-propose", byName("case-propose"), renderProposeZone);
  zone("case-thread", byName("case-thread"), renderThreadZone);
  zone("case-composer", byName("case-composer"), renderComposerZone);
  zone("case-alfred", byName("case-alfred"), renderAlfredZone);
}

function mountShell() {
  injectStyles();
  const root = findViewRoot();
  root.innerHTML = "";
  shellEl = document.createElement("div");
  shellEl.className = `svc-case${state.ui.alfredOpen ? "" : " is-alfred-closed"}`;
  shellEl.innerHTML = scaffoldHtml();
  root.appendChild(shellEl);

  disposeActions = bindActions(shellEl, ACTIONS);
  disposeKeys = bindShortcuts(shortcutMap());
  shellEl.addEventListener("input", onShellInput);
  shellEl.addEventListener("keydown", onShellKeydown);
  shellEl.addEventListener("focusout", onShellFocusout);
  document.addEventListener("visibilitychange", onVisibilityChange);
  cleanupFns.push(() => document.removeEventListener("visibilitychange", onVisibilityChange));

  registerZones();
  mounted = true;

  // Deep links can land before the boot payload: repaint the queue rail
  // when it shows up instead of leaving a stale "Loading the queue" shell.
  if (!state.boot) {
    let polls = 0;
    bootPollTimer = setInterval(() => {
      polls += 1;
      if (state.boot || polls > 30) {
        clearInterval(bootPollTimer);
        bootPollTimer = null;
        if (state.boot) invalidate("case-queue-head", "case-queue-list", "case-topbar");
      }
    }, 500);
  }
}

function teardown() {
  unzone(...ZONES);
  if (disposeActions) { try { disposeActions(); } catch { /* noop */ } disposeActions = null; }
  if (disposeKeys) { try { disposeKeys(); } catch { /* noop */ } disposeKeys = null; }
  for (const fn of cleanupFns.splice(0)) {
    try { fn(); } catch { /* teardown must never throw */ }
  }
  if (bootPollTimer) {
    clearInterval(bootPollTimer);
    bootPollTimer = null;
  }
  if (shellEl) {
    shellEl.remove();
    shellEl = null;
  }
  mounted = false;
  currentId = null;
}

// ---------------------------------------------------------------------------
// Router surface
// ---------------------------------------------------------------------------

export async function enter(arg) {
  const requestId = typeof arg === "string"
    ? arg
    : (arg && (arg.id || arg.requestId || arg.request_id)) || null;

  // Re-entry on the already open case: background refresh only.
  if (requestId && requestId === currentId && mounted && shellEl && document.body.contains(shellEl)) {
    await loadBundle(requestId, { showErrors: false });
    return;
  }

  // Switching cases (or entering fresh) while mounted: persist the
  // outgoing draft + any pending vendor-ledger rows, then rebuild the
  // shell so listeners never stack.
  if (mounted) {
    if (currentId) flushDraft(currentId);
    flushVendorDrafts();
    teardown();
  }

  currentId = requestId;
  setState({ activeCaseId: requestId });
  queueCursor = requestId || filteredQueue()[0]?.id || null;
  resetComposerFor();
  resetAlfredFor();
  resetVendorsFor();
  resetProposeFor();
  mountShell();

  if (!requestId) {
    // #/cases with an empty queue: rail + empty workspace, nothing to load.
    trackCaseFocus(null);
    return;
  }

  if (state.cases[requestId] && !state.cases[requestId]._error) {
    // Cached bundle: same top-first rule as a fresh load.
    requestAnimationFrame(scrollWorkspaceToTop);
  }
  requestAnimationFrame(scrollAlfredToBottom);

  trackCaseFocus(requestId);
  await loadBundle(requestId);
}

/// Case-open scroll position: work order first. The workspace column
/// scroller also hosts the thread, whose scroll-to-bottom is reserved
/// for send / propose / resolve actions.
function scrollWorkspaceToTop() {
  const scroller = document.querySelector("[data-svc-thread-scroll]");
  if (scroller) scroller.scrollTop = 0;
}

export function leave() {
  if (currentId) flushDraft(currentId);
  flushVendorDrafts();
  trackCaseFocus(null);
  flushCaseEvents();
  teardown();
}

// ---------------------------------------------------------------------------
// Case-only styles. service.css owns the portal chrome (buttons, pills,
// chips, forms, the .svc-case grid, queue items, messages, composer bar);
// this block covers only the pieces unique to the case workspace: queue-row
// internals, the topbar case header, the work order document, proposal
// internals, the snippet popover, the Alfred rail internals, and the
// resolve form quick-picks. Purple stays reserved for primary CTAs and
// active accents.
// ---------------------------------------------------------------------------

function injectStyles() {
  if (document.getElementById("svc-case-style")) return;
  const style = document.createElement("style");
  style.id = "svc-case-style";
  style.textContent = `
.svc-case-scroll { display: flex; flex-direction: column; gap: 16px; }
.svc-dim { color: var(--text-muted, #6B6B7B); font-size: 12.5px; }
.svc-mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px; }
.svc-num { text-align: right; }
.svc-skeleton { height: 12px; border-radius: 6px; background: var(--neutral-200, #EDEEF0); margin: 8px 0; animation: svcCasePulse 1.4s ease-in-out infinite; }
@keyframes svcCasePulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.45; } }

/* Queue rail internals */
.svc-queue-empty { padding: 18px 14px; font-size: 13px; color: var(--text-muted, #6B6B7B); }
.svc-queue-item.is-cursor { background: var(--svc-row-hover, #FAFAFC); box-shadow: inset 3px 0 0 var(--neutral-300, #D8DADF); }
.svc-queue-item:focus-visible { outline: 2px solid var(--purple, #6938EF); outline-offset: -2px; }
.svc-filterchip__count { opacity: 0.7; font-weight: 500; }
.svc-qrow__top { display: flex; align-items: center; gap: 6px; padding-right: 14px; }
.svc-qrow__home { font-weight: 600; font-size: 12.5px; color: var(--text, #0A0A0A); flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.svc-qrow__sum { font-size: 13px; color: var(--text, #0A0A0A); margin-top: 3px; line-height: 1.35; }
.svc-qrow__meta { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; margin-top: 6px; }

/* Topbar case header */
.svc-casebar { display: flex; align-items: center; justify-content: space-between; gap: 12px; width: 100%; min-width: 0; }
.svc-casebar__info { min-width: 0; }
.svc-casebar__title { font-weight: 650; font-size: 14.5px; color: var(--text, #0A0A0A); display: flex; align-items: center; gap: 6px; min-width: 0; }
/* Ellipsis must live on the flex CHILD; a flex container clips hard. */
.svc-casebar__title > span { min-width: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.svc-casebar__home { color: inherit; text-decoration: none; }
.svc-casebar__home:hover { color: var(--purple, #6938EF); text-decoration: underline; }
.svc-casebar__meta { display: flex; align-items: center; gap: 8px; margin-top: 3px; font-size: 12px; flex-wrap: wrap; }
.svc-casebar__actions { display: flex; align-items: center; gap: 8px; flex: none; }
.svc-casebar__actions .svc-btn--ghost.is-on { color: var(--purple, #6938EF); }

/* Work order document */
.svc-wo { background: var(--white, #fff); border: 1px solid var(--neutral-200, #EDEEF0); border-radius: 12px; padding: 16px 18px; display: flex; flex-direction: column; gap: 14px; }
.svc-wo--loading, .svc-wo--error { gap: 6px; }
.svc-wo__head { display: flex; flex-direction: column; gap: 8px; }
.svc-wo__title { font-size: 17px; font-weight: 650; color: var(--text, #0A0A0A); line-height: 1.3; }
.svc-wo__pills { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.svc-wo__opened { font-size: 12px; color: var(--text-muted, #6B6B7B); }
.svc-wo__section { border-top: 1px solid var(--neutral-200, #EDEEF0); padding-top: 12px; display: flex; flex-direction: column; gap: 7px; }
.svc-wo__label { margin: 0; font-size: 10.5px; font-weight: 650; letter-spacing: 0.07em; text-transform: uppercase; color: var(--text-soft, #A1A1AC); }
.svc-wo__strong { font-weight: 600; font-size: 14px; color: var(--text, #0A0A0A); display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.svc-wo__prose { font-size: 13px; color: var(--text, #0A0A0A); white-space: pre-wrap; line-height: 1.45; }
.svc-wo__property { font-size: 13px; color: var(--text-muted, #6B6B7B); }
.svc-wo__chips { display: flex; gap: 6px; flex-wrap: wrap; }
.svc-wo__contact { font-size: 13px; display: flex; gap: 10px; flex-wrap: wrap; }
.svc-wo__contact a, .svc-warranty a { color: var(--purple, #6938EF); text-decoration: none; }
.svc-wo__links { display: flex; gap: 6px; flex-wrap: wrap; }
.svc-wo__list { margin: 0; padding-left: 18px; font-size: 13px; display: flex; flex-direction: column; gap: 3px; }
.svc-wo__docs { display: flex; flex-direction: column; gap: 5px; font-size: 13px; }
.svc-doc { display: flex; justify-content: space-between; gap: 10px; }
.svc-muted { color: var(--text-muted, #6B6B7B); font-size: 12.5px; }

.svc-wochip { display: inline-flex; align-items: center; border-radius: 999px; padding: 2px 9px; font-size: 11.5px; font-weight: 550; background: var(--pill-neutral-bg, #F2F2F4); color: var(--pill-neutral-fg, #6B6B7B); }
.svc-wochip--ok { background: #ECFDF5; color: #047857; }
.svc-wochip--bad { background: #FEE2E2; color: #B91C1C; }
.svc-wochip--amber { background: #FEF3C7; color: #92400E; }
.svc-wochip--muted { background: var(--pill-neutral-bg, #F2F2F4); color: var(--pill-neutral-fg, #6B6B7B); }
.svc-wochip--purple { background: var(--pill-purple-bg, #EFEAFE); color: var(--pill-purple-fg, #6938EF); }

/* .svc-banner / .svc-banner--amber / .svc-table come from service.css */
.svc-banner--neutral { background: var(--pearl, #FAFAFC); color: var(--text-muted, #6B6B7B); border: 1px solid var(--neutral-200, #EDEEF0); }
.svc-table .svc-num, .svc-table th.svc-num { text-align: right; }

.svc-facts { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 6px 16px; }
.svc-fact { display: flex; flex-direction: column; gap: 1px; font-size: 13px; }
.svc-fact__k { font-size: 11px; color: var(--text-soft, #A1A1AC); }
.svc-fact__v { color: var(--text, #0A0A0A); }

.svc-warranty { border: 1px solid var(--neutral-200, #EDEEF0); border-radius: 8px; padding: 8px 10px; display: flex; flex-direction: column; gap: 3px; font-size: 13px; }
.svc-wo__warranties { display: flex; flex-direction: column; gap: 6px; }
.svc-warranty__top { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.svc-linkchip { border: 1px solid var(--neutral-300, #D8DADF); border-radius: 999px; padding: 2px 10px; font-size: 12px; color: var(--text, #0A0A0A); text-decoration: none; }
.svc-linkchip:hover { border-color: var(--purple, #6938EF); color: var(--purple, #6938EF); }

/* Thread additions on top of service.css message styles */
.svc-thread__empty { padding: 8px 0; }
.svc-msg--pending { opacity: 0.65; }
.svc-msg__sending { font-size: 11px; color: var(--text-soft, #A1A1AC); padding: 0 4px; }
.svc-msg__attachments { display: flex; gap: 6px; flex-wrap: wrap; padding: 2px 0; }
.svc-workspace-empty { display: flex; flex-direction: column; align-items: center; gap: 6px; padding: 60px 20px; color: var(--text-muted, #6B6B7B); font-size: 13.5px; text-align: center; }

/* Proposal card internals (shell classes come from service.css) */
.svc-proposal__body { display: flex; flex-direction: column; gap: 3px; }
.svc-proposal__name { font-weight: 600; }
.svc-proposal__list { margin: 2px 0 0 16px; padding: 0; }

/* Composer additions */
.svc-composer__input { width: 100%; min-height: 64px; }
.svc-composer { position: relative; }
.svc-composer--locked { display: flex; align-items: center; justify-content: space-between; gap: 12px; font-size: 13px; color: var(--text-muted, #6B6B7B); }
.svc-composer__bar .svc-check { margin: 0; white-space: nowrap; }
.svc-composer__bar { flex-wrap: wrap; }

.svc-snip { position: absolute; bottom: calc(100% + 4px); left: 16px; width: min(440px, 85%); background: var(--white, #fff); border: 1px solid var(--neutral-300, #D8DADF); border-radius: 10px; box-shadow: 0 8px 28px rgba(10, 10, 10, 0.12); overflow: hidden; z-index: 30; }
.svc-snip__hint { font-size: 11px; color: var(--text-soft, #A1A1AC); padding: 6px 12px 4px; }
.svc-snip__empty { font-size: 12.5px; color: var(--text-muted, #6B6B7B); padding: 10px 12px; }
.svc-snip__item { display: flex; align-items: baseline; gap: 8px; width: 100%; text-align: left; border: none; background: transparent; padding: 7px 12px; cursor: pointer; font-size: 13px; font-family: inherit; }
.svc-snip__item:hover, .svc-snip__item.is-sel { background: var(--purple-pale, #EFEAFE); }
.svc-snip__slug { font-weight: 600; color: var(--purple, #6938EF); flex: none; }
.svc-snip__label { color: var(--text, #0A0A0A); flex: none; }
.svc-snip__preview { color: var(--text-soft, #A1A1AC); font-size: 12px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }

/* Alfred rail internals */
.svc-alfred { display: flex; flex-direction: column; height: 100%; min-height: 0; }
.svc-alfred__head { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; padding: 12px 14px; border-bottom: 1px solid var(--neutral-200, #EDEEF0); }
.svc-alfred__title { font-weight: 650; font-size: 14px; color: var(--text, #0A0A0A); }
.svc-alfred__hint { font-size: 11.5px; color: var(--text-soft, #A1A1AC); margin-top: 2px; }
.svc-alfred__scroll { flex: 1; overflow-y: auto; min-height: 0; padding: 12px 14px; display: flex; flex-direction: column; gap: 10px; }
.svc-alfred__empty { font-size: 12.5px; color: var(--text-muted, #6B6B7B); line-height: 1.5; }
.svc-alfred__msg { display: flex; flex-direction: column; gap: 2px; max-width: 95%; }
.svc-alfred__msg--q { align-self: flex-end; align-items: flex-end; }
.svc-alfred__msg--a { align-self: flex-start; }
.svc-alfred__bubble { border-radius: 10px; padding: 7px 10px; font-size: 12.5px; line-height: 1.45; white-space: pre-wrap; word-break: break-word; }
.svc-alfred__msg--q .svc-alfred__bubble { background: var(--text, #0A0A0A); color: #fff; }
.svc-alfred__msg--a .svc-alfred__bubble { background: var(--pearl, #FAFAFC); border: 1px solid var(--neutral-200, #EDEEF0); color: var(--text, #0A0A0A); }
.svc-alfred__bubble--pending { color: var(--text-muted, #6B6B7B); font-style: italic; }
.svc-alfred__time { font-size: 10.5px; color: var(--text-soft, #A1A1AC); }
.svc-alfred__suggest { display: flex; flex-direction: column; gap: 6px; padding: 10px 14px; }
.svc-suggest { border: 1px solid var(--neutral-300, #D8DADF); background: var(--white, #fff); border-radius: 999px; padding: 5px 12px; font-size: 12px; color: var(--text-muted, #6B6B7B); cursor: pointer; text-align: left; font-family: inherit; }
.svc-suggest:hover { border-color: var(--purple, #6938EF); color: var(--purple, #6938EF); }
.svc-suggest:disabled { opacity: 0.5; cursor: default; }
.svc-alfred__inputrow { display: flex; align-items: flex-end; gap: 8px; padding: 0 14px 14px; }
.svc-alfred__input { flex: 1; resize: none; min-height: 0; }

/* Resolve form */
.svc-resolve { display: flex; flex-direction: column; gap: 12px; }
.svc-modal__intro { margin: 0; font-size: 13px; color: var(--text-muted, #6B6B7B); line-height: 1.45; }
.svc-field__hint { font-size: 12px; color: var(--text-soft, #A1A1AC); display: block; margin-bottom: 4px; }
.svc-pickrow { display: flex; gap: 6px; }
.svc-pickrow--wrap { flex-wrap: wrap; }
.svc-pick { border: 1px solid var(--neutral-300, #D8DADF); background: var(--white, #fff); border-radius: 999px; padding: 4px 11px; font-size: 12px; color: var(--text-muted, #6B6B7B); cursor: pointer; font-family: inherit; }
.svc-pick.is-on { background: var(--text, #0A0A0A); border-color: var(--text, #0A0A0A); color: #fff; }
`;
  document.head.appendChild(style);
}
