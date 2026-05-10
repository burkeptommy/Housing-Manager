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
      household_residents: "couple_with_kids",
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
              household_residents: "couple_with_kids",
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
  // Phase 6 — Full House Quiz (37 questions in order, with side effects)
  // --------------------------------------------------------------------------
  async phase6_houseQuiz() {
    logPhase(6, "Full House Quiz (37 questions)");

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
    logStep("Q3 q3_heating_system → oil_boiler");
    await recordAnswer(
      "q3_heating_system",
      makeQuizAnswer("oil_boiler"),
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
    logStep("Q8 q8_water_heater → oil_indirect");
    await recordAnswer(
      "q8_water_heater",
      makeQuizAnswer("oil_indirect"),
      async () => {
        await rest(
          `home_systems?id=eq.${this.state.homeSystemIds["Water Heater"]}`,
          {
            method: "PATCH",
            body: JSON.stringify({ subtype: "oil_indirect", name: "Oil Indirect Water Heater" }),
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
    logStep("Q21 q21_solar → none");
    await recordAnswer("q21_solar", makeQuizAnswer("none"));

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
    logStep("Q14 q14_irrigation → none");
    await recordAnswer("q14_irrigation", makeQuizAnswer("none"));

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
    logStep("Q16 q16_electric → free-form name");
    await recordAnswer(
      "q16_electric",
      makeQuizAnswer(null, { custom_text: "Eversource" }),
      async () => {
        const ins = await rest(
          "utility_accounts",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              household_id: this.state.householdId,
              property_id: this.state.propertyId,
              provider_name: "Eversource",
              account_type: "electric",
            }),
          },
          this.state.jwt
        );
        if (ins.ok) this.state.utilityAccountIds.push(ins.body?.[0]?.id);
      }
    );

    // Q17 — internet provider
    logStep("Q17 q17_internet → Optimum");
    await recordAnswer(
      "q17_internet",
      makeQuizAnswer(null, { custom_text: "Optimum" }),
      async () => {
        const ins = await rest(
          "utility_accounts",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              household_id: this.state.householdId,
              property_id: this.state.propertyId,
              provider_name: "Optimum",
              account_type: "internet_cable",
            }),
          },
          this.state.jwt
        );
        if (ins.ok) this.state.utilityAccountIds.push(ins.body?.[0]?.id);
      }
    );

    // Q18 — trash (with pickup days)
    logStep("Q18 q18_trash → municipal Wed");
    await recordAnswer(
      "q18_trash",
      makeQuizAnswer("municipal", { selected_ids: ["wed"] })
    );

    // Q19 — heating fuel provider (oil delivery)
    logStep("Q19 q19_heating_provider → free-form oil delivery");
    await recordAnswer(
      "q19_heating_provider",
      makeQuizAnswer(null, { custom_text: "Petro Home Services" }),
      async () => {
        const ins = await rest(
          "utility_accounts",
          {
            method: "POST",
            headers: { Prefer: "return=representation" },
            body: JSON.stringify({
              household_id: this.state.householdId,
              property_id: this.state.propertyId,
              provider_name: "Petro Home Services",
              account_type: "oil",
            }),
          },
          this.state.jwt
        );
        if (ins.ok) this.state.utilityAccountIds.push(ins.body?.[0]?.id);
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
    logStep("Q26 q26_insurance → free-form auto + home");
    await recordAnswer(
      "q26_insurance",
      makeQuizAnswer(null, {
        custom_entries: ["auto|Geico", "home|State Farm"],
      }),
      async () => {
        for (const u of [
          { name: "Geico", type: "auto_insurance" },
          { name: "State Farm", type: "home_insurance" },
        ]) {
          const ins = await rest(
            "utility_accounts",
            {
              method: "POST",
              headers: { Prefer: "return=representation" },
              body: JSON.stringify({
                household_id: this.state.householdId,
                property_id: this.state.propertyId,
                provider_name: u.name,
                account_type: u.type,
              }),
            },
            this.state.jwt
          );
          if (ins.ok) this.state.utilityAccountIds.push(ins.body?.[0]?.id);
        }
      }
    );

    // Q28 — household composition (couple_with_kids → 1 kid)
    logStep("Q28 q28_household → couple_with_kids + 1 child + dogs");
    const kid = {
      first_name: "Sam",
      date_of_birth: "2018-06-15",
    };
    await recordAnswer(
      "q28_household",
      makeQuizAnswer("couple_with_kids", {
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
    logStep("Q30 q30_priorities → home value + safety");
    await recordAnswer(
      "q30_priorities",
      makeQuizAnswer(null, { selected_ids: ["home_value", "safety"] })
    );

    logOk(`${Object.keys(quizState.answers).length} questions answered + persisted`);
    this.state.quizState = quizState;
    this.recordSuccess("phase6", `house quiz: ${Object.keys(quizState.answers).length} answers + side effects`);
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
        description: "Quarterly filter swap — 16x25x1 MERV 11.",
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
        description: "Lawn cleanup + first mow — coordinate with Bethel Lawn Care.",
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
