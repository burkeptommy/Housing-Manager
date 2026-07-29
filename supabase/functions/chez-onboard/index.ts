// Chez Onboard Edge Function (Wave 2 — white-glove onboarding capture).
//
// Backs the tokenized capture page (website/onboard.html) the operator
// uses on-site to set up a customer's entire home. The capture store is
// the EXISTING home_assessments row (captured_* JSONB, Phase 84.5); the
// onboarding_sessions table (20270115) only scopes the access token and
// session lifecycle.
//
// Two auth tiers:
//   - Token actions: body carries `token` (onboarding_sessions.token).
//     No JWT. Validated per-call via the service role: session exists,
//     status='active' (revoked → 410, lazy-expire → stamp + 410). Every
//     read/write is scoped to the session's assessment/household/property.
//     The client NEVER supplies a household_id/assessment_id on these.
//   - Admin actions: Authorization Bearer JWT whose verified email is in
//     CHEZ_ADMIN_EMAILS (same pattern as chez-concierge). Non-admin → 403.
//
// Token actions:  bootstrap / start_visit / save_capture /
//                 add_recommendation / list_recommendations /
//                 delete_recommendation / upload_photo /
//                 identify_equipment / submit
// Admin actions:  create_onboarding_session / create_customer_household /
//                 list_onboarding_sessions / get_onboarding_session /
//                 revoke_onboarding_session / extend_onboarding_session /
//                 run_ingestion
//
// Homeowner-facing copy always says "Chez". No em dashes in copy.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { ingestAssessment } from "../_shared/assessment-ingestion.ts";
import {
  CHIP_TO_ROUTINE_KIND,
  defaultCadenceForQuizRoutine,
  HOUSEHOLD_CONTRACTOR_CATEGORY,
} from "../_shared/quiz-mapper-shared.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type ServiceClient = ReturnType<typeof createClient>;

const ONBOARD_PAGE_BASE = "https://www.getchez.com/onboard.html";
const CAPTURE_MAX_BYTES = 512 * 1024; // 512KB JSON payload cap
const PHOTO_MAX_BYTES = 8 * 1024 * 1024; // 8MB decoded photo cap
const IDENTIFY_CALL_CAP = 40; // per-session identify-equipment proxy cap
const DEFAULT_SESSION_HOURS = 24;
const INVITE_EXPIRY_DAYS = 90;

// Assessment statuses where the operator may still write capture data.
// pending/scheduled/en_route can exist when the assessment predates the
// session (legacy dispatch rows); everything at or past submitted is
// read-only from the capture page.
const WRITABLE_ASSESSMENT_STATUSES = [
  "pending",
  "scheduled",
  "en_route",
  "in_progress",
];

// Assessment statuses that block attaching a new onboarding session.
const POST_VISIT_ASSESSMENT_STATUSES = [
  "submitted",
  "awaiting_review",
  "corrections_requested",
  "ingestion_failed",
];

const URGENCIES = ["urgent", "soon", "next_season", "opportunistic"];
const RECOMMENDED_OWNERS = ["homeowner_diy", "chez_handyman", "chez_vendor"];
const CONDITION_RATINGS = ["good", "fair", "needs_attention", "urgent"];
const UTILITY_TYPES = [
  "electric",
  "natural_gas",
  "propane",
  "oil",
  "water",
  "sewer",
  "internet_cable",
  "trash",
  "security",
  "solar",
  "other",
];
const CADENCE_TYPES = [
  "weekly",
  "biweekly",
  "triweekly",
  "monthly",
  "quarterly",
  "semiannual",
  "annual",
  "custom_days",
];

// Staple system categories appended after the chip-derived canonicals
// (dedup, stable order) so the page never hardcodes the registry.
const SYSTEM_CATEGORY_STAPLES = [
  "HVAC",
  "Plumbing",
  "Electrical",
  "Water Heater",
  "Well System",
  "Septic System",
  "Sump Pump",
  "Boiler",
  "Furnace",
  "Generator",
  "Pool/Spa",
  "Hot Tub",
  "Irrigation",
  "Landscaping",
  "Roofing",
  "Chimney",
  "Garage Door",
  "Security",
  "Water Treatment",
  "Appliance",
  "Solar",
  "Elevator",
  "Wine Cellar",
];

// Human labels for the Q15b chip ids served in dictionaries.vendor_chips.
const VENDOR_CHIP_LABELS: Record<string, string> = {
  hvac_service: "HVAC service",
  plumber: "Plumber",
  electrician: "Electrician",
  roofer: "Roofer",
  septic_pumper: "Septic pumper",
  well_water_service: "Well water service",
  chimney_sweep: "Chimney sweep",
  tree_service: "Tree service",
  hardscape: "Hardscape",
  generator_service: "Generator service",
  handyman: "Handyman",
  cleaning: "Cleaning service",
  snow_removal: "Snow removal",
  mosquito_tick: "Mosquito & tick",
  pet_waste: "Pet waste removal",
  pool_service: "Pool service",
  solar_service: "Solar service",
  security_service: "Security system",
  waterproofing: "Waterproofing",
};

// Human labels for routine kinds served in dictionaries.routine_kinds.
const ROUTINE_KIND_LABELS: Record<string, string> = {
  hvac_service: "HVAC service",
  plumbing: "Plumbing",
  electrical: "Electrical",
  roofing: "Roofing",
  septic: "Septic",
  well: "Well service",
  chimney: "Chimney",
  tree_service: "Tree service",
  landscaping: "Landscaping",
  generator: "Generator",
  handyman_recurring: "Recurring handyman",
  cleaning: "Cleaning",
  snow_removal: "Snow removal",
  mosquito_tick: "Mosquito & tick",
  pet_waste: "Pet waste",
  pool_service: "Pool service",
  solar_service: "Solar service",
  security: "Security",
  waterproofing: "Waterproofing",
};

interface OnboardingSessionRow {
  id: string;
  assessment_id: string;
  household_id: string;
  property_id: string;
  token: string;
  onboarder_type: string;
  onboarder_label: string | null;
  status: "active" | "completed" | "expired" | "revoked";
  require_operator_review: boolean;
  expires_at: string;
  last_opened_at: string | null;
  opened_count: number;
  identify_call_count: number;
  created_by_user_id: string | null;
  created_at: string;
  updated_at: string;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function compactString(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function isoNow() {
  return new Date().toISOString();
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function asObject(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function adminEmails(): string[] {
  return (Deno.env.get("CHEZ_ADMIN_EMAILS") ?? "tom@getchez.com")
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
}

async function getAuthenticatedUser(service: ServiceClient, req: Request) {
  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice("Bearer ".length) : "";
  if (!token) return null;
  const { data, error } = await service.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}

function isAdminUser(user: { email?: string | null } | null): boolean {
  if (!user?.email) return false;
  return adminEmails().includes(user.email.toLowerCase());
}

/** 32 random bytes → base64url, no padding. */
function generateSessionToken(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

/** Readable 8-char invite code. Confusion-free alphabet (no 0/O/1/I),
 *  matching DatabaseService.generateInviteCode's character set. */
function generateInviteCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = new Uint8Array(8);
  crypto.getRandomValues(bytes);
  let code = "";
  for (const b of bytes) code += chars[b % chars.length];
  return code;
}

/** Sanitize a filename to [a-zA-Z0-9._-] only, capped at 80 chars. */
function sanitizeFilename(name: string): string {
  const cleaned = (name || "")
    .replace(/[^a-zA-Z0-9._-]+/g, "-")
    .replace(/^[-.]+|[-.]+$/g, "")
    .slice(0, 80);
  return cleaned || "photo.jpg";
}

/** Decode a base64 (optionally data-URI prefixed) string to bytes. */
function decodeBase64Body(raw: string): Uint8Array {
  const cleaned = raw.includes(",") ? raw.split(",", 2)[1] : raw;
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

// ============================================================================
// Dictionaries — derived from _shared/quiz-mapper-shared.ts so the web page
// never hardcodes the registry.
// ============================================================================

function buildDictionaries() {
  // system_categories: distinct canonical values of the chip map, then the
  // staples appended if absent. Stable order, deduped.
  const systemCategories: string[] = [];
  for (const value of Object.values(HOUSEHOLD_CONTRACTOR_CATEGORY)) {
    if (!systemCategories.includes(value)) systemCategories.push(value);
  }
  for (const staple of SYSTEM_CATEGORY_STAPLES) {
    if (!systemCategories.includes(staple)) systemCategories.push(staple);
  }

  const vendorChips = Object.keys(HOUSEHOLD_CONTRACTOR_CATEGORY).map((id) => ({
    id,
    label: VENDOR_CHIP_LABELS[id] ?? id.replace(/_/g, " "),
    category: HOUSEHOLD_CONTRACTOR_CATEGORY[id],
  }));

  const seenKinds: string[] = [];
  for (const kind of Object.values(CHIP_TO_ROUTINE_KIND)) {
    if (!seenKinds.includes(kind)) seenKinds.push(kind);
  }
  const routineKinds = seenKinds.map((kind) => {
    const cadence = defaultCadenceForQuizRoutine(kind);
    return {
      id: kind,
      label: ROUTINE_KIND_LABELS[kind] ?? kind.replace(/_/g, " "),
      default_cadence: {
        cadenceType: cadence.cadenceType,
        cadenceIntervalDays: cadence.cadenceIntervalDays,
        daysOfWeek: null,
        activeMonths: cadence.activeMonths,
      },
    };
  });

  return {
    system_categories: systemCategories,
    vendor_chips: vendorChips,
    routine_kinds: routineKinds,
    utility_types: UTILITY_TYPES,
    cadence_types: CADENCE_TYPES,
    condition_ratings: CONDITION_RATINGS,
    urgencies: URGENCIES,
  };
}

// ============================================================================
// Token session validation — re-run on EVERY token action.
// ============================================================================

type SessionCheck =
  | { ok: true; session: OnboardingSessionRow }
  | { ok: false; response: Response };

async function loadSessionByToken(
  service: ServiceClient,
  token: string
): Promise<SessionCheck> {
  if (!token) {
    return { ok: false, response: json({ error: "Missing token" }, 400) };
  }

  const { data, error } = await service
    .from("onboarding_sessions")
    .select("*")
    .eq("token", token)
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error("[chez-onboard] session fetch error:", error);
    return {
      ok: false,
      response: json({ error: "Failed to load session" }, 500),
    };
  }
  if (!data) {
    return { ok: false, response: json({ error: "link not found" }, 404) };
  }

  const session = data as unknown as OnboardingSessionRow;

  if (session.status === "revoked") {
    return { ok: false, response: json({ error: "link revoked" }, 410) };
  }
  if (session.status === "expired") {
    return { ok: false, response: json({ error: "link expired" }, 410) };
  }
  if (session.status !== "active") {
    // completed or any future terminal state
    return { ok: false, response: json({ error: "link already used" }, 410) };
  }

  // Lazy-expire: stamp status='expired' and reject.
  if (session.expires_at && new Date(session.expires_at).getTime() < Date.now()) {
    await service
      .from("onboarding_sessions")
      .update({ status: "expired", updated_at: isoNow() })
      .eq("id", session.id);
    return { ok: false, response: json({ error: "link expired" }, 410) };
  }

  return { ok: true, session };
}

async function loadAssessment(
  service: ServiceClient,
  assessmentId: string
): Promise<Record<string, unknown> | null> {
  const { data, error } = await service
    .from("home_assessments")
    .select("*")
    .eq("id", assessmentId)
    .maybeSingle();
  if (error) {
    console.error("[chez-onboard] assessment fetch error:", error);
    return null;
  }
  return (data as Record<string, unknown> | null) ?? null;
}

function capturedBlock(assessment: Record<string, unknown>) {
  return {
    systems: asArray(assessment.captured_systems),
    contractors: asArray(assessment.captured_contractors),
    routines: asArray(assessment.captured_routines),
    utility_accounts: asArray(assessment.captured_utility_accounts),
    vehicles: asArray(assessment.captured_vehicles),
    attributes: asObject(assessment.captured_attributes),
    quick_fixes: asArray(assessment.captured_quick_fixes),
    document_paths: asArray(assessment.captured_document_paths),
  };
}

async function fetchRecommendations(
  service: ServiceClient,
  assessmentId: string
): Promise<Record<string, unknown>[]> {
  const { data, error } = await service
    .from("assessment_recommended_tasks")
    .select(
      "id, title, description, urgency, zone, estimated_cost_cents, recommended_owner, photos, created_at"
    )
    .eq("assessment_id", assessmentId)
    .order("created_at", { ascending: true });
  if (error) {
    console.error("[chez-onboard] recommendations fetch error:", error);
    return [];
  }
  return (data as Record<string, unknown>[] | null) ?? [];
}

/** Best-effort homeowner first name from the household's primary user or
 *  family members. Null is fine. */
async function homeownerFirstName(
  service: ServiceClient,
  householdId: string
): Promise<string | null> {
  try {
    const { data: users } = await service
      .from("users")
      .select("full_name, created_at")
      .eq("household_id", householdId)
      .order("created_at", { ascending: true })
      .limit(5);
    for (const row of (users as Record<string, unknown>[] | null) ?? []) {
      const name = compactString(row.full_name);
      if (name) return name.split(/\s+/)[0];
    }

    const { data: members } = await service
      .from("family_members")
      .select("first_name, created_at")
      .eq("household_id", householdId)
      .order("created_at", { ascending: true })
      .limit(5);
    for (const row of (members as Record<string, unknown>[] | null) ?? []) {
      const name = compactString(row.first_name);
      if (name) return name;
    }
  } catch (error) {
    console.error("[chez-onboard] homeownerFirstName error:", error);
  }
  return null;
}

/** The shared bootstrap-shaped payload (session + property + household +
 *  assessment). Used by bootstrap (token) and get_onboarding_session (admin). */
async function buildSessionPayload(
  service: ServiceClient,
  session: OnboardingSessionRow,
  opts?: { includeAdminFields?: boolean }
) {
  const [propertyResult, householdResult, assessment, firstName] =
    await Promise.all([
      service
        .from("properties")
        .select(
          "id, street, city, state, zip_code, property_type, year_built, square_footage"
        )
        .eq("id", session.property_id)
        .maybeSingle(),
      service
        .from("households")
        .select("id, name")
        .eq("id", session.household_id)
        .maybeSingle(),
      loadAssessment(service, session.assessment_id),
      homeownerFirstName(service, session.household_id),
    ]);

  const property = (propertyResult.data as Record<string, unknown> | null) ?? null;
  const household = (householdResult.data as Record<string, unknown> | null) ?? null;
  const recommendations = assessment
    ? await fetchRecommendations(service, session.assessment_id)
    : [];

  const sessionBlock: Record<string, unknown> = {
    id: session.id,
    status: session.status,
    expires_at: session.expires_at,
    onboarder_type: session.onboarder_type,
    require_operator_review: session.require_operator_review,
  };
  if (opts?.includeAdminFields) {
    sessionBlock.token = session.token;
    sessionBlock.onboarder_label = session.onboarder_label;
    sessionBlock.last_opened_at = session.last_opened_at;
    sessionBlock.opened_count = session.opened_count;
    sessionBlock.identify_call_count = session.identify_call_count;
    sessionBlock.created_at = session.created_at;
    sessionBlock.url = `${ONBOARD_PAGE_BASE}?session=${session.token}`;
  }

  return {
    session: sessionBlock,
    property: property
      ? {
        id: property.id,
        street: property.street ?? null,
        city: property.city ?? null,
        state: property.state ?? null,
        zip_code: property.zip_code ?? null,
        property_type: property.property_type ?? null,
        year_built: property.year_built ?? null,
        square_footage: property.square_footage ?? null,
      }
      : null,
    household: household
      ? {
        id: household.id,
        name: household.name ?? null,
        homeowner_first_name: firstName,
      }
      : null,
    assessment: assessment
      ? {
        id: assessment.id,
        status: assessment.status,
        pre_visit_notes: assessment.pre_visit_notes ?? null,
        homeowner_concerns: assessment.homeowner_concerns ?? null,
        // homeowner_wrapup_notes is the verified column name for the
        // contract's wrap_up_notes. Served so the page restores its
        // wrap-up state on refresh.
        wrap_up_notes: assessment.homeowner_wrapup_notes ?? null,
        captured: capturedBlock(assessment),
        recommendations,
      }
      : null,
  };
}

// ============================================================================
// Token actions
// ============================================================================

async function handleBootstrap(
  service: ServiceClient,
  session: OnboardingSessionRow
) {
  // Stamp last_opened_at + increment opened_count (bootstrap only).
  await service
    .from("onboarding_sessions")
    .update({
      last_opened_at: isoNow(),
      opened_count: (session.opened_count ?? 0) + 1,
      updated_at: isoNow(),
    })
    .eq("id", session.id);

  const payload = await buildSessionPayload(service, session);
  if (!payload.assessment) {
    return json({ error: "Assessment not found for this link" }, 404);
  }

  return json({ ...payload, dictionaries: buildDictionaries() });
}

async function handleStartVisit(
  service: ServiceClient,
  session: OnboardingSessionRow
) {
  const assessment = await loadAssessment(service, session.assessment_id);
  if (!assessment) return json({ error: "Assessment not found" }, 404);

  const status = compactString(assessment.status);
  const preVisit = ["pending", "scheduled", "en_route"];
  if (!preVisit.includes(status)) {
    // Idempotent: already in_progress / submitted / anything else — report
    // the current status without flipping anything.
    return json({ ok: true, status });
  }

  const update: Record<string, unknown> = { status: "in_progress" };
  if (!assessment.started_at) update.started_at = isoNow();

  const { error } = await service
    .from("home_assessments")
    .update(update)
    .eq("id", session.assessment_id);
  if (error) {
    console.error("[chez-onboard] start_visit update error:", error);
    return json({ error: "Failed to start visit" }, 500);
  }

  return json({ ok: true, status: "in_progress" });
}

async function handleSaveCapture(
  service: ServiceClient,
  session: OnboardingSessionRow,
  body: Record<string, unknown>
) {
  const capture = body.capture;
  if (!capture || typeof capture !== "object" || Array.isArray(capture)) {
    return json({ error: "Missing capture object" }, 400);
  }

  let serialized: string;
  try {
    serialized = JSON.stringify(capture);
  } catch {
    return json({ error: "Capture payload is not serializable" }, 400);
  }
  if (serialized.length > CAPTURE_MAX_BYTES) {
    return json({ error: "Capture payload too large (512KB max)" }, 413);
  }

  const assessment = await loadAssessment(service, session.assessment_id);
  if (!assessment) return json({ error: "Assessment not found" }, 404);
  const status = compactString(assessment.status);
  if (!WRITABLE_ASSESSMENT_STATUSES.includes(status)) {
    return json(
      { error: "This visit has already been submitted", assessment_status: status },
      409
    );
  }

  const cap = capture as Record<string, unknown>;
  const update: Record<string, unknown> = {};

  // REPLACE semantics per present section — the page owns full local
  // state (single operator per visit, no merging). Absent keys untouched.
  const arrayColumns = [
    "captured_systems",
    "captured_contractors",
    "captured_routines",
    "captured_utility_accounts",
    "captured_vehicles",
    "captured_quick_fixes",
  ];
  for (const column of arrayColumns) {
    if (column in cap) {
      if (!Array.isArray(cap[column])) {
        return json({ error: `${column} must be an array` }, 400);
      }
      update[column] = cap[column];
    }
  }
  if ("captured_attributes" in cap) {
    const attrs = cap.captured_attributes;
    if (!attrs || typeof attrs !== "object" || Array.isArray(attrs)) {
      return json({ error: "captured_attributes must be an object" }, 400);
    }
    update.captured_attributes = attrs;
  }
  if ("homeowner_concerns" in cap) {
    update.homeowner_concerns = compactString(cap.homeowner_concerns) || null;
  }
  // Verified schema reality: the wrap-up text column on home_assessments
  // is homeowner_wrapup_notes (20261211 G24), not wrap_up_notes.
  if ("wrap_up_notes" in cap) {
    update.homeowner_wrapup_notes = compactString(cap.wrap_up_notes) || null;
  }

  if (Object.keys(update).length === 0) {
    return json({ error: "No capture fields provided" }, 400);
  }

  const { data: updated, error } = await service
    .from("home_assessments")
    .update(update)
    .eq("id", session.assessment_id)
    .select(
      "captured_systems, captured_contractors, captured_routines, captured_utility_accounts, captured_vehicles, captured_quick_fixes"
    )
    .single();
  if (error) {
    console.error("[chez-onboard] save_capture update error:", error);
    return json({ error: "Failed to save capture" }, 500);
  }

  const row = updated as Record<string, unknown>;
  return json({
    ok: true,
    counts: {
      systems: asArray(row.captured_systems).length,
      contractors: asArray(row.captured_contractors).length,
      routines: asArray(row.captured_routines).length,
      utilities: asArray(row.captured_utility_accounts).length,
      vehicles: asArray(row.captured_vehicles).length,
      quick_fixes: asArray(row.captured_quick_fixes).length,
    },
  });
}

async function handleAddRecommendation(
  service: ServiceClient,
  session: OnboardingSessionRow,
  body: Record<string, unknown>
) {
  const rec = asObject(body.recommendation);
  const title = compactString(rec.title);
  if (!title) return json({ error: "Missing recommendation title" }, 400);

  const urgency = compactString(rec.urgency);
  if (!URGENCIES.includes(urgency)) {
    return json(
      { error: `urgency must be one of: ${URGENCIES.join(", ")}` },
      400
    );
  }

  // recommended_owner is NOT NULL in assessment_recommended_tasks —
  // default to chez_handyman when the page omits it.
  let recommendedOwner = compactString(rec.recommended_owner) || "chez_handyman";
  if (!RECOMMENDED_OWNERS.includes(recommendedOwner)) {
    recommendedOwner = "chez_handyman";
  }

  const assessment = await loadAssessment(service, session.assessment_id);
  if (!assessment) return json({ error: "Assessment not found" }, 404);
  const status = compactString(assessment.status);
  if (!WRITABLE_ASSESSMENT_STATUSES.includes(status)) {
    return json(
      { error: "This visit has already been submitted", assessment_status: status },
      409
    );
  }

  const costRaw = rec.estimated_cost_cents;
  const estimatedCostCents =
    typeof costRaw === "number" && Number.isFinite(costRaw) && costRaw >= 0
      ? Math.round(costRaw)
      : null;

  const photos = asArray(rec.photos)
    .map((p) => compactString(p))
    .filter(Boolean);

  const { data, error } = await service
    .from("assessment_recommended_tasks")
    .insert({
      assessment_id: session.assessment_id,
      title,
      description: compactString(rec.description) || null,
      zone: compactString(rec.zone) || null,
      urgency,
      recommended_owner: recommendedOwner,
      estimated_cost_cents: estimatedCostCents,
      photos,
      observation_source: "handyman_observed",
    })
    .select("id")
    .single();
  if (error) {
    console.error("[chez-onboard] add_recommendation insert error:", error);
    return json({ error: "Failed to save recommendation" }, 500);
  }

  return json({ ok: true, id: (data as { id: string }).id });
}

async function handleListRecommendations(
  service: ServiceClient,
  session: OnboardingSessionRow
) {
  const items = await fetchRecommendations(service, session.assessment_id);
  return json({ items });
}

async function handleUpdateRecommendation(
  service: ServiceClient,
  session: OnboardingSessionRow,
  body: Record<string, unknown>
) {
  const id = compactString(body.id);
  if (!id) return json({ error: "Missing id" }, 400);
  const rec = asObject(body.recommendation);
  const title = compactString(rec.title);
  if (!title) return json({ error: "Missing recommendation title" }, 400);

  const urgency = compactString(rec.urgency);
  if (!URGENCIES.includes(urgency)) {
    return json(
      { error: `urgency must be one of: ${URGENCIES.join(", ")}` },
      400
    );
  }

  let recommendedOwner = compactString(rec.recommended_owner) || "chez_handyman";
  if (!RECOMMENDED_OWNERS.includes(recommendedOwner)) {
    recommendedOwner = "chez_handyman";
  }

  const assessment = await loadAssessment(service, session.assessment_id);
  if (!assessment) return json({ error: "Assessment not found" }, 404);
  const status = compactString(assessment.status);
  if (!WRITABLE_ASSESSMENT_STATUSES.includes(status)) {
    return json(
      { error: "This visit has already been submitted", assessment_status: status },
      409
    );
  }

  const costRaw = rec.estimated_cost_cents;
  const estimatedCostCents =
    typeof costRaw === "number" && Number.isFinite(costRaw) && costRaw >= 0
      ? Math.round(costRaw)
      : null;

  const photos = asArray(rec.photos)
    .map((p) => compactString(p))
    .filter(Boolean);

  // Scoped update: only rows belonging to this session's assessment.
  const { data, error } = await service
    .from("assessment_recommended_tasks")
    .update({
      title,
      description: compactString(rec.description) || null,
      zone: compactString(rec.zone) || null,
      urgency,
      recommended_owner: recommendedOwner,
      estimated_cost_cents: estimatedCostCents,
      photos,
    })
    .eq("id", id)
    .eq("assessment_id", session.assessment_id)
    .select("id");
  if (error) {
    console.error("[chez-onboard] update_recommendation error:", error);
    return json({ error: "Failed to update recommendation" }, 500);
  }
  if (!data || (data as unknown[]).length === 0) {
    return json({ error: "Recommendation not found" }, 404);
  }

  return json({ ok: true });
}

async function handleDeleteRecommendation(
  service: ServiceClient,
  session: OnboardingSessionRow,
  body: Record<string, unknown>
) {
  const id = compactString(body.id);
  if (!id) return json({ error: "Missing id" }, 400);

  const assessment = await loadAssessment(service, session.assessment_id);
  if (!assessment) return json({ error: "Assessment not found" }, 404);
  const status = compactString(assessment.status);
  if (!WRITABLE_ASSESSMENT_STATUSES.includes(status)) {
    return json(
      { error: "This visit has already been submitted", assessment_status: status },
      409
    );
  }

  // Scoped delete: only rows belonging to this session's assessment.
  const { error } = await service
    .from("assessment_recommended_tasks")
    .delete()
    .eq("id", id)
    .eq("assessment_id", session.assessment_id);
  if (error) {
    console.error("[chez-onboard] delete_recommendation error:", error);
    return json({ error: "Failed to delete recommendation" }, 500);
  }

  return json({ ok: true });
}

async function handleUploadPhoto(
  service: ServiceClient,
  session: OnboardingSessionRow,
  body: Record<string, unknown>
) {
  const kind = compactString(body.kind);
  const validKinds = ["system", "quick_fix", "recommendation", "document"];
  if (!validKinds.includes(kind)) {
    return json({ error: `kind must be one of: ${validKinds.join(", ")}` }, 400);
  }

  const base64 = compactString(body.base64);
  if (!base64) return json({ error: "Missing base64" }, 400);

  const filename = sanitizeFilename(compactString(body.filename) || "photo.jpg");
  const contentType = compactString(body.content_type) || "image/jpeg";

  let bytes: Uint8Array;
  try {
    bytes = decodeBase64Body(base64);
  } catch {
    return json({ error: "Invalid base64 payload" }, 400);
  }
  if (bytes.length === 0) return json({ error: "Empty file" }, 400);
  if (bytes.length > PHOTO_MAX_BYTES) {
    return json({ error: "File too large (8MB max)" }, 413);
  }

  const isDocument = kind === "document";
  const bucket = isDocument ? "documents" : "home-system-photos";
  const path = isDocument
    ? `assessments/${session.assessment_id}/${Date.now()}-${filename}`
    : `${session.household_id}/onboarding/${session.assessment_id}/${Date.now()}-${filename}`;

  const { error: uploadError } = await service.storage
    .from(bucket)
    .upload(path, bytes, { contentType });
  if (uploadError) {
    console.error("[chez-onboard] upload_photo storage error:", uploadError);
    return json({ error: "Upload failed" }, 500);
  }

  // Documents also register on the assessment's captured_document_paths so
  // ingestion picks them up.
  if (isDocument) {
    const assessment = await loadAssessment(service, session.assessment_id);
    if (assessment) {
      const existing = asArray(assessment.captured_document_paths);
      const { error: pathError } = await service
        .from("home_assessments")
        .update({ captured_document_paths: [...existing, path] })
        .eq("id", session.assessment_id);
      if (pathError) {
        console.error(
          "[chez-onboard] captured_document_paths append error:",
          pathError
        );
      }
    }
  }

  let signedUrl: string | null = null;
  const { data: signed, error: signError } = await service.storage
    .from(bucket)
    .createSignedUrl(path, 3600);
  if (signError) {
    console.error("[chez-onboard] signed url error:", signError);
  } else {
    signedUrl = (signed as { signedUrl?: string } | null)?.signedUrl ?? null;
  }

  return json({ ok: true, path, signed_url: signedUrl });
}

async function handleIdentifyEquipment(
  service: ServiceClient,
  session: OnboardingSessionRow,
  body: Record<string, unknown>,
  supabaseUrl: string,
  serviceRoleKey: string
) {
  const imageBase64 = compactString(body.image_base64);
  if (!imageBase64) return json({ error: "Missing image_base64" }, 400);

  if ((session.identify_call_count ?? 0) >= IDENTIFY_CALL_CAP) {
    return json({ error: "identify limit reached for this visit" }, 429);
  }

  // Increment the per-session counter before proxying so retries against
  // a slow upstream still burn quota.
  await service
    .from("onboarding_sessions")
    .update({
      identify_call_count: (session.identify_call_count ?? 0) + 1,
      updated_at: isoNow(),
    })
    .eq("id", session.id);

  try {
    const resp = await fetch(`${supabaseUrl}/functions/v1/identify-equipment`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        image_base64: imageBase64,
        category: compactString(body.category) || null,
      }),
    });
    if (!resp.ok) {
      const errText = await resp.text();
      console.error(
        "[chez-onboard] identify-equipment proxy failed:",
        resp.status,
        errText.slice(0, 500)
      );
      return json({ error: "Equipment identification failed" }, 502);
    }
    const result = await resp.json();
    return json({ ok: true, result });
  } catch (error) {
    console.error("[chez-onboard] identify-equipment proxy error:", error);
    return json({ error: "Equipment identification failed" }, 502);
  }
}

async function handleSubmit(
  service: ServiceClient,
  session: OnboardingSessionRow,
  body: Record<string, unknown>
) {
  const assessment = await loadAssessment(service, session.assessment_id);
  if (!assessment) return json({ error: "Assessment not found" }, 404);
  const status = compactString(assessment.status);
  if (!WRITABLE_ASSESSMENT_STATUSES.includes(status)) {
    return json(
      { error: "This visit has already been submitted", assessment_status: status },
      409
    );
  }

  const update: Record<string, unknown> = {
    status: "submitted",
    submitted_at: isoNow(),
  };
  const wrapUp = compactString(body.wrap_up_notes);
  if (wrapUp) update.homeowner_wrapup_notes = wrapUp;

  const { error: submitError } = await service
    .from("home_assessments")
    .update(update)
    .eq("id", session.assessment_id);
  if (submitError) {
    console.error("[chez-onboard] submit update error:", submitError);
    return json({ error: "Failed to submit visit" }, 500);
  }

  if (session.require_operator_review) {
    // Handyman flow: park at submitted; the operator runs ingestion from
    // the service portal (run_ingestion).
    await service
      .from("onboarding_sessions")
      .update({ status: "completed", updated_at: isoNow() })
      .eq("id", session.id);
    return json({ ok: true, ingested: false, awaiting_review: true });
  }

  // Founder flow: auto-ingest on submit.
  let ingestSummary;
  try {
    ingestSummary = await ingestAssessment(service, session.assessment_id, {
      onboardedVia: "chez_onboarding",
    });
  } catch (error) {
    console.error("[chez-onboard] ingestion error:", error);
    // Keep the session active so the operator can retry from the portal.
    await service
      .from("home_assessments")
      .update({
        status: "ingestion_failed",
        ingestion_error: String(
          (error as { message?: string })?.message ?? error
        ).slice(0, 2000),
      })
      .eq("id", session.assessment_id);
    return json({ ok: false, ingested: false, error: "ingestion failed" });
  }

  await service
    .from("onboarding_sessions")
    .update({ status: "completed", updated_at: isoNow() })
    .eq("id", session.id);
  return json({ ok: true, ingested: true, ingest_summary: ingestSummary });
}

// ============================================================================
// Admin actions
// ============================================================================

async function handleCreateOnboardingSession(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>
) {
  const householdId = compactString(body.household_id);
  const propertyId = compactString(body.property_id);
  if (!householdId || !propertyId) {
    return json({ error: "Missing household_id or property_id" }, 400);
  }

  // Verify the property belongs to the household before touching anything.
  const { data: property, error: propError } = await service
    .from("properties")
    .select("id")
    .eq("id", propertyId)
    .eq("household_id", householdId)
    .maybeSingle();
  if (propError) {
    console.error("[chez-onboard] property check error:", propError);
    return json({ error: "Failed to verify property" }, 500);
  }
  if (!property) {
    return json({ error: "Property not found for this household" }, 404);
  }

  // Find-or-create the assessment (idempotent RPC from 20261210).
  const { data: rpcData, error: rpcError } = await service.rpc(
    "find_or_create_home_assessment",
    { p_property_id: propertyId, p_household_id: householdId }
  );
  if (rpcError || !rpcData) {
    console.error("[chez-onboard] find_or_create rpc error:", rpcError);
    return json({ error: "Failed to prepare assessment" }, 500);
  }
  const assessment = (Array.isArray(rpcData) ? rpcData[0] : rpcData) as Record<
    string,
    unknown
  >;
  const assessmentId = compactString(assessment.id);
  const assessmentStatus = compactString(assessment.status);
  if (!assessmentId) {
    return json({ error: "Failed to prepare assessment" }, 500);
  }
  if (POST_VISIT_ASSESSMENT_STATUSES.includes(assessmentStatus)) {
    return json(
      {
        error: "assessment already in post-visit state",
        assessment_status: assessmentStatus,
      },
      409
    );
  }

  // Revoke-then-recreate is the token rotation path (partial unique index
  // allows one active session per assessment).
  const { error: revokeError } = await service
    .from("onboarding_sessions")
    .update({ status: "revoked", updated_at: isoNow() })
    .eq("assessment_id", assessmentId)
    .eq("status", "active");
  if (revokeError) {
    console.error("[chez-onboard] revoke existing session error:", revokeError);
    return json({ error: "Failed to rotate existing link" }, 500);
  }

  const hoursRaw = body.expires_hours;
  const expiresHours =
    typeof hoursRaw === "number" && Number.isFinite(hoursRaw) && hoursRaw > 0
      ? Math.min(hoursRaw, 24 * 14)
      : DEFAULT_SESSION_HOURS;
  const expiresAt = new Date(
    Date.now() + expiresHours * 60 * 60 * 1000
  ).toISOString();

  const onboarderType =
    compactString(body.onboarder_type) === "handyman" ? "handyman" : "founder";
  const requireReview = body.require_operator_review === true;

  const token = generateSessionToken();
  const { data: created, error: insertError } = await service
    .from("onboarding_sessions")
    .insert({
      assessment_id: assessmentId,
      household_id: householdId,
      property_id: propertyId,
      token,
      onboarder_type: onboarderType,
      onboarder_label: compactString(body.onboarder_label) || null,
      status: "active",
      require_operator_review: requireReview,
      expires_at: expiresAt,
      created_by_user_id: user.id,
    })
    .select("*")
    .single();
  if (insertError || !created) {
    console.error("[chez-onboard] session insert error:", insertError);
    return json({ error: "Failed to create onboarding session" }, 500);
  }

  return json({
    ok: true,
    session: created,
    url: `${ONBOARD_PAGE_BASE}?session=${token}`,
  });
}

async function handleCreateCustomerHousehold(
  service: ServiceClient,
  user: { id: string },
  body: Record<string, unknown>,
  supabaseUrl: string,
  serviceRoleKey: string
) {
  const name = compactString(body.name);
  const email = compactString(body.email).toLowerCase();
  const street = compactString(body.street);
  const city = compactString(body.city);
  const state = compactString(body.state);
  const zipCode = compactString(body.zip_code);
  if (!name || !email || !street || !city || !state || !zipCode) {
    return json(
      { error: "Missing required fields (name, email, street, city, state, zip_code)" },
      400
    );
  }
  const propertyType = compactString(body.property_type) || "single_family";

  // 1. Household + property rows.
  const { data: household, error: householdError } = await service
    .from("households")
    .insert({ name })
    .select("id")
    .single();
  if (householdError || !household) {
    console.error("[chez-onboard] household insert error:", householdError);
    return json({ error: "Failed to create household" }, 500);
  }
  const householdId = (household as { id: string }).id;

  const { data: propertyRow, error: propertyError } = await service
    .from("properties")
    .insert({
      household_id: householdId,
      name: street,
      property_type: propertyType,
      street,
      city,
      state,
      zip_code: zipCode,
    })
    .select("id")
    .single();
  if (propertyError || !propertyRow) {
    console.error("[chez-onboard] property insert error:", propertyError);
    return json({ error: "Failed to create property", household_id: householdId }, 500);
  }
  const propertyId = (propertyRow as { id: string }).id;

  // 2. Best-effort ATTOM enrichment via property-lookup. Non-fatal.
  try {
    const address = `${street}, ${city}, ${state} ${zipCode}`;
    const resp = await fetch(`${supabaseUrl}/functions/v1/property-lookup`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ address }),
    });
    if (resp.ok) {
      const lookup = (await resp.json()) as {
        success?: boolean;
        property?: Record<string, unknown> | null;
      };
      const result = lookup?.success ? lookup.property ?? null : null;
      if (result) {
        const enrich: Record<string, unknown> = {};
        if (typeof result.yearBuilt === "number") {
          enrich.year_built = result.yearBuilt;
        }
        if (typeof result.squareFootage === "number") {
          enrich.square_footage = Math.round(result.squareFootage as number);
        }
        if (typeof result.estimatedValue === "number") {
          enrich.current_estimated_value = result.estimatedValue;
          if (typeof result.estimatedValueLow === "number") {
            enrich.current_estimated_value_low = result.estimatedValueLow;
          }
          if (typeof result.estimatedValueHigh === "number") {
            enrich.current_estimated_value_high = result.estimatedValueHigh;
          }
          if (compactString(result.estimatedValueSource)) {
            enrich.estimated_value_source = result.estimatedValueSource;
          }
          if (typeof result.estimatedValueConfidence === "number") {
            enrich.estimated_value_confidence = Math.round(
              result.estimatedValueConfidence as number
            );
          }
        }
        if (Object.keys(enrich).length > 0) {
          const { error: enrichError } = await service
            .from("properties")
            .update(enrich)
            .eq("id", propertyId);
          if (enrichError) {
            console.error("[chez-onboard] enrich update error:", enrichError);
          }
        }
      }
    } else {
      console.error(
        "[chez-onboard] property-lookup failed:",
        resp.status,
        (await resp.text()).slice(0, 300)
      );
    }
  } catch (error) {
    console.error("[chez-onboard] property-lookup error (non-fatal):", error);
  }

  // 3. Pending invitation so the homeowner can claim the household from
  //    the app. Same shape iOS's HouseholdInvitationInsert writes; role
  //    "member" matches existing invites for a primary member.
  let invitationId: string | null = null;
  let inviteCode: string | null = null;
  for (let attempt = 0; attempt < 3; attempt++) {
    const candidate = generateInviteCode();
    const { data: invitation, error: inviteError } = await service
      .from("household_invitations")
      .insert({
        household_id: householdId,
        invited_by: user.id,
        invited_email: email,
        invite_code: candidate,
        role: "member",
        status: "pending",
        expires_at: new Date(
          Date.now() + INVITE_EXPIRY_DAYS * 24 * 60 * 60 * 1000
        ).toISOString(),
      })
      .select("id")
      .single();
    if (!inviteError && invitation) {
      invitationId = (invitation as { id: string }).id;
      inviteCode = candidate;
      break;
    }
    // Likely a unique-constraint collision on invite_code; retry.
    console.error(
      `[chez-onboard] invitation insert attempt ${attempt + 1} failed:`,
      inviteError
    );
  }
  if (!invitationId || !inviteCode) {
    return json(
      {
        error: "Failed to create invitation",
        household_id: householdId,
        property_id: propertyId,
      },
      500
    );
  }

  return json({
    ok: true,
    household_id: householdId,
    property_id: propertyId,
    invitation_id: invitationId,
    invite_code: inviteCode,
  });
}

async function handleListOnboardingSessions(service: ServiceClient) {
  const { data: sessions, error } = await service
    .from("onboarding_sessions")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) {
    console.error("[chez-onboard] list sessions error:", error);
    return json({ error: "Failed to load sessions" }, 500);
  }

  const rows = (sessions as Record<string, unknown>[] | null) ?? [];
  if (rows.length === 0) return json({ sessions: [] });

  const propertyIds = [
    ...new Set(rows.map((r) => compactString(r.property_id)).filter(Boolean)),
  ];
  const householdIds = [
    ...new Set(rows.map((r) => compactString(r.household_id)).filter(Boolean)),
  ];
  const assessmentIds = [
    ...new Set(rows.map((r) => compactString(r.assessment_id)).filter(Boolean)),
  ];

  const [propertiesResult, householdsResult, assessmentsResult] =
    await Promise.all([
      service.from("properties").select("id, street, city").in("id", propertyIds),
      service.from("households").select("id, name").in("id", householdIds),
      service
        .from("home_assessments")
        .select(
          "id, status, captured_systems, captured_contractors, captured_routines, captured_utility_accounts, captured_vehicles, captured_quick_fixes"
        )
        .in("id", assessmentIds),
    ]);

  const propertyById = new Map<string, Record<string, unknown>>();
  for (const p of (propertiesResult.data as Record<string, unknown>[] | null) ?? []) {
    propertyById.set(compactString(p.id), p);
  }
  const householdById = new Map<string, Record<string, unknown>>();
  for (const h of (householdsResult.data as Record<string, unknown>[] | null) ?? []) {
    householdById.set(compactString(h.id), h);
  }
  const assessmentById = new Map<string, Record<string, unknown>>();
  for (const a of (assessmentsResult.data as Record<string, unknown>[] | null) ?? []) {
    assessmentById.set(compactString(a.id), a);
  }

  const out = rows.map((row) => {
    const property = propertyById.get(compactString(row.property_id));
    const household = householdById.get(compactString(row.household_id));
    const assessment = assessmentById.get(compactString(row.assessment_id));
    return {
      ...row,
      url: `${ONBOARD_PAGE_BASE}?session=${compactString(row.token)}`,
      property_street: property ? compactString(property.street) || null : null,
      household_name: household ? compactString(household.name) || null : null,
      assessment_status: assessment
        ? compactString(assessment.status) || null
        : null,
      capture_counts: assessment
        ? {
          systems: asArray(assessment.captured_systems).length,
          contractors: asArray(assessment.captured_contractors).length,
          routines: asArray(assessment.captured_routines).length,
          utilities: asArray(assessment.captured_utility_accounts).length,
          vehicles: asArray(assessment.captured_vehicles).length,
          quick_fixes: asArray(assessment.captured_quick_fixes).length,
        }
        : null,
    };
  });

  return json({ sessions: out });
}

async function handleGetOnboardingSession(
  service: ServiceClient,
  body: Record<string, unknown>
) {
  const sessionId = compactString(body.session_id);
  if (!sessionId) return json({ error: "Missing session_id" }, 400);

  const { data, error } = await service
    .from("onboarding_sessions")
    .select("*")
    .eq("id", sessionId)
    .maybeSingle();
  if (error) {
    console.error("[chez-onboard] get session error:", error);
    return json({ error: "Failed to load session" }, 500);
  }
  if (!data) return json({ error: "Session not found" }, 404);

  const payload = await buildSessionPayload(
    service,
    data as unknown as OnboardingSessionRow,
    { includeAdminFields: true }
  );
  return json(payload);
}

async function handleRevokeOnboardingSession(
  service: ServiceClient,
  body: Record<string, unknown>
) {
  const sessionId = compactString(body.session_id);
  if (!sessionId) return json({ error: "Missing session_id" }, 400);

  const { data, error } = await service
    .from("onboarding_sessions")
    .update({ status: "revoked", updated_at: isoNow() })
    .eq("id", sessionId)
    .select("id")
    .maybeSingle();
  if (error) {
    console.error("[chez-onboard] revoke error:", error);
    return json({ error: "Failed to revoke session" }, 500);
  }
  if (!data) return json({ error: "Session not found" }, 404);

  return json({ ok: true });
}

async function handleExtendOnboardingSession(
  service: ServiceClient,
  body: Record<string, unknown>
) {
  const sessionId = compactString(body.session_id);
  if (!sessionId) return json({ error: "Missing session_id" }, 400);

  const hoursRaw = body.hours;
  const hours =
    typeof hoursRaw === "number" && Number.isFinite(hoursRaw) && hoursRaw > 0
      ? Math.min(hoursRaw, 24 * 14)
      : null;
  if (!hours) return json({ error: "hours must be a positive number" }, 400);

  const { data, error } = await service
    .from("onboarding_sessions")
    .select("*")
    .eq("id", sessionId)
    .maybeSingle();
  if (error) {
    console.error("[chez-onboard] extend fetch error:", error);
    return json({ error: "Failed to load session" }, 500);
  }
  if (!data) return json({ error: "Session not found" }, 404);

  const session = data as unknown as OnboardingSessionRow;
  if (session.status === "revoked" || session.status === "completed") {
    return json(
      { error: `Cannot extend a ${session.status} session. Create a new link instead.` },
      409
    );
  }

  const expiresAt = new Date(Date.now() + hours * 60 * 60 * 1000).toISOString();
  const update: Record<string, unknown> = {
    expires_at: expiresAt,
    updated_at: isoNow(),
  };
  // Reactivating an expired link — allowed only when no newer active link
  // exists for the assessment (partial unique index).
  if (session.status === "expired") update.status = "active";

  const { error: updateError } = await service
    .from("onboarding_sessions")
    .update(update)
    .eq("id", sessionId);
  if (updateError) {
    console.error("[chez-onboard] extend update error:", updateError);
    return json(
      { error: "Failed to extend session. Another active link may exist for this assessment." },
      409
    );
  }

  return json({ ok: true, expires_at: expiresAt });
}

async function handleRunIngestion(
  service: ServiceClient,
  body: Record<string, unknown>
) {
  const assessmentId = compactString(body.assessment_id);
  if (!assessmentId) return json({ error: "Missing assessment_id" }, 400);

  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) return json({ error: "Assessment not found" }, 404);

  try {
    const ingestSummary = await ingestAssessment(service, assessmentId, {
      onboardedVia: "chez_onboarding",
    });
    return json({ ok: true, ingest_summary: ingestSummary });
  } catch (error) {
    console.error("[chez-onboard] run_ingestion error:", error);
    const message = String(
      (error as { message?: string })?.message ?? error
    ).slice(0, 2000);
    await service
      .from("home_assessments")
      .update({ status: "ingestion_failed", ingestion_error: message })
      .eq("id", assessmentId);
    return json({ ok: false, error: message });
  }
}

// ============================================================================
// Entry point
// ============================================================================

const TOKEN_ACTIONS = new Set([
  "bootstrap",
  "start_visit",
  "save_capture",
  "add_recommendation",
  "update_recommendation",
  "list_recommendations",
  "delete_recommendation",
  "upload_photo",
  "identify_equipment",
  "submit",
]);

const ADMIN_ACTIONS = new Set([
  "create_onboarding_session",
  "create_customer_household",
  "list_onboarding_sessions",
  "get_onboarding_session",
  "revoke_onboarding_session",
  "extend_onboarding_session",
  "run_ingestion",
]);

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const service = createClient(supabaseUrl, serviceRoleKey);

    let body: Record<string, unknown>;
    try {
      body = (await req.json()) as Record<string, unknown>;
    } catch {
      return json({ error: "Invalid JSON body" }, 400);
    }

    const action = compactString(body.action);
    if (!action) return json({ error: "Missing action" }, 400);

    // ------------------------------------------------------------------
    // Token tier — validate the session on EVERY call; all reads/writes
    // are scoped to the session's assessment/household/property.
    // ------------------------------------------------------------------
    if (TOKEN_ACTIONS.has(action)) {
      const check = await loadSessionByToken(service, compactString(body.token));
      if (!check.ok) return check.response;
      const session = check.session;

      switch (action) {
        case "bootstrap":
          return await handleBootstrap(service, session);
        case "start_visit":
          return await handleStartVisit(service, session);
        case "save_capture":
          return await handleSaveCapture(service, session, body);
        case "add_recommendation":
          return await handleAddRecommendation(service, session, body);
        case "update_recommendation":
          return await handleUpdateRecommendation(service, session, body);
        case "list_recommendations":
          return await handleListRecommendations(service, session);
        case "delete_recommendation":
          return await handleDeleteRecommendation(service, session, body);
        case "upload_photo":
          return await handleUploadPhoto(service, session, body);
        case "identify_equipment":
          return await handleIdentifyEquipment(
            service,
            session,
            body,
            supabaseUrl,
            serviceRoleKey
          );
        case "submit":
          return await handleSubmit(service, session, body);
      }
    }

    // ------------------------------------------------------------------
    // Admin tier — Bearer JWT with email in CHEZ_ADMIN_EMAILS.
    // ------------------------------------------------------------------
    if (ADMIN_ACTIONS.has(action)) {
      const user = await getAuthenticatedUser(service, req);
      if (!user || !isAdminUser(user)) {
        return json({ error: "Not authorized" }, 403);
      }

      switch (action) {
        case "create_onboarding_session":
          return await handleCreateOnboardingSession(service, user, body);
        case "create_customer_household":
          return await handleCreateCustomerHousehold(
            service,
            user,
            body,
            supabaseUrl,
            serviceRoleKey
          );
        case "list_onboarding_sessions":
          return await handleListOnboardingSessions(service);
        case "get_onboarding_session":
          return await handleGetOnboardingSession(service, body);
        case "revoke_onboarding_session":
          return await handleRevokeOnboardingSession(service, body);
        case "extend_onboarding_session":
          return await handleExtendOnboardingSession(service, body);
        case "run_ingestion":
          return await handleRunIngestion(service, body);
      }
    }

    return json({ error: `Unknown action: ${action}` }, 400);
  } catch (error) {
    console.error("[chez-onboard] Error:", error);
    return json(
      { error: (error as { message?: string })?.message ?? "Internal error" },
      500
    );
  }
});
