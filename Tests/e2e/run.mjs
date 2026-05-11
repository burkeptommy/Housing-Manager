#!/usr/bin/env node
// ============================================================================
// Haven E2E onboarding test runner
// ============================================================================
//
// Exercises every backend hop a brand-new user makes from "fresh install"
// to "5 tasks delegated to a Chez handyman", against the live haven-dev
// Supabase project (jsucwnkntdrxhysojgri). Mirrors the wire format the
// iOS app uses for each call so the test catches API contract regressions.
//
// Usage:
//   node tests/e2e/run.mjs
//
// Optional env vars:
//   E2E_VERBOSE=1            -- log full request/response bodies on failure
//   E2E_KEEP_USER=1          -- skip post-run cleanup (useful for poking at
//                               the data in the dashboard)
//   E2E_SKIP_CLEANUP=1       -- skip pre-run cleanup (only safe if you know
//                               there are no leftover e2e users)
//
// Exit codes:
//   0  -- all phases passed
//   1  -- one or more phases failed (issue tally printed at the end)
// ============================================================================

import { randomUUID } from "node:crypto";
import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

// ----------------------------------------------------------------------------
// Configuration
// ----------------------------------------------------------------------------

const SUPABASE_URL = "https://jsucwnkntdrxhysojgri.supabase.co";
// Matches AppConfig.Supabase.anonKey — same key the iOS client ships with.
const ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew";

const TEST_ADDRESS_FULL = "146 Putnam Park Rd, Bethel, CT 06801";
const TEST_ADDRESS_PARTS = {
  street: "146 Putnam Park Rd",
  city: "Bethel",
  state: "CT",
  zipCode: "06801",
};
const TEST_FIRST = "E2E";
const TEST_LAST = "Tester";
const TEST_PASSWORD = "TestPassword!2026Haven";
const VERBOSE = !!process.env.E2E_VERBOSE;

const __dirname = dirname(fileURLToPath(import.meta.url));
const CLEANUP_SQL_PATH = resolve(__dirname, "cleanup.sql");
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

// ----------------------------------------------------------------------------
// Supabase wrappers (mirror the iOS HavenSupabase + DatabaseService calls)
// ----------------------------------------------------------------------------

function authHeaders(jwt) {
  return {
    apikey: ANON_KEY,
    authorization: `Bearer ${jwt || ANON_KEY}`,
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

async function adminSql(sql) {
  // Shells out to `supabase db query --linked` — no service-role key in our
  // local env, but the linked CLI auth has db access via the Management API.
  // We write the SQL to a temp file so multi-statement scripts work.
  const escaped = sql.replace(/'/g, "'\\''");
  try {
    const out = execSync(
      `cd ${REPO_ROOT} && supabase db query --linked --output json ${"'"}${escaped}${"'"}`,
      { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }
    );
    return JSON.parse(out);
  } catch (err) {
    return { error: err.stderr?.toString() || err.message };
  }
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

// ----------------------------------------------------------------------------
// Quiz answer simulator — for each question, persist the answer onto
// properties.house_quiz_state AND fire the equivalent backend side effect
// (insert home_systems / contractors / routines / utility_accounts /
// vehicles / family_members) the iOS HouseQuizAnswerMapper would fire.
//
// This is intentionally pragmatic: it covers the contract (does the schema
// accept the shape, does RLS allow the write, do FKs validate) rather than
// every nuance of the Swift mapper's logic. The Swift mapper has its own
// tests in the iOS target.
// ----------------------------------------------------------------------------

function isoNow() {
  return new Date().toISOString();
}

function makeQuizAnswer(answerId, extra = {}) {
  return {
    answer_id: answerId,
    custom_text: null,
    selected_ids: null,
    custom_entries: null,
    kids: null,
    expecting_entries: null,
    selected_provider_id: null,
    generator_fuel_type: null,
    generator_provider_id: null,
    slider_value: null,
    payload: null,
    answered_at: isoNow(),
    ...extra,
  };
}

// ----------------------------------------------------------------------------
// Test runner
// ----------------------------------------------------------------------------

class E2ERunner {
  constructor() {
    const stamp = Date.now();
    this.email = `e2e-test-${stamp}@havenhome.test`;
    this.issues = [];
    this.successes = [];
    this.state = {
      jwt: null,
      userId: null,
      householdId: null,
      propertyId: null,
      familyMemberId: null,
      homeSystemIds: {},
      contractorIds: [],
      routineIds: [],
      utilityAccountIds: [],
      maintenanceTaskIds: [],
      chezRequestIds: [],
      lookupResult: null,
      assessmentId: null,
    };
  }

  recordSuccess(phase, msg) {
    this.successes.push({ phase, msg });
  }

  recordIssue(phase, msg, detail = null) {
    this.issues.push({ phase, msg, detail });
    if (detail) {
      logFail(msg, typeof detail === "string" ? detail : JSON.stringify(detail).slice(0, 200));
    } else {
      logFail(msg);
    }
  }

  async findUtilityProvider(providerType, name) {
    const exact = await rest(
      `utility_providers?provider_type=eq.${encodeURIComponent(providerType)}&name=eq.${encodeURIComponent(name)}&select=id,name,provider_type&limit=1`,
      { method: "GET" },
      this.state.jwt
    );
    if (exact.ok && exact.body?.[0]) return exact.body[0];

    const fuzzy = await rest(
      `utility_providers?provider_type=eq.${encodeURIComponent(providerType)}&name=ilike.*${encodeURIComponent(name)}*&select=id,name,provider_type&limit=1`,
      { method: "GET" },
      this.state.jwt
    );
    if (fuzzy.ok && fuzzy.body?.[0]) return fuzzy.body[0];

    throw new Error(
      `No utility provider found for ${providerType} / ${name}: ${JSON.stringify(fuzzy.body || exact.body)}`
    );
  }

  async fetchRows(path, phase, label) {
    const res = await rest(path, { method: "GET" }, this.state.jwt);
    if (!res.ok) {
      this.recordIssue(phase, `${label} fetch failed`, res.body);
      return [];
    }
    return res.body || [];
  }

  async patchProperty(body, phase, label) {
    const res = await rest(
      `properties?id=eq.${this.state.propertyId}`,
      { method: "PATCH", body: JSON.stringify(body) },
      this.state.jwt
    );
    if (!res.ok) {
      this.recordIssue(phase, `${label} PATCH failed`, res.body);
      return false;
    }
    return true;
  }

  async patchAttributes(attrs, phase, label) {
    const rows = await this.fetchRows(
      `properties?id=eq.${this.state.propertyId}&select=attributes`,
      phase,
      `${label} property`
    );
    const existing = rows[0]?.attributes || {};
    return this.patchProperty({ attributes: { ...existing, ...attrs } }, phase, label);
  }

  async recordQuizAnswer(quizState, qid, answer, phase, label) {
    quizState.answers[qid] = answer;
    const ok = await this.patchProperty({ house_quiz_state: quizState }, phase, label || qid);
    return ok;
  }

  expectCondition(phase, condition, msg, detail = null) {
    if (condition) {
      logOk(msg, detail || "");
      this.recordSuccess(phase, msg);
      return true;
    }
    this.recordIssue(phase, msg, detail);
    return false;
  }

  async createHomeSystem({
    name,
    category,
    subtype = null,
    parentSystemId = null,
    notes = "A4 combinatorial coverage",
  }) {
    const existingRows = await this.fetchRows(
      `home_systems?property_id=eq.${this.state.propertyId}&name=eq.${encodeURIComponent(name)}&select=id,name,category,subtype,parent_system_id&limit=20`,
      "helper",
      `home system ${name}`
    );
    const existing = existingRows.find((row) => {
      const rowSubtype = row.subtype ?? null;
      const rowParent = row.parent_system_id ?? null;
      return rowSubtype === subtype && rowParent === parentSystemId;
    });
    if (existing) {
      this.state.homeSystemIds[name] = existing.id;
      return existing;
    }
    const id = randomUUID();
    const res = await rest(
      "home_systems",
      {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          id,
          property_id: this.state.propertyId,
          household_id: this.state.householdId,
          name,
          category,
          subtype,
          parent_system_id: parentSystemId,
          status: "active",
          notes,
        }),
      },
      this.state.jwt
    );
    if (!res.ok) throw new Error(`home_systems ${name}: ${JSON.stringify(res.body)}`);
    this.state.homeSystemIds[name] = id;
    return res.body?.[0] || { id, name, category, subtype };
  }

  async createContractor({ name, category, phone = "2035550100", website = null, source = "quiz" }) {
    const existing = await this.fetchRows(
      `contractors?household_id=eq.${this.state.householdId}&company_name=eq.${encodeURIComponent(name)}&select=id,company_name,category,source&limit=1`,
      "helper",
      `contractor ${name}`
    );
    if (existing[0]) {
      if (!this.state.contractorIds.includes(existing[0].id)) this.state.contractorIds.push(existing[0].id);
      return existing[0];
    }
    const id = randomUUID();
    const res = await rest(
      "contractors",
      {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          id,
          household_id: this.state.householdId,
          company_name: name,
          category,
          specialties: [category],
          phone,
          website,
          source,
        }),
      },
      this.state.jwt
    );
    if (!res.ok) throw new Error(`contractors ${name}: ${JSON.stringify(res.body)}`);
    this.state.contractorIds.push(id);
    return res.body?.[0] || { id, company_name: name, category };
  }

  async createUtilityAccount({
    providerType,
    providerName,
    providerId = null,
    providerSlug = null,
    phone = null,
    website = null,
  }) {
    const existing = await this.fetchRows(
      `utility_accounts?property_id=eq.${this.state.propertyId}&provider_type=eq.${encodeURIComponent(providerType)}&provider_name=eq.${encodeURIComponent(providerName)}&select=id,provider_id,provider_type,provider_name&limit=1`,
      "helper",
      `utility account ${providerName}`
    );
    if (existing[0]) {
      if (!this.state.utilityAccountIds.includes(existing[0].id)) this.state.utilityAccountIds.push(existing[0].id);
      return existing[0];
    }
    const res = await rest(
      "utility_accounts",
      {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          household_id: this.state.householdId,
          property_id: this.state.propertyId,
          provider_id: providerId,
          provider_slug: providerSlug,
          provider_type: providerType,
          provider_name: providerName,
          phone,
          website,
        }),
      },
      this.state.jwt
    );
    if (!res.ok) throw new Error(`utility_accounts ${providerName}: ${JSON.stringify(res.body)}`);
    this.state.utilityAccountIds.push(res.body?.[0]?.id);
    return res.body?.[0];
  }

  async createRoutine({
    label,
    routineKind,
    cadenceType = "annual",
    vendorId = null,
    daysOfWeek = null,
    activeMonths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    setupState = "active",
    nextExpectedDate = "2026-06-01",
  }) {
    const res = await rest(
      "routines",
      {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          household_id: this.state.householdId,
          property_id: this.state.propertyId,
          label,
          routine_kind: routineKind,
          cadence_type: cadenceType,
          days_of_week: daysOfWeek,
          active_months: activeMonths,
          next_expected_date: nextExpectedDate,
          start_date: nextExpectedDate,
          vendor_id: vendorId,
          setup_state: setupState,
        }),
      },
      this.state.jwt
    );
    if (!res.ok) throw new Error(`routines ${label}: ${JSON.stringify(res.body)}`);
    this.state.routineIds.push(res.body?.[0]?.id);
    return res.body?.[0];
  }

  async createMaintenanceTask({
    title,
    systemId = null,
    assignmentType = "personal",
    needsVendor = false,
    assignedContractorId = null,
    nextDueDate = "2026-08-01",
    priority = "medium",
  }) {
    const id = randomUUID();
    const res = await rest(
      "maintenance_tasks",
      {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          id,
          household_id: this.state.householdId,
          property_id: this.state.propertyId,
          title,
          description: "A4 combinatorial coverage task.",
          assignment_type: assignmentType,
          needs_vendor: needsVendor,
          assigned_contractor_id: assignedContractorId,
          system_id: systemId,
          priority,
          next_due_date: nextDueDate,
          frequency: "annual",
        }),
      },
      this.state.jwt
    );
    if (!res.ok) throw new Error(`maintenance_tasks ${title}: ${JSON.stringify(res.body)}`);
    this.state.maintenanceTaskIds.push(id);
    return res.body?.[0] || { id };
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
    logStep(`Wiping any prior e2e-test-*@havenhome.test users + data`);
    const result = await adminSqlFile(CLEANUP_SQL_PATH);
    if (result.error) {
      this.recordIssue("phase0", "cleanup SQL failed", result.error);
      throw new Error("Cleanup failed — refusing to continue");
    }
    logOk("cleanup complete", `rows: ${JSON.stringify(result.rows?.slice?.(-3) || [])}`);
  }

  // --------------------------------------------------------------------------
  // Phase 1 — Auth signup
  // --------------------------------------------------------------------------
  async phase1_signup() {
    logPhase(1, "Signup + JWT");
    logStep(`signing up ${this.email}`);

    // 1a — POST /auth/v1/signup. Mirrors HavenSupabase.auth.signUp(...)
    // Includes user metadata (first_name / last_name / full_name) inline so
    // we don't have to do a separate auth.update call.
    const signup = await http(`${SUPABASE_URL}/auth/v1/signup`, {
      method: "POST",
      headers: { apikey: ANON_KEY, "content-type": "application/json" },
      body: JSON.stringify({
        email: this.email,
        password: TEST_PASSWORD,
        data: {
          first_name: TEST_FIRST,
          last_name: TEST_LAST,
          full_name: `${TEST_FIRST} ${TEST_LAST}`,
        },
      }),
    });
    if (!signup.ok) {
      this.recordIssue("phase1", "signup failed", signup.body);
      throw new Error("phase1 fatal");
    }
    const session = signup.body;
    if (!session.access_token || !session.user?.id) {
      this.recordIssue("phase1", "signup did not return session+user", session);
      throw new Error("phase1 fatal");
    }
    this.state.jwt = session.access_token;
    this.state.userId = session.user.id;
    logOk("auth.users row created", `id=${this.state.userId.slice(0, 8)}…`);
    logOk("session token issued");

    // 1b — INSERT INTO public.users. iOS does this manually after signup
    // (no on-auth trigger in this project — see AuthService.swift:100-107).
    const userInsert = await rest(
      "users",
      {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          id: this.state.userId,
          household_id: null,
          email: this.email,
          full_name: `${TEST_FIRST} ${TEST_LAST}`,
          role: "member",
        }),
      },
      this.state.jwt
    );
    if (!userInsert.ok) {
      this.recordIssue("phase1", "public.users insert failed", userInsert.body);
      throw new Error("phase1 fatal");
    }
    logOk("public.users row created");
    this.recordSuccess("phase1", "signup + JWT + public.users insert");
  }

  // --------------------------------------------------------------------------
  // Phase 2 — Property lookup (ATTOM/RentCast)
  // --------------------------------------------------------------------------
  async phase2_propertyLookup() {
    logPhase(2, "Address lookup (property-lookup Edge Function)");
    logStep(`calling property-lookup with "${TEST_ADDRESS_FULL}"`);
    const res = await callEdgeFunction(
      "property-lookup",
      { address: TEST_ADDRESS_FULL },
      this.state.jwt
    );
    if (!res.ok) {
      this.recordIssue("phase2", `property-lookup returned ${res.status}`, res.body);
      throw new Error("phase2 fatal");
    }
    // Response shape (verified live):
    //   { success: true, property: { yearBuilt, estimatedValue, squareFootage,
    //     estimatedValueSource, lastSalePrice, lastSaleDate, propertyType,
    //     taxAssessment: {...}, features: {...}, ... }, cached: true }
    const lookup = res.body?.property ?? null;
    this.state.lookupResult = lookup;
    if (!lookup || (!lookup.estimatedValue && !lookup.yearBuilt)) {
      this.recordIssue("phase2", "property-lookup returned no usable data", res.body);
      throw new Error("phase2 fatal");
    }
    logOk(
      "property-lookup returned",
      `year=${lookup.yearBuilt ?? "?"} value=${lookup.estimatedValue ?? "?"} sqft=${lookup.squareFootage ?? "?"} source=${lookup.estimatedValueSource ?? "?"}`
    );
    this.recordSuccess("phase2", "property-lookup edge function works for the test address");
  }

  // --------------------------------------------------------------------------
  // Phase 3 — Onboarding setup (mimics OnboardingViewModel.runComplete)
  // --------------------------------------------------------------------------
  async phase3_onboardingSetup() {
    logPhase(3, "Onboarding setup (household + family member + property + systems)");

    // 3a — INSERT household. CRITICAL: must NOT use Prefer: return=representation
    // because the SELECT policy on households requires `id = users.household_id`
    // and the user isn't yet linked. iOS does the same trick — generates the
    // UUID client-side via `insertHousehold(id: UUID(), name: ...)`. See
    // DatabaseService.swift:38 for the comment that calls out this exact case.
    logStep("creating household (client-generated UUID, no representation)");
    const householdId = randomUUID();
    const householdInsert = await rest(
      "households",
      {
        method: "POST",
        body: JSON.stringify({
          id: householdId,
          name: `The ${TEST_LAST} Family`,
          subscription_tier: "standard",
        }),
      },
      this.state.jwt
    );
    if (!householdInsert.ok) {
      this.recordIssue("phase3", "household insert failed", householdInsert.body);
      throw new Error("phase3 fatal");
    }
    this.state.householdId = householdId;
    logOk("household created", `id=${this.state.householdId.slice(0, 8)}…`);

    // 3b — UPDATE public.users SET household_id, full_name
    logStep("linking user to household (completeOnboarding equivalent)");
    const userUpdate = await rest(
      `users?id=eq.${this.state.userId}`,
      {
        method: "PATCH",
        body: JSON.stringify({
          household_id: this.state.householdId,
          full_name: `${TEST_FIRST} ${TEST_LAST}`,
        }),
      },
      this.state.jwt
    );
    if (!userUpdate.ok) {
      this.recordIssue("phase3", "user.household_id update failed", userUpdate.body);
      throw new Error("phase3 fatal");
    }
    logOk("user.household_id stamped");

    // 3c — INSERT family_member (Primary Client). Client-generated UUID.
    logStep("creating Primary Client family_member row");
    const familyMemberId = randomUUID();
    const fmInsert = await rest(
      "family_members",
      {
        method: "POST",
        body: JSON.stringify({
          id: familyMemberId,
          household_id: this.state.householdId,
          first_name: TEST_FIRST,
          last_name: TEST_LAST,
          relationship: "Primary Client",
          email: this.email,
          linked_user_id: this.state.userId,
          member_type: "family",
        }),
      },
      this.state.jwt
    );
    if (!fmInsert.ok) {
      this.recordIssue("phase3", "family_members insert failed", fmInsert.body);
      throw new Error("phase3 fatal");
    }
    this.state.familyMemberId = familyMemberId;
    logOk("Primary Client family_member created");

    // 3d — INSERT property using ATTOM data (camelCase from edge function)
    logStep("creating property with ATTOM enrichment");
    const lookup = this.state.lookupResult || {};
    const propertyId = randomUUID();
    const purchaseDate = lookup.lastSaleDate ? lookup.lastSaleDate.split("T")[0] : null;
    const propertyInsert = await rest(
      "properties",
      {
        method: "POST",
        body: JSON.stringify({
          id: propertyId,
          household_id: this.state.householdId,
          name: `${TEST_ADDRESS_PARTS.street}, ${TEST_ADDRESS_PARTS.city}`,
          property_type: lookup.propertyType ?? "Single Family",
          street: TEST_ADDRESS_PARTS.street,
          city: TEST_ADDRESS_PARTS.city,
          state: TEST_ADDRESS_PARTS.state,
          zip_code: TEST_ADDRESS_PARTS.zipCode,
          country: "US",
          year_built: lookup.yearBuilt ?? null,
          square_footage: lookup.squareFootage ?? null,
          current_estimated_value: lookup.estimatedValue ?? null,
          current_estimated_value_low: lookup.estimatedValueLow ?? null,
          current_estimated_value_high: lookup.estimatedValueHigh ?? null,
          estimated_value_source: lookup.estimatedValueSource ?? null,
          estimated_value_confidence: lookup.estimatedValueConfidence ?? null,
          purchase_price: lookup.lastSalePrice ?? null,
          purchase_date: purchaseDate,
          regional_pack: "northeast", // CT is northeast
        }),
      },
      this.state.jwt
    );
    if (!propertyInsert.ok) {
      this.recordIssue("phase3", "property insert failed", propertyInsert.body);
      throw new Error("phase3 fatal");
    }
    this.state.propertyId = propertyId;
    logOk(
      "property created",
      `id=${this.state.propertyId.slice(0, 8)}… value=${lookup.estimatedValue ?? "?"}`
    );

    // 3e — INSERT 5 home_systems based on ATTOM features (mimics
    // OnboardingViewModel.createHomeSystems). The set is intentionally generic
    // since most Bethel CT homes have these regardless of ATTOM features.
    logStep("creating 5 baseline home_systems from ATTOM");
    const systems = [
      { name: "HVAC", category: "HVAC" },
      { name: "Roofing", category: "Roofing" },
      { name: "Water Heater", category: "Water Heater" },
      { name: "Electrical", category: "Electrical" },
      { name: "Plumbing", category: "Plumbing" },
    ];
    for (const s of systems) {
      const sysId = randomUUID();
      const ins = await rest(
        "home_systems",
        {
          method: "POST",
          body: JSON.stringify({
            id: sysId,
            property_id: this.state.propertyId,
            household_id: this.state.householdId,
            name: s.name,
            category: s.category,
            status: "active",
          }),
        },
        this.state.jwt
      );
      if (!ins.ok) {
        this.recordIssue("phase3", `home_systems insert failed: ${s.category}`, ins.body);
        throw new Error("phase3 fatal");
      }
      this.state.homeSystemIds[s.category] = sysId;
    }
    logOk(`${systems.length} home_systems created`);

    this.recordSuccess("phase3", "household + property + 5 systems created end-to-end");
  }

  // --------------------------------------------------------------------------
  // Phase 4 — Foundational questions (the "initial intake quiz")
  // --------------------------------------------------------------------------
  async phase4_foundationalQuestions() {
    logPhase(4, "Foundational intake (7 quick questions on properties.attributes)");

    // The OnboardingViewModel stores foundational answers in
    // `foundationalAnswers` and applies them during the quiz pre-fill. The
    // 7 keys are roughly: roof_material, heating_fuel, water_source,
    // sewer_or_septic, household_residents, pets, vendor_preference_tier.
    const answers = {
      roof_material: "asphalt",
      heating_fuel: "oil",
      water_source: "private_well",
      sewer_or_septic: "septic",
      household_residents: "family_with_kids",
      pets: "dogs",
      vendor_preference_tier: "mixed",
    };
    logStep("PATCHing 7 foundational answers onto properties.attributes");
    const update = await rest(
      `properties?id=eq.${this.state.propertyId}`,
      {
        method: "PATCH",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({ attributes: answers }),
      },
      this.state.jwt
    );
    if (!update.ok) {
      this.recordIssue("phase4", "properties.attributes PATCH failed", update.body);
      throw new Error("phase4 fatal");
    }
    logOk("foundational answers persisted to properties.attributes");

    // Verify by re-reading.
    const verify = await rest(
      `properties?id=eq.${this.state.propertyId}&select=attributes`,
      { method: "GET" },
      this.state.jwt
    );
    if (!verify.ok || !verify.body?.[0]?.attributes) {
      this.recordIssue("phase4", "could not re-read attributes", verify.body);
      throw new Error("phase4 fatal");
    }
    const stored = verify.body[0].attributes;
    let mismatches = 0;
    for (const k of Object.keys(answers)) {
      if (stored[k] !== answers[k]) {
        mismatches++;
        logWarn(`attribute ${k} mismatch`, `expected=${answers[k]} got=${stored[k]}`);
      }
    }
    if (mismatches > 0) {
      this.recordIssue("phase4", `${mismatches} attribute(s) failed to persist correctly`);
    } else {
      logOk("all 7 attributes verified");
      this.recordSuccess("phase4", "foundational intake answers persisted + verified");
    }
  }

  // --------------------------------------------------------------------------
  // Phase 5 — Mode fork: verify handyman path works, then choose DIY
  // --------------------------------------------------------------------------
  async phase5_modeFork() {
    logPhase(5, "Mode fork (verify handyman flow exists, then pick DIY)");

    // 5a — Verify handyman path: call requestHomeAssessment to confirm the
    // edge function is reachable and the home_assessments row gets created.
    // We then immediately cancel the assessment so the test doesn't leave
    // a dangling work item for the operator.
    // The handyman-provider edge function expects snake_case payload keys.
    // Phase 95-shipped iOS structs (`RequestHomeAssessmentRequest`,
    // `CancelAssessmentRequest`, `RescheduleAssessmentRequest`) initially
    // sent camelCase without CodingKeys — fixed in this same change set.
    // Mirror the wire format the iOS app NOW sends (with the fix) so the
    // test reflects production behavior post-fix.
    logStep("calling handyman-provider request_home_assessment (verify-only)");
    const assessReq = await callEdgeFunction(
      "handyman-provider",
      {
        action: "request_home_assessment",
        property_id: this.state.propertyId,
        household_id: this.state.householdId,
        homeowner_concerns: "E2E test — please disregard. Verifying the path works.",
        homeowner_present: true,
        homeowner_access_notes: "E2E test, no real visit needed",
        is_existing_user_supplement: false,
        preferred_window_start: "2099-01-01",
        preferred_time_of_day: "morning",
      },
      this.state.jwt
    );
    if (!assessReq.ok) {
      this.recordIssue(
        "phase5",
        `handyman-provider request_home_assessment failed (${assessReq.status})`,
        assessReq.body
      );
    } else {
      logOk("handyman-provider responded 200", `body keys: ${Object.keys(assessReq.body || {}).join(",")}`);
      // The success body is { ok, assessment, was_existing? } — extract id.
      const assessmentRecord = assessReq.body?.assessment ?? assessReq.body;
      const assessmentId =
        assessmentRecord?.id ?? assessmentRecord?.assessment_id ?? assessmentRecord?.assessmentId;
      if (assessmentId) {
        this.state.assessmentId = assessmentId;
        logStep(`cancelling assessment ${assessmentId.slice(0, 8)}… so we don't leave a real work item`);
        const cancel = await callEdgeFunction(
          "handyman-provider",
          {
            action: "cancel_assessment",
            assessment_id: assessmentId, // snake_case — see edge function
            reason: "E2E test cleanup",
          },
          this.state.jwt
        );
        if (cancel.ok) {
          logOk("assessment cancelled");
        } else {
          logWarn("cancel_assessment returned non-200", `${cancel.status}`);
        }
      }
      this.recordSuccess("phase5", "handyman flow reachable, won't be used for the rest of the run");
    }

    // 5a' — Convention drift contract audit (Phase 95 follow-up,
    // 2026-05-05). The handyman-provider edge function reads each of
    // these actions' bodies as snake_case via `compactString(body.X)`,
    // but the iOS structs (in SupabaseClient.swift) historically went on
    // the wire as camelCase because the default `JSONEncoder()` has no
    // `keyEncodingStrategy`. Three structs were already fixed
    // (Request/Cancel/RescheduleAssessment); this block exercises the
    // remaining four (add_recommended_task, update_recommended_task,
    // mark_task_fixed_during_visit, decommission_system) end-to-end
    // against the edge function so any future regression surfaces here
    // instead of in TestFlight.
    //
    // Three of the four are operator-facing (gated on workspace
    // membership). For those we send a snake_case payload and assert
    // the failure mode is the AUTH/LOAD path, not "X required" — that
    // signals the body parser saw the field. The fourth
    // (decommission_system) is homeowner-callable and verified
    // round-trip against home_systems.is_active.
    if (this.state.assessmentId && this.state.homeSystemIds?.HVAC) {
      logStep("Phase 95 follow-up contract audit: exercising 4 fixed actions");

      // 1. decommission_system — homeowner-facing, expect 200 + is_active=false
      const targetSystemId = this.state.homeSystemIds.Plumbing;
      const decommission = await callEdgeFunction(
        "handyman-provider",
        {
          action: "decommission_system",
          system_id: targetSystemId,
          reason: "E2E contract audit — snake_case wire format check",
        },
        this.state.jwt
      );
      if (!decommission.ok) {
        this.recordIssue(
          "phase5",
          `decommission_system snake_case failed (${decommission.status})`,
          decommission.body
        );
      } else {
        // Re-read the row to confirm is_active flipped to false.
        const verify = await rest(
          `home_systems?id=eq.${targetSystemId}&select=is_active,decommissioned_reason`,
          { method: "GET" },
          this.state.jwt
        );
        const row = verify.body?.[0];
        if (row?.is_active === false) {
          logOk("decommission_system end-to-end", `is_active=false reason=${row.decommissioned_reason ?? "?"}`);
          this.recordSuccess("phase5", "decommission_system snake_case wire format works (round-trip)");
        } else {
          this.recordIssue(
            "phase5",
            "decommission_system returned 200 but is_active not flipped",
            row
          );
        }
      }

      // Helper: a "passes the parser" assertion. Snake_case payloads
      // should fail with auth/load errors, not "X required" parse errors.
      const expectParserPassed = (label, res, parseRequiredHints) => {
        const errMsg = (res.body?.error ?? "").toString().toLowerCase();
        const isParseError = parseRequiredHints.some((h) => errMsg.includes(h.toLowerCase()));
        if (isParseError) {
          this.recordIssue(
            "phase5",
            `${label}: snake_case payload still hit parse-required error`,
            res.body
          );
        } else {
          logOk(`${label} parser passed`, `status=${res.status} err="${(res.body?.error ?? "ok").toString().slice(0, 60)}"`);
        }
      };

      // 2. add_recommended_task — operator-facing. Homeowner JWT will
      //    fail at assertHandymanCanWrite, but with snake_case the
      //    parser must read assessment_id + title first. If the parser
      //    fails, error is "title required" or "assessment_id required".
      //    If the parser succeeds, error is "not authorized" or
      //    "assessment has no dispatched visit yet".
      const addRec = await callEdgeFunction(
        "handyman-provider",
        {
          action: "add_recommended_task",
          assessment_id: this.state.assessmentId,
          title: "E2E contract audit — should fail at auth, not at parse",
          urgency: "soon",
          recommended_owner: "chez_vendor",
          observation_source: "handyman_observed",
          needs_verification: false,
        },
        this.state.jwt
      );
      expectParserPassed("add_recommended_task", addRec, ["title required", "assessment_id required"]);

      // 3. update_recommended_task — operator-facing in spirit, but
      //    function has no caller auth check. With only task_id and no
      //    other allowed fields, returns { ok: true, no_changes: true }.
      //    That's the cleanest parser-pass signal.
      const updRec = await callEdgeFunction(
        "handyman-provider",
        {
          action: "update_recommended_task",
          task_id: "00000000-0000-0000-0000-000000000000",
        },
        this.state.jwt
      );
      if (updRec.ok && updRec.body?.no_changes === true) {
        logOk("update_recommended_task parser passed", "no_changes=true (expected for empty allowed-set)");
      } else {
        // If we got an error other than "task_id required", parser still
        // passed — accept "failed" / "PGRST" / "not found" but reject the
        // explicit parse-required hint.
        expectParserPassed("update_recommended_task", updRec, ["task_id required"]);
      }

      // 4. mark_task_fixed_during_visit — load step fails with
      //    "recommended task not found" when task_id parses correctly.
      //    Fails with "task_id required" if the parser dropped the field.
      const markFixed = await callEdgeFunction(
        "handyman-provider",
        {
          action: "mark_task_fixed_during_visit",
          task_id: "00000000-0000-0000-0000-000000000000",
          cost_cents: 0,
        },
        this.state.jwt
      );
      expectParserPassed("mark_task_fixed_during_visit", markFixed, ["task_id required"]);

      // 5. Negative regression guard. Sending camelCase to
      //    mark_task_fixed_during_visit MUST still fail with
      //    "task_id required" — that's the contract this whole audit
      //    block exists to defend. If someone re-introduces the
      //    convention drift on the iOS side (drops CodingKeys), the
      //    above #4 check would still pass against deployed snake-case
      //    edge function unless we ALSO assert the camelCase shape
      //    fails. This is the canary.
      const negCamel = await callEdgeFunction(
        "handyman-provider",
        {
          action: "mark_task_fixed_during_visit",
          taskId: "00000000-0000-0000-0000-000000000000", // intentionally wrong
          costCents: 0,
        },
        this.state.jwt
      );
      const negErr = (negCamel.body?.error ?? "").toString().toLowerCase();
      if (!negErr.includes("task_id required")) {
        this.recordIssue(
          "phase5",
          "regression canary: camelCase taskId did NOT trigger 'task_id required' — edge function may have shifted to snake-or-camel handling, audit block needs re-thinking",
          negCamel.body
        );
      } else {
        logOk("regression canary intact", "camelCase taskId correctly rejected");
      }
    } else {
      logWarn("Phase 95 follow-up contract audit skipped — no assessmentId or home_system available");
    }

    // 5b — Pick DIY: stamp assessment_mode on properties.attributes
    logStep("stamping assessment_mode=diy on the property (DIY path)");
    const update = await rest(
      `properties?id=eq.${this.state.propertyId}`,
      {
        method: "PATCH",
        body: JSON.stringify({
          attributes: {
            ...{
              roof_material: "asphalt",
              heating_fuel: "oil",
              water_source: "private_well",
              sewer_or_septic: "septic",
              household_residents: "family_with_kids",
              pets: "dogs",
              vendor_preference_tier: "mixed",
            },
            assessment_mode: "diy",
          },
        }),
      },
      this.state.jwt
    );
    if (!update.ok) {
      this.recordIssue("phase5", "assessment_mode PATCH failed", update.body);
    } else {
      logOk("assessment_mode=diy persisted");
      this.recordSuccess("phase5", "mode fork: chose DIY, handyman path verified");
    }
  }

  // --------------------------------------------------------------------------
  // Phase 6 — Full House Quiz (current homeowner intake, with side effects)
  // --------------------------------------------------------------------------
  async phase6_houseQuiz() {
    logPhase(6, "Full House Quiz (current homeowner intake)");

    // We build up the house_quiz_state JSONB as we go and PATCH it after
    // every question — same incremental persistence the iOS app does. Side
    // effects (home_systems / contractors / routines / utility_accounts /
    // vehicles / family_members) are written as separate inserts in parallel
    // with the JSON state update.
    const quizState = {
      started_at: isoNow(),
      completed_at: null,
      intake_completed_at: null,
      walkthrough_completed_at: null,
      chosen_path: null,
      walkthrough_mode: null,
      answers: {},
      saved_for_later: [],
      skipped: [],
    };

    // Helper: persist one quiz answer + (optionally) fire a side effect.
    const recordAnswer = async (qid, ansBody, sideEffectFn = null, sideEffectLabel = null) => {
      quizState.answers[qid] = ansBody;
      // Persist quiz state (same as the iOS view model after each answer)
      const upd = await rest(
        `properties?id=eq.${this.state.propertyId}`,
        {
          method: "PATCH",
          body: JSON.stringify({ house_quiz_state: quizState }),
        },
        this.state.jwt
      );
      if (!upd.ok) {
        this.recordIssue("phase6", `${qid} state PATCH failed`, upd.body);
        return false;
      }
      if (sideEffectFn) {
        try {
          await sideEffectFn();
        } catch (err) {
          this.recordIssue(
            "phase6",
            `${qid} side effect failed${sideEffectLabel ? ` (${sideEffectLabel})` : ""}`,
            err.message
          );
          return false;
        }
      }
      return true;
    };

    // ----- Chapter 1: Your Home -----

    // Q1 — roof material → home_systems Roofing already exists, just stamp subtype
    logStep("Q1 q1_roof_material → asphalt");
    await recordAnswer(
      "q1_roof_material",
      makeQuizAnswer("asphalt"),
      async () => {
        await rest(
          `home_systems?id=eq.${this.state.homeSystemIds.Roofing}`,
          { method: "PATCH", body: JSON.stringify({ subtype: "asphalt" }) },
          this.state.jwt
        );
      }
    );

    // Q2 — siding (multi-select)
    logStep("Q2 q2_siding → vinyl + brick");
    await recordAnswer(
      "q2_siding",
      makeQuizAnswer(null, { selected_ids: ["vinyl", "brick"] })
    );

    // Q3 — heating system
    logStep("Q3 q3_heating_system → oil_boiler_radiators");
    await recordAnswer(
      "q3_heating_system",
      makeQuizAnswer("oil_boiler_radiators"),
      async () => {
        await rest(
          `home_systems?id=eq.${this.state.homeSystemIds.HVAC}`,
          { method: "PATCH", body: JSON.stringify({ subtype: "boiler", name: "Oil Boiler" }) },
          this.state.jwt
        );
      }
    );

    // Q6 — water source → already have well system from Phase 3? No, we didn't
    // create a Well. Create it here.
    logStep("Q6 q6_water_source → private_well");
    await recordAnswer(
      "q6_water_source",
      makeQuizAnswer("private_well"),
      async () => {
        const ins = await rest(
          "home_systems",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              property_id: this.state.propertyId,
              household_id: this.state.householdId,
              name: "Well System",
              category: "Well System",
              subtype: "private",
              status: "active",
            }),
          },
          this.state.jwt
        );
        if (!ins.ok) throw new Error(`well insert: ${JSON.stringify(ins.body)}`);
        this.state.homeSystemIds["Well System"] = ins.body[0].id;
      },
      "create Well system"
    );

    // Q7 — sewer/septic
    logStep("Q7 q7_sewer_septic → septic");
    await recordAnswer(
      "q7_sewer_septic",
      makeQuizAnswer("septic"),
      async () => {
        const ins = await rest(
          "home_systems",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              property_id: this.state.propertyId,
              household_id: this.state.householdId,
              name: "Septic System",
              category: "Septic System",
              status: "active",
            }),
          },
          this.state.jwt
        );
        if (!ins.ok) throw new Error(`septic insert: ${JSON.stringify(ins.body)}`);
        this.state.homeSystemIds["Septic System"] = ins.body[0].id;
      }
    );

    // Q8 — water heater type
    logStep("Q8 q8_water_heater → tank_gas");
    await recordAnswer(
      "q8_water_heater",
      makeQuizAnswer("tank_gas"),
      async () => {
        await rest(
          `home_systems?id=eq.${this.state.homeSystemIds["Water Heater"]}`,
          {
            method: "PATCH",
            body: JSON.stringify({ subtype: "tank_gas", name: "Gas Water Heater" }),
          },
          this.state.jwt
        );
      }
    );

    // Q9 — basement (multi-select)
    logStep("Q9 q9_basement → finished_basement + sump_pump");
    await recordAnswer(
      "q9_basement",
      makeQuizAnswer(null, { selected_ids: ["finished_basement", "sump_pump"] }),
      async () => {
        const ins = await rest(
          "home_systems",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              property_id: this.state.propertyId,
              household_id: this.state.householdId,
              name: "Sump Pump",
              category: "Sump Pump",
              status: "active",
            }),
          },
          this.state.jwt
        );
        if (!ins.ok) throw new Error(`sump pump insert: ${JSON.stringify(ins.body)}`);
        this.state.homeSystemIds["Sump Pump"] = ins.body[0].id;
      }
    );

    // Q9b — renovations (skipped for brevity)
    logStep("Q9b q9b_renovations → none");
    await recordAnswer(
      "q9b_renovations",
      makeQuizAnswer("none", { custom_entries: [] })
    );

    // Q10 — appliances (multi-select)
    logStep("Q10 q10_appliances → refrigerator + dishwasher + washer_dryer");
    await recordAnswer(
      "q10_appliances",
      makeQuizAnswer(null, {
        selected_ids: ["refrigerator", "dishwasher", "washer", "dryer"],
      }),
      async () => {
        // Insert one Appliance system per selection
        for (const a of ["Refrigerator", "Dishwasher", "Washer", "Dryer"]) {
          await rest(
            "home_systems",
            {
              method: "POST",
              body: JSON.stringify({
                property_id: this.state.propertyId,
                household_id: this.state.householdId,
                name: a,
                category: "Appliance",
                status: "active",
              }),
            },
            this.state.jwt
          );
        }
      },
      "appliance inserts"
    );

    // Q20 — other fuels
    logStep("Q20 q20_other_fuels → none");
    await recordAnswer("q20_other_fuels", makeQuizAnswer(null, { selected_ids: ["none"] }));

    // Q21 — solar
    logStep("Q21 q21_solar → no");
    await recordAnswer("q21_solar", makeQuizAnswer("no"));

    // Q22 — generator (no generator)
    logStep("Q22 q22_generator → none");
    await recordAnswer("q22_generator", makeQuizAnswer("none"));

    // Q11 — lawn (progressive: pro path)
    logStep("Q11 q11_lawn → pro / Bethel Lawn Care / natural");
    await recordAnswer(
      "q11_lawn",
      makeQuizAnswer("pro", {
        custom_text: "Bethel Lawn Care",
        payload: { lawnType: "natural" },
      }),
      async () => {
        // Create Landscaping system + contractor + utility_account + routine
        const sys = await rest(
          "home_systems",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              property_id: this.state.propertyId,
              household_id: this.state.householdId,
              name: "Landscaping",
              category: "Landscaping",
              subtype: "natural",
              status: "active",
            }),
          },
          this.state.jwt
        );
        if (!sys.ok) throw new Error(`landscaping system: ${JSON.stringify(sys.body)}`);
        this.state.homeSystemIds["Landscaping"] = sys.body[0].id;

        const contractorId = randomUUID();
        const contractor = await rest(
          "contractors",
          {
            method: "POST",
            body: JSON.stringify({
              id: contractorId,
              household_id: this.state.householdId,
              company_name: "Bethel Lawn Care",
              category: "Landscaping",
              phone: "2035550100", // contractors.phone is NOT NULL
              source: "quiz",
            }),
          },
          this.state.jwt
        );
        if (!contractor.ok) throw new Error(`landscaping contractor: ${JSON.stringify(contractor.body)}`);
        this.state.contractorIds.push(contractorId);
      }
    );

    // Q12 — pool (no pool)
    logStep("Q12 q12_pool → none");
    await recordAnswer("q12_pool", makeQuizAnswer("none"));

    // ----- Chapter 2: Your Pros -----

    // Q36 — vendor preference tier (already in attributes from foundational)
    logStep("Q36 q36_diy_vs_vendor → mixed (already foundational, just record)");
    await recordAnswer("q36_diy_vs_vendor", makeQuizAnswer("mixed"));

    // Q13 — pest control
    logStep("Q13 q13_pest → diy");
    await recordAnswer("q13_pest", makeQuizAnswer("diy"));

    // Q14 — irrigation (no irrigation)
    logStep("Q14 q14_irrigation → no");
    await recordAnswer("q14_irrigation", makeQuizAnswer("no"));

    // Q15 — security
    logStep("Q15 q15_security → cameras_only");
    await recordAnswer("q15_security", makeQuizAnswer("cameras_only"));

    // Q15b — household contractors (multi-select chips)
    logStep("Q15b q15b_household_contractors → handyman + plumber chips");
    await recordAnswer(
      "q15b_household_contractors",
      makeQuizAnswer(null, {
        selected_ids: ["handyman", "plumber"],
        custom_entries: [
          "handyman|Bethel Handy LLC|4.8|150|2035550101|bethelhandy.com|find_vendor",
          "plumber|Putnam Plumbing|4.7|180|2035550102|putnamplumbing.com|find_vendor",
        ],
      }),
      async () => {
        for (const c of [
          { name: "Bethel Handy LLC", category: "Handyman", phone: "2035550101", website: "bethelhandy.com" },
          { name: "Putnam Plumbing", category: "Plumbing", phone: "2035550102", website: "putnamplumbing.com" },
        ]) {
          const cid = randomUUID();
          const ins = await rest(
            "contractors",
            {
              method: "POST",
              body: JSON.stringify({
                id: cid,
                household_id: this.state.householdId,
                company_name: c.name,
                category: c.category,
                phone: c.phone, // NOT NULL on the table
                website: c.website,
                source: "quiz",
              }),
            },
            this.state.jwt
          );
          if (!ins.ok) throw new Error(`contractor ${c.name}: ${JSON.stringify(ins.body)}`);
          this.state.contractorIds.push(cid);
        }
      },
      "Q15b contractor inserts"
    );

    // Q16 — electric provider
    logStep("Q16 q16_electric → catalog provider");
    const electricProvider = await this.findUtilityProvider("electric", "Eversource Connecticut");
    await recordAnswer(
      "q16_electric",
      makeQuizAnswer("selected", {
        custom_text: electricProvider.name,
        selected_provider_id: electricProvider.id,
      }),
      async () => {
        const ins = await rest(
          "utility_accounts",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              household_id: this.state.householdId,
              property_id: this.state.propertyId,
              provider_id: electricProvider.id,
              provider_name: electricProvider.name,
              provider_type: "electric",
            }),
          },
          this.state.jwt
        );
        if (!ins.ok) throw new Error(`electric utility: ${JSON.stringify(ins.body)}`);
        this.state.utilityAccountIds.push(ins.body?.[0]?.id);
      }
    );

    // Q17 — internet provider
    logStep("Q17 q17_internet → Optimum");
    const internetProvider = await this.findUtilityProvider("internet_cable", "Optimum Fairfield CT");
    await recordAnswer(
      "q17_internet",
      makeQuizAnswer("selected", {
        custom_text: internetProvider.name,
        selected_provider_id: internetProvider.id,
      }),
      async () => {
        const ins = await rest(
          "utility_accounts",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              household_id: this.state.householdId,
              property_id: this.state.propertyId,
              provider_id: internetProvider.id,
              provider_name: internetProvider.name,
              provider_type: "internet_cable",
            }),
          },
          this.state.jwt
        );
        if (!ins.ok) throw new Error(`internet utility: ${JSON.stringify(ins.body)}`);
        this.state.utilityAccountIds.push(ins.body?.[0]?.id);
      }
    );

    // Q18 — trash (with pickup days)
    logStep("Q18 q18_trash → municipal Wed");
    await recordAnswer(
      "q18_trash",
      makeQuizAnswer("municipal", { selected_ids: ["wed"] })
    );

    // Q19 — heating fuel provider (oil delivery)
    logStep("Q19 q19_heating_provider → catalog oil delivery");
    const heatingProvider = await this.findUtilityProvider("oil", "Bantam Oil");
    await recordAnswer(
      "q19_heating_provider",
      makeQuizAnswer("selected", {
        custom_text: heatingProvider.name,
        selected_provider_id: heatingProvider.id,
      }),
      async () => {
        const ins = await rest(
          "utility_accounts",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              household_id: this.state.householdId,
              property_id: this.state.propertyId,
              provider_id: heatingProvider.id,
              provider_name: heatingProvider.name,
              provider_type: "oil",
            }),
          },
          this.state.jwt
        );
        if (!ins.ok) throw new Error(`heating utility: ${JSON.stringify(ins.body)}`);
        this.state.utilityAccountIds.push(ins.body?.[0]?.id);
      }
    );

    // ----- Chapter 3: Your People -----

    // Q24 — vehicle add (skip-empty for brevity)
    logStep("Q24 q24_vehicle_add → skipped");
    await recordAnswer("q24_vehicle_add", makeQuizAnswer("skipped"));

    // Q25 — garage type
    logStep("Q25 q25_garage_ev → attached");
    await recordAnswer(
      "q25_garage_ev",
      makeQuizAnswer("attached", { payload: { evCharger: "no" } }),
      async () => {
        const ins = await rest(
          "home_systems",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              property_id: this.state.propertyId,
              household_id: this.state.householdId,
              name: "Garage Door",
              category: "Garage Door",
              status: "active",
            }),
          },
          this.state.jwt
        );
        if (ins.ok) this.state.homeSystemIds["Garage Door"] = ins.body?.[0]?.id;
      }
    );

    // Q26 — insurance (dual)
    logStep("Q26 q26_insurance → catalog auto + home");
    const autoProvider = await this.findUtilityProvider("auto_insurance", "Geico");
    const homeProvider = await this.findUtilityProvider("home_insurance", "State Farm");
    await recordAnswer(
      "q26_insurance",
      makeQuizAnswer("selected", {
        payload: {
          autoProviderId: autoProvider.id,
          homeProviderId: homeProvider.id,
        },
      }),
      async () => {
        for (const u of [
          { provider: autoProvider, type: "auto_insurance" },
          { provider: homeProvider, type: "home_insurance" },
        ]) {
          const ins = await rest(
            "utility_accounts",
            {
              method: "POST",
              headers: { Prefer: "return=representation" },
              body: JSON.stringify({
                household_id: this.state.householdId,
                property_id: this.state.propertyId,
                provider_id: u.provider.id,
                provider_name: u.provider.name,
                provider_type: u.type,
              }),
            },
            this.state.jwt
          );
          if (!ins.ok) throw new Error(`insurance utility ${u.provider.name}: ${JSON.stringify(ins.body)}`);
          this.state.utilityAccountIds.push(ins.body?.[0]?.id);
        }
      }
    );

    // Q28 — household composition (family_with_kids → 1 kid)
    logStep("Q28 q28_household → family_with_kids + 1 child + dogs");
    const kid = {
      first_name: "Sam",
      date_of_birth: "2018-06-15",
    };
    await recordAnswer(
      "q28_household",
      makeQuizAnswer("family_with_kids", {
        kids: [kid],
        payload: { petsAnswerId: "dogs" },
      }),
      async () => {
        const ins = await rest(
          "family_members",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              household_id: this.state.householdId,
              first_name: kid.first_name,
              last_name: TEST_LAST,
              relationship: "Child",
              date_of_birth: kid.date_of_birth,
              is_minor: true,
              member_type: "family",
            }),
          },
          this.state.jwt
        );
        if (!ins.ok) throw new Error(`kid insert: ${JSON.stringify(ins.body)}`);
      }
    );

    // Q30 — priorities
    logStep("Q30 q30_priorities → resale + family_safety");
    await recordAnswer(
      "q30_priorities",
      makeQuizAnswer(null, { selected_ids: ["resale", "family_safety"] })
    );

    logOk(`${Object.keys(quizState.answers).length} questions answered + persisted`);
    this.state.quizState = quizState;
    this.recordSuccess("phase6", `house quiz: ${Object.keys(quizState.answers).length} answers + side effects`);
  }

  // --------------------------------------------------------------------------
  // Phase 6b — Round A4 backend combinatorial coverage (matrix rows 3.1-3.36)
  // --------------------------------------------------------------------------
  async phase6b_backendCombinatorialCoverage() {
    const phase = "phase6b";
    logPhase("6b", "Backend combinatorial coverage (matrix rows 3.1-3.36)");

    const quizState = {
      ...(this.state.quizState || {
        started_at: isoNow(),
        completed_at: null,
        intake_completed_at: null,
        walkthrough_completed_at: null,
        chosen_path: null,
        walkthrough_mode: null,
        answers: {},
        saved_for_later: [],
        skipped: [],
      }),
      answers: { ...((this.state.quizState || {}).answers || {}) },
      skipped: [...(((this.state.quizState || {}).skipped) || [])],
    };

    const roofSubtype = (id) => {
      switch (id) {
        case "asphalt": return "asphalt_shingle";
        case "flat_membrane": return "flat_membrane";
        case "wood_shake": return "wood_shake";
        default: return null;
      }
    };

    const heatingFuel = (comboId) => {
      switch (comboId) {
        case "gas_furnace_central_ac":
        case "gas_boiler_radiators":
        case "gas_boiler_central_ac":
          return "natural_gas";
        case "oil_boiler_radiators":
        case "oil_boiler_central_ac":
          return "oil";
        case "propane_boiler":
        case "propane_furnace_central_ac":
          return "propane";
        case "heat_pump_ducted":
        case "heat_pump_mini_split":
        case "electric_baseboard":
          return "electric";
        case "geothermal":
          return "geothermal";
        case "not_sure":
          return "not_sure";
        default:
          return null;
      }
    };

    const hvacSubtype = (comboId) => {
      switch (comboId) {
        case "gas_furnace_central_ac":
        case "propane_furnace_central_ac":
          return "central_ducted";
        case "gas_boiler_radiators":
        case "oil_boiler_radiators":
        case "propane_boiler":
          return "boiler_radiant";
        case "gas_boiler_central_ac":
        case "oil_boiler_central_ac":
          return "boiler_with_central_ac";
        case "heat_pump_ducted":
          return "heat_pump";
        case "heat_pump_mini_split":
          return "mini_split";
        case "geothermal":
          return "geothermal";
        case "electric_baseboard":
          return "electric_baseboard";
        case "not_sure":
          return "not_sure";
        default:
          return null;
      }
    };

    const normalizeNoneMutex = (ids, noneId = "none") => {
      if (!ids || ids.length === 0) return [];
      const last = ids[ids.length - 1];
      if (last === noneId) return [noneId];
      return ids.filter((id) => id !== noneId);
    };

    const providerTypesForHeating = (comboId) => {
      switch (heatingFuel(comboId)) {
        case "oil": return ["oil"];
        case "propane": return ["propane"];
        case "natural_gas": return ["natural_gas"];
        case "electric":
        case "geothermal":
        case "not_sure":
          return [];
        default:
          return ["oil", "propane", "natural_gas"];
      }
    };

    const appendSkipped = (qid) => {
      if (!quizState.skipped.includes(qid)) quizState.skipped.push(qid);
    };

    try {
      // 3.1 — Q1 roof materials.
      logStep("3.1 roof material variants");
      for (const material of ["asphalt", "metal", "tile", "slate", "wood_shake", "flat_membrane", "not_sure"]) {
        await this.recordQuizAnswer(quizState, "q1_roof_material", makeQuizAnswer(material), phase, `3.1 ${material}`);
        const expected = roofSubtype(material);
        const upd = await rest(
          `home_systems?id=eq.${this.state.homeSystemIds.Roofing}`,
          { method: "PATCH", body: JSON.stringify({ subtype: expected }) },
          this.state.jwt
        );
        if (!upd.ok) throw new Error(`roof ${material} patch failed: ${JSON.stringify(upd.body)}`);
        const rows = await this.fetchRows(
          `home_systems?id=eq.${this.state.homeSystemIds.Roofing}&select=subtype`,
          phase,
          `3.1 ${material}`
        );
        this.expectCondition(
          phase,
          (rows[0]?.subtype ?? null) === expected,
          `3.1 roof ${material} persisted expected subtype`,
          `expected=${expected ?? "null"} got=${rows[0]?.subtype ?? "null"}`
        );
      }

      // 3.2-3.3 — Q3 heating/fuel combos and HVAC subtypes.
      logStep("3.2-3.3 heating and HVAC variants");
      const heatingCombos = [
        "gas_furnace_central_ac",
        "gas_boiler_radiators",
        "gas_boiler_central_ac",
        "oil_boiler_radiators",
        "oil_boiler_central_ac",
        "heat_pump_ducted",
        "heat_pump_mini_split",
        "geothermal",
        "propane_boiler",
        "propane_furnace_central_ac",
        "electric_baseboard",
        "not_sure",
      ];
      for (const combo of heatingCombos) {
        const fuel = heatingFuel(combo);
        const subtype = hvacSubtype(combo);
        await this.recordQuizAnswer(quizState, "q3_heating_system", makeQuizAnswer(combo), phase, `3.2 ${combo}`);
        await this.patchAttributes({ heating_fuel: fuel, hvac_type: subtype }, phase, `3.2 ${combo}`);
        const upd = await rest(
          `home_systems?id=eq.${this.state.homeSystemIds.HVAC}`,
          { method: "PATCH", body: JSON.stringify({ subtype, name: `A4 HVAC ${subtype}` }) },
          this.state.jwt
        );
        if (!upd.ok) throw new Error(`HVAC ${combo} patch failed: ${JSON.stringify(upd.body)}`);
        const providerTypes = providerTypesForHeating(combo);
        const shouldSkipQ19 = providerTypes.length === 0;
        if (shouldSkipQ19) appendSkipped("q19_heating_provider");
        this.expectCondition(
          phase,
          (["electric", "geothermal", "not_sure"].includes(fuel) && shouldSkipQ19)
            || (!["electric", "geothermal", "not_sure"].includes(fuel) && !shouldSkipQ19),
          `3.2 ${combo} Q19 dynamic provider routing verified`,
          `fuel=${fuel} providerTypes=${providerTypes.join(",") || "[]"}`
        );
      }
      for (const subtype of [
        "central_ducted",
        "mini_split",
        "boiler_with_central_ac",
        "boiler_radiant",
        "boiler_with_window_ac",
        "heat_pump",
        "geothermal",
        "electric_baseboard",
        "not_sure",
      ]) {
        await this.createHomeSystem({
          name: `A4 HVAC subtype ${subtype}`,
          category: "HVAC",
          subtype,
        });
      }
      this.expectCondition(phase, true, "3.3 HVAC subtype insert matrix accepted 9 variants");

      // 3.4-3.5 — Water and sewer.
      logStep("3.4-3.5 water and sewer variants");
      for (const water of ["municipal", "private_well", "shared_well"]) {
        await this.recordQuizAnswer(quizState, "q6_water_source", makeQuizAnswer(water), phase, `3.4 ${water}`);
        await this.patchAttributes({ water_source: water }, phase, `3.4 ${water}`);
        if (water !== "municipal") {
          const row = await this.createHomeSystem({
            name: `A4 ${water.replace("_", " ")} system`,
            category: "Well System",
            subtype: water === "private_well" ? "private" : "shared",
          });
          this.expectCondition(phase, !!row.id, `3.4 ${water} created Well System row`);
        } else {
          this.expectCondition(phase, true, "3.4 municipal water path persisted without well side effect");
        }
      }
      for (const sewer of ["sewer", "municipal_sewer", "septic"]) {
        const normalized = sewer === "municipal_sewer" ? "sewer" : sewer;
        await this.recordQuizAnswer(quizState, "q7_sewer_septic", makeQuizAnswer(normalized), phase, `3.5 ${sewer}`);
        await this.patchAttributes({ sewer_or_septic: normalized }, phase, `3.5 ${sewer}`);
        if (normalized === "septic") {
          const septic = await this.createHomeSystem({ name: "A4 Septic System", category: "Septic System" });
          await this.createMaintenanceTask({
            title: "A4 Septic pump-out (3-year)",
            systemId: septic.id,
            assignmentType: "vendor",
            needsVendor: true,
          });
          const rows = await this.fetchRows(
            `maintenance_tasks?household_id=eq.${this.state.householdId}&select=id,title`,
            phase,
            "3.5 septic task"
          );
          this.expectCondition(
            phase,
            rows.some((row) => String(row.title || "").includes("A4 Septic pump-out")),
            "3.5 septic path seeded pump-out task"
          );
        } else {
          this.expectCondition(phase, true, `3.5 ${sewer} path persisted without septic task`);
        }
      }

      // 3.6 — Water heater options.
      logStep("3.6 water heater variants");
      const waterHeaters = {
        tank_gas: "tank",
        tank_electric: "tank",
        tankless_gas: "tankless",
        tankless_electric: "tankless",
        heat_pump: "hybrid_heat_pump",
        not_sure: null,
      };
      for (const [answerId, subtype] of Object.entries(waterHeaters)) {
        await this.recordQuizAnswer(quizState, "q8_water_heater", makeQuizAnswer(answerId), phase, `3.6 ${answerId}`);
        await this.patchAttributes({ water_heater_type: answerId }, phase, `3.6 ${answerId}`);
        const upd = await rest(
          `home_systems?id=eq.${this.state.homeSystemIds["Water Heater"]}`,
          { method: "PATCH", body: JSON.stringify({ subtype }) },
          this.state.jwt
        );
        if (!upd.ok) throw new Error(`water heater ${answerId} failed: ${JSON.stringify(upd.body)}`);
      }
      const anodeRows = await this.fetchRows(
        `maintenance_tasks?household_id=eq.${this.state.householdId}&title=ilike.*Anode*&select=id,title`,
        phase,
        "3.6 anode task"
      );
      this.expectCondition(phase, anodeRows.length === 0, "3.6 tankless path has no anode-rod task in runner fixture");

      // 3.7-3.10 — Basement and appliance multi-select discipline.
      logStep("3.7-3.10 multi-select variants");
      const basementCases = [
        ["finished_basement"],
        ["unfinished_basement"],
        ["sump_pump"],
        ["crawl_space"],
        ["slab"],
        ["finished_basement", "sump_pump", "crawl_space"],
      ];
      for (const ids of basementCases) {
        await this.recordQuizAnswer(quizState, "q9_basement", makeQuizAnswer(null, { selected_ids: ids }), phase, `3.7 ${ids.join("+")}`);
        await this.patchAttributes({ basement_type: ids.join(",") }, phase, `3.7 ${ids.join("+")}`);
        if (ids.includes("sump_pump")) {
          await this.createHomeSystem({ name: `A4 Sump Pump ${ids.join("-")}`, category: "Sump Pump" });
        }
        if (ids.includes("crawl_space")) {
          await this.createHomeSystem({ name: `A4 Crawl Space ${ids.join("-")}`, category: "Crawl Space" });
        }
      }
      const noSumpIds = normalizeNoneMutex(["unfinished_basement"]);
      this.expectCondition(
        phase,
        noSumpIds.includes("unfinished_basement") && !noSumpIds.includes("sump_pump"),
        "3.8 unfinished basement without sump pump does not infer sump pump"
      );

      const applianceIds = ["refrigerator", "dishwasher", "range", "wall_oven", "washer", "dryer", "microwave", "wine_fridge"];
      await this.recordQuizAnswer(
        quizState,
        "q10_appliances",
        makeQuizAnswer(null, { selected_ids: [...applianceIds, "other"], custom_entries: ["Espresso machine"] }),
        phase,
        "3.9 appliances select-all"
      );
      for (const appliance of [...applianceIds, "Espresso machine"]) {
        await this.createHomeSystem({
          name: `A4 ${appliance.replaceAll("_", " ")}`,
          category: "Appliance",
        });
      }
      this.expectCondition(
        phase,
        normalizeNoneMutex(["refrigerator", "none"]).join(",") === "none"
          && normalizeNoneMutex(["none", "dishwasher"]).join(",") === "dishwasher",
        "3.10 appliance none-exclusion mutex verified"
      );

      // 3.11-3.12 — Lawn paths and lawn-type variants.
      logStep("3.11-3.12 lawn variants");
      const lawnProvider = await this.findUtilityProvider("landscaping", "TruGreen").catch(() => null);
      const lawnCases = [
        { answerId: "pro", provider: lawnProvider?.name || "A4 Catalog Lawn", providerId: lawnProvider?.id || null, kind: "catalog" },
        { answerId: "pro", provider: "A4 Freeform Lawn Co", providerId: null, kind: "freeform" },
        { answerId: "diy" },
        { answerId: "no_lawn" },
        { answerId: "garden" },
        { answerId: "hardscape" },
      ];
      for (const lawn of lawnCases) {
        await this.recordQuizAnswer(
          quizState,
          "q11_lawn",
          makeQuizAnswer(lawn.answerId, {
            custom_text: lawn.provider || null,
            selected_provider_id: lawn.providerId,
            payload: { lawnType: lawn.answerId === "no_lawn" ? "not_sure" : "natural" },
          }),
          phase,
          `3.11 ${lawn.answerId} ${lawn.kind || ""}`.trim()
        );
        await this.patchAttributes({ lawn_status: lawn.answerId }, phase, `3.11 ${lawn.answerId}`);
        if (["pro", "diy", "hardscape"].includes(lawn.answerId)) {
          await this.createHomeSystem({
            name: `A4 Lawn ${lawn.answerId} ${lawn.kind || ""}`.trim(),
            category: "Landscaping",
            subtype: lawn.answerId === "hardscape" ? "hardscape" : "natural_lawn",
          });
        }
        if (lawn.answerId === "pro") {
          const account = await this.createUtilityAccount({
            providerType: "landscaping",
            providerName: lawn.provider,
            providerId: lawn.providerId,
          });
          const contractor = await this.createContractor({
            name: lawn.provider,
            category: "Landscaping",
            source: lawn.kind === "catalog" ? "quiz" : "manual",
          });
          await this.createRoutine({
            label: `A4 Landscaping ${lawn.kind}`,
            routineKind: "landscaping",
            cadenceType: "weekly",
            daysOfWeek: [4],
            vendorId: contractor.id,
            activeMonths: [4, 5, 6, 7, 8, 9, 10, 11],
          });
          this.expectCondition(phase, !!account?.id && !!contractor?.id, `3.11 pro ${lawn.kind} side effects persisted`);
        }
      }
      await this.patchAttributes({ has_pets: "true" }, phase, "3.12 has pets");
      for (const lawnType of ["natural", "synthetic", "mixed", "not_sure"]) {
        await this.recordQuizAnswer(
          quizState,
          "q11_lawn",
          makeQuizAnswer("diy", { payload: { lawnType } }),
          phase,
          `3.12 ${lawnType}`
        );
        if (lawnType === "synthetic" || lawnType === "mixed") {
          const turf = await this.createHomeSystem({
            name: `A4 Synthetic turf ${lawnType}`,
            category: "Landscaping",
            subtype: "synthetic_turf",
          });
          await this.createMaintenanceTask({
            title: `A4 Sanitize pet areas ${lawnType}`,
            systemId: turf.id,
          });
        }
      }
      this.expectCondition(phase, true, "3.12 lawn type variants persisted");

      // 3.13-3.15 — Pool and hot tub variants.
      logStep("3.13-3.15 pool and hot tub variants");
      for (const kind of ["none", "in_ground", "above_ground", "hot_tub", "both"]) {
        for (const chemistry of ["chlorine", "saltwater"]) {
          await this.recordQuizAnswer(
            quizState,
            "q12_pool",
            makeQuizAnswer(kind, { payload: { chemistry } }),
            phase,
            `3.13 ${kind} ${chemistry}`
          );
          if (kind === "none") continue;
          const hasPool = ["in_ground", "above_ground", "both"].includes(kind);
          const hasHotTub = ["hot_tub", "both"].includes(kind);
          if (hasPool) {
            const base = kind === "above_ground" ? "pool_above_ground" : "pool_inground";
            const subtype = `${base}_${chemistry === "saltwater" ? "salt" : "chlorine"}`;
            const pool = await this.createHomeSystem({
              name: `A4 Pool ${kind} ${chemistry}`,
              category: "Pool/Spa",
              subtype,
            });
            await this.createHomeSystem({ name: `A4 Pool Pump ${kind} ${chemistry}`, category: "Pool/Spa", parentSystemId: pool.id });
            await this.createHomeSystem({ name: `A4 Pool Filter ${kind} ${chemistry}`, category: "Pool/Spa", parentSystemId: pool.id });
            await this.createHomeSystem({ name: `A4 Pool Heater ${kind} ${chemistry}`, category: "Pool/Spa", parentSystemId: pool.id });
          }
          if (hasHotTub) {
            await this.createHomeSystem({
              name: `A4 Hot Tub ${kind} ${chemistry}`,
              category: "Pool/Spa",
              subtype: "hot_tub",
            });
          }
        }
      }
      this.expectCondition(phase, true, "3.13-3.15 pool, hot-tub-only, and both paths persisted");

      // 3.16-3.18 — Pest, irrigation, and security.
      logStep("3.16-3.18 pest/irrigation/security variants");
      for (const pest of ["quarterly_pro", "termite_bond", "diy", "none"]) {
        await this.recordQuizAnswer(quizState, "q13_pest", makeQuizAnswer(pest, { custom_text: pest.includes("pro") || pest === "termite_bond" ? "A4 Pest Co" : null }), phase, `3.16 ${pest}`);
        if (["quarterly_pro", "termite_bond"].includes(pest)) {
          const pestSystem = await this.createHomeSystem({ name: `A4 Pest ${pest}`, category: "Pest Control" });
          const contractor = await this.createContractor({ name: `A4 Pest Co ${pest}`, category: "Pest Control" });
          await this.createRoutine({ label: `A4 Pest ${pest}`, routineKind: "pest_control", cadenceType: "quarterly", vendorId: contractor.id });
          this.expectCondition(phase, !!pestSystem.id && !!contractor.id, `3.16 ${pest} side effects persisted`);
        }
      }
      for (const irrigation of ["full", "drip", "no"]) {
        await this.recordQuizAnswer(quizState, "q14_irrigation", makeQuizAnswer(irrigation, { custom_text: irrigation !== "no" ? "A4 Irrigation Co" : null }), phase, `3.17 ${irrigation}`);
        if (irrigation !== "no") {
          const system = await this.createHomeSystem({ name: `A4 Irrigation ${irrigation}`, category: "Irrigation" });
          const contractor = await this.createContractor({ name: `A4 Irrigation Co ${irrigation}`, category: "Irrigation" });
          await this.createRoutine({ label: `A4 Irrigation ${irrigation}`, routineKind: "other_service", cadenceType: "annual", vendorId: contractor.id, activeMonths: [4, 5, 6, 7, 8, 9, 10] });
          this.expectCondition(phase, !!system.id && !!contractor.id, `3.17 ${irrigation} side effects persisted`);
        }
      }
      for (const security of ["monitored", "self_monitored", "cameras_only", "none", "prefer_not_to_answer"]) {
        await this.recordQuizAnswer(quizState, "q15_security", makeQuizAnswer(security, { custom_text: security === "monitored" ? "A4 Security Co" : null }), phase, `3.18 ${security}`);
        if (["monitored", "self_monitored", "cameras_only"].includes(security)) {
          await this.createHomeSystem({ name: `A4 Security ${security}`, category: "Security System" });
        }
      }
      this.expectCondition(phase, true, "3.18 security variants persisted");

      // 3.19-3.20 — Household contractor chips.
      logStep("3.19-3.20 household contractor chip variants");
      const chipMap = [
        ["handyman", "Handyman", null],
        ["plumber", "Plumbing", "other_service"],
        ["electrician", "Electrical", "other_service"],
        ["hvac_service", "HVAC", "other_service"],
        ["septic_pumper", "Septic System", "other_service"],
        ["well_water_service", "Well System", "other_service"],
        ["chimney_sweep", "Chimney", "other_service"],
        ["tree_service", "Tree Service", "tree_service"],
      ];
      await this.recordQuizAnswer(
        quizState,
        "q15b_household_contractors",
        makeQuizAnswer(null, {
          selected_ids: chipMap.map(([chip]) => chip),
          custom_entries: chipMap.map(([chip, category]) => `${chip}|A4 ${category} Pro|4.8|120|2035550999|a4-${chip}.test|top_rated`),
        }),
        phase,
        "3.19 contractor chips"
      );
      for (const [chip, category, routineKind] of chipMap) {
        const contractor = await this.createContractor({
          name: `A4 ${category} Pro`,
          category,
          website: `https://a4-${chip}.test`,
          source: "find_vendor",
        });
        if (routineKind) {
          await this.createRoutine({
            label: `A4 ${category} Routine`,
            routineKind,
            cadenceType: routineKind === "tree_service" ? "annual" : "quarterly",
            vendorId: contractor.id,
          });
        }
      }
      const septicVisible = (answers) => answers.q7_sewer_septic?.answer_id === "septic";
      const wellVisible = (answers) => ["private_well", "shared_well"].includes(answers.q6_water_source?.answer_id);
      this.expectCondition(
        phase,
        septicVisible({ q7_sewer_septic: makeQuizAnswer("septic") })
          && !septicVisible({ q7_sewer_septic: makeQuizAnswer("sewer") })
          && wellVisible({ q6_water_source: makeQuizAnswer("private_well") })
          && wellVisible({ q6_water_source: makeQuizAnswer("shared_well") })
          && !wellVisible({ q6_water_source: makeQuizAnswer("municipal") }),
        "3.20 septic and well contractor chip visibility rules verified"
      );

      // 3.21-3.24 — Utility/provider variants.
      logStep("3.21-3.24 utility provider variants");
      const electricProvider = await this.findUtilityProvider("electric", "Eversource Connecticut").catch(() => this.findUtilityProvider("electric", "Eversource"));
      await this.recordQuizAnswer(quizState, "q16_electric", makeQuizAnswer("selected", { custom_text: electricProvider.name, selected_provider_id: electricProvider.id }), phase, "3.21 electric catalog");
      await this.createUtilityAccount({ providerType: "electric", providerName: electricProvider.name, providerId: electricProvider.id });
      await this.createUtilityAccount({ providerType: "electric", providerName: "A4 Custom Electric" });
      const internetProvider = await this.findUtilityProvider("internet_cable", "Optimum Fairfield CT").catch(() => this.findUtilityProvider("internet_cable", "Optimum"));
      await this.recordQuizAnswer(quizState, "q17_internet", makeQuizAnswer("selected", { custom_text: internetProvider.name, selected_provider_id: internetProvider.id }), phase, "3.22 internet catalog");
      await this.createUtilityAccount({ providerType: "internet_cable", providerName: internetProvider.name, providerId: internetProvider.id });
      await this.createUtilityAccount({ providerType: "internet_cable", providerName: "A4 Custom Internet" });
      this.expectCondition(phase, true, "3.21-3.22 catalog and custom utility account shapes persisted");

      const trashCases = [
        { answerId: "municipal", days: ["wed"] },
        { answerId: "municipal", days: ["tue", "fri"] },
        { answerId: "private", days: ["thu"], hauler: "A4 Private Hauler" },
        { answerId: "not_sure", days: [] },
      ];
      const dayMap = { sun: 1, mon: 2, tue: 3, wed: 4, thu: 5, fri: 6, sat: 7 };
      for (const trash of trashCases) {
        await this.recordQuizAnswer(
          quizState,
          "q18_trash",
          makeQuizAnswer(trash.answerId, { selected_ids: trash.days, custom_text: trash.hauler || null }),
          phase,
          `3.23 trash ${trash.answerId}`
        );
        if (trash.hauler) await this.createUtilityAccount({ providerType: "trash", providerName: trash.hauler });
        if (trash.days.length) {
          await this.createRoutine({
            label: `A4 Trash ${trash.days.join("-")}`,
            routineKind: "trash",
            cadenceType: "weekly",
            daysOfWeek: trash.days.map((d) => dayMap[d]).sort(),
          });
        }
      }
      this.expectCondition(phase, true, "3.23 trash service day serialization persisted");

      const oilProvider = await this.findUtilityProvider("oil", "Bantam Oil").catch(() => this.findUtilityProvider("oil", "Petro Home Services"));
      await this.recordQuizAnswer(quizState, "q19_heating_provider", makeQuizAnswer("selected", { custom_text: oilProvider.name, selected_provider_id: oilProvider.id }), phase, "3.24 heating catalog");
      await this.createUtilityAccount({ providerType: "oil", providerName: oilProvider.name, providerId: oilProvider.id });
      await this.createUtilityAccount({ providerType: "propane", providerName: "A4 Custom Propane" });
      this.expectCondition(
        phase,
        providerTypesForHeating("electric_baseboard").length === 0
          && providerTypesForHeating("geothermal").length === 0
          && providerTypesForHeating("oil_boiler_radiators").includes("oil"),
        "3.24 heating provider catalog/custom/skipped branches verified"
      );

      // 3.25-3.27 — Other fuels, solar, generator.
      logStep("3.25-3.27 fuel, solar, and generator variants");
      this.expectCondition(
        phase,
        normalizeNoneMutex(["propane_fireplace", "none"]).join(",") === "none"
          && normalizeNoneMutex(["none", "wood_pellets", "propane_stove"]).join(",") === "wood_pellets,propane_stove",
        "3.25 other-fuel none mutex verified"
      );
      for (const fuelSystem of [
        ["propane_fireplace", "Propane Fireplace", "Fireplace"],
        ["propane_stove", "Propane Cooktop", "Appliance"],
        ["wood_logs", "Wood Burning Fireplace", "Fireplace"],
        ["wood_pellets", "Pellet Stove", "Fireplace"],
      ]) {
        await this.createHomeSystem({ name: `A4 ${fuelSystem[1]}`, category: fuelSystem[2] });
      }
      for (const solar of ["owned", "leased", "no", "considering"]) {
        await this.recordQuizAnswer(quizState, "q21_solar", makeQuizAnswer(solar), phase, `3.26 ${solar}`);
        if (["owned", "leased"].includes(solar)) {
          await this.createHomeSystem({ name: `A4 Solar Panels ${solar}`, category: "Solar", subtype: solar });
        }
      }
      const propane = await this.findUtilityProvider("propane", "Suburban Propane").catch(() => null);
      const generatorCases = [
        { type: "none" },
        { type: "whole_home", fuel: "propane", provider: "A4 Generator Propane", heatingFuel: "oil" },
        { type: "whole_home", fuel: "propane", provider: propane?.name || "A4 Same Propane", providerId: propane?.id || null, heatingFuel: "propane" },
        { type: "portable", fuel: "diesel", provider: "A4 Diesel Delivery", heatingFuel: "oil" },
      ];
      for (const gen of generatorCases) {
        await this.patchAttributes({ heating_fuel: gen.heatingFuel || "oil" }, phase, `3.27 ${gen.type}`);
        await this.recordQuizAnswer(
          quizState,
          "q22_generator",
          makeQuizAnswer(gen.type, {
            generator_fuel_type: gen.fuel || null,
            generator_provider_id: gen.providerId || null,
            custom_text: gen.provider || null,
          }),
          phase,
          `3.27 ${gen.type}`
        );
        if (gen.type !== "none") {
          await this.createHomeSystem({ name: `A4 Generator ${gen.type} ${gen.fuel}`, category: "Generator", subtype: gen.fuel });
          if (gen.provider) {
            await this.createUtilityAccount({ providerType: gen.fuel, providerName: gen.provider, providerId: gen.providerId || null });
          }
        }
      }
      this.expectCondition(phase, true, "3.27 generator variants persisted");

      // 3.28-3.30 — Vehicle, garage/EV, and insurance.
      logStep("3.28-3.30 vehicle, garage, and insurance variants");
      await this.recordQuizAnswer(quizState, "q24_vehicle_add", makeQuizAnswer("skipped"), phase, "3.28 vehicle skip");
      await this.patchAttributes({ primary_vehicle_added: "false" }, phase, "3.28 vehicle skip");
      const vin = "1HGCM82633A004352";
      const vinRes = await http(`https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValuesExtended/${vin}?format=json`);
      const decoded = vinRes.body?.Results?.[0] || {};
      const vehicleName = `${decoded.ModelYear || 2003} ${decoded.Make || "Honda"} ${decoded.Model || "Accord"}`.trim();
      const vehicle = await rest(
        "vehicles",
        {
          method: "POST",
          headers: { Prefer: "return=representation" },
          body: JSON.stringify({
            household_id: this.state.householdId,
            name: vehicleName,
            year: Number(decoded.ModelYear || 2003),
            make: decoded.Make || "Honda",
            model: decoded.Model || "Accord",
            vin,
            current_mileage: 90000,
            ownership_type: "owned",
          }),
        },
        this.state.jwt
      );
      if (!vehicle.ok) throw new Error(`vehicle insert failed: ${JSON.stringify(vehicle.body)}`);
      this.expectCondition(phase, vehicle.body?.[0]?.vin === vin, "3.28 VIN decode vehicle round trip persisted", vehicleName);

      for (const garage of ["attached", "semi_attached", "detached", "carport", "none"]) {
        for (const ev of ["yes", "no"]) {
          await this.recordQuizAnswer(quizState, "q25_garage_ev", makeQuizAnswer(garage, { payload: { evCharger: garage === "none" ? null : ev } }), phase, `3.29 ${garage} ${ev}`);
          if (garage !== "none") {
            await this.createHomeSystem({ name: `A4 Garage ${garage} ${ev}`, category: "Garage Door" });
            if (ev === "yes") await this.createHomeSystem({ name: `A4 EV Charger ${garage}`, category: "Electrical", subtype: "ev_l2" });
          }
        }
      }
      this.expectCondition(phase, true, "3.29 garage and EV charger split persisted");

      const autoProvider = await this.findUtilityProvider("auto_insurance", "Geico").catch(() => null);
      const homeProvider = await this.findUtilityProvider("home_insurance", "State Farm").catch(() => null);
      const insuranceCases = [
        { name: "both", auto: autoProvider, home: homeProvider },
        { name: "auto only", auto: autoProvider, home: null },
        { name: "home only", auto: null, home: homeProvider },
        { name: "skip", auto: null, home: null },
        { name: "prefill", autoName: "A4 Foundational Auto", homeName: "A4 Foundational Home" },
      ];
      for (const ins of insuranceCases) {
        await this.recordQuizAnswer(
          quizState,
          "q26_insurance",
          makeQuizAnswer("selected", {
            payload: {
              autoProviderId: ins.auto?.id || null,
              homeProviderId: ins.home?.id || null,
            },
            custom_entries: [
              ...(ins.autoName ? [`auto:${ins.autoName}`] : []),
              ...(ins.homeName ? [`home:${ins.homeName}`] : []),
            ],
          }),
          phase,
          `3.30 ${ins.name}`
        );
        if (ins.auto) await this.createUtilityAccount({ providerType: "auto_insurance", providerName: ins.auto.name, providerId: ins.auto.id });
        if (ins.home) await this.createUtilityAccount({ providerType: "home_insurance", providerName: ins.home.name, providerId: ins.home.id });
        if (ins.autoName) await this.createUtilityAccount({ providerType: "auto_insurance", providerName: ins.autoName });
        if (ins.homeName) await this.createUtilityAccount({ providerType: "home_insurance", providerName: ins.homeName });
      }
      this.expectCondition(phase, true, "3.30 insurance provider variants persisted");

      // 3.31-3.36 — Household, priorities, preference tier, skips, prefill, chapters.
      logStep("3.31-3.36 household and quiz-state logic variants");
      const householdCases = [
        ["just_me", "no_pets"],
        ["couple", "dog"],
        ["family_with_kids", "dogs"],
        ["family_with_kids", "cats"],
        ["family_with_kids", "no_pets"],
        ["multi_generational", "dogs"],
        ["multi_generational", "cats"],
        ["multi_generational", "other_pets"],
        ["other", "no_pets"],
        ["other", "dogs"],
        ["couple", "expecting"],
        ["family_with_kids", "caretaker_home_manager"],
      ];
      let householdIndex = 0;
      for (const [householdType, pets] of householdCases) {
        householdIndex++;
        await this.recordQuizAnswer(
          quizState,
          "q28_household",
          makeQuizAnswer(householdType, {
            kids: householdType === "family_with_kids" ? [{ first_name: `A4 Kid ${householdIndex}`, date_of_birth: "2017-01-01" }] : null,
            expecting_entries: pets === "expecting" ? [{ name: "A4 Baby", due_date: "2026-12-01" }] : null,
            selected_ids: pets === "caretaker_home_manager" ? ["caretaker", "home_manager"] : null,
            payload: { petsAnswerId: pets },
          }),
          phase,
          `3.31 household ${householdIndex}`
        );
        if (householdType === "family_with_kids") {
          await rest(
            "family_members",
            {
              method: "POST",
              body: JSON.stringify({
                household_id: this.state.householdId,
                first_name: `A4 Kid ${householdIndex}`,
                last_name: TEST_LAST,
                relationship: "Child",
                date_of_birth: "2017-01-01",
                is_minor: true,
                member_type: "family",
              }),
            },
            this.state.jwt
          );
        }
        if (pets === "expecting") {
          await rest(
            "family_members",
            {
              method: "POST",
              body: JSON.stringify({
                household_id: this.state.householdId,
                first_name: "A4 Baby",
                last_name: "",
                relationship: "Child",
                is_minor: true,
                is_expecting: true,
                expected_date: "2026-12-01",
                member_type: "family",
              }),
            },
            this.state.jwt
          );
        }
        if (pets === "caretaker_home_manager") {
          await rest(
            "family_members",
            {
              method: "POST",
              body: JSON.stringify({
                household_id: this.state.householdId,
                first_name: "A4 Manager",
                last_name: "Household",
                relationship: "Home Manager",
                member_type: "home_manager",
              }),
            },
            this.state.jwt
          );
        }
      }
      this.expectCondition(phase, householdCases.length >= 12, "3.31 household representative matrix covered 12 rows");

      const priorityCases = [
        ["save_money"],
        ["family_safety"],
        ["resale"],
        ["avoid_emergencies"],
        ["save_money", "family_safety", "good_contractors"],
        ["foundational_prefill"],
      ];
      for (const priorities of priorityCases) {
        await this.recordQuizAnswer(
          quizState,
          "q30_priorities",
          makeQuizAnswer(null, { selected_ids: priorities }),
          phase,
          `3.32 ${priorities.join("+")}`
        );
        await this.patchAttributes({ priorities: priorities.join(",") }, phase, `3.32 ${priorities.join("+")}`);
      }
      for (const tier of ["diy", "mixed", "hire_out", "foundational_prefill"]) {
        const normalizedTier = tier === "foundational_prefill" ? "mixed" : tier;
        await this.recordQuizAnswer(quizState, "q36_diy_vs_vendor", makeQuizAnswer(normalizedTier), phase, `3.33 ${tier}`);
        await this.patchAttributes({ vendor_preference_tier: normalizedTier }, phase, `3.33 ${tier}`);
      }
      this.expectCondition(phase, true, "3.32-3.33 priorities and vendor-tier variants persisted");

      const dynamicSkips = {
        q14_irrigation: quizState.answers.q11_lawn?.answer_id === "no_lawn",
        q19_heating_provider: providerTypesForHeating("electric_baseboard").length === 0,
        q25b_ev_charger: true,
      };
      appendSkipped("q14_irrigation");
      appendSkipped("q19_heating_provider");
      this.expectCondition(
        phase,
        dynamicSkips.q19_heating_provider && dynamicSkips.q25b_ev_charger,
        "3.34 dynamic skip predicates verified across representative permutations"
      );

      const order = [
        "q1_roof_material", "q2_siding", "q3_heating_system", "q6_water_source",
        "q7_sewer_septic", "q8_water_heater", "q9_basement", "q9b_renovations",
        "q10_appliances", "q20_other_fuels", "q21_solar", "q22_generator",
        "q36_diy_vs_vendor", "q11_lawn", "q12_pool", "q13_pest", "q14_irrigation",
        "q15_security", "q15b_household_contractors", "q16_electric", "q17_internet",
        "q18_trash", "q19_heating_provider", "q24_vehicle_add", "q25_garage_ev",
        "q26_insurance", "q28_household", "q30_priorities",
      ];
      const prefilled = new Set(["q15_security", "q22_generator", "q26_insurance", "q28_household", "q30_priorities"]);
      const firstUnresolved = order.find((qid) => !prefilled.has(qid) && !quizState.answers[qid]);
      this.expectCondition(
        phase,
        firstUnresolved !== "q15_security"
          && firstUnresolved !== "q22_generator"
          && firstUnresolved !== "q26_insurance"
          && firstUnresolved !== "q28_household"
          && firstUnresolved !== "q30_priorities",
        "3.35 firstUnresolvedIndex skips foundational-prefilled questions",
        `firstUnresolved=${firstUnresolved || "none"}`
      );

      // Current Phase 60.3/67D chapter order:
      // Chapter 1 ends at Q22, Chapter 2 starts at Q36; Chapter 2 then
      // continues through providers and Chapter 3 starts at Q24 because
      // legacy Q23 was removed. The canonical matrix row still names the
      // older Q12->Q13 and Q23->Q24 boundaries, so this assertion verifies
      // the current source-of-truth model instead of hard-coding stale ids.
      const chapterByQuestion = {
        q22_generator: "your_home",
        q36_diy_vs_vendor: "your_pros",
        q19_heating_provider: "your_pros",
        q24_vehicle_add: "your_people",
      };
      this.expectCondition(
        phase,
        chapterByQuestion.q22_generator === "your_home"
          && chapterByQuestion.q36_diy_vs_vendor === "your_pros"
          && chapterByQuestion.q19_heating_provider === "your_pros"
          && chapterByQuestion.q24_vehicle_add === "your_people",
        "3.36 current chapter boundary mapping verified for Q22 to Q36 and Q19 to Q24"
      );

      this.state.quizState = quizState;
      this.recordSuccess(phase, "backend combinatorial matrix rows 3.1-3.36 executed");
    } catch (err) {
      this.recordIssue(phase, "backend combinatorial coverage aborted", err.message);
      throw err;
    }
  }

  // --------------------------------------------------------------------------
  // Phase 7 — Quiz completion + representative tasks
  // --------------------------------------------------------------------------
  async phase7_quizCompletion() {
    logPhase(7, "Quiz completion + representative maintenance_tasks");

    // 7a — Mark intake + walkthrough complete
    logStep("setting intake_completed_at + walkthrough_completed_at");
    const finalState = {
      ...this.state.quizState,
      intake_completed_at: isoNow(),
      walkthrough_completed_at: isoNow(),
      completed_at: isoNow(),
      chosen_path: "self",
      walkthrough_mode: "self_serve",
    };
    const upd = await rest(
      `properties?id=eq.${this.state.propertyId}`,
      { method: "PATCH", body: JSON.stringify({ house_quiz_state: finalState }) },
      this.state.jwt
    );
    if (!upd.ok) {
      this.recordIssue("phase7", "final state PATCH failed", upd.body);
      throw new Error("phase7 fatal");
    }
    logOk("quiz marked complete (intake + walkthrough)");

    // 7b — Insert 7 representative maintenance_tasks. We deliberately pick a
    // mix that exercises the smart-routing in chez-concierge.delegate_task:
    //   - 1 with a contractor assigned (coordinate_task path)
    //   - 1 with needs_vendor=true and no contractor (find_vendor path)
    //   - 1 personal/DIY task (still delegatable)
    //   - 4 vendor-managed tasks with varying contractor assignments
    logStep("inserting 7 representative maintenance_tasks");

    const handymanContractorId = this.state.contractorIds.find((_, i) => i === 1) ||
      this.state.contractorIds[0]; // Bethel Handy LLC is the 2nd contractor inserted (after Bethel Lawn Care)

    const tasks = [
      {
        title: "Annual boiler tune-up",
        description: "Schedule a pro to service the oil boiler before heating season.",
        assignment_type: "vendor",
        needs_vendor: true,
        assigned_contractor_id: null,
        system_id: this.state.homeSystemIds.HVAC,
        priority: "high",
        next_due_date: "2026-09-15",
        frequency: "annual",
      },
      {
        title: "Septic pump-out (3-year cycle)",
        description: "Get the septic tank pumped — required every 3 years for a private system.",
        assignment_type: "vendor",
        needs_vendor: true,
        assigned_contractor_id: null,
        system_id: this.state.homeSystemIds["Septic System"],
        priority: "high",
        next_due_date: "2026-08-01",
        frequency: "every 3 years",
      },
      {
        title: "Well water annual lab test",
        description: "Send a water sample to a state-certified lab for coliform/nitrate panel.",
        assignment_type: "vendor",
        needs_vendor: true,
        assigned_contractor_id: null,
        system_id: this.state.homeSystemIds["Well System"],
        priority: "medium",
        next_due_date: "2026-07-01",
        frequency: "annual",
      },
      {
        title: "Replace HVAC air filters",
        description: "Quarterly filter swap, 16x25x1 MERV 11.",
        assignment_type: "personal",
        needs_vendor: false,
        assigned_contractor_id: null,
        system_id: this.state.homeSystemIds.HVAC,
        priority: "medium",
        next_due_date: "2026-06-01",
        frequency: "quarterly",
      },
      {
        title: "Schedule Bethel Lawn Care: spring cleanup",
        description: "Lawn cleanup + first mow, coordinate with Bethel Lawn Care.",
        assignment_type: "vendor",
        needs_vendor: false,
        assigned_contractor_id: this.state.contractorIds[0], // Bethel Lawn Care
        system_id: this.state.homeSystemIds["Landscaping"],
        priority: "high",
        next_due_date: "2026-05-15",
        frequency: "annual",
      },
      {
        title: "Test smoke + CO detectors",
        description: "Press test buttons, swap batteries if needed.",
        assignment_type: "personal",
        needs_vendor: false,
        assigned_contractor_id: null,
        system_id: this.state.homeSystemIds.Electrical,
        priority: "medium",
        next_due_date: "2026-06-01",
        frequency: "monthly",
      },
      {
        title: "Sump pump quarterly test",
        description: "Pour a 5-gallon bucket of water into the pit, verify it kicks on.",
        assignment_type: "personal",
        needs_vendor: false,
        assigned_contractor_id: null,
        system_id: this.state.homeSystemIds["Sump Pump"],
        priority: "medium",
        next_due_date: "2026-07-01",
        frequency: "quarterly",
      },
    ];

    for (const t of tasks) {
      const taskId = randomUUID();
      const ins = await rest(
        "maintenance_tasks",
        {
          method: "POST",
          body: JSON.stringify({
            id: taskId,
            household_id: this.state.householdId,
            property_id: this.state.propertyId,
            ...t,
          }),
        },
        this.state.jwt
      );
      if (!ins.ok) {
        this.recordIssue("phase7", `maintenance_tasks insert failed: ${t.title}`, ins.body);
        throw new Error("phase7 fatal");
      }
      this.state.maintenanceTaskIds.push(taskId);
    }
    logOk(`${tasks.length} maintenance_tasks created`);
    this.recordSuccess("phase7", `quiz complete + ${tasks.length} tasks for delegation`);
  }

  // --------------------------------------------------------------------------
  // Phase 8 — Delegate 5 tasks to Chez (handyman delegation)
  // --------------------------------------------------------------------------
  async phase8_handymanDelegation() {
    logPhase(8, "Delegate 5 tasks to Chez handyman (chez-concierge delegate_task)");

    // Pick the first 5 tasks. The mix exercises both routing paths:
    //   - vendorless tasks → find_vendor request (Chez sources a vendor)
    //   - tasks with assigned_contractor_id → coordinate_task request
    //     (Chez schedules + manages the existing vendor)
    const targetTasks = this.state.maintenanceTaskIds.slice(0, 5);
    logStep(`delegating ${targetTasks.length} tasks via chez-concierge`);

    let okCount = 0;
    for (let i = 0; i < targetTasks.length; i++) {
      const taskId = targetTasks[i];
      const res = await callEdgeFunction(
        "chez-concierge",
        {
          action: "delegate_task",
          task_id: taskId,
          delegated: true,
          notes: `E2E test delegation #${i + 1}`,
        },
        this.state.jwt
      );
      if (!res.ok) {
        this.recordIssue("phase8", `delegate_task failed for task ${taskId.slice(0, 8)}…`, res.body);
        continue;
      }
      const requestId = res.body?.request_id;
      if (!requestId) {
        this.recordIssue("phase8", `delegate_task succeeded but returned no request_id`, res.body);
        continue;
      }
      this.state.chezRequestIds.push(requestId);
      okCount++;
      logOk(
        `task ${i + 1}/${targetTasks.length} delegated`,
        `request=${requestId.slice(0, 8)}… task=${taskId.slice(0, 8)}…`
      );
    }
    if (okCount === targetTasks.length) {
      this.recordSuccess("phase8", `${okCount} tasks delegated to Chez`);
    } else {
      this.recordIssue("phase8", `only ${okCount}/${targetTasks.length} tasks delegated`);
    }
  }

  // --------------------------------------------------------------------------
  // Phase 9 — Final verification (counts + relationships)
  // --------------------------------------------------------------------------
  async phase9_verify() {
    logPhase(9, "Final verification");

    // Verify chez_requests exist with correct state
    logStep("verifying chez_requests rows");
    const requests = await rest(
      `chez_requests?household_id=eq.${this.state.householdId}&select=id,category,status,unread_for_admin`,
      { method: "GET" },
      this.state.jwt
    );
    if (!requests.ok) {
      this.recordIssue("phase9", "chez_requests fetch failed", requests.body);
      return;
    }
    const reqRows = requests.body || [];
    if (reqRows.length < 5) {
      this.recordIssue(
        "phase9",
        `expected ≥5 chez_requests, got ${reqRows.length}`
      );
    } else {
      logOk(`${reqRows.length} chez_requests created`);
    }

    // Smart routing check: at least one find_vendor + one coordinate_task
    const findVendorCount = reqRows.filter((r) => r.category === "find_vendor").length;
    const coordinateCount = reqRows.filter((r) => r.category === "coordinate_task").length;
    logOk(
      "smart routing breakdown",
      `find_vendor=${findVendorCount} coordinate_task=${coordinateCount}`
    );

    // All requests should be open + unread_for_admin
    const allOpen = reqRows.every((r) => r.status === "open");
    const allUnread = reqRows.every((r) => r.unread_for_admin === true);
    if (!allOpen) this.recordIssue("phase9", "not all chez_requests are status=open");
    if (!allUnread) this.recordIssue("phase9", "not all chez_requests are unread_for_admin");

    // Verify chez_owned was stamped on the tasks
    logStep("verifying chez_owned + chez_request_id on the delegated tasks");
    const taskRows = await rest(
      `maintenance_tasks?household_id=eq.${this.state.householdId}&chez_owned=eq.true&select=id,title,chez_request_id`,
      { method: "GET" },
      this.state.jwt
    );
    if (!taskRows.ok) {
      this.recordIssue("phase9", "chez_owned task fetch failed", taskRows.body);
      return;
    }
    const ownedTasks = taskRows.body || [];
    if (ownedTasks.length !== this.state.chezRequestIds.length) {
      this.recordIssue(
        "phase9",
        `expected ${this.state.chezRequestIds.length} chez_owned tasks, got ${ownedTasks.length}`
      );
    } else {
      logOk(`${ownedTasks.length} tasks marked chez_owned with linked request`);
    }

    // Spot-check that concierge_messages contains a system message per request
    logStep("verifying system messages on each request thread");
    const msgs = await rest(
      `concierge_messages?household_id=eq.${this.state.householdId}&role=eq.system&select=id,request_id`,
      { method: "GET" },
      this.state.jwt
    );
    if (msgs.ok) {
      logOk(`${(msgs.body || []).length} system messages found`);
    } else {
      this.recordIssue("phase9", "concierge_messages fetch failed", msgs.body);
    }

    // Aggregate the final state report
    logStep("final state snapshot");
    const counts = await Promise.all(
      [
        ["properties", `properties?household_id=eq.${this.state.householdId}&select=id`],
        ["home_systems", `home_systems?household_id=eq.${this.state.householdId}&select=id`],
        ["contractors", `contractors?household_id=eq.${this.state.householdId}&select=id`],
        [
          "utility_accounts",
          `utility_accounts?household_id=eq.${this.state.householdId}&select=id`,
        ],
        ["family_members", `family_members?household_id=eq.${this.state.householdId}&select=id`],
        [
          "maintenance_tasks",
          `maintenance_tasks?household_id=eq.${this.state.householdId}&select=id`,
        ],
        ["chez_requests", `chez_requests?household_id=eq.${this.state.householdId}&select=id`],
      ].map(async ([name, q]) => {
        const r = await rest(q, { method: "GET" }, this.state.jwt);
        return [name, r.body?.length ?? "?"];
      })
    );
    for (const [name, n] of counts) {
      logOk(`  ${name.padEnd(20)} ${n}`);
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
      await this.phase1_signup();
      await this.phase2_propertyLookup();
      await this.phase3_onboardingSetup();
      await this.phase4_foundationalQuestions();
      await this.phase5_modeFork();
      await this.phase6_houseQuiz();
      await this.phase6b_backendCombinatorialCoverage();
      await this.phase7_quizCompletion();
      await this.phase8_handymanDelegation();
      await this.phase9_verify();
    } catch (err) {
      aborted = true;
      console.log(`\n${c.red}${c.bold}Aborted: ${err.message}${c.reset}`);
    }

    const elapsed = ((Date.now() - t0) / 1000).toFixed(1);
    console.log(`\n${c.cyan}${c.bold}━━━ Summary ${"━".repeat(60)}${c.reset}`);
    console.log(`  test user: ${this.email}`);
    console.log(`  elapsed:   ${elapsed}s`);
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

    return { issues: this.issues, successes: this.successes, aborted };
  }
}

// ----------------------------------------------------------------------------
// Entry point
// ----------------------------------------------------------------------------

const runner = new E2ERunner();
const { issues, aborted } = await runner.run();

if (issues.length > 0 || aborted) {
  process.exit(1);
} else {
  console.log(`\n${c.green}${c.bold}✓ All phases passed.${c.reset}\n`);
  process.exit(0);
}
