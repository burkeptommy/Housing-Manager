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

  // Phase 67D (A3): Q3 + Q3b merged into a single fuel+system combo
  // picker. Each combo unions the fuel subtype + the HVAC subtype that
  // the old two-step would have stamped, so downstream subtype-driven
  // template gating produces identical output to pre-67D presets.
  q3_heating_system: {
    gas_furnace_central_ac:        { subtypes: { natural_gas: true, central_ducted: true, ducted: true } },
    gas_boiler_radiators:          { subtypes: { natural_gas: true, boiler: true, radiant: true } },
    gas_boiler_central_ac:         { subtypes: { natural_gas: true, boiler: true, central_ducted: true } },
    oil_boiler_radiators:          { subtypes: { oil: true, boiler: true, radiant: true } },
    oil_boiler_central_ac:         { subtypes: { oil: true, boiler: true, central_ducted: true } },
    heat_pump_ducted:              { subtypes: { electric: true, heat_pump: true } },
    heat_pump_mini_split:          { subtypes: { electric: true, mini_split: true } },
    geothermal:                    { subtypes: { geothermal: true, heat_pump: true } },
    propane_boiler:                { subtypes: { propane: true, boiler: true, radiant: true } },
    propane_furnace_central_ac:    { subtypes: { propane: true, central_ducted: true } },
    electric_baseboard:            { subtypes: { electric: true } },
    not_sure:                      { subtypes: { central_ducted: true } },
  },

  // Phase 67D legacy (kept for backward-compat with persisted simulator
  // runs from before the merge; new presets use q3_heating_system).
  q3_heating_fuel: {
    natural_gas: { subtypes: { natural_gas: true } },
    oil:         { subtypes: { oil: true } },
    electric:    { subtypes: { electric: true } },
    propane:     { subtypes: { propane: true } },
    geothermal:  { subtypes: { geothermal: true } },
    not_sure:    {},
  },
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
      // Phase 67D (A3): Q3 + Q3b merged. Legacy keys retained as harmless
      // duplicate signal — the simulator subtype lookup unions them.
      q3_heating_system: "gas_furnace_central_ac",
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
      // Phase 67 (C2/C3) — review-only no-op breadcrumbs.
      q37_routines: "reviewed",
      q38_handyman_punchlist: "reviewed",
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
      q3_heating_system: "oil_boiler_central_ac",
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
      // Phase 67 (C2/C3) — review-only no-op breadcrumbs.
      q37_routines: "reviewed",
      q38_handyman_punchlist: "reviewed",
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
      q3_heating_system: "heat_pump_mini_split",
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
      // Phase 67 (C2/C3) — review-only no-op breadcrumbs.
      q37_routines: "reviewed",
      q38_handyman_punchlist: "reviewed",
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
      q3_heating_system: "propane_boiler",
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
      // Phase 67 (C2/C3) — review-only no-op breadcrumbs.
      q37_routines: "reviewed",
      q38_handyman_punchlist: "reviewed",
    },
    factsOverride: { state: "CA", yearBuilt: 1988, squareFootage: 3200 },
  },
];

// =============================================================================
// Public API
// =============================================================================

// Phase 5o — Handyman bundles aren't tasks. Their children become punch
// list items, and the visit itself is a seasonal home-screen reminder
// (driven by a singleton handymanRecurring routine). The simulator
// filters them out of the task lanes and shows the punch list separately.
function isHandymanBundleId(bundleId) {
  return bundleId === "Handyman:spring" || bundleId === "Handyman:fall";
}

// Phase 5p — Routines are FACT-DRIVEN, not template-driven. The reconciler
// (and this simulator) creates a routine for every applicable category
// based on the homeowner's quiz answers, regardless of whether matching
// templates exist. Vendor status (active vs pending_vendor) is determined
// by Q15b / Q11 / Q12 / Q13 / Q15 / Q18 / Q19 captures. Cadence + days
// default to seeder values; homeowner confirms post-quiz at Q37.
const ROUTINE_AUTO_CREATE_RULES = [
  {
    category: "Landscaping",
    kind: "landscaping",
    label: "Landscaping",
    icon: "🌿",
    defaultCadence: "Weekly",
    defaultDay: "Tuesday",
    activeMonths: "Apr–Nov",
    // q11_lawn captures presence (has_lawn / has_garden); q11b captures
    // type. Don't gate on natural_lawn / synthetic_turf because those
    // default to true in DEFAULT_FACTS and would leak through no_lawn.
    activeIf: (s) => s.has_lawn === true || s.has_garden === true,
  },
  {
    category: "Cleaning Service",
    kind: "cleaning",
    label: "House cleaning",
    icon: "🧹",
    defaultCadence: "Biweekly",
    defaultDay: "Wednesday",
    activeMonths: "Year-round",
    activeIf: () => true,  // Every home benefits — surfaced as suggestion
  },
  {
    category: "Pool/Spa",
    kind: "poolService",
    label: "Pool service",
    icon: "💦",
    defaultCadence: "Weekly",
    defaultDay: "Tuesday",
    activeMonths: "May–Sep",
    activeIf: (s) => s.has_pool === true || s.pool_inground === true || s.pool_above_ground === true,
  },
  {
    category: "Hot Tub",
    kind: "hotTubService",
    label: "Hot tub service",
    icon: "♨️",
    defaultCadence: "Monthly",
    defaultDay: null,
    activeMonths: "Year-round",
    activeIf: (s) => s.hot_tub === true,
  },
  {
    category: "Pest Control",
    kind: "pestControl",
    label: "Pest control",
    icon: "🐜",
    defaultCadence: "Quarterly",
    defaultDay: null,
    activeMonths: "Year-round",
    activeIf: () => true,  // Common in all regions; surfaced as suggestion
  },
  {
    category: "Mosquito & Tick",
    kind: "mosquitoTick",
    label: "Mosquito & tick spraying",
    icon: "🐛",
    defaultCadence: "Triweekly",
    defaultDay: null,
    activeMonths: "Apr–Oct",
    activeIf: (s, region) => region === "northeast" || region === "southeast",
  },
  {
    category: "Snow Removal",
    kind: "snowRemoval",
    label: "Snow removal",
    icon: "❄️",
    defaultCadence: "As scheduled",
    defaultDay: null,
    activeMonths: "Dec–Apr",
    activeIf: (s, region) => region === "northeast" || region === "midwest",
  },
  {
    category: "Pet Waste",
    kind: "petWaste",
    label: "Pet waste pickup",
    icon: "🐾",
    defaultCadence: "Weekly",
    defaultDay: "Friday",
    activeMonths: "Year-round",
    activeIf: (s) => s.has_pets === true,
  },
  {
    category: "Window Cleaning",
    kind: "windowCleaning",
    label: "Window cleaning",
    icon: "🪟",
    defaultCadence: "Quarterly",
    defaultDay: null,
    activeMonths: "Year-round",
    activeIf: () => true,
  },
  {
    category: "Gutter Cleaning",
    kind: "gutterCleaning",
    label: "Gutter cleaning",
    icon: "🍂",
    defaultCadence: "Quarterly",
    defaultDay: null,
    activeMonths: "Year-round",
    activeIf: (s, region) => region === "northeast" || region === "midwest" || region === "southeast",
  },
  {
    category: "Trash & Recycling",
    kind: "trash",
    label: "Trash & recycling",
    icon: "♻️",
    defaultCadence: "Weekly",
    defaultDay: "Wednesday",
    activeMonths: "Year-round",
    activeIf: () => true,  // Every home
  },
];

function buildAutoRoutines(facts, region) {
  const subtypes = facts.subtypes || {};
  const out = [];
  for (const rule of ROUTINE_AUTO_CREATE_RULES) {
    if (!rule.activeIf(subtypes, region)) continue;
    const hasVendor = !!facts.hasContractorsFor?.[rule.category];
    out.push({
      category: rule.category,
      kind: rule.kind,
      label: rule.label,
      icon: rule.icon,
      defaultCadence: rule.defaultCadence,
      defaultDay: rule.defaultDay,
      activeMonths: rule.activeMonths,
      hasVendor,
      setupState: hasVendor ? "active" : "pending_vendor",
      templateRollup: [],
      source: hasVendor ? "vendor_captured" : "auto_suggested",
    });
  }
  return out;
}

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

  // Phase 5p — Build fact-driven routines first so we know which templates
  // get folded into which routine vs. left as tasks.
  const autoRoutines = buildAutoRoutines(facts, region);
  const routineByCategory = new Map(autoRoutines.map((r) => [r.category, r]));

  // Phase 5o — separate handyman bundle children into the punch list.
  // Phase 5p — also pull routine-candidate templates out of task lanes
  // and fold them into the matching auto-created routine's templateRollup.
  const punchList = [];
  const taskEligible = [];
  for (const t of eligible) {
    if (isHandymanBundleId(t.bundleId)) {
      punchList.push(t);
      continue;
    }
    if (simIsRoutineCandidate(t) && routineByCategory.has(t.systemCategory)) {
      routineByCategory.get(t.systemCategory).templateRollup.push(t);
      continue;
    }
    taskEligible.push(t);
  }

  // Group by bundle so children roll up.
  const bundleMap = new Map();
  const standalone = [];
  for (const t of taskEligible) {
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

  // Phase 5o — punch list groups by season (spring-only, fall-only, both)
  const punchListGrouped = groupPunchListBySeason(punchList);

  return {
    // facts is exposed so the UI's tier breakdown can check
    // hasContractorsFor when collapsing routines.
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
      punchList: punchList.length,
      routines: autoRoutines.length,
      routinesActive: autoRoutines.filter((r) => r.hasVendor).length,
      routinesPending: autoRoutines.filter((r) => !r.hasVendor).length,
    },
    lanes,
    // Phase 5p — fact-driven routines (replaces template-driven detection).
    // Every applicable category gets a routine card; vendor presence
    // flips active vs pending_vendor. Cadence + days are seeder defaults
    // the homeowner confirms post-quiz.
    routines: autoRoutines,
    punchList: {
      total: punchList.length,
      hasHandymanOnFile: !!facts?.hasContractorsFor?.["Handyman"],
      grouped: punchListGrouped,
    },
    // Phase 5q — explicit funnel numbers so the simulator UI can show
    // "221 templates → 91 essential → 75 after region/subtype → 50 unique
    // tasks → 31 task rows + 21 punch list + 10 routines" without
    // re-deriving anything in the renderer.
    funnel: {
      totalTemplates: templates.length,
      essentialTemplates: templates.filter((t) => t.isEssential !== false).length,
      eligibleAfterGating: eligible.length,                  // essential ∧ region match ∧ subtypes met
      bundleChildrenRolledUp: eligible.filter((t) => t.bundleId && !isHandymanBundleId(t.bundleId)).length,
      handymanBundleChildrenToPunch: punchList.length,
      uniqueTasksAfterBundling:
        lanes.vendor.length + lanes.findContractor.length + lanes.personal.length + lanes.bundles.length,
      bundleParentVisits: lanes.bundles.length,
      routinesExtracted: autoRoutines.length,
    },
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

function groupPunchListBySeason(items) {
  const spring = items.filter((t) => t.bundleId === "Handyman:spring");
  const fall = items.filter((t) => t.bundleId === "Handyman:fall");
  spring.sort((a, b) => (a.title || "").localeCompare(b.title || ""));
  fall.sort((a, b) => (a.title || "").localeCompare(b.title || ""));
  return { spring, fall };
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
  // Phase 5p — routines are fact-driven and pre-extracted; no more
  // template-walk collapse. result.routines IS the routine list.
  const tier = bucketByAssignmentTier(lanes, result.facts);

  return `
    <div class="admin-sim__output">
      <div class="admin-sim__summary">
        <div class="admin-stat-tile"><strong>${result.counts.total}</strong><span>Tasks</span></div>
        <div class="admin-stat-tile"><strong>${result.counts.routines || 0}</strong><span>Routines</span></div>
        <div class="admin-stat-tile"><strong>${result.counts.punchList || 0}</strong><span>Punch list</span></div>
        <div class="admin-stat-tile"><strong>${tier.vendor_only.length}</strong><span>Vendor only</span></div>
      </div>

      <div class="admin-sim__filter-summary admin-muted">
        Region: <strong>${escapeHtml(result.region || "?")}</strong> ·
        Tier: <strong>${escapeHtml(result.tier)}</strong> ·
        ${result.activeSubtypes.length} active subtypes
      </div>

      ${renderFunnelBreakdown(result.funnel)}

      ${renderRoutineSection(result.routines || [], result.counts)}
      ${renderPunchListSection(result.punchList)}
      ${renderVendorCoverageGapsSection(tier.vendor_coverage_gaps)}
      ${tierSection("🚫 Vendor only", "Always a pro — gas, panel, roof, septic. One-off work, not recurring.", tier.vendor_only)}
      ${tierSection("👥 Vendor or Handyman", "Defaults to a vendor visit but the homeowner can flip to handyman.", tier.vendor_or_handyman)}
      ${tierSection("🔨 Handyman only (unbundled)", "DIY-friendly templates that aren't in the spring/fall handyman bundle. These DO seed as tasks today; if you want them on the punch list instead, flag them with bundleId Handyman:spring or Handyman:fall.", tier.handyman_only)}
      ${tierSection("✋ I'll do it myself", "Templates never seed here — runtime-only. (Should always be empty.)", tier.homeowner_only)}
    </div>
  `;
}

// Phase 67 (C4) — Vendor coverage gaps. Vendor-tier tasks WITHOUT a
// contractor on file. Replaces the "Find a contractor for X" rendering
// in the vendor_only lane with a single consolidated card per
// systemCategory — mirroring what `VendorCoverageSheet` shows on the
// homeowner's dashboard.
function renderVendorCoverageGapsSection(gaps) {
  if (!gaps || !gaps.length) return "";
  const grouped = new Map();
  for (const task of gaps) {
    const cat = task.systemCategory || "Other";
    if (!grouped.has(cat)) {
      grouped.set(cat, []);
    }
    grouped.get(cat).push(task);
  }
  const cards = [...grouped.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([cat, tasks]) => `
      <article class="admin-sim__gap-card">
        <header>
          <h5>${escapeHtml(cat)}</h5>
          <span class="admin-pill admin-pill--warn">Needs a pro</span>
        </header>
        <p class="admin-muted">${tasks.length} template${tasks.length === 1 ? "" : "s"} would have seeded "Find a contractor for X" tasks. iOS now flags <code>home_systems.needs_vendor_coverage = true</code> instead.</p>
        <ul class="admin-sim__gap-list">
          ${tasks.map((t) => `<li>${escapeHtml(t.title)}</li>`).join("")}
        </ul>
      </article>
    `).join("");
  return `
    <section class="admin-sim__lane admin-sim__lane--gaps">
      <header>
        <h4>🔧 Vendor coverage gaps</h4>
        <span class="admin-muted">${grouped.size} categor${grouped.size === 1 ? "y" : "ies"}</span>
      </header>
      <p class="admin-sim__lane-blurb admin-muted">Phase 67 reconciler v2: instead of seeding "Find a contractor for X" tasks per template, the iOS reconciler marks the system's <code>needs_vendor_coverage = true</code> and the homeowner sees a consolidated VendorCoverageSheet card.</p>
      <div class="admin-sim__gap-grid">
        ${cards}
      </div>
    </section>
  `;
}

// Phase 5q — Step funnel showing how 220+ templates collapse into the
// task list the homeowner actually sees. Tom flagged confusion about
// "why does only X% of templates fire?" — every step here explains a
// real piece of the gating + bundling pipeline.
function renderFunnelBreakdown(f) {
  if (!f) return "";
  const dropEssential = f.totalTemplates - f.essentialTemplates;
  const dropGated = f.essentialTemplates - f.eligibleAfterGating;
  const dropBundles = f.bundleChildrenRolledUp;
  const dropHandymanPunch = f.handymanBundleChildrenToPunch;
  return `
    <div class="admin-sim__funnel">
      <header>
        <h4>Why these tasks (and not the others)</h4>
        <span class="admin-muted">220+ templates collapse into a manageable list. Each step below cuts a real chunk.</span>
      </header>
      <ol class="admin-sim__funnel-steps">
        <li>
          <strong>${f.totalTemplates}</strong>
          <span>total templates in the library</span>
        </li>
        <li class="admin-sim__funnel-step--cut">
          <strong>−${dropEssential}</strong>
          <span>opt-in only (isEssential: false). Homeowner adds via Recommended.</span>
        </li>
        <li>
          <strong>${f.essentialTemplates}</strong>
          <span>auto-seed candidates</span>
        </li>
        <li class="admin-sim__funnel-step--cut">
          <strong>−${dropGated}</strong>
          <span>gated out by region or missing subtypes (no pool, no boiler, etc.)</span>
        </li>
        <li>
          <strong>${f.eligibleAfterGating}</strong>
          <span>eligible for this property</span>
        </li>
        <li class="admin-sim__funnel-step--cut">
          <strong>−${dropHandymanPunch}</strong>
          <span>handyman bundle children → punch list (NOT individual tasks)</span>
        </li>
        <li class="admin-sim__funnel-step--cut">
          <strong>−${dropBundles}</strong>
          <span>vendor bundle children → roll up into 1 parent visit each</span>
        </li>
        <li class="admin-sim__funnel-step--final">
          <strong>${f.uniqueTasksAfterBundling}</strong>
          <span>final task rows the homeowner sees (${f.bundleParentVisits} of those are multi-item parent visits)</span>
        </li>
      </ol>
      <p class="admin-sim__funnel-note admin-muted">
        Plus <strong>${f.handymanBundleChildrenToPunch}</strong> punch-list items the handyman tackles in one visit, and
        <strong>${f.routinesExtracted}</strong> recurring routines (landscaper, cleaner, pool service, etc.).
      </p>
    </div>
  `;
}

// Phase 5o — Handyman punch list section. Shows what the spring/fall
// handyman bundles' children would auto-populate as handyman_punch_items
// rows on the homeowner's punch list. The bundle parents themselves
// ("Schedule Spring Handyman Visit" / "Schedule Fall Handyman Visit")
// are NOT seeded as tasks anymore — they become seasonal home-screen
// reminders that route into the handyman view.
function renderPunchListSection(punch) {
  const total = punch?.total || 0;
  if (!total) {
    return `
      <section class="admin-sim__lane admin-sim__lane--punch">
        <header><h4>📋 Handyman punch list</h4><span class="admin-muted">No items</span></header>
        <p class="admin-sim__lane-blurb admin-muted">Spring + fall handyman bundle children would land on the punch list. None of those templates passed the gating filters for these answers.</p>
      </section>
    `;
  }
  const handymanLine = punch.hasHandymanOnFile
    ? `Handyman on file from Q15b — these auto-populate the punch list and the handyman tackles them on the next visit.`
    : `No handyman on file yet — items still seed on the punch list. Homeowner picks a handyman later (or via the Vendor Coverage card) to assign them to.`;
  return `
    <section class="admin-sim__lane admin-sim__lane--punch">
      <header><h4>📋 Handyman punch list</h4><span class="admin-muted">${total} items auto-populated</span></header>
      <p class="admin-sim__lane-blurb">
        ${escapeHtml(handymanLine)}<br/>
        <strong>Note:</strong> "Schedule Spring Handyman Visit" / "Schedule Fall Handyman Visit" tasks are NOT created. Those become twice-a-year "Time to book your handyman" reminders on the home screen that push the homeowner into the handyman tab to coordinate this list.
      </p>
      <div class="admin-sim__punch-grid">
        ${renderPunchSeasonCol("🌷 Spring auto-populated", punch.grouped.spring)}
        ${renderPunchSeasonCol("🍂 Fall auto-populated", punch.grouped.fall)}
      </div>
    </section>
  `;
}

function renderPunchSeasonCol(title, items) {
  if (!items.length) {
    return `
      <div class="admin-sim__punch-col">
        <header>${escapeHtml(title)}</header>
        <p class="admin-muted">No items pass the gating filter for these answers.</p>
      </div>
    `;
  }
  return `
    <div class="admin-sim__punch-col">
      <header>${escapeHtml(title)} <span class="admin-muted">${items.length}</span></header>
      <ul>
        ${items
          .map(
            (t) => `
              <li data-jump-template-key="${escapeHtml(t.templateKey || `${t.systemCategory}:${t.title}`)}" title="Click to open this punch-list template and add a note">
                <span class="admin-sim__punch-check">☑</span>
                <span class="admin-sim__punch-title">${escapeHtml(t.title || "(untitled)")}</span>
                <span class="admin-sim__punch-meta">
                  ${t.diyEffortMinutes ? `${t.diyEffortMinutes} min · ` : ""}${escapeHtml(t.systemCategory || "")}
                </span>
              </li>
            `
          )
          .join("")}
      </ul>
    </div>
  `;
}

function renderRoutineSection(routines, counts) {
  if (!routines.length) {
    return `
      <section class="admin-sim__lane admin-sim__lane--routine">
        <header><h4>🔁 Routines</h4><span class="admin-muted">No routines apply</span></header>
        <p class="admin-sim__lane-blurb admin-muted">No routine categories matched these facts. Toggle quiz answers like q11_lawn (pro), q12_pool (in-ground), q28b_pets (yes), etc. to add routines.</p>
      </section>
    `;
  }
  const active = counts?.routinesActive ?? routines.filter((r) => r.hasVendor).length;
  const pending = counts?.routinesPending ?? routines.filter((r) => !r.hasVendor).length;
  return `
    <section class="admin-sim__lane admin-sim__lane--routine">
      <header>
        <h4>🔁 Routines</h4>
        <span class="admin-muted">${routines.length} · ${active} active · ${pending} pending vendor</span>
      </header>
      <p class="admin-sim__lane-blurb admin-muted">
        Routines are created from quiz facts (has lawn, has pool, has pets, region) — not by walking templates.
        Active = vendor on file from Q15b/Q11/Q12/etc. Pending vendor = routine still gets created in pending state;
        homeowner picks a pro post-quiz via Find a Pro, Q37, or Settings → Routines.
      </p>
      <div class="admin-sim__routines">
        ${routines
          .map(
            (r) => `
              <article class="admin-sim__routine ${r.hasVendor ? "is-active" : "is-pending"}" data-jump-routine-kind="${escapeHtml(r.kind)}" title="Click to open this routine's detail panel and add a note">
                <header>
                  <span class="admin-sim__routine-status">${r.hasVendor ? "Active — vendor on file" : "Pending — pick vendor post-quiz"}</span>
                  <strong>${r.icon} ${escapeHtml(r.label)}</strong>
                  <span class="admin-muted">${escapeHtml(r.defaultCadence)}${r.defaultDay ? ` · ${escapeHtml(r.defaultDay)}` : ""} · ${escapeHtml(r.activeMonths)}</span>
                </header>
                <p class="admin-sim__routine-blurb">
                  ${
                    r.hasVendor
                      ? "Vendor captured at Q15b/Q11/Q12/etc. Routine auto-creates with vendor linked. Homeowner just confirms days post-quiz at Q37."
                      : "No vendor captured. Routine still creates in pending_vendor state — homeowner picks a pro later via Find a Pro / Q37 / Settings → Routines."
                  }
                </p>
                ${
                  r.templateRollup.length
                    ? `<details>
                        <summary>${r.templateRollup.length} template${r.templateRollup.length === 1 ? "" : "s"} fold into this routine</summary>
                        <ul>
                          ${r.templateRollup
                            .map(
                              (t) => `
                                <li data-jump-template-key="${escapeHtml(t.templateKey || `${t.systemCategory}:${t.title}`)}">
                                  <code>${escapeHtml(t.title || t.bundleTitle || "(untitled)")}</code>
                                  <span class="admin-muted">${escapeHtml(t.frequency || "")}</span>
                                </li>
                              `
                            )
                            .join("")}
                        </ul>
                      </details>`
                    : ""
                }
              </article>
            `
          )
          .join("")}
      </div>
    </section>
  `;
}

// Phase 5m — categories whose recurring vendor work should auto-collapse
// into a routine instead of seeding individual tasks. Mirrors the
// allowlist in admin-forms.js.
const SIM_ROUTINE_CATEGORIES = new Set([
  "Landscaping", "Cleaning Service", "Pool/Spa", "Hot Tub",
  "Pest Control", "Snow Removal", "Mosquito & Tick", "Pet Waste",
  "Window Cleaning", "Gutter Cleaning", "Trash & Recycling",
]);
// Phase 5n — Tom's rule: routines are weekly / biweekly / monthly /
// quarterly only. Semi-annual / annual / multi-year are tasks. No
// bundleId shortcut — frequency is the ground truth.
const SIM_ROUTINE_FREQUENCIES = new Set([
  "Weekly", "Biweekly", "Triweekly",
  "Monthly", "Bi-monthly",
  "Quarterly",
]);

function simIsRoutineCandidate(task) {
  if (!task) return false;
  if (task.assignmentType === "personal") return false;
  if (task.safetyFloor === true) return false;
  if (task.routingOverride === "diyDefault") return false;
  if (!SIM_ROUTINE_FREQUENCIES.has(task.frequency)) return false;
  if (!SIM_ROUTINE_CATEGORIES.has(task.systemCategory)) return false;
  return true;
}

// Map a simulator task to its 5-tier category. Routines take priority
// over the underlying Swift fields — recurring vendor work surfaces as
// a routine even if the template ships as `vendorDefault`.
function tierForTask(task) {
  if (simIsRoutineCandidate(task)) return "routine";
  if (task.safetyFloor === true) return "vendor_only";
  if (task.routingOverride === "vendorOnly") return "vendor_only";
  if (task.assignmentType === "vendor" && !task.routingOverride) return "vendor_only";
  if (task.routingOverride === "diyDefault") return "handyman_only";
  if (task.assignmentType === "personal") return "handyman_only";
  return "vendor_or_handyman";
}

function bucketByAssignmentTier(lanes, facts) {
  // Phase 5p — Routine bucket is empty here because routines are now
  // built fact-driven and pre-extracted from the task lanes upstream.
  // Anything that lands in `lanes` is genuinely a task.
  //
  // Phase 67 (C4) — `vendor_coverage_gaps` peels vendor-tier tasks where
  // the homeowner has NO contractor on file for the system's category out
  // of the vendor lanes and into a dedicated "🔧 Vendor coverage gaps"
  // callout. The iOS reconciler v2 stops creating "Find a contractor for X"
  // maintenance_tasks rows; the simulator mirrors that by stop-rendering
  // them as tasks in the vendor lane and instead surfacing the gap as a
  // single card per category — matching what `VendorCoverageSheet`
  // surfaces on the dashboard.
  const out = {
    routine: [],
    vendor_only: [],
    vendor_or_handyman: [],
    handyman_only: [],
    homeowner_only: [],
    vendor_coverage_gaps: [],
  };
  const all = [
    ...(lanes.bundles || []),
    ...(lanes.vendor || []),
    ...(lanes.findContractor || []),
    ...(lanes.personal || []),
  ];
  for (const task of all) {
    const tier = tierForTask(task);
    const isVendorTier = tier === "vendor_only" || tier === "vendor_or_handyman";
    if (isVendorTier) {
      const cat = task.systemCategory;
      const hasContractor = !!facts?.hasContractorsFor?.[cat];
      if (!hasContractor) {
        out.vendor_coverage_gaps.push(task);
        continue;
      }
    }
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
  // Use the parent template's key for bundle parents (children are listed
  // in the disclosure but the row itself jumps to the bundle parent's
  // template). Standalone tasks jump to their own template.
  const jumpKey = task.parentTemplate?.templateKey
    || task.templateKey
    || (task.systemCategory && task.title ? `${task.systemCategory}:${task.title.replace(/^Schedule\s+/i, "")}` : "");
  const childList = isBundle && task.children
    ? `<details class="admin-sim__children"><summary>${task.children.length} item${task.children.length === 1 ? "" : "s"} in this visit</summary><ul>${task.children
        .map((c) => `<li data-jump-template-key="${escapeHtml(c.templateKey || `${c.systemCategory}:${c.title}`)}"><code>${escapeHtml(c.systemCategory)}</code> ${escapeHtml(c.title)}</li>`)
        .join("")}</ul></details>`
    : "";
  return `
    <li class="admin-sim__task" data-lane="${escapeHtml(task._lane)}" data-jump-template-key="${escapeHtml(jumpKey)}" title="Click to open this template's detail panel and add a note">
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
  // Phase 67D (A3): Q3 + Q3b merged. Legacy entries kept below for
  // backward-compat with persisted simulator state.
  { id: "q3_heating_system", label: "Heating system" },
  { id: "q3_heating_fuel", label: "Heating fuel (legacy)" },
  { id: "q3b_hvac_type", label: "HVAC type (legacy)" },
  { id: "q6_water_source", label: "Water source" },
  { id: "q7_sewer_septic", label: "Sewer / septic" },
  { id: "q8_water_heater", label: "Water heater" },
  { id: "q9_basement", label: "Basement / crawl" },
  { id: "q11_lawn", label: "Lawn handling" },
  { id: "q11b_lawn_type", label: "Lawn type (legacy)", showIf: (a) => ["diy", "pro"].includes(a.q11_lawn) },
  { id: "q12_pool", label: "Pool / hot tub" },
  { id: "q12b_pool_chemistry", label: "Pool chemistry (legacy)", showIf: (a) => ["in_ground", "above_ground", "both"].includes(a.q12_pool) },
  { id: "q13_pest", label: "Pest control" },
  { id: "q14_irrigation", label: "Irrigation" },
  { id: "q15_security", label: "Security system" },
  { id: "q21_solar", label: "Solar" },
  { id: "q22_generator", label: "Generator" },
  { id: "q25_garage_ev", label: "Garage" },
  { id: "q25b_ev_charger", label: "EV charger (legacy)", showIf: (a) => a.q25_garage_ev && a.q25_garage_ev !== "none" },
  { id: "q28b_pets", label: "Pets (legacy)" },
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
