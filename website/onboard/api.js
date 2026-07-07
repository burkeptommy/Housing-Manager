// Chez onboarding capture app — API client for the chez-onboard edge function.
// Deployed --no-verify-jwt, so no apikey/Authorization headers are needed;
// the session token in the body is the credential.

const ENDPOINT = "https://jsucwnkntdrxhysojgri.supabase.co/functions/v1/chez-onboard";

let token = "";
let onGone = null; // called with "expired" | "revoked" | "unknown"

export class ApiError extends Error {
  constructor(message, status, code) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code; // "network" | "expired" | "revoked" | "unknown" | "error"
  }
}

export function init(sessionToken, goneHandler) {
  token = sessionToken;
  onGone = goneHandler;
}

async function post(body, timeoutMs) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    return await fetch(ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: ctrl.signal,
    });
  } finally {
    clearTimeout(timer);
  }
}

// call("save_capture", { capture: {...} }) — token is injected on every call.
// One automatic retry on network failure (offline blip, timeout).
export async function call(action, payload = {}, opts = {}) {
  const body = { action, token, ...payload };
  const timeoutMs = opts.timeoutMs || 20000;

  let res;
  try {
    res = await post(body, timeoutMs);
  } catch (_first) {
    try {
      res = await post(body, timeoutMs);
    } catch (_second) {
      throw new ApiError("We could not reach Chez. Check your connection.", 0, "network");
    }
  }

  let data;
  try {
    data = await res.json();
  } catch (_e) {
    data = {};
  }

  if (res.ok) return data;

  const message = (data && data.error) || "Something went wrong.";

  if (res.status === 410) {
    const code = /revok/i.test(message) ? "revoked" : "expired";
    if (onGone) onGone(code);
    throw new ApiError(message, 410, code);
  }

  if (res.status === 404 && action === "bootstrap") {
    if (onGone) onGone("unknown");
    throw new ApiError(message, 404, "unknown");
  }

  throw new ApiError(message, res.status, "error");
}
