#!/usr/bin/env node

import { writeFile } from "node:fs/promises";
import { resolve } from "node:path";

const supabaseUrl = process.env.SUPABASE_URL || "https://jsucwnkntdrxhysojgri.supabase.co";
const anonKey =
  process.env.SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";
const outputPath = resolve(process.cwd(), process.env.ADMIN_NOTES_PATH || "CODEX_ADMIN_NOTES.md");

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
      "Set SUPABASE_SERVICE_ROLE_KEY or CHEZ_ADMIN_PASSWORD to sync private admin notes."
    );
  }

  const response = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: {
      apikey: anonKey,
      "content-type": "application/json",
    },
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
  const response = await fetch(
    `${supabaseUrl}/rest/v1/admin_codex_notes?select=*&order=created_at.desc&limit=1000`,
    { headers }
  );
  if (!response.ok) {
    throw new Error(`Note fetch failed: ${response.status} ${await response.text()}`);
  }
  return response.json();
}

function markdownFor(notes) {
  const lines = [
    "# Codex Admin Notes",
    "",
    "This file is generated from `admin_codex_notes` so Codex can read the running product-work log.",
    "",
    `Synced: ${new Date().toISOString()}`,
    `Notes: ${notes.length}`,
    "",
  ];

  for (const note of notes) {
    lines.push(`## ${note.scope_title || "General admin note"}`);
    lines.push("");
    lines.push(`- Created: ${note.created_at || ""}`);
    lines.push(`- Type: ${note.scope_type || "general"}`);
    if (note.scope_id) lines.push(`- ID: ${note.scope_id}`);
    lines.push("");
    lines.push(note.body || "");
    lines.push("");
    lines.push("```json");
    lines.push(JSON.stringify(note.snapshot || {}, null, 2));
    lines.push("```");
    lines.push("");
  }

  return `${lines.join("\n").trim()}\n`;
}

const notes = await fetchNotes();
await writeFile(outputPath, markdownFor(notes), "utf8");
console.log(`[admin-notes] synced ${notes.length} notes to ${outputPath}`);
