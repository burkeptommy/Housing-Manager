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
// Phase 5k — Quiz answer → property facts mapper
// =============================================================================
// Reproduces the most impactful side-effects of HouseQuizAnswerMapper.swift
// in JS so Tom can simulate quiz permutations and watch the seeded task
// list change live. Covers the system-creating answers + Q15b
// (contractors-on-file) + Q36 (preference tier). Doesn't try to model
// every answer (provider names, vehicle adds, family invites) since
// those don't affect the templates the reconciler picks.

const QUIZ_ANSWER_MAP = {
  // Q1 — roof material → roof_<material> subtype on Roofing system
  q1_roof_material: {
    asphalt:       { subtypes: { roof_asphalt: true } },
    metal:         { subtypes: { roof_metal: true } },
    tile:          { subtypes: { roof_tile: true } },
    slate:         { subtypes: { roof_slate: true } },
    wood_shake:    { subtypes: { roof_wood: true } },
    flat_membrane: { subtypes: { roof_flat: true } },
    not_sure:      { subtypes: { roof_asphalt: true } },
  },

  // Q2 — siding material
  q2_siding: {
    vinyl:        { subtypes: { siding_vinyl: true } },
    wood:         { subtypes: { siding_wood: true } },
    brick:        { subtypes: { siding_brick: true } },
    stucco:       { subtypes: { siding_stucco: true } },
    fiber_cement: { subtypes: { siding_fiber_cement: true } },
    stone:        { subtypes: { siding_stone: true } },
    mixed:        { subtypes: { siding_mixed: true } },
  },

  // Q3 — heating fuel
  q3_heating_fuel: {
    natural_gas: { subtypes: { natural_gas: true } },
    oil:         { subtypes: { oil: true } },
    electric:    { subtypes: { electric: true } },
    propane:     { subtypes: { propane: true } },
    geothermal:  { subtypes: { geothermal: true } },
    not_sure:    {},
  },

  // Q3b — HVAC type
  q3b_hvac_type: {
    central_ducted:           { subtypes: { central_ducted: true, ducted: true } },
    mini_split:               { subtypes: { mini_split: true } },
    boiler_with_central_ac:   { subtypes: { boiler: true, central_ducted: true } },
    boiler_radiant:           { subtypes: { boiler: true, radiant: true } },
    boiler_with_window_ac:    { subtypes: { boiler: true } },
    heat_pump:                { subtypes: { heat_pump: true } },
    geothermal:               { subtypes: { geothermal: true, heat_pump: true } },
    not_sure:                 { subtypes: { central_ducted: true } },
  },

  // Q6 — water source
  q6_water_source: {
    municipal: { subtypes: { municipal_water: true } },
    well:      { subtypes: { has_well: true } },
    not_sure:  { subtypes: { municipal_water: true } },
  },

  // Q7 — sewer / septic
  q7_sewer_septic: {
    municipal: { subtypes: { municipal_sewer: true } },
    septic:    { subtypes: { has_septic: true } },
    not_sure:  { subtypes: { municipal_sewer: true } },
  },

  // Q8 — water heater type
  q8_water_heater: {
    tank:           { subtypes: { tank: true } },
    tankless:       { subtypes: { tankless: true } },
    heat_pump:      { subtypes: { water_heater_heat_pump: true } },
    indirect_off_boiler: { subtypes: { boiler_indirect: true } },
    not_sure:       { subtypes: { tank: true } },
  },

  // Q9 — basement / crawl space
  q9_basement: {
    full_basement:       { subtypes: { has_basement: true, has_sump_pump: true } },
    partial_basement:    { subtypes: { has_basement: true } },
    crawl_space:         { subtypes: { has_crawl_space: true } },
    slab:                {},
    not_sure:            {},
  },

  // Q10 — appliances (multi-select)
  q10_appliances: {
    _multi: true,
    dishwasher:    { subtypes: { has_dishwasher: true } },
    refrigerator:  { subtypes: { has_refrigerator: true } },
    range_oven:    { subtypes: { has_range: true } },
    microwave:     { subtypes: { has_microwave: true } },
    washer_dryer:  { subtypes: { has_laundry: true } },
    garbage_disposal: { subtypes: { has_disposal: true } },
    wine_cooler:   { subtypes: { has_wine_cooler: true } },
    ice_maker:     { subtypes: { has_ice_maker: true } },
  },

  // Q11 — lawn maintenance
  q11_lawn: {
    diy:       { subtypes: { has_lawn: true } },
    pro:       { subtypes: { has_lawn: true } },
    no_lawn:   {},
    garden:    { subtypes: { has_garden: true } },
    hardscape: { subtypes: { hardscape: true } },
  },

  // Q11b — lawn type (only when lawn exists)
  q11b_lawn_type: {
    natural:        { subtypes: { natural_lawn: true } },
    synthetic_turf: { subtypes: { synthetic_turf: true } },
    mixed:          { subtypes: { natural_lawn: true, synthetic_turf: true } },
    not_sure:       { subtypes: { natural_lawn: true } },
  },

  // Q12 — pool / hot tub
  q12_pool: {
    in_ground:    { subtypes: { has_pool: true, pool_inground: true } },
    above_ground: { subtypes: { has_pool: true, pool_above_ground: true } },
    hot_tub:      { subtypes: { hot_tub: true } },
    both:         { subtypes: { has_pool: true, pool_inground: true, hot_tub: true } },
    none:         {},
  },

  // Q12b — pool chemistry
  q12b_pool_chemistry: {
    chlorine: { subtypes: { pool_chlorine: true } },
    salt:     { subtypes: { pool_salt: true } },
    not_sure: { subtypes: { pool_chlorine: true } },
  },

  // Q13 — pest control
  q13_pest: {
    quarterly_pro: { subtypes: { has_pest_control: true } },
    sometimes:     {},
    none:          {},
  },

  // Q14 — irrigation
  q14_irrigation: {
    full: { subtypes: { has_irrigation: true } },
    drip: { subtypes: { has_irrigation: true, drip_irrigation: true } },
    no:   {},
  },

  // Q15 — security
  q15_security: {
    monitored:   { subtypes: { has_security_system: true, monitored_alarm: true } },
    unmonitored: { subtypes: { has_security_system: true } },
    none:        {},
  },

  // Q21 — solar
  q21_solar: {
    yes: { subtypes: { has_solar: true } },
    no:  {},
  },

  // Q22 — generator
  q22_generator: {
    whole_home: { subtypes: { has_generator: true, whole_home_generator: true } },
    portable:   { subtypes: { has_generator: true, portable_generator: true } },
    none:       {},
  },

  // Q25 — garage
  q25_garage_ev: {
    attached:      { subtypes: { has_garage: true } },
    semi_attached: { subtypes: { has_garage: true } },
    detached:      { subtypes: { has_garage: true } },
    carport:       {},
    none:          {},
  },

  // Q25b — EV charger
  q25b_ev_charger: {
    yes: { subtypes: { has_ev_charger: true } },
    no:  {},
  },

  // Q28b — pets
  q28b_pets: {
    has_pets: { subtypes: { has_pets: true } },
    no_pets:  {},
  },

  // Q36 — DIY vs Vendor preference tier
  q36_diy_vs_vendor: {
    diy:      { preferenceTier: "diy" },
    mixed:    { preferenceTier: "mixed" },
    hire_out: { preferenceTier: "hire_out" },
  },
};

// Q15b chip → contractor category mapping
const Q15B_CHIP_TO_CATEGORY = {
  handyman:        "Handyman",
  hvac_service:    "HVAC",
  plumber:         "Plumbing",
  electrician:     "Electrical",
  roofer:          "Roofing",
  septic_pumper:   "Septic",
  well_water:      "Well",
  chimney_sweep:   "Chimney",
  tree_service:    "Tree Service",
  landscaper:      "Landscaping",
  cleaner:         "Cleaning Service",
  pool_service:    "Pool/Spa",
  pest_control:    "Pest Control",
  snow_removal:    "Snow Removal",
};

export function quizAnswerToFacts(quizAnswers, baseFacts = DEFAULT_FACTS) {
  const facts = JSON.parse(JSON.stringify(baseFacts));
  facts.subtypes = facts.subtypes || {};
  facts.hasContractorsFor = facts.hasContractorsFor || {};

  for (const [questionId, answer] of Object.entries(quizAnswers || {})) {
    if (questionId === "q15b_household_contractors") {
      const selectedIds = Array.isArray(answer?.selectedIds) ? answer.selectedIds : [];
      for (const chipId of selectedIds) {
        const cat = Q15B_CHIP_TO_CATEGORY[chipId];
        if (cat) facts.hasContractorsFor[cat] = true;
      }
      continue;
    }
    const map = QUIZ_ANSWER_MAP[questionId];
    if (!map) continue;

    if (map._multi && Array.isArray(answer?.selectedIds)) {
      for (const id of answer.selectedIds) {
        const effect = map[id];
        applyAnswerEffect(facts, effect);
      }
      continue;
    }

    const answerId = typeof answer === "string" ? answer : answer?.answerId;
    if (!answerId) continue;
    const effect = map[answerId];
    applyAnswerEffect(facts, effect);
  }

  return facts;
}

function applyAnswerEffect(facts, effect) {
  if (!effect) return;
  if (effect.subtypes) {
    for (const [k, v] of Object.entries(effect.subtypes)) {
      facts.subtypes[k] = v;
    }
  }
  if (effect.preferenceTier) {
    facts.preferenceTier = effect.preferenceTier;
  }
}

// =============================================================================
// Phase 5k — preset profiles
// =============================================================================

export const QUIZ_PRESETS = [
  {
    key: "westchester_family",
    label: "Westchester family · 4-bed colonial",
    description: "Northeast suburban home, gas heat, in-ground pool, kid + dog.",
    answers: {
      q1_roof_material: "asphalt",
      q2_siding: "vinyl",
      q3_heating_fuel: "natural_gas",
      q3b_hvac_type: "central_ducted",
      q6_water_source: "municipal",
      q7_sewer_septic: "municipal",
      q8_water_heater: "tank",
      q9_basement: "full_basement",
      q11_lawn: "pro",
      q11b_lawn_type: "natural",
      q12_pool: "in_ground",
      q12b_pool_chemistry: "chlorine",
      q13_pest: "quarterly_pro",
      q14_irrigation: "full",
      q15_security: "monitored",
      q15b_household_contractors: { selectedIds: ["hvac_service", "plumber", "landscaper", "pool_service"] },
      q21_solar: "no",
      q22_generator: "whole_home",
      q25_garage_ev: "attached",
      q25b_ev_charger: "yes",
      q28b_pets: "has_pets",
      q36_diy_vs_vendor: "mixed",
    },
    factsOverride: { state: "CT", yearBuilt: 1962, squareFootage: 4200 },
  },
  {
    key: "greenwich_estate",
    label: "Greenwich estate · 8-bed, full staff",
    description: "Massive HNW home, well + septic, pool + hot tub, vendor-on-everything.",
    answers: {
      q1_roof_material: "slate",
      q2_siding: "brick",
      q3_heating_fuel: "oil",
      q3b_hvac_type: "boiler_with_central_ac",
      q6_water_source: "well",
      q7_sewer_septic: "septic",
      q8_water_heater: "indirect_off_boiler",
      q9_basement: "full_basement",
      q11_lawn: "pro",
      q11b_lawn_type: "natural",
      q12_pool: "both",
      q12b_pool_chemistry: "salt",
      q13_pest: "quarterly_pro",
      q14_irrigation: "full",
      q15_security: "monitored",
      q15b_household_contractors: {
        selectedIds: [
          "handyman", "hvac_service", "plumber", "electrician", "roofer",
          "septic_pumper", "well_water", "chimney_sweep", "tree_service",
          "landscaper", "cleaner", "pool_service", "pest_control",
        ],
      },
      q21_solar: "no",
      q22_generator: "whole_home",
      q25_garage_ev: "detached",
      q25b_ev_charger: "yes",
      q28b_pets: "has_pets",
      q36_diy_vs_vendor: "hire_out",
    },
    factsOverride: { state: "CT", yearBuilt: 1924, squareFootage: 9800 },
  },
  {
    key: "boston_condo",
    label: "Boston condo · no lawn, no car",
    description: "Urban condo, electric heat, no pool / pool / lawn / garage. Stripped-down.",
    answers: {
      q1_roof_material: "flat_membrane",
      q2_siding: "brick",
      q3_heating_fuel: "electric",
      q3b_hvac_type: "mini_split",
      q6_water_source: "municipal",
      q7_sewer_septic: "municipal",
      q8_water_heater: "tankless",
      q9_basement: "slab",
      q11_lawn: "no_lawn",
      q12_pool: "none",
      q13_pest: "none",
      q14_irrigation: "no",
      q15_security: "unmonitored",
      q15b_household_contractors: { selectedIds: ["handyman", "cleaner"] },
      q21_solar: "no",
      q22_generator: "none",
      q25_garage_ev: "none",
      q28b_pets: "no_pets",
      q36_diy_vs_vendor: "diy",
    },
    factsOverride: { state: "MA", yearBuilt: 1995, squareFootage: 1100 },
  },
  {
    key: "tahoe_second_home",
    label: "Tahoe second home · seasonal",
    description: "Western mountain home, propane, hot tub, snow removal critical.",
    answers: {
      q1_roof_material: "metal",
      q2_siding: "wood",
      q3_heating_fuel: "propane",
      q3b_hvac_type: "boiler_radiant",
      q6_water_source: "well",
      q7_sewer_septic: "septic",
      q8_water_heater: "tank",
      q9_basement: "crawl_space",
      q11_lawn: "no_lawn",
      q12_pool: "hot_tub",
      q13_pest: "sometimes",
      q14_irrigation: "no",
      q15_security: "monitored",
      q15b_household_contractors: { selectedIds: ["handyman", "snow_removal", "well_water"] },
      q21_solar: "yes",
      q22_generator: "portable",
      q25_garage_ev: "attached",
      q25b_ev_charger: "no",
      q28b_pets: "no_pets",
      q36_diy_vs_vendor: "hire_out",
    },
    factsOverride: { state: "CA", yearBuilt: 1988, squareFootage: 3200 },
  },
];

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
  // Phase 5l — 4-tier breakdown using assignment-tier semantics, not the
  // old vendor/findContractor/personal split. Maps each task to one of:
  //   Vendor only · Vendor or Handyman · Handyman only · I'll do it myself
  const tier = bucketByAssignmentTier(lanes);

  return `
    <div class="admin-sim__output">
      <div class="admin-sim__summary">
        <div class="admin-stat-tile"><strong>${result.counts.total}</strong><span>Total tasks</span></div>
        <div class="admin-stat-tile"><strong>${result.counts.bundles}</strong><span>Bundle visits</span></div>
        <div class="admin-stat-tile"><strong>${tier.vendor_only.length}</strong><span>Vendor only</span></div>
        <div class="admin-stat-tile"><strong>${tier.vendor_or_handyman.length}</strong><span>Vendor or Handyman</span></div>
      </div>

      <div class="admin-sim__filter-summary admin-muted">
        Region: <strong>${escapeHtml(result.region || "?")}</strong> ·
        Tier: <strong>${escapeHtml(result.tier)}</strong> ·
        ${result.activeSubtypes.length} active subtypes ·
        ${result.rules.regionalFiltered} filtered by regional pack ·
        ${result.rules.essentialOnlyFiltered} non-essential excluded ·
        ${result.rules.subtypeFiltered} filtered by subtype gating
      </div>

      ${tierSection("🚫 Vendor only", "Always a pro — gas, panel, roof, septic.", tier.vendor_only)}
      ${tierSection("👥 Vendor or Handyman", "Defaults to a vendor visit but the homeowner can flip to handyman.", tier.vendor_or_handyman)}
      ${tierSection("🔨 Handyman only", "Small DIY-friendly items. Usually bundled into a handyman visit.", tier.handyman_only)}
      ${tierSection("✋ I'll do it myself", "Templates never seed here — runtime-only. (Should always be empty.)", tier.homeowner_only)}
    </div>
  `;
}

// Map a simulator task to its 4-tier category.
function tierForTask(task) {
  if (task.safetyFloor === true) return "vendor_only";
  if (task.routingOverride === "vendorOnly") return "vendor_only";
  if (task.assignmentType === "vendor" && !task.routingOverride) return "vendor_only";
  if (task.routingOverride === "diyDefault") return "handyman_only";
  if (task.assignmentType === "personal") return "handyman_only";
  // Default: vendor_or_handyman (3-option picker)
  return "vendor_or_handyman";
}

function bucketByAssignmentTier(lanes) {
  const out = { vendor_only: [], vendor_or_handyman: [], handyman_only: [], homeowner_only: [] };
  // Bundles + standalone tasks all flow through the same bucketer.
  const all = [...(lanes.bundles || []), ...(lanes.vendor || []), ...(lanes.findContractor || []), ...(lanes.personal || [])];
  for (const task of all) {
    const tier = tierForTask(task);
    out[tier].push(task);
  }
  return out;
}

function tierSection(title, blurb, items) {
  if (!items.length) {
    return `
      <section class="admin-sim__lane">
        <header><h4>${escapeHtml(title)}</h4><span class="admin-muted">Empty</span></header>
        <p class="admin-sim__lane-blurb admin-muted">${escapeHtml(blurb)}</p>
      </section>
    `;
  }
  return `
    <section class="admin-sim__lane">
      <header><h4>${escapeHtml(title)}</h4><span class="admin-muted">${items.length}</span></header>
      <p class="admin-sim__lane-blurb admin-muted">${escapeHtml(blurb)}</p>
      <ul class="admin-sim__tasks">
        ${items.map((t) => simTaskRow(t, t.isBundle)).join("")}
      </ul>
    </section>
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

// =============================================================================
// Phase 5k — Quiz Mode UI
// =============================================================================
// Renders chapter-grouped answer chips for every quiz question that drives
// system / task creation. Each pick updates the running quiz state, the
// derived facts re-compute, and the simulator re-runs. Preset profiles
// load a complete set of answers in one click.

const KEY_QUESTIONS = [
  { id: "q1_roof_material", label: "Roof material" },
  { id: "q2_siding", label: "Siding" },
  { id: "q3_heating_fuel", label: "Heating fuel" },
  { id: "q3b_hvac_type", label: "HVAC type" },
  { id: "q6_water_source", label: "Water source" },
  { id: "q7_sewer_septic", label: "Sewer / septic" },
  { id: "q8_water_heater", label: "Water heater" },
  { id: "q9_basement", label: "Basement / crawl" },
  { id: "q11_lawn", label: "Lawn handling" },
  { id: "q11b_lawn_type", label: "Lawn type", showIf: (a) => ["diy", "pro"].includes(a.q11_lawn) },
  { id: "q12_pool", label: "Pool / hot tub" },
  { id: "q12b_pool_chemistry", label: "Pool chemistry", showIf: (a) => ["in_ground", "above_ground", "both"].includes(a.q12_pool) },
  { id: "q13_pest", label: "Pest control" },
  { id: "q14_irrigation", label: "Irrigation" },
  { id: "q15_security", label: "Security system" },
  { id: "q21_solar", label: "Solar" },
  { id: "q22_generator", label: "Generator" },
  { id: "q25_garage_ev", label: "Garage" },
  { id: "q25b_ev_charger", label: "EV charger", showIf: (a) => a.q25_garage_ev && a.q25_garage_ev !== "none" },
  { id: "q28b_pets", label: "Pets" },
  { id: "q36_diy_vs_vendor", label: "DIY vs Vendor preference" },
];

export function renderQuizModeUI(quizAnswers, quizQuestionsJSON) {
  const questions = quizQuestionsJSON?.entries || [];
  const byId = Object.fromEntries(questions.map((q) => [q.id, q]));
  const activeAnswers = flattenedAnswers(quizAnswers);

  const presetButtonsHtml = `
    <div class="admin-quizsim__presets">
      <strong>Load a preset</strong>
      <div class="admin-quizsim__preset-row">
        ${QUIZ_PRESETS.map(
          (p) => `
            <button type="button" class="admin-quizsim__preset" data-preset="${escapeHtml(p.key)}">
              <strong>${escapeHtml(p.label)}</strong>
              <span>${escapeHtml(p.description)}</span>
            </button>
          `
        ).join("")}
        <button type="button" class="admin-quizsim__preset admin-quizsim__preset--reset" data-preset="__reset__">
          <strong>Reset all answers</strong>
          <span>Clear the quiz state and start from scratch.</span>
        </button>
      </div>
    </div>
  `;

  const keyAnswersHtml = `
    <div class="admin-quizsim__section">
      <strong>Key answers</strong>
      ${KEY_QUESTIONS.map((cfg) => {
        if (cfg.showIf && !cfg.showIf(activeAnswers)) return "";
        const q = byId[cfg.id];
        if (!q) return "";
        const current = activeAnswers[q.id];
        const opts = q.answerOptions || [];
        return `
          <div class="admin-quizsim__question" data-q-id="${escapeHtml(q.id)}">
            <header>
              <span class="admin-quizsim__q-label">${escapeHtml(cfg.label)}</span>
              <code>${escapeHtml(q.id)}</code>
            </header>
            <div class="admin-quizsim__chips">
              ${opts
                .map(
                  (o) => `
                    <button type="button" class="admin-quizsim__chip ${current === o.id ? "is-active" : ""}"
                            data-q-id="${escapeHtml(q.id)}" data-answer-id="${escapeHtml(o.id)}">
                      ${escapeHtml(o.label || o.id)}
                    </button>
                  `
                )
                .join("")}
              ${current ? `<button type="button" class="admin-quizsim__clear" data-q-id="${escapeHtml(q.id)}" data-answer-id="">Clear</button>` : ""}
            </div>
          </div>
        `;
      }).join("")}
    </div>
  `;

  const q15bHtml = renderContractorChips(activeAnswers);

  return `
    <div class="admin-quizsim">
      ${presetButtonsHtml}
      ${q15bHtml}
      ${keyAnswersHtml}
    </div>
  `;
}

function renderContractorChips(activeAnswers) {
  const selected = new Set(activeAnswers.q15b_household_contractors_selectedIds || []);
  const chips = Object.entries(Q15B_CHIP_TO_CATEGORY).map(([chipId, cat]) => `
    <button type="button" class="admin-quizsim__chip ${selected.has(chipId) ? "is-active" : ""}"
            data-q15b-toggle="${escapeHtml(chipId)}">
      ${escapeHtml(cat)}
    </button>
  `).join("");
  return `
    <div class="admin-quizsim__section">
      <strong>Contractors on file (Q15b)</strong>
      <p class="admin-muted admin-quizsim__hint">Each toggle pretends the homeowner has hired a vendor for that category. Tasks in matching categories flip from "find a pro" to "vendor on file."</p>
      <div class="admin-quizsim__chips">${chips}</div>
    </div>
  `;
}

function flattenedAnswers(quizAnswers) {
  // Quiz state stores answers as { questionId: { answerId, selectedIds, ... } }
  // Flatten to a simple map of questionId → answerId for the chip
  // active-state checks. Q15b's selectedIds gets a special key.
  const flat = {};
  for (const [qId, a] of Object.entries(quizAnswers || {})) {
    if (qId === "q15b_household_contractors") {
      flat.q15b_household_contractors_selectedIds = a?.selectedIds || [];
      continue;
    }
    if (typeof a === "string") flat[qId] = a;
    else if (a?.answerId) flat[qId] = a.answerId;
  }
  return flat;
}

export function attachQuizModeHandlers(container, quizAnswers, onChange) {
  // Single-answer chips
  container.querySelectorAll("[data-answer-id]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const qId = btn.dataset.qId;
      const aId = btn.dataset.answerId;
      if (!aId) {
        delete quizAnswers[qId];
      } else {
        quizAnswers[qId] = aId;
      }
      onChange?.();
    });
  });

  // Q15b toggles
  container.querySelectorAll("[data-q15b-toggle]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const chipId = btn.dataset.q15bToggle;
      const cur = quizAnswers.q15b_household_contractors || { selectedIds: [] };
      const sel = new Set(cur.selectedIds || []);
      if (sel.has(chipId)) sel.delete(chipId);
      else sel.add(chipId);
      quizAnswers.q15b_household_contractors = { selectedIds: [...sel] };
      onChange?.();
    });
  });

  // Preset buttons
  container.querySelectorAll("[data-preset]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const key = btn.dataset.preset;
      if (key === "__reset__") {
        for (const k of Object.keys(quizAnswers)) delete quizAnswers[k];
      } else {
        const preset = QUIZ_PRESETS.find((p) => p.key === key);
        if (preset) {
          for (const k of Object.keys(quizAnswers)) delete quizAnswers[k];
          Object.assign(quizAnswers, JSON.parse(JSON.stringify(preset.answers)));
        }
      }
      onChange?.(key);
    });
  });
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
