// api.js — auth + edge-function transport for the Chez service portal.
//
// Contract (SERVICE_PORTAL_CONTRACT.md):
//   initAuth()                — supabase-js from the same CDN admin.js uses; restores session
//   currentUser()             — {id, email} | null
//   signIn(email, password)   — throws Error(message) on failure
//   signOut()
//   callConcierge(action, payload = {})
//   ApiError                  — {status, body} on non-2xx
//
// ─────────────────────────────────────────────────────────────────────────────
// TEST HOOK: window.__SVC_MOCK__
// ─────────────────────────────────────────────────────────────────────────────
// When `window.__SVC_MOCK__` is set, this module never touches the network
// (no supabase-js CDN load, no edge-function calls). Shape:
//
//   window.__SVC_MOCK__ = {
//     // Session restored by initAuth(). Falsy -> the login card shows.
//     user: { id: "op-1", email: "tom@getchez.com" },
//
//     // Optional sign-in control. Either a function (throw to simulate a
//     // failure) or `signInPassword`: signIn succeeds only when the typed
//     // password matches (else throws "Invalid login credentials").
//     // With neither, any credentials succeed as `user`.
//     signIn: async (email, password) => ({ id: "op-1", email }),
//     signInPassword: "demo",
//
//     // Canned responses per action. Value is a plain object (deep-cloned
//     // per call) OR a function `(payload, action) => value` (may be async,
//     // may throw ApiError). "*" is the fallback for unlisted actions.
//     // To simulate an HTTP error from a plain-object entry, use:
//     //   { __apiError: { status: 403, body: { error: "admin only" }, message: "admin only" } }
//     responses: {
//       fetch_service_boot: { today: {...}, queue: [...], tag_definitions: [], snippets: [] },
//       "*": (payload, action) => ({ ok: true }),
//     },
//
//     delay: 120,   // optional ms of simulated latency per call
//     calls: [],    // auto-populated: { action, payload, at } per callConcierge
//   };
//
// Reload persistence: JSON-only mocks (no functions) survive reloads via
//   sessionStorage.setItem("chez-svc-mock-v1", JSON.stringify(mock))
// api.js hydrates window.__SVC_MOCK__ from that key at module load when the
// window global isn't already set. Clear the key to return to live mode.
// ─────────────────────────────────────────────────────────────────────────────

const SUPABASE_URL = "https://jsucwnkntdrxhysojgri.supabase.co";
// Public anon key (same constant admin.js ships; it is not a secret).
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";
const CONCIERGE_URL = `${SUPABASE_URL}/functions/v1/chez-concierge`;
const MOCK_SESSION_KEY = "chez-svc-mock-v1";

export class ApiError extends Error {
  constructor(message, status = 0, body = null) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.body = body;
  }
}

// Hydrate a reload-persistent mock (JSON only) into the window global.
(() => {
  try {
    if (typeof window !== "undefined" && !window.__SVC_MOCK__) {
      const raw = sessionStorage.getItem(MOCK_SESSION_KEY);
      if (raw) window.__SVC_MOCK__ = JSON.parse(raw);
    }
  } catch {
    /* sessionStorage unavailable; live mode */
  }
})();

function mock() {
  return (typeof window !== "undefined" && window.__SVC_MOCK__) || null;
}

let supabase = null;
let user = null;

async function ensureClient() {
  if (supabase) return supabase;
  const { createClient } = await import(
    "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm"
  );
  supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
    },
  });
  return supabase;
}

/** Restore any persisted session. Returns {id, email} | null. */
export async function initAuth() {
  const m = mock();
  if (m) {
    user = m.user || null;
    return user;
  }
  await ensureClient();
  const { data } = await supabase.auth.getSession();
  user = data.session
    ? { id: data.session.user.id, email: data.session.user.email || "" }
    : null;
  return user;
}

/** {id, email} | null — the signed-in operator as of the last auth event. */
export function currentUser() {
  return user;
}

/** Email + password sign-in. Throws Error(message) on failure. */
export async function signIn(email, password) {
  const m = mock();
  if (m) {
    if (typeof m.signIn === "function") {
      user = await m.signIn(email, password);
      return user;
    }
    if (m.signInPassword !== undefined && password !== m.signInPassword) {
      throw new Error("Invalid login credentials");
    }
    user = m.user || { id: "mock-user", email };
    return user;
  }
  await ensureClient();
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw new Error(error.message);
  user = { id: data.session.user.id, email: data.session.user.email || "" };
  return user;
}

export async function signOut() {
  const m = mock();
  if (m) {
    user = null;
    return;
  }
  try {
    await ensureClient();
    await supabase.auth.signOut();
  } finally {
    user = null;
  }
}

/**
 * POST {action, ...payload} to the chez-concierge edge function.
 * Non-2xx throws ApiError {status, body}. One silent retry on a network
 * error or a 5xx before giving up.
 */
export async function callConcierge(action, payload = {}) {
  const m = mock();
  if (m) return mockCall(m, action, payload);

  await ensureClient();
  const { data } = await supabase.auth.getSession();
  const session = data.session;
  if (!session) throw new ApiError("Not signed in", 401, null);

  const request = () =>
    fetch(CONCIERGE_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ ...payload, action }),
    });

  let resp = null;
  let networkError = null;
  try {
    resp = await request();
  } catch (err) {
    networkError = err;
  }
  if (networkError || (resp && resp.status >= 500)) {
    // One silent retry after a short beat.
    await new Promise((r) => setTimeout(r, 400));
    networkError = null;
    try {
      resp = await request();
    } catch (err) {
      networkError = err;
    }
  }
  if (networkError || !resp) {
    throw new ApiError("Network error. Check the connection and try again.", 0, null);
  }
  if (!resp.ok) {
    const text = await resp.text();
    let body = null;
    let message = `Request failed (${resp.status})`;
    try {
      body = JSON.parse(text);
      if (body && body.error) message = body.error;
    } catch {
      body = text || null;
      if (text) message = text.slice(0, 200);
    }
    throw new ApiError(message, resp.status, body);
  }
  return resp.json();
}

// ── Mock transport ──────────────────────────────────────────────────────────

async function mockCall(m, action, payload) {
  if (!Array.isArray(m.calls)) m.calls = [];
  m.calls.push({ action, payload, at: Date.now() });
  if (m.delay) await new Promise((r) => setTimeout(r, m.delay));

  const table = m.responses || {};
  const handler = table[action] !== undefined ? table[action] : table["*"];
  if (handler === undefined) {
    throw new ApiError(`No mock response for "${action}"`, 501, null);
  }
  let value = typeof handler === "function" ? await handler(payload, action) : handler;
  if (value && typeof value === "object" && value.__apiError) {
    const e = value.__apiError;
    throw new ApiError(
      e.message || `Request failed (${e.status || 500})`,
      e.status || 500,
      e.body ?? null
    );
  }
  if (value && typeof value === "object") {
    try {
      return structuredClone(value);
    } catch {
      return value; // non-cloneable (contains functions); hand back as-is
    }
  }
  return value;
}
