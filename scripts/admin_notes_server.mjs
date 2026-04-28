#!/usr/bin/env node

import http from "node:http";
import { appendFile } from "node:fs/promises";
import { resolve } from "node:path";

const port = Number(process.env.ADMIN_NOTES_PORT || 8787);
const notesPath = resolve(process.cwd(), "CODEX_ADMIN_NOTES.md");

function cors(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "content-type");
}

function readBody(req) {
  return new Promise((resolveBody, reject) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1_000_000) {
        reject(new Error("Body too large"));
        req.destroy();
      }
    });
    req.on("end", () => resolveBody(body));
    req.on("error", reject);
  });
}

function noteMarkdown(note) {
  const title = note.scopeTitle || "General admin note";
  const lines = [
    "",
    `## ${title}`,
    "",
    `- Created: ${note.createdAt || new Date().toISOString()}`,
    `- Type: ${note.scopeType || "general"}`,
  ];
  if (note.scopeId) lines.push(`- ID: ${note.scopeId}`);
  lines.push("");
  lines.push(note.body || "");
  lines.push("");
  lines.push("```json");
  lines.push(JSON.stringify(note.snapshot || {}, null, 2));
  lines.push("```");
  lines.push("");
  return lines.join("\n");
}

const server = http.createServer(async (req, res) => {
  cors(res);
  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method !== "POST" || req.url !== "/admin-note") {
    res.writeHead(404, { "content-type": "application/json" });
    res.end(JSON.stringify({ error: "Not found" }));
    return;
  }

  try {
    const body = await readBody(req);
    const note = JSON.parse(body || "{}");
    await appendFile(notesPath, noteMarkdown(note), "utf8");
    res.writeHead(200, { "content-type": "application/json" });
    res.end(JSON.stringify({ ok: true, path: notesPath }));
  } catch (error) {
    res.writeHead(500, { "content-type": "application/json" });
    res.end(JSON.stringify({ error: error.message || String(error) }));
  }
});

server.listen(port, () => {
  console.log(`[admin-notes] appending to ${notesPath}`);
  console.log(`[admin-notes] listening on http://localhost:${port}/admin-note`);
});
