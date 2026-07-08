// suggested-actions.ts
//
// Phase 7 (Ingestion Intelligence v2) — the ONE shape every ingestion path
// emits when it spots work the homeowner should review: receive-email's
// classifier, analyze-document's maintenance suggestions, and (M3)
// process-invoice's completions/follow-ups/cadence. The iOS universal
// review card renders these rows with per-row checkboxes and destination
// remapping; application is HYBRID:
//
//   - task / event / project kinds apply SERVER-side via process-inbox-item
//     action `apply_suggested_actions` (task dedup lives in task-ingest.ts).
//   - routine / visit_log / punch_item / complete_task / chez_request kinds
//     apply on iOS through the existing Swift machinery (RoutineSeeder
//     serviceKey dedup, ServiceOrchestrator, the task-completion path,
//     ChezConciergeService). The routine payload is EVIDENCE ONLY — never
//     kind/serviceKey/cadence_type — because those rules are single-sourced
//     in Swift (see CLAUDE.md hard rules; the painter-hijacks-smoke/CO bug
//     was a dedup-rules-drift bug).
//
// Completion is LEDGER-driven: iOS reports each applied action via
// process-inbox-item `record_applied_actions`; the item's action_completed
// stamps only when the ledger call says done. Partial applies are re-entrant.
//
// BACK-COMPAT (hard rule): emitters write metadata.suggested_actions
// ALONGSIDE the legacy metadata.suggested_tasks (task kinds only — never
// fabricate task fallbacks for routine/chez kinds). action_type stays
// "review_followups" when >= 1 task kind exists (old clients render the
// working "Add all N" card); "review_actions" when only non-task kinds
// exist (old clients render a generic item). `add_suggested_tasks` stays
// supported for old clients indefinitely.

// deno-lint-ignore-file no-explicit-any

import type { SuggestedTask } from "./task-ingest.ts";

export type SuggestedActionKind =
  | "task"
  | "complete_task"
  | "routine"
  | "visit_log"
  | "project"
  | "event"
  | "punch_item"
  | "chez_request"
  | "schedule_task"
  | "system_link";

export type SuggestedActionSource =
  | "email_classifier"
  | "document_analysis"
  | "invoice_analysis";

export interface SuggestedAction {
  /// Stable per-item address ("a1", "a2", …) — the applied-ledger key.
  id: string;
  kind: SuggestedActionKind;
  /// Action-first, user-facing ("Schedule annual chimney sweep").
  title: string;
  /// Evidence sentence quoted/paraphrased from the source.
  reason: string | null;
  confidence: "high" | "medium" | "low";
  /// Checkbox default on the review card.
  recommended: boolean;
  source: SuggestedActionSource;
  /// Kind-specific fields. Kept as a flat map — iOS decodes it as one
  /// all-optional struct so a malformed field never kills the row.
  payload: Record<string, unknown>;
}

export interface AppliedAction {
  id: string;
  status: "applied" | "duplicate" | "failed" | "skipped";
  /// Row id of what was created/updated, when applicable.
  result_ref: string | null;
  applied_at: string;
  applied_by_user_id: string | null;
}

/// Metadata cap — email_body already eats up to 5KB of the JSONB.
export const MAX_SUGGESTED_ACTIONS = 8;

/// Assign stable ids (a1, a2, …) and enforce the cap. Call ONCE per item
/// right before writing metadata; the ids are the ledger addresses so they
/// must never be re-derived differently later.
export function assignIds(actions: Omit<SuggestedAction, "id">[]): SuggestedAction[] {
  return actions.slice(0, MAX_SUGGESTED_ACTIONS).map((a, i) => ({
    ...a,
    id: `a${i + 1}`,
  }));
}

/// The legacy mirror: task kinds only, mapped to the pipeline-v1
/// SuggestedTask shape so OLD app versions keep a functional
/// "Add all N" card. Routine/chez/etc. kinds are intentionally absent —
/// an old client turning "set up pool routine" into a one-off task is
/// worse than the old client seeing nothing.
export function toLegacySuggestedTasks(actions: SuggestedAction[]): SuggestedTask[] {
  return actions
    .filter((a) => a.kind === "task")
    .map((a) => ({
      title: a.title,
      due_date: (a.payload.due_date as string | null) ?? null,
      urgency: (a.payload.urgency as string | null) ?? null,
      reason: a.reason,
      category: (a.payload.category as string | null) ?? null,
      needs_vendor: (a.payload.needs_vendor as boolean | null) ?? null,
    }));
}

/// action_type for the review item: keep the legacy value whenever an old
/// client could still act on the item (>= 1 task kind); otherwise the new
/// value old clients render as a generic informational item.
export function pickActionType(actions: SuggestedAction[]): "review_followups" | "review_actions" {
  return actions.some((a) => a.kind === "task") ? "review_followups" : "review_actions";
}

// ---------------------------------------------------------------------------
// Builders — small helpers so emitters construct consistent rows.
// ---------------------------------------------------------------------------

export function taskAction(args: {
  title: string;
  reason?: string | null;
  confidence?: "high" | "medium" | "low";
  recommended?: boolean;
  source: SuggestedActionSource;
  due_date?: string | null;
  urgency?: string | null;
  category?: string | null;
  needs_vendor?: boolean | null;
}): Omit<SuggestedAction, "id"> {
  return {
    kind: "task",
    title: args.title,
    reason: args.reason ?? null,
    confidence: args.confidence ?? "medium",
    recommended: args.recommended ?? true,
    source: args.source,
    payload: {
      due_date: args.due_date ?? null,
      urgency: args.urgency ?? null,
      category: args.category ?? null,
      needs_vendor: args.needs_vendor ?? null,
    },
  };
}

export function chezAction(args: {
  summary: string;
  description?: string | null;
  category?: string | null;
  source: SuggestedActionSource;
}): Omit<SuggestedAction, "id"> {
  return {
    kind: "chez_request",
    title: "Have Chez handle this",
    reason: null,
    confidence: "high",
    // Never the default — the homeowner opts into the concierge handoff.
    recommended: false,
    source: args.source,
    payload: {
      category: args.category ?? "general",
      summary: args.summary,
      description: args.description ?? null,
    },
  };
}

export function projectAction(args: {
  projectId: string;
  projectName: string;
  signal: string;
  source: SuggestedActionSource;
}): Omit<SuggestedAction, "id"> {
  return {
    kind: "project",
    title: `Attach to project: ${args.projectName}`,
    reason: `Matched via ${args.signal.replace(/_/g, " ")}`,
    confidence: "medium",
    recommended: false,
    source: args.source,
    payload: {
      project_id: args.projectId,
      project_name: args.projectName,
      signal: args.signal,
    },
  };
}

export function eventAction(args: {
  title: string;
  reason?: string | null;
  source: SuggestedActionSource;
  date: string;
  end_date?: string | null;
  all_day?: boolean;
  location?: string | null;
}): Omit<SuggestedAction, "id"> {
  return {
    kind: "event",
    title: args.title,
    reason: args.reason ?? null,
    confidence: "medium",
    recommended: true,
    source: args.source,
    payload: {
      date: args.date,
      end_date: args.end_date ?? null,
      all_day: args.all_day ?? false,
      location: args.location ?? null,
    },
  };
}

export function completeTaskAction(args: {
  taskId: string;
  taskTitle?: string | null;
  reason?: string | null;
  confidence?: "high" | "medium" | "low";
  source: SuggestedActionSource;
  completedOn?: string | null;
  costCents?: number | null;
}): Omit<SuggestedAction, "id"> {
  const label = args.taskTitle ?? "this task";
  return {
    kind: "complete_task",
    title: `Mark done: ${label}`,
    reason: args.reason ?? null,
    confidence: args.confidence ?? "medium",
    // Pre-check only when the invoice match was high-confidence.
    recommended: (args.confidence ?? "medium") === "high",
    source: args.source,
    payload: {
      task_id: args.taskId,
      task_title: args.taskTitle ?? null,
      completed_on: args.completedOn ?? null,
      cost_cents: args.costCents ?? null,
    },
  };
}

export function scheduleTaskAction(args: {
  date: string;                 // YYYY-MM-DD from the appointment email
  candidates: Array<{ task_id: string; title: string; due_date: string | null }>;
  vendorName?: string | null;
  reason?: string | null;
  source: SuggestedActionSource;
}): Omit<SuggestedAction, "id"> {
  return {
    kind: "schedule_task",
    title: `Put this ${args.vendorName ?? "vendor"} visit on a task`,
    reason: args.reason ?? null,
    confidence: "medium",
    recommended: true,
    source: args.source,
    payload: {
      date: args.date,
      candidates: args.candidates.slice(0, 4),
      count: args.candidates.length,
    },
  };
}

export function visitLogAction(args: {
  contractorId: string;
  vendorName?: string | null;
  date: string;                 // YYYY-MM-DD — the visit/service date
  costCents?: number | null;
  reason?: string | null;
  source: SuggestedActionSource;
}): Omit<SuggestedAction, "id"> {
  const cost = args.costCents != null ? ` ($${(args.costCents / 100).toFixed(0)})` : "";
  return {
    kind: "visit_log",
    title: `Log a ${args.vendorName ?? "vendor"} visit${cost}`,
    reason: args.reason ?? null,
    confidence: "high",
    recommended: true,
    source: args.source,
    payload: {
      contractor_id: args.contractorId,
      date: args.date,
      cost_cents: args.costCents ?? null,
    },
  };
}

export function systemLinkAction(args: {
  count: number;
  source: SuggestedActionSource;
}): Omit<SuggestedAction, "id"> {
  return {
    kind: "system_link",
    title: args.count === 1
      ? "1 new system spotted on this invoice"
      : `${args.count} new systems spotted on this invoice`,
    reason: "Review in the invoice scanner to add them to your home profile.",
    confidence: "medium",
    recommended: false,
    source: args.source,
    payload: { count: args.count },
  };
}

export function routineAction(args: {
  title: string;
  reason?: string | null;
  confidence?: "high" | "medium" | "low";
  source: SuggestedActionSource;
  /// Canonical-ish category string; iOS canonicalizes + derives kind.
  category: string;
  raw_category?: string | null;
  interval_days?: number | null;
  cadence_phrase?: string | null;
  active_months_hint?: number[] | null;
  quoted_text?: string | null;
  estimated_cost_cents?: number | null;
  contractor_id?: string | null;
}): Omit<SuggestedAction, "id"> {
  return {
    kind: "routine",
    title: args.title,
    reason: args.reason ?? null,
    confidence: args.confidence ?? "medium",
    recommended: true,
    source: args.source,
    // EVIDENCE ONLY — no kind / serviceKey / cadence_type. Swift owns those.
    payload: {
      category: args.category,
      raw_category: args.raw_category ?? null,
      interval_days: args.interval_days ?? null,
      cadence_phrase: args.cadence_phrase ?? null,
      active_months_hint: args.active_months_hint ?? null,
      quoted_text: args.quoted_text ?? null,
      estimated_cost_cents: args.estimated_cost_cents ?? null,
      contractor_id: args.contractor_id ?? null,
    },
  };
}
