// render.js — zone rendering engine for the Chez service portal.
//
// The core pattern (SERVICE_PORTAL_CONTRACT.md): views register named zones
// (an element + a pure renderFn over `state`). State mutations invalidate
// zones by name; dirty zones flush together on a microtask. Typing in an
// input NEVER invalidates the zone that contains it (drafts go to
// storage/state without a re-render), and event handlers are never inline
// in HTML (see actions.js delegation).
//
// zone() paints once at registration so callers don't need an immediate
// invalidate after registering.

const zones = new Map(); // name -> { el, renderFn }
const dirty = new Set();
let flushScheduled = false;

/** Register a zone and paint it. renderFn: () => htmlString (pure read of state). */
export function zone(name, el, renderFn) {
  if (!el) {
    console.warn(`[render] zone "${name}" registered without an element`);
    return;
  }
  zones.set(name, { el, renderFn });
  paint(name);
}

/** Deregister zones on view teardown. */
export function unzone(...names) {
  for (const name of names) {
    zones.delete(name);
    dirty.delete(name);
  }
}

/** Mark zones dirty; they repaint together on the next microtask. */
export function invalidate(...names) {
  for (const name of names) dirty.add(name);
  if (flushScheduled) return;
  flushScheduled = true;
  queueMicrotask(flush);
}

function flush() {
  flushScheduled = false;
  const batch = [...dirty];
  dirty.clear();
  for (const name of batch) paint(name);
}

function paint(name) {
  const z = zones.get(name);
  if (!z) return; // unzoned before the flush landed
  try {
    z.el.innerHTML = z.renderFn();
  } catch (err) {
    console.error(`[render] zone "${name}" failed to render`, err);
  }
}

/** HTML-escape any value. Null-safe: null/undefined -> "". */
export function esc(v) {
  if (v === null || v === undefined) return "";
  return String(v)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}
