// Chez onboarding capture app — local draft store + sync queue.
//
// Everything the operator captures lives in localStorage under
// chez-onboard-<token>, then syncs to the chez-onboard edge function:
//   - sections sync via save_capture with REPLACE semantics (the page owns
//     the full array for each section; single operator per visit)
//   - follow-up recommendations sync via add/update/delete_recommendation
// Failed writes queue locally; the sync badge shows the pending count and
// syncNow() retries the whole queue.

import * as api from "./api.js";
import { updateSyncBadge } from "./ui.js";

// local section name -> save_capture payload key
const SECTION_KEYS = {
  systems: "captured_systems",
  contractors: "captured_contractors",
  routines: "captured_routines",
  utility_accounts: "captured_utility_accounts",
  quick_fixes: "captured_quick_fixes",
  attributes: "captured_attributes",
  concerns: "homeowner_concerns",
};

function defaultState() {
  return {
    systems: [],
    contractors: [],
    routines: [],
    utility_accounts: [],
    quick_fixes: [],
    attributes: {},
    concerns: "",
    recommendations: [],
    dirty: {},        // { sectionName: true } — needs sync
    pendingOps: [],   // [{ type: "add_rec", tempId } | { type: "upd_rec", id } | { type: "del_rec", id }]
  };
}

export let state = defaultState();

let storageKey = "";
let listeners = [];
const revs = {}; // per-section edit counter so an in-flight flush never clears a newer edit

export function init(token) {
  storageKey = `chez-onboard-${token}`;
  try {
    const raw = localStorage.getItem(storageKey);
    if (raw) state = { ...defaultState(), ...JSON.parse(raw) };
  } catch (_e) {
    state = defaultState();
  }
}

function persist() {
  try {
    localStorage.setItem(storageKey, JSON.stringify(state));
  } catch (_e) {
    // Storage full or unavailable — server sync still works; keep going.
  }
}

export function subscribe(fn) {
  listeners.push(fn);
}

function notify() {
  updateSyncBadge(pendingCount());
  for (const fn of listeners) fn(state);
}

export function pendingCount() {
  return Object.values(state.dirty).filter(Boolean).length + state.pendingOps.length;
}

// ---------- bootstrap merge ----------

// Server data comes in on bootstrap; local drafts win per-section when dirty
// (mid-visit resume after a reload or connection drop).
export function mergeBootstrap(assessment) {
  const cap = (assessment && assessment.captured) || {};
  const arraySections = ["systems", "contractors", "routines", "utility_accounts", "quick_fixes"];
  for (const section of arraySections) {
    if (!state.dirty[section]) state[section] = Array.isArray(cap[section]) ? cap[section] : [];
  }
  if (!state.dirty.attributes) {
    state.attributes = (cap.attributes && typeof cap.attributes === "object") ? cap.attributes : {};
  }
  if (!state.dirty.concerns) {
    state.concerns = assessment.homeowner_concerns || "";
  }
  // Recommendations: server rows are truth; keep local adds that never synced.
  const localTemps = (state.recommendations || []).filter((r) => String(r.id).startsWith("local-"));
  state.recommendations = [...(assessment.recommendations || []), ...localTemps];
  persist();
  notify();
}

// ---------- section saves (REPLACE semantics) ----------

async function flushSection(section) {
  if (!state.dirty[section]) return true;
  const key = SECTION_KEYS[section];
  const value = section === "concerns" ? state.concerns : state[section];
  const rev = revs[section] || 0;
  try {
    await api.call("save_capture", { capture: { [key]: value } });
    if ((revs[section] || 0) === rev) {
      state.dirty[section] = false;
      persist();
    }
    notify();
    return true;
  } catch (_e) {
    notify();
    return false;
  }
}

// Writes locally first, then pushes the full section to the server.
// On failure the section stays queued (dirty) and the badge shows it.
export async function saveSection(section) {
  if (!SECTION_KEYS[section]) throw new Error(`unknown section ${section}`);
  revs[section] = (revs[section] || 0) + 1;
  state.dirty[section] = true;
  persist();
  notify();
  return flushSection(section);
}

// ---------- recommendations (add/delete, not save_capture) ----------

export async function addRecommendation(rec) {
  const tempId = "local-" + Date.now() + "-" + Math.random().toString(36).slice(2, 7);
  state.recommendations.push({ ...rec, id: tempId });
  persist();
  notify();
  try {
    const res = await api.call("add_recommendation", { recommendation: rec });
    const item = state.recommendations.find((r) => r.id === tempId);
    if (item && res && res.id) item.id = res.id;
    persist();
    notify();
  } catch (_e) {
    state.pendingOps.push({ type: "add_rec", tempId });
    persist();
    notify();
  }
}

// Edits an existing recommendation in place, keeping its id.
// Temp-id items (a queued or in-flight add) only mutate locally: the add op
// re-reads current state at flush time, so the queued payload IS the edit.
// Server-id items call update_recommendation; failures queue an upd_rec op.
export async function updateRecommendation(id, rec) {
  const item = state.recommendations.find((r) => r.id === id);
  if (!item) return;
  for (const k of Object.keys(item)) { if (k !== "id") delete item[k]; }
  Object.assign(item, rec);
  persist();
  notify();
  if (String(id).startsWith("local-")) return;
  try {
    await api.call("update_recommendation", { id, recommendation: rec });
  } catch (e) {
    if (e && e.status === 404) return; // row gone server-side; nothing to update
    if (!state.pendingOps.some((op) => op.type === "upd_rec" && op.id === id)) {
      state.pendingOps.push({ type: "upd_rec", id });
    }
    persist();
    notify();
  }
}

export async function deleteRecommendation(id) {
  const idx = state.recommendations.findIndex((r) => r.id === id);
  if (idx >= 0) state.recommendations.splice(idx, 1);
  // A delete supersedes any queued edit for the same row.
  state.pendingOps = state.pendingOps.filter((op) => !(op.type === "upd_rec" && op.id === id));
  if (String(id).startsWith("local-")) {
    // Never reached the server; drop any queued add for it.
    state.pendingOps = state.pendingOps.filter((op) => !(op.type === "add_rec" && op.tempId === id));
    persist();
    notify();
    return;
  }
  persist();
  notify();
  try {
    await api.call("delete_recommendation", { id });
  } catch (e) {
    if (e && e.status === 404) return; // already gone server-side
    state.pendingOps.push({ type: "del_rec", id });
    persist();
    notify();
  }
}

async function flushOp(op) {
  if (op.type === "add_rec") {
    const item = state.recommendations.find((r) => r.id === op.tempId);
    if (!item) return true; // deleted locally before it ever synced
    const { id: _drop, ...rec } = item;
    try {
      const res = await api.call("add_recommendation", { recommendation: rec });
      if (res && res.id) item.id = res.id;
      return true;
    } catch (_e) {
      return false;
    }
  }
  if (op.type === "upd_rec") {
    const item = state.recommendations.find((r) => r.id === op.id);
    if (!item) return true; // removed locally before the edit synced
    const { id: _drop, ...rec } = item;
    try {
      await api.call("update_recommendation", { id: op.id, recommendation: rec });
      return true;
    } catch (e) {
      return !!(e && e.status === 404); // row gone server-side counts as done
    }
  }
  if (op.type === "del_rec") {
    try {
      await api.call("delete_recommendation", { id: op.id });
      return true;
    } catch (e) {
      return e && e.status === 404; // treat missing row as done
    }
  }
  return true; // unknown op — drop it
}

// ---------- sync ----------

// Retries every queued section and recommendation op. Returns true when
// everything made it to the server.
export async function syncNow() {
  for (const section of Object.keys(SECTION_KEYS)) {
    if (state.dirty[section]) await flushSection(section);
  }
  const remaining = [];
  for (const op of state.pendingOps) {
    const ok = await flushOp(op);
    if (!ok) remaining.push(op);
  }
  state.pendingOps = remaining;
  persist();
  notify();
  return pendingCount() === 0;
}
