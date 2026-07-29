// Service portal v2 - case view: conversation thread zone.
//
// Renders concierge_messages ascending. Roles: user (right, indigo tint),
// concierge (left, white), system (centered, muted italic) - the bubble
// treatments come from service.css (.svc-msg--user / --concierge /
// --system). Proposal messages render a read-only structured card
// (Approve / Decline live on the homeowner side; the operator only sees
// the state). Attachments render as filename chips.

import { esc } from "../../render.js";
import { state } from "../../state.js";
import { fmtDateTime, fmtMoneyCents, truncate } from "../../lib/format.js";

function str(v) {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t.length > 0 ? t : null;
}

function num(v) {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string" && v.trim() !== "") {
    const n = Number(v);
    if (Number.isFinite(n)) return n;
  }
  return null;
}

function moneyDollars(v) {
  const n = num(v);
  if (n === null) return null;
  return fmtMoneyCents(Math.round(n * 100));
}

function moneyCents(v) {
  const n = num(v);
  if (n === null) return null;
  return fmtMoneyCents(Math.round(n));
}

const PROPOSAL_KIND_LABELS = {
  vendor: "Vendor proposal",
  date_slot: "Date options",
  cost: "Cost proposal",
  quote: "Quote proposal",
};

const PROPOSAL_STATUS_TONES = {
  approved: "ok",
  declined: "bad",
  countered: "amber",
  pending: "muted",
};

const PROPOSAL_STATUS_LABELS = {
  approved: "Approved",
  declined: "Declined",
  countered: "Countered",
  pending: "Awaiting homeowner",
};

function fairBandLine(lowCents, highCents) {
  const low = moneyCents(lowCents);
  const high = moneyCents(highCents);
  if (!low || !high) return "";
  return `<div class="svc-muted">Fair market: ${esc(low)} to ${esc(high)}</div>`;
}

/// Read-only structured proposal card. Field semantics ported from
/// admin.js renderProposalCardHtml + the proposal builder payloads.
function renderProposalCard(proposal) {
  if (!proposal || typeof proposal !== "object" || !proposal.kind) return "";
  const status = str(proposal.status) || "pending";
  const tone = PROPOSAL_STATUS_TONES[status] || "muted";
  const statusLabel = PROPOSAL_STATUS_LABELS[status] || status;
  const kindLabel = PROPOSAL_KIND_LABELS[proposal.kind] || "Proposal";

  let body = "";
  if (proposal.kind === "vendor" && proposal.vendor && typeof proposal.vendor === "object") {
    const v = proposal.vendor;
    const slots = Array.isArray(v.availability_slots) ? v.availability_slots.filter((s) => str(s)) : [];
    const cost = str(v.estimated_cost_range) || (num(v.estimated_cost) !== null ? moneyDollars(v.estimated_cost) : null);
    const ratingBits = [
      num(v.rating) !== null ? `Rated ${num(v.rating)}` : null,
      num(v.review_count) !== null ? `${num(v.review_count)} reviews` : null,
    ].filter(Boolean).join(" · ");
    body = `
      <div class="svc-proposal__name">${esc(str(v.name) || "Vendor")}</div>
      ${cost ? `<div>Estimated: ${esc(cost)}</div>` : ""}
      ${fairBandLine(v.fair_market_low_cents, v.fair_market_high_cents)}
      ${slots.length > 0
        ? `<div>Times offered:<ul class="svc-proposal__list">${slots.map((s) => `<li>${esc(s)}</li>`).join("")}</ul></div>`
        : (str(v.estimated_window) ? `<div>Earliest: ${esc(v.estimated_window)}</div>` : "")}
      ${ratingBits ? `<div class="svc-muted">${esc(ratingBits)}</div>` : ""}
      ${str(v.rationale) ? `<div class="svc-muted">${esc(truncate(v.rationale, 240))}</div>` : ""}
    `;
  } else if (proposal.kind === "date_slot" && proposal.date_slot && typeof proposal.date_slot === "object") {
    const options = Array.isArray(proposal.date_slot.options) ? proposal.date_slot.options : [];
    body = options
      .filter((o) => o && typeof o === "object")
      .map((o) => `<div>${esc(str(o.label) || (str(o.iso) ? fmtDateTime(o.iso) : "Date option"))}</div>`)
      .join("");
  } else if (proposal.kind === "cost" && proposal.cost && typeof proposal.cost === "object") {
    const c = proposal.cost;
    body = `
      <div class="svc-proposal__name">${esc(moneyDollars(c.amount) || "Cost")}</div>
      ${str(c.vendor_name) ? `<div>${esc(c.vendor_name)}</div>` : ""}
      ${str(c.scope) ? `<div class="svc-muted">${esc(truncate(c.scope, 240))}</div>` : ""}
    `;
  } else if (proposal.kind === "quote" && proposal.quote && typeof proposal.quote === "object") {
    const q = proposal.quote;
    const alternatives = Array.isArray(q.alternatives) ? q.alternatives.filter((a) => a && str(a.vendor_name)) : [];
    body = `
      <div class="svc-proposal__name">${esc(str(q.vendor_name) || "Quote")}</div>
      ${num(q.total) !== null ? `<div>Total: ${esc(moneyDollars(q.total))}</div>` : ""}
      ${fairBandLine(q.fair_market_low_cents ?? (num(q.fair_market_low) !== null ? num(q.fair_market_low) * 100 : null),
                     q.fair_market_high_cents ?? (num(q.fair_market_high) !== null ? num(q.fair_market_high) * 100 : null))}
      ${str(q.valid_until) ? `<div class="svc-muted">Valid until ${esc(q.valid_until)}</div>` : ""}
      ${alternatives.length > 0 ? `<div class="svc-muted">Alternatives: ${alternatives.map((a) => esc(`${str(a.vendor_name)}${num(a.total) !== null ? ` (${moneyDollars(a.total)})` : ""}`)).join(", ")}</div>` : ""}
    `;
  }

  return `
    <div class="svc-proposal">
      <div class="svc-proposal__head">
        <span>${esc(kindLabel)}</span>
        <span class="svc-wochip svc-wochip--${tone}">${esc(statusLabel)}</span>
      </div>
      <div class="svc-proposal__body">${body || `<span class="svc-muted">Proposal details unavailable.</span>`}</div>
    </div>
  `;
}

function renderAttachments(attachments) {
  const list = Array.isArray(attachments) ? attachments.filter((a) => a && typeof a === "object") : [];
  if (list.length === 0) return "";
  return `
    <div class="svc-msg__attachments">
      ${list.map((a) => `<span class="svc-attach-chip">${esc(str(a.filename) || "Attachment")}</span>`).join("")}
    </div>
  `;
}

function homeownerLabel(bundle) {
  const dossierName = str(bundle && bundle.dossier_lite && bundle.dossier_lite.household && bundle.dossier_lite.household.name);
  if (dossierName) return dossierName;
  const request = (bundle && bundle.request) || {};
  const row = (state.queue || []).find((r) => r && r.id === request.id);
  return str(row && row.household_name) || "Homeowner";
}

function renderMessage(m, ownerName) {
  const role = str(m.role) || "user";
  const time = m.created_at ? fmtDateTime(m.created_at) : "";

  if (role === "system") {
    return `
      <div class="svc-msg svc-msg--system">
        <div class="svc-msg__bubble">${esc(str(m.content) || "")}</div>
        ${time ? `<div class="svc-msg__meta">${esc(time)}</div>` : ""}
      </div>
    `;
  }

  const isChez = role === "concierge";
  const sender = isChez ? "Chez (you)" : ownerName;
  return `
    <div class="svc-msg ${isChez ? "svc-msg--concierge" : "svc-msg--user"} ${m._optimistic ? "svc-msg--pending" : ""}">
      <div class="svc-msg__meta"><strong>${esc(sender)}</strong>${time ? ` · ${esc(time)}` : ""}</div>
      ${str(m.content) ? `<div class="svc-msg__bubble">${esc(m.content)}</div>` : ""}
      ${renderProposalCard(m.proposal)}
      ${renderAttachments(m.attachments)}
      ${m._optimistic ? `<div class="svc-msg__sending">Sending...</div>` : ""}
    </div>
  `;
}

// ---------------------------------------------------------------------------
// Zone entry point
// ---------------------------------------------------------------------------

export function renderThreadZone() {
  const id = state.activeCaseId;
  if (!id) return "";
  const bundle = state.cases[id];

  if (!bundle || bundle._error) {
    return bundle && bundle._error ? "" : `
      <div class="svc-thread svc-thread--loading">
        <div class="svc-skeleton" style="width:45%"></div>
        <div class="svc-skeleton" style="width:60%; margin-left:auto;"></div>
      </div>
    `;
  }

  const messages = Array.isArray(bundle.messages) ? bundle.messages.filter((m) => m && typeof m === "object") : [];
  if (messages.length === 0) {
    return `
      <div class="svc-thread">
        <h3 class="svc-wo__label">Thread</h3>
        <div class="svc-muted svc-thread__empty">No messages yet. Send the first reply below.</div>
      </div>
    `;
  }

  const ownerName = homeownerLabel(bundle);
  return `
    <div class="svc-thread">
      <h3 class="svc-wo__label">Thread</h3>
      ${messages.map((m) => renderMessage(m, ownerName)).join("")}
    </div>
  `;
}

/// Scrolls the workspace scroller (workorder + thread column) to its end so
/// the latest message is visible. Callers schedule via requestAnimationFrame
/// AFTER invalidate() so the microtask render flush has landed.
export function scrollThreadToBottom() {
  const scroller = document.querySelector("[data-svc-thread-scroll]");
  if (scroller) scroller.scrollTop = scroller.scrollHeight;
}
