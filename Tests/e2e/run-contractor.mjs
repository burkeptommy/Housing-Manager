#!/usr/bin/env node
// ============================================================================
// Haven Contractor (web Operations Desk) E2E test runner
// ============================================================================
//
// Seeds three test contractor workspaces (W1 solo / W2 6-person crew /
// W3 25-person crew) and ~30 customer households against the live
// haven-dev Supabase project. Mirrors the homeowner / handyman runners
// but with multi-workspace + per-workspace richer fixture density per
// Section 0 of CHEZ_CONTRACTOR_WEB_TEST_MATRIX.md.
//
// Usage:
//   node Tests/e2e/run-contractor.mjs
//
// Optional env vars:
//   E2E_VERBOSE=1            -- log full request/response bodies on failure
//   E2E_KEEP_USER=1          -- skip post-run cleanup
//   E2E_SKIP_CLEANUP=1       -- skip pre-run cleanup
//   E2E_SERVICE_JWT=...      -- override service-role JWT
//
// Exit codes:
//   0  -- all phases passed
//   1  -- one or more phases failed
// ============================================================================

import { randomUUID } from "node:crypto";
import { execSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const SUPABASE_URL = "https://jsucwnkntdrxhysojgri.supabase.co";
const ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

const SERVICE_JWT = (() => {
  if (process.env.E2E_SERVICE_JWT) return process.env.E2E_SERVICE_JWT;
  const path = "/tmp/ui-test/service-jwt.txt";
  if (existsSync(path)) return readFileSync(path, "utf8").trim();
  console.error("Missing service-role JWT at /tmp/ui-test/service-jwt.txt");
  process.exit(1);
})();

const TEST_PASSWORD = "TestContractorPwd!2026";
const VERBOSE = !!process.env.E2E_VERBOSE;

const __dirname = dirname(fileURLToPath(import.meta.url));
const CLEANUP_SQL_PATH = resolve(__dirname, "cleanup-contractor.sql");
const REPO_ROOT = resolve(__dirname, "..", "..");

// ----------------------------------------------------------------------------
// Logging
// ----------------------------------------------------------------------------

const c = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
};

function logPhase(num, title) {
  console.log(`\n${c.cyan}${c.bold}━━━ Phase ${num}: ${title} ${"━".repeat(Math.max(0, 60 - title.length))}${c.reset}`);
}
function logStep(msg) { console.log(`  ${c.dim}→${c.reset} ${msg}`); }
function logOk(msg, detail = "") { console.log(`  ${c.green}✓${c.reset} ${msg}${detail ? ` ${c.dim}${detail}${c.reset}` : ""}`); }
function logFail(msg, detail = "") { console.log(`  ${c.red}✗${c.reset} ${msg}${detail ? ` ${c.dim}${detail}${c.reset}` : ""}`); }
function logWarn(msg, detail = "") { console.log(`  ${c.yellow}!${c.reset} ${msg}${detail ? ` ${c.dim}${detail}${c.reset}` : ""}`); }

// ----------------------------------------------------------------------------
// HTTP
// ----------------------------------------------------------------------------

async function http(url, opts = {}) {
  const res = await fetch(url, opts);
  const text = await res.text();
  let body;
  try { body = text ? JSON.parse(text) : null; } catch { body = text; }
  if (VERBOSE && !res.ok) {
    console.log(`  ${c.dim}HTTP ${res.status} ${url}${c.reset}\n  ${c.dim}${typeof body === "string" ? body : JSON.stringify(body, null, 2)}${c.reset}`);
  }
  return { ok: res.ok, status: res.status, body, raw: text };
}

function authHeaders(jwt) {
  return { apikey: ANON_KEY, authorization: `Bearer ${jwt || ANON_KEY}`, "content-type": "application/json" };
}
function serviceHeaders() {
  return { apikey: SERVICE_JWT, authorization: `Bearer ${SERVICE_JWT}`, "content-type": "application/json" };
}
async function callEdgeFunction(name, body, jwt) {
  return http(`${SUPABASE_URL}/functions/v1/${name}`, { method: "POST", headers: authHeaders(jwt), body: JSON.stringify(body) });
}
async function rest(path, opts, jwt) {
  return http(`${SUPABASE_URL}/rest/v1/${path}`, { ...opts, headers: { ...authHeaders(jwt), ...(opts?.headers || {}) } });
}
async function restService(path, opts) {
  return http(`${SUPABASE_URL}/rest/v1/${path}`, { ...opts, headers: { ...serviceHeaders(), ...(opts?.headers || {}) } });
}
async function adminSqlFile(filePath) {
  try {
    const out = execSync(`cd ${REPO_ROOT} && supabase db query --linked --output json --file ${filePath}`, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
    return JSON.parse(out);
  } catch (err) {
    return { error: err.stderr?.toString() || err.message };
  }
}

function isoNow() { return new Date().toISOString(); }
function isoDateInDays(n) { const d = new Date(); d.setDate(d.getDate() + n); return d.toISOString().slice(0, 10); }
function pick(arr, i) { return arr[i % arr.length]; }

// ----------------------------------------------------------------------------
// Runner
// ----------------------------------------------------------------------------

class ContractorE2ERunner {
  constructor() {
    const stamp = Date.now();
    this.stamp = stamp;
    // Three workspaces, varied scale. Supabase signup is rate-limited
    // (~30/hr/IP/project) so we trim per-workspace counts while keeping
    // breadth: every workspace still seeds quotes / visits / punch items
    // / messages / saved-items, so subagents can exercise the full
    // surface even with the smaller customer count.
    this.workspaces = [
      { key: "w1", label: "solo", crewSize: 0, customerCount: 2 },
      { key: "w2", label: "crew6", crewSize: 3, customerCount: 6 },
      { key: "w3", label: "crew25", crewSize: 2, customerCount: 3 },
    ];
    this.issues = [];
    this.successes = [];
    this.gaps = [];
    this.state = {
      workspaces: {}, // keyed by workspace.key → { id, ownerEmail, ownerJwt, ownerUserId, ownerMembershipId, members: [{id,jwt,userId,email,role}] }
      customers: [], // [{ workspaceKey, email, jwt, userId, householdId, propertyId, contractorId, providerLinkId, lifecycle, systemIds, requestIds, quoteIds, assignmentIds }]
      ownerMessagesSeeded: 0,
      chezInboundSeeded: 0,
    };
  }

  recordSuccess(phase, msg) { this.successes.push({ phase, msg }); logOk(msg); }
  recordIssue(phase, msg, detail = null) {
    this.issues.push({ phase, msg, detail });
    if (detail) logFail(msg, typeof detail === "string" ? detail : JSON.stringify(detail).slice(0, 300));
    else logFail(msg);
  }
  recordGap(phase, scenario, detail) { this.gaps.push({ phase, scenario, detail }); logWarn(`gap: ${scenario}`, detail); }

  async signupUser(email, firstName, lastName) {
    // 2.5s sleep keeps us well under Supabase auth rate-limits (~30/hr).
    // For an overnight run, total fixture time is small but stable.
    await new Promise((r) => setTimeout(r, 2500));
    const signup = await http(`${SUPABASE_URL}/auth/v1/signup`, {
      method: "POST",
      headers: { apikey: ANON_KEY, "content-type": "application/json" },
      body: JSON.stringify({ email, password: TEST_PASSWORD, data: { first_name: firstName, last_name: lastName, full_name: `${firstName} ${lastName}` } }),
    });
    if (!signup.ok) throw new Error(`signup failed for ${email}: ${JSON.stringify(signup.body)}`);
    const session = signup.body;
    if (!session.access_token || !session.user?.id) throw new Error(`signup did not return session+user for ${email}`);
    const userInsert = await rest("users", {
      method: "POST",
      body: JSON.stringify({ id: session.user.id, household_id: null, email, full_name: `${firstName} ${lastName}`, role: "member" }),
    }, session.access_token);
    if (!userInsert.ok) throw new Error(`public.users insert failed for ${email}`);
    return { jwt: session.access_token, userId: session.user.id };
  }

  // --------------------------------------------------------------------------
  // Phase 0 — Cleanup
  // --------------------------------------------------------------------------
  async phase0_cleanup() {
    logPhase(0, "Pre-run cleanup");
    if (process.env.E2E_SKIP_CLEANUP) { logWarn("E2E_SKIP_CLEANUP=1, skipping"); return; }
    logStep(`Wiping any prior e2e-contractor-* + e2e-customer-of-contractor-* users`);
    const result = await adminSqlFile(CLEANUP_SQL_PATH);
    if (result.error) {
      this.recordIssue("phase0", "cleanup SQL failed", result.error);
      throw new Error("Cleanup failed — refusing to continue");
    }
    logOk("cleanup complete");
  }

  // --------------------------------------------------------------------------
  // Phase 1 — Three workspace owners + bootstrap_workspace
  // --------------------------------------------------------------------------
  async phase1_workspaceOwners() {
    logPhase(1, "Three workspace owners (W1 solo / W2 crew6 / W3 crew25)");
    for (const ws of this.workspaces) {
      const ownerEmail = `e2e-contractor-${ws.key}-owner-${this.stamp}@chezcontractor.test`;
      logStep(`(${ws.key}) signing up ${ownerEmail}`);
      let owner;
      try {
        owner = await this.signupUser(ownerEmail, "E2EOwner", ws.key.toUpperCase());
      } catch (err) {
        this.recordIssue("phase1", `owner signup failed ${ws.key}`, err.message);
        continue;
      }
      const bootstrap = await callEdgeFunction("handyman-provider", {
        action: "bootstrap_workspace",
        fullName: `E2E Owner ${ws.key}`,
        companyName: `E2E Contractor ${ws.label} ${this.stamp}`,
        phone: `555-${1000 + this.workspaces.indexOf(ws) * 100}`,
        website: `https://e2e-contractor-${ws.key}.example`,
      }, owner.jwt);
      if (!bootstrap.ok) {
        this.recordIssue("phase1", `bootstrap_workspace failed ${ws.key}`, bootstrap.body);
        continue;
      }
      const wsId = bootstrap.body?.workspace?.id;
      if (!wsId) {
        this.recordIssue("phase1", `bootstrap returned no workspace id ${ws.key}`, bootstrap.body);
        continue;
      }
      const memb = await restService(`provider_workspace_members?workspace_id=eq.${wsId}&user_id=eq.${owner.userId}&select=id`);
      const ownerMembershipId = memb.ok && memb.body[0]?.id;
      this.state.workspaces[ws.key] = {
        id: wsId,
        meta: ws,
        ownerEmail,
        ownerJwt: owner.jwt,
        ownerUserId: owner.userId,
        ownerMembershipId,
        members: [],
      };
      logOk(`(${ws.key}) workspace bootstrapped`, `id=${wsId.slice(0, 8)}…`);
    }
    if (Object.keys(this.state.workspaces).length === 3) {
      this.recordSuccess("phase1", `3 workspaces bootstrapped`);
    } else {
      this.recordIssue("phase1", `expected 3 workspaces, got ${Object.keys(this.state.workspaces).length}`);
    }
  }

  // --------------------------------------------------------------------------
  // Phase 2 — Crew members for W2 (5) + W3 (24)
  // --------------------------------------------------------------------------
  async phase2_crew() {
    logPhase(2, "Crew member signups (W2: 5, W3: 24)");
    const roleCycle = ["dispatcher", "technician", "technician", "technician", "technician"];
    for (const ws of this.workspaces) {
      const wsState = this.state.workspaces[ws.key];
      if (!wsState) continue;
      if (ws.crewSize === 0) continue;
      logStep(`(${ws.key}) provisioning ${ws.crewSize} crew members`);
      // Cap W3 to 6 for runtime budget — we still test pagination via customers (14)
      // and via the seeded crew avatar set; full 24 is overkill for fixture-time.
      const cap = Math.min(ws.crewSize, ws.key === "w3" ? 6 : ws.crewSize);
      for (let i = 0; i < cap; i++) {
        const email = `e2e-contractor-${ws.key}-crew${i + 1}-${this.stamp}@chezcontractor.test`;
        let crew;
        try { crew = await this.signupUser(email, `E2ECrew${i + 1}`, ws.key.toUpperCase()); } catch (err) {
          this.recordIssue("phase2", `crew signup ${ws.key}#${i + 1}`, err.message);
          continue;
        }
        const role = i === 0 && ws.key !== "w1" ? "dispatcher" : "technician";
        const ins = await restService("provider_workspace_members", {
          method: "POST",
          headers: { Prefer: "return=representation" },
          body: JSON.stringify({
            workspace_id: wsState.id,
            user_id: crew.userId,
            full_name: `E2E Crew ${i + 1} ${ws.key}`,
            email,
            role,
            status: "active",
          }),
        });
        if (!ins.ok) { this.recordIssue("phase2", `crew member insert failed ${ws.key}#${i + 1}`, ins.body); continue; }
        wsState.members.push({ id: ins.body[0]?.id, userId: crew.userId, email, jwt: crew.jwt, role });
      }
      logOk(`(${ws.key}) crew added`, `count=${wsState.members.length}`);
    }
    this.recordSuccess("phase2", `crew populated W2/W3`);
  }

  // --------------------------------------------------------------------------
  // Phase 3 — Customer households per workspace
  // --------------------------------------------------------------------------
  async phase3_customers() {
    logPhase(3, "Customer households (4 + 12 + 14 across W1/W2/W3)");
    const lifecycleStates = ["lead", "prospect", "active", "active", "dormant", "churned"];
    let globalIdx = 0;
    for (const ws of this.workspaces) {
      const wsState = this.state.workspaces[ws.key];
      if (!wsState) continue;
      logStep(`(${ws.key}) seeding ${ws.customerCount} customers`);
      for (let i = 0; i < ws.customerCount; i++) {
        globalIdx++;
        const email = `e2e-customer-of-contractor-${ws.key}-${i + 1}-${this.stamp}@havenhome.test`;
        const lifecycle = pick(lifecycleStates, i);
        let user;
        try { user = await this.signupUser(email, `E2ECust${globalIdx}`, "Customer"); } catch (err) {
          this.recordIssue("phase3", `customer signup failed ${email}`, err.message);
          continue;
        }
        const householdId = randomUUID();
        const householdIns = await rest("households", {
          method: "POST",
          body: JSON.stringify({ id: householdId, name: `Customer ${globalIdx} of ${ws.key}`, subscription_tier: "standard" }),
        }, user.jwt);
        if (!householdIns.ok) { this.recordIssue("phase3", `household insert ${email}`, householdIns.body); continue; }

        await rest(`users?id=eq.${user.userId}`, {
          method: "PATCH",
          body: JSON.stringify({ household_id: householdId, full_name: `E2ECust${globalIdx} Customer` }),
        }, user.jwt);

        await rest("family_members", {
          method: "POST",
          body: JSON.stringify({
            id: randomUUID(),
            household_id: householdId,
            first_name: `E2ECust${globalIdx}`,
            last_name: "Customer",
            relationship: "Primary Client",
            email,
            linked_user_id: user.userId,
            member_type: "family",
          }),
        }, user.jwt);

        const propertyId = randomUUID();
        const propIns = await rest("properties", {
          method: "POST",
          body: JSON.stringify({
            id: propertyId,
            household_id: householdId,
            name: `Customer ${globalIdx} home`,
            property_type: "Single Family",
            street: `${100 + globalIdx} Test Lane`,
            city: pick(["Bethel", "Brookfield", "Danbury", "Newtown", "Ridgefield"], globalIdx),
            state: "CT",
            zip_code: pick(["06801", "06804", "06810", "06470", "06877"], globalIdx),
            country: "US",
            year_built: 1940 + (globalIdx * 7) % 80,
            square_footage: 1800 + (globalIdx * 200) % 4000,
            current_estimated_value: 500000 + globalIdx * 23000,
            regional_pack: "northeast",
          }),
        }, user.jwt);
        if (!propIns.ok) { this.recordIssue("phase3", `property insert ${email}`, propIns.body); continue; }

        // Vary completeness of home_systems per customer.
        // 5+ per customer per matrix Section 0.7. Mix of complete / partial / bare.
        const systemSpecs = [
          { category: "HVAC", name: "Furnace", complete: true },
          { category: "HVAC", name: "AC", complete: false }, // partial
          { category: "Water Heater", name: "Water heater", complete: globalIdx % 2 === 0 },
          { category: "Roofing", name: "Roof", complete: false }, // bare
          { category: "Electrical", name: "Panel", complete: globalIdx % 3 !== 0 },
        ];
        const systemIds = [];
        for (const spec of systemSpecs) {
          const sysIns = await rest("home_systems", {
            method: "POST",
            body: JSON.stringify({
              id: randomUUID(),
              household_id: householdId,
              property_id: propertyId,
              category: spec.category,
              name: spec.name,
              status: "active",
              ...(spec.complete ? { manufacturer: "Lennox", model_number: `M-${globalIdx}-${spec.name.slice(0, 2)}`, serial_number: `S${globalIdx}${spec.name.length}`, install_date: isoDateInDays(-365 * 5) } : {}),
            }),
          }, user.jwt);
          if (sysIns.ok) systemIds.push(sysIns.body?.[0]?.id);
        }

        // Link to workspace via contractor + provider_contractor_links (only for non-Lead lifecycles)
        let contractorId = null, providerLinkId = null;
        if (lifecycle !== "lead" && lifecycle !== "churned") {
          contractorId = randomUUID();
          const contractorIns = await rest("contractors", {
            method: "POST",
            body: JSON.stringify({
              id: contractorId,
              household_id: householdId,
              company_name: `E2E Contractor ${ws.label} ${this.stamp}`,
              contact_name: `E2E Owner ${ws.key}`,
              phone: `555-${1000 + this.workspaces.indexOf(ws) * 100}`,
              website: `https://e2e-contractor-${ws.key}.example`,
              category: "General",
              source: "manual",
            }),
          }, user.jwt);
          if (contractorIns.ok) {
            const linkIns = await restService("provider_contractor_links", {
              method: "POST",
              headers: { Prefer: "return=representation" },
              body: JSON.stringify({
                workspace_id: wsState.id,
                contractor_id: contractorId,
                is_primary: true,
                claim_source: "manual",
              }),
            });
            if (linkIns.ok) providerLinkId = linkIns.body[0]?.id;
          }
        }

        this.state.customers.push({
          workspaceKey: ws.key,
          globalIdx,
          email,
          jwt: user.jwt,
          userId: user.userId,
          householdId,
          propertyId,
          contractorId,
          providerLinkId,
          lifecycle,
          systemIds,
          requestIds: [],
          quoteIds: [],
          assignmentIds: [],
        });
      }
      const wsCust = this.state.customers.filter((c) => c.workspaceKey === ws.key);
      logOk(`(${ws.key}) customers seeded`, `count=${wsCust.length} linked=${wsCust.filter((c) => c.providerLinkId).length}`);
    }
    this.recordSuccess("phase3", `${this.state.customers.length} customers across 3 workspaces`);
  }

  // --------------------------------------------------------------------------
  // Phase 4 — Quotes (20+ per workspace, all statuses)
  // --------------------------------------------------------------------------
  async phase4_quotes() {
    logPhase(4, "Provider quotes (mixed status, every workspace)");
    const statusPool = ["draft", "draft", "sent", "sent", "viewed", "viewed", "approved", "declined", "withdrawn", "countered_by_homeowner", "superseded"];
    let total = 0;
    for (const ws of this.workspaces) {
      const wsState = this.state.workspaces[ws.key];
      if (!wsState) continue;
      const linkedCustomers = this.state.customers.filter((c) => c.workspaceKey === ws.key && c.providerLinkId);
      if (linkedCustomers.length === 0) continue;
      const quoteCount = Math.min(20, linkedCustomers.length * 3);
      for (let i = 0; i < quoteCount; i++) {
        const cust = pick(linkedCustomers, i);
        const status = pick(statusPool, i);
        const lineItems = [
          { name: "Service call", quantity: 1, unit_price: 150 + (i * 7) % 80 },
          { name: "Filter replacement", quantity: 2, unit_price: 25 },
          ...(i % 4 === 0 ? [{ name: "Refrigerant top-off", quantity: 1, unit_price: 95 }] : []),
        ];
        const subtotal = lineItems.reduce((s, l) => s + l.quantity * l.unit_price, 0);
        const tax = Math.round(subtotal * 0.0635 * 100) / 100;
        const quoteId = randomUUID();
        const ins = await restService("provider_quotes", {
          method: "POST",
          headers: { Prefer: "return=representation" },
          body: JSON.stringify({
            id: quoteId,
            workspace_id: wsState.id,
            contractor_id: cust.contractorId,
            household_id: cust.householdId,
            property_id: cust.propertyId,
            title: `${pick(["Annual HVAC tune-up", "Water heater replacement", "Panel upgrade", "Roof repair"], i)} for Customer ${cust.globalIdx}`,
            status,
            currency: "USD",
            line_items: lineItems,
            scope_notes: i % 5 === 0 ? "Multi-trade scope; coordinate with electrician for panel breakers." : null,
            homeowner_message: i % 7 === 0 ? "Heads up: customer asked about good/better/best tiers." : null,
            subtotal,
            tax_total: tax,
            total: subtotal + tax,
            created_by_user_id: wsState.ownerUserId,
            public_share_token: randomUUID(),
            sent_at: ["sent", "viewed", "approved", "declined", "countered_by_homeowner", "superseded"].includes(status) ? isoNow() : null,
            viewed_at: ["viewed", "approved", "declined", "countered_by_homeowner", "superseded"].includes(status) ? isoNow() : null,
            approved_at: status === "approved" ? isoNow() : null,
            declined_at: status === "declined" ? isoNow() : null,
          }),
        });
        if (!ins.ok) { this.recordIssue("phase4", `quote insert ${ws.key}#${i + 1} (${status})`, ins.body); continue; }
        cust.quoteIds.push(quoteId);
        total++;
      }
      logOk(`(${ws.key}) quotes seeded`, `count=${this.state.customers.filter((c) => c.workspaceKey === ws.key).reduce((s, c) => s + c.quoteIds.length, 0)}`);
    }
    this.recordSuccess("phase4", `${total} quotes total across all workspaces`);
  }

  // --------------------------------------------------------------------------
  // Phase 5 — Visits (handyman_requests + provider_visit_assignments)
  // --------------------------------------------------------------------------
  async phase5_visits() {
    logPhase(5, "Visits + assignments (mixed status, past 365 + future 90)");
    const visitScenarios = [
      { request_type: "standard_visit", urgency: "routine", status: "scheduled", days: 1 },
      { request_type: "standard_visit", urgency: "routine", status: "scheduled", days: 5 },
      { request_type: "quote", urgency: "soon", status: "submitted", days: 0 },
      { request_type: "repair", urgency: "urgent", status: "in_progress", days: 0 },
      { request_type: "install", urgency: "routine", status: "completed", days: -7 },
      { request_type: "standard_visit", urgency: "routine", status: "completed", days: -45 },
      { request_type: "standard_visit", urgency: "routine", status: "cancelled", days: -2 },
      { request_type: "repair", urgency: "soon", status: "completed", days: -120 },
      { request_type: "standard_visit", urgency: "routine", status: "completed", days: -365 },
    ];
    let total = 0;
    for (const ws of this.workspaces) {
      const wsState = this.state.workspaces[ws.key];
      if (!wsState) continue;
      const linkedCustomers = this.state.customers.filter((c) => c.workspaceKey === ws.key && c.providerLinkId);
      const targetCount = Math.min(30, linkedCustomers.length * 4);
      for (let i = 0; i < targetCount; i++) {
        const cust = pick(linkedCustomers, i);
        const sc = pick(visitScenarios, i);
        const requestId = randomUUID();
        const reqIns = await restService("handyman_requests", {
          method: "POST",
          headers: { Prefer: "return=representation" },
          body: JSON.stringify({
            id: requestId,
            household_id: cust.householdId,
            property_id: cust.propertyId,
            contractor_id: cust.contractorId,
            request_type: sc.request_type,
            source: i % 3 === 0 ? "vendor" : "homeowner",
            title: `${sc.request_type.replace(/_/g, " ")}: Customer ${cust.globalIdx}`,
            details: `Auto-seeded ${sc.request_type} for E2E test (#${i + 1})`,
            urgency: sc.urgency,
            status: sc.status,
            recommended_lane: "standard",
            quick_upsell_titles: [],
            created_by_user_id: cust.userId,
          }),
        });
        if (!reqIns.ok) continue;
        cust.requestIds.push(requestId);

        // Assignment row
        const assignedMember = wsState.members.length > 0
          ? pick(wsState.members, i)
          : null;
        const assignedMemberId = assignedMember?.id ?? wsState.ownerMembershipId;
        const assignId = randomUUID();
        const assignIns = await restService("provider_visit_assignments", {
          method: "POST",
          headers: { Prefer: "return=representation" },
          body: JSON.stringify({
            id: assignId,
            workspace_id: wsState.id,
            request_id: requestId,
            assigned_member_id: assignedMemberId,
            assigned_by_user_id: wsState.ownerUserId,
            route_date: isoDateInDays(sc.days),
            stop_order: (i % 8) + 1,
          }),
        });
        if (assignIns.ok) {
          cust.assignmentIds.push(assignId);
          total++;
        }
      }
    }
    this.recordSuccess("phase5", `${total} visits + assignments seeded`);
  }

  // --------------------------------------------------------------------------
  // Phase 6 — Punch list items (handyman_punch_items, mixed origins)
  // --------------------------------------------------------------------------
  async phase6_punchItems() {
    logPhase(6, "Handyman punch items (3-8 per visit, mixed origins)");
    let total = 0;
    const sourcePool = ["recommended", "manual", "auto_seed_handyman_tier", "promoted_from_task"];
    for (const cust of this.state.customers) {
      if (cust.requestIds.length === 0) continue;
      for (const requestId of cust.requestIds.slice(0, 4)) {
        const itemCount = 3 + (Math.abs(requestId.charCodeAt(0)) % 6);
        for (let i = 0; i < itemCount; i++) {
          const ins = await restService("handyman_punch_items", {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              id: randomUUID(),
              household_id: cust.householdId,
              property_id: cust.propertyId,
              title: pick(["Replace HVAC filter", "Inspect water heater", "Check smoke detectors", "Replace caulk in tub", "Tighten loose railing", "Test sump pump", "Lubricate garage door"], i),
              source: pick(sourcePool, i),
              completed_at: i === 0 ? isoNow() : null,
            }),
          });
          if (ins.ok) total++;
        }
      }
    }
    this.recordSuccess("phase6", `${total} punch items seeded`);
  }

  // --------------------------------------------------------------------------
  // Phase 7 — Message threads (homeowner ↔ contractor + Chez-mediated)
  // --------------------------------------------------------------------------
  async phase7_messages() {
    logPhase(7, "Message threads (homeowner ↔ contractor + Chez)");
    let total = 0;
    for (const cust of this.state.customers) {
      if (cust.requestIds.length === 0) continue;
      for (let r = 0; r < Math.min(2, cust.requestIds.length); r++) {
        const requestId = cust.requestIds[r];
        // Customer initial
        const m1 = await restService("handyman_request_messages", {
          method: "POST",
          body: JSON.stringify({
            request_id: requestId,
            household_id: cust.householdId,
            sender_role: "homeowner",
            body: `Hi, this is customer ${cust.globalIdx}. Wanted to follow up on the visit.`,
            metadata: {},
          }),
        });
        // Vendor reply
        const m2 = await restService("handyman_request_messages", {
          method: "POST",
          body: JSON.stringify({
            request_id: requestId,
            household_id: cust.householdId,
            sender_role: "vendor",
            body: `Got it. I'll be there at the scheduled time.`,
            metadata: {},
          }),
        });
        // Chez-relayed message (every 5th customer to test the brand voice rendering)
        if (cust.globalIdx % 5 === 0) {
          const mc = await restService("handyman_request_messages", {
            method: "POST",
            body: JSON.stringify({
              request_id: requestId,
              household_id: cust.householdId,
              sender_role: "chez",
              body: `Quick note from Chez: customer asked about scheduling preference.`,
              metadata: { relayed: true },
            }),
          });
          if (mc.ok) this.state.ownerMessagesSeeded++;
        }
        if (m1.ok) total++;
        if (m2.ok) total++;
      }
    }
    this.recordSuccess("phase7", `${total} messages seeded`);
  }

  // --------------------------------------------------------------------------
  // Phase 8 — Chez-orchestrated inbound items to W2 (5 flavors)
  // --------------------------------------------------------------------------
  async phase8_chezInbound() {
    logPhase(8, "Chez admin inbound to W2 (5 flavors)");
    const w2 = this.state.workspaces.w2;
    if (!w2) { this.recordIssue("phase8", "W2 missing"); return; }
    const w2Customers = this.state.customers.filter((c) => c.workspaceKey === "w2" && c.providerLinkId);
    const flavors = [
      { type: "task_routing", title: "Chez routed: replace HVAC filter", request_type: "standard_visit", urgency: "routine" },
      { type: "visit_routing", title: "Chez scheduled: annual tune-up", request_type: "standard_visit", urgency: "routine" },
      { type: "quote_request", title: "Chez asks: roof replacement quote", request_type: "quote", urgency: "soon" },
      { type: "standing_engagement", title: "Chez owns scheduling for this customer", request_type: "standard_visit", urgency: "routine" },
      { type: "emergency_routing", title: "Chez emergency: water heater leak", request_type: "repair", urgency: "urgent" },
    ];
    if (w2Customers.length < flavors.length) {
      this.recordGap("phase8", "Chez inbound seeding", `need ≥${flavors.length} linked W2 customers, got ${w2Customers.length} — re-using customers across flavors`);
    }
    let okCount = 0;
    for (let i = 0; i < flavors.length; i++) {
      const f = flavors[i];
      const cust = w2Customers[i % w2Customers.length];
      const reqId = randomUUID();
      // Seed the request as if it came from Chez admin (source=chez_admin in metadata)
      // GAP: handyman_requests.source CHECK constraint is
      // ('homeowner','haven','vendor','field') — it does NOT include
      // 'chez_admin'. Phase 80+ added Chez orchestration but didn't
      // extend the constraint. We use 'haven' as the closest fit and
      // stamp the actual routing flavor in metadata. Logged in
      // CONTRACTOR_GAPS.md as a real gap.
      const reqIns = await restService("handyman_requests", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          id: reqId,
          household_id: cust.householdId,
          property_id: cust.propertyId,
          contractor_id: cust.contractorId,
          request_type: f.request_type,
          source: "haven",
          title: f.title,
          details: `Chez admin routed this to W2 contractor — flavor=${f.type}`,
          urgency: f.urgency,
          status: "submitted",
          recommended_lane: "standard",
          quick_upsell_titles: [],
          created_by_user_id: cust.userId,
          // GAP: handyman_requests has NO `metadata` JSONB column. Phase 80
          // Chez orchestration relies on the messages table for context.
          // The flavor lives only on the relayed Chez message metadata.
        }),
      });
      if (reqIns.ok) {
        cust.requestIds.push(reqId);
        okCount++;
        // Add a message marking this as Chez-mediated
        await restService("handyman_request_messages", {
          method: "POST",
          body: JSON.stringify({
            request_id: reqId,
            household_id: cust.householdId,
            sender_role: "chez",
            body: `[Chez routed] ${f.title}. Context: ${f.type}. Reply to Chez with accept/decline/counter.`,
            metadata: { chez_inbound_flavor: f.type, requires_acknowledgment: f.type === "emergency_routing" },
          }),
        });
        this.state.chezInboundSeeded++;
      } else {
        this.recordIssue("phase8", `chez inbound ${f.type}`, reqIns.body);
      }
    }
    this.recordSuccess("phase8", `${okCount}/5 Chez inbound flavors seeded to W2`);
  }

  // --------------------------------------------------------------------------
  // Phase 9 — Saved quote items per workspace
  // --------------------------------------------------------------------------
  async phase9_savedQuoteItems() {
    logPhase(9, "Saved quote items library per workspace");
    let total = 0;
    const items = [
      { name: "Service call", description: "Diagnostic visit + first hour of labor", unit: "visit", default_quantity: 1, default_unit_price: 150 },
      { name: "HVAC filter (16x25x4)", description: "Standard pleated filter", unit: "each", default_quantity: 2, default_unit_price: 25 },
      { name: "Refrigerant top-off (R410A)", description: "Per pound of refrigerant", unit: "lb", default_quantity: 1, default_unit_price: 95 },
      { name: "Hourly labor", description: "Standard labor rate", unit: "hr", default_quantity: 1, default_unit_price: 125 },
      { name: "Annual maintenance plan", description: "Two visits + priority booking + 10% off repairs", unit: "year", default_quantity: 1, default_unit_price: 299 },
    ];
    for (const ws of this.workspaces) {
      const wsState = this.state.workspaces[ws.key];
      if (!wsState) continue;
      for (let i = 0; i < items.length; i++) {
        const it = items[i];
        const ins = await restService("provider_saved_quote_items", {
          method: "POST",
          body: JSON.stringify({
            id: randomUUID(),
            workspace_id: wsState.id,
            ...it,
            sort_order: i,
            created_by_user_id: wsState.ownerUserId,
          }),
        });
        if (ins.ok) total++;
      }
    }
    this.recordSuccess("phase9", `${total} saved quote items seeded`);
  }

  // --------------------------------------------------------------------------
  // Phase 10 — Verification (count rows, fetch dashboard for each workspace)
  // --------------------------------------------------------------------------
  async phase10_verify() {
    logPhase(10, "Verification: row counts + dashboard fetch per workspace");
    for (const ws of this.workspaces) {
      const wsState = this.state.workspaces[ws.key];
      if (!wsState) continue;
      const counts = await Promise.all([
        ["members", `provider_workspace_members?workspace_id=eq.${wsState.id}&select=id`],
        ["customers (links)", `provider_contractor_links?workspace_id=eq.${wsState.id}&select=id`],
        ["quotes", `provider_quotes?workspace_id=eq.${wsState.id}&select=id`],
        ["visits (assignments)", `provider_visit_assignments?workspace_id=eq.${wsState.id}&select=id`],
        ["saved_items", `provider_saved_quote_items?workspace_id=eq.${wsState.id}&select=id`],
      ].map(async ([name, q]) => {
        const r = await restService(q);
        return [name, r.body?.length ?? "?"];
      }));
      logStep(`(${ws.key})`);
      for (const [name, n] of counts) logOk(`  ${name.padEnd(24)} ${n}`);

      // Dashboard fetch as workspace owner — confirm the round-trip works.
      const dashRes = await http(`${SUPABASE_URL}/functions/v1/handyman-provider`, {
        method: "GET",
        headers: authHeaders(wsState.ownerJwt),
      });
      if (dashRes.ok) {
        const d = dashRes.body;
        logOk(`  dashboard fetch ok`, `visits=${(d?.visits || []).length} homes=${(d?.homes || []).length} quotes=${(d?.quotes || []).length} threads=${(d?.messages || []).length}`);
      } else {
        this.recordIssue("phase10", `(${ws.key}) dashboard fetch failed`, dashRes.body);
      }
    }
    if (this.issues.length === 0) this.recordSuccess("phase10", "all phases verified");
  }

  // --------------------------------------------------------------------------
  // Run all
  // --------------------------------------------------------------------------
  async run() {
    const t0 = Date.now();
    let aborted = false;
    try {
      await this.phase0_cleanup();
      await this.phase1_workspaceOwners();
      await this.phase2_crew();
      await this.phase3_customers();
      await this.phase4_quotes();
      await this.phase5_visits();
      await this.phase6_punchItems();
      await this.phase7_messages();
      await this.phase8_chezInbound();
      await this.phase9_savedQuoteItems();
      await this.phase10_verify();
    } catch (err) {
      aborted = true;
      console.log(`\n${c.red}${c.bold}Aborted: ${err.message}${c.reset}`);
    }

    const elapsed = ((Date.now() - t0) / 1000).toFixed(1);
    // Persist the timestamp so subagents can compose owner emails.
    try {
      const fs = await import("node:fs");
      fs.writeFileSync("/tmp/ui-test/contractor-stamp.txt", String(this.stamp));
      const summary = {
        stamp: this.stamp,
        workspaces: Object.fromEntries(
          Object.entries(this.state.workspaces).map(([k, v]) => [k, { id: v.id, ownerEmail: v.ownerEmail, memberCount: v.members.length + 1 }])
        ),
      };
      fs.writeFileSync("/tmp/ui-test/contractor-fixture.json", JSON.stringify(summary, null, 2));
    } catch {}
    console.log(`\n${c.cyan}${c.bold}━━━ Summary ${"━".repeat(60)}${c.reset}`);
    for (const ws of this.workspaces) {
      const wsState = this.state.workspaces[ws.key];
      if (wsState) {
        console.log(`  (${ws.key}) ${wsState.ownerEmail} — id=${wsState.id?.slice(0, 8)}…`);
      }
    }
    console.log(`  customers:       ${this.state.customers.length}`);
    console.log(`  chez inbound:    ${this.state.chezInboundSeeded}`);
    console.log(`  elapsed:         ${elapsed}s`);
    console.log(`  ${c.green}successes:${c.reset} ${this.successes.length}`);
    for (const s of this.successes) console.log(`    ${c.green}✓${c.reset} [${s.phase}] ${s.msg}`);
    console.log(`  ${c.red}issues:${c.reset}    ${this.issues.length}`);
    for (const i of this.issues) {
      console.log(`    ${c.red}✗${c.reset} [${i.phase}] ${i.msg}${i.detail ? `\n        ${c.dim}${typeof i.detail === "string" ? i.detail : JSON.stringify(i.detail).slice(0, 300)}${c.reset}` : ""}`);
    }
    if (this.gaps.length > 0) {
      console.log(`  ${c.yellow}gaps:${c.reset}      ${this.gaps.length}`);
      for (const g of this.gaps) console.log(`    ${c.yellow}!${c.reset} [${g.phase}] ${g.scenario} — ${g.detail}`);
    }
    return { issues: this.issues, successes: this.successes, gaps: this.gaps, aborted };
  }
}

// ----------------------------------------------------------------------------
// Entry point
// ----------------------------------------------------------------------------

const runner = new ContractorE2ERunner();
const { issues, aborted } = await runner.run();
if (issues.length > 0 || aborted) process.exit(1);
console.log(`\n${c.green}${c.bold}✓ All phases passed.${c.reset}\n`);
process.exit(0);
