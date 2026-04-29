#!/usr/bin/env node
/**
 * Marks one or more admin_codex_notes rows as applied (with optional commit SHA).
 * Run after Claude lands the corresponding code changes so the note moves out
 * of the "Pending Changes" section in CLAUDE_ADMIN_NOTES.md.
 *
 * Usage:
 *   node scripts/mark_admin_note_applied.mjs <note_id> [commit_sha]
 *   node scripts/mark_admin_note_applied.mjs <note_id1> <note_id2> ... --commit <sha>
 *
 * Examples:
 *   node scripts/mark_admin_note_applied.mjs c4a1...uuid abc1234
 *   node scripts/mark_admin_note_applied.mjs id1 id2 id3 --commit abc1234
 *
 * Env (same as sync script):
 *   SUPABASE_SERVICE_ROLE_KEY  — preferred
 *   CHEZ_ADMIN_PASSWORD        — fallback (signs in as tom@getchez.com)
 */

import { execSync } from "node:child_process";

const supabaseUrl = process.env.SUPABASE_URL || "https://jsucwnkntdrxhysojgri.supabase.co";
const anonKey =
  process.env.SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

const argv = process.argv.slice(2);
const commitFlagIdx = argv.indexOf("--commit");
let explicitCommit = null;
if (commitFlagIdx >= 0) {
  explicitCommit = argv[commitFlagIdx + 1];
  argv.splice(commitFlagIdx, 2);
}

const noteIds = argv.filter((a) => /^[0-9a-f-]{32,40}$/.test(a) || /^[0-9a-f-]{36}$/.test(a));
const possibleSha = argv.find((a) => /^[0-9a-f]{6,40}$/.test(a) && a.length < 40);

if (!noteIds.length) {
  console.error("Usage: mark_admin_note_applied.mjs <note_id> [commit_sha]");
  console.error("       mark_admin_note_applied.mjs <id1> <id2> ... --commit <sha>");
  process.exit(1);
}

const commitSha = explicitCommit || possibleSha || resolveHeadCommit();

function resolveHeadCommit() {
  try {
    return execSync("git rev-parse HEAD").toString().trim();
  } catch {
    return null;
  }
}

async function authHeaders() {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return {
      apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
      authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    };
  }
  const email = process.env.CHEZ_ADMIN_EMAIL || "tom@getchez.com";
  const password = process.env.CHEZ_ADMIN_PASSWORD;
  if (!password) {
    throw new Error("Set SUPABASE_SERVICE_ROLE_KEY or CHEZ_ADMIN_PASSWORD.");
  }
  const response = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: { apikey: anonKey, "content-type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  if (!response.ok) {
    throw new Error(`Sign-in failed: ${response.status} ${await response.text()}`);
  }
  const json = await response.json();
  return {
    apikey: anonKey,
    authorization: `Bearer ${json.access_token}`,
  };
}

async function markApplied() {
  const headers = await authHeaders();
  const appliedAt = new Date().toISOString();
  const updated = [];
  for (const noteId of noteIds) {
    const url = new URL(`${supabaseUrl}/rest/v1/admin_codex_notes`);
    url.searchParams.set("id", `eq.${noteId}`);
    const r = await fetch(url, {
      method: "PATCH",
      headers: { ...headers, "content-type": "application/json", prefer: "return=representation" },
      body: JSON.stringify({
        applied_at: appliedAt,
        applied_commit: commitSha,
        apply_validation_status: "pending",
      }),
    });
    if (!r.ok) {
      console.warn(`[mark-applied] ${noteId} → ${r.status} ${await r.text()}`);
      continue;
    }
    const [row] = await r.json();
    if (row) updated.push(row);
  }
  console.log(
    `[mark-applied] applied ${updated.length}/${noteIds.length} note(s)${
      commitSha ? " at commit " + commitSha.slice(0, 7) : ""
    }`
  );
  for (const row of updated) {
    console.log(`  ✓ ${row.id} — ${row.scope_type}/${row.scope_id || "?"} "${row.scope_title}"`);
  }
}

markApplied().catch((err) => {
  console.error("[mark-applied] failed:", err.message);
  process.exit(1);
});
