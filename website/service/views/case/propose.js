// Service portal v2 - case view: inline proposal builder (Wave 3 Phase B).
//
// A DOCKED panel (not a modal) that slides open at the top of the thread
// zone when the operator clicks Propose on a recommended candidate, or
// Send recommendations on the vendor engine header (all recommended ones).
//
// Vendor chips act as tabs: each selected vendor carries its own draft
// (framing / offered times / cost line) prefilled from its call-ledger row;
// the fields below edit the active chip. Typing writes to the in-memory
// draft and never repaints the zone; chip switches and sends do.
//
// Send ships ONE propose call per vendor, shaped exactly like admin.js's
// packageAndSendRecommendedVendors (verified against handlePropose +
// iOS ChezProposalVendor's resilient decode):
//
//   { action: "propose", request_id, content: i === 0 ? intro : "",
//     proposal: { kind: "vendor", vendor: {
//       name, phone, rating, review_count, place_id?,
//       fair_market_low_cents?, fair_market_high_cents?, fair_market_source?,
//       estimated_cost? | estimated_cost_range?,   // numeric only for a
//                                                  // plain typed number
//       availability_slots?, estimated_window?,    // Phase 81.2 shape; the
//                                                  // window mirrors slot one
//       rationale? } } }
//
// undefined / empty / [] keys are stripped before send so the iOS card
// renders cleanly. The fair-market band derives from the analysis cache's
// chez_network comparables (min*0.9 .. max*1.1, source "chez_network"),
// the same fallback packageAndSend used when the operator typed no band.

import { invalidate, esc } from "../../render.js";
import { state } from "../../state.js";
import { callConcierge } from "../../api.js";
import { toast } from "../../components/toast.js";
import { truncate } from "../../lib/format.js";
import { scrollThreadToBottom } from "./thread.js";
import {
  candidatesFor, candidateKey, rowFor, saveRow,
} from "./vendors.js";

// ---------------------------------------------------------------------------
// Panel state
// ---------------------------------------------------------------------------

let panel = null; // { requestId, keys: [], included: Set, activeKey, drafts: {key: {framing, slots, cost}}, sending, polishing }

function activeId() {
  return state.activeCaseId;
}

export function resetProposeFor() {
  panel = null;
}

export function isProposeOpen() {
  return !!panel && panel.requestId === activeId();
}

// ---------------------------------------------------------------------------
// Open / close
// ---------------------------------------------------------------------------

/// Open for one candidate (Propose button) or every recommended one
/// (Send recommendations). Drafts prefill from each vendor's ledger row.
export function openProposeFor(requestId, keys) {
  if (!requestId || !Array.isArray(keys) || keys.length === 0) return;
  const ordered = candidatesFor(requestId)
    .map((v) => candidateKey(v))
    .filter((k) => keys.includes(k));
  if (ordered.length === 0) return;

  const drafts = {};
  for (const key of ordered) {
    const row = rowFor(requestId, key);
    const slots = Array.isArray(row.availability_slots) ? row.availability_slots : [];
    drafts[key] = {
      framing: row.rationale || "",
      slots: [slots[0] || "", slots[1] || "", slots[2] || ""],
      cost: row.cost_range === "custom" ? (row.cost_custom || "") : (row.cost_range || ""),
    };
  }
  panel = {
    requestId,
    keys: ordered,
    included: new Set(ordered),
    activeKey: ordered[0],
    drafts,
    sending: false,
    polishing: false,
  };
  invalidate("case-propose");
  requestAnimationFrame(() => {
    document.querySelector("[data-svc-propose]")?.scrollIntoView({ block: "nearest", behavior: "smooth" });
    document.querySelector("[data-propose-field='framing']")?.focus();
  });
}

export function closePropose() {
  panel = null;
  invalidate("case-propose");
}

// ---------------------------------------------------------------------------
// Chip interactions
// ---------------------------------------------------------------------------

export function activateChip(key) {
  if (!panel || !panel.drafts[key]) return;
  panel.activeKey = key;
  if (!panel.included.has(key)) panel.included.add(key); // tapping re-includes
  invalidate("case-propose");
}

export function removeChip(key) {
  if (!panel) return;
  panel.included.delete(key);
  panel.keys = panel.keys.filter((k) => k !== key);
  delete panel.drafts[key];
  if (panel.keys.length === 0) {
    closePropose();
    return;
  }
  if (panel.activeKey === key) panel.activeKey = panel.keys[0];
  invalidate("case-propose");
}

// ---------------------------------------------------------------------------
// Typing (delegated from index.js; never repaints)
// ---------------------------------------------------------------------------

export function handleProposeInput(target) {
  if (!panel) return;
  const draft = panel.drafts[panel.activeKey];
  if (!draft) return;
  if (target.matches("[data-propose-field='framing']")) {
    draft.framing = target.value;
  } else if (target.matches("[data-propose-field='cost']")) {
    draft.cost = target.value;
  } else if (target.matches("[data-propose-slot]")) {
    const idx = Number(target.getAttribute("data-propose-slot"));
    if (idx >= 0 && idx < 3) draft.slots[idx] = target.value;
  }
}

// ---------------------------------------------------------------------------
// Polish with AI (suggest_vendor_framing — payload ported from the cockpit
// call form: vendor identity + call notes + slots + cost context)
// ---------------------------------------------------------------------------

export async function polishFraming() {
  if (!panel || panel.polishing) return;
  const requestId = panel.requestId;
  const bundle = state.cases[requestId];
  if (!bundle || bundle._error || !bundle.request) return;
  const key = panel.activeKey;
  const draft = panel.drafts[key];
  const cand = candidatesFor(requestId).find((v) => candidateKey(v) === key);
  if (!draft || !cand) return;

  const request = bundle.request;
  const dossier = bundle.dossier_lite && typeof bundle.dossier_lite === "object" ? bundle.dossier_lite : {};
  const household = dossier.household && typeof dossier.household === "object" ? dossier.household : {};
  const profile = household.chez_profile && typeof household.chez_profile === "object" ? household.chez_profile : {};
  const property = dossier.property && typeof dossier.property === "object" ? dossier.property : null;
  const propertyContext = property
    ? `${property.year_built ? property.year_built + " " : ""}${property.property_type || "home"} in ${property.city || ""}, ${property.state || ""}`
    : "";
  const cache = request.analysis_cache && typeof request.analysis_cache === "object" ? request.analysis_cache : {};
  const inferredCategory = (cache.analysis && cache.analysis.inferred_category) || "";
  const row = rowFor(requestId, key);

  panel.polishing = true;
  invalidate("case-propose");
  try {
    const result = await callConcierge("suggest_vendor_framing", {
      household_id: request.household_id,
      request_summary: request.summary,
      request_category: request.category,
      vendor: {
        name: cand.company_name || cand.name,
        category: cand.category || inferredCategory || undefined,
        rating: cand.rating || undefined,
        review_count: cand.user_ratings_total || cand.review_count || undefined,
      },
      homeowner_about: profile.about_us || undefined,
      property_context: propertyContext || undefined,
      call_notes: row.notes || "",
      availability_slots: draft.slots.map((s) => s.trim()).filter(Boolean),
      cost_range: (draft.cost || "").trim(),
    });
    if (result && typeof result.framing === "string" && result.framing.trim()) {
      draft.framing = result.framing.trim();
    } else {
      toast("No framing came back. Write it by hand.", "info");
    }
  } catch (err) {
    toast(`Could not polish: ${err && err.message ? err.message : err}`, "error");
  } finally {
    panel.polishing = false;
    invalidate("case-propose");
  }
}

// ---------------------------------------------------------------------------
// Send
// ---------------------------------------------------------------------------

/// Fair-market band from the analysis cache's cross-household comparables.
/// Exact port of packageAndSend's chez_network fallback.
function deriveFairBand(cache) {
  const netCosts = (Array.isArray(cache.chez_network) ? cache.chez_network : [])
    .map((r) => Number(r && r.avg_quoted_cost_cents))
    .filter((n) => Number.isFinite(n) && n > 500);
  if (netCosts.length === 0) return null;
  return {
    low: Math.round(Math.min(...netCosts) * 0.9),
    high: Math.round(Math.max(...netCosts) * 1.1),
    source: "chez_network",
  };
}

/// admin.js's numeric rule: a plain typed number ("1200", "$1,200") ships
/// as estimated_cost; anything else non-empty ("$1,000–2,500", "Will quote
/// on site visit") ships verbatim as estimated_cost_range.
function costFields(rawCost) {
  const raw = (rawCost || "").trim();
  if (!raw) return {};
  const numeric = Number(raw.replace(/[^0-9.]/g, ""));
  const useNumeric = Number.isFinite(numeric) && numeric > 0 && /^\$?\s*[\d,]+\s*$/.test(raw);
  return useNumeric ? { estimated_cost: numeric } : { estimated_cost_range: raw };
}

function buildVendorProposal(cand, draft, fairBand) {
  const slots = draft.slots.map((s) => s.trim()).filter(Boolean);
  const vendor = {
    name: cand.company_name || cand.name,
    phone: cand.phone || cand.formatted_phone_number,
    rating: cand.rating,
    review_count: cand.user_ratings_total || cand.review_count,
    place_id: cand.google_place_id || cand.place_id || undefined,
    fair_market_low_cents: fairBand ? fairBand.low : undefined,
    fair_market_high_cents: fairBand ? fairBand.high : undefined,
    fair_market_source: fairBand ? fairBand.source : undefined,
    ...costFields(draft.cost),
    // Phase 81.2 wire shape: slot list + first-slot mirror for old clients.
    availability_slots: slots.length > 0 ? slots : undefined,
    estimated_window: slots.length > 0 ? slots[0] : undefined,
    rationale: (draft.framing || "").trim() || undefined,
  };
  // Strip undefined / empty / [] so the card renders cleanly (admin.js rule).
  Object.keys(vendor).forEach((k) => {
    const val = vendor[k];
    if (val === undefined || val === "" || val === null || (Array.isArray(val) && val.length === 0)) delete vendor[k];
  });
  return { kind: "vendor", vendor };
}

export async function sendProposals() {
  if (!panel || panel.sending) return;
  const requestId = panel.requestId;
  const bundle = state.cases[requestId];
  if (!bundle || bundle._error || !bundle.request) return;
  if (bundle.request.status === "resolved") {
    toast("This case is resolved. Reopen it first.", "info");
    return;
  }
  const cands = candidatesFor(requestId);
  const picked = panel.keys
    .filter((k) => panel.included.has(k))
    .map((k) => ({ key: k, cand: cands.find((v) => candidateKey(v) === k), draft: panel.drafts[k] }))
    .filter((p) => p.cand && p.draft);
  if (picked.length === 0) {
    toast("Pick at least one vendor to send.", "error");
    return;
  }

  const cache = bundle.request.analysis_cache && typeof bundle.request.analysis_cache === "object"
    ? bundle.request.analysis_cache : {};
  const fairBand = deriveFairBand(cache);
  const intro = picked.length > 1
    ? `Here are ${picked.length} options for you. Tap Approve on whichever fits and Chez handles the rest.`
    : "Chez found a vendor for you. Tap Approve to move forward.";

  panel.sending = true;
  invalidate("case-propose");

  let sent = 0;
  try {
    for (let i = 0; i < picked.length; i++) {
      const { key, cand, draft } = picked[i];
      const proposal = buildVendorProposal(cand, draft, fairBand);
      const resp = await callConcierge("propose", {
        request_id: requestId,
        proposal,
        content: i === 0 ? intro : "",
      });
      sent += 1;
      if (resp && resp.message) {
        if (!Array.isArray(bundle.messages)) bundle.messages = [];
        bundle.messages.push(resp.message);
        bundle.request.last_message_at = resp.message.created_at || new Date().toISOString();
      }
      // Write the final framing back into the ledger row so the resolve
      // prefill + future sessions see what actually shipped.
      const row = rowFor(requestId, key);
      if ((draft.framing || "").trim()) row.rationale = draft.framing.trim();
      saveRow(requestId, key, { draft: true });
    }
    toast(sent === 1 ? "Proposal sent." : `${sent} proposals sent.`, "success");
    panel = null;
    invalidate("case-propose", "case-thread", "case-vendors", "case-queue-list");
    requestAnimationFrame(scrollThreadToBottom);
  } catch (err) {
    panel.sending = false;
    invalidate("case-propose", "case-thread", "case-vendors");
    toast(
      sent > 0
        ? `Sent ${sent} of ${picked.length}, then failed: ${err && err.message ? err.message : err}`
        : `Send failed: ${err && err.message ? err.message : err}`,
      "error"
    );
  }
}

// ---------------------------------------------------------------------------
// Zone entry point
// ---------------------------------------------------------------------------

export function renderProposeZone() {
  if (!panel || panel.requestId !== activeId()) return "";
  const requestId = panel.requestId;
  const cands = candidatesFor(requestId);
  const byKey = new Map(cands.map((v) => [candidateKey(v), v]));
  const draft = panel.drafts[panel.activeKey] || { framing: "", slots: ["", "", ""], cost: "" };
  const includedCount = panel.keys.filter((k) => panel.included.has(k)).length;
  const disabled = panel.sending;

  const chips = panel.keys.map((key) => {
    const cand = byKey.get(key) || {};
    const name = cand.company_name || cand.name || key;
    const isActive = key === panel.activeKey;
    const isIncluded = panel.included.has(key);
    return `
      <span class="svc-propose__chip ${isActive ? "is-active" : ""} ${isIncluded ? "" : "is-excluded"}">
        <button type="button" class="svc-propose__chipname" data-action="propose-chip" data-key="${esc(key)}">${esc(truncate(name, 32))}</button>
        <button type="button" class="svc-propose__chipx" data-action="propose-chip-remove" data-key="${esc(key)}" aria-label="Remove ${esc(name)}">&times;</button>
      </span>
    `;
  }).join("");

  return `
    <section class="svc-propose" data-svc-propose>
      <header class="svc-propose__head">
        <div>
          <h3 class="svc-propose__title">Proposal to the homeowner</h3>
          <div class="svc-muted">Each vendor lands as its own Approve / Counter / Decline card in their app.</div>
        </div>
        <button type="button" class="svc-btn svc-btn--ghost svc-btn--small" data-action="propose-close" ${disabled ? "disabled" : ""}>Close</button>
      </header>
      <div class="svc-propose__chips">${chips}</div>
      <label class="svc-field">
        <span class="svc-propose__labelrow">
          Why Chez recommends them (shows on their card)
          <button type="button" class="svc-propose__polish" data-action="propose-polish" ${disabled || panel.polishing ? "disabled" : ""}>
            ${panel.polishing ? "Writing..." : "Polish with AI"}
          </button>
        </span>
        <textarea class="svc-textarea" rows="3" data-propose-field="framing"
                  placeholder="Two or three sentences. Lead with what makes them right for this home.">${esc(draft.framing)}</textarea>
      </label>
      <div class="svc-propose__grid">
        <div class="svc-field">
          <span>Times offered (optional)</span>
          <div class="svc-propose__slots">
            <input type="text" class="svc-input" data-propose-slot="0" value="${esc(draft.slots[0])}" placeholder="e.g. Tue May 12 morning" />
            <input type="text" class="svc-input" data-propose-slot="1" value="${esc(draft.slots[1])}" placeholder="Second option" />
            <input type="text" class="svc-input" data-propose-slot="2" value="${esc(draft.slots[2])}" placeholder="Third option" />
          </div>
        </div>
        <label class="svc-field">
          <span>Cost line (optional)</span>
          <input type="text" class="svc-input" data-propose-field="cost" value="${esc(draft.cost)}" placeholder="e.g. $1,000–2,500 or 1200" />
          <span class="svc-field__hint">A plain number reads as an exact price. Ranges ship word for word.</span>
        </label>
      </div>
      <footer class="svc-propose__foot">
        <span class="svc-muted">${includedCount} vendor${includedCount === 1 ? "" : "s"} will go out</span>
        <button type="button" class="svc-btn svc-btn--primary" data-action="propose-send" ${disabled || includedCount === 0 ? "disabled" : ""}>
          ${panel.sending ? "Sending..." : (includedCount > 1 ? `Send ${includedCount} proposals` : "Send proposal")}
        </button>
      </footer>
    </section>
  `;
}
