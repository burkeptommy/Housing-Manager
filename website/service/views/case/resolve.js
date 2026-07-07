// Service portal v2 - case view: resolve flow + status transitions.
//
// Every resolution goes through the REQUIRED outcome mini-form (Phase 100
// discipline: a resolved case produces training data or it does not
// resolve). Payload shape verified against chez-concierge handleTransition
// (OutcomePayload) and migration 20270102_chez_request_outcomes.sql:
//
//   transition_status { request_id, to_status, outcome?: {
//     resolution_type, winning_contractor_id?, winning_vendor_name?,
//     winning_google_place_id?, final_cost_cents?, operator_minutes?,
//     summary?, automation_candidate?, friction_tags? } }

import { invalidate, esc } from "../../render.js";
import { state } from "../../state.js";
import { callConcierge } from "../../api.js";
import { toast } from "../../components/toast.js";
import { openModal } from "../../components/modal.js";
import { scrollThreadToBottom } from "./thread.js";

// Enum values verified against the resolution_type CHECK constraint in
// supabase/migrations/20270102_chez_request_outcomes.sql.
const RESOLUTION_TYPES = [
  { value: "completed_via_vendor", label: "Completed via vendor" },
  { value: "completed_internal", label: "Completed by Chez directly" },
  { value: "advice_only", label: "Advice only, nothing booked" },
  { value: "converted_to_standing", label: "Converted to standing routine" },
  { value: "no_vendor_found", label: "No vendor found" },
  { value: "homeowner_cancelled", label: "Homeowner cancelled" },
  { value: "duplicate_or_merged", label: "Duplicate or merged" },
  { value: "no_response", label: "Homeowner went quiet" },
  { value: "other", label: "Other" },
];

// Suggested friction vocabulary from the same migration.
const FRICTION_TAGS = [
  "vendor_no_answer", "scheduling_churn", "homeowner_slow_reply",
  "price_pushback", "scope_unclear", "vendor_no_show", "tooling_gap",
];

// Operator time quick-picks: the real values admin.js uses (5/15/30/60/120).
const MINUTE_PICKS = [5, 15, 30, 60, 120];

function num(v) {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string" && v.trim() !== "") {
    const n = Number(v);
    if (Number.isFinite(n)) return n;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Shared transition helper (used by the topbar, the composer quick toggle,
// and the resolve modal).
// ---------------------------------------------------------------------------

const SYSTEM_COPY = {
  resolved: "Chez marked this resolved.",
  waiting_customer: "Chez is waiting on your answer.",
  open: "Chez reopened this request.",
};

export async function performTransition(requestId, toStatus, outcome = null) {
  try {
    await callConcierge("transition_status", {
      request_id: requestId,
      to_status: toStatus,
      outcome: outcome || undefined,
    });
  } catch (err) {
    toast(`Could not update the case: ${err && err.message ? err.message : err}`, "error");
    return false;
  }

  const now = new Date().toISOString();
  const bundle = state.cases[requestId];
  if (bundle && bundle.request) {
    bundle.request.status = toStatus;
    bundle.request.resolved_at = toStatus === "resolved" ? now : null;
    bundle.request.last_message_at = now;
    // Mirror the system message the server just inserted so the thread
    // reflects the audit trail without a refetch.
    if (Array.isArray(bundle.messages)) {
      bundle.messages.push({
        id: `local-system-${Date.now()}`,
        role: "system",
        content: SYSTEM_COPY[toStatus] || "Chez updated this request.",
        created_at: now,
        attachments: [],
      });
    }
  }
  const row = (state.queue || []).find((r) => r && r.id === requestId);
  if (row) {
    row.status = toStatus;
    row.last_message_at = now;
  }

  invalidate("case-topbar", "case-queue-head", "case-queue-list", "case-composer", "case-thread");
  requestAnimationFrame(scrollThreadToBottom);
  return true;
}

// ---------------------------------------------------------------------------
// Confirmation modals for the non-resolve transitions
// ---------------------------------------------------------------------------

function confirmTransition({ title, body, confirmLabel, requestId, toStatus, successNote }) {
  let m = null;
  m = openModal({
    title,
    bodyHtml: `<p class="svc-modal__intro">${esc(body)}</p>`,
    actions: [
      { label: "Cancel", kind: "ghost", onClick: () => { if (m) m.close(); } },
      {
        label: confirmLabel,
        kind: "primary",
        onClick: async () => {
          if (m) m.close();
          const ok = await performTransition(requestId, toStatus);
          if (ok && successNote) toast(successNote, "success");
        },
      },
    ],
  });
}

export function markWaiting(requestId) {
  const bundle = state.cases[requestId];
  const status = bundle && bundle.request ? bundle.request.status : null;
  if (status === "waiting_customer") {
    toast("This case is already waiting on the homeowner.", "info");
    return;
  }
  confirmTransition({
    title: "Wait on the homeowner?",
    body: "They will see a permanent note in their thread: Chez is waiting on your answer. The SLA clock pauses until they reply.",
    confirmLabel: "Mark waiting",
    requestId,
    toStatus: "waiting_customer",
    successNote: "Case is now waiting on the homeowner.",
  });
}

/// Reopen covers both the resolved case ("Reopen") and the waiting case
/// ("Mark open"). Same transition, slightly different framing.
export function reopenCase(requestId, { fromWaiting = false } = {}) {
  confirmTransition({
    title: fromWaiting ? "Put this case back in your queue?" : "Reopen this case?",
    body: fromWaiting
      ? "The homeowner sees a permanent note: Chez reopened this request. The SLA clock restarts."
      : "The homeowner sees a permanent note in their thread: Chez reopened this request. The SLA clock restarts.",
    confirmLabel: fromWaiting ? "Mark open" : "Reopen",
    requestId,
    toStatus: "open",
    successNote: "Case reopened.",
  });
}

// ---------------------------------------------------------------------------
// Prefill: ported from admin.js guessResolveOutcomePrefill, adapted to the
// fetch_case_bundle shape (messages / visits / vendor_calls ride the bundle).
// ---------------------------------------------------------------------------

function guessPrefill(bundle) {
  const request = (bundle && bundle.request) || {};
  const messages = Array.isArray(bundle && bundle.messages) ? bundle.messages : [];
  const visits = Array.isArray(bundle && bundle.visits) ? bundle.visits : [];
  const calls = Array.isArray(bundle && bundle.vendor_calls) ? bundle.vendor_calls : [];

  const proposalOf = (m) => (m && m.proposal && typeof m.proposal === "object" ? m.proposal : null);
  const approvedVendorMsg = [...messages].reverse().find((m) => {
    const p = proposalOf(m);
    const kind = (m && m.proposal_kind) || (p && p.kind);
    return kind === "vendor" && p && p.status === "approved";
  });
  const approvedCostMsg = [...messages].reverse().find((m) => {
    const p = proposalOf(m);
    const kind = (m && m.proposal_kind) || (p && p.kind);
    return kind === "cost" && p && p.status === "approved";
  });
  const completedVisit = visits.find((v) => v && ((v.state || v.visit_state) === "completed"));

  let resolutionType = "advice_only";
  if (request.merged_into_request_id) resolutionType = "duplicate_or_merged";
  else if (completedVisit || approvedVendorMsg) resolutionType = "completed_via_vendor";

  const proposedVendor = approvedVendorMsg ? proposalOf(approvedVendorMsg).vendor || {} : {};
  const vendorName = (completedVisit && completedVisit.vendor_name) || proposedVendor.name || "";

  let costCents = completedVisit && num(completedVisit.final_cost_cents) !== null
    ? num(completedVisit.final_cost_cents)
    : null;
  if (costCents === null && approvedCostMsg) {
    const amount = num(proposalOf(approvedCostMsg).cost && proposalOf(approvedCostMsg).cost.amount);
    if (amount !== null && amount > 0) costCents = Math.round(amount * 100);
  }
  if (costCents === null && num(proposedVendor.estimated_cost) !== null) {
    costCents = Math.round(num(proposedVendor.estimated_cost) * 100);
  }
  if (costCents === null) {
    const recommended = calls.find((c) => c && c.recommended && (num(c.quoted_cost_cents) !== null || c.cost_custom || c.cost_range));
    if (recommended) {
      if (num(recommended.quoted_cost_cents) !== null) {
        costCents = num(recommended.quoted_cost_cents);
      } else {
        const raw = String(recommended.cost_custom || recommended.cost_range || "");
        const numeric = Number(raw.replace(/[^0-9.]/g, ""));
        if (Number.isFinite(numeric) && numeric > 4) costCents = Math.round(numeric * 100);
      }
    }
  }

  return {
    resolutionType,
    vendorName,
    costCents,
    // Identity riders from the approved vendor proposal: attach on confirm
    // only if the operator kept the prefilled name.
    vendorContractorId: proposedVendor.contractor_id || null,
    vendorPlaceId: proposedVendor.place_id || null,
  };
}

// ---------------------------------------------------------------------------
// The resolve modal
// ---------------------------------------------------------------------------

export function openResolveModal(requestId) {
  const bundle = state.cases[requestId];
  if (!bundle || !bundle.request) {
    toast("Give the case a second to load first.", "info");
    return;
  }
  if (bundle.request.status === "resolved") {
    toast("This case is already resolved.", "info");
    return;
  }

  const prefill = guessPrefill(bundle);

  const bodyHtml = `
    <div class="svc-resolve">
      <p class="svc-modal__intro">Twenty seconds of structure makes the next case cheaper. The homeowner sees a permanent "Chez marked this resolved" note in their thread.</p>
      <label class="svc-field"><span>How it resolved</span>
        <select class="svc-select" data-outcome="resolution_type">
          ${RESOLUTION_TYPES.map((t) => `<option value="${t.value}" ${t.value === prefill.resolutionType ? "selected" : ""}>${esc(t.label)}</option>`).join("")}
        </select>
      </label>
      <label class="svc-field"><span>Winning vendor (when one won)</span>
        <input type="text" class="svc-input" data-outcome="vendor_name" value="${esc(prefill.vendorName)}" placeholder="e.g. Romano Plumbing" />
      </label>
      <label class="svc-field"><span>Final cost in dollars (when known)</span>
        <input type="text" class="svc-input" data-outcome="final_cost" inputmode="decimal" value="${prefill.costCents != null ? esc(String(Math.round(prefill.costCents / 100))) : ""}" placeholder="e.g. 1200" />
      </label>
      <div class="svc-field">
        <span class="svc-field__hint">Your time on this case</span>
        <div class="svc-pickrow" data-outcome-minutes>
          ${MINUTE_PICKS.map((m) => `<button type="button" class="svc-pick" data-minutes="${m}">${m >= 60 ? `${m / 60}h` : `${m}m`}</button>`).join("")}
        </div>
      </div>
      <div class="svc-field">
        <span class="svc-field__hint">What made it slow (pick any)</span>
        <div class="svc-pickrow svc-pickrow--wrap" data-outcome-frictions>
          ${FRICTION_TAGS.map((t) => `<button type="button" class="svc-pick" data-friction="${t}">${esc(t.replaceAll("_", " "))}</button>`).join("")}
        </div>
      </div>
      <label class="svc-check">
        <input type="checkbox" data-outcome="automation_candidate" />
        <span>Software could have closed this without me</span>
      </label>
      <label class="svc-field"><span>One line summary (shows on the homeowner activity feed when a cost is set)</span>
        <textarea class="svc-textarea" rows="2" data-outcome="summary" placeholder="e.g. Booked Romano for the water heater swap, done same week"></textarea>
      </label>
    </div>
  `;

  let minutes = null;
  const frictions = new Set();
  let m = null;

  const confirm = async () => {
    const el = m && m.el ? m.el : document;
    const get = (f) => el.querySelector(`[data-outcome='${f}']`);
    const resolutionType = get("resolution_type") ? get("resolution_type").value : "other";

    const costRaw = get("final_cost") ? get("final_cost").value.trim() : "";
    let finalCostCents = null;
    if (costRaw) {
      const costNum = Number(costRaw.replace(/[^0-9.]/g, ""));
      if (!Number.isFinite(costNum) || costNum <= 0) {
        toast("Enter the final cost as plain dollars, like 1200.", "error");
        return;
      }
      finalCostCents = Math.round(costNum * 100);
    }

    const vendorNameRaw = get("vendor_name") ? get("vendor_name").value.trim() : "";
    const keptPrefillVendor = vendorNameRaw && prefill.vendorName &&
      vendorNameRaw.toLowerCase() === String(prefill.vendorName).trim().toLowerCase();

    const outcome = {
      resolution_type: resolutionType,
      winning_vendor_name: vendorNameRaw || null,
      winning_contractor_id: keptPrefillVendor ? (prefill.vendorContractorId || null) : null,
      winning_google_place_id: keptPrefillVendor ? (prefill.vendorPlaceId || null) : null,
      final_cost_cents: finalCostCents,
      operator_minutes: minutes,
      summary: (get("summary") && get("summary").value.trim()) || null,
      automation_candidate: !!(get("automation_candidate") && get("automation_candidate").checked),
      friction_tags: [...frictions],
    };

    if (m) m.close();
    const ok = await performTransition(requestId, "resolved", outcome);
    if (ok) toast("Case resolved.", "success");
  };

  m = openModal({
    title: "Resolve case",
    bodyHtml,
    actions: [
      { label: "Cancel", kind: "ghost", onClick: () => { if (m) m.close(); } },
      { label: "Resolve case", kind: "primary", onClick: confirm },
    ],
  });

  // Wire the quick-pick chips directly on the modal element (the modal body
  // is this module's own markup; the view-level action table does not reach
  // into modals).
  const rootEl = m && m.el ? m.el : null;
  if (rootEl) {
    rootEl.querySelectorAll("[data-minutes]").forEach((b) => {
      b.addEventListener("click", () => {
        const v = Number(b.dataset.minutes);
        minutes = minutes === v ? null : v;
        rootEl.querySelectorAll("[data-minutes]").forEach((x) => {
          x.classList.toggle("is-on", Number(x.dataset.minutes) === minutes);
        });
      });
    });
    rootEl.querySelectorAll("[data-friction]").forEach((b) => {
      b.addEventListener("click", () => {
        const t = b.dataset.friction;
        if (frictions.has(t)) frictions.delete(t);
        else frictions.add(t);
        b.classList.toggle("is-on", frictions.has(t));
      });
    });
  }
}
