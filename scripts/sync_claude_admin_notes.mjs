#!/usr/bin/env node
/**
 * Pulls notes from `admin_codex_notes` where target IN ('claude', 'both')
 * and writes a Claude-readable digest to CLAUDE_ADMIN_NOTES.md at repo root.
 *
 * Sister to scripts/sync_admin_notes.mjs (which targets Codex). Both read
 * the same Supabase table; the `target` column discriminates which file
 * each note belongs to.
 *
 * Usage:
 *   node scripts/sync_claude_admin_notes.mjs
 *
 * Env:
 *   SUPABASE_SERVICE_ROLE_KEY  — preferred; bypasses RLS
 *   CHEZ_ADMIN_PASSWORD        — fallback; signs in as tom@getchez.com
 *   CHEZ_ADMIN_EMAIL           — defaults to tom@getchez.com
 *   ADMIN_NOTES_PATH           — output file (default: ./CLAUDE_ADMIN_NOTES.md)
 *   ADMIN_NOTES_ARCHIVE_PATH   — archive file (default: ./CLAUDE_ADMIN_NOTES_ARCHIVE.md)
 *   ARCHIVE_DAYS               — applied-note retention threshold (default: 30)
 */

import { writeFile } from "node:fs/promises";
import { resolve } from "node:path";

const supabaseUrl = process.env.SUPABASE_URL || "https://jsucwnkntdrxhysojgri.supabase.co";
const anonKey =
  process.env.SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

const outputPath = resolve(process.cwd(), process.env.ADMIN_NOTES_PATH || "CLAUDE_ADMIN_NOTES.md");
const archivePath = resolve(
  process.cwd(),
  process.env.ADMIN_NOTES_ARCHIVE_PATH || "CLAUDE_ADMIN_NOTES_ARCHIVE.md"
);
const archiveDays = Number(process.env.ARCHIVE_DAYS || 30);

const ENTITY_GROUPS = [
  { type: "question", label: "Quiz Questions", emoji: "❓" },
  { type: "task", label: "Maintenance Templates", emoji: "🛠" },
  { type: "handyman", label: "Handyman Templates", emoji: "🔨" },
  { type: "routine", label: "Routine Kinds", emoji: "🔁" },
  { type: "system", label: "System Categories", emoji: "🏠" },
  { type: "vehicle", label: "Vehicle Task Generation", emoji: "🚗" },
  { type: "prompt", label: "Edge Function Prompts", emoji: "🧠" },
  { type: "general", label: "General Notes", emoji: "📝" },
];

const PROPOSAL_INTENTS = new Set(["change_request", "proposal_add", "proposal_delete"]);
const QUESTION_INTENTS = new Set(["question_for_claude"]);

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
    throw new Error(
      "Set SUPABASE_SERVICE_ROLE_KEY or CHEZ_ADMIN_PASSWORD to sync Claude admin notes."
    );
  }

  const response = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: { apikey: anonKey, "content-type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  if (!response.ok) {
    throw new Error(`Admin sign-in failed: ${response.status} ${await response.text()}`);
  }
  const json = await response.json();
  return {
    apikey: anonKey,
    authorization: `Bearer ${json.access_token}`,
  };
}

async function fetchNotes() {
  const headers = await authHeaders();
  const url = new URL(`${supabaseUrl}/rest/v1/admin_codex_notes`);
  url.searchParams.set("select", "*");
  // Use OR filter for target; Supabase REST `or` syntax: or=(target.eq.claude,target.eq.both)
  url.searchParams.set("or", "(target.eq.claude,target.eq.both)");
  url.searchParams.set("order", "created_at.desc");
  url.searchParams.set("limit", "2000");
  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`Note fetch failed: ${response.status} ${await response.text()}`);
  }
  return response.json();
}

function groupByEntity(notes) {
  const buckets = new Map();
  for (const note of notes) {
    const type = note.scope_type || "general";
    const id = note.scope_id || note.scope_title || "(unscoped)";
    const key = `${type}::${id}`;
    if (!buckets.has(key)) {
      buckets.set(key, {
        scopeType: type,
        scopeId: note.scope_id,
        scopeTitle: note.scope_title || "Unnamed",
        notes: [],
      });
    }
    buckets.get(key).notes.push(note);
  }
  return [...buckets.values()];
}

function nestThreads(notes) {
  // Returns top-level notes with `replies` arrays.
  const byId = new Map(notes.map((n) => [n.id, { ...n, replies: [] }]));
  const top = [];
  for (const note of notes) {
    const wrapped = byId.get(note.id);
    if (note.parent_note_id && byId.has(note.parent_note_id)) {
      byId.get(note.parent_note_id).replies.push(wrapped);
    } else {
      top.push(wrapped);
    }
  }
  // Sort top-level newest first; replies oldest first within a thread.
  top.sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at));
  for (const t of top) {
    t.replies.sort((a, b) => +new Date(a.created_at) - +new Date(b.created_at));
  }
  return top;
}

function formatNote(note, depth = 0) {
  const indent = depth > 0 ? "> " : "";
  const lines = [];
  const intentLabel = note.intent || "feedback";
  const author = note.author || "tom";
  const ts = note.created_at ? note.created_at.split("T")[0] : "?";
  const headerBits = [`${ts}`, intentLabel, author];
  if (note.applied_at) {
    headerBits.push(`applied ${note.applied_at.split("T")[0]}`);
    if (note.applied_commit) headerBits.push(`commit ${note.applied_commit.slice(0, 7)}`);
  }
  if (note.reverted_at) headerBits.push(`reverted ${note.reverted_at.split("T")[0]}`);
  if (note.superseded_by_note_id) headerBits.push(`superseded`);

  lines.push(`${indent}**${headerBits.join(" · ")}**`);
  if (note.body) {
    for (const bodyLine of note.body.split("\n")) {
      lines.push(`${indent}${bodyLine}`);
    }
  }
  if (note.proposed_diff) {
    lines.push(`${indent}`);
    lines.push(`${indent}**Proposed diff:**`);
    lines.push(`${indent}\`\`\`json`);
    const diffStr = JSON.stringify(note.proposed_diff, null, 2);
    for (const line of diffStr.split("\n")) lines.push(`${indent}${line}`);
    lines.push(`${indent}\`\`\``);
  }
  if (Array.isArray(note.attachment_urls) && note.attachment_urls.length > 0) {
    for (const url of note.attachment_urls) {
      lines.push(`${indent}![attachment](${url})`);
    }
  }
  if (note.replies?.length) {
    for (const reply of note.replies) {
      lines.push("");
      lines.push(...formatNote(reply, depth + 1).split("\n"));
    }
  }
  return lines.join("\n");
}

function formatEntityHeader(group) {
  const meta = group.notes[0]?.snapshot?.payload || {};
  const bits = [];
  if (group.scopeType === "question") {
    bits.push(`**Section** ${meta.section || "?"} · **Chapter** ${meta.chapter || "?"} · **Kind** ${meta.kind || "?"}`);
    if (meta.subtitle) bits.push(`**Subtitle** ${meta.subtitle}`);
    const opts = (meta.answerOptions || []).map((o) => o.label).join(", ");
    if (opts) bits.push(`**Options** ${opts}`);
  } else if (group.scopeType === "task" || group.scopeType === "handyman") {
    bits.push(
      `**Category** ${meta.systemCategory || "?"} · **Frequency** ${meta.frequency || "?"} · **Priority** ${
        meta.priority || "?"
      } · **Cost** ${meta.estimatedCostRange || "?"}`
    );
    bits.push(
      `**Assignment** ${meta.assignmentType || "?"} · **Routing** ${meta.routing || "?"} · **Safety floor** ${
        meta.safetyFloor || false
      } · **Essential** ${meta.isEssential ?? "?"}`
    );
    if (meta.bundleId) bits.push(`**Bundle** ${meta.bundleId}${meta.bundleTitle ? ` — ${meta.bundleTitle}` : ""}`);
    if (meta.requiredSubtypes?.length) bits.push(`**Subtypes** ${meta.requiredSubtypes.join(", ")}`);
  } else if (group.scopeType === "system") {
    bits.push(
      `**Tier** ${meta.tier || "?"} · **Priority** ${meta.displayPriority ?? "?"} · **Cadence** ${
        meta.defaultCadence || "?"
      } · **Icon** ${meta.icon || "?"}`
    );
  } else if (group.scopeType === "routine") {
    bits.push(`**Vendor-based** ${meta.isVendorBased ?? "?"} · **Icon** ${meta.icon || "?"}`);
    if (meta.seederDefault) {
      bits.push(`**Seeder** cadence=${meta.seederDefault.cadenceType || "?"}, months=${(meta.seederDefault.activeMonths || []).join(",") || "year-round"}`);
    }
  } else if (group.scopeType === "prompt") {
    bits.push(`**Model** ${meta.model || "?"} · **Source** ${meta.sourceFile || "?"}`);
  }
  return bits.join("  \n");
}

function buildMarkdown(notes) {
  const cutoff = Date.now() - archiveDays * 86400 * 1000;

  // Split notes
  const liveNotes = notes.filter((n) => {
    if (!n.applied_at) return true;
    return new Date(n.applied_at).getTime() >= cutoff;
  });
  const archived = notes.filter((n) => {
    if (!n.applied_at) return false;
    return new Date(n.applied_at).getTime() < cutoff;
  });

  // Pending changes (all unapplied notes with a proposal intent)
  const pending = liveNotes.filter(
    (n) => !n.applied_at && !n.reverted_at && PROPOSAL_INTENTS.has(n.intent || "feedback")
  );
  // Questions for Claude (priority — answer first)
  const questions = liveNotes.filter(
    (n) => !n.applied_at && QUESTION_INTENTS.has(n.intent || "feedback")
  );
  // Open feedback / bugs / ideas
  const feedback = liveNotes.filter(
    (n) =>
      !n.applied_at &&
      !n.reverted_at &&
      !PROPOSAL_INTENTS.has(n.intent || "feedback") &&
      !QUESTION_INTENTS.has(n.intent || "feedback")
  );
  // Recently applied (within retention window) — for context, not action
  const applied = liveNotes.filter((n) => n.applied_at && !n.reverted_at);

  const lines = [];
  lines.push("# Claude Admin Notes");
  lines.push("");
  lines.push(
    `Generated from \`admin_codex_notes\` where target IN ('claude','both'). When a new Claude session opens, scan this file before doing anything else.`
  );
  lines.push("");
  lines.push(`**Synced:** ${new Date().toISOString()}`);
  lines.push(
    `**Pending:** ${pending.length} change request${pending.length === 1 ? "" : "s"} · **Open questions:** ${questions.length} · **Feedback:** ${feedback.length} · **Applied (last ${archiveDays}d):** ${applied.length}`
  );
  lines.push("");
  lines.push(
    "Reading order: 1. Questions for Claude. 2. Pending Changes. 3. Open Feedback (by entity). 4. Recently Applied (audit)."
  );
  lines.push("");

  // ----- Section 1: Questions for Claude -----
  if (questions.length) {
    lines.push("---");
    lines.push("");
    lines.push("## ❓ Questions for Claude (answer first)");
    lines.push("");
    const threaded = nestThreads(questions);
    for (const note of threaded) {
      lines.push(`### ${note.scope_title || "(unscoped question)"}  \\[${note.scope_type || "general"}\\]`);
      lines.push("");
      lines.push(formatNote(note));
      lines.push("");
    }
  }

  // ----- Section 2: Pending Changes -----
  if (pending.length) {
    lines.push("---");
    lines.push("");
    lines.push("## ⚡ Pending Changes (act on these)");
    lines.push("");
    const threaded = nestThreads(pending);
    for (const note of threaded) {
      lines.push(`### ${note.scope_title || "(unscoped)"}  \\[${note.intent}\\]`);
      lines.push("");
      lines.push(formatNote(note));
      lines.push("");
    }
  }

  // ----- Section 3: Open Feedback grouped by entity -----
  if (feedback.length) {
    lines.push("---");
    lines.push("");
    lines.push("## 📋 Open Feedback (by entity)");
    lines.push("");
    const groups = groupByEntity(feedback);
    // Sort groups by ENTITY_GROUPS ordering
    groups.sort((a, b) => {
      const ai = ENTITY_GROUPS.findIndex((g) => g.type === a.scopeType);
      const bi = ENTITY_GROUPS.findIndex((g) => g.type === b.scopeType);
      const ax = ai < 0 ? 999 : ai;
      const bx = bi < 0 ? 999 : bi;
      if (ax !== bx) return ax - bx;
      return (a.scopeTitle || "").localeCompare(b.scopeTitle || "");
    });

    let lastType = null;
    for (const group of groups) {
      const meta = ENTITY_GROUPS.find((g) => g.type === group.scopeType) || {
        emoji: "📌",
        label: group.scopeType,
      };
      if (group.scopeType !== lastType) {
        lines.push(`### ${meta.emoji} ${meta.label}`);
        lines.push("");
        lastType = group.scopeType;
      }
      lines.push(`#### ${group.scopeTitle}${group.scopeId ? `  \`${group.scopeId}\`` : ""}`);
      const headerInfo = formatEntityHeader(group);
      if (headerInfo) {
        lines.push("");
        lines.push(headerInfo);
      }
      lines.push("");
      const threaded = nestThreads(group.notes);
      for (const note of threaded) {
        lines.push(formatNote(note));
        lines.push("");
      }
    }
  }

  // ----- Section 4: Recently Applied (audit log) -----
  if (applied.length) {
    lines.push("---");
    lines.push("");
    lines.push(`## ✅ Recently Applied (last ${archiveDays} days)`);
    lines.push("");
    lines.push("These have already shipped. Review for retroactive QA only.");
    lines.push("");
    const groups = groupByEntity(applied);
    for (const group of groups) {
      lines.push(`### ${group.scopeTitle}${group.scopeId ? `  \`${group.scopeId}\`` : ""}`);
      lines.push("");
      const threaded = nestThreads(group.notes);
      for (const note of threaded) {
        lines.push(formatNote(note));
        lines.push("");
      }
    }
  }

  if (!questions.length && !pending.length && !feedback.length && !applied.length) {
    lines.push("---");
    lines.push("");
    lines.push("_No notes yet. Take some via the admin and re-run this sync._");
    lines.push("");
  }

  return [lines.join("\n").trim(), "\n"].join("");
}

function buildArchiveMarkdown(notes) {
  const lines = [
    "# Claude Admin Notes — Archive",
    "",
    `Notes applied more than ${archiveDays} days ago. Read-only audit trail.`,
    "",
    `**Synced:** ${new Date().toISOString()}  `,
    `**Archived notes:** ${notes.length}`,
    "",
  ];
  if (!notes.length) {
    lines.push("_(No archived notes yet.)_");
    lines.push("");
    return lines.join("\n");
  }

  const groups = groupByEntity(notes);
  for (const group of groups) {
    lines.push(`## ${group.scopeTitle || "(unscoped)"}  \`${group.scopeType}/${group.scopeId || "?"}\``);
    lines.push("");
    const threaded = nestThreads(group.notes);
    for (const note of threaded) {
      lines.push(formatNote(note));
      lines.push("");
    }
  }
  return lines.join("\n");
}

async function main() {
  const all = await fetchNotes();
  const cutoff = Date.now() - archiveDays * 86400 * 1000;
  const archived = all.filter((n) => n.applied_at && new Date(n.applied_at).getTime() < cutoff);
  const live = all.filter((n) => !archived.includes(n));

  const md = buildMarkdown(live);
  const archiveMd = buildArchiveMarkdown(archived);

  await writeFile(outputPath, md, "utf8");
  await writeFile(archivePath, archiveMd, "utf8");

  console.log(`[claude-admin-notes] ${all.length} total notes synced`);
  console.log(`  → live: ${live.length}, archived: ${archived.length}`);
  console.log(`  → ${outputPath}`);
  console.log(`  → ${archivePath}`);
}

main().catch((err) => {
  console.error("[claude-admin-notes] failed:", err.message);
  process.exit(1);
});
