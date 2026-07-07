// components/pills.js — pill + chip html-string helpers.
//
// Contract: slaPill(request), statusPill(status), categoryGlyph(category),
// snapshotChips(request). All return html strings ("" when not applicable)
// for composition inside zone renderFns.
//
// Purple discipline: the ONLY loud pill here is SLA-overdue (solid purple).
// Everything else stays on the neutral chrome. slaPill ports the
// chezSlaPill thresholds from admin.js: resolved -> nothing,
// waiting_customer -> muted, overdue -> critical, <= 4h -> amber, else ok.

import { esc } from "../render.js";
import { fmtMoneyCents } from "../lib/format.js";

export function slaPill(request) {
  if (!request || request.status === "resolved") return "";
  if (request.status === "waiting_customer") {
    return '<span class="svc-pill svc-pill--muted">Awaiting customer</span>';
  }
  if (!request.sla_due_at) return "";
  const due = new Date(request.sla_due_at).getTime();
  if (Number.isNaN(due)) return "";
  const remainingMs = due - Date.now();
  if (remainingMs <= 0) {
    const overdueHours = Math.round(Math.abs(remainingMs) / 3600000);
    return `<span class="svc-pill svc-pill--sla-overdue">Overdue ${overdueHours}h</span>`;
  }
  const hoursLeft = Math.round(remainingMs / 3600000);
  if (hoursLeft <= 4) {
    return `<span class="svc-pill svc-pill--sla-soon">SLA: ${hoursLeft}h left</span>`;
  }
  return `<span class="svc-pill svc-pill--sla-ok">SLA: ${hoursLeft}h left</span>`;
}

const STATUS = {
  open: { label: "Open", cls: "svc-pill--open" },
  waiting_customer: { label: "Waiting on customer", cls: "svc-pill--muted" },
  resolved: { label: "Resolved", cls: "svc-pill--resolved" },
};

export function statusPill(status) {
  const s = STATUS[status];
  if (!s) return status ? `<span class="svc-pill svc-pill--muted">${esc(prettify(status))}</span>` : "";
  return `<span class="svc-pill ${s.cls}">${s.label}</span>`;
}

// Category chips — same map the admin cockpit uses so the glyph language
// carries over for the operator.
const CATEGORIES = {
  find_vendor: { glyph: "🔍", label: "Find a vendor" },
  get_quote: { glyph: "💰", label: "Get a quote" },
  schedule_visit: { glyph: "📅", label: "Schedule a visit" },
  coordinate_task: { glyph: "✅", label: "Coordinate a task" },
  find_handyman: { glyph: "🛠️", label: "Find a handyman" },
  general: { glyph: "💬", label: "General help" },
};

export function categoryGlyph(category) {
  const c = CATEGORIES[category] || { glyph: "💬", label: prettify(category) || "Request" };
  return `<span class="svc-chip svc-chip--cat"><span class="svc-chip__glyph" aria-hidden="true">${c.glyph}</span>${esc(c.label)}</span>`;
}

// ── Snapshot chips ──────────────────────────────────────────────────────────
// Budget band + timing + readiness, read from either the server-derived
// `request.chips` (boot queue rows carry {budget, timing, has_snapshot,
// kind}) or, for full rows, `request.snapshot.homeowner_intake` + snapshot
// presence. Returns "" when there is nothing to show.

const BUDGET_BANDS = {
  under_250: "Under $250",
  "250_750": "$250 to $750",
  "750_2000": "$750 to $2,000",
  "2000_plus": "$2,000 plus",
  show_options: "Show me options",
};

const TIMING = {
  asap: "ASAP",
  this_week: "This week",
  two_weeks: "Within 2 weeks",
  within_2_weeks: "Within 2 weeks",
  flexible: "Flexible",
};

const KIND_LABELS = {
  task_delegation: "Delegated task",
  routine_delegation: "Delegated routine",
  contractor_delegation: "Delegated vendor",
  group_delegation: "Delegated group",
};

export function snapshotChips(request) {
  if (!request) return "";
  const server = request.chips || null;
  const intake = request.snapshot?.homeowner_intake || null;

  const budget = server?.budget ?? intakeBudgetLabel(intake);
  const timing = server?.timing ?? intakeTimingLabel(intake);
  const hasSnapshot = server ? server.has_snapshot === true : !!request.snapshot;
  const kind = server?.kind ?? request.snapshot?.kind ?? null;
  const gapCount = Array.isArray(request.snapshot?.readiness?.gaps)
    ? request.snapshot.readiness.gaps.length
    : 0;

  const chips = [];
  if (budget) chips.push(`<span class="svc-chip">${esc(budget)}</span>`);
  if (timing) chips.push(`<span class="svc-chip">${esc(timing)}</span>`);
  if (kind && KIND_LABELS[kind]) chips.push(`<span class="svc-chip">${KIND_LABELS[kind]}</span>`);
  if (hasSnapshot) chips.push('<span class="svc-chip svc-chip--ready">Work order ready</span>');
  if (gapCount > 0) {
    chips.push(`<span class="svc-chip svc-chip--gap">${gapCount} intake ${gapCount === 1 ? "gap" : "gaps"}</span>`);
  }
  if (!chips.length) return "";
  return `<span class="svc-chips">${chips.join("")}</span>`;
}

function intakeBudgetLabel(intake) {
  if (!intake) return null;
  if (typeof intake.budget_band === "string" && intake.budget_band) {
    return BUDGET_BANDS[intake.budget_band] || prettify(intake.budget_band);
  }
  const low = intake.budget_low_cents;
  const high = intake.budget_high_cents;
  if (low != null && high != null) return `${fmtMoneyCents(low)} to ${fmtMoneyCents(high)}`;
  if (high != null) return `Up to ${fmtMoneyCents(high)}`;
  if (low != null) return `${fmtMoneyCents(low)} plus`;
  return null;
}

function intakeTimingLabel(intake) {
  if (!intake) return null;
  const raw = intake.urgency || intake.timing;
  if (typeof raw !== "string" || !raw) return null;
  return TIMING[raw] || prettify(raw);
}

function prettify(token) {
  if (typeof token !== "string") return "";
  return token
    .replace(/[_-]+/g, " ")
    .trim()
    .replace(/^./, (c) => c.toUpperCase());
}
