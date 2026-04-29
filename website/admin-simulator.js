// =============================================================================
// admin-simulator.js — JS port of MaintenanceTaskReconciler + Day1TaskCurator
// =============================================================================
// Pure-function simulator that takes property facts (state, region,
// attributes, subtypes, preference tier) and returns the task list that
// WOULD seed if you ran the reconciler on a real household with those
// facts. Lets Tom verify proposed template changes against a hypothetical
// home before asking for an iOS rebuild.
//
// Not pixel-perfect parity with Swift — it focuses on the gating + routing
// rules that drive 95% of the seeding decisions. Bundle collapsing,
// safetyFloor short-circuit, regional pack filter, isEssential gating,
// requiredSubtypes filter, preference-tier flip, and Day1Curator routing
// are all faithfully ported. Seasonal anchor math + interpolation are
// kept simple (just labels, not computed dates).

const TIER_DIY = "diy";
const TIER_MIXED = "mixed";
const TIER_HIRE_OUT = "hire_out";

const STATE_REGION_MAP = {
  // Northeast
  CT: "northeast", MA: "northeast", ME: "northeast", NH: "northeast",
  NJ: "northeast", NY: "northeast", PA: "northeast", RI: "northeast",
  VT: "northeast",
  // Southeast
  AL: "southeast", FL: "southeast", GA: "southeast", KY: "southeast",
  MS: "southeast", NC: "southeast", SC: "southeast", TN: "southeast",
  VA: "southeast", WV: "southeast", DE: "southeast", MD: "southeast",
  // Midwest
  IL: "midwest", IN: "midwest", IA: "midwest", KS: "midwest", MI: "midwest",
  MN: "midwest", MO: "midwest", NE: "midwest", ND: "midwest", OH: "midwest",
  SD: "midwest", WI: "midwest",
  // Southwest
  AZ: "southwest", NM: "southwest", OK: "southwest", TX: "southwest",
  // West
  AK: "west", CA: "west", CO: "west", HI: "west", ID: "west", MT: "west",
  NV: "west", OR: "west", UT: "west", WA: "west", WY: "west", DC: "northeast",
};

// Default fact bundle the form pre-fills with. Northeast HNW family of 4
// in a 4-bed colonial — close to Tom's TestFlight cohort.
export const DEFAULT_FACTS = {
  state: "CT",
  yearBuilt: 1962,
  squareFootage: 4200,
  preferenceTier: TIER_MIXED,
  // Subtypes / flags drawn from the same names the Swift reconciler reads.
  subtypes: {
    // Roofing
    roof_asphalt: true,
    // HVAC
    central_ducted: true,
    has_humidifier: false,
    // Heating fuel + heat
    natural_gas: true,
    // Plumbing
    has_sump_pump: true,
    has_sump_battery_backup: true,
    // Water source
    municipal_water: true,
    // Sewer
    municipal_sewer: true,
    // Lawn / outdoor
    natural_lawn: true,
    has_irrigation: true,
    // Pool
    has_pool: false,
    pool_chlorine: false,
    pool_inground: false,
    // Pets
    has_pets: false,
    // Garage / driveway
    has_garage: true,
    driveway_asphalt: true,
    // Generator
    has_generator: false,
    // Solar
    has_solar: false,
    // EV
    has_ev_charger: false,
    // HNW Phase 57
    has_built_in_grill: false,
    has_outdoor_lighting: false,
    has_leak_detector: false,
    has_central_vacuum: false,
    has_radon_mitigation: false,
    has_pool_safety_fence: false,
    has_scheduled_valuables: false,
    // Specialty subtypes
    has_chimney: true,
    has_wood_fireplace: true,
    has_well: false,
    has_septic: false,
    has_security_system: true,
  },
  // Q15b household contractors — used to flip .either tasks to .vendor
  // when a contractor for the matching category exists.
  hasContractorsFor: {
    Plumbing: false,
    HVAC: false,
    Landscaping: false,
    "Pool/Spa": false,
    "Pest Control": false,
    Electrical: false,
    Roofing: false,
    Chimney: false,
    Septic: false,
    Well: false,
  },
};

// =============================================================================
// Public API
// =============================================================================

export function runSimulation(facts, templatesJSON, systemsJSON) {
  const templates = templatesJSON?.entries || [];
  const systems = systemsJSON?.entries || [];
  const region = factRegion(facts);
  const activeSubtypes = activeSubtypeSet(facts);
  const tier = facts.preferenceTier || TIER_MIXED;

  // Gate templates by regional pack + isEssential + requiredSubtypes
  const eligible = templates.filter((t) => {
    if (t.regionalPack && t.regionalPack !== region) return false;
    if (t.isEssential === false) return false; // simulator only seeds essentials
    if (!subtypesSatisfied(t.requiredSubtypes || [], activeSubtypes)) return false;
    return true;
  });

  // Group by bundle so children roll up.
  const bundleMap = new Map();
  const standalone = [];
  for (const t of eligible) {
    if (t.bundleId) {
      if (!bundleMap.has(t.bundleId)) bundleMap.set(t.bundleId, []);
      bundleMap.get(t.bundleId).push(t);
    } else {
      standalone.push(t);
    }
  }

  // For each bundle, synthesize a parent task that lists children. The
  // bundle's routing comes from the first child (template authors keep
  // these consistent within a bundle).
  const bundleParents = [];
  for (const [bundleId, children] of bundleMap.entries()) {
    const first = children[0];
    bundleParents.push({
      isBundle: true,
      bundleId,
      bundleTitle: first.bundleTitle || prettifyBundleId(bundleId),
      parentTemplate: first,
      children,
      systemCategory: first.systemCategory,
      seasonalTiming: first.seasonalTiming,
      assignmentType: first.assignmentType || "either",
      routingOverride: first.routingOverride,
      safetyFloor: children.some((c) => c.safetyFloor === true),
      requiredSubtypes: first.requiredSubtypes,
      regionalPack: first.regionalPack,
      title: `Schedule ${first.bundleTitle || prettifyBundleId(bundleId)}`,
      description: first.description,
      frequency: first.frequency,
      priority: first.priority,
    });
  }

  // Day1TaskCurator routing — for every standalone + bundle parent, decide
  // which lane it lands in based on safetyFloor / routingOverride /
  // assignmentType + preference tier + has-vendor-for-category.
  const lanes = {
    vendor: [],
    findContractor: [],
    personal: [],
    bundles: [],
  };

  for (const t of standalone) {
    const lane = routeTask(t, tier, facts);
    pushTaskToLane(lanes, lane, t, facts);
  }
  for (const b of bundleParents) {
    const lane = routeTask(b, tier, facts);
    if (lane === "vendor" || lane === "findContractor") {
      lanes.bundles.push({ ...b, _lane: lane });
    } else {
      pushTaskToLane(lanes, lane, b, facts);
    }
  }

  // Sort by season then title within each lane.
  for (const lane of Object.values(lanes)) {
    lane.sort((a, b) => {
      const sa = SEASON_ORDER[a.seasonalTiming] ?? 99;
      const sb = SEASON_ORDER[b.seasonalTiming] ?? 99;
      if (sa !== sb) return sa - sb;
      return (a.title || "").localeCompare(b.title || "");
    });
  }

  return {
    facts,
    region,
    tier,
    activeSubtypes: [...activeSubtypes].sort(),
    counts: {
      total:
        lanes.vendor.length +
        lanes.findContractor.length +
        lanes.personal.length +
        lanes.bundles.length,
      vendor: lanes.vendor.length,
      findContractor: lanes.findContractor.length,
      personal: lanes.personal.length,
      bundles: lanes.bundles.length,
    },
    lanes,
    rules: {
      regionalFiltered: templates.filter((t) => t.regionalPack && t.regionalPack !== region).length,
      essentialOnlyFiltered: templates.filter((t) => t.isEssential === false).length,
      subtypeFiltered:
        templates.length -
        eligible.length -
        templates.filter((t) => t.regionalPack && t.regionalPack !== region).length -
        templates.filter((t) => t.isEssential === false).length,
    },
  };
}

// =============================================================================
// Routing rules (Day1TaskCurator port)
// =============================================================================

function routeTask(task, tier, facts) {
  // safetyFloor short-circuits everything — always vendor.
  if (task.safetyFloor === true) {
    return findContractorOrVendor(task, facts);
  }
  // routingOverride.diyDefault → personal (.diy hard floor)
  if (task.routingOverride === "diyDefault") return "personal";
  // routingOverride.vendorOnly → vendor (or findContractor if none)
  if (task.routingOverride === "vendorOnly") return findContractorOrVendor(task, facts);
  // assignmentType resolution
  const at = task.assignmentType || "either";
  if (at === "personal") return "personal";
  if (at === "vendor") return findContractorOrVendor(task, facts);
  // .either resolves against preference tier
  if (tier === TIER_DIY) return "personal";
  if (tier === TIER_HIRE_OUT) return findContractorOrVendor(task, facts);
  // mixed: 30-min cap rule
  const minutes = task.diyEffortMinutes ?? 0;
  if (minutes > 30) return findContractorOrVendor(task, facts);
  return "personal";
}

function findContractorOrVendor(task, facts) {
  const cat = task.systemCategory;
  const has = !!facts.hasContractorsFor?.[cat];
  return has ? "vendor" : "findContractor";
}

function pushTaskToLane(lanes, lane, task, facts) {
  if (lane === "vendor") {
    const vendorName = vendorLabelFor(task, facts);
    lanes.vendor.push({ ...task, _lane: "vendor", title: vendorReframe(task, vendorName) });
  } else if (lane === "findContractor") {
    lanes.findContractor.push({
      ...task,
      _lane: "findContractor",
      title: `Find a contractor for: ${(task.title || "").replace(/^(Schedule|Annual|Inspect|Test|Replace|Service)\s+/i, "")}`,
    });
  } else if (lane === "personal") {
    lanes.personal.push({ ...task, _lane: "personal" });
  }
}

function vendorReframe(task, vendorName) {
  const original = (task.title || "").replace(/^(Schedule|Annual|Inspect|Test|Replace|Service)\s+/i, "").toLowerCase();
  if (task.isBundle) return `Schedule ${vendorName}: ${task.bundleTitle?.toLowerCase() || original}`;
  return `Schedule ${vendorName}: ${original}`;
}

function vendorLabelFor(task, facts) {
  const cat = task.systemCategory;
  return facts.hasContractorsFor?.[cat] ? `${cat} pro` : "your pro";
}

// =============================================================================
// Subtype gating
// =============================================================================

function activeSubtypeSet(facts) {
  const set = new Set();
  for (const [k, v] of Object.entries(facts.subtypes || {})) {
    if (v === true) set.add(k);
  }
  // Composite subtypes — match the activeSubtypes(category, flags) Swift logic.
  if (set.has("pool_inground") && set.has("pool_chlorine")) set.add("pool_inground_chlorine");
  if (set.has("pool_inground") && set.has("pool_salt")) set.add("pool_inground_salt");
  if (set.has("pool_above_ground") && set.has("pool_chlorine")) set.add("pool_above_ground_chlorine");
  // Pool umbrella token
  if (set.has("pool_inground") || set.has("pool_above_ground")) set.add("pool");
  // Hot tub umbrella
  if (set.has("hot_tub")) set.add("hot_tub");
  return set;
}

function subtypesSatisfied(required, active) {
  if (!required.length) return true;
  // Swift semantics: ALL required subtypes must be in the active set.
  return required.every((s) => active.has(s));
}

function factRegion(facts) {
  if (!facts?.state) return null;
  return STATE_REGION_MAP[String(facts.state).toUpperCase()] || null;
}

const SEASON_ORDER = { Spring: 1, Summer: 2, Fall: 3, Winter: 4, "Spring/Fall": 1.5 };

function prettifyBundleId(bundleId) {
  return String(bundleId)
    .split(":")
    .map((p) => p.charAt(0).toUpperCase() + p.slice(1))
    .join(" — ");
}

// =============================================================================
// Render — HTML for the Simulator surface
// =============================================================================

export function renderSimulatorUI(result) {
  const lanes = result.lanes;
  return `
    <div class="admin-sim__output">
      <div class="admin-sim__summary">
        <div class="admin-stat-tile"><strong>${result.counts.total}</strong><span>Total tasks</span></div>
        <div class="admin-stat-tile"><strong>${result.counts.bundles}</strong><span>Bundle visits</span></div>
        <div class="admin-stat-tile"><strong>${result.counts.vendor + result.counts.findContractor}</strong><span>Vendor lane</span></div>
        <div class="admin-stat-tile"><strong>${result.counts.personal}</strong><span>Personal (DIY)</span></div>
      </div>

      <div class="admin-sim__filter-summary admin-muted">
        Region: <strong>${escapeHtml(result.region || "?")}</strong> ·
        Tier: <strong>${escapeHtml(result.tier)}</strong> ·
        ${result.activeSubtypes.length} active subtypes ·
        ${result.rules.regionalFiltered} filtered by regional pack ·
        ${result.rules.essentialOnlyFiltered} non-essential excluded ·
        ${result.rules.subtypeFiltered} filtered by subtype gating
      </div>

      ${laneSection("🛠 Bundle visits (rolled up)", lanes.bundles, true)}
      ${laneSection("👥 Vendor — has contractor on file", lanes.vendor, false)}
      ${laneSection("📞 Find a contractor (vendor lane, no match)", lanes.findContractor, false)}
      ${laneSection("✋ Personal (DIY)", lanes.personal, false)}
    </div>
  `;
}

function laneSection(title, items, isBundles) {
  if (!items.length) {
    return `
      <section class="admin-sim__lane">
        <header><h4>${escapeHtml(title)}</h4><span class="admin-muted">Empty</span></header>
      </section>
    `;
  }
  return `
    <section class="admin-sim__lane">
      <header><h4>${escapeHtml(title)}</h4><span class="admin-muted">${items.length}</span></header>
      <ul class="admin-sim__tasks">
        ${items.map((t) => simTaskRow(t, isBundles)).join("")}
      </ul>
    </section>
  `;
}

function simTaskRow(task, isBundle) {
  const meta = [
    task.systemCategory,
    task.frequency,
    task.seasonalTiming,
    task.assignmentType ? `${task.assignmentType}` : null,
    task.routingOverride || null,
    task.safetyFloor ? "safety-floor" : null,
  ].filter(Boolean);
  const childList = isBundle && task.children
    ? `<details class="admin-sim__children"><summary>${task.children.length} item${task.children.length === 1 ? "" : "s"} in this visit</summary><ul>${task.children
        .map((c) => `<li><code>${escapeHtml(c.systemCategory)}</code> ${escapeHtml(c.title)}</li>`)
        .join("")}</ul></details>`
    : "";
  return `
    <li class="admin-sim__task" data-lane="${escapeHtml(task._lane)}">
      <div class="admin-sim__task-top">
        <strong>${escapeHtml(task.title)}</strong>
      </div>
      <div class="admin-sim__task-meta">${meta.map((m) => `<span>${escapeHtml(String(m))}</span>`).join("")}</div>
      ${childList}
    </li>
  `;
}

// =============================================================================
// Property fact form
// =============================================================================

export function renderFactForm(facts) {
  const subtypes = facts.subtypes || {};
  const subtypeKeys = Object.keys(subtypes);
  const contractorKeys = Object.keys(facts.hasContractorsFor || {});
  return `
    <form class="admin-sim__form" data-sim-form>
      <fieldset>
        <legend>Property</legend>
        <label>
          <span>State</span>
          <input type="text" name="state" value="${escapeHtml(facts.state || "CT")}" maxlength="2" />
        </label>
        <label>
          <span>Year built</span>
          <input type="number" name="yearBuilt" value="${facts.yearBuilt ?? 1962}" />
        </label>
        <label>
          <span>Square footage</span>
          <input type="number" name="squareFootage" value="${facts.squareFootage ?? 4200}" />
        </label>
        <label>
          <span>Preference tier (Q36)</span>
          <select name="preferenceTier">
            <option value="diy" ${facts.preferenceTier === "diy" ? "selected" : ""}>DIY ("I handle it")</option>
            <option value="mixed" ${facts.preferenceTier === "mixed" ? "selected" : ""}>Mixed</option>
            <option value="hire_out" ${facts.preferenceTier === "hire_out" ? "selected" : ""}>Hire out</option>
          </select>
        </label>
      </fieldset>

      <fieldset>
        <legend>Subtypes (gates templates via requiredSubtypes)</legend>
        <div class="admin-sim__chips">
          ${subtypeKeys.map((k) => `
            <button type="button" class="admin-chip admin-chip--toggle ${subtypes[k] ? "is-active" : ""}"
                    data-subtype="${escapeHtml(k)}">${escapeHtml(k)}</button>
          `).join("")}
        </div>
      </fieldset>

      <fieldset>
        <legend>Has contractor for…</legend>
        <p class="admin-muted">Toggling these flips .either tasks from "find contractor" to "vendor" lane (mimics Q15b).</p>
        <div class="admin-sim__chips">
          ${contractorKeys.map((k) => `
            <button type="button" class="admin-chip admin-chip--toggle ${facts.hasContractorsFor[k] ? "is-active" : ""}"
                    data-contractor="${escapeHtml(k)}">${escapeHtml(k)}</button>
          `).join("")}
        </div>
      </fieldset>
    </form>
  `;
}

export function attachFactFormHandlers(container, facts, onChange) {
  container.querySelectorAll("input, select").forEach((input) => {
    const handler = () => {
      const name = input.name;
      let v = input.value;
      if (input.type === "number") v = v === "" ? null : Number(v);
      facts[name] = v;
      onChange?.(facts);
    };
    input.addEventListener("input", handler);
    input.addEventListener("change", handler);
  });
  container.querySelectorAll("[data-subtype]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const k = btn.dataset.subtype;
      facts.subtypes[k] = !facts.subtypes[k];
      btn.classList.toggle("is-active");
      onChange?.(facts);
    });
  });
  container.querySelectorAll("[data-contractor]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const k = btn.dataset.contractor;
      facts.hasContractorsFor[k] = !facts.hasContractorsFor[k];
      btn.classList.toggle("is-active");
      onChange?.(facts);
    });
  });
}

// =============================================================================
// Helpers
// =============================================================================

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
