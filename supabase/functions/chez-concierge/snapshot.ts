// Wave 1 (Chez service rebuild) — server-assembled delegation snapshots.
//
// Design principle: iOS sends IDs + only what the server cannot know
// (budget, timing, access overrides). This module assembles the truth —
// system details, warranties, service history, routine cadence, vendor
// history, cost references — into a versioned JSONB blob stored on
// `chez_requests.snapshot`. The operator's Work Order panel, the admin
// email digest, and the AI analysis prompt all render from it, so the
// operator can act without follow-up questions.
//
// Every fetch is wrapped so one missing column / RLS surprise never
// kills the whole snapshot (same `safe()` posture as handleFetchDossier).
// Callers must treat a null return or a thrown error as "no snapshot" —
// a snapshot failure never sinks the delegation itself.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type ServiceClient = ReturnType<typeof createClient>;
type Row = Record<string, unknown>;

export const SNAPSHOT_VERSION = 1;

export type SnapshotKind =
  | "task"
  | "routine"
  | "contractor"
  | "system"
  | "project"
  | "vehicle"
  | "document"
  | "utility"
  | "insurance"
  | "property"
  | "group"
  | "general";

const SNAPSHOT_KINDS: SnapshotKind[] = [
  "task", "routine", "contractor", "system", "project", "vehicle",
  "document", "utility", "insurance", "property", "group", "general",
];

export function isSnapshotKind(value: unknown): value is SnapshotKind {
  return typeof value === "string" && SNAPSHOT_KINDS.includes(value as SnapshotKind);
}

/// Thrown when the requested entity exists but belongs to a different
/// household than the caller resolved to. Callers map this to a 403.
export class SnapshotAuthError extends Error {
  constructor(message = "entity does not belong to household") {
    super(message);
    this.name = "SnapshotAuthError";
  }
}

export interface SnapshotBuildOpts {
  kind: SnapshotKind;
  householdId: string;
  entityId?: string;
  propertyId?: string;
  /// kind=group only — one of the OWNERSHIP_GROUPS keys ("all_routines" etc.)
  group?: string;
}

export type DelegationSnapshot = Record<string, unknown>;

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

function str(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t.length > 0 ? t : null;
}

function num(v: unknown): number | null {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string" && v.trim() !== "") {
    const n = Number(v);
    if (Number.isFinite(n)) return n;
  }
  return null;
}

function bool(v: unknown): boolean | null {
  return typeof v === "boolean" ? v : null;
}

function capText(v: unknown, max = 2000): string | null {
  const s = str(v);
  if (!s) return null;
  return s.length > max ? `${s.slice(0, max)}…` : s;
}

function looksLikeUuid(v: unknown): v is string {
  return typeof v === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v.trim());
}

function daysUntil(dateStr: unknown): number | null {
  const s = str(dateStr);
  if (!s) return null;
  const t = new Date(s).getTime();
  if (Number.isNaN(t)) return null;
  return Math.round((t - Date.now()) / (24 * 60 * 60 * 1000));
}

function fmtDate(v: unknown): string | null {
  const s = str(v);
  if (!s) return null;
  const d = new Date(s);
  if (Number.isNaN(d.getTime())) return s;
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

function fmtMoney(amount: number | null): string | null {
  if (amount === null) return null;
  return `$${Math.round(amount).toLocaleString("en-US")}`;
}

function median(values: number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
}

const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/// Formats an active-months set as a season range, correctly handling
/// wrap-around runs — snow removal's {12,1,2,3} is "Dec to Mar", never
/// the min/max lie "Jan to Dec". Non-contiguous sets list the months.
/// Returns null for empty or year-round sets (nothing worth saying).
export function formatActiveMonths(months: unknown): string | null {
  if (!Array.isArray(months)) return null;
  const valid = [...new Set(
    months.filter((m): m is number => Number.isInteger(m) && m >= 1 && m <= 12)
  )].sort((a, b) => a - b);
  if (valid.length === 0 || valid.length >= 12) return null;

  const set = new Set(valid);
  // A single contiguous circular run has exactly one month whose
  // predecessor (wrapping Dec→Jan) is absent — that month starts the run.
  const starts = valid.filter((m) => !set.has(m === 1 ? 12 : m - 1));
  if (starts.length === 1) {
    const start = starts[0];
    let end = start;
    while (set.has((end % 12) + 1) && ((end % 12) + 1) !== start) {
      end = (end % 12) + 1;
    }
    return `${MONTH_NAMES[start - 1]} to ${MONTH_NAMES[end - 1]}`;
  }
  return valid.map((m) => MONTH_NAMES[m - 1]).join(", ");
}

async function safe<T>(promise: PromiseLike<T>, label: string): Promise<T | null> {
  try {
    return await promise;
  } catch (e) {
    console.warn(`[snapshot] ${label} failed:`, e);
    return null;
  }
}

function rows(res: unknown): Row[] {
  return ((res as { data?: Row[] } | null)?.data) ?? [];
}

function row(res: unknown): Row | null {
  return ((res as { data?: Row } | null)?.data) ?? null;
}

// ---------------------------------------------------------------------------
// Kind inference from a context dict (for handleSubmit — iOS entry points
// pass entity ids as plain string keys in `context`).
// ---------------------------------------------------------------------------

export function inferSnapshotKindFromContext(
  context: Record<string, unknown>
): { kind: SnapshotKind; entityId?: string; propertyId?: string } | null {
  const propertyId = looksLikeUuid(context.property_id) ? (context.property_id as string) : undefined;
  const priorities: Array<[string, SnapshotKind]> = [
    ["task_id", "task"],
    ["routine_id", "routine"],
    ["contractor_id", "contractor"],
    ["system_id", "system"],
    ["project_id", "project"],
    ["vehicle_id", "vehicle"],
    ["utility_id", "utility"],
    ["document_id", "document"],
  ];
  for (const [key, kind] of priorities) {
    if (looksLikeUuid(context[key])) {
      return { kind, entityId: context[key] as string, propertyId };
    }
  }
  if (propertyId) return { kind: "property", propertyId };
  return null;
}

// ---------------------------------------------------------------------------
// Row mappers — slim, defensive projections of full table rows.
// ---------------------------------------------------------------------------

function mapProperty(p: Row | null): Row | null {
  if (!p) return null;
  return {
    id: str(p.id),
    street: str(p.street),
    city: str(p.city),
    state: str(p.state),
    property_type: str(p.property_type),
    year_built: num(p.year_built),
    square_footage: num(p.square_footage),
  };
}

function mapManualLinks(v: unknown): Row[] {
  if (!Array.isArray(v)) return [];
  return v.slice(0, 3).map((entry) => {
    const e = (entry ?? {}) as Row;
    return { title: str(e.title) ?? str(e.name), url: str(e.url) };
  }).filter((e) => e.url);
}

function mapWarranty(w: Row): Row {
  const days = daysUntil(w.end_date);
  return {
    id: str(w.id),
    provider: str(w.provider),
    warranty_type: str(w.warranty_type),
    start_date: str(w.start_date),
    end_date: str(w.end_date),
    coverage_details: capText(w.coverage_details, 500),
    claim_phone: str(w.claim_phone),
    policy_number: str(w.policy_number),
    active: days !== null ? days >= 0 : null,
    expires_within_90d: days !== null ? days >= 0 && days <= 90 : null,
  };
}

function mapSystem(s: Row | null): Row | null {
  if (!s) return null;
  return {
    id: str(s.id),
    name: str(s.name),
    category: str(s.category),
    subtype: str(s.subtype),
    manufacturer: str(s.manufacturer),
    model_number: str(s.model_number),
    serial_number: str(s.serial_number),
    install_date: str(s.install_date),
    expected_lifespan_years: num(s.expected_lifespan_years),
    status: str(s.status),
    condition_rating: str(s.condition_rating),
    last_service_date: str(s.last_service_date),
    next_service_due: str(s.next_service_due) ?? str(s.next_maintenance_date),
    service_interval_days: num(s.service_interval_days),
    total_spent: num(s.total_spent),
    reliability_score: num(s.reliability_score),
    notes: capText(s.notes, 1000),
    manual_links: mapManualLinks(s.cached_manual_links ?? s.manual_links),
  };
}

function mapServiceRecord(r: Row, contractorNames: Map<string, string>): Row {
  const contractorId = str(r.contractor_id);
  return {
    service_date: str(r.service_date),
    service_type: str(r.service_type),
    description: capText(r.description, 300),
    cost: num(r.cost),
    contractor_name: contractorId ? (contractorNames.get(contractorId) ?? null) : null,
  };
}

function mapVendor(c: Row | null): Row | null {
  if (!c) return null;
  return {
    id: str(c.id),
    company_name: str(c.company_name),
    contact_name: str(c.contact_name),
    phone: str(c.phone),
    email: str(c.email),
    category: str(c.category),
    website: str(c.website),
    rating: num(c.rating),
    source: str(c.source),
    chez_owned: bool(c.chez_owned),
    notes: capText(c.notes, 500),
  };
}

function mapTask(t: Row | null): Row | null {
  if (!t) return null;
  return {
    id: str(t.id),
    title: str(t.title),
    description: capText(t.description, 2000),
    notes: capText(t.notes, 2000),
    frequency: str(t.frequency),
    scheduled_date: str(t.scheduled_date),
    next_due_date: str(t.next_due_date),
    assignment_type: str(t.assignment_type),
    needs_vendor: bool(t.needs_vendor),
    priority: str(t.priority),
    status: str(t.status),
  };
}

function mapRoutine(r: Row | null): Row | null {
  if (!r) return null;
  return {
    id: str(r.id),
    label: str(r.label),
    routine_kind: str(r.routine_kind),
    cadence_type: str(r.cadence_type),
    cadence_interval_days: num(r.cadence_interval_days),
    days_of_week: Array.isArray(r.days_of_week) ? r.days_of_week : null,
    time_of_day: str(r.time_of_day),
    active_months: Array.isArray(r.active_months) ? r.active_months : null,
    start_date: str(r.start_date),
    next_expected_date: str(r.next_expected_date),
    last_confirmed_date: str(r.last_confirmed_date),
    estimated_cost_per_visit_cents: num(r.estimated_cost_per_visit_cents),
    cost_notes: capText(r.cost_notes, 300),
    setup_state: str(r.setup_state),
    is_paused: bool(r.is_paused) ?? bool(r.paused),
    notes: capText(r.notes, 1000),
  };
}

function mapVehicle(v: Row | null): Row | null {
  if (!v) return null;
  return {
    id: str(v.id),
    name: str(v.name),
    year: num(v.year),
    make: str(v.make),
    model: str(v.model),
    trim: str(v.trim),
    vin: str(v.vin),
    current_mileage: num(v.current_mileage),
    registration_expiry: str(v.registration_expiry),
    inspection_expiry: str(v.inspection_expiry),
    preferred_mechanic_id: str(v.preferred_mechanic_id),
    notes: capText(v.notes, 500),
  };
}

function mapProject(p: Row | null): Row | null {
  if (!p) return null;
  return {
    id: str(p.id),
    name: str(p.name),
    description: capText(p.description, 1000),
    category: str(p.category),
    status: str(p.status),
    entry_type: str(p.entry_type),
    estimated_budget: num(p.estimated_budget),
    notes: capText(p.notes, 500),
  };
}

function mapUtility(u: Row | null): Row | null {
  if (!u) return null;
  return {
    id: str(u.id),
    provider_type: str(u.provider_type),
    provider_name: str(u.provider_name),
    phone: str(u.phone),
    website: str(u.website),
    monthly_cost: num(u.monthly_cost),
    plan_name: str(u.plan_name),
    notes: capText(u.notes, 500),
  };
}

function mapDocumentMeta(d: Row | null): Row | null {
  if (!d) return null;
  return {
    id: str(d.id),
    title: str(d.title) ?? str(d.filename),
    category: str(d.category),
    expiration_date: str(d.expiration_date),
    uploaded_at: str(d.uploaded_at) ?? str(d.created_at),
  };
}

// ---------------------------------------------------------------------------
// Group snapshots ("Chez handles all my X")
// ---------------------------------------------------------------------------

const GROUP_TABLES: Record<string, { table: string; archivedCol?: string }> = {
  all_routines: { table: "routines", archivedCol: "archived_at" },
  all_systems: { table: "home_systems", archivedCol: "archived_at" },
  all_vendors: { table: "contractors" },
  all_projects: { table: "property_projects" },
  all_bills: { table: "utility_accounts" },
  all_documents: { table: "documents", archivedCol: "deleted_at" },
  all_vehicles: { table: "vehicles", archivedCol: "archived_at" },
  // all_insurance is intentionally absent — policies live as a JSONB key
  // on properties, not as rows. buildGroupSection returns null for it and
  // the digest simply omits the enumeration.
};

/// Rough visits-per-month multiplier per cadence, for the group
/// snapshot's estimated monthly spend line. A guide, not a promise.
function visitsPerMonth(cadenceType: string | null, intervalDays: number | null): number {
  switch (cadenceType) {
    case "weekly": return 4.33;
    case "biweekly": return 2.17;
    case "triweekly": return 1.44;
    case "monthly": return 1;
    case "quarterly": return 1 / 3;
    case "semiannual": return 1 / 6;
    case "annual": return 1 / 12;
    case "custom_days": return intervalDays && intervalDays > 0 ? 30 / intervalDays : 0;
    default: return 0;
  }
}

async function buildGroupSection(
  service: ServiceClient,
  householdId: string,
  group: string
): Promise<Row | null> {
  const cfg = GROUP_TABLES[group];
  // Unknown / row-less groups (all_insurance) get no section rather than
  // a contradictory "Handing off: 0 items" line in the digest.
  if (!cfg) return null;

  let query = service.from(cfg.table).select("*").eq("household_id", householdId).limit(60);
  if (cfg.archivedCol) query = query.is(cfg.archivedCol, null);
  // Snapshots are readable by every household member including home
  // managers / staff (chez_requests RLS), so the documents enumeration
  // must respect the same visibility boundary the documents RLS enforces.
  if (cfg.table === "documents") query = query.eq("visible_to_home_managers", true);
  const res = await safe(query, `group ${group}`);
  const items = rows(res);

  // Resolve vendor names for routines so the enumeration reads naturally.
  const vendorIds = [...new Set(items.map((i) => str(i.vendor_id)).filter((v): v is string => !!v))];
  const vendorNames = new Map<string, string>();
  if (vendorIds.length > 0) {
    const vres = await safe(
      service.from("contractors").select("id, company_name")
        .eq("household_id", householdId).in("id", vendorIds),
      "group vendor names"
    );
    for (const v of rows(vres)) {
      const id = str(v.id);
      const name = str(v.company_name);
      if (id && name) vendorNames.set(id, name);
    }
  }

  let estMonthlyCents = 0;
  const entities = items.map((item) => {
    switch (group) {
      case "all_routines": {
        const cost = num(item.estimated_cost_per_visit_cents);
        const activeMonths = Array.isArray(item.active_months) ? item.active_months.length : 12;
        if (cost) {
          estMonthlyCents += cost
            * visitsPerMonth(str(item.cadence_type), num(item.cadence_interval_days))
            * (activeMonths / 12);
        }
        const vendorId = str(item.vendor_id);
        return {
          id: str(item.id),
          label: str(item.label),
          cadence_type: str(item.cadence_type),
          vendor_name: vendorId ? (vendorNames.get(vendorId) ?? null) : null,
          estimated_cost_per_visit_cents: cost,
        };
      }
      case "all_systems":
        return { id: str(item.id), label: str(item.name), category: str(item.category) };
      case "all_vendors":
        return { id: str(item.id), label: str(item.company_name), category: str(item.category), phone: str(item.phone) };
      case "all_projects":
        return { id: str(item.id), label: str(item.name), status: str(item.status) };
      case "all_bills":
        return { id: str(item.id), label: str(item.provider_name), provider_type: str(item.provider_type), monthly_cost: num(item.monthly_cost) };
      case "all_documents":
        return { id: str(item.id), label: str(item.title) ?? str(item.filename), category: str(item.category) };
      case "all_vehicles":
        return { id: str(item.id), label: [num(item.year), str(item.make), str(item.model)].filter(Boolean).join(" ") || str(item.name) };
      default:
        return { id: str(item.id) };
    }
  });

  const totals: Row = { count: entities.length };
  if (group === "all_routines" && estMonthlyCents > 0) {
    totals.est_monthly_spend_cents = Math.round(estMonthlyCents);
  }
  return { group, entities, totals };
}

// ---------------------------------------------------------------------------
// Cost references + suggested budget
// ---------------------------------------------------------------------------

/// Static per-category guide ranges (dollars) used when the household has
/// no service history for the category. Operator-facing guides only.
const CATEGORY_BUDGET_DEFAULTS: Record<string, [number, number]> = {
  "hvac": [250, 650],
  "plumbing": [200, 550],
  "electrical": [200, 600],
  "roofing": [400, 1200],
  "landscaping": [100, 350],
  "chimney": [300, 550],
  "septic system": [400, 750],
  "septic": [400, 750],
  "generator": [300, 650],
  "pool/spa": [250, 600],
  "cleaning service": [150, 350],
  "cleaning": [150, 350],
  "handyman": [150, 450],
  "tree service": [500, 1500],
  "pest control": [100, 300],
  "window cleaning": [150, 400],
  "pressure washing": [200, 500],
  "garage door": [150, 450],
  "water treatment": [200, 500],
  "well system": [250, 700],
};

async function buildCostReference(
  service: ServiceClient,
  householdId: string,
  category: string | null
): Promise<Row | null> {
  let recordsRes: unknown = null;
  let scopedToCategory = false;
  if (category) {
    const sysRes = await safe(
      service.from("home_systems").select("id").eq("household_id", householdId).eq("category", category),
      "cost-ref systems"
    );
    const sysIds = rows(sysRes).map((s) => str(s.id)).filter((s): s is string => !!s);
    if (sysIds.length > 0) {
      recordsRes = await safe(
        service.from("service_records")
          .select("cost")
          .eq("household_id", householdId)
          .in("system_id", sysIds)
          .not("cost", "is", null)
          .order("service_date", { ascending: false })
          .limit(50),
        "cost-ref records"
      );
      scopedToCategory = true;
    }
  }
  if (!recordsRes) {
    recordsRes = await safe(
      service.from("service_records")
        .select("cost")
        .eq("household_id", householdId)
        .not("cost", "is", null)
        .order("service_date", { ascending: false })
        .limit(50),
      "cost-ref household records"
    );
  }
  const costs = rows(recordsRes)
    .map((r) => num(r.cost))
    .filter((c): c is number => c !== null && c > 0);
  // The category label only survives when the costs actually came from
  // that category's systems — a household-wide fallback must never be
  // presented as trade-specific history.
  const labeledCategory = scopedToCategory ? category : null;
  if (costs.length === 0) return labeledCategory ? { category: labeledCategory, sample: 0 } : null;

  const med = median(costs) ?? 0;
  return {
    category: labeledCategory,
    median_cents: Math.round(med * 100),
    low_cents: Math.round(Math.min(...costs) * 100),
    high_cents: Math.round(Math.max(...costs) * 100),
    sample: costs.length,
  };
}

/// Budget suggestion consumed by composer v2 (Wave 4) and the operator
/// portal. Basis ladder: household service history → static category
/// defaults, scaled by the household's budget orientation.
export function suggestedBudgetFor(snapshot: DelegationSnapshot): Row | null {
  const profile = ((snapshot.household as Row | undefined)?.chez_profile ?? {}) as Row;
  const prefs = (profile.vendor_preferences ?? {}) as Row;
  const orientation = str(prefs.budget_orientation) ?? "standard";
  const scale = orientation === "budget" ? 0.8 : orientation === "premium" ? 1.4 : 1.0;

  const costRef = (snapshot.cost_reference ?? null) as Row | null;
  const sample = costRef ? num(costRef.sample) ?? 0 : 0;

  // Ladder: category-scoped household history beats everything; a
  // household-wide fallback (cost_reference.category is null) must NOT
  // outrank the trade-specific static default — cross-trade costs are a
  // worse guide than a decent per-category range.
  if (costRef && sample >= 2 && str(costRef.category)) {
    const med = num(costRef.median_cents) ?? 0;
    return {
      low_cents: Math.round(med * 0.7 * scale),
      high_cents: Math.round(med * 1.4 * scale),
      basis: "household_history",
    };
  }

  const category = (str((snapshot.system as Row | undefined)?.category)
    ?? str((snapshot.vendor as Row | undefined)?.category)
    ?? str(costRef?.category)
    ?? "").toLowerCase();
  const defaults = CATEGORY_BUDGET_DEFAULTS[category];
  if (defaults) {
    return {
      low_cents: Math.round(defaults[0] * 100 * scale),
      high_cents: Math.round(defaults[1] * 100 * scale),
      basis: "orientation_default",
    };
  }

  if (costRef && sample >= 2) {
    const med = num(costRef.median_cents) ?? 0;
    return {
      low_cents: Math.round(med * 0.7 * scale),
      high_cents: Math.round(med * 1.4 * scale),
      basis: "household_history_general",
    };
  }
  return null;
}

// ---------------------------------------------------------------------------
// The builder
// ---------------------------------------------------------------------------

export async function buildDelegationSnapshot(
  service: ServiceClient,
  opts: SnapshotBuildOpts
): Promise<DelegationSnapshot | null> {
  const { kind, householdId } = opts;
  const snapshot: DelegationSnapshot = {
    _v: SNAPSHOT_VERSION,
    built_at: new Date().toISOString(),
    kind,
    homeowner_intake: null,
  };

  // --- Entity fetch per kind (with household ownership check) ------------
  const fetchOwned = async (table: string, id: string, label: string): Promise<Row | null> => {
    const res = await safe(service.from(table).select("*").eq("id", id).maybeSingle(), label);
    const entity = row(res);
    if (!entity) return null;
    if (str(entity.household_id) !== householdId) throw new SnapshotAuthError();
    return entity;
  };

  let task: Row | null = null;
  let system: Row | null = null;
  let routine: Row | null = null;
  let vendorRow: Row | null = null;
  let vehicle: Row | null = null;
  let project: Row | null = null;
  let utility: Row | null = null;
  let documentRow: Row | null = null;
  let propertyId = opts.propertyId ?? null;

  if (opts.entityId) {
    switch (kind) {
      case "task": {
        task = await fetchOwned("maintenance_tasks", opts.entityId, "task");
        if (!task) return null;
        propertyId = propertyId ?? str(task.property_id);
        if (str(task.system_id)) {
          system = await fetchOwned("home_systems", str(task.system_id)!, "task system").catch(() => null);
        }
        if (str(task.vehicle_id)) {
          vehicle = await fetchOwned("vehicles", str(task.vehicle_id)!, "task vehicle").catch(() => null);
        }
        const contractorId = str(task.assigned_contractor_id);
        if (contractorId) {
          vendorRow = await fetchOwned("contractors", contractorId, "task vendor").catch(() => null);
        }
        break;
      }
      case "routine": {
        routine = await fetchOwned("routines", opts.entityId, "routine");
        if (!routine) return null;
        propertyId = propertyId ?? str(routine.property_id);
        if (str(routine.vendor_id)) {
          vendorRow = await fetchOwned("contractors", str(routine.vendor_id)!, "routine vendor").catch(() => null);
        }
        if (str(routine.system_id)) {
          system = await fetchOwned("home_systems", str(routine.system_id)!, "routine system").catch(() => null);
        }
        break;
      }
      case "contractor": {
        vendorRow = await fetchOwned("contractors", opts.entityId, "contractor");
        if (!vendorRow) return null;
        break;
      }
      case "system": {
        system = await fetchOwned("home_systems", opts.entityId, "system");
        if (!system) return null;
        propertyId = propertyId ?? str(system.property_id);
        const preferred = str(system.preferred_contractor_id) ?? str(system.service_vendor_id);
        if (preferred) {
          vendorRow = await fetchOwned("contractors", preferred, "system vendor").catch(() => null);
        }
        break;
      }
      case "project": {
        project = await fetchOwned("property_projects", opts.entityId, "project");
        if (!project) return null;
        propertyId = propertyId ?? str(project.property_id);
        break;
      }
      case "vehicle": {
        vehicle = await fetchOwned("vehicles", opts.entityId, "vehicle");
        if (!vehicle) return null;
        break;
      }
      case "utility": {
        utility = await fetchOwned("utility_accounts", opts.entityId, "utility");
        if (!utility) return null;
        propertyId = propertyId ?? str(utility.property_id);
        break;
      }
      case "document": {
        documentRow = await fetchOwned("documents", opts.entityId, "document");
        if (!documentRow) return null;
        propertyId = propertyId ?? str(documentRow.property_id);
        // Snapshots are readable by every household member (including
        // home managers / staff via chez_requests RLS), so deleted or
        // manager-restricted documents contribute no metadata — the
        // snapshot survives with the common sections only.
        if (documentRow.deleted_at || documentRow.visible_to_home_managers === false) {
          documentRow = null;
        }
        break;
      }
      default:
        break;
    }
  }

  // --- Common sections: household profile + property ---------------------
  const [householdRes, propertyRes] = await Promise.all([
    safe(
      service.from("households").select("id, name, chez_profile").eq("id", householdId).maybeSingle(),
      "household"
    ),
    propertyId
      ? safe(service.from("properties").select("*").eq("id", propertyId).maybeSingle(), "property")
      : safe(
          service.from("properties").select("*").eq("household_id", householdId)
            .order("created_at", { ascending: true }).limit(1).maybeSingle(),
          "first property"
        ),
  ]);

  const household = row(householdRes);
  const property = row(propertyRes);
  if (property && str(property.household_id) !== householdId) {
    throw new SnapshotAuthError("property does not belong to household");
  }

  snapshot.household = {
    id: householdId,
    name: str(household?.name),
    town: str(property?.city),
    state: str(property?.state),
    chez_profile: (household?.chez_profile ?? {}) as Row,
  };
  snapshot.property = mapProperty(property);

  // --- Kind-specific related data -----------------------------------------
  const systemId = str(system?.id);
  const vendorId = str(vendorRow?.id);

  // Every secondary fetch is household-scoped IN ADDITION to the FK
  // filter: warranty / service_record RLS only validates the row's own
  // household_id on insert, so a crafted row in another household can
  // reference this household's system UUID. The service role bypasses
  // RLS here — the explicit household filter is the boundary.
  const [warrantiesRes, systemHistoryRes, vendorHistoryRes, subsystemsRes] = await Promise.all([
    systemId
      ? safe(
          service.from("warranties").select("*")
            .eq("household_id", householdId).eq("system_id", systemId),
          "warranties"
        )
      : Promise.resolve(null),
    systemId
      ? safe(
          service.from("service_records").select("*")
            .eq("household_id", householdId).eq("system_id", systemId)
            .order("service_date", { ascending: false }).limit(5),
          "system history"
        )
      : Promise.resolve(null),
    vendorId
      ? safe(
          service.from("service_records").select("*")
            .eq("household_id", householdId).eq("contractor_id", vendorId)
            .order("service_date", { ascending: false }).limit(10),
          "vendor history"
        )
      : Promise.resolve(null),
    systemId
      ? safe(
          service.from("home_systems").select("id, name")
            .eq("household_id", householdId).eq("parent_system_id", systemId),
          "subsystems"
        )
      : Promise.resolve(null),
  ]);

  // Resolve contractor names referenced by the service history rows so
  // the digest reads "Tyler Heating", not a UUID.
  const historyRows = [...rows(systemHistoryRes), ...rows(vendorHistoryRes)];
  const historyContractorIds = [
    ...new Set(historyRows.map((r) => str(r.contractor_id)).filter((v): v is string => !!v)),
  ];
  const contractorNames = new Map<string, string>();
  if (vendorId && str(vendorRow?.company_name)) {
    contractorNames.set(vendorId, str(vendorRow?.company_name)!);
  }
  const unresolved = historyContractorIds.filter((id) => !contractorNames.has(id));
  if (unresolved.length > 0) {
    const namesRes = await safe(
      service.from("contractors").select("id, company_name")
        .eq("household_id", householdId).in("id", unresolved),
      "history contractor names"
    );
    for (const c of rows(namesRes)) {
      const id = str(c.id);
      const name = str(c.company_name);
      if (id && name) contractorNames.set(id, name);
    }
  }

  if (task) snapshot.task = mapTask(task);
  if (routine) snapshot.routine = mapRoutine(routine);
  if (project) snapshot.project = mapProject(project);
  if (utility) snapshot.utility = mapUtility(utility);
  if (documentRow) snapshot.document = mapDocumentMeta(documentRow);
  if (vehicle) {
    const mapped = mapVehicle(vehicle);
    const vehicleId = str(vehicle.id);
    if (mapped && vehicleId) {
      const [vsrRes, recallsRes] = await Promise.all([
        safe(
          service.from("vehicle_service_records").select("*")
            .eq("household_id", householdId).eq("vehicle_id", vehicleId)
            .order("service_date", { ascending: false }).limit(5),
          "vehicle history"
        ),
        safe(
          service.from("vehicle_recalls").select("*")
            .eq("household_id", householdId).eq("vehicle_id", vehicleId).limit(10),
          "vehicle recalls"
        ),
      ]);
      mapped.service_history = rows(vsrRes).map((r) => ({
        service_date: str(r.service_date),
        service_type: str(r.service_type),
        description: capText(r.description, 200),
        cost: num(r.cost),
        mileage: num(r.mileage_at_service) ?? num(r.mileage),
      }));
      mapped.open_recalls = rows(recallsRes)
        .filter((r) => bool(r.is_resolved) !== true && str(r.status) !== "resolved")
        .map((r) => ({
          campaign_number: str(r.campaign_number) ?? str(r.nhtsa_campaign_number),
          summary: capText(r.summary ?? r.component, 200),
        }));
    }
    snapshot.vehicle = mapped;
  }

  if (system) {
    const mappedSystem = mapSystem(system);
    if (mappedSystem) {
      mappedSystem.subsystems = rows(subsystemsRes).map((s) => ({ id: str(s.id), name: str(s.name) }));
      mappedSystem.warranties = rows(warrantiesRes).map(mapWarranty);
    }
    snapshot.system = mappedSystem;
    snapshot.service_history = rows(systemHistoryRes).map((r) => mapServiceRecord(r, contractorNames));
  }

  if (vendorRow) {
    const mappedVendor = mapVendor(vendorRow);
    const history = rows(vendorHistoryRes);
    if (mappedVendor) {
      mappedVendor.history = history.map((r) => mapServiceRecord(r, contractorNames));
      const costs = history.map((r) => num(r.cost)).filter((c): c is number => c !== null);
      mappedVendor.stats = {
        jobs_on_file: history.length,
        total_spent: costs.reduce((a, b) => a + b, 0) || null,
        last_visit: str(history[0]?.service_date),
      };
    }
    snapshot.vendor = mappedVendor;
  }

  if (project) {
    const projectId = str(project.id);
    if (projectId) {
      const [quotesRes, projectDocsRes] = await Promise.all([
        safe(
          service.from("project_quotes").select("*")
            .eq("household_id", householdId).eq("project_id", projectId).limit(5),
          "project quotes"
        ),
        safe(
          service.from("documents").select("id, title, category, expiration_date, uploaded_at")
            .eq("household_id", householdId).eq("project_id", projectId)
            .is("deleted_at", null).eq("visible_to_home_managers", true)
            .limit(10),
          "project documents"
        ),
      ]);
      // project_quotes carries a contractor_id, never a vendor name —
      // resolve names through the household's contractors so quotes
      // render as "Tyler Heating: $12,400", not an unnamed row.
      const quoteRows = rows(quotesRes);
      const quoteContractorIds = [
        ...new Set(quoteRows.map((q) => str(q.contractor_id)).filter((v): v is string => !!v)),
      ].filter((id) => !contractorNames.has(id));
      if (quoteContractorIds.length > 0) {
        const qNamesRes = await safe(
          service.from("contractors").select("id, company_name")
            .eq("household_id", householdId).in("id", quoteContractorIds),
          "quote contractor names"
        );
        for (const c of rows(qNamesRes)) {
          const id = str(c.id);
          const name = str(c.company_name);
          if (id && name) contractorNames.set(id, name);
        }
      }
      (snapshot.project as Row).quotes = quoteRows.map((q) => {
        const contractorId = str(q.contractor_id);
        return {
          id: str(q.id),
          vendor_name: contractorId ? (contractorNames.get(contractorId) ?? null) : null,
          trade: str(q.trade),
          total: num(q.quote_total),
          fair_total: num(q.estimated_fair_total),
          rating: str(q.overall_rating),
        };
      });
      snapshot.documents = rows(projectDocsRes).map((d) => mapDocumentMeta(d));
    }
  }

  // Linked documents for system-flavored snapshots come via warranty +
  // invoice links (documents has no system_id column).
  if (system && !snapshot.documents) {
    const docIds = [
      ...new Set([
        ...rows(warrantiesRes).map((w) => str(w.linked_document_id)),
        ...rows(systemHistoryRes).map((r) => str(r.invoice_document_id)),
      ].filter((v): v is string => !!v)),
    ].slice(0, 10);
    if (docIds.length > 0) {
      const docsRes = await safe(
        service.from("documents").select("id, title, category, expiration_date, uploaded_at")
          .eq("household_id", householdId).in("id", docIds)
          .is("deleted_at", null).eq("visible_to_home_managers", true),
        "linked documents"
      );
      snapshot.documents = rows(docsRes).map((d) => mapDocumentMeta(d));
    }
  }

  // --- Group snapshot ------------------------------------------------------
  if (kind === "group" && opts.group) {
    snapshot.group = await buildGroupSection(service, householdId, opts.group);
  }

  // --- Cost reference ------------------------------------------------------
  const costCategory = str((snapshot.system as Row | undefined)?.category)
    ?? str((snapshot.vendor as Row | undefined)?.category)
    ?? null;
  snapshot.cost_reference = await buildCostReference(service, householdId, costCategory);

  return snapshot;
}

// ---------------------------------------------------------------------------
// Digest — compact plain-text block for system messages, admin email,
// and the AI analysis prompt. Homeowner-visible, so: Chez voice, no em
// dashes, no UUIDs.
// ---------------------------------------------------------------------------

export function snapshotDigest(snapshot: DelegationSnapshot): string {
  const lines: string[] = ["Chez context snapshot:"];
  const push = (label: string, value: string | null) => {
    if (value) lines.push(`${label}: ${value}`);
  };

  const property = (snapshot.property ?? null) as Row | null;
  if (property) {
    const parts = [
      num(property.year_built) ? `built ${num(property.year_built)}` : null,
      [str(property.city), str(property.state)].filter(Boolean).join(", ") || null,
      num(property.square_footage) ? `${num(property.square_footage)?.toLocaleString("en-US")} sq ft` : null,
    ].filter(Boolean);
    push("Property", parts.join(" · ") || null);
  }

  const task = (snapshot.task ?? null) as Row | null;
  if (task) {
    const parts = [
      str(task.title),
      fmtDate(task.scheduled_date ?? task.next_due_date) ? `due ${fmtDate(task.scheduled_date ?? task.next_due_date)}` : null,
      str(task.frequency),
    ].filter(Boolean);
    push("Task", parts.join(" · ") || null);
  }

  const system = (snapshot.system ?? null) as Row | null;
  if (system) {
    const label = [str(system.manufacturer), str(system.model_number)].filter(Boolean).join(" ")
      || str(system.name) || "";
    const parts = [
      label ? `${label}${str(system.category) ? ` (${str(system.category)})` : ""}` : str(system.category),
      str(system.install_date) ? `installed ${fmtDate(system.install_date)}` : null,
      str(system.serial_number) ? `serial ${str(system.serial_number)}` : null,
      str(system.condition_rating) ?? str(system.status),
    ].filter(Boolean);
    push("System", parts.join(" · ") || null);

    const warranties = (Array.isArray(system.warranties) ? system.warranties : []) as Row[];
    const active = warranties.find((w) => w.active === true);
    if (active) {
      const parts2 = [
        `${str(active.provider) ?? "Warranty"} through ${fmtDate(active.end_date)}`,
        active.expires_within_90d === true ? "expires within 90 days" : null,
        str(active.claim_phone) ? `claim ${str(active.claim_phone)}` : null,
      ].filter(Boolean);
      push("Warranty", parts2.join(" · "));
    }
  }

  const history = (Array.isArray(snapshot.service_history) ? snapshot.service_history : []) as Row[];
  if (history.length > 0) {
    const latest = history[0];
    const total = history.map((r) => num(r.cost)).filter((c): c is number => c !== null).reduce((a, b) => a + b, 0);
    const parts = [
      `${history.length} record${history.length === 1 ? "" : "s"}`,
      `last ${fmtDate(latest.service_date)}${str(latest.service_type) ? ` (${str(latest.service_type)}${str(latest.contractor_name) ? `, ${str(latest.contractor_name)}` : ""}${num(latest.cost) ? `, ${fmtMoney(num(latest.cost))}` : ""})` : ""}`,
      total > 0 ? `${fmtMoney(total)} total` : null,
    ].filter(Boolean);
    push("Service history", parts.join(" · "));
  }

  const vendor = (snapshot.vendor ?? null) as Row | null;
  if (vendor) {
    const stats = (vendor.stats ?? {}) as Row;
    const parts = [
      `${str(vendor.company_name) ?? "Vendor"}${str(vendor.category) ? ` (${str(vendor.category)})` : ""}`,
      str(vendor.phone),
      num(stats.jobs_on_file) ? `${num(stats.jobs_on_file)} job${num(stats.jobs_on_file) === 1 ? "" : "s"} on file` : null,
      num(stats.total_spent) ? `${fmtMoney(num(stats.total_spent))} total` : null,
    ].filter(Boolean);
    push("Vendor on file", parts.join(" · "));
  }

  const routine = (snapshot.routine ?? null) as Row | null;
  if (routine) {
    const monthsLabel = formatActiveMonths(routine.active_months);
    const seasonal = monthsLabel ? `active ${monthsLabel}` : null;
    const costCents = num(routine.estimated_cost_per_visit_cents);
    const parts = [
      str(routine.label),
      str(routine.cadence_type),
      seasonal,
      costCents ? `about ${fmtMoney(costCents / 100)}/visit` : null,
      str(routine.next_expected_date) ? `next expected ${fmtDate(routine.next_expected_date)}` : null,
    ].filter(Boolean);
    push("Routine", parts.join(" · ") || null);
  }

  const vehicle = (snapshot.vehicle ?? null) as Row | null;
  if (vehicle) {
    const recalls = (Array.isArray(vehicle.open_recalls) ? vehicle.open_recalls : []) as Row[];
    const parts = [
      [num(vehicle.year), str(vehicle.make), str(vehicle.model)].filter(Boolean).join(" ") || str(vehicle.name),
      num(vehicle.current_mileage) ? `${num(vehicle.current_mileage)?.toLocaleString("en-US")} miles` : null,
      recalls.length > 0 ? `${recalls.length} open recall${recalls.length === 1 ? "" : "s"}` : null,
    ].filter(Boolean);
    push("Vehicle", parts.join(" · ") || null);
  }

  const projectSection = (snapshot.project ?? null) as Row | null;
  if (projectSection) {
    const quotes = (Array.isArray(projectSection.quotes) ? projectSection.quotes : []) as Row[];
    const parts = [
      str(projectSection.name),
      str(projectSection.status),
      num(projectSection.estimated_budget) ? `budget ${fmtMoney(num(projectSection.estimated_budget))}` : null,
      quotes.length > 0 ? `${quotes.length} quote${quotes.length === 1 ? "" : "s"} on file` : null,
    ].filter(Boolean);
    push("Project", parts.join(" · ") || null);
  }

  const utilitySection = (snapshot.utility ?? null) as Row | null;
  if (utilitySection) {
    const parts = [
      str(utilitySection.provider_name),
      str(utilitySection.provider_type),
      num(utilitySection.monthly_cost) ? `${fmtMoney(num(utilitySection.monthly_cost))}/mo` : null,
    ].filter(Boolean);
    push("Utility", parts.join(" · ") || null);
  }

  const group = (snapshot.group ?? null) as Row | null;
  if (group) {
    const entities = (Array.isArray(group.entities) ? group.entities : []) as Row[];
    const totals = (group.totals ?? {}) as Row;
    const spend = num(totals.est_monthly_spend_cents);
    push("Handing off", `${num(totals.count) ?? entities.length} items${spend ? ` · about ${fmtMoney(spend / 100)}/month estimated` : ""}`);
    for (const e of entities.slice(0, 12)) {
      const detail = [
        str(e.cadence_type),
        str(e.vendor_name) ? `with ${str(e.vendor_name)}` : null,
        str(e.category),
        num(e.estimated_cost_per_visit_cents) ? `about ${fmtMoney((num(e.estimated_cost_per_visit_cents) ?? 0) / 100)}/visit` : null,
        num(e.monthly_cost) ? `${fmtMoney(num(e.monthly_cost))}/mo` : null,
      ].filter(Boolean).join(", ");
      lines.push(`- ${str(e.label) ?? "Item"}${detail ? ` (${detail})` : ""}`);
    }
    if (entities.length > 12) lines.push(`- and ${entities.length - 12} more`);
  }

  for (const line of intakeDigestLines((snapshot.homeowner_intake ?? null) as Row | null)) {
    lines.push(line);
  }

  const costRef = (snapshot.cost_reference ?? null) as Row | null;
  if (costRef && (num(costRef.sample) ?? 0) >= 2) {
    const scopeLabel = str(costRef.category)
      ? `similar ${str(costRef.category)} work in this home`
      : "past service work in this home (all trades)";
    push(
      "Cost guide",
      `${scopeLabel} ran ${fmtMoney((num(costRef.low_cents) ?? 0) / 100)} to ${fmtMoney((num(costRef.high_cents) ?? 0) / 100)} (median ${fmtMoney((num(costRef.median_cents) ?? 0) / 100)}, ${num(costRef.sample)} jobs)`
    );
  }

  const profile = ((snapshot.household as Row | undefined)?.chez_profile ?? {}) as Row;
  const logistics = (profile.logistics ?? {}) as Row;
  const accessParts = [
    bool(logistics.has_pets) === true ? (str(logistics.pet_notes) ?? "has pets") : null,
    str(logistics.entry_instructions),
  ].filter(Boolean);
  if (accessParts.length > 0) push("Access", accessParts.join(" · "));

  const tiers = (profile.spending_tiers ?? {}) as Row;
  const auto = num(tiers.auto_approve_under);
  const explicit = num(tiers.explicit_above);
  if (auto || explicit) {
    const parts = [
      auto ? `auto-approve under ${fmtMoney(auto)}` : null,
      explicit ? `always ask above ${fmtMoney(explicit)}` : null,
    ].filter(Boolean);
    push("Budget authority", parts.join(" · "));
  }

  // Only the header line means nothing useful was assembled.
  if (lines.length === 1) return "";
  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// Readiness — what's missing before Chez can act well. Consumed by
// composer v2 (amber inline hints) and the operator's thin-request flag.
// ---------------------------------------------------------------------------

export interface ReadinessGap {
  key: string;
  label: string;
}

export function snapshotReadiness(snapshot: DelegationSnapshot): { score: number; missing: ReadinessGap[] } {
  const missing: ReadinessGap[] = [];
  const kind = str(snapshot.kind);

  const system = (snapshot.system ?? null) as Row | null;
  if (system) {
    if (!str(system.model_number) && !str(system.manufacturer)) {
      missing.push({ key: "system_model_missing", label: "No make or model on file for this system" });
    }
    if (!str(system.install_date)) {
      missing.push({ key: "system_install_missing", label: "Install date unknown for this system" });
    }
  }

  const history = (Array.isArray(snapshot.service_history) ? snapshot.service_history : []) as Row[];
  if ((kind === "task" || kind === "system") && system && history.length === 0) {
    missing.push({ key: "no_service_history", label: "No service history on file for this system" });
  }

  const vendor = (snapshot.vendor ?? null) as Row | null;
  if (kind === "contractor" && vendor && !str(vendor.phone)) {
    missing.push({ key: "vendor_phone_missing", label: "No phone number on file for this vendor" });
  }

  const routine = (snapshot.routine ?? null) as Row | null;
  if (kind === "routine" && routine && !num(routine.estimated_cost_per_visit_cents)) {
    missing.push({ key: "routine_cost_missing", label: "No cost estimate on file for this routine" });
  }

  const profile = ((snapshot.household as Row | undefined)?.chez_profile ?? {}) as Row;
  const logistics = (profile.logistics ?? {}) as Row;
  if (!str(logistics.entry_instructions)) {
    missing.push({ key: "no_entry_instructions", label: "No home access instructions in your Chez profile" });
  }

  const tiers = (profile.spending_tiers ?? {}) as Row;
  const intake = (snapshot.homeowner_intake ?? null) as Row | null;
  if (!intake && !num(tiers.auto_approve_under)) {
    missing.push({ key: "no_budget_signal", label: "No budget guidance for Chez to work within" });
  }

  const score = Math.max(20, Math.min(100, 100 - missing.length * 15));
  return { score, missing };
}

// ---------------------------------------------------------------------------
// Wave 4 — homeowner intake (what only the homeowner can tell Chez).
// iOS sends `intake` on every delegation; it lands at
// snapshot.homeowner_intake, and display-safe string mirrors go into the
// flat `context` map so shipped clients' [String: String] decode keeps
// working.
// ---------------------------------------------------------------------------

const INTAKE_BUDGET_BANDS = new Set([
  "under_250", "250_750", "750_2000", "2000_plus", "options_first",
]);
const INTAKE_URGENCIES = new Set(["asap", "this_week", "two_weeks", "flexible"]);
const INTAKE_WINDOWS = new Set(["weekday_am", "weekday_pm", "weekend"]);

const INTAKE_BUDGET_DISPLAY: Record<string, string> = {
  under_250: "Under $250",
  "250_750": "$250 to $750",
  "750_2000": "$750 to $2,000",
  "2000_plus": "$2,000 plus",
  options_first: "Show me options first",
};
const INTAKE_URGENCY_DISPLAY: Record<string, string> = {
  asap: "As soon as possible",
  this_week: "This week",
  two_weeks: "Within two weeks",
  flexible: "Flexible",
};
const INTAKE_WINDOW_DISPLAY: Record<string, string> = {
  weekday_am: "Weekday mornings",
  weekday_pm: "Weekday afternoons",
  weekend: "Weekends",
};

/// Validates + normalizes the raw intake payload from iOS. Unknown enum
/// values and junk fields are dropped rather than rejected — a client a
/// version ahead should degrade, not fail. Returns null when nothing
/// usable was sent.
export function sanitizeHomeownerIntake(raw: unknown): Row | null {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  const r = raw as Row;
  const out: Row = {};

  const band = str(r.budget_band)?.toLowerCase();
  if (band && INTAKE_BUDGET_BANDS.has(band)) out.budget_band = band;

  const low = num(r.budget_low_cents);
  const high = num(r.budget_high_cents);
  if (low !== null && low >= 0) out.budget_low_cents = Math.round(low);
  if (high !== null && high >= 0) out.budget_high_cents = Math.round(high);

  const urgency = str(r.urgency)?.toLowerCase();
  if (urgency && INTAKE_URGENCIES.has(urgency)) out.urgency = urgency;

  if (Array.isArray(r.preferred_windows)) {
    const windows = r.preferred_windows
      .map((w) => (typeof w === "string" ? w.trim().toLowerCase() : ""))
      .filter((w) => INTAKE_WINDOWS.has(w));
    if (windows.length > 0) out.preferred_windows = [...new Set(windows)];
  }

  const accessNote = capText(r.access_note_override, 500);
  if (accessNote) out.access_note_override = accessNote;

  return Object.keys(out).length > 0 ? out : null;
}

/// Display-safe string mirrors for the flat context map ("budget" /
/// "timing" keys — added to iOS displayContextKeys in Wave 4).
export function intakeContextMirrors(intake: Row | null): Record<string, string> {
  if (!intake) return {};
  const out: Record<string, string> = {};
  const band = str(intake.budget_band);
  if (band && INTAKE_BUDGET_DISPLAY[band]) out.budget = INTAKE_BUDGET_DISPLAY[band];
  const urgency = str(intake.urgency);
  if (urgency && INTAKE_URGENCY_DISPLAY[urgency]) out.timing = INTAKE_URGENCY_DISPLAY[urgency];
  return out;
}

function intakeDigestLines(intake: Row | null): string[] {
  if (!intake) return [];
  const lines: string[] = [];
  const band = str(intake.budget_band);
  const low = num(intake.budget_low_cents);
  const high = num(intake.budget_high_cents);
  const budgetLabel = band ? INTAKE_BUDGET_DISPLAY[band] ?? null : null;
  const range = low !== null && high !== null
    ? `${fmtMoney(low / 100)} to ${fmtMoney(high / 100)}`
    : null;
  if (budgetLabel || range) {
    lines.push(`Homeowner budget: ${[budgetLabel, range && budgetLabel !== range ? `(${range})` : null].filter(Boolean).join(" ")}`);
  }
  const urgency = str(intake.urgency);
  if (urgency && INTAKE_URGENCY_DISPLAY[urgency]) {
    lines.push(`Timing: ${INTAKE_URGENCY_DISPLAY[urgency]}`);
  }
  if (Array.isArray(intake.preferred_windows) && intake.preferred_windows.length > 0) {
    const windows = (intake.preferred_windows as unknown[])
      .map((w) => INTAKE_WINDOW_DISPLAY[str(w) ?? ""] ?? null)
      .filter(Boolean);
    if (windows.length > 0) lines.push(`Preferred windows: ${windows.join(", ")}`);
  }
  const accessNote = str(intake.access_note_override);
  if (accessNote) lines.push(`Access for this job: ${accessNote}`);
  return lines;
}

// ---------------------------------------------------------------------------
// Persistence helper
// ---------------------------------------------------------------------------

export async function attachSnapshotToRequest(
  service: ServiceClient,
  requestId: string,
  snapshot: DelegationSnapshot
): Promise<void> {
  const { error } = await service
    .from("chez_requests")
    .update({ snapshot })
    .eq("id", requestId);
  if (error) console.warn("[snapshot] attach failed:", error);
}
