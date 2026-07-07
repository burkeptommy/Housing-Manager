// task-ingest.ts
//
// Shared server-side task creation from AI-extracted "suggested tasks".
//
// July 2026 email/document pipeline upgrade: several ingest paths now spot
// follow-up work — receive-email's classifier (invoice follow-ups, service
// reminders), analyze-document's maintenance_suggestions (inspection reports,
// warranty upkeep), and process-invoice's follow_up_needed. Rather than each
// re-implementing task creation (with subtly different dedup and field
// stamping), they all converge on ONE shape (`SuggestedTask`) and ONE
// creator (`createTasksFromSuggestions`).
//
// Two entry policies use this helper:
//   1. AUTO-ADD — no-document reminders/appointments the homeowner clearly
//      wants (Tom's rule: "if it's just reminders we auto add those too if
//      there is no document"). receive-email calls this directly at ingest.
//   2. ASK-THEN-ADD — document-attached follow-ups. The ingest path stashes
//      the same `SuggestedTask[]` in inbox_items.metadata.suggested_tasks and
//      process-inbox-item calls this helper only after the homeowner taps
//      "Add these" (action `add_suggested_tasks`).
//
// Dedup is the load-bearing safety property: a vendor using the household's
// alfred address as their primary contact will forward/CC the same reminder
// repeatedly. The 48h email-hash gate in receive-email stops same-email
// reprocessing; this helper stops cross-email duplicates by matching an
// existing non-archived task with the same household + case-insensitive title
// within a ±21-day due-date window.

// deno-lint-ignore-file no-explicit-any

export interface SuggestedTask {
  title: string;
  // ISO YYYY-MM-DD. When absent the caller's default window is used.
  due_date?: string | null;
  // Drives priority + whether it auto-adds. "soon" | "routine" | "informational"
  urgency?: string | null;
  // Short human explanation shown in the review card ("Technician flagged the
  // flame sensor is near end of life").
  reason?: string | null;
  // Canonical SystemCategoryRegistry key when the classifier could infer one.
  category?: string | null;
  // When true the task lands as a vendor coordination item (needs_vendor).
  needs_vendor?: boolean | null;
}

export interface CreateTasksArgs {
  householdId: string;
  // Required — maintenance_tasks.property_id is NOT NULL. Callers MUST resolve
  // a property first (address match, single-property fallback, or user pick).
  propertyId: string;
  // Optional vendor to link (from sender→contractor match or invoice vendor).
  contractorId?: string | null;
  // Provenance stamped on maintenance_tasks.source, e.g. "email_reminder",
  // "email_invoice_followup", "document_followup".
  source: string;
  suggestions: SuggestedTask[];
  // Fallback due date (ISO YYYY-MM-DD) when a suggestion omits one. Defaults
  // to 30 days out.
  defaultDueDate?: string;
}

export interface CreateTasksResult {
  created: Array<{ id: string; title: string }>;
  skippedDuplicates: string[];
  errors: string[];
}

function isoDaysFromNow(days: number): string {
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000)
    .toISOString()
    .split("T")[0];
}

function priorityForUrgency(urgency: string | null | undefined): string {
  switch ((urgency || "").toLowerCase()) {
    case "soon":
    case "critical":
    case "high":
      return "high";
    case "routine":
    case "medium":
      return "medium";
    default:
      return "low";
  }
}

// Normalize a title for dedup comparison: lowercase, strip the vendor
// reframing prefix ("Schedule Petro: ..."), collapse whitespace.
function normalizeTitle(title: string): string {
  return title
    .toLowerCase()
    .replace(/^schedule\s+[^:]+:\s*/i, "")
    .replace(/^find a contractor for:\s*/i, "")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Create maintenance tasks from AI suggestions, skipping duplicates.
 * Returns the created rows so the caller can build an informational inbox
 * item ("We added N reminders") or a confirmation toast.
 */
export async function createTasksFromSuggestions(
  supabase: any,
  args: CreateTasksArgs,
): Promise<CreateTasksResult> {
  const result: CreateTasksResult = { created: [], skippedDuplicates: [], errors: [] };
  if (!args.householdId || !args.propertyId) {
    result.errors.push("missing household or property");
    return result;
  }
  const fallbackDue = args.defaultDueDate || isoDaysFromNow(30);

  // Load recent non-archived task titles ONCE for cheap in-memory dedup
  // instead of a per-suggestion round trip.
  const { data: existingTasks } = await supabase
    .from("maintenance_tasks")
    .select("id, title, next_due_date")
    .eq("household_id", args.householdId)
    .eq("property_id", args.propertyId)
    .eq("is_archived", false);

  const existing: Array<{ title: string; due: string | null }> =
    (existingTasks || []).map((t: any) => ({
      title: normalizeTitle(t.title || ""),
      due: t.next_due_date || null,
    }));

  for (const s of args.suggestions) {
    const rawTitle = (s.title || "").trim();
    if (!rawTitle) continue;

    const dueDate = s.due_date || fallbackDue;
    const normTitle = normalizeTitle(rawTitle);

    // Dedup: same normalized title within a ±21-day window (annual services
    // legitimately recur, but not within three weeks).
    const isDuplicate = existing.some((e) => {
      if (e.title !== normTitle) return false;
      if (!e.due || !dueDate) return true; // title match, one side undated → treat as dup
      const diffDays = Math.abs(
        (new Date(e.due).getTime() - new Date(dueDate).getTime()) / (24 * 60 * 60 * 1000),
      );
      return diffDays <= 21;
    });
    if (isDuplicate) {
      result.skippedDuplicates.push(rawTitle);
      continue;
    }

    const needsVendor = s.needs_vendor === true || (s.needs_vendor == null && !args.contractorId);
    const insert: Record<string, unknown> = {
      household_id: args.householdId,
      property_id: args.propertyId,
      title: rawTitle,
      frequency: "once",
      next_due_date: dueDate,
      priority: priorityForUrgency(s.urgency),
      assignment_type: args.contractorId ? "vendor" : (needsVendor ? "vendor" : "either"),
      needs_vendor: needsVendor && !args.contractorId,
      source: args.source,
      service_key: "custom_seasonal_service",
      notes: s.reason ? `${s.reason}` : "Added from a forwarded email.",
      ...(args.contractorId ? { assigned_contractor_id: args.contractorId } : {}),
      ...(s.category ? { suggested_category: s.category } : {}),
    };

    const { data: inserted, error } = await supabase
      .from("maintenance_tasks")
      .insert(insert)
      .select("id, title")
      .single();

    if (error) {
      result.errors.push(`${rawTitle}: ${error.message}`);
      continue;
    }
    result.created.push({ id: inserted.id, title: inserted.title });
    // Track locally so two suggestions in the same batch don't both insert.
    existing.push({ title: normTitle, due: dueDate });
  }

  return result;
}
