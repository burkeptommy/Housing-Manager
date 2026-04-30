#!/usr/bin/env node
/**
 * Pulls all pending Voice fix notes from admin_codex_notes, applies their
 * proposed_diff (from -> to) to MaintenanceTemplates.swift, and emits a
 * summary of which notes succeeded / failed.
 *
 * Usage:
 *   CHEZ_ADMIN_PASSWORD=… node scripts/apply_voice_fixes.mjs           # dry run
 *   CHEZ_ADMIN_PASSWORD=… node scripts/apply_voice_fixes.mjs --write   # write file
 */

import { readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

const supabaseUrl = process.env.SUPABASE_URL || "https://jsucwnkntdrxhysojgri.supabase.co";
const anonKey = process.env.SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

const targetFile = resolve(process.cwd(), "Haven/Features/Property/Services/MaintenanceTemplates.swift");
const writeMode = process.argv.includes("--write");
const skipTemplates = (process.env.SKIP_TEMPLATES || "").split(",").map((s) => s.trim()).filter(Boolean);

async function authHeaders() {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return {
      apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
      authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
    };
  }
  const password = process.env.CHEZ_ADMIN_PASSWORD;
  if (!password) throw new Error("Set CHEZ_ADMIN_PASSWORD or SUPABASE_SERVICE_ROLE_KEY.");
  const r = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: { apikey: anonKey, "content-type": "application/json" },
    body: JSON.stringify({ email: process.env.CHEZ_ADMIN_EMAIL || "tom@getchez.com", password }),
  });
  if (!r.ok) throw new Error(`Auth: ${r.status} ${await r.text()}`);
  const { access_token } = await r.json();
  return { apikey: anonKey, authorization: `Bearer ${access_token}` };
}

const headers = await authHeaders();
const url = new URL(`${supabaseUrl}/rest/v1/admin_codex_notes`);
url.searchParams.set("select", "id,intent,scope_type,scope_title,body,proposed_diff,applied_at");
url.searchParams.set("or", "(target.eq.claude,target.eq.both)");
url.searchParams.set("order", "created_at.desc");
url.searchParams.set("limit", "2000");
const r = await fetch(url, { headers });
if (!r.ok) throw new Error(`Fetch: ${r.status} ${await r.text()}`);
const rows = await r.json();

const voiceFixNotes = rows.filter(
  (n) =>
    !n.applied_at &&
    n.intent === "change_request" &&
    n.scope_type === "task" &&
    typeof n.body === "string" &&
    n.body.includes("Voice fix") &&
    n.proposed_diff &&
    typeof n.proposed_diff === "object" &&
    !skipTemplates.some((s) => n.scope_title.toLowerCase().includes(s.toLowerCase()))
);

console.log(`[voice-fix] ${voiceFixNotes.length} pending notes to apply`);

let source = await readFile(targetFile, "utf8");
const succeeded = [];
const failed = [];

// Sort: longest 'from' first to avoid partial-match collisions when one
// template's wording is a substring of another.
const ordered = voiceFixNotes
  .map((note) => {
    const diff = note.proposed_diff;
    // diff shape: { description: { from, to } } OR { notes: { from, to } }
    const field = Object.keys(diff)[0];
    const pair = diff[field];
    return { note, field, from: pair?.from || "", to: pair?.to || "" };
  })
  .filter((p) => p.from && p.to)
  .sort((a, b) => b.from.length - a.from.length);

// Swift source uses `\"` for inline double-quotes inside string literals,
// but JSON decodes those to plain `"`. Try the literal first, then a
// Swift-escaped variant before declaring failure.
function swiftEscape(s) {
  return s.replace(/"/g, '\\"');
}

for (const { note, field, from, to } of ordered) {
  let attemptFrom = from;
  let attemptTo = to;
  let idx = source.indexOf(attemptFrom);
  if (idx < 0) {
    // Retry with Swift-style escaped quotes.
    attemptFrom = swiftEscape(from);
    attemptTo = swiftEscape(to);
    idx = source.indexOf(attemptFrom);
  }
  if (idx < 0) {
    // Idempotent: if the target text is already present (and the source
    // isn't), the change was already applied (likely by a duplicate note
    // earlier in this same batch). Mark it applied without rewriting.
    if (source.includes(to) || source.includes(swiftEscape(to))) {
      succeeded.push({ note, field, idempotent: true });
      continue;
    }
    failed.push({ note, field, reason: "from-string not found" });
    continue;
  }
  const occurrences = source.split(attemptFrom).length - 1;
  if (occurrences > 1) {
    failed.push({ note, field, reason: `from-string ambiguous (${occurrences} matches)` });
    continue;
  }
  source = source.replace(attemptFrom, attemptTo);
  succeeded.push({ note, field });
}

console.log(`[voice-fix] ${succeeded.length} succeeded, ${failed.length} failed`);
for (const s of succeeded) {
  console.log(`  ✓ ${s.note.id} — ${s.note.scope_title} (${s.field})`);
}
for (const f of failed) {
  console.log(`  ✗ ${f.note.id} — ${f.note.scope_title} (${f.field}): ${f.reason}`);
}

if (writeMode && succeeded.length > 0) {
  await writeFile(targetFile, source);
  console.log(`[voice-fix] wrote ${targetFile}`);
}
if (!writeMode) {
  console.log(`[voice-fix] DRY RUN — re-run with --write to apply`);
}

// Emit succeeded note IDs to stderr (one per line) for shell capture.
for (const s of succeeded) {
  process.stderr.write(`${s.note.id}\n`);
}
