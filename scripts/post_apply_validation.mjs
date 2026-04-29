#!/usr/bin/env node
/**
 * Posts the result of `xcodebuild` for a given commit back to Supabase.
 * Updates every admin_codex_notes row whose applied_commit matches the
 * provided SHA — flipping apply_validation_status to 'success' or
 * 'failed' (with optional log excerpt on failure).
 *
 * Usage:
 *   node scripts/post_apply_validation.mjs <status> <commit_sha> [log_excerpt]
 *
 * status: 'success' | 'failed' | 'pending'
 *
 * Env (CI runs with SUPABASE_SERVICE_ROLE_KEY):
 *   SUPABASE_URL                 — defaults to Haven prod project
 *   SUPABASE_SERVICE_ROLE_KEY    — required
 */

const supabaseUrl = process.env.SUPABASE_URL || "https://jsucwnkntdrxhysojgri.supabase.co";
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const [, , status, sha, ...logRest] = process.argv;
const logExcerpt = logRest.join(" ");

if (!status || !sha) {
  console.error("Usage: post_apply_validation.mjs <status> <commit_sha> [log_excerpt]");
  process.exit(1);
}
if (!["success", "failed", "pending"].includes(status)) {
  console.error("status must be one of: success, failed, pending");
  process.exit(1);
}
if (!serviceKey) {
  console.error("SUPABASE_SERVICE_ROLE_KEY not set");
  process.exit(1);
}

async function main() {
  const url = new URL(`${supabaseUrl}/rest/v1/admin_codex_notes`);
  url.searchParams.set("applied_commit", `eq.${sha}`);

  const body = {
    apply_validation_status: status,
    applied_validated_at: new Date().toISOString(),
    apply_validation_log: status === "failed" ? logExcerpt.slice(0, 4000) : null,
  };

  const r = await fetch(url, {
    method: "PATCH",
    headers: {
      apikey: serviceKey,
      authorization: `Bearer ${serviceKey}`,
      "content-type": "application/json",
      prefer: "return=representation",
    },
    body: JSON.stringify(body),
  });

  if (!r.ok) {
    const text = await r.text();
    console.error(`[post-apply] PATCH failed: ${r.status} ${text}`);
    process.exit(1);
  }
  const rows = await r.json();
  console.log(`[post-apply] marked ${rows.length} note(s) for commit ${sha.slice(0, 7)} as ${status}.`);
  if (status === "failed") {
    console.log(`[post-apply] log excerpt (${logExcerpt.length} chars) attached.`);
  }
}

main().catch((err) => {
  console.error("[post-apply] fatal:", err.message);
  process.exit(1);
});
