#!/usr/bin/env node
/**
 * Auto-propose curation changes from the Swift→JSON snapshots. The output
 * lands as admin_codex_notes rows with intent='change_request' so they
 * appear in the Decisions queue + sync into CLAUDE_ADMIN_NOTES.md for
 * Claude to apply next session.
 *
 * Flags:
 *   --voice-lint-sweep      For every entity with _lint hits, emit a
 *                           change_request note proposing a clean copy
 *                           edit (em-dash → hyphen, "Professional X" →
 *                           "Annual X", trim long answer labels).
 *   --zero-completion-cuts  (Stub — needs real-data RPC integration.)
 *                           Will propose cut for templates with 0%
 *                           completion across ≥10 households.
 *   --dry-run               Print proposals, don't insert. Default true
 *                           when no flag is passed.
 *
 * Usage:
 *   node scripts/run_curation_pass.mjs --voice-lint-sweep
 *   node scripts/run_curation_pass.mjs --voice-lint-sweep --dry-run=false
 *
 * Env (same as sync script):
 *   SUPABASE_SERVICE_ROLE_KEY  — preferred
 *   CHEZ_ADMIN_PASSWORD        — fallback
 */

import { readFile } from "node:fs/promises";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(__dirname, "..");

const supabaseUrl = process.env.SUPABASE_URL || "https://jsucwnkntdrxhysojgri.supabase.co";
const anonKey =
  process.env.SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

const argv = process.argv.slice(2);
const flags = {
  voiceLintSweep: argv.includes("--voice-lint-sweep"),
  zeroCompletionCuts: argv.includes("--zero-completion-cuts"),
  dryRun: !argv.some((a) => a === "--dry-run=false") && !argv.some((a) => a === "--apply"),
};

if (!flags.voiceLintSweep && !flags.zeroCompletionCuts) {
  console.error(
    "Usage: run_curation_pass.mjs [--voice-lint-sweep] [--zero-completion-cuts] [--dry-run=false | --apply]"
  );
  process.exit(1);
}

// -----------------------------------------------------------------------------

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
  return { apikey: anonKey, authorization: `Bearer ${json.access_token}` };
}

async function readJSON(name) {
  const path = resolve(REPO, "website/admin-data", name);
  return JSON.parse(await readFile(path, "utf8"));
}

// -----------------------------------------------------------------------------
// Voice-lint sweep — auto-fix proposals
// -----------------------------------------------------------------------------

function fixCopy(value, ruleId) {
  if (typeof value !== "string") return value;
  if (ruleId === "no-em-dash") {
    // Em-dash → " — " spaced en-dash isn't right either; HNW voice uses
    // hyphen/comma. Replace " — " with ", " and "—" with " - ".
    return value.replace(/\s—\s/g, ", ").replace(/—/g, "-");
  }
  if (ruleId === "no-professional-x-titles") {
    return value.replace(/^Professional /, "Annual ");
  }
  return value;
}

function buildVoiceProposalsForEntity(entry, scopeType, idResolver) {
  const proposals = [];
  const lints = entry._lint || [];
  if (!lints.length) return proposals;

  for (const lint of lints) {
    const path = lint.field; // e.g. "title", "answerOption.label", "description"
    const ruleId = lint.ruleId;
    const fixField = path.split(".").shift(); // for nested fields, propose at the top level
    const before = entry[fixField];
    if (!before) continue;
    let after;
    if (Array.isArray(before)) {
      // answerOption.label etc. — apply fix to each item's nested key
      const innerKey = path.split(".")[1];
      if (!innerKey) continue;
      after = before.map((it) =>
        typeof it === "object" && it ? { ...it, [innerKey]: fixCopy(it[innerKey], ruleId) } : it
      );
    } else {
      after = fixCopy(before, ruleId);
    }
    if (JSON.stringify(before) === JSON.stringify(after)) continue;

    proposals.push({
      scope_type: scopeType,
      scope_id: idResolver(entry),
      scope_title: entry.title || entry.id || idResolver(entry),
      body:
        `Auto-proposed by run_curation_pass --voice-lint-sweep. Lint rule: ${ruleId} — ${lint.message}.\n\n` +
        `Before: ${trimSnippet(JSON.stringify(before))}\n` +
        `After:  ${trimSnippet(JSON.stringify(after))}`,
      intent: "change_request",
      target: "claude",
      author: "claude",
      proposed_diff: { [fixField]: { from: before, to: after, lint_rule: ruleId } },
      snapshot: { source: "voice_lint_sweep", lint, payload: entry },
    });
  }

  return proposals;
}

function trimSnippet(s) {
  return s.length > 220 ? s.slice(0, 217) + "..." : s;
}

// -----------------------------------------------------------------------------

async function main() {
  console.log(`[curation] dry-run=${flags.dryRun}`);
  const proposals = [];

  if (flags.voiceLintSweep) {
    const quiz = await readJSON("quiz-questions.json");
    const templates = await readJSON("templates.json");
    const systems = await readJSON("system-categories.json");

    for (const q of quiz.entries || []) {
      proposals.push(...buildVoiceProposalsForEntity(q, "question", (e) => e.id));
    }
    for (const t of templates.entries || []) {
      proposals.push(...buildVoiceProposalsForEntity(t, "task", (e) => e.templateKey));
    }
    for (const s of systems.entries || []) {
      proposals.push(...buildVoiceProposalsForEntity(s, "system", (e) => e.categoryKey));
    }

    console.log(`[curation] voice-lint-sweep: ${proposals.length} proposal(s)`);
  }

  if (flags.zeroCompletionCuts) {
    console.log(
      "[curation] zero-completion-cuts is a stub — needs real-data RPC integration. Skipping."
    );
  }

  if (flags.dryRun) {
    console.log("\n--- DRY RUN ---\n");
    for (const p of proposals.slice(0, 10)) {
      console.log(`* ${p.scope_type}/${p.scope_id}: ${p.body.split("\n")[0]}`);
    }
    if (proposals.length > 10) console.log(`  ...and ${proposals.length - 10} more.`);
    console.log(`\nRe-run with --apply to insert ${proposals.length} note(s).`);
    return;
  }

  if (!proposals.length) {
    console.log("[curation] no proposals to apply — admin data is clean.");
    return;
  }

  const headers = await authHeaders();
  // Insert in chunks to avoid huge requests
  const chunkSize = 25;
  let inserted = 0;
  for (let i = 0; i < proposals.length; i += chunkSize) {
    const chunk = proposals.slice(i, i + chunkSize);
    const r = await fetch(`${supabaseUrl}/rest/v1/admin_codex_notes`, {
      method: "POST",
      headers: { ...headers, "content-type": "application/json", prefer: "return=minimal" },
      body: JSON.stringify(chunk),
    });
    if (!r.ok) {
      console.warn(`[curation] insert chunk ${i / chunkSize} failed: ${r.status} ${await r.text()}`);
      continue;
    }
    inserted += chunk.length;
    process.stdout.write(`.`);
  }
  console.log(`\n[curation] inserted ${inserted}/${proposals.length} proposal(s).`);
}

main().catch((err) => {
  console.error("[curation] failed:", err.message);
  process.exit(1);
});
