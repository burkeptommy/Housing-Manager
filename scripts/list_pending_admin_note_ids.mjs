#!/usr/bin/env node
// One-shot helper: lists pending Claude notes as TSV (id<TAB>intent<TAB>body_first_line<TAB>scope_title)
// for downstream scripting. Same auth pattern as sync_claude_admin_notes.mjs.

const supabaseUrl = process.env.SUPABASE_URL || "https://jsucwnkntdrxhysojgri.supabase.co";
const anonKey = process.env.SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

const PROPOSAL = new Set(["change_request", "proposal_add", "proposal_delete"]);

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
url.searchParams.set("select", "id,intent,scope_type,scope_title,body,created_at,applied_at");
url.searchParams.set("or", "(target.eq.claude,target.eq.both)");
url.searchParams.set("order", "created_at.desc");
url.searchParams.set("limit", "2000");
const r = await fetch(url, { headers });
if (!r.ok) throw new Error(`Fetch: ${r.status} ${await r.text()}`);
const rows = await r.json();
const pending = rows.filter((n) => !n.applied_at && PROPOSAL.has(n.intent || "feedback"));

for (const n of pending) {
  const firstLine = (n.body || "").split("\n").find((l) => l.trim()) || "";
  process.stdout.write(`${n.id}\t${n.intent}\t${n.scope_type}\t${n.scope_title}\t${firstLine.slice(0, 100)}\n`);
}
