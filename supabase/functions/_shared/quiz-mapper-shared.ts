// Phase 84.5 G8 / G12 — TypeScript port of HouseQuizAnswerMapper helpers.
// Used by handyman-provider's submit_assessment_data action so the
// handyman-captured contractors and routines land with the same canonical
// categories + cadences + active months as the quiz produces.
//
// Stay strictly aligned with HouseQuizAnswerMapper.swift —
// `householdContractorCategoryFor(chipId:)` (line 1774) and
// `defaultCadenceForQuizRoutine(kind:)` (line 1923). Any change to the
// Swift versions must mirror here.

// ============================================================================
// Q15b chip → SystemCategoryRegistry canonical category
// ============================================================================
//
// Mirrors HouseQuizAnswerMapper.householdContractorCategoryFor.
// Empty string return means "no canonical category" (chip wasn't in the
// quiz set — e.g. an "other" custom add).

export const HOUSEHOLD_CONTRACTOR_CATEGORY: Record<string, string> = {
  hvac_service: "HVAC",
  plumber: "Plumbing",
  electrician: "Electrical",
  roofer: "Roofing",
  septic_pumper: "Septic System",
  well_water_service: "Well System",
  // Phase 60.6: chimney_sweep → "Chimney" (not "Fire Protection")
  chimney_sweep: "Chimney",
  // Phase 60.6: tree_service → dedicated Tier 2 category
  tree_service: "Tree Service",
  // Phase 60.6: hardscape vendors are usually Landscaping-category pros
  hardscape: "Landscaping",
  generator_service: "Generator",
  // Phase 60.2 F1: handyman is Tier 1 with spring/fall punch-list bundles
  handyman: "Handyman",
  // Phase 60.2 F5: vendor categories with RoutineSeeder wiring
  cleaning: "Cleaning Service",
  snow_removal: "Snow Removal",
  mosquito_tick: "Mosquito & Tick",
  pet_waste: "Pet Waste",
  // Phase 67I: pool / solar / security / waterproofing
  pool_service: "Pool/Spa",
  solar_service: "Solar",
  security_service: "Security System",
  waterproofing: "Crawl Space",
};

export function householdContractorCategoryFor(chipId: string): string | null {
  return HOUSEHOLD_CONTRACTOR_CATEGORY[chipId] ?? null;
}

// ============================================================================
// Q15b chip → RoutineKind (string raw value)
// ============================================================================
//
// Maps a Q15b chip directly to the routines.routine_kind enum value the
// reconciler + Day1TaskCurator expect. Used at handyman ingestion to seed
// the active routine alongside the contractor row.

export const CHIP_TO_ROUTINE_KIND: Record<string, string> = {
  hvac_service: "hvac_service",
  plumber: "plumbing",
  electrician: "electrical",
  roofer: "roofing",
  septic_pumper: "septic",
  well_water_service: "well",
  chimney_sweep: "chimney",
  tree_service: "tree_service",
  hardscape: "landscaping",
  generator_service: "generator",
  handyman: "handyman_recurring",
  cleaning: "cleaning",
  snow_removal: "snow_removal",
  mosquito_tick: "mosquito_tick",
  pet_waste: "pet_waste",
  pool_service: "pool_service",
  solar_service: "solar_service",
  security_service: "security",
  waterproofing: "waterproofing",
};

export function routineKindForChip(chipId: string): string | null {
  return CHIP_TO_ROUTINE_KIND[chipId] ?? null;
}

// ============================================================================
// RoutineKind → default cadence + active months
// ============================================================================
//
// Mirrors HouseQuizAnswerMapper.defaultCadenceForQuizRoutine (line 1923).
// Returns the seed values used when a Q15b chip captures a vendor — the
// homeowner can refine via the routine setup sheet later.

export type RoutineCadenceType =
  | "weekly" | "biweekly" | "triweekly"
  | "monthly" | "quarterly" | "semiannual"
  | "annual" | "custom_days";

export interface RoutineCadenceDefault {
  cadenceType: RoutineCadenceType;
  cadenceIntervalDays: number;
  activeMonths: number[];
}

const YEAR_ROUND = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

export function defaultCadenceForQuizRoutine(kind: string): RoutineCadenceDefault {
  switch (kind) {
    case "cleaning":
      return { cadenceType: "biweekly", cadenceIntervalDays: 14, activeMonths: YEAR_ROUND };
    case "landscaping":
      return { cadenceType: "weekly", cadenceIntervalDays: 7, activeMonths: [4, 5, 6, 7, 8, 9, 10, 11] };
    case "pool_service":
      return { cadenceType: "weekly", cadenceIntervalDays: 7, activeMonths: [5, 6, 7, 8, 9] };
    case "pest_control":
      return { cadenceType: "quarterly", cadenceIntervalDays: 91, activeMonths: YEAR_ROUND };
    case "pet_waste":
      return { cadenceType: "weekly", cadenceIntervalDays: 7, activeMonths: YEAR_ROUND };
    case "mosquito_tick":
      return { cadenceType: "monthly", cadenceIntervalDays: 30, activeMonths: [4, 5, 6, 7, 8, 9, 10] };
    case "snow_removal":
      return { cadenceType: "annual", cadenceIntervalDays: 365, activeMonths: [12, 1, 2, 3, 4] };
    case "gutter_cleaning":
      return { cadenceType: "semiannual", cadenceIntervalDays: 182, activeMonths: YEAR_ROUND };
    case "window_cleaning":
      return { cadenceType: "semiannual", cadenceIntervalDays: 182, activeMonths: YEAR_ROUND };
    case "tree_service":
      return { cadenceType: "annual", cadenceIntervalDays: 365, activeMonths: YEAR_ROUND };
    case "handyman_recurring":
      return { cadenceType: "custom_days", cadenceIntervalDays: 9999, activeMonths: YEAR_ROUND };
    default:
      return { cadenceType: "annual", cadenceIntervalDays: 365, activeMonths: YEAR_ROUND };
  }
}

// ============================================================================
// Vendor dedup helpers (G7)
// ============================================================================
//
// Used at submit_assessment_data ingestion to avoid creating duplicate
// contractor rows when the homeowner already added one. Match on
// (household_id, normalized_company_name, normalized_phone). Existing
// rows are patched only where current value is null.

export function normalizeCompanyName(name: string | null | undefined): string {
  return (name ?? "")
    .toLowerCase()
    .replace(/\b(llc|inc|corp|company|co|the)\b/g, "")
    .replace(/[^a-z0-9]+/g, "")
    .trim();
}

export function normalizePhone(phone: string | null | undefined): string {
  return (phone ?? "").replace(/\D/g, "");
}

/**
 * Levenshtein distance — for fuzzy company name matching when the
 * exact normalized form differs slightly (e.g. "Tylers Heating" vs
 * "Tyler's Heating"). Threshold of 2 catches typos and apostrophe
 * variations without false-positiving distinct vendors.
 */
export function levenshtein(a: string, b: string): number {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;
  const m = a.length, n = b.length;
  let prev = new Array(n + 1);
  let curr = new Array(n + 1);
  for (let j = 0; j <= n; j++) prev[j] = j;
  for (let i = 1; i <= m; i++) {
    curr[0] = i;
    for (let j = 1; j <= n; j++) {
      const cost = a.charCodeAt(i - 1) === b.charCodeAt(j - 1) ? 0 : 1;
      curr[j] = Math.min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost);
    }
    [prev, curr] = [curr, prev];
  }
  return prev[n];
}

export function isLikelySameVendor(
  a: { companyName: string; phone?: string | null },
  b: { companyName: string; phone?: string | null }
): boolean {
  // Phone match is the strongest signal
  const phoneA = normalizePhone(a.phone);
  const phoneB = normalizePhone(b.phone);
  if (phoneA && phoneB && phoneA === phoneB) return true;

  // Normalized name exact match
  const nameA = normalizeCompanyName(a.companyName);
  const nameB = normalizeCompanyName(b.companyName);
  if (!nameA || !nameB) return false;
  if (nameA === nameB) return true;

  // Fuzzy name match (Levenshtein ≤ 2 on the normalized form catches
  // apostrophe/typo variants without conflating distinct vendors).
  if (Math.abs(nameA.length - nameB.length) > 4) return false;
  return levenshtein(nameA, nameB) <= 2;
}

// ============================================================================
// Urgency tier → chez_request priority mapping
// ============================================================================
//
// Used at submit_assessment_data ingestion to fan out
// assessment_recommended_tasks into chez_requests with the right SLA.

export type AssessmentUrgency = "urgent" | "soon" | "next_season" | "opportunistic";

export interface UrgencyMapping {
  category: "find_vendor" | "coordinate_task" | "general";
  slaHours: number | null;
  bypassesSLA: boolean;
}

export function chezRequestRoutingForUrgency(urgency: AssessmentUrgency): UrgencyMapping {
  switch (urgency) {
    case "urgent":
      // Safety / code — bypass SLA, immediate admin push
      return { category: "general", slaHours: null, bypassesSLA: true };
    case "soon":
      // Overdue service — standard 24h SLA
      return { category: "coordinate_task", slaHours: 24, bypassesSLA: false };
    case "next_season":
      // Timing-bound — handled via routine seeding, no SLA
      return { category: "general", slaHours: null, bypassesSLA: false };
    case "opportunistic":
      // Improvements — backlog, no SLA
      return { category: "general", slaHours: null, bypassesSLA: false };
  }
}
