// require-household.ts
//
// Shared auth guard for edge functions — July 2026 security sweep.
//
// The audit (PRODUCT_AUDIT_2026-07.md, finding S1) traced one defect class
// through ~9 functions: service-role clients acting on household / document /
// vehicle IDs taken from the request body, several with a silent
// service-role FALLBACK when JWT verification failed. A leaked UUID was the
// only thing protecting household data. This helper is the single
// replacement: derive identity from the JWT, derive household from the
// caller's users row, and NEVER fall back.
//
// Model implementation this codifies: view-document/index.ts (steps 1+4).
//
// Usage:
//   import { requireHousehold, requireInternal, authFailure } from "../_shared/require-household.ts";
//
//   const auth = await requireHousehold(req);
//   if ("failure" in auth) return authFailure(auth, headers);
//   const { userId, householdId } = auth;
//   // ...verify any body-supplied row belongs to householdId before acting.
//
// Function-to-function calls (receive-email → analyze-document, pg_cron →
// watchers) can't carry a user JWT. They authenticate with a shared secret
// header instead:
//   headers: { "x-internal-secret": Deno.env.get("INTERNAL_FN_SECRET")! }
// and the receiving function accepts EITHER a valid user JWT or
// requireInternal(req).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export interface AuthedCaller {
  userId: string;
  email: string | null;
  householdId: string;
}

export interface AuthFailure {
  failure: true;
  status: 401 | 403 | 500;
  message: string;
}

/** Build the JSON error response for a failed guard. */
export function authFailure(
  f: AuthFailure,
  headers: Record<string, string>,
): Response {
  return new Response(JSON.stringify({ error: f.message }), {
    status: f.status,
    headers,
  });
}

/**
 * Verify the caller's JWT and resolve their household. Returns AuthFailure
 * (never throws, never falls back to service role) when anything is off.
 */
export async function requireHousehold(
  req: Request,
): Promise<AuthedCaller | AuthFailure> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return { failure: true, status: 401, message: "Missing authorization header" };
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !anonKey) {
    return { failure: true, status: 500, message: "Auth not configured" };
  }

  const client = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error: authError } = await client.auth.getUser();
  if (authError || !user) {
    return { failure: true, status: 401, message: "Unauthorized" };
  }

  // Resolve household via the caller's users row (RLS-scoped client — the
  // caller can always read their own row; a service-role read here would
  // work too but the anon client keeps this helper privilege-free).
  const { data: userRow, error: userError } = await client
    .from("users")
    .select("household_id")
    .eq("id", user.id)
    .single();

  if (userError || !userRow?.household_id) {
    return { failure: true, status: 403, message: "No household for caller" };
  }

  return {
    userId: user.id,
    email: user.email ?? null,
    householdId: userRow.household_id as string,
  };
}

/**
 * True when the request carries the internal function-to-function secret.
 * Returns false (not a failure object) so callers can chain:
 *   if (!requireInternal(req)) { const auth = await requireHousehold(req); ... }
 */
export function requireInternal(req: Request): boolean {
  const secret = Deno.env.get("INTERNAL_FN_SECRET");
  if (!secret) return false;
  const provided = req.headers.get("x-internal-secret");
  return provided === secret;
}

/**
 * Convenience: 403 unless the body-supplied household matches the caller's.
 * Pass the body value ONLY for backward compatibility with clients that
 * still send household_id — the caller's JWT household always wins.
 */
export function householdMismatch(
  auth: AuthedCaller,
  bodyHouseholdId: string | null | undefined,
): AuthFailure | null {
  if (bodyHouseholdId && bodyHouseholdId !== auth.householdId) {
    return {
      failure: true,
      status: 403,
      message: "Access denied: household mismatch",
    };
  }
  return null;
}
