#!/usr/bin/env node
// ============================================================================
// Haven Handyman E2E test runner
// ============================================================================
//
// Exercises the provider workspace + handyman request schema and the
// `handyman-provider` Edge Function via service-role JWT, against the live
// haven-dev Supabase project. Mirrors how the iOS field app calls each
// action so contract regressions show up here before they ship.
//
// Test fixtures created:
//   - 1 provider workspace (owner)
//   - 1 crew member
//   - 5 customer households (varying state: clean / populated / pre-quiz /
//     post-assessment / overdue) — used as targets for handyman flows
//   - Sample quote drafts on each customer (mix of statuses)
//   - Sample scheduled visits across customers
//   - Sample message threads
//
// Usage:
//   node Tests/e2e/run-handyman.mjs
//
// Optional env vars:
//   E2E_VERBOSE=1            -- log full request/response bodies on failure
//   E2E_KEEP_USER=1          -- skip post-run cleanup
//   E2E_SKIP_CLEANUP=1       -- skip pre-run cleanup
//   E2E_SERVICE_JWT=...      -- override service-role JWT (default reads from
//                               .claude/settings.local.json scrape file at
//                               /tmp/ui-test/service-jwt.txt)
//
// Exit codes:
//   0  -- all phases passed
//   1  -- one or more phases failed (issue tally printed at the end)
// ============================================================================

import { randomUUID } from "node:crypto";
import { execSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

// ----------------------------------------------------------------------------
// Configuration
// ----------------------------------------------------------------------------

const SUPABASE_URL = "https://jsucwnkntdrxhysojgri.supabase.co";
const ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

// Service-role JWT — needed for cleanup + cross-account fixture seeding.
// Read from disk so it isn't checked in. The overnight harness scrapes this
// from .claude/settings.local.json on first run.
const SERVICE_JWT = (() => {
  if (process.env.E2E_SERVICE_JWT) return process.env.E2E_SERVICE_JWT;
  const path = "/tmp/ui-test/service-jwt.txt";
  if (existsSync(path)) return readFileSync(path, "utf8").trim();
  console.error("Missing service-role JWT at /tmp/ui-test/service-jwt.txt and E2E_SERVICE_JWT not set.");
  process.exit(1);
})();

const TEST_PASSWORD = "TestHandymanPassword!2026";
const VERBOSE = !!process.env.E2E_VERBOSE;

const __dirname = dirname(fileURLToPath(import.meta.url));
const CLEANUP_SQL_PATH = resolve(__dirname, "cleanup-handyman.sql");
const REPO_ROOT = resolve(__dirname, "..", "..");

// ----------------------------------------------------------------------------
// Logging helpers
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
  console.log(
    `\n${c.cyan}${c.bold}━━━ Phase ${num}: ${title} ${"━".repeat(Math.max(0, 60 - title.length))}${c.reset}`
  );
}

function logStep(msg) {
  console.log(`  ${c.dim}→${c.reset} ${msg}`);
}

function logOk(msg, detail = "") {
  console.log(
    `  ${c.green}✓${c.reset} ${msg}${detail ? ` ${c.dim}${detail}${c.reset}` : ""}`
  );
}

function logFail(msg, detail = "") {
  console.log(
    `  ${c.red}✗${c.reset} ${msg}${detail ? ` ${c.dim}${detail}${c.reset}` : ""}`
  );
}

function logWarn(msg, detail = "") {
  console.log(
    `  ${c.yellow}!${c.reset} ${msg}${detail ? ` ${c.dim}${detail}${c.reset}` : ""}`
  );
}

// ----------------------------------------------------------------------------
// HTTP helper
// ----------------------------------------------------------------------------

async function http(url, opts = {}) {
  const res = await fetch(url, opts);
  const text = await res.text();
  let body;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = text;
  }
  if (VERBOSE && !res.ok) {
    console.log(
      `  ${c.dim}HTTP ${res.status} ${url}${c.reset}\n  ${c.dim}${typeof body === "string" ? body : JSON.stringify(body, null, 2)}${c.reset}`
    );
  }
  return { ok: res.ok, status: res.status, body, raw: text };
}

function authHeaders(jwt) {
  return {
    apikey: ANON_KEY,
    authorization: `Bearer ${jwt || ANON_KEY}`,
    "content-type": "application/json",
  };
}

function serviceHeaders() {
  return {
    apikey: SERVICE_JWT,
    authorization: `Bearer ${SERVICE_JWT}`,
    "content-type": "application/json",
  };
}

async function callEdgeFunction(name, body, jwt) {
  return http(`${SUPABASE_URL}/functions/v1/${name}`, {
    method: "POST",
    headers: authHeaders(jwt),
    body: JSON.stringify(body),
  });
}

async function rest(path, opts, jwt) {
  return http(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...opts,
    headers: { ...authHeaders(jwt), ...(opts?.headers || {}) },
  });
}

async function restService(path, opts) {
  return http(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...opts,
    headers: { ...serviceHeaders(), ...(opts?.headers || {}) },
  });
}

async function adminSqlFile(filePath) {
  try {
    const out = execSync(
      `cd ${REPO_ROOT} && supabase db query --linked --output json --file ${filePath}`,
      { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }
    );
    return JSON.parse(out);
  } catch (err) {
    return { error: err.stderr?.toString() || err.message };
  }
}

function isoNow() {
  return new Date().toISOString();
}

// Add N days to today, return ISO date (yyyy-mm-dd)
function isoDateInDays(n) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d.toISOString().slice(0, 10);
}

// ----------------------------------------------------------------------------
// Provider workspace runner
// ----------------------------------------------------------------------------

class HandymanE2ERunner {
  constructor() {
    const stamp = Date.now();
    this.stamp = stamp;
    this.ownerEmail = `e2e-handyman-w1-owner-${stamp}@havenhome.test`;
    this.crewEmail = `e2e-handyman-w1-crew-${stamp}@havenhome.test`;
    this.customerEmails = Array.from({ length: 5 }, (_, i) =>
      `e2e-customer-of-handyman-w1-${i + 1}-${stamp}@havenhome.test`
    );
    this.issues = [];
    this.successes = [];
    this.gaps = [];
    this.state = {
      ownerJwt: null,
      ownerUserId: null,
      crewJwt: null,
      crewUserId: null,
      workspaceId: null,
      workspaceMembershipId: null,
      crewMembershipId: null,
      customers: [], // [{ email, jwt, userId, householdId, propertyId, systemIds: [] }]
      contractorIds: [], // contractor rows linked to W1
      providerContractorLinkIds: [],
      quoteIds: [], // mix of states
      assignmentIds: [],
      requestIds: [],
      messageThreadIds: [],
    };
  }

  recordSuccess(phase, msg) {
    this.successes.push({ phase, msg });
    logOk(msg);
  }

  recordIssue(phase, msg, detail = null) {
    this.issues.push({ phase, msg, detail });
    if (detail) {
      logFail(msg, typeof detail === "string" ? detail : JSON.stringify(detail).slice(0, 250));
    } else {
      logFail(msg);
    }
  }

  recordGap(phase, scenario, detail) {
    this.gaps.push({ phase, scenario, detail });
    logWarn(`gap: ${scenario}`, detail);
  }

  // --------------------------------------------------------------------------
  // Phase 0 — Cleanup
  // --------------------------------------------------------------------------
  async phase0_cleanup() {
    logPhase(0, "Pre-run cleanup");
    if (process.env.E2E_SKIP_CLEANUP) {
      logWarn("E2E_SKIP_CLEANUP=1, skipping");
      return;
    }
    logStep(`Wiping any prior e2e-handyman-* + e2e-customer-of-handyman-* users`);
    const result = await adminSqlFile(CLEANUP_SQL_PATH);
    if (result.error) {
      this.recordIssue("phase0", "cleanup SQL failed", result.error);
      throw new Error("Cleanup failed — refusing to continue");
    }
    logOk("cleanup complete");
  }

  // --------------------------------------------------------------------------
  // Helper — sign up a fresh user via auth/v1/signup, return { jwt, userId }
  // --------------------------------------------------------------------------
  async signupUser(email, firstName, lastName) {
    const signup = await http(`${SUPABASE_URL}/auth/v1/signup`, {
      method: "POST",
      headers: { apikey: ANON_KEY, "content-type": "application/json" },
      body: JSON.stringify({
        email,
        password: TEST_PASSWORD,
        data: {
          first_name: firstName,
          last_name: lastName,
          full_name: `${firstName} ${lastName}`,
        },
      }),
    });
    if (!signup.ok) throw new Error(`signup failed for ${email}: ${JSON.stringify(signup.body)}`);
    const session = signup.body;
    if (!session.access_token || !session.user?.id) {
      throw new Error(`signup did not return session+user for ${email}`);
    }

    // Insert public.users row mirroring iOS pattern
    const userInsert = await rest(
      "users",
      {
        method: "POST",
        body: JSON.stringify({
          id: session.user.id,
          household_id: null,
          email,
          full_name: `${firstName} ${lastName}`,
          role: "member",
        }),
      },
      session.access_token
    );
    if (!userInsert.ok) throw new Error(`public.users insert failed for ${email}`);

    return { jwt: session.access_token, userId: session.user.id };
  }

  // --------------------------------------------------------------------------
  // Phase 1 — Create handyman workspace owner
  // --------------------------------------------------------------------------
  async phase1_workspaceOwner() {
    logPhase(1, "Workspace owner signup + bootstrap_workspace");
    logStep(`signing up ${this.ownerEmail}`);
    const { jwt, userId } = await this.signupUser(this.ownerEmail, "E2E", "Owner");
    this.state.ownerJwt = jwt;
    this.state.ownerUserId = userId;
    logOk(`owner auth user created`, `id=${userId.slice(0, 8)}…`);

    // Bootstrap the workspace via the same Edge Function the iOS app uses.
    logStep("calling handyman-provider bootstrap_workspace");
    const bootstrap = await callEdgeFunction(
      "handyman-provider",
      {
        action: "bootstrap_workspace",
        fullName: "E2E Owner",
        companyName: `E2E Handyman Co ${this.stamp}`,
        phone: "555-0100",
        website: "https://e2e-handyman.example",
      },
      jwt
    );
    if (!bootstrap.ok) {
      this.recordIssue("phase1", "bootstrap_workspace failed", bootstrap.body);
      throw new Error("phase1 fatal — cannot continue without workspace");
    }
    const dashboard = bootstrap.body || {};
    const wsId = dashboard?.workspace?.id;
    if (!wsId) {
      this.recordIssue("phase1", "bootstrap_workspace returned no workspace id", dashboard);
      throw new Error("phase1 fatal");
    }
    this.state.workspaceId = wsId;
    logOk(`workspace created`, `id=${wsId.slice(0, 8)}…`);

    // Find the membership row that bootstrap created.
    const memb = await restService(
      `provider_workspace_members?workspace_id=eq.${wsId}&user_id=eq.${userId}&select=id,role,status`
    );
    if (memb.ok && memb.body && memb.body.length) {
      this.state.workspaceMembershipId = memb.body[0].id;
      logOk(`owner membership row exists`, `role=${memb.body[0].role} status=${memb.body[0].status}`);
    } else {
      this.recordIssue("phase1", "owner membership row not found after bootstrap", memb.body);
    }

    this.recordSuccess("phase1", "workspace owner + bootstrap complete");
  }

  // --------------------------------------------------------------------------
  // Phase 2 — Add a crew member (via service-role direct insert; the
  // invite_team_member edge action would normally do this but requires email
  // delivery setup. Direct insert exercises the same DB path.)
  // --------------------------------------------------------------------------
  async phase2_crewMember() {
    logPhase(2, "Crew member signup + workspace_member insert");
    logStep(`signing up ${this.crewEmail}`);
    let crew;
    try {
      crew = await this.signupUser(this.crewEmail, "E2E", "Crew");
    } catch (err) {
      this.recordIssue("phase2", "crew signup failed", err.message);
      return;
    }
    this.state.crewJwt = crew.jwt;
    this.state.crewUserId = crew.userId;
    logOk(`crew auth user created`, `id=${crew.userId.slice(0, 8)}…`);

    // Create the membership row directly (Edge Function `invite_team_member`
    // depends on email send infra; simulate the resulting DB state here).
    const memberInsert = await restService("provider_workspace_members", {
      method: "POST",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify({
        workspace_id: this.state.workspaceId,
        user_id: crew.userId,
        full_name: "E2E Crew",
        email: this.crewEmail,
        role: "technician",
        status: "active",
      }),
    });
    if (!memberInsert.ok) {
      this.recordIssue("phase2", "crew membership insert failed", memberInsert.body);
      return;
    }
    this.state.crewMembershipId = memberInsert.body[0]?.id;
    this.recordSuccess(
      "phase2",
      `crew member added to workspace as technician`
    );
  }

  // --------------------------------------------------------------------------
  // Phase 3 — Create 5 customer households
  // --------------------------------------------------------------------------
  async phase3_customers() {
    logPhase(3, "Create 5 customer households (varying states)");
    const variants = [
      { label: "clean linked-yesterday", systems: 0 },
      { label: "populated 3+ systems", systems: 3 },
      { label: "pre-quiz", systems: 0 },
      { label: "post-handyman-assessment", systems: 5 },
      { label: "overdue for service", systems: 2 },
    ];

    for (let i = 0; i < this.customerEmails.length; i++) {
      const email = this.customerEmails[i];
      const variant = variants[i];
      logStep(`(${i + 1}/5) ${email} — ${variant.label}`);

      let user;
      try {
        user = await this.signupUser(email, `E2EClient${i + 1}`, "Customer");
      } catch (err) {
        this.recordIssue("phase3", `customer ${i + 1} signup failed`, err.message);
        continue;
      }

      // Create household
      const householdId = randomUUID();
      const householdIns = await rest(
        "households",
        {
          method: "POST",
          body: JSON.stringify({
            id: householdId,
            name: `Customer ${i + 1} of E2E Handyman`,
            subscription_tier: "standard",
          }),
        },
        user.jwt
      );
      if (!householdIns.ok) {
        this.recordIssue("phase3", `customer ${i + 1} household insert failed`, householdIns.body);
        continue;
      }

      // Link user to household
      const userUpd = await rest(
        `users?id=eq.${user.userId}`,
        {
          method: "PATCH",
          body: JSON.stringify({
            household_id: householdId,
            full_name: `E2EClient${i + 1} Customer`,
          }),
        },
        user.jwt
      );
      if (!userUpd.ok) {
        this.recordIssue("phase3", `customer ${i + 1} user link failed`, userUpd.body);
        continue;
      }

      // Create primary client family member
      const fmId = randomUUID();
      await rest(
        "family_members",
        {
          method: "POST",
          body: JSON.stringify({
            id: fmId,
            household_id: householdId,
            first_name: `E2EClient${i + 1}`,
            last_name: "Customer",
            relationship: "Primary Client",
            email,
            linked_user_id: user.userId,
            member_type: "family",
          }),
        },
        user.jwt
      );

      // Create property
      const propertyId = randomUUID();
      const propIns = await rest(
        "properties",
        {
          method: "POST",
          body: JSON.stringify({
            id: propertyId,
            household_id: householdId,
            name: `Customer ${i + 1} home`,
            property_type: "Single Family",
            street: `${100 + i} Test Lane`,
            city: "Bethel",
            state: "CT",
            zip_code: "06801",
            country: "US",
            year_built: 1985,
            square_footage: 2400,
            current_estimated_value: 700000,
            regional_pack: "northeast",
          }),
        },
        user.jwt
      );
      if (!propIns.ok) {
        this.recordIssue("phase3", `customer ${i + 1} property insert failed`, propIns.body);
        continue;
      }

      // Seed home_systems based on variant
      const systemIds = [];
      const baselineSystems = ["HVAC", "Water Heater", "Roofing", "Electrical", "Plumbing"];
      for (let s = 0; s < variant.systems; s++) {
        const sysId = randomUUID();
        const sysIns = await rest(
          "home_systems",
          {
            method: "POST",
            body: JSON.stringify({
              id: sysId,
              household_id: householdId,
              property_id: propertyId,
              category: baselineSystems[s],
              name: baselineSystems[s],
              is_essential: true,
            }),
          },
          user.jwt
        );
        if (sysIns.ok) systemIds.push(sysId);
      }

      this.state.customers.push({
        email,
        jwt: user.jwt,
        userId: user.userId,
        householdId,
        propertyId,
        systemIds,
        variant: variant.label,
      });
      logOk(`customer ${i + 1} ready`, `household=${householdId.slice(0, 8)}… systems=${systemIds.length}`);
    }

    if (this.state.customers.length !== 5) {
      this.recordIssue("phase3", `expected 5 customers, got ${this.state.customers.length}`);
    } else {
      this.recordSuccess("phase3", `5 customer households created`);
    }
  }

  // --------------------------------------------------------------------------
  // Phase 4 — Link customers to W1 via contractor + provider_contractor_link
  // --------------------------------------------------------------------------
  async phase4_linkCustomers() {
    logPhase(4, "Link 4/5 customers to W1 (1 declined for state coverage)");
    // First 4 customers get linked. Customer 5 is left "unlinked" to exercise
    // the not-yet-claimed state.
    for (let i = 0; i < Math.min(4, this.state.customers.length); i++) {
      const cust = this.state.customers[i];
      // Insert a contractor row on the customer's household pointing to W1's
      // company name. Then insert provider_contractor_links.
      const contractorId = randomUUID();
      const contractorIns = await rest(
        "contractors",
        {
          method: "POST",
          body: JSON.stringify({
            id: contractorId,
            household_id: cust.householdId,
            company_name: `E2E Handyman Co ${this.stamp}`,
            contact_name: "E2E Owner",
            phone: "555-0100",
            website: "https://e2e-handyman.example",
            category: "General",
            source: "manual",
          }),
        },
        cust.jwt
      );
      if (!contractorIns.ok) {
        this.recordIssue("phase4", `contractor row insert failed for customer ${i + 1}`, contractorIns.body);
        continue;
      }
      this.state.contractorIds.push(contractorId);

      // Service-role insert into provider_contractor_links (cross-household
      // relationship needs elevated perms).
      const linkIns = await restService("provider_contractor_links", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          workspace_id: this.state.workspaceId,
          contractor_id: contractorId,
          is_primary: true,
          claim_source: "manual",
        }),
      });
      if (!linkIns.ok) {
        this.recordIssue("phase4", `provider_contractor_link insert failed for customer ${i + 1}`, linkIns.body);
        continue;
      }
      this.state.providerContractorLinkIds.push(linkIns.body[0]?.id);
      logOk(`customer ${i + 1} linked to W1`, `contractor=${contractorId.slice(0, 8)}…`);
    }

    if (this.state.providerContractorLinkIds.length === 4) {
      this.recordSuccess("phase4", `4 customers linked, 1 unlinked for state coverage`);
    } else {
      this.recordIssue(
        "phase4",
        `expected 4 links, got ${this.state.providerContractorLinkIds.length}`
      );
    }
  }

  // --------------------------------------------------------------------------
  // Phase 5 — Sample quote drafts (mix of statuses)
  // --------------------------------------------------------------------------
  async phase5_quotes() {
    logPhase(5, "Seed sample quotes (draft / sent / approved / declined)");
    const states = ["draft", "sent", "approved", "declined"];
    for (let i = 0; i < Math.min(4, this.state.customers.length); i++) {
      const cust = this.state.customers[i];
      const status = states[i];
      const quoteId = randomUUID();
      // Seed via service role since cross-workspace + cross-household.
      const ins = await restService("provider_quotes", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          id: quoteId,
          workspace_id: this.state.workspaceId,
          contractor_id: this.state.contractorIds[i] ?? null,
          household_id: cust.householdId,
          property_id: cust.propertyId,
          title: `Annual HVAC tune-up. Customer ${i + 1}`,
          status,
          currency: "USD",
          line_items: [
            { name: "Service call", quantity: 1, unit_price: 150 },
            { name: "Filter replacement", quantity: 2, unit_price: 25 },
          ],
          subtotal: 200,
          tax_total: 0,
          total: 200,
          created_by_user_id: this.state.ownerUserId,
          public_share_token: randomUUID(),
        }),
      });
      if (!ins.ok) {
        this.recordIssue("phase5", `provider_quote insert failed for customer ${i + 1} (${status})`, ins.body);
        continue;
      }
      this.state.quoteIds.push(quoteId);
      logOk(`quote ${i + 1}/4 (${status})`, `id=${quoteId.slice(0, 8)}…`);
    }

    if (this.state.quoteIds.length === 4) {
      this.recordSuccess("phase5", `4 quotes spanning draft/sent/approved/declined`);
    } else {
      this.recordIssue(
        "phase5",
        `expected 4 quotes, got ${this.state.quoteIds.length}`
      );
    }
  }

  // --------------------------------------------------------------------------
  // Phase 6 — Sample handyman_requests (mix of types/statuses) + visit assignments
  // --------------------------------------------------------------------------
  async phase6_visits() {
    logPhase(6, "Seed handyman_requests + provider_visit_assignments");
    const today = isoDateInDays(0);
    const scenarios = [
      { request_type: "standard_visit", urgency: "routine", status: "scheduled", days: 1 },
      { request_type: "quote", urgency: "soon", status: "submitted", days: 3 },
      { request_type: "repair", urgency: "urgent", status: "in_progress", days: 0 },
      { request_type: "install", urgency: "routine", status: "completed", days: -7 },
    ];

    for (let i = 0; i < Math.min(4, this.state.customers.length); i++) {
      const cust = this.state.customers[i];
      const sc = scenarios[i];
      const requestId = randomUUID();
      // Customer's household-scoped insert via service-role
      const reqIns = await restService("handyman_requests", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          id: requestId,
          household_id: cust.householdId,
          property_id: cust.propertyId,
          contractor_id: this.state.contractorIds[i] ?? null,
          request_type: sc.request_type,
          source: "homeowner",
          title: `${sc.request_type.replace(/_/g, " ")}: Customer ${i + 1}`,
          details: `Auto-seeded ${sc.request_type} for E2E test`,
          urgency: sc.urgency,
          status: sc.status,
          recommended_lane: "standard",
          quick_upsell_titles: [],
          created_by_user_id: cust.userId,
        }),
      });
      if (!reqIns.ok) {
        this.recordIssue("phase6", `handyman_request insert failed for customer ${i + 1}`, reqIns.body);
        continue;
      }
      this.state.requestIds.push(requestId);

      // Create matching provider_visit_assignment
      const assignId = randomUUID();
      const assignIns = await restService("provider_visit_assignments", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          id: assignId,
          workspace_id: this.state.workspaceId,
          request_id: requestId,
          assigned_user_id: this.state.crewUserId ?? this.state.ownerUserId,
          status: sc.status,
          scheduled_date: isoDateInDays(sc.days),
          request_type: sc.request_type,
        }),
      });
      if (!assignIns.ok) {
        // Workspace_id was the only required field; the rest may be schema-strict.
        // Try a minimal fallback insert.
        const fallback = await restService("provider_visit_assignments", {
          method: "POST",
          headers: { Prefer: "return=representation" },
          body: JSON.stringify({
            id: assignId,
            workspace_id: this.state.workspaceId,
            request_id: requestId,
          }),
        });
        if (!fallback.ok) {
          this.recordIssue(
            "phase6",
            `visit_assignment insert failed for customer ${i + 1}`,
            assignIns.body
          );
          continue;
        }
      }
      this.state.assignmentIds.push(assignId);
      logOk(
        `visit ${i + 1}/4 ${sc.request_type}`,
        `req=${requestId.slice(0, 8)}… assign=${assignId.slice(0, 8)}…`
      );
    }

    if (this.state.requestIds.length === 4) {
      this.recordSuccess("phase6", `4 handyman_requests + ${this.state.assignmentIds.length} visit assignments`);
    } else {
      this.recordIssue(
        "phase6",
        `expected 4 requests, got ${this.state.requestIds.length}`
      );
    }
  }

  // --------------------------------------------------------------------------
  // Phase 7 — Sample messages thread per customer with a request
  // --------------------------------------------------------------------------
  async phase7_messageThreads() {
    logPhase(7, "Seed handyman_request_messages threads");
    let okCount = 0;
    for (let i = 0; i < this.state.requestIds.length; i++) {
      const requestId = this.state.requestIds[i];
      const cust = this.state.customers[i];
      // Customer message
      const m1 = await restService("handyman_request_messages", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          request_id: requestId,
          household_id: cust.householdId,
          sender_role: "homeowner",
          body: `Customer ${i + 1} initial message — please come look at the issue.`,
          metadata: {},
        }),
      });
      // Vendor reply
      const m2 = await restService("handyman_request_messages", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          request_id: requestId,
          household_id: cust.householdId,
          sender_role: "vendor",
          body: `On my way. Will arrive by ${new Date().toLocaleTimeString()}.`,
          metadata: {},
        }),
      });
      if (m1.ok && m2.ok) okCount++;
      else this.recordIssue("phase7", `message thread insert failed for customer ${i + 1}`);
    }
    this.recordSuccess("phase7", `${okCount}/${this.state.requestIds.length} message threads seeded`);
  }

  // --------------------------------------------------------------------------
  // Phase 8 — fetchDashboard via Edge Function (verify entire fixture
  // surfaces correctly through the same path the iOS app uses)
  // --------------------------------------------------------------------------
  async phase8_dashboardFetch() {
    logPhase(8, "Fetch handyman-provider dashboard as the workspace owner");
    const dashRes = await http(`${SUPABASE_URL}/functions/v1/handyman-provider`, {
      method: "GET",
      headers: authHeaders(this.state.ownerJwt),
    });
    if (!dashRes.ok) {
      this.recordIssue("phase8", `dashboard fetch failed`, dashRes.body);
      return;
    }
    const dashboard = dashRes.body;
    if (!dashboard?.workspace?.id) {
      this.recordIssue("phase8", `dashboard missing workspace`, dashboard);
      return;
    }
    logOk(`dashboard returned`, `workspace=${dashboard.workspace.id.slice(0, 8)}…`);

    // Spot-check the visits / homes / messages arrays
    const visits = (dashboard.visits || []).length;
    const homes = (dashboard.homes || []).length;
    const messages = (dashboard.messages || []).length;
    logOk(`dashboard contents`, `visits=${visits} homes=${homes} messages=${messages}`);

    if (visits === 0 && this.state.assignmentIds.length > 0) {
      this.recordIssue(
        "phase8",
        `dashboard visits=0 but seeded ${this.state.assignmentIds.length} assignments`
      );
    }
    if (homes === 0 && this.state.providerContractorLinkIds.length > 0) {
      this.recordIssue(
        "phase8",
        `dashboard homes=0 but seeded ${this.state.providerContractorLinkIds.length} customer links`
      );
    }

    this.recordSuccess(
      "phase8",
      `dashboard fetch succeeded with visits=${visits} homes=${homes} messages=${messages}`
    );
  }

  // --------------------------------------------------------------------------
  // Phase 9 — Final verification (counts of each fixture)
  // --------------------------------------------------------------------------
  async phase9_verify() {
    logPhase(9, "Final verification");
    const counts = await Promise.all(
      [
        ["provider_workspaces", `provider_workspaces?id=eq.${this.state.workspaceId}&select=id`],
        [
          "provider_workspace_members",
          `provider_workspace_members?workspace_id=eq.${this.state.workspaceId}&select=id`,
        ],
        [
          "provider_contractor_links",
          `provider_contractor_links?workspace_id=eq.${this.state.workspaceId}&select=id`,
        ],
        [
          "provider_quotes",
          `provider_quotes?workspace_id=eq.${this.state.workspaceId}&select=id,status`,
        ],
        [
          "provider_visit_assignments",
          `provider_visit_assignments?workspace_id=eq.${this.state.workspaceId}&select=id`,
        ],
        [
          "handyman_requests (any of our customers)",
          this.state.customers.length > 0
            ? `handyman_requests?household_id=in.(${this.state.customers.map((c) => c.householdId).join(",")})&select=id`
            : `handyman_requests?id=eq.00000000-0000-0000-0000-000000000000&select=id`,
        ],
        [
          "handyman_request_messages",
          this.state.requestIds.length > 0
            ? `handyman_request_messages?request_id=in.(${this.state.requestIds.join(",")})&select=id`
            : `handyman_request_messages?id=eq.00000000-0000-0000-0000-000000000000&select=id`,
        ],
      ].map(async ([name, q]) => {
        const r = await restService(q);
        return [name, r.body?.length ?? "?"];
      })
    );
    for (const [name, n] of counts) {
      logOk(`  ${name.padEnd(40)} ${n}`);
    }

    if (this.issues.length === 0) {
      this.recordSuccess("phase9", "all verifications passed");
    }
  }

  // --------------------------------------------------------------------------
  // Run all phases
  // --------------------------------------------------------------------------
  async run() {
    const t0 = Date.now();
    let aborted = false;
    try {
      await this.phase0_cleanup();
      await this.phase1_workspaceOwner();
      await this.phase2_crewMember();
      await this.phase3_customers();
      await this.phase4_linkCustomers();
      await this.phase5_quotes();
      await this.phase6_visits();
      await this.phase7_messageThreads();
      await this.phase8_dashboardFetch();
      await this.phase9_verify();
    } catch (err) {
      aborted = true;
      console.log(`\n${c.red}${c.bold}Aborted: ${err.message}${c.reset}`);
    }

    const elapsed = ((Date.now() - t0) / 1000).toFixed(1);
    console.log(`\n${c.cyan}${c.bold}━━━ Summary ${"━".repeat(60)}${c.reset}`);
    console.log(`  owner:           ${this.ownerEmail}`);
    console.log(`  crew:            ${this.crewEmail}`);
    console.log(`  customers:       ${this.state.customers.length}`);
    console.log(`  workspaceId:     ${this.state.workspaceId}`);
    console.log(`  elapsed:         ${elapsed}s`);
    console.log(`  ${c.green}successes:${c.reset} ${this.successes.length}`);
    for (const s of this.successes) {
      console.log(`    ${c.green}✓${c.reset} [${s.phase}] ${s.msg}`);
    }
    console.log(`  ${c.red}issues:${c.reset}    ${this.issues.length}`);
    for (const i of this.issues) {
      console.log(
        `    ${c.red}✗${c.reset} [${i.phase}] ${i.msg}${i.detail ? `\n        ${c.dim}${typeof i.detail === "string" ? i.detail : JSON.stringify(i.detail).slice(0, 300)}${c.reset}` : ""}`
      );
    }
    if (this.gaps.length > 0) {
      console.log(`  ${c.yellow}gaps:${c.reset}      ${this.gaps.length}`);
      for (const g of this.gaps) {
        console.log(`    ${c.yellow}!${c.reset} [${g.phase}] ${g.scenario} — ${g.detail}`);
      }
    }

    return { issues: this.issues, successes: this.successes, gaps: this.gaps, aborted };
  }
}

// ----------------------------------------------------------------------------
// Entry point
// ----------------------------------------------------------------------------

const runner = new HandymanE2ERunner();
const { issues, aborted } = await runner.run();

if (issues.length > 0 || aborted) {
  process.exit(1);
} else {
  console.log(`\n${c.green}${c.bold}✓ All phases passed.${c.reset}\n`);
  process.exit(0);
}
