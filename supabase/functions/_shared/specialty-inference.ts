// Phase 52b: Keyword-based specialty system inference.
// Shared between process-invoice and analyze-document Edge Functions.
// When an invoice description or document mentions keywords that imply
// a specialty system the household hasn't registered, this module
// returns a suggestion the iOS client can surface for one-tap confirmation.

export interface SpecialtyInferenceRule {
  category: string;        // matches home_systems.category
  subtypeHint?: string;    // optional subtype to suggest
  displayName: string;     // for the suggestion card
  keywords: string[];      // all lowercase, matched as substrings
  minConfidence: number;   // 0-1, threshold for surfacing
}

export interface SpecialtySuggestion {
  category: string;
  display_name: string;
  subtype_hint: string | null;
  evidence: string;
  source: string;  // "invoice" | "document"
}

export const SPECIALTY_INFERENCE_RULES: SpecialtyInferenceRule[] = [
  {
    category: "Pool/Spa",
    displayName: "Pool",
    keywords: [
      "pool opening", "pool closing", "pool service", "chlorine tablets",
      "pool cover", "pool heater", "pool pump", "pool filter cartridge",
      "skimmer basket", "salt cell", "pool chemical", "pentair", "hayward",
      "jandy", "leslie's pool",
    ],
    minConfidence: 0.75,
  },
  {
    category: "Hot Tub",
    displayName: "Hot Tub",
    keywords: [
      "hot tub", "spa cover", "spa chemical", "jacuzzi service",
      "bromine tablets", "spa filter",
    ],
    minConfidence: 0.8,
  },
  {
    category: "Chimney",
    displayName: "Chimney",
    keywords: [
      "chimney sweep", "chimney inspection", "flue cleaning",
      "creosote removal", "chimney cap",
    ],
    minConfidence: 0.85,
  },
  {
    category: "Fire Protection",
    subtypeHint: "gas_fireplace",
    displayName: "Gas Fireplace",
    keywords: [
      "gas fireplace service", "fireplace thermopile", "fireplace thermocouple",
      "gas log set", "fireplace pilot light",
    ],
    minConfidence: 0.8,
  },
  {
    category: "Water Treatment",
    displayName: "Water Softener",
    keywords: [
      "water softener", "softener salt delivery", "salt pellets",
      "brine tank", "culligan", "kinetico", "ecowater",
    ],
    minConfidence: 0.8,
  },
  {
    category: "Solar",
    displayName: "Solar Panels",
    keywords: [
      "solar panel cleaning", "solar inverter", "solar array",
      "sunrun", "sunpower", "solaredge",
    ],
    minConfidence: 0.8,
  },
  {
    category: "Tree Service",
    displayName: "Tree Service",
    keywords: [
      "tree trimming", "tree removal", "arborist", "stump grinding",
      "tree pruning", "cabling", "deep root fertilization",
    ],
    minConfidence: 0.75,
  },
  {
    category: "Pet Waste",
    displayName: "Pet Waste Removal",
    keywords: [
      "doodycalls", "poop 911", "scoop soldiers", "pet waste", "yard cleanup service",
    ],
    minConfidence: 0.9,
  },
  {
    category: "Mosquito & Tick",
    displayName: "Mosquito & Tick Spraying",
    keywords: [
      "mosquito joe", "mosquito squad", "mosquito treatment",
      "tick treatment", "barrier spray",
    ],
    minConfidence: 0.9,
  },
  {
    category: "Elevator",
    displayName: "Residential Elevator",
    keywords: [
      "elevator inspection", "residential elevator", "stair lift service",
      "otis", "schindler residential",
    ],
    minConfidence: 0.85,
  },
  {
    category: "Wine Cellar",
    displayName: "Wine Cellar",
    keywords: [
      "wine cellar cooling", "cellar cooling unit", "wineguardian",
      "wine cooling repair",
    ],
    minConfidence: 0.85,
  },
];

/**
 * Returns the first specialty rule whose keywords appear in the combined
 * text, or null if nothing matches. Skips categories the household already
 * has and categories the household has previously dismissed.
 */
export function inferSpecialtyCategory(
  combinedText: string,
  existingCategories: Set<string>,
  dismissedCategories?: Set<string>,
): SpecialtySuggestion | null {
  const hay = combinedText.toLowerCase();
  for (const rule of SPECIALTY_INFERENCE_RULES) {
    if (existingCategories.has(rule.category)) continue;
    if (dismissedCategories?.has(rule.category)) continue;
    const hit = rule.keywords.find(kw => hay.includes(kw));
    if (hit) {
      return {
        category: rule.category,
        display_name: rule.displayName,
        subtype_hint: rule.subtypeHint ?? null,
        evidence: hit,
        source: "", // caller sets this
      };
    }
  }
  return null;
}
