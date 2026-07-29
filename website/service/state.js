// state.js — the single shared state object for the Chez service portal.
//
// Contract (SERVICE_PORTAL_CONTRACT.md): `state` + `setState(patch)` with a
// shallow merge and NO auto-render. Zones re-paint only when a caller
// explicitly invalidates them (see render.js). renderFns are pure reads of
// this object.

import { callConcierge } from "./api.js";

export const state = {
  user: null, // {id, email} | null
  boot: null, // fetch_service_boot result (today brief + queue + tags + snippets)
  queue: [], // slim request rows (from boot; refreshed via refreshQueue())
  activeCaseId: null,
  cases: {}, // request_id -> fetch_case_bundle result (cache)
  ui: { density: "normal", alfredOpen: true, queueFilter: "all", search: "" },
};

/** Shallow merge. Callers invalidate the zones they touched. */
export function setState(patch) {
  Object.assign(state, patch || {});
}

/**
 * Re-fetch the boot payload and refresh `state.boot` + `state.queue`.
 * Callers invalidate their own zones afterward. Returns the boot result.
 */
export async function refreshQueue() {
  const boot = await callConcierge("fetch_service_boot");
  setState({ boot, queue: Array.isArray(boot?.queue) ? boot.queue : [] });
  return boot;
}
