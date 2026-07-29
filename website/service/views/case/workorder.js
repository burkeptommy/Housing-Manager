// Service portal v2 - case view: Work Order zone.
//
// Renders chez_requests.snapshot (server-assembled by snapshot.ts) as the
// operator's work order. Every section is defensive-null: one missing field
// never takes down the panel. Legacy rows (null snapshot) fall back to
// dossier_lite + the request's context dict.
//
// Pure render module: reads `state`, returns HTML strings. No listeners.

import { esc } from "../../render.js";
import { state } from "../../state.js";
import { slaPill, statusPill, categoryGlyph, snapshotChips } from "../../components/pills.js";
import { fmtDate, fmtDateTime, fmtMoneyCents, fmtAgo, truncate } from "../../lib/format.js";

// ---------------------------------------------------------------------------
// Small local helpers
// ---------------------------------------------------------------------------

const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
// routines.days_of_week convention: 1 = Sunday ... 7 = Saturday (iOS Calendar).
const DAY_NAMES = [null, "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

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

/// Dollars -> formatted money (fmtMoneyCents expects cents).
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

function humanize(v) {
  const s = str(String(v ?? ""));
  if (!s) return "";
  const spaced = s.replaceAll("_", " ").replaceAll("-", " ");
  return spaced.charAt(0).toUpperCase() + spaced.slice(1);
}

function looksLikeUuid(v) {
  return typeof v === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v.trim());
}

/// Port of snapshot.ts formatActiveMonths: contiguous circular runs render
/// as "Dec to Mar"; scattered sets list months; empty / year-round -> null.
function formatActiveMonths(months) {
  if (!Array.isArray(months)) return null;
  const valid = [...new Set(months.filter((m) => Number.isInteger(m) && m >= 1 && m <= 12))].sort((a, b) => a - b);
  if (valid.length === 0 || valid.length >= 12) return null;
  const set = new Set(valid);
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

function section(title, bodyHtml, extraClass = "") {
  if (!bodyHtml) return "";
  return `
    <section class="svc-wo__section ${extraClass}">
      <h3 class="svc-wo__label">${esc(title)}</h3>
      ${bodyHtml}
    </section>
  `;
}

function factRow(label, valueHtml) {
  if (!valueHtml) return "";
  return `<div class="svc-fact"><span class="svc-fact__k">${esc(label)}</span><span class="svc-fact__v">${valueHtml}</span></div>`;
}

function chip(text, tone = "") {
  if (!text) return "";
  return `<span class="svc-wochip ${tone ? `svc-wochip--${tone}` : ""}">${esc(text)}</span>`;
}

// ---------------------------------------------------------------------------
// Section renderers (each returns "" when it has nothing to say)
// ---------------------------------------------------------------------------

function renderHeadline(request) {
  if (!request) return "";
  const opened = request.created_at ? `Opened ${esc(fmtAgo(request.created_at))}` : "";
  return `
    <header class="svc-wo__head">
      <div class="svc-wo__title">${esc(request.summary || "Concierge request")}</div>
      <div class="svc-wo__pills">
        ${categoryGlyph(request.category)}
        ${statusPill(request.status)}
        ${slaPill(request) || ""}
        ${opened ? `<span class="svc-wo__opened">${opened}</span>` : ""}
      </div>
    </header>
  `;
}

// Same label table pills.js uses for the queue chips, so the work order
// and the rail read identically.
const BUDGET_BAND_LABELS = {
  under_250: "Under $250",
  "250_750": "$250 to $750",
  "750_2000": "$750 to $2,000",
  "2000_plus": "$2,000 plus",
  show_options: "Show me options",
};

/// Homeowner intake chips. The Wave 4 intake shape is snake_case JSONB;
/// read every plausible key so early payload variants still render.
function renderIntake(intake) {
  if (!intake || typeof intake !== "object") return "";
  const chips = [];

  const band = str(intake.budget_band);
  const low = num(intake.budget_low_cents);
  const high = num(intake.budget_high_cents);
  if (band) chips.push(chip(`Budget: ${BUDGET_BAND_LABELS[band] || humanize(band)}`));
  else if (low !== null || high !== null) {
    const lowTxt = low !== null ? fmtMoneyCents(low) : "";
    const highTxt = high !== null ? fmtMoneyCents(high) : "";
    chips.push(chip(`Budget: ${lowTxt && highTxt ? `${lowTxt} to ${highTxt}` : (lowTxt || highTxt)}`));
  }

  const timing = str(intake.urgency) || str(intake.timing) || str(intake.preferred_timing);
  if (timing) chips.push(chip(`Timing: ${humanize(timing)}`));

  const windows = Array.isArray(intake.preferred_windows) ? intake.preferred_windows : [];
  for (const w of windows.slice(0, 3)) {
    if (str(w)) chips.push(chip(`Window: ${str(w)}`));
  }

  const access = str(intake.access_note_override) || str(intake.access_notes) || str(intake.access);
  if (access) chips.push(chip(`Access: ${truncate(access, 80)}`));

  if (chips.length === 0) return "";
  return `<div class="svc-wo__chips">${chips.join("")}</div>`;
}

function renderThinIntakeBanner() {
  return `
    <div class="svc-banner svc-banner--amber">
      <strong>Thin intake.</strong> The homeowner sent this without budget or timing guidance. Plan on one clarifying question before you commit a vendor.
    </div>
  `;
}

function renderProperty(property) {
  if (!property || typeof property !== "object") return "";
  const parts = [
    num(property.year_built) ? `Built ${num(property.year_built)}` : null,
    str(property.property_type) ? humanize(property.property_type) : null,
    [str(property.street)].filter(Boolean).join(""),
    [str(property.city), str(property.state)].filter(Boolean).join(", ") || null,
    num(property.square_footage) ? `${num(property.square_footage).toLocaleString("en-US")} sq ft` : null,
  ].filter(Boolean);
  if (parts.length === 0) return "";
  return `<div class="svc-wo__property">${esc(parts.join(" · "))}</div>`;
}

function renderTask(task) {
  if (!task || typeof task !== "object") return "";
  const due = str(task.scheduled_date) || str(task.next_due_date);
  const rows = [
    factRow("Due", due ? esc(fmtDate(due)) : ""),
    factRow("Frequency", task.frequency ? esc(humanize(task.frequency)) : ""),
    factRow("Priority", task.priority ? esc(humanize(task.priority)) : ""),
    factRow("Routing", [
      str(task.assignment_type) ? humanize(task.assignment_type) : null,
      task.needs_vendor === true ? "needs a vendor" : null,
    ].filter(Boolean).map(esc).join(" · ")),
  ].join("");
  const detail = str(task.description) || str(task.notes);
  return section("Task", `
    ${str(task.title) ? `<div class="svc-wo__strong">${esc(task.title)}</div>` : ""}
    <div class="svc-facts">${rows}</div>
    ${detail ? `<div class="svc-wo__prose">${esc(truncate(detail, 600))}</div>` : ""}
  `);
}

function renderWarranties(warranties) {
  const list = Array.isArray(warranties) ? warranties : [];
  if (list.length === 0) return "";
  return `
    <div class="svc-wo__warranties">
      ${list.map((w) => {
        if (!w || typeof w !== "object") return "";
        const dates = [str(w.start_date) ? fmtDate(w.start_date) : null, str(w.end_date) ? fmtDate(w.end_date) : null]
          .filter(Boolean).join(" to ");
        const badges = [
          w.expires_within_90d === true ? chip("Expires within 90 days", "amber") : "",
          w.active === true ? chip("Active", "ok") : (w.active === false ? chip("Expired", "muted") : ""),
        ].join("");
        const meta = [
          str(w.warranty_type) ? humanize(w.warranty_type) : null,
          dates || null,
          str(w.policy_number) ? `Policy ${str(w.policy_number)}` : null,
        ].filter(Boolean).join(" · ");
        return `
          <div class="svc-warranty">
            <div class="svc-warranty__top">
              <strong>${esc(str(w.provider) || "Warranty")}</strong>
              ${badges}
            </div>
            ${meta ? `<div class="svc-muted">${esc(meta)}</div>` : ""}
            ${str(w.claim_phone) ? `<div class="svc-muted">Claims: <a href="tel:${esc(w.claim_phone)}">${esc(w.claim_phone)}</a></div>` : ""}
            ${str(w.coverage_details) ? `<div class="svc-muted">${esc(truncate(w.coverage_details, 200))}</div>` : ""}
          </div>
        `;
      }).join("")}
    </div>
  `;
}

function renderSystem(system) {
  if (!system || typeof system !== "object") return "";
  const nameLine = [str(system.manufacturer), str(system.model_number)].filter(Boolean).join(" ")
    || str(system.name) || str(system.category) || "System";
  const rows = [
    factRow("Category", [str(system.category), str(system.subtype) ? humanize(system.subtype) : null].filter(Boolean).map(esc).join(" · ")),
    factRow("Serial", str(system.serial_number) ? `<span class="svc-mono">${esc(system.serial_number)}</span>` : ""),
    factRow("Installed", str(system.install_date) ? esc(fmtDate(system.install_date)) : ""),
    factRow("Condition", [
      str(system.condition_rating) ? humanize(system.condition_rating) : null,
      str(system.status) ? humanize(system.status) : null,
    ].filter(Boolean).map(esc).join(" · ")),
    factRow("Last serviced", str(system.last_service_date) ? esc(fmtDate(system.last_service_date)) : ""),
    factRow("Next due", str(system.next_service_due) ? esc(fmtDate(system.next_service_due)) : ""),
    factRow("Lifetime spend", moneyDollars(system.total_spent) ? esc(moneyDollars(system.total_spent)) : ""),
  ].join("");

  const subsystems = Array.isArray(system.subsystems) ? system.subsystems.map((s) => str(s && s.name)).filter(Boolean) : [];
  const manuals = Array.isArray(system.manual_links) ? system.manual_links.filter((m) => m && str(m.url)) : [];

  return section("System", `
    <div class="svc-wo__strong">${esc(nameLine)}</div>
    <div class="svc-facts">${rows}</div>
    ${subsystems.length > 0 ? `<div class="svc-muted">Components: ${esc(subsystems.join(", "))}</div>` : ""}
    ${manuals.length > 0 ? `<div class="svc-wo__links">${manuals.map((m) => `<a class="svc-linkchip" href="${esc(m.url)}" target="_blank" rel="noopener">${esc(str(m.title) || "Manual")}</a>`).join("")}</div>` : ""}
    ${renderWarranties(system.warranties)}
    ${str(system.notes) ? `<div class="svc-wo__prose">${esc(truncate(system.notes, 400))}</div>` : ""}
  `);
}

function renderHistoryTable(history, title = "Service history") {
  const rowsIn = Array.isArray(history) ? history.filter((r) => r && typeof r === "object") : [];
  if (rowsIn.length === 0) return "";
  const body = rowsIn.slice(0, 10).map((r) => `
    <tr>
      <td>${esc(str(r.service_date) ? fmtDate(r.service_date) : "")}</td>
      <td>${esc(str(r.service_type) || str(r.description) || "Service")}${str(r.service_type) && str(r.description) ? `<div class="svc-muted">${esc(truncate(r.description, 90))}</div>` : ""}</td>
      <td>${esc(str(r.contractor_name) || "")}</td>
      <td class="svc-num">${esc(moneyDollars(r.cost) || "")}</td>
    </tr>
  `).join("");
  return section(title, `
    <table class="svc-table">
      <thead><tr><th>Date</th><th>Work</th><th>Vendor</th><th class="svc-num">Cost</th></tr></thead>
      <tbody>${body}</tbody>
    </table>
  `);
}

function renderVendor(vendor) {
  if (!vendor || typeof vendor !== "object") return "";
  const stats = vendor.stats && typeof vendor.stats === "object" ? vendor.stats : {};
  const statBits = [
    num(stats.jobs_on_file) ? `${num(stats.jobs_on_file)} job${num(stats.jobs_on_file) === 1 ? "" : "s"} on file` : null,
    moneyDollars(stats.total_spent) ? `${moneyDollars(stats.total_spent)} total` : null,
    str(stats.last_visit) ? `last visit ${fmtDate(stats.last_visit)}` : null,
  ].filter(Boolean).join(" · ");
  const contactBits = [
    str(vendor.phone) ? `<a href="tel:${esc(vendor.phone)}">${esc(vendor.phone)}</a>` : null,
    str(vendor.email) ? `<a href="mailto:${esc(vendor.email)}">${esc(vendor.email)}</a>` : null,
    str(vendor.website) ? `<a href="${esc(vendor.website)}" target="_blank" rel="noopener">Website</a>` : null,
  ].filter(Boolean).join(" · ");
  return section("Vendor on file", `
    <div class="svc-wo__strong">
      ${esc(str(vendor.company_name) || "Vendor")}
      ${str(vendor.category) ? chip(str(vendor.category)) : ""}
      ${num(vendor.rating) !== null ? chip(`Rated ${num(vendor.rating)}`) : ""}
      ${vendor.chez_owned === true ? chip("Chez point of contact", "purple") : ""}
    </div>
    ${str(vendor.contact_name) ? `<div class="svc-muted">${esc(vendor.contact_name)}</div>` : ""}
    ${contactBits ? `<div class="svc-wo__contact">${contactBits}</div>` : ""}
    ${statBits ? `<div class="svc-muted">${esc(statBits)}</div>` : ""}
    ${str(vendor.notes) ? `<div class="svc-wo__prose">${esc(truncate(vendor.notes, 300))}</div>` : ""}
    ${renderHistoryTable(vendor.history, "Work they have done here")}
  `);
}

function renderRoutine(routine) {
  if (!routine || typeof routine !== "object") return "";
  const days = Array.isArray(routine.days_of_week)
    ? routine.days_of_week.map((d) => DAY_NAMES[Number(d)] || null).filter(Boolean).join(", ")
    : null;
  const cadence = [
    str(routine.cadence_type) ? humanize(routine.cadence_type) : null,
    num(routine.cadence_interval_days) ? `every ${num(routine.cadence_interval_days)} days` : null,
    days,
    str(routine.time_of_day) ? `around ${str(routine.time_of_day)}` : null,
  ].filter(Boolean).join(" · ");
  const monthsLabel = formatActiveMonths(routine.active_months);
  const rows = [
    factRow("Cadence", cadence ? esc(cadence) : ""),
    factRow("Active", monthsLabel ? esc(monthsLabel) : (Array.isArray(routine.active_months) && routine.active_months.length >= 12 ? "Year round" : "")),
    factRow("Per visit", moneyCents(routine.estimated_cost_per_visit_cents) ? esc(`about ${moneyCents(routine.estimated_cost_per_visit_cents)}`) : ""),
    factRow("Next expected", str(routine.next_expected_date) ? esc(fmtDate(routine.next_expected_date)) : ""),
    factRow("Last confirmed", str(routine.last_confirmed_date) ? esc(fmtDate(routine.last_confirmed_date)) : ""),
  ].join("");
  const flags = [
    str(routine.setup_state) && routine.setup_state !== "active" ? chip(humanize(routine.setup_state), "amber") : "",
    routine.is_paused === true ? chip("Paused", "muted") : "",
  ].join("");
  return section("Routine", `
    <div class="svc-wo__strong">${esc(str(routine.label) || humanize(str(routine.routine_kind) || "Routine"))} ${flags}</div>
    <div class="svc-facts">${rows}</div>
    ${str(routine.cost_notes) ? `<div class="svc-muted">${esc(truncate(routine.cost_notes, 200))}</div>` : ""}
    ${str(routine.notes) ? `<div class="svc-wo__prose">${esc(truncate(routine.notes, 300))}</div>` : ""}
  `);
}

function renderVehicle(vehicle) {
  if (!vehicle || typeof vehicle !== "object") return "";
  const name = [num(vehicle.year), str(vehicle.make), str(vehicle.model), str(vehicle.trim)].filter(Boolean).join(" ")
    || str(vehicle.name) || "Vehicle";
  const rows = [
    factRow("Mileage", num(vehicle.current_mileage) !== null ? esc(`${num(vehicle.current_mileage).toLocaleString("en-US")} miles`) : ""),
    factRow("VIN", str(vehicle.vin) ? `<span class="svc-mono">${esc(vehicle.vin)}</span>` : ""),
    factRow("Registration", str(vehicle.registration_expiry) ? esc(`expires ${fmtDate(vehicle.registration_expiry)}`) : ""),
    factRow("Inspection", str(vehicle.inspection_expiry) ? esc(`expires ${fmtDate(vehicle.inspection_expiry)}`) : ""),
  ].join("");
  const recalls = Array.isArray(vehicle.open_recalls) ? vehicle.open_recalls.filter((r) => r && typeof r === "object") : [];
  const history = Array.isArray(vehicle.service_history) ? vehicle.service_history : [];
  return section("Vehicle", `
    <div class="svc-wo__strong">${esc(name)}</div>
    <div class="svc-facts">${rows}</div>
    ${recalls.length > 0 ? `
      <div class="svc-banner svc-banner--amber">
        <strong>${recalls.length} open recall${recalls.length === 1 ? "" : "s"}.</strong>
        ${recalls.slice(0, 3).map((r) => esc(truncate(str(r.summary) || str(r.campaign_number) || "Recall", 120))).join(" · ")}
      </div>` : ""}
    ${renderHistoryTable(history.map((r) => ({ ...r, contractor_name: null })), "Recent service")}
    ${str(vehicle.notes) ? `<div class="svc-wo__prose">${esc(truncate(vehicle.notes, 300))}</div>` : ""}
  `);
}

function renderProject(project) {
  if (!project || typeof project !== "object") return "";
  const quotes = Array.isArray(project.quotes) ? project.quotes.filter((q) => q && typeof q === "object") : [];
  const rows = [
    factRow("Status", str(project.status) ? esc(humanize(project.status)) : ""),
    factRow("Category", str(project.category) ? esc(humanize(project.category)) : ""),
    factRow("Budget", moneyDollars(project.estimated_budget) ? esc(moneyDollars(project.estimated_budget)) : ""),
  ].join("");
  const quotesHtml = quotes.length > 0 ? `
    <table class="svc-table">
      <thead><tr><th>Vendor</th><th>Trade</th><th class="svc-num">Quote</th><th class="svc-num">Fair est.</th></tr></thead>
      <tbody>${quotes.slice(0, 5).map((q) => `
        <tr>
          <td>${esc(str(q.vendor_name) || "Vendor")}</td>
          <td>${esc(str(q.trade) || "")}</td>
          <td class="svc-num">${esc(moneyDollars(q.total) || "")}</td>
          <td class="svc-num">${esc(moneyDollars(q.fair_total) || "")}</td>
        </tr>`).join("")}
      </tbody>
    </table>` : "";
  return section("Project", `
    <div class="svc-wo__strong">${esc(str(project.name) || "Project")}</div>
    <div class="svc-facts">${rows}</div>
    ${str(project.description) ? `<div class="svc-wo__prose">${esc(truncate(project.description, 400))}</div>` : ""}
    ${quotesHtml}
  `);
}

function renderUtility(utility) {
  if (!utility || typeof utility !== "object") return "";
  const rows = [
    factRow("Type", str(utility.provider_type) ? esc(humanize(utility.provider_type)) : ""),
    factRow("Plan", str(utility.plan_name) ? esc(utility.plan_name) : ""),
    factRow("Monthly", moneyDollars(utility.monthly_cost) ? esc(moneyDollars(utility.monthly_cost)) : ""),
    factRow("Phone", str(utility.phone) ? `<a href="tel:${esc(utility.phone)}">${esc(utility.phone)}</a>` : ""),
  ].join("");
  return section("Utility account", `
    <div class="svc-wo__strong">${esc(str(utility.provider_name) || "Utility")}</div>
    <div class="svc-facts">${rows}</div>
  `);
}

function renderDocuments(snapshot) {
  const single = snapshot.document && typeof snapshot.document === "object" ? [snapshot.document] : [];
  const list = Array.isArray(snapshot.documents) ? snapshot.documents.filter((d) => d && typeof d === "object") : [];
  const docs = [...single, ...list].slice(0, 10);
  if (docs.length === 0) return "";
  return section("Documents on file", `
    <div class="svc-wo__docs">
      ${docs.map((d) => `
        <div class="svc-doc">
          <span>${esc(str(d.title) || "Document")}</span>
          <span class="svc-muted">${esc([str(d.category), str(d.expiration_date) ? `expires ${fmtDate(d.expiration_date)}` : null].filter(Boolean).join(" · "))}</span>
        </div>`).join("")}
    </div>
  `);
}

function renderGroup(group) {
  if (!group || typeof group !== "object") return "";
  const entities = Array.isArray(group.entities) ? group.entities.filter((e) => e && typeof e === "object") : [];
  const totals = group.totals && typeof group.totals === "object" ? group.totals : {};
  const count = num(totals.count) ?? entities.length;
  if (count === 0 && entities.length === 0) return "";
  const spend = moneyCents(totals.est_monthly_spend_cents);
  const headline = `Handing off ${count} item${count === 1 ? "" : "s"}${spend ? ` · about ${spend}/month estimated` : ""}`;
  const rows = entities.slice(0, 12).map((e) => {
    const detail = [
      str(e.cadence_type) ? humanize(e.cadence_type) : null,
      str(e.vendor_name) ? `with ${str(e.vendor_name)}` : null,
      str(e.category),
      str(e.status) ? humanize(e.status) : null,
      moneyCents(e.estimated_cost_per_visit_cents) ? `about ${moneyCents(e.estimated_cost_per_visit_cents)}/visit` : null,
      moneyDollars(e.monthly_cost) ? `${moneyDollars(e.monthly_cost)}/mo` : null,
      str(e.phone),
    ].filter(Boolean).join(", ");
    return `<li>${esc(str(e.label) || "Item")}${detail ? ` <span class="svc-muted">(${esc(detail)})</span>` : ""}</li>`;
  }).join("");
  return section(`Group handoff: ${humanize(str(group.group) || "items")}`, `
    <div class="svc-wo__strong">${esc(headline)}</div>
    <ul class="svc-wo__list">${rows}</ul>
    ${entities.length > 12 ? `<div class="svc-muted">and ${entities.length - 12} more</div>` : ""}
  `);
}

function renderCostReference(costRef) {
  if (!costRef || typeof costRef !== "object") return "";
  const sample = num(costRef.sample) ?? 0;
  const category = str(costRef.category);
  if (sample < 2) {
    if (category) {
      return section("Cost reference", `<div class="svc-muted">No past ${esc(category)} costs on file for this home yet.</div>`);
    }
    return "";
  }
  const scope = category
    ? `Similar ${category} work in this home`
    : "Past service work in this home (all trades)";
  const line = `${scope} ran ${moneyCents(costRef.low_cents) || "?"} to ${moneyCents(costRef.high_cents) || "?"} (median ${moneyCents(costRef.median_cents) || "?"}, ${sample} jobs).`;
  return section("Cost reference", `<div>${esc(line)}</div>`);
}

function renderStandingInstructions(chezProfile) {
  const profile = chezProfile && typeof chezProfile === "object" ? chezProfile : {};
  const about = str(profile.about_us);
  const logistics = profile.logistics && typeof profile.logistics === "object" ? profile.logistics : {};
  const tiers = profile.spending_tiers && typeof profile.spending_tiers === "object" ? profile.spending_tiers : {};
  const prefs = profile.vendor_preferences && typeof profile.vendor_preferences === "object" ? profile.vendor_preferences : {};

  const bits = [];
  if (about) bits.push(`<div class="svc-wo__prose">${esc(truncate(about, 280))}</div>`);

  const logisticsBits = [
    logistics.has_pets === true ? (str(logistics.pet_notes) || "Has pets") : null,
    str(logistics.entry_instructions) ? `Entry: ${str(logistics.entry_instructions)}` : null,
  ].filter(Boolean);
  if (logisticsBits.length > 0) bits.push(`<div>${esc(logisticsBits.join(" · "))}</div>`);

  const auto = num(tiers.auto_approve_under);
  const ping = num(tiers.ping_under);
  const explicit = num(tiers.explicit_above);
  const tierBits = [
    auto ? `Auto approve under ${moneyDollars(auto)}` : null,
    ping ? `Quick ping under ${moneyDollars(ping)}` : null,
    explicit ? `Always ask above ${moneyDollars(explicit)}` : null,
  ].filter(Boolean);
  if (tierBits.length > 0) bits.push(`<div>${chip("Budget authority", "purple")} ${esc(tierBits.join(" · "))}</div>`);

  const prefBits = [
    str(prefs.budget_orientation) ? `${humanize(prefs.budget_orientation)} orientation` : null,
    prefs.prefer_local_owned === true ? "Prefers local owned shops" : null,
    str(prefs.notes),
  ].filter(Boolean);
  if (prefBits.length > 0) bits.push(`<div class="svc-muted">${esc(prefBits.join(" · "))}</div>`);

  if (bits.length === 0) return "";
  return section("Standing instructions", bits.join(""));
}

/// Legacy fallback: the request's context dict, rendered as a recap of
/// whatever display strings the app attached at submit time.
function renderContextRecap(context) {
  if (!context || typeof context !== "object") return "";
  const rows = Object.entries(context)
    .filter(([k, v]) => !k.startsWith("_") && (typeof v === "string" || typeof v === "number" || typeof v === "boolean"))
    .filter(([, v]) => !looksLikeUuid(String(v)))
    .filter(([, v]) => String(v).trim() !== "")
    .slice(0, 14)
    .map(([k, v]) => factRow(humanize(k), esc(truncate(String(v), 200))));
  if (rows.length === 0) return "";
  return section("What the homeowner sent", `<div class="svc-facts">${rows.join("")}</div>`);
}

// ---------------------------------------------------------------------------
// Zone entry point
// ---------------------------------------------------------------------------

export function renderWorkOrderZone() {
  const id = state.activeCaseId;
  if (!id) {
    return `
      <div class="svc-workspace-empty">
        <strong>No case open.</strong>
        <span>Pick one from the queue on the left, or head back to Today.</span>
      </div>
    `;
  }
  const bundle = state.cases[id];

  if (!bundle) {
    return `
      <div class="svc-wo svc-wo--loading">
        <div class="svc-skeleton" style="width:55%"></div>
        <div class="svc-skeleton" style="width:80%"></div>
        <div class="svc-skeleton" style="width:70%"></div>
        <div class="svc-muted">Pulling the case file...</div>
      </div>
    `;
  }

  if (bundle._error) {
    return `
      <div class="svc-wo svc-wo--error">
        <div class="svc-wo__strong">Could not load this case.</div>
        <div class="svc-muted">${esc(truncate(String(bundle._error), 200))}</div>
        <button type="button" class="svc-btn svc-btn--small" data-action="retry-bundle">Try again</button>
      </div>
    `;
  }

  const request = bundle.request || {};
  const snapshot = request.snapshot && typeof request.snapshot === "object" ? request.snapshot : null;
  const dossier = bundle.dossier_lite && typeof bundle.dossier_lite === "object" ? bundle.dossier_lite : {};
  const referenced = dossier.referenced && typeof dossier.referenced === "object" ? dossier.referenced : {};

  const parts = [renderHeadline(request)];

  if (snapshot) {
    const intake = snapshot.homeowner_intake && typeof snapshot.homeowner_intake === "object" ? snapshot.homeowner_intake : null;
    parts.push(intake ? renderIntake(intake) : renderThinIntakeBanner());
    parts.push(renderProperty(snapshot.property));
    parts.push(renderTask(snapshot.task));
    parts.push(renderSystem(snapshot.system));
    parts.push(renderHistoryTable(snapshot.service_history));
    parts.push(renderVendor(snapshot.vendor));
    parts.push(renderRoutine(snapshot.routine));
    parts.push(renderVehicle(snapshot.vehicle));
    parts.push(renderProject(snapshot.project));
    parts.push(renderUtility(snapshot.utility));
    parts.push(renderDocuments(snapshot));
    parts.push(renderGroup(snapshot.group));
    parts.push(renderCostReference(snapshot.cost_reference));
    const household = snapshot.household && typeof snapshot.household === "object" ? snapshot.household : {};
    parts.push(renderStandingInstructions(household.chez_profile));
  } else {
    // Legacy row: no server-assembled work order. Build from dossier_lite
    // plus the context dict so the operator still gets everything on file.
    parts.push(`
      <div class="svc-banner svc-banner--neutral">
        This request came in before Chez captured full work orders. Here is what is on file for this home.
      </div>
    `);
    parts.push(renderContextRecap(request.context));
    parts.push(renderProperty(dossier.property));
    parts.push(renderTask(referenced.task));
    parts.push(renderSystem(referenced.system));
    parts.push(renderVendor(referenced.contractor));
    parts.push(renderRoutine(referenced.routine));
    const household = dossier.household && typeof dossier.household === "object" ? dossier.household : {};
    parts.push(renderStandingInstructions(household.chez_profile));
    const members = Array.isArray(dossier.family_members) ? dossier.family_members : [];
    if (members.length > 0) {
      const names = members.map((m) => str(m && m.first_name)).filter(Boolean).slice(0, 6).join(", ");
      parts.push(section("Household", `<div class="svc-muted">${esc(`${members.length} member${members.length === 1 ? "" : "s"}${names ? `: ${names}` : ""}`)}</div>`));
    }
  }

  return `<div class="svc-wo">${parts.filter(Boolean).join("")}</div>`;
}
