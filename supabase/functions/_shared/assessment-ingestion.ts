// Wave 2 — Shared assessment ingestion path.
//
// Extracted verbatim from handyman-provider/index.ts (Phase 84.5) so the
// chez-onboard function can reuse it. Reads captured_* JSONB from a
// submitted home_assessments row and writes the canonical Haven tables
// (home_systems, contractors, routines, vehicles, utility_accounts,
// documents, service_records, chez_requests, properties.house_quiz_state).
//
// Callers:
//   - handyman-provider submit_assessment_data (auto) and the admin
//     "Run ingestion" override — no opts, provenance defaults to
//     "handyman_assessment" so behavior is unchanged.
//   - chez-onboard — pass { onboardedVia: "chez_onboard" } (or similar)
//     so the provenance stamps on every insert AND the chez_owned
//     auto-flip queries in step 10 track the new source.
//
// Usage:
//   import { ingestAssessment } from "../_shared/assessment-ingestion.ts";
//   const summary = await ingestAssessment(service, assessmentId);
//   await ingestAssessment(service, assessmentId, { onboardedVia: "chez_onboard" });
//
// Returns an IngestSummary counting successful writes per step plus a
// warnings array (one entry per failed write). Callers that ignore the
// return keep working.

// deno-lint-ignore-file no-explicit-any

import {
  householdContractorCategoryFor,
  routineKindForChip,
  defaultCadenceForQuizRoutine,
  isLikelySameVendor,
  normalizeCompanyName,
  chezRequestRoutingForUrgency,
  type AssessmentUrgency,
} from "./quiz-mapper-shared.ts";

// Loosely typed like ai-cost-discipline's `supabase: any` — the callers
// each construct their own createClient and the generated row types
// aren't shared across functions.
export type ServiceClient = any;

// ============================================================================
// Small local utils (duplicated from handyman-provider — trivially small,
// kept local so the module stays self-contained)
// ============================================================================

function compactString(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function isoNow() {
  return new Date().toISOString();
}

// ============================================================================
// Assessment record + loader
// ============================================================================

export interface AssessmentRecord {
  id: string;
  household_id: string;
  property_id: string;
  status: string;
  visit_assignment_id: string | null;
  handyman_member_id: string | null;
  captured_quiz_state: Record<string, unknown> | null;
  captured_systems: Array<Record<string, unknown>> | null;
  captured_contractors: Array<Record<string, unknown>> | null;
  captured_routines: Array<Record<string, unknown>> | null;
  captured_document_paths: string[] | null;
  captured_attributes: Record<string, unknown> | null;
}

export async function loadAssessment(
  service: ServiceClient,
  assessmentId: string
): Promise<AssessmentRecord | null> {
  const { data, error } = await service
    .from("home_assessments")
    .select("*")
    .eq("id", assessmentId)
    .maybeSingle();
  if (error || !data) return null;
  return data as unknown as AssessmentRecord;
}

// ============================================================================
// JSONB array merge helper
// ============================================================================

export function mergeJsonbArrayByKey(
  existing: Array<Record<string, unknown>> | null,
  incoming: Array<Record<string, unknown>> | null,
  keyField: string
): Array<Record<string, unknown>> {
  // Dedup by keyField, preferring incoming values. Used for captured_systems
  // (key=category), captured_contractors (key=company_name),
  // captured_routines (key=kind+vendor_name).
  const merged = new Map<string, Record<string, unknown>>();
  for (const item of existing ?? []) {
    const k = compactString((item as Record<string, unknown>)[keyField]).toLowerCase();
    if (k) merged.set(k, item);
  }
  for (const item of incoming ?? []) {
    const k = compactString((item as Record<string, unknown>)[keyField]).toLowerCase();
    if (k) merged.set(k, { ...(merged.get(k) ?? {}), ...item });
  }
  return Array.from(merged.values());
}

// ============================================================================
// Phase 84.5 — Ingestion path
// ============================================================================
//
// Reads captured_* JSONB from a submitted home_assessments row and writes
// the canonical Haven tables (home_systems, contractors, routines,
// documents, properties.house_quiz_state).  Run on submit_assessment_data
// (auto) or admin "Run ingestion" override.

export interface IngestSummary {
  systems: number;
  contractors: number;
  routines: number;
  vehicles: number;
  utility_accounts: number;
  documents: number;
  quick_fixes: number;
  recommendations_spawned: number;
  warnings: string[];
}

export async function ingestAssessment(
  service: ServiceClient,
  assessmentId: string,
  opts?: { onboardedVia?: string }
): Promise<IngestSummary> {
  const summary: IngestSummary = {
    systems: 0,
    contractors: 0,
    routines: 0,
    vehicles: 0,
    utility_accounts: 0,
    documents: 0,
    quick_fixes: 0,
    recommendations_spawned: 0,
    warnings: [],
  };
  // Every insert/update failure funnels through here. supabase-js never
  // throws on write errors — silent failures are how five schema bugs
  // shipped undetected.
  const fail = (step: string, error: unknown) => {
    console.warn(`[ingest] ${step} failed:`, error);
    summary.warnings.push(`${step} failed`);
  };

  const onboardedVia = opts?.onboardedVia ?? "handyman_assessment";
  const assessment = await loadAssessment(service, assessmentId);
  if (!assessment) throw new Error("assessment not found");
  if (assessment.status === "completed" || assessment.status === "awaiting_review") {
    summary.warnings.push("assessment already ingested; nothing written");
    return summary; // idempotent — don't re-ingest
  }

  const householdId = assessment.household_id;
  const propertyId = assessment.property_id;
  const isSupplement = (assessment as unknown as Record<string, unknown>).is_existing_user_supplement === true;

  // ============================================================
  // 1. SYSTEMS — G6 / G15 / G18 / G44 (condition + decommission)
  // ============================================================
  const systems = (assessment.captured_systems ?? []) as Array<Record<string, unknown>>;
  for (const s of systems) {
    const category = compactString(s.category);
    if (!category) continue;
    const manufacturer = compactString(s.manufacturer) || null;
    // Accept both key spellings so the chez-onboard web contract
    // (model_number / condition / photos / serial_number) AND the legacy
    // portal shapes (model / condition_rating / equipment_plate_photos)
    // both land.
    const model = compactString(s.model) || compactString(s.model_number) || null;
    const serialNumber = compactString(s.serial_number) || null;
    const installYear = typeof s.install_year === "number" ? s.install_year : null;
    const installDate = installYear ? `${installYear}-01-01` : null;
    const subtype = compactString(s.subtype) || null;
    const notes = compactString(s.notes) || null;
    const conditionRating = compactString(s.condition_rating) || compactString(s.condition) || null;
    const conditionNotes = compactString(s.condition_notes) || null;
    const conditionPhotos = Array.isArray(s.condition_photos) ? s.condition_photos : [];
    const equipmentPhotos = Array.isArray(s.equipment_plate_photos)
      ? s.equipment_plate_photos
      : (Array.isArray(s.photos) ? s.photos : []);
    const isDecommissioned = s.is_decommissioned === true;
    const decommissionReason = compactString(s.decommissioned_reason) || null;
    // T2.4 (post-overnight) — visit-draft followup flag fan-out. The
    // tech flagged the system mid-visit because they couldn't finish
    // (panel locked, tenant out). Stamp marked_for_followup_at +
    // followup_reason on home_systems so the next prep checklist
    // surfaces it. Cleared automatically on subsequent capture if
    // the flag is dropped.
    const followupRequired = s.followup_required === true
      || s.markedForFollowup === true
      || compactString(s.marked_for_followup_at) !== ""
      || compactString(s.markedForFollowupAt) !== "";
    const followupReason = compactString(s.followup_reason)
      || compactString(s.followupReason)
      || null;

    // find-or-create by (household, property, category, model). Supplement
    // mode patches existing rows; first-time mode skips duplicates.
    //
    // Wave 2 fix: the old match used .eq("model_number", model ?? "") —
    // a captured system with NO model_number never matched an existing
    // row whose model_number is NULL, creating duplicates. When the
    // capture has no model, fall back to matching by (household,
    // property, category) among non-decommissioned rows (`is_active` is
    // not false — the same column the decommission path below writes),
    // case-insensitive on category, preferring a row that also has no
    // model_number, and PATCH that match instead of inserting.
    let existing:
      | { id: string; install_date_source: string | null; condition_rating: string | null }
      | null = null;
    if (model) {
      const { data } = await service
        .from("home_systems")
        .select("id, install_date_source, condition_rating")
        .eq("household_id", householdId)
        .eq("property_id", propertyId)
        .eq("category", category)
        .eq("model_number", model)
        .maybeSingle();
      existing = (data as typeof existing) ?? null;
    } else {
      const { data } = await service
        .from("home_systems")
        .select("id, install_date_source, condition_rating, model_number")
        .eq("household_id", householdId)
        .eq("property_id", propertyId)
        .ilike("category", category)
        .not("is_active", "is", false);
      const candidates = ((data ?? []) as Array<{
        id: string;
        install_date_source: string | null;
        condition_rating: string | null;
        model_number: string | null;
      }>);
      existing = candidates.find((row) => !compactString(row.model_number)) ?? candidates[0] ?? null;
    }

    if (existing) {
      // Supplement / update path: handyman observation always wins over
      // ATTOM estimate (G6). Apply decommission flag if set.
      const update: Record<string, unknown> = {
        condition_rating: conditionRating ?? existing.condition_rating,
        condition_notes: conditionNotes,
        condition_photos: conditionPhotos.length ? conditionPhotos : undefined,
        last_assessed_at: isoNow(),
        install_date_source: existing.install_date_source === "vendor_invoice"
          ? "vendor_invoice"
          : "handyman_observed",
      };
      if (isDecommissioned) {
        update.is_active = false;
        update.decommissioned_at = isoNow();
        update.decommissioned_reason = decommissionReason;
      }
      // T2.4 — propagate follow-up flag from snapshot. Setting both
      // columns nulls them when the tech cleared the flag mid-visit.
      if (followupRequired) {
        update.marked_for_followup_at = isoNow();
        update.followup_reason = followupReason;
      } else if (s.followup_required === false) {
        update.marked_for_followup_at = null;
        update.followup_reason = null;
      }
      const { error: sysUpdateError } = await service.from("home_systems").update(update).eq("id", existing.id);
      if (sysUpdateError) fail(`systems update (${category})`, sysUpdateError);
      else summary.systems += 1;
      continue;
    }

    const { error: sysInsertError } = await service.from("home_systems").insert({
      household_id: householdId,
      property_id: propertyId,
      category,
      subtype,
      name: compactString(s.name) || [manufacturer, model].filter(Boolean).join(" ") || category,
      manufacturer,
      model_number: model,
      serial_number: serialNumber,
      install_date: installDate,
      install_date_source: "handyman_observed",
      notes,
      condition_rating: conditionRating,
      condition_notes: conditionNotes,
      condition_photos: conditionPhotos,
      photos: equipmentPhotos,
      last_assessed_at: isoNow(),
      onboarded_via: onboardedVia,
      is_active: !isDecommissioned,
      decommissioned_at: isDecommissioned ? isoNow() : null,
      decommissioned_reason: isDecommissioned ? decommissionReason : null,
      // T2.4 — flag carries through to the new home_systems row when
      // the tech captured + flagged the system in the same visit.
      marked_for_followup_at: followupRequired ? isoNow() : null,
      followup_reason: followupRequired ? followupReason : null,
    });
    if (sysInsertError) fail(`systems insert (${category})`, sysInsertError);
    else summary.systems += 1;
  }

  // ============================================================
  // 2. CONTRACTORS — G7 (fuzzy dedup) / G8 (canonical category) / G15
  // ============================================================
  const contractors = (assessment.captured_contractors ?? []) as Array<Record<string, unknown>>;
  // Pre-load existing contractors once for fuzzy dedup
  const { data: existingContractors } = await service
    .from("contractors")
    .select("id, company_name, phone, category")
    .eq("household_id", householdId);
  const existingList = (existingContractors ?? []) as Array<{
    id: string; company_name: string; phone: string | null; category: string | null;
  }>;

  for (const c of contractors) {
    const companyName = compactString(c.company_name);
    if (!companyName) continue;
    const phone = compactString(c.phone) || null;
    // Canonicalize category from chip_id when handyman captured via chip
    const chipId = compactString(c.chip_id) || null;
    const category = compactString(c.category)
      || (chipId ? householdContractorCategoryFor(chipId) : null);

    // Fuzzy dedup against existing roster
    const match = existingList.find((row) => isLikelySameVendor(
      { companyName: row.company_name, phone: row.phone },
      { companyName, phone }
    ));

    if (match) {
      // Patch only fields that are currently null
      const update: Record<string, unknown> = {};
      if (!match.phone && phone) update.phone = phone;
      if (!match.category && category) update.category = category;
      if (Object.keys(update).length > 0) {
        const { error: contractorUpdateError } = await service.from("contractors").update(update).eq("id", match.id);
        if (contractorUpdateError) fail(`contractors update (${companyName})`, contractorUpdateError);
        else summary.contractors += 1;
      }
      continue;
    }

    const { data: inserted, error: contractorInsertError } = await service
      .from("contractors")
      .insert({
        household_id: householdId,
        company_name: companyName,
        category,
        phone,
        email: compactString(c.email) || null,
        website: compactString(c.website) || null,
        source: "home_assessment",
        onboarded_via: onboardedVia,
      })
      .select("id, company_name, phone, category")
      .single();
    if (contractorInsertError) fail(`contractors insert (${companyName})`, contractorInsertError);
    if (inserted) {
      summary.contractors += 1;
      existingList.push(inserted as { id: string; company_name: string; phone: string | null; category: string | null });
    }
  }

  // ============================================================
  // 3. ROUTINES — G12 full RoutineInsert shape, G15 attribution
  // ============================================================
  const routines = (assessment.captured_routines ?? []) as Array<Record<string, unknown>>;
  for (const r of routines) {
    const kind = compactString(r.kind) || (compactString(r.chip_id) ? routineKindForChip(compactString(r.chip_id)) : null);
    if (!kind) continue;
    const vendorName = compactString(r.vendor_name) || null;
    const label = compactString(r.label) || (vendorName ? `${kind} · ${vendorName}` : kind);

    // Apply default cadence + active_months based on kind, then override
    // with anything explicitly captured.
    const defaults = defaultCadenceForQuizRoutine(kind);
    const cadenceType = compactString(r.cadence_type) || defaults.cadenceType;
    const cadenceIntervalDays = typeof r.cadence_interval_days === "number"
      ? r.cadence_interval_days
      : defaults.cadenceIntervalDays;
    let daysOfWeek = Array.isArray(r.days_of_week)
      ? r.days_of_week
      : (typeof r.day_of_week === "number" ? [r.day_of_week] : null);
    // Weekly-family cadences violate the weekly_has_days_of_week CHECK when
    // days_of_week is null/empty. Default to Monday — days_of_week uses
    // 1=Sunday..7=Saturday per the iOS Calendar convention.
    if (
      (cadenceType === "weekly" || cadenceType === "biweekly" || cadenceType === "triweekly") &&
      (!daysOfWeek || daysOfWeek.length === 0)
    ) {
      daysOfWeek = [2];
    }
    const activeMonths = Array.isArray(r.active_months) ? r.active_months : defaults.activeMonths;
    const timeOfDay = compactString(r.time_of_day) || null;

    // Look up vendor_id by company name (with fuzzy dedup just used).
    let vendorId: string | null = null;
    if (vendorName) {
      const v = existingList.find((row) =>
        normalizeCompanyName(row.company_name) === normalizeCompanyName(vendorName)
      );
      if (v) vendorId = v.id;
    }

    // Dedup by (household, kind, vendor_id). An .eq() against an
    // empty-string UUID errors — branch to .is(null) when no vendor.
    let dedupQuery = service
      .from("routines")
      .select("id")
      .eq("household_id", householdId)
      .eq("routine_kind", kind)
      .is("archived_at", null);
    dedupQuery = vendorId ? dedupQuery.eq("vendor_id", vendorId) : dedupQuery.is("vendor_id", null);
    const { data: existing } = await dedupQuery.maybeSingle();
    if (existing) continue;

    const { error: routineInsertError } = await service.from("routines").insert({
      household_id: householdId,
      property_id: propertyId,
      label,
      routine_kind: kind,
      cadence_type: cadenceType,
      cadence_interval_days: cadenceIntervalDays,
      days_of_week: daysOfWeek,
      active_months: activeMonths,
      time_of_day: timeOfDay,
      vendor_id: vendorId,
      setup_state: vendorId ? "active" : "pending_vendor",
      scope: "property",
      onboarded_via: onboardedVia,
    });
    if (routineInsertError) fail(`routines insert (${kind})`, routineInsertError);
    else summary.routines += 1;
  }

  // ============================================================
  // 4. VEHICLES — Q24 (was missing from original)
  // ============================================================
  const vehicles = ((assessment as unknown as Record<string, unknown>).captured_vehicles ?? []) as Array<Record<string, unknown>>;
  for (const v of vehicles) {
    const vin = compactString(v.vin);
    const make = compactString(v.make);
    const model = compactString(v.model);
    if (!vin && !make && !model) continue;
    // Dedup on VIN
    if (vin) {
      const { data: existing } = await service
        .from("vehicles")
        .select("id")
        .eq("household_id", householdId)
        .eq("vin", vin)
        .maybeSingle();
      if (existing) continue;
    }
    const { error: vehicleInsertError } = await service.from("vehicles").insert({
      household_id: householdId,
      // vehicles.name is NOT NULL — derive the display name the way the
      // iOS add flow does (year make model).
      name: [typeof v.year === "number" ? v.year : null, make || null, model || null]
        .filter(Boolean).join(" ") || "Vehicle",
      vin: vin || null,
      year: typeof v.year === "number" ? v.year : null,
      make: make || null,
      model: model || null,
      trim: compactString(v.trim) || null,
      color: compactString(v.color) || null,
      license_plate: compactString(v.license_plate) || null,
      // Column is current_mileage, not mileage. Accept both capture keys.
      current_mileage: typeof v.mileage === "number" ? v.mileage : (typeof v.current_mileage === "number" ? v.current_mileage : null),
      onboarded_via: onboardedVia,
    });
    if (vehicleInsertError) fail(`vehicles insert (${vin || make || model})`, vehicleInsertError);
    else summary.vehicles += 1;
  }

  // ============================================================
  // 5. UTILITY ACCOUNTS — Q16/17/19/26
  // ============================================================
  const utilityAccounts = ((assessment as unknown as Record<string, unknown>).captured_utility_accounts ?? []) as Array<Record<string, unknown>>;
  for (const ua of utilityAccounts) {
    const providerName = compactString(ua.provider_name);
    const providerType = compactString(ua.provider_type);
    if (!providerName || !providerType) continue;
    const { data: existing } = await service
      .from("utility_accounts")
      .select("id")
      .eq("household_id", householdId)
      .eq("provider_type", providerType)
      .ilike("provider_name", providerName)
      .maybeSingle();
    if (existing) continue;
    const { error: utilityInsertError } = await service.from("utility_accounts").insert({
      household_id: householdId,
      property_id: propertyId,
      provider_name: providerName,
      provider_type: providerType,
      account_number: compactString(ua.account_number) || null,
      // Column is monthly_cost NUMERIC DOLLARS, not monthly_cost_cents.
      monthly_cost: typeof ua.monthly_cost_cents === "number" ? ua.monthly_cost_cents / 100 : null,
      phone: compactString(ua.phone) || null,
      website: compactString(ua.website) || null,
      onboarded_via: onboardedVia,
    });
    if (utilityInsertError) fail(`utility_accounts insert (${providerName})`, utilityInsertError);
    else summary.utility_accounts += 1;
  }

  // ============================================================
  // 6. DOCUMENTS — G4 attribution
  // ============================================================
  const docPaths = (assessment.captured_document_paths ?? []) as Array<string | Record<string, unknown>>;
  for (const item of docPaths) {
    const path = typeof item === "string" ? item : compactString((item as Record<string, unknown>).path);
    if (!path) continue;
    const docMeta = typeof item === "object" ? (item as Record<string, unknown>) : {};
    const filename = path.split("/").pop() ?? path;
    const { data: existing } = await service
      .from("documents")
      .select("id")
      .eq("household_id", householdId)
      .eq("file_path", path)
      .maybeSingle();
    if (existing) continue;
    const { error: docInsertError } = await service.from("documents").insert({
      household_id: householdId,
      property_id: propertyId,
      filename,
      file_path: path,
      category: compactString(docMeta.category) || "Home Document",
      visible_to_home_managers: true,
      uploaded_via: onboardedVia,
    });
    if (docInsertError) fail(`documents insert (${filename})`, docInsertError);
    else summary.documents += 1;
  }

  // ============================================================
  // 7. QUICK-FIXES → backdated service_records (G21)
  // ============================================================
  const quickFixes = ((assessment as unknown as Record<string, unknown>).captured_quick_fixes ?? []) as Array<Record<string, unknown>>;
  for (const qf of quickFixes) {
    const description = compactString(qf.description);
    if (!description) continue;
    const { error: quickFixInsertError } = await service.from("service_records").insert({
      household_id: householdId,
      property_id: propertyId,
      system_id: compactString(qf.system_id) || null,
      service_date: new Date().toISOString().slice(0, 10),
      // service_records.service_type is NOT NULL.
      service_type: "Quick fix",
      description,
      // Column is cost NUMERIC DOLLARS, not cost_cents.
      cost: typeof qf.cost_cents === "number" ? qf.cost_cents / 100 : 0,
      notes: onboardedVia === "chez_onboarding"
        ? "Fixed on the spot during the Chez home setup visit."
        : "Fixed during Chez handyman assessment.",
    });
    if (quickFixInsertError) fail(`quick fix insert (${description.slice(0, 40)})`, quickFixInsertError);
    else summary.quick_fixes += 1;
  }

  // ============================================================
  // 8. RECOMMENDED TASKS → chez_requests / property_projects /
  //    maintenance_tasks (G19, G20, G25, G36, G45, G46, G48)
  // ============================================================
  const { data: recommendations } = await service
    .from("assessment_recommended_tasks")
    .select("*")
    .eq("assessment_id", assessmentId);
  const recList = (recommendations ?? []) as Array<Record<string, unknown>>;
  const HIGH_COST_THRESHOLD_CENTS = 500_000; // $5,000

  // chez_requests.user_id is NOT NULL — resolve a fan-out user up front. A
  // brand-new customer household may have no claimed account yet; in that
  // case skip the chez_request/property_project fan-out entirely and leave
  // the recommendations unspawned. The spawned_* null checks make a later
  // re-run pick them up after the homeowner claims the account.
  const { data: hhUsers } = await service
    .from("users")
    .select("id")
    .eq("household_id", householdId)
    .limit(1);
  const fanoutUserId = ((hhUsers ?? []) as Array<{ id: string }>)[0]?.id ?? null;
  if (!fanoutUserId && recList.length > 0) {
    console.warn("[ingest] no household user yet; skipping chez_request/property_project fan-out");
    summary.warnings.push("recommendation fan-out skipped: no household user yet");
  }

  for (const rec of recList) {
    // Skip already-handled rows
    if (rec.fixed_during_visit === true) continue;
    if (rec.spawned_chez_request_id || rec.spawned_project_id || rec.spawned_maintenance_task_id) continue;

    const recId = compactString(rec.id);
    const title = compactString(rec.title);
    const homeownerResponse = compactString(rec.homeowner_response);
    const urgency = compactString(rec.urgency) as AssessmentUrgency;
    const isDisputed = rec.disputed === true;
    const isHomeownerHandled = homeownerResponse === "homeowner_handled";
    const isDeclined = homeownerResponse === "declined";
    const observationSource = compactString(rec.observation_source) || "handyman_observed";
    const needsVerification = rec.needs_verification === true || observationSource === "homeowner_reported";
    const estCost = typeof rec.estimated_cost_cents === "number" ? rec.estimated_cost_cents : 0;

    // G46: homeowner_handled → spawn maintenance_task with their date.
    // maintenance_tasks has NO status column — do not stamp one.
    if (isHomeownerHandled) {
      const { data: task, error: taskInsertError } = await service
        .from("maintenance_tasks")
        .insert({
          household_id: householdId,
          property_id: propertyId,
          system_id: compactString(rec.system_id) || null,
          title,
          description: compactString(rec.description) || null,
          priority: "medium",
          assignment_type: "personal",
          assigned_route: "diy",
          scheduled_date: compactString(rec.homeowner_handled_scheduled_for) || null,
          notes: `Homeowner-handled via ${compactString(rec.homeowner_handled_vendor) || "their own arrangement"}.`,
        })
        .select("id")
        .single();
      if (taskInsertError) fail(`maintenance_tasks insert (${title})`, taskInsertError);
      if (task) {
        summary.recommendations_spawned += 1;
        const { error: taskBacklinkError } = await service
          .from("assessment_recommended_tasks")
          .update({ spawned_maintenance_task_id: (task as { id: string }).id })
          .eq("id", recId);
        if (taskBacklinkError) fail(`assessment_recommended_tasks backlink (${recId})`, taskBacklinkError);
      }
      continue;
    }

    // G48: declined-but-disputed → still create chez_request, mark disputed
    // G48: declined-and-not-disputed → skip entirely (homeowner doesn't want it)
    if (isDeclined && !isDisputed) continue;

    // No claimed household user yet — leave this recommendation unspawned
    // (warned once above the loop); a later re-run picks it up.
    if (!fanoutUserId) continue;

    const routing = chezRequestRoutingForUrgency(urgency);
    const description = compactString(rec.description) || compactString(rec.homeowner_visible_notes);

    // Create chez_request. Columns verified against the production schema —
    // there is NO source / submitted_by_user_id / property_id / description /
    // tags column; everything assessment-specific rides in context JSONB.
    // sla_due_at and last_message_at are NOT NULL.
    const reqInsert: Record<string, unknown> = {
      household_id: householdId,
      user_id: fanoutUserId,
      category: routing.category,
      summary: title,
      context: {
        _kind: "assessment_recommendation",
        recommendation_id: recId,
        urgency,
        zone: compactString(rec.zone) || null,
        estimated_cost_cents: estCost || null,
        description,
        needs_verification: needsVerification,
        disputed: isDisputed,
        source: "home_assessment",
      },
      status: "open",
      sla_due_at: new Date(Date.now() + (routing.slaHours ?? 168) * 3600_000).toISOString(),
      last_message_at: new Date().toISOString(),
      unread_for_user: false,
      unread_for_admin: true,
      admin_initiated: true,
    };
    const { data: chezReq, error: chezReqError } = await service
      .from("chez_requests")
      .insert(reqInsert)
      .select("id")
      .single();
    if (chezReqError) fail(`chez_requests insert (${title})`, chezReqError);

    if (chezReq) {
      summary.recommendations_spawned += 1;
      // First thread message so the case doesn't render empty. Chez voice.
      const content = description
        ? `From your Chez home visit: ${title}. ${description}`
        : `From your Chez home visit: ${title}.`;
      const { error: msgInsertError } = await service.from("concierge_messages").insert({
        household_id: householdId,
        request_id: (chezReq as { id: string }).id,
        role: "system",
        content,
        attachments: [],
      });
      if (msgInsertError) fail(`concierge_messages insert (${title})`, msgInsertError);
    }

    let projectId: string | null = null;

    // G36: high-cost → ALSO create property_projects (column is name, not title)
    if (estCost > HIGH_COST_THRESHOLD_CENTS) {
      const { data: proj, error: projInsertError } = await service
        .from("property_projects")
        .insert({
          household_id: householdId,
          property_id: propertyId,
          name: title,
          description: compactString(rec.description) || null,
          status: "planning",
          entry_type: "planned",
          estimated_budget: estCost / 100,
        })
        .select("id")
        .single();
      if (projInsertError) fail(`property_projects insert (${title})`, projInsertError);
      if (proj) projectId = (proj as { id: string }).id;
    }

    // Backlink the recommendation row
    const { error: recBacklinkError } = await service
      .from("assessment_recommended_tasks")
      .update({
        spawned_chez_request_id: chezReq ? (chezReq as { id: string }).id : null,
        spawned_project_id: projectId,
      })
      .eq("id", recId);
    if (recBacklinkError) fail(`assessment_recommended_tasks backlink (${recId})`, recBacklinkError);
  }

  // ============================================================
  // 9. PRE-VISIT QUIZ ANSWERS + completedAt
  // ============================================================
  const captured_quiz_state = assessment.captured_quiz_state ?? {};
  const merged_quiz_state = {
    ...captured_quiz_state,
    completedAt: new Date().toISOString(),
  };
  const { data: prop } = await service
    .from("properties")
    .select("house_quiz_state, attributes")
    .eq("id", propertyId)
    .maybeSingle();
  const existingState = ((prop as { house_quiz_state: Record<string, unknown> | null } | null)?.house_quiz_state) ?? {};
  // Merge captured_attributes deep — preserve any existing keys not overridden
  const mergedAttributes = {
    ...((prop as { attributes: Record<string, unknown> | null } | null)?.attributes ?? {}),
    ...(assessment.captured_attributes ?? {}),
  };
  // Stamp assessment_mode so the homeowner-side knows ingestion happened
  mergedAttributes["assessment_mode"] = "handyman";
  const { error: propUpdateError } = await service
    .from("properties")
    .update({
      house_quiz_state: { ...existingState, ...merged_quiz_state },
      attributes: mergedAttributes,
    })
    .eq("id", propertyId);
  if (propUpdateError) fail("properties quiz-state update", propUpdateError);

  // ============================================================
  // 10. AUTO-FLIP chez_owned ON GROUP TOGGLES (Phase 84 inheritance)
  // ============================================================
  // If household has chez_ownership_groups.{systems|vendors|routines}.on=true,
  // every newly-created entity in that group gets chez_owned=true.
  const { data: hh } = await service
    .from("households")
    .select("chez_ownership_groups")
    .eq("id", householdId)
    .maybeSingle();
  const groups = (hh as { chez_ownership_groups: Record<string, unknown> | null } | null)?.chez_ownership_groups ?? {};
  const isOwned = (group: string) => {
    const g = groups[group] as { on?: boolean } | undefined;
    return g?.on === true;
  };
  if (isOwned("systems")) {
    const { error: flipSystemsError } = await service.from("home_systems")
      .update({ chez_owned: true, chez_owned_at: isoNow() })
      .eq("property_id", propertyId)
      .eq("onboarded_via", onboardedVia)
      .is("chez_owned", null);
    if (flipSystemsError) fail("chez_owned flip (systems)", flipSystemsError);
  }
  if (isOwned("vendors")) {
    const { error: flipVendorsError } = await service.from("contractors")
      .update({ chez_owned: true, chez_owned_at: isoNow() })
      .eq("household_id", householdId)
      .eq("onboarded_via", onboardedVia)
      .is("chez_owned", null);
    if (flipVendorsError) fail("chez_owned flip (vendors)", flipVendorsError);
  }
  if (isOwned("routines")) {
    const { error: flipRoutinesError } = await service.from("routines")
      .update({ chez_owned: true, chez_owned_at: isoNow() })
      .eq("household_id", householdId)
      .eq("onboarded_via", onboardedVia)
      .is("chez_owned", null);
    if (flipRoutinesError) fail("chez_owned flip (routines)", flipRoutinesError);
  }

  // ============================================================
  // 11. FINAL STATUS FLIP
  // ============================================================
  const { error: statusFlipError } = await service
    .from("home_assessments")
    .update({
      status: "awaiting_review",
      ingested_at: isoNow(),
    })
    .eq("id", assessmentId);
  if (statusFlipError) fail("home_assessments status flip", statusFlipError);

  // ============================================================
  // 12. CHEZ ACTIVITY LOG — Phase 85 PR 5c
  // ============================================================
  //
  // Surface the completed assessment in the homeowner's "This week
  // with Chez" digest + permanent activity history. Soft-fail: if
  // log_chez_activity isn't deployed yet (pre-20261213 envs) the
  // ingestion still succeeds.
  try {
    const systemCount = systems.length;
    const recommendationCount = recList.length;
    const quickFixCount = quickFixes.length;
    const titleParts: string[] = [];
    if (systemCount > 0) titleParts.push(`${systemCount} system${systemCount === 1 ? "" : "s"}`);
    if (recommendationCount > 0) titleParts.push(`${recommendationCount} follow-up${recommendationCount === 1 ? "" : "s"}`);
    if (quickFixCount > 0) titleParts.push(`${quickFixCount} quick fix${quickFixCount === 1 ? "" : "es"}`);
    const digestSummary = titleParts.length > 0 ? titleParts.join(" · ") : "Visit complete";
    await service.rpc("log_chez_activity", {
      p_household_id: householdId,
      p_activity_type: "assessment_completed",
      p_title: "Home assessment complete",
      p_description: digestSummary,
      p_entity_type: "home_assessment",
      p_entity_id: assessmentId,
      p_cost_cents: null,
      p_occurred_at: isoNow(),
      p_surface_on_dashboard: true,
    });

    // Per-system log entries — only when there's a notable count to
    // signal in the digest (skip noise on tiny visits)
    if (systemCount >= 3) {
      await service.rpc("log_chez_activity", {
        p_household_id: householdId,
        p_activity_type: "system_added",
        p_title: `${systemCount} systems documented`,
        p_description: null,
        p_entity_type: "home_assessment",
        p_entity_id: assessmentId,
        p_cost_cents: null,
        p_occurred_at: isoNow(),
        p_surface_on_dashboard: false,
      });
    }
    if (recommendationCount > 0) {
      await service.rpc("log_chez_activity", {
        p_household_id: householdId,
        p_activity_type: "recommendation_logged",
        p_title: `${recommendationCount} recommendation${recommendationCount === 1 ? "" : "s"} logged`,
        p_description: null,
        p_entity_type: "home_assessment",
        p_entity_id: assessmentId,
        p_cost_cents: null,
        p_occurred_at: isoNow(),
        p_surface_on_dashboard: false,
      });
    }
  } catch (err) {
    console.warn("[assessment-ingestion] log_chez_activity failed (non-fatal):", err);
  }

  return summary;
}
