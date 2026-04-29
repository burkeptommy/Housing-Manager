#!/usr/bin/env node
/**
 * Claude posts a threaded reply on an existing admin_codex_notes row.
 * Used after applying a proposal to confirm "applied in commit X — anything
 * to revisit?" so Tom sees the answer in-thread next time he opens admin
 * or the synced markdown file.
 *
 * Usage:
 *   node scripts/post_admin_note_reply.mjs <parent_note_id> "<body>" [intent]
 *
 * Example:
 *   node scripts/post_admin_note_reply.mjs c4a1...uuid "Applied in commit abc1234. Updated Q3 fallback title and added 'Asbestos' answer option."
 *
 * Default intent is "feedback". Author is hard-coded to 'claude'.
 *
 * Env (same as sync script):
 *   SUPABASE_SERVICE_ROLE_KEY  — preferred
 *   CHEZ_ADMIN_PASSWORD        — fallback (signs in as tom@getchez.com)
 */

const supabaseUrl = process.env.SUPABASE_URL || "https://jsucwnkntdrxhysojgri.supabase.co";
const anonKey =
  process.env.SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

const [, , parentId, body, intent = "feedback"] = process.argv;

if (!parentId || !body) {
  console.error("Usage: post_admin_note_reply.mjs <parent_note_id> <body> [intent]");
  process.exit(1);
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

async function fetchParent(headers) {
  const url = new URL(`${supabaseUrl}/rest/v1/admin_codex_notes`);
  url.searchParams.set("select", "id,scope_type,scope_id,scope_title,target");
  url.searchParams.set("id", `eq.${parentId}`);
  const r = await fetch(url, { headers });
  if (!r.ok) throw new Error(`Parent fetch failed: ${r.status} ${await r.text()}`);
  const rows = await r.json();
  if (!rows.length) throw new Error(`Parent note ${parentId} not found.`);
  return rows[0];
}

async function postReply() {
  const headers = await authHeaders();
  const parent = await fetchParent(headers);

  const r = await fetch(`${supabaseUrl}/rest/v1/admin_codex_notes`, {
    method: "POST",
    headers: { ...headers, "content-type": "application/json", prefer: "return=representation" },
    body: JSON.stringify({
      scope_type: parent.scope_type,
      scope_id: parent.scope_id,
      scope_title: parent.scope_title,
      body,
      snapshot: { reply_to: parent.id },
      intent,
      target: parent.target || "claude",
      author: "claude",
      parent_note_id: parent.id,
    }),
  });
  if (!r.ok) throw new Error(`Insert failed: ${r.status} ${await r.text()}`);
  const [inserted] = await r.json();
  console.log(`[admin-reply] posted ${inserted.id} as reply to ${parent.id}`);
  console.log(`  on entity: ${parent.scope_type}/${parent.scope_id || "?"} — "${parent.scope_title}"`);
}

postReply().catch((err) => {
  console.error("[admin-reply] failed:", err.message);
  process.exit(1);
});
