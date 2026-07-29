// storage.js — localStorage persistence for the Chez service portal.
//
// Contract (SERVICE_PORTAL_CONTRACT.md):
//   uiGet()                    — "chez-svc-ui-v1" -> object
//   uiSet(patch)
//   scratchGet(requestId)      — "chez-svc-scratch-<id>" -> per-case scratchpad
//   scratchSet(requestId, patch) — LRU cap of 30 scratchpads, index list
//                                  under "chez-svc-scratch-index"
//
// First run imports the legacy admin cockpit prefs ("chez-cockpit-ui-v1":
// { aiOpen, vendorOpen, density }) so the operator's Alfred-rail and density
// choices carry over: aiOpen -> alfredOpen, "compact" stays compact and
// everything else maps to "normal".
//
// Every call fails soft (private browsing, quota, disabled storage).

const UI_KEY = "chez-svc-ui-v1";
const LEGACY_COCKPIT_KEY = "chez-cockpit-ui-v1";
const SCRATCH_PREFIX = "chez-svc-scratch-";
const SCRATCH_INDEX_KEY = "chez-svc-scratch-index";
const SCRATCH_CAP = 30;

const SCRATCH_DEFAULTS = {
  composerDraft: "",
  tone: "warm",
  ackRequired: false,
  alfredInput: "",
  alfredChat: [],
};

function readJson(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    const parsed = JSON.parse(raw);
    return parsed === null || parsed === undefined ? fallback : parsed;
  } catch {
    return fallback;
  }
}

function writeJson(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* fail soft */
  }
}

function importLegacyCockpitUi() {
  const legacy = readJson(LEGACY_COCKPIT_KEY, null);
  if (!legacy || typeof legacy !== "object") return {};
  const imported = {};
  if (typeof legacy.aiOpen === "boolean") imported.alfredOpen = legacy.aiOpen;
  if (typeof legacy.density === "string") {
    imported.density = legacy.density === "compact" ? "compact" : "normal";
  }
  if (Object.keys(imported).length > 0) writeJson(UI_KEY, imported);
  return imported;
}

/** UI prefs object (density, alfredOpen, ...). Never null. */
export function uiGet() {
  const stored = readJson(UI_KEY, null);
  if (stored && typeof stored === "object") return stored;
  return importLegacyCockpitUi();
}

/** Shallow-merge a patch into the persisted UI prefs. */
export function uiSet(patch) {
  const current = uiGet();
  writeJson(UI_KEY, { ...current, ...(patch || {}) });
}

// ── Per-case scratchpads (LRU capped) ───────────────────────────────────────

function readIndex() {
  const idx = readJson(SCRATCH_INDEX_KEY, []);
  return Array.isArray(idx) ? idx.filter((id) => typeof id === "string") : [];
}

/** Scratchpad for a case; always returns the full default shape. */
export function scratchGet(requestId) {
  if (!requestId) return { ...SCRATCH_DEFAULTS, alfredChat: [] };
  const stored = readJson(SCRATCH_PREFIX + requestId, null) || {};
  const merged = { ...SCRATCH_DEFAULTS, ...stored };
  if (!Array.isArray(merged.alfredChat)) merged.alfredChat = [];
  return merged;
}

/** Merge a patch into a case scratchpad and bump it to the front of the LRU. */
export function scratchSet(requestId, patch) {
  if (!requestId) return;
  const next = { ...scratchGet(requestId), ...(patch || {}) };
  writeJson(SCRATCH_PREFIX + requestId, next);

  // LRU bookkeeping: most-recent first, evict past the cap.
  let index = readIndex().filter((id) => id !== requestId);
  index.unshift(requestId);
  if (index.length > SCRATCH_CAP) {
    const evicted = index.slice(SCRATCH_CAP);
    index = index.slice(0, SCRATCH_CAP);
    for (const id of evicted) {
      try {
        localStorage.removeItem(SCRATCH_PREFIX + id);
      } catch {
        /* fail soft */
      }
    }
  }
  writeJson(SCRATCH_INDEX_KEY, index);
}
